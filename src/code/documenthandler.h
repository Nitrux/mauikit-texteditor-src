/****************************************************************************
 * *
 ** Copyright (C) 2017 The Qt Company Ltd.
 ** Contact: https://www.qt.io/licensing/
 **
 ** This file is part of the examples of the Qt Toolkit.
 **
 ** $QT_BEGIN_LICENSE:BSD$
 ** Commercial License Usage
 ** Licensees holding valid commercial Qt licenses may use this file in
 ** accordance with the commercial license agreement provided with the
 ** Software or, alternatively, in accordance with the terms contained in
 ** a written agreement between you and The Qt Company. For licensing terms
 ** and conditions see https://www.qt.io/terms-conditions. For further
 ** information use the contact form at https://www.qt.io/contact-us.
 **
 ** BSD License Usage
 ** Alternatively, you may use this file under the terms of the BSD license
 ** as follows:
 **
 ** "Redistribution and use in source and binary forms, with or without
 ** modification, are permitted provided that the following conditions are
 ** met:
 **   * Redistributions of source code must retain the above copyright
 **     notice, this list of conditions and the following disclaimer.
 **   * Redistributions in binary form must reproduce the above copyright
 **     notice, this list of conditions and the following disclaimer in
 **     the documentation and/or other materials provided with the
 **     distribution.
 **   * Neither the name of The Qt Company Ltd nor the names of its
 **     contributors may be used to endorse or promote products derived
 **     from this software without specific prior written permission.
 **
 **
 ** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 ** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 ** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 ** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 ** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 ** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 ** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 ** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 ** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 ** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 ** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 **
 ** $QT_END_LICENSE$
 **
 ****************************************************************************/

#pragma once

#include <QAbstractListModel>
#include <QDebug>
#include <QFont>
#include <QObject>
#include <QTextCursor>
#include <QThread>
#include <QTimer>
#include <QUrl>
#include <QQuickTextDocument>
#include <QQmlEngine>
#include <QtQmlIntegration/qqmlintegration.h>

class QFileSystemWatcher;
class QTextDocument;

namespace KSyntaxHighlighting
{
class Repository;
class SyntaxHighlighter;
}

/**
 * @brief Pairs an alert action label with the callback it invokes.
 */
struct AlertAction
{
    QString label;
    std::function<void()> action;
};

/**
 * @brief Describes a document warning and the actions available to resolve it.
 */
class DocumentAlert : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString title MEMBER m_title CONSTANT FINAL)
    Q_PROPERTY(QString body MEMBER m_body CONSTANT FINAL)
    Q_PROPERTY(uint level MEMBER m_level CONSTANT FINAL)
    Q_PROPERTY(QStringList actionLabels READ actionLabels CONSTANT FINAL)
    
public:
    enum LEVEL : uint { INFO_LEVEL = 0, WARNING_LEVEL = 1, DANGER_LEVEL = 2 };

    DocumentAlert(const QString &title, const QString &body, const uint &level, const int &id, QObject *parent = nullptr)
        : QObject(parent)
    {
        this->m_title = title;
        this->m_body = body;
        this->m_level = level;
        this->m_id = id;
    }

    /** Associates this alert with its row index in the alerts model. */
    void setIndex(const int &index)
    {
        this->m_index = index;
    }

    /** Replaces the actions presented for this alert. */
    void setActions(QVector<AlertAction> actions)
    {
        this->m_actions = actions;
    }

    /** Returns the stable identifier used to detect duplicate alerts. */
    int getId() const
    {
        return this->m_id;
    }

    /**
     * @brief operator ==
     * @param other
     * @param other2
     * @return
     */
    friend bool operator==(const DocumentAlert &other, const DocumentAlert &other2)
    {
        return other.getId() == other2.getId();
    }

    /** Returns the action labels in invocation order. */
    QStringList actionLabels() const
    {
        return std::accumulate(this->m_actions.constBegin(), this->m_actions.constEnd(), QStringList(), [](QStringList &labels, const AlertAction &action) -> QStringList {
            labels << action.label;
            return labels;
        });
    }

