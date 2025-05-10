# 🚨 FiveM Anti-Cheat System

A comprehensive and customizable anti-cheat system for FiveM servers. This system helps detect and prevent various exploits, ensuring a fair and secure gaming environment.

## ✨ Features

- **Core Anti-Cheat**:
  - Detection of abnormal speeds, restricted weapons, teleportation, God Mode, NoClip/Fly, and hidden resources.
  - Monitoring of inventory, vehicles, and object spawns.
  - Detection of aimbot behavior.

- **Advanced Protections**:
  - Anti-Backdoor: Neutralizes unauthorized server-side script injections.
  - Anti-Cipher Panel: Blocks unauthorized control panels.
  - Continuous Monitoring: Logs suspicious events and applies sanctions.

- **Configurable Settings**:
  - Manage allowed vehicles, objects, weapons, restricted zones, and more via `config.json`.

- **Admin Tools**:
  - NUI-based admin menu for managing bans, viewing logs, and configuring settings.
  - Real-time notifications for suspicious activities.

## 📂 File Structure

```
.
├── anticheat_client.lua   # Client-side anti-cheat logic
├── anticheat_server.lua   # Server-side anti-cheat logic
├── config.json            # Configuration file
├── ban.dnzac              # Stores banned players
├── logs.json              # Stores detailed logs
├── nui/                   # NUI files for the admin menu
│   └── menu.html          # Admin menu UI
├── fxmanifest.lua         # Resource manifest
```

## ⚙️ Configuration

Edit the `config.json` file to customize the anti-cheat settings:

```json
{
    "allowedVehicles": ["adder", "zentorno"],
    "allowedObjects": ["prop_chair_01a", "prop_table_03"],
    "restrictedZones": [
        {"x": 100.0, "y": 200.0, "z": 300.0, "radius": 50.0}
    ],
    "allowedResources": ["essentialmode", "es_extended", "vMenu"],
    "knownCipherPanels": ["adminpanel", "hackerpanel", "cheatmenu"],
    "allowedWeapons": ["WEAPON_PISTOL", "WEAPON_KNIFE", "WEAPON_BAT"],
    "adminSteamIDs": ["steam:010101010101010"],
    "banFile": "ban.dnzac",
    "whitelist": []
}
```

## 🛠️ Usage

1. **Install the Resource**:
   - Place the folder in your FiveM server's `resources` directory.
   - Add `ensure ac` to your `server.cfg`.

2. **Admin Menu**:
   - Use the `/adminmenu` command in-game to open the admin menu.
   - Features include:
     - Viewing and managing bans.
     - Adjusting settings like max speed and restricted weapons.
     - Viewing logs and statistics.

3. **Logs and Bans**:
   - Suspicious events are logged in `logs.json`.
   - Banned players are stored in `ban.dnzac`.

## 📜 License

This project is licensed under the MIT License. Feel free to use and modify it as needed.

## ❤️ Contributions

Contributions are welcome! Feel free to submit issues or pull requests to improve the system.

## 📞 Support

For support or questions, feel free to reach out via GitHub issues.

---

Enjoy a fair and secure gaming experience! 🎮
