#V3.30.23.1;_safe;_compile_date:_Dec  5 2024;_Stock_Synthesis_by_Richard_Methot_(NOAA)_using_ADMB_13.2
#_Stock_Synthesis_is_a_work_of_the_U.S._Government_and_is_not_subject_to_copyright_protection_in_the_United_States.
#_Foreign_copyrights_may_apply._See_copyright.txt_for_more_information.
#_User_support_available_at:NMFS.Stock.Synthesis@noaa.gov
#_User_info_available_at:https://vlab.noaa.gov/group/stock-synthesis
#_Source_code_at:_https://github.com/nmfs-ost/ss3-source-code

#C file created using an r4ss function
#C file write time: 2025-06-11  18:05:55
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
 0.01 0.3 0.122306 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Fem_GP_1
# Sex: 1  BioPattern: 1  Growth
 10 40 20.6577 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Fem_GP_1
 35 60 49.4919 50 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Fem_GP_1
 0.01 0.4 0.181125 0.15 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Fem_GP_1
 0.01 0.4 0.115621 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Fem_GP_1
 0.01 0.4 0.0480224 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Fem_GP_1
# Sex: 1  BioPattern: 1  WtLen
 -3 3 1.5885e-05 0 99 0 -99 0 0 0 0 0 0 0 # Wtlen_1_Fem_GP_1
 -3 10 2.98734 2.962 99 0 -99 0 0 0 0 0 0 0 # Wtlen_2_Fem_GP_1
# Sex: 1  BioPattern: 1  Maturity&Fecundity
 -3 50 5.47 7 99 0 -99 0 0 0 0 0 0 0 # Mat50%_Fem_GP_1
 -3 3 -0.7747 -1 99 0 -99 0 0 0 0 0 0 0 # Mat_slope_Fem_GP_1
 -1 1 1 1 99 0 -99 0 0 0 0 0 0 0 # Eggs/kg_inter_Fem_GP_1
 0 1 0 0 99 0 -99 0 0 0 0 0 0 0 # Eggs/kg_slope_wt_Fem_GP_1
# Sex: 2  BioPattern: 1  NatMort
 0.01 0.3 0.134775 -2.3 0.31 3 5 0 0 0 0 0 0 0 # NatM_uniform_Mal_GP_1
