project('mauikit-texteditor', 'cpp', version: '4.0.5', meson_version: '>=1.0.0', default_options: ['cpp_std=c++17', 'buildtype=release'])

cpp_compiler = meson.get_compiler('cpp')
if cpp_compiler.get_id() == 'gcc' and cpp_compiler.has_argument('-Wno-sfinae-incomplete')
    add_project_arguments('-Wno-sfinae-incomplete', language: 'cpp')
endif
qt6 = import('qt6')
qt = dependency('qt6', version: '>=6.4', modules: ['Core', 'Quick', 'Qml', 'Core5Compat'])
qt_moc_args = ['-I' + qt.get_variable('includedir')]
kf6_core = declare_dependency(include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KCoreAddons'), dependencies: [cpp_compiler.find_library('KF6CoreAddons')])
kf6_i18n = declare_dependency(include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KI18n'), dependencies: [cpp_compiler.find_library('KF6I18n')])
kf6_syntax = declare_dependency(include_directories: include_directories(get_option('prefix') / 'include' / 'KF6' / 'KSyntaxHighlighting'), dependencies: [cpp_compiler.find_library('KF6SyntaxHighlighting')])
mauikit = dependency('MauiKit4', version: '>=4.0.5')
cpp_args = host_machine.cpu_family() == 'x86_64' ? ['-march=x86-64-v3'] : []
export_header = configure_file(
    input: 'meson-content.in',
    output: 'texteditor_export.h',
    configuration: {'CONTENT': ('#pragma once\n#define TEXTEDITOR_EXPORT __attribute__((visibility("default")))\n')}
)
texteditor_version_header = configure_file(
    input: 'meson-content.in',
    output: 'texteditor_version.h',
    configuration: {'CONTENT': ('''#pragma once
#define TextEditor_VERSION_STRING "4.0.5"
#define GIT_BRANCH "Stable"
#define GIT_COMMIT_HASH "4.0.5"
''')}
)
lib = shared_library('MauiKitTextEditor4', files('src/code/moduleinfo.cpp') + [texteditor_version_header, export_header], dependencies: [qt, kf6_core, kf6_i18n], cpp_args: cpp_args, version: '4.0.5', soversion: '4', install: true)
plugin_sources = qt6.preprocess(moc_extra_arguments: qt_moc_args, moc_headers: ['src/code/texteditor_plugin.h', 'src/code/documenthandler.h', 'src/code/colorschemesmodel.h', 'src/code/linenumbermodel.h'])
plugin = shared_module('MauiKitTextEditor4plugin', ['src/code/texteditor_plugin.cpp', 'src/code/documenthandler.cpp', 'src/code/colorschemesmodel.cpp', 'src/code/linenumbermodel.cpp'] + plugin_sources, link_with: lib, dependencies: [qt, kf6_core, kf6_i18n, kf6_syntax, mauikit], install: true, install_dir: get_option('libdir') / 'qt6/qml/org/mauikit/texteditor')
qml_dir = get_option('libdir') / 'qt6/qml/org/mauikit/texteditor'
install_data(configure_file(
    input: 'meson-content.in',
    output: 'qmldir',
    configuration: {'CONTENT': ('module org.mauikit.texteditor\nplugin MauiKitTextEditor4plugin\n')}
), install_dir: qml_dir)
install_subdir('src/controls.6', install_dir: qml_dir, strip_directory: true)
install_headers(files('src/code/moduleinfo.h') + [export_header], subdir: 'MauiKit4/TextEditor')
pkg = import('pkgconfig')
pkg.generate(lib, name: 'MauiKit Text Editor 4', filebase: 'MauiKitTextEditor4', version: meson.project_version(), description: 'MauiKit text editor library', requires: 'MauiKit4')

cmake_targets = configure_file(
    input: 'meson-content.in',
    output: 'MauiKitTextEditor4Targets.cmake',
    configuration: {'CONTENT': (('''get_filename_component(_MAUIKIT_PREFIX "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)
if(NOT TARGET MauiKitTextEditor4)
  add_library(MauiKitTextEditor4 SHARED IMPORTED)
  set_target_properties(MauiKitTextEditor4 PROPERTIES
    IMPORTED_LOCATION "${_MAUIKIT_PREFIX}/@LIBDIR@/libMauiKitTextEditor4.so.4.0.5"
    INTERFACE_INCLUDE_DIRECTORIES "${_MAUIKIT_PREFIX}/include/MauiKit4/TextEditor")
endif()
if(NOT TARGET MauiKit4::TextEditor)
  add_library(MauiKit4::TextEditor ALIAS MauiKitTextEditor4)
endif()
if(NOT TARGET MauiKit::TextEditor)
  add_library(MauiKit::TextEditor ALIAS MauiKitTextEditor4)
endif()
''')).replace('@LIBDIR@', (get_option('libdir')))}
)
cmake_config = configure_file(
    input: 'meson-content.in',
    output: 'MauiKitTextEditor4Config.cmake',
    configuration: {'CONTENT': ('''include(CMakeFindDependencyMacro)
find_dependency(Qt6 6.4 COMPONENTS Core)
include("${CMAKE_CURRENT_LIST_DIR}/MauiKitTextEditor4Targets.cmake")
set(MauiKitTextEditor4_FOUND TRUE)
''')}
)
cmake_version = configure_file(
    input: 'meson-content.in',
    output: 'MauiKitTextEditor4ConfigVersion.cmake',
    configuration: {'CONTENT': (('''set(PACKAGE_VERSION "@VERSION@")
if(PACKAGE_FIND_VERSION VERSION_LESS_EQUAL PACKAGE_VERSION)
  set(PACKAGE_VERSION_COMPATIBLE TRUE)
endif()
if(PACKAGE_FIND_VERSION VERSION_EQUAL PACKAGE_VERSION)
  set(PACKAGE_VERSION_EXACT TRUE)
endif()
''')).replace('@VERSION@', (meson.project_version()))}
)
install_data([cmake_targets, cmake_config, cmake_version], install_dir: get_option('libdir') / 'cmake' / 'MauiKitTextEditor4')
