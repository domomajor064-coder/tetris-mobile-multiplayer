# Tetris Mobile Multiplayer - System Architecture

## 1. Overview

### 1.1 Design Goals
- **Mobile-First**: Optimize for touch interfaces and small screens
- **Low Latency**: <100ms game state synchronization
- **Scalable**: Support 10,000+ concurrent multiplayer matches
- **Reliable**: 99.9% uptime with graceful degradation
- **Secure**: Encrypted communications, anti-cheat measures

### 1.2 Core Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        SYSTEM ARCHITECTURE                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────┐    ┌─────────────┐    ┌─────────────────────┐ │
│  │   CLIENT    │    │    PROXY    │    │      BACKEND        │ │
│  │   LAYER     │◄──►│    LAYER    │◄──►│      LAYER          │ │
│  │             │    │             │    │                     │ │
│  │ • React App │    │ • Nginx     │    │ • Game Servers      │ │
│  │ • Canvas    │    │ • SSL/TLS   │    │ • Matchmaking       │ │
│  │ • WebSocket │    │ • WSS Proxy │    │ • API Gateway       │ │
│  │ • PWA       │    │ • Load Bal  │    │ • Message Queue     │ │
│  └─────────────┘    └─────────────┘    └─────────────────────┘ │
│         │                  │                      │             │
│         └──────────────────┴──────────────────────┘             │
│                                    │                            │
│                           ┌────────┴────────┐                   │
│                           │   DATA LAYER    │                   │
│                           │                 │                   │
│                           │ • PostgreSQL    │                   │
│                           │ • Redis Cache   │                   │
│                           │ • S3/MinIO      │                   │
│                           └─────────────────┘                   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 2. Client Architecture

### 2.1 Frontend Stack

```typescript
// Tech Stack
- Framework: React 18 with TypeScript
- State: Zustand (lightweight) + React Query
- Rendering: Canvas API with OffscreenCanvas for workers
- Styling: TailwindCSS with mobile-first breakpoints
- Build: Vite with PWA plugin
- Testing: Vitest + Playwright
```

### 2.2 Module Structure

```
frontend/mobile-client/
├── src/
│   ├── components/
│   │   ├── GameBoard/           # Main game canvas
│   │   ├── PiecePreview/        # Next piece display
│   │   ├── HoldPiece/           # Hold piece display
│   │   ├── ScoreBoard/          # Score, level, lines
│   │   ├── TouchControls/       # Virtual D-pad/buttons
│   │   ├── MultiplayerHUD/      # Opponent boards (ghost)
│   │   ├── Matchmaking/         # Queue status, timer
│   │   └── Menus/               # Main, pause, settings
│   ├── engine/
│   │   ├── TetrisEngine.ts      # Core game logic
│   │   ├── PieceGenerator.ts    # Bag randomizer (7-bag)
│   │   ├── CollisionDetector.ts # Board collision
│   │   ├── LineClearer.ts       # Line clearing logic
│   │   ├── ScoringSystem.ts     # Score calculation
│   │   └── LevelManager.ts      # Level progression
│   ├── network/
│   │   ├── WebSocketClient.ts   # Socket.io wrapper
│   │   ├── StateSync.ts         # Client-side prediction
│   │   ├── LagCompensation.ts   # Input buffering
│   │   └── Reconnection.ts      # Auto-reconnect logic
│   ├── input/
│   │   ├── TouchHandler.ts      # Touch gestures
│   │   ├── GestureRecognizer.ts # Swipe, tap, hold
│   │   ├── VirtualButtons.ts    # On-screen controls
│   │   └── HapticFeedback.ts    # Vibration API
│   ├── multiplayer/
│   │   ├── GhostBoard.ts        # Render opponent boards
│   │   ├── AttackSender.ts      # Send garbage lines
│   │   ├── AttackReceiver.ts    # Receive garbage lines
│   │   └── ComboTracker.ts      # Combo/Back-to-back
│   └── utils/
│       ├── MobileDetector.ts
│       ├── LocalStorage.ts
│       └── AudioManager.ts
```

### 2.3 Game Engine Design

