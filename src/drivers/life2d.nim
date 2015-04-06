import sdl2, sdl2/gfx
import "../lifecore"

proc resize(univ: var Universe, width: int, height: int) =
    # TODO: implement!
    return

proc render(univ: Universe, renderer: RendererPtr) =
    # TODO: implement!
    return

proc main*() =
    discard sdl2.init(INIT_EVERYTHING)

    var
        univ = newUniverse(640, 480)
        window = createWindow("Game of Life",
                              x = 100, y = 100,
                              w = int32(univ.width), h = int32(univ.height),
                              flags = SDL_WINDOW_SHOWN)
        renderer = createRenderer(window, -1,
                                Renderer_Accelerated or
                                Renderer_PresentVsync or
                                Renderer_TargetTexture)
        evt = sdl2.defaultEvent
        done = false
        fpsMan: FpsManager

    fpsMan.init()

    while not done:
        while pollEvent(evt):
            if evt.kind == QuitEvent:
                done = true
                break
            if evt.kind == WindowEvent:
                var windowEvent = cast[WindowEventPtr](addr(evt))
                if windowEvent.event == WindowEvent_Resized:
                    let newWidth = windowEvent.data1
                    let newHeight = windowEvent.data2
                    univ.resize(newWidth, newHeight)

        renderer.setDrawColor(0, 0, 0, 255)
        renderer.clear()

        univ.render(renderer)

        renderer.present()
        fpsMan.delay()

    destroy(renderer)
    destroy(window)

when isMainModule:
    main()
