// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IWalletPolicy.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// TODO: needs to add a check for parameters to the call
//       if the parameters don't match with the signature
//       it may trigger the fallback function even if there's
//       a matching function selector
contract WalletPolicy is Ownable, IWalletPolicy {
    // bytes4(keccak256("isMethodAllowed(address,bytes)")
    bytes4 constant internal POLICY_MAGIC_VALUE = 0xba6d2984;

    event SetScope(address target, bool allowed, bool scoped);
    event SetAllowedMethods(address indexed target, bytes4 method, bool allowed);

    struct Scope {
        bool allowed;
        bool scoped;
        mapping(bytes4 => bool) allowedMethods;
    }
    
    mapping(address => Scope) public allowedContracts;

    constructor() {}

    function isMethodAllowed(
        address target,
        bytes calldata data
    ) external view override returns (bytes4) {
        Scope storage scope = allowedContracts[target];
        if (!scope.allowed) {
            return 0;
        }

        if (!scope.scoped) {
            return POLICY_MAGIC_VALUE;
        }

        if (data.length >= 4) {
           if (scope.allowedMethods[bytes4(data)] == true) {
               return POLICY_MAGIC_VALUE;
           }
        } else {
          // Don't allow fallback methods
          // return data.length == 0; // fallback method
        }

        return 0;
    }

    function setScope(
        address target,
        bool allowed,
        bool scoped
    ) external onlyOwner {
        Scope storage scope = allowedContracts[target];
        require(scope.allowed != allowed || scope.scoped != scoped, "Nothing to update");
        if (scoped) {
            require(allowed, "Can't be scoped without being allowed");
        }
        allowedContracts[target].allowed = allowed;
        allowedContracts[target].scoped = scoped;
        emit SetScope(target, allowed, scoped);
    }

    function setAllowedMethod(
        address target,
        bytes4 method,
        bool allowed
    ) external onlyOwner {
        Scope storage scope = allowedContracts[target];
        require(scope.allowed && scope.scoped, "The contract needs to be allowed and scoped");
        require(scope.allowedMethods[method] != allowed, "Nothing to update");
        scope.allowedMethods[method] = allowed;
        emit SetAllowedMethods(target, method, allowed);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IWalletPolicy {
    function isMethodAllowed(address target, bytes calldata data) external view returns (bytes4);
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