# Sex: 2  BioPattern: 1  Growth
 10 40 21.0185 27 99 0 3 0 0 0 0 0 0 0 # L_at_Amin_Mal_GP_1
 35 60 43.6083 45 99 0 2 0 0 0 0 0 0 0 # L_at_Amax_Mal_GP_1
 0.01 0.4 0.245195 0.19 99 0 2 0 0 0 0 0 0 0 # VonBert_K_Mal_GP_1
 0.01 0.4 0.094698 0.07 99 0 3 0 0 0 0 0 0 0 # CV_young_Mal_GP_1
 0.01 0.4 0.0562736 0.04 99 0 3 0 0 0 0 0 0 0 # CV_old_Mal_GP_1
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
             1            20       10.4573            10            99             0          2          0          0          0          0          0          0          0 # SR_LN(R0)
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
 1960.51 #_last_yr_nobias_adj_in_MPD; begin of ramp
 1977 #_first_yr_fullbias_adj_in_MPD; begin of plateau
 2016.33 #_last_yr_fullbias_adj_in_MPD
 2024.88 #_end_yr_for_ramp_in_MPD (can be in forecast to shape ramp, but SS3 sets bias_adj to 0.0 for fcast yrs)
 0.8577 #_max_bias_adj_in_MPD (typical ~0.8; -3 sets all years to 0.0; -2 sets all non-forecast yrs w/ estimated recdevs to 1.0; -1 sets biasadj=1.0 for all yrs w/ recdevs)
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
#  -0.00191883 -0.00216087 -0.0024255 -0.00272904 -0.00307128 -0.00344139 -0.00384512 -0.00429111 -0.00477289 -0.00529927 -0.00586529 -0.00646922 -0.00712905 -0.00784832 -0.00863056 -0.00949917 -0.0104436 -0.0114957 -0.0126387 -0.0139103 -0.0152987 -0.0168268 -0.0185117 -0.0203588 -0.0223944 -0.02463 -0.0270862 -0.0297825 -0.0327401 -0.0359839 -0.0395356 -0.0434238 -0.0476744 -0.0523167 -0.0573884 -0.0629293 -0.0689992 -0.0756755 -0.0830629 -0.0912716 -0.10031 -0.110183 -0.120893 -0.13218 -0.14375 -0.155607 -0.167439 -0.178767 -0.18969 -0.199797 -0.20838 -0.21443 -0.216787 -0.214023 -0.204808 -0.188083 -0.163918 -0.135048 -0.108369 -0.0933277 -0.0948927 -0.103939 -0.0997477 -0.0660981 -0.0107596 0.0489324 0.110521 0.12447 0.0810049 -0.0480379 1.33903 1.16116 -0.842835 -1.00837 -0.700397 0.0430005 -1.08771 0.660455 1.08145 -0.0648057 0.493119 1.01737 0.399804 -0.0195201 0.665561 0.354246 -0.402391 0.532845 0.077494 -0.224983 0.223559 0.827769 -0.146358 0.0869443 -0.00148804 -0.453459 -0.74297 -0.310127 0.275946 0.564225 0.364902 -0.227741 -0.343434 -0.397564 0.777689 -0.888843 0.502246 -0.996225 1.34942 -0.736422 0.919653 -1.0437 -1.4349 0.744321 -0.12254 -0.393338 1.32978 0.0358843 -0.96494 -1.13132 -1.14149 -0.29496 -0.148403 0.290514 0.134753 0 0 0 0 0 0 0 0 0 0 0 0
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
# BottomTrawl 4.5954e-05 7.14388e-05 8.34044e-05 5.80029e-05 5.92486e-05 4.90233e-05 4.22042e-05 4.5819e-05 2.70369e-05 2.28705e-05 6.49289e-05 8.79166e-05 0.000124444 0.000175334 0.000156318 0.000153471 0.000166824 0.000260727 0.000232118 0.000225498 0.000191107 0.000273124 0.0002538 0.000318825 0.000577167 0.000719883 0.00102962 0.00363285 0.00718833 0.0122439 0.00871283 0.0044606 0.00356223 0.00270807 0.00297015 0.00419659 0.00420629 0.00385636 0.00364216 0.00384821 0.0048627 0.00635384 0.00591093 0.00577154 0.00714412 0.00604128 0.00680531 0.00380485 0.00540182 0.0021873 0.00527847 0.00829162 0.00397312 0.00454765 0.00275829 0.00357374 0.00444222 0.00440019 0.00394052 0.00382403 0.00433458 0.00660666 0.00834128 0.0119894 0.0212944 0.0438123 0.0680162 0.116095 0.0576689 0.0456967 0.0618 0.0691608 0.0696842 0.0802261 0.127032 0.100006 0.112931 0.152225 0.110279 0.123249 0.110573 0.114517 0.0994609 0.0632826 0.00224338 0.00157715 0.000732469 0.000142434 0.000304284 0.000104068 0.000183943 0.000138162 5.87479e-05 0.000109329 0.000117969 0.000230876 0.000494046 0.000578304 0.000752321 0.000120957 9.13828e-05 0.000332709 0.000342387 0.000284467 0.000792045 0.0011444 0.00144809 0.000995124 0.000361037 0.000515661 0.000594517 0.000378293 0.00037627 0.000374651 0.000373033 0.00037101 0.000369392 0.000367773 0.00036575 0.000364132 0.000362514
# MidwaterTrawl 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.063345 0.178599 0.270176 0.325219 0.0839405 0.150992 0.133202 0.114012 0.164661 0.127512 0.166778 0.102946 0.0521464 0.0385238 0.0605412 0.0625659 0.0687078 0.056349 0.0720416 0.0260821 0.0606643 0.111582 0.0539121 0.00681891 0.000248505 0.000668262 0.000679545 0.000243021 2.78191e-05 0.000736809 0.000614279 0.000875998 0.000712648 0.000741827 0.00349962 0.00403721 0.00583875 0.00689941 0.0579283 0.119937 0.114029 0.112299 0.150817 0.157467 0.154682 0.155643 0.186951 0.226878 0.0986978 0.09817 0.0977478 0.0973256 0.0967978 0.0963755 0.0959533 0.0954255 0.0950033 0.094581
# Hake 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.0373935 0.0409208 0.0211806 0.00390606 0.00598937 0.00748914 0.00444091 0.00680772 0.00426554 0.00386254 0.00666944 0.0010252 0.00154114 0.00153952 0.00223094 0.00223738 0.00204994 0.00232944 0.00559522 0.00352536 0.00486643 0.00334647 0.00438533 0.0040592 0.00472586 0.0124413 0.0101375 0.00629993 0.0150531 0.0118864 0.0223188 0.0100944 0.0163957 0.0100271 0.00739204 0.00555869 0.00395163 0.000633476 0.00107688 0.00313764 0.00349328 0.00381016 0.00342794 0.00203437 0.0015293 0.00205893 0.00239183 0.00221501 0.00403859 0.00425758 0.00457028 0.0144886 0.0110282 0.0120833 0.00694278 0.00562876 0.0103394 0.0067512 0.00603025 0.0187277 0.0216153 0.0153212 0.0152393 0.0151737 0.0151082 0.0150263 0.0149607 0.0148952 0.0148132 0.0147477 0.0146822
# Net 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.000153631 0.000501994 0.00506308 0.0063344 0.0116411 0.0097844 0.0111268 0.00430114 0.00498816 0.00866422 0.00532964 0.00104557 0.00120841 0.00147177 0.00150983 0.000441592 0.000449117 0.00133655 0.000267175 0.00017699 0.000182152 5.02509e-07 9.75544e-06 0 2.63904e-06 0 4.94345e-05 0 3.20574e-06 0 0 0 0 3.61003e-07 0 0 0 0 0 2.15417e-08 0 7.14363e-07 0 0 3.38329e-12 3.38329e-12 1.14426e-05 1.13814e-05 1.13324e-05 1.12835e-05 1.12223e-05 1.11733e-05 1.11244e-05 1.10632e-05 1.10142e-05 1.09653e-05
# HnL 0.000505004 0.000786584 0.000904111 0.000624613 0.000640036 0.000531323 0.000462024 0.000508363 0.000329137 0.000417868 0.000607595 0.000472779 0.000515738 0.000449709 0.00065031 0.000565687 0.000555472 0.000366427 0.000430625 0.000489689 0.00061363 0.000486652 0.000364741 0.000252356 0.000329078 0.000261558 9.69317e-05 0.000160703 0.000290718 0.000506648 0.000537334 0.000704531 0.00031533 0.00034597 0.000501829 0.000391623 0.000321402 0.000112586 0.000175776 0.000152361 0.000346607 0.000316208 0.00030927 0.000244955 0.000189043 0.000133097 0.000136662 0.000172838 0.000113244 0.000178759 0.000323896 0.000290211 0.000181203 0.000181001 8.81602e-05 0.000105932 0.000174571 0.000155306 0.000364351 0.000227154 0.000287914 0.000266623 0.00104406 0.000683516 0.000427612 0.000612077 0.00199989 0.000435476 0.000345791 0.000351271 0.00104246 0.000675308 0.00094607 0.000599632 0.00193014 0.00148452 0.0027926 0.00177105 0.0014308 0.000471963 0.000588328 0.000677516 0.00157962 0.000806316 0.000273985 0.000141023 1.09493e-05 1.17039e-05 4.34014e-06 1.78207e-05 1.94804e-05 2.88009e-05 2.04018e-05 4.2406e-06 4.4029e-06 1.29533e-06 3.16976e-06 8.74425e-06 1.41491e-05 1.59436e-05 7.54184e-06 1.987e-05 1.2472e-05 1.6491e-05 2.13507e-05 3.63514e-05 7.55363e-05 6.79742e-05 0.000138483 3.18862e-05 3.49252e-05 2.84273e-05 2.82752e-05 2.81536e-05 2.8032e-05 2.788e-05 2.77584e-05 2.76368e-05 2.74847e-05 2.73631e-05 2.72415e-05
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
           -25            25      -5.98424             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_BottomTrawl(1)
             0             2      0.163403             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_BottomTrawl(1)
           -20             2      -11.1104             0            99             0          1          0          0          0          0          0         10          1  #  LnQ_base_Hake(3)
             0             2       0.37122             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_Hake(3)
           -25            25      -4.86424             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_JuvSurvey(6)
             0             2       1.25019             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_JuvSurvey(6)
            -4             4      -2.04354             0            99             0          2          0          0          0          0          0          9          1  #  LnQ_base_Triennial(7)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_Triennial(7)
           -25            25       -3.4694             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_WCGBTS(8)
             0             2             0             0            99             0         -2          0          0          0          0          0          0          0  #  Q_extraSD_WCGBTS(8)
           -25            25      -11.4283             0             1             0         -1          0          0          0          0          0          0          0  #  LnQ_base_ForeignAtSea(9)
             0             2      0.578482             0            99             0          2          0          0          0          0          0          0          0  #  Q_extraSD_ForeignAtSea(9)
