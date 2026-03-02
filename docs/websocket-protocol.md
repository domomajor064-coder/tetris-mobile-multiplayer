# Tetris Mobile Multiplayer - WebSocket Protocol

## 1. Overview

WebSocket is used for real-time game communication between clients and game server.

- **Endpoint**: `wss://tetris.yourdomain.com/tetris/ws/{gameId}`
- **Protocol**: Socket.io 4.x with fallback to HTTP long-polling
- **Authentication**: JWT token in query parameter or header
- **Heartbeat**: Ping/pong every 30 seconds

## 2. Connection Flow

```
Client                                              Server
  │                                                   │
  │  1. HTTP GET /tetris/ws/game-123                  │
  │     Authorization: Bearer {token}                 │
  ├──────────────────────────────────────────────────►│
  │                                                   │
  │     2. 101 Switching Protocols                   │
  │        Connection: Upgrade                       │
  │        Upgrade: websocket                        │
  │◄──────────────────────────────────────────────────┤
  │                                                   │
  │  3. { type: "join", gameId: "game-123" }          │
  ├──────────────────────────────────────────────────►│
  │                                                   │
  │     4. { type: "joined", playerId: "p1", ... }   │
  │◄──────────────────────────────────────────────────┤
  │                                                   │
  │  5. [Game in progress - bidirectional messages]   │
  │◄══════════════════════════════════════════════════►│
```

## 3. Message Format

All messages are JSON with the following structure:

```typescript
interface WebSocketMessage {
  type: string;        // Message type
  timestamp: number;   // Unix timestamp (ms)
  payload: any;        // Message-specific data
  seq?: number;        // Sequence number for ordering
}
```

## 4. Client → Server Messages

### 4.1 Join Game
```json
{
  "type": "join",
  "timestamp": 1705321200000,
  "payload": {
    "gameId": "game-uuid-123",
    "playerInfo": {
      "preferences": {
        "das": 167,
        "arr": 33
      }
    }
  }
}
```

### 4.2 Player Input
```json
{
  "type": "input",
  "timestamp": 1705321200150,
  "seq": 42,
  "payload": {
    "action": "move_left",
    "pieceId": "p1-1234567890",  // Current piece identifier
    "frame": 1234                // Game frame number
  }
}
```

**Input Actions:**
- `move_left` / `move_right` - Horizontal movement
- `rotate_cw` / `rotate_ccw` - Rotation
- `soft_drop` - Accelerated descent
- `hard_drop` - Instant drop to bottom
- `hold` - Store current piece
- `sonic_drop` - Drop without locking

### 4.3 Game Action
```json
{
  "type": "action",
  "timestamp": 1705321200200,
  "payload": {
    "action": "ready",      // ready, pause_request, leave
    "data": null
  }
}
```

### 4.4 Chat Message
```json
{
  "type": "chat",
  "timestamp": 1705321200500,
  "payload": {
    "message": "Good luck!",
    "target": "all"  // all, team, or playerId
  }
}
```

### 4.5 Ping (Keepalive)
```json
{
  "type": "ping",
  "timestamp": 1705321230000,
  "payload": {
    "latency": 45  // Last measured latency
  }
}
```

## 5. Server → Client Messages

### 5.1 Join Confirmation
```json
{
  "type": "joined",
  "timestamp": 1705321200100,
  "payload": {
    "playerId": "p1-uuid",
    "gameId": "game-uuid-123",
    "gameState": "waiting",  // waiting, countdown, playing, finished
    "players": [
      {
        "id": "p1-uuid",
        "username": "player1",
        "team": 1,
        "isReady": true
      },
      {
        "id": "p2-uuid",
        "username": "player2",
        "team": 2,
        "isReady": false
      }
    ]
  }
}
```

### 5.2 Game Start
```json
{
  "type": "game_start",
  "timestamp": 1705321205000,
  "payload": {
    "countdown": 3,           // 3, 2, 1, GO
    "seed": "random-seed-123", // For piece generation sync
    "startTime": 1705321206000,
    "initialState": {
      "level": 1,
      "gravity": 1000
    }
  }
}
```

### 5.3 State Update (Delta)
Sent 20 times per second (50ms interval)

