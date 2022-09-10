// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Counter {
    uint256 number;

    event NumberUpdated(address indexed newNumberUpdater, uint256 newNumber);

    function updateNumber(uint256 _newNumber) public {
        number = _newNumber;

        // emit event updates a mapping
        emit NumberUpdated(msg.sender, number);
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}