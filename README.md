# 🎮 Tetris Mobile Multiplayer

A modern, mobile-optimized Tetris game with real-time multiplayer battles, progressive levels, and seamless deployment behind a reverse proxy.

## 🌟 Features

- 📱 **Mobile-First Design**: Touch-optimized controls, responsive UI
- 🎮 **Multiple Game Modes**:
  - Single Player (Classic & Level Mode)
  - Real-time Multiplayer Battles (1v1, 4-player FFA, Team Battles)
  - Tournament Mode
- 📈 **Progressive Level System**: 50+ levels with increasing difficulty
- 🏆 **Ranking & Matchmaking**: ELO-based skill matching
- 🔄 **Real-time Sync**: WebSocket-based game state synchronization
- 🌐 **Reverse Proxy Ready**: Deploy behind nginx/Apache with WebSocket support

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Client (Mobile Browser)                   │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Game UI     │  │ Touch Input  │  │ WebSocket Client │  │
│  │  (Canvas)    │  │  Controller  │  │                  │  │
│  └──────────────┘  └──────────────┘  └──────────────────┘  │
└──────────────────────────┬──────────────────────────────────┘
                           │ HTTPS/WSS
                           ▼
┌─────────────────────────────────────────────────────────────┐
│                   Reverse Proxy (Nginx)                      │
│     Routes: /tetris/* → Backend /tetris/ws → WebSocket     │
└──────────────────────────┬──────────────────────────────────┘
                           │
           ┌───────────────┴───────────────┐
           ▼                               ▼
┌─────────────────────┐      ┌──────────────────────────────┐
│   Game Server       │      │   Matchmaking Server         │
│   (Node.js/Fastify) │      │   (Redis + WebSocket)        │
│   - Game Logic      │      │   - Queue Management         │
│   - State Sync      │      │   - Room Assignment          │
│   - Score Calc      │      │   - ELO Rating               │
└──────────┬──────────┘      └──────────────┬───────────────┘
           │                                │
           └───────────────┬────────────────┘
                           ▼
              ┌────────────────────┐
              │     Database       │
              │  (PostgreSQL +     │
              │   Redis Cache)     │
              └────────────────────┘
```

## 📁 Project Structure

```
tetris-mobile-multiplayer/
├── 📂 docs/
│   ├── architecture.md       # System architecture details
│   ├── api-design.md         # REST API specifications
│   ├── websocket-protocol.md # WebSocket message specs
│   ├── database-schema.md    # Database design
│   └── mobile-ui-design.md   # UI/UX design guidelines
├── 📂 frontend/
│   └── mobile-client/        # React/Vue mobile app
├── 📂 backend/
│   ├── game-server/          # Core game logic server
│   └── matchmaking/          # Matchmaking service
├── 📂 api/
│   └── openapi.yaml          # OpenAPI specification
├── 📂 database/
│   ├── migrations/           # SQL migrations
│   └── seed-data/            # Initial data
└── 📂 deployment/
    ├── docker-compose.yml    # Local development
    ├── nginx.conf            # Reverse proxy config
    └── k8s/                  # Kubernetes manifests
```

## 🚀 Quick Start

### Local Development

```bash
# Clone repository
git clone https://github.com/domomajor064-coder/tetris-mobile-multiplayer.git
cd tetris-mobile-multiplayer

# Start with Docker Compose
docker-compose -f deployment/docker-compose.yml up

# Access game
open http://localhost:3000/tetris
```

### Production Deployment (Behind Reverse Proxy)

```bash
# Deploy with reverse proxy
cd deployment
./deploy.sh --proxy --ssl --domain tetris.yourdomain.com
```

## 📱 Mobile Controls

| Gesture | Action |
|---------|--------|
| Tap | Rotate piece |
| Swipe Left/Right | Move piece |
| Swipe Down | Soft drop |
| Swipe Up | Hard drop |
| Hold | Store piece |
| Two-finger tap | Pause |

## 🔧 Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18 + TypeScript + Canvas API |
| Backend | Node.js + Fastify + Socket.io |
| Database | PostgreSQL 15 + Redis 7 |
| Real-time | WebSocket (Socket.io) |
| Reverse Proxy | Nginx with WebSocket support |
| Deployment | Docker + Docker Compose |

## 📖 Documentation

- [Architecture Design](docs/architecture.md)
- [API Design](docs/api-design.md)
- [WebSocket Protocol](docs/websocket-protocol.md)
- [Database Schema](docs/database-schema.md)
- [Mobile UI Design](docs/mobile-ui-design.md)

## 📝 License

MIT License - See [LICENSE](LICENSE) for details.

---

Built with ❤️ for mobile Tetris enthusiasts.
