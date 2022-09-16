/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;



contract Testcontract{
    constructor(){

    }

    function getData(string memory name) public pure returns(string memory){
        return name;
    }
}