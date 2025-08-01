# 🏆 Sistema Badge e XP - Guida Completa

## 📋 Panoramica

Questo sistema di gamification completo include:
- **Sistema XP** con livelli progressivi
- **Badge** con rarità diverse (Common, Rare, Epic, Legendary)
- **Classifica** utenti
- **Login giornaliero** con bonus consecutivi
- **Attività** che generano XP
- **Notifiche** per nuovi badge e level up

## 🚀 Installazione

### 1. Database Setup

Esegui lo schema SQL nel dashboard Supabase:

```bash
# Apri il file e copia il contenuto
cat simple-badge-schema.sql
```

**Passi:**
1. Vai su [supabase.com/dashboard](https://supabase.com/dashboard)
2. Seleziona il tuo progetto
3. Vai su "SQL Editor"
4. Crea una nuova query
5. Incolla il contenuto di `simple-badge-schema.sql`
6. Esegui la query

### 2. Verifica Installazione

Esegui il test:
```bash
node init-badge-system.js
```

Dovresti vedere:
- ✅ Connessione OK
- ✅ Tutte le tabelle OK
- ✅ Funzioni funzionanti

### 3. Integrazione React

Sostituisci i componenti esistenti:

```tsx
// In MobileHomeScreen.tsx
import { SimpleBadgeSystem } from './SimpleBadgeSystem';

// Sostituisci il widget gamification con:
<SimpleBadgeSystem userId={currentUserId} compact={true} />
```

## 📊 Struttura Database

### Tabelle Principali

1. **users** (estesa)
   - `total_xp`: XP totali utente
   - `current_level`: Livello attuale
   - `level_progress`: Progresso verso prossimo livello
   - `badges_earned`: Array JSON dei badge ottenuti
   - `last_login`: Ultimo accesso
   - `consecutive_days`: Giorni consecutivi di accesso

2. **badge_definitions**
   - Definizioni di tutti i badge disponibili
   - Requisiti per ottenerli
   - Ricompense XP

3. **xp_log**
   - Storico di tutte le attività XP
   - Tracciamento per analytics

### Funzioni Database

1. **add_xp_simple(user_id, activity_type, xp_amount)**
   - Aggiunge XP all'utente
   - Calcola nuovo livello
   - Controlla e assegna nuovi badge
   - Ritorna: nuovo_xp_totale, level_up, nuovi_badge

2. **daily_login_xp(user_id)**
   - Gestisce login giornaliero
   - Calcola bonus per giorni consecutivi
   - Ritorna: xp_guadagnati, giorni_consecutivi

3. **get_user_stats(user_id)**
   - Ottiene statistiche complete utente
   - Include posizione in classifica

## 🎮 Sistema XP

### Attività e Ricompense

| Attività | XP Base | Limite | Note |
|----------|---------|--------|------|
| Login giornaliero | 10 | 1/giorno | +10 XP dopo 3 giorni, +20 XP dopo 7 giorni |
| Condivisione | 5 | 3/giorno | Social sharing |
| Segnalazione | 25 | 5/giorno | Report problemi |
| Visita luogo | 30 | Illimitato | Esplorazione città |
| Completamento profilo | 50 | 1 volta | Setup iniziale |
| Partecipazione evento | 75 | Illimitato | Eventi cittadini |

### Sistema Livelli

- **Livello 1**: 0-249 XP - "Cittadino Novizio"
- **Livello 2**: 250-499 XP - "Cittadino Attivo"  
- **Livello 3**: 500-749 XP - "Cittadino Impegnato"
- **Livello 4**: 750-999 XP - "Cittadino Esperto"
- **Livello 5+**: +250 XP per livello

## 🏆 Sistema Badge

### Rarità e Colori

- **Common** (Grigio): Badge base, facili da ottenere
- **Rare** (Blu): Richiedono impegno moderato
- **Epic** (Viola): Difficili da ottenere
- **Legendary** (Oro): Estremamente rari

### Badge Predefiniti

| Nome | Descrizione | Requisito | Rarità | XP Bonus |
|------|-------------|-----------|--------|----------|
| welcome | Benvenuto! | Registrazione | Common | 25 |
| first_steps | Primi passi | 50 XP totali | Common | 50 |
| active_citizen | Cittadino attivo | 200 XP totali | Rare | 100 |
| explorer | Esploratore | 500 XP totali | Rare | 150 |
| level_master | Maestro livello | Livello 5 | Epic | 300 |
| xp_collector | Collezionista XP | 1000 XP totali | Rare | 200 |
| daily_champion | Campione giornaliero | 7 giorni consecutivi | Rare | 175 |
| super_citizen | Super cittadino | 2000 XP totali | Epic | 500 |
| legend | Leggenda civica | 5000 XP totali | Legendary | 1000 |

## 💻 Utilizzo Componenti

### SimpleBadgeSystem

```tsx
// Versione completa
<SimpleBadgeSystem userId="user-id" />

// Versione compatta per widget
<SimpleBadgeSystem userId="user-id" compact={true} />
```

### Funzioni Utili

```tsx
// Hook per aggiungere XP
const addXP = async (activityType: string, amount: number) => {
  const { data } = await supabase.rpc('add_xp_simple', {
    p_user_id: userId,
    p_activity_type: activityType,
    p_xp_amount: amount
  });
  return data[0];
};

// Login giornaliero
const dailyLogin = async () => {
  const { data } = await supabase.rpc('daily_login_xp', {
    p_user_id: userId
  });
  return data[0];
};

// Statistiche utente
const getUserStats = async () => {
  const { data } = await supabase.rpc('get_user_stats', {
    p_user_id: userId
  });
  return data[0];
};
```

## 🔧 Personalizzazione

### Aggiungere Nuovi Badge

```sql
INSERT INTO badge_definitions (
  name, 
  description, 
  icon, 
  category, 
  rarity, 
  xp_reward, 
  requirement_type, 
  requirement_value
) VALUES (
  'new_badge',
  'Descrizione del badge',
  '🎯',
  'achievement',
  'rare',
  100,
  'xp_total',
  1500
);
```

### Modificare Sistema Livelli

Modifica la funzione `add_xp_simple` per cambiare la formula:

```sql
-- Attuale: ogni 250 XP = 1 livello
v_new_level := GREATEST(1, (v_new_xp / 250) + 1);

-- Esempio: livelli più difficili
v_new_level := GREATEST(1, FLOOR(SQRT(v_new_xp / 100)) + 1);
```

### Aggiungere Nuove Attività

Modifica il componente per includere nuove azioni:

```tsx
const handleNewActivity = async () => {
  await addXP('new_activity', 15, { 
    source: 'custom',
    timestamp: new Date().toISOString()
  });
};
```

## 📈 Analytics e Monitoraggio

### Query Utili

```sql
-- Top 10 utenti per XP
SELECT username, total_xp, current_level 
FROM users 
ORDER BY total_xp DESC 
LIMIT 10;

-- Attività più popolari
SELECT activity_type, COUNT(*), SUM(xp_earned)
FROM xp_log 
GROUP BY activity_type 
ORDER BY COUNT(*) DESC;

-- Badge più rari
SELECT bd.name, COUNT(u.id) as users_with_badge
FROM badge_definitions bd
LEFT JOIN users u ON u.badges_earned ? bd.name
GROUP BY bd.name
ORDER BY users_with_badge ASC;
```

## 🚨 Troubleshooting

### Errori Comuni

1. **"Funzione non trovata"**
   - Verifica che lo schema SQL sia stato eseguito completamente
   - Controlla i permessi RLS

2. **"Badge non assegnati"**
   - Verifica la logica dei requisiti nella funzione `add_xp_simple`
   - Controlla che `requirement_type` e `requirement_value` siano corretti

3. **"XP non aggiornati"**
   - Verifica che l'utente esista nella tabella `users`
   - Controlla i log degli errori Supabase

### Debug

```tsx
// Abilita logging dettagliato
const debugAddXP = async (activity: string, amount: number) => {
  console.log('Adding XP:', { activity, amount, userId });
  
  try {
    const result = await supabase.rpc('add_xp_simple', {
      p_user_id: userId,
      p_activity_type: activity,
      p_xp_amount: amount
    });
    
    console.log('XP Result:', result);
    return result;
  } catch (error) {
    console.error('XP Error:', error);
    throw error;
  }
};
```

## 🎯 Prossimi Sviluppi

- [ ] Sistema di achievement complessi
- [ ] Badge stagionali/temporanei
- [ ] Competizioni tra utenti
- [ ] Ricompense fisiche per badge leggendari
- [ ] Integrazione con eventi reali della città
- [ ] Sistema di mentorship (utenti esperti aiutano novizi)

## 📞 Supporto

Per problemi o domande:
1. Controlla i log di Supabase
2. Verifica la console del browser
3. Testa con lo script `init-badge-system.js`
4. Consulta la documentazione Supabase per RLS e funzioni

---

**Buona gamification! 🎮🏆**