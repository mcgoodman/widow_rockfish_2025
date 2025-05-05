#V3.30.23.2;_safe;_compile_date:_Apr 17 2025;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:_https://groups.google.com/g/ss3-forum_and_NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:_https://nmfs-ost.github.io/ss3-website/
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-05-01  15:55:52
#_data_and_control_files: 2025widow.dat // 2025widow.ctl
0  # 0 means do not read wtatage.ss; 1 means read and use wtatage.ss and also read and use growth parameters
1  #_N_Growth_Patterns (Growth Patterns, Morphs, Bio Patterns, GP are terms used interchangeably in SS3)
1 #_N_platoons_Within_GrowthPattern 
#_Cond 1 #_Platoon_within/between_stdev_ratio (no read if N_platoons=1)
#_Cond sd_ratio_rd < 0: platoon_sd_ratio parameter required after movement params.
#_Cond  1 #vector_platoon_dist_(-1_in_first_val_gives_normal_approx)
#
4 # recr_dist_method for parameters:  2=main effects for GP, Area, Settle timing; 3=each Settle entity; 4=none (only when N_GP*Nsettle*pop==1)
1 # not yet implemented; Future usage: Spawner-Recruitment: 1=global; 2=by area
1 #  number of recruitment settlement assignments 
0 # unused option
#GPattern month  area  age (for each settlement assignment)
 1 1 1 0
#
#_Cond 0 # N_movement_definitions goes here if Nareas > 1
#_Cond 1.0 # first age that moves (real age at begin of season, not integer) also cond on do_migration>0
#_Cond 1 1 1 2 4 10 # example move definition for seas=1, morph=1, source=1 dest=2, age1=4, age2=10
#
12 #_Nblock_Patterns
 3 2 1 1 1 1 3 1 1 1 1 4 #_blocks_per_pattern 
# begin and end years of blocks
 1982 1989 1990 1997 1998 2010
 1982 1989 1990 2010
 1916 1982
 1916 2001
 1916 2002
 1995 2012
 1916 1982 1983 2001 2002 2010
 1915 1915
 1995 2004
 1991 1998
 1916 2019
 1916 1982 1983 2001 2002 2010 2011 2016
#
# controls for all timevary parameters 
1 #_time-vary parm bound check (1=warn relative to base parm bounds; 3=no bound check); Also see env (3) and dev (5) options to constrain with base bounds
#
# AUTOGEN
 1 1 1 1 1 # autogen: 1st element for biology, 2nd for SR, 3rd for Q, 4th reserved, 5th for selex
# where: 0 = autogen time-varying parms of this category; 1 = read each time-varying parm line; 2 = read then autogen if parm min==-12345
#
#_Available timevary codes
#_Block types: 0: P_block=P_base*exp(TVP); 1: P_block=P_base+TVP; 2: P_block=TVP; 3: P_block=P_block(-1) + TVP
#_Block_trends: -1: trend bounded by base parm min-max and parms in transformed units (beware); -2: endtrend and infl_year direct values; -3: end and infl as fraction of base range
#_EnvLinks:  1: P(y)=P_base*exp(TVP*env(y));  2: P(y)=P_base+TVP*env(y);  3: P(y)=f(TVP,env_Zscore) w/ logit to stay in min-max;  4: P(y)=2.0/(1.0+exp(-TVP1*env(y) - TVP2))
#_DevLinks:  1: P(y)*=exp(dev(y)*dev_se;  2: P(y)+=dev(y)*dev_se;  3: random walk;  4: zero-reverting random walk with rho;  5: like 4 with logit transform to stay in base min-max
#_DevLinks(more):  21-25 keep last dev for rest of years
#
#_Prior_codes:  0=none; 6=normal; 1=symmetric beta; 2=CASAL's beta; 3=lognormal; 4=lognormal with biascorr; 5=gamma
#
# setup for M, growth, wt-len, maturity, fecundity, (hermaphro), recr_distr, cohort_grow, (movement), (age error), (catch_mult), sex ratio 
#_NATMORT
0 #_natM_type:_0=1Parm; 1=N_breakpoints;_2=Lorenzen;_3=agespecific;_4=agespec_withseasinterpolate;_5=BETA:_Maunder_link_to_maturity;_6=Lorenzen_range
  #_no additional input for selected M option; read 1P per morph
