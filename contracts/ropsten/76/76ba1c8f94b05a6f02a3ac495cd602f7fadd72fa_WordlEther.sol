/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// contracts/Box.sol
// SPDX-License-Identifier: MIT
// Author - Rajesh Royal [github/Rajesh-Royal]
pragma solidity ^0.8.0;

contract WordlEther {
    uint256 private _contractUseCount;

    // Emitted when the stored value changes
    event ValueChanged(uint256 contractUseCount);

    struct gameInfo {
        string id;
        uint gamePlayed;
        uint winPercentage;
        uint currentStreak;
        uint maxStreak;
        uint[] Tries;
        string playerName;
        string description;
    }

    mapping(string => gameInfo) private games;
    string[] private gameIds;

    // register a new game result
    function registerGames(string memory id, uint gamePlayed, uint winPercentage, uint currentStreak, 
                             uint maxStreak, uint[] memory Tries, string memory playerName, string memory description) public {
        gameInfo storage newGame = games[id];
        
        newGame.id = id;
        newGame.gamePlayed = gamePlayed;
        newGame.winPercentage = winPercentage;
        newGame.currentStreak = currentStreak;
        newGame.maxStreak = maxStreak;
        newGame.Tries = Tries;
        newGame.playerName = playerName;
        newGame.description = description;

        gameIds.push(id);
        incrementContractUse();
    }
    
    //get game results
    function getGameState(string memory id) public view returns (string memory, uint, uint, uint, 
                             uint, uint[] memory, string memory, string memory){
        gameInfo storage game = games[id];
        return (game.id, game.gamePlayed, game.winPercentage, game.currentStreak, game.maxStreak, game.Tries, game.playerName,
         game.description);
    }

    // get all game result
    function getAllGameStates() public view returns (gameInfo[] memory){
        gameInfo[] memory allGames = new gameInfo[](_contractUseCount);
        for (uint i = 0; i < _contractUseCount; i++) {
            gameInfo storage gmState = games[gameIds[i]];
            allGames[i] = gmState;
        }
        return allGames;
    }

    // Increment the contract usages count
    function incrementContractUse() private {
        _contractUseCount++;
        emit ValueChanged(_contractUseCount);
    }

    // Reads the last stored countractUsages value
    function retrieve() public view returns (uint256) {
        return _contractUseCount;
    }
}