# timevary Q parameters 
#_          LO            HI          INIT         PRIOR         PR_SD       PR_type     PHASE  #  parm_name
        0.0001             2      0.463502           0.5           0.5             6      3  # LnQ_base_Hake(3)_BLK10add_1991
        0.0001             2      0.153881           0.5           0.5             6      3  # LnQ_base_Triennial(7)_BLK9add_1995
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
 24 1 0 0 # 5 HnL
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
            10            59        43.475            45          0.05             0          1          0          0          0          0        0.5          4          2  #  Size_DblN_peak_BottomTrawl(1)
            -5            10      -1.80319             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_BottomTrawl(1)
            -4            12        4.5978             3          0.05             0          2          0          0          0          0        0.5          4          2  #  Size_DblN_ascend_se_BottomTrawl(1)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_BottomTrawl(1)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_BottomTrawl(1)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_BottomTrawl(1)
            -5            60       3.63825             0            99             0          4          0          0          0          0          0          2          2  #  Retain_L_infl_BottomTrawl(1)
          0.01             8      0.946652             1            99             0          4          0          0          0          0          0          2          2  #  Retain_L_width_BottomTrawl(1)
           -10            10       4.59512            10            99             0         -2          0          0          0          0          0          1          2  #  Retain_L_asymptote_logit_BottomTrawl(1)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_BottomTrawl(1)
