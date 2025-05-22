
Back to [♦️ Preview](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/PREVIEW.md) of the project.

See [⭐ Features](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/FEATURES.md) of the project.



## 📂 Structure


### 📂 File Structure

- **.github**
	- **docs**
	- **workflows**
	- FUNDING.yml
- **godot**
	- **addons** (Plugins)
	- **root** (project files)
		- **artifacts** (additional examples)
		- **assets** *(.png, .mp3, .csv, .ttf, ...)*
		- **autoload** (Globals)
		- **resources** *(.tres, .gd)*
		- **scenes** *(.tscn, .gd)*
		- **scripts** *(static/const/object .gd)*
		- **shaders** *(.gdshader)*
		- **snippets** *(.cpp, .js, ...)*
		- CREDITS.md
	- export_presets.cfg
	- project.godot (ProjectSettings)
- .gitattributes
- .gitignore
- LICENSE
- README.md


### 📜 Conventions

- Use **snake_case** for files, folders, variables, functions.
- Use **PascalCase** for nodes, classes, enums, types.
- Use **typed** variables and functions.
- Use **style** inspired by [GDScript Style](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) (see [*gdlintrc*](https://github.com/Scony/godot-gdscript-toolkit/wiki/3.-Linter#tweaking-default-check-settings)).
- Function definition order: [override](https://docs.godotengine.org/en/stable/tutorials/scripting/overridable_functions.html), public, private, static.
- Consider using [**good design patterns**](https://refactoring.guru/design-patterns) when programming.
- Consider maintaining **enum** values when appropriate.
- Consider `_` prefix on "base" scripts with sole purpose to be extended.
