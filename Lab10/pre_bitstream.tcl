# these constraints are required if you are not assigning pins for 
# one or more of the top-level input (or) output signals
# i have not assigned one of the output signals. Hence, added the following 
# constraints 
set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
set_property SEVERITY {Warning} [get_drc_checks UCIO-1]
