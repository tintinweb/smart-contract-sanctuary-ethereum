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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
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

import {Ownable2Step} from "openzeppelin-contracts/access/Ownable2Step.sol";

import {IController} from "./interfaces/IController.sol";
import {IControllable} from "./interfaces/IControllable.sol";
import {IAllowList} from "./interfaces/IAllowList.sol";
import {IPausable} from "./interfaces/IPausable.sol";

/// @title Controller - System admin module
/// @notice This module has authority to pause and unpause contracts, update
/// contract dependencies, manage allowlists, and execute arbitrary calls.
contract Controller is IController, Ownable2Step {
    string public constant NAME = "Controller";
    string public constant VERSION = "0.0.1";

    mapping(address => bool) public pausers;

    modifier onlyPauser() {
        if (msg.sender != owner() && !pausers[msg.sender]) {
            revert Forbidden();
        }
        _;
    }

    /// @inheritdoc IController
    function setDependency(address _contract, bytes32 _name, address _dependency) external override onlyOwner {
        IControllable(_contract).setDependency(_name, _dependency);
    }

    /// @inheritdoc IController
    function allow(address _allowList, address _caller) external override onlyOwner {
        IAllowList(_allowList).allow(_caller);
    }

    /// @inheritdoc IController
    function deny(address _allowList, address _caller) external override onlyOwner {
        IAllowList(_allowList).deny(_caller);
    }

    /// @inheritdoc IController
    function allowPauser(address pauser) external override onlyOwner {
        pausers[pauser] = true;
        emit AllowPauser(pauser);
    }

    /// @inheritdoc IController
    function denyPauser(address pauser) external override onlyOwner {
        pausers[pauser] = false;
        emit DenyPauser(pauser);
    }

    /// @inheritdoc IController
    function pause(address _contract) external override onlyPauser {
        IPausable(_contract).pause();
    }

    /// @inheritdoc IController
    function unpause(address _contract) external override onlyPauser {
        IPausable(_contract).unpause();
    }

    /// @inheritdoc IController
    function exec(address receiver, bytes calldata data) external payable override onlyOwner returns (bytes memory) {
        (bool success, bytes memory returnData) = address(receiver).call{value: msg.value}(data);
        if (!success) revert ExecFailed(returnData);
        return returnData;
    }
}

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

import {IAnnotated} from "./IAnnotated.sol";
import {ICommonErrors} from "./ICommonErrors.sol";

interface IController is IAnnotated, ICommonErrors {
    event AllowPauser(address pauser);
    event DenyPauser(address pauser);

    /// @notice The attempted low level call failed.
    error ExecFailed(bytes data);

    /// @notice Given a Controllable contract address, set a named dependency
    /// to the given contract address.
    /// @param _contract address of the Controllable contract.
    /// @param _name bytes32 name of the dependency to set.
    /// @param _dependency address of the dependency.
    function setDependency(address _contract, bytes32 _name, address _dependency) external;

    /// @notice Given an AllowList contract address, add an address to the
    /// allowlist.
    /// @param _allowList address of the AllowList contract.
    /// @param _caller address to allow.
    function allow(address _allowList, address _caller) external;

    /// @notice Given an AllowList contract address, remove an address from the
    /// allowlist.
    /// @param _allowList address of the AllowList contract.
    /// @param _caller address to deny.
    function deny(address _allowList, address _caller) external;

    /// @notice Pause a Pausable contract by address.
    function pause(address _contract) external;

    /// @notice Unpause a Pausable contract by address.
    function unpause(address _contract) external;

    /// @notice Allow an address to call pause and unpause.
    /// @param pauser address to allow.
    function allowPauser(address pauser) external;

    /// @notice Deny an address from calling pause and unpause.
    /// @param pauser address to deny.
    function denyPauser(address pauser) external;

    /// @notice Execute a low level call to `receiver` with the given encoded
    /// `data`.
    /// @param receiver address of the call target.
    /// @param data encoded calldata bytes.
    /// @return Call returndata.
    function exec(address receiver, bytes calldata data) external payable returns (bytes memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IPausable {
    /// @notice Pause the contract.
    function pause() external;

    /// @notice Unpause the contract.
    function unpause() external;
}