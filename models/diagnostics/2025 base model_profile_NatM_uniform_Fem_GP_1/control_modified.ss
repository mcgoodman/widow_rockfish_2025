#V3.30.23.2;_safe;_compile_date:_Apr 17 2025;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:_https://groups.google.com/g/ss3-forum_and_NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:_https://nmfs-ost.github.io/ss3-website/
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-05-29  16:20:58
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
 0.01 0.4 0.244638 0.19 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
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
#  -0.00142583 -0.00160951 -0.0018152 -0.00204495 -0.0023008 -0.00258464 -0.00289803 -0.00324192 -0.00361643 -0.00402097 -0.00445567 -0.00492373 -0.00543194 -0.00598832 -0.00659973 -0.00727344 -0.00801431 -0.0088312 -0.00973073 -0.0107214 -0.0118129 -0.0130154 -0.0143404 -0.0158 -0.0174072 -0.0191775 -0.0211263 -0.0232705 -0.0256292 -0.0282222 -0.0310719 -0.0342024 -0.0376399 -0.0414109 -0.0455469 -0.0500855 -0.0550758 -0.0605838 -0.0666997 -0.0735251 -0.08108 -0.089392 -0.0984855 -0.108122 -0.117993 -0.12808 -0.138098 -0.147601 -0.156696 -0.164961 -0.171656 -0.175751 -0.176076 -0.171164 -0.159592 -0.140196 -0.112999 -0.0807785 -0.0508552 -0.0336418 -0.0350712 -0.0464106 -0.0458671 -0.0151291 0.0382083 0.0960571 0.156606 0.169093 0.12058 -0.0206674 1.38674 1.19633 -0.806605 -0.969296 -0.659431 0.089796 -1.04667 0.694981 1.11535 -0.0310057 0.523549 1.04765 0.428543 0.00908551 0.695125 0.378744 -0.379232 0.557298 0.104506 -0.202848 0.246225 0.845612 -0.133591 0.099118 0.0124493 -0.454556 -0.756011 -0.329124 0.259548 0.539803 0.34828 -0.245865 -0.371023 -0.414 0.76144 -0.899852 0.48052 -0.921416 1.31603 -0.721105 0.877963 -1.04025 -1.46389 0.703359 -0.183041 -0.433761 1.25456 -0.0255368 -1.00651 -1.26755 -1.21045 -0.475913 -0.411016 -0.0361982 -0.18875 0 0 0 0 0 0 0 0 0 0 0 0
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
# BottomTrawl 4.8275e-05 7.50425e-05 8.76066e-05 6.09215e-05 6.22248e-05 5.14811e-05 4.43153e-05 4.8105e-05 2.8382e-05 2.40046e-05 6.81375e-05 9.22457e-05 0.000130547 0.000183896 0.000163914 0.000160891 0.000174843 0.000273181 0.000243129 0.000236113 0.000200028 0.000285759 0.000265425 0.000333268 0.000602998 0.000751688 0.00107447 0.00378872 0.00749234 0.012755 0.00907262 0.0046417 0.0037035 0.00281258 0.00308132 0.00434858 0.00435342 0.00398622 0.00375977 0.0039669 0.00500536 0.00653038 0.00606567 0.00591266 0.00730548 0.00616563 0.00693025 0.0038655 0.00547375 0.00221057 0.00532045 0.00833612 0.00398314 0.0045453 0.00274892 0.00355265 0.0044072 0.00435994 0.00390194 0.00378435 0.00428779 0.00653833 0.00826588 0.021458 0.0438541 0.0435167 0.0674053 0.114797 0.0569947 0.0451719 0.0611284 0.0684625 0.0690158 0.079504 0.125315 0.098619 0.111422 0.150262 0.108848 0.12171 0.109249 0.113285 0.0990286 0.0631708 0.00224579 0.0015842 0.000736249 0.000143783 0.000308536 0.000105988 0.000188122 0.000141851 6.05283e-05 0.000112981 0.000122223 0.000239991 0.000514566 0.000603518 0.000786937 0.000126872 9.61459e-05 0.000351191 0.000363568 0.000304797 0.00085671 0.00125003 0.00160218 0.00111858 0.000413281 0.00128753 0.00141116 0.000676023 0.000665399 0.000661898 0.00066284 0.000665228 0.000668788 0.000671765 0.000673089 0.000672289 0.000669301
# MidwaterTrawl 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0509115 0.148263 0.268023 0.322435 0.0832263 0.149696 0.132127 0.1132 0.163674 0.126841 0.166014 0.102483 0.0519007 0.0383673 0.0603313 0.0623492 0.0685027 0.0562107 0.0719613 0.0261019 0.0608748 0.11231 0.054468 0.00694986 0.000254414 0.000687372 0.000702202 0.000252161 2.89737e-05 0.000769988 0.000643666 0.000919872 0.000749835 0.000781514 0.0036925 0.0042698 0.00619402 0.00734444 0.0618787 0.128949 0.123808 0.123154 0.167153 0.176821 0.176456 0.180981 0.231879 0.267104 0.106363 0.104691 0.104141 0.104289 0.104664 0.105224 0.105693 0.105901 0.105775 0.105305
# Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0379008 0.0413737 0.0213577 0.00392711 0.00600368 0.00748605 0.00442828 0.00677566 0.00424004 0.00383633 0.00662149 0.00101798 0.00153136 0.00153131 0.0022207 0.00222668 0.00203806 0.00231144 0.00555025 0.00349765 0.00483089 0.00332471 0.00435898 0.00403741 0.00470083 0.012369 0.0100823 0.00626842 0.014976 0.0118303 0.022223 0.0100631 0.0163719 0.0100384 0.00742082 0.00559739 0.00399231 0.000642313 0.00109656 0.00321036 0.00359115 0.00393308 0.0035509 0.00211372 0.00159321 0.0021501 0.00250293 0.00232236 0.00424385 0.00448607 0.00482991 0.0153576 0.0117551 0.0129929 0.00754193 0.00618341 0.0115023 0.00762294 0.00692993 0.0117608 0.0131959 0.0051314 0.00505075 0.00502418 0.00503133 0.00504945 0.00507648 0.00509907 0.00510912 0.00510305 0.00508037
# Net 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000152524 0.000498005 0.0050118 0.00626221 0.0115019 0.00966966 0.0110021 0.00425448 0.00493805 0.00857931 0.00527476 0.00103527 0.00119713 0.00145783 0.00149625 0.000437798 0.000445644 0.00132808 0.000266187 0.000176867 0.000182645 5.05718e-07 9.85571e-06 0 2.68976e-06 0 5.08265e-05 0 3.31971e-06 0 0 0 0 3.78092e-07 0 0 0 0 0 2.33141e-08 0 7.91137e-07 0 0 3.38329e-12 3.38329e-12 1.05062e-07 1.0341e-07 1.02867e-07 1.03013e-07 1.03384e-07 1.03937e-07 1.044e-07 1.04606e-07 1.04481e-07 1.04017e-07
# HnL 0.000524691 0.000817196 0.000939238 0.000648837 0.0006648 0.000551826 0.000479797 0.00052785 0.000341706 0.000433756 0.000630589 0.000490584 0.000535055 0.000466453 0.000674365 0.000586465 0.000575716 0.000379666 0.000446035 0.00050703 0.000635112 0.000503475 0.000377177 0.000260829 0.000339943 0.000270039 0.000100013 0.000165702 0.000299576 0.000521785 0.000553117 0.000724705 0.000324053 0.000355165 0.000514573 0.000401089 0.000328767 0.000115018 0.000179327 0.000155217 0.000352575 0.000321155 0.0003136 0.000247951 0.000190991 0.00013419 0.000137469 0.000173428 0.000113333 0.00017843 0.000322449 0.000288145 0.000179385 0.000178652 8.6785e-05 0.000104052 0.000171202 0.000152181 0.000356799 0.000222298 0.000281787 0.00026122 0.00102445 0.000671718 0.000420588 0.000601712 0.0019637 0.000430509 0.000341816 0.000347336 0.00103151 0.00066884 0.000937398 0.000594386 0.00191349 0.00147139 0.00276922 0.00175708 0.00141938 0.000468389 0.000584306 0.000673945 0.00157419 0.000805618 0.000274569 0.000141841 1.10587e-05 1.19114e-05 4.1657e-06 1.5595e-05 1.08918e-05 2.25904e-05 1.39546e-05 4.39855e-06 1.55901e-06 1.15632e-06 2.9484e-06 8.22829e-06 1.47664e-05 1.63016e-05 6.46533e-06 2.06512e-05 1.2164e-05 1.76423e-05 2.31847e-05 3.9842e-05 8.35918e-05 7.66144e-05 0.000159104 0.000602269 0.000685416 4.93187e-05 4.85436e-05 4.82882e-05 4.83569e-05 4.85311e-05 4.87909e-05 4.9008e-05 4.91046e-05 4.90463e-05 4.88283e-05
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
         8         1         0         1         0         1  #  WCGBTS
         9         1         0         1         0         1  #  ForeignAtSea
