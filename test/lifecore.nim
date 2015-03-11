import unittest
from sequtils import concat, filter, foldl, mapIt, newSeqWith

include "../src/lifecore"

suite "core life tests":
    setup:
        proc toCellSeq(cells: seq[seq[bool]]): seq[Cell] =
            var cellSeq = foldl(cells, concat(a, b))
            cellSeq.mapIt(Cell, newCell(alive = it))

        # Helper to create a new universe surrounded by the given set of
        # neighbors.
        proc universeWithNeighborsAt(cellState: bool,
                                     x, y: int,
                                     neighbors: seq[seq[bool]]): Universe =
            var cells: seq[seq[bool]]
            deepCopy(cells, neighbors)
            cells[x].insert(cellState, y)  # Bool matrices are inverted
            return newUniverse(cells)

        # Special helper proc that discards cell age and only checks if the
        # live/dead cells in both universes match.
        proc cellsMatch(univ1: Universe, univ2: Universe): bool =
            let cells1 = univ1.cells.mapIt(bool, it.alive)
            let cells2 = univ2.cells.mapIt(bool, it.alive)
            return cells1 == cells2

        # Ugly because we're nesting sequences (which require '@' prefixing),
        # but it's more flexible for testing...
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

        # Universes must be constructed from actual bool matrices. Jagged 2D
        # sequences should fail.
        expect(IndexError):
            var jaggedUniv = newUniverse(killingNeighbors)

    test "out-of-bounds cellAt":
        var simpleUniv = newUniverse(simple)
        check:
            simpleUniv.cellAt(-1, -1).alive == false
            simpleUniv.cellAt(simpleUniv.width, 0).alive == false
            simpleUniv.cellAt(0, simpleUniv.height).alive == false
            simpleUniv.cellAt(simpleUniv.width, simpleUniv.height).alive == false

    test "countAlive":
        var cells = newSeqWith(20, newCell(false))
        check(cells.countAlive() == 0)

        cells[1].alive = true
        cells[5].alive = true
        check(cells.countAlive() == 2)

        check(killingNeighbors.toCellSeq().countAlive() == 5)
        check(revivingNeighbors.toCellSeq().countAlive() == 3)
        check(passiveNeighbors.toCellSeq().countAlive() == 2)

    test "neighborsAt":
        let killing = universeWithNeighborsAt(true, 1, 1, killingNeighbors)
        let reviving = universeWithNeighborsAt(true, 1, 1, revivingNeighbors)
        let passive = universeWithNeighborsAt(true, 1, 1, passiveNeighbors)

        check(len(killing.neighborsAt(1, 1)) == len(killingNeighbors.toCellSeq()))
        check(len(reviving.neighborsAt(1, 1)) == len(revivingNeighbors.toCellSeq()))
        check(len(passive.neighborsAt(1, 1)) == len(passiveNeighbors.toCellSeq()))

        check(killing.neighborsAt(0, 0).countAlive() == 2, "out-of-bounds neighbors check")

    test "evolveCellAt":
        var univ: Universe

        univ = universeWithNeighborsAt(true, 1, 1, killingNeighbors)
        check(univ.cellAt(1, 1).alive == true, "cell to be killed starts alive")
        univ.evolve()
        check(univ.cellAt(1, 1).alive == false, "cell to be killed gets killed")

        univ = universeWithNeighborsAt(false, 1, 1, revivingNeighbors)
        check(univ.cellAt(1, 1).alive == false, "cell to be revived starts dead")
        univ.evolve()
        check(univ.cellAt(1, 1).alive == true, "cell to be revived gets revived")

        univ = universeWithNeighborsAt(true, 1, 1, passiveNeighbors)
        check(univ.cellAt(1, 1).alive == true, "cell with passive neighbors starts alive")
        univ.evolve()
        check(univ.cellAt(1, 1).alive == true, "cell with passive neighbors stays alive")

        univ = universeWithNeighborsAt(false, 1, 1, passiveNeighbors)
        check(univ.cellAt(1, 1).alive == false, "cell with passive neighbors starts dead")
        univ.evolve()
        check(univ.cellAt(1, 1).alive == false, "cell with passive neighbors starts dead")

    test "evolve and cell age":
        var univ = newUniverse(grid)
        let referenceUniv = newUniverse(gridEvolved)
        univ.evolve()

        check(univ.cellsMatch(referenceUniv))
        check(univ.cellAt(0, 0).age == 0)
        check(univ.cellAt(3, 0).age == 1)
        check(univ.cellAt(1, 1).age == 1)
        check(univ.cellAt(4, 1).age == 1)
        check(univ.cellAt(2, 2).age == 1)
        check(univ.cellAt(4, 2).age == 1)
        check(univ.cellAt(5, 2).age == 1)
        check(univ.cellAt(1, 3).age == 1)

        univ.evolve()
        check(univ.cellAt(0, 0).age == 0)
        check(univ.cellAt(3, 0).age == 0)
        check(univ.cellAt(1, 1).age == 0)
        check(univ.cellAt(2, 1).age == 1)
        check(univ.cellAt(4, 1).age == 2)
        check(univ.cellAt(5, 1).age == 1)
        check(univ.cellAt(1, 2).age == 1)
        check(univ.cellAt(2, 2).age == 2)
        check(univ.cellAt(3, 2).age == 1)
        check(univ.cellAt(4, 2).age == 2)
        check(univ.cellAt(5, 2).age == 2)
        check(univ.cellAt(1, 3).age == 0)

        # TODO: add glider as a test case
