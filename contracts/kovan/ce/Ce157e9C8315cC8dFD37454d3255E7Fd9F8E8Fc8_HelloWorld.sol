/**
 *Submitted for verification at Etherscan.io on 2022-04-03
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract HelloWorld {
    uint8 num = 0;

    function sayHello() public returns (string memory) {
        num+=1;
        return "Hello World";
    }

    function getNum() public view returns (uint8) {
        return num;
    }
}