// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Engine } from "./Engine.sol";

/// @title Utils library for fiveoutofnine (a 100% on-chain 6x6 chess engine)
/// @author fiveoutofnine
/// @dev Understand the representations of the chess pieces, board, and moves very carefully before
/// using this library:
/// ======================================Piece Representation======================================
/// Each chess piece is defined with 4 bits as follows:
///     * The first bit denotes the color (0 means black; 1 means white).
///     * The last 3 bits denote the type:
///         | Bits | # | Type   |
///         | ---- | - | ------ |
///         | 000  | 0 | Empty  |
///         | 001  | 1 | Pawn   |
///         | 010  | 2 | Bishop |
///         | 011  | 3 | Rook   |
///         | 100  | 4 | Knight |
///         | 101  | 5 | Queen  |
///         | 110  | 6 | King   |
/// ======================================Board Representation======================================
/// The board is an 8x8 representation of a 6x6 chess board. For efficiency, all information is
/// bitpacked into a single uint256. Thus, unlike typical implementations, board positions are
/// accessed via bit shifts and bit masks, as opposed to array accesses. Since each piece is 4 bits,
/// there are 64 ``indices'' to access:
///                                     63 62 61 60 59 58 57 56
///                                     55 54 53 52 51 50 49 48
///                                     47 46 45 44 43 42 41 40
///                                     39 38 37 36 35 34 33 32
///                                     31 30 29 28 27 26 25 24
///                                     23 22 21 20 19 18 17 16
///                                     15 14 13 12 11 10 09 08
///                                     07 06 05 04 03 02 01 00
/// All numbers in the figure above are in decimal representation.
/// For example, the piece at index 27 is accessed with ``(board >> (27 << 2)) & 0xF''.
///
/// The top/bottom rows and left/right columns are treated as sentinel rows/columns for efficient
/// boundary validation (see {Chess-generateMoves} and {Chess-isValid}). i.e., (63, ..., 56),
/// (07, ..., 00), (63, ..., 07), and (56, ..., 00) never contain pieces. Every bit in those rows
/// and columns should be ignored, except for the last bit. The last bit denotes whose turn it is to
/// play (0 means black's turn; 1 means white's turn). e.g. a potential starting position:
///                                Black
///                       00 00 00 00 00 00 00 00                    Black
///                       00 03 02 05 06 02 03 00                 ♜ ♝ ♛ ♚ ♝ ♜
///                       00 01 01 01 01 01 01 00                 ♟ ♟ ♟ ♟ ♟ ♟
///                       00 00 00 00 00 00 00 00     denotes
///                       00 00 00 00 00 00 00 00    the board
///                       00 09 09 09 09 09 09 00                 ♙ ♙ ♙ ♙ ♙ ♙
///                       00 11 12 13 14 12 11 00                 ♖ ♘ ♕ ♔ ♘ ♖
///                       00 00 00 00 00 00 00 01                    White
///                                White
/// All numbers in the example above are in decimal representation.
/// ======================================Move Representation=======================================
/// Each move is allocated 12 bits. The first 6 bits are the index the piece is moving from, and the
/// last 6 bits are the index the piece is moving to. Since the index representing a square is at
/// most 54, 6 bits sufficiently represents any index (0b111111 = 63 > 54). e.g. 1243 denotes a move
/// from index 19 to 27 (1243 = (19 << 6) | 27).
///
/// Since the board is represented by a uint256, consider including ``using Chess for uint256''.
library Chess {
    using Chess for uint256;
    using Chess for Chess.MovesArray;

    /// The depth, white's move, and black's move are bitpacked in that order as `metadata` for
    /// efficiency. As explained above, 12 bits sufficiently describe a move, so both white's and
    /// black's moves are allocated 12 bits each.
    struct Move {
        uint256 board;
        uint256 metadata;
    }

    /// ``moves'' are bitpacked into uint256s for efficiency. Since every move is defined by at most
    /// 12 bits, a uint256 can contain up to 21 moves via bitpacking (21 * 12 = 252 < 256).
    /// Therefore, `items` can contain up to 21 * 5 = 105 moves. 105 is a safe upper bound for the
    /// number of possible moves a given side may have during a real game, but be wary because there
    /// is no formal proof of the upper bound being less than or equal to 105.
    struct MovesArray {
        uint256 index;
        uint256[5] items;
    }

    /// @notice Takes in a board position, and applies the move `_move` to it.
    /// @dev After applying the move, the board's perspective is updated (see {rotate}). Thus,
    /// engines with symmterical search algorithms -- like negamax search -- probably work best.
    /// @param _board The board to apply the move to.
    /// @param _move The move to apply.
    /// @return The reversed board after applying `_move` to `_board`.
    function applyMove(uint256 _board, uint256 _move) internal pure returns (uint256) {
        unchecked {
            // Get piece at the from index
            uint256 piece = (_board >> ((_move >> 6) << 2)) & 0xF;
            // Replace 4 bits at the from index with 0000
            _board &= type(uint256).max ^ (0xF << ((_move >> 6) << 2));
            // Replace 4 bits at the to index with 0000
            _board &= type(uint256).max ^ (0xF << ((_move & 0x3F) << 2));
            // Place the piece at the to index
            _board |= (piece << ((_move & 0x3F) << 2));

            return _board.rotate();
        }
    }

    /// @notice Switches the perspective of the board by reversing its 4-bit subdivisions (e.g.
    /// 1100-0011 would become 0011-1100).
    /// @dev Since the last bit exchanges positions with the 4th bit, the turn identifier is updated
    /// as well.
    /// @param _board The board to reverse the perspective on.
    /// @return `_board` reversed.
    function rotate(uint256 _board) internal pure returns (uint256) {
        uint256 rotatedBoard;

        unchecked {
            for (uint256 i; i < 64; ++i) {
                rotatedBoard = (rotatedBoard << 4) | (_board & 0xF);
                _board >>= 4;
            }
        }

        return rotatedBoard;
    }

    /// @notice Generates all possible pseudolegal moves for a given position and color.
    /// @dev The last bit denotes which color to generate the moves for (see {Chess}). Also, the
    /// function errors if more than 105 moves are found (see {Chess-MovesArray}). All moves are
    /// expressed in code as shifts respective to the board's 8x8 representation (see {Chess}).
    /// @param _board The board position to generate moves for.
    /// @return Bitpacked uint256(s) containing moves.
    function generateMoves(uint256 _board) internal pure returns (uint256[5] memory) {
        Chess.MovesArray memory movesArray;
        uint256 move;
        uint256 moveTo;

        unchecked {
            // `0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289` is a mapping of indices
            // relative to the 6x6 board to indices relative to the 8x8 representation (see
            // {Chess-getAdjustedIndex}).
            for (
                uint256 index = 0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289;
                index != 0;
                index >>= 6
            ) {
                uint256 adjustedIndex = index & 0x3F;
                uint256 adjustedBoard = _board >> (adjustedIndex << 2);
                uint256 piece = adjustedBoard & 0xF;
                // Skip if square is empty or not the color of the board the function call is
                // analyzing.
                if (piece == 0 || piece >> 3 != _board & 1) continue;
                // The first bit can be discarded because the if statement above catches all
                // redundant squares.
                piece &= 7;

                if (piece == 1) { // Piece is a pawn.
                    // 1 square in front of the pawn is empty.
                    if ((adjustedBoard >> 0x20) & 0xF == 0) {
                        movesArray.append(adjustedIndex, adjustedIndex + 8);
                        // The pawn is in its starting row and 2 squares in front is empty. This
                        // must be nested because moving 2 squares would not be valid if there was
                        // an obstruction 1 square in front (i.e. pawns can not jump over pieces).
                        if (adjustedIndex >> 3 == 2 && (adjustedBoard >> 0x40) & 0xF == 0) {
                            movesArray.append(adjustedIndex, adjustedIndex + 0x10);
                        }
                    }
                    // Moving to the right diagonal by 1 captures a piece.
                    if (_board.isCapture(adjustedBoard >> 0x1C)) {
                        movesArray.append(adjustedIndex, adjustedIndex + 7); 
                    }
                    // Moving to the left diagonal by 1 captures a piece.
                    if (_board.isCapture(adjustedBoard >> 0x24)) {
                        movesArray.append(adjustedIndex, adjustedIndex + 9);
                    }
                } else if (piece > 3 && piece & 1 == 0) { // Piece is a knight or a king.
                    // Knights and kings always only have 8 positions to check relative to their
                    // current position, and the relative distances are always the same. For
                    // knights, positions to check are ±{6, 10, 15, 17}. This is bitpacked into
                    // `0x060A0F11` to reduce code redundancy. Similarly, the positions to check for
                    // kings are ±{1, 7, 8, 9}, which is `0x01070809` when bitpacked.
                    for (move = piece == 4 ? 0x060A0F11 : 0x01070809; move != 0; move >>= 8) {
                        if (_board.isValid(moveTo = adjustedIndex + (move & 0xFF))) {
                            movesArray.append(adjustedIndex, moveTo);
                        }
                        if (move <= adjustedIndex
                            && _board.isValid(moveTo = adjustedIndex - (move & 0xFF)))
                        {
                            movesArray.append(adjustedIndex, moveTo);
                        }
                    }
                } else {
                    // This else block generates moves for all sliding pieces. All of the 8 for
                    // loops terminate
                    //     * before a sliding piece makes an illegal move
                    //     * or after a sliding piece captures a piece.
                    if (piece != 2) { // Ortholinear pieces (i.e. rook and queen)
                        for (move = adjustedIndex + 1; _board.isValid(move); move += 1) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 1; _board.isValid(move); move -= 1) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex + 8; _board.isValid(move); move += 8) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 8; _board.isValid(move); move -= 8) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                    }
                    if (piece != 3) { // Diagonal pieces (i.e. bishop and queen)
                        for (move = adjustedIndex + 7; _board.isValid(move); move += 7) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 7; _board.isValid(move); move -= 7) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex + 9; _board.isValid(move); move += 9) {
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                        for (move = adjustedIndex - 9; _board.isValid(move); move -= 9) {
                            // Handles the edge case where a white bishop believes it can capture
                            // the ``piece'' at index 0, when it is actually the turn identifier It
                            // would mistakenly believe it is valid move via capturing a black pawn.
                            if (move == 0) break;
                            movesArray.append(adjustedIndex, move);
                            if (_board.isCapture(_board >> (move << 2))) break;
                        }
                    }
                }
            }
        }

        return movesArray.items;
    }

    /// @notice Determines whether a move is a legal move or not (includes checking whether king is
    /// checked or not after the move).
    /// @param _board The board to analyze.
    /// @param _move The move to check.
    /// @return Whether the move is legal or not.
    function isLegalMove(uint256 _board, uint256 _move) internal pure returns (bool) {
        unchecked {
            uint256 fromIndex = _move >> 6;
            uint256 toIndex = _move & 0x3F;
            if ((0x7E7E7E7E7E7E00 >> fromIndex) & 1 == 0) return false;
            if ((0x7E7E7E7E7E7E00 >> toIndex) & 1 == 0) return false;

            uint256 pieceAtFromIndex = (_board >> (fromIndex << 2)) & 0xF;
            if (pieceAtFromIndex == 0) return false;
            if (pieceAtFromIndex >> 3 != _board & 1) return false;
            pieceAtFromIndex &= 7;

            uint256 adjustedBoard = _board >> (toIndex << 2);
            uint256 indexChange = toIndex < fromIndex
                    ? fromIndex - toIndex
                    : toIndex - fromIndex;
            if (pieceAtFromIndex == 1) {
                if (toIndex <= fromIndex) return false;
                indexChange = toIndex - fromIndex;
                if ((indexChange == 7 || indexChange == 9)) {
                    if (!_board.isCapture(adjustedBoard)) return false;
                } else if (indexChange == 8) {
                    if (!isValid(_board, toIndex)) return false;
                } else if (indexChange == 0x10) {
                    if (!isValid(_board, toIndex - 8) || !isValid(_board, toIndex)) return false;
                } else {
                    return false;
                }
            } else if (pieceAtFromIndex == 4 || pieceAtFromIndex == 6) {
                if (((pieceAtFromIndex == 4 ? 0x28440 : 0x382) >> indexChange) & 1 == 0) {
                    return false;
                }
                if (!isValid(_board, toIndex)) return false;
            } else {
                bool rayFound;
                if (pieceAtFromIndex != 2) {
                    rayFound = searchRay(_board, fromIndex, toIndex, 1)
                        || searchRay(_board, fromIndex, toIndex, 8);
                }
                if (pieceAtFromIndex != 3) {
                    rayFound = rayFound
                        || searchRay(_board, fromIndex, toIndex, 7)
                        || searchRay(_board, fromIndex, toIndex, 9);
                }
                if (!rayFound) return false;
            }

            if (Engine.negaMax(_board.applyMove(_move), 1) < -1_260) return false;

            return true;
        }
    }

    /// @notice Determines whether there is a clear path along a direction vector from one index to
    /// another index on the board.
    /// @dev The board's representation essentially flattens it from 2D to 1D, so `_directionVector`
    /// should be the change in index that represents the direction vector.
    /// @param _board The board to analyze.
    /// @param _fromIndex The index of the starting piece.
    /// @param _toIndex The index of the ending piece.
    /// @param _directionVector The direction vector of the ray.
    /// @return Whether there is a clear path between `_fromIndex` and `_toIndex` or not.
    function searchRay(
        uint256 _board,
        uint256 _fromIndex,
        uint256 _toIndex,
        uint256 _directionVector
    )
        internal pure
        returns (bool)
    {
        unchecked {
            uint256 indexChange;
            uint256 rayStart;
            uint256 rayEnd;
            if (_fromIndex < _toIndex) {
                indexChange = _toIndex - _fromIndex;
                rayStart = _fromIndex + _directionVector;
                rayEnd = _toIndex;
            } else {
                indexChange = _fromIndex - _toIndex;
                rayStart = _toIndex;
                rayEnd = _fromIndex - _directionVector;
            }
            if (indexChange % _directionVector != 0) return false;

            for (
                rayStart = rayStart;
                rayStart < rayEnd;
                rayStart += _directionVector
            ) {
                if (!isValid(_board, rayStart)) return false;
                if (isCapture(_board, _board >> (rayStart << 2))) return false;
            }

            if (!isValid(_board, rayStart)) return false;

            return rayStart == rayEnd;
        }
    }

    /// @notice Determines whether a move results in a capture or not.
    /// @param _board The board prior to the potential capture.
    /// @param _indexAdjustedBoard The board bitshifted to the to index to consider.
    /// @return Whether the move is a capture or not.
    function isCapture(uint256 _board, uint256 _indexAdjustedBoard) internal pure returns (bool) {
        unchecked {
            return (_indexAdjustedBoard & 0xF) != 0 // The square is not empty.
                && (_indexAdjustedBoard & 0xF) >> 3 != _board & 1; // The piece is opposite color.
        }
    }

    /// @notice Determines whether a move is valid or not (i.e. within bounds and not capturing
    /// same colored piece).
    /// @dev As mentioned above, the board representation has 2 sentinel rows and columns for
    /// efficient boundary validation as follows:
    ///                                           0 0 0 0 0 0 0 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 1 1 1 1 1 1 0
    ///                                           0 0 0 0 0 0 0 0,
    /// where 1 means a piece is within the board, and 0 means the piece is out of bounds. The bits
    /// are bitpacked into a uint256 (i.e. ``0x7E7E7E7E7E7E00 = 0 << 63 | ... | 0 << 0'') for
    /// efficiency.
    ///
    /// Moves that overflow the uint256 are computed correctly because bitshifting more than bits
    /// available results in 0. However, moves that underflow the uint256 (i.e. applying the move
    /// results in a negative index) must be checked beforehand.
    /// @param _board The board on which to consider whether the move is valid.
    /// @param _toIndex The to index of the move.
    /// @return Whether the move is valid or not.
    function isValid(uint256 _board, uint256 _toIndex) internal pure returns (bool) {
        unchecked {
            return (0x7E7E7E7E7E7E00 >> _toIndex) & 1 == 1 // Move is within bounds.
                && ((_board >> (_toIndex << 2)) & 0xF == 0 // Square is empty.
                    || (((_board >> (_toIndex << 2)) & 0xF) >> 3) != _board & 1); // Piece captured.
        }
    }

    /// @notice Maps an index relative to the 6x6 board to the index relative to the 8x8
    /// representation.
    /// @dev The indices are mapped as follows:
    ///                           35 34 33 32 31 30              54 53 52 51 50 49
    ///                           29 28 27 26 25 24              46 45 44 43 42 41
    ///                           23 22 21 20 19 18    mapped    38 37 36 35 34 33
    ///                           17 16 15 14 13 12      to      30 29 28 27 26 25
    ///                           11 10 09 08 07 06              22 21 20 19 18 17
    ///                           05 04 03 02 01 00              14 13 12 11 10 09
    /// All numbers in the figure above are in decimal representation. The bits are bitpacked into a
    /// uint256 (i.e. ``0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289 = 54 << (6 * 35) |
    /// ... | 9 << (6 * 0)'') for efficiency.
    /// @param _index Index relative to the 6x6 board.
    /// @return Index relative to the 8x8 representation.
    function getAdjustedIndex(uint256 _index) internal pure returns (uint256) {
        unchecked {
            return (
                (0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289 >> (_index * 6)) & 0x3F
            );
        }
    }

    /// @notice Appends a move to a {Chess-MovesArray} object.
    /// @dev Since each uint256 fits at most 21 moves (see {Chess-MovesArray}), {Chess-append}
    /// bitpacks 21 moves per uint256 before moving on to the next uint256.
    /// @param _movesArray {Chess-MovesArray} object to append the new move to.
    /// @param _fromMoveIndex Index the piece moves from.
    /// @param _toMoveIndex Index the piece moves to.
    function append(MovesArray memory _movesArray, uint256 _fromMoveIndex, uint256 _toMoveIndex)
        internal pure
    {
        unchecked {
            uint256 currentIndex = _movesArray.index;
            uint256 currentPartition = _movesArray.items[currentIndex];

            if (currentPartition > (1 << 0xF6)) {
                _movesArray.items[++_movesArray.index] = (_fromMoveIndex << 6) | _toMoveIndex;
            } else {
                _movesArray.items[currentIndex] = (currentPartition << 0xC)
                    | (_fromMoveIndex << 6)
                    | _toMoveIndex;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import { Chess } from "./Chess.sol";

/// @title A 6x6 chess engine with negamax search
/// @author fiveoutofnine
/// @notice Docstrings below are written from the perspective of black (i.e. written as if the
/// engine is always black). However, due to negamax's symmetric nature, the engine may be used for
/// white as well.
library Engine {
    using Chess for uint256;
    using Engine for uint256;

    /// @notice Searches for the ``best'' move.
    /// @dev The ply depth must be at least 3 because game ending scenarios are determined lazily.
    /// This is because {generateMoves} generates pseudolegal moves. Consider the following:
    ///     1. In the case of white checkmates black, depth 2 is necessary:
    ///         * Depth 1: This is the move black plays after considering depth 2.
    ///         * Depth 2: Check whether white captures black's king within 1 turn for every such
    ///           move. If so, white has checkmated black.
    ///     2. In the case of black checkmates white, depth 3 is necessary:
    ///         * Depth 1: This is the move black plays after considering depths 2 and 3.
    ///         * Depth 2: Generate all pseudolegal moves for white in response to black's move.
    ///         * Depth 3: Check whether black captures white's king within 1 turn for every such
    ///         * move. If so, black has checkmated white.
    /// The minimum depth required to cover all the cases above is 3. For simplicity, stalemates
    /// are treated as checkmates.
    ///
    /// The function returns 0 if the game is over after white's move (no collision with any
    /// potentially real moves because 0 is not a valid index), and returns true if the game is over
    /// after black's move.
    /// @param _board The board position to analyze.
    /// @param _depth The ply depth to analyze to. Must be at least 3.
    /// @return The best move for the player (denoted by the last bit in `_board`).
    /// @return Whether white is checkmated or not.
    function searchMove(uint256 _board, uint256 _depth) internal pure returns (uint256, bool) {
        uint256[5] memory moves = _board.generateMoves();
        if (moves[0] == 0) return (0, false);
        // See {Engine-negaMax} for explanation on why `bestScore` is set to -4_196.
        int256 bestScore = -4_196;
        int256 currentScore;
        uint256 bestMove;

        unchecked {
            for (uint256 i; moves[i] != 0; ++i) {
                for (uint256 movePartition = moves[i]; movePartition != 0; movePartition >>= 0xC) {
                    currentScore = _board.evaluateMove(movePartition & 0xFFF)
                        + negaMax(_board.applyMove(movePartition & 0xFFF), _depth - 1);
                    if (currentScore > bestScore) {
                        bestScore = currentScore;
                        bestMove = movePartition & 0xFFF;
                    }
                }
            }
        }

        // 1_260 is equivalent to 7 queens (7 * 180 = 1260). Since a king's capture is equivalent to
        // an evaluation of 4_000, ±1_260 catches all lines that include the capture of a king.
        if (bestScore < -1_260) return (0, false);
        return (bestMove, bestScore > 1_260);
    }

    /// @notice Searches and evaluates moves using a variant of the negamax search algorithm.
    /// @dev For efficiency, the function evaluates how good moves are and sums them up, rather than
    /// evaluating entire board positions. Thus, the only pruning the algorithm performs is when a
    /// king is captured. If a king is captured, it always returns -4,000, which is the king's value
    /// (see {Chess}) because there is nothing more to consider.
    /// @param _board The board position to analyze.
    /// @param _depth The ply depth to analyze to.
    /// @return The cumulative score searched to a ply depth of `_depth`, assuming each side picks
    /// their ``best'' (as decided by {Engine-evaluateMove}) moves.
    function negaMax(uint256 _board, uint256 _depth) internal pure returns (int256) {
        // Base case for the recursion.
        if (_depth == 0) return 0;
        uint256[5] memory moves = _board.generateMoves();
        // There is no ``best'' score if there are no moves to play.
        if (moves[0] == 0) return 0;
        // `bestScore` is initially set to -4_196 because no line will result in a cumulative
        // evaluation of <-4_195. -4_195 occurs, for example. when the engine's king is captured
        // (-4000), and the player captures an engine's queen on index 35 (-181) with knight from
        // index 52 (-14).
        int256 bestScore = -4_196;
        int256 currentScore;
        uint256 bestMove;

        unchecked {
            for (uint256 i; moves[i] != 0; ++i) {
                for (uint256 movePartition = moves[i]; movePartition != 0; movePartition >>= 0xC) {
                    currentScore = _board.evaluateMove(movePartition & 0xFFF);
                    if (currentScore > bestScore) {
                        bestScore = currentScore;
                        bestMove = movePartition & 0xFFF;
                    }
                }
            }

            // If a king is captured, stop the recursive call stack and return a score of 4_000.
            // There is nothing more to consider.
            if (((_board >> ((bestMove & 0x3F) << 2)) & 7) == 6) return 4_000;
            return _board & 1 == 0
                ? bestScore + negaMax(_board.applyMove(bestMove), _depth - 1)
                : -bestScore + negaMax(_board.applyMove(bestMove), _depth - 1);
        }
    }

    /// @notice Uses piece-square tables (PSTs) to evaluate how ``good'' a move is.
    /// @dev The PSTs were selected semi-arbitrarily with chess strategies in mind (e.g. pawns are
    /// good in the center). Updating them changes the way the engine ``thinks.'' Each piece's PST
    /// is bitpacked into as few uint256s as possible for efficiency (see {Engine-getPst} and
    /// {Engine-getPstTwo}):
    ///          Pawn                Bishop               Knight                   Rook
    ///    20 20 20 20 20 20    62 64 64 64 64 62    54 56 54 54 56 58    100 100 100 100 100 100
    ///    30 30 30 30 30 30    64 66 66 66 66 64    56 60 64 64 60 56    101 102 102 102 102 101
    ///    20 22 24 24 22 20    64 67 68 68 67 64    58 64 68 68 64 58     99 100 100 100 100  99
    ///    21 20 26 26 20 21    64 68 68 68 68 64    58 65 68 68 65 58     99 100 100 100 100  99
    ///    21 30 16 16 30 21    64 67 66 66 67 64    56 60 65 65 60 56     99 100 100 100 100  99
    ///    20 20 20 20 20 20    62 64 64 64 64 62    54 56 58 58 56 54    100 100 101 101 100 100
    ///                            Queen                         King
    ///                   176 178 179 179 178 176    3994 3992 3990 3990 3992 3994
    ///                   178 180 180 180 180 178    3994 3992 3990 3990 3992 3994
    ///                   179 180 181 181 180 179    3996 3994 3992 3992 3994 3995
    ///                   179 181 181 181 180 179    3998 3996 3996 3996 3996 3998
    ///                   178 180 181 180 180 178    4001 4001 4000 4000 4001 4001
    ///                   176 178 179 179 178 176    4004 4006 4002 4002 4006 4004
    /// All entries in the figure above are in decimal representation.
    ///
    /// Each entry in the pawn's, bishop's, knight's, and rook's PSTs uses 7 bits, and each entry in
    /// the queen's and king's PSTs uses 12 bits. Additionally, each piece is valued as following:
    ///                                      | Type   | Value |
    ///                                      | ------ | ----- |
    ///                                      | Pawn   | 20    |
    ///                                      | Bishop | 66    |
    ///                                      | Knight | 64    |
    ///                                      | Rook   | 100   |
    ///                                      | Queen  | 180   |
    ///                                      | King   | 4000  |
    /// The king's value just has to be sufficiently larger than 180 * 7 = 1260 (i.e. equivalent to
    /// 7 queens) because check/checkmates are detected lazily (see {Engine-generateMoves}).
    ///
    /// The evaluation of a move is given by
    ///                Δ(PST value of the moved piece) + (PST value of any captured pieces).
    /// @param _board The board to apply the move to.
    /// @param _move The move to evaluate.
    /// @return The evaluation of the move applied to the given position.
    function evaluateMove(uint256 _board, uint256 _move) internal pure returns (int256) {
        unchecked {
            uint256 fromIndex = 6 * (_move >> 9) + ((_move >> 6) & 7) - 7;
            uint256 toIndex = 6 * ((_move & 0x3F) >> 3) + ((_move & 0x3F) & 7) - 7;
            uint256 pieceAtFromIndex = (_board >> ((_move >> 6) << 2)) & 7;
            uint256 pieceAtToIndex = (_board >> ((_move & 0x3F) << 2)) & 7;
            uint256 oldPst;
            uint256 newPst;
            uint256 captureValue;

            if (pieceAtToIndex != 0) {
                if (pieceAtToIndex < 5) { // Piece is not a queen or king
                    captureValue = (getPst(pieceAtToIndex) >> (7 * (0x23 - toIndex))) & 0x7F;
                } else
                if (toIndex < 0x12) { // Piece is queen or king and in the closer half
                    captureValue = (getPst(pieceAtToIndex) >> (0xC * (0x11 - toIndex))) & 0xFFF;
                } else { // Piece is queen or king and in the further half
                    captureValue = (getPstTwo(pieceAtToIndex) >> (0xC * (0x23 - toIndex))) & 0xFFF;
                }
            }
            if (pieceAtFromIndex < 5) { // Piece is not a queen or king
                oldPst = (getPst(pieceAtFromIndex) >> (7 * fromIndex)) & 0x7F;
                newPst = (getPst(pieceAtFromIndex) >> (7 * toIndex)) & 0x7F;
            } else
            if (fromIndex < 0x12) { // Piece is queen or king and in the closer half
                oldPst = (getPstTwo(pieceAtFromIndex) >> (0xC * fromIndex)) & 0xFFF;
                newPst = (getPstTwo(pieceAtFromIndex) >> (0xC * toIndex)) & 0xFFF;
            } else { // Piece is queen or king and in the further half
                oldPst = (getPst(pieceAtFromIndex) >> (0xC * (fromIndex - 0x12))) & 0xFFF;
                newPst = (getPst(pieceAtFromIndex) >> (0xC * (toIndex - 0x12))) & 0xFFF;
            }

            return int256(captureValue + newPst) - int256(oldPst);
        }
    }

    /// @notice Maps a given piece type to its PST (see {Engine-evaluateMove} for details on the
    /// PSTs and {Chess} for piece representation).
    /// @dev The queen's and king's PSTs do not fit in 1 uint256, so their PSTs are split into 2
    /// uint256s each. {Chess-getPst} contains the first half, and {Chess-getPstTwo} contains the
    /// second half.
    /// @param _type A piece type defined in {Chess}.
    /// @return The PST corresponding to `_type`.
    function getPst(uint256 _type) internal pure returns (uint256) {
        if (_type == 1) return 0x2850A142850F1E3C78F1E2858C182C50A943468A152A788103C54A142850A14;
        if (_type == 2) return 0x7D0204080FA042850A140810E24487020448912240810E1428701F40810203E;
        if (_type == 3) return 0xC993264C9932E6CD9B365C793264C98F1E4C993263C793264C98F264CB97264;
        if (_type == 4) return 0x6CE1B3670E9C3C8101E38750224480E9D4189120BA70F20C178E1B3874E9C36;
        if (_type == 5) return 0xB00B20B30B30B20B00B20B40B40B40B40B20B30B40B50B50B40B3;
        return 0xF9AF98F96F96F98F9AF9AF98F96F96F98F9AF9CF9AF98F98F9AF9B;
    }

    /// @notice Maps a queen or king to the second half of its PST (see {Engine-getPst}).
    /// @param _type A piece type defined in {Chess}. Must be a queen or a king (see
    /// {Engine-getPst}).
    /// @return The PST corresponding to `_type`.
    function getPstTwo(uint256 _type) internal pure returns (uint256) {
        return _type == 5
            ? 0xB30B50B50B50B40B30B20B40B50B40B40B20B00B20B30B30B20B0
            : 0xF9EF9CF9CF9CF9CF9EFA1FA1FA0FA0FA1FA1FA4FA6FA2FA2FA6FA4;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract AddressRegistry {
    address payable immutable WETH_9;
    address public immutable KP3R_V1;
    address public immutable KP3R_LP;
    address public immutable SWAP_ROUTER;
    address public immutable KEEP3R;
    address public immutable SUDOSWAP_FACTORY;
    address public immutable SUDOSWAP_CURVE;

    constructor() {
        address _weth;
        address _kp3rV1;
        address _kp3rLP;
        address _keep3r;
        address _uniswapRouter;
        address _sudoswapFactory;
        address _sudoswapCurve;

        uint256 _chainId = block.chainid;
        if (_chainId == 1 || _chainId == 31337) {
            _weth = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
            _kp3rV1 = 0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44;
            _kp3rLP = 0x3f6740b5898c5D3650ec6eAce9a649Ac791e44D7;
            _keep3r = 0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xb16c1342E617A5B6E4b631EB114483FDB289c0A4;
            _sudoswapCurve = 0x7942E264e21C5e6CbBA45fe50785a15D3BEb1DA0;
        } else if (_chainId == 5) {
            _weth = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;
            _kp3rV1 = 0x16F63C5036d3F48A239358656a8f123eCE85789C;
            _kp3rLP = 0xb4A7137B024d4C0531b0164fCb6E8fc20e6777Ae;
            _keep3r = 0x229d018065019c3164B899F4B9c2d4ffEae9B92b;
            _uniswapRouter = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
            _sudoswapFactory = 0xF0202E9267930aE942F0667dC6d805057328F6dC;
            _sudoswapCurve = 0x02363a2F1B2c2C5815cb6893Aa27861BE0c4F760;
        }

        WETH_9 = payable(_weth);
        KP3R_V1 = _kp3rV1;
        KP3R_LP = _kp3rLP;
        KEEP3R = _keep3r;
        SWAP_ROUTER = _uniswapRouter;
        SUDOSWAP_FACTORY = _sudoswapFactory;
        SUDOSWAP_CURVE = _sudoswapCurve;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

abstract contract GameSchema {
    error WrongMethod(); // method should not be externally called
    error WrongTiming(); // method called at wrong roadmap state or cooldown
    error WrongKeeper(); // keeper doesn't fulfill the required params
    error WrongValue(); // badge minting value should be between 0.05 and 1
    error WrongBadge(); // only the badge owner or allowed can access
    error WrongTeam(); // only specific badges can access
    error WrongNFT(); // an unknown NFT was sent to the contract

    event VoteSubmitted(TEAM _team, uint256 _badgeId, address _buttPlug);
    event MoveExecuted(TEAM _team, address _buttPlug, int8 _moveScore, uint64 _weight);
    event MedalMinted(uint256 _badgeId, bytes32 _seed, uint256[] _badges, uint256 _totalScore);

    address public immutable FIVE_OUT_OF_NINE;

    constructor(address _fiveOutOfNine) {
        FIVE_OUT_OF_NINE = _fiveOutOfNine;
    }

    uint256 constant BASE = 10_000;
    uint256 constant MAX_UINT = type(uint256).max;
    uint256 constant CHECKMATE = 0x3256230011111100000000000000000099999900BCDECB000000001; // new board
    uint256 constant MAGIC_NUMBER = 0xDB5D33CB1BADB2BAA99A59238A179D71B69959551349138D30B289; // by @fiveOutOfNine
    uint256 constant BUTT_PLUG_GAS_LIMIT = 10_000_000; // amount of gas used to read buttPlug moves
    uint256 constant BUTT_PLUG_GAS_DELTA = 1_000_000; // gas reduction per match to read buttPlug moves

    enum STATE {
        ANNOUNCEMENT, // rabbit can cancel event
        TICKET_SALE, // can mint badges
        GAME_RUNNING, // game runs, can mint badges
        GAME_OVER, // game stops, can unbondLiquidity
        PREPARATIONS, // can mint medals, waits until kLPs are unbonded
        PRIZE_CEREMONY, // can withdraw prizes
        CANCELLED // a critical bug was found
    }

    STATE public state = STATE.ANNOUNCEMENT;

    uint256 canStartSales; // can startEvent()
    uint256 canPlayNext; // can executeMove()
    uint256 canPushLiquidity; // can pushLiquidity()
    uint256 canUpdateSpotPriceNext; // can updateSpotPrice()

    enum TEAM {
        ZERO,
        ONE,
        BUTTPLUG,
        MEDAL,
        SCOREBOARD
    }

    /*///////////////////////////////////////////////////////////////
                            GAME VARIABLES
    //////////////////////////////////////////////////////////////*/

    mapping(TEAM => uint256) matchesWon; // amount of matches won by each team
    mapping(TEAM => int256) matchScore; // current match score for each team
    uint256 matchNumber; // amount of matches started
    uint256 matchMoves; // amount of moves made on current match

    /* Badge mechanics */
    uint256 totalPlayers; // amount of player badges minted

    /* Vote mechanics */
    mapping(uint256 => uint256) voteData; // player -> vote data
    mapping(TEAM => address) buttPlug; // team -> most-voted buttPlug
    mapping(TEAM => mapping(address => uint256)) votes; // team -> buttPlug -> votes

    /* Prize mechanics */
    uint256 totalPrize; // total amount of kLPs minted as liquidity
    uint256 totalSales; // total amount of ETH from sudoswap sales
    uint256 totalWeight; // total weigth of minted medals
    uint256 totalScore; // total score of minted medals
    mapping(uint256 => uint256) claimedSales; // medal -> amount of ETH already claimed

    mapping(uint256 => int256) score; // badge -> score record (see _calcScore)
    mapping(uint256 => mapping(uint256 => int256)) lastUpdatedScore; // badge -> buttPlug -> lastUpdated score

    /* Badge mechanics */

    function _getBadgeType(uint256 _badgeId) internal pure returns (TEAM) {
        return TEAM(uint8(_badgeId));
    }

    /* Players */

    /// @dev Non-view method, increases totalPlayers
    function _calcPlayerBadge(uint256 _tokenId, TEAM _team, uint256 _weight) internal returns (uint256 _badgeId) {
        return (++totalPlayers << 96) + (_weight << 32) + (_tokenId << 8) + uint256(_team);
    }

    function _getStakedToken(uint256 _badgeId) internal pure returns (uint256 _tokenId) {
        return uint16(_badgeId >> 8);
    }

    function _getBadgeWeight(uint256 _badgeId) internal pure returns (uint256 _weight) {
        return uint64(_badgeId >> 32);
    }

    function _getPlayerNumber(uint256 _badgeId) internal pure returns (uint256 _playerNumber) {
        return uint16(_badgeId >> 96);
    }

    /* ButtPlugs */

    function _calcButtPlugBadge(address _buttPlug, TEAM _team) internal pure returns (uint256 _badgeId) {
        return (uint256(uint160(_buttPlug)) << 96) + uint256(_team);
    }

    function _getButtPlugAddress(uint256 _badgeId) internal pure returns (address _buttPlug) {
        return address(uint160(_badgeId >> 96));
    }

    /* Medals */

    function _calcMedalBadge(uint256 _totalWeight, uint256 _totalScore, bytes32 _salt)
        internal
        pure
        returns (uint256 _badgeId)
    {
        return (_totalScore << 96) + (_totalWeight << 32) + uint32(uint256(_salt) << 8) + uint256(TEAM.MEDAL);
    }

    function _getMedalScore(uint256 _badgeId) internal pure returns (uint256 _score) {
        return uint64(_badgeId >> 96);
    }

    function _getMedalSalt(uint256 _badgeId) internal pure returns (uint256 _salt) {
        return uint24(_badgeId >> 8);
    }

    /* Vote mechanism */

    function _calcVoteData(address _buttPlug, uint256 _voteParticipation) internal pure returns (uint256 _voteData) {
        return (_voteParticipation << 160) + uint160(_buttPlug);
    }

    function _getVoteAddress(uint256 _vote) internal pure returns (address _voteAddress) {
        return address(uint160(_vote));
    }

    function _getVoteParticipation(uint256 _vote) internal pure returns (uint256 _voteParticipation) {
        return uint256(_vote >> 160);
    }

    /* Score mechanism */

    function _calcScore(uint256 _badgeId) internal view returns (int256 _score) {
        TEAM _team = _getBadgeType(_badgeId);
        if (_team < TEAM.BUTTPLUG) {
            // player badge
            uint256 _previousVote = voteData[_badgeId];
            address _votedButtPlug = _getVoteAddress(_previousVote);
            uint256 _voteParticipation = _getVoteParticipation(_previousVote);
            uint256 _votedButtPlugBadge = _calcButtPlugBadge(_votedButtPlug, _team);

            int256 _lastVoteScore = score[_votedButtPlugBadge] - lastUpdatedScore[_badgeId][_votedButtPlugBadge];
            if (_lastVoteScore >= 0) {
                return score[_badgeId] + int256((uint256(_lastVoteScore) * _voteParticipation) / BASE);
            } else {
                return score[_badgeId] - int256((uint256(-_lastVoteScore) * _voteParticipation) / BASE);
            }
        } else if (_team == TEAM.BUTTPLUG) {
            // buttplug badge
            address _buttPlug = _getButtPlugAddress(_badgeId);
            uint256 _buttPlugZERO = _calcButtPlugBadge(_buttPlug, TEAM.ZERO);
            uint256 _buttPlugONE = _calcButtPlugBadge(_buttPlug, TEAM.ONE);
            return score[_buttPlugZERO] + score[_buttPlugONE];
        } else {
            // medal badge
            return int256(_getMedalScore(_badgeId));
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {GameSchema} from './GameSchema.sol';
import {AddressRegistry} from './AddressRegistry.sol';
import {IKeep3r} from 'interfaces/IKeep3r.sol';
import {IButtPlug, IChess} from 'interfaces/IGame.sol';
import {Base64} from './libs/Base64.sol';
import {Jeison, Strings, IntStrings} from './libs/Jeison.sol';
import {FiveOutOfNineUtils, Chess} from './libs/FiveOutOfNineUtils.sol';

contract NFTDescriptor is GameSchema, AddressRegistry {
    using Chess for uint256;
    using Jeison for Jeison.JsonObject;
    using Jeison for string;
    using Strings for address;
    using Strings for uint256;
    using Strings for uint160;
    using Strings for uint32;
    using Strings for uint16;
    using IntStrings for int256;

    constructor(address _fiveOutOfNine) GameSchema(_fiveOutOfNine) {}

    function _tokenURI(uint256 _badgeId) public view virtual returns (string memory _uri) {
        string memory _nameStr;
        string memory _descriptionStr;
        Jeison.DataPoint[] memory _datapoints = new Jeison.DataPoint[](2);
        Jeison.DataPoint[] memory _longDatapoints = new Jeison.DataPoint[](3);
        Jeison.JsonObject[] memory _metadata;

        /* Scoreboard */
        if (_badgeId == 0) {
            _nameStr = 'ChessOlympiads Scoreboard';
            _descriptionStr = 'Scoreboard NFT with information about the game state';
            _metadata = new Jeison.JsonObject[](6);

            {
                _datapoints[0] = Jeison.dataPoint('trait_type', 'game-score');
                _datapoints[1] = Jeison.dataPoint('value', _getScoreboard());
                _metadata[0] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'players');
                _datapoints[1] = Jeison.dataPoint('value', totalPlayers.toString());
                _metadata[1] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'prize');
                _datapoints[1] = Jeison.dataPoint('value', (totalPrize / 1e15).toString());
                _metadata[2] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'sales');
                _datapoints[1] = Jeison.dataPoint('value', (totalSales / 1e15).toString());
                _metadata[3] = Jeison.create(_datapoints);

                _datapoints[0] = Jeison.dataPoint('trait_type', 'period-credits');
                _datapoints[1] =
                    Jeison.dataPoint('value', (IKeep3r(KEEP3R).jobPeriodCredits(address(this)) / 1e15).toString());
                _metadata[4] = Jeison.create(_datapoints);

                if (state == STATE.ANNOUNCEMENT) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'sales-start');
                    _longDatapoints[1] = Jeison.dataPoint('value', canStartSales);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.TICKET_SALE) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'game-start');
                    _longDatapoints[1] = Jeison.dataPoint('value', canPushLiquidity);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.GAME_RUNNING) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'can-play-next');
                    _longDatapoints[1] = Jeison.dataPoint('value', canPlayNext);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.GAME_OVER) {
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'can-unbond-liquidity');
                    _datapoints[1] = Jeison.dataPoint('value', true);
                    _metadata[5] = Jeison.create(_datapoints);
                } else if (state == STATE.PREPARATIONS) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'rewards-start');
                    _longDatapoints[1] =
                        Jeison.dataPoint('value', IKeep3r(KEEP3R).canWithdrawAfter(address(this), KP3R_LP));
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                } else if (state == STATE.PRIZE_CEREMONY) {
                    _longDatapoints[0] = Jeison.dataPoint('trait_type', 'can-update-next');
                    _longDatapoints[1] = Jeison.dataPoint('value', canUpdateSpotPriceNext);
                    _longDatapoints[2] = Jeison.dataPoint('display_type', 'date');
                    _metadata[5] = Jeison.create(_longDatapoints);
                }
            }
        } else {
            TEAM _team = _getBadgeType(_badgeId);

            /* Player metadata */
            if (_team < TEAM.BUTTPLUG) {
                _nameStr = string(abi.encodePacked('Player #', _getPlayerNumber(_badgeId).toString()));
                _descriptionStr = string(
                    abi.encodePacked('Player Badge with bonded FiveOutOfNine#', (_getStakedToken(_badgeId)).toString())
                );

                _metadata = new Jeison.JsonObject[](5);
                {
                    uint256 _voteData = voteData[_badgeId];

                    string memory teamString = _team == TEAM.ZERO ? 'A' : 'B';
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _calcScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'team');
                    _datapoints[1] = Jeison.dataPoint('value', teamString);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'weight');
                    _datapoints[1] = Jeison.dataPoint('value', _getBadgeWeight(_badgeId) / 1e6);
                    _metadata[2] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'vote');
                    _datapoints[1] =
                        Jeison.dataPoint('value', (uint160(_getVoteAddress(_voteData)) >> 128).toHexString());
                    _metadata[3] = Jeison.create(_datapoints);
                    _datapoints = new Jeison.DataPoint[](3);
                    _datapoints[0] = Jeison.dataPoint('display_type', 'boost_percentage');
                    _datapoints[1] = Jeison.dataPoint('trait_type', 'vote_participation');
                    _datapoints[2] = Jeison.dataPoint('value', _getVoteParticipation(_voteData) / 100);
                    _metadata[4] = Jeison.create(_datapoints);
                }
            }

            /* ButtPlug metadata */
            if (_team == TEAM.BUTTPLUG) {
                address _buttPlug = _getButtPlugAddress(_badgeId);

                _nameStr = string(abi.encodePacked('Strategy ', (uint160(_buttPlug) >> 128).toHexString()));
                _descriptionStr = string(abi.encodePacked('Strategy Badge for contract at ', _buttPlug.toHexString()));

                _metadata = new Jeison.JsonObject[](4);

                {
                    uint256 _board = IChess(FIVE_OUT_OF_NINE).board();
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _calcScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);

                    (bool _isLegal,, uint256 _simGasUsed, string memory _description) =
                        _simulateButtPlug(_buttPlug, _board);

                    _datapoints[0] = Jeison.dataPoint('trait_type', 'simulated_move');
                    _datapoints[1] = Jeison.dataPoint('value', _description);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'simulated_gas');
                    _datapoints[1] = Jeison.dataPoint('value', _simGasUsed);
                    _metadata[2] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'is_legal_move');
                    _datapoints[1] = Jeison.dataPoint('value', _isLegal);
                    _metadata[3] = Jeison.create(_datapoints);
                }
            }

            /* Medal metadata */
            if (_team == TEAM.MEDAL) {
                _nameStr = string(abi.encodePacked('Medal ', _getMedalSalt(_badgeId).toHexString()));
                _descriptionStr = string(abi.encodePacked('Medal with score ', _getMedalScore(_badgeId).toHexString()));

                _metadata = new Jeison.JsonObject[](3);

                {
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'score');
                    _datapoints[1] = Jeison.dataPoint('value', _getMedalScore(_badgeId) / 1e6);
                    _metadata[0] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'weight');
                    _datapoints[1] = Jeison.dataPoint('value', _getBadgeWeight(_badgeId) / 1e6);
                    _metadata[1] = Jeison.create(_datapoints);
                    _datapoints[0] = Jeison.dataPoint('trait_type', 'salt');
                    _datapoints[1] = Jeison.dataPoint('value', _getMedalSalt(_badgeId).toHexString());
                    _metadata[2] = Jeison.create(_datapoints);
                }
            }
        }

        _datapoints = new Jeison.DataPoint[](4);
        _datapoints[0] = Jeison.dataPoint('name', _nameStr);
        _datapoints[1] = Jeison.dataPoint('description', _descriptionStr);
        string memory _image = Base64.encode(bytes(_drawSVG(_badgeId)));
        _image = string(abi.encodePacked('data:image/svg+xml;base64,', _image));
        _datapoints[2] = Jeison.dataPoint('image_data', _image);
        _datapoints[3] = Jeison.arraify('attributes', _metadata);

        return Jeison.create(_datapoints).getBase64();
    }

    function _simulateButtPlug(address _buttPlug, uint256 _board)
        internal
        view
        returns (bool _isLegal, uint256 _simMove, uint256 _simGasUsed, string memory _description)
    {
        uint256 _gasLeft = gasleft();
        try IButtPlug(_buttPlug).readMove(_board) returns (uint256 _move) {
            _simMove = _move;
            _simGasUsed = _gasLeft - gasleft();
        } catch {
            _simMove = 0;
            _simGasUsed = _gasLeft - gasleft();
        }
        _isLegal = _board.isLegalMove(_simMove);
        _description = FiveOutOfNineUtils.describeMove(_board, _simMove);
    }

    function _getScoreboard() internal view returns (string memory scoreboard) {
        scoreboard = string(
            abi.encodePacked(
                matchesWon[TEAM.ZERO].toString(),
                '(',
                matchScore[TEAM.ZERO].toString(),
                ') - ',
                matchesWon[TEAM.ONE].toString(),
                '(',
                matchScore[TEAM.ONE].toString(),
                ')'
            )
        );
    }

    function _drawSVG(uint256 _badgeId) internal view returns (string memory) {
        bytes memory _image;
        string memory _color;
        string memory _text;
        TEAM _team;

        if (_badgeId == 0) {
            _text = _getScoreboard();
            _color = '3F784C';
        } else {
            _team = _getBadgeType(_badgeId);

            if (_team == TEAM.ZERO) {
                _text = _getPlayerNumber(_badgeId).toString();
                _color = '2F88FF';
            } else if (_team == TEAM.ONE) {
                _color = 'B20D30';
            } else if (_team == TEAM.BUTTPLUG) {
                _text = (uint160(_getButtPlugAddress(_badgeId)) >> 128).toHexString();
                _color = 'F0E2E7';
            } else if (_team == TEAM.MEDAL) {
                _text = _getMedalSalt(_badgeId).toHexString();
                _color = 'F2CD5D';
            }
        }
        _image = abi.encodePacked(
            '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="300px" height="300px" viewBox="0 0 300 300" fill="none" >',
            '<path width="48" height="48" fill="white" d="M0 0H300V300H0V0z"/>',
            '<path d="M275 25H193L168 89C196 95 220 113 232 137L275 25Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>',
            '<path d="M106 25H25L67 137C79 113 103 95 131 89L106 25Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>',
            '<path d="M243 181C243 233 201 275 150 275C98 275 56 233 56 181 C56 165 60 150 67 137 C79 113 103 95 131 89 C137 88 143 87 150 87 C156 87 162 88 168 89 C196 95 220 113 232 137C239 150.561 243.75 165.449 243 181Z" fill="#',
            _color,
            '" stroke="black" stroke-width="25" stroke-linecap="round" stroke-linejoin="round"/>'
        );

        if (_badgeId != 0) {
            if (_team == TEAM.ZERO) {
                _image = abi.encodePacked(
                    _image,
                    '<svg viewBox="-115 -25 300 100"><path d="M5,90 l30,-80 30,80 M20,50 l30,0" stroke="white" stroke-width="25" stroke-linejoin="round"/></svg>'
                );
            }
            if (_team == TEAM.ONE) {
                _image = abi.encodePacked(
                    _image,
                    '<svg viewBox="-115 -25 300 100"><path d="M5,5 c80,0 80,45 0,45 c80,0 80,45 0,45z" stroke="white" stroke-width="25" stroke-linejoin="round"/></svg>'
                );
            }
        }

        _image = abi.encodePacked(
            _image,
            '<text x="50%" y="80%" stroke="black" dominant-baseline="middle" text-anchor="middle">',
            _text,
            '</text></svg>'
        );

        return string(_image);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678' '9+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)
            for {} lt(dataPtr, endPtr) {} {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(0xF8, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D)) }
            case 2 { mstore(sub(resultPtr, 1), shl(0xF8, 0x3D)) }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {Chess} from 'fiveoutofnine/Chess.sol';
