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

    function Test(uint Limit) public {

        if(Total_Numbers<Limit) {

            for(uint i=Total_Numbers; i<=Limit; i++) {
            number storage num = Number[i];
            num.n = i;
            Total_Numbers = i;
            }

        } else {
            revert("Limit is smaller than Total Numbers");
        }
    }

}