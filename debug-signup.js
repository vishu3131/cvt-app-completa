// Script di debug per testare la registrazione utenti
// Esegui questo script per testare la connessione al database

const { createClient } = require('@supabase/supabase-js');

// Carica le variabili d'ambiente dal file .env.local
const supabaseUrl = 'https://qkljuaututgkxkiaxvql.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrbGp1YXV0dXRna3hraWF4dnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDkxNzMsImV4cCI6MjA2OTM4NTE3M30.i5zYUZN0fPPAtxdeKxrsvsb0_ur9QPT0gTKKMa1KrrU';

if (!supabaseUrl || !supabaseAnonKey) {
  console.error('❌ Variabili d\'ambiente Supabase mancanti!');
  console.log('Assicurati di avere NEXT_PUBLIC_SUPABASE_URL e NEXT_PUBLIC_SUPABASE_ANON_KEY nel tuo .env.local');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testDatabaseConnection() {
  console.log('🔍 Testando connessione al database...');
  
  try {
    // Test 1: Controlla se la tabella users esiste
    console.log('\n1. Controllo esistenza tabella users...');
    const { data, error } = await supabase
      .from('users')
      .select('*', { count: 'exact', head: true });
    
    if (error) {
      console.error('❌ Errore accesso tabella users:', error.message);
      console.log('💡 Possibili soluzioni:');
      console.log('   - Verifica che la tabella "users" esista nel database');
      console.log('   - Controlla i permessi RLS (Row Level Security)');
      console.log('   - Verifica le policy di sicurezza');
      return;
    }
    
    console.log('✅ Tabella users accessibile');
    console.log(`📊 Numero utenti esistenti: ${data || 0}`);
    
    // Test 2: Prova a inserire un utente di test
    console.log('\n2. Test inserimento utente...');
    const testUser = {
      id: 'test-user-' + Date.now(),
      email: 'test@example.com',
      display_name: 'Test User',
      username: 'testuser' + Date.now(),
      phone: '+1234567890',
      birthdate: '1990-01-01',
      role: 'utente'
    };
    
    const { data: insertData, error: insertError } = await supabase
      .from('users')
      .insert(testUser)
      .select();
    
    if (insertError) {
      console.error('❌ Errore inserimento utente test:', insertError.message);
      console.log('💡 Dettagli errore:', insertError);
      
      // Analizza il tipo di errore
      if (insertError.code === '42P01') {
        console.log('🔧 La tabella "users" non esiste. Creala nel dashboard Supabase.');
      } else if (insertError.code === '42501') {
        console.log('🔧 Problema di permessi. Controlla le policy RLS.');
      } else if (insertError.message.includes('duplicate key')) {
        console.log('🔧 Chiave duplicata. Controlla i vincoli di unicità.');
      }
      return;
    }
    
    console.log('✅ Utente test inserito con successo!');
    console.log('📝 Dati inseriti:', insertData);
    
    // Test 3: Rimuovi l'utente di test
    console.log('\n3. Pulizia utente test...');
    const { error: deleteError } = await supabase
      .from('users')
      .delete()
      .eq('id', testUser.id);
    
    if (deleteError) {
      console.warn('⚠️ Errore rimozione utente test:', deleteError.message);
    } else {
      console.log('✅ Utente test rimosso');
    }
    
    console.log('\n🎉 Tutti i test completati con successo!');
    console.log('💡 Il database dovrebbe funzionare correttamente per la registrazione.');
    
  } catch (error) {
    console.error('❌ Errore generico:', error);
  }
}

// Esegui i test
testDatabaseConnection();