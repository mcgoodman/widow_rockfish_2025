#C file created using an r4ss function
#C file write time: 2025-04-14  10:38:30
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
0 0 0 0 -999 0
0 #_Fcast_selex
3 #_ControlRuleMethod
0.4 #_BforconstantF
0.1 #_BfornoF
-1 #_Flimitfraction
 #_year fraction
   2025    1.000
   2026    1.000
   2027    0.935
   2028    0.930
   2029    0.926
   2030    0.922
   2031    0.917
   2032    0.913
   2033    0.909
   2034    0.904
   2035    0.900
   2036    0.896
-9999 0
3 #_N_forecast_loops
3 #_First_forecast_loop_with_stochastic_recruitment
0 #_fcast_rec_option
1 #_fcast_rec_val
0 #_Fcast_loop_control_5
2021 #_FirstYear_for_caps_and_allocations
0 #_stddev_of_log_catch_ratio
0 #_Do_West_Coast_gfish_rebuilder_output
2015 #_Ydecl
2015 #_Yinit
2 #_fleet_relative_F
# Note that fleet allocation is used directly as average F if Do_Forecast=4 
2 #_basis_for_fcast_catch_tuning
#_vals_fleet_relative_f
 #_seas fleet  Relative F
      1     1 0.003306009
      1     2 0.862548985
      1     3 0.133896572
      1     4 0.000000000
      1     5 0.000248434
-9999 0 0
# enter list of fleet number and max for fleets with max annual catch; terminate with fleet=-9999
-9999 -1
# enter list of area ID and max annual catch; terminate with area=-9999
-9999 -1
# enter list of fleet number and allocation group assignment, if any; terminate with fleet=-9999
-9999 -1
2 #_InputBasis
 #_year seas fleet catch_or_F
   2025    1     1      35.93
   2025    1     2    9374.26
   2025    1     3    1455.20
   2025    1     4       0.00
   2025    1     5       2.70
   2026    1     1      35.93
   2026    1     2    9374.26
   2026    1     3    1455.20
   2026    1     4       0.00
   2026    1     5       2.70
-9999 0 0 0
#
999 # verify end of input 
