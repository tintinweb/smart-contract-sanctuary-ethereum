/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address payable[] public players;
    address payable public winner;

    constructor() {
        winner = payable(address(0));
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > .01 ether);

        players.push(payable(msg.sender));
    }

    function getAllPlayers() public view returns (address payable[] memory) {
        return players;
    }

    function random() private view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.difficulty, block.timestamp, players)
                )
            );
    }

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    function pickWinner() public restricted {
        uint256 index = random() % players.length;
        winner = players[index];
        winner.transfer(address(this).balance);
        players = new address payable[](0);
    }
}