```typescript
// Core engine runs at 60 FPS
interface TetrisEngine {
  // Board state
  board: number[][];           // 10x20 grid, 0=empty, 1-7=piece types
  currentPiece: ActivePiece;   // Current falling piece
  holdPiece: PieceType | null; // Held piece
  nextQueue: PieceType[];      // Next 5 pieces (bag system)
  
  // Game state
  score: number;
  lines: number;
  level: number;
  combo: number;
  backToBack: boolean;
  
  // Timing
  gravity: number;             // Drop speed (ms per row)
  lockDelay: number;           // Time before piece locks
  
  // Methods
  update(deltaTime: number): void;
  move(direction: 'left' | 'right'): boolean;
  rotate(direction: 'cw' | 'ccw'): boolean;
  softDrop(): void;
  hardDrop(): DropResult;
  hold(): boolean;
}

// Piece definitions
const PIECES: Record<PieceType, PieceShape> = {
  I: { shape: [[1,1,1,1]], color: '#00f0f0', spawn: [3, 0] },
  O: { shape: [[1,1],[1,1]], color: '#f0f000', spawn: [4, 0] },
  T: { shape: [[0,1,0],[1,1,1]], color: '#a000f0', spawn: [3, 0] },
  S: { shape: [[0,1,1],[1,1,0]], color: '#00f000', spawn: [3, 0] },
  Z: { shape: [[1,1,0],[0,1,1]], color: '#f00000', spawn: [3, 0] },
  J: { shape: [[1,0,0],[1,1,1]], color: '#0000f0', spawn: [3, 0] },
  L: { shape: [[0,0,1],[1,1,1]], color: '#f0a000', spawn: [3, 0] },
};
```

## 3. Backend Architecture

### 3.1 Game Server

```typescript
// Fastify + Socket.io server
interface GameServer {
  // HTTP Routes
  app: FastifyInstance;
  
  // WebSocket Server
  io: SocketIOServer;
  
  // Game rooms
  rooms: Map<string, GameRoom>;
  
  // Services
  matchmaking: MatchmakingService;
  stateManager: StateManager;
  antiCheat: AntiCheatService;
}

// Game Room (1 match)
interface GameRoom {
  id: string;
  mode: '1v1' | 'ffa4' | 'team2v2';
  players: Map<string, PlayerState>;
  gameState: 'waiting' | 'countdown' | 'playing' | 'finished';
  startTime: number;
  endTime: number | null;
  winner: string | null;
  
  // Sync
  broadcast(event: string, data: any): void;
  syncState(): void;
}
```

### 3.2 Matchmaking Service

```typescript
interface MatchmakingService {
  // Queues
  queues: {
    '1v1': PriorityQueue<Player>;
    'ffa4': PriorityQueue<Player>;
    'team2v2': PriorityQueue<Player>;
  };
  
  // ELO-based matching
  findMatch(player: Player, mode: GameMode): Promise<Match>;
  
  // Rating calculation
  calculateElo(winner: Player, loser: Player): EloChange;
}

// Matchmaking algorithm
class SkillBasedMatchmaking {
  // Wait time vs skill range tradeoff
  findOpponents(player: Player, mode: GameMode): Player[] {
    const waitTime = Date.now() - player.queueStartTime;
    const skillRange = this.expandRange(waitTime);
    
    return this.searchInRange(player.elo, skillRange, mode);
  }
  
  private expandRange(waitTime: number): number {
    // Start with ±100 ELO, expand by 50 every 10 seconds
    return 100 + Math.floor(waitTime / 10000) * 50;
  }
}
```

### 3.3 State Synchronization

```typescript
// Authoritative server with client prediction
interface StateSync {
  // Server is authoritative
  authoritativeState: GameState;
  
  // Client inputs buffered
  inputBuffer: Map<string, Input[]>;
  
  // Sync strategy
  syncRate: number;  // Send state 20 times/sec (50ms)
  
  // Methods
  processInput(playerId: string, input: Input): void;
  reconcileState(): void;
  broadcastDelta(): void;
}

// Delta compression for network efficiency
interface StateDelta {
  timestamp: number;
  boardDiff: BoardChange[];      // Only changed cells
  piecePositions: PiecePos[];    // Current piece positions
  scores: ScoreUpdate[];         // Score changes
  attacks: AttackEvent[];        // Garbage line sends
}
```

## 4. Database Design

### 4.1 PostgreSQL Schema

