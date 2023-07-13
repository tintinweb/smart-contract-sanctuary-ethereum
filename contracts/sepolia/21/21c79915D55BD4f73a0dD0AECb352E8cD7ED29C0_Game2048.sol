// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

// solhint-disable not-rely-on-time
contract Game2048 {
    /// @dev Error emitted when a start index is invalid.
    error InvalidStartIndex();

    uint256 public total = 0;
    mapping(uint256 => bool) public gameEnded;
    mapping(uint256 => address) public owners;
    mapping(uint256 => uint256) public moves;
    mapping(uint256 => uint256) public maxTiles;
    mapping(uint256 => uint256[16]) internal _boards;

    event GameStarted(uint256 indexed id);
    event GameEnded(uint256 indexed id);
    event TileMoved(uint256 indexed id, uint256[16] board, bool moved);

    modifier onlyValidMove(uint256 id) {
        require(!gameEnded[id], "Game ended");
        require(owners[id] == msg.sender, "Not owner");
        _;
    }

    /// @dev Start a new game
    function start() external {
        ++total;
        uint256 id = total;
        owners[id] = msg.sender;

        // Start with 2 tiles.
        _placeRandomTile(id);
        _placeRandomTile(id);

        emit GameStarted(id);
    }

    /// @dev Move the tiles up
    function up(uint256 id) public onlyValidMove(id) {
        uint256[16] memory board = _boards[id];
        bool moved = false;

        // Go through all cells of the board from second row to the last one
        for (uint256 i = 4; i < 16; ++i) {
            // If current cell is empty (0), no need to move it, continue to next cell
            if (board[i] == 0) continue;

            // Go through all cells from start of column up to the current cell
            for (uint256 j = i % 4; j < i; j += 4) {
                // If there's an empty cell, move current value to this empty cell
                if (board[j] == 0) {
                    board[j] = board[i];
                    board[i] = 0;
                    moved = true;
                    break;
                }

                // If the current cell and checked cell have same value (and not 0)
                // and there are no cells between them or those cells are empty
                // merge these cells and put their sum into the cell closer to the start of column
                if (board[j] == board[i]) {
                    if (
                        (i - j == 4) ||
                        (i - j == 8 && board[j + 4] == 0) ||
                        (i - j == 12 && board[j + 4] == 0 && board[j + 8] == 0)
                    ) {
                        board[j] = board[i] + board[j];
                        board[i] = 0;
                        moved = true;
                        break;
                    }
                }
            }
        }

        _updateBoard(id, board, moved);
    }

    /// @dev Move the tiles down
    function down(uint256 id) public onlyValidMove(id) {
        uint256[16] memory board = _boards[id];
        bool moved = false;

        // Go through all cells of the board from the start of the last row to the first cell
        // This iteration direction is because we're moving the tiles down
        for (uint256 index = 0; index < 12; ++index) {
            uint256 i = 11 - index;

            // If current cell is empty (0), no need to move it, continue to next cell
            if (board[i] == 0) continue;

            // Go through all cells from end of the column to the current cell
            // The start position 12 + (i % 4) ensures that we start from the end of the column

            for (uint256 j = 12 + (i % 4); j > i; j -= 4) {
                // If there's an empty cell, move current value to this empty cell
                if (board[j] == 0) {
                    board[j] = board[i];
                    board[i] = 0;
                    moved = true;
                    break;
                }

                // If the current cell and checked cell have same value (and not 0)
                // and there are no cells between them or those cells are empty
                // merge these cells and put their sum into the cell closer to the end of the column
                if (board[j] == board[i]) {
                    if (
                        (j - i == 4) ||
                        (j - i == 8 && board[j - 4] == 0) ||
                        (j - i == 12 && board[j - 4] == 0 && board[j - 8] == 0)
                    ) {
                        board[j] += board[i];
                        board[i] = 0;
                        moved = true;
                        break;
                    }
                }
            }
        }

        _updateBoard(id, board, moved);
    }

    /// @dev Move the tiles left
    function left(uint256 id) public onlyValidMove(id) {
        uint256[16] memory board = _boards[id];
        bool moved = false;

        // Go through all cells of the board from the start of the second column to the last cell
        // This iteration direction is because we're moving the tiles to the left
        for (uint256 i = 1; i < 16; ++i) {
            // If current cell is empty (0), no need to move it, continue to next cell
            if (board[i] == 0) continue;

            // Go through all cells from the start of the row to the current cell
            for (uint256 j = i - (i % 4); j < i; ++j) {
                // If there's an empty cell, move current value to this empty cell
                if (board[j] == 0) {
                    board[j] = board[i];
                    board[i] = 0;
                    moved = true;
                    break;
                }

                // If the current cell and checked cell have same value (and not 0)
                // and there are no cells between them or those cells are empty
                // merge these cells and put their sum into the cell closer to the start of the row
                if (board[j] == board[i] && board[i] != 0) {
                    if (
                        (i - j == 1) ||
                        (i - j == 2 && board[j + 1] == 0) ||
                        (i - j == 3 && board[j + 1] == 0 && board[j + 2] == 0)
                    ) {
                        board[j] += board[i];
                        board[i] = 0;
                        moved = true;
                        break;
                    }
                }
            }
        }

        _updateBoard(id, board, moved);
    }

    /// @dev Move the tiles right
    function right(uint256 id) public onlyValidMove(id) {
        uint256[16] memory board = _boards[id];
        bool moved = false;

        // Go through all cells of the board from the end of the last row to the first cell
        // This iteration direction is because we're moving the tiles to the right
        for (uint256 index = 0; index < 15; ++index) {
            uint256 i = 14 - index;

            // If current cell is empty (0), no need to move it, continue to next cell
            if (board[i] == 0) continue;

            // Go through all cells from the end of the row to the current cell
            for (uint256 j = i - (i % 4) + 3; j > i; --j) {
                // If there's an empty cell, move current value to this empty cell
                if (board[j] == 0) {
                    board[j] = board[i];
                    board[i] = 0;
                    moved = true;
                    break;
                }

                // If the current cell and checked cell have same value (and not 0)
                // and there are no cells between them or those cells are empty
                // merge these cells and put their sum into the cell closer to the end of the row
                if (board[j] == board[i]) {
                    if (
                        (j - i == 1) ||
                        (j - i == 2 && board[j - 1] == 0) ||
                        (j - i == 3 && board[j - 1] == 0 && board[j - 2] == 0)
                    ) {
                        board[j] += board[i];
                        board[i] = 0;
                        moved = true;
                        break;
                    }
                }
            }
        }

        _updateBoard(id, board, moved);
    }

    /// @notice Returns a board by ID
    function getBoard(uint256 id) public view returns (uint256[16] memory) {
        return _boards[id];
    }

    /// @notice Returns max tiles of boards
    function queryMaxTiles(
        uint256 startIndex,
        uint256 querySize
    ) public view returns (uint256[] memory) {
        uint256 length = total;

        if (startIndex >= length) {
            revert InvalidStartIndex();
        }

        uint256 end = startIndex + querySize;

        if (end > length) {
            end = length;
        }

        uint256[] memory output = new uint256[](end - startIndex);

        for (uint256 i = startIndex; i < end; ) {
            output[i - startIndex] = maxTiles[i];

            unchecked {
                ++i;
            }
        }

        return output;
    }

    /// @dev Get the indices of available empty tiles
    function _updateBoard(
        uint256 id,
        uint256[16] memory board,
        bool moved
    ) internal {
        emit TileMoved(id, board, moved);

        if (_checkGameEnded(id)) {
            gameEnded[id] = true;
            emit GameEnded(id);
            return;
        }

        if (moved) {
            // Update board
            _boards[id] = board;

            // Update total move
            ++moves[id];

            // Update the max tile
            uint256 max = 0;
            for (uint256 i = 0; i < 16; ++i) {
                if (max < board[i]) {
                    max = board[i];
                }
            }
            maxTiles[id] = max;

            _placeRandomTile(id);
        }
    }

    /// @dev Check if the game has ended
    function _checkGameEnded(uint id) internal view returns (bool) {
        uint256[16] memory board = _boards[id];

        // If there are still available tiles, the game is not over
        if (_availableTileIndices(id).length != 0) return false;

        // If all tiles are filled, check if there are any possible moves left
        for (uint256 i = 0; i < 15; ++i) {
            // Check if there is a move possible horizontally (i.e., left-to-right)
            // We exclude the last column (i.e., i % 4 == 3) because there is no tile to the right of this column
            if (i % 4 < 3 && board[i] == board[i + 1]) return false;

            // Check if there is a move possible vertically (i.e., top-to-bottom)
            // We exclude the last row (i.e., i >= 12) because there is no tile below this row
            if (i < 12 && board[i] == board[i + 4]) return false;
        }

        // If there are no available tiles and no possible moves, the game is over
        return true;
    }

    /// @dev Get the indices of available empty tiles
    function _availableTileIndices(
        uint256 id
    ) internal view returns (uint256[] memory) {
        uint256 arraySize = 0;
        for (uint256 i = 0; i < 16; ++i) {
            if (_boards[id][i] == 0) {
                ++arraySize;
            }
        }
        uint256[] memory indices = new uint256[](arraySize);
        uint256 index = 0;
        for (uint256 i = 0; i < 16; ++i) {
            if (_boards[id][i] == 0) {
                indices[index] = i;
                ++index;
            }
        }

        return indices;
    }

    /// @dev Generate a random number within a range
    /// @notice This function should not be relied upon for strong cryptographic randomness.
    /// @notice It utilizes block timestamp and blockhash, which can be manipulated by miners.
    // slither-disable-next-line weak-prng,dead-code
    function _rand(uint256 modulus) internal view returns (uint256) {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    msg.sender,
                    blockhash(block.number - 1)
                )
            )
        );
        return randomNumber % modulus;
    }

    /// @dev Place a random tile on the board
    // slither-disable-next-line dead-code
    function _placeRandomTile(uint256 id) internal virtual {
        uint256[] memory indices = _availableTileIndices(id);
        require(indices.length > 0, "No available tiles");

        uint256 randIndex = _rand(indices.length);
        uint256 availableSlotIndex = indices[randIndex];

        // Set the cell at the random index to 2
        _boards[id][availableSlotIndex] = 2;
    }
}