/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Demo {
    uint[] public number;
    function set(uint _num) public {
       number.push(_num);
    }
}