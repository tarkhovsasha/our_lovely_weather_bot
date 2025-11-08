# our_lovely_weather_bot

<!-- ABOUT THE PROJECT -->
## About The Project

A Telegram bot that provides current weather information for one of the user's chosen cities. City selection can be done using buttons. As an example, 4 cities from three different time zones are offered. There is also the ability to enter a city name manually (however, it is not guaranteed that weather data for this city can be retrieved).

The bot displays the current weather for the selected city. The bot's response contains the following data:

* Atmospheric condition (clear, cloudy, precipitation, etc.). This information is displayed as an icon. The send_photo method from the telebot module is used to send the image
* Temperature (in degrees Celsius)
* Pressure (in mmHg)
* Humidity (in percentage)
* Wind speed (in m/s)
* Wind direction (N, S, E, W, NW, NE, SW, SE)
* Sunrise time (hours and minutes)
* Sunset time (hours and minutes)

Link to the actual bot in Telegram: [t.me/our_lovely_weather_bot](https://t.me/our_lovely_weather_bot)

### Built With

* python3
* telebot module
* requests module
* datetime module


### Acknowledgements

* [https://openweathermap.org/](https://openweathermap.org/)

