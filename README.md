<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>

<br />
<div align="center">

<a href="https://github.com/stavguo/pico-saga">
  <img src="images/title.svg" alt="Logo" width="240">
</a>
  <p align="center">
    A tactical turn-based RPG featuring procedurally generated terrain.
    <br />
    <a href="https://gustavo.zip/pico-saga/">
      <strong>Play it here!</strong>
      <br />
      <img src="./images/demo.gif?raw=true" alt="Demo GIF" width="250">
    </a>
    <br />
    <a href="#gameplay">How to play</a>
    &middot;
    <a href="https://github.com/stavguo/pico-saga/issues/new?labels=bug&template=bug-report---.md">Report Bug</a>
    &middot;
    <a href="https://github.com/stavguo/pico-saga/issues/new?labels=enhancement&template=feature-request---.md">Request Feature</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#overview">Overview</a></li>
    <li>
      <a href="#gameplay">Gameplay</a>
      <ul>
        <li><a href="#controls">Controls</a></li>
      </ul>
    </li>
    <li>
      <a href="#mechanics">Mechanics</a>
      <ul>
        <li><a href="#unit-movement">Unit Movement</a></li>
        <li><a href="#combat-resolution">Combat Resolution</a></li>
        <li><a href="#sieging-castles">Sieging Castles</a></li>
      </ul>
    </li>
    <li><a href="#time-complexity-analysis">Time Complexity Analysis</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Overview
Pico-Saga delivers [Fire Emblem](https://en.wikipedia.org/wiki/Fire_Emblem)-style tactics in a daily bite-sized format—like [Connections](https://www.nytimes.com/games/connections) meets turn-based strategy. Built for players who want meaningful combat depth in minutes. Under the hood it applies:

- Uniform Cost Search for pathfinding with respect to terrain movement costs
- Space-optimized DP to search for logical castle placements with respect to terrain
- Kruskal's algorithm for efficiently creating a castle network with roads

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Gameplay
The player and enemy take turns moving units across a grid-based map to liberate castles or engage in combat. Victory requires capturing all enemy castles, but losing all your own results in defeat.
- Phases: Player and AI alternate turns, moving all units once per phase.
- Combat: Rock-paper-scissors weapon matchups and positioning determine outcomes.
- Reinforcements: Liberated castles provide new units; enemy castles spawn reinforcements.
- Permadeath: Units lost in battle are gone forever—caution is key!

### Controls
| Context       | Arrow Keys               | `C` Key                  | `X` Key                |
|---------------|--------------------------|--------------------------|------------------------|
| **Overworld** | Move cursor              | Select unit/castle       | Open pause menu        |
| **Castle**    | Move cursor/deploy selected unit  | Select unit              | Exit castle view       |
| **Movement**  | Move unit      | Confirm destination      | Cancel movement        |
| **Menu**      | Navigate options         | Select option           | Back/Exit menu        |
<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Mechanics
### Unit Movement
- Movement Cost: Each terrain type has a movement cost (e.g., roads cost 0.5, thickets cost 4).
- Movement (`Mov`): Units move a set number of tiles per turn, modified by terrain costs (e.g., forests slow movement).

### Combat Resolution
- Weapon Triangle: Grants advantaged unit with +20% accuracy.
  | Unit Type | Strong Against       |
  |-----------|----------------------|
  | Sword     | Axe                  |
  | Axe       | Lance                |
  | Lance     | Sword                |
  | Monk      | Archer, Mage, Thief  |
- Break Mechanic: Attacking with a advantaged weapon (e.g., axe vs. lance) breaks the enemy, blocking their counterattack.
- Terrain: The terrain a unit occupies affects evasion (e.g., forests grant +10% evasion).
  | Terrain Type | Movement Cost | Avoid Bonus |
  |--------------|---------------|-------------|
  | Road         | 0.5           | 0           |
  | Bridge       | 0.5           | -10         |
  | Plains       | 1             | 0           |
  | Forest       | 2             | +20         |
  | Shoal        | 4             | +10         |
  | Thicket      | 4             | +30         |
  | Sea          | *N/A*         | +20         |
  | Mountain     | *N/A*         | +20         |

### Sieging Castles
- Reinforcements: Red pixels = remaining enemy units.
- Siege for 1 turn → destroy 1 reinforcement.
- Liberate when reinforcements reach 0.
- Deployment: Liberated castles let you deploy new units at the start of your phase.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Levels
To keep each playthrough unique and engaging, careful thought went into the world-generation systems. First, simplex noise generates the terrain—one seed shapes the topography (from mountains to oceans), while another determines flora density (forests, trees, plains).

Next, to place castles realistically, I used a space-optimized DP algorithm (O(nm) time, O(n) space) to find the largest square submatrix in each of the map’s 16x16 quadrants. This ensures castles occupy strategic positions, mirroring history—where they were often built on plains to control trade routes, farmland, and key transportation points while maximizing visibility against threats.

Finally, Kruskal’s algorithm connects castles via roads, forming a minimum spanning tree. These routes create meaningful choices: take faster, exposed paths or slower, safer ones through forests. Roads also extend as bridges over water, fixing the previous issue of isolated castles that took too long to reach.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Time Complexity Analysis
Due to token constraints with Pico-8 (8,192 token cutoff), I used insertion sort (`O(n²)`) for sorting operations. If I had used any other framework that didn’t have this limitation, I would’ve utilized more efficient methods like quicksort (`O(n log n)`). Below are the algorithms used and their theoretical complexities:

1. Uniform Cost Search (Pathfinding)
Purpose: Optimal pathfinding with terrain movement costs. When units have unlimited movement (`movement = nil`), the implementation reduces to standard Dijkstra’s algorithm.
    - Time Complexity: `O(V²)` (due to linear-time queue operations, optimizable to `O((V + E) log V)` with a priority queue).
    - Space Complexity: `O(V)` (stores all tiles).

2. Space-Optimized DP (Castle Placement)
Purpose: Evaluates logical castle placements on terrain.
    - Time Complexity: `O(mn)` (iterates over each cell in the grid once).
    - Space Complexity: `O(n)` (uses a 1D array of size n, the height of the grid).

3. Kruskal’s Algorithm (Road Network)
Purpose: Minimal-cost road connections (MST).
    - Time Complexity: `O(E²)` (due to insertion sort, optimizable to `O(E log E)` with efficient sorting).
    - Space Complexity: `O(E + V)` (stores edges + Union-Find data).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## License

Distributed under the project_license. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->
## Contact

Gustavo D'Mello - stavguo@duck.com - [website](https://gustavo.zip)

Project Link: [https://github.com/stavguo/pico-saga](https://github.com/stavguo/pico-saga)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->
## Acknowledgments

* [OpenSimplex Simple Mapgen v2.0 (2024 felice, incorporating code by kurt spencer))](https://www.lexaloffle.com/bbs/widget.php?pid=babikipahi)
* [RandomWizard's Enemy Placement Guide](https://feuniverse.us/t/randomwizards-enemy-placement-guide/14888)
* [Disjoint Set Data Structure](https://github.com/calebwin/disjoint)
* [Procedural Region Map Generator in the Gen-3 Pokémon Style](https://github.com/huderlem/porygion)
* [Pico-8 Minifier and Linter](https://github.com/thisismypassport/shrinko8)

<p align="right">(<a href="#readme-top">back to top</a>)</p>
