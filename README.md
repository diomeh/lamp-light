# LampLight

LampLight is a Godot 4.5 game project built around modular AI and simulation systems, using Goal Oriented Action Planning.

## Project Domains

### GOAP (Goal-Oriented Action Planning)
- Custom AI system for agent planning and decision-making.
- Core components: `GOAPState`, `GOAPAction`, `GOAPGoal`, `GOAPAgent`, `GOAPPlanner`.
- Agents merge shared world state and private blackboard for planning.
- Extendable via new actions (`goap/actions/`) and goals (`goap/goals/`).

### ECS (Entity Component System)
- Entities are `RigidBody3D` nodes with optional AI agent children.
- Movement and interaction APIs: `move_toward()`, `stop_moving()`, `look_toward()`.
- Designed for extensibility and modularity.

### Actor (Integration Layer)
- Actors serve as the merging point between GOAP and ECS.
- Each actor links entity logic with AI agent behavior.
- Supports dual control modes (PLAYER/AI).

### Systems
- Future systems will be added to `/systems` for modular expansion (e.g., inventory, dialogue).
- Each system is self-contained and interacts via defined APIs.

### Playgrounds
- `/playgrounds/` contains isolated scenes and setups for testing features and mechanics.
- Not connected to main gameplay loop.

### Documentation
- `/docs/` holds detailed project information, guides, and technical references.
- The README provides a high-level overview only.
- Refer to the [glossary](docs/glossary.md) for key terms and concepts, both technical and thematic.

## Conventions

- Typed dictionaries: `Dictionary[String, Variant]`
- Typed arrays: `Array[GOAPAction]`
- Abstract methods marked with `@abstract`
- Use `class_name` for reusable classes

## Enabled Addons

- PhantomCamera
- PaletteTools
- Todo_Manager
- debug_draw_3d
- godot_resource_groups
- resources_spreadsheet_view

## Contributing

Contributions are welcome! Feel free to submit a pull request or open an issue if you have any suggestions or feedback.

This project follows the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md)
and the [Conventional Commits Specification](https://www.conventionalcommits.org/en/v1.0.0/).

### Commit Message Format

From the Conventional Commits Specification [Summary](https://www.conventionalcommits.org/en/v1.0.0/#summary):

The commit message should be structured as follows:

```plaintext
{type}[optional scope]: {description}

[optional body]

[optional footer(s)]
```

Where `type` is one of the following:

| Type              | Description                                                                                             | Example Commit Message                            |
| ----------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| `fix`             | Patches a bug in your codebase (correlates with PATCH in Semantic Versioning)                           | `fix: correct typo in README`                     |
| `feat`            | Introduces a new feature to the codebase (correlates with MINOR in Semantic Versioning)                 | `feat: add new user login functionality`          |
| `BREAKING CHANGE` | Introduces a breaking API change (correlates with MAJOR in Semantic Versioning)                         | `feat!: drop support for Node 8`                  |
| `build`           | Changes that affect the build system or external dependencies                                           | `build: update dependency version`                |
| `chore`           | Other changes that don't modify src or test files                                                       | `chore: update package.json scripts`              |
| `ci`              | Changes to CI configuration files and scripts                                                           | `ci: add CircleCI config`                         |
| `docs`            | Documentation only changes                                                                              | `docs: update API documentation`                  |
| `style`           | Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc.) | `style: fix linting errors`                       |
| `refactor`        | Code change that neither fixes a bug nor adds a feature                                                 | `refactor: rename variable for clarity`           |
| `perf`            | Code change that improves performance                                                                   | `perf: reduce size of image files`                |
| `test`            | Adding missing tests or correcting existing tests                                                       | `test: add unit tests for new feature`            |

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](./LICENSE) file for details.
