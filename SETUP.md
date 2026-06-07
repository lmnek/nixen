# Setup

Post-install steps to run after deploying this NixOS configuration.

## 1. Change user password

```sh
sudo passwd lmnk
```

## 2. Install fish plugins

Install fisher, then use it to manage plugins:

```fish
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source && fisher install jorgebucaran/fisher
```

## 3. Install yazi plugins

```sh
ya pkg install
```

## 4. Grant permissions to zellij plugins

```sh
zellij plugin -- https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm
```
