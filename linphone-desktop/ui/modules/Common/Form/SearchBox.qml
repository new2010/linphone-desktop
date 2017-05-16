import QtQuick 2.7
import QtQuick.Window 2.2

import Common 1.0
import Utils 1.0

// =============================================================================
// A reusable search input which display a entries model in a menu.
// Each entry can be filtered with the search input.
// =============================================================================

Item {
  id: searchBox

  // ---------------------------------------------------------------------------

  readonly property alias filter: searchField.text
  readonly property alias isOpen: searchBox._isOpen

  property alias delegate: list.delegate
  property alias header: list.header
  property alias entryHeight: menu.entryHeight
  property alias maxMenuHeight: menu.maxMenuHeight

  // This property must implement `setFilter` function.
  property alias model: list.model

  property alias placeholderText: searchField.placeholderText

  property bool _isOpen: false

  // ---------------------------------------------------------------------------

  signal menuClosed
  signal menuOpened
  signal menuRequested
  signal enterPressed

  // ---------------------------------------------------------------------------

  function hideMenu () {
    if (!_isOpen) {
      return
    }

    _isOpen = false
  }

  function showMenu () {
    if (_isOpen) {
      return
    }

    _isOpen = true
  }

  function _filter (text) {
    Utils.assert(model.setFilter != null, '`model.setFilter` must be defined.')
    model.setFilter(text)
  }

  function _handleCoords () {
    searchBox.hideMenu()

    var point = searchBox.mapToItem(null, 0, searchBox.height)

    desktopPopup.popupX = window.x + point.x
    desktopPopup.popupY = window.y + point.y
  }

  // ---------------------------------------------------------------------------

  implicitHeight: searchField.height

  Item {
    implicitHeight: searchField.height
    width: parent.width

    TextField {
      id: searchField

      icon: 'search'
      width: parent.width

      Keys.onEscapePressed: searchBox.hideMenu()
      Keys.onReturnPressed: {
        searchBox.hideMenu()
        searchBox.enterPressed()
      }

      onActiveFocusChanged: {
        if (activeFocus && !_isOpen) {
          searchBox.menuRequested()
          searchBox.showMenu()
        }
      }

      onTextChanged: _filter(text)
    }

    // -------------------------------------------------------------------------

    Connections {
      target: searchBox.Window.window

      onHeightChanged: _handleCoords()
      onWidthChanged: _handleCoords()

      onXChanged: _handleCoords()
      onYChanged: _handleCoords()

      onVisibilityChanged: _handleCoords()
    }

    // Wrap the search box menu in a window.
    DesktopPopup {
      id: desktopPopup

      requestActivate: true

      onVisibleChanged: !visible && searchBox.hideMenu()

      DropDownDynamicMenu {
        id: menu

        // If the menu is focused, the main window loses the active status.
        // So It's necessary to map the keys events.
        Keys.forwardTo: searchField

        onMenuClosed: searchBox.hideMenu()

        ScrollableListView {
          id: list

          headerPositioning: header ? ListView.OverlayHeader : ListView.InlineFooter
          width: searchField.width
        }
      }
    }
  }

  // ---------------------------------------------------------------------------

  states: State {
    name: 'opened'
    when: _isOpen
  }

  transitions: [
    Transition {
      from: ''
      to: 'opened'

      ScriptAction {
        script: {
          menu.show()
          desktopPopup.show()

          searchBox.menuOpened()
        }
      }
    },

    Transition {
      from: 'opened'
      to: ''

      ScriptAction {
        script: {
          menu.hide()
          searchField.focus = false
          desktopPopup.hide()

          searchBox.menuClosed()
        }
      }
    }
  ]
}
