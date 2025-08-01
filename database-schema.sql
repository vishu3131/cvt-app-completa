-- SCHEMA COMPLETO PER SISTEMA BADGE E XP
-- Esegui questo nel SQL Editor di Supabase

-- 1. Tabella per definire i tipi di badge disponibili
CREATE TABLE IF NOT EXISTS badge_types (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  icon VARCHAR(50), -- emoji o nome icona
  category VARCHAR(50), -- 'civic', 'social', 'explorer', 'achievement'
  rarity VARCHAR(20) DEFAULT 'common', -- 'common', 'rare', 'epic', 'legendary'
  xp_reward INTEGER DEFAULT 0,
  requirements JSONB, -- condizioni per ottenere il badge
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Tabella per i badge ottenuti dagli utenti
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  badge_type_id UUID REFERENCES badge_types(id) ON DELETE CASCADE,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress JSONB, -- progresso verso il badge se applicabile
  UNIQUE(user_id, badge_type_id)
);

-- 3. Tabella per le attività che generano XP
CREATE TABLE IF NOT EXISTS xp_activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  xp_value INTEGER NOT NULL,
  category VARCHAR(50), -- 'report', 'social', 'civic', 'daily'
  max_daily INTEGER, -- limite giornaliero (NULL = illimitato)
  max_total INTEGER, -- limite totale (NULL = illimitato)
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Tabella per tracciare l'XP guadagnato
CREATE TABLE IF NOT EXISTS user_xp_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  activity_id UUID REFERENCES xp_activities(id) ON DELETE CASCADE,
  xp_earned INTEGER NOT NULL,
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  metadata JSONB -- informazioni aggiuntive sull'attività
);

-- 5. Tabella per i livelli utente
CREATE TABLE IF NOT EXISTS user_levels (
  level INTEGER PRIMARY KEY,
  min_xp INTEGER NOT NULL,
  max_xp INTEGER,
  title VARCHAR(100),
  perks JSONB, -- vantaggi del livello
  badge_reward UUID REFERENCES badge_types(id)
);

-- 6. Aggiungi campi XP alla tabella users esistente
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS total_xp INTEGER DEFAULT 0,
ADD COLUMN IF NOT EXISTS current_level INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS level_progress DECIMAL(5,2) DEFAULT 0.00;

-- 7. Inserisci i livelli base
INSERT INTO user_levels (level, min_xp, max_xp, title) VALUES
(1, 0, 99, 'Cittadino Novizio'),
(2, 100, 249, 'Cittadino Attivo'),
(3, 250, 499, 'Cittadino Impegnato'),
(4, 500, 999, 'Cittadino Esperto'),
(5, 1000, 1999, 'Cittadino Veterano'),
(6, 2000, 3999, 'Cittadino Modello'),
(7, 4000, 7999, 'Ambasciatore Civico'),
(8, 8000, 15999, 'Guardiano della Città'),
(9, 16000, 31999, 'Leggenda Civica'),
(10, 32000, NULL, 'Maestro Cittadino');

-- 8. Inserisci le attività XP base
INSERT INTO xp_activities (name, description, xp_value, category, max_daily) VALUES
('daily_login', 'Accesso giornaliero', 10, 'daily', 1),
('profile_complete', 'Completamento profilo', 50, 'civic', NULL),
('report_submit', 'Invio segnalazione', 25, 'report', 5),
('report_resolved', 'Segnalazione risolta', 100, 'report', NULL),
('event_participate', 'Partecipazione evento', 75, 'social', NULL),
('comment_helpful', 'Commento utile', 15, 'social', 10),
('share_content', 'Condivisione contenuto', 5, 'social', 3),
('ar_scan', 'Scansione AR', 20, 'explorer', 5),
('location_visit', 'Visita luogo', 30, 'explorer', NULL),
('survey_complete', 'Completamento sondaggio', 40, 'civic', NULL);