# 2   MidwaterTrawl LenSelex
            10            59       36.9438            45          0.05             0          1          0          0          0          0        0.5          7          2  #  Size_DblN_peak_MidwaterTrawl(2)
           -10            10       -9.4266             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_MidwaterTrawl(2)
            -4            12       2.86134             3          0.05             0          2          0          0          0          0        0.5          7          2  #  Size_DblN_ascend_se_MidwaterTrawl(2)
            -2            10       3.92888            10          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_descend_se_MidwaterTrawl(2)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_MidwaterTrawl(2)
            -9             9       -1.3053           0.5          0.05             0          4          0          0          0          0        0.5          7          2  #  Size_DblN_end_logit_MidwaterTrawl(2)
            -5            60            -5             0            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_infl_MidwaterTrawl(2)
          0.01             8           1.2             1            99             0         -9          0          0          0          0          0          0          0  #  Retain_L_width_MidwaterTrawl(2)
           -10            10       5.76562            10            99             0          2          0          0          0          0          0         12          2  #  Retain_L_asymptote_logit_MidwaterTrawl(2)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_MidwaterTrawl(2)
# 3   Hake LenSelex
            10            59       33.4722            45          0.05             0          1          0          0          0          0        0.5         11          2  #  Size_DblN_peak_Hake(3)
            -5            10      -2.01891             5          0.05             0          3          0          0          0          0        0.5         11          2  #  Size_DblN_top_logit_Hake(3)
            -4            12       2.07545             3          0.05             0          2          0          0          0          0        0.5         11          2  #  Size_DblN_ascend_se_Hake(3)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Hake(3)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Hake(3)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Hake(3)
# 4   Net LenSelex
            10            59       42.6264            45          0.05             0          1          0          0          0          0        0.5          0          0  #  Size_DblN_peak_Net(4)
            -5            10       2.29204             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_Net(4)
            -4            12       3.56161             3          0.05             0          2          0          0          0          0        0.5          0          0  #  Size_DblN_ascend_se_Net(4)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_Net(4)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_Net(4)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_Net(4)
# 5   HnL LenSelex
            10            59       23.4175            45          0.05             0          5          0          0          0          0        0.5          5          2  #  Size_DblN_peak_HnL(5)
            -5            10       2.55128             5          0.05             0          3          0          0          0          0        0.5          0          0  #  Size_DblN_top_logit_HnL(5)
            -5            12            -5             3          0.05             0         -2          0          0          0          0        0.5          5          2  #  Size_DblN_ascend_se_HnL(5)
            -2            10             9            10          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_descend_se_HnL(5)
            -9            10            -9           0.5          0.05             0         -3          0          0          0          0        0.5          0          0  #  Size_DblN_start_logit_HnL(5)
            -9             9             8           0.5          0.05             0         -4          0          0          0          0        0.5          0          0  #  Size_DblN_end_logit_HnL(5)
            -5            60       16.1776             0            99             0          2          0          0          0          0          0          3          2  #  Retain_L_infl_HnL(5)
          0.01             8       2.64716             1            99             0          3          0          0          0          0          0          3          2  #  Retain_L_width_HnL(5)
           -10            15       7.43741            10            99             0          1          0          0          0          0          0          3          2  #  Retain_L_asymptote_logit_HnL(5)
           -10            10             0             0            99             0        -99          0          0          0          0          0          0          0  #  Retain_L_maleoffset_HnL(5)
