Implementation of a Unity grass shader with fancy scripting features. See it in action here: https://twitter.com/CharlieBratches/status/1258572353174372352. Inspired by the tech seen in Zelda: Breath of the Wild.

Features include:
* Splat mapping to control height & color.
* An additional splat map to control masking.
* Dynamic wind direction accessible through an API. Wind intensity & direction can be controlled. See the example script WindManager.
* Interactivity! If your character walks through the grass, it will bend away from their position. Supports multiple interactive objects at once.
* Automatic slope masking. (grass won't appear on very steep terrain)
* Supports your custom grass/plants/flowers/whatever textures with alpha channels (note, if you use a custom texture with a transparency channel, turn shadows off for best performance and to prevent artifacts)
* Easy to set up. Just throw the prefab in your scene and tweak away.
