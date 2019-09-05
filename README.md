# tullaCC

A World of Warcraft addon that adds text to cooldowns to indicate how much time
remains.

Source code for the addon can be found on [Github](https://github.com/tullamods/tullaCC)

## Configuration

As of v8.2.1, tullaCC now has persistent configuration settings, but no
configuration interface. To adjust options, you can either use

```lua
/run tullaCC.Config.setting = value; ReloadU()
```

Or edit your saved variables directly. All of the adjustable settings can be
found and are documented in config.lua
