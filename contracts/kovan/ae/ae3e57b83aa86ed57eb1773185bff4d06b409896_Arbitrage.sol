/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Arbitrage {
    function test(uint a,uint b)public pure returns(uint) {
        uint c = a/b;
        return c;
    }

    function test1(uint a, uint b) public pure returns(uint){
        uint c = (a-b) / 3600/8;
        return c;
    }
    uint inteRate = 5479452054794520;
    uint inteRateDeno = 100000000000000000000;
    function test2(uint a, uint b) public view returns(uint){
        uint c = (a-b) / 3600/8 * inteRate/inteRateDeno;
        return c;
    }
}