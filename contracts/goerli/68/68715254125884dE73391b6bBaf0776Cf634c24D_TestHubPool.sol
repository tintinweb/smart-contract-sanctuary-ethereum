/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;


contract TestHubPool{
    event LivenessSet(uint256 newLiveness);

    function emitSingleEvent() public
    {
        emit LivenessSet(1);
    }
}