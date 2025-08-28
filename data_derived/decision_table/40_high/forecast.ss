#C file created using an r4ss function
#C file write time: 2025-06-12  11:22:45
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
   2025        1
   2026        1
   2027        1
   2028        1
   2029        1
   2030        1
   2031        1
   2032        1
   2033        1
   2034        1
   2035        1
   2036        1
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
    2027    1     1   34.65 #sum_for_2027: 3957.04
    2027    1     2 3620.59                       
    2027    1     3  298.38                       
    2027    1     5    3.42                       
    2028    1     1   33.88 #sum_for_2028: 4058.79
    2028    1     2 3717.29                       
    2028    1     3  304.14                       
    2028    1     5    3.48                       
    2029    1     1   34.11 #sum_for_2029: 4360.06
    2029    1     2 4006.82                       
    2029    1     3  315.58                       
    2029    1     5    3.55                       
    2030    1     1   34.81 #sum_for_2030: 4658.74
    2030    1     2 4295.90                       
    2030    1     3  324.43                       
    2030    1     5    3.60                       
    2031    1     1   35.52 #sum_for_2031: 4851.59
    2031    1     2 4482.90                       
    2031    1     3  329.54                       
    2031    1     5    3.63                       
    2032    1     1   36.06 #sum_for_2032: 4943.19
    2032    1     2 4571.45                       
    2032    1     3  332.04                       
    2032    1     5    3.64                       
    2033    1     1   36.40 #sum_for_2033: 4970.99
    2033    1     2 4597.94                       
    2033    1     3  333.00                       
    2033    1     5    3.65                       
    2034    1     1   36.62  #sum_for_2034: 4973.1
    2034    1     2 4599.26                       
    2034    1     3  333.57                       
    2034    1     5    3.65                       
    2035    1     1   36.69 #sum_for_2035: 4956.43
    2035    1     2 4582.78                       
    2035    1     3  333.31                       
    2035    1     5    3.65                       
    2036    1     1   36.71 #sum_for_2036: 4936.87
    2036    1     2 4563.67                       
    2036    1     3  332.85                       
    2036    1     5    3.64                       
-9999 0 0 0
#
999 # verify end of input 
