-- Tetris Mobile Multiplayer - Database Schema
-- PostgreSQL 15+

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- USERS & AUTHENTICATION
-- ============================================

CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    username VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    country_code CHAR(2),
    avatar_url VARCHAR(500),
    
    -- Account status
    is_active BOOLEAN DEFAULT true,
    is_verified BOOLEAN DEFAULT false,
    
    -- Timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_login TIMESTAMP WITH TIME ZONE,
    
    -- Constraints
    CONSTRAINT username_format CHECK (username ~ '^[a-zA-Z0-9_]{3,20}$'),
    CONSTRAINT email_format CHECK (email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')
);

-- User preferences (1:1 with users)
CREATE TABLE user_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- Game settings
    das INTEGER DEFAULT 167,           -- Delayed Auto Shift (ms)
    arr INTEGER DEFAULT 33,            -- Auto Repeat Rate (ms)
    sdf INTEGER DEFAULT 6,             -- Soft Drop Factor
    
    -- Display settings
    ghost_piece BOOLEAN DEFAULT true,
    grid_visible BOOLEAN DEFAULT true,
    piece_preview_count INTEGER DEFAULT 5,
    
    -- Audio settings
    sound_enabled BOOLEAN DEFAULT true,
    music_enabled BOOLEAN DEFAULT true,
    sound_volume INTEGER DEFAULT 80,   -- 0-100
    music_volume INTEGER DEFAULT 60,   -- 0-100
    
    -- Control settings
    swipe_controls BOOLEAN DEFAULT true,
    button_controls BOOLEAN DEFAULT false,
    vibration_enabled BOOLEAN DEFAULT true,
    
    -- Notification settings
    notify_friend_online BOOLEAN DEFAULT true,
    notify_game_invite BOOLEAN DEFAULT true,
    notify_daily_digest BOOLEAN DEFAULT true
);

-- Refresh tokens for authentication
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    device_info VARCHAR(255),
    ip_address INET
);

-- Email verification codes
CREATE TABLE email_verifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    code VARCHAR(10) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    attempts INTEGER DEFAULT 0
);

-- ============================================
-- PLAYER STATISTICS
-- ============================================

