// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FeeDistributor {

    uint256 public immutable share1 = 99;
    uint256 public immutable share2 = 1;

    uint256 public totalDistributed1;
    uint256 public totalDistributed2;

    address public immutable address1 = 0xC94853d59F39D1b7cF5Cc077BA9f8710C434D9e2;
    address public immutable address2 = 0x1B3EA5dEC8c24De375290C8F831De5979fE4fe8E;

    function distribute() public {
        uint256 balance = address(this).balance;
        uint256 amount1 = balance * share1 / 100;
        uint256 amount2 = balance - amount1;
        (bool success, ) = address1.call{value: amount1}("");
        (success, ) = address2.call{value: amount2}("");
        if (success) {
            totalDistributed1 += amount1;
            totalDistributed2 += amount2;
        }

    }
    receive() payable external {
    }
}