private:
    QString m_title;
    QString m_body;
    uint m_level;
    int m_index = -1;
    int m_id = -1;

    QVector<AlertAction> m_actions;

public Q_SLOTS:
    /** Invokes an action and emits done() for the alert row. */
    void triggerAction(const int &actionIndex, const int &alertIndex)
    {
        qDebug() << "TRIGGERING DOCUMENT ACTION AT INDEX << " << actionIndex << alertIndex;
        this->m_actions.at(actionIndex).action();
        Q_EMIT this->done(alertIndex);
    }

Q_SIGNALS:
    /** Emitted after an action completes, with the alert row to dismiss. */
    void done(int index);
};

/**
 * @brief List model of unresolved alerts associated with a document.
 */
class Alerts : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ROLES : uint { ALERT = Qt::DisplayRole + 1 };

    enum ALERT_TYPES : uint { MISSING, UNSAVED, MODIFIED, SAVE_ERROR };

    explicit Alerts(QObject *parent = nullptr);
    ~Alerts();
    QVariant data(const QModelIndex &index, int role) const override final;
    int rowCount(const QModelIndex &parent = QModelIndex()) const override final;
    QHash<int, QByteArray> roleNames() const override;

    void append(DocumentAlert *alert);

private:
    QVector<DocumentAlert *> m_alerts;
    bool contains(DocumentAlert *const alert);
};

/**
 * @brief Loads a text file asynchronously and emits its contents when ready.
 */
class FileLoader : public QObject
{
    Q_OBJECT

public Q_SLOTS:
    /** Loads the local file at @p url. */
    void loadFile(const QUrl &url);

Q_SIGNALS:
    /** Emitted with the loaded text and its source URL. */
    void fileReady(QString array, QUrl url);
};

/**
 * @brief Manages file I/O, formatting, search, alerts, and syntax highlighting for a QML text document.
 * @note This is not part of any public API, and it is only exposed as part of
 * the text editor controls.
 * 
 */
class DocumentHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    /** The QML text document managed by this handler. */
    Q_PROPERTY(QQuickTextDocument *document READ document WRITE setDocument NOTIFY documentChanged)
    
    /** The current cursor position as a character offset. */
    Q_PROPERTY(int cursorPosition READ cursorPosition WRITE setCursorPosition NOTIFY cursorPositionChanged)
    
    /** The first character offset of the current selection. */
    Q_PROPERTY(int selectionStart READ selectionStart WRITE setSelectionStart NOTIFY selectionStartChanged)
    
    /** The character offset immediately after the current selection. */
    Q_PROPERTY(int selectionEnd READ selectionEnd WRITE setSelectionEnd NOTIFY selectionEndChanged)

    /** The text color at the cursor or across the current selection. */
    Q_PROPERTY(QColor textColor READ textColor WRITE setTextColor NOTIFY textColorChanged)
    
    /** The font family at the cursor or across the current selection. */
    Q_PROPERTY(QString fontFamily READ fontFamily WRITE setFontFamily NOTIFY fontFamilyChanged)
    
    /** The paragraph alignment at the current cursor position. */
    Q_PROPERTY(Qt::Alignment alignment READ alignment WRITE setAlignment NOTIFY alignmentChanged)

    /** Whether text at the cursor or in the current selection is bold. */
    Q_PROPERTY(bool bold READ bold WRITE setBold NOTIFY boldChanged)
    
    /** Whether uppercase capitalization is active at the cursor or selection. */
    Q_PROPERTY(bool uppercase READ uppercase WRITE setUppercase NOTIFY uppercaseChanged)
    
    /** Whether text at the cursor or in the current selection is italic. */
    Q_PROPERTY(bool italic READ italic WRITE setItalic NOTIFY italicChanged)
    
    /** Whether text at the cursor or in the current selection is underlined. */
    Q_PROPERTY(bool underline READ underline WRITE setUnderline NOTIFY underlineChanged)
    
    /** Whether the loaded text was detected as rich text. */
    Q_PROPERTY(bool isRich READ getIsRich NOTIFY isRichChanged)

    /** The number of text blocks in the document. */
    Q_PROPERTY(int lineCount READ lineCount NOTIFY lineCountChanged)
    
    /** The font point size at the cursor or across the current selection. */
    Q_PROPERTY(int fontSize READ fontSize WRITE setFontSize NOTIFY fontSizeChanged)
    
    /** The tab-stop distance in document layout units. */
    Q_PROPERTY(qreal tabSpace READ tabSpace WRITE setTabSpace NOTIFY tabSpaceChanged)
    
    /** The current file name, or untitled.txt when no file is set. */
    Q_PROPERTY(QString fileName READ fileName NOTIFY fileUrlChanged)
    
    /** The suffix of the current file name. */
    Q_PROPERTY(QString fileType READ fileType NOTIFY fileUrlChanged)

    /** Metadata describing the current local file. */
    Q_PROPERTY(QVariantMap fileInfo READ fileInfo NOTIFY fileInfoChanged)
    
    /** The URL loaded by this handler. */
    Q_PROPERTY(QUrl fileUrl READ fileUrl WRITE setFileUrl NOTIFY fileUrlChanged)

    /** The document text being edited. */
    Q_PROPERTY(QString text READ text WRITE setText NOTIFY textChanged)

    /** Whether the file changed on disk after it was loaded. */
    Q_PROPERTY(bool externallyModified READ getExternallyModified NOTIFY externallyModifiedChanged)

    /** Whether the document has unsaved internal changes. */
    Q_PROPERTY(bool modified READ getModified NOTIFY modifiedChanged)

    /** Whether externally modified files are reloaded automatically. */
    Q_PROPERTY(bool autoReload READ getAutoReload WRITE setAutoReload NOTIFY autoReloadChanged)
    
    /** Whether modified documents are saved periodically. */
    Q_PROPERTY(bool autoSave READ autoSave WRITE setAutoSave NOTIFY autoSaveChanged)

    /** The KSyntaxHighlighting definition name applied to the document. */
    Q_PROPERTY(QString formatName READ formatName WRITE setFormatName NOTIFY formatNameChanged)

    /** The zero-based line containing the cursor, or -1 without a document. */
    Q_PROPERTY(int currentLineIndex READ getCurrentLineIndex NOTIFY currentLineIndexChanged)

    /** The model of unresolved file and document alerts. */
    Q_PROPERTY(Alerts *alerts READ getAlerts CONSTANT FINAL)

    /** The editor background used to choose a default highlighting theme. */
    Q_PROPERTY(QColor backgroundColor READ getBackgroundColor WRITE setBackgroundColor NOTIFY backgroundColorChanged)

    /** The KSyntaxHighlighting theme name; empty selects a theme from backgroundColor. */
    Q_PROPERTY(QString theme READ theme WRITE setTheme NOTIFY themeChanged)

    /** Whether syntax highlighting is enabled. */
    Q_PROPERTY(bool enableSyntaxHighlighting READ enableSyntaxHighlighting WRITE setEnableSyntaxHighlighting NOTIFY enableSyntaxHighlightingChanged)    
        
    /** Whether find operations match only complete words. */
    Q_PROPERTY(bool findWholeWords MEMBER m_findWholeWords NOTIFY findWholeWordsChanged)    
    
    /** Whether find operations distinguish letter case. */
    Q_PROPERTY(bool findCaseSensitively MEMBER m_findCaseSensitively NOTIFY findCaseSensitivelyChanged)

