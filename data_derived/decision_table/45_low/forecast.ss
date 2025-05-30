#C file created using an r4ss function
#C file write time: 2025-05-30  15:12:07
#
1 #_benchmarks
2 #_MSY
0.5 #_SPRtarget
0.4 #_Btarget
#_Bmark_years: beg_bio, end_bio, beg_selex, end_selex, beg_relF, end_relF,  beg_recr_dist, end_recr_dist, beg_SRparm, end_SRparm (enter actual year, or values of 0 or -integer to be rel. endyr)
0 0 0 0 0 0 1916 0 1916 0
2 #_Bmark_relF_Basis
1 #_Forecast
12 #_Nforecastyrs
1 #_F_scalar
-12345  # code to invoke new format for expanded fcast year controls
# biology and selectivity vectors are updated annually in the forecast according to timevary parameters, so check end year of blocks and dev vectors
# input in this section directs creation of averages over historical years to override any time_vary changes
#_Types implemented so far: 1=M, 4=recr_dist, 5=migration, 10=selectivity, 11=rel. F, recruitment
#_list: type, method (1, 2), start year, end year
#_Terminate with -9999 for type
#_ year input can be actual year, or values <=0 to be rel. styr or endyr
#_Method = 0 (or omitted) means continue using time_vary parms; 1 means to use average of derived factor
 #_MG_type method st_year end_year
        10      1      -4        0
        11      1      -4        0
        12      1      -4        0
-9999 0 0 0
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
2037 #_FirstYear_for_caps_and_allocations
0 #_stddev_of_log_catch_ratio
0 #_Do_West_Coast_gfish_rebuilder_output
0 #_Ydecl
0 #_Yinit
1 #_fleet_relative_F
# Note that fleet allocation is used directly as average F if Do_Forecast=4 
2 #_basis_for_fcast_catch_tuning
# enter list of fleet number and max for fleets with max annual catch; terminate with fleet=-9999
-9999 -1
# enter list of area ID and max annual catch; terminate with area=-9999
-9999 -1
# enter list of fleet number and allocation group assignment, if any; terminate with fleet=-9999
-9999 -1
2 #_InputBasis
 #_#Year Seas Fleet dead(B)                comment
    2025    1     1   76.70 #sum_for_2025: 10668.6
    2025    1     2 9770.00                       
    2025    1     3  778.70                       
    2025    1     5   43.20                       
    2026    1     1   70.80  #sum_for_2026: 9823.6
    2026    1     2 8975.00                       
    2026    1     3  734.60                       
    2026    1     5   43.20                       
    2027    1     1   28.48 #sum_for_2027: 3241.75
    2027    1     2 2964.83                       
    2027    1     3  245.64                       
    2027    1     5    2.80                       
    2028    1     1   27.37 #sum_for_2028: 3252.74
    2028    1     2 2978.13                       
    2028    1     3  244.42                       
    2028    1     5    2.82                       
    2029    1     1   27.36 #sum_for_2029: 3445.85
    2029    1     2 3164.55                       
    2029    1     3  251.04                       
    2029    1     5    2.90                       
    2030    1     1   28.10 #sum_for_2030: 3719.11
    2030    1     2 3425.81                       
    2030    1     3  262.18                       
    2030    1     5    3.02                       
    2031    1     1   29.20 #sum_for_2031: 4006.87
    2031    1     2 3699.84                       
    2031    1     3  274.69                       
    2031    1     5    3.14                       
    2032    1     1   30.45 #sum_for_2032: 4266.81
    2032    1     2 3946.65                       
    2032    1     3  286.46                       
    2032    1     5    3.25                       
    2033    1     1   31.61 #sum_for_2033: 4467.28
    2033    1     2 4136.11                       
    2033    1     3  296.22                       
    2033    1     5    3.34                       
    2034    1     1   32.57 #sum_for_2034: 4606.24
    2034    1     2 4266.46                       
    2034    1     3  303.79                       
    2034    1     5    3.42                       
    2035    1     1   33.30 #sum_for_2035: 4695.44
    2035    1     2 4349.37                       
    2035    1     3  309.30                       
    2035    1     5    3.47                       
    2036    1     1   33.81  #sum_for_2036: 4748.2
    2036    1     2 4397.82                       
    2036    1     3  313.06                       
    2036    1     5    3.51                       
-9999 0 0 0
#
999 # verify end of input 
