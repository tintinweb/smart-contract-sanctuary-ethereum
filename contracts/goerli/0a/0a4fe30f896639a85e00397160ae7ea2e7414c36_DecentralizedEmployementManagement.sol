/**
 *Submitted for verification at Etherscan.io on 2022-12-03
*/

pragma solidity ^0.8.0;

/// @title A Decentralized Employement Management for Employers
/// @author Soumen Jana and Manish Kumar
/// @notice This contract is a WIP and may contain bugs. Kindly use at your own risk.
contract DecentralizedEmployementManagement {
    
    address immutable employer_address;

    uint number_of_employees;
    uint max_working_hour; 
    uint service_fee = 1 ;

    address[] public employees;

    mapping(address => bool) public employee_status;
    mapping(address => uint256) public salary;
    mapping(address => uint256) public working_hours;
    mapping(address => uint) public notice_period_counter;
    mapping(address => uint256) public per_hours_pay; 

    //Employer

    /// @param employer_head The head of all the employees
    /// @param work_hour The maximum working hours in a month an employee can work
    constructor(address employer_head, uint work_hour) payable {
        require(msg.value >= 1 && work_hour > 0, "Required Security Deposit"); // For Security
        employer_address = employer_head;
        max_working_hour = work_hour;
    }

    receive() external payable {}

    modifier check_employer_head() {
        require(employer_address == msg.sender, "Only Employer head can call");
        _;
    }

    modifier check_employee() {
        require(employee_status[msg.sender], "Not a Employee");
        _;
    }

    /// @param employee_address The addresses of all the employees to be added in the organisation
    /// @param hour_rate The per hour rate of the corresponding employee
    function add_employee(address[] memory employee_address, uint[] memory hour_rate) public check_employer_head() {

        require(employee_address.length == hour_rate.length, "incorrect format");

        for(uint i=0; i< employee_address.length; i++){
            employees[number_of_employees] = employee_address[i];
            number_of_employees += 1;
        }
        
    }
    
    /// @param employee_address_invoke The address of the employee who wants to invoke the employment
    function invoke_employment (address employee_address_invoke) public check_employer_head() {
        for(uint i = 0; i < employees.length; i++) {
            if(employees[i] == employee_address_invoke) {
                employees[i] = address(0);
            }
        }
    }

    /// @return total_pay The total amount to be paid by the employer_head to all the employees
    function total_number_of_hours() public view returns(uint) {

        uint total_pay;
        for(uint i =0; i < employees.length; i++) {
            uint total_hours = working_hours[employees[i]];
            uint per_hourly_pay = per_hours_pay[employees[i]];
            total_pay += (total_hours * per_hourly_pay);
        }
        return total_pay;
    }

    /// @param total_pay The total amount to be paid by the employer_head to all the employees
    function add_money (uint total_pay) public payable{
        
        require(msg.value >= total_pay, "amount not sufficient to pay all employees");
    }
    
    /// @param total_pay The total amount to be paid by the employer_head to all the employees
    function pay_employees (uint total_pay) public payable {

        require(address(this).balance >= total_pay, "not sufficient amount");

        for(uint i = 0; i < employees.length; i++) {
            uint total_hours = working_hours[employees[i]];
            uint per_hourly_pay = per_hours_pay[employees[i]];
            uint total_pay_1 = (total_hours * per_hourly_pay);
            payable(employees[i]).transfer(total_pay_1);
            working_hours[employees[i]] = 0; //after payment hours reset to zero
        }
    }

    function withdraw_service() public payable {
        require(msg.sender == employer_address);
        payable(employer_address).transfer(address(this).balance - service_fee);
    }

    //Employees

    /// @param working_hours_added_by_employee The amount of work done by the employee
    function add_hours(uint256 working_hours_added_by_employee) public check_employee() {

        require(working_hours_added_by_employee <= max_working_hour, "cannot be more than max working hours" );
        working_hours[msg.sender] = working_hours_added_by_employee;
    }

    function request_resignation() public check_employee(){

        notice_period_counter[msg.sender] = block.timestamp ;
    }

    function confirm_resgnation() public check_employee() {

        require(notice_period_counter[msg.sender] + 30 days < block.timestamp ,"cannot be confirmed before notice period");

        employee_status[msg.sender] = false;
        salary[msg.sender] = 0;
        working_hours[msg.sender] = 0;

    }

    function cancel_resignation() public check_employee(){

        require(notice_period_counter[msg.sender] + 30 days > block.timestamp, "cannot cancel after notice period"); 
        notice_period_counter[msg.sender] = 0;        
        
    } 
}