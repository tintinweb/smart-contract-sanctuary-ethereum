/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ViewPure
{
    function pureFunc() pure external returns(uint)
    {
        return 100;
    }
    function viewFunc() view external returns(uint)
    {
        return 100;
    }
    function normalFunc() external returns(uint)
    {
        return 100;
    }
}