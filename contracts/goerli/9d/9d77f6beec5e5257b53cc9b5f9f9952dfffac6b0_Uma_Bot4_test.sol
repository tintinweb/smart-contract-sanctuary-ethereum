/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Uma_Bot4_test{
    event RootBundleDisputed(address indexed disputer, uint256 requestTime);

    function emitSingleEvent() public
    {
        emit RootBundleDisputed(0x981F022D9c87D8EAA33634eDc520FC5F3B5d8747, 1660918147);
    }

    function emitMultipleEvents() public
    {
        emit RootBundleDisputed(0x981F022D9c87D8EAA33634eDc520FC5F3B5d8747, 1660918147);
        emit RootBundleDisputed(0x00990F5F2e1a58d79F007C94127292d03fBf4D92, 1629382147);
    }
}