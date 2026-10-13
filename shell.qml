//@ pragma UseQApplication

import Quickshell
import qs.modules.bar
import qs.modules.menu

// Entry point. Each feature is a module under modules/ and is instantiated here.
// To add one (launcher, OSD, notifications, ...), create modules/<name>/ and list it below.
ShellRoot {
  Bar {}
  Menu {}
}
