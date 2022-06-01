// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract BoxV2 {
    uint256 private value;
    event value_changed(uint256 new_value);

    function set_value(uint256 new_value) public {
        value = new_value;
        emit value_changed(new_value);
    }

    function get_value() public view returns (uint256) {
        return value;
    }

    function increment() public {
        value += 1;
        emit value_changed(value);
    }
}