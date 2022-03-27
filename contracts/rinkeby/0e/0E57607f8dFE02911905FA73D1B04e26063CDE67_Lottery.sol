// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Lottery {

    address public manager;
    address[] public players;
    address public winner;

    constructor () {
        manager = msg.sender;
    }

    function enter() public payable {
        require(msg.value > 1 wei);

        players.push(msg.sender);
    }

    function pickwinner () public {
        winner = players[1]; // random??
    }

}