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

/**
 * @title onchain battleship
 * @author @Da-Colon (github)
 */
contract Battleship {
    event TeamReady(address team);
    event TurnFinished(address team, bytes4 target, bool isSuccessful);
    event GameFinished(address winner);

    address public game_winner = address(0);
    address public teamOne = address(0);
    address public teamTwo = address(0);
    address public currentTurn = address(0);

    mapping(address => bool) private teamReady;
    mapping(address => mapping(bytes4 => uint8)) private locations;
    mapping(address => TeamHits) private teamHits;

    struct TeamHits {
        uint8 hitCount;
        mapping(bytes4 => uint8) targeted;
    }

    modifier piecesSet(bool isReady) {
        require(teamReady[msg.sender] == isReady, "Pieces Set");
        _;
    }

    modifier gameOver() {
        require(game_winner == address(0), "Game is Over");
        _;
    }

    modifier checkTurn() {
        if ((currentTurn == address(0) && msg.sender == teamTwo)) {
            _;
            return;
        }
        require(currentTurn == msg.sender, "Not your turn");
        _;
    }

    function checkAndSetPieces(
        bytes4[15] memory targets,
        address team
    ) private {
        for (uint256 i; i < targets.length; i++) {
            locations[team][targets[i]] = 1;
        }
        teamReady[team] = true;
        emit TeamReady(team);
    }

    function setTeamOnePieces(
        bytes4[15] memory targets
    ) external piecesSet(false) {
        require(msg.sender == teamOne, "Team One Only");
        checkAndSetPieces(targets, msg.sender);
    }

    function setTeamTwoPieces(
        bytes4[15] memory targets
    ) external piecesSet(false) {
        require(msg.sender == teamTwo, "Team Two Only");
        checkAndSetPieces(targets, msg.sender);
    }

    function targetSpot(bytes4 target, address defTeam) private gameOver {
        if (
            locations[defTeam][target] == 1 &&
            teamHits[msg.sender].targeted[target] == 0
        ) {
            uint8 raisedHit = ++teamHits[msg.sender].hitCount;
            teamHits[msg.sender].hitCount = raisedHit;
            teamHits[msg.sender].targeted[target] = 1;
            if (raisedHit == 15) {
                game_winner = msg.sender;
                emit GameFinished(msg.sender);
            } else {
                emit TurnFinished(msg.sender, target, true);
            }
        } else {
            emit TurnFinished(msg.sender, target, false);
        }

        currentTurn = defTeam;
    }

    function takeTurn(bytes4 target) external piecesSet(true) checkTurn {
        if (msg.sender == teamOne) {
            targetSpot(target, teamTwo);
        } else {
            targetSpot(target, teamOne);
        }
    }

    function init(address _teamOne, address _teamTwo) public {
        teamOne = _teamOne;
        teamTwo = _teamTwo;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Battleship.sol";

contract BattleshipFactory {
    event GameCreated(address gameAddress, address teamOne, address teamTwo);

    uint private gameId;
    address private BattleshipAddr;

    // gameId -> contract implementation
    mapping(uint => Battleship) BattleshipGames;

    modifier uniqueTeams(address teamTwo) {
        require(msg.sender != teamTwo);
        _;
    }

    function deployAndChallange(address teamTwo) external uniqueTeams(teamTwo) {
        Battleship newGame = Battleship(
            Clones.clone(BattleshipAddr)
        );
        newGame.init(msg.sender, teamTwo);
        BattleshipGames[gameId] = newGame;
        gameId = ++gameId;
        emit GameCreated(address(newGame), msg.sender, teamTwo);
    }

    constructor(address implAddress) {
        BattleshipAddr = implAddress;
    }

    function getGames() public view returns (Battleship[] memory) {
        Battleship[] memory games = new Battleship[](gameId);
        for (uint i = 0; i < gameId; i++) {
            games[i] = BattleshipGames[i];
        }
        return games;
    }
}