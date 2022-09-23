import "../libraries/SetterAppStorage.sol";

contract SetterGetterFacet {
    Layout internal l;

    function setValues(
        uint256 _x,
        uint256 _y,
        uint256 _z
    ) external {
        l.x = _x;
        l.y = _y;
        l.z = _z;
    }

    function sumValues() external view returns (uint256) {
        return l.x + l.y + l.z;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Layout {
    uint256 x;
    uint256 y;
    uint256 z;
}