```sql
-- Users table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255),
    created_at TIMESTAMP DEFAULT NOW(),
    last_login TIMESTAMP,
    country_code CHAR(2)
);

-- Player stats with ELO
CREATE TABLE player_stats (
    user_id UUID PRIMARY KEY REFERENCES users(id),
    elo_rating INTEGER DEFAULT 1200,
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    total_score BIGINT DEFAULT 0,
    max_combo INTEGER DEFAULT 0,
    play_time_minutes INTEGER DEFAULT 0,
    rank_title VARCHAR(50) DEFAULT 'Beginner'
);

-- Game sessions
CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    mode VARCHAR(20) NOT NULL,  -- '1v1', 'ffa4', 'team2v2', 'solo'
    status VARCHAR(20) NOT NULL, -- 'waiting', 'playing', 'finished'
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    winner_id UUID REFERENCES users(id),
    game_data JSONB  -- Full replay data
);

-- Game participants
CREATE TABLE game_players (
    game_id UUID REFERENCES games(id),
    user_id UUID REFERENCES users(id),
    team INTEGER,  -- For team modes
    final_score INTEGER,
    lines_cleared INTEGER,
    pieces_placed INTEGER,
    attacks_sent INTEGER,
    attacks_received INTEGER,
    placement INTEGER,  -- 1st, 2nd, 3rd, 4th
    PRIMARY KEY (game_id, user_id)
);

-- Level progression (single player)
CREATE TABLE level_progress (
    user_id UUID REFERENCES users(id),
    level INTEGER NOT NULL,
    high_score INTEGER DEFAULT 0,
    stars_earned INTEGER DEFAULT 0,  -- 0-3 stars per level
    completed_at TIMESTAMP,
    attempts INTEGER DEFAULT 0,
    PRIMARY KEY (user_id, level)
);

-- Leaderboards (materialized view, updated hourly)
CREATE MATERIALIZED VIEW leaderboard_1v1 AS
SELECT 
    user_id,
    username,
    elo_rating,
    games_won,
    games_played,
    ROW_NUMBER() OVER (ORDER BY elo_rating DESC) as rank
FROM player_stats ps
JOIN users u ON ps.user_id = u.id
WHERE games_played >= 10;
```

### 4.2 Redis Cache Structure

```
# Active games (TTL: 1 hour)
HSET game:{gameId} state "playing" players "[...]" startTime "..."

# Player sessions (TTL: 2 hours)
HSET session:{userId} socketId "..." gameId "..." lastPing "..."

# Matchmaking queues
ZADD queue:1v1 {eloScore} {userId}
ZADD queue:ffa4 {eloScore} {userId}

# Rate limiting
INCR ratelimit:{ip}
EXPIRE ratelimit:{ip} 60

# Leaderboard cache (updated every 5 min)
ZADD lb:1v1 {elo} {userId}
ZREVRANGE lb:1v1 0 99 WITHSCORES
```

## 5. Level System Design

### 5.1 Single Player Levels (50 Total)

```typescript
interface LevelConfig {
  id: number;
  name: string;
  objective: 'score' | 'lines' | 'survival' | 'sprint';
  target: number;           // Score target, lines to clear, etc.
  timeLimit?: number;       // Seconds (for sprint modes)
  startingLevel: number;    // Initial speed
  garbageRate?: number;     // For survival modes
  obstacles?: Obstacle[];   // Special board configurations
  restrictions?: string[];  // e.g., ['no_hold', 'no_preview']
  rewards: {
    stars: number;          // 1-3 based on performance
    unlocks?: number[];     // Levels unlocked
    title?: string;         // Achievement title
  };
}

// Level progression
const LEVELS: LevelConfig[] = [
  // Tutorial (1-5)
  { id: 1, name: "First Steps", objective: "lines", target: 10, startingLevel: 1 },
  { id: 2, name: "Clear 4", objective: "lines", target: 20, startingLevel: 1 },
  
  // Beginner (6-15)
  { id: 6, name: "Speed Up", objective: "score", target: 10000, startingLevel: 5 },
  
  // Intermediate (16-30)
  { id: 16, name: "Sprint 40L", objective: "sprint", target: 40, timeLimit: 120, startingLevel: 1 },
  
  // Advanced (31-45)
  { id: 31, name: "Survival", objective: "survival", target: 150, garbageRate: 0.5, startingLevel: 10 },
  
  // Expert (46-50)
  { id: 50, name: "Tetris Master", objective: "score", target: 500000, startingLevel: 15, restrictions: ['no_hold'] },
];
```

