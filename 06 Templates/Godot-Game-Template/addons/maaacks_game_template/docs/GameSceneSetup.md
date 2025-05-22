# Game Scene Setup

When setting up a game scene, it is useful to refer to the `game_scene/game_ui.tscn` included in the examples.  

There are a few parts to setting up a basic game scene, as done in the `GameUI` example used in the template.

## Pausing
The `PauseMenuController` node can be added to the tree, or the `pause_menu_controller.gd` script may be attached to an empty `Node`. Selecting the node should then allow for setting the `pause_menu_packed` value in the inspector. Set it to the `pause_menu.tscn` scene and save.

This should be enough to capture when the `ui-cancel` input action is pressed in-game. On keyboards, this is commonly the `Esc` key.

## Level Loading
Some level loading scripts are provided with the examples. They load levels in order from a list, or dynamically by file paths. Levels can be added to the `LevelLoader` by either selecting a directory to automatically read scene files from, or populating the files array manually.

A `LevelLoader` must be provided with a `level_container` in the scene. Levels will get added to and removed from this node. The example uses the `SubViewport`, but any leaf node (ie. node without children) in the scene should work.

The level loader is called from a `LevelListManager` with `advance_and_load_level()`. An additional loading screen in the scene can show progress of loading levels, and is toggled by the `LevelListManager` with `reset()`.

Level Loading is not required if the entire game takes place in one scene.  

## Background Music
`BackgroundMusicPlayer`'s are `AudioStreamPlayer`'s with `autoplay` set to `true` and `audio_bus` set to "Music". These will automatically be recognized by the `ProjectMusicController` with the default settings, and allow for blending between tracks.

A `BackgroundMusicPlayer` can be added to the main game scene, but if using levels, the level scenes are typically a better place for them, as that allows for tracks to vary by level.  

## SubViewports
The game example has the levels loaded into a `SubViewport` node, contained within a `SubViewportContainer`. This has a couple of advantages.

- Separates elements intended to appear inside the game world from those intended to appear on a layer above it. 
- Allows setting a fixed resolution for the game, like pixel art games.
- Allows setting rendering settings, like anti-aliasing, on the `SubViewport`.
- Supports easily adding visual effects with shaders on the `SubViewportContainer`.
- Visual effects can be added to the game world without hurting the readability of the UI.

It has some disadvantages, as well.

- Locks the viewport resolution if any scaling is enabled, which is not ideal for 3D games.
- Requires enabling Audio Listeners to hear audio from the game world.
- Extra processing overhead for the viewport layer.

If a subviewport does not work well for the game, use any empty `Node` as the game world or level container, instead.  

### Pixel Art Games
If working with a pixel art game, often the goal is that the number of art pixels on-screen is to remain the same regardless of screen resolution. As in, the art scales with the monitor, rather than bigger monitors showing more of a scene. This is done by setting the viewport size in the project settings, and setting the stretch mode to either `canvas_mode` or `viewport`.

If a higher resolution is desired for the menus and UI than the game, then the project viewport size should be set to a multiple of the desired game window size. Then set the stretch shrink in `SubViewportContainer` to the multiple of the resolution. For example, if the game is at `640x360`, then the project viewport size can be set to `1280x720`, and the stretch shrink set to `2` (`1280x720 / 2 = 640x360`). Finally, set the texture filter on the `SubViewportContainer` to `Nearest`.

### Mouse Interaction
If trying to detect `mouse_enter` and `mouse_exit` events on areas inside the game world, enable physics object picking on the `SubViewport`.

## Read Inputs
Generally, any game is going to require reading some inputs from the player. Where in the scene hierarchy the reading occurs is best answered with simplicity.  

If the game involves moving a player character, then the inputs for movements could be read by a `player_character.gd` script overriding the `_process(delta)` or `_input(event)` methods.  

If the game involves sending commands to multiple units, then those inputs probably should be read by a `game_ui.gd` script, that then propagates those calls further down the chain.  

## Win & Lose Screens
The example includes win and lose screens. These are triggered by the `LevelListManager` when a level is won or lost.

```
func _load_level_complete_screen_or_next_level():
	if level_won_scene:
		var instance = level_won_scene.instantiate()
		get_tree().current_scene.add_child(instance)
		...
	else:
		_load_next_level()
```
Winning on the last level results in loading a win screen or ending for the game.

```
func _on_level_won():
	if level_list_loader.is_on_last_level():
		_load_win_screen_or_ending()
	else:
		_load_level_complete_screen_or_next_level()
```
 The `LevelListManager` will need to be linked to direct back to the main menu and forward to `end_credits.tscn`.