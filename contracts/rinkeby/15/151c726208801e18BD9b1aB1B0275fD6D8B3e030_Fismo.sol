// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoClone } from  "./components/FismoClone.sol";

/**
 * @title Fismo - Finite State Machines with a twist
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract Fismo is FismoClone {

    /**
     * @notice Constructor
     *
     * Note:
     * - Deployer becomes owner
     * - Only executed in an actual contract deployment
     * - Clones have their init() method called to do same
     */
    constructor() payable {
        setOwner(msg.sender);
        setIsFismo(true);
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoStore } from "../domain/FismoStore.sol";

import { IFismoClone } from "../interfaces/IFismoClone.sol";

import { FismoOperate } from "./FismoOperate.sol";

/**
 * @title FismoClone
 *
 * Create and initialize a Fismo clone
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoClone is IFismoClone, FismoOperate  {

    /**
     * @notice Initialize a cloned Fismo instance.
     *
     * Reverts if:
     * - Owner is not zero address
     *
     * Note:
     * - Must be external to be called from the Fismo factory.
     *
     * @param _owner - the owner of the cloned Fismo instance
     */
    function init(address _owner)
    external
    override
    {
        address owner = getStore().owner;
        require(owner == address(0), ALREADY_INITIALIZED);
        setOwner(_owner);
        setIsFismo(false);
    }

    /**
     * @notice Deploys and returns the address of a Fismo clone.
     *
     * Emits:
     * - FismoCloned
     *
     * @return instance - the address of the Fismo clone instance
     */
    function cloneFismo()
    external
    override
    returns (address instance)
    {
        // Make sure this isn't a clone
        require(getStore().isFismo, MULTIPLICITY);

        // Clone the contract
        instance = clone();

        // Initialize the clone
        IFismoClone(instance).init(msg.sender);

        // Notify watchers of state change
        emit FismoCloned(msg.sender, instance);
    }

    /**
     * @dev Deploys and returns the address of a Fismo clone
     *
     * Note:
     * - This function uses the create opcode, which should never revert.
     *
     * @return instance - the address of the Fismo clone
     */
    function clone()
    internal
    returns (address instance) {

        // Clone this contract
        address implementation = address(this);

        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "../domain/FismoTypes.sol";

/**
 * @title IFismoClone
 *
 * @notice Create and initialize a Fismo clone
 * The ERC-165 identifier for this interface is 0x08a9f5ec
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoClone {

    /// Emitted when a user clones the Fismo contract
    event FismoCloned(
        address indexed owner,
        address indexed instance
    );

    /**
     * @notice Initialize this Fismo instance.
     *
     * Reverts if:
     * - Owner is not zero address
     *
     * Note:
     * Must be external to be called from the Fismo factory.
     *
     * @param _owner - the owner of the cloned Fismo instance
     */
    function init(address _owner) external;


    /**
     * @notice Deploys and returns the address of a Fismo clone.
     *
     * Emits:
     * - FismoCloned
     *
     * @return instance - the address of the Fismo clone instance
     */
    function cloneFismo() external returns (address instance);

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoSupport } from "./FismoSupport.sol";
import { IFismoOperate } from "../interfaces/IFismoOperate.sol";