import {Strings} from 'openzeppelin-contracts/utils/Strings.sol';
import {Math} from 'openzeppelin-contracts/utils/math/Math.sol';

library FiveOutOfNineUtils {
    using Math for uint256;
    using Chess for uint256;

    bytes32 internal constant FILE_NAMES = 'abcdef';

    /*///////////////////////////////////////////////////////////////
                              FIVEOUTOFNINE
    //////////////////////////////////////////////////////////////*/

    function drawMove(uint256 _board, uint256 _fromIndex) internal pure returns (string memory) {
        string memory boardString = '\\n';

        if (_board & 1 == 0) _board = _board.rotate();
        else _fromIndex = ((7 - (_fromIndex >> 3)) << 3) + (7 - (_fromIndex & 7));

        for (uint256 index = 0x24A2CC34E4524D455665A6DC75E8628E4966A6AAECB6EC72CF4D76; index != 0; index >>= 6) {
            uint256 indexToDraw = index & 0x3F;
            boardString = string(
                abi.encodePacked(
                    boardString,
                    indexToDraw & 7 == 6 ? string(abi.encodePacked(Strings.toString((indexToDraw >> 3)), ' ')) : '',
                    indexToDraw == _fromIndex ? '*' : getPieceChar((_board >> (indexToDraw << 2)) & 0xF),
                    indexToDraw & 7 == 1 && indexToDraw != 9 ? '\\n' : indexToDraw != 9 ? ' ' : ''
                )
            );
        }

        boardString = string(abi.encodePacked(boardString, '\\n  a b c d e f\\n'));

        return boardString;
    }

    function drawBoard(uint256 _board) internal pure returns (string memory) {
        string memory boardString = '\\n';

        if (_board & 1 == 0) _board = _board.rotate();

        for (uint256 index = 0x24A2CC34E4524D455665A6DC75E8628E4966A6AAECB6EC72CF4D76; index != 0; index >>= 6) {
            uint256 indexToDraw = index & 0x3F;
            boardString = string(
                abi.encodePacked(
                    boardString,
                    indexToDraw & 7 == 6 ? string(abi.encodePacked(Strings.toString((indexToDraw >> 3)), ' ')) : '',
                    getPieceChar((_board >> (indexToDraw << 2)) & 0xF),
                    indexToDraw & 7 == 1 && indexToDraw != 9 ? '\\n' : indexToDraw != 9 ? ' ' : ''
                )
            );
        }

        boardString = string(abi.encodePacked(boardString, '\\n  a b c d e f\\n'));

        return boardString;
    }

    function describeMove(uint256 _board, uint256 _move) internal pure returns (string memory) {
        bool isCapture = _board.isCapture(_board >> ((_move & 0x3F) << 2));
        return string(
            abi.encodePacked(
                indexToPosition(_move >> 6, true),
                ' ',
                getPieceName((_board >> ((_move >> 6) << 2)) & 7),
                isCapture ? ' captures ' : ' to ',
                indexToPosition(_move & 0x3F, true)
            )
        );
    }

    /// @notice Maps pieces to its corresponding unicode character.
    /// @param _piece A piece.
    /// @return The unicode character corresponding to `_piece`. It returns ``.'' otherwise.
    function getPieceChar(uint256 _piece) internal pure returns (string memory) {
        if (_piece == 1) return unicode'♟';
        if (_piece == 2) return unicode'♝';
        if (_piece == 3) return unicode'♜';
        if (_piece == 4) return unicode'♞';
        if (_piece == 5) return unicode'♛';
        if (_piece == 6) return unicode'♚';
        if (_piece == 9) return unicode'♙';
        if (_piece == 0xA) return unicode'♗';
        if (_piece == 0xB) return unicode'♖';
        if (_piece == 0xC) return unicode'♘';
        if (_piece == 0xD) return unicode'♕';
        if (_piece == 0xE) return unicode'♔';
        return unicode'·';
    }

    /// @notice Converts a position's index to algebraic notation.
    /// @param _index The index of the position.
    /// @param _isWhite Whether the piece is being determined for a white piece or not.
    /// @return The algebraic notation of `_index`.
    function indexToPosition(uint256 _index, bool _isWhite) internal pure returns (string memory) {
        unchecked {
            return _isWhite
                ? string(abi.encodePacked(FILE_NAMES[6 - (_index & 7)], Strings.toString(_index >> 3)))
                : string(abi.encodePacked(FILE_NAMES[(_index & 7) - 1], Strings.toString(7 - (_index >> 3))));
        }
    }

    /// @notice Maps piece type to its corresponding name.
    /// @param _type A piece type defined in {Chess}.
    /// @return The name corresponding to `_type`.
    function getPieceName(uint256 _type) internal pure returns (string memory) {
        if (_type == 1) return 'pawn';
        else if (_type == 2) return 'bishop';
        else if (_type == 3) return 'rook';
        else if (_type == 4) return 'knight';
        else if (_type == 5) return 'queen';
        return 'king';
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4 <0.9.0;

import {Strings} from './Strings.sol';
import {Base64} from './Base64.sol';

library IntStrings {
    function toString(int256 value) internal pure returns (string memory) {
        if (value >= 0) return Strings.toString(uint256(value));
        return string(abi.encodePacked('-', Strings.toString(uint256(-value))));
    }
}

library Jeison {
    using Strings for uint256;
    using Strings for address;
    using IntStrings for int256;

    struct DataPoint {
        string name;
        string value;
        bool isNumeric;
    }

    struct JsonObject {
        string[] varNames;
        string[] varValues;
        bool[] isNumeric;
        uint256 i;
    }

    function dataPoint(string memory varName, bool varValue) internal pure returns (DataPoint memory _datapoint) {
        string memory boolStr = varValue ? 'true' : 'false';
        _datapoint = DataPoint(varName, boolStr, true);
    }

    function dataPoint(string memory varName, string memory varValue)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        _datapoint = DataPoint(varName, varValue, false);
    }

    function dataPoint(string memory varName, address varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toHexString(), false);
    }

    function dataPoint(string memory varName, uint256 varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toString(), true);
    }

    function dataPoint(string memory varName, int256 varValue) internal pure returns (DataPoint memory _datapoint) {
        _datapoint = DataPoint(varName, varValue.toString(), true);
    }

    function dataPoint(string memory varName, uint256[] memory uintValues)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        string memory batchStr = '[';
        for (uint256 _i; _i < uintValues.length; _i++) {
            string memory varStr;
            varStr = uintValues[_i].toString();
            if (_i != 0) varStr = string(abi.encodePacked(', ', varStr));
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        batchStr = string(abi.encodePacked(batchStr, ']'));

        _datapoint = DataPoint(varName, batchStr, true);
    }

    function dataPoint(string memory varName, int256[] memory intValues)
        internal
        pure
        returns (DataPoint memory _datapoint)
    {
        string memory batchStr = '[';
        for (uint256 _i; _i < intValues.length; _i++) {
            string memory varStr;
            varStr = intValues[_i].toString();
            if (_i != 0) varStr = string(abi.encodePacked(', ', varStr));
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        batchStr = string(abi.encodePacked(batchStr, ']'));

        _datapoint = DataPoint(varName, batchStr, true);
    }

    function _load(JsonObject memory self, string memory varName, string memory varValue, bool varType)
        internal
        pure
        returns (JsonObject memory)
    {
        uint256 _index = self.i++;
        self.varNames[_index] = varName;
        self.varValues[_index] = varValue;
        self.isNumeric[_index] = varType;
        return self;
    }

    function get(JsonObject memory self) internal pure returns (string memory jsonStr) {
        jsonStr = '{';
        for (uint256 _i; _i < self.i; _i++) {
            string memory varStr;
            varStr = string(
                abi.encodePacked(
                    '"',
                    self.varNames[_i],
                    '" : ',
                    _separator(self.isNumeric[_i]),
                    self.varValues[_i], // "value" / value
                    _separator(self.isNumeric[_i])
                )
            );
            if (_i != 0) {
                // , "var" : "value"
                varStr = string(abi.encodePacked(', ', varStr));
            }
            jsonStr = string(abi.encodePacked(jsonStr, varStr));
        }

        jsonStr = string(abi.encodePacked(jsonStr, '}'));
    }

    function getBase64(JsonObject memory self) internal pure returns (string memory jsonBase64) {
        return string(abi.encodePacked('data:application/json;base64,', Base64.encode(abi.encodePacked(get(self)))));
    }

    function _separator(bool _isNumeric) private pure returns (string memory separator) {
        if (!_isNumeric) return '"';
    }

    function _initialize(uint256 _jsonLength) private pure returns (JsonObject memory json) {
        json.varNames = new string[](_jsonLength);
        json.varValues = new string[](_jsonLength);
        json.isNumeric = new bool[](_jsonLength);
        json.i = 0;
    }

    function create(DataPoint[] memory _datapoints) internal pure returns (JsonObject memory json) {
        json = _initialize(_datapoints.length);
        for (uint256 _i; _i < _datapoints.length; _i++) {
            json = _load(json, _datapoints[_i].name, _datapoints[_i].value, _datapoints[_i].isNumeric);
        }
        return json;
    }

    function arraify(string memory varName, JsonObject[] memory jsons)
        internal
        pure
        returns (DataPoint memory datapoint)
    {
        datapoint.name = varName;
        datapoint.isNumeric = true;

        string memory batchStr = '[';
        for (uint256 _i; _i < jsons.length; _i++) {
            string memory varStr;
            varStr = get(jsons[_i]);
            if (_i != 0) {
                // , "var" : "value"
                varStr = string(abi.encodePacked(', ', varStr));
            }
            batchStr = string(abi.encodePacked(batchStr, varStr));
        }

        datapoint.value = string(abi.encodePacked(batchStr, ']'));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = '0123456789abcdef';
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) result += 1;
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IButtPlug {
    function readMove(uint256 _board) external view returns (uint256 _move);

    function owner() external view returns (address _owner);
}

interface IChess {
    function mintMove(uint256 _move, uint256 _depth) external payable;

    function board() external view returns (uint256 _board);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

// import {IERC20} from 'isolmate/interfaces/tokens/IERC20.sol';

interface IPairManager {
    function mint(uint256, uint256, uint256, uint256, address) external returns (uint128);
}

interface IKeep3rHelper {
    function quote(uint256) external view returns (uint256);
}

interface IKeep3r {
    function keep3rV1() external view returns (address);

    function keep3rHelper() external view returns (address);

    function addJob(address) external;

    function isKeeper(address) external returns (bool);

    function worked(address) external;

    function bond(address, uint256) external;

    function activate(address) external;

    function liquidityAmount(address, address) external view returns (uint256);

    function jobPeriodCredits(address) external view returns (uint256);

    function addLiquidityToJob(address, address, uint256) external;

    function unbondLiquidityFromJob(address, address, uint256) external;

    function withdrawLiquidityFromJob(address, address, address) external;

    function canWithdrawAfter(address, address) external view returns (uint256);
}