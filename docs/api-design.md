# Tetris Mobile Multiplayer - API Design

## 1. API Overview

- **Base URL**: `/tetris/api/v1`
- **Authentication**: JWT Bearer token
- **Content-Type**: `application/json`
- **Rate Limit**: 100 requests/minute per user

## 2. Authentication

### 2.1 Register
```http
POST /auth/register
Content-Type: application/json

{
  "username": "tetris_master",
  "email": "user@example.com",
  "password": "securePassword123",
  "country": "US"
}

Response 201 Created:
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "tetris_master",
    "email": "user@example.com",
    "createdAt": "2024-01-15T10:30:00Z"
  },
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}
```

### 2.2 Login
```http
POST /auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "securePassword123"
}

Response 200 OK:
{
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "username": "tetris_master",
    "email": "user@example.com"
  },
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 86400
}
```

### 2.3 Refresh Token
```http
POST /auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIs..."
}

Response 200 OK:
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "expiresIn": 86400
}
```

## 3. User Endpoints

### 3.1 Get Current User
```http
GET /users/me
Authorization: Bearer {token}

Response 200 OK:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "tetris_master",
  "email": "user@example.com",
  "country": "US",
  "stats": {
    "elo": 1450,
    "gamesPlayed": 150,
    "gamesWon": 89,
    "winRate": 59.3,
    "totalScore": 12345678,
    "maxCombo": 12,
    "playTimeHours": 45,
    "rankTitle": "Diamond"
  },
  "preferences": {
    "das": 167,        // Delayed Auto Shift (ms)
    "arr": 33,         // Auto Repeat Rate (ms)
    "sdf": 6,          // Soft Drop Factor
    "soundEnabled": true,
    "musicEnabled": true,
    "ghostPiece": true,
    "swipeControls": true
  }
}
```

### 3.2 Update User Profile
```http
PATCH /users/me
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "new_name",
  "country": "CA",
  "preferences": {
    "das": 150,
    "arr": 30
  }
}

Response 200 OK:
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "new_name",
  "country": "CA",
  "preferences": {
    "das": 150,
    "arr": 30
  }
}
```

### 3.3 Get User Stats
```http
GET /users/{userId}/stats

Response 200 OK:
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "username": "tetris_master",
  "elo": 1450,
  "rank": 42,
  "gamesPlayed": 150,
  "gamesWon": 89,
  "winRate": 59.3,
  "recentForm": ["W", "W", "L", "W", "W"],  // Last 5 games
  "achievements": ["First Win", "10x Combo", "Speed Demon"]
}
```

## 4. Game Endpoints

### 4.1 Get Game Modes
```http
GET /game/modes

Response 200 OK:
{
  "modes": [
    {
      "id": "solo_classic",
      "name": "Classic",
      "type": "single",
      "description": "Endless mode with increasing speed",
      "maxPlayers": 1
    },
    {
      "id": "solo_levels",
      "name": "Level Mode",
      "type": "single",
      "description": "Complete 50 challenging levels",
      "maxPlayers": 1
    },
    {
      "id": "multi_1v1",
      "name": "1v1 Battle",
      "type": "multiplayer",
      "description": "Head-to-head battle",
      "maxPlayers": 2,
      "minElo": 0
    },
    {
      "id": "multi_ffa4",
      "name": "4-Player FFA",
      "type": "multiplayer",
      "description": "Free-for-all with 4 players",
      "maxPlayers": 4,
      "minElo": 1000
    },
    {
      "id": "multi_2v2",
      "name": "Team Battle",
      "type": "multiplayer",
      "description": "2v2 team competition",
      "maxPlayers": 4,
      "minElo": 1200
    }
  ]
}
```

### 4.2 Get Current Game
```http
GET /game/current
Authorization: Bearer {token}

Response 200 OK (if in game):
{
  "gameId": "game-uuid-123",
  "mode": "multi_1v1",
  "status": "playing",
  "players": [
    {
      "userId": "550e8400-e29b-41d4-a716-446655440000",
      "username": "tetris_master",
      "team": 1,
      "isAlive": true,
      "board": "base64-encoded-board",
      "score": 15000,
      "lines": 25,
      "level": 5
    }
  ],
  "startTime": "2024-01-15T10:30:00Z",
  "wsEndpoint": "wss://tetris.yourdomain.com/tetris/ws/game-uuid-123"
}

Response 204 No Content (if not in game)
```

