// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ITransferController.sol";

//implementation to control transfer of q2

contract TransferController is ITransferController, Ownable {
    mapping(address => bool) public whitelistedAddresses;

    mapping(address => bool) moderator;

    // add addresss to transfer q2
    function addOrChangeUserStatus(address _user, bool status)
        public
        override
        returns (bool)
    {
        require(
            msg.sender == owner() || moderator[msg.sender],
            "Not an Owner or Moderator"
        );
        whitelistedAddresses[_user] = status;
        emit AddOrChangeUserStatus(_user, status);
        return true;
    }

    function isWhiteListed(address _user) public view override returns (bool) {
        return whitelistedAddresses[_user];
    }

    /**
     * @dev Add moderator to whitelist address
     */
    function addOrChangeModeratorStatus(address _moderator, bool status)
        public
        override
        onlyOwner
        returns (bool)
    {
        moderator[_moderator] = status;
        emit AddOrChangeModeratorStatus(_moderator, status);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./utils/Context.sol";

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

pragma solidity ^0.8.0;

//Interface to control transfer of q2
interface ITransferController {
    /**
     * @dev Add `_user` status to `status` or Change `_user` status to `status`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {AddOrChangeUserStatus} event.
     */

    function addOrChangeUserStatus(address _user, bool status)
        external
        returns (bool);

    /**
     * @dev Add `_moderator` status to `status` or Change `_moderator` status to `status`
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {ChangedModeratorStatus} event.
     */

    function addOrChangeModeratorStatus(address _moderator, bool status)
        external
        returns (bool);

    /**
     * @dev Returns status of user By default every address are false
     */

    function isWhiteListed(address _user) external view returns (bool);

    /**
     * @dev Emitted when the address status is added of a `user` or address status is changed of a `user`
     * is set by owner
     * a call to {addOrChangeUserStatus}. `status` is the new status.
     */
    event AddOrChangeUserStatus(address _address, bool status);

    /**
     * @dev Emitted when the address status is added of a `_moderator` or status is changed
     * of a `_moderator` is set by owner
     * a call to {addOrChangeModeratorStatus}. `status` is the new status.
     */
    event AddOrChangeModeratorStatus(address _moderator, bool status);
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