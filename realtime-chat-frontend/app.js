(function(){
  const $ = sel => document.querySelector(sel);

  // Generate or load a stable userId
  function getUserId() {
    let id = localStorage.getItem("userId");
    if (!id) {
      id = "uid_" + Math.random().toString(36).substr(2, 9);
      localStorage.setItem("userId", id);
    }
    return id;
  }

  // Track read receipts: messageId → Map<userId, displayName>
  const seenMap = {};

  // Elements
  const joinScreen    = $("#join-screen");
  const chatScreen    = $("#chat-screen");
  const joinForm      = $("#join-form");
  const displayNameEl = $("#displayName");
  const roomIdEl      = $("#roomId");
  const messagesEl    = $("#messages");
  const messageInput  = $("#messageInput");
  const sendBtn       = $("#sendBtn");
  const leaveBtn      = $("#leaveBtn");
  const connDot       = $("#connDot");
  const connText      = $("#connText");
  const meName        = $("#me-name");
  const meRoom        = $("#me-room");
  const meInitials    = $("#me-initials");
  const reconnectBtn  = $("#reconnectBtn");
  const typingEl      = $("#typing");

  // State
  let state = {
    ws: null,
    wsUrl: "",
    me: "",
    room: "",
    userId: getUserId(),
    connected: false,
    pingInterval: null,
    reconnectTimer: null,
    reconnectDelay: 1000,
    leftRoom: false
  };
  let typingTimeout;

  // Helpers
  function initials(name) {
    return (name||"?")
      .split(/\s+/).filter(Boolean).slice(0,2)
      .map(s=>s[0].toUpperCase()).join("");
  }

  function parseDate(ts) {
    if (typeof ts === "number") {
      return ts < 1e12 ? new Date(ts * 1000) : new Date(ts);
    }
    if (typeof ts === "string") {
      const n = ts.endsWith("Z") ? ts : ts + "Z";
      const d = new Date(n);
      if (!isNaN(d)) return d;
    }
    return new Date();
  }

  function formatTimestamp(ts) {
    const d = parseDate(ts);
    const optsYMD = { timeZone:"Asia/Manila", year:"numeric", month:"numeric", day:"numeric" };
    const todayKey  = new Date().toLocaleDateString("en-PH", optsYMD);
    const targetKey = d.toLocaleDateString("en-PH", optsYMD);
    const optsTime = { timeZone:"Asia/Manila", hour:"numeric", minute:"2-digit", hour12:true };

    if (targetKey === todayKey) {
      return d.toLocaleTimeString("en-PH", optsTime);
    } else {
      const optsDateLong = { timeZone:"Asia/Manila", year:"numeric", month:"short", day:"numeric" };
      const datePart = d.toLocaleDateString("en-PH", optsDateLong);
      const timePart = d.toLocaleTimeString("en-PH", optsTime);
      return `${datePart} ${timePart}`;
    }
  }

  function setStatus(connected) {
    state.connected = connected;
    connDot.classList.toggle("ok", connected);
    connText.textContent = connected ? "Connected" : "Disconnected";
  }

  function showJoin() {
    joinScreen.classList.remove("hidden");
    chatScreen.classList.add("hidden");
  }

  function showChat() {
    joinScreen.classList.add("hidden");
    chatScreen.classList.remove("hidden");
    messageInput.focus();
  }

  function scrollToBottom() {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }

  // Append a message with avatar, timestamp, and seen badge placeholder
  function appendMessage({ from, userId, text, timestamp }) {
    const mine = userId === state.userId;
    const li = document.createElement("li");
    li.dataset.messageId = timestamp;
    li.className = "msg " + (mine ? "me" : "other");

    const avatarEl = document.createElement("div");
    avatarEl.className = "msg-avatar";
    avatarEl.textContent = initials(from);

    const content = document.createElement("div");
    content.className = "msg-content";

    const bubble = document.createElement("div");
    bubble.className = "bubble";
    bubble.textContent = text;

    const meta = document.createElement("div");
    meta.className = "meta";
    meta.textContent = `${from} • ${formatTimestamp(timestamp)}`;

    const seenBadge = document.createElement("div");
    seenBadge.className = "seen-badge";
    seenBadge.textContent = "";

    content.appendChild(bubble);
    content.appendChild(meta);
    content.appendChild(seenBadge);

    if (mine) {
      li.appendChild(content);
      li.appendChild(avatarEl);
    } else {
      li.appendChild(avatarEl);
      li.appendChild(content);
    }

    messagesEl.appendChild(li);
    scrollToBottom();
  }

  // Send via WebSocket, always including userId
  function sendWS(payload) {
    payload.userId = state.userId;
    if (state.ws && state.ws.readyState === WebSocket.OPEN) {
      state.ws.send(JSON.stringify(payload));
    }
  }

function connect() {
  if (!state.room || state.leftRoom) return;

  state.wsUrl = window.CONFIG.WEBSOCKET_URL;

  let url = `${state.wsUrl}?roomId=${encodeURIComponent(state.room)
    }&fromName=${encodeURIComponent(state.me)
    }&userId=${encodeURIComponent(state.userId)}`;

  state.ws = new WebSocket(url);

  state.ws.onopen = () => {
    setStatus(true);
    state.reconnectDelay = 1000;
    sendWS({ action: "userJoined", roomId: state.room, fromName: state.me });
    
    // Directly fetch message history from REST API
    if (window.CONFIG.REST_API_BASE_URL) {
      fetch(`${window.CONFIG.REST_API_BASE_URL}/messages/${state.room}`)
        .then(response => {
          if (!response.ok) {
            throw new Error('Network response was not ok');
          }
          return response.json();
        })
        .then(messages => {
          messagesEl.innerHTML = "";
          messages.forEach(msg => {
            appendMessage({
              from: msg.fromName,
              userId: msg.userId,
              text: msg.message,
              timestamp: msg.timestamp
            });
          });
        })
        .catch(error => {
          console.error('Error fetching message history:', error);
        });
    }
    
    clearInterval(state.pingInterval);
    state.pingInterval = setInterval(() => {
      if (state.ws.readyState === WebSocket.OPEN) {
        state.ws.send(JSON.stringify({ action: "ping", t: Date.now() }));
      }
    }, 25000);
  };

  // ... rest of your WebSocket event handlers remain the same
  state.ws.onmessage = evt => {
    let msg;
    try { msg = JSON.parse(evt.data); } catch { return; }

    // Remove the messageHistory handler since we're fetching directly
    // Keep all other handlers

    // typing indicator
    if (msg.action === "typing" && msg.userId !== state.userId) {
      typingEl.textContent = `${msg.fromName} is typing…`;
      typingEl.classList.remove("hidden");
      return;
    }
    if (msg.action === "stopTyping" && msg.userId !== state.userId) {
      typingEl.classList.add("hidden");
      return;
    }

    // user join/leave
    if (msg.action === "userJoined" || msg.action === "userLeft") {
      const note = document.createElement("li");
      note.className = "notification";
      note.textContent = msg.action === "userJoined"
        ? `${msg.fromName} joined the chat`
        : `${msg.fromName} left the chat`;
      messagesEl.appendChild(note);
      scrollToBottom();
      return;
    }

    // new message
    if (msg.action === "newMessage") {
      const from = msg.fromName;
      const id   = msg.timestamp;

      appendMessage({
        from,
        userId:    msg.userId,
        text:      msg.message,
        timestamp: id
      });

      // send read receipt once per message
      if (msg.userId !== state.userId && !seenMap[id]) {
        seenMap[id] = new Map([[ state.userId, state.me ]]);
        sendWS({
          action:               "messageSeen",
          roomId:               state.room,
          messageId:            id,
          originalSenderUserId: msg.userId,
          fromName:             state.me
        });
      }
      return;
    }

    // read-receipt
    if (msg.action === "messageSeen") {
      const id = msg.messageId;
      if (!seenMap[id]) seenMap[id] = new Map();
      seenMap[id].set(msg.userId, msg.fromName);

      const li = messagesEl.querySelector(`li[data-message-id="${id}"]`);
      if (!li) return;
      const badge = li.querySelector(".seen-badge");
      if (!badge) return;

      const names = Array.from(seenMap[id].values());
      const count = names.length;
      let text;
      if (count === 1) {
        text = `Seen by ${names[0]}`;
      } else if (count === 2) {
        text = `${names[0]} and ${names[1]} seen your message`;
      } else {
        text = `${names[0]}, ${names[1]} and ${count - 2} others seen your message`;
      }
      badge.textContent = text;
      return;
    }
  };

  state.ws.onclose = () => {
    setStatus(false);
    clearInterval(state.pingInterval);
    clearTimeout(state.reconnectTimer);
    if (!state.leftRoom) {
      state.reconnectTimer = setTimeout(() => {
        connect();
        state.reconnectDelay = Math.min(state.reconnectDelay * 2, 15000);
      }, state.reconnectDelay);
    }
  };

  state.ws.onerror = err => console.error("WebSocket error:", err);
}
  
  
// FOR DISCONNECT FUNCTION!!
  function disconnect() {
    if (state.ws) state.ws.close();
    state.ws = null;
    setStatus(false);
    clearInterval(state.pingInterval);
    clearTimeout(state.reconnectTimer);
  }

  // Event wiring
  joinForm.addEventListener("submit", e => {
    e.preventDefault();
    state.me       = displayNameEl.value.trim();
    state.room     = roomIdEl.value.trim();
    state.leftRoom = false;
    localStorage.removeItem("leftRoom");

    if (!state.me || !state.room) {
      alert("Please enter your name and room ID.");
      return;
    }

    localStorage.setItem("displayName", state.me);
    localStorage.setItem("roomId", state.room);

    meName.textContent     = state.me;
    meRoom.textContent     = `Room: ${state.room}`;
    meInitials.textContent = initials(state.me);

    messagesEl.innerHTML = "";
    showChat();
    connect();
  });

  sendBtn.addEventListener("click", () => {
    const text = messageInput.value.trim();
    if (!text) return;
    sendWS({
      action:   "sendMessage",
      roomId:   state.room,
      message:  text,
      fromName: state.me
    });
    messageInput.value = "";
  });

  messageInput.addEventListener("input", () => {
    sendWS({ action: "typing",    roomId: state.room, fromName: state.me });
    clearTimeout(typingTimeout);
    typingTimeout = setTimeout(() => {
      sendWS({ action: "stopTyping", roomId: state.room, fromName: state.me });
    }, 3000);
  });

  messageInput.addEventListener("keypress", e => {
    if (e.key === "Enter") sendBtn.click();
  });

  leaveBtn.addEventListener("click", () => {
    sendWS({ action: "userLeft", roomId: state.room, fromName: state.me });
    disconnect();
    state.leftRoom = true;
    localStorage.setItem("leftRoom", "true");
    localStorage.removeItem("displayName");
    localStorage.removeItem("roomId");
    showJoin();
  });

  reconnectBtn.addEventListener("click", () => {
    if (!state.connected) {
      disconnect();
      connect();
    }
  });

  document.addEventListener("DOMContentLoaded", () => {
    const savedName = localStorage.getItem("displayName");
    const savedRoom = localStorage.getItem("roomId");
    const leftRoom  = localStorage.getItem("leftRoom") === "true";

    if (savedName && savedRoom && !leftRoom) {
      displayNameEl.value = savedName;
      roomIdEl.value      = savedRoom;
      setTimeout(() => joinForm.requestSubmit(), 100);
    } else {
      showJoin();
    }
  });
})();
