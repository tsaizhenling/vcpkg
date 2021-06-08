set(QT_IS_LATEST OFF)

## All above goes into the qt_port_hashes in the future
include("${CMAKE_CURRENT_LIST_DIR}/cmake/qt_install_submodule.cmake")

set(${PORT}_PATCHES 
        jpeg.patch
        harfbuzz.patch
        config_install.patch 
        allow_outside_prefix.patch 
        buildcmake.patch
        dont_force_cmakecache.patch
        fix_find_dep.patch
        )

if(NOT VCPKG_USE_HEAD_VERSION AND NOT QT_IS_LATEST)
    list(APPEND ${PORT}_PATCHES
                )
endif()

if(VCPKG_TARGET_IS_WINDOWS AND NOT "doubleconversion" IN_LIST FEATURES)
    message(FATAL_ERROR "${PORT} requires feature doubleconversion on windows!" )
endif()

# Features can be found via searching for qt_feature in all configure.cmake files in the source: 
# The files also contain information about the Platform for which it is searched
# Always use FEATURE_<feature> in vcpkg_configure_cmake
# (using QT_FEATURE_X overrides Qts condition check for the feature.)
# Theoretically there is a feature for every widget to enable/disable it but that is way to much for vcpkg

set(input_vars doubleconversion freetype harfbuzz libb2 jpeg libmd4c png sql-sqlite)
set(INPUT_OPTIONS)
foreach(_input IN LISTS input_vars)
    if(_input MATCHES "(png|jpeg)" )
        list(APPEND INPUT_OPTIONS -DINPUT_lib${_input}:STRING=)
    elseif(_input MATCHES "(sql-sqlite)")
        list(APPEND INPUT_OPTIONS -DINPUT_sqlite:STRING=) # Not yet used be the cmake build
    else()
        list(APPEND INPUT_OPTIONS -DINPUT_${_input}:STRING=)
    endif()
    if("${_input}" IN_LIST FEATURES)
        string(APPEND INPUT_OPTIONS system)
    elseif(_input STREQUAL "libb2" AND NOT VCPKG_TARGET_IS_WINDOWS)
        string(APPEND INPUT_OPTIONS system)
    elseif(_input STREQUAL "libmd4c")
        string(APPEND INPUT_OPTIONS qt) # libmd4c is not yet in VCPKG (but required by qtdeclarative)
    else()
        string(APPEND INPUT_OPTIONS no)
    endif()
endforeach()

# General features:
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
FEATURES
    "appstore-compliant"  FEATURE_appstore-compliant
    "zstd"                FEATURE_zstd
    "framework"           FEATURE_framework
    "concurrent"          FEATURE_concurrent
    "dbus"                FEATURE_dbus
    "gui"                 FEATURE_gui
    "network"             FEATURE_network
    "sql"                 FEATURE_sql
    "widgets"             FEATURE_widgets
    #"xml"                 FEATURE_xml  # Required to build moc
    "testlib"             FEATURE_testlib
INVERTED_FEATURES
    "zstd"              CMAKE_DISABLE_FIND_PACKAGE_ZSTD
    "dbus"              CMAKE_DISABLE_FIND_PACKAGE_WrapDBus1
    )

list(APPEND FEATURE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Libudev:BOOL=ON)
list(APPEND FEATURE_OPTIONS -DFEATURE_xml:BOOL=ON)

# Corelib features:
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_CORE_OPTIONS
FEATURES
    "doubleconversion"    FEATURE_doubleconversion
    "glib"                FEATURE_glib
    "icu"                 FEATURE_icu
    "pcre2"               FEATURE_pcre2
INVERTED_FEATURES
    #"doubleconversion"      CMAKE_DISABLE_FIND_PACKAGE_WrapDoubleConversion # Required
    "icu"                   CMAKE_DISABLE_FIND_PACKAGE_ICU
    #"pcre2"                 CMAKE_DISABLE_FIND_PACKAGE_WrapSystemPCRE2 # Bug in qt cannot be deactivated
    "glib"                 CMAKE_DISABLE_FIND_PACKAGE_GLIB2
    )

#list(APPEND FEATURE_CORE_OPTIONS -DFEATURE_doubleconversion:BOOL=ON)
list(APPEND FEATURE_CORE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_LTTngUST:BOOL=ON)
list(APPEND FEATURE_CORE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_PPS:BOOL=ON)
list(APPEND FEATURE_CORE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Slog2:BOOL=ON)
list(APPEND FEATURE_CORE_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Libsystemd:BOOL=ON)


