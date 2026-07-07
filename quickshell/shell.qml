//@ pragma UseQApplication
import Quickshell

ShellRoot {
    // Only instantiate bars on screens that should show one — an invisible
    // bar still costs a full component tree (tray, clock, panels, timers).
    Variants {
        model: {
            var all = [], matched = []
            var screens = Quickshell.screens
            for (var i = 0; i < screens.length; i++) {
                all.push(screens[i])
                if (screens[i].name === Settings.barScreen) matched.push(screens[i])
            }
            // Unknown/unset name -> all screens (covers monitor unplug too)
            return matched.length > 0 ? matched : all
        }
        Scope {
            required property var modelData
            Bar { screen: modelData }
        }
    }

    ToastLayer {
        // Note: Quickshell.screens is a plain list, not an ObjectModel — it
        // has no .values. Toasts follow the bar's screen unless overridden.
        screen: {
            var name = Settings.toastScreen !== "" ? Settings.toastScreen : Settings.barScreen
            var screens = Quickshell.screens
            for (var i = 0; i < screens.length; i++) {
                if (screens[i].name === name) return screens[i]
            }
            return screens.length > 0 ? screens[0] : null
        }
    }
}
