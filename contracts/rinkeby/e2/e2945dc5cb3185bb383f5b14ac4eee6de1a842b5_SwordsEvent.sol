// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {ISwordsEvent} from "./interfaces/ISwordsEvent.sol";
import {ISwordsPlayers} from "./interfaces/ISwordsPlayers.sol";
import {RandomLibrary} from "./RandomLibrary.sol";

contract SwordsEvent is ISwordsEvent, Ownable {
    ISwordsPlayers SWORDS_PLAYERS;

    uint8[16] private INIT_ROLES = [
        1,
        2,
        3,
        4,
        5,
        3,
        2,
        1,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0
    ];

    uint8[32] private INIT_POSITIONS = [
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
        57,
        58,
        59,
        60,
        61,
        62,
        63,
        64,
        49,
        50,
        51,
        52,
        53,
        54,
        55,
        56
    ];

    EventState private state;

    mapping(uint256 => Player) public players;

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                         MODIFIERS                        ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */
    modifier ifActivePhase(Phase _phase) {
        if (state.phase != _phase) revert();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                     PHASE MANAGEMENT                     ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */
    function phase() public view returns (Phase) {
        return state.phase;
    }

    function startEvent() external onlyOwner {
        state.phase = Phase.EventStarted;
        state.turn = Team.Day;

        emit PhaseChanged(Phase.EventStarted);
        emit TurnChanged(Team.Day);
    }

    function setPhase(Phase newPhase) external onlyOwner {
        if (newPhase <= state.phase) revert();

        state.phase = newPhase;
        emit PhaseChanged(newPhase);
    }

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                     STARTING PLAYERS                     ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */

    /// @param playerIds An array where the first 16 playerIds represent the Night team, and last 16 the Day Team, in RKBQKBKRPPPPPPPP order.
    function setTeams(uint256[] calldata playerIds)
        external
        onlyOwner
        ifActivePhase(ISwordsEvent.Phase.VotingClosed)
    {
        if (playerIds.length != 32) revert();

        for (uint256 i; i < playerIds.length; i++) {
            uint256 playerId = playerIds[i];
            players[playerId] = Player({
                active: true,
                team: i < 16 ? Team.Night : Team.Day,
                position: INIT_POSITIONS[i],
                role: ISwordsEvent.Role(INIT_ROLES[i % 16]),
                captures: 0
            });

            emit PlayerAdded(
                playerId,
                players[playerId].team,
                players[playerId].role,
                players[playerId].position
            );
        }
    }

    /* -------------------------------------------------------------------------- */
    /*                                    VOTES                          ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */

    function turn() public view returns (Team) {
        return
            state.phase < Phase.EventStarted
                ? Team.None
                : state.halfTurns % 2 == 0
                ? Team.Day
                : Team.Night;
    }

    function canVote(address addr) external view returns (bool) {
        uint256 playerId = SWORDS_PLAYERS.registry(addr);
        if (playerId == 0) revert();

        return players[playerId].active && state.turn == players[playerId].team;
    }

    function vote(bytes4 move, bytes32 signature) external {
        uint256 playerId = SWORDS_PLAYERS.registry(msg.sender);
        if (playerId == 0) revert();
        if (!players[playerId].active) revert();

        emit PlayerVoted(playerId, move, signature);
    }

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                           MOVES                          ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */
    function registerMove(
        uint256 playerId,
        uint8 from,
        uint8 to
    ) public onlyOwner {
        emit MoveMade(playerId, from, to);

        state.halfTurns++;
        emit TurnChanged(state.halfTurns % 2 == 0 ? Team.Day : Team.Night);
    }

    function registerMoveWithCapture(
        uint256 playerId,
        uint8 from,
        uint8 to,
        uint256 capturedplayerId,
        uint8 capturedMannyPosition
    ) external onlyOwner {
        registerMove(playerId, from, to);

        unchecked {
            players[playerId].captures++;
        }

        players[capturedplayerId].active = false;

        SWORDS_PLAYERS.burnAndDropLoot(
            capturedplayerId,
            capturedMannyPosition,
            playerId
        );

        emit PlayerEliminated(
            capturedplayerId,
            capturedMannyPosition,
            playerId
        );
    }

    function endGame() external onlyOwner {
        state.phase = Phase.EventCompleted;
        state.turn = Team.None;

        emit TurnChanged(Team.None);
    }

    /// @dev This is used in instances of castling.
    function setPosition(uint256 playerId, uint8 position) external onlyOwner {
        players[playerId].position = position;
    }

    /// @dev This is used in instances of pawn promotion.
    function promote(uint256 playerId, Role role) external onlyOwner {
        if (players[playerId].role != Role.Pawn) revert();
        if (players[playerId].position > 8 && players[playerId].position < 56)
            revert();
        if (role == Role.Pawn || role == Role.King) revert();

        players[playerId].role = role;

        emit PlayerRoleChanged(playerId, role);
    }

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                          CONFIG                          ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */
    function setSwordsPlayersAddress(address swordsPlayers) external onlyOwner {
        SWORDS_PLAYERS = ISwordsPlayers(swordsPlayers);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISwordsEvent {
    enum Phase {
        Init,
        SubmissionsOpen,
        VotingOpen,
        VotingClosed,
        RolesAssigned,
        EventStarted,
        EventCompleted
    }

    enum Role {
        Pawn,
        Rook,
        Knight,
        Bishop,
        Queen,
        King
    }

    enum Team {
        None,
        Day,
        Night
    }

    enum GameState {
        Active,
        Checkmate,
        Stalemate,
        Draw
    }

    struct Player {
        bool active;
        Team team;
        uint8 position;
        Role role;
        uint8 captures;
    }

    struct EventState {
        Phase phase;
        GameState gameState;
        Team turn;
        uint16 halfTurns;
    }

    event PhaseChanged(ISwordsEvent.Phase indexed phase);

    event MoveMade(
        uint256 indexed playerId,
        uint8 fromPosition,
        uint8 toPosition
    );
    event TurnChanged(Team turn);

    event PlayerAdded(
        uint256 indexed playerId,
        Team team,
        Role role,
        uint8 position
    );
    event PlayerRoleChanged(uint256 indexed playerId, Role role);

    event PlayerVoted(
        uint256 indexed playerId,
        bytes4 indexed move,
        bytes32 indexed signature
    );

    event PlayerEliminated(
        uint256 indexed playerId,
        uint8 position,
        uint256 indexed byPlayerId
    );

    function phase() external view returns (Phase phase);

    function setSwordsPlayersAddress(address swordsPlayers) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISwordsPlayers {
    struct Player {
        bool team;
        bool submitted;
        uint16 votes;
        uint16 lootId;
        address accessoryContract;
        uint256 accessoryTokenId;
    }

    event PlayerAdded(address indexed player, uint256 indexed playerId);
    event SwordAdded(uint256 indexed playerId, uint256 indexed lootId);
    event AccessoryAdded(
        uint256 indexed playerId,
        address indexed accessoryContract,
        uint256 indexed accessoryTokenId
    );
    event PlayerSubmitted(uint256 indexed playerId, bytes data);

    error OnePlayerPerAddress();
    error CantReceiveThisToken();
    error CantRecieveMultiple1155Tokens();

    function registry(address addr) external view returns (uint256);

    function voteForPlayer(uint256 playerId) external;

    function burnAndDropLoot(
        uint256 playerId,
        uint256 positionId,
        uint256 capturerPlayerId
    ) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library RandomLibrary {
    function getRandomNumber(uint256 max) internal view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    max,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % max;
    }

    function getRandomFromArray(uint256[] memory array)
        internal
        view
        returns (uint256)
    {
        return array[getRandomNumber(array.length)];
    }

    function shuffle(uint256[] memory array)
        external
        view
        returns (uint256[] memory)
    {
        for (uint256 i; i < array.length; i++) {
            uint256 n = i + getRandomNumber(array.length - i);
            uint256 tmp = array[n];
            array[n] = array[i];
            array[i] = tmp;
        }
        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}