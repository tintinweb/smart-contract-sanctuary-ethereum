// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

contract ConnectFour {
    /// @notice revert if caller isn't current team
    error NotYourTurn();
    /// @notice revert if column choice is invalid
    error InvalidSelection();
    /// @notice revert if game has been completed
    error GameOver();
    /// @notice revert season is over (coming soon)
    error SeasonOver();

    /// @notice emiited when game is created
    event GameCreated(uint gameId, address teamOne, address teamTwo);
    /// @notice emitted after turn is successfully taken
    event TurnTaken(uint indexed gameId, address team, uint8 column);
    /// @notice emitted when game is complete
    event GameFinished(uint gameId, address winner);

    /// @notice holds game data
    /// @param teamOne address of challenger
    /// @param teamTwo address of challenged
    /// @param winner address of winning team; default: address(0)
    /// @param turn current turn is calculated using bitwise for basically odd/even teamOne/teamTwo
    /// @param board holds game board data; each 'square' holds current data; 0 = no chip; 1 = team one; 2 = team two
    struct Game {
        address teamOne;
        address teamTwo;
        address winner;
        uint8 turn;
        uint8[6][6] board;
    }

    /// @notice Used as a counter for the next game index.
    /// @dev Initialised at 1 because it makes the first transaction slightly cheaper.
    uint public gameId;

    /// @notice An indexed list of games
    /// @dev This automatically generates a getter for us, which will return `Game.player1`, `Game.player2`, `Game.moves`, and `Game.finished` (the arrays are skipped)
    mapping(uint => Game) public getGame;

    /// @notice prevent move if column is invalid
    modifier validColumn(uint8 column) {
        if (column > 5) revert InvalidSelection();
        _;
    }

    /// @notice prevents gameplay if game is over
    modifier gameOver(uint _gameId) {
        if (getGame[_gameId].winner != address(0)) revert GameOver();
        _;
    }

    /// @notice prevents new games when season is over. (coming soon)
    modifier seasonOver() {
        _;
    }

    /// @notice prevents teams being the same address
    modifier uniqueTeams(address opponent) {
        require(msg.sender != opponent);
        _;
    }

    /**
     * @notice challenge an address to a game of connect four
     * @param opponent challened
     * @dev opponent will go first
     * @dev game id is increated each time a new game is created
     * @dev season is over when timer (soon to be added) is past
     */
    function challenge(address opponent) public uniqueTeams(opponent) {
        uint8[6][6] memory newBoard;
        Game memory newGame = Game({
            teamOne: msg.sender,
            teamTwo: opponent,
            turn: uint8(0),
            winner: address(0),
            board: newBoard
        });
        getGame[gameId] = newGame;

        emit GameCreated(gameId, msg.sender, opponent);

        gameId++;
    }

    /**
     * @notice current team plays a turn
     * @param _gameId id of game
     * @param column selected column for move
     */
    function makeMove(
        uint8 _gameId,
        uint8 column
    ) external gameOver(_gameId) validColumn(column) {
        Game storage game = getGame[_gameId];

        /// @notice row where chip will land
        uint8 row;
        /// @notice assigned team number for squares
        uint8 teamNum = game.turn & 1 == 0 ? 2 : 1;

        /// @notice prevents plays being made by other addresses
        /// @dev even or odd bitwise operator decides turn
        /// @dev starts with team two
        if (msg.sender != (game.turn & 1 == 0 ? game.teamTwo : game.teamOne)) {
            revert NotYourTurn();
        }

        /// @notice finds where chip will land
        for (uint8 i = 0; i < 7; i++) {
            if (i > 5) {
                revert InvalidSelection();
            }
            uint8 square = game.board[i][column];
            if (square == 0) {
                row = i++;
                break;
            }
        }

        /// @notice assigns chip to location onboard
        game.board[row][column] = teamNum;
        /// @notice increments turn
        game.turn++;

        emit TurnTaken(_gameId, msg.sender, column);

        /// @notice checks surrounding squares for connected pieces
        if (didPlayerWin(_gameId, column, row, teamNum)) {
            game.winner = msg.sender;
            emit GameFinished(_gameId, msg.sender);
        }
    }

    /// @notice checks square for team's chip
    /// @param _gameId id of game
    /// @param firstIndex column selected for new chip
    /// @param secondIndex row where new chip lands
    /// @param teamNum number assigned to team
    function checkSquare(
        uint8 _gameId,
        uint8 firstIndex,
        uint8 secondIndex,
        uint8 teamNum
    ) private view returns (bool) {
        uint8[6][6] storage board = getGame[_gameId].board;
        return board[firstIndex][secondIndex] == teamNum;
    }

    /// @notice checks the horizontal win
    /// @param _gameId id of game
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkHorizonalWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint) {
        uint connectedPiecesCount = 1;

        /// @dev checks to the right of new piece
        for (uint8 i = column + 1; i < 6 - column; i++) {
            if (checkSquare(_gameId, row, i, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }
        /// @dev checks to the left of new piece
        if (column != 0) {
            uint8 columnIndex = column - 1;
            while (columnIndex >= 0) {
                if (checkSquare(_gameId, row, columnIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (columnIndex == 0) {
                    break;
                } else {
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the veritical win
    /// @param _gameId id of game
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkVericalWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint) {
        uint connectedPiecesCount = 1;

        /// @dev checks rows above new piece
        for (uint8 i = row + 1; i < 6 - row; i++) {
            if (checkSquare(_gameId, i, column, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }
        /// @dev checks rows below new piece
        if (row != 0) {
            uint8 rowIndex = row - 1;
            while (rowIndex >= 0) {
                if (checkSquare(_gameId, rowIndex, column, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0) {
                    break;
                } else {
                    rowIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the forward angle win
    /// @param _gameId id of game
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkForwardAngleWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint) {
        uint connectedPiecesCount = 1;

        /// @dev checks forward angle up
        for (uint8 i = row + 1; i < 6 - row; i++) {
            if (checkSquare(_gameId, i, i, teamNum)) {
                connectedPiecesCount++;
            } else {
                break;
            }
        }

        /// @dev checks forward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row - 1;
            uint8 columnIndex = column - 1;
            while (rowIndex >= 0 && columnIndex >= 0) {
                if (checkSquare(_gameId, rowIndex, columnIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0 || columnIndex == 0) {
                    break;
                } else {
                    rowIndex--;
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks the backward angle win
    /// @param _gameId id of game
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function checkBackwardAngleWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (uint) {
        uint connectedPiecesCount = 1;

        /// @dev checks backward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row - 1;
            uint8 columnIndex = column + 1;
            while (rowIndex >= 0 && columnIndex < 6) {
                if (checkSquare(_gameId, rowIndex, columnIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex == 0 || columnIndex >= 6) {
                    break;
                } else {
                    rowIndex--;
                    columnIndex++;
                }
            }
        }

        /// @dev checks forward angle down
        if (row != 0 && column != 0) {
            uint8 rowIndex = row + 1;
            uint8 columnIndex = column - 1;
            while (rowIndex < 6 && columnIndex >= 0) {
                if (checkSquare(_gameId, rowIndex, columnIndex, teamNum)) {
                    connectedPiecesCount++;
                } else {
                    break;
                }
                if (rowIndex >= 6 || columnIndex == 0) {
                    break;
                } else {
                    rowIndex++;
                    columnIndex--;
                }
            }
        }
        return connectedPiecesCount;
    }

    /// @notice checks to see if current play won the game
    /// @param _gameId id of game
    /// @param column column selected for new chip
    /// @param row row where new chip lands
    /// @param teamNum number assigned to team
    function didPlayerWin(
        uint8 _gameId,
        uint8 column,
        uint8 row,
        uint8 teamNum
    ) private view returns (bool) {
        /// @dev using new chip location as middle == m
        /// @dev [ [ C+1 | R-1 ] [  C+1  ] [ C+1 | R+1 ] ]
        /// @dev [ [    R-1    ] [ C | R ] [    R+1    ]
        /// @dev [ [ C-1 | R-1 ] [  C-1  ] [ C-1 | R+1 ] ]

        uint horionalCount = checkHorizonalWin(_gameId, column, row, teamNum);
        if (horionalCount == 4) {
            return true;
        }
        uint vericalCount = checkVericalWin(_gameId, column, row, teamNum);
        if (vericalCount == 4) {
            return true;
        }
        uint forwardAngleCount = checkForwardAngleWin(
            _gameId,
            column,
            row,
            teamNum
        );
        if (forwardAngleCount == 4) {
            return true;
        }
        uint backwardAngleCount = checkBackwardAngleWin(
            _gameId,
            column,
            row,
            teamNum
        );
        if (backwardAngleCount == 4) {
            return true;
        }
        return false;
    }

    function getGameBoard(
        uint8 _gameId
    ) public view returns (uint8[6][6] memory) {
        return getGame[_gameId].board;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./ConnectFour.sol";

contract ConnectFourFactory {
    event NewConnectFourSeasonCreated(uint8 seasonId, address gameAddress);

    uint8 private seasonId;
    address private connectFourImplAddr;

    // gameId -> contract implementation
    mapping(uint8 => ConnectFour) public connectFourGames;

    function deployNewSeason() public returns (uint8) {
        ConnectFour newGame = ConnectFour(Clones.clone(connectFourImplAddr));
        connectFourGames[seasonId] = newGame;

        emit NewConnectFourSeasonCreated(seasonId, address(newGame));

        return seasonId++;
    }

    constructor(address implAddress) {
        connectFourImplAddr = implAddress;
    }

    function getGames() public view returns (ConnectFour[] memory) {
        ConnectFour[] memory games = new ConnectFour[](seasonId);
        for (uint8 i = 0; i < seasonId; i++) {
            games[i] = connectFourGames[i];
        }
        return games;
    }
}