# Network features:
 vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_NET_OPTIONS
 FEATURES
    "openssl"             FEATURE_openssl
    "brotli"              FEATURE_brotli
 INVERTED_FEATURES
    "brotli"              CMAKE_DISABLE_FIND_PACKAGE_WrapBrotli
    "openssl"             CMAKE_DISABLE_FIND_PACKAGE_WrapOpenSSL
    )

if("openssl" IN_LIST FEATURES)
    list(APPEND FEATURE_NET_OPTIONS -DINPUT_openssl=linked)
else()
    list(APPEND FEATURE_NET_OPTIONS -DINPUT_openssl=no)
endif()

list(APPEND FEATURE_NET_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Libproxy:BOOL=ON)
list(APPEND FEATURE_NET_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_GSSAPI:BOOL=ON)

# Gui features:
vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_GUI_OPTIONS
    FEATURES
    "freetype"            FEATURE_freetype # required on windows
    "harfbuzz"            FEATURE_harfbuzz
    "fontconfig"          FEATURE_fontconfig # NOT WINDOWS
    "jpeg"                FEATURE_jpeg
    "png"                 FEATURE_png
    #"opengl"              INPUT_opengl=something
    INVERTED_FEATURES
    "vulkan"              CMAKE_DISABLE_FIND_PACKAGE_Vulkan
    "egl"                 CMAKE_DISABLE_FIND_PACKAGE_EGL
    "fontconfig"          CMAKE_DISABLE_FIND_PACKAGE_Fontconfig
    #"freetype"            CMAKE_DISABLE_FIND_PACKAGE_WrapSystemFreetype # Bug in qt cannot be deactivated
    "harfbuzz"            CMAKE_DISABLE_FIND_PACKAGE_WrapSystemHarfbuzz
    "jpeg"                CMAKE_DISABLE_FIND_PACKAGE_JPEG
    "png"                 CMAKE_DISABLE_FIND_PACKAGE_PNG
    "xlib"                CMAKE_DISABLE_FIND_PACKAGE_X11
    "xkb"                 CMAKE_DISABLE_FIND_PACKAGE_XKB
    "xcb"                 CMAKE_DISABLE_FIND_PACKAGE_XCB
    "xcb-xlib"            CMAKE_DISABLE_FIND_PACKAGE_X11_XCB
    "xkbcommon-x11"       CMAKE_DISABLE_FIND_PACKAGE_XKB_COMMON_X11
    "xrender"             CMAKE_DISABLE_FIND_PACKAGE_XRender
    # There are more X features but I am unsure how to safely disable them! Most of them seem to be found automaticall with find_package(X11)
     )

if("xcb" IN_LIST FEATURES)
    list(APPEND FEATURE_GUI_OPTIONS -DINPUT_xcb=yes)
else()
    list(APPEND FEATURE_GUI_OPTIONS -DINPUT_xcb=no)
endif()
if("xkb" IN_LIST FEATURES)
    list(APPEND FEATURE_GUI_OPTIONS -DINPUT_xkbcommon=yes)
else()
    list(APPEND FEATURE_GUI_OPTIONS -DINPUT_xkbcommon=no)
endif()
list(APPEND FEATURE_GUI_OPTIONS )

list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_ATSPI2:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_DirectFB:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Libdrm:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_gbm:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Libinput:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Mtdev:BOOL=ON)
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_GLESv2:BOOL=ON) # only used if INPUT_opengl is correctly set
list(APPEND FEATURE_GUI_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_Tslib:BOOL=ON)
# sql-drivers features:

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_SQLDRIVERS_OPTIONS
    FEATURES
    "sql-sqlite"          FEATURE_system_sqlite
    INVERTED_FEATURES
    "sql-psql"            CMAKE_DISABLE_FIND_PACKAGE_PostgreSQL
    "sql-sqlite"          CMAKE_DISABLE_FIND_PACKAGE_SQLite3
    # "sql-db2"             FEATURE_sql-db2
    # "sql-ibase"           FEATURE_sql-ibase
    # "sql-mysql"           FEATURE_sql-mysql
    # "sql-oci"             FEATURE_sql-oci
    # "sql-odbc"            FEATURE_sql-odbc
    )

set(DB_LIST DB2 MySQL Oracle ODBC)
foreach(_db IN LISTS DB_LIST)
    list(APPEND FEATURE_SQLDRIVERS_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_${_db}:BOOL=ON)
