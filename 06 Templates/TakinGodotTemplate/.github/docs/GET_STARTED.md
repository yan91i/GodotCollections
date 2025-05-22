
Back to [⚡ Hacks](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/HACKS.md) of the project.

See [💕 Examples](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/EXAMPLES.md) of the project.



## 📖  Get Started


### 📘 Setup

After setup, you should have no errors and no warnings.
- Either click [Use this template](https://github.com/new?template_name=TakinGodotTemplate&template_owner=TinyTakinTeller) in Github or clone the repository.
- Setup [GDScript Toolkit](https://github.com/Scony/godot-gdscript-toolkit) python package to use formatter and linter plugins.
- Open (Import) the project for the first time in the Godot Editor.
- Enable all plugins, then restart the project "Project > Reload Current Project".

To resolve "invalid UID" warnings, re-save the scene causing them.


### 📘 Extend Options (Configuration)

1. Add a new enum value in `ConfigurationEnum`.
2. Create a new `_cfg` scene (in `autoload/configuration/configuration_controller/`) and set export variables in the editor.
3. Instantiate the new `_cfg` scene as child of `Configuration` autoload.
4. Instantiate a new UI node (from `scenes/node/menu/menu_configuration/`) and set export variables in the editor.


### ❓ FAQ

For questions and help, open a Github Issue or contact Discord `tiny_takin_teller`.

- Opening the project for the first time, I have errors/warnings?
	- Try (re)enable all Plugins and then select "Reload Current Project".
- Warning "ext_resource, invalid UID" when opening the project?
	- Resolve by re-saving the mentioned scene (.tscn), e.g. rename root node.
	- If warning persists, also delete `filesystem_cache` files from `.godot\editor`.
- Video settings are not working in the Godot Editor?
	- Disable "Game Embed Mode" in Editor Settings.

For additional FAQ search list of [closed issues](https://github.com/TinyTakinTeller/TakinGodotTemplate/issues?q=is%3Aissue%20state%3Aclosed).


### 💼 Editor Layout

Notes:
- You can disable embeded game in "Editor > Editor Settings > Run > Window Placement > Game Embed Mode".
- Editor layout can be changed via "Editor > Editor Layout > ..." in Godot Editor.

To use my layout, locate `editor_layouts.cfg` in [Editor Data Paths](https://docs.godotengine.org/en/latest/tutorials/io/data_paths.html#editor-data-paths) and add:

```
[takin_godot_template]

dock_1_selected_tab_idx=0
dock_5_selected_tab_idx=0
dock_floating={}
dock_bottom=[]
dock_closed=[]
dock_split_1=0
dock_split_3=0
dock_hsplit_1=365
dock_hsplit_2=170
dock_hsplit_3=-430
dock_hsplit_4=0
dock_filesystem_h_split_offset=240
dock_filesystem_v_split_offset=0
dock_filesystem_display_mode=0
dock_filesystem_file_sort=0
dock_filesystem_file_list_display_mode=1
dock_filesystem_selected_paths=PackedStringArray("res://")
dock_filesystem_uncollapsed_paths=PackedStringArray("res://")
dock_1="FileSystem,Scene,Scene Manager"
dock_5="Inspector,Node,Import,History"
```

For editor features, you can change "Editor > Manage Editor Features..." (e.g. toggle 3D Editor view).
