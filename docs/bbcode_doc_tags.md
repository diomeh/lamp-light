# BBCode Documentation Tags

| Tag and Description                                    | Example                                                                  |
| ------------------------------------------------------ | ------------------------------------------------------------------------ |
| `[Class]`Link to class                                 | `Move the [Sprite2D].`                                                   |
| `[annotation Class.name]`Link to annotation            | `See [annotation @GDScript.@rpc].`                                       |
| `[constant Class.name]`Link to constant                | `See [constant Color.RED].`                                              |
| `[enum Class.name]`Link to enum                        | `See [enum Mesh.ArrayType].`                                             |
| `[member Class.name]`Link to member (property)         | `Get [member Node2D.scale].`                                             |
| `[method Class.name]`Link to method                    | `Call [method Node3D.hide].`                                             |
| `[constructor Class.name]`Link to built-in constructor | `Use [constructor Color.Color].`                                         |
| `[operator Class.name]`Link to built-in operator       | `Use [operator Color.operator *].`                                       |
| `[signal Class.name]`Link to signal                    | `Emit [signal Node.renamed].`                                            |
| `[theme_item Class.name]`Link to theme item            | `See [theme_item Label.font].`                                           |
| `[param name]`Parameter name (as code)                 | `Takes [param size] for the size.`                                       |
| `[br]`Line break                                       | `Line 1.[br]``Line 2.`                                                   |
| `[lb]` `[rb]``[` and `]` respectively                  | `[lb]b[rb]text[lb]/b[rb]`                                                |
| `[b]` `[/b]`Bold                                       | `Do [b]not[/b] call this method.`                                        |
| `[i]` `[/i]`Italic                                     | `Returns the [i]global[/i] position.`                                    |
| `[u]` `[/u]`Underline                                  | `[u]Always[/u] use this method.`                                         |
| `[s]` `[/s]`Strikethrough                              | `[s]Outdated information.[/s]`                                           |
| `[color]` `[/color]`Color                              | `[color=red]Error![/color]`                                              |
| `[font]` `[/font]`Font                                 | `[font=res://mono.ttf]LICENSE[/font]`                                    |
| `[img]` `[/img]`Image                                  | `[img width=32]res://icon.svg[/img]`                                     |
| `[url]` `[/url]`Hyperlink                              | `[url]https://example.com[/url]``[url=https://example.com]Website[/url]` |
| `[center]` `[/center]`Horizontal centering             | `[center]2 + 2 = 4[/center]`                                             |
| `[kbd]` `[/kbd]`Keyboard/mouse shortcut                | `Press [kbd]Ctrl + C[/kbd].`                                             |
| `[code]` `[/code]`Inline code fragment                 | `Returns [code]true[/code].`                                             |
| `[codeblock]` `[/codeblock]`Multiline code block       | *See below.*                                                             |
