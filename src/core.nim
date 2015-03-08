type
    Cell = object
        alive: bool
        age: int

    CellGrid = object
        cells: seq[Cell]
