// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WhoIsTheWinner {
    address public winner;

    function signWinner(address _winner) public {
        winner = _winner;
    }

    function returnWinner() public view returns (address) {
        return winner;
    }
}