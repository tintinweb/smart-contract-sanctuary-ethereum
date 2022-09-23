// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StorageV2 {
    uint public num1;
    uint public num2;
    function set_num(uint n1, uint n2) public {
        num1 = n1;
        num2 = n2;
    }

    function display_num() public view returns(uint, uint) {        
        return (num1,num2);    
    }

    function multiply() public view returns (uint) {
        return (num1*num2);
    }
}