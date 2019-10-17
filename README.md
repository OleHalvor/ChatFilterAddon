# ChatFilterAddon

Latest version is 0.9: https://github.com/OleHalvor/ChatFilterAddon/releases/download/0.8/ChatFilterAddon.zip

## Main Features of this addon:
1. Scans all of your joined chat channels for relevant dungeons and copies those messages to a seperate chat window named "LFM"
2. Shares messages with other users of the addon. If someone whith this addon is in a city and someone types "LFM BRD" in [Trade - City], you will also see this message in your LFM window, regardless of where you are.

### How to use

1. Install the latest released version: https://github.com/OleHalvor/ChatFilterAddon/releases/download/0.6/ChatFilterAddon.zip
2. Create a new chat window named "LFM".
#### Enjoy a cleaner channel without spam for dungeons you can't join :)

NB: YOU need to create the chat window named LFM yourself

### Minor Features:
- Has options in blizzards addon menu. System Settings -> interface options -> addons -> ChatFilterAddon
- Looks for LFM messages if you are not in a party. Looks for LFG messages if you are in a party which isn't full. Stops messaging if you are in a 5 man group. (This can be changed in options)
- Can choose to include or remove LFM messages with XP runs or Cleave runs.
- Can choose to see which channel the message comes from (Default is only show channel if the message came from another player)

### Troubleshooting
If it doesn't seem to be working
- Make sure you have made a chat window named "LFM"
- Make sure the folder in you Addon folder is named "ChatFilterAddon" not "ChatFilterAddon-master"
- Make sure you have joined relevant channels like "world" and "LookingForMore". You can go into the chat winow settings and un-check them, the addon works as long as you have joined them, and not left

### Known Issues
- Scarlet Monestary is hard to classify correctly, you may see CATH even though you are too low level.
- Settings are not saved between relog
