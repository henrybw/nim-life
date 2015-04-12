import random
import sdl2, sdl2/gfx
import "../lifecore"

const
    kDefaultPixelSize = 8
    kDefaultCellGradient = 10  # Steps from brightest to darkest
    kDefaultCellMinAlpha = 50

proc init(univ: var Universe) =
    # Cell population is generated with every cell having a 1/5 chance of
    # starting the game alive.
    var pool = @[true, false, false, false, false]
    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            univ.setCellAt(x, y, newCell(pool.randomChoice()))

proc resize(univ: var Universe, width, height: int) =
    # TODO: would be nice if we could "import" the old universe somehow...
    # TODO: this makes things *really* slow...
    univ = newUniverse(width, height)
    univ.init()

proc render(univ: Universe, renderer: RendererPtr) =
    for x in 0..univ.width - 1:
        for y in 0..univ.height - 1:
            var cell = univ.cellAt(x, y)
            if cell.alive:
                var cellRect = (cint(x * kDefaultPixelSize), cint(y * kDefaultPixelSize),
                                cint(kDefaultPixelSize), cint(kDefaultPixelSize))
                var alpha = max((255 * (kDefaultCellGradient - cell.age + 1)) /
                                 kDefaultCellGradient, kDefaultCellMinAlpha)
                renderer.setDrawColor(r = 0, g = 0, b = 255, a = uint8(alpha))
                renderer.fillRect(cellRect)

proc main*() =
    discard sdl2.init(INIT_EVERYTHING)

    var
        univ = newUniverse(128, 96)
        window = createWindow("Game of Life",
                              x = 15, y = 15,
                              w = cint(univ.width * kDefaultPixelSize),
                              h = cint(univ.height * kDefaultPixelSize),
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
        while pollEvent(evt):
            case evt.kind
            of WindowEvent:
                var windowEvent = cast[WindowEventPtr](addr(evt))
                if windowEvent.event == WindowEvent_Resized:
                    let newWidth = windowEvent.data1
                    let newHeight = windowEvent.data2
                    univ.resize(newWidth, newHeight)
            of KeyDown:
                var keyEvent = cast[KeyboardEventPtr](addr(evt))

                # We cast here because modifier keys are outside the range of a
                # character.
                if cast[char](keyEvent.keysym.sym) == 'q':
                    done = true
            of QuitEvent:
                done = true
                break
            else:
                discard

        renderer.setDrawColor(0, 0, 0, 255)
        renderer.clear()

        univ.render(renderer)
        univ.evolve()

        renderer.present()
        fpsMan.delay()

    destroy(renderer)
    destroy(window)

when isMainModule:
    main()
