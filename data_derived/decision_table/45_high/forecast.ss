#C file created using an r4ss function
#C file write time: 2025-06-11  21:19:09
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
    2027    1     1   37.11 #sum_for_2027: 4238.02
    2027    1     2 3877.67                       
    2027    1     3  319.57                       
    2027    1     4    0.01                       
    2027    1     5    3.66                       
    2028    1     1   36.30 #sum_for_2028: 4348.85
    2028    1     2 3982.83                       
    2028    1     3  325.98                       
    2028    1     5    3.74                       
    2029    1     1   36.58 #sum_for_2029: 4676.98
    2029    1     2 4297.94                       
    2029    1     3  338.65                       
    2029    1     5    3.81                       
    2030    1     1   37.36 #sum_for_2030: 5004.36
    2030    1     2 4614.52                       
    2030    1     3  348.60                       
    2030    1     5    3.88                       
    2031    1     1   38.12 #sum_for_2031: 5212.98
    2031    1     2 4816.78                       
    2031    1     3  354.16                       
    2031    1     4    0.01                       
    2031    1     5    3.91                       
    2032    1     1   38.73  #sum_for_2032: 5319.6
    2032    1     2 4919.59                       
    2032    1     3  357.34                       
    2032    1     4    0.01                       
    2032    1     5    3.93                       
    2033    1     1   39.13 #sum_for_2033: 5358.99
    2033    1     2 4957.01                       
    2033    1     3  358.90                       
    2033    1     4    0.01                       
    2033    1     5    3.94                       
    2034    1     1   39.32 #sum_for_2034: 5359.69
    2034    1     2 4957.15                       
    2034    1     3  359.26                       
    2034    1     4    0.01                       
    2034    1     5    3.95                       
    2035    1     1   39.46  #sum_for_2035: 5354.7
    2035    1     2 4951.59                       
    2035    1     3  359.69                       
    2035    1     4    0.01                       
    2035    1     5    3.95                       
    2036    1     1   39.54 #sum_for_2036: 5347.48
    2036    1     2 4944.02                       
    2036    1     3  359.96                       
    2036    1     4    0.01                       
    2036    1     5    3.95                       
-9999 0 0 0
#
999 # verify end of input 
