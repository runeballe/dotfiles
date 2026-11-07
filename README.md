# dotfiles

Mitt oppsett for [Omarchy](https://omarchy.org/) (Arch Linux + Hyprland), styrt med [chezmoi](https://www.chezmoi.io/).

## Innhold

- **Hyprland** (`~/.config/hypr`): tastebindinger, skjermer, input og utseende.
- **Omarchy** (`~/.config/omarchy`): shell-oppsett, Alt+Tab, OmaControl, menyutvidelser og hooks.
- **Skript** (`~/.local/bin`):
  - `titlebar-middle-close`: midtklikk på en tittellinje lukker vinduet.
  - `hypr-screen`: bruk en Android-telefon som ekstra skjerm.
  - `ea-code-watcher`, `wobble-party`.
- **Terminal og shell**: zsh, bash, starship, foot, alacritty, kitty og git.

Plugins, temaer og bakgrunner er ikke med. De installeres via Omarchy.

## Ta i bruk på en ny maskin

```sh
sudo pacman -S chezmoi
chezmoi init --apply runeballe
```

## Oppdatere repoet

```sh
chezmoi re-add          # hent inn endringer fra hjemmemappa
chezmoi cd && git commit -am "..." && git push
```
