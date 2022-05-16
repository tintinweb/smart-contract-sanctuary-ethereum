// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TicTacToeGame {
    uint256 id = 0;

    enum TicTac {
        no,
        zero,
        cross
    }

    enum GameStatus {
        no,
        created,
        started,
        finished
    }
    
    struct Game {
        GameStatus status;
        address winner;
        uint256 timer;
        address player1;
        address player2;
        TicTac[9] fields;
    }

    struct Player {
        uint256 all;
        uint256 win;
        uint256 loss;
    }

    error errorStatus();
    error invalidAddress();

    mapping(uint256 => Game) public games;
    mapping(address => Player) private players;
    //mapping(address => uint256) pablic ids;

    modifier atStatus(uint256 _id, GameStatus _status) {
        Game storage game = games[_id];

        if (game.status == _status) {
            _;
        } else revert errorStatus();
    }

    function createGame(uint256 _timeWait) external {
        Game storage game = games[id];

        game.status = GameStatus.created;
        game.player1 = msg.sender;
        game.timer = _timeWait;

        id++;
    }

    function join(uint256 _id) external atStatus(_id, GameStatus.created) {
        Game storage game = games[_id];

        game.player2 = msg.sender;
        game.status = GameStatus.started;
    }

    function move(uint256 _cell, TicTac _tictac) external atStatus(id--, GameStatus.started) {
        require(_cell < 9, "Invalid cell");
        require(games[id--].fields[_cell] == TicTac.no, "Invalid cell");
        require(_tictac != TicTac.no, "Invalid tictac");
        if (msg.sender != games[id--].player1 && _tictac == TicTac.cross) {
            if (msg.sender != games[id--].player2 && _tictac == TicTac.zero) {
                revert invalidAddress();
            }
        } 

        Game storage game = games[id--];
         
        game.fields[_cell] = _tictac;
    }

    function win() external atStatus(id--, GameStatus.started) {
        if (msg.sender != games[id--].player1) {
            if (msg.sender != games[id--].player2) {
                revert invalidAddress();
            }
        }
    
        if (winCross() ==true || winZero() ==true) {
            Game storage game = games[id];
            Player storage player1 = players[game.player1];
            Player storage player2 = players[game.player2];

            player1.all++;
            player2.all++;
            game.winner = msg.sender;

            if (game.winner == game.player1) {
                player1.win++;
                player2.loss--;
            } else {
                player2.win++;
                player1.loss--;
            }
        }
    }

    function winCross() internal view returns (bool) {
        if ((games[id].fields[0] == TicTac.cross && games[id].fields[3] == TicTac.cross && games[id].fields[6] == TicTac.cross) ||
               (games[id].fields[1] == TicTac.cross && games[id].fields[4] == TicTac.cross && games[id].fields[7] == TicTac.cross) || 
               (games[id].fields[2] == TicTac.cross && games[id].fields[5] == TicTac.cross && games[id].fields[8] == TicTac.cross) ||
               (games[id].fields[0] == TicTac.cross && games[id].fields[1] == TicTac.cross && games[id].fields[2] == TicTac.cross) ||
               (games[id].fields[3] == TicTac.cross && games[id].fields[4] == TicTac.cross && games[id].fields[5] == TicTac.cross) ||
               (games[id].fields[6] == TicTac.cross && games[id].fields[7] == TicTac.cross && games[id].fields[8] == TicTac.cross) ||
               (games[id].fields[0] == TicTac.cross && games[id].fields[4] == TicTac.cross && games[id].fields[8] == TicTac.cross) ||
               (games[id].fields[2] == TicTac.cross && games[id].fields[4] == TicTac.cross && games[id].fields[6] == TicTac.cross) ||
               (block.timestamp > games[id].timer)) {
                   return true;
               }

        return false;
    }

    function winZero() internal view returns (bool) {
        if ((games[id].fields[0] == TicTac.zero && games[id].fields[3] == TicTac.zero && games[id].fields[6] == TicTac.zero) ||
               (games[id].fields[1] == TicTac.zero && games[id].fields[4] == TicTac.zero && games[id].fields[7] == TicTac.zero) || 
               (games[id].fields[2] == TicTac.zero && games[id].fields[5] == TicTac.zero && games[id].fields[8] == TicTac.zero) ||
               (games[id].fields[0] == TicTac.zero && games[id].fields[1] == TicTac.zero && games[id].fields[2] == TicTac.zero) ||
               (games[id].fields[3] == TicTac.zero && games[id].fields[4] == TicTac.zero && games[id].fields[5] == TicTac.zero) ||
               (games[id].fields[6] == TicTac.zero && games[id].fields[7] == TicTac.zero && games[id].fields[8] == TicTac.zero) ||
               (games[id].fields[0] == TicTac.zero && games[id].fields[4] == TicTac.zero && games[id].fields[8] == TicTac.zero) ||
               (games[id].fields[2] == TicTac.zero && games[id].fields[4] == TicTac.zero && games[id].fields[6] == TicTac.zero) ||
               (block.timestamp > games[id].timer)) {
                   return true;
               }
        
        return false;
    }

    function getStatPlayer() external view returns (Player memory) {
        return players[msg.sender];
    }

    function getStatGame(uint256 _id) external view returns (Game memory) {
        return games[_id];
    }
}