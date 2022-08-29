/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage{
    uint public num1;
    uint public num2;
    function set_num(uint n1, uint n2) public {
        num1 = n1;
        num2 = n2;
    }

    function display_num() public view returns(uint, uint) {        
        return (num1,num2);    
    }
}