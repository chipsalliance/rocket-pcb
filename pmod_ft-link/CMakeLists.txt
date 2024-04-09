cmake_minimum_required(VERSION 3.5)

project(pmod_ft_link
    VERSION 1.0.0
    DESCRIPTION "A generic in-circuit debugger and programmer based on the FT2232H chip"
)

find_program(LCEDA_PROGRAM "lceda-pro")
if(NOT LCEDA_PROGRAM)
    find_program(LCEDA_PROGRAM "lceda")
endif()
if(NOT LCEDA_PROGRAM)
    find_program(LCEDA_PROGRAM "easyeda")
endif()

if (NOT LCEDA_PROGRAM)
    message(FATAL_ERROR "lceda not found, please download and install lceda: https://easyeda.com")
endif()