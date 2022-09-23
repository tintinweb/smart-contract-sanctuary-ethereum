// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Check {
    string winner;

    function setWinner(string memory _winner) public {
        winner = _winner;
    }

    function getWinner() public view returns (string memory) {
        return winner;
    }
}