(function(){
  const $ = sel => document.querySelector(sel);

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
    restUrl: "",
    jwt: "",
    me: "",
    room: "",
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
      .split(/\s+/)
      .filter(Boolean)
      .slice(0,2)
      .map(s=>s[0].toUpperCase())
      .join("");
  }

  // Fixed timestamp function - ensures accurate Philippine time conversion
  function formatTimestamp(ts) {
    // Handle different timestamp formats from server
    let timestamp = ts;
    
    // If timestamp is a string, try to parse it
    if (typeof timestamp === 'string') {
      // Remove any timezone indicators to treat as UTC
      timestamp = timestamp.replace('Z', '').replace(/[+-]\d{2}:\d{2}$/, '');
      timestamp = new Date(timestamp + 'Z'); // Force UTC interpretation
    }
    
    const d = new Date(timestamp || Date.now());
    
    // Get current time in Manila for comparison
    const now = new Date();
    const manilaOffset = 8 * 60; // UTC+8 in minutes
    const localOffset = now.getTimezoneOffset();
    const manilaTime = new Date(now.getTime() + (localOffset + manilaOffset) * 60000);
    
    // Format options for Manila time
    const optsTime = { 
      timeZone: "Asia/Manila", 
      hour: "numeric", 
      minute: "2-digit", 
      hour12: true 
    };
    
    // Check if the message is from today
    const messageDate = new Date(d.getTime() + (localOffset + manilaOffset) * 60000);
    const isToday = manilaTime.toDateString() === messageDate.toDateString();
    
    if (isToday) {
      // Same day → show only time
      return messageDate.toLocaleTimeString("en-PH", optsTime);
    } else {
      // Different day → show date + time
      const optsDate = { 
        timeZone: "Asia/Manila", 
        year: "numeric", 
        month: "short", 
        day: "numeric" 
      };
      const dateStr = messageDate.toLocaleDateString("en-PH", optsDate);
      const timeStr = messageDate.toLocaleTimeString("en-PH", optsTime);
      return `${dateStr} ${timeStr}`;
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

  // Append message + avatar + PH timestamp
  function appendMessage({ from, text, timestamp, mine }) {
    const li = document.createElement("li");
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

    content.appendChild(bubble);
    content.appendChild(meta);

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

  // WebSocket connect/disconnect
  function connect() {
    if (!state.room || state.leftRoom) return;

    state.wsUrl   = window.CONFIG.WEBSOCKET_URL;
    state.restUrl = window.CONFIG.REST_API_BASE_URL;
    state.jwt     = window.CONFIG.JWT_TOKEN || "";

    const params = [
      `roomId=${encodeURIComponent(state.room)}`,
      `fromName=${encodeURIComponent(state.me)}`
    ];
    let url = `${state.wsUrl}?${params.join("&")}`;
    if (state.jwt) url += `&token=${encodeURIComponent(state.jwt)}`;

    state.ws = new WebSocket(url);

    state.ws.onopen = () => {
      setStatus(true);
      state.reconnectDelay = 1000;

      sendWS({ action:"userJoined", roomId: state.room, fromName: state.me });

      clearInterval(state.pingInterval);
      state.pingInterval = setInterval(() => {
        if (state.ws.readyState === WebSocket.OPEN) {
          state.ws.send(JSON.stringify({ action: "ping", t: Date.now() }));
        }
      }, 25000);
    };

    state.ws.onmessage = evt => {
      let msg;
      try { msg = JSON.parse(evt.data); }
      catch { return; }

      // Typing
      if (msg.action === "typing" && msg.fromName !== state.me) {
        typingEl.textContent = `${msg.fromName} is typing…`;
        typingEl.classList.remove("hidden");
        return;
      }
      if (msg.action === "stopTyping" && msg.fromName !== state.me) {
        typingEl.classList.add("hidden");
        return;
      }

      // Notifications
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

      // New message
      if (msg.action === "newMessage" || msg.type === "message") {
        const from = msg.fromName || msg.from;
        appendMessage({
          from,
          text: msg.message,
          timestamp: msg.timestamp || msg.ts,
          mine: from === state.me
        });
        return;
      }

      // History
      if (msg.action === "messageHistory") {
        messagesEl.innerHTML = "";
        (msg.messages||[]).forEach(it => {
          const from = it.fromName || it.from;
          appendMessage({
            from,
            text: it.message,
            timestamp: it.timestamp || it.ts,
            mine: from === state.me
          });
        });
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

  function disconnect() {
    if (state.ws) state.ws.close();
    state.ws = null;
    setStatus(false);
    clearInterval(state.pingInterval);
    clearTimeout(state.reconnectTimer);
  }

  // Load history via REST
  function loadMessageHistory() {
    if (!state.restUrl) return;
    fetch(`${state.restUrl}/messages/${encodeURIComponent(state.room)}`, {
      headers: state.jwt ? { "Authorization": `Bearer ${state.jwt}` } : {}
    })
    .then(r => r.ok ? r.json() : Promise.reject(r.status))
    .then(data => {
      messagesEl.innerHTML = "";
      if (Array.isArray(data)) {
        data.forEach(d => {
          const from = d.fromName || d.from;
          appendMessage({
            from,
            text: d.message,
            timestamp: d.timestamp || d.ts,
            mine: from === state.me
          });
        });
      }
    })
    .catch(err => console.error("History load failed:", err));
  }

  // Events
  joinForm.addEventListener("submit", e => {
    e.preventDefault();
    state.me   = displayNameEl.value.trim();
    state.room = roomIdEl.value.trim();
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
    loadMessageHistory();
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
    sendWS({ action:"typing",    roomId:state.room, fromName:state.me });
    clearTimeout(typingTimeout);
    typingTimeout = setTimeout(() => {
      sendWS({ action:"stopTyping",roomId:state.room, fromName:state.me });
    }, 3000);
  });

  messageInput.addEventListener("keypress", e => {
    if (e.key === "Enter") sendBtn.click();
  });

  leaveBtn.addEventListener("click", () => {
    sendWS({ action:"userLeft", roomId:state.room, fromName:state.me });
    disconnect();
    state.leftRoom = true;
    localStorage.setItem("leftRoom","true");
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
    }
  });

  // Helper to send over WS
  function sendWS(payload) {
    if (state.ws && state.ws.readyState === WebSocket.OPEN) {
      state.ws.send(JSON.stringify(payload));
    } else {
      console.error("WebSocket not connected");
    }
  }
})();