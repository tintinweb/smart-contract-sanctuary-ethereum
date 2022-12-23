// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract HouseV2 {
    uint256 public avg;

    function inc() public {
        avg++;
    }

    function dec() public {
        avg--;
    }
}