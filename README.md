<p align="center">
  <img src="./img/logo.png" alt="Instixct Poker Script Logo" width="120" />
</p>

<h1 align="center">Poker System</h1>

<p align="center">
  A lightweight <b>SA-MP / open.mp Pawn filterscript</b> that provides a full-featured <br/>
  <b>poker system with admin controls, tables, and gameplay logic</b>.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/open.mp-supported-green?style=flat-square" />
  <img src="https://img.shields.io/badge/SA--MP-compatible-blue?style=flat-square" />
</p>

---

## ✨ Features

- 🃏 Fully functional **poker table system**
- 🎮 Player seating, blinds, and buy-in handling
- 🛠️ **Admin management commands** (/ctable, /dtable, /agame)
- 📍 Dynamic table creation at player position
- 🔄 Game flow handling (turns, betting, abort system)
- 📊 Supports multiple tables simultaneously

---

## 📦 Requirements

Make sure your server includes:

- [open.mp](https://open.mp/)
- [streamer plugin](https://github.com/samp-incognito/samp-streamer-plugin)
- [YSI Includes](https://github.com/pawn-lang/YSI-Includes)
- [zcmd](https://github.com/Southclaws/zcmd)
- [sscanf2](https://github.com/maddinat0r/sscanf)
- [easyDialog]

---

## ⚙️ Installation

1. Place the script inside your server filterscripts/modules folder
2. Ensure all required includes are installed
3. Add it to your config or use /rcon loadfs poker

---

## 🎮 Admin Commands

| Command | Description |
|--------|-------------|
| `/ctable` | Create a poker table |
| `/dtable` | Delete a poker table |
| `/agame` | Abort current game |

---

## 🧠 Notes

- Admin checks use `IsPlayerAdmin()`
- Tables are created at player position (Z offset applied)
- Script is modular and split into `poker/*.pwn` components

---

## 📁 Structure

```
poker/
├── core.pwn
├── commands.pwn
├── data.pwn
├── turns.pwn
├── util.pwn
├── helpers.pwn
├── textdraws.pwn
└── init.pwn
```
