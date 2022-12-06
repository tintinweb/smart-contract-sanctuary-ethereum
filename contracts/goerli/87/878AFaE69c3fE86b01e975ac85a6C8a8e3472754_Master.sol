// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Storage.sol";

contract Master is Storage {
    function setX(uint _x) external {
        x = _x;
    }

    function getX() external view returns(uint) {
        return x;
    }
}