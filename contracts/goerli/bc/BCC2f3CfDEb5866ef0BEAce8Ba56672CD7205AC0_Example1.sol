// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Example1 {

    struct Game {
        uint256 id;
        uint256 answer;
        uint256 numberOfGuesses;
        uint256 winningAnswer;
        address winner;
        address owner;
    }

    uint256 public numberOfGames = 0;

    mapping(uint256 => Game) public games;

    event CreatedNewGame(uint256 gameId, uint256 answer);

    constructor() {

    }

    function createGame(uint256 _answer) public {
        
        require(_answer < 10000, "Answer more than 10000");

        games[numberOfGames] = Game({
            id: numberOfGames,
            answer: _answer,
            numberOfGuesses: 0,
            winner: address(0),
            winningAnswer: 0,
            owner: msg.sender
        });

        numberOfGames++;

        emit CreatedNewGame(numberOfGames - 1, _answer);
    }

    function getGameAnswer(uint256 _gameId) public view returns (uint256) {

        //INCORRECT: Watch for multiple requires and use custom modifier        
        require(_gameId < numberOfGames, "Invalid ID");
        
        return games[_gameId].answer;
    }

    //Return method 1:
    //Initialize type and name, then just return name
    function getGameNumberOfGuesses(uint256 _gameId) public view isValidGameId(_gameId) returns (uint256 numOfGuesses) {
        numOfGuesses = games[_gameId].numberOfGuesses;
        return numOfGuesses;
    }

    //Return method 2:
    //Just state type of return variable and then return a compatible type
    function getGameWinner(uint256 _gameId) public view isValidGameId(_gameId) returns (address) {
        return games[_gameId].winner;
    }

    function getGameWinningAnswer(uint256 _gameId) public view isValidGameId(_gameId) returns (uint256) {
        return games[_gameId].winningAnswer;
    }

    function getGameOwner(uint256 _gameId) public view isValidGameId(_gameId) returns (address) {
        return games[_gameId].owner;
    }

    function playGame(uint256 _gameId, uint256 _guess) public isValidGameId(_gameId) {

        uint256 currentWinningDiff;
        uint256 playersDiff;

        if(games[_gameId].numberOfGuesses == 0){
            games[_gameId].winner = msg.sender;
            games[_gameId].winningAnswer = _guess;
        }else{
            if(games[_gameId].winningAnswer < games[_gameId].answer){
                currentWinningDiff = games[_gameId].answer - games[_gameId].winningAnswer;
            }else{
                currentWinningDiff = games[_gameId].winningAnswer - games[_gameId].answer;
            }

            if(games[_gameId].answer < _guess){
                playersDiff = _guess - games[_gameId].answer;
            }else{
                playersDiff = games[_gameId].answer - _guess;
            }

            if(playersDiff < currentWinningDiff){
                games[_gameId].winner = msg.sender;
                games[_gameId].winningAnswer = _guess;
            }
        } 

        games[_gameId].numberOfGuesses++;

    }

    modifier isValidGameId(uint256 _gameId) {
        require(_gameId < numberOfGames, "Invalid ID");
        _;
    }


}