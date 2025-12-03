#V3.30.23.1;_safe;_compile_date:_Dec  5 2024;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-11-26  15:08:06
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
 1 1 1 1 1 1 3 1 1 1 1 1 #_blocks_per_pattern 
# begin and end years of blocks
 1916 1916
 1916 1916
 1916 1916
 1916 2001
 1916 1916
 1916 1916
 1916 1982 1983 2001 2002 2016
 1916 1916
 1995 2004
 1991 1998
 1916 2019
 1916 1916
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
2 #_fecundity_at_length option:(1)eggs=Wt*(a+b*Wt);(2)eggs=a*L^b;(3)eggs=a*Wt^b; (4)eggs=a+b*L; (5)eggs=a+b*W
0 #_hermaphroditism option:  0=none; 1=female-to-male age-specific fxn; -1=male-to-female age-specific fxn
1 #_parameter_offset_approach for M, G, CV_G:  1- direct, no offset**; 2- male=fem_parm*exp(male_parm); 3: male=female*exp(parm) then old=young*exp(parm)
#_** in option 1, any male parameter with value = 0.0 and phase <0 is set equal to female parameter
#
#_growth_parms
#_ LO HI INIT PRIOR PR_SD PR_type PHASE env_var&link dev_link dev_minyr dev_maxyr dev_PH Block Block_Fxn
# Sex: 1  BioPattern: 1  NatMort
 0.01 0.3 0.134991 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 10 40 18.8917 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 35 60 49.4312 50 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.01 0.4 0.193788 0.15 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.01 0.4 0.142274 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.4 0.0471367 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 -3 3 1.5885e-05 0 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 -3 10 2.98734 2.962 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 -3 50 5.47 7 99 0 -99 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.7747 -1 99 0 -99 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 -1 1 1.10961e-08 1 99 0 -99 0 0 0 0 0 0 0 # Eggs_scalar_Fem_GP_1
 0 5 4.545 0 99 0 -99 0 0 0 0 0 0 0 # Eggs_exp_len_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.01 0.3 0.14698 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 10 40 20.3211 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 35 60 43.6451 45 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.01 0.4 0.266605 0.19 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.01 0.4 0.091484 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.4 0.0548446 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
