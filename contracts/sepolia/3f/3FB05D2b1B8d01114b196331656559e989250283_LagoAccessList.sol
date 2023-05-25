// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import "../interface/ILagoAccessList.sol";
import "openzeppelin-contracts/access/Ownable.sol";

/// @dev Generic access list contract
contract LagoAccessList is ILagoAccessList, Ownable {
    event AccessUpdated(address addr1, address addr2, bool status);

    /// @dev members of the access list
    mapping(address => mapping(address => bool)) public member;

    constructor(address owner, bool addZeroAddress) {
        _transferOwnership(owner);
        if (addZeroAddress) {
            _set(address(0), LAGO_ACCESS_ANY, true);
        }
    }

    /// @inheritdoc ILagoAccessList
    function set(address addr, bool status) external onlyOwner {
        _set(addr, LAGO_ACCESS_ANY, status);
    }

    /// @inheritdoc ILagoAccessList
    function set(address addr1, address addr2, bool status) external onlyOwner {
        _set(addr1, addr2, status);
    }

    function _set(address addr1, address addr2, bool status) internal {
        emit AccessUpdated(addr1, addr2, status);
        member[addr1][addr2] = status;
    }

    /// @inheritdoc ILagoAccessList
    function isMember(address addr1, address addr2) public view returns (bool) {
        if (member[addr1][LAGO_ACCESS_ANY] || member[LAGO_ACCESS_ANY][addr2]) {
            return true;
        }
        return member[addr1][addr2];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

address constant LAGO_ACCESS_ANY = 0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF;

/// @dev Interface definition for LagoAccessList
interface ILagoAccessList {
    /// set `addr`->`LAGO_ACCESS_ANY` to `status`
    /// @param addr the address
    /// @param status true to include on list, false to remove
    function set(address addr, bool status) external;

    /// set `addr1`->`addr2` to `status`
    /// @param addr1 the first address
    /// @param addr2 the second address
    /// @param status true to include on list, false to remove
    function set(address addr1, address addr2, bool status) external;

    /// check if the `addr1`->`addr2` pair is a member of the list
    /// @param addr1 address to check
    /// @param addr2 address to check
    /// @return member true if `addr` is a member of the list, false otherwise
    function isMember(address addr1, address addr2) external view returns (bool member);
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