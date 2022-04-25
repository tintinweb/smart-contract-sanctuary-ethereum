// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "../../domain/FismoStore.sol";
import "../../domain/FismoConstants.sol";

/**
 * @notice KeyToken is the Fismo ERC-20, which we only check for a balance of
 */
interface KeyToken {
    function balanceOf(address account) external view returns (uint256);
}

/**
 * @notice Lockable Door Guard Logic
 *
 * - Machine: LockableDoor
 * - Init: Validate and store key token address
 * - States guarded: Locked
 * - Transition Guards: Exit
 * - Action Filter: Suppress 'Unlock' action if user doesn't have key
 */
contract LockableDoorGuards is FismoConstants {

    // -------------------------------------------------------------------------
    // MACHINE STORAGE
    // -------------------------------------------------------------------------

    // Unique storage slot id
    bytes32 internal constant LOCKABLE_DOOR_SLOT = keccak256("LockableDoor.Storage");

    // Storage slot structure
    struct LockableDoorSlot {

        // Address of the key contract
        KeyToken keyToken;

    }

    // Getter for the storage slot
    function lockableDoorSlot() internal pure returns (LockableDoorSlot storage lds) {
        bytes32 position = LOCKABLE_DOOR_SLOT;
        assembly {
            lds.slot := position
        }
    }

    // -------------------------------------------------------------------------
    // MACHINE INITIALIZER
    // -------------------------------------------------------------------------

    /**
     * @notice Machine Initializer
     *
     * @param _keyToken - The token contract where a non-zero balance represents a key
     */
    function initialize(address _keyToken)
    external
    {
        // Make sure _keyToken isn't the zero address
        // Note: specifically testing a revert with no reason here
        require(_keyToken != address(0));

        // Make sure _keyToken address has code
        // Note: specifically testing a revert with a reason here
        requireContractCode(_keyToken, CODELESS_INITIALIZER);

        // Initialize market config params
        lockableDoorSlot().keyToken = KeyToken(_keyToken);
    }

    // -------------------------------------------------------------------------
    // ACTION FILTER
    // -------------------------------------------------------------------------

    // Filter actions contextually
    function LockableDoor_Locked_Filter(address _user, string calldata _action)
    external
    view
    returns(bool suppress)
    {
        // User must have key to unlock door
        bool hasKey = isKeyHolder(_user);

        // For unlock action only, suppress if user does not have key
        suppress = (
            keccak256(abi.encodePacked(_action)) ==
            keccak256(abi.encodePacked("Unlock"))
        ) ? !(hasKey) : false;
    }

    // -------------------------------------------------------------------------
    // TRANSITION GUARDS
    // -------------------------------------------------------------------------

    // Locked / Exit
    // Valid next states: Closed
    function LockableDoor_Locked_Exit(address _user, string calldata _action, string calldata _nextStateName)
    external
    view
    returns(string memory)
    {
        // Make sure _user isn't the owner address
        // Note: specifically testing a revert with no reason here
        require(_user != FismoStore.getStore().owner);

        // User must have key to unlock door
        bool hasKey = isKeyHolder(_user);
        require(hasKey);

        // Success response message
        return "Door unlocked.";

    }

    // -------------------------------------------------------------------------
    // HELPERS
    // -------------------------------------------------------------------------

    /**
     * @notice Determine if user holds the key
     *
     * @param _user - the user to check
     *
     * @return true if the user holds a balance of the key token
     */
    function isKeyHolder(address _user)
    internal
    view
    returns (bool)
    {
        return lockableDoorSlot().keyToken.balanceOf(_user) > 0;
    }

    /**
     * @notice Verify an address is a contract and not an EOA
     *
     * Reverts if address has no contract code
     *
     * @param _contract - the contract to check
     * @param _errorMessage - the revert reason to throw
     */
    function requireContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "./FismoTypes.sol";

/**
 * @title FismoStore
 *
 * @notice Fismo storage slot configuration and accessor
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
library FismoStore {

    bytes32 internal constant FISMO_SLOT = keccak256("fismo.storage.slot");

    struct FismoSlot {

        // Is this the original Fismo contract or a clone?
        bool isFismo;

        // Address of the contract owner
        address owner;

        // Maps machine id to a machine struct
        //      machine id => Machine struct
        mapping(bytes4 => FismoTypes.Machine) machine;

        // Maps a machine id to a mapping of a state id to the index of that state in the machine's states array
        //  machine id =>     ( state id => state index )
        mapping(bytes4 => mapping(bytes4 => uint256)) stateIndex;

        // Maps a user's address to a mapping of a machine id to the user's current state in that machine
        //  user wallet =>   ( machine id => current state id )
        mapping(address => mapping(bytes4 => bytes4)) userState;

        // Maps a user's address to a an array of Position structs, accumulated over time
        //  user wallet => array of Positions
        mapping(address => FismoTypes.Position[]) userHistory;

    }

    /**
     * @notice Get the Fismo storage slot
     *
     * @return fismoStore - Fismo storage slot
     */
    function getStore()
    internal
    pure
    returns (FismoSlot storage fismoStore)
    {
        bytes32 position = FISMO_SLOT;
        assembly {
            fismoStore.slot := position
        }
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title FismoConstants
 *
 * @notice Constants used by the Fismo protocol
 */
contract FismoConstants {

    // Revert Reasons
    string internal constant MULTIPLICITY = "Can't clone a clone";

    string internal constant ALREADY_INITIALIZED = "Already initialized";

    string internal constant ONLY_OWNER = "Only owner may call";
    string internal constant ONLY_OPERATOR = "Only operator may call";

    string internal constant MACHINE_EXISTS = "Machine already exists";
    string internal constant STATE_EXISTS = "State already exists";

    string internal constant NO_SUCH_GUARD = "No such guard";
    string internal constant NO_SUCH_MACHINE = "No such machine";
    string internal constant NO_SUCH_STATE = "No such state";
    string internal constant NO_SUCH_ACTION = "No such action";

    string internal constant INVALID_ADDRESS = "Invalid address";
    string internal constant INVALID_OPERATOR_ADDR = "Invalid operator address";
    string internal constant INVALID_MACHINE_ID = "Invalid machine id";
    string internal constant INVALID_STATE_ID = "Invalid state id";
    string internal constant INVALID_ACTION_ID = "Invalid action id";
    string internal constant INVALID_TARGET_ID = "Invalid target state id";

    string internal constant CODELESS_INITIALIZER = "Initializer address not a contract";
    string internal constant INITIALIZER_REVERTED = "Initializer function reverted, no reason given";
    string internal constant CODELESS_GUARD = "Guard address not a contract";
    string internal constant GUARD_REVERTED = "Guard function reverted, no reason given";

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/**
 * @title FismoTypes
 *
 * @notice Enums and structs used by Fismo
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoTypes {

    enum Guard {
        Enter,
        Exit,
        Filter
    }

    struct Machine {
        address operator;         // address of approved operator (can be contract or EOA)
        bytes4 id;                // keccak256 hash of machine name
        bytes4 initialStateId;    // keccak256 hash of initial state
        string name;              // name of machine
        string uri;               // off-chain URI of metadata describing the machine
        State[] states;           // all of the valid states for this machine
    }

    struct State {
        bytes4 id;                // keccak256 hash of state name
        string name;              // name of state. begin with letter, no spaces, a-z, A-Z, 0-9, and _
        bool exitGuarded;         // is there an exit guard?
        bool enterGuarded;        // is there an enter guard?
        address guardLogic;       // address of guard logic contract
        Transition[] transitions; // all of the valid transitions from this state
    }

    struct Position {
        bytes4 machineId;         // keccak256 hash of machine name
        bytes4 stateId;           // keccak256 hash of state name
    }

    struct Transition {
        bytes4 actionId;          // keccak256 hash of action name
        bytes4 targetStateId;     // keccak256 hash of target state name
        string action;            // Action name. no spaces, only a-z, A-Z, 0-9, and _
        string targetStateName;   // Target State name. begin with letter, no spaces, a-z, A-Z, 0-9, and _
    }

    struct ActionResponse {
        string machineName;        // name of machine
        string action;             // name of action that triggered the transition
        string priorStateName;     // name of prior state
        string nextStateName;      // name of new state
        string exitMessage;        // response from the prior state's exit guard
        string enterMessage;       // response from the new state's enter guard
    }

}