/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

contract Sports {
    string[] public sports;
    string[] public teams;
    string[] public players;

    event Sport(string name);
    event Team(string name, string sport);
    event Player(string name, string team);

    function addSport(string memory name) public {
        sports.push(name);
        emit Sport(name);
    }

    function addTeam(string memory name, string memory sport) public {
        teams.push(name);
        emit Team(name, sport);
    }

    function addPlayer(string memory name, string memory team) public {
        players.push(name);
        emit Player(name, team);
    }
}