/**
 * @title FismoOperate
 *
 * Operate Fismo state machines
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoOperate is IFismoOperate, FismoSupport  {

    /**
     * @notice Modifier to only allow a method to be called by a machine's operator
     */
    modifier onlyOperator(bytes4 _machineId) {
        Machine storage machine = getMachine(_machineId);
        require(msg.sender == machine.operator, ONLY_OPERATOR);
        _;
    }

    /**
     * Invoke an action on a configured Machine.
     *
     * Emits:
     * - UserTransitioned
     *
     * Reverts if:
     * - Caller is not the machine's operator
     * - Machine does not exist
     * - Action is not valid for the user's current State in the given Machine
     * - any invoked Guard logic reverts
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the target machine
     * @param _actionId - the id of the action to invoke
     *
     * @return response - the response from the action. See {FismoTypes.ActionResponse}
        */
    function invokeAction(
        address _user,
        bytes4 _machineId,
        bytes4 _actionId
    )
    external
    override
    onlyOperator(_machineId)
    returns(ActionResponse memory response)
    {
        // Get the machine
        Machine storage machine = getMachine(_machineId);

        // Get the user's current state in the given machine
        bytes4 currentStateId = getUserStateId(_user, _machineId);

        // Get the state
        State storage state = getState(_machineId, currentStateId, true);

        // Find the transition triggered by the given action
        bool found = false;
        Transition memory transition;
        for (uint256 i = 0; i < state.transitions.length; i++) {

            // We found it...
            if (state.transitions[i].actionId == _actionId) {
                found = true;
                transition = state.transitions[i];
                break;
            }

        }

        // Determine if action is suppressed
        bool suppressed =
            !found || (                                      // invalid action
                (state.exitGuarded || state.enterGuarded) && // state is guarded and thus may filter
                isActionSuppressed(_user, state.guardLogic, machine.name, state.name, transition.action)
            );

        // Make sure transition was found and not suppressed
        require(!suppressed, NO_SUCH_ACTION);

        // Get the next state
        State storage nextState = getState(_machineId, transition.targetStateId, true);

        // Create the action response
        response.machineName = machine.name;
        response.action = transition.action;
        response.priorStateName = state.name;
        response.nextStateName = nextState.name;

        // if there is exit guard logic for the current state, call it
        if (state.exitGuarded) {
            response.exitMessage = invokeGuard(_user, state.guardLogic, machine.name, state.name, transition.action, Guard.Exit);
        }

        // if there is enter guard logic for the next state, call it
        if (nextState.enterGuarded) {
            response.enterMessage = invokeGuard(_user, nextState.guardLogic, machine.name, nextState.name, transition.action, Guard.Enter);
        }

        // if we made it this far, set the new state
        setUserState(_user, _machineId, nextState.id);

        // Alert listeners to change of state
        emit UserTransitioned(_user, _machineId, nextState.id, response);

    }

    /**
     * @notice Make a delegatecall to the specified guard function
     *
     * Reverts if:
     * - guard logic implementation is not defined
     * - guard logic reverts
     * - delegatecall attempt fails for any other reason
     *
     * @param _user - the user address the call is being invoked for
     * @param _guardLogic - the address of the guard logic contract
     * @param _machineName - the name of the machine
     * @param _action - the name of the state
     * @param _targetStateName - the name of the target state
     * @param _guard - the guard type (enter/exit) See: {FismoTypes.Guard}
     *
     * @return guardResponse - the message (if any) returned from the guard
     */
    function invokeGuard(
        address _user,
        address _guardLogic,
        string memory _machineName,
        string memory _targetStateName,
        string memory _action,
        Guard _guard
    )
    internal
    returns (string memory guardResponse)
    {
        // Get the function selector and encode the call
        bytes4 selector = getGuardSelector(_machineName, _targetStateName, _guard);
        bytes memory guardCall = abi.encodeWithSelector(
            selector,
            _user,
            _action,
            _targetStateName
        );

        // Invoke the guard
        (bool success, bytes memory response) = _guardLogic.delegatecall(guardCall);

        // if the function call reverted
        if (success == false) {
            // if there is a return reason string
            if (response.length > 0) {
                // bubble up any reason for revert
                assembly {
                    let response_size := mload(response)
                    revert(add(32, response), response_size)
                }
            } else {
                revert(GUARD_REVERTED);
            }
        }

        // Decode the response message
        (guardResponse) = abi.decode(response, (string));

        // Revert with guard message as reason if invocation not successful
        require(success, guardResponse);

    }

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

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoStore } from "../domain/FismoStore.sol";
import { FismoTypes } from "../domain/FismoTypes.sol";

import { IFismoClone } from "../interfaces/IFismoClone.sol";
import { IFismoOperate } from "../interfaces/IFismoOperate.sol";
import { IFismoOwner } from "../interfaces/IFismoOwner.sol";
import { IFismoSupport } from "../interfaces/IFismoSupport.sol";
import { IFismoUpdate } from "../interfaces/IFismoUpdate.sol";
import { IFismoView } from "../interfaces/IFismoView.sol";

import { FismoUpdate } from "./FismoUpdate.sol";

