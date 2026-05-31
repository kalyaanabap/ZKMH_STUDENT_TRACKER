CLASS lhc_ZKMH_I_STUDENT_REG DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Student RESULT result.

    "Actions
    METHODS markAsActive FOR MODIFY
      IMPORTING keys FOR ACTION Student~markAsActive RESULT result.
    METHODS markAsCompleted FOR MODIFY
      IMPORTING keys FOR ACTION Student~markAsCompleted RESULT result.
    METHODS placeOnHold FOR MODIFY
      IMPORTING keys FOR ACTION Student~placeOnHold RESULT result.

    "Determinations
    METHODS calculateFees FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Student~calculateFees.
    METHODS setInitialDefaults FOR DETERMINE ON SAVE
      IMPORTING keys FOR Student~setInitialDefaults.
    METHODS validateAmountPaid FOR VALIDATE ON SAVE
      IMPORTING keys FOR Student~validateAmountPaid.

    "Validations
    METHODS validateDiscount FOR VALIDATE ON SAVE
      IMPORTING keys FOR Student~validateDiscount.
    METHODS validateEmail FOR VALIDATE ON SAVE
      IMPORTING keys FOR Student~validateEmail.
    METHODS validateMobile FOR VALIDATE ON SAVE
      IMPORTING keys FOR Student~validateMobile.
    METHODS validateTotalFees FOR VALIDATE ON SAVE
      IMPORTING keys FOR Student~validateTotalFees.

ENDCLASS.

