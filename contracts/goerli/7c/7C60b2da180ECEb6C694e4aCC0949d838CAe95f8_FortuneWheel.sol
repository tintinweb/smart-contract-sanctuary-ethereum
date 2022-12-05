/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

contract FortuneWheel {
    address[] public players;
    uint256 public capacity;

    constructor(uint256 x) {
        capacity = x;
    }

    function play() external payable {
        uint256 fee = 1e16;
        require(!isInGame(msg.sender), "You've already joined the game.");
        require(msg.value == fee, "The game fee is 0.01 ETH.");
        players.push(msg.sender);

        if (players.length == capacity) {
            withdraw(msg.sender);
        }
    }

    function withdraw(address winner) internal {
        (bool callSuccess, ) = payable(winner).call{value: address(this).balance}("");
        require(callSuccess, "Transfer failed");
        players = new address[](0);
        winner = address(0);
    }

    function isInGame(address player) internal view returns(bool) {
        for (uint i; i < players.length; i++) {
            if (players[i] == player) {
                return true;
            }
        }
        return false;
    }
}