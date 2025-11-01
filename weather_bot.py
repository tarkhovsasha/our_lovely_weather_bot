# @our_lovely_weather_bot
import telebot
from datetime import datetime
import requests

TOKEN = value
url_pref = 'https://api.openweathermap.org/data/2.5/weather?q='
url_postf = '&units=metric&appid='

bot = telebot.TeleBot(TOKEN)

keyboard = telebot.types.InlineKeyboardMarkup()
button1 = telebot.types.InlineKeyboardButton(text="МОСКВА", callback_data='Moscow')
button2 = telebot.types.InlineKeyboardButton(text="СОФИЯ", callback_data='Sofia')
button3 = telebot.types.InlineKeyboardButton(text="САЛОНИКИ", callback_data='Thessaloniki')
button4 = telebot.types.InlineKeyboardButton(text="СТАМБУЛ", callback_data='Istanbul')
keyboard.row(button1, button2, button3, button4)

def windrose(deg):
    dirlist = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'N']
    num = int(deg + 22.5) // 45
    return dirlist[num]

@bot.message_handler(content_types=['text'])
def get_text_messages(message):
    url = url_pref + message.text.lower() + url_postf
    res = 'Что-то пошло не так :('
    try:
        response = requests.get(url)
        name = response.json()["name"]
        temp = str(int(round(response.json()["main"]["temp"] - 273.15)))
        pressure = str(int(response.json()["main"]["pressure"] * 0.75006375541921))
        humidity = str(response.json()["main"]["humidity"])
        wind = str(int(round(response.json()["wind"]["speed"])))
        wind_dir = windrose(response.json()["wind"]["deg"])
        icon = response.json()["weather"][0]["icon"]
        icon_url = 'https://openweathermap.org/img/wn/{}@4x.png'.format(icon)        
        tz = response.json()["timezone"]
        sunRise = datetime.fromtimestamp(response.json()["sys"]["sunrise"] + tz)
        sunSet = datetime.fromtimestamp(response.json()["sys"]["sunset"] + tz)
        res = '**' + name + '**\n'
        res += 'Температура: {}°С\n'.format(temp)
        res += 'Давление: {} мм\n'.format(pressure)
        res += 'Влажность: {}%\n'.format(humidity)
        res += 'Ветер: {} {} м/с\n'.format(wind_dir, wind)
        res += 'Солнце всходит: {:%H:%M}\n'.format(sunRise)
        res += 'Солнце заходит: {:%H:%M}\n'.format(sunSet)
        bot.send_photo(message.from_user.id, icon_url)
        bot.send_message(message.from_user.id, res, reply_markup=keyboard)
    except:
        bot.send_message(message.from_user.id, "Should be a city on earth", reply_markup=keyboard)
    
@bot.callback_query_handler(func=lambda call: True)
def callback_function1(callback_obj):
    url = url_pref + callback_obj.data + url_postf
    res = 'Что-то пошло не так :('
    try:
        response = requests.get(url)
        name = response.json()["name"]
        temp = str(int(round(response.json()["main"]["temp"] - 273.15)))
        pressure = str(int(response.json()["main"]["pressure"] * 0.75006375541921))
        humidity = str(response.json()["main"]["humidity"])
        wind = str(int(round(response.json()["wind"]["speed"])))
        wind_dir = windrose(response.json()["wind"]["deg"])
        icon = response.json()["weather"][0]["icon"]
        icon_url = 'https://openweathermap.org/img/wn/{}@4x.png'.format(icon)        
        tz = response.json()["timezone"]
        sunRise = datetime.fromtimestamp(response.json()["sys"]["sunrise"] + tz)
        sunSet = datetime.fromtimestamp(response.json()["sys"]["sunset"] + tz)
        res = '**' + name + '**\n'
        res += 'Температура: {}°С\n'.format(temp)
        res += 'Давление: {} мм\n'.format(pressure)
        res += 'Влажность: {}%\n'.format(humidity)
        res += 'Ветер: {} {} м/с\n'.format(wind_dir, wind)
        res += 'Солнце всходит: {:%H:%M}\n'.format(sunRise)
        res += 'Солнце заходит: {:%H:%M}\n'.format(sunSet)
        bot.send_photo(callback_obj.from_user.id, icon_url)
        bot.send_message(callback_obj.from_user.id, res, reply_markup=keyboard)
    except:
        bot.send_message(message.from_user.id, "Пол года плохая погода", reply_markup=keyboard)
    bot.answer_callback_query(callback_query_id=callback_obj.id)

bot.infinity_polling()
