// Script per aggiungere il campo password_hash alla tabella users
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://qkljuaututgkxkiaxvql.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrbGp1YXV0dXRna3hraWF4dnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDkxNzMsImV4cCI6MjA2OTM4NTE3M30.i5zYUZN0fPPAtxdeKxrsvsb0_ur9QPT0gTKKMa1KrrU';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function addPasswordField() {
  console.log('🔧 Tentativo di aggiungere campo password_hash...');
  
  try {
    // Nota: Questo probabilmente non funzionerà con la chiave anon
    // Dovrai eseguire questo comando direttamente nel dashboard Supabase SQL Editor:
    
    const sqlCommand = `
      ALTER TABLE users 
      ADD COLUMN IF NOT EXISTS password_hash TEXT,
      ADD COLUMN IF NOT EXISTS email_confirmed BOOLEAN DEFAULT FALSE;
    `;
    
    console.log('📝 Comando SQL da eseguire nel dashboard Supabase:');
    console.log(sqlCommand);
    
    console.log('\n🚀 Istruzioni:');
    console.log('1. Vai al dashboard Supabase: https://supabase.com/dashboard');
    console.log('2. Seleziona il tuo progetto');
    console.log('3. Vai su "SQL Editor"');
    console.log('4. Crea una nuova query');
    console.log('5. Incolla il comando SQL sopra');
    console.log('6. Esegui la query');
    
    // Proviamo comunque a vedere la struttura attuale
    console.log('\n🔍 Struttura attuale tabella users:');
    const { data, error } = await supabase
      .from('users')
      .select('*')
      .limit(1);
    
    if (data && data.length > 0) {
      console.log('📊 Campi esistenti:', Object.keys(data[0]));
    } else {
      console.log('❌ Nessun dato trovato o errore:', error);
    }
    
  } catch (err) {
    console.error('❌ Errore:', err);
  }
}

addPasswordField();