cmake_minimum_required(VERSION 3.5)

project(pmod_microsd
    VERSION 1.0.0
    DESCRIPTION "Pmod MicroSD provides a microSD card slot to VCU118 board"
)

find_program(KICADCLI_PROGRAM "kicad-cli")
if(NOT KICADCLI_PROGRAM)
    message(FATAL_ERROR "kicad-cli not found, please install kicad7")
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
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-NPTH.drl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-PTH.drl"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}-job.gbrjob"
    "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_bom.xml"
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
        -l "B.Cu,B.Mask,B.Paste,B.SilkS,Edge.Cuts,F.Cu,F.Mask,F.Paste,F.SilkS,In1.Cu,In2.Cu,User.Drawings"
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
        ${KICADCLI_PROGRAM} sch export python-bom
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_gerber/${CMAKE_PROJECT_NAME}_bom.xml"
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
        -l "B.Cu,B.Mask,B.Paste,B.SilkS,Edge.Cuts,F.Cu,F.Mask,F.Paste,F.SilkS,In1.Cu,In2.Cu,User.Drawings,*"
        -o "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}_pcb.pdf"
        "${CMAKE_CURRENT_SOURCE_DIR}/${CMAKE_PROJECT_NAME}.kicad_pcb"
    DEPENDS
        ${PROJECT_SCH_FILES}
)