### 5.2 Gravity/Speed Curve

```typescript
// Classic Tetris gravity formula
function getGravity(level: number): number {
  // Frames per grid cell (at 60 FPS)
  // Level 1: 48 frames (0.8s per row)
  // Level 10: 6 frames (0.1s per row)
  // Level 15+: 1 frame (instant drop)
  
  if (level >= 15) return 1;
  if (level >= 10) return 6;
  if (level >= 5) return 12;
  return Math.max(1, 48 - (level - 1) * 4);
}

// In milliseconds per row
function getDropSpeedMs(level: number): number {
  const frames = getGravity(level);
  return (frames / 60) * 1000;  // Convert to ms
}
```

## 6. Reverse Proxy Configuration

### 6.1 Nginx Config

```nginx
# /tetris location with WebSocket support
server {
    listen 443 ssl http2;
    server_name tetris.yourdomain.com;
    
    # SSL certificates
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    # Static files (frontend)
    location /tetris/ {
        alias /var/www/tetris/frontend/dist/;
        try_files $uri $uri/ /tetris/index.html;
        
        # Cache static assets
        location ~* \.(js|css|png|jpg|svg|woff|woff2)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # API routes
    location /tetris/api/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # WebSocket for real-time game
    location /tetris/ws/ {
        proxy_pass http://localhost:3002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        
        # WebSocket timeouts
        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
    
    # Rate limiting
    limit_req_zone $binary_remote_addr zone=tetris:10m rate=10r/s;
    limit_req zone=tetris burst=20 nodelay;
}
```

### 6.2 Path Mapping

| URL Path | Destination | Purpose |
|----------|-------------|---------|
| `/tetris/` | Frontend static files | Game UI |
| `/tetris/api/*` | Backend API (port 3001) | REST API |
| `/tetris/ws/*` | WebSocket server (port 3002) | Real-time game |
| `/tetris/health` | Health check endpoint | Monitoring |

## 7. Scaling Strategy

### 7.1 Horizontal Scaling

```
┌─────────────────────────────────────────────────────────┐
│                      Load Balancer                       │
│                     (nginx/HAProxy)                      │
└──────────────┬────────────────────────────┬─────────────┘
               │                            │
    ┌──────────▼──────────┐      ┌─────────▼──────────┐
    │   Game Server 1     │      │   Game Server 2    │
    │   (Port 3002)       │      │   (Port 3002)      │
    │   Rooms: A-M        │      │   Rooms: N-Z       │
    └──────────┬──────────┘      └─────────┬──────────┘
               │                            │
               └────────────┬───────────────┘
                            │
                   ┌────────▼────────┐
                   │   Redis PubSub  │
                   │  (Cross-server   │
                   │   messaging)     │
                   └─────────────────┘
```

### 7.2 Room Sharding

- Use consistent hashing on `roomId` to assign rooms to servers
- Redis PubSub for cross-server messaging
- Sticky sessions for WebSocket connections

## 8. Security Considerations

### 8.1 Anti-Cheat Measures

```typescript
class AntiCheatService {
  // Validate moves on server
  validateMove(playerId: string, move: Move, state: GameState): boolean {
    // Check if move is physically possible
    // Verify timing (no speed hacks)
    // Ensure piece position is valid
  }
  
  // Detect impossible scores
  detectScoreHack(player: Player, score: number, time: number): boolean {
    const maxPossibleScore = this.calculateMaxScore(time);
    return score > maxPossibleScore * 1.1; // 10% tolerance
  }
  
  // Rate limit inputs
  checkInputRate(playerId: string): boolean {
    // Max 10 inputs per second (human limit)
  }
}
```

### 8.2 DDoS Protection

- Rate limiting: 10 req/s per IP
- WebSocket connection limits: 5 per IP
- Challenge-response for suspicious activity
- CloudFlare or similar for edge protection

---

## Appendix: File Structure

```
docs/
├── architecture.md          # This file
├── api-design.md            # REST API specs
├── websocket-protocol.md    # WebSocket message formats
├── database-schema.md       # Full SQL schema
└── mobile-ui-design.md      # UI mockups and flows
```
