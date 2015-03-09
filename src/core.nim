## Implements core logic for Conway's Game of Life. Exposes a Universe object
## composed of Cell objects. The Universe is constructed with a starting state,
## and can be evolved an arbitrary number of ages. Each Cell tracks whether it
## is alive or not, and how long it has been alive.
##
## NOTE: For the sake of simplicity, this implementation assumes every cell
## outside of the grid is dead.

from sequtils import filter, newSeqWith
from strutils import repeatChar, `%`

type
    Cell* = ref CellObj
    CellObj = object
        alive*: bool
        age*: int
        liveNeighbors: int

    Universe* = object
        cells: seq[Cell]
        width: int
        height: int
        age: int

## Constructs a new cell.
proc newCell(alive: bool): Cell =
    Cell(alive: alive, age: 0, liveNeighbors: 0)

## Constructs a new (dead) cell.
proc newCell(): Cell =
    newCell(false)

## Counts the number of living cells in the given sequence of cells.
proc countAlive(cells: seq[Cell]): int =
    cells.filter(proc (c: Cell): bool = c.alive).len

## Determines which physical slot in the universe this cell should be in.
proc cellSlot(univ: Universe, x, y: int): int =
    y * univ.width + x

## Creates an empty universe of the given dimensions. Each cell starts off dead.
proc newUniverse*(width: int, height: int): Universe =
    let cells = newSeqWith(width * height, newCell())
    return Universe(cells: cells, width: width, height: height, age: 0)

## Creates a universe from the given 2D matrix of booleans, representing
## live/dead cells. The bool matrix should be constructed in the form of
## [y][x], since this allows the bool matrix to be visually laid out in an
## [x][y] manner.
##
## NOTE: This assumes that each dimension has the same width/height. If the
## bool matrix is jagged in any way, this will throw an IndexError.
proc newUniverse*(cells: seq[seq[bool]]): Universe =
    # Swap the "x" and "y" coordinates from the bool matrix, since it's inverted
    var univ = newUniverse(cells[0].len, cells.len)
    for x in cells[0].low .. cells[0].high:
        for y in cells.low .. cells.high:
            univ.cells[univ.cellSlot(x, y)] = newCell(cells[y][x])
    return univ

## Universe width/height should be immutable after creation, so only expose
## read-only properties for them.

proc width*(univ: Universe): int {.inline.} =
    univ.width

proc height*(univ: Universe): int {.inline.} =
    univ.height

## Returns the cell at (x,y) in the given universe. If the requested cell is
## outside the bounds of the universe, this just assumes that the cell is dead.
proc cellAt*(univ: Universe, x, y: int): Cell {.inline.} =
    if x >= 0 and x < univ.width and y >= 0 and y < univ.height:
        return univ.cells[univ.cellSlot(x, y)]
    else:
        return newCell()

## Returns a sequence of cells representing the neighbors of the cell at (x,y)
## in the given universe.
proc neighborsAt(univ: Universe, x, y: int): seq[Cell] =
    @[univ.cellAt(x - 1, y - 1),
      univ.cellAt(  x  , y - 1),
      univ.cellAt(x + 1, y - 1),

      univ.cellAt(x - 1,   y  ),
      # This space intentionally left blank
      univ.cellAt(x + 1,   y  ),

      univ.cellAt(x - 1, y + 1),
      univ.cellAt(  x  , y + 1),
      univ.cellAt(x + 1, y + 1)]

## Decides if the given cell, in the context of the universe it is in, should
## live, according to the following rules:
##
## 1. Any live cell with fewer than two live neighbors dies, as if caused by
##    under-population.
## 2. Any live cell with two or three live neighbors lives on to the next
##    generation.
## 3. Any live cell with more than three live neighbors dies, as if by
##    overcrowding.
## 4. Any dead cell with exactly three live neighbors becomes a live cell, as
##    if by reproduction.
##
## NOTE: This depends on each cell having a cached count of live neighbors, and
## thus this procedure should never be called directly.
proc evolveCellAt(univ: var Universe, x, y: int) =
    var cell = univ.cellAt(x, y)

    if cell.alive:
        cell.alive = cell.liveNeighbors >= 2 and cell.liveNeighbors <= 3
    else:
        cell.alive = cell.liveNeighbors == 3

    cell.age = if cell.alive: cell.age + 1 else: 0
    univ.cells[univ.cellSlot(x, y)] = cell

## Evolves a generation according to the Game of Life rules
proc evolve*(univ: var Universe) =
    # Snapshot the live neighbors before we start evolving the cells. If we
    # don't do this, we'll end up mutating the neighbors as we are evolving
    # each cell, which will affect life or death decisions and lead to
    # incorrect evolution.
    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            univ.cellAt(x, y).liveNeighbors = univ.neighborsAt(x, y).countAlive()

    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            univ.evolveCellAt(x, y)

    inc(univ.age)

proc `$`(cell: Cell): string =
    return if cell.alive: $cell.age else: " "

proc `$`*(univ: Universe): string =
    let divider = "+" & repeatChar(2 * univ.width - 1, '-') & "+"
    var str = "\n" & divider & "\n"
    for y in 0..univ.height - 1:
        str &= "|"
        for x in 0..univ.width - 1:
            str &= $univ.cellAt(x, y) & "|"
        str &= "\n"
        str &= divider & "\n"
    return str
