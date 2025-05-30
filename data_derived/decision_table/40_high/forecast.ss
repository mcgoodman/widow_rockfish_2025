#C file created using an r4ss function
#C file write time: 2025-05-30  15:12:08
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
   2027    0.873
   2028    0.864
   2029    0.856
   2030    0.848
   2031    0.840
   2032    0.832
   2033    0.824
   2034    0.817
   2035    0.809
   2036    0.801
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
    2027    1     1   26.60 #sum_for_2027: 3026.79
    2027    1     2 2768.23                       
    2027    1     3  229.35                       
    2027    1     5    2.61                       
    2028    1     1   25.57 #sum_for_2028: 3040.14
    2028    1     2 2783.57                       
    2028    1     3  228.37                       
    2028    1     5    2.63                       
    2029    1     1   25.58 #sum_for_2029: 3221.12
    2029    1     2 2958.27                       
    2029    1     3  234.56                       
    2029    1     5    2.71                       
    2030    1     1   26.27 #sum_for_2030: 3474.71
    2030    1     2 3200.77                       
    2030    1     3  244.85                       
    2030    1     5    2.82                       
    2031    1     1   27.32 #sum_for_2031: 3743.85
    2031    1     2 3457.01                       
    2031    1     3  256.60                       
    2031    1     5    2.92                       
    2032    1     1   28.47 #sum_for_2032: 3981.29
    2032    1     2 3682.50                       
    2032    1     3  267.30                       
    2032    1     5    3.02                       
    2033    1     1   29.54 #sum_for_2033: 4162.49
    2033    1     2 3853.73                       
    2033    1     3  276.11                       
    2033    1     5    3.11                       
    2034    1     1   30.33 #sum_for_2034: 4273.95
    2034    1     2 3958.40                       
    2034    1     3  282.06                       
    2034    1     5    3.16                       
    2035    1     1   30.86 #sum_for_2035: 4332.77
    2035    1     2 4013.01                       
    2035    1     3  285.70                       
    2035    1     5    3.20                       
    2036    1     1   31.28 #sum_for_2036: 4372.07
    2036    1     2 4048.91                       
    2036    1     3  288.66                       
    2036    1     5    3.22                       
-9999 0 0 0
#
999 # verify end of input 
