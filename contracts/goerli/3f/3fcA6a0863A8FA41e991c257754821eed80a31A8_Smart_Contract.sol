// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.0 <=0.9.0;

import {BokkyPooBahsDateTimeLibrary} from './BokkyPooBahsDateTimeLibrary.sol';

contract Smart_Contract{
    using BokkyPooBahsDateTimeLibrary for uint;
    address payable private Owner;
    
    // Flats details:
    struct Flat {
        uint Flat_Size;
        string Flat_Name;
        string Flat_Address;
        uint Monthly_Cold_Rent;
        uint Monthly_Additional_Cost;
        uint Deposit;
        uint Accepted_Payment_Days;
        uint LatePayment_Penalty;
        uint TimeStamp;
        bool Vacancy;
        address Landlord;
        address CurrentTenant;
        bool Queue;
    }

    Flat private Current_Flat;
    function GetFlat() public view returns(Flat memory) {
        return Current_Flat;
    }

    struct PaymentSchedule {
        uint Payment01_Schedule;
        uint Payment02_Schedule;
        uint Payment03_Schedule;
        uint Payment04_Schedule;
        uint Payment05_Schedule;
        uint Payment06_Schedule;
        uint End_of_Rent;
    }

    PaymentSchedule private Payment_Schedule;
    function GetSchedule() public view returns(PaymentSchedule memory) {
        return Payment_Schedule;
    }

    struct MyStorage{
        uint SignedMonth;
        uint SignedYear;
        uint StartRentYear;
        uint StartRentMonth;
        uint Month2;
        uint Month3;
        uint Month4;
        uint Month5;
        uint Month6;
        uint Year2;
        uint Year3;
        uint Year4;
        uint Year5;
        uint Year6;
        uint EndMonth;
        uint EndYear;
        address TenantinQueue;
    }

    MyStorage private My_Storage;

    struct PaymentProgress{
        bool Payment01;
        bool Payment02;
        bool Payment03;
        bool Payment04;
        bool Payment05;
        bool Payment06;
        uint Warning;
        bool Renewal;
        bool Early_Cancellation;
    }

    PaymentProgress private Payment_Progress;

    function GetProgress() public view returns(PaymentProgress memory) {
        return Payment_Progress;
    }

    constructor() {
        Current_Flat.Flat_Size = 50;
        Current_Flat.Flat_Name = "Sample Flat";
        Current_Flat.Flat_Address = "Magdeburg";
        Current_Flat.Monthly_Cold_Rent = 1000000000000000000;
        Current_Flat.Monthly_Additional_Cost = 1000000000000000000;
        Current_Flat.Deposit = (Current_Flat.Monthly_Cold_Rent+ Current_Flat.Monthly_Additional_Cost)*2;
        Current_Flat.Accepted_Payment_Days = 5 days;
        Current_Flat.LatePayment_Penalty = (Current_Flat.Monthly_Cold_Rent+ Current_Flat.Monthly_Additional_Cost)*1/1000;
        Current_Flat.TimeStamp = 0;
        Current_Flat.Vacancy = true;
        Current_Flat.Landlord = msg.sender;
        Current_Flat.CurrentTenant = address(0);
        Owner = payable(msg.sender);
        Current_Flat.Queue = false;
    }

    modifier OnlyLandlord {
      require(msg.sender == Current_Flat.Landlord, "Only Landlord");
      _;
    }

    modifier OnlyTenant {
      require(msg.sender == Current_Flat.CurrentTenant, "Only Tenant");
      _;
    }

    modifier VacantFlat {
      require(Current_Flat.Vacancy == true, "Flat unavailable");
      _;
    }

    modifier OccupiedFlat {
      require(Current_Flat.Vacancy == false, "Flat occupied");
      _;
    }

    modifier Queing {
      require(Current_Flat.Queue == true, "No queuing tenant");
      _;
    }

    modifier UnQueing {
      require(Current_Flat.Queue == false, "Queuing");
      _;
    }


    event ModifyFlat(uint New_Size, string New_Name, string New_Address, uint New_Cold_Rent, uint New_Additional_Cost);
    function Modify_Flat(uint New_Size, string memory New_Name, string memory New_Address, uint New_Cold_Rent, uint New_Additional_Cost) public OnlyLandlord VacantFlat UnQueing {
        Flat storage New_Flat = Current_Flat;
        New_Flat.Flat_Size = New_Size;
        New_Flat.Flat_Name = New_Name;
        New_Flat.Flat_Address = New_Address;
        New_Flat.Monthly_Cold_Rent = New_Cold_Rent;
        New_Flat.Monthly_Additional_Cost = New_Additional_Cost;
        New_Flat.Deposit = (New_Flat.Monthly_Cold_Rent+ New_Flat.Monthly_Additional_Cost)*2;
        New_Flat.LatePayment_Penalty = (New_Flat.Monthly_Cold_Rent+ New_Flat.Monthly_Additional_Cost)*1/1000;
        emit ModifyFlat(New_Size, New_Name, New_Address, New_Cold_Rent, New_Additional_Cost);
    }

    // Tenant to sign the rental contract and pay deposit to the contract
    event SignAgreement(address Potential_Tenant, uint Deposit_Transfer);
    function Sign_Agreement() public payable VacantFlat UnQueing {
        require(msg.sender != Current_Flat.Landlord, "Not for Landlord");
        require(msg.value == Current_Flat.Deposit, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(Current_Flat.Deposit);
        My_Storage.TenantinQueue = msg.sender;
        Current_Flat.Queue = true;
        emit SignAgreement(msg.sender, msg.value);
    }

    event ApproveTenant(address Landlord, address Tenant);
    function Approve_Tenant() public OnlyLandlord Queing {
        Current_Flat.CurrentTenant = My_Storage.TenantinQueue;
        Current_Flat.Vacancy = false;
        Current_Flat.TimeStamp = 1642672800;
        My_Storage.TenantinQueue = address(0);
        Current_Flat.Queue = false;
        My_Storage.SignedMonth = Current_Flat.TimeStamp.getMonth();
        My_Storage.SignedYear = Current_Flat.TimeStamp.getYear();
        if (My_Storage.SignedMonth==12)  {
            My_Storage.StartRentMonth = 1; 
            My_Storage.StartRentYear = My_Storage.SignedYear + 1;
            }
        else  { 
            My_Storage.StartRentMonth =  My_Storage.SignedMonth + 1;
            My_Storage.StartRentYear = My_Storage.SignedYear;
            }
        Payment_Schedule.Payment01_Schedule = My_Storage.StartRentYear.timestampFromDate(My_Storage.StartRentMonth, 1);
        
        if (My_Storage.StartRentMonth==12) {
            My_Storage.Month2 = 1;
            My_Storage.Year2 = My_Storage.StartRentYear + 1;
            }
        else {
            My_Storage.Month2 = My_Storage.StartRentMonth + 1;
            My_Storage.Year2 = My_Storage.StartRentYear;
            }  
        Payment_Schedule.Payment02_Schedule = My_Storage.Year2.timestampFromDate(My_Storage.Month2, 1);
        
        if (My_Storage.Month2==12) {
            My_Storage.Month3 = 1;
            My_Storage.Year3 = My_Storage.Year2 + 1;
            }
        else {
            My_Storage.Month3 = My_Storage.Month2 + 1;
            My_Storage.Year3 = My_Storage.Year2;
        }
        Payment_Schedule.Payment03_Schedule = My_Storage.Year3.timestampFromDate(My_Storage.Month3, 1);

        if (My_Storage.Month3==12) {
            My_Storage.Month4 = 1;
            My_Storage.Year4 = My_Storage.Year3 + 1;
            }
        else {
            My_Storage.Month4 = My_Storage.Month3 + 1;
            My_Storage.Year4 = My_Storage.Year3;
        }
        Payment_Schedule.Payment04_Schedule = My_Storage.Year4.timestampFromDate(My_Storage.Month4, 1);
        
        if (My_Storage.Month4==12) {
            My_Storage.Month5 = 1;
            My_Storage.Year5 = My_Storage.Year4 + 1;
            }
        else {
            My_Storage.Month5 = My_Storage.Month4 + 1;
            My_Storage.Year5 = My_Storage.Year4;
        }
        Payment_Schedule.Payment05_Schedule = My_Storage.Year5.timestampFromDate(My_Storage.Month5, 1);

        if (My_Storage.Month5==12) {
            My_Storage.Month6 = 1;
            My_Storage.Year6 = My_Storage.Year5 + 1;
            }
        else {
            My_Storage.Month6 = My_Storage.Month5 + 1;
            My_Storage.Year6 = My_Storage.Year5;
        }
        Payment_Schedule.Payment06_Schedule = My_Storage.Year6.timestampFromDate(My_Storage.Month6, 1);

        if (My_Storage.Month6==12) {
            My_Storage.EndMonth = 1;
            My_Storage.EndYear = My_Storage.Year6 + 1;
            }
        else {
            My_Storage.EndMonth = My_Storage.Month6 + 1;
            My_Storage.EndYear = My_Storage.Year6;
        }
        Payment_Schedule.End_of_Rent = My_Storage.EndYear.timestampFromDate(My_Storage.EndMonth, 1) - 7300;
        emit ApproveTenant (msg.sender, Current_Flat.CurrentTenant);
    }

    event RejectTenant (address Landlord, uint Deposit_Return);
    function Reject_Tenant() public payable OnlyLandlord Queing {
        payable(My_Storage.TenantinQueue).transfer(Current_Flat.Deposit);
        Current_Flat.Queue = false;
        My_Storage.TenantinQueue = address(0);
        emit RejectTenant (msg.sender, msg.value);
    }

    struct InternalWarning{
        uint Warn01;
        uint Warn02;
        uint Warn03;
        uint Warn04;
        uint Warn05;
        uint Warn06;
    }
    
    InternalWarning private Internal_Warning;

    event Warning (uint Number_of_Warnings, address Tenant);
    function Warn() public OnlyLandlord OccupiedFlat {
        
        if (Payment_Progress.Payment01 == false && block.timestamp >= Payment_Schedule.Payment02_Schedule) Internal_Warning.Warn01 = 1;
        else Internal_Warning.Warn01 = 0;

        if (Payment_Progress.Payment02 == false && block.timestamp >= Payment_Schedule.Payment03_Schedule) Internal_Warning.Warn02 = 1;
        else Internal_Warning.Warn02 = 0;

        if (Payment_Progress.Payment03 == false && block.timestamp >= Payment_Schedule.Payment04_Schedule) Internal_Warning.Warn03 = 1;
        else Internal_Warning.Warn03 = 0;

        if (Payment_Progress.Payment04 == false && block.timestamp >= Payment_Schedule.Payment05_Schedule) Internal_Warning.Warn04 = 1;
        else Internal_Warning.Warn04 = 0;

        if (Payment_Progress.Payment05 == false && block.timestamp >= Payment_Schedule.Payment06_Schedule) Internal_Warning.Warn05 = 1;
        else Internal_Warning.Warn05 = 0;

        if (Payment_Progress.Payment06 == false && block.timestamp >= Payment_Schedule.End_of_Rent) Internal_Warning.Warn06 = 1;
        else Internal_Warning.Warn06 = 0;

        Payment_Progress.Warning = Internal_Warning.Warn01 + Internal_Warning.Warn02 + Internal_Warning.Warn03 + Internal_Warning.Warn04 + Internal_Warning.Warn05 + Internal_Warning.Warn06;
        emit Warning (Payment_Progress.Warning, Current_Flat.CurrentTenant);
    }

    event Payment1 (address Tenant, uint Payment_Amount);
    function Payment_01() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment01_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment01_Schedule, "Too soon");
        require(Payment_Progress.Payment01 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment01 = true;
        Payment_Schedule.Payment01_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.Payment02_Schedule) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment1 (msg.sender, msg.value);
    }

    event Payment2 (address Tenant, uint Payment_Amount);
    function Payment_02() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment02_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment02_Schedule, "Too soon");
        require(Payment_Progress.Payment02 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment02 = true;
        Payment_Schedule.Payment02_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.Payment03_Schedule) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment2 (msg.sender, msg.value);
    }

    event Payment3 (address Tenant, uint Payment_Amount);
    function Payment_03() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment03_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment03_Schedule, "Too soon");
        require(Payment_Progress.Payment03 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment03 = true;
        Payment_Schedule.Payment03_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.Payment04_Schedule) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment3 (msg.sender, msg.value);
    }

    event Payment4 (address Tenant, uint Payment_Amount);
    function Payment_04() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment04_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment04_Schedule, "Too soon");
        require(Payment_Progress.Payment04 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment04 = true;
        Payment_Schedule.Payment04_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.Payment05_Schedule) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment4 (msg.sender, msg.value);
    }

    event Payment5 (address Tenant, uint Payment_Amount);
    function Payment_05() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment05_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment05_Schedule, "Too soon");
        require(Payment_Progress.Payment05 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment05 = true;
        Payment_Schedule.Payment05_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.Payment06_Schedule) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment5 (msg.sender, msg.value);
    }

    event Payment6 (address Tenant, uint Payment_Amount);
    function Payment_06() public payable OnlyTenant {
        uint MonthlyPayment;
        if (block.timestamp <= Payment_Schedule.Payment06_Schedule + Current_Flat.Accepted_Payment_Days) MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost;
        else MonthlyPayment = Current_Flat.Monthly_Cold_Rent + Current_Flat.Monthly_Additional_Cost + Current_Flat.LatePayment_Penalty;
        require(block.timestamp >= Payment_Schedule.Payment06_Schedule, "Too soon");
        require(Payment_Progress.Payment06 == false, "Rent paid");
        require(msg.value == MonthlyPayment, "Wrong amount");
        payable(Current_Flat.Landlord).transfer(MonthlyPayment);
        Payment_Progress.Payment06 = true;
        Payment_Schedule.Payment06_Schedule = block.timestamp;
        if (Payment_Progress.Warning == 0) Payment_Progress.Warning = Payment_Progress.Warning;
        else if (block.timestamp >= Payment_Schedule.End_of_Rent) Payment_Progress.Warning = Payment_Progress.Warning - 1;
        else Payment_Progress.Warning = Payment_Progress.Warning;
        emit Payment6 (msg.sender, msg.value);
    }

    event TerminateAgreement (uint Payment_Breaches);
    function Terminate_Agreement() public OnlyLandlord OccupiedFlat {
        require(Payment_Progress.Warning >= 2, "No payment breach" );
        Current_Flat.TimeStamp = 0;
        Current_Flat.Vacancy = true;
        Current_Flat.CurrentTenant = address(0);
        Payment_Schedule.Payment01_Schedule = 0;
        Payment_Schedule.Payment02_Schedule = 0;
        Payment_Schedule.Payment03_Schedule = 0;
        Payment_Schedule.Payment04_Schedule = 0;
        Payment_Schedule.Payment05_Schedule = 0;
        Payment_Schedule.Payment06_Schedule = 0;
        Payment_Schedule.End_of_Rent = 0;
        Payment_Progress.Payment01 = false;
        Payment_Progress.Payment02 = false;
        Payment_Progress.Payment03 = false;
        Payment_Progress.Payment04 = false;
        Payment_Progress.Payment05 = false;
        Payment_Progress.Payment06 = false;
        Payment_Progress.Warning = 0;
        Payment_Progress.Renewal = false;
        Payment_Progress.Early_Cancellation = false;
        emit TerminateAgreement (Payment_Progress.Warning);
    }

    event Liquidate (uint Deposit_Return_Amount);
    function Liquidate_Agreement() public payable OnlyLandlord OccupiedFlat {
        require(block.timestamp > Payment_Schedule.Payment06_Schedule, "The flat is in the renting period!" );
        require(Payment_Progress.Warning < 2, "Tenant has more than 1 pending payment");
        require(msg.value <= Current_Flat.Deposit, "Wrong amount");
        uint Deposit_Return = msg.value;
        payable(Current_Flat.CurrentTenant).transfer(Deposit_Return);
        Current_Flat.TimeStamp = 0;
        Current_Flat.Vacancy = true;
        Current_Flat.CurrentTenant = address(0);
        Payment_Schedule.Payment01_Schedule = 0;
        Payment_Schedule.Payment02_Schedule = 0;
        Payment_Schedule.Payment03_Schedule = 0;
        Payment_Schedule.Payment04_Schedule = 0;
        Payment_Schedule.Payment05_Schedule = 0;
        Payment_Schedule.Payment06_Schedule = 0;
        Payment_Schedule.End_of_Rent = 0;
        Payment_Progress.Payment01 = false;
        Payment_Progress.Payment02 = false;
        Payment_Progress.Payment03 = false;
        Payment_Progress.Payment04 = false;
        Payment_Progress.Payment05 = false;
        Payment_Progress.Payment06 = false;
        Payment_Progress.Warning = 0;
        Payment_Progress.Renewal = false;
        Payment_Progress.Early_Cancellation = false;
        emit Liquidate (msg.value);
    }

    event RenewalRequest(address Request_Tenant);
    function Renewal_Request() public OnlyTenant {
        require(block.timestamp > Payment_Schedule.Payment06_Schedule, "Too soon" );
        require(Payment_Progress.Payment01 == true && Payment_Progress.Payment02 == true && Payment_Progress.Payment03 == true && Payment_Progress.Payment04 && Payment_Progress.Payment05 == true && Payment_Progress.Payment06 == true, "You have pending payment(s)");
        Payment_Progress.Renewal = true;
        emit RenewalRequest(msg.sender);
    }

    event RenewalConfirm(address Landlord, address Tenant);
    function Renewal_Confirm() public OnlyLandlord OccupiedFlat {
        require(Payment_Progress.Renewal == true, "No renewal request" );
        Current_Flat.TimeStamp = block.timestamp;
        My_Storage.SignedMonth = Current_Flat.TimeStamp.getMonth();
        My_Storage.SignedYear = Current_Flat.TimeStamp.getYear();
        if (My_Storage.SignedMonth==12)  {
            My_Storage.StartRentMonth = 1; 
            My_Storage.StartRentYear = My_Storage.SignedYear + 1;
            }
        else  { 
            My_Storage.StartRentMonth =  My_Storage.SignedMonth + 1;
            My_Storage.StartRentYear = My_Storage.SignedYear;
            }
        Payment_Schedule.Payment01_Schedule = My_Storage.StartRentYear.timestampFromDate(My_Storage.StartRentMonth, 1);
        
        if (My_Storage.StartRentMonth==12) {
            My_Storage.Month2 = 1;
            My_Storage.Year2 = My_Storage.StartRentYear + 1;
            }
        else {
            My_Storage.Month2 = My_Storage.StartRentMonth + 1;
            My_Storage.Year2 = My_Storage.StartRentYear;
            }  
        Payment_Schedule.Payment02_Schedule = My_Storage.Year2.timestampFromDate(My_Storage.Month2, 1);
        
        if (My_Storage.Month2==12) {
            My_Storage.Month3 = 1;
            My_Storage.Year3 = My_Storage.Year2 + 1;
            }
        else {
            My_Storage.Month3 = My_Storage.Month2 + 1;
            My_Storage.Year3 = My_Storage.Year2;
        }
        Payment_Schedule.Payment03_Schedule = My_Storage.Year3.timestampFromDate(My_Storage.Month3, 1);

        if (My_Storage.Month3==12) {
            My_Storage.Month4 = 1;
            My_Storage.Year4 = My_Storage.Year3 + 1;
            }
        else {
            My_Storage.Month4 = My_Storage.Month3 + 1;
            My_Storage.Year4 = My_Storage.Year3;
        }
        Payment_Schedule.Payment04_Schedule = My_Storage.Year4.timestampFromDate(My_Storage.Month4, 1);
        
        if (My_Storage.Month4==12) {
            My_Storage.Month5 = 1;
            My_Storage.Year5 = My_Storage.Year4 + 1;
            }
        else {
            My_Storage.Month5 = My_Storage.Month4 + 1;
            My_Storage.Year5 = My_Storage.Year4;
        }
        Payment_Schedule.Payment05_Schedule = My_Storage.Year5.timestampFromDate(My_Storage.Month5, 1);

        if (My_Storage.Month5==12) {
            My_Storage.Month6 = 1;
            My_Storage.Year6 = My_Storage.Year5 + 1;
            }
        else {
            My_Storage.Month6 = My_Storage.Month5 + 1;
            My_Storage.Year6 = My_Storage.Year5;
        }
        Payment_Schedule.Payment06_Schedule = My_Storage.Year6.timestampFromDate(My_Storage.Month6, 1);

        if (My_Storage.Month6==12) {
            My_Storage.EndMonth = 1;
            My_Storage.EndYear = My_Storage.Year6 + 1;
            }
        else {
            My_Storage.EndMonth = My_Storage.Month6 + 1;
            My_Storage.EndYear = My_Storage.Year6;
        }
        Payment_Schedule.End_of_Rent = My_Storage.EndYear.timestampFromDate(My_Storage.EndMonth, 1) - 3601;
        Payment_Progress.Payment01 = false;
        Payment_Progress.Payment02 = false;
        Payment_Progress.Payment03 = false;
        Payment_Progress.Payment04 = false;
        Payment_Progress.Payment05 = false;
        Payment_Progress.Payment06 = false;
        Payment_Progress.Warning = 0;
        Payment_Progress.Renewal = false;
        Payment_Progress.Early_Cancellation = false;
        emit RenewalConfirm(msg.sender, Current_Flat.CurrentTenant);
    }

    event RejectRenewal(address Tenant);
    function Renewal_Reject() public OnlyLandlord OccupiedFlat {
        require(Payment_Progress.Renewal == true, "No renewal request" );
        Payment_Progress.Renewal = false;
        emit RejectRenewal(Current_Flat.CurrentTenant);
    }

    //Function getBalance() public view returns(uint){
    //return address(this).balance;
    //}

    event EarlyCancel(address Tenant);
    function EarlyCancel_Request() public OnlyTenant {
        require (block.timestamp < Payment_Schedule.Payment06_Schedule,"Passed Request period");
        if (block.timestamp >= Payment_Schedule.Payment01_Schedule && block.timestamp < Payment_Schedule.Payment02_Schedule) require(Payment_Progress.Payment01 == true, "Pending payment(s)");
        else if (block.timestamp >= Payment_Schedule.Payment02_Schedule && block.timestamp < Payment_Schedule.Payment03_Schedule) require(Payment_Progress.Payment01 == true && Payment_Progress.Payment02 == true, "Pending payment(s)");
        else if (block.timestamp >= Payment_Schedule.Payment03_Schedule && block.timestamp < Payment_Schedule.Payment04_Schedule) require(Payment_Progress.Payment01 == true && Payment_Progress.Payment02 == true && Payment_Progress.Payment03 == true, "Pending payment(s)");
        else if (block.timestamp >= Payment_Schedule.Payment04_Schedule && block.timestamp < Payment_Schedule.Payment05_Schedule) require(Payment_Progress.Payment01 == true && Payment_Progress.Payment02 == true && Payment_Progress.Payment03 == true && Payment_Progress.Payment04 == true, "Pending payment(s)");
        else if (block.timestamp >= Payment_Schedule.Payment05_Schedule && block.timestamp < Payment_Schedule.Payment06_Schedule) require(Payment_Progress.Payment01 == true && Payment_Progress.Payment02 == true && Payment_Progress.Payment03 == true && Payment_Progress.Payment04 == true && Payment_Progress.Payment05 == true, "Pending payment(s)");
        Payment_Progress.Early_Cancellation = true;
        emit EarlyCancel(msg.sender);
    }

    event EarlyCancelConfirm(address Landlord, uint Deposit_Return_Amount);
    function EarlyCancel_Confirm() public payable OnlyLandlord {
        require(Payment_Progress.Early_Cancellation == true, "No early cancellation request");
        require(msg.value <= Current_Flat.Deposit, "Wrong amount");
        uint Deposit_Return = msg.value;
        payable(Current_Flat.CurrentTenant).transfer(Deposit_Return);
        Current_Flat.TimeStamp = 0;
        Current_Flat.Vacancy = true;
        Current_Flat.CurrentTenant = address(0);
        Payment_Schedule.Payment01_Schedule = 0;
        Payment_Schedule.Payment02_Schedule = 0;
        Payment_Schedule.Payment03_Schedule = 0;
        Payment_Schedule.Payment04_Schedule = 0;
        Payment_Schedule.Payment05_Schedule = 0;
        Payment_Schedule.Payment06_Schedule = 0;
        Payment_Schedule.End_of_Rent = 0;
        Payment_Progress.Payment01 = false;
        Payment_Progress.Payment02 = false;
        Payment_Progress.Payment03 = false;
        Payment_Progress.Payment04 = false;
        Payment_Progress.Payment05 = false;
        Payment_Progress.Payment06 = false;
        Payment_Progress.Warning = 0;
        Payment_Progress.Renewal = false;
        Payment_Progress.Early_Cancellation = false;
        emit EarlyCancelConfirm(msg.sender, msg.value);
    }

    function Deactivate_Contract() public OnlyLandlord VacantFlat UnQueing {
        require(msg.sender == Owner, "Only Landlord");
        selfdestruct(Owner);
    }
}