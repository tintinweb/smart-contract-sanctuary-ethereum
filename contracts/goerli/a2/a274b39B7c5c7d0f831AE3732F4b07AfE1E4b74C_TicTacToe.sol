// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

contract TicTacToe {
    address public owner;

    struct Game {
        address playerX;
        address playerO;
        uint256 turns;
        uint256[9] board;
    }

    mapping(uint256 => Game) public games;

    uint256 internal constant EMPTY = 0;
    uint256 internal constant X = 1;
    uint256 internal constant O = 2;

    uint256 internal _nextGameId;

    constructor(address _owner) {
        owner = _owner;
    }

    function newGame(address playerX, address playerO) public {
        games[_nextGameId].playerX = playerX;
        games[_nextGameId].playerO = playerO;
        _nextGameId++;
    }

    function getBoard(uint256 id) public view returns (uint256[9] memory) {
        return games[id].board;
    }

    function resetBoard(uint256 id) public {
        require(msg.sender == owner, "Unauthorized");
        delete games[id].board;
    }

    function markSpace(uint256 id, uint256 space) public {
        require(_validPlayer(id), "Unauthorized");
        require(_validTurn(id), "Not your turn");
        require(_emptySpace(id, space), "Already marked");
        games[id].board[space] = _getSymbol(id, msg.sender);
        games[id].turns++;
    }

    function currentTurn(uint256 id) public view returns (uint256) {
        return (games[id].turns % 2 == 0) ? X : O;
    }

    function winner(uint256 id) public view returns (uint256) {
        uint256[8] memory wins = [
            _row(id, 0),
            _row(id, 1),
            _row(id, 2),
            _col(id, 0),
            _col(id, 1),
            _col(id, 2),
            _diag(id),
            _antiDiag(id)
        ];
        for (uint256 i; i < wins.length; i++) {
            uint256 win = _checkWin(wins[i]);
            if (win == X || win == O) return win;
        }
        return 0;
    }

    function _getSymbol(uint256 id, address player)
        public
        view
        returns (uint256)
    {
        if (player == games[id].playerX) return X;
        if (player == games[id].playerO) return O;
        return EMPTY;
    }

    function _validTurn(uint256 id) internal view returns (bool) {
        return currentTurn(id) == _getSymbol(id, msg.sender);
    }

    function _validPlayer(uint256 id) internal view returns (bool) {
        return
            msg.sender == games[id].playerX || msg.sender == games[id].playerO;
    }

    function _checkWin(uint256 product) internal pure returns (uint256) {
        if (product == 1) {
            return X;
        }
        if (product == 8) {
            return O;
        }
        return 0;
    }

    function _row(uint256 id, uint256 row) internal view returns (uint256) {
        require(row < 3, "Invalid row");
        uint256 idx = 3 * row;
        return
            games[id].board[idx] *
            games[id].board[idx + 1] *
            games[id].board[idx + 2];
    }

    function _col(uint256 id, uint256 col) internal view returns (uint256) {
        require(col < 3, "Invalid column");
        return
            games[id].board[col] *
            games[id].board[col + 3] *
            games[id].board[col + 6];
    }

    function _diag(uint256 id) internal view returns (uint256) {
        return games[id].board[0] * games[id].board[4] * games[id].board[8];
    }

    function _antiDiag(uint256 id) internal view returns (uint256) {
        return games[id].board[2] * games[id].board[4] * games[id].board[6];
    }

    function _validTurn(uint256 id, uint256 symbol)
        internal
        view
        returns (bool)
    {
        return symbol == currentTurn(id);
    }

    function _emptySpace(uint256 id, uint256 i) internal view returns (bool) {
        return games[id].board[i] == EMPTY;
    }

    function _validSymbol(uint256 symbol) internal pure returns (bool) {
        return symbol == X || symbol == O;
    }
}