public:
    /**
     * @private
     */
    explicit DocumentHandler(QObject *parent = nullptr);
    
    /**
     * @private
     */
    ~DocumentHandler();

    /** Returns the managed QML text document. */
    QQuickTextDocument *document() const;

    /** Sets the QML text document to manage. */
    void setDocument(QQuickTextDocument *document);

    /** Returns the current character-offset cursor position. */
    int cursorPosition() const;

    /** Moves the cursor state to the character offset @p position. */
    void setCursorPosition(int position);

    /** Returns the first character offset of the selection. */
    int selectionStart() const;

    /** Sets the first character offset of the selection. */
    void setSelectionStart(int position);

    /** Returns the character offset immediately after the selection. */
    int selectionEnd() const;

    /** Sets the character offset immediately after the selection. */
    void setSelectionEnd(int position);

    /** Returns the font family at the cursor or selection. */
    QString fontFamily() const;

    /** Applies @p family at the cursor or to the selection. */
    void setFontFamily(const QString &family);

    /** Returns the text color at the cursor or selection. */
    QColor textColor() const;

    /** Applies @p color at the cursor or to the selection. */
    void setTextColor(const QColor &color);

    /** Returns the alignment of the current text block. */
    Qt::Alignment alignment() const;

    /** Sets the alignment of the current text block. */
    void setAlignment(Qt::Alignment alignment);

    /** Returns whether the cursor or selection uses bold text. */
    bool bold() const;

    /** Enables or disables bold formatting at the cursor or selection. */
    void setBold(bool bold);

    /** Returns whether uppercase capitalization is active. */
    bool uppercase() const;

    /** Enables or disables uppercase capitalization. */
    void setUppercase(bool uppercase);

    /** Returns whether the cursor or selection uses italic text. */
    bool italic() const;

    /** Enables or disables italic formatting at the cursor or selection. */
    void setItalic(bool italic);

    /** Returns whether the cursor or selection uses underlined text. */
    bool underline() const;

    /** Enables or disables underline formatting at the cursor or selection. */
    void setUnderline(bool underline);

    /** Returns whether the loaded text was detected as rich text. */
    bool getIsRich() const;

    /** Returns the font point size at the cursor or selection. */
    int fontSize() const;

    /** Applies the font point @p size at the cursor or selection. */
    void setFontSize(int size);

    qreal tabSpace() const;
    void setTabSpace(qreal value);

    /** Returns the current file name, or untitled.txt when unset. */
    QString fileName() const;

    /** Returns the current file-name suffix. */
    QString fileType() const;

    /** Returns the URL associated with the document. */
    QUrl fileUrl() const;

    /** Associates the document with @p url and starts loading it. */
    void setFileUrl(const QUrl &url);

    /** Returns metadata for the current local file. */
    QVariantMap fileInfo() const;

    /** Returns the document text. */
    inline QString text() const
    {
        return m_text;
    }

    /** Replaces the document text. */
    void setText(const QString &text);

    /** Returns whether externally changed files reload automatically. */
    bool getAutoReload() const;

    /** Enables or disables automatic reload after external changes. */
    void setAutoReload(const bool &value);

    /** Returns whether periodic automatic saving is enabled. */
    bool autoSave() const;

    /** Enables or disables periodic automatic saving. */
    void setAutoSave(const bool &value);

    /** Returns whether the document has unsaved internal changes. */
    bool getModified() const;

    /** Returns whether the file has changed on disk. */
    bool getExternallyModified() const;

    /** Updates the externally-modified state. */
    void setExternallyModified(const bool &value);

    /** Returns the active KSyntaxHighlighting definition name. */
    QString formatName() const;

    /** Selects a KSyntaxHighlighting definition by name. */
    void setFormatName(const QString &formatName);

    /** Returns the editor background used for automatic theme selection. */
    QColor getBackgroundColor() const;

    /** Sets the editor background used for automatic theme selection. */
    void setBackgroundColor(const QColor &color);

    /** Returns the document alert model. */
    Alerts *getAlerts() const;

    /** Returns the selected KSyntaxHighlighting theme name. */
    QString theme() const;

    /** Selects a KSyntaxHighlighting theme by name. */
    void setTheme(const QString &theme);

    /** Returns whether syntax highlighting is enabled. */
    bool enableSyntaxHighlighting() const;

    /** Enables or disables syntax highlighting. */
    void setEnableSyntaxHighlighting(const bool &value);
    
    /** Returns whether @p color has dark perceived luminance. */
    static bool isDark(const QColor &color)
    {
        const double darkness = 1 - (0.299 * color.red() + 0.587 * color.green() + 0.114 * color.blue()) / 255;
        return (darkness > 0.5);
    }

