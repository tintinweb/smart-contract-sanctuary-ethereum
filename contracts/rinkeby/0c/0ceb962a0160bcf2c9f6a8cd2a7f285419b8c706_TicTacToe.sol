/**
 *Submitted for verification at Etherscan.io on 2022-02-02
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract  TicTacToe {
    mapping(uint8 => address) public players;

    uint8[9] board = [
        0, 0, 0,
        0, 0, 0,
        0, 0, 0
    ];

    uint8 public playerMove;
    address public playerWinner;
    bool public isGameInProggress;

    constructor(address player1) {
        players[1] = player1;
    }

    modifier canEnterGame() {
        require(players[1] == address(0x0) || players[2] == address(0x0), "Game is full");

        require(players[1] != msg.sender, "You have entered to this game already");
        _;
    }

    modifier isGamePlayer() {
        require(players[1] == msg.sender || players[2] == msg.sender, "You are not the player");
        _;
    }

    modifier canStartGame() {
        require(players[1] != address(0x0) && players[2] != address(0x0), "Waiting for players");
        _;
    }

    modifier canPlayerMove() {
        require(isGameInProggress == true, "This game is not in proggress");
        require(players[playerMove] == msg.sender, "It's not your turn");
        _;
    }

    modifier validateBoardIndex(uint8 boardIndex) {
        require(boardIndex >= 0 && boardIndex <= 8, "Invalid board index");
        require(board[boardIndex] == 0, "This field is not empty");
        _;
    }

    function random(uint number) private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % number;
    }

    function hasGameWinner() private view returns (bool) {
        for (uint8 i = 0; i < 9; i += 3) {
            if(board[i] != 0 && board[i] == board[i + 1] && board[i] == board[i + 2]) {
                return true;
            }
        }

        for (uint8 i = 0; i < 3; i++) {
            if(board[i] != 0 && board[i] == board[i + 3] && board[i] == board[i + 6]) {
                return true;
            }
        }

        if(board[0] != 0 && board[0] == board[4] && board[0] == board[8]) {
            return true;
        }

        if(board[2] != 0 && board[2] == board[4] && board[0] == board[6]) {
            return true;
        }

        return false;
    }

    function getBoard() public view returns(uint8[9] memory) {
        return board;
    }

    function enterGame() public canEnterGame {
        uint8 boardValue = players[1] == address(0x0) ? 1 : 2; 
        players[boardValue] = msg.sender;
    }

    function startGame() public isGamePlayer canStartGame {
        isGameInProggress = true;
        playerMove = uint8(random(2)) + 1;
    }

    function move(uint8 boardIndex) public isGamePlayer canPlayerMove validateBoardIndex(boardIndex) {
        board[boardIndex] = playerMove;
        if(hasGameWinner()) {
            isGameInProggress = false;
            playerWinner = players[playerMove];
        } else {
            playerMove = playerMove == 1 ? 2 : 1;
        }
    }
}