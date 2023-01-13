//SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Employee {   
       
    uint normalWorkingHours = 40;

    enum Departments {
        GARDENING,
        CLOTHING,
        TOOLS
    }

    string firstName;
    string lastName;
    uint hourlyPay;

    Departments departments;  
    

    constructor(string memory _firstName, string memory _lastName, uint _hourlyPay, Departments _department){
        firstName = _firstName;
        lastName = _lastName;
        hourlyPay = _hourlyPay;
        departments = _department;
    }

    // overtime pay is 2*regular hourlypay
    function getWeeklyPay(uint hoursWorked) public view returns (uint){
                
        if (hoursWorked <= normalWorkingHours){
            return hoursWorked * hourlyPay;
             
        }
        uint overtimePay = 2 * hourlyPay * (hoursWorked - normalWorkingHours);
        return 40 * hourlyPay + overtimePay;       
        
    }

    function getFirstName() public view returns (string memory) {
        return firstName;
    }

}

contract Manager is Employee {
    Employee[] subordinates;

    constructor(string memory _firstName, string memory _lastName, uint _hourlyPay, Departments _department)
    Employee(_firstName,_lastName,_hourlyPay,_department){}
    

    //this function takes the required argument to create the new employee and add it to the manager's subordinates

    function addSubordinate(string memory _firstName, string memory _lastName, 
    uint _hourlyPay, Departments _department) public {
        
        Employee employee = new Employee(_firstName,_lastName,_hourlyPay,_department);
        subordinates.push(employee);
        
    }

    // this function returns a string[] containing the first name of all of its subordinates 
    function getSubordinates() public view returns (string[] memory) {
        string[] memory names = new string[](subordinates.length);
        for(uint idx; idx < subordinates.length; idx++){
            names[idx] = subordinates[idx].getFirstName();
        }
        return names;
    }
}