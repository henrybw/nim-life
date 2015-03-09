## Implements core logic for Conway's Game of Life. Exposes a Universe object
## composed of Cell objects. The Universe is constructed with a starting state,
## and can be evolved an arbitrary number of ages. Each Cell tracks whether it
## is alive or not, and how long it has been alive.
##
## N.B. For the sake of simplicity, this implementation assumes every cell
## outside of the grid is dead.

from sequtils import newSeqWith, filter
from strutils import repeatChar, `%`

const
    kDeadCell = -1
    kMaxCellAge = 6  # 7 steps, i.e. 0..6
                     # TODO: make this configurable?

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

proc newCell(alive: bool): Cell =
    Cell(alive: alive, age: if alive: 0 else: kDeadCell, liveNeighbors: 0)

proc newCell(): Cell =
    newCell(false)

proc countAlive(cells: seq[Cell]): int =
    cells.filter(proc (c: Cell): bool = c.alive).len

## Determines which physical slot in the universe this cell should be in.
proc cellSlot(univ: Universe, x, y: int): int =
    y * univ.width + x

proc newUniverse*(width: int, height: int): Universe =
    let cells = newSeqWith(width * height, newCell())
    return Universe(cells: cells, width: width, height: height, age: 0)

proc newUniverse*(cells: seq[seq[bool]]): Universe =
    # The bool matrix is inverted from our normal [x][y] convention, so when we
    # construct the universe, we need to swap the "x" and "y" coordinates from
    # the bool matrix.
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
proc evolveCellAt(univ: var Universe, x, y: int) =
    let slot = univ.cellSlot(x, y)
    var cell = univ.cellAt(x, y)

    if cell.alive:
        cell.alive = cell.liveNeighbors >= 2 and cell.liveNeighbors <= 3
    else:
        cell.alive = cell.liveNeighbors == 3
    cell.age = if cell.alive: min(cell.age + 1, kMaxCellAge) else: kDeadCell

    univ.cells[slot] = cell

## Evolves a generation according to the Game of Life rules
proc evolve*(univ: var Universe) =
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
    var divider = "+" & repeatChar(2 * univ.width - 1, '-') & "+"
    var str = "\n" & divider & "\n"
    for y in 0..univ.height - 1:
        str &= "|"
        for x in 0..univ.width - 1:
            str &= $univ.cellAt(x, y) & "|"
        str &= "\n"
        str &= divider & "\n"
    return str