/**
 * @title FismoSupport
 *
 * @notice ERC-165 interface detection standard
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoSupport is IFismoSupport, FismoUpdate {

    /**
     * @notice Onboard implementation of ERC-165 interface detection standard.
     *
     * @param _interfaceId - the sighash of the given interface
     *
     * @return true if _interfaceId is supported
     */
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    override
    returns (bool)
    {
        return (
        (_interfaceId == type(IFismoClone).interfaceId && getStore().isFismo) ||
        _interfaceId == type(IFismoOperate).interfaceId ||
        _interfaceId == type(IFismoOwner).interfaceId ||
        _interfaceId == type(IFismoSupport).interfaceId ||
        _interfaceId == type(IFismoUpdate).interfaceId ||
        _interfaceId == type(IFismoView).interfaceId
        ) ;
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "../domain/FismoTypes.sol";

/**
 * @title FismoOperate
 *
 * @notice Operate Fismo state machines
 * The ERC-165 identifier for this interface is 0xcad6b576
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoOperate {

    /// Emitted when a user transitions from one State to another.
    event UserTransitioned(
        address indexed user,
        bytes4 indexed machineId,
        bytes4 indexed newStateId,
        FismoTypes.ActionResponse response
    );

    /**
     * Invoke an action on a configured Machine.
     *
     * Reverts if
     * - Caller is not the machine's operator (contract or EOA)
     * - Machine does not exist
     * - Action is not valid for the user's current State in the given Machine
     * - Any invoked Guard logic reverts
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the target machine
     * @param _actionId - the id of the action to invoke
     *
     * @return response - the response from the action. See {FismoTypes.ActionResponse}
     */
    function invokeAction(
        address _user,
        bytes4 _machineId,
        bytes4 _actionId
    )
    external
    returns(
        FismoTypes.ActionResponse memory response
    );

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

/**
 * @title IFismoOwner
 *
 * @notice ERC-173 Contract Ownership Standard
 * The ERC-165 identifier for this interface is 0x7f5828d0
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoOwner {

    /// Emitted when ownership of the Fismo instance is transferred
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Get the address of the Fismo instance's owner
     *
     * @return The address of the owner.
     */
    function owner() view external returns(address);

    /**
     * @notice Transfer ownership of the Fismo instance to another address.
     *
     * Reverts if:
     * - Caller is not contract owner
     * - New owner is zero address
     *
     * Emits:
     * - OwnershipTransferred
     *
     * @param _newOwner - the new owner's address
     */
    function transferOwnership (
        address _newOwner
    )
    external;

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";

/**
 * @title IFismoSupport
 *
 * @notice ERC-165 interface detection standard
 * The ERC-165 identifier for this interface is 0x01ffc9a7
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoSupport {

    /**
     * @notice Query whether Fismo supports a given interface
     *
     * @param _interfaceId - the sighash of the given interface
     *
     * @return true if _interfaceId is supported
     */
    function supportsInterface(bytes4 _interfaceId) external view returns (bool);

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "../domain/FismoTypes.sol";

/**
 * @title IFismoUpdate
 *
 * @notice Interface for Fismo update functions
 * The ERC-165 identifier for this interface is 0xf8ebd091
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoUpdate {

    /// Emitted when a new Machine is installed in this Fismo instance
    event MachineInstalled (
        bytes4 indexed machineId,
        string machineName
    );

    /// Emitted when a new State is added to a Fismo Machine.
    /// May be emitted multiple times during the addition of a Machine.
    event StateAdded (
        bytes4 indexed machineId,
        bytes4 indexed stateId,
        string stateName
    );

    /// Emitted when an existing State is updated.
    event StateUpdated (
        bytes4 indexed machineId,
        bytes4 indexed stateId,
        string stateName
    );

    /// Emitted when a new Transition is added to an existing State.
    /// May be emitted multiple times during the addition of a Machine or State.
    event TransitionAdded (
        bytes4 indexed machineId,
        bytes4 indexed stateId,
        string action, string targetStateName
    );

    /**
     * @notice Install a Fismo Machine that requires no initialization.
     *
     * Emits:
     * - MachineInstalled
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Operator address is zero
     * - Machine id is not valid for Machine name
     * - Machine already exists
     *
     * @param _machine - the machine definition to install
     */
    function installMachine (
        FismoTypes.Machine memory _machine
    )
    external;

    /**
     * @notice Install a Fismo Machine and initialize it.
     *
     * Emits:
     * - MachineInstalled
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Operator address is zero
     * - Machine id is not valid for Machine name
     * - Machine already exists
     * - Initializer has no code
     * - Initializer call reverts
     *
     * @param _machine - the machine definition to install
     * @param _initializer - the address of the initializer contract
     * @param _calldata - the encoded function and args to pass in delegatecall
     */
    function installAndInitializeMachine (
        FismoTypes.Machine memory _machine,
        address _initializer,
        bytes memory _calldata
    )
    external;

    /**
     * @notice Add a State to an existing Machine.
     *
     * Note:
     * - The new state will not be reachable by any action
     * - Add one or more transitions to other states, targeting the new state
     *
     * Emits:
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - State id is invalid
     * - Machine does not exist
     * - Any contained transition is invalid
     *
     * @param _machineId - the id of the machine
     * @param _state - the state to add to the machine
     */
    function addState (
        bytes4 _machineId,
        FismoTypes.State memory _state
    )
    external;

    /**
     * @notice Update an existing State in an existing Machine.
     *
     * Note:
     * - State name and id cannot be changed.
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Machine does not exist
     * - State does not exist
     * - State id is invalid
     * - Any contained transition is invalid
     *
     * Use this when:
     * - Adding more than one transition
     * - Removing one or more transitions
     * - Changing exitGuarded, enterGuarded, guardLogic params
     *
     * @param _machineId - the id of the machine
     * @param _state - the state to update
     */
    function updateState (
        bytes4 _machineId,
        FismoTypes.State memory _state
    )
    external;

    /**
     * @notice Add a Transition to an existing State of an existing Machine.
     *
     * Emits:
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Machine does not exist
     * - State does not exist
     * - Action id is invalid
     * - Target state id is invalid
     *
     * Use this when:
     * - Adding only a single transition (use updateState for multiple)
     *
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state
     * @param _transition - the transition to add to the state
     */
    function addTransition (
        bytes4 _machineId,
        bytes4 _stateId,
        FismoTypes.Transition memory _transition
    )
    external;

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoTypes } from "../domain/FismoTypes.sol";

