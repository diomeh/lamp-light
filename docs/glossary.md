# Glossary

This glossary compiles all relevant technical and thematic terms, ideas, and concepts used in the LampLight project. It serves as a reference for both developers and players, clarifying the architecture, systems, and in-game elements.

## Table of Contents

- [Glossary](#glossary)
  - [Table of Contents](#table-of-contents)
  - [Technical terms](#technical-terms)
    - [GOAP (Goal-Oriented Action Planning)](#goap-goal-oriented-action-planning)
      - [State](#state)
      - [Agent](#agent)
      - [Actions](#actions)
      - [Goals](#goals)
    - [Plans](#plans)
      - [Planning](#planning)
    - [ECS (Entity Component System)](#ecs-entity-component-system)
      - [Entity](#entity)
      - [Component](#component)
      - [Manager](#manager)
    - [Jolt Physics](#jolt-physics)
  - [Thematic terms](#thematic-terms)

> [!NOTE]
> Technical terms relate to the architecture and systems used in the development of LampLight, while thematic terms pertain to the lore, setting, and narrative elements within the game world.
>
> A technical term is something the developer should know about, while a thematic term is something the player should know about.

---

## Technical terms

### GOAP (Goal-Oriented Action Planning)

A decision-making architecture for AI agents, enabling them to plan sequences of actions to achieve goals based on the current world and agent state.
See [Goal-Oriented Action Planning](https://medium.com/@vedantchaudhari/goal-oriented-action-planning-34035ed40d0b) for more details.

#### State

A general representation of facts about the world or an agent, used for planning and reasoning.
Defined as the `GOAPState` class, which acts as a typed dictionary wrapper with utility methods.

The state is divided into two main parts:

- **World State**: Represents shared information about the environment, accessible to all agents.
- **Blackboard State**: Represents private information specific to an individual agent.

On a technical level, both states are represented by a `GOAPState` instance even if conceptually they differ in scope and accessibility.

#### Agent

Defined as the `GOAPAgent` node component.
Agents are game objects that utilize the GOAP system to make decisions and plan actions based on their goals and the current state of the world.

#### Actions

Defined as the `GOAPAction` abstract base class.
Actions represent atomic operations that an agent can perform to change the state of the world or itself.

For example, an action could be "Move to Location", "Pick up Item", or "Attack Enemy".

#### Goals

Defined as the `GOAPGoal` abstract base class.
Goals represent desired end states that an agent aims to achieve through planning and executing actions.

For example, a goal could be "Find Food", "Defend Territory", or "Explore Area".

### Plans

Defined as the `GOAPPlan` class.
Plans are sequences of actions an agent intends to execute to achieve a specific goal,
based on the current state of the world and the agent's blackboard.

#### Planning

Defined as the `GOAPPlanner` singleton autoload.
The planning process involves evaluating the current world and blackboard states,
selecting a goal, and generating a sequence of actions (a plan) that will lead to the achievement of that goal.

The planner makes use of a regressive A* search algorithm to efficiently find viable plans.

### ECS (Entity Component System)

A software architectural pattern that organizes game objects as entities composed of reusable components.
See [ECS Pattern](https://gameprogrammingpatterns.com/component.html) for more details.

#### Entity

Container that allows any game object to define behaviors and data through attached components.
Defined as the `ECSEntity` class .

#### Component

Reusable, data-driven Godot Scene that is attached to an entity. Components encapsulate specific behaviors or data, such as health, position, or inventory.
An `ECSComponent` may be attached to any other `ECSEntity`.

#### Manager

Autoload singleton that handles manipulation and querying of entities and their components.

### Jolt Physics

A third-party physics engine integrated with Godot 4.5, used for simulating physical interactions.
See [Jolt Physics GitHub](https://github.com/jrouwe/JoltPhysics) for more details.

---

## Thematic terms
