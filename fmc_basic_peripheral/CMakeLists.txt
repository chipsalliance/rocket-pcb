cmake_minimum_required(VERSION 3.5)

project(fmc_usb_gpio_spi_jtag
    VERSION 1.0.0
    DESCRIPTION "FPGA mezzanine board used to verify basic peripherals"
)

find_program(FRUGY_PROGRAM "frugy")
if(NOT FRUGY_PROGRAM)
    message(FATAL_ERROR "frugy not found, please run `pip install frugy`")
endif()

find_program(KICADCLI_PROGRAM "kicad-cli")
if(NOT KICADCLI_PROGRAM)
    message(FATAL_ERROR "kicad-cli not found, please install kicad7")
endif()

file(GLOB_RECURSE PROJECT_SCH_FILES ${CMAKE_CURRENT_LIST_DIR} "*.kicad_sch")
file(GLOB_RECURSE PROJECT_PCB_FILES ${CMAKE_CURRENT_LIST_DIR} "*.kicad_pcb")

add_custom_target(eeprom
    ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin"
)

add_custom_command(
    OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin"
    COMMENT
        "Generate the FRU eeprom data using frugy"
    COMMAND
        ${FRUGY_PROGRAM}
            ${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml
            -o ${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin
            -e 2048
    DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml
)

add_custom_target(production
    ALL
    COMMAND
        ${CMAKE_COMMAND} -E make_directory ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber
    COMMAND
        ${KICADCLI_PROGRAM} pcb export gerbers
        --disable-aperture-macros
        --no-x2
        -l "B.Cu,B.Mask,B.Paste,B.SilkS,Edge.Cuts,F.Cu,F.Mask,F.Paste,F.SilkS,In1.Cu,In2.Cu,In3.Cu,In4.Cu"
        ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb
        -o ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/
    COMMAND
        ${KICADCLI_PROGRAM} pcb export drill
        --map-format ps
        --drill-origin
        plot --excellon-zeros-format suppressleading 
        ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb
        -o ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/
    COMMAND
        ${KICADCLI_PROGRAM} pcb export pos
        --format csv --units mm --use-drill-file-origin --bottom-negate-x 
        ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb
        -o ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_positions.csv
    VERBATIM
)

add_custom_target(pdf
    ALL
    COMMAND
        ${KICADCLI_PROGRAM} sch export pdf
        --no-background-color
        ${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_sch
        -o ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_sch.pdf
    VERBATIM
)
