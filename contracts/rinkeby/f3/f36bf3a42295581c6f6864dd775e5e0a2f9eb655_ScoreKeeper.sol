/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract ScoreKeeper {
    // --- User States ---
    struct Player {
        uint24 highScore;
        uint24[] scores;
    }
    mapping(address => Player) ledger;

    // --- Global States ---
    struct HighScore {
        string username;
        uint24 highScore;
    }
    HighScore public globalHighScore1;
    HighScore public globalHighScore2;
    HighScore public globalHighScore3;

    // --- Constructor ---
    constructor(){
        globalHighScore1 = HighScore("player.1", 0);
        globalHighScore2 = HighScore("player.2", 0);
        globalHighScore3 = HighScore("player.3", 0);
    }


    // --- Add Score ---
    function addOneScore(uint24 _score, string memory _username) public {
        // -- User Scores --
        ledger[msg.sender].scores.push(_score);
        if(_score > ledger[msg.sender].highScore){
            ledger[msg.sender].highScore = _score;
        }
        // -- Global Scores --
        if(_score > globalHighScore1.highScore){
            globalHighScore3 = globalHighScore2;
            globalHighScore2 = globalHighScore1;
            globalHighScore1.username = _username;
            globalHighScore1.highScore = _score;
        }
        else if(_score > globalHighScore2.highScore){
            globalHighScore3 = globalHighScore2;
            globalHighScore2.username = _username;
            globalHighScore2.highScore = _score;
        }
        else if(_score > globalHighScore3.highScore){
            globalHighScore3.username = _username;
            globalHighScore3.highScore = _score;
        }
    }

    function getUserScores(address _address) public view returns(uint24[] memory, uint24){
        return (
            ledger[_address].scores,
            ledger[_address].highScore);
    }
    
    function getHighScores() public view returns (
        string[3] memory usernames,
        uint24[3] memory scores
    ){
        return (
            [
                globalHighScore1.username,
                globalHighScore2.username,
                globalHighScore3.username
            ],
            [
                globalHighScore1.highScore,
                globalHighScore2.highScore,
                globalHighScore3.highScore
            ]
        );
    }
}