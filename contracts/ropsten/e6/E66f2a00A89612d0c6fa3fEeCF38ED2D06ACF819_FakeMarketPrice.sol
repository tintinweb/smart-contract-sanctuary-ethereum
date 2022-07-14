// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/*
FakeMarketPrice.sol

written by:
mousedev.eth

Implications of using FakeMarketPrice.sol

Any call to _convertCentsToWei will fail.

These includes:
1. modifier onlyOwnerOrAdmin
    a. This means the fake market price MUST detect if sender is an admin, and continue to work if it is.
2. createRandomizedIpc
3. createIpcSeed
4. buyIpc
5. changeIpcName
6. modifyDna
7. buyXp
8. getIpcPriceInWei

Since _convertCentsToWei is called within the onlyOwnerOrAdmin modifier, these functions are also affected:
1. setIpcPrice
2. rollAttributes
3. customizeDna
4. randomizeDna
5. changeAdminAuthorization
6. setSpecialPriceForAddress
7. changeIpcName

However, we can solve this by allowing admin accounts to call the USD function.

The side effects are that under no circumstance can a user call the included functions without admin access.
*/

interface MarketPrice {
    function USD(uint256 _id) external view returns (uint256);
}

contract FakeMarketPrice is Ownable {
    MarketPrice public OldMarketPrice;

    constructor(address marketPriceAddress) {
        OldMarketPrice = MarketPrice(marketPriceAddress);
    }
    
    uint256 public testVar;

    bool public willRevert = true;
    bool public allowAdminUsage = true;

    mapping(address => bool) public isAdmin;

    function setAdmin(address _admin, bool _isAdmin) public onlyOwner {
        isAdmin[_admin] = _isAdmin;
    }

    function toggleRevert(bool _willRevert) public onlyOwner {
        willRevert = _willRevert;
    }

    function toggleAdminUsage(bool _allowAdminUsage) public onlyOwner {
        allowAdminUsage = _allowAdminUsage;
    }

    function USD(uint256) public view returns (uint256) {
        if (willRevert) {
            //If admins are allowed and they are one, return old market price.
            if (allowAdminUsage && isAdmin[msg.sender]) return OldMarketPrice.USD(0);

            //revert.
            revert();
        }

        //If reverting it turned off, return old market price.
        return OldMarketPrice.USD(0);
    }

    function tryToReadFromUSD() public {
        testVar = USD(0);
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