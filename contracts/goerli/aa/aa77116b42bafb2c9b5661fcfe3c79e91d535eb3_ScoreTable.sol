// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { IGameRegistry } from "./interfaces/IGameRegistry.sol";
import { IGameScore } from "./interfaces/IGameScore.sol";

contract ScoreTable is IGameRegistry, IGameScore {
    // =============================================================
    //                            STORAGE
    // =============================================================

    uint256 public gameCount;

    mapping(uint256 => address) public gameOwners;
    mapping(uint256 => string) public gameNames;
    mapping(uint256 => bytes32) public gamesMetadata;
    mapping(address => mapping(uint256 => uint256)) public playerGameScores;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor() { }

    modifier onlyGameOwner(uint gameId) {
        require(msg.sender == gameOwners[gameId]);
        _;
    }

    // =============================================================
	//               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

	function registerGame(
        string calldata name, bytes32 meta
    ) external returns (uint gameId) {
        gameOwners[gameCount] = msg.sender;

        if (bytes(name).length > 0) {
            gameNames[gameCount] = name;
        }

        if (meta > 0) {
            gamesMetadata[gameCount] = meta;
        }

        gameCount++;

        return gameCount - 1;
    }

	function updateGame(
        uint gameId, bytes32 meta
    ) external onlyGameOwner(gameId) {
        if (meta == 0) {
            revert MetadataRequired();
        }

        gamesMetadata[gameCount] = meta;
    }

	function submitScore(
        uint gameId, address player, uint score
    ) external {
        revert NotImplemented();
    }

	// =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================

	function gameInfo(
        uint gameId
    ) external view returns (string memory name, bytes32 meta) {
        return (
            gameNames[gameId],
            gamesMetadata[gameId]
        );
    }

    function gameTopScore(
        uint gameId, uint offset
    ) external view returns (address player, uint score) {
        revert NotImplemented();
    }

	function playerScore(
        address player, uint gameId
    ) external view returns (uint score) {
        revert NotImplemented();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
	@title IGameRegistry
	@notice An interface for game data management.
 */
interface IGameRegistry {
	// =============================================================
	//                            EVENTS
	// =============================================================

	event RegisterGame(
		uint indexed id, 
		address indexed owner, 
		string indexed name, 
		bytes32 meta
	);

    // =============================================================
	//                            ERRORS
	// =============================================================

    error MetadataRequired();

    error NotImplemented();

	// =============================================================
	//               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

	function registerGame(string calldata name, bytes32 meta) external returns (uint gameId);
	function updateGame(uint gameId, bytes32 meta) external;

	// =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================
	
	function gameCount() external view returns (uint count);
	function gameInfo(uint gameId) external view returns (string memory name, bytes32 meta);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
	@title IGameScore
	@notice An interface for game score keeping.
 */
interface IGameScore {
	// =============================================================
	//                            EVENTS
	// =============================================================

	event RegisterPlayer(
	  	address indexed player
	);

	event SubmitScore(
		uint indexed gameId, address indexed player, uint score
	);

	// =============================================================
	//               PUBLIC / EXTERNAL WRITE FUNCTIONS
    // =============================================================

	function submitScore(uint gameId, address player, uint score) external;

	// =============================================================
    //               PUBLIC / EXTERNAL VIEW FUNCTIONS
    // =============================================================
	
	function gameTopScore(
        uint gameId, uint offset
    ) external view returns (address player, uint score);

	function playerScore(
        address player, uint gameId
    ) external view returns (uint score);
}