-9999 0 0 0 0 0
#
#_Q_parameters
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
           -25            25      -5.99524             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_BottomTrawl(1)
             0             2      0.164307             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_BottomTrawl(1)
           -20             2      -11.1167             0            99             0          1          0          0          0          0          0         10          1  #  LnQ_base_Hake(3)
             0             2       0.37122             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Hake(3)
           -25            25      -1.63652             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_JuvSurvey(6)
             0             2       1.68806             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_JuvSurvey(6)
            -4             4      -2.05842             0            99             0          2          0          0          0          0          0          9          1  #  LnQ_base_Triennial(7)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(7)
           -25            25      -3.14075             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_WCGBTS(8)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_WCGBTS(8)
           -25            25      -11.4354             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_ForeignAtSea(9)
             0             2      0.577966             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_ForeignAtSea(9)
# timevary Q parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type     PHASE  #  parm_name
        0.0001             2      0.465312           0.5           0.5             6      3  # LnQ_base_Hake(3)_BLK10add_1991
        0.0001             2       0.15851           0.5           0.5             6      3  # LnQ_base_Triennial(7)_BLK9add_1995
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
 27 0 0 3 # 8 WCGBTS
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
 11 0 0 0 # 8 WCGBTS
 10 0 0 0 # 9 ForeignAtSea
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   BottomTrawl LenSelex
            10            59       43.3984            45          0.05             0          1          0          0          0          0        0.5          4          2  #  Size_DblN_peak_BottomTrawl(1)
            -5            10       2.49984             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_BottomTrawl(1)
            -4            12       4.59264             3          0.05             0          2          0          0          0          0        0.5          4          2  #  Size_DblN_ascend_se_BottomTrawl(1)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_BottomTrawl(1)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_BottomTrawl(1)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_BottomTrawl(1)
            -5            60       3.64069             0            99             0          4          0          0          0          0          0          2          2  #  Retain_L_infl_BottomTrawl(1)
          0.01             8      0.951083             1            99             0          4          0          0          0          0          0          2          2  #  Retain_L_width_BottomTrawl(1)
           -10            10       4.59512            10            99             0         -2          0          0          0          0          0          1          2  #  Retain_L_asymptote_logit_BottomTrawl(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_BottomTrawl(1)
