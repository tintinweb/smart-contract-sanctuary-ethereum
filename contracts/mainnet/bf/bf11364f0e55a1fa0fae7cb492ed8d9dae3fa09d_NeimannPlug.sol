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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.4 <0.9.0;

import {IChessOlympiads} from 'interfaces/IChessOlympiads.sol';
import {IButtPlug} from 'interfaces/IGame.sol';
import {Engine} from 'fiveoutofnine/Engine.sol';
import {ERC721} from 'solmate/tokens/ERC721.sol';

contract NeimannPlug is IButtPlug {
    address constant CHESS_OLYMPIADS = 0x220d6F53444FB9205083E810344a3a3989527a34;
    uint256 immutable public BADGE_ID;

    uint256 depth = 7;
    address public owner;
    mapping(uint256 => uint256) knownMoves;

    constructor() {
        owner = msg.sender;
        BADGE_ID = _calcButtPlugBadge(address(this));
    }

    function setMove(uint256 _boardKeccak, uint256 _move) external onlyBadgeOwner {
        knownMoves[_boardKeccak] = _move;
    }

    function setMoves(uint256[] memory _boards, uint256[] memory _moves) external onlyBadgeOwner {
      for(uint256 _i; _i < _boards.length; _i++){
        knownMoves[_boards[_i]] = _moves[_i];
      }
    }

    function setDepth(uint256 _depth) external onlyBadgeOwner {
        depth = _depth;
    }

    function readMove(uint256 _board) external view returns (uint256 _move) {
        _move = knownMoves[uint256(keccak256(abi.encode(_board)))];
        if (_move == 0) (_move,) = Engine.searchMove(_board, depth);
    }

    error OnlyOwner();

    modifier onlyBadgeOwner() {
      if(msg.sender != ERC721(CHESS_OLYMPIADS).ownerOf(BADGE_ID)) revert OnlyOwner();
      _;
    }

    function _calcButtPlugBadge(address _buttPlug) internal pure returns (uint256 _badgeId) {
        return (uint256(uint160(_buttPlug)) << 96) + 2;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface IChessOlympiads {
    function mintPlayerBadge(uint256 _tokenId) external payable returns (uint256 _badgeId);
    function mintButtPlugBadge(address _buttPlug) external returns (uint256 _badgeId);
    function mintMedal(uint256[] memory _badgeIds) external returns (uint256 _badgeId);
    function withdrawRewards(uint256 _badgeId) external;
    function withdrawStakedNft(uint256 _badgeId) external;
    function startEvent() external;
    function pushLiquidity() external;
    function unbondLiquidity() external;
    function withdrawLiquidity() external;
    function updateSpotPrice() external;
    function workable() external view returns (bool _workable);
    function executeMove() external;
    function voteButtPlug(address _buttPlug, uint256 _badgeId) external;
    function voteButtPlug(address _buttPlug, uint256[] memory _badgeIds) external;
    function isWhitelistedToken(uint256 _id) external view returns (bool _isWhitelisted);
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