#!/bin/sh

# Permission to use, copy, modify, and/or distribute this software for
# any purpose with or without fee is hereby granted.

# THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL
# WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES
# OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE
# FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY
# DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN
# AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT
# OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# Install required packages
pkg install go-devel git gcc sqlite3 bash tor python3 py39-yaml

# Clone GoBlog repository
git clone https://github.com/jlelse/GoBlog.git
cd GoBlog

# Build GoBlog
go-devel build -tags=sqlite_fts5 -ldflags '-w -s' -o GoBlog

# Install GoBlog
install -m 755 GoBlog /usr/local/bin/GoBlog

# Create required directories
directories="
  /var/GoBlog
  /var/GoBlog/pkgs
  /var/GoBlog/logo
  /var/GoBlog/testdata
  /var/GoBlog/leaflet
  /var/GoBlog/hlsjs
  /var/GoBlog/dbmigrations
  /var/GoBlog/strings
  /var/GoBlog/plugins
  /var/GoBlog/templates
  /var/GoBlog/config
  /var/GoBlog/data
"

for dir in $directories; do
  mkdir -p "$dir"
done

# Copy required files and directories
# Note that /config and /data are persistent across versions of GoBlog, ie.
# if goblog is updated, these folders will need ot remain the same in order to 
# preserve all user data. In the Linux docker setup process these are mounted as 
# external volumes. On a freebsd setup the exact way in which this data is preserved may vary 

cp -R pkgs testdata templates leaflet hlsjs dbmigrations strings plugins /var/GoBlog/
cp logo/GoBlog.png /var/GoBlog/logo/GoBlog.png

# Write the script that generates the config.yaml file to the target file
cat > goblogcfggen.py << 'EOF'
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

reverse_proxy_input = input("Is GoBlog being used with a reverse proxy such as Caddy or Nginx? A reverse proxy configuration is strongly recomended. Note, this script assumes that GoBlog is being ran under a jail or similar, and thus either way http is listening on port 80. This configuration option decide if a listener on https is set up, and if SSL certs are requested from LetsEncrypt (Y/n): ")
reverse_proxy = reverse_proxy_input.lower() not in ["n", "no"]

server_config = {
    "logging": True,
    "logFile": "data/access.log",
    "port": 80,
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
EOF

chmod +x goblogcfggen.py

# Prompt the user to see if the user wants to use the example config file or generate one
printf "Choose an option for the GoBlog config file:\n"
printf "  1) Use the default config file\n"
printf "  2) Use a setup wizard to generate a config file\n"
printf "  3) Set no config file\n"
printf "Enter your choice (1, 2, or 3): "
read -r answer

# Process the user's choice
case "$answer" in
  1)
    # Use the default config file
    cp example-config.yml /var/GoBlog/config/config.yml
    echo "Default config file copied to /var/GoBlog/config/config.yml"
    ;;
  2)
    # Use a setup wizard to generate a config file
    python3 goblogcfggen.py
    cp config.yml /var/GoBlog/config/config.yml
    ;;
  3)
    # Do nothing if the user chooses no config file
    echo "No config file will be used."
    ;;
  *)
    # Display an error message for an invalid choice
    echo "Invalid choice. No changes made."
    ;;
esac

# Cleaning up and removing no longer needed source code files downloaded from Git
cd ..
rm -rf GoBlog

#Creating the rc script 
# Set the target file for the rc script
rc_script_file="/usr/local/etc/rc.d/goblog"

# Write the rc script to the target file
cat > "$rc_script_file" << 'EOF'
#!/bin/sh

# PROVIDE: goblog
# REQUIRE: DAEMON
# KEYWORD: shutdown

. /etc/rc.subr

name="goblog"
rcvar="${name}_enable"

# Set the default value for the goblog_enable variable
: ${goblog_enable:="NO"}

# Set the command to run and the required environment variable
command="/usr/local/bin/GoBlog"
command_args=">/dev/null 2>&1 &"
export PATH="/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin:/root/bin"

# Set the working directory for the GoBlog service
goblog_chdir="/var/GoBlog"

# Load the service configuration
load_rc_config "$name"

# Run the service in the background
start_precmd="goblog_precmd"
goblog_precmd()
{
  command_args="${command_args}"
}

# Add the service to the rc system
run_rc_command "$@"
EOF

# Make the rc script file executable
chmod +x "$rc_script_file"


# Prompt the user
printf "Do you want GoBlog to start when the system does? (y/N): "
read -r answer

# Check the user's answer
case "$answer" in
  [yY]|[yY][eE][sS])
    # Enable GoBlog service
    echo 'goblog_enable="YES"' >> /etc/rc.conf
    echo "GoBlog service enabled."
    ;;
  *)
    # Do nothing if the answer is not 'yes'
    echo "No changes made."
    ;;
esac

# Printing out notes to the terminal 

printf "The Goblog setup is now complete. If you told the script to, a config file has been created at /var/GoBlog/config/config.yml"
printf "Most of the other data data can be found in /var/GoBlog/"
printf "Goblog can be loaded with the GoBlog command (the binary has been copied to /usr/local/bin/GoBlog)"