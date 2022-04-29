/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

contract ExpReportSC {

    /**
     * Enums
     */

    enum ERStatus { PENDING, APPROVED, REJECTED, PAID }
        

    /**
     * Storage
     */

    address public owner;

    uint public balance;

    mapping (string => Employee) public employees;

    mapping (uint16 => ExpenseReport) public expenseReports;

    /**
     * Structs
     */

    struct Employee {
        string emailAddress;
        address payable empAddress;
        string fullName;
        uint16 amountPendingApproval;
        uint16 amountApproved;
        uint16 amountPaid;
        uint16 amountDenied;
    }

    struct ExpenseReport {
        uint16 id;
        string employeeEmailAddress;
        Employee ownerEmployee;
        uint presentationDate;
        uint16 amount;
        ERStatus status;
        uint statusDate;
    }


    constructor()
    {
        owner = msg.sender;
    }

    /**
     * Functions
     */
    function addFunds() public payable {
      require(msg.sender == owner, "Only the owner of the contract can add to its balance");
      balance += msg.value;
    }

    function newEmployee(string memory emailAddress, address payable empAddress, string memory fullName)
      public 
    {
        /* 
        employees.addEmployee(this, emailAddress, empAddress, fullName)
        */
        employees[emailAddress].emailAddress = emailAddress;
        employees[emailAddress].amountApproved = 0;
        employees[emailAddress].amountPaid = 0;
        employees[emailAddress].amountDenied = 0;
        employees[emailAddress].empAddress = empAddress;

        employees[emailAddress].fullName = fullName;
    }

    function newExpenseReport(uint16 expenseReportId, uint16 expenseReportAmount, string memory reportEmployee)
      public 
    {
        /* 
        expenseReports.addExpenseReport(THIS, expenseReportId, reportEmployee.emailAddress, expenseReportAmount) . 

FOR ALL employees WHERE (employees = reportEmployee)
DO employees.notifyPending(employees, expenseReportAmount)
        */
        Employee storage reportEmployeeInstance = employees[reportEmployee];

        expenseReports[expenseReportId].id = expenseReportId;
        expenseReports[expenseReportId].presentationDate = block.timestamp;
        expenseReports[expenseReportId].status = ERStatus.PENDING;
        expenseReports[expenseReportId].statusDate = block.timestamp;
        expenseReports[expenseReportId].employeeEmailAddress = reportEmployeeInstance.emailAddress;
        expenseReports[expenseReportId].amount = expenseReportAmount;

        notifyPending(reportEmployeeInstance.emailAddress, expenseReportAmount);

        emit notifyChangeInStatus(expenseReportId, reportEmployeeInstance.fullName, "Created. Pending approval or rejection");
    }

    function approveExpReport(string memory employee, uint16 expReport)
      public 
    {
        /* 
        FOR ALL employees WHERE (employees = employee)
DO employees.notifyApproval(employees, expReport.amount) . 

FOR ALL expenseReports WHERE (expenseReports = expReport)
DO expenseReports.approve(expenseReports)
        */
        Employee storage employeeInstance = employees[employee];
        ExpenseReport storage expReportInstance = expenseReports[expReport];

        notifyApproval(employeeInstance.emailAddress, expReportInstance.amount);
        approve(expReport);

        emit notifyChangeInStatus(expReport, employeeInstance.fullName, "Approved. Pending payment");
    }

    function rejectExpReport(string memory employee, uint16 expReport)
      public 
    {
        /* 
        FOR ALL employees WHERE (employees = employee)
DO employees.notifyRejection(employees, expReport.amount) . 

FOR ALL expenseReports WHERE (expenseReports = expReport)
DO expenseReports.reject(expenseReports)
        */
        Employee storage employeeInstance = employees[employee];
        ExpenseReport storage expReportInstance = expenseReports[expReport];

        notifyRejection(employeeInstance.emailAddress, expReportInstance.amount);
        reject(expReport);

        emit notifyChangeInStatus(expReport, employeeInstance.fullName, "Rejected");
    }

    function payExpReport(string memory employee, uint16 expReport)
      public 
    {
        /* 
        FOR ALL employees WHERE (employees = employee)
DO employees.notifyPayment(employees, expReport.amount) . 

FOR ALL expenseReports WHERE (expenseReports = expReport)
DO expenseReports.pay(expenseReports)
        */
        Employee storage employeeInstance = employees[employee];
        ExpenseReport storage expReportInstance = expenseReports[expReport];

        require(balance >= expReportInstance.amount, "Insufficient funds to fulfill payment");
        balance -= expReportInstance.amount;

        notifyPayment(employeeInstance.emailAddress, expReportInstance.amount);
        pay(expReport);

        fulfillPayment(employeeInstance.emailAddress, expReportInstance.amount);

        emit notifyChangeInStatus(expReport, employeeInstance.fullName, "Payment fulfilled");
    }

    function fulfillPayment(string memory employee, uint16 expReport) 
        private
    {
        Employee storage employeeInstance = employees[employee];
        ExpenseReport storage expReportInstance = expenseReports[expReport];
        balance -= expReportInstance.amount;
        employeeInstance.empAddress.transfer(expReportInstance.amount);
    }

    function notifyApproval(string memory p_thisEmployee, uint16 amount)
      private 
    {
        Employee storage instance = employees[p_thisEmployee];
        instance.amountPendingApproval = instance.amountPendingApproval - amount;
        instance.amountApproved = instance.amountApproved + amount;
    }

    function notifyRejection(string memory p_thisEmployee, uint16 amount)
      private 
    {
        Employee storage instance = employees[p_thisEmployee];
        instance.amountPendingApproval = instance.amountPendingApproval - amount;
        instance.amountDenied = instance.amountDenied + amount;
    }

    function notifyPayment(string memory p_thisEmployee, uint16 amount)
      private 
    {
        Employee storage instance = employees[p_thisEmployee];
        instance.amountApproved = instance.amountApproved - amount;
        instance.amountPaid = instance.amountPaid + amount;
    }

    function notifyPending(string memory p_thisEmployee, uint16 amount)
      private 
    {
        Employee storage instance = employees[p_thisEmployee];
        instance.amountPendingApproval = instance.amountPendingApproval + amount;
    }

    function approve(uint16 p_thisExpenseReport)
      private 
    {
        ExpenseReport storage instance = expenseReports[p_thisExpenseReport];
        require(instance.status == ERStatus.PENDING, "The expense report should be PENDING");
        instance.status = ERStatus.APPROVED;
        instance.statusDate = block.timestamp;
    }

    function reject(uint16 p_thisExpenseReport)
      private 
    {
        ExpenseReport storage instance = expenseReports[p_thisExpenseReport];
        require(instance.status == ERStatus.PENDING, "The expense report should be PENDING");
        instance.status = ERStatus.REJECTED;
        instance.statusDate = block.timestamp;
    }

    function pay(uint16 p_thisExpenseReport)
      private 
    {
        ExpenseReport storage instance = expenseReports[p_thisExpenseReport];
        require(instance.status == ERStatus.APPROVED, "The expense report should be APPROVED");
        instance.status = ERStatus.PAID;
        instance.statusDate = block.timestamp;
    }

    function findEmployee(string memory emailAddress) public view returns(Employee memory) {
      return employees[emailAddress];
    }
    
    function findExpenseReport(uint16 id) public view returns(ExpenseReport memory) {
      return expenseReports[id];
    }

    /**
     * Events
     */
    event notifyChangeInStatus(uint16 expenseReport, string employeeName, string message);
}