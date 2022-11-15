// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";

// Via the "opt-out" list, creators are able to disallow collections they
// own from being tradeable on Forward. The owner of the contract has the
// power of overriding the status of any collection (useful in cases when
// the collection doesn't follow the standard ownership interface).
contract OptOutList is Ownable {
    // Errors

    error AlreadySet();
    error Unauthorized();

    // Events

    event OptOutListUpdated(address token, bool optedOut);

    // Private fields

    // Use `uint256` instead of `bool` for gas-efficiency
    // Reference:
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/58f635312aa21f947cae5f8578638a85aa2519f5/contracts/security/ReentrancyGuard.sol#L23-L27
    mapping(address => uint256) private optOutStatus;

    // Public methods

    function setOptOutStatus(address token, bool status) external {
        if (msg.sender != Ownable(token).owner()) {
            revert Unauthorized();
        }

        _setOptOutStatus(token, status);
    }

    function optedOut(address token) external view returns (bool status) {
        return optOutStatus[token] == 1 ? true : false;
    }

    // Restricted methods

    function adminSetOptOutStatus(address token, bool status) external {
        if (msg.sender != owner()) {
            revert Unauthorized();
        }

        _setOptOutStatus(token, status);
    }

    // Internal methods

    function _setOptOutStatus(address token, bool status) internal {
        uint256 currentStatus = optOutStatus[token] == 1 ? 1 : 2;
        uint256 newStatus = status ? 1 : 2;
        if (currentStatus == newStatus) {
            revert AlreadySet();
        }

        optOutStatus[token] = newStatus;
        emit OptOutListUpdated(token, status);
    }
}

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