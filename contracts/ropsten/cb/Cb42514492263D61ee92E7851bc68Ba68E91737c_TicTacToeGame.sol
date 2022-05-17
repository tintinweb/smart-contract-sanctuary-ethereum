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
        if (msg.sender == games[_id].player1) 
        {
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
    {
        if (_cell >= 9 || games[_id].fields[_cell] != TicTac.no || _tictac == TicTac.no) {
            revert invalidCellOrTicTac();
        }

        if ((msg.sender != address(games[_id].player1) && _tictac == TicTac.cross) ||
                (msg.sender != address(games[_id].player2) && _tictac == TicTac.zero)) 
        {
            revert invalidAddress();
        } 

        Game storage game = games[_id];
         
        game.fields[_cell] = _tictac;

        emit Move(
            msg.sender,
            _cell,
            _tictac
        );
    }

    function win(uint256 _id) 
        external 
        atStatus(_id, GameStatus.started) 
    {
        if ((msg.sender != address(games[_id].player1)) || (msg.sender != address(games[_id].player2))) { 
            revert invalidAddress();
        }
        
        Game storage game = games[_id];
    
        if (!winCrossVertically(game) || 
                !winZeroVertically(game) || 
                !winCrossHorizontally(game) || 
                !winZeroHorizontally(game) || 
                !winCrossObliquely(game) || 
                !winZeroObliquely(game)) {
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

    function winCrossVertically(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.cross && _game.fields[3] == TicTac.cross && _game.fields[6] == TicTac.cross) ||
               (_game.fields[1] == TicTac.cross && _game.fields[4] == TicTac.cross && _game.fields[7] == TicTac.cross) || 
               (_game.fields[2] == TicTac.cross && _game.fields[5] == TicTac.cross && _game.fields[8] == TicTac.cross)) {
                   return true;
               }

        return false;
    }

    function winCrossHorizontally(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.cross && _game.fields[1] == TicTac.cross && _game.fields[2] == TicTac.cross) ||
               (_game.fields[3] == TicTac.cross && _game.fields[4] == TicTac.cross && _game.fields[5] == TicTac.cross) ||
               (_game.fields[6] == TicTac.cross && _game.fields[7] == TicTac.cross && _game.fields[8] == TicTac.cross)) {
                   return true;
               }

        return false;
    }

    function winCrossObliquely(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.cross && _game.fields[4] == TicTac.cross && _game.fields[8] == TicTac.cross) ||
               (_game.fields[2] == TicTac.cross && _game.fields[4] == TicTac.cross && _game.fields[6] == TicTac.cross)) {
                   return true;
               }

        return false;
    }

    function winZeroVertically(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.zero && _game.fields[3] == TicTac.zero && _game.fields[6] == TicTac.zero) ||
               (_game.fields[1] == TicTac.zero && _game.fields[4] == TicTac.zero && _game.fields[7] == TicTac.zero) || 
               (_game.fields[2] == TicTac.zero && _game.fields[5] == TicTac.zero && _game.fields[8] == TicTac.zero)) {
                   return true;
               }
        
        return false;
    }

    function winZeroHorizontally(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.zero && _game.fields[1] == TicTac.zero && _game.fields[2] == TicTac.zero) ||
               (_game.fields[3] == TicTac.zero && _game.fields[4] == TicTac.zero && _game.fields[5] == TicTac.zero) ||
               (_game.fields[6] == TicTac.zero && _game.fields[7] == TicTac.zero && _game.fields[8] == TicTac.zero)) {
                   return true;
               }
        
        return false;
    }

    function winZeroObliquely(Game storage _game) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == TicTac.zero && _game.fields[4] == TicTac.zero && _game.fields[8] == TicTac.zero) ||
               (_game.fields[2] == TicTac.zero && _game.fields[4] == TicTac.zero && _game.fields[6] == TicTac.zero)) {
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