endforeach()

# printsupport features:
# vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_PRINTSUPPORT_OPTIONS
    # )
list(APPEND FEATURE_PRINTSUPPORT_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_CUPS:BOOL=ON)

# widgets features:
# vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_WIDGETS_OPTIONS
    # "gtk3"             FEATURE_gtk3
    # There are a lot of additional features here to deactivate parts of widgets. 
    # )
list(APPEND FEATURE_WIDGETS_OPTIONS -DCMAKE_DISABLE_FIND_PACKAGE_GTK3:BOOL=ON)

set(TOOL_NAMES 
        androiddeployqt 
        androidtestrunner 
        cmake_automoc_parser 
        moc 
        qdbuscpp2xml 
        qdbusxml2cpp 
        qlalr 
        qmake 
        qmake6 
        qvkgen 
        rcc 
        tracegen 
        uic
    )

qt_install_submodule(PATCHES    ${${PORT}_PATCHES}
                     TOOL_NAMES ${TOOL_NAMES}
                     CONFIGURE_OPTIONS
                        #--trace-expand
                        ${FEATURE_OPTIONS}
                        ${FEATURE_CORE_OPTIONS}
                        ${FEATURE_NET_OPTIONS}
                        ${FEATURE_GUI_OPTIONS}
                        ${FEATURE_SQLDRIVERS_OPTIONS}
                        ${FEATURE_PRINTSUPPORT_OPTIONS}
                        ${FEATURE_WIDGETS_OPTIONS}
                        ${INPUT_OPTIONS}
                        -DQT_USE_BUNDLED_BundledFreetype:BOOL=FALSE
                        -DQT_USE_BUNDLED_BundledHarfbuzz:BOOL=FALSE
                        -DQT_USE_BUNDLED_BundledLibpng:BOOL=FALSE
                        -DQT_USE_BUNDLED_BundledPcre2:BOOL=FALSE
                        -DINPUT_bundled_xcb_xinput:STRING=no
                        -DFEATURE_force_debug_info:BOOL=ON
                        -DFEATURE_relocatable:BOOL=ON
                     CONFIGURE_OPTIONS_RELEASE
                     CONFIGURE_OPTIONS_DEBUG
                        -DQT_NO_MAKE_TOOLS:BOOL=ON
                        -DFEATURE_debug:BOOL=ON
                    )

# Install CMake helper scripts
if(QT_IS_LATEST)
    set(port_details "${CMAKE_CURRENT_LIST_DIR}/cmake/qt_port_details-latest.cmake") 
else()
    set(port_details "${CMAKE_CURRENT_LIST_DIR}/cmake/qt_port_details.cmake") 
endif()
file(INSTALL
    "${port_details}"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME
        "qt_port_details.cmake"
    )
