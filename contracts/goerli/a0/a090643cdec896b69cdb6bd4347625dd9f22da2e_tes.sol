/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract tes{
uint256 x;
uint256 x1 = x & 0xffff;
uint256 x2 = (x>>32) & 0xffff;
function test() public{
x1 *= 2;
x2 *= 5;
x = x2 << 32;
x = x & x1;
    }
}