#
1 # GrowthModel: 1=vonBert with L1&L2; 2=Richards with L1&L2; 3=age_specific_K_incr; 4=age_specific_K_decr; 5=age_specific_K_each; 6=NA; 7=NA; 8=growth cessation
3 #_Age(post-settlement) for L1 (aka Amin); first growth parameter is size at this age; linear growth below this
40 #_Age(post-settlement) for L2 (aka Amax); 999 to treat as Linf
-999 #_exponential decay for growth above maxage (value should approx initial Z; -999 replicates 3.24; -998 to not allow growth above maxage)
0  #_placeholder for future growth feature
#
0 #_SD_add_to_LAA (set to 0.1 for SS2 V1.x compatibility)
0 #_CV_Growth_Pattern:  0 CV=f(LAA); 1 CV=F(A); 2 SD=F(LAA); 3 SD=F(A); 4 logSD=F(A)
#
2 #_maturity_option:  1=length logistic; 2=age logistic; 3=read age-maturity matrix by growth_pattern; 4=read age-fecundity; 5=disabled; 6=read length-maturity
3 #_First_Mature_Age
1 #_fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
1 #_parameter_offset_approach for M, G, CV_G:  1- direct, no offset**; 2- male=fem_parm*exp(male_parm); 3: male=female*exp(parm) then old=young*exp(parm)
#_** in option 1, any male parameter with value = 0.0 and phase <0 is set equal to female parameter
#
#_growth_parms
#_ LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Sex: 1  BioPattern: 1  NatMort
 0.01 0.3 0.124599 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 10 40 20.6525 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 35 60 49.5239 50 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.01 0.4 0.181107 0.15 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.01 0.4 0.11584 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.4 0.0481482 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 -3 3 1.59e-05 0 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 -3 10 2.99 2.962 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 -3 50 5.47 7 99 0 -99 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.7747 -1 99 0 -99 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 -1 1 1 1 99 0 -99 0 0 0 0 0 0 0 # Eggs/kg_inter_Fem_GP_1
 0 1 0 0 99 0 -99 0 0 0 0 0 0 0 # Eggs/kg_slope_wt_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.01 0.3 0.136775 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 10 40 21.0408 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 35 60 43.6366 45 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.01 0.4 0.244637 0.19 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.01 0.4 0.0941347 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.4 0.0568501 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 -3 3 1.45e-05 0 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 -3 10 3.01 3.005 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
# Hermaphroditism
#  Recruitment Distribution 
#  Cohort growth dev base
 0 2 1 1 99 0 -99 0 0 0 0 0 0 0 # CohortGrowDev
#  Movement
#  Platoon StDev Ratio 
#  Age Error from parameters
#  catch multiplier
#  fraction female, by GP
 1e-06 0.999999 0.5 0.5 0.5 0 -99 0 0 0 0 0 0 0 # FracFemale_GP_1
#  M2 parameter for each predator fleet
#
#_no timevary MG parameters
#
#_seasonal_effects_on_biology_parms
 0 0 0 0 0 0 0 0 0 0 #_femwtlen1,femwtlen2,mat1,mat2,fec1,fec2,Malewtlen1,malewtlen2,L1,K
#_ LO HI INIT PRIOR PR_SD PR_type PHASE
#_Cond -2 2 0 0 -1 99 -2 #_placeholder when no seasonal MG parameters
#
3 #_Spawner-Recruitment; Options: 1=NA; 2=Ricker; 3=std_B-H; 4=SCAA; 5=Hockey; 6=B-H_flattop; 7=survival_3Parm; 8=Shepherd_3Parm; 9=RickerPower_3parm
0  # 0/1 to use steepness in initial equ recruitment calculation
0  #  future feature:  0/1 to make realized sigmaR a function of SR curvature
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn #  parm_name
             1            20       10.4371            10            99             0          2          0          0          0          0          0          0          0 # SR_LN(R0)
           0.2             1          0.72          0.72          0.16             2         -5          0          0          0          0          0          0          0 # SR_BH_steep
             0             2           0.6          0.65            99             0        -50          0          0          0          0          0          0          0 # SR_sigmaR
            -5             5             0             0             1             0        -99          0          0          0          0          0          0          0 # SR_regime
             0           0.5             0             0            99             0        -99          0          0          0          0          0          0          0 # SR_autocorr
#_no timevary SR parameters
1 #do_recdev:  0=none; 1=devvector (R=F(SSB)+dev); 2=deviations (R=F(SSB)+dev); 3=deviations (R=R0*dev; dev2=R-f(SSB)); 4=like 3 with sum(dev2) adding penalty
1970 # first year of main recr_devs; early devs can precede this era
2020 # last year of main recr_devs; forecast devs start in following year
2 #_recdev phase 
1 # (0/1) to read 13 advanced options
 1900 #_recdev_early_start (0=none; neg value makes relative to recdev_start)
 4 #_recdev_early_phase
 0 #_forecast_recruitment phase (incl. late recr) (0 value resets to maxphase+1)
 1 #_lambda for Fcast_recr_like occurring before endyr+1
 1962.89 #_last_yr_nobias_adj_in_MPD; begin of ramp
 1975.38 #_first_yr_fullbias_adj_in_MPD; begin of plateau
 2017.14 #_last_yr_fullbias_adj_in_MPD
 2024.28 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.8514 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
 0 #_period of cycles in recruitment (N parms read below)
 -5 #min rec_dev
 5 #max rec_dev
 0 #_read_recdevs