### 4.3 Get Game Replay
```http
GET /games/{gameId}/replay

Response 200 OK:
{
  "gameId": "game-uuid-123",
  "mode": "multi_1v1",
  "duration": 185000,  // ms
  "players": [
    {
      "userId": "...",
      "username": "tetris_master",
      "finalScore": 25000,
      "linesCleared": 40,
      "piecesPlaced": 120,
      "attacksSent": 15,
      "maxCombo": 8
    }
  ],
  "events": [
    {"time": 0, "type": "piece_spawn", "piece": "T"},
    {"time": 1500, "type": "line_clear", "lines": 4, "combo": 1},
    {"time": 3000, "type": "attack_sent", "lines": 4, "target": "opponent-id"}
    // ... full replay data
  ],
  "winner": "550e8400-e29b-41d4-a716-446655440000"
}
```

## 5. Matchmaking Endpoints

### 5.1 Join Queue
```http
POST /matchmaking/queue
Authorization: Bearer {token}
Content-Type: application/json

{
  "mode": "multi_1v1",
  "preferredOpponents": null  // Optional: list of userIds
}

Response 200 OK:
{
  "queueId": "queue-uuid",
  "mode": "multi_1v1",
  "position": 3,
  "estimatedWait": 15,  // seconds
  "eloRange": [1400, 1500]  // Current search range
}
```

### 5.2 Get Queue Status
```http
GET /matchmaking/queue/{queueId}
Authorization: Bearer {token}

Response 200 OK (still waiting):
{
  "queueId": "queue-uuid",
  "status": "waiting",
  "position": 2,
  "estimatedWait": 10,
  "elapsedTime": 25
}

Response 200 OK (match found):
{
  "queueId": "queue-uuid",
  "status": "matched",
  "gameId": "game-uuid-456",
  "wsEndpoint": "wss://tetris.yourdomain.com/tetris/ws/game-uuid-456",
  "opponents": [
    {
      "userId": "...",
      "username": "opponent_name",
      "elo": 1475
    }
  ]
}
```

### 5.3 Leave Queue
```http
DELETE /matchmaking/queue/{queueId}
Authorization: Bearer {token}

Response 204 No Content
```

## 6. Leaderboard Endpoints

### 6.1 Get Global Leaderboard
```http
GET /leaderboards/global
Query: ?mode=1v1&page=1&limit=50

Response 200 OK:
{
  "mode": "1v1",
  "page": 1,
  "totalPages": 20,
  "totalPlayers": 1000,
  "players": [
    {
      "rank": 1,
      "userId": "...",
      "username": "tetris_god",
      "elo": 2450,
      "gamesPlayed": 500,
      "winRate": 78.5,
      "country": "JP"
    },
    {
      "rank": 2,
      "userId": "...",
      "username": "block_master",
      "elo": 2380,
      "gamesPlayed": 420,
      "winRate": 72.1,
      "country": "KR"
    }
    // ... more players
  ],
  "userRank": 42  // Current user's rank if authenticated
}
```

### 6.2 Get Country Leaderboard
```http
GET /leaderboards/country/{countryCode}
Query: ?mode=1v1&page=1

Response 200 OK:
{
  "country": "US",
  "mode": "1v1",
  "players": [...]
}
```

### 6.3 Get Friends Leaderboard
```http
GET /leaderboards/friends
Authorization: Bearer {token}

Response 200 OK:
{
  "friends": [
    {
      "rank": 1,
      "userId": "...",
      "username": "friend1",
      "elo": 1800,
      "isOnline": true
    }
  ]
}
```

## 7. Level Endpoints

