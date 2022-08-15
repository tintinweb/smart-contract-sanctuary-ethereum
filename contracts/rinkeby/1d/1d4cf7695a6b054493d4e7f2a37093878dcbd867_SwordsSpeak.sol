// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ISwordsSpeak} from "./interfaces/ISwordsSpeak.sol";
import {ISwordsEvent} from "./interfaces/ISwordsEvent.sol";

interface ISwordsMannys {
    function ownerOf(uint256 tokenId) external view returns (address);
}

contract SwordsSpeak is ISwordsSpeak {
    ISwordsMannys immutable SWORDS_MANNYS;
    ISwordsEvent immutable SWORDS_EVENT;

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                      INITIALIZATION                      ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */

    constructor(address swordsMannys, address swordsEvent) {
        SWORDS_MANNYS = ISwordsMannys(swordsMannys);
        SWORDS_EVENT = ISwordsEvent(swordsEvent);
    }

    /* -------------------------------------------------------------------------- */
    /* ▄▀ ▄▀ ▄▀                       BROADCASTING                       ▄▀ ▄▀ ▄▀ */
    /* -------------------------------------------------------------------------- */

    function postMessage(
        uint256 mannyId,
        Rooms room,
        string calldata message
    ) external {
        if (msg.sender != SWORDS_MANNYS.ownerOf(mannyId)) revert();

        //TODO Validate room availability

        emit Message(mannyId, room, message);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface ISwordsSpeak {
    enum Rooms {
        Square,
        TeamW,
        TeamB,
        Kings,
        Queens,
        Bishops,
        Knights,
        Rooks,
        Pawns
    }

    event Message(uint256 indexed mannyId, Rooms indexed room, string message);
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