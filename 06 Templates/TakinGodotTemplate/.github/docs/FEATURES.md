
Back to [📂 Structure](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/STRUCTURE.md) of the project.

See [🧩 Plugins](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/PLUGINS.md) of the project.



## ⭐ Features


### ✨ Game Modules

Some feature modules were written from scratch, others use installed addons.

Feel free to swap modules with either simpler or advanced alternatives, depending on your project.

- **Foundation**
	- 🖼️ [**Scene Manager**](https://github.com/maktoobgar/scene_manager) - Custom transitions and loading screens.
	- 🎵 [**Audio Manager**](https://github.com/hugemenace/resonate) - Reliable music tracks and sound effects.
	- ⚙️ **Configuration** - Persistent game options and statistics in INI file.
	- 💾 **Save Files** - Modular save system for game data, optional encryption.
- **Localization**
	- 🌍 [**Polygot Template**](https://github.com/agens-no/PolyglotUnity) with 28 languages and over 600 [game words](https://docs.google.com/spreadsheets/d/17f0dQawb-s_Fd7DHgmVvJoEGDMH_yoSd8EYigrb0zmM/edit?gid=296134756#gid=296134756).
	- ✏️ [**Google Noto Sans**](https://fonts.google.com/) fonts glyphs (Arabic, Hebrew, HK, JP, KR, SC, TC, Thai).
- **Accessibility**
	- 🎮 **Controller Support** - Grab UI focus for joypad and keyboard users.
	- 🔍 **Multiple Resolutions** - Video options: display mode, window zoom.
	- ⚡ **Optimizations** - E.g. Native web dialog to capture clipboard.
- **UI/UX**
	- 🎬 **Boot Splash** - The main scene, allowing custom transition to main menu.
	- 🏠 **Main Menu** - Display buttons to enter other menus, version and author.
	- 🔧 **Options Menu** - Audio, Video (display, vsync), Controls (keybinds), Game.
	- 📜 **Credits Menu** - Renders [CREDITS.md](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/godot/CREDITS.md) file in-game with formatting.
	- 📓 **Save Files Menu** - List of files: Play, Import, Export, Delete, Rename.
	- 🎲 **Game Scene** - Example incremental game mechanics and particle effects.
	- ⏸️ **Pause Menu** - Pause gameplay, change options. Esc key shortcut.
- **Placeholder**
	- 🎨 **Theme** - Godot default theme. Alternatives at [Kenney](https://kenney.nl/assets/tag:interface?sort=update), [Itch](https://itch.io/c/1473270/themes-for-godot-games), [OGA](https://opengameart.org/art-search-advanced?keys=&title=&field_art_tags_tid_op=or&field_art_tags_tid=ui&name=&field_art_type_tid%5B%5D=9&sort_by=count&sort_order=DESC&items_per_page=24&Collection=), ...
	- 🖌️ **Images** - [CC0](https://creativecommons.org/publicdomain/zero/1.0/) Public Domain: [Dannya](https://openclipart.org/artist/dannya) save file icon, [Maaack](https://github.com/Maaack/Godot-Menus-Template/tree/main/addons/maaacks_menus_template/base/assets/images) icons.
	- 🎶 **Music & SFX** - [CC0](https://creativecommons.org/publicdomain/zero/1.0/) Public Domain: [Kenney](https://kenney.nl/assets/category:Audio) SFX and [OGA](https://opengameart.org/content/menu-doodle-2) Music (loop).
	- 🌪️ **Juice** - UI twist Animation (Tween) on mouse hover or node focus.

### 💫 Development Modules

- **Singletons**
	- 📢 **Signal Bus** - Observer pattern for cleaner global signals.
	- 📖 **References** - Maps of preloaded resources and assets.
- **Special**
	- 👷 **Builder** - adds components to nodes, alternative to upcomming [Traits](https://github.com/godotengine/godot/pull/97657).
- **Scripts**
	- 🧰 **Utility** - Many reusable scripts that provide common functionalities.
	- 🛠️ **Objects** - ActionHandler, ConfigStorage (INI File), LinkedMap.
- **Tools**
	- 🐛 [**Logger**](https://github.com/albinaask/Log) - Easier debugging, custom log groups configuration.
	- 🧩 [**IDE Plugin**](https://github.com/Maran23/script-ide) - Improves scripting in GDScript in editor.
	- 📋 [**Resource View**](https://github.com/don-tnowe/godot-resources-as-sheets-plugin/tree/Godot-4) - Better resource management in editor.
	- ✨ [**GDScript Toolkit**](https://github.com/Scony/godot-gdscript-toolkit) - Code style [formatting](https://github.com/ryan-haskell/gdformat-on-save) on save and [linter](https://github.com/el-falso/gdlinter).
- **Workflow**
	- 🚀 **Deployment** - Automatically upload to [itch.io](https://itch.io/) page from Github.
	- ✅ **Actions** - Verify style and formatting in GDScript code on push to Github.

### 🗿 Additional Examples

The project contains example `game_content` scenes (set it in `game_scene` scene).

- **2D Incremental Clicker** (default)
- [**3D First Person Controller**](https://github.com/rbarongr/GodotFirstPersonController) (`/artifacts/example_3d_fp_controller`)

Default game content scene can be changed in Game Options under "Game Mode".

This is applied via `_load_game_content_scene` function. *(Option 0 is empty project.)*
