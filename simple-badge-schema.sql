-- SCHEMA SEMPLIFICATO PER SISTEMA BADGE E XP
-- Esegui questo nel SQL Editor di Supabase

-- 1. Aggiungi campi XP alla tabella users esistente
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS total_xp INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS current_level INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS level_progress DECIMAL(5,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS badges_earned JSONB DEFAULT '[]'::jsonb,
ADD COLUMN IF NOT EXISTS last_login DATE,
ADD COLUMN IF NOT EXISTS consecutive_days INTEGER DEFAULT 0;

-- 2. Tabella semplificata per i badge disponibili
CREATE TABLE IF NOT EXISTS badge_definitions (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(10),
  category VARCHAR(50),
  rarity VARCHAR(20) DEFAULT 'common',
  xp_reward INTEGER DEFAULT 0,
  requirement_type VARCHAR(50), -- 'xp_total', 'level', 'activity_count', 'days_consecutive'
  requirement_value INTEGER,
  is_active BOOLEAN DEFAULT true
);

-- 3. Tabella per tracciare le attività XP
CREATE TABLE IF NOT EXISTS xp_log (
  id SERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  activity_type VARCHAR(50) NOT NULL,
  xp_earned INTEGER NOT NULL,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB DEFAULT '{}'::jsonb
);

-- 4. Inserisci badge predefiniti
INSERT INTO badge_definitions (name, description, icon, category, rarity, xp_reward, requirement_type, requirement_value) VALUES
('welcome', 'Benvenuto in Civitanova Marche!', '👋', 'achievement', 'common', 25, 'xp_total', 0),
('first_steps', 'Primi passi da cittadino', '👶', 'achievement', 'common', 50, 'xp_total', 50),
('active_citizen', 'Cittadino attivo', '⭐', 'civic', 'rare', 100, 'xp_total', 200),
('explorer', 'Esploratore della città', '🗺️', 'explorer', 'rare', 150, 'xp_total', 500),
('level_master', 'Maestro di livello', '🏆', 'achievement', 'epic', 300, 'level', 5),
('xp_collector', 'Collezionista di XP', '💎', 'achievement', 'rare', 200, 'xp_total', 1000),
('daily_champion', 'Campione giornaliero', '🌟', 'achievement', 'rare', 175, 'days_consecutive', 7),
('super_citizen', 'Super cittadino', '🦸', 'civic', 'epic', 500, 'xp_total', 2000),
('legend', 'Leggenda civica', '👑', 'achievement', 'legendary', 1000, 'xp_total', 5000);

-- 5. Funzione semplificata per aggiungere XP
CREATE OR REPLACE FUNCTION add_xp_simple(
  p_user_id UUID,
  p_activity_type VARCHAR,
  p_xp_amount INTEGER,
  p_metadata JSONB DEFAULT '{}'::jsonb
)
RETURNS TABLE(new_total_xp INTEGER, level_up BOOLEAN, new_badges TEXT[]) AS $$
DECLARE
  v_current_xp INTEGER;
  v_new_xp INTEGER;
  v_old_level INTEGER;
  v_new_level INTEGER;
  v_current_badges JSONB;
  v_new_badges TEXT[] := ARRAY[]::TEXT[];
  badge_record RECORD;
BEGIN
  -- Ottieni dati attuali utente
  SELECT total_xp, current_level, badges_earned
  INTO v_current_xp, v_old_level, v_current_badges
  FROM users WHERE id = p_user_id;
  
  -- Calcola nuovo XP
  v_new_xp := COALESCE(v_current_xp, 0) + p_xp_amount;
  
  -- Calcola nuovo livello (ogni 250 XP = 1 livello)
  v_new_level := GREATEST(1, (v_new_xp / 250) + 1);
  
  -- Aggiorna utente
  UPDATE users 
  SET 
    total_xp = v_new_xp,
    current_level = v_new_level,
    level_progress = ((v_new_xp % 250) / 250.0) * 100
  WHERE id = p_user_id;
  
  -- Registra attività
  INSERT INTO xp_log (user_id, activity_type, xp_earned, metadata)
  VALUES (p_user_id, p_activity_type, p_xp_amount, p_metadata);
  
  -- Controlla nuovi badge
  FOR badge_record IN 
    SELECT * FROM badge_definitions 
    WHERE is_active = true 
    AND name NOT IN (
      SELECT jsonb_array_elements_text(COALESCE(v_current_badges, '[]'::jsonb))
    )
  LOOP
    -- Controlla se il badge è meritato
    IF (badge_record.requirement_type = 'xp_total' AND v_new_xp >= badge_record.requirement_value) OR
       (badge_record.requirement_type = 'level' AND v_new_level >= badge_record.requirement_value) THEN
      
      -- Aggiungi badge
      v_new_badges := array_append(v_new_badges, badge_record.name);
      
      -- Aggiorna badge utente
      UPDATE users 
      SET badges_earned = COALESCE(badges_earned, '[]'::jsonb) || to_jsonb(badge_record.name::text)
      WHERE id = p_user_id;
      
      -- Aggiungi XP bonus
      IF badge_record.xp_reward > 0 THEN
        v_new_xp := v_new_xp + badge_record.xp_reward;
        UPDATE users SET total_xp = v_new_xp WHERE id = p_user_id;
      END IF;
    END IF;
  END LOOP;
  
  RETURN QUERY SELECT v_new_xp, (v_new_level > v_old_level), v_new_badges;
END;
$$ LANGUAGE plpgsql;

-- 6. Funzione per ottenere statistiche utente
CREATE OR REPLACE FUNCTION get_user_stats(p_user_id UUID)
RETURNS TABLE(
  total_xp INTEGER,
  current_level INTEGER,
  level_progress DECIMAL,
  badges_count INTEGER,
  badges_list JSONB,
  rank_position INTEGER
) AS $$
BEGIN
  RETURN QUERY
  WITH user_ranks AS (
    SELECT 
      id,
      total_xp,
      current_level,
      level_progress,
      badges_earned,
      jsonb_array_length(COALESCE(badges_earned, '[]'::jsonb)) as badge_count,
      RANK() OVER (ORDER BY total_xp DESC) as rank_pos
    FROM users
    WHERE total_xp > 0
  )
  SELECT 
    ur.total_xp,
    ur.current_level,
    ur.level_progress,
    ur.badge_count::INTEGER,
    ur.badges_earned,
    ur.rank_pos::INTEGER
  FROM user_ranks ur
  WHERE ur.id = p_user_id;
END;
$$ LANGUAGE plpgsql;

-- 7. Funzione per login giornaliero
CREATE OR REPLACE FUNCTION daily_login_xp(p_user_id UUID)
RETURNS TABLE(xp_earned INTEGER, consecutive_days INTEGER, new_badges TEXT[]) AS $$
DECLARE
  v_last_login DATE;
  v_consecutive_days INTEGER;
  v_today DATE := CURRENT_DATE;
  v_xp_amount INTEGER := 10;
  v_result RECORD;
BEGIN
  -- Ottieni ultimo login
  SELECT last_login, consecutive_days
  INTO v_last_login, v_consecutive_days
  FROM users WHERE id = p_user_id;
  
  -- Se già fatto login oggi, non dare XP
  IF v_last_login = v_today THEN
    RETURN QUERY SELECT 0, COALESCE(v_consecutive_days, 0), ARRAY[]::TEXT[];
    RETURN;
  END IF;
  
  -- Calcola giorni consecutivi
  IF v_last_login = v_today - INTERVAL '1 day' THEN
    v_consecutive_days := COALESCE(v_consecutive_days, 0) + 1;
  ELSE
    v_consecutive_days := 1;
  END IF;
  
  -- Bonus XP per giorni consecutivi
  IF v_consecutive_days >= 7 THEN
    v_xp_amount := v_xp_amount + 20; -- Bonus per 7+ giorni
  ELSIF v_consecutive_days >= 3 THEN
    v_xp_amount := v_xp_amount + 10; -- Bonus per 3+ giorni
  END IF;
  
  -- Aggiorna ultimo login
  UPDATE users 
  SET 
    last_login = v_today,
    consecutive_days = v_consecutive_days
  WHERE id = p_user_id;
  
  -- Aggiungi XP
  SELECT * INTO v_result FROM add_xp_simple(
    p_user_id, 
    'daily_login', 
    v_xp_amount, 
    jsonb_build_object('consecutive_days', v_consecutive_days)
  );
  
  RETURN QUERY SELECT v_xp_amount, v_consecutive_days, v_result.new_badges;
END;
$$ LANGUAGE plpgsql;

-- 8. Vista per leaderboard
CREATE OR REPLACE VIEW leaderboard AS
SELECT 
  u.id,
  u.username,
  u.display_name,
  u.total_xp,
  u.current_level,
  jsonb_array_length(COALESCE(u.badges_earned, '[]'::jsonb)) as badges_count,
  RANK() OVER (ORDER BY u.total_xp DESC) as rank_position
FROM users u
WHERE u.total_xp > 0
ORDER BY u.total_xp DESC;

-- 9. Politiche RLS
ALTER TABLE badge_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Badge definitions are viewable by everyone" ON badge_definitions FOR SELECT USING (true);
CREATE POLICY "XP log is viewable by everyone" ON xp_log FOR SELECT USING (true);
CREATE POLICY "Users can insert their own XP log" ON xp_log FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 10. Indici per performance
CREATE INDEX IF NOT EXISTS idx_users_total_xp ON users(total_xp DESC);
CREATE INDEX IF NOT EXISTS idx_xp_log_user_id ON xp_log(user_id);
CREATE INDEX IF NOT EXISTS idx_xp_log_earned_at ON xp_log(earned_at);

COMMIT;