private Q_SLOTS:
    /** Loads the document contents from @p url. */
    void load(const QUrl &url);

public Q_SLOTS:

    /** Writes the document to @p url and associates the handler with it. */
    void saveAs(const QUrl &url);

    /** Finds the next or previous occurrence of @p query. */
    void find(const QString &query, const bool &forward = true);

    void replace(const QString &query, const QString &value);
    
    void replaceAll(const QString &query, const QString &value);
    
    bool isFoldable(const int &line) const;
    bool isFolded(const int &line) const;
    void toggleFold(const int &line);

    /** Returns the layout height of the zero-based @p line. */
    int lineHeight(const int &line);
    
    int lineCount();

    /** Returns the zero-based line containing the cursor, or -1. */
    int getCurrentLineIndex();
    
    int goToLine(const int &line);

    /** Returns the available syntax-definition names. */
    static const QStringList getLanguageNameList();

    /** Returns the syntax-definition name inferred from @p fileName. */
    static const QString getLanguageNameFromFileName(const QUrl &fileName);

Q_SIGNALS:
    void documentChanged();
    void fileSaved();

    void cursorPositionChanged();
    void selectionStartChanged();
    void selectionEndChanged();

    void fontFamilyChanged();
    void textColorChanged();
    void alignmentChanged();

    void boldChanged();
    void uppercaseChanged();
    void italicChanged();
    void underlineChanged();
    void isRichChanged();

    void lineCountChanged();
    void fontSizeChanged();
    void tabSpaceChanged();

    void textChanged();
    void fileUrlChanged();
    void fileInfoChanged();

    void loaded(const QUrl &url);
    void error(const QString &message);
    void loadFile(QUrl url);

    void autoReloadChanged();
    void autoSaveChanged();

    void externallyModifiedChanged();

    void backgroundColorChanged();

    void formatNameChanged();

    void modifiedChanged();

    void currentLineIndexChanged();

    void enableSyntaxHighlightingChanged();
    void themeChanged();
    
    void searchFound(int start, int end);
    void findCaseSensitivelyChanged();
    void findWholeWordsChanged();
//     void cursorYPosChanged();

private:
    void reset();
    void setStyle();

    QTextCursor textCursor() const;
    QTextDocument *textDocument() const;
    void mergeFormatOnWordOrSelection(const QTextCharFormat &format);

    QQuickTextDocument *m_document;
    QFileSystemWatcher *m_watcher;

    int m_cursorPosition;
    int m_selectionStart;
    int m_selectionEnd;

    bool isRich = false;

    QFont m_font;
    int m_fontSize = 12;
    qreal m_tabSpace = 8;

    QUrl m_fileUrl;

    QThread m_worker;
    QString m_text;

    bool m_autoReload = false;
    bool m_autoSave = false;

    bool m_externallyModified = false;
    bool m_internallyModified = false;
    
    bool m_findCaseSensitively = false;
    bool m_findWholeWords = false;

    QColor m_backgroundColor;

    static int m_instanceCount;
    QString m_formatName = "None";
    static KSyntaxHighlighting::Repository *m_repository;
    KSyntaxHighlighting::SyntaxHighlighter *m_highlighter;

    bool m_enableSyntaxHighlighting = false;
    QString m_theme;
    
    QString m_searchQuery;
    QString m_replaceText;

    Alerts *m_alerts;
    DocumentAlert *missingAlert();
    DocumentAlert *externallyModifiedAlert();
    DocumentAlert *canNotSaveAlert(const QString &details);

    QTimer m_autoSaveTimer;
    
    void refreshAllBlocks();
};
