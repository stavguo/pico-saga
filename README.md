<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a id="readme-top"></a>
<!--
*** Thanks for checking out the Best-README-Template. If you have a suggestion
*** that would make this better, please fork the repo and create a pull request
*** or simply open an issue with the tag "enhancement".
*** Don't forget to give the project a star!
*** Thanks again! Now go create something AMAZING! :D
-->



<!-- PROJECT LOGO -->
<br />
<div align="center">
<h3 align="center">Pico-Saga</h3>

  <p align="center">
    A tactical turn-based RPG featuring procedurally generated terrain.
    <br />
    <a href="https://gustavo.zip/pico-saga/"><strong>Play it here! »</strong></a>
    <br />
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
    <li><a href="#gameplay">Gameplay</a></li>
    <li>
      <a href="#mechanics">Mechanics</a>
      <ul>
        <li><a href="#units">Units</a></li>
        <li><a href="#terrain">Terrain</a></li>
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
The player and enemy take turns moving their units across the map, either engaging in combat or sieging castles. To win, the player must liberate all castles from enemy control. Some enemies stand guard, while others actively push to capture the player’s castles. Losing every castle results in defeat.

The combat system is turn-based, with outcomes heavily influenced by a rock-paper-scissors-like weapon matchup system. Careful positioning and favorable engagements provide an edge, but the player should expect to lose a few units in battles.

Fortunately, liberated castles provide new units to keep the advance going. Conversely, enemy reinforcements may deploy from their castles, forcing the player to balance aggression with caution.

### Controls
| Context       | Arrow Keys               | `C` Key                  | `X` Key                |
|---------------|--------------------------|--------------------------|------------------------|
| **Overworld** | Move cursor              | Select unit/castle       | Open pause menu        |
| **Castle**    | Move cursor/deploy selected unit  | Select unit              | Exit castle view       |
| **Movement**  | Move unit      | Confirm destination      | Cancel movement        |
| **Menu**      | Navigate options         | Select option           | Back/Exit menu        |


<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Mechanics
The game begins in the player’s phase, where the player uses the direction arrows to move a cursor on the map. Selecting a castle reveals the units inside. Pressing “C” while hovering over a unit displays their stats and movement range. To deselect a unit, exit a castle, or open the pause menu, press “X”. To deploy a unit, press any arrow key while it’s selected.

Each phase allows the player or enemy AI to move every unit once across the grid-based map. To move, select a unit and press the d-pad to enter the move menu. Units can move anywhere within their range, which is determined by terrain (each tile has a movement cost). Units with higher Mov stats travel farther per turn.

Press “C” to confirm movement, then choose to stand by, attack a nearby unit, or siege an adjacent enemy castle. Combat resolves automatically, factoring in unit stats, terrain effects, and luck.

To siege an enemy castle, position a player unit adjacent to it. The red pixels on the castle indicate remaining enemy reinforcements. Each turn, continuing the siege eliminates one reinforcement. Once all are removed, any adjacent player unit can liberate the castle—progressing the player toward victory and granting new deployable units.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Units
| Unit Type | Strong Against       |
|-----------|----------------------|
| Sword     | Axe                  |
| Axe       | Lance                |
| Lance     | Sword                |
| Monk      | Archer, Mage, Thief  |

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Terrain
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
