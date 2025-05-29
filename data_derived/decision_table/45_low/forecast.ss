#C file created using an r4ss function
#C file write time: 2025-05-29  00:20:18
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
    2027    1     1   27.81 #sum_for_2027: 3155.27
    2027    1     2 2884.84                       
    2027    1     3  239.88                       
    2027    1     5    2.74                       
    2028    1     1   26.75 #sum_for_2028: 3181.77
    2028    1     2 2913.04                       
    2028    1     3  239.21                       
    2028    1     5    2.77                       
    2029    1     1   26.80 #sum_for_2029: 3385.65
    2029    1     2 3109.76                       
    2029    1     3  246.23                       
    2029    1     5    2.86                       
    2030    1     1   27.57 #sum_for_2030: 3665.73
    2030    1     2 3377.51                       
    2030    1     3  257.67                       
    2030    1     5    2.98                       
    2031    1     1   28.71 #sum_for_2031: 3957.35
    2031    1     2 3655.13                       
    2031    1     3  270.41                       
    2031    1     5    3.10                       
    2032    1     1   29.98 #sum_for_2032: 4218.45
    2032    1     2 3902.92                       
    2032    1     3  282.34                       
    2032    1     5    3.21                       
    2033    1     1   31.16 #sum_for_2033: 4418.78
    2033    1     2 4092.08                       
    2033    1     3  292.24                       
    2033    1     5    3.30                       
    2034    1     1   32.13 #sum_for_2034: 4557.52
    2034    1     2 4222.07                       
    2034    1     3  299.94                       
    2034    1     5    3.38                       
    2035    1     1   32.93 #sum_for_2035: 4654.44
    2035    1     2 4311.99                       
    2035    1     3  306.08                       
    2035    1     5    3.44                       
    2036    1     1   33.44 #sum_for_2036: 4706.66
    2036    1     2 4359.84                       
    2036    1     3  309.90                       
    2036    1     5    3.48                       
-9999 0 0 0
#
999 # verify end of input 