# 6   JuvSurvey LenSelex
# 7   Triennial LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_Triennial(7)
        -0.001             1      0.118711             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_Triennial(7)
            -1             1     0.0395709             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_Triennial(7)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_Triennial(7)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_Triennial(7)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_Triennial(7)
           -10            10      -1.82325           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_Triennial(7)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_Triennial(7)
           -10            10      0.448466           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_Triennial(7)
# 8   WCGBTS LenSelex
             0             2             0             0             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Code_WCGBTS(8)
        -0.001             1       0.46773             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradLo_WCGBTS(8)
            -1             1     -0.100002             0             0             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_GradHi_WCGBTS(8)
             8            56            24           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_1_WCGBTS(8)
             8            56            34           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_2_WCGBTS(8)
             8            56            48           -10             0             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Knot_3_WCGBTS(8)
           -10            10      -2.22974           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_1_WCGBTS(8)
           -10            10            -1           -10            99             0        -99          0          0          0          0        0.5          0          0  #  SizeSpline_Val_2_WCGBTS(8)
           -10            10    -0.0895604           -10            99             0          2          0          0          0          0        0.5          0          0  #  SizeSpline_Val_3_WCGBTS(8)
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
            10            59       38.9965            45          0.05             0      1  # Size_DblN_peak_BottomTrawl(1)_BLK4repl_1916
            -4            12       3.43277             3          0.05             0      2  # Size_DblN_ascend_se_BottomTrawl(1)_BLK4repl_1916
            -5            50       27.2082            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1982
            -5            50       27.4945            34            99             0      3  # Retain_L_infl_BottomTrawl(1)_BLK2repl_1990
          0.01             5      0.967365             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1982
          0.01             5       1.82725             1            99             0      3  # Retain_L_width_BottomTrawl(1)_BLK2repl_1990
           -10            10       1.71027            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1982
           -10            10      0.763769            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1990
           -10            10      0.105131            10            99             0      2  # Retain_L_asymptote_logit_BottomTrawl(1)_BLK1repl_1998
            10            59       38.6608            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1916
            10            59       38.0012            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_1983
            10            59       37.3779            45          0.05             0      1  # Size_DblN_peak_MidwaterTrawl(2)_BLK7repl_2002
            -4            12       3.36759             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1916
            -4            12        3.0767             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_1983
            -4            12       2.78975             3          0.05             0      2  # Size_DblN_ascend_se_MidwaterTrawl(2)_BLK7repl_2002
            -2            10        4.2501            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1916
            -2            10       3.07436            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_1983
            -2            10      -1.38611            10          0.05             0      4  # Size_DblN_descend_se_MidwaterTrawl(2)_BLK7repl_2002
            -9             9      -1.96901           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1916
            -9             9     -0.423968           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_1983
            -9             9       1.63209           0.5          0.05             0      4  # Size_DblN_end_logit_MidwaterTrawl(2)_BLK7repl_2002
           -10            10        4.5912            10            99             0      -2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1916
           -10            10       1.65702            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_1983
           -10            10       1.85387            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2002
           -10            10       8.94664            10            99             0      2  # Retain_L_asymptote_logit_MidwaterTrawl(2)_BLK12repl_2011
            10            59       42.7232            45          0.05             0      1  # Size_DblN_peak_Hake(3)_BLK11repl_1916
            -5            10       2.34066             5          0.05             0      3  # Size_DblN_top_logit_Hake(3)_BLK11repl_1916
            -4            12        3.7083             3          0.05             0      2  # Size_DblN_ascend_se_Hake(3)_BLK11repl_1916
            15            59       37.2391            45          0.05             0      1  # Size_DblN_peak_HnL(5)_BLK5repl_1916
            -4            12        3.7505             3          0.05             0      2  # Size_DblN_ascend_se_HnL(5)_BLK5repl_1916
            -5            50            -5            34            99             0      -2  # Retain_L_infl_HnL(5)_BLK3repl_1916
           0.1             8           1.2             1            99             0      -3  # Retain_L_width_HnL(5)_BLK3repl_1916
           -10            10        4.5912            10            99             0      -3  # Retain_L_asymptote_logit_HnL(5)_BLK3repl_1916
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
#      5    39    33     3     2     0     0     0     0     0     0     0
#      5    40    34     3     2     0     0     0     0     0     0     0
#      5    41    35     3     2     0     0     0     0     0     0     0
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
      4      1  0.056379
      4      2  0.207585
      4      3  0.110421
      4      4  0.495704
      4      5  0.373375
      4      7  0.372441
      4      8   0.63518
      5      1  0.166103
      5      2   0.27951
      5      3   0.24137
      5      4  0.500509
      5      5   0.55139
      5      8  0.296203
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

