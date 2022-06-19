// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Lottery
{
    address public manager;
    address[] public players;

    constructor()
    {
        manager = msg.sender;
    }

    function enter() public payable
    {
        require(msg.value > 0.01 ether, "Not Enough ETH");

        players.push(msg.sender);
    }

    function random() private view returns (uint)
    {
        return uint(keccak256(abi.encode(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted
    {
        uint index = random() % players.length;
        (bool success, ) = players[index].call{ value: address(this).balance }("");
        require(success, "Transfer failed");
        players = new address[](0);
    }

    modifier restricted()
    {
        require(msg.sender == manager);
        _;
    }

    function getPlayers() public view returns (address[] memory)
    {
        return players;
    }
}