# Sex: 2  BioPattern: 1  WtLen
 -3 3 1.45067e-05 0 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Mal_GP_1
 -3 10 3.01229 3.005 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Mal_GP_1
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
             6            15       10.6083            10            99             0          1          0          0          0          0          0          0          0 # SR_LN(R0)
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
 1962.68 #_last_yr_nobias_adj_in_MPD; begin of ramp
 1970 #_first_yr_fullbias_adj_in_MPD; begin of plateau
 2016.27 #_last_yr_fullbias_adj_in_MPD
 2022.7 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.8639 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
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
#  -0.00131367 -0.00149337 -0.00169511 -0.00192074 -0.00217193 -0.0024501 -0.00275623 -0.00309073 -0.00345354 -0.00384476 -0.00426625 -0.00472316 -0.00522313 -0.00577382 -0.00638189 -0.00705377 -0.00779498 -0.00861435 -0.00951921 -0.0105186 -0.0116231 -0.0128431 -0.014191 -0.0156797 -0.0173236 -0.0191391 -0.0211429 -0.0233534 -0.025792 -0.0284809 -0.0314453 -0.0347117 -0.0383102 -0.0422733 -0.0466402 -0.051458 -0.0567878 -0.0627116 -0.0693389 -0.0767956 -0.085065 -0.094197 -0.104256 -0.115002 -0.125782 -0.136823 -0.147853 -0.158552 -0.168843 -0.178099 -0.185314 -0.189158 -0.187752 -0.179047 -0.160892 -0.131375 -0.0904216 -0.0429971 -0.00283342 0.0117952 -0.00447802 -0.0304083 -0.0321497 0.0125331 0.0818992 0.136996 0.190614 0.199439 0.191744 -0.026469 1.36544 1.22445 -0.832618 -0.929182 -0.58432 0.158315 -1.18362 0.672856 1.01826 -0.0251775 0.451014 1.02606 0.409485 -0.190178 0.450098 0.283411 -0.626219 0.204714 -0.158436 -0.390766 -0.00758821 0.652403 -0.229672 0.100962 -0.0207972 -0.406974 -0.607908 -0.149037 0.462009 0.523853 0.585413 -0.353898 -0.330339 -0.273335 0.754483 -1.03184 0.689458 -1.15078 1.13207 -0.758768 0.561311 -0.941417 -1.28674 0.413718 -0.0184371 -0.412103 1.33125 0.338797 -0.68996 -0.773727 -0.446004 0.0226779 0.00381986 0.248298 0.135625 0 0 0 0 0 0 0 0 0 0 0 0
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
# BottomTrawl 0.000595362 0.000927115 0.00106758 0.000737951 0.000755835 0.000627033 0.000544842 0.000599224 0.000385765 0.000478363 0.000727665 0.000604638 0.000688941 0.000670971 0.000869987 0.000770781 0.000772857 0.00066645 0.000704858 0.000759558 0.000851005 0.000799756 0.000645874 0.000593268 0.000943797 0.00101516 0.00114214 0.00390009 0.00767461 0.0131265 0.00952517 0.00534589 0.00401846 0.00316108 0.00362832 0.00474401 0.00471691 0.00408455 0.00392844 0.00410595 0.00537734 0.00685355 0.00640537 0.00619363 0.00750412 0.00630842 0.00706456 0.00407617 0.00553281 0.00241496 0.0380063 0.0435922 0.0221564 0.00784763 0.00776259 0.00977312 0.00809172 0.0100188 0.00767031 0.0068291 0.00887541 0.00714487 0.00939613 0.0124956 0.0211289 0.0435919 0.0713666 0.132979 0.0696608 0.061005 0.079382 0.086912 0.0827953 0.0950414 0.145132 0.115286 0.128229 0.174951 0.132343 0.150318 0.138636 0.144555 0.101262 0.0610049 0.00279155 0.00192695 0.000556982 0.00015367 0.000310439 0.000169836 0.000170461 0.000530507 0.000122797 0.000379652 0.000343996 0.000293682 0.000579382 0.000673008 0.000950147 0.00015472 0.000116173 0.000400668 0.000422303 0.000365564 0.000987573 0.00144071 0.00183107 0.00122659 0.000586196 0.001858 0.00198081 0.000786309 0.000782104 0.00077874 0.000775376 0.000771171 0.000767807 0.000764443 0.000760239 0.000756875 0.000753511
# MidwaterTrawl 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 7.92748e-08 0 0 0 0 0 0 0 0 0 0 0 0 0 0 2.08749e-05 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.063517 0.1761 0.26964 0.399443 0.104591 0.180488 0.157144 0.137754 0.194163 0.150527 0.203726 0.121607 0.0628873 0.0479826 0.0784772 0.0837861 0.0956451 0.0821797 0.100845 0.0366647 0.080886 0.144364 0.0696357 0.00691754 0.000353868 0.000813877 0.000879302 0.000795879 0.000376086 0.00122039 0.00142075 0.00101311 0.000799648 0.0007955 0.00322615 0.00371143 0.00512239 0.00614841 0.0650993 0.138257 0.1341 0.1335 0.174505 0.173558 0.162614 0.158307 0.191793 0.202975 0.103917 0.103361 0.102917 0.102472 0.101917 0.101472 0.101027 0.100472 0.100027 0.0995826
# Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000278025 0.00110323 0.000955862 0.00143078 0.00143601 0.00209303 0.00211413 0.0019387 0.00234123 0.0055689 0.00347458 0.00479952 0.00328653 0.00426707 0.00400325 0.00483205 0.012869 0.0107853 0.00671703 0.0165632 0.0131902 0.0243834 0.0120499 0.0199386 0.0119005 0.00876847 0.00638727 0.00463703 0.000609319 0.00120172 0.00307869 0.00296643 0.00328835 0.002887 0.00207045 0.00129895 0.0018128 0.00218155 0.00185644 0.003653 0.00433035 0.00473677 0.0153762 0.0120733 0.0136813 0.00831168 0.00663925 0.0117694 0.00745057 0.00650042 0.0105004 0.0109763 0.00526671 0.00523855 0.00521601 0.00519348 0.00516532 0.00514279 0.00512026 0.00509209 0.00506956 0.00504703
# ignore1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
# ignore2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0
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
           -25            25      -6.17025             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_BottomTrawl(1)
             0             2       0.20376             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_BottomTrawl(1)
           -20             2      -11.1032             0            99             0          1          0          0          0          0          0         10          1  #  LnQ_base_Hake(3)
             0             2      0.385593             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Hake(3)
           -25            25      -5.03664             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_JuvSurvey(6)
             0             2       1.27231             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_JuvSurvey(6)
            -4             4      -1.88416             0            99             0          2          0          0          0          0          0          9          1  #  LnQ_base_Triennial(7)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(7)
           -25            25      -3.33928             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_WCGBTS(8)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_WCGBTS(8)
           -25            25      -11.4715             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_ForeignAtSea(9)
             0             2      0.595158             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_ForeignAtSea(9)
