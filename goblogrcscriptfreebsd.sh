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