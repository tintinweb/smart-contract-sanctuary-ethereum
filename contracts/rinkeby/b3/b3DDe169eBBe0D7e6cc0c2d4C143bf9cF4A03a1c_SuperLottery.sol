/**
 *Submitted for verification at Etherscan.io on 2022-05-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract SuperLottery {
    address public manager;
    address payable[] public players;

    constructor() {
        manager = msg.sender;
        players = new address payable[](0);
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "only running by Manager.");
        _;
    }

    modifier noOwner() {
        require(msg.sender != manager, "Owner can't enter the game");
        _;
    }

    modifier onlyOnce() {
        bool isExist = false;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == msg.sender) {
                isExist = true;
            }
        }
        require(isExist == false, "User already join the lottery");
        _;
    }

    function enterGame() public payable noOwner onlyOnce {
        require(msg.value > 0.01 ether, "Minimum Ether is 0.011 Ether");

        players.push(payable(msg.sender));
    }

    function getPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() private view returns (uint256) {
        // currently is hard to random a number in solidity, so i used the pseudo random logic (not literally random)
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            ); // keccak256 same as sha3
    }

    function pickWinner() public onlyOwner {
        uint256 idx = random() % players.length;

        players[idx].transfer(address(this).balance);

        players = new address payable[](0);
    }
}