/**
 * @title IFismoView
 *
 * Interface for Fismo view functions
 * The ERC-165 identifier for this interface is 0x691b5451
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
interface IFismoView {

    /**
     * @notice Get the last recorded position of the given user.
     *
     * Positions contain a machine id and state id.
     * See: {FismoTypes.Position}
     *
     * @param _user - the address of the user
     * @return success - whether any positions have been recorded for the user
     * @return position - the last recorded position of the given user
     */
    function getLastPosition(address _user)
    external
    view
    returns (bool success, FismoTypes.Position memory position);

    /**
     * @notice Get the entire position history for a given user.
     *
     * Each Position contains a machine id and state id.
     * See: {FismoTypes.Position}
     *
     * @param _user - the address of the user
     * @return success - whether any history exists for the user
     * @return history - an array of Position structs
     */
    function getPositionHistory(address _user)
    external
    view
    returns (bool success, FismoTypes.Position[] memory history);

    /**
     * @notice Get the current state for a given user in a given machine.
     *
     * Note:
     * - If the user has not interacted with the machine, the initial state
     *   for the machine is returned.
     *
     * Reverts if:
     * - Machine does not exist
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the machine
     * @return state - the user's current state in the given machine. See {FismoTypes.State}
     */
    function getUserState(address _user, bytes4 _machineId)
    external
    view
    returns (FismoTypes.State memory state);

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoOwner } from "./FismoOwner.sol";
import { IFismoOwner } from "../interfaces/IFismoOwner.sol";
import { IFismoUpdate } from "../interfaces/IFismoUpdate.sol";

