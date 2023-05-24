// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Gambling {
    address payable public owner;

    event BetResult(address indexed player, uint guess, uint winningNumber, bool win);

    constructor() {
        owner = payable(msg.sender);
    }


    function bet(uint guess) public payable {
        require(msg.value == 0.1 ether, "bet value most 0.1 Ether");
        require(guess >= 1 && guess <= 10, "guess number must between 1 to 10.");

        uint winningNumber = block.timestamp % 10 + 1;

        if (guess == winningNumber) {
            // 玩家猜對了，傳送 2 Ether 給他
            payable(msg.sender).transfer(0.2 ether);

            // 觸發賭博結果事件，表示玩家贏了
            emit BetResult(msg.sender, guess, winningNumber, true);
        } else {
            // 玩家猜錯了，傳送 1 Ether 給賭場擁有者
            owner.transfer(msg.value);
            // 觸發賭博結果事件，表示玩家輸了
            emit BetResult(msg.sender, guess, winningNumber, false);
        }
    }
}