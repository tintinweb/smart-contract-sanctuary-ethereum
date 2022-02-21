/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;



contract Lottery {
    address public manager;
    address[] public players;

    modifier isManager() {
        require(msg.sender == manager, "Caller is not manager.");
        _;
    }

    constructor() {
        manager = msg.sender;
    }

    function enter() external payable {
        require(msg.value >= .01 ether, "Insufficient amount of ether. Minimum is 0.01 ether.");

        players.push(msg.sender);
    }

    function pickWinner() external isManager{
        require(players.length > 0);

        uint256 index = random() % players.length;
        payable(manager).transfer(address(this).balance/100);
        payable(players[index]).transfer(address(this).balance);
        players = new address[](0);
    }

    function random() internal view returns(uint256) {
        return uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function getPlayers() external view returns(address[] memory){
        return players;
    }
}