/**
 * @title FismoUpdate
 *
 * @notice Fismo storage update functionality
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoUpdate is IFismoUpdate, FismoOwner {

    /**
     * @notice Install a Fismo Machine that requires no initialization.
     *
     * Emits:
     * - MachineInstalled
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Operator address is zero
     * - Machine id is not valid for Machine name
     * - Machine already exists
     *
     * @param _machine - the machine definition to install
     */
    function installMachine(Machine memory _machine)
    external
    override
    onlyOwner
    {
        // Add the new machine to Fismo's storage
        addMachine(_machine);
    }

    /**
     * @notice Install a Fismo Machine and initialize it.
     *
     * Emits:
     * - MachineInstalled
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Operator address is zero
     * - Machine id is not valid for Machine name
     * - Machine already exists
     * - Initializer has no code
     * - Initializer call reverts
     *
     * @param _machine - the machine definition to install
     * @param _initializer - the address of the initializer contract
     * @param _calldata - the encoded function and args to pass in delegatecall
     */
    function installAndInitializeMachine(
        Machine memory _machine,
        address _initializer,
        bytes memory _calldata
    )
    external
    override
    onlyOwner
    {
        // Make sure this is actually a contract
        requireContractCode(_initializer, CODELESS_INITIALIZER);

        // Add the new machine to Fismo's storage
        addMachine(_machine);

        // Delegate the call to the initializer contract
        (bool success, bytes memory error) = _initializer.delegatecall(_calldata);

        // Handle failure
        if (!success) {
            revert (
                (error.length > 0)
                    ? string(error)
                    : INITIALIZER_REVERTED
            );
        }

    }

    /**
     * @notice Add a State to an existing Machine.
     *
     * Note:
     * - The new state will not be reachable by any action
     * - Add one or more transitions to other states, targeting the new state
     *
     * Emits:
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - State id is invalid for State name
     * - Machine does not exist
     * - Any contained transition is invalid
     *
     * @param _machineId - the id of the machine
     * @param _state - the state to add to the machine
     */
    function addState(bytes4 _machineId, State memory _state)
    public
    override
    onlyOwner
    {
        // Make sure state id is valid
        require(_state.id == nameToId(_state.name), INVALID_STATE_ID);

        // Get the machine's storage location
        Machine storage machine = getMachine(_machineId);

        // Zero init a new states array element in storage
        machine.states.push();

        // Get the new state's storage location
        uint256 index = machine.states.length - 1;

        // Map state id to index of state in machine's states array
        mapStateIndex(_machineId, _state.id, index);

        // Store the new state in the machine's states array
        storeState(machine, _state, false);

        // Alert listeners to change of state
        emit StateAdded(_machineId, _state.id, _state.name);

    }

    /**
     * @notice Add a Transition to an existing State of an existing Machine.
     *
     * Note:
     * - State name and id cannot be changed.
     *
     * Emits:
     * - StateUpdated
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Machine does not exist
     * - State does not exist
     * - State id is invalid
     * - Any contained transition is invalid
     *
     * Use this when:
     * - Adding more than one transition
     * - Removing one or more transitions
     * - Changing exitGuarded, enterGuarded, guardLogic params
     *
     * @param _machineId - the id of the machine
     * @param _state - the state to update
     */
    function updateState(bytes4 _machineId, State memory _state)
    external
    override
    onlyOwner
    {
        // Make sure state id is valid
        require(_state.id == nameToId(_state.name), INVALID_STATE_ID);

        // Get the machine
        Machine storage machine = getMachine(_machineId);

        // Overwrite the state in the machine's states array
        storeState(machine, _state, true);

        // Alert listeners to change of state
        emit StateUpdated(_machineId, _state.id, _state.name);
    }

    /**
     * @notice Add a Transition to an existing State of an existing Machine
     *
     * Emits:
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Machine does not exist
     * - State does not exist
     * - Action id is invalid
     * - Target state id is invalid
     *
     * Use this when:
     * - Adding only a single transition (use updateState for multiple)
     *
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state
     * @param _transition - the transition to add to the state
     */
    function addTransition(bytes4 _machineId, bytes4 _stateId, Transition memory _transition)
    public
    override
    onlyOwner
    {
        // Make sure action id is valid
        require(_transition.actionId == nameToId(_transition.action), INVALID_ACTION_ID);

        // Make sure target state id is valid
        require(_transition.targetStateId == nameToId(_transition.targetStateName), INVALID_TARGET_ID);

        // Get the target state
        State storage state = getState(_machineId, _stateId, true);

        // Zero init a new transitions array element in storage
        state.transitions.push();

        // Get the new transition's storage index in the state's transitions array
        uint256 index = state.transitions.length - 1;

        // Overwrite the state in the machine's states array
        Transition storage transition = state.transitions[index];
        transition.actionId = _transition.actionId;
        transition.action = _transition.action;
        transition.targetStateId = _transition.targetStateId;
        transition.targetStateName = _transition.targetStateName;

        // Alert listeners to change of state
        emit TransitionAdded(_machineId, state.id, transition.action, transition.targetStateName);
    }

    /**
     * @notice Add a new Machine to Fismo.
     *
     * Emits:
     * - MachineInstalled
     * - StateAdded
     * - TransitionAdded
     *
     * Reverts if:
     * - Caller is not contract owner
     * - Operator address is zero
     * - Machine id is not valid for Machine name
     * - Machine already exists
     *
     * @param _machine - the machine definition to add
     */
    function addMachine(Machine memory _machine)
    internal
    {
        // Make sure operator address is not the black hole
        require(_machine.operator != address(0), INVALID_OPERATOR_ADDR);

        // Make sure machine id is valid
        require(_machine.id == nameToId(_machine.name), INVALID_MACHINE_ID);

        // Get the machine's storage location
        Machine storage machine = getStore().machine[_machine.id];

        // Make sure machine doesn't already exist
        require(machine.id != _machine.id, MACHINE_EXISTS);

        // Store the machine
        machine.operator = _machine.operator;
        machine.id = _machine.id;
        machine.initialStateId = _machine.initialStateId;
        machine.name = _machine.name;
        machine.uri = _machine.uri;

        // Store and map the machine's states
        //
        // Struct arrays cannot be copied from memory to storage,
        // so states must be added to the machine individually
        uint256 length = _machine.states.length;
        for (uint256 i = 0; i < length; i+=1) {

            // Get the state from memory
            State memory state = _machine.states[i];

            // Store the state
            addState(_machine.id, state);
        }

        // Alert listeners to change of state
        emit MachineInstalled(_machine.id, _machine.name);

    }

    /**
     * @notice Store a State.
     *
     * Note:
     * - Shared by addState and updateState.
     *
     * Reverts if:
     * - No code is found at a guarded state's guardLogic address
     *
     * @param _machine - the machine's storage location
     * @param _state - the state's storage location
     * @param _shouldExist - true if the state should exist
     */
    function storeState(Machine storage _machine, State memory _state, bool _shouldExist)
    internal
    {
        // Overwrite the state in the machine's states array
        State storage state = getState(_machine.id, _state.id, _shouldExist);
        state.id = _state.id;
        state.name = _state.name;
        state.exitGuarded = _state.exitGuarded;
        state.enterGuarded = _state.enterGuarded;
        if (_state.exitGuarded || _state.enterGuarded) {
            requireContractCode(_state.guardLogic, CODELESS_GUARD);
            state.guardLogic = _state.guardLogic;
        }

        // Store the state's transitions
        //
        // Struct arrays cannot be copied from memory to storage,
        // so transitions must be added to the state individually
        uint256 length = _state.transitions.length;
        for (uint256 i = 0; i < length; i+=1) {

            // Get the transition from memory
            Transition memory transition = _state.transitions[i];

            // Store the transition
            addTransition(_machine.id, _state.id, transition);

        }

    }

    /**
     * @notice Map a State's index in Machine's states array.
     *
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state within the given machine
     * @param _index - the index of the state within the array
     */
    function mapStateIndex(bytes4 _machineId, bytes4 _stateId, uint256 _index)
    internal
    {
        // Add mapping: machine id => state id => states array index
        getStore().stateIndex[_machineId][_stateId] = _index;
    }

    /**
     * @notice Set the current State for a given user in a given Machine.
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state within the given machine
     */
    function setUserState(address _user, bytes4 _machineId, bytes4 _stateId)
    internal
    {
        // Store the user's new state in the given machine
        getStore().userState[_user][_machineId] = _stateId;

        // Push user's current location onto their history stack
        getStore().userHistory[_user].push(
            Position(_machineId, _stateId)
        );
    }

    /**
     * @notice Set the isFismo flag.
     *
     * @dev Will the real Fismo please stand up?
     *
     * @param _assertion - true if this contract is an original deployment
     */
    function setIsFismo(bool _assertion)
    internal
    {
        getStore().isFismo = _assertion;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoView } from "./FismoView.sol";
