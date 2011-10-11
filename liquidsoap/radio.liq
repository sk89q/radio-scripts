#!/usr/local/bin/liquidsoap
#
# Copyright (c) 2008-2011 sk89q <http://www.sk89q.com>
# Available under GNU Lesser General Public License v3 or WTFPL
#

base_dir = "/home/radio/liquidsoap/"
automation_dir = "/home/radio/automation/"
source_pass = "CHANGEME"
telnet_port = 10000

# ----------------------------------------
# Configuration
# ----------------------------------------

set("decoding.buffer_length", 20.)
set("frame.channels", 2)
set("frame.samplerate", 44100)
set("harbor.icy", false)
set("harbor.bind_addr", "0.0.0.0")
set("harbor.port", 8004)
set("init.daemon.pidfile.path", base_dir^"<script>.pid")
set("log.file", true)
set("log.file.append", true)
set("log.file.path", base_dir^"<script>.log")
set("log.file.perms", 644)
set("log.level", 3)
set("log.stdout", true)
set("server.telnet", true)
set("server.telnet.bind_addr", "127.0.0.1")
set("server.telnet.port", telnet_port)

# ----------------------------------------
# Functions
# ----------------------------------------

def cfade(a, b)
    add(normalize=false,
        [sequence([blank(duration=1.),
                     fade.initial(duration=1., b)]),
        fade.final(duration=2., a)])
end

def automation(~path, ~harbor)
    request(get_process_output(automation_dir^path^".py "^quote(harbor)))
end

def login(~harbor, user, pass)
    test_process(automation_dir^"login.py "^quote(harbor)^" "^quote(pass)) 
end

def fix_metadata(s)
    rewrite_metadata(insert_missing=true,
                     [("song", '$(if $(display_title),"$(display_title) [NOT LIVE]","$(artist) - $(title) [NOT LIVE]")')],
                     s)
end

def log_metadata(~stream, metadata)
    print("######TEST######")
    print(list.assoc("song", metadata))
    print(list.assoc("dj", metadata))
end

def do_skip_cmd(s)
    source.skip(s)
    "Skipped!"
end

# ----------------------------------------
# Standard sources
# ----------------------------------------

# If the stream fails, we'll just play nothing...
s_blank = blank(id="blank", duration=1.)
s_blank = mksafe(s_blank) # This is assured to be safe!

# ----------------------------------------
# Primary
# ----------------------------------------

def rewrite_dj(~harbor, metadata)
    dj = list.hd(get_process_lines(automation_dir^"getlogin.py "^quote(harbor)))
    [("dj", dj)]
end

def add_dj(s)
    rewrite_metadata(insert_missing=true,
                     [("song", '$(if $(song),"$(song) [DJ: $(dj)]", "Live program/Unknown track [DJ: $(dj)]")')],
                     s)
end

# Use Last.FM has a fallback. Currently Last.FM is not compiled into the
# Liquidsoap binary that we are using, so we can't use this yet.
#s_lastfm = input.lastfm(id="LASTFM", autostart=false, "lastfm://globaltags/rock")

# For when there is no DJ and no Last.FM, we'll use our scheduling
# system.
s_primary_playlist = request.dynamic(id="playlist", length=60.,
    default_duration=60., timeout=20.,
    {automation(harbor="primary", path="getnext")})
store_metadata(id="primary_playlist", s_primary_playlist)

# Now for DJs to get in.
s_primary0 = input.harbor(id="primary0", auth=fun(user, pass) -> login(harbor="primary0", user, pass), "primary0")
s_primary1 = input.harbor(id="primary1", auth=fun(user, pass) -> login(harbor="primary1", user, pass), "primary1")
s_primary2 = input.harbor(id="primary2", auth=fun(user, pass) -> login(harbor="primary2", user, pass), "primary2")

# Eat blanks
s_primary0 = eat_blank(s_primary0)
s_primary1 = eat_blank(s_primary1)
s_primary2 = eat_blank(s_primary2)

# Add in DJ information
s_primary0 = map_metadata(fun(metadata) -> rewrite_dj(harbor="primary0", metadata), s_primary0)
s_primary1 = map_metadata(fun(metadata) -> rewrite_dj(harbor="primary1", metadata), s_primary1)
s_primary2 = map_metadata(fun(metadata) -> rewrite_dj(harbor="primary2", metadata), s_primary2)

# Pull together the harbors
s_primary = fallback(track_sensitive=false,
    transitions=[cfade, cfade, cfade],
    [s_primary0, s_primary1, s_primary2])
s_primary = add_dj(s_primary)

# Add in random promotion clips.
s_primary_promo = request.dynamic(id="promo", length=60., default_duration=60.,
    timeout=20., {automation(harbor="primary", path="getpromo")})
s_primary_promo_timed = delay(900., s_primary_promo)
map_metadata(fun(metadata) -> [("display_title", "You are listening to CHANGEME Radio")], s_primary_promo)

# Promo+playlist (we need it track_sensitive).
s_primary_playlist_promo = fallback(track_sensitive=true,
    [s_primary_promo_timed, s_primary_playlist])
s_primary_playlist_promo = fix_metadata(s_primary_playlist_promo) # Fix metadata

# Build the output.
primary_out = fallback(track_sensitive=false,
    transitions=[cfade, cfade],
    [s_primary, s_primary_playlist_promo, s_blank])
store_metadata(id="primary_out", primary_out)
#on_metadata(fun(metadata) -> log_metadata(stream="primary", metadata), primary_out)
                   
server.register(namespace="",
    usage="doskip",
    description = "Skip song on primary praylist",                
    "doskip",
    fun(_) -> do_skip_cmd(s_primary_playlist))

# Send it off
output.icecast.mp3(id="primary_out_mp3_112",
                   host="localhost", port=8000,
                   mount="/main.mp3",
                   password=source_pass,
                   name="CHANGEME Radio (112 kbps MP3)",
                   description="Music",
                   genre="Music",
                   url="http://CHANGEME",
                   public=false,
                   restart=true,
                   restart_delay=3,
                   samplerate=44100, bitrate=64, quality=5, stereo=true,
                   protocol="http",
                   primary_out)
output.icecast.aacplusenc(id="primary_out_aac_64",
                   host="localhost", port=8000,
                   mount="/main.aac",
                   password=source_pass,
                   name="CHANGEME Radio (64 kbps AAC+)",
                   description="Music",
                   genre="Music",
                   url="http://CHANGEME",
                   public=false,
                   restart=true,
                   restart_delay=3,
                   restart_encoder_delay=-1,
                   aacplusenc="/usr/local/bin/aacplusenc",
                   bitrate=64,
                   protocol="http",
                   primary_out)
output.icecast.aacplusenc(id="primary_out_aac_16",
                   host="localhost", port=8000,
                   mount="/main-low.aac",
                   password=source_pass,
                   name="CHANGEME Radio (16 kbps AAC+)",
                   description="Music",
                   genre="Music",
                   url="http://CHANGEME",
                   public=false,
                   restart=true,
                   restart_delay=3,
                   restart_encoder_delay=-1,
                   aacplusenc="/usr/local/bin/aacplusenc",
                   bitrate=16,
                   protocol="http",
                   primary_out)