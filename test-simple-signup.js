// Test semplificato per la registrazione Supabase
const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = 'https://qkljuaututgkxkiaxvql.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrbGp1YXV0dXRna3hraWF4dnFsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4MDkxNzMsImV4cCI6MjA2OTM4NTE3M30.i5zYUZN0fPPAtxdeKxrsvsb0_ur9QPT0gTKKMa1KrrU';

const supabase = createClient(supabaseUrl, supabaseAnonKey);

async function testSimpleSignup() {
  console.log('🧪 Test registrazione semplificata...');
  
  const testEmail = `test${Date.now()}@example.com`;
  const testPassword = 'password123';
  
  console.log('📧 Email test:', testEmail);
  
  try {
    // Test 1: Registrazione minima senza metadati
    console.log('\n1. Test registrazione base...');
    const { data, error } = await supabase.auth.signUp({
      email: testEmail,
      password: testPassword
    });
    
    if (error) {
      console.error('❌ Errore registrazione base:', {
        message: error.message,
        status: error.status,
        name: error.name,
        cause: error.cause
      });
      
      if (error.status === 500) {
        console.log('💡 Errore 500 - Possibili cause:');
        console.log('   - Configurazione email non completata nel dashboard Supabase');
        console.log('   - Rate limiting attivo');
        console.log('   - Problema temporaneo del server');
        console.log('   - Configurazione Auth non corretta');
      }
      return;
    }
    
    console.log('✅ Registrazione base riuscita!');
    console.log('👤 User ID:', data.user?.id);
    console.log('📧 Email:', data.user?.email);
    console.log('✉️ Email confermata:', data.user?.email_confirmed_at ? 'Sì' : 'No');
    
    // Test 2: Prova con metadati
    console.log('\n2. Test con metadati...');
    const testEmail2 = `test${Date.now() + 1}@example.com`;
    
    const { data: data2, error: error2 } = await supabase.auth.signUp({
      email: testEmail2,
      password: testPassword,
      options: {
        data: {
          display_name: 'Test User',
          username: 'testuser',
          role: 'utente'
        }
      }
    });
    
    if (error2) {
      console.error('❌ Errore registrazione con metadati:', error2);
    } else {
      console.log('✅ Registrazione con metadati riuscita!');
      console.log('👤 User ID:', data2.user?.id);
    }
    
  } catch (err) {
    console.error('❌ Errore generico:', err);
  }
}

testSimpleSignup();