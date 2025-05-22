
Back to [🧩 Plugins](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/PLUGINS.md) of the project.

See [🎉 CI/CD](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/CICD.md) of the project.



## 🤖 Code


Globals (autoload Scenes) act as singletons.

Scripts (statics, consts, objects) act as utility. 

Otherwise, normal Scenes must be loaded or added to the Scene Tree.

### 💎 Globals

- **Configuration**
	- Configurations use ConfigStorage object for presistence in INI files.
	- Audio, Video, Controls, Game configurations are tied to the options menu UI.
- **Data**
	- Use as setter and getter of save file data, configure structure of save files.
- **Overlay**
	- Container for debug elements, e.g. FPS counter.
- **Reference**
	- Preload here references to Resources and Assets for quick access.
- **SignalBus**
	- Exchange global signals for cleaner observer pattern.
- **Wrapper**
	- **LogWrapper** - Extends Logger plugin with log groups configuration.
	- **AudioManagerWrapper** - Calls Resonance plugin with enums instead of string names.
	- **SceneManagerWrapper** - Calls SceneManager plugin with custom preloaded resource.
	- **TranslationServerWrapper** - Extends localization to work in tool scripts.

### 🎬 Scenes

Scenes are split into following categories:
1. "Component" scenes extend functionality of the parent.
2. "Node" scenes are reusable as standalone functional units.
3. "Scene" scenes are larger specialized functional collections.

- **Component**
	- **Audio**
		- **ButtonAudio** - Triggers Audio events on signals (focus, click, release).
		- **SliderAudio** - Triggers Audio events on signals (drag start, drag end).
		- **TreeAudio** - Triggers Audio events on signals (cell selected, button clicked).
	- **Builder**
		- **UiBuilder** - Spawn components, e.g. an focus animation on all focusable nodes.
	- **Control**
		- **ControlExpandStylebox** - Resize target node to fill parent container.
		- **ControlFocusOnHover** - Grabs focus of node on mouse hover signal.
		- **ControlGrabFocus** - Grabs focus of node for controller support.
	- **Emitter**
		- **ParticleEmitter** - Convert any scene into a particle via a sub-viewport.
	- **Motion**
		- **ScaleMotion** - Animate (tween) scale on interaction. *(Game counter labels.)*
		- **TwistMotion** - Animate (tween) scale and rotation on interaction. *(UI nodes.)*
	- **Tween**
		- **ParticleTween** - Emulates particle emitter with a tween.
- **Node**
	- **Game**
		- **ParticleQueue** - Emit any scene via GPU particles as SubViewport.
	- **Menu**
		- **MenuButton** - Localized menu button.
		- **MenuConfiguration** - Localized UI elements: dropdown, slider, toggle, tree.
- **Scene**
	- **BootSplashScene** *(Main Scene)*  - Smooth transition to menu scene.
	- **MenuScene** - Manages menu scenes as children.
		- **MainMenu** - Display buttons to enter other menus or next scene.
		- **OptionsMenu** - Manages options (persistent app settings) scenes.
			- **AudioOptions** - Configure Music and SFX volume or mute.
			- **VideoOptions** - Display, Resolution, VSync, FPS Limit, Anti-Alias.
			- **ControlsOptions** - Change (add or remove) keybinds.
			- **GameOptions** - Custom options, e.g. toggle autosave.
		- **CreditsMenu** - Renders CREDITS.md file in-game with formatting.
		- **SaveFilesMenu** - List of files: play, import, export, delete, rename.
	- **GameScene** - Contains gameplay.
		- **GameContent** - Example incremental game mechanics and effects.
			- **ClicksCounter** - Counts and displays clicks. 
			- **CoinsCounter** - Counts and displays coins.
			- **GameButton** - Animated clickable texture button giving coins.
		- **PauseMenu** - Pause gameplay, change options. Esc key shortcut.

### 📄 Scripts

- **Const** - Collections of commonly used constants.
- **Object**
	- **ActionHandler** - Implements the (light) [command pattern](https://refactoring.guru/design-patterns/command) design.
	- **ConfigStorage** - Persists (save & load) app settings in INI file.
	- **LinkedMap** - Dictionary data structure that tracks order of keys.
- **Util**
	- **DatetimeUtils** - Useful for save file metadata (e.g. last played at).
	- **DictionaryUtils** - Nested dictionary helper functions.
	- **EnumUtils** - Enum name converters.
	- **FileSystemUtils** - Robust functions to extract file paths and names.
	- **MarshallsUtils** - Convert data formats with optional encryption.
	- **MathUtils** - Integer power function, base conversion and similar.
	- **NodeUtils** - Collection of node manipulation functions.
	- **NumberUtils** - Numbers format (digits, metric, scientific), validate.
	- **RandomUtils** - Weighted Loot Table and random string functions.
	- **StringUtils** - String functions for validation and transformations.
	- **ThemeUtils** - Shortcut Theme getters and setters.

### 🌸 Snippets

Native code snippets. (e.g. javascript for web export, java for android export, ...)

Also see [GDExtension](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/what_is_gdextension.html).

- **ConfirmationDialogJsLoader** 
	- Loads native HTML/CSS/JS dialog to access clipboard in web build.
	- Supports transfer of Theme resource properties to CSS style.
	- Useful because Godot Nodes cannot read or write to web clipboard.
