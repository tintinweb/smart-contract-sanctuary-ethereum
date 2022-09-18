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

contract CallOtherContractPureViewFunc
{
    address public calleeContractAddr;
    ViewPure public calleeContract;

    function setCalleeContractAddr (address _addr) public
    {
        calleeContractAddr = _addr;
        calleeContract = ViewPure(_addr);
    }

    function callPure() public returns(uint)
    {
        calleeContract.pureFunc();
        return 200;
    }

    function callView() public returns(uint)
    {
        calleeContract.viewFunc();
        return 200;
    }

    function callNormal() public returns(uint)
    {
        calleeContract.normalFunc();
        return 200;
    }
}