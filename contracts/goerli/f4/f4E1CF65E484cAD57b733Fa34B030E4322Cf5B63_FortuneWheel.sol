// SPDX-License0Identifier: MIT

pragma solidity 0.8.8;


//Author: Dawid Bach
contract FortuneWheel {
    uint256 private immutable capacity;
    address[] private players;

    constructor(uint256 x) {
        capacity = x;
    }

    function address_not_in_game(address player) private view returns (bool) {
        for (uint256 index = 0; index < players.length; index++) {
            if (players[index] == player) return false;
        }
        return true;
    }

    function play_game() external payable {
        uint256 in_amount = 1e16;
        require(address_not_in_game(msg.sender), "Address already in game");
        require(
            msg.value == in_amount,
            "Wrong amount of ETH, it should 0.01 ETH"
        );
        players.push(msg.sender);

        if (players.length == capacity) {
            (bool callSuccess, ) = (msg.sender).call{
                value: address(this).balance
            }("");
            require(callSuccess, "Transfer failed");
            players = new address[](0);
        }
    }
}