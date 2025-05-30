#C file created using an r4ss function
#C file write time: 2025-05-30  15:12:04
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
    2027    1     1   64.78    #sum_for_2027: 9000
    2027    1     2 8232.25                       
    2027    1     3  664.96                       
    2027    1     5   38.01                       
    2028    1     1   64.78    #sum_for_2028: 9000
    2028    1     2 8232.25                       
    2028    1     3  664.96                       
    2028    1     5   38.01                       
    2029    1     1   64.78    #sum_for_2029: 9000
    2029    1     2 8232.25                       
    2029    1     3  664.96                       
    2029    1     5   38.01                       
    2030    1     1   64.78    #sum_for_2030: 9000
    2030    1     2 8232.25                       
    2030    1     3  664.96                       
    2030    1     5   38.01                       
    2031    1     1   64.78    #sum_for_2031: 9000
    2031    1     2 8232.25                       
    2031    1     3  664.96                       
    2031    1     5   38.01                       
    2032    1     1   64.78    #sum_for_2032: 9000
    2032    1     2 8232.25                       
    2032    1     3  664.96                       
    2032    1     5   38.01                       
    2033    1     1   64.78    #sum_for_2033: 9000
    2033    1     2 8232.25                       
    2033    1     3  664.96                       
    2033    1     5   38.01                       
    2034    1     1   64.78    #sum_for_2034: 9000
    2034    1     2 8232.25                       
    2034    1     3  664.96                       
    2034    1     5   38.01                       
    2035    1     1   64.78 #sum_for_2035: 9000.01
    2035    1     2 8232.26                       
    2035    1     3  664.96                       
    2035    1     5   38.01                       
    2036    1     1   64.78 #sum_for_2036: 9000.03
    2036    1     2 8232.28                       
    2036    1     3  664.96                       
    2036    1     5   38.01                       
-9999 0 0 0
#
999 # verify end of input 