# 2   MidwaterTrawl LenSelex
            10            59       36.9648            45          0.05             0          1          0          0          0          0        0.5          7          2  #  Size_DblN_peak_MidwaterTrawl(2)
           -10            10      -9.42035             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_MidwaterTrawl(2)
            -4            12       2.86574             3          0.05             0          2          0          0          0          0        0.5          7          2  #  Size_DblN_ascend_se_MidwaterTrawl(2)
            -2            10       3.93474            10          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_descend_se_MidwaterTrawl(2)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_MidwaterTrawl(2)
            -9             9      -1.38521           0.5          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_end_logit_MidwaterTrawl(2)
            -5            60            -5             0            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_infl_MidwaterTrawl(2)
          0.01             8           1.2             1            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_width_MidwaterTrawl(2)
           -10            10       5.76562            10            99             0          2          0          0          0          0          0         12          2  #  Retain_L_asymptote_logit_MidwaterTrawl(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_MidwaterTrawl(2)
# 3   Hake LenSelex
            10            59       33.5575            45          0.05             0          1          0          0          0          0        0.5         11          2  #  Size_DblN_peak_Hake(3)
            -5            10       2.49799             5          0.05             0          3          0          0          0          0        0.5         11          2  #  Size_DblN_top_logit_Hake(3)
            -4            12       2.11549             3          0.05             0          2          0          0          0          0        0.5         11          2  #  Size_DblN_ascend_se_Hake(3)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Hake(3)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Hake(3)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Hake(3)
