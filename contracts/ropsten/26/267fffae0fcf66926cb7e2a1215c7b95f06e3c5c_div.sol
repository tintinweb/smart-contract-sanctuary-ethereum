/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract div {
    uint internal mul = 10**18;
    function divZero(uint _n1, uint _n2) public view returns(uint) {
        return((_n1*mul)/ _n2);
    }
}