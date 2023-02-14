/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

pragma solidity ^0.8.0;

contract Lottery {
    address payable public manager;
    address payable[] public players;

    constructor() {
        manager = payable(msg.sender);
    }

    function enter() public payable {
        require(msg.value > 0.01 ether, "Minimum bet is 0.01 ether");
        players.push(payable(msg.sender));
    }

    function pickWinner() public restricted {
        require(players.length > 0, "No players entered the lottery");
        uint index = random() % players.length;
        players[index].transfer(address(this).balance);
        players = new address payable[](0);
    }

    modifier restricted() {
        require(msg.sender == manager, "Only the manager can call this function");
        _;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.length)));
    }
}