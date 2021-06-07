# Discord Bash Bot For The [Discord Linux](https://discord.gg/discord-linux) Server

## About Bash Bot

This bot is very much a work in progress.  The core and few available commands are working, but may be changed to accommodate future needs.

This repository contains the source code for `@bot.sh` for the [Discord Linux](https://discord.gg/discord-linux) server.  This bot is not intended for use elsewhere as is.  If you would like to use this bot, it will require a bit of modification such as changing/removing the existing commands and setting up a realtime database on [Google Firebase](https://firebase.google.com/).

The backend for bash bot runs on nodejs using [discord.js](https://discord.js.org) and [discord-slash-commands](https://github.com/shadeoxide/discord-slash-commands).

On startup, bash bot creates a named pipe at `/tmp/.bashbot` to listen for output, and then the nodejs backend is started with its `stdout` redirected to the named pipe at `/tmp/.bashbot`.  The output from the nodejs backend uses this format:

```
{
  "name": "ping",
  "id": "851338272415416320",
  "token": "aW50ZXJhY3Rpb246ODUxMzM4MjcyNDE1NDE2MzIwOmZJYzVwdG42cHlHZHl1SnRkS0VWNzVrWlQ1Slp0dGVUUUpJMHN6bkRHOUN6R01ZZGp6aUl6YzFaNWxza1J1ek9rclFsYXJlUjdiVjYwNllUbVoxbXd6dFlBU2RMT1pic3liYUxhaEE4cU51aDFRd0FiMDlyMXdLdEs4UFhpaWM4",
  "type": 2,
  "member": {
    "user": {
      "username": "Syretia",
      "public_flags": 640,
      "id": "86201442112671744",
      "discriminator": "4268",
      "avatar": "fb76f500b4d6b0f05ae1bb470d511a83"
    },
    "roles": [
      "204077487657975808",
      "437040802393489408",
      "459245940876771328",
      "501257816015634452"
    ],
    "premium_since": null,
    "permissions": "137438953471",
    "pending": false,
    "nick": null,
    "mute": false,
    "joined_at": "2016-07-17T02:27:21.613000+00:00",
    "is_pending": false,
    "deaf": false,
    "avatar": null
  },
  "guildId": "204061452707954688"
}
```

If the `.name` from the slash command used matches a script found in the `commands` directory, the script will be sourced by the main script with the output from the nodejs backend passed to it as an argument.

## Installation

To use the core of the bot, you will need `jq`, `npm`, `node` (only tested with version 14.17.0), and, of course, `bash`.  The commands all require at least `curl` in order to use Discord's API and may also have additional dependencies.

To install bash bot, run the following commands in a terminal:

```
git clone https://github.com/discordlinux/bot
cd ./bot
npm install
cp ./.env.example ./.env
```

After running the above commands, open the `.env` file you just copied in the editor of your choice and fill out the `token`, `client_id`, and `owner_id` variables.

## Running Bash Bot

After installing bash bot by following the instructions above, simply run the `bashbot.sh` script in a terminal.
