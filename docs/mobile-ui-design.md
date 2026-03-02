# Tetris Mobile Multiplayer - Mobile UI Design

## 1. Design Principles

### 1.1 Mobile-First Approach
- **Touch-Optimized**: All interactions designed for fingers, not mouse
- **Portrait Primary**: Optimized for portrait mode, landscape supported
- **Performance**: 60 FPS rendering, <100ms input response
- **Accessibility**: Support for screen readers, dynamic text sizing

### 1.2 Visual Style
```css
/* Design System */
--color-primary: #00D9FF;        /* Cyan - Tetris I piece */
--color-secondary: #FF0055;      /* Pink accent */
--color-background: #0A0A0F;     /* Dark navy */
--color-surface: #151520;        /* Card backgrounds */
--color-text: #FFFFFF;
--color-text-secondary: #8B8B9E;

/* Typography */
--font-primary: 'Inter', sans-serif;
--font-mono: 'JetBrains Mono', monospace;  /* For numbers */

/* Spacing (8px base) */
--space-xs: 4px;
--space-sm: 8px;
--space-md: 16px;
--space-lg: 24px;
--space-xl: 32px;

/* Touch targets */
--touch-min: 44px;  /* Apple's HIG minimum */
--touch-comfortable: 56px;
```

## 2. Screen Designs

### 2.1 Main Menu

```
┌─────────────────────────────┐
│  ≡  🎮 TETRIS         👤    │  ← Header (hamburger, title, profile)
├─────────────────────────────┤
│                             │
│    ╔═══════════════╗        │
│    ║  T E T R I S  ║        │  ← Animated logo
│    ╚═══════════════╝        │
│                             │
│  ┌─────────────────────┐    │
│  │  ▶  Quick Play      │    │  ← Primary CTA
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  🏆  Multiplayer    │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  🎯  Level Mode     │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  📊  Leaderboard    │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────────────────┐    │
│  │  ⚙️  Settings       │    │
│  └─────────────────────┘    │
│                             │
├─────────────────────────────┤
│  🏆 1,450 ELO  |  💎 Rank   │  ← Status bar
└─────────────────────────────┘
```

**Interactions:**
- Swipe left → Leaderboard
- Swipe right → Profile
- Pull down → Refresh stats

### 2.2 Game Board (Portrait)

```
┌─────────────────────────────┐
│  ←  PAUSE  |  Level 5  |  👤 │  ← Top bar
├─────────────────────────────┤
│  NEXT    │                  │
│  ┌──┐    │                  │
│  │██│    │   GAME BOARD     │
│  │██│    │   (10x20 grid)   │
│  └──┘    │                  │
│          │                  │
│  HOLD    │                  │
│  ┌──┐    │                  │
│  │  │    │                  │
│  └──┘    │                  │
│          │                  │
├──────────┴──────────────────┤
│  Score: 15,000              │
│  Lines: 25   |   Combo: x3  │
├─────────────────────────────┤
│     ATTACK QUEUE (if MP)    │
│  ┌─┬─┬─┬─┬─┬─┬─┬─┬─┐        │
│  │█│ │ │ │█│ │ │ │ │        │  ← Incoming garbage
│  └─┴─┴─┴─┴─┴─┴─┴─┴─┘        │
├─────────────────────────────┤
│                             │
│     ┌───┐ ┌───┐ ┌───┐      │
│     │ ◀ │ │ ▼ │ │ ▶ │      │  ← D-Pad
│     └───┘ └───┘ └───┘      │
│                             │
│  ┌───┐     ┌───┐  ┌───┐    │
│  │ROT│     │HLD│  │DRP│    │  ← Actions
│  └───┘     └───┘  └───┘    │
│                             │
└─────────────────────────────┘
```

**Touch Controls:**
- **D-Pad**: Swipe gestures preferred
  - Tap left/right: Move
  - Tap down: Soft drop
  - Swipe down: Hard drop
- **ROT**: Rotate piece (CW)
  - Long press: Rotate CCW
- **HLD**: Hold piece
- **DRP**: Hard drop

**Gesture Controls (Alternative):**
```
┌─────────────────────────────┐
│                             │
│        GAME BOARD           │
│                             │
│   ┌─────────────────────┐   │
│   │                     │   │
│   │   Swipe ← → = Move  │   │
│   │                     │   │
│   │   Swipe ↓ = Drop    │   │
│   │                     │   │
│   │   Tap = Rotate      │   │
│   │                     │   │
│   │   Hold = Hold piece │   │
│   └─────────────────────┘   │
│                             │
└─────────────────────────────┘
```

