/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract Lottery {
    address public manager;
    address[] public players;

    constructor () {
        manager = msg.sender;
    }

    function enterLottery() public payable {
        require(msg.value > .01 ether);

        players.push(msg.sender);
    }

    function randomNbr() private view returns(uint) {
        return uint (keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function pickWinner() public restricted {

        uint winnerIndex = randomNbr() % players.length;
        uint prizeWinner = address(this).balance;

        players[winnerIndex].call{ value: prizeWinner } ("");
        delete players;
        //* the above statement could also be written as
        //*players = new address[](0);

    }

    modifier restricted() {               //*  function modifiers are used to prevent duplication of code
        require(msg.sender == manager);
        _;
    }

    function getPlayersList() public view returns(address[] memory) {
        return players;
    }
}