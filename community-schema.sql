-- SCHEMA PER SISTEMA COMMUNITY COMPLETO
-- Esegui questo nel SQL Editor di Supabase

-- 1. Tabella per i post della community
CREATE TABLE IF NOT EXISTS community_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(20) NOT NULL CHECK (type IN ('report', 'discussion', 'event', 'group', 'announcement')),
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  location VARCHAR(255),
  category VARCHAR(50),
  status VARCHAR(20) DEFAULT 'open' CHECK (status IN ('open', 'in-progress', 'resolved', 'closed')),
  images TEXT[], -- Array di URL immagini
  tags TEXT[], -- Array di tag
  is_pinned BOOLEAN DEFAULT false,
  is_locked BOOLEAN DEFAULT false,
  visibility VARCHAR(20) DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'friends')),
  likes_count INTEGER DEFAULT 0,
  dislikes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  shares_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 2. Tabella per i commenti sui post
CREATE TABLE IF NOT EXISTS community_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  parent_id UUID REFERENCES community_comments(id) ON DELETE CASCADE, -- Per risposte ai commenti
  content TEXT NOT NULL,
  images TEXT[], -- Array di URL immagini
  likes_count INTEGER DEFAULT 0,
  dislikes_count INTEGER DEFAULT 0,
  is_solution BOOLEAN DEFAULT false, -- Per marcare come soluzione
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- 3. Tabella per i like/dislike sui post
CREATE TABLE IF NOT EXISTS community_post_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reaction_type VARCHAR(10) NOT NULL CHECK (reaction_type IN ('like', 'dislike', 'love', 'laugh', 'angry', 'sad')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id) -- Un utente può avere solo una reazione per post
);

