/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract testInt {
    int8 a = -1;
    int16 b =2;

    uint32 c = 10;
    uint8 d = 255;

    function add (uint x, uint y) public  pure returns (uint z) {
        z = x + y;
    }

    function divide(uint x,uint y) public pure returns (uint z) {
        z = x /y;
    }

    function testPulsPlus() public pure returns(uint) {
        uint x = 1;
        uint y = ++x;
        return y;
    }

    
}