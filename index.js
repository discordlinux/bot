const client = new(require("discord.js").Client)
const {
    Slash
} = require("discord-slash-commands");
const slash = new Slash({
    client: client
})
require('dotenv').config();

slash.on("command", async (command) => {
    var cmd = JSON.stringify({ "name" :command.name, "id": command.id, "token": command.token, "type": command.type, "options": command.options, "member": command.member, "guildId": command.guild.id })
    console.log(cmd);
    if (command.name === "exit") {
    	if (command.member.user.id === process.env.owner_id){
		console.log('Disconnecting client...');
    		client.destroy();
    		console.log('Client disconnected.  Exiting...');
    		process.exit();
    	}
    }
})

client.on("ready", () => {
    console.log("Ready");
    client.user.setActivity('with slash commands', { type: 'PLAYING' });
})

client.login(process.env.token)
