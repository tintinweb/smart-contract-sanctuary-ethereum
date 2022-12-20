/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ITemple {
    /// Write data to the contract's ith storage slot
    function write(uint256 _i, bytes32 _data) external;
}

contract TempleTaskOne {
    function writeAddressToMainHall(address _temple) public {
        ITemple(_temple).write(1, bytes32(abi.encode(msg.sender)));
    }
}