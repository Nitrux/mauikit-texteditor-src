import QtQuick
import QtQml
import QtQuick.Controls
import QtQuick.Layouts

import org.mauikit.controls as Maui
import org.mauikit.texteditor as TE

import org.kde.sonnet as Sonnet

/**
 * @since org.mauikit.texteditor 1.0
 * @brief Advanced text editor component
 *
 * A text editor surface for advanced editing workflows with convenient
 * code-editor features.
 * The editor is controlled by the DocumentHandler, which manages file I/O,
 * syntax highlighting styles, and many more text editing properties.
 *
 * @section features Features
 *
 * The CodeEditor control comes with a set of built-in features, such as
 * find and replace, syntax highlighting support, a line number sidebar,
 * I/O capabilities, file document alerts, and syntax correction.
 *
 * @subsection io I/O
 * Opening a local text file is handled by the DocumentHandler via the
 * `fileUrl` property. The document contents will be loaded by the FileLoader
 * and made available to the CodeEditor for drawing.
 *
 * @see DocumentHandler::fileUrl
 *
 * @warning Opening large contents will cause the app to freeze, since it is not optimized to dynamically allocate the contents by chunks and instead all of the content will be rendered at once. A solution with a different backend is being implemented.
 *
 * Once an existing document is opened or created, it will also be watched for any external changes, such as modifications to its contents or its removal, those changes will be notified via the alert bars, exposing the avaliable options.
 * @see DocumentHandler::autoReload
 *
 * @image html alert_bars.png
 *
 * To save any changes made to an existing document or to save a new one manually use the exposed method DocumentHandler::saveAs, which will take as parameter the location where to save the file at, if you mean to save the changes to an already existing file, simply pass the DocumentHandler::fileUrl value.
 * The changes made could be automatically saved every few seconds if the DocumentHandler::autoSave property is enabled.
 *
 * @code
 * ToolButton
 * {
 *    icon.name: "folder-open"
 *    onClicked: _editor.fileUrl = "file:///home/camiloh/nota/CMakeLists.txt"
 * }
 *
 * ...
 *
 * TE.CodeEditor
 * {
 *    id: _editor
 *    anchors.fill: parent
 *    body.wrapMode: Text.NoWrap
 *    document.enableSyntaxHighlighting: true
 * }
 * @endcode
 *
 * @subsection syntax_highlighting Syntax Highlighting
 *
 * To enable the syntax highlighting enable the DocumentHandler::enableSyntaxHighlighting property.
 *
 * @note If the language is not detected automatically or if you desire to change it, use the `showSyntaxHighlightingLanguages` property to toggle the selection combobox to allow the user to select a custom language, and bind it to the DocumentHandler::formatName property.
 *
 * There are different color schemes available, those can be set using the DocumentHandler::theme property. You can also use the ColorSchemesPage control which lists all the available options.
 *
 * @subsection other Others
 *
 * The find & replace bars can be toggled using the `showFindBar` property.
 * @see DocumentHandler::findWholeWords
 * @see DocumentHandler::findCaseSensitively
 *
 * To enable the line number sidebar use the `showLineNumbers` property.
 *
 * Spell checking can be anbled using the `spellcheckEnabled` property. For this Sonnet must be available.
 *
 * @subsection fonts Fonts & Colors
 *
 * For tweaking the font properties and colors use the DocumentHandler::textColor and DocumentHandler::backgroundColor, etc.
 *
 * For more details and properties check the own DocumentHandler properties.
 */
