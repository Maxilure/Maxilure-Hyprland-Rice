import GLib from "gi://GLib?version=2.0"
import Gio from "gi://Gio?version=2.0"
import { execAsync } from "ags/process"
import { createState } from "ags"

export interface HyprlandWorkspace {
  id: number
  name: string
  monitor: string
  windows: number
  active: boolean
}

const [workspaces, setWorkspaces] = createState<HyprlandWorkspace[]>([])
const [activeId, setActiveId] = createState(0)
const [activeTitle, setActiveTitle] = createState("")

export { workspaces, activeId, activeTitle }

export async function switchWorkspace(id: number): Promise<void> {
  await execAsync(["sh", "-c", `hyprctl dispatch 'hl.dsp.focus({ workspace = ${id} })'`])
}

async function refreshWorkspaces(): Promise<void> {
  try {
    const monitorOut = await execAsync(["hyprctl", "monitors", "-j"])
    const monitors = JSON.parse(monitorOut) as Array<{
      name: string
      id: number
      focused: boolean
      activeWorkspace: { id: number }
    }>
    const focused = monitors.find((m) => m.focused)
    if (focused) {
      setActiveId(focused.activeWorkspace.id)
    }

    const wsOut = await execAsync(["hyprctl", "workspaces", "-j"])
    const raw = JSON.parse(wsOut) as Array<{
      id: number
      name: string
      monitor: string
      windows: number
    }>

    const wsList: HyprlandWorkspace[] = raw
      .filter((w) => w.id > 0)
      .map((w) => ({
        id: w.id,
        name: w.name,
        monitor: w.monitor,
        windows: w.windows,
        active: w.id === focused?.activeWorkspace.id,
      }))

    setWorkspaces(wsList)
  } catch (e) {
    console.error("Failed to refresh workspaces:", e)
  }
}

async function refreshActiveTitle(): Promise<void> {
  try {
    const out = await execAsync(["hyprctl", "activewindow", "-j"])
    const data = JSON.parse(out) as { title: string }
    setActiveTitle(data.title || "")
  } catch {
    setActiveTitle("")
  }
}

function updateState(): void {
  refreshWorkspaces()
  refreshActiveTitle()
}

// Subscribe to Hyprland event socket for instant updates
function subscribeToEvents(): void {
  try {
    const his = GLib.getenv("HYPRLAND_INSTANCE_SIGNATURE")
    if (!his) {
      console.error("HYPRLAND_INSTANCE_SIGNATURE not found")
      return
    }

    const xdgRuntime = GLib.getenv("XDG_RUNTIME_DIR") || "/run/user/1000"
    const socketPath = `${xdgRuntime}/hypr/${his}/.socket2.sock`

    const address = Gio.UnixSocketAddress.new(socketPath)
    const client = new Gio.SocketClient()

    client.connect_async(address, null, (_source, result) => {
      try {
        const connection = client.connect_finish(result)
        const inputStream = new Gio.DataInputStream({
          base_stream: connection.get_input_stream(),
        })

        const readLine = (): void => {
          inputStream.read_line_async(
            GLib.PRIORITY_DEFAULT,
            null,
            (_stream, res) => {
              try {
                const [line] = inputStream.read_line_finish_utf8(res)
                if (line !== null) {
                  const [event] = line.split(">>")

                  switch (event) {
                    case "workspace":
                    case "workspacev2":
                    case "focusedmon":
                    case "createworkspace":
                    case "destroyworkspace":
                    case "moveworkspace":
                    case "activewindow":
                    case "activewindowv2":
                    case "openwindow":
                    case "closewindow":
                      updateState()
                      break
                  }

                  readLine()
                } else {
                  connection.close(null)
                  setTimeout(subscribeToEvents, 2000)
                }
              } catch (e) {
                console.error("Hyprland socket read error:", e)
                connection.close(null)
                setTimeout(subscribeToEvents, 2000)
              }
            },
          )
        }

        updateState()
        readLine()
      } catch (e) {
        console.error("Hyprland socket connection error, retrying in 2s:", e)
        setTimeout(subscribeToEvents, 2000)
      }
    })
  } catch (e) {
    console.error("Failed to subscribe to Hyprland events:", e)
  }
}

// Subscribe to events for instant updates
subscribeToEvents()
