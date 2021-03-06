import nimprof
import os
import parseopt2
import parseutils
import random
import sdl2, sdl2/gfx
import "../lifecore"

type
    UniverseStyle = object
        width, height: int
        pixelSize: int
        fgColor, bgColor: Color
        cellMinAlpha: int
        cellGradient: int

proc defaultUniverseStyle() : UniverseStyle =
    UniverseStyle(width: 128,
                  height: 98,
                  pixelSize: 8,
                  fgColor: (r: 85u8, g: 255u8, b: 255u8, a: 255u8),  # Cyan
                  bgColor: (r: 4u8, g: 45u8, b: 55u8, a: 255u8),  # Dark green
                  cellMinAlpha: 50,
                  cellGradient: 10)

proc init(univ: var Universe) =
    # Cell population is generated with every cell having a 1/5 chance of
    # starting the game alive.
    var pool = @[true, false, false, false, false]
    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            univ.setCellAt(x, y, newCell(pool.randomChoice()))

proc resize(univ: var Universe, width, height: int) =
    # TODO: dynamically resize the universe
    discard

proc renderCellAt(renderer: RendererPtr, cell: Cell, x, y: int, style: UniverseStyle) =
    var cellRect = (cint(x * style.pixelSize),
                    cint(y * style.pixelSize),
                    cint(style.pixelSize),
                    cint(style.pixelSize))
    var step = max(style.cellGradient - cell.age + 1, 1)
    var alpha = max((255 * step) /% style.cellGradient,
                    style.cellMinAlpha)
    renderer.setDrawColor(r = style.fgColor.r,
                          g = style.fgColor.g,
                          b = style.fgColor.b,
                          a = uint8(alpha))
    renderer.fillRect(cellRect)

proc renderUniverse(renderer: RendererPtr, univ: Universe, style: UniverseStyle) =
    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            var cell = univ.cellAt(x, y)
            if cell.alive:
                renderer.renderCellAt(cell, x, y, style)

proc usage() =
    echo "Usage:"
    echo "life [--width=N] [--height=N] [--pixel-size=N]"
    echo "     [--fg-color=HEXCOLOR] [--bg-color=HEXCOLOR]"
    echo "     [--gradient=N] [--min-alpha=0-255]"

proc configureStyle(): UniverseStyle =
    var style = defaultUniverseStyle()
    for kind, key, val in getopt():
        case kind
        of cmdLongOption:
            case key
            of "bg-color", "fg-color":
                var r, g, b: int
                discard parseHex(val[0..1], r)
                discard parseHex(val[2..3], g)
                discard parseHex(val[4..5], b)
                if key == "fg-color":
                    style.fgColor = (r: uint8(r), g: uint8(g), b: uint8(b),
                                     a: 255u8)
                else:
                    style.bgColor = (r: uint8(r), g: uint8(g), b: uint8(b),
                                     a: 255u8)

            of "pixel-size":
                discard parseInt(val, style.pixelSize)

            of "gradient":
                discard parseInt(val, style.cellGradient)

            of "min-alpha":
                discard parseInt(val, style.cellMinAlpha)

            of "width":
                discard parseInt(val, style.width)

            of "height":
                discard parseInt(val, style.height)

            of "help":
                usage()
                quit(0)

            else:
                echo "Unrecognized option '", key, "'"
                usage()
                quit(1)

        else:
            usage()
            quit(1)

    return style

proc main*() =
    discard sdl2.init(INIT_EVERYTHING)

    var
        style = configureStyle()
        univ = newUniverse(style.width, style.height)
        window = createWindow("Game of Life (press 'q' to quit)",
                              x = 15, y = 15,
                              w = cint(univ.width * style.pixelSize),
                              h = cint(univ.height * style.pixelSize),
                              flags = SDL_WINDOW_SHOWN)
        renderer = createRenderer(window, -1,
                                Renderer_Accelerated or
                                Renderer_PresentVsync or
                                Renderer_TargetTexture)
        evt = sdl2.defaultEvent
        done = false
        fpsMan: FpsManager

    univ.init()
    fpsMan.init()
    renderer.setDrawBlendMode(BlendMode_Blend)

    while not done:
        var mouseDown = false
        while pollEvent(evt):
            case evt.kind
            of WindowEvent:
                let windowEvent = cast[WindowEventPtr](addr(evt))
                if windowEvent.event == WindowEvent_Resized:
                    let newWidth = windowEvent.data1
                    let newHeight = windowEvent.data2
                    univ.resize(newWidth, newHeight)

            of KeyDown:
                let keyEvent = cast[KeyboardEventPtr](addr(evt))

                # We cast here because modifier keys are outside the range of a
                # character.
                if cast[char](keyEvent.keysym.sym) == 'q':
                    done = true

            of MouseMotion:
                if (getMouseState(nil, nil) and SDL_BUTTON(BUTTON_LEFT)) != 0:
                    let mouseEvent = cast[MouseMotionEventPtr](addr(evt))
                    let cellX = int(mouseEvent.x /% style.pixelSize)
                    let cellY = int(mouseEvent.y /% style.pixelSize)
                    let createdCell = newCell(true)

                    univ.setCellAt(cellX, cellY, createdCell)
                    renderer.renderCellAt(createdCell, cellX, cellY, style)

            of QuitEvent:
                done = true
                break

            else:
                discard

        renderer.setDrawColor(style.bgColor.r, style.bgColor.g, style.bgColor.b,
                              style.bgColor.a)
        renderer.clear()

        renderer.renderUniverse(univ, style)
        univ.evolve()

        renderer.present()
        fpsMan.delay()

    destroy(renderer)
    destroy(window)

when isMainModule:
    main()