#_end of advanced SR options
#
#_placeholder for full parameter lines for recruitment cycles
# read specified recr devs
#_year Input_value
#
# all recruitment deviations
#  1900E 1901E 1902E 1903E 1904E 1905E 1906E 1907E 1908E 1909E 1910E 1911E 1912E 1913E 1914E 1915E 1916E 1917E 1918E 1919E 1920E 1921E 1922E 1923E 1924E 1925E 1926E 1927E 1928E 1929E 1930E 1931E 1932E 1933E 1934E 1935E 1936E 1937E 1938E 1939E 1940E 1941E 1942E 1943E 1944E 1945E 1946E 1947E 1948E 1949E 1950E 1951E 1952E 1953E 1954E 1955E 1956E 1957E 1958E 1959E 1960E 1961E 1962E 1963E 1964E 1965E 1966E 1967E 1968E 1969E 1970R 1971R 1972R 1973R 1974R 1975R 1976R 1977R 1978R 1979R 1980R 1981R 1982R 1983R 1984R 1985R 1986R 1987R 1988R 1989R 1990R 1991R 1992R 1993R 1994R 1995R 1996R 1997R 1998R 1999R 2000R 2001R 2002R 2003R 2004R 2005R 2006R 2007R 2008R 2009R 2010R 2011R 2012R 2013R 2014R 2015R 2016R 2017R 2018R 2019R 2020R 2021F 2022F 2023F 2024F 2025F 2026F 2027F 2028F 2029F 2030F 2031F 2032F 2033F 2034F 2035F 2036F
#  -0.00142572 -0.0016094 -0.00181508 -0.00204483 -0.00230068 -0.00258453 -0.00289794 -0.00324185 -0.00361639 -0.00402096 -0.00445572 -0.00492383 -0.00543211 -0.00598859 -0.00660011 -0.00727397 -0.00801504 -0.00883215 -0.00973193 -0.0107229 -0.0118148 -0.0130176 -0.014343 -0.015803 -0.0174107 -0.0191814 -0.0211306 -0.0232751 -0.0256339 -0.0282268 -0.0310764 -0.0342064 -0.0376431 -0.0414131 -0.0455476 -0.0500844 -0.0550722 -0.0605776 -0.0666913 -0.0735164 -0.0810744 -0.0893931 -0.0984937 -0.108132 -0.117998 -0.128077 -0.13809 -0.14759 -0.156682 -0.16495 -0.17166 -0.175771 -0.176095 -0.171166 -0.159586 -0.14019 -0.112993 -0.0807833 -0.0508666 -0.0336474 -0.0350723 -0.0464075 -0.0458643 -0.0151712 0.0382087 0.0960343 0.156565 0.169075 0.120563 -0.0206939 1.38672 1.19631 -0.806616 -0.969309 -0.659444 0.0897847 -1.04666 0.694989 1.11536 -0.0309988 0.523557 1.04766 0.42855 0.00909195 0.695132 0.378751 -0.379228 0.557306 0.104511 -0.202842 0.246231 0.845618 -0.133586 0.0991233 0.0124542 -0.454551 -0.756008 -0.329118 0.259554 0.53981 0.348287 -0.245858 -0.371017 -0.413999 0.761438 -0.899856 0.480518 -0.921418 1.31603 -0.721105 0.877966 -1.04025 -1.46389 0.70336 -0.183042 -0.433765 1.25456 -0.0255447 -1.00654 -1.26756 -1.21045 -0.475902 -0.411009 -0.0361947 -0.188743 0 0 0 0 0 0 0 0 0 0 0 0
#
#Fishing Mortality info 
0.05 # F ballpark value in units of annual_F
-1982 # F ballpark year (neg value to disable)
1 # F_Method:  1=Pope midseason rate; 2=F as parameter; 3=F as hybrid; 4=fleet-specific parm/hybrid (#4 is superset of #2 and #3 and is recommended)
0.9 # max F (methods 2-4) or harvest fraction (method 1)
# F_Method 1:  no additional input needed
#
#_initial_F_parms; for each fleet x season that has init_catch; nest season in fleet; count = 0
#_for unconstrained init_F, use an arbitrary initial catch and set lambda=0 for its logL
#_ LO HI INIT PRIOR PR_SD  PR_type  PHASE
#
# F rates by fleet x season
#_year:  1916 1917 1918 1919 1920 1921 1922 1923 1924 1925 1926 1927 1928 1929 1930 1931 1932 1933 1934 1935 1936 1937 1938 1939 1940 1941 1942 1943 1944 1945 1946 1947 1948 1949 1950 1951 1952 1953 1954 1955 1956 1957 1958 1959 1960 1961 1962 1963 1964 1965 1966 1967 1968 1969 1970 1971 1972 1973 1974 1975 1976 1977 1978 1979 1980 1981 1982 1983 1984 1985 1986 1987 1988 1989 1990 1991 1992 1993 1994 1995 1996 1997 1998 1999 2000 2001 2002 2003 2004 2005 2006 2007 2008 2009 2010 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021 2022 2023 2024 2025 2026 2027 2028 2029 2030 2031 2032 2033 2034 2035 2036
# seas:  1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
# BottomTrawl 4.82754e-05 7.5043e-05 8.76072e-05 6.09219e-05 6.22252e-05 5.14814e-05 4.43156e-05 4.81053e-05 2.83822e-05 2.40048e-05 6.8138e-05 9.22464e-05 0.000130548 0.000183897 0.000163916 0.000160892 0.000174844 0.000273184 0.000243131 0.000236115 0.00020003 0.000285762 0.000265427 0.000333271 0.000603004 0.000751695 0.00107448 0.00378875 0.0074924 0.0127551 0.00907268 0.00464174 0.00370353 0.0028126 0.00308135 0.00434861 0.00435345 0.00398625 0.00375979 0.00396692 0.00500539 0.00653042 0.00606571 0.0059127 0.00730554 0.00616567 0.0069303 0.00386552 0.00547379 0.00221059 0.00532049 0.00833619 0.00398317 0.00454533 0.00274894 0.00355267 0.00440722 0.00435995 0.00390195 0.00378436 0.0042878 0.00653835 0.00826589 0.0214581 0.0438541 0.0435168 0.0674054 0.114797 0.0569947 0.045172 0.0611285 0.0684626 0.0690159 0.0795042 0.125315 0.0986192 0.111423 0.150262 0.108848 0.12171 0.109249 0.113286 0.099029 0.063171 0.0022458 0.00158421 0.000736251 0.000143783 0.000308537 0.000105989 0.000188123 0.000141853 6.05291e-05 0.000112982 0.000122225 0.000239994 0.000514572 0.000603526 0.000786946 0.000126874 9.61469e-05 0.000351196 0.000363572 0.000304802 0.000856724 0.00125005 0.00160222 0.0011186 0.000413291 0.000603157 0.000718526 0.000369782 0.00036351 0.000361438 0.000362013 0.000363487 0.000365615 0.000367385 0.000368204 0.000368945 0.000369307
# MidwaterTrawl 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0509116 0.148263 0.268023 0.322435 0.0832265 0.149696 0.132127 0.113201 0.163674 0.126841 0.166014 0.102483 0.0519008 0.0383674 0.0603315 0.0623495 0.0685029 0.0562109 0.0719616 0.026102 0.0608751 0.112311 0.0544682 0.00694994 0.000254417 0.00068738 0.00070221 0.000252164 2.89743e-05 0.000770005 0.00064368 0.000919892 0.000749845 0.000781524 0.00369254 0.00426985 0.00619409 0.00734452 0.0618795 0.128951 0.12381 0.123156 0.167156 0.176825 0.17646 0.180986 0.222493 0.279686 0.0964774 0.0948411 0.0943004 0.0944505 0.094835 0.0953901 0.095852 0.0960656 0.0962589 0.0963536
# Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0379011 0.0413741 0.0213579 0.00392715 0.00600373 0.0074861 0.00442831 0.0067757 0.00424005 0.00383634 0.00662151 0.00101798 0.00153137 0.00153131 0.0022207 0.00222668 0.00203806 0.00231145 0.00555026 0.00349766 0.0048309 0.00332472 0.00435899 0.00403742 0.00470084 0.012369 0.0100823 0.00626844 0.014976 0.0118303 0.0222231 0.0100632 0.016372 0.0100385 0.00742086 0.00559742 0.00399233 0.000642316 0.00109657 0.00321037 0.00359117 0.00393314 0.00355095 0.00211375 0.00159323 0.00215013 0.00250296 0.00232239 0.0042439 0.00448612 0.00482997 0.0153578 0.0117553 0.0129931 0.00754206 0.00618352 0.0115025 0.00762311 0.0069301 0.0219786 0.0262222 0.0149765 0.0147225 0.0146386 0.0146619 0.0147216 0.0148077 0.0148794 0.0149126 0.0149426 0.0149573
# Net 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000152525 0.000498006 0.00501181 0.00626222 0.0115019 0.00966968 0.0110021 0.00425449 0.00493806 0.00857933 0.00527477 0.00103528 0.00119713 0.00145783 0.00149625 0.000437799 0.000445646 0.00132809 0.000266188 0.000176868 0.000182646 5.0572e-07 9.85575e-06 0 2.68977e-06 0 5.08272e-05 0 3.31976e-06 0 0 0 0 3.78097e-07 0 0 0 0 0 2.33145e-08 0 7.91152e-07 0 0 3.38329e-12 3.38329e-12 1.11852e-05 1.09955e-05 1.09328e-05 1.09502e-05 1.09947e-05 1.10591e-05 1.11126e-05 1.11374e-05 1.11598e-05 1.11708e-05
# HnL 0.000524695 0.000817202 0.000939245 0.000648842 0.000664805 0.00055183 0.000479801 0.000527854 0.000341709 0.00043376 0.000630594 0.000490588 0.000535059 0.000466457 0.000674371 0.00058647 0.000575721 0.000379669 0.000446039 0.000507035 0.000635118 0.000503481 0.000377181 0.000260832 0.000339947 0.000270042 0.000100014 0.000165704 0.000299578 0.000521789 0.000553121 0.00072471 0.000324055 0.000355168 0.000514578 0.000401092 0.00032877 0.000115018 0.000179328 0.000155217 0.000352578 0.000321157 0.000313602 0.000247953 0.000190992 0.000134191 0.00013747 0.00017343 0.000113334 0.000178431 0.000322452 0.000288148 0.000179387 0.000178653 8.67856e-05 0.000104052 0.000171202 0.000152182 0.0003568 0.000222299 0.000281787 0.000261221 0.00102446 0.000671719 0.000420588 0.000601713 0.00196371 0.00043051 0.000341816 0.000347337 0.00103151 0.000668841 0.000937401 0.000594388 0.0019135 0.00147139 0.00276923 0.00175708 0.00141939 0.00046839 0.000584308 0.000673948 0.0015742 0.000805621 0.00027457 0.000141842 1.10588e-05 1.19115e-05 4.43448e-06 1.82794e-05 2.00509e-05 2.27777e-05 1.40851e-05 4.39861e-06 1.64182e-06 1.26329e-06 2.95634e-06 8.23738e-06 1.48365e-05 1.67399e-05 7.9472e-06 2.09416e-05 1.32842e-05 1.77451e-05 2.3185e-05 3.98515e-05 8.38494e-05 7.66393e-05 0.000159108 3.76429e-05 4.29574e-05 2.77877e-05 2.73164e-05 2.71607e-05 2.72039e-05 2.73147e-05 2.74745e-05 2.76076e-05 2.76691e-05 2.77248e-05 2.77521e-05
#
#_Q_setup for fleets with cpue or survey or deviation data
#_1:  fleet number
#_2:  link type: 1=simple q; 2=mirror; 3=power (+1 parm); 4=mirror with scale (+1p); 5=offset (+1p); 6=offset & power (+2p)
#_     where power is applied as y = q * x ^ (1 + power); so a power value of 0 has null effect
#_     and with the offset included it is y = q * (x + offset) ^ (1 + power)
#_3:  extra input for link, i.e. mirror fleet# or dev index number
#_4:  0/1 to select extra sd parameter
#_5:  0/1 for biasadj or not
#_6:  0/1 to float
#_   fleet      link link_info  extra_se   biasadj     float  #  fleetname
         1         1         0         1         0         1  #  BottomTrawl
         3         1         0         1         1         0  #  Hake
         6         1         0         1         0         1  #  JuvSurvey
         7         1         0         1         1         0  #  Triennial
         8         1         0         1         0         1  #  NWFSC
         9         1         0         1         0         1  #  ForeignAtSea
