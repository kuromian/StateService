# StateService Setup Instructions

## Download

Download the latest `.rbxmx` file from: **[GitHub Releases](https://github.com/kuromian/StateService/releases/latest)**

## Installation

1. **Import** the `.rbxmx` file into Roblox Studio
2. **Move** each folder to its matching directory:
   - `ServerScriptService` → ServerScriptService
   - `ReplicatedStorage` → ReplicatedStorage
   - `StarterPlayerScripts` → StarterPlayer.StarterPlayerScripts
3. **Ungroup** the folders after moving them

## Customization

**Optional:** You can move the scripts to different locations
- Edit the `require()` paths in Server and Client scripts to match your new locations

## Cleanup

After installation, delete the original setup script from your game.<br>
That, or delete the whole folder all-together if you're sure you set it up right.<br>
Basically: It's another way to explain how to setup the module safely without the documentation.

---

**Basic Example Reference:** [Basic Example](/Tutorial/Basic%20Example)<br>
**API Reference:** [API](/API)