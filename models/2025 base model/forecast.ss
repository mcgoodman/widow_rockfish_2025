#C file created using an r4ss function
#C file write time: 2025-05-16  15:31:38
#
1 #_benchmarks
2 #_MSY
0.5 #_SPRtarget
0.4 #_Btarget
#_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF,  beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 0 0 0 0 1916 0 1916 0
1 #_Bmark_relF_Basis
1 #_Forecast
12 #_Nforecastyrs
1 #_F_scalar
#_Fcast_years:  beg_selex, end_selex, beg_relF, end_relF, beg_recruits, end_recruits (enter actual year, or values of 0 or -integer to be rel. endyr)
-4 -4 -4 0 0 0
1 #_Fcast_selex
2026 #_ControlRuleMethod
1 #_BforconstantF
2027 #_BfornoF
0.935 #_Flimitfraction
2028 #_N_forecast_loops
0.93 #_First_forecast_loop_with_stochastic_recruitment
2029 #_fcast_rec_option
0.926 #_fcast_rec_val
2030 #_Fcast_loop_control_5
0.922 #_FirstYear_for_caps_and_allocations
2031 #_stddev_of_log_catch_ratio
0.917 #_Do_West_Coast_gfish_rebuilder_output
2032 #_Ydecl
0.913 #_Yinit
2033 #_fleet_relative_F
# Note that fleet allocation is used directly as average F if Do_Forecast=4 
0.909 #_basis_for_fcast_catch_tuning
# enter list of fleet number and max for fleets with max annual catch; terminate with fleet=-9999
 #_fleet max_catch
    2034     0.904
    2035     0.900
    2036     0.896
-9999 -1
# enter list of area ID and max annual catch; terminate with area=-9999
       #_area   max_catch
 3.000000e+00    3.000000
 0.000000e+00    1.000000
 0.000000e+00 2021.000000
 0.000000e+00    0.000000
 2.015000e+03 2015.000000
 2.000000e+00    2.000000
 1.000000e+00    1.000000
 3.306009e-03    1.000000
 2.000000e+00    0.862549
 1.000000e+00    3.000000
 1.338966e-01    1.000000
 4.000000e+00    0.000100
 1.000000e+00    5.000000
-9999 -1
# enter list of fleet number and allocation group assignment, if any; terminate with fleet=-9999
 #_fleet group
       0     0
-9999 -1
-1 #_InputBasis
 #_year seas fleet catch_or_F
   2025    1     1       76.7
   2025    1     2     9770.0
   2025    1     3      778.7
   2025    1     4        0.0
   2025    1     5       43.2
   2026    1     1       70.8
   2026    1     2     8975.0
   2026    1     3      734.6
   2026    1     4        0.0
   2026    1     5       43.2
-9999 0 0 0 0
#
999 # verify end of input 
