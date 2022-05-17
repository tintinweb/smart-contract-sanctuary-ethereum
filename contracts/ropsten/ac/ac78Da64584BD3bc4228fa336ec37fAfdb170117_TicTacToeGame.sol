// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract TicTacToeGame {
    uint256 public id = 0;

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

    error invalidStatus();
    error invalidAddress();
    error invalidCellOrTicTac();

    mapping(uint256 => Game) public games;
    mapping(address => Player) private players;

    event Player1(
        address indexed player1, 
        uint256 indexed id, 
        uint256 timer
    );

     event Player2(
        address indexed player2, 
        uint256 indexed id, 
        uint256 timer
    );

    event Move(
        address indexed player,
        uint256 indexed cell,
        TicTac tictac
    );

    modifier atStatus(uint256 _id, GameStatus _status) {
        Game storage game = games[_id];

        if (game.status != _status) {
            revert invalidStatus();
        }

        _;
    }

    modifier addressPlayer(uint256 _id, address _player) {
        if (_player != games[_id].player1) { 
            if (_player != games[_id].player2) { 
                revert invalidAddress();
            }
        }
        _;
    }

    function createGame(uint256 _timeWait) external {
        Game storage game = games[id];

        game.status = GameStatus.created;
        game.player1 = msg.sender;
        game.timer = _timeWait;

        id++;

        emit Player1(
            game.player1,
            id,
            game.timer
        );
    }

    function join(uint256 _id) 
        external 
        atStatus(_id, GameStatus.created) 
    {   
        if (msg.sender == games[_id].player1) {
            revert invalidAddress();
        }

        Game storage game = games[_id];

        game.player2 = msg.sender;
        game.status = GameStatus.started;

        emit Player2(
            game.player2,
            _id,
            game.timer
        );
    }

    function move(uint256 _cell, TicTac _tictac, uint256 _id) 
        external 
        atStatus(_id, GameStatus.started) 
        addressPlayer(_id, msg.sender)
    {
        if (_cell >= 9 || games[_id].fields[_cell] != TicTac.no || _tictac == TicTac.no) {
            revert invalidCellOrTicTac();
        }

        Game storage game = games[_id];
         
        game.fields[_cell] = _tictac;

        emit Move(
            msg.sender,
            _cell,
            _tictac
        );
    }

    function win(uint256 _id, TicTac _tictac) 
        external 
        atStatus(_id, GameStatus.started) 
        addressPlayer(_id, msg.sender)
    {   
        Game storage game = games[_id];
    
        if (!winVertically(game, _tictac) || 
                !winVertically(game, _tictac)|| 
                !winObliquely(game, _tictac)) {
            Player storage player1 = players[game.player1];
            Player storage player2 = players[game.player2];

            player1.all++;
            player2.all++;
            game.winner = msg.sender;
            game.status= GameStatus.finished;

            if (game.winner == game.player1) {
                player1.win++;
                player2.loss--;
            } else {
                player2.win++;
                player1.loss--;
            }
        }
    }

    function winVertically(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[3] == _tictac && _game.fields[6] == _tictac) ||
               (_game.fields[1] == _tictac && _game.fields[4] == TicTac.cross && _game.fields[7] == TicTac.cross) || 
               (_game.fields[2] == _tictac && _game.fields[5] == _tictac && _game.fields[8] == _tictac)) {
                   return true;
               }

        return false;
    }

    function winHorizontally(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[1] == _tictac && _game.fields[2] == _tictac) ||
               (_game.fields[3] == _tictac && _game.fields[4] == _tictac && _game.fields[5] == _tictac) ||
               (_game.fields[6] == _tictac && _game.fields[7] == _tictac && _game.fields[8] == _tictac)) {
                   return true;
               }

        return false;
    }

    function winObliquely(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[4] == _tictac && _game.fields[8] == _tictac) ||
               (_game.fields[2] == _tictac && _game.fields[4] == _tictac && _game.fields[6] == _tictac)) {
                   return true;
               }

        return false;
    }

    function getStatPlayer() 
        external 
        view 
        returns (Player memory) 
    {
        return players[msg.sender];
    }

    function getStatGame(uint256 _id) 
        external 
        view 
        returns (Game memory) 
    {
        return games[_id];
    }
}