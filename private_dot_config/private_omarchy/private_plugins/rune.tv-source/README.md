# TV Source for Omarchy

A bar widget for the [Omarchy](https://omarchy.org/) shell that switches the input on a Samsung smart TV over the local network, so you don't need the remote.

Click the input icon (󰡁) and two buttons appear next to it:

| Button | Does |
|---|---|
| 󰖺 Xbox | Switches the TV to the Xbox |
| 󰍹 PC | Switches the TV back to the PC |

Picking one folds the buttons away again. So does clicking the input icon a second time, or waiting 6 seconds.

Tested on a Samsung UE65KU6075 (2016, Tizen). Other Samsung Tizen TVs from 2016 onwards use the same remote API and should work too.

## Install

```bash
git clone https://github.com/runeballe/omarchy-tv-source ~/.config/omarchy/plugins/rune.tv-source
cp ~/.config/omarchy/plugins/rune.tv-source/tv-remote.conf.example ~/.config/tv-remote.conf
$EDITOR ~/.config/tv-remote.conf          # set TV=<your TV's IP>
omarchy plugin enable rune.tv-source
omarchy bar put rune.tv-source
```

To find the TV's IP, open Settings → General → Network → Network Status on the TV.

Set up a DHCP reservation in your router so the IP stays the same.

The first time the plugin talks to the TV, the TV may ask whether to allow a device called "Omarchy". Choose Allow. If you chose Deny by mistake, go to Settings → General → External Device Manager → Device Connection Manager on the TV and allow it there.

## How it switches

Many Samsung TVs accept the direct `KEY_HDMI1`–`KEY_HDMI4` keys but do nothing with them. This plugin therefore opens the source list and steps one input left or right:

- **Xbox:** open the source list, one step left, OK.
- **PC:** open the source list, one step right, OK.

That lands on the right input only when the TV is on the other of the two, and when Xbox sits directly left of the PC in the source list (for example Xbox on HDMI 2 and PC on HDMI 3). If your inputs are laid out differently, change the `XBOX` and `PC` lines in `~/.config/tv-remote.conf`.

## Keyboard shortcuts

The widget has no shortcuts of its own. To add them, put this in `~/.config/hypr/bindings.lua`:

```lua
local tv = os.getenv("HOME") .. "/.config/omarchy/plugins/rune.tv-source/tv-remote"
o.bind("CTRL + ALT + X", "TV: switch to Xbox", tv .. " xbox")
o.bind("CTRL + ALT + P", "TV: switch back to PC", tv .. " pc")
```

## The helper

`tv-remote` is a small Python script with no dependencies outside the standard library. You can also run it on its own:

```bash
./tv-remote xbox                    # a named sequence from the config
./tv-remote KEY_SOURCE              # any Samsung remote key
./tv-remote KEY_VOLUP KEY_VOLDOWN   # several keys, DELAY seconds apart
```

It connects to the TV's websocket API on port 8002 (TLS, self-signed certificate). Port 8001 also accepts the connection, but on this TV keys sent there are ignored. If the TV hands out an access token, the script stores it in `~/.config/tv-remote.token`.

## Requirements

- Omarchy shell
- Python 3
- A Samsung Tizen TV on the same network, switched on

## License

MIT
