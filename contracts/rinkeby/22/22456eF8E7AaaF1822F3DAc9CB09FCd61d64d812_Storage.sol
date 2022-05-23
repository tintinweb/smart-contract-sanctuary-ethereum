// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

contract Storage {
    uint256 number;

    // Declare an Event
    event Stored(address executor, uint256 value);

    function store(uint256 num) public {
        number = num;

        // Emit event
        emit Stored(msg.sender, num);
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}