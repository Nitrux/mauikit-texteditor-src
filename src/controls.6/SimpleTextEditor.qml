import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.texteditor as TE

/**
 * @since org.mauikit.texteditor 1.0
 * @brief Lightweight text editor component
 *
 * A simpler editable text surface intended for note-taking and general text
 * editing scenarios that do not need a synchronized gutter or other
 * code-editor-specific UI.
 *
 * The editor is controlled by DocumentHandler, which manages file I/O,
 * syntax highlighting, search, and other document-related features.
 *
 * @see CodeEditor
 * @see DocumentHandler
 */
Page
{
    id: control

    padding: 0
    focus: false
    clip: false
    title: document.fileName + (document.modified ? "*" : "")

    property bool showFindBar: false
    property bool showLineNumbers: false
    property bool spellcheckEnabled: false
    property bool showSpellingContextMenu: true

    readonly property alias body: body
    readonly property alias document: document
    readonly property alias scrollView: _scrollView
    readonly property alias documentMenu: _contextMenu

    property alias text: body.text
    property alias uppercase: document.uppercase
    property alias underline: document.underline
    property alias italic: document.italic
    property alias bold: document.bold
    property alias canRedo: body.canRedo
    property alias fileUrl: document.fileUrl

    onShowFindBarChanged:
    {
        if(showFindBar)
        {
            _findField.forceActiveFocus()
        }else
        {
            body.forceActiveFocus()
        }
    }

    TE.DocumentHandler
    {
        id: document
        document: body.textDocument
        cursorPosition: body.cursorPosition
        selectionStart: body.selectionStart
        selectionEnd: body.selectionEnd
        backgroundColor: control.Maui.Theme.backgroundColor
        enableSyntaxHighlighting: false
        findCaseSensitively: _findCaseSensitively.checked
        findWholeWords: _findWholeWords.checked

        onSearchFound: (start, end) =>
        {
            body.select(start, end)
        }
    }

    Menu
    {
        id: _contextMenu

        MenuItem
        {
            text: i18n("Cut")
            enabled: !body.readOnly && body.selectedText.length > 0
            onTriggered: body.cut()
        }

        MenuItem
        {
            text: i18n("Copy")
            enabled: body.selectedText.length > 0
            onTriggered: body.copy()
        }

        MenuItem
        {
            text: i18n("Paste")
            enabled: !body.readOnly
            onTriggered: body.paste()
        }

        MenuSeparator {}

        MenuItem
        {
            text: i18n("Select All")
            onTriggered: body.selectAll()
        }
    }

    footer: Maui.ToolBar
    {
        id: _findToolBar
        visible: showFindBar
        width: parent.width
        position: ToolBar.Footer
        forceCenterMiddleContent: false

        leftContent: [
            ToolButton
            {
                id: _findCaseSensitively
                icon.name: "format-text-uppercase"
                checkable: true

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18nd("mauikittexteditor", "Case Sensitive")
            },

            ToolButton
            {
                id: _findWholeWords
                icon.name: "edit-select-text"
                checkable: true

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18nd("mauikittexteditor", "Whole Words Only")
            }
        ]

        middleContent: RowLayout
        {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: Maui.Style.space.small

            Maui.SearchField
            {
                id: _findField
                Layout.fillWidth: true
                Layout.maximumWidth: _replaceButton.checked ? 320 : 500
                Layout.alignment: Qt.AlignCenter
                placeholderText: i18nd("mauikittexteditor", "Find")

                onAccepted:
                {
                    document.find(text)
                }

                actions: [
                    Action
                    {
                        enabled: _findField.text.length > 0
                        icon.name: "arrow-up"
                        onTriggered: document.find(_findField.text, false)
                    }
                ]
            }

            Maui.SearchField
            {
                id: _replaceField
                visible: _replaceButton.checked
                enabled: visible && !body.readOnly
                Layout.fillWidth: visible
                Layout.maximumWidth: visible ? 320 : 0
                Layout.alignment: Qt.AlignCenter
                placeholderText: i18nd("mauikittexteditor", "Replace")
                icon.source: "edit-find-replace"
                actions: Action
                {
                    text: i18nd("mauikittexteditor", "Replace")
                    enabled: _replaceField.text.length > 0
                    icon.name: "checkmark"
                    onTriggered: document.replace(_findField.text, _replaceField.text)
                }
            }
        }

        rightContent: RowLayout
        {
            spacing: Maui.Style.space.small

            ToolButton
            {
                id: _replaceButton
                icon.name: "edit-find-replace"
                enabled: !body.readOnly
                checkable: true

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18nd("mauikittexteditor", "Replace")
            }

            Button
            {
                visible: _replaceButton.checked
                enabled: !body.readOnly && _replaceField.text.length > 0
                text: i18nd("mauikittexteditor", "Replace All")
                onClicked: document.replaceAll(_findField.text, _replaceField.text)
            }
        }
    }

    header: Column
    {
        width: parent.width

        Repeater
        {
            model: document.alerts

            Maui.ToolBar
            {
                id: _alertBar
                property var alert: model.alert
                readonly property int index_: index
                width: parent.width

                Maui.Theme.backgroundColor:
                {
                    switch(alert.level)
                    {
                    case 0: return Maui.Theme.positiveBackgroundColor
                    case 1: return Maui.Theme.neutralBackgroundColor
                    case 2: return Maui.Theme.negativeBackgroundColor
                    }
                }

                Maui.Theme.textColor:
                {
                    switch(alert.level)
                    {
                    case 0: return Maui.Theme.positiveTextColor
                    case 1: return Maui.Theme.neutralTextColor
                    case 2: return Maui.Theme.negativeTextColor
                    }
                }

                forceCenterMiddleContent: false

                middleContent: Maui.ListItemTemplate
                {
                    Maui.Theme.inherit: true
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    label1.text: alert.title
                    label2.text: alert.body
                }

                rightContent: Repeater
                {
                    model: alert.actionLabels

                    Button
                    {
                        property int index_: index
                        text: modelData
                        onClicked: alert.triggerAction(index_, _alertBar.index_)

                        Maui.Theme.backgroundColor: Qt.lighter(_alertBar.Maui.Theme.backgroundColor, 1.2)
                        Maui.Theme.hoverColor: Qt.lighter(_alertBar.Maui.Theme.backgroundColor, 1)
                        Maui.Theme.textColor: Qt.darker(Maui.Theme.backgroundColor)
                    }
                }
            }
        }
    }

    contentItem: Item
    {
        ScrollView
        {
            id: _scrollView
            anchors.fill: parent
            clip: false

            ScrollBar.horizontal.policy: ScrollBar.AsNeeded

            Keys.enabled: true
            Keys.forwardTo: body
            Keys.onPressed: (event) =>
            {
                if((event.key === Qt.Key_F) && (event.modifiers & Qt.ControlModifier))
                {
                    control.showFindBar = true

                    if(control.body.selectedText.length)
                    {
                        _findField.text = control.body.selectedText
                    }else
                    {
                        _findField.selectAll()
                    }

                    _findField.forceActiveFocus()
                    event.accepted = true
                }

                if((event.key === Qt.Key_R) && (event.modifiers & Qt.ControlModifier))
                {
                    control.showFindBar = true
                    _replaceButton.checked = true
                    _findField.text = control.body.selectedText
                    _replaceField.forceActiveFocus()
                    event.accepted = true
                }
            }

            Flickable
            {
                clip: false
                interactive: true
                boundsBehavior: Flickable.StopAtBounds
                boundsMovement: Flickable.StopAtBounds

                TextArea.flickable: TextArea
                {
                    id: body
                    text: document.text
                    clip: false

                    placeholderText: i18nd("mauikittexteditor", "Body")
                    textFormat: TextEdit.PlainText
                    tabStopDistance: fontMetrics.averageCharacterWidth * 4
                    renderType: Text.QtRendering
                    antialiasing: true
                    activeFocusOnPress: true
                    focusPolicy: Qt.StrongFocus
                    selectByMouse: true

                    leftPadding: Maui.Style.space.medium
                    rightPadding: Maui.Style.space.medium
                    topPadding: Maui.Style.space.medium
                    bottomPadding: Maui.Style.space.medium

                    background: null
                }
            }

            TapHandler
            {
                acceptedButtons: Qt.RightButton
                onTapped: (eventPoint) => _contextMenu.popup(eventPoint.position.x, eventPoint.position.y)
            }
        }
    }

    FontMetrics
    {
        id: fontMetrics
        font: body.font
    }
}
