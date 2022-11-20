// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

contract DataTypes {
    uint256 public num;

    function setNum(uint256 newNum) public {
        num = newNum;
    }
}