### 2.3 Multiplayer Battle View

```
┌─────────────────────────────┐
│  🔴 LIVE  |  1v1  |  2:45   │  ← Match info
├─────────────────────────────┤
│  ┌───────┐  │  ┌───────┐   │
│  │ YOU   │  │  │OPPONENT│   │
│  │██████ │  │  │░░░░░░░ │   │  ← Ghost boards
│  │██████ │  │  │░░░░░░░ │   │     (simplified)
│  │██████ │  │  │░░░░░░░ │   │
│  └───────┘  │  └───────┘   │
│             │               │
│  ┌──────────┴────────────┐  │
│  │      YOUR BOARD       │  │  ← Full board
│  │                       │  │
│  └───────────────────────┘  │
│                             │
│  YOUR STATS  vs  OPPONENT   │
│  12 attacks     8 attacks   │
│  Combo: x4      Combo: x2   │
├─────────────────────────────┤
│        [CONTROLS]           │
└─────────────────────────────┘
```

**Multiplayer Features:**
- Ghost boards: Show opponent's simplified board (10x10 thumbnail)
- Attack animations: Visual lines flying between boards
- Combo indicators: Highlight when combo building
- KO animations: When opponent is eliminated

### 2.4 Matchmaking Screen

```
┌─────────────────────────────┐
│  ←  MATCHMAKING             │
├─────────────────────────────┤
│                             │
│     ┌───────────────┐       │
│     │               │       │
│     │    [Spinner]  │       │  ← Animated spinner
│     │               │       │
│     └───────────────┘       │
│                             │
│    Finding opponent...      │
│                             │
│    Estimated wait: 15s      │
│                             │
│    ELO Range: 1400-1500     │
│                             │
│    ┌─────────────────┐      │
│    │  ○ 1v1 Battle   │      │  ← Mode selector
│    │  ○ 4-Player FFA │      │
│    │  ● 2v2 Team     │      │
│    └─────────────────┘      │
│                             │
│    ┌─────────────────┐      │
│    │    CANCEL       │      │
│    └─────────────────┘      │
│                             │
└─────────────────────────────┘
```

### 2.5 Level Select

```
┌─────────────────────────────┐
│  ←  LEVEL MODE          🏆  │
├─────────────────────────────┤
│  Progress: 16/50 ★★★        │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐    │
│  │ ▶ 16. Sprint 40L    │    │  ← Current level
│  │    ⭐⭐  Best: 85s   │    │
│  │    [PLAY]           │    │
│  └─────────────────────┘    │
│                             │
│  ┌─────────┐ ┌─────────┐    │
│  │ 15. ✓✓✓│ │ 17. 🔒  │    │  ← Adjacent levels
│  │ Speed   │ │ Survival│    │
│  │    ★★★  │ │ 🔒🔒🔒  │    │
│  └─────────┘ └─────────┘    │
│                             │
│  [Scrollable level grid]    │
│  ┌──┬──┬──┬──┐              │
│  │01│02│03│04│              │
│  │★★│★★│★★│★☆│              │
│  ├──┼──┼──┼──┤              │
│  │05│06│07│08│              │
│  │★★│★☆│☆☆│🔒 │              │
│  └──┴──┴──┴──┘              │
│                             │
└─────────────────────────────┘
```

### 2.6 Leaderboard

```
┌─────────────────────────────┐
│  🏆  LEADERBOARD       🔍   │
├─────────────────────────────┤
│  ┌──────┬──────┬──────┐     │
│  │GLOBAL│COUNTRY│FRIENDS│    │  ← Tabs
│  └──────┴──────┴──────┘     │
├─────────────────────────────┤
│                             │
│  #1  🇯🇵 TetrisGod    2450   │
│  #2  🇰🇷 BlockMaster  2380   │
│  #3  🇺🇸 DropKing     2290   │
│      ...                    │
│  ─────────────────────      │
│  #42 👤 You          1450   │  ← Current user
│  ─────────────────────      │
│  #43 🇩🇪 StackPro     1445   │
│  #44 🇫🇷 LineClearer  1440   │
│                             │
│  [Load more...]             │
│                             │
└─────────────────────────────┘
```

### 2.7 Settings