-9999 0 0 0 0 0
#
#_Q_parameters
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
           -25            25      -5.99524             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_BottomTrawl(1)
             0             2      0.164307             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_BottomTrawl(1)
           -20             2      -11.1167             0            99             0          1          0          0          0          0          0         10          1  #  LnQ_base_Hake(3)
             0             2      0.371222             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Hake(3)
           -25            25       -1.6365             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_JuvSurvey(6)
             0             2       1.68807             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_JuvSurvey(6)
            -4             4      -2.05842             0            99             0          2          0          0          0          0          0          9          1  #  LnQ_base_Triennial(7)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(7)
           -25            25      -3.14074             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_NWFSC(8)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_NWFSC(8)
           -25            25      -11.4353             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_ForeignAtSea(9)
             0             2      0.577965             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_ForeignAtSea(9)
# timevary Q parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type     PHASE  #  parm_name
        0.0001             2      0.465312           0.5           0.5             6      3  # LnQ_base_Hake(3)_BLK10add_1991
        0.0001             2      0.158512           0.5           0.5             6      3  # LnQ_base_Triennial(7)_BLK9add_1995
# info on dev vectors created for Q parms are reported with other devs after tag parameter section 
#
#_size_selex_patterns
#Pattern:_0;  parm=0; selex=1.0 for all sizes
#Pattern:_1;  parm=2; logistic; with 95% width specification
#Pattern:_5;  parm=2; mirror another size selex; PARMS pick the min-max bin to mirror
#Pattern:_11; parm=2; selex=1.0  for specified min-max population length bin range
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_6;  parm=2+special; non-parm len selex
#Pattern:_43; parm=2+special+2;  like 6, with 2 additional param for scaling (mean over bin range)
#Pattern:_8;  parm=8; double_logistic with smooth transitions and constant above Linf option
#Pattern:_9;  parm=6; simple 4-parm double logistic with starting length; parm 5 is first length; parm 6=1 does desc as offset
#Pattern:_21; parm=2*special; non-parm len selex, read as N break points, then N selex parameters
#Pattern:_22; parm=4; double_normal as in CASAL
#Pattern:_23; parm=6; double_normal where final value is directly equal to sp(6) so can be >1.0
#Pattern:_24; parm=6; double_normal with sel(minL) and sel(maxL), using joiners
#Pattern:_2;  parm=6; double_normal with sel(minL) and sel(maxL), using joiners, back compatibile version of 24 with 3.30.18 and older
#Pattern:_25; parm=3; exponential-logistic in length
#Pattern:_27; parm=special+3; cubic spline in length; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=special+3+2; cubic spline; like 27, with 2 additional param for scaling (mean over bin range)
#_discard_options:_0=none;_1=define_retention;_2=retention&mortality;_3=all_discarded_dead;_4=define_dome-shaped_retention
#_Pattern Discard Male Special
 24 1 0 0 # 1 BottomTrawl
 24 1 0 0 # 2 MidwaterTrawl
 24 0 0 0 # 3 Hake
 24 0 0 0 # 4 Net
 24 0 0 0 # 5 HnL
 0 0 0 0 # 6 JuvSurvey
 27 0 0 3 # 7 Triennial
 27 0 0 3 # 8 NWFSC
 5 0 0 3 # 9 ForeignAtSea
