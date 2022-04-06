// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Box {
    uint256 private magic_number;

    // Emitted when the stored value changes
    event ValueChanged(uint256 value);

    function init(uint256 value) public{
        magic_number = value;
        emit ValueChanged(value);
    }

    // Reads the last stored value
    function retrieve() public view returns (uint256) {
        return magic_number;
    }
}