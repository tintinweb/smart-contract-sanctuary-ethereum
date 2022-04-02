// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract SalaryV2 {
    uint public myAge;
    uint public mySalary; //reverse the order to test which variables gets updated
    
    // constructor(uint _val) {
    //     val = _val;
    // }

    function increaseSalary() external {
        mySalary += 100;
    }

}