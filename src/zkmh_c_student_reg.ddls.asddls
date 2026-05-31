@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'consumption view  student reg details'
@Metadata.allowExtensions: true
define root view entity ZKMH_c_STUDENT_REG 
provider contract transactional_query
as projection on ZKMH_I_STUDENT_REG
{
    key Studentuuid,
    Registrationnumber,
    StudentName,
    EmailAddress,
    MobileNumber,
    Address,
    City,
    BatchName,
    CourseName,
    RegistrationDate,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    TotalFees,
    DiscountPercentage,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    DiscountAmount,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    NetFeePayable,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    AmountPaid,
    @Semantics.amount.currencyCode: 'CurrencyCode'
    BalanceAmount,
    CurrencyCode,
    PaymentStatus,
    StudentStatus,
    Remarks,
    CreatedBy,
    CreatedAt,
    LastChangedBy,
    LastChangedAt,
    LocalLastChangedAt
    
}
