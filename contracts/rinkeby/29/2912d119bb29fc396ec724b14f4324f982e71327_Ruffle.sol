/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract Ruffle {
    address public manager;
    mapping(address => bool) public winnersMap;
    address[] public winners;
    mapping(address => bool) public playersMap;
    address[] public players;
    uint256 private _minBalance = .5 ether;
    uint16 private _winnersCnt = 2;

    constructor() {
        manager = msg.sender;
    }

    function getPlayers() public view returns (address  [] memory) {
        return players;
    }

    function getWinners() public view returns (address  [] memory) {
        return winners;
    }

    function enter() public {
        require(msg.sender.balance > _minBalance, "Sender balance too low");
        require(!playersMap[msg.sender], "Sender already in ruffle");
        require(winners.length == 0, "Ruffle finished!");

        players.push(msg.sender);
        playersMap[msg.sender] = true;
    }

    function kindaRandom() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players)));
    }

    function setMinBalance(uint256 val) public restricted {
        _minBalance = val;
    }

    function setWinnersCnt(uint16 val) public restricted {
        _winnersCnt = val;
    }

    function pickWinners() public restricted {
        require(players.length >= _winnersCnt, "Not enough players");
        uint pickedWinners = 0;
        while (pickedWinners < _winnersCnt) {
            uint index = kindaRandom() % players.length;
            address currAddr = players[index];
            if (!winnersMap[currAddr]) {
                winners.push(currAddr);
                winnersMap[currAddr] = true;
                pickedWinners += 1;
            }
        }
    }

    function clearRuffle() public restricted {
        // clear players and start over.
        uint j = 0;
        for (j = players.length - 1; j >= 0; j -= 1) {
            playersMap[players[j]] = false;
        }
        players = new address[](0);

        for (j = winners.length - 1; j >= 0; j -= 1) {
            winnersMap[winners[j]] = false;
        }
        winners = new address[](0);
    }

    // restrict to only the manager (the contract creator)
    modifier restricted() {
        require(msg.sender == manager, "Only manager allow to call");
        _;
    }
}