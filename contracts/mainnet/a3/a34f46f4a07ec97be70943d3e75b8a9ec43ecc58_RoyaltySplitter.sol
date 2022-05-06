/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract RoyaltySplitter {
    event Deposit(address sender, uint256 amount);

    address user1;
    address user2;
    uint256 user1Fraction;

    constructor(
        address u1,
        address u2,
        uint256 fraction
    ) {
        user1 = u1;
        user2 = u2;
        user1Fraction = fraction;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw() external {
        require(
            msg.sender == user1 || msg.sender == user2,
            "Only user1 or user2 can withdraw"
        );
        uint256 u1total = (address(this).balance * user1Fraction) / 100;
        (bool success, ) = user1.call{value: u1total}("");
        require(success, "failed to receive ether");
        (success, ) = user2.call{value: address(this).balance}("");
        require(success, "failed to receive ether");
    }
}