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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../interface/ILagoAccessList.sol";
import "../interface/ILagoAccess.sol";

import "openzeppelin-contracts/access/Ownable.sol";

// @dev interface for Chainalsys sactions oracle
// https://go.chainalysis.com/chainalysis-oracle-docs.html
interface SanctionsList {
    function isSanctioned(address addr) external view returns (bool);
}

/// @dev helper functions for allow & deny lists
contract LagoAccess is ILagoAccess, Ownable {

    event AllowListUpdated(address current, address previous);
    event DenyListUpdated(address current, address previous);
    event UseSanctionsList(bool);

    /// @dev Chainalysis sanctions oracle, if available on the network
    // https://go.chainalysis.com/chainalysis-oracle-docs.html
    SanctionsList constant public sanctionsList = SanctionsList(0x40C57923924B5c5c5455c48D93317139ADDaC8fb);
    bool public useSanctionsList;

    /// @dev Allow list
    ILagoAccessList public allowList;

    /// @dev Deny list
    ILagoAccessList public denyList;

    constructor(
        address owner_,
        ILagoAccessList allowList_,
        ILagoAccessList denyList_
    ) Ownable() {
        if (owner_ != _msgSender()) {
            Ownable.transferOwnership(owner_);
        }

        _setAllowList(allowList_);
        _setDenyList(denyList_);

        if (block.chainid == 1) {
            _setUseSanctionsList(true);
        }
    }

    /// @inheritdoc ILagoAccess
    function isAllowed(address a) external view returns (bool) {
        return _isAllowed(a);
    }

    /// @inheritdoc ILagoAccess
    function isAllowed(address a, address b) external view returns (bool) {
        return _isAllowed(a) && _isAllowed(b);
    }

    function _isAllowed(address a) internal view returns (bool) {
        // ensure address is NOT sanctioned if sanctions list check is enabled
        if (useSanctionsList) {
            if (sanctionsList.isSanctioned(a)) {
                return false;
            }
        }

        // If allowList exists, ensure address is on the list
        if (address(allowList) != address(0)) {
            if (!allowList.isMember(a)) {
                return false;
            }
        }

        // If denyList exists, ensure address is NOT on the list
        if (address(denyList) != address(0)) {
            if(denyList.isMember(a)) {
                return false;
            }
        }

        // all checks pass
        return true;
    }

    function _setAllowList(ILagoAccessList allowList_) internal {
        emit AllowListUpdated(address(allowList_), address(allowList));
        allowList = allowList_;
    }

    function _setDenyList(ILagoAccessList denyList_) internal {
        emit DenyListUpdated(address(denyList_), address(denyList));
        denyList = denyList_;
    }

    function _setUseSanctionsList(bool enable_) internal {
        emit UseSanctionsList(enable_);
        useSanctionsList = enable_;
    }


    /// update the allowList 
    /// @param allowList_ address of LagoAccessList contract used as allow list
    function setAllowList(ILagoAccessList allowList_) external onlyOwner {
        _setAllowList(allowList_);
    }

    /// update the denyList
    /// @param denyList_ address of LagoAccessList contract used as deny list
    function setDenyList(ILagoAccessList denyList_) external onlyOwner {
        _setDenyList(denyList_);
    }


    /// enable/disable sanctions list check
    /// @param enable_ true to enable, false to disable sanctions list checking
    function setUseSanctionsList(bool enable_) external onlyOwner {
        _setUseSanctionsList(enable_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Interface definition for LagoAccessList
interface ILagoAccess {
    /// @dev check if address is permitted per the allow & deny lists
    /// @param a address to check
    /// @return allowed  true if permitted, false if not
    function isAllowed(address a) external view returns (bool allowed);

    /// @dev check if both addresses are permitted per the allow & deny lists
    /// @param a first address to check
    /// @param b second address to check
    /// @return allowed true if permitted, false if not
    function isAllowed(address a, address b) external view returns (bool allowed);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// @dev Interface definition for LagoAccessList
interface ILagoAccessList  {
    /// if `addr` is a member of the list
    /// @param addr address to check
    /// @return isMember true if `addr` is a member of the list, false otherwise
    function isMember(address addr) external view returns (bool isMember);
}