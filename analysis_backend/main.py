from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import openai
import os
from dotenv import load_dotenv
import requests
from datetime import datetime
from typing import List, Optional

# .env'den API anahtarını oku
load_dotenv()
client = openai.OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

app = FastAPI()

class AnalysisRequest(BaseModel):
    coin_name: str
    rsi: float
    macd: str
    volume: float
    custom_prompt: Optional[str] = None

class ChartCandle(BaseModel):
    timestamp: int
    open: float
    high: float
    low: float
    close: float
    volume: float

@app.post("/analyze")
async def analyze(request: AnalysisRequest):
    # Teknik göstergelere göre ön değerlendirme yap
    rsi_signal = ""
    if request.rsi > 70:
        rsi_signal = "overbought (potentially bearish)"
    elif request.rsi < 30:
        rsi_signal = "oversold (potentially bullish)"
    else:
        rsi_signal = "neutral zone"
    
    # MACD sinyali
    macd_signal = "bullish momentum" if request.macd.lower() == "pozitif" else "bearish momentum"
    
    # Volume analizi
    volume_analysis = "high volume" if request.volume > 50000000 else "low volume"
    
    # Eğer custom_prompt varsa onu kullan, yoksa İngilizce formatı kullan
    if request.custom_prompt:
        prompt = request.custom_prompt
    else:
        prompt = (
            f"Perform an OBJECTIVE technical analysis for {request.coin_name}:\n\n"
            f"Technical Indicators:\n"
            f"• RSI: {request.rsi} ({rsi_signal})\n"
            f"• MACD: {request.macd} ({macd_signal})\n"
            f"• Volume: {request.volume:,.0f} ({volume_analysis})\n\n"
            f"IMPORTANT: Be brutally honest and objective. Don't be overly optimistic. "
            f"If indicators suggest bearish conditions, clearly state it. "
            f"If RSI is overbought (>70), lean towards bearish analysis. "
            f"If RSI is oversold (<30), consider bullish potential but mention risks."
        )

    try:
        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system", 
                    "content": (
                        "You are a CONSERVATIVE cryptocurrency technical analyst with 15+ years of experience. "
                        "CRITICAL: Always respond in English only. "
                        "BE OBJECTIVE AND REALISTIC - don't be overly bullish or optimistic. "
                        "Your job is to provide balanced, honest analysis that considers both upside AND downside risks. "
                        "\n\nANALYSIS RULES:\n"
                        "• RSI >70 = OVERBOUGHT → Lean bearish, warn of potential correction\n"
                        "• RSI <30 = OVERSOLD → Cautiously bullish but mention bounce risks\n"
                        "• RSI 30-70 = NEUTRAL → Analyze other indicators\n"
                        "• Always mention BOTH opportunities AND risks\n"
                        "• Use terms like 'bearish', 'bullish', 'neutral', 'caution' appropriately\n"
                        "• Don't sugar-coat negative indicators\n"
                        "• Be specific about entry/exit points\n"
                        "\nStructure your response:\n"
                        "1) Market Condition (bullish/bearish/neutral)\n"
                        "2) Technical Analysis\n"
                        "3) Trading Strategy\n"
                        "4) Risk Management"
                    )
                },
                {"role": "user", "content": prompt}
            ],
            max_tokens=450,
            temperature=0.4  # Daha az yaratıcı, daha objektif
        )

        return {"analysis": response.choices[0].message.content}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Analysis failed: {str(e)}")

@app.get("/chart_data")
async def get_chart_data(symbol: str, interval: str = "1d", limit: int = 100):
    """
    Binance API'sinden kline (candlestick) verilerini çeker
    """
    try:
        # Binance API URL
        base_url = "https://api.binance.com/api/v3/klines"
        
        # İnterval mapping
        interval_map = {
            "1m": "1m",
            "5m": "5m", 
            "15m": "15m",
            "30m": "30m",
            "1h": "1h",
            "4h": "4h",
            "1d": "1d",
            "1w": "1w"
        }
        
        binance_interval = interval_map.get(interval, "1d")
        
        # Sembol formatını Binance'e uygun hale getir (örn: BTC -> BTCUSDT)
        if not symbol.endswith("USDT"):
            symbol = symbol.upper() + "USDT"
        
        params = {
            "symbol": symbol,
            "interval": binance_interval,
            "limit": min(limit, 1000)  # Binance limiti max 1000
        }
        
        response = requests.get(base_url, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        # Binance kline formatını ChartCandle formatına çevir
        candles = []
        for kline in data:
            candle = {
                "timestamp": int(kline[0]),  # Open time
                "open": float(kline[1]),
                "high": float(kline[2]),
                "low": float(kline[3]),
                "close": float(kline[4]),
                "volume": float(kline[5])
            }
            candles.append(candle)
        
        return candles
        
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"API request failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching chart data: {str(e)}")

