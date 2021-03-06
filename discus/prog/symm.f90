MODULE symm_menu
!
CONTAINS
!+                                                                      
!     Generalized symmetry operations:                                  
!                                                                       
!     Rotations around a general axis by a general angle                
!     Mirror operations with free choice of normal and glide            
!     component.                                                        
!                                                                       
!*****7*****************************************************************
      SUBROUTINE symm 
!-                                                                      
!     Main menu for generalized symmetry operations                     
!+                                                                      
      USE discus_config_mod 
      USE discus_allocate_appl_mod
      USE crystal_mod 
      USE discus_kdo_common_mod
      USE modify_mod
      USE molecule_mod 
      USE update_cr_dim_mod
      USE discus_show_menu
      USE symm_mod 
      USE symm_sup_mod 
      USE trafo_mod
      USE wyckoff_mod
!
      USE ber_params_mod
      USE calc_expr_mod
      USE doact_mod 
      USE do_eval_mod
      USE do_wait_mod
      USE errlist_mod 
      USE get_params_mod
      USE learn_mod 
      USE class_macro_internal
      USE param_mod 
USE precision_mod
      USE prompt_mod 
      USE take_param_mod
      USE sup_mod
!                                                                       
      IMPLICIT none 
!                                                                       
      INTEGER, PARAMETER :: MIN_PARA = 20
      INTEGER            :: maxw 
      LOGICAL lold 
!                                                                       
      PARAMETER (lold = .false.) 
!                                                                       
      CHARACTER(LEN=1024), DIMENSION(MAX(MIN_PARA,MAXSCAT+1)) :: cpara
      REAL(KIND=PREC_DP) , DIMENSION(MAX(MIN_PARA,MAXSCAT+1)) :: werte
      INTEGER            , DIMENSION(MAX(MIN_PARA,MAXSCAT+1)) :: lpara
!
      CHARACTER(5) befehl 
      CHARACTER(LEN=LEN(prompt)) :: orig_prompt
      CHARACTER(1024) line, zeile
      INTEGER lp, length, lbef 
      INTEGER indxg, ianz, i , iianz
      INTEGER indxc 
      INTEGER         :: nscat
      LOGICAL lend, lspace 
      LOGICAL l_need_setup 
      LOGICAL lselect 
      LOGICAL :: lout         ! Screen echo for 'calc' yes/no
      LOGICAL :: success   
      REAL hkl (3) 
!
INTEGER, PARAMETER :: NOPTIONAL = 3
INTEGER, PARAMETER :: O_RADIUS  = 1
INTEGER, PARAMETER :: O_OCCUP   = 2
INTEGER, PARAMETER :: O_ECHO    = 3
CHARACTER(LEN=1024), DIMENSION(NOPTIONAL) :: oname   !Optional parameter names
CHARACTER(LEN=1024), DIMENSION(NOPTIONAL) :: opara   !Optional parameter strings returned
INTEGER            , DIMENSION(NOPTIONAL) :: loname  !Lenght opt. para name
INTEGER            , DIMENSION(NOPTIONAL) :: lopara  !Lenght opt. para name returned
LOGICAL            , DIMENSION(NOPTIONAL) :: lpresent  !opt. para present
REAL(KIND=PREC_DP) , DIMENSION(NOPTIONAL) :: owerte   ! Calculated values
INTEGER, PARAMETER                        :: ncalc = 1 ! Number of values to calculate 
!
      INTEGER len_str 
      LOGICAL str_comp 
!
      DATA l_need_setup / .true. / 
      DATA oname  / 'radius', 'occupied', 'echo    '/
      DATA loname /  6        ,  8      ,  8        /
!
      maxw = MAX(MIN_PARA,MAXSCAT+1)
      lend = .false. 
      CALL no_error 
!
      orig_prompt = prompt
      prompt = prompt (1:len_str (prompt) ) //'/symm' 
!                                                                       
      DO while (.not.lend) 
      CALL get_cmd (line, length, befehl, lbef, zeile, lp, prompt) 
      opara  =  (/ '1.0E-8', 'any   '   , 'screen'  /)   ! Always provide fresh default values
      lopara =  (/  6,        6         ,  6        /)
      owerte =  (/  1.0E-8 ,  0.0       ,  0.00     /)
      IF (ier_num.eq.0) THEN 
         IF (line /= ' '      .and. line(1:1) /= '#' .and. &
             line /= char(13) .and. line(1:1) /= '!'        ) THEN
!                                                                       
!     ----search for "="                                                
!                                                                       
indxg = index (line, '=') 
IF (indxg.ne.0.AND..NOT. (str_comp (befehl, 'echo', 2, lbef, 4) ) &
              .AND..NOT. (str_comp (befehl, 'syst', 2, lbef, 4) )    &
              .AND..NOT. (str_comp (befehl, 'help', 2, lbef, 4) .OR. &
                          str_comp (befehl, '?   ', 2, lbef, 4) )    &
              .AND. INDEX(line,'==') == 0                            ) THEN
