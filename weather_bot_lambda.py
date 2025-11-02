# @our_lovely_weather_bot
import json
import os
from datetime import datetime
import requests

OPENWEATHERMAP_ORG_APP_ID = os.environ.get('OPENWEATHERMAP_ORG_APP_ID')
TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

url_pref = 'https://api.openweathermap.org/data/2.5/weather?q='
url_postf = '&units=metric&appid='


def send_message(chat_id, text, reply_markup=None):
    """Send a message to Telegram chat"""
    url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {'chat_id': chat_id, "text": text}
    if reply_markup:
        payload['reply_markup'] = reply_markup
    response = requests.post(url, json=payload)
    return response.json()


def get_keyboard():
    """Create a custom keyboard with 4 city options"""
    keyboard = {
        "keyboard": [
            [{"text": "САЛОНИКИ", "callback_data": "Thessaloniki"}, 
             {"text": "СОФИЯ", "callback_data": "Sofia"}],
            [{"text": "МОСКВА", "callback_data": "Moscow"}, 
             {"text": "СТАМБУЛ", "callback_data": "Istanbul"}]
        ],
        "resize_keyboard": True,
        "one_time_keyboard": False
    }
    return keyboard


def windrose(deg):
    dirlist = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N']
    num = int(deg + 22.5) // 45
    return dirlist[num]


def send_photo_from_url(chat_id, photo_url, caption=None):
    """Send a photo from URL to Telegram chat"""
    url = f"{TELEGRAM_API_URL}/sendPhoto"
    payload = {
        'chat_id': chat_id,
        'photo': photo_url
    }
    if caption:
        payload['caption'] = caption
    
    response = requests.post(url, json=payload)
    return response.json()


def check_weather(user_text):
    url = url_pref + user_text.lower() + url_postf + OPENWEATHERMAP_ORG_APP_ID
    res = 'Should be a city on earth'
    
    try:
        response = requests.get(url)
        name = response.json()["name"]
        temp = str(int(round(response.json()["main"]["temp"])))
        pressure = str(int(response.json()["main"]["pressure"] * 0.75006375541921))
        humidity = str(response.json()["main"]["humidity"])
        wind = str(int(round(response.json()["wind"]["speed"])))
        wind_dir = windrose(response.json()["wind"]["deg"])
        icon = response.json()["weather"][0]["icon"]
        icon_url = 'https://openweathermap.org/img/wn/{}@4x.png'.format(icon)        
        tz = response.json()["timezone"]
        sunRise = datetime.fromtimestamp(response.json()["sys"]["sunrise"] + tz)
        sunSet = datetime.fromtimestamp(response.json()["sys"]["sunset"] + tz)
    except:
        return res,None

    res = '**' + name + '**\n'
    res += 'Температура: {}°С\n'.format(temp)
    res += 'Давление: {} мм\n'.format(pressure)
    res += 'Влажность: {}%\n'.format(humidity)
    res += 'Ветер: {} {} м/с\n'.format(wind_dir, wind)
    res += 'Солнце всходит: {:%H:%M}\n'.format(sunRise)
    res += 'Солнце заходит: {:%H:%M}\n'.format(sunSet)
    return res,icon_url


def send_weather_with_icon(chat_id, icon_url, caption=None):
    """Send weather info with weather icon image"""
    url = f"{TELEGRAM_API_URL}/sendPhoto"
    
    # Create caption with weather information if not provided
    if not caption:
        caption = f"Weather Info"
    
    payload = {
        'chat_id': chat_id,
        'photo': icon_url,
        'caption': caption,
        'parse_mode': 'HTML'  # Allows HTML formatting in caption
    }
    
    response = requests.post(url, json=payload)
    return response.json()


def lambda_handler(event, context):
    """Main handler function for AWS Lambda"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        if 'message' not in body:
            return {'statusCode': 200, 'body': json.dumps('No message found')}
        
        message = body['message']
        chat_id = message['chat']['id']
        
        # Handle /start command
        if "text" in message and message["text"] == '/start':
            welcome_text = "Welcome! Please select a city from the keyboard below:"
            keyboard = get_keyboard()
            send_message(chat_id, welcome_text, keyboard)
            return {'statusCode': 200, 'body': json.dumps('Start command processed')}
        
        # Handle text messages
        if "text" in message:
            user_text = message["text"]
            # valid_cities = ['Istanbul', 'Moscow', 'Sofia', 'Thessaloniki']
            
            response_text,icon_url = check_weather(user_text)
            send_weather_with_icon(chat_id, icon_url, response_text)

        return {'statusCode': 200, 'body': json.dumps('Message processed successfully')}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps(f'Error: {str(e)}')}
