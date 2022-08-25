/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract TestSpokePool{
    event SetXDomainAdmin(address indexed newAdmin);

    function emitSingleEvent() public
    {
        emit SetXDomainAdmin(0x1Abf3a6C41035C1d2A3c74ec22405B54450f5e13);
    }
}