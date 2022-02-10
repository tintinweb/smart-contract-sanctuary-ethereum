// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IWorkspaceRegistry.sol";

/// @title Registry for all the workspaces used to create and update workspaces
contract WorkspaceRegistry is Ownable, Pausable, IWorkspaceRegistry {
    /// @notice Number of workspace stored in this registry
    uint96 public workspaceCount;

    /// @notice structure holding each workspace data
    struct Workspace {
        uint96 id;
        address owner;
        string metadataHash;
    }

    /// @notice mapping to store workspaceId vs workspace data structure
    mapping(uint96 => Workspace) public workspaces;

    /// @notice mapping to store workspaceId vs admins
    mapping(uint96 => mapping(address => bool)) public workspaceAdmins;

    // --- Events ---
    /// @notice Emitted when a new workspace is created
    event WorkspaceCreated(uint96 indexed id, address indexed owner, string metadataHash, uint256 time);

    /// @notice Emitted when a workspace is updated
    event WorkspaceUpdated(uint96 indexed id, address indexed owner, string metadataHash, uint256 time);

    /// @notice Emitted when a workspace is updated
    event WorkspaceAdminsAdded(uint96 indexed id, address[] admins, string[] emails, uint256 time);

    /// @notice Emitted when a workspace is updated
    event WorkspaceAdminsRemoved(uint96 indexed id, address[] admins, uint256 time);

    modifier onlyWorkspaceAdmin(uint96 _workspaceId) {
        require(workspaceAdmins[_workspaceId][msg.sender], "Unauthorised: Not an admin");
        _;
    }

    modifier withinLimit(uint256 _adminsLength) {
        require(_adminsLength <= 1000, "WorkspaceRemoveAdmins: Limit exceeded");
        _;
    }

    /**
     * @notice Create a new workspace under which grants will be created,
     * can be called by anyone who wants to create workspace
     * @param _metadataHash workspace metadata pointer to IPFS file
     */
    function createWorkspace(string memory _metadataHash) external whenNotPaused {
        uint96 _id = workspaceCount;
        workspaces[_id] = Workspace(_id, msg.sender, _metadataHash);
        workspaceAdmins[_id][msg.sender] = true;
        emit WorkspaceCreated(_id, msg.sender, _metadataHash, block.timestamp);
        assert(workspaceCount + 1 > workspaceCount);
        workspaceCount += 1;
    }

    /**
     * @notice Update the metadata pointer of a workspace, can be called by workspace admins
     * @param _id ID of workspace to update
     * @param _metadataHash New IPFS hash that points to workspace metadata
     */
    function updateWorkspaceMetadata(uint96 _id, string memory _metadataHash)
        external
        whenNotPaused
        onlyWorkspaceAdmin(_id)
    {
        Workspace storage workspace = workspaces[_id];
        workspace.metadataHash = _metadataHash;
        emit WorkspaceUpdated(workspace.id, workspace.owner, workspace.metadataHash, block.timestamp);
    }

    /**
     * @notice Add admin to a workspace, can be called by workspace admins
     * @param _id ID of target workspace
     * @param _admins New admins for managing workspace
     * @param _emails emails of admin. admin[0] has email [0]
     */
    function addWorkspaceAdmins(
        uint96 _id,
        address[] memory _admins,
        string[] memory _emails
    ) external whenNotPaused onlyWorkspaceAdmin(_id) withinLimit(_admins.length) {
        for (uint256 i = 0; i < _admins.length; i++) {
            address adm = _admins[i];
            workspaceAdmins[_id][adm] = true;
        }
        emit WorkspaceAdminsAdded(_id, _admins, _emails, block.timestamp);
    }

    /**
     * @notice Remove admins from a workspace, can be called by workspace admins
     * @param _id ID of target workspace
     * @param _admins Admins to be removed
     */
    function removeWorkspaceAdmins(uint96 _id, address[] memory _admins)
        external
        whenNotPaused
        onlyWorkspaceAdmin(_id)
        withinLimit(_admins.length)
    {
        for (uint256 i = 0; i < _admins.length; i++) {
            address adm = _admins[i];
            workspaceAdmins[_id][adm] = false;
        }
        emit WorkspaceAdminsRemoved(_id, _admins, block.timestamp);
    }

    /**
     * @notice Check if an address is admin of specified workspace, can be called by anyone
     * @param _id ID of target workspace
     * @param _address Address to validate role
     * @return true if specified address is admin of provided workspace id, else false
     */
    function isWorkspaceAdmin(uint96 _id, address _address) external view override returns (bool) {
        return workspaceAdmins[_id][_address];
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Interface of workspaceRegistry contract
interface IWorkspaceRegistry {
    /// @notice Returns a boolean value indicating whether specified address is owner of given workspace
    function isWorkspaceAdmin(uint96 _id, address _member) external view returns (bool);
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