@app.get("/")
async def root():
    return {"message": "Crypto Analysis API is running"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.now().isoformat()}

@app.get("/popular_coins")
async def get_popular_coins():
    """Popüler coin listesini döndürür"""
    popular_coins = [
        "BTC", "ETH", "BNB", "ADA", "DOT", "SOL", "MATIC", "AVAX",
        "LINK", "UNI", "LTC", "XRP", "DOGE", "SHIB", "ATOM", "FTM"
    ]
    return popular_coins

@app.get("/current_price")
async def get_current_price(symbol: str):
    """Gerçek zamanlı fiyat bilgisini döndürür"""
    try:
        # Sembol formatını Binance'e uygun hale getir
        if not symbol.endswith("USDT"):
            symbol = symbol.upper() + "USDT"
        
        # Binance 24hr ticker endpoint
        url = f"https://api.binance.com/api/v3/ticker/24hr"
        params = {"symbol": symbol}
        
        response = requests.get(url, params=params, timeout=10)
        response.raise_for_status()
        
        data = response.json()
        
        return {
            "symbol": symbol,
            "price": float(data["lastPrice"]),
            "change_24h": float(data["priceChangePercent"]),
            "volume_24h": float(data["volume"]),
            "high_24h": float(data["highPrice"]),
            "low_24h": float(data["lowPrice"]),
            "timestamp": datetime.now().isoformat()
        }
        
    except requests.exceptions.RequestException as e:
        raise HTTPException(status_code=500, detail=f"Price API request failed: {str(e)}")
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error fetching price: {str(e)}")

@app.post("/custom_analysis")
async def custom_analysis(request: AnalysisRequest):
    """
    Özel analiz endpoint'i - daha detaylı analiz için
    """
    try:
        # Daha detaylı ve yapılandırılmış prompt
        detailed_prompt = (
            f"Perform a comprehensive technical analysis for {request.coin_name} "
            f"using these indicators:\n"
            f"• RSI: {request.rsi} (Relative Strength Index)\n"
            f"• MACD: {request.macd} direction\n"
            f"• Volume: {request.volume:,.0f}\n\n"
            f"Please provide a detailed analysis covering:\n"
            f"1. Current market sentiment based on RSI levels\n"
            f"2. MACD trend interpretation\n"
            f"3. Volume analysis and significance\n"
            f"4. Short-term trading strategy\n"
            f"5. Risk management recommendations\n"
            f"6. Price targets (support/resistance levels)"
        )

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {
                    "role": "system", 
                    "content": (
                        "You are an expert cryptocurrency technical analyst with 10+ years of experience. "
                        "IMPORTANT: Always respond in English only, never use any other language. "
                        "Provide professional, actionable trading insights. "
                        "Use specific technical analysis terminology. "
                        "Include numerical targets when possible. "
                        "Be objective about both bullish and bearish scenarios. "
                        "Format your response with clear sections and bullet points for readability."
                    )
                },
                {"role": "user", "content": detailed_prompt}
            ],
            max_tokens=600,
            temperature=0.6
        )

        return {"analysis": response.choices[0].message.content}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Custom analysis failed: {str(e)}")

@app.get("/market_overview")
async def get_market_overview():
    """
    Genel piyasa durumu için hızlı bir bakış
    """
    try:
        # Binance'den birkaç major coin'in fiyatlarını çek
        major_coins = ["BTCUSDT", "ETHUSDT", "BNBUSDT", "ADAUSDT"]
        market_data = []
        
        for symbol in major_coins:
            url = f"https://api.binance.com/api/v3/ticker/24hr"
            params = {"symbol": symbol}
            
            response = requests.get(url, params=params, timeout=5)
            if response.status_code == 200:
                data = response.json()
                market_data.append({
                    "symbol": symbol.replace("USDT", ""),
                    "price": float(data["lastPrice"]),
                    "change_24h": float(data["priceChangePercent"]),
                    "volume_24h": float(data["volume"])
                })
        
        return {
            "market_data": market_data,
            "timestamp": datetime.now().isoformat(),
            "total_coins": len(market_data)
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Market overview failed: {str(e)}")