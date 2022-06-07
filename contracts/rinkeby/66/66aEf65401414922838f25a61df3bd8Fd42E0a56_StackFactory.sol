//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Owned} from "@rari-capital/solmate/src/auth/Owned.sol";
import {IStack} from "./IStack.sol";

/// @notice Factory contract squad admins can use to deploy new Metalabel stacks
contract StackFactory is Owned {
    // ---
    // Events
    // ---

    /// @notice A new squad was created
    event SquadCreated(uint256 squadId, address admin, string metadata);

    /// @notice A squad's admin was set
    event SquadAdminUpdated(uint256 squadId, address admin);

    /// @notice The squad admin updated the squad metadata
    event SquadMetadataUpdated(uint256 squadId, string metadata);

    /// @notice A new stack was deployed by the squad admin
    event StackCreated(uint256 squadId, string stackType, IStack stack);

    /// @notice A new stack type was added by Metalabel
    event StackImplementationAdded(string stackType, IStack implementation);

    // ---
    // Errors
    // ---

    /// @notice A non-allowed account attempted to launch a stack
    error StackCreationNotAllowed();

    /// @notice An action requiring msg.sender to be the squad admin was attempted
    error NotSquadAdmin();

    /// @notice A stack implementation using the same type name was already added
    error StackTypeAlreadyExists();

    // ---
    // Storage
    // ---

    /// @notice A mapping from an implementation id => its address
    mapping(string => IStack) public stackImplementations;

    /// @notice Mapping from a squad ID => squad admin account
    mapping(uint256 => address) public squadAdmins;

    /// @notice The merkle root of the admin allowlist, zero = GA
    bytes32 public adminAllowlistRoot;

    /// @notice The next squad ID to be issued
    uint256 public nextSquadId = 1;

    /// @notice Constructor takes an initial stack type and implementation to register
    constructor(
        address metalabelAdmin,
        string memory stackType,
        IStack implementation
    ) Owned(metalabelAdmin) {
        stackImplementations[stackType] = implementation;
        emit StackImplementationAdded(stackType, implementation);
    }

    // ---
    // Metalabel admin functionality
    // ---

    /// @notice Add a new stack implementation, only callable by Metalabel
    function addStackImplementation(
        string calldata stackType,
        IStack implementation
    ) public onlyOwner {
        // stack types are immutable, only allow setting once
        if (stackImplementations[stackType] != IStack(address(0))) {
            revert StackTypeAlreadyExists();
        }

        stackImplementations[stackType] = implementation;
        emit StackImplementationAdded(stackType, implementation);
    }

    // ---
    // Public functionality
    // ---

    /// @notice Create a new squad and stack
    function createSquadAndStack(
        string calldata squadMetadata,
        string calldata stackType,
        string calldata name,
        string calldata symbol,
        address stackOwnerAndSquadAdmin,
        bytes32[] calldata /* proof */
    ) external returns (uint256 squadId, IStack stack) {
        if (adminAllowlistRoot != 0) {
            // TODO: verify proof
        }

        squadId = _createSquad(squadMetadata, stackOwnerAndSquadAdmin);
        // TODO: owner = 0, stack owner behavior modification
        stack = _createStack(squadId, stackType, name, symbol, stackOwnerAndSquadAdmin);
    }

    /// @notice Create a new squad
    function createSquad(
        string calldata metadata,
        address admin,
        bytes32[] calldata /* proof */
    ) external returns (uint256 squadId) {
        if (adminAllowlistRoot != 0) {
            // TODO: verify proof
        }

        return _createSquad(metadata, admin);
    }

    // ---
    // Squad admin functionality
    // ---

    /// @notice Create a new stack for a squad, only callable by squad admin
    function createStack(
        uint256 squadId,
        string calldata stackType,
        string calldata name,
        string calldata symbol,
        address stackOwner
    ) external returns (IStack) {
        if (squadAdmins[squadId] != msg.sender) revert NotSquadAdmin();

        return _createStack(squadId, stackType, name, symbol, stackOwner);
    }

    /// @notice Announce new metadata for a squad
    function setSquadMetadata(uint256 squadId, string calldata metadata)
        external
    {
        if (squadAdmins[squadId] != msg.sender) revert NotSquadAdmin();

        emit SquadMetadataUpdated(squadId, metadata);
    }

    /// @notice Modify the squad owner
    function setSquadAdmin(uint256 squadId, address admin) external {
        if (squadAdmins[squadId] != msg.sender) revert NotSquadAdmin();

        squadAdmins[squadId] = admin;
        emit SquadAdminUpdated(squadId, admin);
    }

    // ---
    // Implementation
    // ---

    function _createSquad(string calldata metadata, address admin)
        private
        returns (uint256)
    {
        uint256 squadId = nextSquadId++;
        squadAdmins[squadId] = admin;

        emit SquadCreated(squadId, admin, metadata);
        return squadId;
    }

    function _createStack(
        uint256 squadId,
        string calldata stackType,
        string calldata name,
        string calldata symbol,
        address stackOwner
    ) private returns (IStack) {
        IStack implementation = stackImplementations[stackType];

        // reverts if invalid stackType
        IStack stack = IStack(Clones.clone(address(implementation)));

        stack.initialize(squadId, name, symbol, stackOwner);

        emit StackCreated(squadId, stackType, stack);
        return stack;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStack {
    /// @notice The squad that this stack belongs to
    function squadId() external view returns (uint256);

    /// @notice Called by the factory after deploying a new stack clone
    function initialize(
        uint256 squadId,
        string calldata name,
        string calldata symbol,
        address owner
        /* TODO bytes calldata data */
    ) external;
}