# 4   Net LenSelex
            10            59       42.6002            45          0.05             0          1          0          0          0          0        0.5          0          0  #  Size_DblN_peak_Net(4)
            -5            10       2.50849             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_Net(4)
            -4            12        3.5559             3          0.05             0          2          0          0          0          0        0.5          0          0  #  Size_DblN_ascend_se_Net(4)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Net(4)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Net(4)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Net(4)
# 5   HnL LenSelex
            10            59       23.5538            45          0.05             0          5          0          0          0          0        0.5          5          2  #  Size_DblN_peak_HnL(5)
            -5            10       2.50211             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_HnL(5)
            -5            12            -5             3          0.05             0         -2          0          0          0          0        0.5          5          2  #  Size_DblN_ascend_se_HnL(5)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_HnL(5)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_HnL(5)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_HnL(5)
# 6   JuvSurvey LenSelex
# 7   Triennial LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_Triennial(7)
        -0.001             1      0.118854             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_Triennial(7)
            -1             1     0.0381031             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_Triennial(7)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_Triennial(7)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_Triennial(7)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_Triennial(7)
           -10            10      -1.82423           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_Triennial(7)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_Triennial(7)
           -10            10       0.43537           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_Triennial(7)
# 8   WCGBTS LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_WCGBTS(8)
        -0.001             1      0.467134             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_WCGBTS(8)
            -1             1     -0.109047             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_WCGBTS(8)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_WCGBTS(8)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_WCGBTS(8)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_WCGBTS(8)
           -10            10      -2.22354           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_WCGBTS(8)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_WCGBTS(8)
           -10            10     -0.114491           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_WCGBTS(8)
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
# 8   WCGBTS AgeSelex
             0             1             0             0            99             0        -99          0          0          0          0        0.5          0          0  #  minage@sel=1_WCGBTS(8)
             0            50            40             0            99             0        -99          0          0          0          0        0.5          0          0  #  maxage@sel=1_WCGBTS(8)
# 9   ForeignAtSea AgeSelex
#_No_Dirichlet parameters
# timevary selex parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type    PHASE  #  parm_name
            10            59       38.9802            45          0.05             0      1  # Size_DblN_peak_BottomTrawl(1)_BLK4repl_1916
            -4            12       3.42758             3          0.05             0      2  # Size_DblN_ascend_se_BottomTrawl(1)_BLK4repl_1916
            -5            50       27.2211            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1982
            -5            50       27.5208            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1990
          0.01             5      0.968861             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1982
          0.01             5       1.83062             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1990
           -10            10       1.71885            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1982
           -10            10      0.782736            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1990
           -10            10      0.107811            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1998
            10            59       38.6834            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1916
            10            59       38.0162            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1983
            10            59       37.3982            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_2002
            -4            12       3.37013             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1916
            -4            12       3.08059             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1983
            -4            12       2.79634             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_2002
            -2            10       4.24163            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1916
            -2            10       3.05552            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1983
            -2            10      -1.41664            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_2002
            -9             9      -1.93351           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1916
            -9             9     -0.423944           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1983
            -9             9       1.56281           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_2002
           -10            10        4.5912            10            99             0      -2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1916
           -10            10       1.66015            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1983
           -10            10        1.8538            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2002
           -10            10       8.94664            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2011
            10            59       42.7924            45          0.05             0      1  # Size_DblN_peak_Hake(3)_BLK11repl_1916
            -5            10       2.50432             5          0.05             0      3  # Size_DblN_top_logit_Hake(3)_BLK11repl_1916
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

