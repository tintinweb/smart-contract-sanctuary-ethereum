/**
 *Submitted for verification at Etherscan.io on 2022-07-30
*/

// SPDX-License-Identifier: MIT


pragma solidity =0.8.12;


contract myContract{
    address public Test;
    function initAddress(address test) public{
        Test = test;
    }
    fallback() external payable{
        Test.call(abi.encodeWithSignature("mainpulation(uint256)", 10));

    }

}