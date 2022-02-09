// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Box {
    uint256 public count;

    function inc() public {
        count++;
    }
}