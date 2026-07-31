set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Set exact toolchain path (corrected to 15.3.rel1 which is the one actually on your computer)
set(TC_PATH "D:/EmbeddedTools/arm-gnu-toolchain-15.3.rel1-mingw-w64-x86_64-arm-none-eabi/bin")

# Force CMake to use this explicit path
set(CMAKE_C_COMPILER "${TC_PATH}/arm-none-eabi-gcc.exe")
set(CMAKE_CXX_COMPILER "${TC_PATH}/arm-none-eabi-g++.exe")
set(CMAKE_ASM_COMPILER "${TC_PATH}/arm-none-eabi-gcc.exe")
set(CMAKE_OBJCOPY "${TC_PATH}/arm-none-eabi-objcopy.exe")
set(CMAKE_SIZE "${TC_PATH}/arm-none-eabi-size.exe")

# We must set these to bypass the compiler checks because it's a bare-metal environment
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
