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

// SPDX-License-Identifier: MIT
//TODO: Update all natspecs

pragma solidity ^0.8.17;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IAccessManager.sol";

contract AccessManager is IAccessManager, Ownable {
    /// @notice The Access mode by which it is decided whether the caller has access
    mapping(address => AccessMode) private _accessMode;

    /// @notice The mapping that stores permissions to call the function on the target address by the caller
    /// @dev caller => target => function signature => permission to call target function for the given caller address
    /// Only applucable if accessMode for the contracts is set to RestrictedAccess
    mapping(address => mapping(address => mapping(bytes4 => bool)))
        private _restrictedAccess;

    /// @notice Set the permission mode to call the target contract
    /// @param target The address of the target smart contract
    /// @param accessMode Whether no one, any or specific addresses can call the target contract
    function setAccessMode(
        address target,
        AccessMode accessMode
    ) external onlyOwner {
        _setAccessMode(target, accessMode);
    }

    /// @notice Set the permission to call the function on the contract to the specified caller address
    /// @param caller The caller address, who is granted access
    /// @param target The address of the target smart contractd
    /// @param functionSig The function signature (selector), access to which need to be changed
    /// @param enable Whether enable or disable the permission
    function setPermissionToCall(
        address caller,
        address target,
        bytes4 functionSig,
        bool enable
    ) external onlyOwner {
        _setPermissionToCall(caller, target, functionSig, enable);
    }

    /// @return Whether the caller can call the specific function on the target contract
    /// @param caller The caller address
    /// @param target The address of the smart contract which is called
    /// @param functionSig The function signature (selector) to which access wants to be checked
    function canCall(
        address caller,
        address target,
        bytes4 functionSig
    ) external view returns (bool) {
        AccessMode accessMode = _accessMode[target];
        return
            accessMode == AccessMode.Public ||
            (accessMode == AccessMode.RestrictedAccess &&
                _restrictedAccess[caller][target][functionSig]);
    }

    /// @return The access mode for the target
    /// @param target The target smart contract
    function getAccessMode(address target) public view returns (AccessMode) {
        return _accessMode[target];
    }

    /// This is only relevant if accessMode is set to RestrictedAccess
    /// @return Wheter the desired function has restricted access enabled or disabled
    /// @param caller The caller address
    /// @param target The address of the smart contract which is called
    /// @param functionSig The function signature (selector) to which access wants to be checked
    function hasRestricedAccess(
        address caller,
        address target,
        bytes4 functionSig
    ) public view returns (bool) {
        return _restrictedAccess[caller][target][functionSig];
    }

    /// @dev Changes permission to call and emits the event if the permission was changed
    /// Emits and {UpdateCallPermission} event
    function _setPermissionToCall(
        address caller,
        address target,
        bytes4 functionSig,
        bool enable
    ) internal {
        bool currentPermission = _restrictedAccess[caller][target][functionSig];

        if (currentPermission != enable) {
            _restrictedAccess[caller][target][functionSig] = enable;
            emit UpdateCallPermission(caller, target, functionSig, enable);
        }
    }

    /// @dev Changes access mode and emit the event if the access was changed
    /// Emits an {UpdateAccessMode} event
    function _setAccessMode(address target, AccessMode accessMode) internal {
        AccessMode currentAccessMode = _accessMode[target];

        if (currentAccessMode != accessMode) {
            _accessMode[target] = accessMode;
            emit UpdateAccessMode(target, currentAccessMode, accessMode);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IAccessManager {
    /// @notice Type of access to a smart contract. Includes three different modes
    /// @param Closed No one has access to the contract's protected functions
    /// @param RestrictedAccess Any address that has been granted special access can interact with a contract's protected functions
    /// @param Public Everyone can interact with the contract
    enum AccessMode {
        Closed,
        RestrictedAccess,
        Public
    }

    /// @notice Access mode of target contract is changed
    event UpdateAccessMode(
        address indexed target,
        AccessMode previousMode,
        AccessMode newMode
    );

    /// @notice Permission to call the contract's function is changed
    event UpdateCallPermission(
        address indexed caller,
        address indexed target,
        bytes4 indexed functionSig,
        bool status
    );

    function canCall(
        address caller,
        address target,
        bytes4 functionSig
    ) external view returns (bool);

    function setAccessMode(address target, AccessMode accessMode) external;

    function setPermissionToCall(
        address caller,
        address target,
        bytes4 functionSig,
        bool enable
    ) external;
}