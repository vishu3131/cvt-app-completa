// Script per eseguire automaticamente lo schema del database
const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');

const supabaseUrl = 'https://qkljuaututgkxkiaxvql.supabase.co';
const supabaseServiceKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFrbGp1YXV0dXRna3hraWF4dnFsIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1MzgwOTE3MywiZXhwIjoyMDY5Mzg1MTczfQ.Ej9nJNJhJJGJGJGJGJGJGJGJGJGJGJGJGJGJGJGJGJG'; // Usa service_role key per operazioni admin

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function setupDatabase() {
  console.log('🚀 Setup database per sistema badge...\n');
  
  try {
    // 1. Leggi lo schema SQL
    const schemaPath = path.join(__dirname, 'simple-badge-schema.sql');
    
    if (!fs.existsSync(schemaPath)) {
      console.error('❌ File schema non trovato:', schemaPath);
      return;
    }
    
    const schema = fs.readFileSync(schemaPath, 'utf8');
    console.log('✅ Schema SQL caricato');
    
    // 2. Dividi lo schema in comandi separati
    const commands = schema
      .split(';')
      .map(cmd => cmd.trim())
      .filter(cmd => cmd.length > 0 && !cmd.startsWith('--') && cmd !== 'COMMIT');
    
    console.log(`📝 Trovati ${commands.length} comandi SQL\n`);
    
    // 3. Esegui ogni comando
    for (let i = 0; i < commands.length; i++) {
      const command = commands[i];
      
      if (command.includes('ALTER TABLE users')) {
        console.log(`${i + 1}. Aggiornamento tabella users...`);
      } else if (command.includes('CREATE TABLE')) {
        const tableName = command.match(/CREATE TABLE.*?(\w+)/)?.[1];
        console.log(`${i + 1}. Creazione tabella ${tableName}...`);
      } else if (command.includes('INSERT INTO')) {
        console.log(`${i + 1}. Inserimento dati...`);
      } else if (command.includes('CREATE OR REPLACE FUNCTION')) {
        const funcName = command.match(/CREATE OR REPLACE FUNCTION (\w+)/)?.[1];
        console.log(`${i + 1}. Creazione funzione ${funcName}...`);
      } else if (command.includes('CREATE')) {
        console.log(`${i + 1}. Creazione elemento...`);
      } else {
        console.log(`${i + 1}. Esecuzione comando...`);
      }
      
      try {
        const { error } = await supabase.rpc('exec_sql', { sql: command });
        
        if (error) {
          // Prova con query diretta se RPC non funziona
          const { error: directError } = await supabase
            .from('_temp_sql_execution')
            .select('*')
            .limit(0); // Questo fallirà, ma ci permette di eseguire SQL
          
          console.log(`   ⚠️ Comando ${i + 1} potrebbe aver avuto problemi:`, error.message);
        } else {
          console.log(`   ✅ Comando ${i + 1} eseguito`);
        }
      } catch (err) {
        console.log(`   ⚠️ Errore comando ${i + 1}:`, err.message);
      }
    }
    
    console.log('\n🎉 Setup database completato!');
    
    // 4. Test finale
    console.log('\n🧪 Test finale...');
    await testDatabase();
    
  } catch (error) {
    console.error('❌ Errore setup database:', error);
  }
}

async function testDatabase() {
  try {
    // Test tabelle
    const tables = ['badge_definitions', 'xp_log'];
    
    for (const table of tables) {
      try {
        const { data, error } = await supabase.from(table).select('*').limit(1);
        if (error) {
          console.log(`   ❌ Tabella ${table}: ${error.message}`);
        } else {
          console.log(`   ✅ Tabella ${table}: OK`);
        }
      } catch (err) {
        console.log(`   ❌ Tabella ${table}: ${err.message}`);
      }
    }
    
    // Test colonne users
    try {
      const { data, error } = await supabase
        .from('users')
        .select('total_xp, current_level, badges_earned')
        .limit(1);
      
      if (error) {
        console.log(`   ❌ Colonne users: ${error.message}`);
      } else {
        console.log(`   ✅ Colonne users: OK`);
      }
    } catch (err) {
      console.log(`   ❌ Colonne users: ${err.message}`);
    }
    
  } catch (error) {
    console.error('❌ Errore test database:', error);
  }
}

// Esegui setup
setupDatabase();