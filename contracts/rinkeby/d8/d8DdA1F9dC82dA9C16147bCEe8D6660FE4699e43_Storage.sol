/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Storage {

    uint public number = 0;

    function increment(uint num) public  returns (uint){
        number = number+num;
        return number;
    }

    function decrement(uint num) public  returns (uint){
        number = number-num;
        return number;
    }

     function getNumber() public view  returns (uint){
        return number;
    }
}