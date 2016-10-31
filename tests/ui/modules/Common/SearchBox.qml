import QtQuick 2.7
import QtQuick.Controls 2.0

import Common.Styles 1.0
import Utils 1.0

// ===================================================================
// A reusable search input which display a entries model in a menu.
// Each entry can be filtered with the search input.
// ===================================================================

Item {
  id: searchBox

  property alias delegate: list.delegate
  property alias entryHeight: menu.entryHeight
  property alias maxMenuHeight: menu.maxMenuHeight

  // This property must implement `setFilterFixedString` and/or
  // `invalidate` functions.
  property alias model: list.model

  property alias placeholderText: searchField.placeholderText

  property bool _isOpen: false

  signal menuClosed
  signal menuOpened

  // -----------------------------------------------------------------

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
    Utils.assert(
      model.setFilterFixedString != null,
      '`model.setFilterFixedString` must be defined.'
    )

    model.setFilterFixedString(text)
    if (model.invalidate) {
      model.invalidate()
    }
  }

  // -----------------------------------------------------------------

  implicitHeight: searchField.height

  Item {
    implicitHeight: searchField.height + menu.height
    width: parent.width

    TextField {
      id: searchField

      background: SearchBoxStyle.searchFieldBackground
      color: SearchBoxStyle.text.color
      font.pointSize: SearchBoxStyle.text.fontSize
      width: parent.width

      Keys.onEscapePressed: searchBox.hideMenu()

      onActiveFocusChanged: activeFocus && searchBox.showMenu()
      onTextChanged: _filter()

      Icon {
        anchors {
          right: parent.right
          rightMargin: parent.rightPadding
          verticalCenter: parent.verticalCenter
        }

        icon: 'search'
        iconSize: parent.contentHeight
        visible: !parent.text
      }
    }

    // Wrap the search box menu in a window.
    DesktopPopup {
      id: desktopPopup

      // The menu is always below the search field.
      property point coords: {
        var point = searchBox.mapToItem(null, 0, searchBox.height)
        point.x += window.x
        point.y += window.y

        return point
      }

      popupX: coords.x
      popupY: coords.y

      onVisibleChanged: !visible && searchBox.hideMenu()

      DropDownDynamicMenu {
        id: menu

        launcher: searchField
        width: searchField.width

        onMenuClosed: searchBox.hideMenu()

        ScrollableListView {
          id: list

          anchors.fill: parent
        }
      }
    }
  }

  // -----------------------------------------------------------------

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
          menu.showMenu()
          desktopPopup.show()

          menuOpened()
        }
      }
    },

    Transition {
      from: 'opened'
      to: ''

      ScriptAction {
        script: {
          menu.hideMenu()
          searchField.focus = false
          desktopPopup.hide()

          menuClosed()
        }
      }
    }
  ]
}