# ChatFilterAddon
This addon scans all incomming messages in all channels you have joined, looks for LFM messages, checks if the dungeon mentioned is within your level range and puts those messages into a chat window named "LFM". 

### How to use

1. Press "Clone or Download" on this page, choose "Download ZIP"
2. Extract "ChatFilterAddon-Master" into interface/addons/ folder
2. Remove "-master" from folder name
3. activate it in the addon menu before loggin into your character
4. Create a new chat window named "LFM". The name of the chat window is important and needs to be EXACTLY "LFM", as the addon always looks for a window named LFM. 
5. Optional: Join "world, LookingForMore" etc in a chat window (can be hidden)
Enjoy a cleaner channel without spam for dungeons you can't join :)

NB: YOU need to create the chat window named LFM yourself

## Update 0.3
- The addon now forwards LFM messages to a dedicated channel, and scans this channel as well. This means everyone with this addon will be able to se relevant LFM messages from all channels all players are in. For example: If _one_ player with this addon is in a town and someone writes "LFM DM" in Trade - City, every level 18-24 player with this addon will see the message. Regardless of where they are

### Troubleshooting

If it doesn't seem to be working

- Make sure you have made a chat window named "LFM"
- Make sure you have joined relevant channels like "world" and "LookingForMore". You can go into the settings and un-check them, the addon works as long as you have joined them, and not left

### Known Issues

- Scarlet Monestary is hard to filter correctly, it may show up even if level range is not within
