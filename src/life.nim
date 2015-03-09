import core

when isMainModule:
    var univ = newUniverse(width = 400, height = 300)
    echo("Height: ", univ.height)
    echo("1,1 age: ", univ.cellAt(1, 1).age)
    univ.evolve
    echo("1,1 age: ", univ.cellAt(1, 1).age)
