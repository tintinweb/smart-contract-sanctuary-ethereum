/**
 *Submitted for verification at Etherscan.io on 2023-05-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

contract CoinFlip {
    address immutable owner;
    uint256 public maxPayout = 0;

    constructor() {
        owner = msg.sender;
    }

    event CoinFlipped(address indexed player, bool isWon, uint256 amountWon, uint256 timestamp);

    function getRandom() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 2;  
    }

    function flip(uint256 choice) external payable {
        require(msg.value >= 1000000000000000, "The value you sent is too small"); //0.0048 ETH
        require(msg.value <= address(this).balance / 2);

        uint256 amountWon = (msg.value * 196) / 100;
        uint256 randNumber = getRandom();

        if (choice == randNumber) {
            payable(msg.sender).transfer(amountWon);
            if (amountWon > maxPayout) {
                maxPayout = amountWon;
            }
            emit CoinFlipped(msg.sender, true, amountWon, block.timestamp);
        }
        else {
            emit CoinFlipped(msg.sender, false, 0, block.timestamp);
        }
    }

    function deposit() public payable {}

    function withdraw(uint256 amount) public {
        require(msg.sender == owner, "ONly owner can withdraw funds");
        require(address(this).balance >= amount, "Insufficient balance to withdraw");
        payable(msg.sender).transfer(amount);
    }

}