
Back to [🤖 Code](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/CODE.md) of the project.

See [⚡ Hacks](https://github.com/TinyTakinTeller/TakinGodotTemplate/blob/master/.github/docs/HACKS.md) of the project.



## 🎉 CI/CD


### 🚀 Deployment

- **Itch.io**
	- Project uses `release_master.yml` to automate uploads to [itch.io](https://itch.io/) page.
	- You can **disable** this by deleting the mentioned file.
	- You can **enable** this by doing the following:
		1. Generate new API key in Itch settings, setup `BUTLER_API_KEY` secret in Github.
		2. Create a new game project page on Itch.
		3. Setup `ITCHIO_GAME` and `ITCHIO_USERNAME` secrets in Github.

### ✅ Workflows

- **quality_check.yml**
	- Automatically check [*gdlintrc*](https://github.com/Scony/godot-gdscript-toolkit/wiki/3.-Linter#tweaking-default-check-settings) coding style standards.
