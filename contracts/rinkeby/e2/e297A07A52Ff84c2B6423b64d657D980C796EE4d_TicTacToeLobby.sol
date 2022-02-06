pragma solidity ^0.8.0;

import "./TicTacToe.sol";

contract TicTacToeLobby {
    mapping(address => address[]) userGames;
    event NewGameCreated(address gameAddress, uint256 amount, address player1);

    function createNewGame() public payable {
        // we create the new Tic-Tac-Toe game
        TicTacToe newTicTacToeGame = new TicTacToe(
            msg.sender, // player1
            msg.value // bet amount
        );

        // we transfer the bet amount
        payable(address(newTicTacToeGame)).transfer(msg.value);

        // we update user games
        userGames[msg.sender].push(address(newTicTacToeGame));

        emit NewGameCreated(address(newTicTacToeGame), msg.value, msg.sender);
    }

    function findUserGames(address userAddress)
        public
        view
        returns (address[] memory)
    {
        return userGames[userAddress];
    }
}