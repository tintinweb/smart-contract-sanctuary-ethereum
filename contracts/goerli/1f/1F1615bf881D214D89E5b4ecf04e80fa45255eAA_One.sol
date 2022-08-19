/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract One{
    uint a;
    event RootBundleDisputed(address disputer, uint256 requestTime);

    function emitSingleEvent() public
    {
        emit RootBundleDisputed(0x981F022D9c87D8EAA33634eDc520FC5F3B5d8747, 1660918147);
    }

}