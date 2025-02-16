# mmkay.cmake README

This module handles asset embedding with humor and style. It provides CMake a CMake include that processes asset files and generates a header to access the embedded binary data.

## Usage
- Make sure the dependency is added with `qpm dependency add mmkay`.
- Add this to your `CMakeLists.txt` file.
  ```cmake
  include("${EXTERN_DIR}/includes/mmkay/shared/mmkay.cmake")
  ```
- Place your assets in the `assets` directory.
- The module will create or update `include/assets.hpp` with embedded asset information.

Sit back and relax, mmkay?

## How It Works

**Asset Processing:**
Each file in the `assets` directory is processed:
- A prepended file is generated.
- A binary object is created from this prepended file.
- Corresponding external symbols are declared for later use in C++.

**Header Generation:**
An asset header is constructed with:
- External C symbol declarations generated for each asset.
- Asset declarations wrapped in namespaces reflecting their original directory structure.
- Utility conversions to work effortlessly with C++ asset types like `std::string_view` and `std::span`.

**Linking:**
An object library is created from the generated binary files and linked with the main project.

## Why The Name?
![I like South Park, mmkay?](mmkay.png)
