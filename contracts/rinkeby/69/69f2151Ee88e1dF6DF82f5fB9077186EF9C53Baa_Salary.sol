// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Salary {
    uint public myAge;
    uint public mySalary;

    // constructor(uint _val) {
    //     val = _val;
    // }

    function initialize(uint _age, uint _sal) external {
        myAge = _age;
        mySalary = _sal;
    }

}