-- 9. Inserisci i badge base
INSERT INTO badge_types (name, description, icon, category, rarity, xp_reward, requirements) VALUES
('welcome', 'Benvenuto in Civitanova Marche!', '👋', 'achievement', 'common', 25, '{"action": "register"}'),
('first_report', 'Prima segnalazione inviata', '📝', 'civic', 'common', 50, '{"reports_count": 1}'),
('reporter', 'Hai inviato 10 segnalazioni', '🔍', 'civic', 'rare', 100, '{"reports_count": 10}'),
('super_reporter', 'Hai inviato 50 segnalazioni', '🕵️', 'civic', 'epic', 250, '{"reports_count": 50}'),
('problem_solver', 'Le tue segnalazioni sono state risolte', '✅', 'civic', 'rare', 150, '{"resolved_reports": 5}'),
('social_butterfly', 'Hai partecipato a 5 eventi', '🦋', 'social', 'rare', 125, '{"events_participated": 5}'),
('explorer', 'Hai visitato 10 luoghi', '🗺️', 'explorer', 'rare', 100, '{"locations_visited": 10}'),
('ar_pioneer', 'Hai usato 20 volte l\'AR', '📱', 'explorer', 'epic', 200, '{"ar_scans": 20}'),
('daily_champion', 'Accesso per 7 giorni consecutivi', '🏆', 'achievement', 'rare', 175, '{"consecutive_days": 7}'),
('monthly_hero', 'Accesso per 30 giorni consecutivi', '🌟', 'achievement', 'epic', 500, '{"consecutive_days": 30}'),
('level_master', 'Raggiunto livello 5', '⭐', 'achievement', 'epic', 300, '{"level_reached": 5}'),
('xp_collector', 'Raccolto 1000 XP', '💎', 'achievement', 'rare', 200, '{"total_xp": 1000}'),
('community_leader', 'I tuoi contenuti hanno ricevuto 50 like', '👑', 'social', 'legendary', 1000, '{"likes_received": 50}'),
('city_guardian', 'Hai contribuito significativamente alla città', '🛡️', 'civic', 'legendary', 2000, '{"civic_score": 100}');

-- 10. Funzione per calcolare il livello basato sull'XP
CREATE OR REPLACE FUNCTION calculate_user_level(user_xp INTEGER)
RETURNS TABLE(level INTEGER, title VARCHAR, progress DECIMAL) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    ul.level,
    ul.title,
    CASE 
      WHEN ul.max_xp IS NULL THEN 100.00
      ELSE ROUND(((user_xp - ul.min_xp)::DECIMAL / (ul.max_xp - ul.min_xp)::DECIMAL) * 100, 2)
    END as progress
  FROM user_levels ul
  WHERE user_xp >= ul.min_xp 
    AND (ul.max_xp IS NULL OR user_xp <= ul.max_xp)
  ORDER BY ul.level DESC
  LIMIT 1;
END;
$$ LANGUAGE plpgsql;

-- 11. Funzione per aggiungere XP a un utente
CREATE OR REPLACE FUNCTION add_user_xp(
  p_user_id UUID,
  p_activity_name VARCHAR,
  p_metadata JSONB DEFAULT '{}'
)
RETURNS TABLE(xp_earned INTEGER, new_total INTEGER, level_up BOOLEAN) AS $$
DECLARE
  v_activity_id UUID;
  v_xp_value INTEGER;
  v_max_daily INTEGER;
  v_max_total INTEGER;
  v_current_xp INTEGER;
  v_new_xp INTEGER;
  v_old_level INTEGER;
  v_new_level INTEGER;
  v_daily_count INTEGER;
  v_total_count INTEGER;
