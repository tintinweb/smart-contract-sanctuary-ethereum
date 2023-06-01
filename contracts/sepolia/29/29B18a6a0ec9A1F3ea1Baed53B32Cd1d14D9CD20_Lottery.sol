// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor() {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 0.01 ether);
        players.push(msg.sender);
    }

    function getPlayers() public view returns (address[] memory) {
        return players;
    }

    function _random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, players)));
    }

    function pickWinner() public onlyManager {
        uint index = _random() % players.length;
        address payable winner = payable(players[index]);
        winner.transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }
}