### 7.1 Get All Levels
```http
GET /levels

Response 200 OK:
{
  "levels": [
    {
      "id": 1,
      "name": "First Steps",
      "objective": "lines",
      "target": 10,
      "difficulty": "beginner",
      "unlocked": true,
      "stars": 3,
      "highScore": 15000
    },
    {
      "id": 2,
      "name": "Speed Up",
      "objective": "score",
      "target": 10000,
      "difficulty": "beginner",
      "unlocked": true,
      "stars": 2,
      "highScore": 12500
    },
    {
      "id": 50,
      "name": "Tetris Master",
      "objective": "score",
      "target": 500000,
      "difficulty": "expert",
      "unlocked": false,
      "requirement": "Complete all previous levels"
    }
  ]
}
```

### 7.2 Get Level Details
```http
GET /levels/{levelId}

Response 200 OK:
{
  "id": 16,
  "name": "Sprint 40L",
  "description": "Clear 40 lines as fast as possible!",
  "objective": "sprint",
  "target": 40,
  "timeLimit": 120,
  "startingLevel": 1,
  "rewards": {
    "1_star": "Complete within time limit",
    "2_stars": "Complete within 90 seconds",
    "3_stars": "Complete within 60 seconds"
  },
  "userProgress": {
    "bestTime": 85,
    "starsEarned": 2,
    "attempts": 15,
    "completedAt": "2024-01-10T14:20:00Z"
  }
}
```

### 7.3 Submit Level Score
```http
POST /levels/{levelId}/submit
Authorization: Bearer {token}
Content-Type: application/json

{
  "score": 25000,
  "time": 75,
  "lines": 40,
  "replay": "base64-encoded-replay-data"
}

Response 200 OK:
{
  "levelId": 16,
  "score": 25000,
  "time": 75,
  "starsEarned": 3,
  "newHighScore": true,
  "rank": 150,  // Global rank for this level
  "unlocks": [17, 18]  // Newly unlocked levels
}
```

## 8. Social Endpoints

### 8.1 Get Friends List
```http
GET /friends
Authorization: Bearer {token}

Response 200 OK:
{
  "friends": [
    {
      "userId": "...",
      "username": "friend1",
      "status": "online",
      "currentGame": null,
      "lastSeen": "2024-01-15T10:30:00Z"
    },
    {
      "userId": "...",
      "username": "friend2",
      "status": "playing",
      "currentGame": "game-uuid",
      "lastSeen": "2024-01-15T10:25:00Z"
    }
  ],
  "pendingRequests": [
    {
      "userId": "...",
      "username": "new_friend",
      "sentAt": "2024-01-15T10:00:00Z"
    }
  ]
}
```

### 8.2 Send Friend Request
```http
POST /friends/request
Authorization: Bearer {token}
Content-Type: application/json

{
  "username": "friend_username"
}

Response 201 Created:
{
  "requestId": "req-uuid",
  "status": "pending",
  "recipient": {
    "userId": "...",
    "username": "friend_username"
  }
}
```

### 8.3 Invite Friend to Game
```http
POST /games/invite
Authorization: Bearer {token}
Content-Type: application/json

{
  "friendId": "friend-uuid",
  "mode": "multi_1v1",
  "message": "Let's battle!"
}

Response 201 Created:
{
  "inviteId": "invite-uuid",
  "expiresAt": "2024-01-15T10:35:00Z",
  "wsEndpoint": "wss://tetris.yourdomain.com/tetris/ws/lobby-invite-uuid"
}
```

## 9. Error Responses

### Standard Error Format
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input data",
    "details": [
      {
        "field": "username",
        "message": "Username must be between 3 and 20 characters"
      }
    ]
  }
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `AUTH_REQUIRED` | 401 | Authentication required |
| `INVALID_TOKEN` | 401 | Invalid or expired token |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `VALIDATION_ERROR` | 422 | Invalid input data |
| `RATE_LIMITED` | 429 | Too many requests |
| `QUEUE_FULL` | 503 | Matchmaking queue full |
| `ALREADY_IN_GAME` | 409 | User already in active game |

## 10. WebSocket Upgrade

Games use WebSocket for real-time communication. See [WebSocket Protocol](websocket-protocol.md) for details.

```http
GET /game/join/{gameId}
Upgrade: websocket
Connection: Upgrade
Authorization: Bearer {token}
```

---

**Next**: See [WebSocket Protocol](websocket-protocol.md) for real-time game communication specs.
