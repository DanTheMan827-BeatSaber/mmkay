# -----------------------------------------------------------------------------
# mmkay.cmake
#
# A cheeky CMake module for embedding asset files, mmkay?
#
# mmkay stands for:
#   Multi‑Modal Kit (for) Asset Yeilding...
#   ...or maybe I just like South Park, mmkay?
#
# This module processes your assets with style and humor. It defines two functions:
#
#   1. process_asset_mmkay: Processes a single asset file (each file gets its moment).
#   2. include_assets_mmkay: Orchestrates the process—setting up directories, processing assets,
#      writing the header, and creating an object library.
#
# Sit back and let your assets roll. Do it, mmkay?
#
# Thanks to https://github.com/Lauriethefish/ for the original version, mmkay?
# -----------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# process_asset_mmkay
#
# Processes a single asset file, mmkay?
#
# @param REL_FILE  The asset file path relative to ASSETS_DIRECTORY.
# ---------------------------------------------------------------------------
function(process_asset_mmkay REL_FILE)
    # Compute the full path for the current asset.
    set(SRC_FILE "${ASSETS_DIRECTORY}/${REL_FILE}")

    # Skip directories (folders aren’t processed, mmkay?).
    if(IS_DIRECTORY "${SRC_FILE}")
        return()
    endif()

    message("-- Including asset: '${REL_FILE}', mmkay?")

    # Ensure matching subdirectories exist in the prepended assets folder, mmkay?
    get_filename_component(REL_DIR "${REL_FILE}" DIRECTORY)
    if(NOT REL_DIR STREQUAL "")
        file(MAKE_DIRECTORY "${PREPENDED_ASSETS_DIR}/${REL_DIR}")
    endif()

    # Create a "prepended" version of the asset with an extra 32 bytes of pizzazz, mmkay?
    set(PREPENDED_FILE "${PREPENDED_ASSETS_DIR}/${REL_FILE}")
    add_custom_command(
        OUTPUT "${PREPENDED_FILE}"
        COMMAND ${CMAKE_COMMAND} -E echo_append "                                " > "${PREPENDED_FILE}"
        COMMAND ${CMAKE_COMMAND} -E cat "${SRC_FILE}" >> "${PREPENDED_FILE}"
        COMMAND ${CMAKE_COMMAND} -E echo_append " " >> "${PREPENDED_FILE}"
        DEPENDS "${SRC_FILE}"
    )

    # Ensure the binary assets folder has the proper subdirectory structure, mmkay?
    if(NOT REL_DIR STREQUAL "")
        file(MAKE_DIRECTORY "${ASSET_BINARIES_DIRECTORY}/${REL_DIR}")
    endif()

    # Define the output object file (with a .o extension), mmkay?
    set(OUTPUT_OBJ "${ASSET_BINARIES_DIRECTORY}/${REL_FILE}.o")
    add_custom_command(
        OUTPUT "${OUTPUT_OBJ}"
        COMMAND ${CMAKE_OBJCOPY} "${REL_FILE}" "${OUTPUT_OBJ}"
                --input-target binary --output-target elf64-aarch64 --set-section-flags binary=strings
        DEPENDS "${PREPENDED_FILE}"
        WORKING_DIRECTORY "${PREPENDED_ASSETS_DIR}"
    )

    # Append this object file to the global list, mmkay?
    set(BINARY_ASSET_FILES_MMKAY "${BINARY_ASSET_FILES_MMKAY};${OUTPUT_OBJ}")

    # Generate a mangled symbol for the asset, mmkay?
    string(REGEX REPLACE "[^a-zA-Z0-9]" "_" FULL_SYMBOL "${REL_FILE}")
    get_filename_component(FILE_NAME "${REL_FILE}" NAME)
    string(REGEX REPLACE "[^a-zA-Z0-9]" "_" LOCAL_NAME "${FILE_NAME}")

    # Append the extern declarations, mmkay?
    set(EXTERN_DECLARATIONS_MMKAY "${EXTERN_DECLARATIONS_MMKAY}extern \"C\" uint8_t _binary_${FULL_SYMBOL}_start[];\n")
    set(EXTERN_DECLARATIONS_MMKAY "${EXTERN_DECLARATIONS_MMKAY}extern \"C\" uint8_t _binary_${FULL_SYMBOL}_end[];\n")
    set(EXTERN_DECLARATIONS_MMKAY "${EXTERN_DECLARATIONS_MMKAY}extern \"C\" uint8_t _binary_${FULL_SYMBOL}_size[];\n")

    # Build an asset declaration (with namespace wrapping if needed), mmkay?
    set(INDENT_STRING "    ")
    set(INDENT "")
    set(NAMESPACE_OPEN "")
    set(NAMESPACE_CLOSE "")
    if(NOT REL_DIR STREQUAL "")
        string(REPLACE "/" ";" DIR_LIST "${REL_DIR}")
        foreach(DIR IN LISTS DIR_LIST)
            string(REGEX REPLACE "[^a-zA-Z0-9]" "_" NS "${DIR}")
            set(NAMESPACE_OPEN "${NAMESPACE_OPEN}\n${INDENT}namespace ${NS} {")
            set(NAMESPACE_CLOSE "${INDENT}}  // namespace ${NS}\n${NAMESPACE_CLOSE}")
            set(INDENT "${INDENT}${INDENT_STRING}")
        endforeach()
    endif()

    set(ASSET_DECLARATION "${NAMESPACE_OPEN}
${INDENT}/**
${INDENT} * Binary asset representing the file \"${REL_FILE}\".
${INDENT} * Embedded with love (and a little objcopy magic), mmkay?
${INDENT} */
${INDENT}const IncludedAsset ${LOCAL_NAME} {
${INDENT}    ::IncludedAssets::__AssetExterns__::_binary_${FULL_SYMBOL}_start,
${INDENT}    ::IncludedAssets::__AssetExterns__::_binary_${FULL_SYMBOL}_end
${INDENT}};
${NAMESPACE_CLOSE}")

    set(ASSET_DECLARATIONS_MMKAY "${ASSET_DECLARATIONS_MMKAY}${ASSET_DECLARATION}")

    # Update global accumulators in the parent scope.
    set(BINARY_ASSET_FILES_MMKAY "${BINARY_ASSET_FILES_MMKAY}" PARENT_SCOPE)
    set(EXTERN_DECLARATIONS_MMKAY "${EXTERN_DECLARATIONS_MMKAY}" PARENT_SCOPE)
    set(ASSET_DECLARATIONS_MMKAY "${ASSET_DECLARATIONS_MMKAY}" PARENT_SCOPE)
endfunction()


# ---------------------------------------------------------------------------
# include_assets_mmkay
#
# The main function that includes all assets.
#
# This function sets up directories, finds asset files,
# processes each via process_asset_mmkay, writes the header,
# and creates an object library so your assets get linked.
#
# Let's do this, mmkay?
# ---------------------------------------------------------------------------
function(include_assets_mmkay)
    # Define directories, mmkay?
    set(ASSETS_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/assets")
    set(ASSET_BINARIES_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/binaryAssets")
    set(PREPENDED_ASSETS_DIR "${CMAKE_CURRENT_BINARY_DIR}/prependedAssets")
    set(ASSET_HEADER_PATH "${CMAKE_CURRENT_SOURCE_DIR}/include/assets.hpp")

    # Initialize global accumulators, mmkay?
    set(EXTERN_DECLARATIONS_MMKAY "")
    set(ASSET_DECLARATIONS_MMKAY "")
    set(BINARY_ASSET_FILES_MMKAY "")

    if(EXISTS "${ASSETS_DIRECTORY}")
        file(MAKE_DIRECTORY "${ASSET_BINARIES_DIRECTORY}")
        file(MAKE_DIRECTORY "${PREPENDED_ASSETS_DIR}")

        # Find all asset files (recursively) in the assets directory, mmkay?
        file(GLOB_RECURSE ASSETS RELATIVE "${ASSETS_DIRECTORY}" "${ASSETS_DIRECTORY}/*")

        foreach(REL_FILE IN LISTS ASSETS)
            process_asset_mmkay("${REL_FILE}")
        endforeach()

        # Tidy up the accumulated declarations with extra indentation, mmkay?
        set(INDENT_STRING "    ")
        string(REPLACE "\n" "\n${INDENT_STRING}" ASSET_DECLARATIONS_MMKAY "${ASSET_DECLARATIONS_MMKAY}")
        string(STRIP "${ASSET_DECLARATIONS_MMKAY}" ASSET_DECLARATIONS_MMKAY)
        string(REPLACE "\n" "\n${INDENT_STRING}${INDENT_STRING}" EXTERN_DECLARATIONS_MMKAY "${EXTERN_DECLARATIONS_MMKAY}")
        string(STRIP "${EXTERN_DECLARATIONS_MMKAY}" EXTERN_DECLARATIONS_MMKAY)

        # Build the asset header with the accumulated declarations, mmkay?
        set(ASSET_HEADER_DATA "#pragma once

#include <string_view>

#include \"beatsaber-hook/shared/utils/typedefs.h\"

#if __has_include(\"bsml/shared/Helpers/utilities.hpp\")
#include \"bsml/shared/Helpers/utilities.hpp\"
#endif

struct IncludedAsset {
    IncludedAsset(uint8_t* start, uint8_t* end) : array(reinterpret_cast<Array<uint8_t>*>(start)) {
        array->klass = nullptr;
        array->monitor = nullptr;
        array->bounds = nullptr;
        array->max_length = end - start - 32;
        *(end - 1) = '\\0';
    }

    operator ArrayW<uint8_t>() const {
        init();
        return array;
    }

    operator std::string_view() const {
        return {reinterpret_cast<char*>(array->_values), array->get_Length()};
    }

    operator std::span<uint8_t>() const {
        return {array->_values, array->get_Length()};
    }

    void init() const {
        if (!array->klass) {
            array->klass = classof(Array<uint8_t>*);
        }
    }

   private:
    Array<uint8_t>* array;
};

#define PNG_SPRITE(asset) BSML::Utilities::LoadSpriteRaw(static_cast<ArrayW<uint8_t>>(asset))

/**
 * Namespace containing all embedded assets.
 */
namespace IncludedAssets {
    /**
    * @brief Contains raw asset symbols generated by llvm-objcopy.
    * This namespace is private and should not be used directly.
    */
    namespace __AssetExterns__ {
        ${EXTERN_DECLARATIONS_MMKAY}
    }  // namespace __AssetExterns__

    ${ASSET_DECLARATIONS_MMKAY}
}  // namespace IncludedAssets
")

        # Write the header if any assets were processed, mmkay?
        list(LENGTH BINARY_ASSET_FILES_MMKAY COUNT)
        if(${COUNT} GREATER 0)
            if(EXISTS "${ASSET_HEADER_PATH}")
                file(READ "${ASSET_HEADER_PATH}" CURRENT_ASSET_HEADER)
            else()
                set(CURRENT_ASSET_HEADER "")
            endif()

            if(NOT "${CURRENT_ASSET_HEADER}" STREQUAL "${ASSET_HEADER_DATA}")
                message("-- Writing '${ASSET_HEADER_PATH}' — fresh and updated, mmkay?")
                file(WRITE "${ASSET_HEADER_PATH}" "${ASSET_HEADER_DATA}")
            else()
                message("-- '${ASSET_HEADER_PATH}' is up to date, mmkay?")
            endif()

            # Create an object library with the asset object files, mmkay?
            add_library(asset_files OBJECT ${BINARY_ASSET_FILES_MMKAY})
            set_target_properties(asset_files PROPERTIES LINKER_LANGUAGE CXX)
            target_link_libraries(${COMPILE_ID} PRIVATE asset_files ${BINARY_ASSET_FILES_MMKAY})
        else()
            if(EXISTS "${ASSET_HEADER_PATH}")
                message("-- Removing '${ASSET_HEADER_PATH}' — no assets found in '${ASSETS_DIRECTORY}', mmkay?")
                file(REMOVE "${ASSET_HEADER_PATH}")
            endif()
        endif()
    else()
        if(EXISTS "${ASSET_HEADER_PATH}")
            message("-- Removing '${ASSET_HEADER_PATH}' — '${ASSETS_DIRECTORY}' doesn't exist, mmkay?")
            file(REMOVE "${ASSET_HEADER_PATH}")
        endif()
    endif()
endfunction()


# -----------------------------------------------------------------------------
# Kick off the asset inclusion process. Let's do this, mmkay?
# -----------------------------------------------------------------------------
include_assets_mmkay()
