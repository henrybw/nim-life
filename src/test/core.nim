import unittest
from sequtils import concat, foldl, filter, mapIt, newSeqWith

include "../core"

suite "core life tests":
    setup:
        proc toCells(cells: seq[seq[bool]]): seq[Cell] =
            var cellSeq = foldl(cells, concat(a, b))
            cellSeq.mapIt(Cell, newCell(alive = it))

        proc universeWithneighborsAt(cellState: bool,
                                   x, y: int,
                                   neighbors: seq[seq[bool]]): Universe =
            var cells: seq[seq[bool]]
            deepCopy(cells, neighbors)
            cells[x].insert(cellState, y)  # Bool matrices are inverted
            return newUniverse(cells)

        # Ugly because we're nesting sequences of sequences, but it's more
        # flexible for testing...
        let simple = @[@[true,  false],
                       @[false, true],
                       @[true,  true]]

        let grid =        @[@[true , false, false, false, true , false],
                            @[false, false, true , false, true , false],
                            @[true , false, false, false, true , true ],
                            @[false, true , true , false, false, false]]

        let gridEvolved = @[@[false, false, false, true , false, false],
                            @[false, true , false, false, true , false],
                            @[false, false, true , false, true , true ],
                            @[false, true , false, false, false, false]]

        let killingNeighbors = @[@[true , true , true],
                                 @[false, true],
                                 @[true , false, false]]
        let revivingNeighbors = @[@[true , false, false],
                                  @[false, true],
                                  @[true , false, false]]
        let passiveNeighbors = @[@[true , false, false],
                                @[false, true],
                                @[false, false, false]]

    test "newUniverse":
        var blankUniv = newUniverse(width = 4, height = 3)
        check:
            blankUniv.width == 4
            blankUniv.height == 3
            blankUniv.cells.filter(proc (c: Cell): bool = c.alive).len == 0

        var simpleUniv = newUniverse(simple)
        check:
            simpleUniv.width == 2
            simpleUniv.height == 3
            simpleUniv.cellAt(0, 0).alive == true
            simpleUniv.cellAt(1, 0).alive == false
            simpleUniv.cellAt(0, 1).alive == false
            simpleUniv.cellAt(1, 1).alive == true
            simpleUniv.cellAt(0, 2).alive == true
            simpleUniv.cellAt(1, 2).alive == true

    test "countAlive":
        var cells = newSeqWith(20, newCell(false))
        check(cells.countAlive() == 0)

        cells[1].alive = true
        cells[5].alive = true
        check(cells.countAlive() == 2)

        check(killingNeighbors.toCells().countAlive() == 5)
        check(revivingNeighbors.toCells().countAlive() == 3)
        check(passiveNeighbors.toCells().countAlive() == 2)

    test "neighborsAt":
        let killing = universeWithNeighborsAt(true, 1, 1, killingNeighbors)
        let reviving = universeWithNeighborsAt(true, 1, 1, revivingNeighbors)
        let passive = universeWithNeighborsAt(true, 1, 1, passiveNeighbors)

        check(len(killing.neighborsAt(1, 1)) == len(killingNeighbors.toCells()))
        check(len(reviving.neighborsAt(1, 1)) == len(revivingNeighbors.toCells()))
        check(len(passive.neighborsAt(1, 1)) == len(passiveNeighbors.toCells()))

    test "evolveCellAt":
        var univ: Universe

        univ = universeWithNeighborsAt(true, 1, 1, killingNeighbors)
        check(univ.cellAt(1, 1).alive == true, "cell to be killed starts alive")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == false, "cell to be killed gets killed")

        univ = universeWithNeighborsAt(false, 1, 1, killingNeighbors)
        check(univ.cellAt(1, 1).alive == false, "cell to be killed starts dead")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == false, "cell to be killed is still dead")

        univ = universeWithNeighborsAt(false, 1, 1, revivingNeighbors)
        check(univ.cellAt(1, 1).alive == false, "cell to be revived starts dead")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == true, "cell to be revived gets revived")

        univ = universeWithNeighborsAt(true, 1, 1, revivingNeighbors)
        check(univ.cellAt(1, 1).alive == true, "cell to be revived starts alive")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == true, "cell to be revived is still alive")

        univ = universeWithNeighborsAt(true, 1, 1, passiveNeighbors)
        check(univ.cellAt(1, 1).alive == true, "cell with passive neighbors starts alive")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == true, "cell with passive neighbors stays alive")

        univ = universeWithNeighborsAt(false, 1, 1, passiveNeighbors)
        check(univ.cellAt(1, 1).alive == false, "cell with passive neighbors starts dead")
        univ.evolveCellAt(1, 1)
        check(univ.cellAt(1, 1).alive == false, "cell with passive neighbors starts dead")

    test "evolve":
        var univ = newUniverse(grid)
        univ.evolve()
        
        var evolvedCells = univ.cells.mapIt(bool, it.alive)
        var referenceCells = newUniverse(gridEvolved).cells.mapIt(bool, it.alive)
        check(evolvedCells == referenceCells)
