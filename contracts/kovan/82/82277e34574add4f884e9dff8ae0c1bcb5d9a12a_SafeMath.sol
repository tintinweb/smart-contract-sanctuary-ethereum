/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SafeMath {
    function testUnderflow() public pure returns(uint) {
        uint x = 0;
        x--;
        return x;        
    }

    function testUncheckedUndeflow() public pure returns(uint) {
        uint x = 0;
        unchecked { x--;}
        return x;
    }
}