file(COPY
    "${CMAKE_CURRENT_LIST_DIR}/cmake/qt_install_copyright.cmake"
    "${CMAKE_CURRENT_LIST_DIR}/cmake/qt_install_submodule.cmake"
    DESTINATION
        "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    )

qt_stop_on_update()

set(script_files qt-cmake qt-cmake-private qt-cmake-standalone-test qt-configure-module qt-internal-configure-tests)
if(VCPKG_TARGET_IS_WINDOWS)
    set(script_suffix .bat)
else()
    set(script_suffix)
endif()
set(other_files 
        qt-cmake-private-install.cmake 
        syncqt.pl
        android_cmakelist_patcher.sh
        android_emulator_launcher.sh
        ensure_pro_file.cmake
        )
foreach(_config debug release)
    if(_config MATCHES "debug")
        set(path_suffix debug/)
    else()
        set(path_suffix)
    endif()
    if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/${path_suffix}bin")
        continue()
    endif()
    file(MAKE_DIRECTORY "${CURRENT_PACKAGES_DIR}/tools/qt6/bin/${path_suffix}")
    foreach(script IN LISTS script_files)
        if(EXISTS "${CURRENT_PACKAGES_DIR}/${path_suffix}bin/${script}${script_suffix}")
            set(target_script "${CURRENT_PACKAGES_DIR}/tools/qt6/bin/${path_suffix}${script}${script_suffix}")
            file(RENAME "${CURRENT_PACKAGES_DIR}/${path_suffix}bin/${script}${script_suffix}" "${target_script}")
            file(READ "${target_script}" _contents)
            if(_config MATCHES "debug")
                string(REPLACE "\\..\\share\\" "\\..\\..\\..\\..\\share\\" _contents "${_contents}")
            else()
                string(REPLACE "\\..\\share\\" "\\..\\..\\..\\share\\" _contents "${_contents}")
            endif()
            file(WRITE "${target_script}" "${_contents}")
        endif()
    endforeach()
    foreach(other IN LISTS other_files)
        if(EXISTS "${CURRENT_PACKAGES_DIR}/${path_suffix}bin/${other}")
            file(RENAME "${CURRENT_PACKAGES_DIR}/${path_suffix}bin/${other}" "${CURRENT_PACKAGES_DIR}/tools/qt6/bin/${path_suffix}${other}")
        endif()
    endforeach()
endforeach()


if(VCPKG_LIBRARY_LINKAGE STREQUAL "static")
    file(GLOB_RECURSE _bin_files "${CURRENT_PACKAGES_DIR}/bin/*")
    if(NOT _bin_files) # Only clean if empty otherwise let vcpkg throw and error. 
        file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/bin/" "${CURRENT_PACKAGES_DIR}/debug/bin/")
    endif()
endif()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/Qt6/QtBuildInternals")

if(NOT VCPKG_TARGET_IS_OSX)
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/share/Qt6/macos")
endif()

set(_file "${CMAKE_CURRENT_LIST_DIR}/qt.conf.in")
set(REL_PATH)
configure_file("${_file}" "${CURRENT_PACKAGES_DIR}/tools/qt6/qt_release.conf" @ONLY)
set(BACKUP_CURRENT_INSTALLED_DIR "${CURRENT_INSTALLED_DIR}")
set(BACKUP_CURRENT_HOST_INSTALLED_DIR "${CURRENT_HOST_INSTALLED_DIR}")
set(CURRENT_INSTALLED_DIR "./../../../")
set(CURRENT_HOST_INSTALLED_DIR "./../../../")
configure_file("${_file}" "${CURRENT_PACKAGES_DIR}/tools/qt6/bin/qt.conf")
set(REL_PATH debug/)
configure_file("${_file}" "${CURRENT_PACKAGES_DIR}/tools/qt6/bin/qt.debug.conf")
set(CURRENT_INSTALLED_DIR "${BACKUP_CURRENT_INSTALLED_DIR}")
set(CURRENT_HOST_INSTALLED_DIR "${BACKUP_CURRENT_HOST_INSTALLED_DIR}")
configure_file("${_file}" "${CURRENT_PACKAGES_DIR}/tools/qt6/qt_debug.conf" @ONLY)

if(VCPKG_TARGET_IS_WINDOWS)
    set(_DLL_FILES brotlicommon brotlidec bz2 freetype harfbuzz libpng16)
    set(DLLS_TO_COPY)
    foreach(_file IN LISTS _DLL_FILES)
        if(EXISTS "${CURRENT_INSTALLED_DIR}/bin/${_file}.dll")
            list(APPEND DLLS_TO_COPY "${CURRENT_INSTALLED_DIR}/bin/${_file}.dll")
        endif()
    endforeach()
    file(COPY ${DLLS_TO_COPY} DESTINATION "${CURRENT_PACKAGES_DIR}/tools/qt6/bin")
endif()

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/qmake.debug.bat" DESTINATION "${CURRENT_PACKAGES_DIR}/tools/qt6/bin")
set(hostinfofile "${CURRENT_PACKAGES_DIR}/share/Qt6HostInfo/Qt6HostInfoConfig.cmake")
file(READ "${hostinfofile}" _contents)
string(REPLACE [[set(QT6_HOST_INFO_LIBEXECDIR "bin")]] [[set(QT6_HOST_INFO_LIBEXECDIR "tools/qt6/bin")]] _contents "${_contents}")
string(REPLACE [[set(QT6_HOST_INFO_BINDIR "bin")]] [[set(QT6_HOST_INFO_BINDIR "tools/qt6/bin")]] _contents "${_contents}")
file(WRITE "${hostinfofile}" "${_contents}")

set(coretools "${CURRENT_PACKAGES_DIR}/share/Qt6CoreTools/Qt6CoreTools.cmake")
if(EXISTS "${coretools}")
    file(READ "${coretools}" _contents)
    string(REPLACE [[ "${_IMPORT_PREFIX}/tools/qt6/bin/qmake.exe"]] [["${_IMPORT_PREFIX}/tools/qt6/bin/qmake.debug.bat"]] _contents "${_contents}")
    file(WRITE "${coretools}" "${_contents}")
endif()