CREATE TABLE player_stats (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    
    -- ELO ratings by mode
    elo_1v1 INTEGER DEFAULT 1200,
    elo_ffa4 INTEGER DEFAULT 1200,
    elo_team2v2 INTEGER DEFAULT 1200,
    
    -- Overall stats
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    games_lost INTEGER DEFAULT 0,
    
    -- Single player stats
    solo_games_played INTEGER DEFAULT 0,
    solo_high_score BIGINT DEFAULT 0,
    solo_max_lines INTEGER DEFAULT 0,
    
    -- Multiplayer stats
    mp_games_played INTEGER DEFAULT 0,
    mp_games_won INTEGER DEFAULT 0,
    
    -- Performance metrics
    total_score BIGINT DEFAULT 0,
    total_lines_cleared INTEGER DEFAULT 0,
    total_pieces_placed INTEGER DEFAULT 0,
    
    -- Records
    max_combo INTEGER DEFAULT 0,
    max_back_to_back INTEGER DEFAULT 0,
    fastest_40l INTEGER,  -- milliseconds
    highest_single_game_score BIGINT DEFAULT 0,
    
    -- Attack stats
    total_attacks_sent INTEGER DEFAULT 0,
    total_attacks_received INTEGER DEFAULT 0,
    total_garbage_cleared INTEGER DEFAULT 0,
    
    -- Play time
    play_time_minutes INTEGER DEFAULT 0,
    
    -- Rank progression
    current_rank VARCHAR(50) DEFAULT 'Beginner',
    rank_progress INTEGER DEFAULT 0,  -- 0-100
    
    -- Streaks
    current_win_streak INTEGER DEFAULT 0,
    best_win_streak INTEGER DEFAULT 0,
    
    -- Last updated
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Rank thresholds
CREATE TABLE rank_thresholds (
    rank_name VARCHAR(50) PRIMARY KEY,
    min_elo INTEGER NOT NULL,
    max_elo INTEGER,
    icon_url VARCHAR(500),
    color VARCHAR(7)  -- Hex color
);

INSERT INTO rank_thresholds (rank_name, min_elo, max_elo, color) VALUES
('Beginner', 0, 999, '#8B4513'),
('Novice', 1000, 1199, '#A9A9A9'),
('Intermediate', 1200, 1399, '#FFD700'),
('Advanced', 1400, 1599, '#00CED1'),
('Expert', 1600, 1799, '#FF6347'),
('Master', 1800, 1999, '#9370DB'),
('Grandmaster', 2000, 2199, '#FF1493'),
('Legend', 2200, NULL, '#FFD700');

-- ============================================
-- GAMES
-- ============================================

CREATE TABLE games (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Game configuration
    mode VARCHAR(20) NOT NULL,  -- 'solo_classic', 'solo_levels', '1v1', 'ffa4', '2v2'
    status VARCHAR(20) NOT NULL DEFAULT 'waiting',  -- waiting, countdown, playing, finished, cancelled
    
    -- Timing
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    duration_ms INTEGER,  -- Total game duration
    
    -- Game settings
    starting_level INTEGER DEFAULT 1,
    garbage_multiplier DECIMAL(3,2) DEFAULT 1.0,
    
    -- Results
    winner_id UUID REFERENCES users(id),
    
    -- Replay data (stored in S3/MinIO, reference here)
    replay_storage_key VARCHAR(500),
    replay_size_bytes INTEGER,
    
    -- Server info
    server_region VARCHAR(50),
    server_instance VARCHAR(100)
);

CREATE INDEX idx_games_status ON games(status);
CREATE INDEX idx_games_mode ON games(mode);
CREATE INDEX idx_games_created_at ON games(created_at DESC);
CREATE INDEX idx_games_winner ON games(winner_id);

-- Game participants
CREATE TABLE game_players (
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    -- Team assignment (for team modes)
    team INTEGER DEFAULT 1,
    
    -- Final results
    placement INTEGER,  -- 1st, 2nd, 3rd, 4th
    is_winner BOOLEAN DEFAULT false,
    
    -- Score stats
    final_score INTEGER DEFAULT 0,
    lines_cleared INTEGER DEFAULT 0,
    pieces_placed INTEGER DEFAULT 0,
    
    -- Attack stats
    attacks_sent INTEGER DEFAULT 0,
    attacks_received INTEGER DEFAULT 0,
    garbage_cleared INTEGER DEFAULT 0,
    
    -- Performance
    max_combo INTEGER DEFAULT 0,
    max_back_to_back INTEGER DEFAULT 0,
    tetrises INTEGER DEFAULT 0,
    t_spins INTEGER DEFAULT 0,
    perfect_clears INTEGER DEFAULT 0,
    
    -- ELO change
    elo_before INTEGER,
    elo_after INTEGER,
    elo_change INTEGER,
    
    -- Disconnect/surrender info
    disconnected_at TIMESTAMP WITH TIME ZONE,
    disconnect_reason VARCHAR(50),  -- 'network', 'quit', 'timeout'
    
    PRIMARY KEY (game_id, user_id)
);

CREATE INDEX idx_game_players_user ON game_players(user_id);
CREATE INDEX idx_game_players_game ON game_players(game_id);

-- Game events (for replay reconstruction)
CREATE TABLE game_events (
    id BIGSERIAL PRIMARY KEY,
    game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
    
    frame INTEGER NOT NULL,
    timestamp_ms INTEGER NOT NULL,  -- Relative to game start
    
    event_type VARCHAR(50) NOT NULL,  -- 'piece_spawn', 'move', 'rotate', 'lock', 'line_clear', 'attack', etc.
    player_id UUID REFERENCES users(id),
    
    event_data JSONB,  -- Flexible event-specific data
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_game_events_game ON game_events(game_id);
CREATE INDEX idx_game_events_frame ON game_events(game_id, frame);

-- ============================================
-- LEVELS (Single Player)
-- ============================================

CREATE TABLE levels (
    id INTEGER PRIMARY KEY,
    
    -- Level info
    name VARCHAR(100) NOT NULL,
    description TEXT,
    difficulty VARCHAR(20) NOT NULL,  -- beginner, intermediate, advanced, expert
    
    -- Objectives
    objective_type VARCHAR(20) NOT NULL,  -- 'score', 'lines', 'time', 'survival', 'sprint'
    objective_target INTEGER NOT NULL,
    time_limit_seconds INTEGER,  -- For time-limited levels
    
    -- Game settings
    starting_level INTEGER DEFAULT 1,
    starting_lines INTEGER DEFAULT 0,
    garbage_rate DECIMAL(3,2),  -- For survival mode
    
    -- Restrictions
    restrictions JSONB,  -- ['no_hold', 'no_preview', 'invisible']
    
    -- Board setup (for special levels)
    initial_board JSONB,  -- Array of pre-filled garbage lines
    
    -- Unlock requirements
    required_level_id INTEGER REFERENCES levels(id),
    required_stars INTEGER DEFAULT 0,
    
    -- Rewards
    reward_stars INTEGER DEFAULT 3,
    reward_title VARCHAR(50),
    
    -- Metadata
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Player level progress
CREATE TABLE player_levels (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    level_id INTEGER REFERENCES levels(id) ON DELETE CASCADE,
    
    -- Progress
    is_unlocked BOOLEAN DEFAULT false,
    is_completed BOOLEAN DEFAULT false,
    stars_earned INTEGER DEFAULT 0,
    
    -- Best attempts
    high_score INTEGER DEFAULT 0,
    best_time_ms INTEGER,  -- For sprint/time attack
    
    -- Stats
    attempts INTEGER DEFAULT 0,
    completed_at TIMESTAMP WITH TIME ZONE,
    
    PRIMARY KEY (user_id, level_id)
);

CREATE INDEX idx_player_levels_user ON player_levels(user_id);
CREATE INDEX idx_player_levels_unlocked ON player_levels(user_id, is_unlocked) WHERE is_unlocked = true;

-- ============================================
-- SOCIAL FEATURES
-- ============================================

-- Friends
CREATE TABLE friendships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    requester_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    addressee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    status VARCHAR(20) NOT NULL DEFAULT 'pending',  -- pending, accepted, blocked
    
    requested_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    responded_at TIMESTAMP WITH TIME ZONE,
    
    UNIQUE(requester_id, addressee_id)
);

CREATE INDEX idx_friendships_requester ON friendships(requester_id);
CREATE INDEX idx_friendships_addressee ON friendships(addressee_id);
CREATE INDEX idx_friendships_status ON friendships(status);

-- Friend activity (for "recently played with")
CREATE TABLE friend_activities (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    friend_id UUID REFERENCES users(id) ON DELETE CASCADE,
    game_id UUID REFERENCES games(id) ON DELETE CASCADE,
    played_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_friend_activities_user ON friend_activities(user_id, played_at DESC);

-- Game invites
CREATE TABLE game_invites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invitee_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    mode VARCHAR(20) NOT NULL,
    message TEXT,
    
    status VARCHAR(20) DEFAULT 'pending',  -- pending, accepted, declined, expired
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    responded_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_game_invites_invitee ON game_invites(invitee_id, status);

-- ============================================
-- LEADERBOARDS
-- ============================================

CREATE TABLE leaderboard_entries (
    id BIGSERIAL PRIMARY KEY,
    
    leaderboard_type VARCHAR(20) NOT NULL,  -- 'global_1v1', 'country_1v1', 'weekly_1v1'
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    rank INTEGER NOT NULL,
    elo INTEGER NOT NULL,
    
    games_played INTEGER DEFAULT 0,
    games_won INTEGER DEFAULT 0,
    win_rate DECIMAL(5,2),
    
    period_start DATE,  -- For weekly/monthly leaderboards
    period_end DATE,
    
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(leaderboard_type, user_id, period_start)
);

CREATE INDEX idx_leaderboard_type_rank ON leaderboard_entries(leaderboard_type, rank);
CREATE INDEX idx_leaderboard_user ON leaderboard_entries(user_id);

-- ============================================
-- ACHIEVEMENTS
-- ============================================

CREATE TABLE achievements (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon_url VARCHAR(500),
    
    category VARCHAR(50),  -- 'milestone', 'skill', 'social', 'special'
    difficulty VARCHAR(20),  -- 'easy', 'medium', 'hard', 'expert'
    
    requirement_type VARCHAR(50),  -- 'games_played', 'win_streak', 'score', etc.
    requirement_value INTEGER,
    
    reward_title VARCHAR(50),
    reward_icon VARCHAR(500)
);

CREATE TABLE player_achievements (
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    achievement_id VARCHAR(50) REFERENCES achievements(id) ON DELETE CASCADE,
    
    unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    progress INTEGER,  -- For partial progress tracking
    
    PRIMARY KEY (user_id, achievement_id)
);

-- ============================================
-- AUDIT & ANALYTICS
-- ============================================

-- Login history
CREATE TABLE login_history (
    id BIGSERIAL PRIMARY KEY,
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    
    ip_address INET NOT NULL,
    user_agent TEXT,
    device_info VARCHAR(255),
    
    login_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    logout_at TIMESTAMP WITH TIME ZONE,
    
    success BOOLEAN DEFAULT true,
    failure_reason VARCHAR(100)
);

CREATE INDEX idx_login_history_user ON login_history(user_id, login_at DESC);

-- Game analytics (aggregated)
CREATE TABLE daily_game_stats (
    date DATE PRIMARY KEY,
    
    total_games INTEGER DEFAULT 0,
    unique_players INTEGER DEFAULT 0,
    new_players INTEGER DEFAULT 0,
    
    games_by_mode JSONB,  -- { '1v1': 100, 'ffa4': 50, ... }
    avg_game_duration_ms INTEGER,
    
    peak_concurrent INTEGER DEFAULT 0,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update timestamp on users table
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_stats_updated_at BEFORE UPDATE ON player_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calculate win rate
CREATE OR REPLACE FUNCTION calculate_win_rate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.games_played > 0 THEN
        NEW.win_rate = (NEW.games_won::DECIMAL / NEW.games_played) * 100;
    END IF;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER calc_win_rate BEFORE INSERT OR UPDATE ON player_stats
    FOR EACH ROW EXECUTE FUNCTION calculate_win_rate();

-- ============================================
-- INITIAL DATA
-- ============================================

INSERT INTO achievements (id, name, description, category, difficulty, requirement_type, requirement_value) VALUES
('first_win', 'First Victory', 'Win your first multiplayer game', 'milestone', 'easy', 'games_won', 1),
('win_streak_5', 'On Fire', 'Win 5 games in a row', 'skill', 'medium', 'win_streak', 5),
('win_streak_10', 'Unstoppable', 'Win 10 games in a row', 'skill', 'hard', 'win_streak', 10),
('tetris_master', 'Tetris Master', 'Clear 100 Tetris line clears', 'skill', 'medium', 'tetrises', 100),
('combo_king', 'Combo King', 'Achieve a 10x combo', 'skill', 'hard', 'max_combo', 10),
('speed_demon', 'Speed Demon', 'Complete 40 lines in under 60 seconds', 'skill', 'expert', 'fastest_40l', 60000),
('veteran', 'Veteran', 'Play 1000 games', 'milestone', 'medium', 'games_played', 1000),
('social_butterfly', 'Social Butterfly', 'Add 10 friends', 'social', 'easy', 'friends', 10);

-- Sample levels
INSERT INTO levels (id, name, description, difficulty, objective_type, objective_target, starting_level) VALUES
(1, 'First Steps', 'Clear 10 lines to complete your first level', 'beginner', 'lines', 10, 1),
(2, 'Score Hunter', 'Reach 5000 points', 'beginner', 'score', 5000, 1),
(3, 'Speed Up', 'Clear 20 lines at level 5 speed', 'beginner', 'lines', 20, 5),
(10, 'Combo Practice', 'Achieve a 5x combo', 'intermediate', 'combo', 5, 3),
(16, 'Sprint 40L', 'Clear 40 lines as fast as you can', 'intermediate', 'sprint', 40, 1),
(25, 'Marathon', 'Survive for 5 minutes', 'advanced', 'time', 300, 10),
(50, 'Tetris Master', 'Score 500,000 points without using hold', 'expert', 'score', 500000, 15);

-- Update sequence for levels
SELECT setval('levels_id_seq', 50);
