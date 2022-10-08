// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract BoxV2 {
    uint256 internal value;

    event ValueChanged(uint256 value);

    function setValue(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(value);
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function version() public pure returns (uint256) {
        return 2;
    }

    function increment() public {
        value = value + 1;
        emit ValueChanged(value);
    }
}