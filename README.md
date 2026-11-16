<h1 align="center">Xen Tree</h1>

<p align="center">
  <a href="https://www.youtube.com/watch?v=jvHx_RQNcMo"><img src="https://img.youtube.com/vi/jvHx_RQNcMo/maxresdefault.jpg" alt="Watch on YouTube" width="600"></a>
</p>

## 📝 Description
This plugin adds a fully dynamic Xen Tree system to Counter-Strike 1.6.
Xen Trees can be placed, managed and configured during gameplay with runtime control over activation, team access, damage and push effects.
- Create and remove Xen Trees during gameplay via an in-game menu
- Two configurable tree sizes with independent models and collision bounds
- Configurable per tree: team access, animation speed and spawn chance
- Delayed and timed activation with configurable values for round-based gameplay
- Optional cooldown before a tree becomes active again
- Configurable damage and push force applied when the tree attacks
- Optional damage trigger to activate the tree's attack behavior
- Configurable attack and swing sounds
- Optional blood effects and configurable blood color
- Configurable punch angle applied to players when attacked
- Dynamic tree rotation and natural ghost preview placement
- Custom tree setups are saved per map and automatically loaded on every map start

## 📋 Requirements
- ReGameDLL
- AMX Mod X 1.10+

## 💬 Commands
- `say /xt` - Opens the Xen Tree menu.
- `say_team /xt` - Opens the Xen Tree menu.
- `xt_reload` - Reloads the configuration file.

## ⚙️ Configuration
```ini
# Per-tree settings (defined under each [Tree Name] section):
# TREE_FLAGS              = a - Active Delay     b - Active Duration     c - Damage Trigger
# TREE_TEAM               = 0 - None             1 - Terrorist           2 - Counter-Terrorist   3 - Both
# TREE_FRAMERATE          = Tree's animation speed
# TREE_SPAWN_CHANCE       = Tree's respawn probability (0.0 - 1.0)
# TREE_ACTIVE_DELAY       = Delay in seconds before the Tree becomes active at round start
# TREE_ACTIVE_DURATION    = Duration of the active state in seconds
# TREE_ACTIVE_COOLDOWN    = Cooldown in seconds before the Tree becomes active again
# TREE_DAMAGE             = Damage dealt to players when the Tree is active (MIN - MAX)
# TREE_PUSH               = Push force applied to players when the Tree is active (MIN - MAX)
# TREE_SOUND_ATTACK       = Sound to play when the Tree attacks a player
# TREE_SOUND_SWING        = Sound to play when the Tree swings (but doesn't hit a player)
```

## 🔄 Changelog
```text
* v1.0: Initial release.
```

[![Watch on YouTube](https://img.shields.io/badge/YouTube-Watch%20video-FF0000?logo=youtube&logoColor=white)](https://www.youtube.com/watch?v=jvHx_RQNcMo)