#
#_age_selex_patterns
#Pattern:_0; parm=0; selex=1.0 for ages 0 to maxage
#Pattern:_10; parm=0; selex=1.0 for ages 1 to maxage
#Pattern:_11; parm=2; selex=1.0  for specified min-max age
#Pattern:_12; parm=2; age logistic
#Pattern:_13; parm=8; age double logistic. Recommend using pattern 18 instead.
#Pattern:_14; parm=nages+1; age empirical
#Pattern:_15; parm=0; mirror another age or length selex
#Pattern:_16; parm=2; Coleraine - Gaussian
#Pattern:_17; parm=nages+1; empirical as random walk  N parameters to read can be overridden by setting special to non-zero
#Pattern:_41; parm=2+nages+1; // like 17, with 2 additional param for scaling (mean over bin range)
#Pattern:_18; parm=8; double logistic - smooth transition
#Pattern:_19; parm=6; simple 4-parm double logistic with starting age
#Pattern:_20; parm=6; double_normal,using joiners
#Pattern:_26; parm=3; exponential-logistic in age
#Pattern:_27; parm=3+special; cubic spline in age; parm1==1 resets knots; parm1==2 resets all 
#Pattern:_42; parm=2+special+3; // cubic spline; with 2 additional param for scaling (mean over bin range)
#Age patterns entered with value >100 create Min_selage from first digit and pattern from remainder
#_Pattern Discard Male Special
 10 0 0 0 # 1 BottomTrawl
 10 0 0 0 # 2 MidwaterTrawl
 10 0 0 0 # 3 Hake
 10 0 0 0 # 4 Net
 10 0 0 0 # 5 HnL
 11 0 0 0 # 6 JuvSurvey
 10 0 0 0 # 7 Triennial
 11 0 0 0 # 8 NWFSC
 10 0 0 0 # 9 ForeignAtSea
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   BottomTrawl LenSelex
            10            59       43.3983            45          0.05             0          1          0          0          0          0        0.5          4          2  #  Size_DblN_peak_BottomTrawl(1)
            -5            10       2.49993             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_BottomTrawl(1)
            -4            12       4.59264             3          0.05             0          2          0          0          0          0        0.5          4          2  #  Size_DblN_ascend_se_BottomTrawl(1)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_BottomTrawl(1)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_BottomTrawl(1)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_BottomTrawl(1)
            -5            60       3.78523             0            99             0          4          0          0          0          0          0          2          2  #  Retain_L_infl_BottomTrawl(1)
          0.01             8      0.996433             1            99             0          4          0          0          0          0          0          2          2  #  Retain_L_width_BottomTrawl(1)
           -10            10       4.59512            10            99             0         -2          0          0          0          0          0          1          2  #  Retain_L_asymptote_logit_BottomTrawl(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_BottomTrawl(1)
