// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WhoIsTheWinner {
    address public winner;

    function signWinner() public {
        winner = msg.sender;
    }

    function returnWinner() public view returns (address) {
        return winner;
    }
}