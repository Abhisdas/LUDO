const { WebSocketServer } = require('ws');
const http = require('http');

// HTTP healthcheck server
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/plain', 'Access-Control-Allow-Origin': '*' });
  res.end('LudoVerse Server Running\n');
});

const wss = new WebSocketServer({ server });

// Keep track of rooms
// Room schema: { roomCode: { hostId, players: [ { id, name, color, ws } ], gameStarted: false } }
const rooms = {};

wss.on('connection', (ws) => {
  console.log('New WebSocket Connection');
  let currentRoom = null;
  let playerInfo = null;

  ws.on('message', (message) => {
    try {
      const data = JSON.parse(message);
      
      switch (data.action) {
        case 'create_room': {
          const roomCode = Math.random().toString(36).substring(2, 6).toUpperCase();
          playerInfo = {
            id: data.playerId,
            name: data.playerName,
            color: 'red', // Host starts as Red
            isHost: true,
          };
          rooms[roomCode] = {
            code: roomCode,
            hostId: data.playerId,
            players: [{ ...playerInfo, ws }],
            gameStarted: false,
          };
          currentRoom = roomCode;
          console.log(`Room created: ${roomCode} by ${data.playerName}`);
          ws.send(JSON.stringify({
            action: 'room_created',
            roomCode,
            players: rooms[roomCode].players.map(p => ({ id: p.id, name: p.name, color: p.color, isHost: p.isHost })),
          }));
          break;
        }

        case 'join_room': {
          const code = data.roomCode.toUpperCase();
          const room = rooms[code];
          if (!room) {
            ws.send(JSON.stringify({ action: 'error', message: 'Room not found' }));
            return;
          }
          if (room.players.length >= 4) {
            ws.send(JSON.stringify({ action: 'error', message: 'Room is full' }));
            return;
          }
          if (room.gameStarted) {
            ws.send(JSON.stringify({ action: 'error', message: 'Game already started' }));
            return;
          }

          // Pick next available color
          const colors = ['red', 'green', 'yellow', 'blue'];
          const occupiedColors = room.players.map(p => p.color);
          const color = colors.find(c => !occupiedColors.includes(c)) || 'green';

          playerInfo = {
            id: data.playerId,
            name: data.playerName,
            color,
            isHost: false,
          };
          room.players.push({ ...playerInfo, ws });
          currentRoom = code;
          console.log(`Player ${data.playerName} joined Room ${code} as ${color}`);

          const playerList = room.players.map(p => ({ id: p.id, name: p.name, color: p.color, isHost: p.isHost }));
          room.players.forEach(p => {
            p.ws.send(JSON.stringify({
              action: 'player_joined',
              players: playerList,
            }));
          });
          break;
        }

        case 'start_game': {
          if (!currentRoom || !rooms[currentRoom]) return;
          const room = rooms[currentRoom];
          if (room.hostId !== data.playerId) return;

          room.gameStarted = true;
          console.log(`Game starting in Room ${currentRoom}`);
          room.players.forEach(p => {
            p.ws.send(JSON.stringify({
              action: 'game_started',
            }));
          });
          break;
        }

        case 'game_event': {
          if (!currentRoom || !rooms[currentRoom]) return;
          const room = rooms[currentRoom];
          // Broadcast to all other players in the room
          room.players.forEach(p => {
            if (p.id !== data.playerId) {
              p.ws.send(JSON.stringify({
                action: 'game_event',
                event: data.event,
              }));
            }
          });
          break;
        }

        case 'voice_stream': {
          if (!currentRoom || !rooms[currentRoom]) return;
          const room = rooms[currentRoom];
          // Broadcast voice packets to all other players in the room
          room.players.forEach(p => {
            if (p.id !== data.playerId) {
              p.ws.send(JSON.stringify({
                action: 'voice_stream',
                senderColor: playerInfo.color,
                audio: data.audio,
              }));
            }
          });
          break;
        }
      }
    } catch (err) {
      console.error('Error handling websocket message:', err);
    }
  });

  ws.on('close', () => {
    console.log('WebSocket closed');
    if (currentRoom && rooms[currentRoom]) {
      const room = rooms[currentRoom];
      room.players = room.players.filter(p => p.ws !== ws);

      if (room.players.length === 0) {
        console.log(`Room ${currentRoom} is empty. Deleting...`);
        delete rooms[currentRoom];
      } else {
        // Re-assign host if host left
        if (room.hostId === playerInfo?.id) {
          room.hostId = room.players[0].id;
          room.players[0].isHost = true;
        }

        const playerList = room.players.map(p => ({ id: p.id, name: p.name, color: p.color, isHost: p.isHost }));
        room.players.forEach(p => {
          p.ws.send(JSON.stringify({
            action: 'player_left',
            players: playerList,
          }));
        });
      }
    }
  });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log(`WebSocket server listening on port ${PORT}`);
});