# timevary Q parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type     PHASE  #  parm_name
        0.0001             2      0.600114           0.5           0.5             6      3  # LnQ_base_Hake(3)_BLK10add_1991
        0.0001             2      0.248656           0.5           0.5             6      3  # LnQ_base_Triennial(7)_BLK9add_1995
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
 24 0 0 0 # 1 BottomTrawl
 24 0 0 0 # 2 MidwaterTrawl
 24 0 0 0 # 3 Hake
 0 0 0 0 # 4 ignore1
 0 0 0 0 # 5 ignore2
 0 0 0 0 # 6 JuvSurvey
 27 0 0 3 # 7 Triennial
 27 0 0 3 # 8 WCGBTS
 15 0 0 3 # 9 ForeignAtSea
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
 10 0 0 0 # 4 ignore1
 10 0 0 0 # 5 ignore2
 11 0 0 0 # 6 JuvSurvey
 10 0 0 0 # 7 Triennial
 11 0 0 0 # 8 WCGBTS
 10 0 0 0 # 9 ForeignAtSea
#
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type      PHASE    env-var    use_dev   dev_mnyr   dev_mxyr     dev_PH      Block    Blk_Fxn  #  parm_name
# 1   BottomTrawl LenSelex
            10            59       42.0806            45          0.05             0          1          0          0          0          0        0.5          4          2  #  Size_DblN_peak_BottomTrawl(1)
            -5            10           2.5             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_BottomTrawl(1)
            -4            12       4.06109             3          0.05             0          2          0          0          0          0        0.5          4          2  #  Size_DblN_ascend_se_BottomTrawl(1)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_BottomTrawl(1)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_BottomTrawl(1)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_BottomTrawl(1)
# 2   MidwaterTrawl LenSelex
            10            59       37.0971            45          0.05             0          1          0          0          0          0        0.5          7          2  #  Size_DblN_peak_MidwaterTrawl(2)
           -10            10      -9.24608             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_MidwaterTrawl(2)
            -4            12       2.79801             3          0.05             0          2          0          0          0          0        0.5          7          2  #  Size_DblN_ascend_se_MidwaterTrawl(2)
            -2            10       3.94028            10          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_descend_se_MidwaterTrawl(2)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_MidwaterTrawl(2)
            -9             9      -1.16681           0.5          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_end_logit_MidwaterTrawl(2)
# 3   Hake LenSelex
            10            59       34.4773            45          0.05             0          1          0          0          0          0        0.5         11          2  #  Size_DblN_peak_Hake(3)
            -5            10       2.49977             5          0.05             0          3          0          0          0          0        0.5         11          2  #  Size_DblN_top_logit_Hake(3)
            -4            12        2.5147             3          0.05             0          2          0          0          0          0        0.5         11          2  #  Size_DblN_ascend_se_Hake(3)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Hake(3)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Hake(3)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Hake(3)
# 4   ignore1 LenSelex
# 5   ignore2 LenSelex
# 6   JuvSurvey LenSelex
# 7   Triennial LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_Triennial(7)
        -0.001             1       0.12723             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_Triennial(7)
            -1             1     0.0940298             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_Triennial(7)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_Triennial(7)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_Triennial(7)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_Triennial(7)
           -10            10      -2.16648           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_Triennial(7)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_Triennial(7)
           -10            10      0.435261           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_Triennial(7)
