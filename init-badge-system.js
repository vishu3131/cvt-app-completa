// Script per inizializzare il sistema di badge con dati di esempio
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://qkljuaututgkxkiaxvql.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrbGp1YXV0dXRna3hraWF4dnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDkxNzMsImV4cCI6MjA2OTM4NTE3M30.i5zYUZN0fPPAtxdeKxrsvsb0_ur9QPT0gTKKMa1KrrU';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function initializeBadgeSystem() {
  console.log('🚀 Inizializzazione sistema badge...');
  
  try {
    // 1. Test connessione database
    console.log('\n1. Test connessione...');
    const { data: testData, error: testError } = await supabase
      .from('users')
      .select('count', { count: 'exact', head: true });
    
    if (testError) {
      console.error('❌ Errore connessione:', testError.message);
      return;
    }
    
    console.log('✅ Connessione OK');
    
    // 2. Controlla se le tabelle esistono
    console.log('\n2. Controllo tabelle...');
    
    const tables = ['badge_types', 'user_badges', 'xp_activities', 'user_xp_log', 'user_levels'];
    
    for (const table of tables) {
      try {
        const { error } = await supabase.from(table).select('*').limit(1);
        if (error) {
          console.log(`❌ Tabella ${table} non trovata:`, error.message);
        } else {
          console.log(`✅ Tabella ${table} OK`);
        }
      } catch (err) {
        console.log(`❌ Errore controllo tabella ${table}:`, err.message);
      }
    }
    
    // 3. Inserisci dati di esempio se le tabelle esistono
    console.log('\n3. Inserimento dati di esempio...');
    
    // Prova a inserire un utente di esempio
    const exampleUserId = 'example-user-' + Date.now();
    
    try {
      const { data: userData, error: userError } = await supabase
        .from('users')
        .insert({
          id: exampleUserId,
          email: 'esempio@civitanova.it',
          username: 'cittadino_esempio',
          display_name: 'Cittadino Esempio',
          phone: '+393331234567',
          birthdate: '1990-01-01',
          role: 'utente',
          total_xp: 150,
          current_level: 2,
          level_progress: 50.0
        })
        .select();
      
      if (userError) {
        console.log('⚠️ Errore inserimento utente esempio:', userError.message);
      } else {
        console.log('✅ Utente esempio creato:', userData[0].username);
        
        // 4. Test funzioni XP
        console.log('\n4. Test sistema XP...');
        
        try {
          const { data: xpResult, error: xpError } = await supabase.rpc('add_user_xp', {
            p_user_id: exampleUserId,
            p_activity_name: 'daily_login',
            p_metadata: { source: 'init_script' }
          });
          
          if (xpError) {
            console.log('⚠️ Errore test XP:', xpError.message);
          } else {
            console.log('✅ Sistema XP funzionante:', xpResult);
          }
        } catch (err) {
          console.log('⚠️ Funzione add_user_xp non disponibile:', err.message);
        }
        
        // 5. Test sistema badge
        console.log('\n5. Test sistema badge...');
        
        try {
          const { data: badgeResult, error: badgeError } = await supabase.rpc('check_and_award_badges', {
            p_user_id: exampleUserId
          });
          
          if (badgeError) {
            console.log('⚠️ Errore test badge:', badgeError.message);
          } else {
            console.log('✅ Sistema badge funzionante:', badgeResult);
          }
        } catch (err) {
          console.log('⚠️ Funzione check_and_award_badges non disponibile:', err.message);
        }
        
        // 6. Pulizia utente esempio
        console.log('\n6. Pulizia...');
        await supabase.from('users').delete().eq('id', exampleUserId);
        console.log('✅ Utente esempio rimosso');
      }
    } catch (err) {
      console.log('⚠️ Errore generale test:', err.message);
    }
    
    // 7. Statistiche sistema
    console.log('\n7. Statistiche sistema...');
    
    try {
      const { data: badgeTypes } = await supabase.from('badge_types').select('count', { count: 'exact', head: true });
      const { data: xpActivities } = await supabase.from('xp_activities').select('count', { count: 'exact', head: true });
      const { data: userLevels } = await supabase.from('user_levels').select('count', { count: 'exact', head: true });
      
      console.log(`📊 Badge disponibili: ${badgeTypes || 0}`);
      console.log(`📊 Attività XP: ${xpActivities || 0}`);
      console.log(`📊 Livelli utente: ${userLevels || 0}`);
    } catch (err) {
      console.log('⚠️ Errore statistiche:', err.message);
    }
    
    console.log('\n🎉 Inizializzazione completata!');
    
    console.log('\n📋 PROSSIMI PASSI:');
    console.log('1. Esegui lo schema SQL nel dashboard Supabase se non l\'hai già fatto');
    console.log('2. Verifica che tutte le tabelle siano create correttamente');
    console.log('3. Controlla che le funzioni PL/pgSQL siano installate');
    console.log('4. Testa la registrazione di un utente reale');
    console.log('5. Integra i componenti React nella tua app');
    
  } catch (error) {
    console.error('❌ Errore generale:', error);
  }
}

// Funzione per testare il sistema con un utente esistente
async function testWithExistingUser(userId) {
  console.log(`\n🧪 Test con utente esistente: ${userId}`);
  
  try {
    // Controlla se l'utente esiste
    const { data: user, error: userError } = await supabase
      .from('users')
      .select('*')
      .eq('id', userId)
      .single();
    
    if (userError) {
      console.log('❌ Utente non trovato:', userError.message);
      return;
    }
    
    console.log('✅ Utente trovato:', user.username);
    console.log(`📊 XP attuali: ${user.total_xp}`);
    console.log(`📊 Livello: ${user.current_level}`);
    
    // Carica badge utente
    const { data: userBadges, error: badgesError } = await supabase
      .from('user_badges')
      .select(`
        badge_types (name, icon, rarity)
      `)
      .eq('user_id', userId);
    
    if (!badgesError && userBadges) {
      console.log(`🏆 Badge ottenuti: ${userBadges.length}`);
      userBadges.forEach(badge => {
        console.log(`   ${badge.badge_types.icon} ${badge.badge_types.name} (${badge.badge_types.rarity})`);
      });
    }
    
  } catch (error) {
    console.error('❌ Errore test utente:', error);
  }
}

// Esegui inizializzazione
initializeBadgeSystem();

// Se vuoi testare con un utente specifico, decommentare e inserire l'ID:
// testWithExistingUser('your-user-id-here');