import { IFismoOwner } from "../interfaces/IFismoOwner.sol";

/**
 * @title FismoOwner
 *
 * @notice Fismo ownership functionality
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoOwner is IFismoOwner, FismoView {

    /**
     * @notice Modifier to only allow a method to bre called by the contract owner
     */
    modifier onlyOwner() {
        require(msg.sender == getStore().owner, ONLY_OWNER);
        _;
    }

    /**
     * @notice Get the owner of this Fismo contract
     *
     * @return the address of the contract owner
     */
    function owner()
    external
    view
    returns (address)
    {
        return getStore().owner;
    }

    /**
     * @notice Transfer ownership of the Fismo instance to another address.
     *
     * Reverts if:
     * - Caller is not contract owner
     * - New owner is zero address
     *
     * Emits:
     * - OwnershipTransferred
     *
     * @param _newOwner - the new owner's address
     */
    function transferOwnership(address _newOwner)
    external
    override
    onlyOwner
    {
        require(_newOwner != address(0), INVALID_ADDRESS);
        setOwner(_newOwner);
    }

    /**
     * @notice Set the contract owner
     *
     * Emits:
     * - OwnershipTransferred
     *
     * Used by
     * - Fismo constructor
     * - FismoClone.cloneFismo method
     * - FismoOwner.transferOwnership method
     *
     * @param _newOwner - the new contract owner address
     */
    function setOwner(address _newOwner)
    internal
    {
        address previousOwner = getStore().owner;
        getStore().owner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.0;

import { FismoStore } from "../domain/FismoStore.sol";
import { FismoTypes } from "../domain/FismoTypes.sol";
import { FismoConstants } from "../domain/FismoConstants.sol";
import { IFismoClone } from "../interfaces/IFismoClone.sol";
import { IFismoView } from "../interfaces/IFismoView.sol";
import { FismoSupport } from "./FismoSupport.sol";

/**
 * @title FismoView
 *
 * @notice Fismo storage read functionality
 *
 * @author Cliff Hall <[email protected]> (https://twitter.com/seaofarrows)
 */
contract FismoView is IFismoView, FismoTypes, FismoConstants {

    //-------------------------------------------------------
    // EXTERNAL FUNCTIONS
    //-------------------------------------------------------

    /**
     * @notice Get the last recorded position of the given user.
     *
     * Each position contains a machine id and state id.
     * See: {FismoTypes.Position}
     *
     * @param _user - the address of the user
     * @return success - whether any positions have been recorded for the user
     * @return position - the last recorded position of the given user
     */
    function getLastPosition(address _user)
    public
    view
    override
    returns (bool success, Position memory position)
    {
        // Get the user's position historyCF
        Position[] storage history = getStore().userHistory[_user];

        // Return the last position on the stack
        bytes4 none = 0;
        position = (history.length > 0) ? history[history.length-1] : Position(none, none);

        // If the machine id is zero, the user has not interacted with this Fismo instance
        success = (position.machineId != 0);
    }

    /**
     * @notice Get the entire position history for a given user
     *
     * Each position contains a machine id and state id.
     * See: {FismoTypes.Position}
     *
     * @param _user - the address of the user
     * @return success - whether any history exists for the user
     * @return history - an array of Position structs
     */
    function getPositionHistory(address _user)
    public
    view
    returns (bool success, Position[] memory history)
    {
        // Return the user's position history
        history = getStore().userHistory[_user];

        // If there are no history entries, the user has not interacted with this Fismo instance
        success = history.length > 0;
    }

    /**
     * @notice Get the current state for a given user in a given machine.
     *
     * Note:
     * - If the user has not interacted with the machine, the initial state
     *   for the machine is returned.
     *
     * Reverts if:
     * - machine does not exist
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the machine
     * @return state - the user's current state in the given machine. See {FismoTypes.State}
     */
    function getUserState(address _user, bytes4 _machineId)
    external
    view
    override
    returns (State memory state)
    {
        // Get the machine
        Machine storage machine = getMachine(_machineId);

        // Get the user's current state in the given machine
        bytes4 currentStateId = getUserStateId(_user, _machineId);

        // Get the installed state
        state = getState(_machineId, currentStateId, true);

        // If state is guarded, it may filter
        if (state.exitGuarded || state.enterGuarded) {

            // Remove any contextually suppressed actions
            bool[] memory states;
            uint256 count;
            Transition[] memory transitions;
            for (uint256 i = 0; i < state.transitions.length; i++) {

                // Find out if the action is suppressed
                (bool success, bytes memory response) = address(this).staticcall(
                    abi.encodeWithSelector(
                            this.isActionSuppressed.selector,
                            _user,
                            state.guardLogic,
                            machine.name,
                            state.name,
                            state.transitions[i].action
                    )
                );

                states[i] = success && !(bool(abi.decode(response, (bool))));

                if (bool(states[i])) {
                    transitions[count] = state.transitions[i];
                    count++;
                }
            }
            state.transitions = transitions;

        }

    }

    //-------------------------------------------------------
    // INTERNAL FUNCTIONS
    //-------------------------------------------------------

    /**
     * @notice Get a machine by id
     *
     * Reverts if
     * - Machine does not exist
     *
     * @param _machineId - the id of the machine
     * @return machine - the machine configuration
     */
    function getMachine(bytes4 _machineId)
    internal
    view
    returns (Machine storage machine)
    {
        // Get the machine
        machine = getStore().machine[_machineId];

        // Make sure machine exists
        require(machine.id == _machineId, NO_SUCH_MACHINE);
    }

    /**
     * @notice Get a state by Machine id and State id.
     *
     * Reverts if
     * - _verify is true and State does not exist
     *
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state
     * @param _shouldExist - true if the state should already exist
     * @return state - the state definition
     */
    function getState(bytes4 _machineId, bytes4 _stateId, bool _shouldExist)
    internal
    view
    returns (State storage state) {

        // Get the machine
        Machine storage machine = getMachine(_machineId);

        // Get index of state in machine's states array
        uint256 index = getStateIndex(_machineId, _stateId);

        // Get the state
        state = machine.states[index];

        // Verify expected existence or non-existence of State
        if (_shouldExist) {
            require(state.id == _stateId, NO_SUCH_STATE);
        } else {
            require(state.id == 0, STATE_EXISTS);
        }
    }

    /**
     * @notice Get a State's index in Machine's states array.
     *
     * @param _machineId - the id of the machine
     * @param _stateId - the id of the state within the given machine
     *
     * @return index - the state's index in the machine's states array
     */
    function getStateIndex(bytes4 _machineId, bytes4 _stateId)
    internal
    view
    returns(uint256 index)
    {
        index = getStore().stateIndex[_machineId][_stateId];
    }

    /**
     * @notice Get the current state for a given user in a given machine.
     *
     * Note:
     * - If the user has not interacted with the machine, the initial state
     *   for the machine is returned.
     *
     * Reverts if:
     * - machine does not exist
     *
     * @param _user - the address of the user
     * @param _machineId - the id of the machine
     * @return currentStateId - the user's current state id in the given machine.
     */
    function getUserStateId(address _user, bytes4 _machineId)
    internal
    view
    returns (bytes4 currentStateId)
    {
        // Get the machine
        Machine storage machine = getMachine(_machineId);

        // Get the user's current state in the given machine, default to initialStateId if not found
        currentStateId = getStore().userState[_user][_machineId];
        if (currentStateId == bytes4(0)) currentStateId = machine.initialStateId;
    }

    /**
     * @notice Is the given action contextually suppressed?
     *
     * Notes:
     * - A guard contract may supply deterministically named
     *   filter function for each of the machine states it
     *   supports. This function takes the user's address and
     *   an action name, and returns true if it should be
     *   suppressed.
     *
     * Ex.
     * - MachineName_StateName_Filter(address _user, string calldata _action)
     *   external
     *   view
     *   returns (bool)
     *
     * - Enter and exit guards can store information about users
     *   as they interact with the machine, which can be used to
     *   contextually allow or suppress one or more pre-defined
     *   actions for any given state.
     *
     * @param _user - the user address the call is being invoked for
     * @param _guardLogic - the address of the guard logic contract
     * @param _machineName - the name of the machine
     * @param _stateName - the name of the state
     *
     * @return suppressed - list of actions to suppress
     */
    function isActionSuppressed(
        address _user,
        address _guardLogic,
        string memory _machineName,
        string memory _stateName,
        string memory _action
    )
    public
    returns (bool suppressed)
    {
        // Get the filter function selector and encode the call
        bytes4 selector = getGuardSelector(_machineName, _stateName, Guard.Filter);
        bytes memory guardCall = abi.encodeWithSelector(
            selector,
            _user,
            _action
        );

        // Invoke the filter
        (, bytes memory response) = _guardLogic.delegatecall(guardCall);

        // if the function call did not revert, decode the response message
        suppressed = abi.decode(response, (bool));

    }

    /**
     * @notice Get the function selector for an enter or exit guard guard
     *
     * @param _machineName - the name of the machine
     * @param _stateName - the name of the state
     * @param _guard - the type of guard (enter/exit/filter). See {FismoTypes.Guard}
     *
     * @return guardSelector - the function selector, e.g., `0x23b872dd`
     */
    function getGuardSelector(string memory _machineName, string memory _stateName, Guard _guard)
    internal
    pure
    returns (bytes4 guardSelector)
    {
        // Get the guard type as a string
        string memory guardType =
        (_guard == Guard.Filter)
        ? "_Filter"
        : (_guard == Guard.Enter) ? "_Enter" : "_Exit";

        // Get the function name
        string memory functionName = strConcat(
            strConcat(
                strConcat(_machineName, "_"),
                _stateName
            ),
            guardType
        );

        // Construct signature
        string memory guardSignature = strConcat(
            functionName,
            (_guard == Guard.Filter)
            ? "(address,string)"
            : "(address,string,string)"
        );

        // Return the hashed function selector
        guardSelector = nameToId(guardSignature);
    }

    /**
     * @notice Concatenate two strings
     * @param _a the first string
     * @param _b the second string
     * @return result the concatenation of `_a` and `_b`
     */
    function strConcat(string memory _a, string memory _b)
    internal
    pure
    returns(string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    /**
     * @notice Hash a name into a bytes4 id
     *
     * @param _name a string to hash
     *
     * @return id bytes4 sighash of _name
     */
    function nameToId(string memory _name)
    internal
    pure
    returns
    (bytes4 id)
    {
        id = bytes4(keccak256(bytes(_name)));
    }

    /**
     * @notice Get the Fismo storage slot.
     *
     * @return Fismo storage slot
     */
    function getStore()
    internal
    pure
    returns (FismoStore.FismoSlot storage)
    {
        return FismoStore.getStore();
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