# 8   WCGBTS LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_WCGBTS(8)
        -0.001             1      0.447439             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_WCGBTS(8)
            -1             1    -0.0980434             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_WCGBTS(8)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_WCGBTS(8)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_WCGBTS(8)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_WCGBTS(8)
           -10            10      -2.19075           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_WCGBTS(8)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_WCGBTS(8)
           -10            10     0.0499914           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_WCGBTS(8)
# 9   ForeignAtSea LenSelex
# 1   BottomTrawl AgeSelex
# 2   MidwaterTrawl AgeSelex
# 3   Hake AgeSelex
# 4   ignore1 AgeSelex
# 5   ignore2 AgeSelex
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
            10            59       39.4459            45          0.05             0      1  # Size_DblN_peak_BottomTrawl(1)_BLK4repl_1916
            -4            12       3.46623             3          0.05             0      2  # Size_DblN_ascend_se_BottomTrawl(1)_BLK4repl_1916
            10            59       38.5647            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1916
            10            59       38.1825            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1983
            10            59       37.8054            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_2002
            -4            12       3.39467             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1916
            -4            12       2.98524             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1983
            -4            12       2.95895             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_2002
            -2            10       4.10674            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1916
            -2            10       2.57325            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1983
            -2            10      -1.82157            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_2002
            -9             9      -1.67412           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1916
            -9             9     -0.608612           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1983
            -9             9       1.99565           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_2002
            10            59       41.3675            45          0.05             0      1  # Size_DblN_peak_Hake(3)_BLK11repl_1916
            -5            10       2.50093             5          0.05             0      3  # Size_DblN_top_logit_Hake(3)_BLK11repl_1916
            -4            12        3.3549             3          0.05             0      2  # Size_DblN_ascend_se_Hake(3)_BLK11repl_1916
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
#      5     7     5     7     2     0     0     0     0     0     0     0
#      5     9     8     7     2     0     0     0     0     0     0     0
#      5    10    11     7     2     0     0     0     0     0     0     0
#      5    12    14     7     2     0     0     0     0     0     0     0
#      5    13    17    11     2     0     0     0     0     0     0     0
#      5    14    18    11     2     0     0     0     0     0     0     0
#      5    15    19    11     2     0     0     0     0     0     0     0
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
      4      1  0.054758
      4      2  0.039395
      4      3  0.022304
      4      7  0.091614
      4      8  0.083012
      5      1  0.194286
      5      2  0.150503
      5      3  0.261565
      5      8  0.106416
 -9999   1    0  # terminator
#
1 #_maxlambdaphase
1 #_sd_offset; must be 1 if any growthCV, sigmaR, or survey extraSD is an estimated parameter
# read 9 changes to default Lambdas (default value is 1.0)
# Like_comp codes:  1=surv; 2=disc; 3=mnwt; 4=length; 5=age; 6=SizeFreq; 7=sizeage; 8=catch; 9=init_equ_catch; 
# 10=recrdev; 11=parm_prior; 12=parm_dev; 13=CrashPen; 14=Morphcomp; 15=Tag-comp; 16=Tag-negbin; 17=F_ballpark; 18=initEQregime
#like_comp fleet  phase  value  sizefreq_method
 4 1 1 1 1
 4 2 1 1 1
 4 3 1 1 1
 4 7 1 1 1
 4 8 1 1 1
 5 1 1 1 1
 5 2 1 1 1
 5 3 1 1 1
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
#  1 #_lencomp:_1
#  1 #_lencomp:_2
#  1 #_lencomp:_3
#  0 #_lencomp:_4
#  0 #_lencomp:_5
#  0 #_lencomp:_6
#  1 #_lencomp:_7
#  1 #_lencomp:_8
#  0 #_lencomp:_9
#  1 #_agecomp:_1
#  1 #_agecomp:_2
#  1 #_agecomp:_3
#  0 #_agecomp:_4
#  0 #_agecomp:_5
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