!                                                                       
!     ------evaluatean expression and assign the value to a variabble   
!                                                                       
               CALL do_math (line, indxg, length) 
            ELSE 
!
! - Test common menu entries
!
               CALL discus_kdo_common(befehl, lbef, line, length, zeile, lp, 'symm' , &
                             lend, success)
!                                                                       
!     ----run symmetry 'rese'                                            
!                                                                       
               IF (str_comp (befehl, 'rese', 2, lbef, 4) ) THEN 
                  CALL symm_reset
!-------------------------------------------------------------------------------
!-------- SYMM specific commands if no common command was found
!-------------------------------------------------------------------------------
               ELSEIF(.NOT. success) THEN
!
      IF( cr_nscat > SYM_MAXSCAT .or. mole_num_type > SYM_MAXSCAT) THEN
         nscat = max ( cr_nscat, mole_num_type)
         CALL alloc_symmetry ( nscat )
         IF ( ier_num < 0 ) THEN
            RETURN
         ENDIF
      ENDIF
!                                                                       
!     ----angle of rotation 'angle'                                     
!                                                                       
                   IF (str_comp (befehl, 'angle', 2, lbef, 5) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0.and.ianz.eq.1) THEN 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        sym_angle = werte (1) 
                        l_need_setup = .true. 
                        sym_use = 0             ! Turn off space group matrix usage
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----calculate a single symmetry operation                         
!                                                                       
               ELSEIF (str_comp (befehl, 'calc', 2, lbef, 4) ) THEN 
                  IF (l_need_setup) THEN 
                     CALL symm_setup 
                  ENDIF 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
                     CALL get_optional(ianz, MAXW, cpara, lpara, NOPTIONAL,  &
                          ncalc, oname, loname, opara, lopara, lpresent, owerte)
                     lout = opara(O_ECHO) == 'screen'
                     IF (ianz.eq.3) THEN 
                        cpara (4) = 'd' 
                        lpara (4) = 1 
                     ENDIF 
                     ianz = 3 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        DO i = 1, 3 
                        hkl (i) = werte (i) 
                        ENDDO 
                        IF (str_comp (cpara (4) , 'd', 1, lpara (4) , 1)&
                        ) THEN                                          
                           lspace = .true. 
                        ELSEIF (str_comp (cpara (4) , 'r', 1, lpara (4) &
                        , 1) ) THEN                                     
                           lspace = .false. 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                        IF (ier_num.eq.0) THEN 
                           IF (sym_power_mult) THEN 
                              CALL symm_ca_mult (hkl, lspace, lout  ) 
                           ELSE 
                              CALL symm_ca_single (hkl, lspace, lout  ) 
                           ENDIF 
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----Work on domains 'domain'                                      
!                                                                       
               ELSEIF (str_comp (befehl, 'domain', 2, lbef, 6) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
                     IF (str_comp (cpara (1) , 'select', 2, lpara (1) , &
                     6) .or.str_comp (cpara (1) , 'deselect', 2, lpara (&
                     1) , 8) ) THEN                                     
                        line = ' ' 
                        indxc = index (zeile, ',') 
                        line = zeile (indxc + 1:lp) 
                        lp = len_str (line) 
!                                                                       
                        lselect = str_comp (cpara (1) , 'select', 2,    &
                        lpara (1) , 6) .or.str_comp (cpara (1) ,        &
                        'deselect', 2, lpara (1) , 8)                   
!                                                                       
                        CALL mole_select (line, lp, 0, SYM_MAXSCAT,     &
                             sym_latom, sym_sel_atom, lselect)
                        sym_sel_mode = SYM_RUN_DOMAIN 
                     ELSEIF (str_comp (cpara (1) , 'include', 3, lpara (&
                     1) , 7) ) THEN                                     
                        CALL del_params (1, ianz, cpara, lpara, maxw) 
                        IF (ianz.eq.2) THEN 
                           CALL ber_params (ianz, cpara, lpara, werte,  &
                           maxw)                                        
                           IF (ier_num.eq.0) THEN 
                              sym_sel_atom = .false. 
                              sym_start = nint (werte (1) ) 
                              sym_end = nint (werte (2) ) 
                           ENDIF 
                        ELSEIF (ianz.eq.1) THEN 
                           IF (str_comp (cpara (1) , 'all', 1, lpara (1)&
                           , 3) ) THEN                                  
                              sym_sel_atom = .false. 
                              sym_start = 1 
                              sym_end = - 1 
                           ELSE 
                              ier_num = - 6 
                              ier_typ = ER_COMM 
                           ENDIF 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ELSEIF (str_comp (cpara (1) , 'atoms', 2, lpara (1)&
                     , 4) ) THEN                                        
                        sym_dom_mode_atom = str_comp (cpara (2) ,       &
                        'apply', 2, lpara (2) , 5)                      
                     ELSEIF (str_comp (cpara (1) , 'shape', 2, lpara (2)&
                     , 5) ) THEN                                        
                        sym_dom_mode_shape = str_comp (cpara (2) ,      &
                        'apply', 2, lpara (2) , 5)                      
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----Select the reciprocal space direction of the symmetry         
!         axis 'hkl'                                                    
!                                                                       
               ELSEIF (str_comp (befehl, 'hkl ', 2, lbef, 4) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0.and.ianz.eq.3) THEN 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        DO i = 1, 3 
                        sym_hkl (i) = werte (i) 
                        ENDDO 
                        CALL trans (sym_hkl, cr_rten, sym_uvw, 3) 
                        sym_axis_type     = 0      ! Axis in absolute coordinates
                        l_need_setup = .true. 
                        sym_use = 0             ! Turn off space group matrix usage
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----Select range of atoms within crystal to be included 'incl'    
!                                                                       
               ELSEIF (str_comp (befehl, 'incl', 1, lbef, 4) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
                     IF (ianz.eq.2) THEN 
                        CALL ber_params (ianz, cpara, lpara, werte,     &
                        maxw)                                           
                        IF (ier_num.eq.0) THEN 
                           sym_sel_atom = .true. 
                           sym_start = nint (werte (1) ) 
                           sym_end = nint (werte (2) ) 
                           sym_incl = 'list' 
                        ENDIF 
                     ELSEIF (ianz.eq.1) THEN 
                        IF (str_comp (cpara (1) , 'all', 1, lpara (1) , &
                        3) ) THEN                                       
                           sym_sel_atom = .true. 
                           sym_start = 1 
                           sym_end = - 1 
                           sym_incl = 'all ' 
                        ELSEIF (str_comp (cpara (1) , 'env', 1, lpara ( &
                        1) , 3) ) THEN                                  
                           sym_sel_atom = .true. 
                           sym_start = 1 
                           sym_end = - 1 
                           sym_incl = 'env ' 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----Select range of molecules within crystal to be included       
!         'mincl'                                                       
!                                                                       
               ELSEIF (str_comp (befehl, 'mincl', 3, lbef, 5) .OR.      &
                       str_comp (befehl, 'oincl', 3, lbef, 5) ) THEN
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN
                     sym_sel_sub  = .FALSE.
                     IF (str_comp(cpara(1),'all', 1, lpara(1), 3)) THEN
                        sym_sel_atom = .false. 
                        sym_start =  1                  ! Select all molecule numbers
                        sym_end   = -1 
                        CALL del_params (1, ianz, cpara, lpara, maxw) 
                     ELSE
                        iianz = 2
                        CALL ber_params(iianz, cpara, lpara, werte, maxw)
                        IF (ier_num.eq.0) THEN
                           sym_sel_atom = .false.
                           sym_start = nint (werte (1) )  ! Select limited molecule
                           sym_end   = nint (werte (2) )  !        range
                           CALL del_params (2, ianz, cpara, lpara, maxw)
                        ENDIF
                     ENDIF 
                     IF(ier_num == 0 .AND. ianz > 0 ) THEN
                        IF (str_comp(cpara(1),'group', 1, lpara(1), 5)) THEN
                           sym_sel_sub  = .TRUE.
                           CALL del_params (1, ianz, cpara, lpara, maxw) 
                           CALL ber_params(ianz, cpara, lpara, werte, maxw)                                           
                           IF (ier_num.eq.0) THEN 
                              sym_sub_start = nint (werte (1) ) 
                              IF(ianz > 1) THEN    ! We have excluded atoms
                                 IF(ALLOCATED(sym_excl)) DEALLOCATE(sym_excl)
                                 sym_n_excl = ianz-1
                                 ALLOCATE(sym_excl(1:sym_n_excl))
                                 sym_excl(:) = 0
                                 DO i=2,ianz
                                    sym_excl(i-1) = NINT(werte(i))
                                 ENDDO
                              ENDIF
                           ENDIF 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ENDIF 
                        
!                     IF (ianz.eq.2) THEN 
!!                        CALL ber_params (ianz, cpara, lpara, werte,     &
!                        maxw)                                           
!                        IF (ier_num.eq.0) THEN 
!                           sym_sel_atom = .false. 
!                           sym_start = nint (werte (1) ) 
!                           sym_end = nint (werte (2) ) 
!                        ENDIF 
!                     ELSEIF (ianz.eq.1) THEN 
!                        IF (str_comp (cpara (1) , 'all', 1, lpara (1) , &
!                        3) ) THEN                                       
!                           sym_sel_atom = .false. 
!                           sym_start = 1 
!                           sym_end = - 1 
!                        ELSE 
!                           ier_num = - 6 
!                           ier_typ = ER_COMM 
!                        ENDIF 
!                     ELSE 
!                        ier_num = - 6 
!                        ier_typ = ER_COMM 
!                     ENDIF 
                  ENDIF 
!                                                                       
!     ----Select the mode of symmetry operation 'mode'                  
!                                                                       
               ELSEIF (str_comp (befehl, 'mode', 1, lbef, 4) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
!                    opara  =  (/ '1.0E-8', 'any   '   /)   ! Always provide fresh default values
!                    lopara =  (/  6,        6         /)
!                    owerte =  (/  1.0E-8 ,  0.0       /)
                     CALL get_optional(ianz, MAXW, cpara, lpara, NOPTIONAL,  &
                          ncalc, oname, loname, opara, lopara, lpresent, owerte)
                     IF (ier_num.eq.0) THEN 
                     IF (ianz.eq.1.or.ianz.eq.2) THEN 
                        sym_occup  = opara(O_OCCUP) == 'empty'   ! Can target position by occupied or empty?
                        sym_radius = owerte(O_RADIUS)             ! If empty, necessary free radius
                        IF (str_comp (cpara (1) , 'copy', 1, lpara (1) ,&
                        4) ) THEN                                       
                           sym_mode = .true. 
                           l_need_setup = .true. 
                        ELSEIF (str_comp (cpara (1) , 'repl', 1, lpara (&
                        1) , 4) ) THEN                                  
                           sym_mode = .false. 
                           l_need_setup = .true. 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ENDIF 
!                                                                       
                     IF (ier_num.eq.0.and.ianz.eq.2) THEN 
                        IF (str_comp (cpara (2) , 'new', 1, lpara (2) , &
                        3) ) THEN                                       
                           sym_new = .true. 
                           l_need_setup = .true. 
                        ELSEIF (str_comp (cpara (2) , 'old', 1, lpara ( &
                        1) , 3) ) THEN                                  
                           sym_new = .false. 
                           l_need_setup = .true. 
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ENDIF 
                  ENDIF 
                  ENDIF 
!                                                                       
!     ----Select/deselect molecules                                     
!                                                                       
               ELSEIF (str_comp (befehl, 'msel', 2, lbef, 4)            &
                  .OR. str_comp (befehl, 'mdes', 2, lbef, 4) &
                  .OR. str_comp (befehl, 'osel', 2, lbef, 4) &
                  .OR. str_comp (befehl, 'odes', 2, lbef, 4) ) THEN                                       
!                                                                       
                  lselect = str_comp (befehl, 'msel', 2, lbef, 4)       &
                        .OR.str_comp (befehl, 'osel', 2, lbef, 4)             
!                                                                       
                  CALL mole_select (zeile, lp, 0, SYM_MAXSCAT,         &
                             sym_latom, sym_sel_atom, lselect)
!                                                                       
!     ----Select the origin of the symmetry operation  'origin'         
!                                                                       
               ELSEIF (str_comp (befehl, 'origin', 1, lbef, 6) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN
                     IF(str_comp(cpara(1), 'atom', 1, lpara(1), 4)) THEN
                        sym_orig (:)  = 0.0
                        sym_orig_type = 1
                        sym_orig_mol  = str_comp(cpara(ianz), 'molecule', 1, lpara(ianz), 8)
                        IF(sym_orig_mol) sym_orig_type = -1
                        CALL del_params (1, ianz, cpara, lpara, maxw) 
                        ianz = 1
                        CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                        IF (ier_num.eq.0) THEN 
                           sym_orig_atom = NINT(werte(1))
                           l_need_setup = .true. 
                           sym_use = 0             ! Turn off space group matrix usage
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ELSEIF ((ianz.eq.3.or.ianz.eq.4) ) THEN 
                        sym_orig_mol = .FALSE.
                     IF (ianz.eq.4) THEN 
                        sym_orig_mol = str_comp (cpara (4) , 'mol', 1,  &
                        lpara (4) , 3)                                  
                        ianz = 3 
                     ENDIF 
!                                                                       
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        DO i = 1, 3 
                        sym_orig (i) = werte (i) 
                        ENDDO 
                        sym_orig_type = 0
                        l_need_setup = .true. 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----Set the power of the symmetry operation  'power'              
!                                                                       
               ELSEIF (str_comp (befehl, 'power', 1, lbef, 6) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
                     IF (ianz.eq.1.or.ianz.eq.2) THEN 
                        IF (ianz.eq.2) THEN 
                           IF (str_comp (cpara (2) , 'mult', 1, lpara ( &
                           2) , 4) ) THEN                               
                              sym_power_mult = .true. 
                           ELSEIF (str_comp (cpara (2) , 'sing', 1,     &
                           lpara (2) , 4) ) THEN                        
                              sym_power_mult = .false. 
                           ELSE 
                              ier_num = - 6 
                              ier_typ = ER_COMM 
                           ENDIF 
                        ENDIF 
                        ianz = 1 
                        CALL ber_params (ianz, cpara, lpara, werte,     &
                        maxw)                                           
                        IF (ier_num.eq.0) THEN 
                           sym_power = nint (werte (1) ) 
                           l_need_setup = .true. 
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----run symmetry 'run'                                            
!                                                                       
               ELSEIF (str_comp (befehl, 'run ', 2, lbef, 4) ) THEN 
                  IF (l_need_setup) THEN 
                     CALL symm_setup 
                  ENDIF 
                  IF (sym_sel_atom) THEN 
!                                                                       
!-----      --------Apply symmetry operation to atoms                   
!                                                                       
                     IF(sym_end == -1) sym_end=cr_natoms
                     IF(.NOT. (sym_start >= 1           .AND. &
                               sym_end <= cr_natoms     .AND. &
                               sym_start <= sym_end)          ) THEN
                        ier_num = -19
                        ier_typ = ER_APPL
                        ier_msg(1) = 'Values for ''inc'' are wrong'
                     ELSE
                     IF (sym_power_mult) THEN 
                        CALL symm_op_mult 
                     ELSE 
                        CALL symm_op_single 
                     ENDIF 
                     ENDIF 
                  ELSE 
                     IF (sym_sel_mode.eq.SYM_RUN_MOLECULE) THEN 
!                                                                       
!-----      ----------Apply symmetry operation to molecules             
!                                                                       
                       IF(sym_end == -1) sym_end=mole_num_mole
                        IF(.NOT. (sym_start >= 1           .AND. &
                                  sym_end <= mole_num_mole .AND. &
                                  sym_start <= sym_end)          ) THEN
                           ier_num = -63
                           ier_typ = ER_APPL
                           ier_msg(1) = 'Values for ''minc'' are wrong'
                        ELSE
                        IF (sym_power_mult) THEN 
                           CALL symm_mole_mult 
                        ELSE 
                           CALL symm_mole_single 
                        ENDIF 
                        ENDIF 
                     ELSEIF (sym_sel_mode.eq.SYM_RUN_DOMAIN) THEN 
!                                                                       
!-----      ----------Apply symmetry operation to molecules             
!                                                                       
                        IF (sym_power_mult) THEN 
                           CALL symm_domain_mult 
                        ELSE 
                           CALL symm_domain_single 
                        ENDIF 
                     ENDIF 
                  ENDIF 
                  IF(ier_num==0) THEN
                  IF(ALL(sym_latom(0:SYM_MAXSCAT)) .AND. sym_incl=='all') THEN
                     lspace = .TRUE.
                     DO i=1,2
                        hkl(:) = cr_dim0(:,i)
                        IF (sym_power_mult) THEN 
                           CALL symm_ca_mult (hkl, lspace, .FALSE.) 
                        ELSE 
                           CALL symm_ca_single (hkl, lspace, .FALSE.) 
                        ENDIF 
                        cr_dim0(1,i) = NINT(res_para(1))
                        cr_dim0(2,i) = NINT(res_para(2))
                        cr_dim0(3,i) = NINT(res_para(3))
                     ENDDO
                  ENDIF
                  CALL update_cr_dim 
                  ENDIF
!                                                                       
!     ----Select which atoms are copied to their image 'sele'           
!                                                                       
               ELSEIF (str_comp (befehl, 'sele', 2, lbef, 4)            &
                  .OR. str_comp (befehl, 'dese', 2, lbef, 4) ) THEN         
!                                                                       
                  CALL atom_select (zeile, lp, 0, SYM_MAXSCAT, sym_latom, &
                  sym_sel_atom, lold,     &
                  str_comp (befehl, 'sele', 2, lbef, 4) )               
!                                                                       
!     ----show current parameters 'show'                                
!                                                                       
               ELSEIF (str_comp (befehl, 'show', 2, lbef, 4) ) THEN 
                  IF (l_need_setup) THEN 
                     CALL symm_setup 
                  ENDIF 
                  CALL symm_show 
!                                                                       
!     ----Select translational part of the symmetry operation 'trans'   
!                                                                       
               ELSEIF (str_comp (befehl, 'trans', 2, lbef, 5) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0.and.ianz.eq.3) THEN 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        DO i = 1, 3 
                        sym_trans (i) = werte (i) 
                        ENDDO 
                        l_need_setup = .true. 
                        sym_use = 0             ! Turn off space group matrix usage
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----Select the type of symmetry operation                  'type' 
!                                                                       
               ELSEIF (str_comp (befehl, 'type', 2, lbef, 4) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN 
                     IF (ianz.eq.1) THEN 
                        IF (str_comp (cpara (1) , 'proper', 1, lpara (1)&
                        , 6) ) THEN                                     
                           sym_type = .true. 
                           l_need_setup = .true. 
                        ELSEIF (str_comp (cpara (1) , 'improper', 1,    &
                        lpara (1) , 8) ) THEN                           
                           sym_type = .false. 
                           l_need_setup = .true. 
                           sym_use = 0             ! Turn off space group matrix usage
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF 
                     ENDIF 
                  ENDIF 
!                                                                       
!     ----Select the direct space direction of the symmetry axis 'uvw'  
!                                                                       
               ELSEIF (str_comp (befehl, 'uvw ', 2, lbef, 3) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN
                     IF(str_comp(cpara(1), 'atoms', 1, lpara(1), 5)) THEN
                        IF(str_comp(cpara(ianz), 'crystal', 1, lpara(ianz), 7)) THEN
                           sym_axis_type = 1
                           l_need_setup = .true. 
                           CALL del_params (1, ianz, cpara, lpara, maxw) 
                           ianz = ianz - 1
                           CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                           DO i=1,ianz
                              sym_axis_atoms(i) = NINT(werte(i))
                           ENDDO
                           sym_uvw(:) = 0.0
                           sym_uvw(3) = 1.0
                           sym_use = 0             ! Turn off space group matrix usage
                        ELSEIF(str_comp(cpara(ianz), 'molecule', 1, lpara(ianz), 8)) THEN
                           sym_axis_type = -1
                           l_need_setup = .true. 
                           CALL del_params (1, ianz, cpara, lpara, maxw) 
                           ianz = ianz - 1
                           CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                           DO i=1,ianz
                              sym_axis_atoms(i) = NINT(werte(i))
                           ENDDO
                           sym_uvw(:) = 0.0
                           sym_uvw(3) = 1.0
                           sym_use = 0             ! Turn off space group matrix usage
                        ELSE 
                           ier_num = - 6 
                           ier_typ = ER_COMM 
                        ENDIF
                     ELSEIF(ianz.eq.3) THEN 
                     CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                     IF (ier_num.eq.0) THEN 
                        DO i = 1, 3 
                        sym_uvw (i) = werte (i) 
                        ENDDO 
                        CALL trans (sym_uvw, cr_gten, sym_hkl, 3) 
                        sym_axis_type     = 0      ! Axis in absolute coordinates
                        l_need_setup = .true. 
                        sym_use = 0             ! Turn off space group matrix usage
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ELSE 
                     ier_num = - 6 
                     ier_typ = ER_COMM 
                  ENDIF 
!                                                                       
!     ----Select a space group symmetry matrix 'use'  
!                                                                       
               ELSEIF (str_comp (befehl, 'use ', 2, lbef, 3) ) THEN 
                  CALL get_params (zeile, ianz, cpara, lpara, maxw, lp) 
                  IF (ier_num.eq.0) THEN
                     IF(ianz==1) THEN
                        CALL ber_params (ianz, cpara, lpara, werte, maxw) 
                        IF (ier_num.eq.0) THEN
                           IF(NINT(werte(1))>0 .AND. NINT(werte(1))<=spc_n) THEN
                              sym_use = NINT(werte(1))
                              l_need_setup = .true. 
                           ELSE
                              sym_use = 0
                           ENDIF
                        ENDIF 
                     ELSE 
                        ier_num = - 6 
                        ier_typ = ER_COMM 
                     ENDIF 
                  ENDIF
               ELSE 
                  ier_num = - 8 
                  ier_typ = ER_COMM 
               ENDIF 
            ENDIF 
            ENDIF 
         ENDIF 
      ENDIF 
      IF (ier_num.ne.0) THEN 
         CALL errlist 
         IF (ier_sta.ne.ER_S_LIVE) THEN 
            IF (lmakro .OR. lmakro_error) THEN  ! Error within macro or termination errror
               IF(sprompt /= prompt ) THEN
                  ier_num = -10
                  ier_typ = ER_COMM
                  ier_msg(1) = ' Error occured in symmetry menu'
                  prompt_status = PROMPT_ON 
                  prompt = orig_prompt
                  RETURN
               ELSE
                  IF(lmacro_close) THEN
                     CALL macro_close 
                     prompt_status = PROMPT_ON 
                  ENDIF 
               ENDIF 
            ENDIF 
            IF (lblock) THEN 
               ier_num = - 11 
               ier_typ = ER_COMM 
               prompt_status = PROMPT_ON 
               prompt = orig_prompt
               RETURN 
            ENDIF 
            CALL no_error 
            lmakro_error = .FALSE.
            sprompt = ' '
         ENDIF 
      ENDIF 
      ENDDO 
!
      prompt = orig_prompt
!                                                                       
      END SUBROUTINE symm                           
!*****7*****************************************************************
      SUBROUTINE symm_show 
!-                                                                      
!     Shows current symm settings                                       
!+                                                                      
      USE discus_config_mod 
      USE discus_show_menu
      USE crystal_mod 
      USE atom_name
      USE molecule_mod 
      USE symm_mod 
!                                                                       
      USE prompt_mod 
!
      IMPLICIT none 
!                                                                       
      CHARACTER(9) at_lis (0:maxscat+1)!, at_name 
      INTEGER mol_lis (maxscat+1)
      INTEGER i, j, k 
!                                                                       
   IF(sym_use==0) THEN
      WRITE (output_io, 3000) sym_uvw 
      WRITE (output_io, 3010) sym_hkl 
      IF (sym_orig_mol) THEN 
         WRITE (output_io, 3020) sym_orig, ' rel.to molecule' 
      ELSE 
         WRITE (output_io, 3020) sym_orig, ' rel. to crystal' 
      ENDIF 
      WRITE (output_io, 3030) sym_angle 
      WRITE (output_io, 3040) sym_trans 
      WRITE (output_io, 3045) sym_or_tr 
      WRITE (output_io, 3050) ( (sym_mat (i, j), j = 1, 4), i = 1, 3) 
      WRITE (output_io, 3060) ( (sym_rmat (i, j), j = 1, 3), i = 1, 3) 
      WRITE (output_io, 3070) sym_power 
!                                                                       
      IF (sym_power_mult) THEN 
         WRITE (output_io, 3080) 'Multiple copy of original' 
      ELSE 
         WRITE (output_io, 3080) 'Single copy of original' 
      ENDIF 
!                                                                       
      IF (sym_type) THEN 
         WRITE (output_io, 3090) 'Proper rotation' 
      ELSE 
         WRITE (output_io, 3090) 'Improper rotation' 
      ENDIF 
!                                                                       
      IF (sym_mode) THEN 
         WRITE (output_io, 3100) 'Copy atom/molecule to new position' 
      ELSE 
         WRITE (output_io, 3100) 'Move atom/molecule to new position' 
      ENDIF 
!                                                                       
      IF (sym_new.and..not.sym_sel_atom) THEN 
         WRITE (output_io, 3110) 'Create new molecule type' 
      ELSE 
         WRITE (output_io, 3110) 'Keep molecule type' 
      ENDIF 
!                                                                       
!------ Working with atoms ...                                          
!                                                                       
      IF (sym_sel_atom) THEN 
!                                                                       
         j = 0 
         DO i = 0, cr_nscat 
         IF (sym_latom (i) ) THEN 
            j = j + 1 
            at_lis (j) = at_name (i) 
         ENDIF 
         ENDDO 
         WRITE (output_io, 3210) (at_lis (i), i = 1, j) 
!                                                                       
         IF (sym_incl.eq.'all ') THEN 
            WRITE (output_io, 3220) 
         ELSEIF (sym_incl.eq.'env ') THEN 
            WRITE (output_io, 3225) 
         ELSE 
            WRITE (output_io, 3230) sym_start, sym_end 
         ENDIF 
!                                                                       
!------ Working with molecules                                          
!                                                                       
      ELSE 
!                                                                       
         IF (sym_orig_mol) THEN 
            WRITE (output_io, 3250) 'Molecule' 
         ELSE 
            WRITE (output_io, 3250) 'Crystal' 
         ENDIF 
!                                                                       
         j = 0 
         DO i = 0, mole_num_type 
         IF (sym_latom (i) ) THEN 
            j = j + 1 
            mol_lis (j) = i 
         ENDIF 
         ENDDO 
         WRITE (output_io, 3300) (mol_lis (k), k = 1, j) 
!                                                                       
         IF (sym_end.eq. - 1) THEN 
            WRITE (output_io, 3310) 
         ELSE 
            WRITE (output_io, 3320) sym_start, sym_end 
         ENDIF 
         IF (sym_sel_mode.eq.SYM_RUN_DOMAIN) THEN 
            IF (sym_dom_mode_atom) THEN 
               WRITE (output_io, 4100) 
            ELSE 
               WRITE (output_io, 4150) 
            ENDIF 
            IF (sym_dom_mode_shape) THEN 
               WRITE (output_io, 4200) 
            ELSE 
               WRITE (output_io, 4250) 
            ENDIF 
         ENDIF 
      ENDIF 
   ELSE
      WRITE(output_io,5000)
      CALL do_show_symmetry_single(sym_use, 0)
      WRITE (output_io, 3050) ( (sym_mat (i, j), j = 1, 4), i = 1, 3) 
      WRITE (output_io, 3060) ( (sym_rmat (i, j), j = 1, 3), i = 1, 3) 
      WRITE (output_io, 3070) sym_power 
!                                                                       
      IF (sym_power_mult) THEN 
         WRITE (output_io, 3080) 'Multiple copy of original' 
      ELSE 
         WRITE (output_io, 3080) 'Single copy of original' 
      ENDIF 
!                                                                       
      IF (sym_mode) THEN 
         WRITE (output_io, 3100) 'Copy atom/molecule to new position' 
      ELSE 
         WRITE (output_io, 3100) 'Move atom/molecule to new position' 
      ENDIF 
!                                                                       
      IF (sym_new.and..not.sym_sel_atom) THEN 
         WRITE (output_io, 3110) 'Create new molecule type' 
      ELSE 
         WRITE (output_io, 3110) 'Keep molecule type' 
      ENDIF 
!                                                                       
!------ Working with atoms ...                                          
!                                                                       
      IF (sym_sel_atom) THEN 
!                                                                       
         j = 0 
         DO i = 0, cr_nscat 
         IF (sym_latom (i) ) THEN 
            j = j + 1 
            at_lis (j) = at_name (i) 
         ENDIF 
         ENDDO 
         WRITE (output_io, 3210) (at_lis (i), i = 1, j) 
!                                                                       
         IF (sym_incl.eq.'all ') THEN 
            WRITE (output_io, 3220) 
         ELSEIF (sym_incl.eq.'env ') THEN 
            WRITE (output_io, 3225) 
         ELSE 
            WRITE (output_io, 3230) sym_start, sym_end 
         ENDIF 
      ELSE
!                                                                       
!------ Working with molecules                                          
!                                                                       
         j = 0 
         DO i = 0, mole_num_type 
         IF (sym_latom (i) ) THEN 
            j = j + 1 
            mol_lis (j) = i 
         ENDIF 
         ENDDO 
         WRITE (output_io, 3300) (mol_lis (k), k = 1, j) 
!                                                                       
         IF (sym_end.eq. - 1) THEN 
            WRITE (output_io, 3310) 
         ELSE 
            WRITE (output_io, 3320) sym_start, sym_end 
         ENDIF 
         IF (sym_sel_mode.eq.SYM_RUN_DOMAIN) THEN 
            IF (sym_dom_mode_atom) THEN 
               WRITE (output_io, 4100) 
            ELSE 
               WRITE (output_io, 4150) 
            ENDIF 
            IF (sym_dom_mode_shape) THEN 
               WRITE (output_io, 4200) 
            ELSE 
               WRITE (output_io, 4250) 
            ENDIF 
         ENDIF 
      ENDIF 
   ENDIF 
 5000 FORMAT    ( ' Space Group Symmetry Operation'/                    &
                  '                               ')              
!
 3000 FORMAT    ( ' Generalized Symmetry Operation'/                    &
     &                   '   Axis in direct space      : ',3(2x,f9.4))  
 3010 FORMAT    ( '   Axis in reciprocal space  : ',3(2x,f9.4)) 
 3020 FORMAT    ( '   Origin of symmetry element: ',3(2x,f9.4),a) 
 3030 FORMAT    ( '   Rotation angle            : ',  2x,f9.4 ) 
 3040 FORMAT    ( '   Translation part(true)    : ',3(2x,f9.4)) 
 3045 FORMAT    ( '   Translation part(origin)  : ',3(2x,f9.4)/) 
 3050 FORMAT    ( '   Real space matrix         : ',4(2x,f9.4)/         &
     &                2( '                             : ',4(2x,f9.4)/))
 3060 FORMAT    ( '   Reciprocal space matrix   : ',3(2x,f9.4)/         &
     &                2( '                             : ',3(2x,f9.4)/))
 3070 FORMAT    ( '   Power of symmetry element : ', (2x,i4  )) 
 3080 FORMAT    ( '   Mode of power level       : ',2x,a) 
 3090 FORMAT    ( '   Type of symmetry element  : ',2x,a) 
 3100 FORMAT    ( '   Mode of symmetry operation: ',2x,a) 
 3110 FORMAT    ( '   Molecule status           : ',2x,a) 
 3210 FORMAT    ( '   Selected atom types       : ',2x,50(a9,1x)) 
 3220 FORMAT    ( '   Range of selected atoms   :   All atoms included') 
 3225 FORMAT( '   Range of selected atoms   :   Current environment') 
 3230 FORMAT    ( '   Range of selected atoms   : ',i9,' to ',i9) 
 3250 FORMAT    ( '   Given origin relative to  : ',2x,a) 
 3300 FORMAT    ( '   Selected molecule types   : ',2x,50(i4,1x)) 
 3310 FORMAT    ( '   Range of sel. molecules   : ',                    &
     &          '  All molecules included')                             
 3320 FORMAT    ( '   Range of sel. molecules   : ',i9,' to ',i9) 
 4100 FORMAT    ( '   Status of atoms in domain :   rotated') 
 4150 FORMAT    ( '   Status of shape of domain :   invariant') 
 4200 FORMAT    ( '   Status of shape of domain :   rotated') 
 4250 FORMAT    ( '   Status of atoms in domain :   invariant') 
!                                                                       
      END SUBROUTINE symm_show                      
!*****7*****************************************************************
END MODULE symm_menu
