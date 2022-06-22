/**
 *Submitted for verification at Etherscan.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract helloworld{
    string public hello = "Hi, Chutima Mangtub";

    uint256 a = 125;
    uint256 b = 10;
    
    function getSumOfAAndB() public view returns(uint256){
    return a+b;
    }
}