```json
{
  "type": "state_delta",
  "timestamp": 1705321210000,
  "seq": 100,
  "payload": {
    "frame": 1200,
    "players": {
      "p1-uuid": {
        "board": "base64-compressed-board",
        "currentPiece": {
          "type": "T",
          "x": 4,
          "y": 12,
          "rotation": 1
        },
        "holdPiece": "I",
        "nextQueue": ["O", "S", "Z", "L", "J"],
        "score": 15000,
        "lines": 25,
        "level": 5,
        "combo": 3,
        "isAlive": true
      },
      "p2-uuid": {
        "board": "base64-compressed-board",
        // ... similar structure
      }
    },
    "attacks": [
      {
        "from": "p1-uuid",
        "to": "p2-uuid",
        "lines": 4,
        "type": "tetris",
        "time": 1705321209950
      }
    ]
  }
}
```

### 5.4 Full State Sync
Sent every 2 seconds for recovery

```json
{
  "type": "state_full",
  "timestamp": 1705321220000,
  "payload": {
    "gameId": "game-uuid-123",
    "frame": 2400,
    "status": "playing",
    "players": {
      // Complete state for all players
    }
  }
}
```

### 5.5 Attack Event
```json
{
  "type": "attack",
  "timestamp": 1705321215000,
  "payload": {
    "from": "p1-uuid",
    "to": "p2-uuid",
    "lines": 4,
    "type": "tetris",     // single, double, triple, tetris, tspin
    "combo": 3,
    "backToBack": true,
    "garbageIndex": 15    // For animation sync
  }
}
```

### 5.6 Garbage Lines Received
```json
{
  "type": "garbage_incoming",
  "timestamp": 1705321215050,
  "payload": {
    "lines": 4,
    "column": 3,           // Garbage hole position
    "delay": 1500,         // ms before lines appear
    "garbageId": "g-123"
  }
}
```

### 5.7 Line Clear Animation
```json
{
  "type": "line_clear",
  "timestamp": 1705321212000,
  "payload": {
    "playerId": "p1-uuid",
    "lines": [18, 19],     // Row indices cleared
    "type": "triple",
    "combo": 2,
    "perfectClear": false
  }
}
```

### 5.8 Player Eliminated
```json
{
  "type": "player_eliminated",
  "timestamp": 1705321250000,
  "payload": {
    "playerId": "p2-uuid",
    "username": "player2",
    "placement": 2,
    "reason": "top_out",   // top_out, disconnected, surrendered
    "by": "p1-uuid"        // Who eliminated them (if applicable)
  }
}
```

### 5.9 Game End
```json
{
  "type": "game_end",
  "timestamp": 1705321300000,
  "payload": {
    "winner": "p1-uuid",
    "results": [
      {
        "playerId": "p1-uuid",
        "username": "player1",
        "placement": 1,
        "score": 45000,
        "lines": 65,
        "pieces": 180,
        "attacksSent": 25,
        "maxCombo": 8,
        "eloChange": +15
      },
      {
        "playerId": "p2-uuid",
        "username": "player2",
        "placement": 2,
        "score": 32000,
        "eloChange": -15
      }
    ],
    "replayId": "replay-uuid-456"
  }
}
```

### 5.10 Player Joined/Left
```json
{
  "type": "player_joined",
  "timestamp": 1705321203000,
  "payload": {
    "player": {
      "id": "p3-uuid",
      "username": "player3",
      "elo": 1400
    }
  }
}
```

```json
{
  "type": "player_left",
  "timestamp": 1705321240000,
  "payload": {
    "playerId": "p3-uuid",
    "reason": "disconnected"
  }
}
```

### 5.11 Error
```json
{
  "type": "error",
  "timestamp": 1705321200000,
  "payload": {
    "code": "INVALID_MOVE",
    "message": "Move validation failed",
    "details": {
      "expectedFrame": 1200,
      "receivedFrame": 1198
    }
  }
}
```

### 5.12 Pong (Keepalive Response)
```json
{
  "type": "pong",
  "timestamp": 1705321230030,
  "payload": {
    "serverTime": 1705321230030,
    "latency": 30
  }
}
```

## 6. Message Sequence Examples

### 6.1 Single Line Clear
```
Client                          Server
  │                               │
  │  1. Input: rotate + move     │
  ├──────────────────────────────►│
  │                               │
  │  2. Input: hard_drop         │
  ├──────────────────────────────►│
  │                               │
  │     3. State: piece locked   │
  │◄──────────────────────────────┤
  │                               │
  │     4. Event: line_clear     │
  │        (4 lines = Tetris)    │
  │◄──────────────────────────────┤
  │                               │
  │     5. Event: attack_sent    │
  │        (4 garbage lines)     │
  │◄──────────────────────────────┤
```

