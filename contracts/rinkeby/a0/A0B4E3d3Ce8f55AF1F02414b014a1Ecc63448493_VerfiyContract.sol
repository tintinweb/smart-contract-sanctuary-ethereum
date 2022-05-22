// SPDX-license-Identifier: MIT

pragma solidity ^0.8.10;

contract VerfiyContract {
    uint256 x;

    function setValue(uint256 _x) public {
        x = _x;
    }

    function getValue() public view returns (uint256) {
        return x;
    }

}