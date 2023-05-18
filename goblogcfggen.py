import yaml

config = {}

# Debug
debug_input = input("Should GoBlog be set in debug mode? (y/N): ")
config["debug"] = debug_input.lower() in ["y", "yes"]

# Pprof
pprof_input = input("Enable Pprof profiling? (y/N): ")
pprof_enabled = pprof_input.lower() in ["y", "yes"]

config["pprof"] = {
    "enabled": pprof_enabled,
    "address": ":6060" if pprof_enabled else None
}

# Database
config["database"] = {
    "file": "data/db.sqlite",
    "dumpFile": "data/db.sql",
    "debug": False
}

# Web server configuration
public_address_input = input("What is the public address of the blog? (default: https://example.com): ")
public_address = public_address_input if public_address_input else "https://example.com"

reverse_proxy_input = input("Is GoBlog being used with a reverse proxy such as Caddy or Nginx? (Y/n): ")
reverse_proxy = reverse_proxy_input.lower() not in ["n", "no"]

server_config = {
    "logging": True,
    "logFile": "data/access.log",
    "port": 80 if reverse_proxy else 8080,
    "publicAddress": public_address,
    "publicHttps": not reverse_proxy,
    "cspDomains": ["media.example.com"],
    "tor": True,
    "torSingleHop": True
}

if not reverse_proxy:
    server_config["shortPublicAddress"] = f"https://short.{public_address}"
    server_config["mediaAddress"] = f"https://media.{public_address}"
    server_config["httpsCert"] = "/path/to/cert.crt"
    server_config["httpsKey"] = "/path/to/key.key"
    server_config["httpsRedirect"] = True
    server_config["securityHeaders"] = True

config["server"] = server_config

# Cache configuration
cache_config = {
    "enable": True,
    "expiration": 600
}
config["cache"] = cache_config

# Private mode configuration
private_mode_config = {
    "enabled": False
}
config["privateMode"] = private_mode_config

# IndexNow configuration
index_now_config = {
    "enabled": True
}
config["indexNow"] = index_now_config

# User configuration
user_name = input("What is your full name? ")
user_nick = input("What is your username/nick? ")
user_password = input("What is your password? ")
user_email = input("What is your email address? ")

user_config = {
    "name": user_name,
    "nick": user_nick,
    "password": user_password,
    "email": user_email
}
config["user"] = user_config

# Hooks configuration
hooks_config = {
    "shell": "/bin/bash",
    "hourly": ["echo hourly"],
    "prestart": ["echo pass"],
    "postpost": ["echo pass"],
    "postupdate": ["echo pass"],
    "postdelete": ["echo pass"],
    "postundelete": ["echo pass"]
}
config["hooks"] = hooks_config

# ActivityPub configuration
activity_pub_config = {
    "enabled": True,
    "tagsTaxonomies": ["tags"]
}
config["activityPub"] = activity_pub_config

# Webmention configuration
webmention_config = {
    "disableSending": False,
    "disableReceiving": False
}
config["webmention"] = webmention_config

# MicroPub configuration
micropub_config = {
    "replyParam": "replylink",
    "replyTitleParam": "replytitle",
    "likeParam": "likelink",
    "likeTitleParam": "liketitle",
    "bookmarkParam": "link",
    "audioParam": "audio",
    "photoParam": "images",
    "photoDescriptionParam": "imagealts",
    "locationParam": "location"
}
config["micropub"] = micropub_config

# Ask user for Ntfy configuration
use_ntfy = input("Do you want to use ntfy for push notifications? (y/n): ").lower()
if use_ntfy == 'y':
    ntfy_topic = input("Enter the topic for ntfy notifications: ")
    ntfy_server = input("Enter the server for ntfy (default is https://ntfy.sh): ") or "https://ntfy.sh"
    ntfy_config = {
        "enabled": True,
        "topic": ntfy_topic,
        "server": ntfy_server
    }
else:
    ntfy_config = {"enabled": False}

# Ask user for Telegram configuration
use_telegram = input("Do you want to enable Telegram notifications? (y/n): ").lower()
if use_telegram == 'y':
    telegram_chat_id = input("Enter the Telegram chat ID: ")
    telegram_bot_token = input("Enter the Telegram bot token: ")
    telegram_config = {
        "enabled": True,
        "chatId": telegram_chat_id,
        "botToken": telegram_bot_token
    }
else:
    telegram_config = {"enabled": False}

# Add notifications to the config
config["notifications"] = {
    "ntfy": ntfy_config,
    "telegram": telegram_config
}

# Add pathRedirects to the config
config["pathRedirects"] = [
    {
        "from": "\\/index\\.xml",
        "to": ".rss"
    },
    {
        "from": "^\\/(writings|dev)\\/posts(.*)$",
        "to": "/$1$2",
        "type": 301
    }
]

# Add mapTiles to the config
config["mapTiles"] = {
    "source": "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    "attribution": "&copy; <a href=\"https://www.openstreetmap.org/copyright\">OpenStreetMap</a> contributors",
    "minZoom": 0,
    "maxZoom": 20
}

# Ask user for Text-to-Speech configuration
use_tts = input("Do you want to enable Text-to-Speech with Google Cloud TTS-API? (y/n): ").lower()
if use_tts == 'y':
    google_api_key = input("Enter your Google API Key: ")
    tts_config = {
        "enabled": True,
        "googleApiKey": google_api_key
    }
else:
    tts_config = {"enabled": False}

# Add Text-to-Speech to the config
config["tts"] = tts_config

# Add Reactions to the config
config["reactions"] = {
    "enabled": True
}

# Ask user for default blog details
default_blog = input("Enter the default blog name (used as the username for ActivityPub endpoints): ")
blog_title = input("Enter the blog title: ")
blog_description = input("Enter the blog description: ")

# Add Blogs to the config
config["defaultBlog"] = default_blog
config["blogs"] = {
    default_blog: {
        "path": "/",
        "lang": "en",
        "title": blog_title,
        "description": blog_description,
        "pagination": 10,
        "taxonomies": [
            {
                "name": "tags",
                "title": "Tags",
                "description": "**Tags** on this blog"
            }
        ],
        "menus": {
            "main": {
                "items": [
                    {
                        "title": "Home",
                        "link": "/"
                    }
                ]
            }
        },
        "photos": {
            "enabled": True,
            "path": "/photos",
            "title": "Photos",
            "description": "Instead of using Instagram, I prefer uploading pictures to my blog."
        },
        "search": {
            "enabled": True,
            "title": "Search",
            "path": "/search",
            "placeholder": "Search on this blog"
        },
        "blogStats": {
            "enabled": True,
            "path": "/statistics",
            "title": "Statistics",
            "description": "Here are some statistics with the number of posts per year:"
        },
        "randomPost": {
            "enabled": True,
            "path": "/random"
        },
        "onThisDay": {
            "enabled": True,
            "path": "/onthisday"
        },
        "comments": {
            "enabled": True
        },
        "map": {
            "enabled": True,
            "path": "/map"
        }
    }
}

# Ask user for footer item title and link
footer_title = input("Enter the footer item title: ")
footer_link = input("Enter the footer item link: ")

# Add footer menu to the config
config["blogs"][default_blog]["menus"]["footer"] = {
    "items": [
        {
            "title": footer_title,
            "link": footer_link
        }
    ]
}

# Save the config to a YAML file
with open("config.yml", "w") as config_file:
    yaml.dump(config, config_file)

print("Config file generated as config.yml.")