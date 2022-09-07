/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity  ^0.8.0;

contract Car{
    int public tyres;
    int public numberOfTyres;
    string internal  str; // internal => like protected
    address public  user1;

    function change() public {
        numberOfTyres = 1024;
    }
}


/**
    inherited from car contract 
    is => is used for inheritance
    external => like can use without inhritance
*/
contract BMW is Car {
    uint[10] public  arr;

    mapping (uint=> uint) public  Salary;
    
    function changeSTR() external {
        str = "hello";
    }

    function readSTR() external  view  returns(string memory){
        return  str;
    }

    function pushData(uint _data, uint _index) public {
        uint num = 10;
        arr[_index] = _data;
        arr[_index+1] = num;
    }

    function enterSalary(uint _salary, uint _code) public {
        Salary[_code] = _salary;
    }
}