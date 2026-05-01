import QtQuick
import QtQuick.Controls

import org.mauikit.controls as Maui
import org.mauikit.texteditor as TE

Maui.Page
{
    id: control

    property alias path: _document.fileUrl
    property alias fileUrl: _document.fileUrl
    property int currentPage: _textArea.cursorPosition
    readonly property alias body: _textArea
    readonly property alias document: _document

    readonly property string title:
    {
        const currentPath = String(fileUrl)

        if (currentPath.length === 0)
            return ""

        var lastSlash = currentPath.lastIndexOf("/")
        var fileName = lastSlash >= 0 ? currentPath.substring(lastSlash + 1) : currentPath
        var lastDot = fileName.lastIndexOf(".")
        return lastDot > 0 ? fileName.substring(0, lastDot) : fileName
    }

    headBar.visible: false

    TE.DocumentHandler
    {
        id: _document
        document: _textArea.textDocument
        enableSyntaxHighlighting: true
    }

    Menu
    {
        id: _contextMenu

        MenuItem
        {
            text: i18n("Copy")
            enabled: _textArea.selectedText.length > 0
            onTriggered: _textArea.copy()
        }

        MenuItem
        {
            text: i18n("Select All")
            onTriggered: _textArea.selectAll()
        }
    }

    ScrollView
    {
        anchors.fill: parent
        clip: true

        TextArea
        {
            id: _textArea
            readOnly: true
            selectByMouse: true
            wrapMode: TextEdit.NoWrap
            textFormat: TextEdit.PlainText
            font.family: "monospace"
            leftPadding: Maui.Style.space.medium
            rightPadding: Maui.Style.space.medium
            topPadding: Maui.Style.space.medium
            bottomPadding: Maui.Style.space.medium
            background: null
            text: _document.text
        }

        TapHandler
        {
            acceptedButtons: Qt.RightButton
            onTapped: (eventPoint) => _contextMenu.popup(eventPoint.position.x, eventPoint.position.y)
        }
    }
}
