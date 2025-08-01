// Simple test script to verify the weather API is working
const fetch = require('node-fetch');

const username = "vishu_singh_vishu";
const password = "VEizNBC1995V6wELi1h2";

async function testWeatherAPI() {
  const coords = "43.3062,13.7231"; // Civitanova Marche
  const now = new Date().toISOString().split('.')[0] + "Z";
  const url = `https://api.meteomatics.com/${now}/t_2m:C,wind_speed_10m:ms,precip_1h:mm,relative_humidity_2m:p/${coords}/json`;
  
  try {
    console.log("🌤️  Testing Meteomatics API for Civitanova Marche...");
    console.log("📍 Coordinates:", coords);
    console.log("🕐 Timestamp:", now);
    console.log("🔗 URL:", url);
    console.log("");
    
    const response = await fetch(url, {
      headers: {
        "Authorization": "Basic " + Buffer.from(username + ":" + password).toString('base64'),
      }
    });
    
    if (!response.ok) {
      throw new Error(`API Error: ${response.status} - ${response.statusText}`);
    }
    
    const data = await response.json();
    
    // Extract weather data
    const temperature = Math.round(data.data.find(p => p.parameter === "t_2m:C").coordinates[0].dates[0].value);
    const windSpeedMs = data.data.find(p => p.parameter === "wind_speed_10m:ms").coordinates[0].dates[0].value;
    const windSpeed = Math.round(windSpeedMs * 3.6); // Convert m/s to km/h
    const precipitation = data.data.find(p => p.parameter === "precip_1h:mm").coordinates[0].dates[0].value;
    const humidity = Math.round(data.data.find(p => p.parameter === "relative_humidity_2m:p").coordinates[0].dates[0].value);
    
    console.log("✅ API Response successful!");
    console.log("🌡️  Temperature:", temperature + "°C");
    console.log("💨 Wind Speed:", windSpeed + " km/h (" + windSpeedMs.toFixed(1) + " m/s)");
    console.log("🌧️  Precipitation:", precipitation + " mm");
    console.log("💧 Humidity:", humidity + "%");
    console.log("");
    
    // Determine weather condition
    let condition = "Soleggiato";
    let emoji = "☀️";
    
    if (precipitation > 0.5) {
      if (precipitation > 5) {
        condition = "Pioggia intensa";
        emoji = "🌧️";
      } else {
        condition = "Pioggia leggera";
        emoji = "🌦️";
      }
    } else if (windSpeed > 15) {
      condition = "Ventoso";
      emoji = "💨";
    } else if (temperature > 25) {
      condition = "Soleggiato";
      emoji = "☀️";
    } else if (temperature > 15) {
      condition = "Nuvoloso";
      emoji = "☁️";
    } else {
      condition = "Freddo";
      emoji = "🌫️";
    }
    
    console.log("🎯 Weather Condition:", condition, emoji);
    console.log("🌊 Sea Condition:", windSpeed < 5 ? "Mare calmo" : windSpeed < 15 ? "Mare mosso" : "Mare agitato");
    console.log("");
    console.log("🎉 Weather API test completed successfully!");
    
  } catch (error) {
    console.error("❌ Error testing weather API:", error.message);
    console.log("");
    console.log("🔧 Troubleshooting tips:");
    console.log("1. Check internet connection");
    console.log("2. Verify API credentials");
    console.log("3. Check if Meteomatics API is accessible");
  }
}

testWeatherAPI();