// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract StorageV1 {
    uint256 public num1;
    uint256 public num2;

    function set_num(uint256 n1, uint256 n2) public {
        num1 = n1;
        num2 = n2;
    }

    function display_num() public view returns (uint256, uint256) {
        return (num1, num2);
    }
}