CLASS lhc_ZKMH_I_STUDENT_REG IMPLEMENTATION.

  METHOD get_instance_authorizations.
    "Delete Rules : Prevent deletion if fees are paid or student is completed
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( PaymentStatus StudentStatus ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      DATA(lv_delete_auth) = if_abap_behv=>auth-allowed.

      IF requested_authorizations-%delete = if_abap_behv=>mk-on.
        IF ls_student-PaymentStatus = 'PARTIAL' OR ls_student-PaymentStatus = 'PAID'.
          lv_delete_auth = if_abap_behv=>auth-unauthorized.
        ENDIF.
        IF ls_student-StudentStatus = 'COMPLETED'.
          lv_delete_auth = if_abap_behv=>auth-unauthorized.
        ENDIF.
      ENDIF.

      APPEND VALUE #( %tky    = ls_student-%tky
                      %update = if_abap_behv=>auth-allowed
                      %delete = lv_delete_auth ) TO result.
    ENDLOOP.

  ENDMETHOD.

  METHOD markAsActive.
    "Change Status to Active
    MODIFY ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
           ENTITY Student
           UPDATE FIELDS ( StudentStatus )
              WITH VALUE #( FOR ls_key IN keys ( %tky          = ls_key-%tky
                                                 StudentStatus = 'ACTIVE' ) ).

    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
         ENTITY Student
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(lt_students).

    result = VALUE #( FOR ls_student IN lt_students ( %tky   = ls_student-%tky
                                                      %param = ls_student ) ).
  ENDMETHOD.

  METHOD markAsCompleted.
    "Change status to completed only if fully paid
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
      ENTITY Student
      FIELDS ( PaymentStatus ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      IF ls_student-PaymentStatus = 'PAID'.
        MODIFY ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
            ENTITY Student
            UPDATE FIELDS ( StudentStatus )
            WITH VALUE #( FOR ls_key IN keys ( %tky          = ls_key-%tky
                                               StudentStatus = 'COMPLETED' ) ).
      ELSE.
        APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
        APPEND VALUE #( %tky = ls_student-%tky
                        %msg = new_message( id = 'SY'
                                            severity = if_abap_behv_message=>severity-error
                                            number = '002'
                                            v1 = 'Cannot mark completed' ) ) TO reported-student.
      ENDIF.

      READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_updated).

      result = VALUE #( FOR ls_updated IN lt_updated ( %tky = ls_updated-%tky
                                                       %param = ls_updated ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD placeOnHold.
    "Change Status to ONHOLD
    MODIFY ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        UPDATE FIELDS ( StudentStatus )
        WITH VALUE #( FOR ls_key IN keys ( %tky = ls_key-%tky
                                           StudentStatus = 'ONHOLD' ) ).

    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(lt_updated).

    result = VALUE #( FOR ls_updated IN lt_updated ( %tky = ls_updated-%tky
                                                     %param = ls_updated ) ).
  ENDMETHOD.

  METHOD calculateFees.
    "Automatic calculations for fees and payment status
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( TotalFees DiscountPercentage AmountPaid )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      DATA(lv_Disc_amount) = ( ls_student-TotalFees * ls_student-DiscountPercentage ) / 100 .
      DATA(lv_net_payable) = ls_student-TotalFees - lv_disc_amount.
      DATA(lv_balance)     = lv_net_payable - ls_student-AmountPaid.

      IF lv_balance < 0.
        lv_balance = 0.
      ENDIF.

      DATA(lv_status) = COND char7( WHEN lv_balance = 0 THEN 'PAID'
                                WHEN ls_student-AmountPaid = 0 THEN 'PENDING'
                                ELSE 'PARTIAL' ).

      MODIFY ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
      ENTITY Student
      UPDATE FIELDS ( DiscountAmount NetFeePayable BalanceAmount PaymentStatus )
      WITH VALUE #( (  %tky           = ls_student-%tky
                       DiscountAmount = lv_disc_amount
                       NetFeePayable  = lv_net_payable
                       BalanceAmount  = lv_balance
                       PaymentStatus  = lv_status ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD setInitialDefaults.
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( Registrationnumber RegistrationDate StudentStatus )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      DATA(lv_reg_no) = 'REG-' && cl_abap_context_info=>get_system_time(  ).
      MODIFY ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
          ENTITY Student
          UPDATE FIELDS ( Registrationnumber RegistrationDate StudentStatus )
          WITH VALUE #( ( %tky               = ls_student-%tky
                          Registrationnumber = lv_reg_no
                          RegistrationDate   = cl_abap_context_info=>get_system_date( )
                          StudentStatus      = 'ACTIVE' ) ).
    ENDLOOP.
  ENDMETHOD.

  METHOD validateAmountPaid.
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( NetFeePayable AmountPaid ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      IF ls_student-AmountPaid > ls_student-NetFeePayable.
        APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
        APPEND VALUE #( %tky = ls_student-%tky
                        %msg = new_message( id = 'SY'
                                            number = '002'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Amount paid cannot exceed netpayable amount' ) )
                           TO reported-student.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDiscount.
    READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
          ENTITY Student
          FIELDS ( DiscountPercentage ) WITH CORRESPONDING #( keys )
          RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
      IF ls_student-DiscountPercentage > 50 OR ls_student-DiscountPercentage < 0.
        APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
        APPEND VALUE #( %tky = ls_student-%tky
                        %msg = new_message( id = 'SY'
                                            number = '002'
                                            severity = if_abap_behv_message=>severity-error
                                            v1 = 'Enter Discount upto 50%' ) )
                           TO reported-student.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

    METHOD validateEmail.
        READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( EmailAddress ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
        FIND REGEX '^.+@.+$' IN ls_student-EmailAddress.
        IF sy-subrc <> 0.
            APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
            APPEND VALUE #( %tky = ls_student-%tky
                            %msg = new_message( id = 'SY'
                                                number = '002'
                                                severity = if_abap_behv_message=>severity-error
                                                v1 = 'Enter valid email address' ) )
                               TO reported-student.
        ENDIF.
    ENDLOOP.
    ENDMETHOD.

    METHOD validateMobile.
        READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( MobileNumber ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
        IF ls_student-MobileNumber CN '0123456789' OR STRLEN( ls_student-MobileNumber ) <> 10.
            APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
            APPEND VALUE #( %tky = ls_student-%tky
                            %msg = new_message( id = 'SY'
                                                number = '002'
                                                severity = if_abap_behv_message=>severity-error
                                                v1 = 'Mobile Number must be 10 digits' ) )
                               TO reported-student.
        ENDIF.
    ENDLOOP.
    ENDMETHOD.

    METHOD validateTotalFees.
        READ ENTITIES OF zkmh_i_student_reg IN LOCAL MODE
        ENTITY Student
        FIELDS ( TotalFees ) WITH CORRESPONDING #( keys )
        RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).
        IF ls_student-TotalFees <= 0.
            APPEND VALUE #( %tky = ls_student-%tky ) TO failed-student.
            APPEND VALUE #( %tky = ls_student-%tky
                            %msg = new_message( id = 'SY'
                                                number = '002'
                                                severity = if_abap_behv_message=>severity-error
                                                v1 = 'Total course fee must not be 0.' ) )
                               TO reported-student.
        ENDIF.
    ENDLOOP.
    ENDMETHOD.

ENDCLASS.