# 2   MidwaterTrawl LenSelex
            10            59       36.9648            45          0.05             0          1          0          0          0          0        0.5          7          2  #  Size_DblN_peak_MidwaterTrawl(2)
           -10            10      -9.42117             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_MidwaterTrawl(2)
            -4            12       2.86574             3          0.05             0          2          0          0          0          0        0.5          7          2  #  Size_DblN_ascend_se_MidwaterTrawl(2)
            -2            10       3.93475            10          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_descend_se_MidwaterTrawl(2)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_MidwaterTrawl(2)
            -9             9      -1.38522           0.5          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_end_logit_MidwaterTrawl(2)
            -5            60            -5             0            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_infl_MidwaterTrawl(2)
          0.01             8           1.2             1            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_width_MidwaterTrawl(2)
           -10            10       5.76509            10            99             0          2          0          0          0          0          0         12          2  #  Retain_L_asymptote_logit_MidwaterTrawl(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_MidwaterTrawl(2)
# 3   Hake LenSelex
            10            59       33.5575            45          0.05             0          1          0          0          0          0        0.5         11          2  #  Size_DblN_peak_Hake(3)
            -5            10       2.49778             5          0.05             0          3          0          0          0          0        0.5         11          2  #  Size_DblN_top_logit_Hake(3)
            -4            12       2.11549             3          0.05             0          2          0          0          0          0        0.5         11          2  #  Size_DblN_ascend_se_Hake(3)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Hake(3)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Hake(3)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Hake(3)
# 4   Net LenSelex
            10            59       42.6002            45          0.05             0          1          0          0          0          0        0.5          0          0  #  Size_DblN_peak_Net(4)
            -5            10       2.50864             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_Net(4)
            -4            12        3.5559             3          0.05             0          2          0          0          0          0        0.5          0          0  #  Size_DblN_ascend_se_Net(4)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Net(4)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Net(4)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Net(4)
# 5   HnL LenSelex
            10            59       23.5538            45          0.05             0          5          0          0          0          0        0.5          5          2  #  Size_DblN_peak_HnL(5)
            -5            10       2.50234             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_HnL(5)
            -5            12            -5             3          0.05             0         -2          0          0          0          0        0.5          5          2  #  Size_DblN_ascend_se_HnL(5)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_HnL(5)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_HnL(5)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_HnL(5)