```
┌─────────────────────────────┐
│  ←  SETTINGS                │
├─────────────────────────────┤
│  🎮 GAMEPLAY                │
│  ─────────────────────────  │
│  DAS              [167ms] > │
│  ARR               [33ms] > │
│  Soft Drop          [6x]  > │
│                             │
│  Ghost Piece        [✓]     │
│  Grid Lines         [✓]     │
│  Piece Preview      [5]   > │
│                             │
│  🎵 AUDIO                   │
│  ─────────────────────────  │
│  Sound Effects    [===⦀]    │
│  Music            [==⦀⦀]    │
│                             │
│  👆 CONTROLS                │
│  ─────────────────────────  │
│  Swipe Controls     [✓]     │
│  Button Controls    [ ]     │
│  Vibration          [✓]     │
│                             │
│  🔔 NOTIFICATIONS           │
│  ─────────────────────────  │
│  Friend Online      [✓]     │
│  Game Invites       [✓]     │
│                             │
└─────────────────────────────┘
```

## 3. Animations & Transitions

### 3.1 Line Clear Animation
```
Duration: 300ms

Frame 0:    Normal board
Frame 1-3:  Flashing lines (white)
Frame 4-6:  Lines disappear (shrink height)
Frame 7-10: Lines above fall down
Frame 11:   New pieces visible
```

### 3.2 Piece Lock Animation
```
Duration: 150ms

Effect: Piece flashes once when locking
Color: White flash at 50% opacity
Easing: ease-out
```

### 3.3 Attack Animation (Multiplayer)
```
Duration: 500ms

1. Warning indicator at bottom (red bars)
2. Lines "push up" from bottom
3. Screen shake slightly
4. Particles emit from attack origin
```

### 3.4 Menu Transitions
```
Page transitions: 200ms
Easing: cubic-bezier(0.4, 0, 0.2, 1)
Effect: Slide + fade
```

## 4. Responsive Breakpoints

```css
/* Mobile portrait (default) */
@media (max-width: 480px) {
  --board-scale: 1;
  --controls-height: 180px;
}

/* Mobile landscape */
@media (min-width: 481px) and (max-width: 768px) {
  --board-scale: 0.9;
  --controls-side: true;  /* Move controls to side */
}

/* Tablet */
@media (min-width: 769px) and (max-width: 1024px) {
  --board-scale: 1.2;
  --side-panel: true;  /* Show stats on side */
}
```

## 5. Canvas Rendering Specs

### 5.1 Game Board
```typescript
const BOARD_CONFIG = {
  // Dimensions
  cols: 10,
  rows: 20,
  cellSize: 24,  // CSS pixels, scaled by DPR
  
  // Visual
  gridLineWidth: 1,
  gridLineColor: 'rgba(255,255,255,0.1)',
  ghostOpacity: 0.3,
  
  // Animation
  lockFlashDuration: 150,
  lineClearDuration: 300,
  
  // Colors (standard Tetris)
  pieces: {
    I: '#00f0f0',
    O: '#f0f000', 
    T: '#a000f0',
    S: '#00f000',
    Z: '#f00000',
    J: '#0000f0',
    L: '#f0a000'
  }
};
```

### 5.2 Performance Targets
- Render loop: 60 FPS (16.67ms frame budget)
- Input latency: < 16ms (1 frame)
- State sync: 20 Hz (50ms)
- Memory usage: < 50MB for game

## 6. Accessibility

### 6.1 Screen Reader Support
```html
<!-- Board announced as -->
<div role="region" aria-label="Tetris game board, 10 columns, 20 rows">
  <div aria-live="polite" aria-atomic="true">
    Current piece: T at column 5, row 12
  </div>
</div>

<!-- Controls announced as -->
<button aria-label="Rotate piece clockwise">
  ROT
</button>
```

### 6.2 Color Blindness Support
```css
/* Pattern overlays for pieces */
.piece-I { border-top: 2px dashed; }
.piece-O { border: 2px dotted; }
.piece-T { background: repeating-linear-gradient(...); }
/* etc. */
```

### 6.3 Motion Preferences
```css
@media (prefers-reduced-motion: reduce) {
  .line-clear-animation { display: none; }
  .page-transition { opacity: 1; }
}
```

## 7. Haptic Feedback

```typescript
// Vibration patterns
const HAPTIC = {
  pieceLock: [10],           // Short pulse
  lineClear: [20, 30, 20],   // Double pulse
  tetris: [50, 100, 50],     // Strong double
  attackReceived: [30, 50, 30, 50, 30],  // Warning pattern
  gameOver: [100, 200, 100, 200, 300],   // Long pattern
};

// Usage
if (navigator.vibrate && preferences.vibration) {
  navigator.vibrate(HAPTIC.lineClear);
}
```

---

**Next**: See [Deployment](deployment/) for production setup.
