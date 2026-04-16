// SPDX-FileCopyrightText: 2020 Carl Schwan <carl@carlschwan.eu>
//
// SPDX-License-Identifier: LGPL-2.1-or-later

#pragma once

#include <QDir>
#include <QLibraryInfo>
#include <QQmlExtensionPlugin>

class TextEditorPlugin : public QQmlExtensionPlugin
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid)
public:
    void registerTypes(const char *uri) override;

private:    
    QUrl componentUrl(const QString &fileName) const;

    QString resolveFileUrl(const QString &filePath) const
    {
#if defined(Q_OS_ANDROID)
        return QStringLiteral("qrc:/qt/qml/org/mauikit/texteditor/") + filePath;
#else
        const QString qmlModulePath = QDir(QLibraryInfo::path(QLibraryInfo::QmlImportsPath)).filePath(QStringLiteral("org/mauikit/texteditor"));
        return QUrl::fromLocalFile(QDir(qmlModulePath).filePath(filePath)).toString();
#endif
    }
};
