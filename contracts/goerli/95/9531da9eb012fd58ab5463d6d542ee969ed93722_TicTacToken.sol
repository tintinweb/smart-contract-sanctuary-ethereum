// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.17;

contract TicTacToken {
    uint256[9] public board;

    uint256 internal constant EMPTY = 0;
    uint256 internal constant X = 1;
    uint256 internal constant O = 2;
    uint256 internal _turns;

    function getBoard() public view returns (uint256[9] memory) {
        return board;
    }

    function markSpace(uint256 space, uint256 symbol) public {
        require(_validSymbol(symbol), "Invalid symbol");
        require(_validTurn(symbol), "Not your turn");
        require(_emptySpace(space), "Already marked");
        board[space] = symbol;
        _turns++;
    }

    function currentTurn() public view returns (uint256) {
        return (_turns % 2 == 0) ? X : O;
    }

    function winner() public view returns (uint256) {
        uint256[8] memory wins = [_row(0), _row(1), _row(2), _col(0), _col(1), _col(2), _diag(), _antiDiag()];
        for (uint256 i; i < wins.length; i++) {
            uint256 win = _checkWin(wins[i]);
            if (win == X || win == O) return win;
        }
        return 0;
    }

    function _validTurn(uint256 symbol) internal view returns (bool) {
        return symbol == currentTurn();
    }

    function _emptySpace(uint256 space) internal view returns (bool) {
        return board[space] == EMPTY;
    }

    function _validSymbol(uint256 symbol) internal pure returns (bool) {
        return symbol == X || symbol == O;
    }

    function _row(uint256 row) internal view returns (uint256) {
        require(row < 3, "Invalid row");
        uint256 idx = 3 * row;
        return board[idx] * board[idx + 1] * board[idx + 2];
    }

    function _col(uint256 col) internal view returns (uint256) {
        require(col < 3, "Invalid column");
        return board[col] * board[col + 3] * board[col + 6];
    }

    function _diag() internal view returns (uint256) {
        return board[0] * board[4] * board[8];
    }

    function _antiDiag() internal view returns (uint256) {
        return board[2] * board[4] * board[6];
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
}