/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract Caller
{
    function callOtherFunction(address addr) external
    {
        Callee(addr).callMe();
    }
}

contract Callee
{
    event msgSender(address addr);
    event txOrigin(address addr);

    function callMe() external
    {
        emit msgSender(msg.sender);
        emit msgSender(tx.origin);
    }
}