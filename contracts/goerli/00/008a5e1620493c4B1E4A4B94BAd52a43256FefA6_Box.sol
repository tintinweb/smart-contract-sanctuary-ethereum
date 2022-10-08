// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.7;

contract Box {
    bytes payload;
    uint256 internal value;

    event ValueChanged(uint256 value);

    function setValue(uint256 _newValue) public {
        value = _newValue;
        emit ValueChanged(value);
    }

    function getValue() public view returns (uint256) {
        return value;
    }

    function getPayload() public view returns (bytes memory) {
        return payload;
    }

    function version() public pure returns (uint256) {
        return 1;
    }
}