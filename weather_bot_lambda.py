# @our_lovely_weather_bot
import json
import os
import requests

TELEGRAM_BOT_TOKEN = os.environ.get('TELEGRAM_BOT_TOKEN')
TELEGRAM_API_URL = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}"

def send_message(chat_id, text, reply_markup=None):
    """Send a message to Telegram chat"""
    url = f"{TELEGRAM_API_URL}/sendMessage"
    payload = {'chat_id': chat_id, 'text': text}
    if reply_markup:
        payload['reply_markup'] = reply_markup
    response = requests.post(url, json=payload)
    return response.json()

def get_keyboard():
    """Create a custom keyboard with 4 city options"""
    keyboard = {
        'keyboard': [
            [{'text': 'МОСКВА'}, {'text': 'СОФИЯ'}],
            [{'text': 'САЛОНИКИ'}, {'text': 'СТАМБУЛ'}]
        ],
        'resize_keyboard': True,
        'one_time_keyboard': False
    }
    return keyboard

def lambda_handler(event, context):
    """Main handler function for AWS Lambda"""
    try:
        body = json.loads(event.get('body', '{}'))
        
        if 'message' not in body:
            return {'statusCode': 200, 'body': json.dumps('No message found')}
        
        message = body['message']
        chat_id = message['chat']['id']
        
        # Handle /start command
        if 'text' in message and message['text'] == '/start':
            welcome_text = "Welcome! Please select a city from the keyboard below:"
            keyboard = get_keyboard()
            send_message(chat_id, welcome_text, keyboard)
            return {'statusCode': 200, 'body': json.dumps('Start command processed')}
        
        # Handle text messages
        if 'text' in message:
            user_text = message['text']
            valid_cities = ['London', 'Paris', 'Tokyo', 'New York']
            
            if user_text in valid_cities:
                response_text = f"You selected: {user_text}"
                send_message(chat_id, response_text)
            else:
                error_text = "Should be a city on earth"
                send_message(chat_id, error_text)
        
        return {'statusCode': 200, 'body': json.dumps('Message processed successfully')}
        
    except Exception as e:
        print(f"Error: {str(e)}")
        return {'statusCode': 500, 'body': json.dumps(f'Error: {str(e)}')}
