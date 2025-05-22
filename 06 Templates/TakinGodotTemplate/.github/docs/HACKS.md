
Back to [🎉 CI/CD](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/CICD.md) of the project.

See [📖 Get Started](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/GET_STARTED.md) of the project.



## ⚡ Hacks

Godot Engine [has known issues](https://github.com/godotengine/godot/issues) requiring hacks (workarounds) until officially resolved.

This template implements workarounds for the following issues:

- **General**
	- [x] Issue [#96023](https://github.com/godotengine/godot/issues/96023) **custom theme**. Solved with startup script.
	- [x] Issue [#66014](https://github.com/godotengine/godot/issues/66014) **suffixed tres files**. Solved with sanitization.
	- [x] Issue [#65390](https://github.com/godotengine/godot/issues/65390) **defect GPU particles**. Solved with interpolate toggle.
	- [x] Issue [#35836](https://github.com/godotengine/godot/issues/35836#issuecomment-581083643) **font size tween lag**. Solved by scale tween instead.
	- [ ] Issue [#89712](https://github.com/godotengine/godot/issues/89712) **"hicon" is null** sometimes. TODO?
	- [ ] Issues [#75369](https://github.com/godotengine/godot/issues/75369), [#71182](https://github.com/godotengine/godot/issues/71182), [#61929](https://github.com/godotengine/godot/issues/61929) **large scene lag** sometimes. TODO?
- **Desktop**
	- [ ] Issues [#3145](https://github.com/godotengine/godot-proposals/issues/3145), [#6247](https://github.com/godotengine/godot-proposals/issues/6247) **boot window mode**. TODO: cfg override.
	- [ ] Issues [#76167](https://github.com/godotengine/godot/issues/76167), [#91543](https://github.com/godotengine/godot/issues/91543) **Boot Splash "leak"**. TODO?
- **Web**
	- [x] Issue [#81252](https://github.com/godotengine/godot/issues/81252) **web clipboard**. Solved by native JavaScript dialog.
	- [x] Issue [#96874](https://github.com/godotengine/godot/issues/96874) **web boot splash**. Solved by CSS in Head Include.
	- [x] Issue [#100696](https://github.com/godotengine/godot/issues/100696) **play_stream bus**. Solved by explicit func args.
	- [ ] Issue [#43138](https://github.com/godotengine/godot/issues/43138) **web user focus**. TODO: "click to continue" boot screen.

**TODO**: Test the template on following platforms.
- **Linux**
- **MacOS**
- **iOS**
- **Android**

**Notes**
- Renaming root folder
	- localization files will need to be re-imported (Project > Project Settings > Localization)
	- font files will lose fallbacks and will need to be re-imported after setting fallbacks again
	- constant `const ROOT: String` will need to be updated to new value (`path_consts.gd`)
	- scene manager plugin will need to be re-saved (in Scene Manager tab, click Refresh then Save)