# 6   JuvSurvey LenSelex
# 7   Triennial LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_Triennial(7)
        -0.001             1      0.118854             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_Triennial(7)
            -1             1     0.0381032             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_Triennial(7)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_Triennial(7)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_Triennial(7)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_Triennial(7)
           -10            10      -1.82423           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_Triennial(7)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_Triennial(7)
           -10            10      0.435369           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_Triennial(7)
# 8   NWFSC LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_NWFSC(8)
        -0.001             1      0.467133             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_NWFSC(8)
            -1             1     -0.109047             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_NWFSC(8)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_NWFSC(8)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_NWFSC(8)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_NWFSC(8)
           -10            10      -2.22354           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_NWFSC(8)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_NWFSC(8)
           -10            10     -0.114489           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_NWFSC(8)
# 9   ForeignAtSea LenSelex
            -2            60             1             0           0.2             0        -99          0          0          0          0        0.5          0          0  #  SizeSel_P1_ForeignAtSea(9)
            -2            60            -1             0           0.2             0        -99          0          0          0          0        0.5          0          0  #  SizeSel_P2_ForeignAtSea(9)
# 1   BottomTrawl AgeSelex
# 2   MidwaterTrawl AgeSelex
# 3   Hake AgeSelex
# 4   Net AgeSelex
# 5   HnL AgeSelex
# 6   JuvSurvey AgeSelex
             0             1             0             0            99             0        -99          0          0          0          0        0.5          0          0  #  minage@sel=1_JuvSurvey(6)
             0             1             0             0            99             0        -99          0          0          0          0        0.5          0          0  #  maxage@sel=1_JuvSurvey(6)
# 7   Triennial AgeSelex
# 8   NWFSC AgeSelex
             0             1             0             0            99             0        -99          0          0          0          0        0.5          0          0  #  minage@sel=1_NWFSC(8)
             0            50            40             0            99             0        -99          0          0          0          0        0.5          0          0  #  maxage@sel=1_NWFSC(8)
# 9   ForeignAtSea AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
            10            59       38.9802            45          0.05             0      1  # Size_DblN_peak_BottomTrawl(1)_BLK4repl_1916
            -4            12       3.42758             3          0.05             0      2  # Size_DblN_ascend_se_BottomTrawl(1)_BLK4repl_1916
            -5            50       27.2206            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1982
            -5            50       27.5208            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1990
          0.01             5      0.969216             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1982
          0.01             5       1.83064             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1990
           -10            10       1.71885            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1982
           -10            10       0.78274            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1990
           -10            10      0.107812            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1998
            10            59       38.6834            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1916
            10            59       38.0162            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1983
            10            59       37.3983            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_2002
            -4            12       3.37013             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1916
            -4            12       3.08059             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1983
            -4            12       2.79637             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_2002
            -2            10       4.24163            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1916
            -2            10       3.05551            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1983
            -2            10      -1.41765            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_2002
            -9             9       -1.9335           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1916
            -9             9     -0.423944           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1983
            -9             9       1.56276           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_2002
           -10            10        4.5912            10            99             0      -2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1916
           -10            10       1.66015            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1983
           -10            10        1.8538            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2002
           -10            10        8.9466            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2011
            10            59       42.7924            45          0.05             0      1  # Size_DblN_peak_Hake(3)_BLK11repl_1916
            -5            10       2.50455             5          0.05             0      3  # Size_DblN_top_logit_Hake(3)_BLK11repl_1916
            -4            12       3.72208             3          0.05             0      2  # Size_DblN_ascend_se_Hake(3)_BLK11repl_1916
            15            59       37.2195            45          0.05             0      1  # Size_DblN_peak_HnL(5)_BLK5repl_1916
            -4            12       3.74653             3          0.05             0      2  # Size_DblN_ascend_se_HnL(5)_BLK5repl_1916
# info on dev vectors created for selex parms are reported with other devs after tag parameter section 
#
0   #  use 2D_AR1 selectivity? (0/1)
#_no 2D_AR1 selex offset used
#_specs:  fleet, ymin, ymax, amin, amax, sigma_amax, use_rho, len1/age2, devphase, before_range, after_range
#_sigma_amax>amin means create sigma parm for each bin from min to sigma_amax; sigma_amax<0 means just one sigma parm is read and used for all bins
#_needed parameters follow each fleet's specifications
# -9999  0 0 0 0 0 0 0 0 0 0 # terminator
#
# Tag loss and Tag reporting parameters go next
0  # TG_custom:  0=no read and autogen if tag data exist; 1=read
#_Cond -6 6 1 1 2 0.01 -4 0 0 0 0 0 0 0  #_placeholder if no parameters
#
# deviation vectors for timevary parameters
#  base   base first block   block  env  env   dev   dev   dev   dev   dev
#  type  index  parm trend pattern link  var  vectr link _mnyr  mxyr phase  dev_vector
#      3     3     1    10     1     0     0     0     0     0     0     0
#      3     7     2     9     1     0     0     0     0     0     0     0
#      5     1     3     4     2     0     0     0     0     0     0     0
#      5     3     4     4     2     0     0     0     0     0     0     0
#      5     7     5     2     2     0     0     0     0     0     0     0
#      5     8     7     2     2     0     0     0     0     0     0     0
#      5     9     9     1     2     0     0     0     0     0     0     0
#      5    11    12     7     2     0     0     0     0     0     0     0
#      5    13    15     7     2     0     0     0     0     0     0     0
#      5    14    18     7     2     0     0     0     0     0     0     0
#      5    16    21     7     2     0     0     0     0     0     0     0
#      5    19    24    12     2     0     0     0     0     0     0     0
#      5    21    28    11     2     0     0     0     0     0     0     0
#      5    22    29    11     2     0     0     0     0     0     0     0
#      5    23    30    11     2     0     0     0     0     0     0     0
#      5    33    31     5     2     0     0     0     0     0     0     0
#      5    35    32     5     2     0     0     0     0     0     0     0
     #
