// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Pausable} from "./abstract/Pausable.sol";
import {AllowList} from "./abstract/AllowList.sol";
import {IProjects} from "./interfaces/IProjects.sol";
import {IPausable} from "./interfaces/IPausable.sol";

/// @title Projects - Tracks projects and their owners
/// @notice A storage contract that tracks project IDs and owner accounts.
contract Projects is IProjects, AllowList, Pausable {
    string public constant NAME = "Projects";
    string public constant VERSION = "0.0.1";

    mapping(uint32 => address) public owners;
    mapping(uint32 => address) public pendingOwners;

    uint32 internal _nextProjectId;

    constructor(address _controller) AllowList(_controller) {}

    /// @inheritdoc IProjects
    function create(address owner) external override onlyAllowed whenNotPaused returns (uint32 id) {
        emit CreateProject(id = ++_nextProjectId);
        owners[id] = owner;
    }

    /// @inheritdoc IProjects
    function transferOwnership(uint32 projectId, address newOwner) external override onlyAllowed whenNotPaused {
        pendingOwners[projectId] = newOwner;
        emit TransferOwnership(projectId, owners[projectId], newOwner);
    }

    /// @inheritdoc IProjects
    function acceptOwnership(uint32 projectId) external override onlyAllowed whenNotPaused {
        address oldOwner = owners[projectId];
        address newOwner = pendingOwnerOf(projectId);
        owners[projectId] = newOwner;
        delete pendingOwners[projectId];
        emit AcceptOwnership(projectId, oldOwner, newOwner);
    }

    /// @inheritdoc IProjects
    function ownerOf(uint32 projectId) external view override returns (address owner) {
        owner = owners[projectId];
        if (owner == address(0)) {
            revert NotFound();
        }
    }

    /// @inheritdoc IProjects
    function pendingOwnerOf(uint32 projectId) public view override returns (address pendingOwner) {
        pendingOwner = pendingOwners[projectId];
        if (pendingOwner == address(0)) {
            revert NotFound();
        }
    }

    /// @inheritdoc IProjects
    function exists(uint32 projectId) external view override returns (bool) {
        return owners[projectId] != address(0);
    }

    /// @inheritdoc IPausable
    function pause() external override onlyController {
        _pause();
    }

    /// @inheritdoc IPausable
    function unpause() external override onlyController {
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Controllable} from "./Controllable.sol";
import {IAllowList} from "../interfaces/IAllowList.sol";

/// @title AllowList - Tracks approved addresses
/// @notice An abstract contract for tracking allowed and denied addresses.
abstract contract AllowList is IAllowList, Controllable {
    mapping(address => bool) public allowed;

    modifier onlyAllowed() {
        if (!allowed[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) Controllable(_controller) {}

    /// @inheritdoc IAllowList
    function denied(address caller) external view returns (bool) {
        return !allowed[caller];
    }

    /// @inheritdoc IAllowList
    function allow(address caller) external onlyController {
        allowed[caller] = true;
        emit Allow(caller);
    }

    /// @inheritdoc IAllowList
    function deny(address caller) external onlyController {
        allowed[caller] = false;
        emit Deny(caller);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "../interfaces/IControllable.sol";

/// @title Controllable - Controller management functions
/// @notice An abstract base contract for contracts managed by the Controller.
abstract contract Controllable is IControllable {
    address public controller;

    modifier onlyController() {
        if (msg.sender != controller) {
            revert Forbidden();
        }
        _;
    }

    constructor(address _controller) {
        if (_controller == address(0)) {
            revert ZeroAddress();
        }
        controller = _controller;
    }

    /// @inheritdoc IControllable
    function setDependency(bytes32 _name, address) external virtual onlyController {
        revert InvalidDependency(_name);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Pausable as OZPausable} from "openzeppelin-contracts/security/Pausable.sol";
import {IPausable} from "../interfaces/IPausable.sol";

/// @title Pausable - Pause and unpause functionality
/// @notice Wraps OZ Pausable and adds an IPausable interface.
abstract contract Pausable is IPausable, OZPausable {}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IControllable} from "./IControllable.sol";

interface IAllowList is IControllable {
    event Allow(address caller);
    event Deny(address caller);

    /// @notice Check whether the given `caller` address is allowed.
    /// @param caller The caller address.
    /// @return True if caller is allowed, false if caller is denied.
    function allowed(address caller) external view returns (bool);

    /// @notice Check whether the given `caller` address is denied.
    /// @param caller The caller address.
    /// @return True if caller is denied, false if caller is allowed.
    function denied(address caller) external view returns (bool);

    /// @notice Add a caller address to the allowlist.
    /// @param caller The caller address.
    function allow(address caller) external;

    /// @notice Remove a caller address from the allowlist.
    /// @param caller The caller address.
    function deny(address caller) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IAnnotated {
    /// @notice Get contract name.
    /// @return Contract name.
    function NAME() external returns (string memory);

    /// @notice Get contract version.
    /// @return Contract version.
    function VERSION() external returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICommonErrors {
    /// @notice The provided address is the zero address.
    error ZeroAddress();
    /// @notice The attempted action is not allowed.
    error Forbidden();
    /// @notice The requested entity cannot be found.
    error NotFound();
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {ICommonErrors} from "./ICommonErrors.sol";

interface IControllable is ICommonErrors {
    /// @notice The dependency with the given `name` is invalid.
    error InvalidDependency(bytes32 name);

    /// @notice Get controller address.
    /// @return Controller address.
    function controller() external returns (address);

    /// @notice Set a named dependency to the given contract address.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _contract address of the dependency.
    function setDependency(bytes32 _name, address _contract) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";
import {IPausable} from "./IPausable.sol";
import {IAllowList} from "./IAllowList.sol";

interface IProjects is IAllowList, IPausable, IAnnotated {
    event CreateProject(uint32 id);
    event TransferOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);
    event AcceptOwnership(uint32 indexed projectId, address indexed owner, address indexed newOwner);

    /// @notice Create a new project owned by the given `owner`.
    /// @param owner address of project owner.
    /// @return uint32 Project ID.
    function create(address owner) external returns (uint32);

    /// @notice Start transfer of `projectId` to `newOwner`. The new owner must
    /// accept the transfer in order to assume ownership of the project.
    /// @param projectId uint32 project ID.
    /// @param newOwner address of proposed new owner.
    function transferOwnership(uint32 projectId, address newOwner) external;

    /// @notice Transfer ownership of `projectId` to `pendingOwner`.
    /// @param projectId uint32 project ID.
    function acceptOwnership(uint32 projectId) external;

    /// @notice Get owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of project owner.
    function ownerOf(uint32 projectId) external view returns (address);

    /// @notice Get pending owner of project by ID.
    /// @param projectId uint32 project ID.
    /// @return address of pending project owner.
    function pendingOwnerOf(uint32 projectId) external view returns (address);

    /// @notice Check whether project exists by ID.
    /// @param projectId uint32 project ID.
    /// @return True if project exists, false if project does not exist.
    function exists(uint32 projectId) external view returns (bool);
}