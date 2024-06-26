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
    message(FATAL_ERROR "kicad-cli not found, please install kicad 8")
endif()

file(GLOB_RECURSE PROJECT_SCH_FILES ${CMAKE_CURRENT_LIST_DIR} "*.kicad_sch")
file(GLOB_RECURSE PROJECT_PCB_FILES ${CMAKE_CURRENT_LIST_DIR} "*.kicad_pcb")

set (PROJECT_PRODUCTION_FILES
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_positions.csv"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-B_Cu.gbl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-B_Mask.gbs"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-B_Paste.gbp"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-B_Silkscreen.gbo"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-Edge_Cuts.gm1"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-F_Cu.gtl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-F_Mask.gts"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-F_Paste.gtp"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-F_Silkscreen.gto"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-In1_Cu.g2"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-In2_Cu.g3"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-In3_Cu.g4"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-In4_Cu.g5"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-NPTH.drl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-PTH.drl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-job.gbrjob"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_bom.xml"
)

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
            "${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml"
            -o "${CMAKE_CURRENT_BINARY_DIR}/fmc_fru_eeprom.bin"
            -e 2048
    DEPENDS
        "${CMAKE_CURRENT_SOURCE_DIR}/data/fmc_fru_eeprom.yml"
)

add_custom_target(production
    ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber.zip"
        ${PROJECT_PRODUCTION_FILES}
)

add_custom_command(
    OUTPUT
        ${PROJECT_PRODUCTION_FILES}
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber"
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber.zip"
    COMMENT
        "Generate the production files"
    COMMAND
        ${CMAKE_COMMAND} -E make_directory "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber"
    COMMAND
        ${KICADCLI_PROGRAM} pcb export gerbers
        --disable-aperture-macros
        --no-x2
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/"
        -l "B.Cu,B.Mask,B.Paste,B.SilkS,Edge.Cuts,F.Cu,F.Mask,F.Paste,F.SilkS,In1.Cu,In2.Cu,In3.Cu,In4.Cu,User.Drawings"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
    COMMAND
        ${KICADCLI_PROGRAM} pcb export drill
        --excellon-separate-th
        --generate-map
        --excellon-units mm
        --excellon-zeros-format suppressleading
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
    COMMAND
        ${KICADCLI_PROGRAM} pcb export pos
        --format csv --units mm --use-drill-file-origin --bottom-negate-x
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_positions.csv"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
        COMMAND
        ${KICADCLI_PROGRAM} sch export bom
        --preset "Grouped By Value"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_bom.csv"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_sch"
    COMMAND
        ${CMAKE_COMMAND} -E tar "cfv" "${CMAKE_PROJECT_NAME}_gerber.zip" --format=zip
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/"
    DEPENDS
        ${PROJECT_PCB_FILES}
)

add_custom_target(pdf
    ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_sch.pdf"
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_pcb.pdf"
)

add_custom_command(
    OUTPUT
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_sch.pdf"
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_pcb.pdf"
    COMMAND
        ${KICADCLI_PROGRAM} sch export pdf
        --no-background-color
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_sch.pdf"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_sch"
    COMMAND
        ${KICADCLI_PROGRAM} pcb export pdf
        --ibt
        -l "B.Cu,B.Mask,B.Paste,B.SilkS,Edge.Cuts,F.Cu,F.Mask,F.Paste,F.SilkS,In1.Cu,In2.Cu,In3.Cu,In4.Cu,User.Drawings,*"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_pcb.pdf"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
    DEPENDS
        ${PROJECT_SCH_FILES}
)

add_custom_target(erc
    ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_erc.rpt"
)

add_custom_command(
    OUTPUT
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_erc.rpt"
    COMMAND
        ${KICADCLI_PROGRAM} sch erc
        --severity-error
        --exit-code-violations
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_erc.rpt"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_sch"
)

add_custom_target(drc
    ALL
    DEPENDS
        "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_drc.rpt"
)

add_custom_command(
    OUTPUT
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_drc.rpt"
    COMMAND
        ${KICADCLI_PROGRAM} pcb drc
        --severity-error
        --exit-code-violations
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_drc.rpt"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
)
