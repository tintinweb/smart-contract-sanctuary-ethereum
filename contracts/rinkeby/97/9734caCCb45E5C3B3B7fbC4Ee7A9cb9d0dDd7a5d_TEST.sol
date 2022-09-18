/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;



contract TEST {

    struct number {
        uint n;
    }
    mapping(uint => number) public Number;

    uint public Total_Numbers;

    function loop(uint limit) public {

        for(uint i=0; i<=limit; i++) {
            number storage num = Number[i];
            num.n = i;
            Total_Numbers = i;
        }
    }

}