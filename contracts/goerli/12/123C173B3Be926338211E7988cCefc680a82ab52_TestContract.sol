// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.17;

contract TestContract {
    mapping(uint256 => address) public values;
    event Value(address sender, uint256 value);

    function setValue(uint256 value) external {
        require(values[value] == address(0), "already has same value");
        values[value] = msg.sender;
        emit Value(msg.sender, value);
    }
}