@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Interface view student Tracking'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZKMH_I_STUDENT_REG
  as select from zkmh_student_reg
{
  key  student_uuid          as Studentuuid,
       registration_number   as Registrationnumber,
       student_name          as StudentName,
       email_address         as EmailAddress,
       mobile_number         as MobileNumber,
       address               as Address,
       city                  as City,
       batch_name            as BatchName,
       course_name           as CourseName,
       registration_date     as RegistrationDate,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       total_fees            as TotalFees,
       discount_percentage   as DiscountPercentage,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       discount_amount       as DiscountAmount,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       net_fee_payable       as NetFeePayable,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       amount_paid           as AmountPaid,
       @Semantics.amount.currencyCode: 'CurrencyCode'
       balance_amount        as BalanceAmount,
       currency_code         as CurrencyCode,
       payment_status        as PaymentStatus,
       student_status        as StudentStatus,
       remarks               as Remarks,
       @Semantics.user.createdBy: true
       created_by            as CreatedBy,
       @Semantics.systemDateTime.createdAt: true
       created_at            as CreatedAt,
       @Semantics.user.lastChangedBy: true
       last_changed_by       as LastChangedBy,
       @Semantics.systemDateTime.lastChangedAt: true
       last_changed_at       as LastChangedAt,
       @Semantics.systemDateTime.localInstanceLastChangedAt: true
       local_last_changed_at as LocalLastChangedAt

}