Page
{
    id: control

    padding: 0
    focus: false
    clip: false
    title: document.fileName + (document.modified ? "*" : "")

    /**
     * @brief
     */
    property bool showFindBar: false

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

    function scheduleLinesCounterReload()
    {
        control.logGutterDebug("scheduleLinesCounterReload wrapMode=" + body.wrapMode
                               + " contentWidth=" + body.contentWidth
                               + " contentHeight=" + body.contentHeight)
        body.update()

        if(!_linesCounter.active || !_linesCounter.item)
        {
            return
        }

        _linesCounter.item.scheduleLayoutRefresh()
    }

    function scheduleLinesCounterRebuild()
    {
        control.logGutterDebug("scheduleLinesCounterRebuild wrapMode=" + body.wrapMode
                               + " contentWidth=" + body.contentWidth
                               + " contentHeight=" + body.contentHeight)
        body.update()

        if(!_linesCounter.active || !_linesCounter.item)
        {
            return
        }

        _linesCounter.item.scheduleLayoutRefresh("rebuild")
    }

    function scheduleLinesCounterRebuildDebounced(reason)
    {
        control.logGutterDebug("scheduleLinesCounterRebuildDebounced reason=" + reason
                               + " wrapMode=" + body.wrapMode
                               + " contentWidth=" + body.contentWidth
                               + " contentHeight=" + body.contentHeight)

        if(body.wrapMode === Text.NoWrap)
        {
            control.scheduleLinesCounterReload()
            return
        }

        _linesCounterRebuildDebounceTimer.restart()
    }

    onWidthChanged:
    {
        control.logGutterDebug("editor width changed to " + width)
        if(body.wrapMode === Text.NoWrap)
        {
            control.scheduleLinesCounterReload()
        }else
        {
            control.scheduleLinesCounterRebuildDebounced("width")
        }
    }

    onHeightChanged:
    {
        control.logGutterDebug("editor height changed to " + height)
        if(body.wrapMode === Text.NoWrap)
        {
            control.scheduleLinesCounterReload()
        }else
        {
            control.scheduleLinesCounterRebuildDebounced("height")
        }
    }

    /**
     * @brief Access to the editor text area.
     * @property TextArea CodeEditor::body
     */
    readonly property alias body : body

    /**
     * @brief Alias to access the DocumentHandler
     * @property DocumentHandler CodeEditor::document
     */
    readonly property alias document : document

    /**
     * @brief Alias to the ScrollView
     * @property ScrollView CodeEditor::scrollView
     */
    readonly property alias scrollView: _scrollView

    /**
     * @brief Alias to the contextual menu. This menu is loaded asynchronous.
     * @property Menu CodeEditor::documentMenu
     */
    readonly property alias documentMenu : _documentMenuLoader.item

    /**
     * @brief Alias to the text area text content
     * @property string CodeEditor::text
     */
    property alias text: body.text

    /**
     * @see DocumentHandler::uppercase
     * @property bool CodeEditor::uppercase
     */
    property alias uppercase: document.uppercase

    /**
     * @see DocumentHandler::underline
     * @property bool CodeEditor::underline
     */
    property alias underline: document.underline

    /**
     * @see DocumentHandler::italic
     * @property bool CodeEditor::italic
     */
    property alias italic: document.italic

    /**
     * @see DocumentHandler::bold
     * @property bool CodeEditor::bold
     */
    property alias bold: document.bold

    /**
     * @brief Whether there are modifications to the document that can be redo. Alias to the TextArea::canRedo
     * @property bool CodeEditor::canRedo
     */
    property alias canRedo: body.canRedo

    /**
     * @brief If a file url is provided the DocumentHandler will try to open its contents and display it
     * @see DocumentHandler::fileUrl
     * @property url CodeEditor::fileUrl
     */
    property alias fileUrl : document.fileUrl

    /**
     * @brief If a sidebar listing each line number should be visible.
     * By default this is set to `false`
     */
    property bool showLineNumbers : false

    /**
     * @brief Whether to enable the spell checker.
     * By default this is set to `false`
     */
    property bool spellcheckEnabled: false

    /**
     * @brief Whether to log gutter and editor geometry for debugging.
     */
    property bool gutterDebugEnabled: false

    /**
     * @brief Whether the contextual menu should expose the spelling submenu.
     * Apps that are not focused on prose editing can disable this while still
     * keeping spell checking support available elsewhere.
     */
    property bool showSpellingContextMenu: true
    function logGutterDebug(message)
    {
        if(!control.gutterDebugEnabled)
        {
            return
        }

        console.log("[CodeEditor gutter]", message)
    }

    FontMetrics
    {
        id: fontMetrics
        font: body.font
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
        findCaseSensitively:  _findCaseSensitively.checked
        findWholeWords: _findWholeWords.checked

        onSearchFound: (start, end) =>
                       {
                           body.select(start, end)
                       }
    }

    Loader
    {
        id: spellcheckhighlighterLoader
        property bool activable: control.spellcheckEnabled
        property Sonnet.Settings settings: Sonnet.Settings {}
        active: activable && settings.checkerEnabledByDefault
        onActiveChanged:
        {
            if (active)
            {
                item.active = true;
            }
        }

        sourceComponent: Sonnet.SpellcheckHighlighter
        {
            id: spellcheckhighlighter
            document:  body.textDocument
            cursorPosition: body.cursorPosition
            selectionStart: body.selectionStart
            selectionEnd: body.selectionEnd
            misspelledColor: Maui.Theme.negativeTextColor
            active: spellcheckhighlighterLoader.activable && settings.checkerEnabledByDefault

            onChangeCursorPosition: (start, end) =>
                                    {
                                        body.cursorPosition = start;
                                        body.moveCursorSelection(end, TextEdit.SelectCharacters);
                                    }
        }
    }

    Loader
    {
        id: _documentMenuLoader

        asynchronous: true
        sourceComponent: Maui.ContextualMenu
        {
            id: _menu
            property var spellcheckhighlighter: null
            property var spellcheckhighlighterLoader: null
            readonly property bool spellingMenuVisible: control.showSpellingContextMenu && control.spellcheckEnabled
            property int restoredCursorPosition: 0
            property int restoredSelectionStart
            property int restoredSelectionEnd
            property var suggestions: []
            property bool deselectWhenMenuClosed: true
            property var runOnMenuClose: () => {}
            property bool persistentSelectionSetting

            Component.onCompleted:
            {
                persistentSelectionSetting = body.persistentSelection
            }

            MenuItem
            {
                action: Action
                {
                    icon.name: "edit-copy-symbolic"
                    text: i18n("Copy")
                }

                onTriggered:
                {
                    documentMenu.deselectWhenMenuClosed = false;
                    documentMenu.runOnMenuClose = () => control.body.copy();
                }

                enabled: body.selectedText.length
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
            }

            MenuItem
            {
                action: Action {
                    icon.name: "edit-cut-symbolic"
                    text: i18n("Cut")
                }
                onTriggered:
                {
                    documentMenu.deselectWhenMenuClosed = false;
                    documentMenu.runOnMenuClose = () => control.body.cut();
                }
                enabled: !body.readOnly && body.selectedText.length
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
            }

            MenuItem
            {
                action: Action
                {
                    icon.name: "edit-paste-symbolic"
                    text: i18n("Paste")
                }

                onTriggered:
                {
                    documentMenu.deselectWhenMenuClosed = false;
                    documentMenu.runOnMenuClose = () => control.body.paste();
                }

                enabled: !body.readOnly
            }

            MenuItem
            {
                action: Action
                {
                    icon.name: "edit-select-all-symbolic"
                    text: i18n("Select All")
                }

                onTriggered:
                {
                    documentMenu.deselectWhenMenuClosed = false
                    documentMenu.runOnMenuClose = () => control.body.selectAll();
                }
            }
            
            MenuSeparator
            {
                visible: _searchSelectedItem.visible
                      || _emailItem.visible
                      || _phoneItem.visible
                      || _openLinkItem.visible
                      || _deleteItem.visible
                      || documentMenu.spellingMenuVisible
                height: visible ? implicitHeight : -_menu.spacing
            }

            MenuItem
            {
                id: _searchSelectedItem
                text: i18nd("mauikittexteditor","Search Selected Text on Google...")
                onTriggered: Qt.openUrlExternally("https://www.google.com/search?q="+body.selectedText)
                enabled: body.selectedText.length
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
            }
            
            MenuItem
            {
                id: _emailItem
                enabled: control.body.selectedText.length > 0 && Maui.Handy.isEmail(control.body.selectedText)
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
                text: i18n("Email")
                icon.name: "mail-sent"
                onTriggered: Qt.openUrlExternally("mailto:"+control.body.selectedText)
            }
            
            MenuItem
            {
                id: _phoneItem
                enabled: control.body.selectedText.length > 0 && Maui.Handy.isPhoneNumber(control.body.selectedText)
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
                text: i18n("Save as Contact")
                icon.name: "contact-new-symbolic"
                onTriggered: Qt.openUrlExternally("tel:"+control.body.selectedText)
            }
            
            MenuItem
            {
                id: _openLinkItem
                enabled: control.body.selectedText.length > 0 && Maui.Handy.isWebLink(control.body.selectedText)
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
                text: i18n("Open Link")
                icon.name: "website-symbolic"
                onTriggered: Qt.openUrlExternally(control.body.selectedText)
            }

            MenuSeparator
            {
                visible: (_searchSelectedItem.visible
                       || _emailItem.visible
                       || _phoneItem.visible
                       || _openLinkItem.visible)
                      && (_deleteItem.visible || documentMenu.spellingMenuVisible)
                height: visible ? implicitHeight : -_menu.spacing
            }
            
            MenuItem
            {
                id: _deleteItem
                enabled: !control.body.readOnly && control.body.selectedText
                visible: enabled
                height: visible ? implicitHeight : -_menu.spacing
                action: Action
                {
                    icon.name: "edit-delete-symbolic"
                    text: i18n("Delete")
                }
                
                onTriggered:
                {
                    documentMenu.deselectWhenMenuClosed = false;
                    documentMenu.runOnMenuClose = () => control.body.remove(control.body.selectionStart, control.body.selectionEnd);
                }
            }

            MenuSeparator
            {
                visible: _deleteItem.visible && documentMenu.spellingMenuVisible
                height: visible ? implicitHeight : -_menu.spacing
            }

            Loader
            {
                id: _spellingMenuLoader
                active: documentMenu.spellingMenuVisible
                asynchronous: false

                sourceComponent: Menu
                {
                    id: _spellingMenu
                    title: i18nd("mauikittexteditor","Spelling")

                    Instantiator
                    {
                        id: _suggestions
                        active: !control.body.readOnly && documentMenu.spellcheckhighlighter !== null && documentMenu.spellcheckhighlighter.active && documentMenu.spellcheckhighlighter.wordIsMisspelled
                        model: documentMenu.suggestions
                        delegate: MenuItem
                        {
                            text: modelData
                            onClicked:
                            {
                                documentMenu.deselectWhenMenuClosed = false;
                                documentMenu.runOnMenuClose = () => documentMenu.spellcheckhighlighter.replaceWord(modelData);
                            }
                        }

                        onObjectAdded: (index, object) =>
                                       {
                                           _spellingMenu.insertItem(0, object)
                                       }

                        onObjectRemoved: (index, object) =>
                                         {
                                             _spellingMenu.removeItem(_spellingMenu.itemAt(0))
                                         }
                    }

                    MenuSeparator
                    {
                        enabled: !control.body.readOnly && ((documentMenu.spellcheckhighlighter !== null && documentMenu.spellcheckhighlighter.active && documentMenu.spellcheckhighlighter.wordIsMisspelled) || (documentMenu.spellcheckhighlighterLoader && documentMenu.spellcheckhighlighterLoader.activable))
                    }

                    MenuItem
                    {
                        enabled: !control.body.readOnly && documentMenu.spellcheckhighlighter !== null && documentMenu.spellcheckhighlighter.active && documentMenu.spellcheckhighlighter.wordIsMisspelled && documentMenu.suggestions.length === 0
                        action: Action
                        {
                            text: documentMenu.spellcheckhighlighter ? i18n("No suggestions for \"%1\"").arg(documentMenu.spellcheckhighlighter.wordUnderMouse) : ''
                            enabled: false
                        }
                    }

                    MenuItem
                    {
                        enabled: !control.body.readOnly && documentMenu.spellcheckhighlighter !== null && documentMenu.spellcheckhighlighter.active && documentMenu.spellcheckhighlighter.wordIsMisspelled
                        action: Action
                        {
                            text: documentMenu.spellcheckhighlighter ? i18n("Add \"%1\" to dictionary").arg(documentMenu.spellcheckhighlighter.wordUnderMouse) : ''
                            onTriggered:
                            {
                                documentMenu.deselectWhenMenuClosed = false;
                                documentMenu.runOnMenuClose = () => spellcheckhighlighter.addWordToDictionary(documentMenu.spellcheckhighlighter.wordUnderMouse);
                            }
                        }
                    }

                    MenuItem
                    {
                        enabled: !control.body.readOnly && documentMenu.spellcheckhighlighter !== null && documentMenu.spellcheckhighlighter.active && documentMenu.spellcheckhighlighter.wordIsMisspelled
                        action: Action
                        {
                            text: i18n("Ignore")
                            onTriggered:
                            {
                                documentMenu.deselectWhenMenuClosed = false;
                                documentMenu.runOnMenuClose = () => documentMenu.spellcheckhighlighter.ignoreWord(documentMenu.spellcheckhighlighter.wordUnderMouse);
                            }
                        }
                    }

                    MenuItem
                    {
                        enabled: !control.body.readOnly && documentMenu.spellcheckhighlighterLoader && documentMenu.spellcheckhighlighterLoader.activable
                        checkable: true
                        checked: documentMenu.spellcheckhighlighter ? documentMenu.spellcheckhighlighter.active : false
                        text: i18n("Enable Spellchecker")
                        onCheckedChanged:
                        {
                            spellcheckhighlighterLoader.active = checked;
                            documentMenu.spellcheckhighlighter = documentMenu.spellcheckhighlighterLoader.item;
                        }
                    }
                }
            }

            function targetClick(spellcheckhighlighter, mousePosition)
            {
                control.body.persistentSelection = true; // persist selection when menu is opened
                documentMenu.spellcheckhighlighterLoader = spellcheckhighlighter;
                if (spellcheckhighlighter && spellcheckhighlighter.active) {
                    documentMenu.spellcheckhighlighter = spellcheckhighlighter.item;
                    documentMenu.suggestions = mousePosition ? spellcheckhighlighter.item.suggestions(mousePosition) : [];
                } else {
                    documentMenu.spellcheckhighlighter = null;
                    documentMenu.suggestions = [];
                }

                storeCursorAndSelection();
                documentMenu.show()
            }

            function storeCursorAndSelection()
            {
                documentMenu.restoredCursorPosition = control.body.cursorPosition;
                documentMenu.restoredSelectionStart = control.body.selectionStart;
                documentMenu.restoredSelectionEnd = control.body.selectionEnd;
            }

            onOpened:
            {
                runOnMenuClose = () => {};
            }

            onClosed:
            {
                // restore text field's original persistent selection setting
                body.persistentSelection = documentMenu.persistentSelectionSetting
                // deselect text field text if menu is closed not because of a right click on the text field
                if (documentMenu.deselectWhenMenuClosed)
                {
                    body.deselect();
                }
                documentMenu.deselectWhenMenuClosed = true;

                // restore cursor position
                body.forceActiveFocus();
                body.cursorPosition = documentMenu.restoredCursorPosition;
                body.select(documentMenu.restoredSelectionStart, documentMenu.restoredSelectionEnd);

                // run action, and free memory
                runOnMenuClose();
                runOnMenuClose = () => {};
            }
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
                placeholderText: i18nd("mauikittexteditor","Find")

                onAccepted:
                {
                    document.find(text)
                }

                actions:[

                    Action
                    {
                        enabled: _findField.text.length
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
                placeholderText: i18nd("mauikittexteditor","Replace")
                icon.source: "edit-find-replace"
                actions: Action
                {
                    text: i18nd("mauikittexteditor","Replace")
                    enabled: _replaceField.text.length
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
                checked: false

                ToolTip.delay: 1000
                ToolTip.timeout: 5000
                ToolTip.visible: hovered
                ToolTip.text: i18nd("mauikittexteditor", "Replace")
            }

            Button
            {
                visible: _replaceButton.checked
                enabled: !body.readOnly && _replaceField.text.length
                text: i18nd("mauikittexteditor","Replace All")
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
                property var alert : model.alert
                readonly property int index_ : index
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
                        id: _alertAction
                        property int index_ : index
                        text: modelData
                        onClicked: alert.triggerAction(_alertAction.index_, _alertBar.index_)

                        Maui.Theme.backgroundColor: Qt.lighter(_alertBar.Maui.Theme.backgroundColor, 1.2)
                        Maui.Theme.hoverColor: Qt.lighter(_alertBar.Maui.Theme.backgroundColor, 1)
                        Maui.Theme.textColor: Qt.darker(Maui.Theme.backgroundColor)
                    }
                }
            }
        }
    }

    Component
    {
        id: _linesCounterComponent

        Rectangle
        {
            Maui.Theme.inherit: true
            anchors.fill: parent
            anchors.topMargin: body.topPadding + body.textMargin

            color: document.backgroundColor

            function dumpGeometry(reason)
            {
                if(!control.gutterDebugEnabled)
                {
                    return
                }

                const samples = []
                const maxSamples = Math.min(5, document.lineCount)

                for(let i = 0; i < maxSamples; ++i)
                {
                    const item = _linesCounterRepeater.itemAt(i)
                    samples.push("#" + (i + 1)
                                 + ":docH=" + document.lineHeight(i)
                                 + ",itemH=" + (item ? item.height : "na")
                                 + ",visual=" + (item ? item.visualLineCount : "na"))
                }

                control.logGutterDebug(reason
                                       + " wrapMode=" + body.wrapMode
                                       + " flickY=" + _flickable.contentY
                                       + " gutterOffsetY=" + (-_linesCounterContent.y)
                                       + " viewport=" + _flickable.width + "x" + _flickable.height
                                       + " content=" + body.contentWidth + "x" + body.contentHeight
                                       + " gutterHeight=" + _linesCounterContent.height
                                       + " topPadding=" + body.topPadding
                                       + " textMargin=" + body.textMargin
                                       + " lineSpacing=" + Math.ceil(fontMetrics.lineSpacing)
                                       + " lineCount=" + document.lineCount
                                       + " samples=" + samples.join("; "))
            }

            function scheduleLayoutRefresh(reason)
            {
                dumpGeometry("scheduleLayoutRefresh(" + reason + ")")
                dumpGeometry("before forceLayout")
                _linesCounterColumn.forceLayout()
                dumpGeometry("after forceLayout")
            }

            // body.contentHeight / contentWidth are QBindable in Qt 6: they do NOT
            // emit signals, so Connections cannot observe them. QML property bindings
            // here ARE notified by the QBindable mechanism.
            //
            // contentHeight covers: typing that adds/removes lines, startup layout.
            // contentWidth covers: the NoWrap→WordWrap toggle at runtime — observed
            // to not change contentHeight but must change contentWidth (NoWrap
            // contentWidth = longest-line width; WordWrap contentWidth = viewport width).
            readonly property int  _bodyContentHeight: body.contentHeight
            readonly property real _bodyContentWidth:  body.contentWidth

            on_BodyContentHeightChanged:
            {
                if(body.wrapMode === Text.NoWrap)
                {
                    scheduleLayoutRefresh("body.contentHeight")
                }else
                {
                    control.scheduleLinesCounterRebuildDebounced("body.contentHeight")
                }
            }

            on_BodyContentWidthChanged:
            {
                if(body.wrapMode === Text.NoWrap)
                {
                    scheduleLayoutRefresh("body.contentWidth")
                }else
                {
                    control.scheduleLinesCounterRebuildDebounced("body.contentWidth")
                }
            }

            Item
            {
                id: _linesCounterViewport
                anchors.fill: parent
                clip: true

                Item
                {
                    id: _linesCounterContent
                    width: parent.width
                    height: _linesCounterColumn.implicitHeight
                    y: -_flickable.contentY

                    onYChanged:
                    {
                        dumpGeometry("gutter offset changed")
                    }

                    Column
                    {
                        id: _linesCounterColumn
                        width: parent.width
                        spacing: 0

                        Repeater
                        {
                            id: _linesCounterRepeater
                            model: body.text !== "" ? document.lineCount : 0

                            delegate: Item
                            {
                                id: _delegate

                                readonly property int line : index
                                readonly property int visualLineCount:
                                {
                                    let _h = body.contentHeight
                                    let _w = body.contentWidth
                                    const rawH = document.lineHeight(line)
                                    const lineSpacing = Math.ceil(fontMetrics.lineSpacing)
                                    return body.wrapMode === Text.NoWrap ? 1 : Math.max(1, Math.ceil(rawH / lineSpacing))
                                }
                                readonly property bool isCurrentItem : document.currentLineIndex === index

                                width: _linesCounterColumn.width
                                height:
                                {
                                    let _h = body.contentHeight
                                    let _w = body.contentWidth
                                    return Math.max(Math.ceil(fontMetrics.lineSpacing), document.lineHeight(line))
                                }

                                Column
                                {
                                    anchors.fill: parent
                                    spacing: 0

                                    Repeater
                                    {
                                        model: _delegate.visualLineCount

                                        delegate: Item
                                        {
                                            required property int index

                                            readonly property real gutterTrackWidth:
                                                Math.max(
                                                    fontMetrics.averageCharacterWidth * (Math.floor(Math.log10(body.lineCount)) + 1),
                                                    fontMetrics.averageCharacterWidth * 2
                                                )

                                            width: parent.width
                                            height: _delegate.height / _delegate.visualLineCount

                                            Item
                                            {
                                                id: _gutterTrack
                                                anchors.top: parent.top
                                                anchors.bottom: parent.bottom
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                width: parent.gutterTrackWidth
                                            }

                                            Label
                                            {
                                                anchors.fill: _gutterTrack
                                                visible: index === 0
                                                opacity: _delegate.isCurrentItem ? 1 : 0.7
                                                color: control.body.color
                                                font.family: body.font.family
                                                font.pointSize: body.font.pointSize
                                                font.weight: body.font.weight
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignTop
                                                text: _delegate.line + 1
                                            }

                                            Item
                                            {
                                                anchors.fill: _gutterTrack
                                                visible: body.wrapMode !== Text.NoWrap && index > 0
                                                opacity: _delegate.isCurrentItem ? 1 : 0.7

                                                Rectangle
                                                {
                                                    color: control.body.color
                                                    radius: width * 0.5
                                                    width: Math.max(1, parent.width * 0.08)
                                                    height: Math.max(1, parent.height * 0.38)
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    anchors.top: parent.top
                                                    anchors.topMargin: parent.height * 0.18
                                                }

                                                Rectangle
                                                {
                                                    color: control.body.color
                                                    radius: height * 0.5
                                                    width: Math.max(1, parent.width * 0.24)
                                                    height: Math.max(1, parent.height * 0.08)
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    x: parent.width * 0.5
                                                }

                                                Rectangle
                                                {
                                                    color: control.body.color
                                                    width: Math.max(2, parent.width * 0.12)
                                                    height: width
                                                    rotation: 45
                                                    x: parent.width * 0.74
                                                    y: (parent.height - height) * 0.5
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }

    contentItem: Item
    {
        RowLayout
        {
            anchors.fill: parent
            clip: false

            Loader
            {
                id: _linesCounter
                asynchronous: true
                active: control.showLineNumbers && !document.isRich && body.lineCount > 1
                onLoaded:
                {
                    control.logGutterDebug("linesCounter loaded")
                    control.scheduleLinesCounterReload()
                }

                Layout.fillHeight: true
                Layout.preferredWidth: active ? fontMetrics.averageCharacterWidth
                                                * Math.max(2, Math.floor(Math.log10(body.lineCount)) + 1) + 10 : 0


                sourceComponent: _linesCounterComponent
            }

            Timer
            {
                id: _linesCounterRebuildDebounceTimer
                interval: 80
                repeat: false
                onTriggered: control.scheduleLinesCounterRebuild()
            }

            Connections
            {
                target: body
                function onWrapModeChanged()
                {
                    control.logGutterDebug("body.wrapMode changed to " + body.wrapMode
                                           + " contentWidth=" + body.contentWidth
                                           + " contentHeight=" + body.contentHeight)
                    control.scheduleLinesCounterRebuildDebounced("wrapMode")
                }
            }

            Connections
            {
                target: _flickable
                function onContentYChanged()
                {
                    control.logGutterDebug("flickable contentY changed to " + _flickable.contentY)
                }
            }

            Connections
            {
                target: body
                function onContentWidthChanged()
                {
                    control.logGutterDebug("body contentWidth changed to " + body.contentWidth)
                }

                function onContentHeightChanged()
                {
                    control.logGutterDebug("body contentHeight changed to " + body.contentHeight)
                }
            }

            ScrollView
            {
                id: _scrollView

                Layout.fillHeight: true
                Layout.fillWidth: true

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
                                            _findField.text =  control.body.selectedText
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
                    id: _flickable
                    clip: false

                    interactive: true
                    boundsBehavior : Flickable.StopAtBounds
                    boundsMovement : Flickable.StopAtBounds

                    TextArea.flickable: TextArea
                    {
                        id: body
                        Maui.Theme.inherit: true
                        text: document.text
                        clip: false

                        placeholderText: i18nd("mauikittexteditor","Body")

                        textFormat: TextEdit.PlainText

                        tabStopDistance: fontMetrics.averageCharacterWidth * 4
                        renderType: Text.QtRendering
                        antialiasing: true
                        activeFocusOnPress: true
                        focusPolicy: Qt.StrongFocus

                        Keys.onReturnPressed: (event) =>
                                              {
                                                  body.insert(body.cursorPosition, "\n")
                                                  if(Maui.Handy.isAndroid)//workaround for Android, since pressing return/enter will close the keyboard after inserting the break
                                                  /*The fix to this workaround has been introduced into  Qt 6.8
                                                    see: https://doc.qt.io/qt-6/qml-qtquick-virtualkeyboard-settings-virtualkeyboardsettings.html#closeOnReturn-prop
                                                    */
                                                  {
                                                      Qt.inputMethod.show();
                                                      event.accepted = true
                                                  }
                                              }

                        Keys.onPressed: (event) =>
                                        {
                                            if(event.key === Qt.Key_PageUp)
                                            {
                                                _flickable.flick(0,  60*Math.sqrt(_flickable.height))
                                                event.accepted = true
                                            }

                                            if(event.key === Qt.Key_PageDown)
                                            {
                                                _flickable.flick(0, -60*Math.sqrt(_flickable.height))
                                                event.accepted = true
                                            }                                    // TODO: Move cursor
                                        }

                        onPressAndHold: (event) =>
                                        {
                                            if(Maui.Handy.isAndroid)
                                            {
                                                return
                                            }

                                            if(Maui.Handy.isMobile || Maui.Handy.isTouch)
                                            {
                                                documentMenu.targetClick(spellcheckhighlighterLoader, body.positionAt(event.x, event.y))
                                                event.accepted = true
                                                return
                                            }
                                            event.accepted = false
                                        }

                        onPressed: (event) =>
                                   {
                                       if(Maui.Handy.isMobile)
                                       {
                                           return
                                       }

                                       if(event.button === Qt.RightButton)
                                       {
                                           documentMenu.targetClick(spellcheckhighlighterLoader, body.positionAt(event.x, event.y))
                                           event.accepted = true
                                       }
                                   }
                    }
                }
            }
        }

        Loader
        {
            active: Maui.Handy.isTouch
            asynchronous: true

            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.margins: Maui.Style.space.big

            sourceComponent: Maui.FloatingButton
            {
                icon.name: "edit-menu"
                onClicked: documentMenu.targetClick(spellcheckhighlighterLoader, body.cursorPosition)
            }
        }
    }

    /**
     * @brief Force to focus the text area for input
     */
    function forceActiveFocus()
    {
        body.forceActiveFocus()
    }

    /**
     * @brief Position the view and cursor at the given line number
     * @param line the line number
     */
    function goToLine(line)
    {
        if(line>0 && line <= body.lineCount)
        {
            body.cursorPosition = document.goToLine(line-1)
            body.forceActiveFocus()
        }
    }
}
