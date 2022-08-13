// SPDX-License-Identifier: MIT

pragma solidity ^0.6;

contract Lottery {

    address owner;
    uint pot;
    address[] players;
    address winner;

    modifier onlyOwner{
        require(msg.sender == owner);
        _;

    }

    constructor() public {
        owner = msg.sender;
    }

    function payIn() public payable {
        require(msg.value >= 0.01 ether);
        pot += msg.value;
        players.push(msg.sender);

    }

    function selectWinner() public onlyOwner {
        require(pot > 0);
        require(winner == address(0));
        uint participants = players.length;
        uint random = uint(blockhash(block.number - 1)) % participants;
        winner = players[random];

    }

    function withdraw() public {
        require(winner != address(0));
        require(pot != 0);
        require(address(this).balance >= pot);
        payable(winner).transfer(pot);

        //reset
        pot = 0;
        delete players;
        winner = address(0);
    }
}