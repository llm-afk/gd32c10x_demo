cmake_minimum_required(VERSION 3.10)

project(gd32c10x_demo C CXX ASM)

# 1. Architecture and Compiler Flags
set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(ARCH_FLAGS "-mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16")
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} ${ARCH_FLAGS} -O2 -g -Wall -Wextra -Wno-unused-parameter -Wshadow -fdata-sections -ffunction-sections -fno-common")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} ${ARCH_FLAGS} -O2 -g -Wall -Wextra -Wno-unused-parameter -Wshadow -fdata-sections -ffunction-sections -fno-common -fno-exceptions -fno-rtti -fno-threadsafe-statics -fno-use-cxa-atexit")
set(CMAKE_ASM_FLAGS "${CMAKE_ASM_FLAGS} ${ARCH_FLAGS} -g -Wall")

# 2. Linker Flags
set(LINKER_SCRIPT ${CMAKE_CURRENT_SOURCE_DIR}/gd32c10xxB_flash.ld)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} ${ARCH_FLAGS} -T ${LINKER_SCRIPT} -Wl,--gc-sections -O2 -Wl,-Map=${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}.map")

add_link_options(--specs=nano.specs)
add_link_options("-Wl,--no-warn-rwx-segments")

# 3. Source Files
set(SOURCES
    src/app/main.c
    src/app/systick_delay.c
    src/driver/CMSIS/GD/GD32C10x/Source/system_gd32c10x.c
    src/driver/CMSIS/GD/GD32C10x/Source/GCC/startup_gd32c10x.S
    src/driver/CMSIS/GD/GD32C10x/Source/GCC/newlib/syscalls.c
    src/driver/GD32C10x_standard_peripheral/Source/gd32c10x_misc.c
    src/driver/GD32C10x_standard_peripheral/Source/gd32c10x_rcu.c
    src/driver/GD32C10x_standard_peripheral/Source/gd32c10x_gpio.c
)

# 4. Create the executable
add_executable(${PROJECT_NAME}.elf ${SOURCES})

# 5. Include Directories
target_include_directories(${PROJECT_NAME}.elf PRIVATE
    src/app
    src/driver/CMSIS
    src/driver/CMSIS/GD/GD32C10x/Include
    src/driver/GD32C10x_standard_peripheral/Include
)

# 6. Global Defines
target_compile_definitions(${PROJECT_NAME}.elf PRIVATE GD32C10X)

# 7. Post-build steps to generate hex and bin files
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_OBJCOPY} -O ihex $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.hex
    COMMAND ${CMAKE_OBJCOPY} -O binary $<TARGET_FILE:${PROJECT_NAME}.elf> ${PROJECT_NAME}.bin
    COMMENT "Generating .hex and .bin files..."
)
