
# PlanAhead Launch Script for Post-Synthesis pin planning, created by Project Navigator

create_project -name HKRMIPS -dir "F:/HKRMIPS/xilinx/planAhead_run_1" -part xc6slx100fgg676-2
set_property design_mode GateLvl [get_property srcset [current_run -impl]]
set_property edif_top_file "F:/HKRMIPS/xilinx/soc_hkrmips.ngc" [ get_property srcset [ current_run ] ]
add_files -norecurse { {F:/HKRMIPS/xilinx} {../src} }
set_param project.pinAheadLayout  yes
set_property target_constrs_file "soc_hkrmips.ucf" [current_fileset -constrset]
add_files [list {soc_hkrmips.ucf}] -fileset [get_property constrset [current_run]]
link_design