BEGIN
  -- Ottieni informazioni sull'attività
  SELECT id, xp_value, max_daily, max_total
  INTO v_activity_id, v_xp_value, v_max_daily, v_max_total
  FROM xp_activities
  WHERE name = p_activity_name AND is_active = true;
  
  IF v_activity_id IS NULL THEN
    RAISE EXCEPTION 'Attività non trovata: %', p_activity_name;
  END IF;
  
  -- Controlla limiti giornalieri
  IF v_max_daily IS NOT NULL THEN
    SELECT COUNT(*)
    INTO v_daily_count
    FROM user_xp_log
    WHERE user_id = p_user_id 
      AND activity_id = v_activity_id
      AND earned_at >= CURRENT_DATE;
      
    IF v_daily_count >= v_max_daily THEN
      RETURN QUERY SELECT 0, (SELECT total_xp FROM users WHERE id = p_user_id), false;
      RETURN;
    END IF;
  END IF;
  
  -- Controlla limiti totali
  IF v_max_total IS NOT NULL THEN
    SELECT COUNT(*)
    INTO v_total_count
    FROM user_xp_log
    WHERE user_id = p_user_id AND activity_id = v_activity_id;
      
    IF v_total_count >= v_max_total THEN
      RETURN QUERY SELECT 0, (SELECT total_xp FROM users WHERE id = p_user_id), false;
      RETURN;
    END IF;
  END IF;
  
  -- Ottieni XP attuale e livello
  SELECT total_xp, current_level
  INTO v_current_xp, v_old_level
  FROM users
  WHERE id = p_user_id;
  
  v_new_xp := v_current_xp + v_xp_value;
  
  -- Calcola nuovo livello
  SELECT level INTO v_new_level
  FROM calculate_user_level(v_new_xp);
  
  -- Aggiorna utente
  UPDATE users
  SET 
    total_xp = v_new_xp,
    current_level = v_new_level,
    level_progress = (SELECT progress FROM calculate_user_level(v_new_xp))
  WHERE id = p_user_id;
  
  -- Registra l'XP guadagnato
  INSERT INTO user_xp_log (user_id, activity_id, xp_earned, metadata)
  VALUES (p_user_id, v_activity_id, v_xp_value, p_metadata);
  
  RETURN QUERY SELECT v_xp_value, v_new_xp, (v_new_level > v_old_level);
END;
$$ LANGUAGE plpgsql;

-- 12. Funzione per controllare e assegnare badge
CREATE OR REPLACE FUNCTION check_and_award_badges(p_user_id UUID)
RETURNS TABLE(badge_name VARCHAR, newly_earned BOOLEAN) AS $$
DECLARE
  badge_record RECORD;
  user_stats RECORD;
  requirement_met BOOLEAN;
BEGIN
  -- Ottieni statistiche utente
  SELECT 
    u.total_xp,
    u.current_level,
    u.created_at,
    COUNT(DISTINCT uxl.id) as total_activities,
    COUNT(DISTINCT CASE WHEN xa.category = 'report' THEN uxl.id END) as reports_count,
    COUNT(DISTINCT CASE WHEN xa.category = 'social' THEN uxl.id END) as social_activities,
    COUNT(DISTINCT CASE WHEN xa.name = 'ar_scan' THEN uxl.id END) as ar_scans,
    COUNT(DISTINCT CASE WHEN xa.name = 'location_visit' THEN uxl.id END) as locations_visited
  INTO user_stats
  FROM users u
  LEFT JOIN user_xp_log uxl ON u.id = uxl.user_id
  LEFT JOIN xp_activities xa ON uxl.activity_id = xa.id
  WHERE u.id = p_user_id
  GROUP BY u.id, u.total_xp, u.current_level, u.created_at;
  
  -- Controlla ogni badge
  FOR badge_record IN 
    SELECT bt.*, ub.id as user_badge_id
    FROM badge_types bt
    LEFT JOIN user_badges ub ON bt.id = ub.badge_type_id AND ub.user_id = p_user_id
    WHERE bt.is_active = true
  LOOP
    requirement_met := false;
    
    -- Controlla i requisiti (semplificato - espandibile)
    IF badge_record.requirements->>'action' = 'register' THEN
      requirement_met := true;
    ELSIF badge_record.requirements->>'reports_count' IS NOT NULL THEN
      requirement_met := user_stats.reports_count >= (badge_record.requirements->>'reports_count')::INTEGER;
    ELSIF badge_record.requirements->>'total_xp' IS NOT NULL THEN
      requirement_met := user_stats.total_xp >= (badge_record.requirements->>'total_xp')::INTEGER;
    ELSIF badge_record.requirements->>'level_reached' IS NOT NULL THEN
      requirement_met := user_stats.current_level >= (badge_record.requirements->>'level_reached')::INTEGER;
    ELSIF badge_record.requirements->>'ar_scans' IS NOT NULL THEN
      requirement_met := user_stats.ar_scans >= (badge_record.requirements->>'ar_scans')::INTEGER;
    ELSIF badge_record.requirements->>'locations_visited' IS NOT NULL THEN
      requirement_met := user_stats.locations_visited >= (badge_record.requirements->>'locations_visited')::INTEGER;
    END IF;
    
    -- Assegna badge se meritato e non già posseduto
    IF requirement_met AND badge_record.user_badge_id IS NULL THEN
      INSERT INTO user_badges (user_id, badge_type_id)
      VALUES (p_user_id, badge_record.id);
      
      -- Aggiungi XP bonus se previsto
      IF badge_record.xp_reward > 0 THEN
        UPDATE users 
        SET total_xp = total_xp + badge_record.xp_reward
        WHERE id = p_user_id;
      END IF;
      
      RETURN QUERY SELECT badge_record.name, true;
    ELSIF badge_record.user_badge_id IS NOT NULL THEN
      RETURN QUERY SELECT badge_record.name, false;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 13. Trigger per controllare badge dopo ogni aggiornamento XP