-- 4. Tabella per i like/dislike sui commenti
CREATE TABLE IF NOT EXISTS community_comment_reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  comment_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  reaction_type VARCHAR(10) NOT NULL CHECK (reaction_type IN ('like', 'dislike')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- 5. Tabella per le condivisioni
CREATE TABLE IF NOT EXISTS community_shares (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  share_type VARCHAR(20) NOT NULL CHECK (share_type IN ('internal', 'facebook', 'twitter', 'whatsapp', 'telegram')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Tabella per seguire i post (notifiche)
CREATE TABLE IF NOT EXISTS community_post_follows (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 7. Tabella per le visualizzazioni dei post
CREATE TABLE IF NOT EXISTS community_post_views (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- 8. Tabella per i gruppi della community
CREATE TABLE IF NOT EXISTS community_groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL,
  description TEXT,
  avatar_url TEXT,
  cover_url TEXT,
  category VARCHAR(50),
  privacy VARCHAR(20) DEFAULT 'public' CHECK (privacy IN ('public', 'private', 'secret')),
  creator_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  members_count INTEGER DEFAULT 1,
  posts_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 9. Tabella per i membri dei gruppi
CREATE TABLE IF NOT EXISTS community_group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID REFERENCES community_groups(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- 10. Tabella per le notifiche della community
CREATE TABLE IF NOT EXISTS community_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL CHECK (type IN ('new_comment', 'new_like', 'new_share', 'post_update', 'mention', 'group_invite')),
  title VARCHAR(255) NOT NULL,
  message TEXT NOT NULL,
  related_post_id UUID REFERENCES community_posts(id) ON DELETE CASCADE,
  related_comment_id UUID REFERENCES community_comments(id) ON DELETE CASCADE,
  related_user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 11. Indici per performance
CREATE INDEX IF NOT EXISTS idx_community_posts_user_id ON community_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_community_posts_type ON community_posts(type);
CREATE INDEX IF NOT EXISTS idx_community_posts_created_at ON community_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_community_posts_status ON community_posts(status);
CREATE INDEX IF NOT EXISTS idx_community_posts_category ON community_posts(category);
CREATE INDEX IF NOT EXISTS idx_community_posts_visibility ON community_posts(visibility);

CREATE INDEX IF NOT EXISTS idx_community_comments_post_id ON community_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_community_comments_user_id ON community_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_community_comments_parent_id ON community_comments(parent_id);
CREATE INDEX IF NOT EXISTS idx_community_comments_created_at ON community_comments(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_community_post_reactions_post_id ON community_post_reactions(post_id);
CREATE INDEX IF NOT EXISTS idx_community_post_reactions_user_id ON community_post_reactions(user_id);

CREATE INDEX IF NOT EXISTS idx_community_notifications_user_id ON community_notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_community_notifications_is_read ON community_notifications(is_read);
CREATE INDEX IF NOT EXISTS idx_community_notifications_created_at ON community_notifications(created_at DESC);

-- 12. Trigger per aggiornare i contatori
CREATE OR REPLACE FUNCTION update_post_counters()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'community_comments' THEN
    IF TG_OP = 'INSERT' THEN
      UPDATE community_posts 
      SET comments_count = comments_count + 1,
          updated_at = NOW()
      WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
      UPDATE community_posts 
      SET comments_count = GREATEST(comments_count - 1, 0),
          updated_at = NOW()
      WHERE id = OLD.post_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'community_post_reactions' THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.reaction_type = 'like' THEN
        UPDATE community_posts 
        SET likes_count = likes_count + 1,
            updated_at = NOW()
        WHERE id = NEW.post_id;
      ELSIF NEW.reaction_type = 'dislike' THEN
        UPDATE community_posts 
        SET dislikes_count = dislikes_count + 1,
            updated_at = NOW()
        WHERE id = NEW.post_id;
      END IF;
    ELSIF TG_OP = 'DELETE' THEN
      IF OLD.reaction_type = 'like' THEN
        UPDATE community_posts 
        SET likes_count = GREATEST(likes_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.post_id;
      ELSIF OLD.reaction_type = 'dislike' THEN
        UPDATE community_posts 
        SET dislikes_count = GREATEST(dislikes_count - 1, 0),
            updated_at = NOW()
        WHERE id = OLD.post_id;
      END IF;
    ELSIF TG_OP = 'UPDATE' THEN
      -- Gestisce il cambio di reazione
      IF OLD.reaction_type = 'like' AND NEW.reaction_type = 'dislike' THEN
        UPDATE community_posts 
        SET likes_count = GREATEST(likes_count - 1, 0),
            dislikes_count = dislikes_count + 1,
            updated_at = NOW()
        WHERE id = NEW.post_id;
      ELSIF OLD.reaction_type = 'dislike' AND NEW.reaction_type = 'like' THEN
        UPDATE community_posts 
        SET dislikes_count = GREATEST(dislikes_count - 1, 0),
            likes_count = likes_count + 1,
            updated_at = NOW()
        WHERE id = NEW.post_id;
      END IF;
    END IF;
  ELSIF TG_TABLE_NAME = 'community_shares' THEN
    IF TG_OP = 'INSERT' THEN
      UPDATE community_posts 
      SET shares_count = shares_count + 1,
          updated_at = NOW()
      WHERE id = NEW.post_id;
    END IF;
  END IF;
  
  RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Crea i trigger
CREATE TRIGGER trigger_update_comments_count
  AFTER INSERT OR DELETE ON community_comments
  FOR EACH ROW EXECUTE FUNCTION update_post_counters();

CREATE TRIGGER trigger_update_reactions_count
  AFTER INSERT OR DELETE OR UPDATE ON community_post_reactions
  FOR EACH ROW EXECUTE FUNCTION update_post_counters();

CREATE TRIGGER trigger_update_shares_count
  AFTER INSERT ON community_shares
  FOR EACH ROW EXECUTE FUNCTION update_post_counters();

-- 13. Funzione per creare un nuovo post
CREATE OR REPLACE FUNCTION create_community_post(
  p_user_id UUID,
  p_type VARCHAR,
  p_title VARCHAR,
  p_content TEXT,
  p_location VARCHAR DEFAULT NULL,
  p_category VARCHAR DEFAULT NULL,
  p_images TEXT[] DEFAULT '{}',
  p_tags TEXT[] DEFAULT '{}',
  p_visibility VARCHAR DEFAULT 'public'
)
RETURNS UUID AS $$
DECLARE
  v_post_id UUID;
BEGIN
  INSERT INTO community_posts (
    user_id, type, title, content, location, category, 
    images, tags, visibility
  ) VALUES (
    p_user_id, p_type, p_title, p_content, p_location, p_category,
    p_images, p_tags, p_visibility
  ) RETURNING id INTO v_post_id;
  
  -- Aggiungi XP per il post
  PERFORM add_user_xp(p_user_id, 'community_post', jsonb_build_object('post_id', v_post_id));
  
  RETURN v_post_id;
END;
$$ LANGUAGE plpgsql;

-- 14. Funzione per aggiungere un commento
CREATE OR REPLACE FUNCTION add_community_comment(
  p_post_id UUID,
  p_user_id UUID,
  p_content TEXT,
  p_parent_id UUID DEFAULT NULL,
  p_images TEXT[] DEFAULT '{}'
)
RETURNS UUID AS $$
DECLARE
  v_comment_id UUID;
BEGIN
  INSERT INTO community_comments (
    post_id, user_id, content, parent_id, images
  ) VALUES (
    p_post_id, p_user_id, p_content, p_parent_id, p_images
  ) RETURNING id INTO v_comment_id;
  
  -- Aggiungi XP per il commento
  PERFORM add_user_xp(p_user_id, 'comment_helpful', jsonb_build_object('comment_id', v_comment_id));
  
  RETURN v_comment_id;
END;
$$ LANGUAGE plpgsql;

-- 15. Funzione per gestire le reazioni
CREATE OR REPLACE FUNCTION toggle_post_reaction(
  p_post_id UUID,
  p_user_id UUID,
  p_reaction_type VARCHAR
)
RETURNS BOOLEAN AS $$
DECLARE
  v_existing_reaction VARCHAR;
  v_action_taken BOOLEAN := false;
BEGIN
  -- Controlla se esiste già una reazione
  SELECT reaction_type INTO v_existing_reaction
  FROM community_post_reactions
  WHERE post_id = p_post_id AND user_id = p_user_id;
  
  IF v_existing_reaction IS NULL THEN
    -- Inserisci nuova reazione
    INSERT INTO community_post_reactions (post_id, user_id, reaction_type)
    VALUES (p_post_id, p_user_id, p_reaction_type);
    v_action_taken := true;
  ELSIF v_existing_reaction = p_reaction_type THEN
    -- Rimuovi reazione esistente (toggle off)
    DELETE FROM community_post_reactions
    WHERE post_id = p_post_id AND user_id = p_user_id;
    v_action_taken := false;
  ELSE
    -- Cambia tipo di reazione
    UPDATE community_post_reactions
    SET reaction_type = p_reaction_type
    WHERE post_id = p_post_id AND user_id = p_user_id;
    v_action_taken := true;
  END IF;
  
  RETURN v_action_taken;
END;
$$ LANGUAGE plpgsql;

-- 16. Vista per i post con informazioni complete
CREATE OR REPLACE VIEW community_posts_with_details AS
SELECT 
  cp.*,
  p.display_name as author_name,
  p.avatar as author_avatar,
  p.role as author_role,
  COALESCE(user_reaction.reaction_type, '') as user_reaction,
  CASE 
    WHEN cp.created_at > NOW() - INTERVAL '1 hour' THEN EXTRACT(EPOCH FROM (NOW() - cp.created_at))/60 || ' minuti fa'
    WHEN cp.created_at > NOW() - INTERVAL '1 day' THEN EXTRACT(EPOCH FROM (NOW() - cp.created_at))/3600 || ' ore fa'
    WHEN cp.created_at > NOW() - INTERVAL '1 week' THEN EXTRACT(EPOCH FROM (NOW() - cp.created_at))/86400 || ' giorni fa'
    ELSE TO_CHAR(cp.created_at, 'DD/MM/YYYY')
  END as time_ago
FROM community_posts cp
LEFT JOIN profiles p ON cp.user_id = p.id
LEFT JOIN community_post_reactions user_reaction ON cp.id = user_reaction.post_id 
WHERE cp.deleted_at IS NULL;

-- 17. Politiche RLS (Row Level Security)
ALTER TABLE community_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_comment_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_shares ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_post_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE community_notifications ENABLE ROW LEVEL SECURITY;

-- Politiche per i post
CREATE POLICY "Everyone can view public posts" ON community_posts 
  FOR SELECT USING (visibility = 'public' OR user_id = auth.uid());

CREATE POLICY "Users can create posts" ON community_posts 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own posts" ON community_posts 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own posts" ON community_posts 
  FOR DELETE USING (auth.uid() = user_id);

-- Politiche per i commenti
CREATE POLICY "Everyone can view comments on public posts" ON community_comments 
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM community_posts 
      WHERE id = community_comments.post_id 
      AND (visibility = 'public' OR user_id = auth.uid())
    )
  );

CREATE POLICY "Users can create comments" ON community_comments 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own comments" ON community_comments 
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own comments" ON community_comments 
  FOR DELETE USING (auth.uid() = user_id);

-- Politiche per le reazioni
CREATE POLICY "Everyone can view reactions" ON community_post_reactions FOR SELECT USING (true);
CREATE POLICY "Users can manage their own reactions" ON community_post_reactions 
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Everyone can view comment reactions" ON community_comment_reactions FOR SELECT USING (true);
CREATE POLICY "Users can manage their own comment reactions" ON community_comment_reactions 
  FOR ALL USING (auth.uid() = user_id);

-- Politiche per condivisioni e visualizzazioni
CREATE POLICY "Users can share posts" ON community_shares 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view posts" ON community_post_views 
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politiche per notifiche
CREATE POLICY "Users can view their own notifications" ON community_notifications 
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON community_notifications 
  FOR UPDATE USING (auth.uid() = user_id);

-- Aggiungi attività XP per la community
INSERT INTO xp_activities (name, description, xp_value, category, max_daily) VALUES
('community_post', 'Creazione post community', 20, 'social', 5),
('community_comment', 'Commento su post', 10, 'social', 10),
('community_like', 'Like su post', 2, 'social', 20),
('community_share', 'Condivisione post', 5, 'social', 10)
ON CONFLICT (name) DO NOTHING;

COMMIT;