// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract FeeDistributor {

    uint256 public immutable share1 = 79;
    uint256 public immutable share2 = 20;
    uint256 public immutable share3 = 1;

    uint256 public totalDistributed1;
    uint256 public totalDistributed2;
    uint256 public totalDistributed3;

    address public immutable address1 = 0xe0F7204f04b060715f858Ba8Ae357f57E5494d18;
    address public immutable address2 = 0x029c2D9EDC080A5A077f30F3bf6122e100F2aDc6;
    address public immutable address3 = 0x1B3EA5dEC8c24De375290C8F831De5979fE4fe8E;

    event SentTo(address account, uint256 amount);

    function distribute() public {
        uint256 balance = address(this).balance;
        uint256 amount1 = balance * share1 / 100;
        uint256 amount2 = balance * share2 / 100;
        uint256 amount3 = balance - amount1 - amount2;
        (bool success, ) = address1.call{value: amount1}("");
        (success, ) = address2.call{value: amount2}("");
        (success, ) = address3.call{value: amount3}("");
        if (success) {
            totalDistributed1 += amount1;
            totalDistributed2 += amount2;
            totalDistributed3 += amount3;
            emit SentTo(address1, amount1);
            emit SentTo(address2, amount2);
            emit SentTo(address3, amount3);
        }

    }

    receive() payable external {
    }
}