# Input variance adjustments factors: 
 #_1=add_to_survey_CV
 #_2=add_to_discard_stddev
 #_3=add_to_bodywt_CV
 #_4=mult_by_lencomp_N
 #_5=mult_by_agecomp_N
 #_6=mult_by_size-at-age_N
 #_7=mult_by_generalized_sizecomp
#_factor  fleet  value
      4      1  0.056068
      4      2  0.205432
      4      3  0.128964
      4      4  0.498959
      4      5  0.371622
      4      7  0.372265
      4      8  0.655378
      5      1  0.163806
      5      2  0.273415
      5      3  0.251316
      5      4  0.499302
      5      5  0.546574
      5      8   0.29546
 -9999   1    0  # terminator
#
1 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 13 changes to default Lambdas (default value is 1.0)
# Like_comp codes:  1=surv; 2=disc; 3=mnwt; 4=length; 5=age; 6=SizeFreq; 7=sizeage; 8=catch; 9=init_equ_catch; 
# 10=recrdev; 11=parm_prior; 12=parm_dev; 13=CrashPen; 14=Morphcomp; 15=Tag-comp; 16=Tag-negbin; 17=F_ballpark; 18=initEQregime
#like_comp fleet  phase  value  sizefreq_method
 4 1 1 0.5 1
 4 2 1 0.5 1
 4 3 1 0.5 1
 4 4 1 0.5 1
 4 5 1 0.5 1
 4 7 1 1 1
 4 8 1 1 1
 5 1 1 0.5 1
 5 2 1 0.5 1
 5 3 1 0.5 1
 5 4 1 0.5 1
 5 5 1 0.5 1
 5 8 1 1 1
-9999  1  1  1  1  #  terminator
#
# lambdas (for info only; columns are phases)
#  1 #_CPUE/survey:_1
#  0 #_CPUE/survey:_2
#  1 #_CPUE/survey:_3
#  0 #_CPUE/survey:_4
#  0 #_CPUE/survey:_5
#  1 #_CPUE/survey:_6
#  1 #_CPUE/survey:_7
#  1 #_CPUE/survey:_8
#  1 #_CPUE/survey:_9
#  1 #_discard:_1
#  1 #_discard:_2
#  0 #_discard:_3
#  0 #_discard:_4
#  0 #_discard:_5
#  0 #_discard:_6
#  0 #_discard:_7
#  0 #_discard:_8
#  0 #_discard:_9
#  0.5 #_lencomp:_1
#  0.5 #_lencomp:_2
#  0.5 #_lencomp:_3
#  0.5 #_lencomp:_4
#  0.5 #_lencomp:_5
#  0 #_lencomp:_6
#  1 #_lencomp:_7
#  1 #_lencomp:_8
#  0 #_lencomp:_9
#  0.5 #_agecomp:_1
#  0.5 #_agecomp:_2
#  0.5 #_agecomp:_3
#  0.5 #_agecomp:_4
#  0.5 #_agecomp:_5
#  0 #_agecomp:_6
#  0 #_agecomp:_7
#  1 #_agecomp:_8
#  0 #_agecomp:_9
#  1 #_init_equ_catch1
#  1 #_init_equ_catch2
#  1 #_init_equ_catch3
#  1 #_init_equ_catch4
#  1 #_init_equ_catch5
#  1 #_init_equ_catch6
#  1 #_init_equ_catch7
#  1 #_init_equ_catch8
#  1 #_init_equ_catch9
#  1 #_recruitments
#  1 #_parameter-priors
#  1 #_parameter-dev-vectors
#  1 #_crashPenLambda
#  0 # F_ballpark_lambda
0 # (0/1/2) read specs for more stddev reporting: 0 = skip, 1 = read specs for reporting stdev for selectivity, size, and numbers, 2 = add options for M,Dyn. Bzero, SmryBio
 # 0 2 0 0 # Selectivity: (1) fleet, (2) 1=len/2=age/3=both, (3) year, (4) N selex bins
 # 0 0 # Growth: (1) growth pattern, (2) growth ages
 # 0 0 0 # Numbers-at-age: (1) area(-1 for all), (2) year, (3) N ages
 # -1 # list of bin #'s for selex std (-1 in first bin to self-generate)
 # -1 # list of ages for growth std (-1 in first bin to self-generate)
 # -1 # list of ages for NatAge std (-1 in first bin to self-generate)
999