### 6.2 Receiving Attack
```
Server                          Client
  │                               │
  │  1. Event: garbage_incoming  │
  ├──────────────────────────────►│
  │        (4 lines, 1.5s delay)  │
  │                               │
  │  2. State updates continue   │
  ├══════════════════════════════►│
  │                               │
  │  3. Event: garbage_apply     │
  ├──────────────────────────────►│
  │        (lines appear at      │
  │         bottom of board)      │
```

### 6.3 Combo Chain
```
Client Action          Server Response
─────────────          ───────────────
Line clear #1    ──►   State + combo=1
Line clear #2    ──►   State + combo=2  
Line clear #3    ──►   State + combo=3 + Attack
(0.5s gap)              combo reset
```

## 7. Lag Compensation

### 7.1 Client-Side Prediction
Client predicts game state locally and reconciles with server:

```typescript
class GameClient {
  // Local prediction
  predictedState: GameState;
  
  // Server reconciliation
  serverState: GameState;
  
  onInput(input: Input) {
    // Apply locally immediately
    this.predictedState.apply(input);
    
    // Send to server
    this.ws.send({ type: 'input', ...input });
  }
  
  onServerState(state: GameState) {
    // Reconcile if different
    if (!this.statesEqual(this.predictedState, state)) {
      this.predictedState = this.reconcile(state);
    }
  }
}
```

### 7.2 Input Buffering
Server buffers inputs to handle network jitter:

```typescript
// Server input buffer
const INPUT_BUFFER_MS = 100;  // 100ms buffer

function processInput(input: Input, timestamp: number) {
  const targetFrame = timeToFrame(timestamp + INPUT_BUFFER_MS);
  
  // Schedule input for target frame
  scheduleForFrame(targetFrame, input);
}
```

### 7.3 Dead Reckoning
For opponent boards (ghost display):

```typescript
// Predict opponent position based on last known state
function predictOpponentState(lastState: PlayerState, deltaTime: number): PlayerState {
  const predicted = { ...lastState };
  
  // Apply gravity based on level
  predicted.currentPiece.y += gravity * deltaTime;
  
  // Apply any buffered inputs
  predicted.currentPiece.x += bufferedMoves;
  
  return predicted;
}
```

## 8. Reconnection Handling

### 8.1 Automatic Reconnect
```typescript
const RECONNECT_DELAY = [1000, 2000, 5000, 10000];  // Exponential backoff

class WebSocketClient {
  reconnectAttempts = 0;
  
  onDisconnect() {
    const delay = RECONNECT_DELAY[this.reconnectAttempts] || 30000;
    
    setTimeout(() => {
      this.connect();
      this.reconnectAttempts++;
    }, delay);
  }
  
  onConnect() {
    this.reconnectAttempts = 0;
    
    // Request full state sync
    this.send({ type: 'request_sync' });
  }
}
```

### 8.2 State Resync
When reconnecting mid-game:

```json
// Client request
{
  "type": "request_sync",
  "payload": {
    "lastFrame": 5000,
    "gameId": "game-uuid-123"
  }
}

// Server response
{
  "type": "state_full",
  "payload": {
    "gameId": "game-uuid-123",
    "currentFrame": 5200,
    "players": { /* full state */ },
    "replayEvents": [
      // Events from frame 5001 to 5200
    ]
  }
}
```

## 9. Binary Protocol (Optional Optimization)

For production, consider binary encoding for state updates:

```typescript
// Binary state packet structure
// [header][player_count][player_data...]

interface BinaryStatePacket {
  header: {
    magic: uint8;        // 0x54 'T'
    version: uint8;      // Protocol version
    sequence: uint32;    // Sequence number
    timestamp: uint32;   // Unix timestamp
    flags: uint8;        // Compression, etc.
  };
  playerData: BinaryPlayerData[];
}

// Compression: Use delta encoding + run-length for boards
```

## 10. Error Codes

| Code | Description | Action |
|------|-------------|--------|
| `AUTH_FAILED` | Invalid or expired token | Re-authenticate |
| `GAME_NOT_FOUND` | Game doesn't exist | Check game ID |
| `GAME_FULL` | Maximum players reached | Join different game |
| `ALREADY_IN_GAME` | Player in another game | Leave current game |
| `INVALID_MOVE` | Illegal piece movement | Sync state |
| `RATE_LIMITED` | Too many messages | Slow down |
| `SERVER_ERROR` | Internal server error | Retry |

---

**Next**: See [Database Schema](database-schema.md) for data persistence specs.