CREATE OR REPLACE FUNCTION trigger_check_badges()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM check_and_award_badges(NEW.user_id);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_xp_update
  AFTER INSERT ON user_xp_log
  FOR EACH ROW
  EXECUTE FUNCTION trigger_check_badges();

-- 14. Vista per statistiche utente complete
CREATE OR REPLACE VIEW user_stats_complete AS
SELECT 
  u.id,
  u.username,
  u.display_name,
  u.total_xp,
  u.current_level,
  u.level_progress,
  ul.title as level_title,
  COUNT(DISTINCT ub.id) as badges_count,
  COUNT(DISTINCT CASE WHEN bt.rarity = 'legendary' THEN ub.id END) as legendary_badges,
  COUNT(DISTINCT CASE WHEN bt.rarity = 'epic' THEN ub.id END) as epic_badges,
  COUNT(DISTINCT CASE WHEN bt.rarity = 'rare' THEN ub.id END) as rare_badges,
  COUNT(DISTINCT CASE WHEN bt.rarity = 'common' THEN ub.id END) as common_badges,
  RANK() OVER (ORDER BY u.total_xp DESC) as xp_rank,
  RANK() OVER (ORDER BY COUNT(DISTINCT ub.id) DESC) as badge_rank
FROM users u
LEFT JOIN user_levels ul ON u.current_level = ul.level
LEFT JOIN user_badges ub ON u.id = ub.user_id
LEFT JOIN badge_types bt ON ub.badge_type_id = bt.id
GROUP BY u.id, u.username, u.display_name, u.total_xp, u.current_level, u.level_progress, ul.title;

-- 15. Politiche RLS (Row Level Security)
ALTER TABLE badge_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;
ALTER TABLE xp_activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_xp_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_levels ENABLE ROW LEVEL SECURITY;

-- Politiche di lettura pubblica
CREATE POLICY "Badge types are viewable by everyone" ON badge_types FOR SELECT USING (true);
CREATE POLICY "XP activities are viewable by everyone" ON xp_activities FOR SELECT USING (true);
CREATE POLICY "User levels are viewable by everyone" ON user_levels FOR SELECT USING (true);

-- Politiche per user_badges
CREATE POLICY "Users can view all badges" ON user_badges FOR SELECT USING (true);
CREATE POLICY "Users can insert their own badges" ON user_badges FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiche per user_xp_log
CREATE POLICY "Users can view all XP logs" ON user_xp_log FOR SELECT USING (true);
CREATE POLICY "Users can insert their own XP" ON user_xp_log FOR INSERT WITH CHECK (auth.uid() = user_id);

COMMIT;