//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Owned} from "@rari-capital/solmate/src/auth/Owned.sol";
import {IStack} from "./IStack.sol";

/// @dev Data required when creating a new stack
struct CreateStack {
    string slug;
    string stackType;
    address owner;
    bytes initData;
    string metadata;
}

/// @notice Factory contract project admins can use to deploy new Metalabel stacks
contract StackFactory is Owned {
    // ---
    // Events
    // ---

    /// @notice A new project was created
    event ProjectCreated(uint256 projectId, address admin, string metadata);

    /// @notice A projects's admin was set
    event ProjectAdminUpdated(uint256 projectId, address admin);

    /// @notice The project admin updated the project metadata
    event ProjectMetadataUpdated(uint256 projectId, string metadata);

    /// @notice A new stack was deployed by the project admin
    event StackCreated(
        uint256 projectId,
        string stackType,
        string slug,
        IStack stack,
        string metadata
    );

    // ---
    // Errors
    // ---

    /// @notice A non-allowed account attempted to launch a stack
    error StackCreationNotAllowed();

    /// @notice An action requiring msg.sender to be the project admin was attempted
    error NotProjectAdmin();

    /// @notice A stack implementation using the same type name was already added
    error StackTypeAlreadyExists();

    /// @notice A stack was created with a slug that was already used for this project
    error StackSlugAlreadyExists();

    /// @notice A stack deploy was attempted with a bad stack type value
    error InvalidStackType();

    // ---
    // Storage
    // ---

    /// @notice Mapping from a project ID => project admin account
    mapping(uint256 => address) public projectAdmins;

    /// @notice A mapping from an implementation id => its address
    mapping(string => IStack) public stackImplementations;

    /// @notice A mapping from (project id, stack slug) => its address
    mapping(uint256 => mapping(string => IStack)) public projectStacks;

    /// @notice The merkle root of the admin allowlist, zero = GA
    bytes32 public adminAllowlistRoot;

    /// @notice The next project ID to be issued
    uint256 public nextProjectId = 1;

    /// @notice Constructor takes an initial stack type and implementation to register
    constructor(
        address metalabelAdmin,
        string memory stackType,
        IStack implementation
    ) Owned(metalabelAdmin) {
        stackImplementations[stackType] = implementation;
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
    }

    // ---
    // Public functionality
    // ---

    /// @notice Create a new project and stack in a single trx
    function createProjectAndStack(
        CreateStack calldata stackParams,
        string calldata projectMetadata,
        bytes32[] calldata /* proof */
    ) external returns (uint256 projectId, IStack stack) {
        if (adminAllowlistRoot != 0) {
            // TODO: verify proof
        }

        projectId = _createProject(projectMetadata, stackParams.owner);
        stack = _createStack(projectId, stackParams);
    }

    /// @notice Create a new Metalabel project
    function createProject(
        string calldata metadata,
        address admin,
        bytes32[] calldata /* proof */
    ) external returns (uint256 projectId) {
        if (adminAllowlistRoot != 0) {
            // TODO: verify proof
        }

        return _createProject(metadata, admin);
    }

    // ---
    // Project admin functionality
    // ---

    modifier msgSenderMustBeAdmin(uint256 projectId) {
        if (projectAdmins[projectId] != msg.sender) revert NotProjectAdmin();
        _;
    }

    /// @notice Create a new stack for a project, only callable by project admin
    function createStack(uint256 projectId, CreateStack calldata stackParams)
        external
        msgSenderMustBeAdmin(projectId)
        returns (IStack)
    {
        return _createStack(projectId, stackParams);
    }

    /// @notice Announce new metadata for a project
    function setProjectMetadata(uint256 projectId, string calldata metadata)
        external
        msgSenderMustBeAdmin(projectId)
    {
        emit ProjectMetadataUpdated(projectId, metadata);
    }

    /// @notice Modify the project owner
    function setProjectAdmin(uint256 projectId, address admin)
        external
        msgSenderMustBeAdmin(projectId)
    {
        projectAdmins[projectId] = admin;
        emit ProjectAdminUpdated(projectId, admin);
    }

    // ---
    // Implementation
    // ---

    function _createProject(string calldata metadata, address admin)
        private
        returns (uint256)
    {
        uint256 projectId = nextProjectId++;
        projectAdmins[projectId] = admin;

        emit ProjectCreated(projectId, admin, metadata);
        return projectId;
    }

    function _createStack(uint256 projectId, CreateStack calldata stackParams)
        private
        returns (IStack)
    {
        IStack implementation = stackImplementations[stackParams.stackType];

        // ensure stackType resolves to an actual implementation and that the
        // slug hasn't yet been used for this project
        if (implementation == IStack(address(0))) revert InvalidStackType();
        if (projectStacks[projectId][stackParams.slug] != IStack(address(0))) {
            revert StackSlugAlreadyExists();
        }

        // Deploy, initialize, and store the address of the stack
        IStack stack = IStack(Clones.clone(address(implementation)));
        stack.initialize(projectId, stackParams.owner, stackParams.initData);
        projectStacks[projectId][stackParams.slug] = stack;

        emit StackCreated(
            projectId,
            stackParams.stackType,
            stackParams.slug,
            stack,
            stackParams.metadata
        );

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

/// @dev The interface all stack collection implementation contracts must adhere to
interface IStack {
    /// @notice The project that this stack belongs to
    function projectId() external view returns (uint256);

    /// @notice Called by the factory after deploying a new stack clone
    function initialize(
        uint256 projectId,
        address owner,
        bytes calldata initData
    ) external;
}