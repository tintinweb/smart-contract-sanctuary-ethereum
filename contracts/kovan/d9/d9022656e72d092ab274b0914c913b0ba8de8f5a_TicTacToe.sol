/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract TicTacToe {

    address public player1;
    address public player2;
    uint gameId = 1;
    address public winner;
    address public currentPlayerTurn;
    address[3][3] public gameBoard;

    constructor() {

    }

    function makeMove(uint x, uint y, address player) public {

        require(winner == address(0), "This game already have winner");

        if (currentPlayerTurn == player && player == player1) {
            currentPlayerTurn = player2;
        } else if (currentPlayerTurn == player && player == player2) {
            currentPlayerTurn = player1;
        } else {
            revert("Currently Not your turn");
        }

        // Insert current player move
        gameBoard[x][y] = player;
        address winnerAddress = checkWinner(player);
        
        if (winnerAddress != address(0)) {
            winner = winnerAddress;
        }
    }

    function startGame(address player1Address, address player2Address) public {
        player1 = player1Address;
        player2 = player2Address;
        currentPlayerTurn = player1Address;
    }

    function getWinner() public view returns (address) {
        return winner;
    }

    function checkWinner(address player) private view returns (address) {

        address newWinner = checkRows(gameBoard, player);
        if(newWinner != address(0)){
            return newWinner;
        }

        newWinner = checkColumns(gameBoard, player);
        if(newWinner != address(0)){
            return newWinner;
        }

        newWinner = checkDiagnols(gameBoard, player);
        if(newWinner != address(0)){
            return newWinner;
        }
        return address(0);
    }

    function checkRows(address[3][3] memory myGameBoard, address player) private pure returns (address) {
        for (uint x = 0; x < 3; x++){
            if (myGameBoard[x][0] == player && myGameBoard[x][0] == myGameBoard[x][1] && myGameBoard[x][1] == myGameBoard[x][2]){
                return player;
            }
        }
        return address(0);
    }
  
    function checkColumns(address[3][3] memory myGameBoard, address player) private pure returns (address) {
        for (uint x = 0; x < 3; x++){
            if (myGameBoard[0][x] == player && myGameBoard[0][x] == myGameBoard[1][x] && myGameBoard[1][x] == myGameBoard[2][x]){
                return player;
            }
        }
        return address(0);
    }

    function checkDiagnols(address[3][3] memory myGameBoard, address player) private pure returns (address) {
        if (myGameBoard[0][0] == player && myGameBoard[0][0] == myGameBoard[1][1] && myGameBoard[1][1] == myGameBoard[2][2]){
            return player;
        }

        if (myGameBoard[0][2] == player && myGameBoard[0][2] == myGameBoard[1][1] && myGameBoard[1][1] == myGameBoard[2][0]){
            return player;
        }
        return address(0);
    }
}