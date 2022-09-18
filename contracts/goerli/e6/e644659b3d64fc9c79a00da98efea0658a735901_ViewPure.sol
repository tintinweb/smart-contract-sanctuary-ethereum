/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ViewPure
{
    uint public state = 777;
    function pureFunc() pure public returns(uint)
    {
        return 100;
    }
    function viewFunc() view public returns(uint)
    {
        // return state;
        return 100;
    }
    function normalFunc() public returns(uint)
    {
        return 100;
    }

    function callNothing() public returns(uint)
    {
        return 200;
    }
    
    function callPure() public returns(uint)
    {
        pureFunc();
        return 200;
    }

    function callView() public returns(uint)
    {
        viewFunc();
        return 200;
    }

    function callNormal() public returns(uint)
    {
        normalFunc();
        return 200;
    }

}