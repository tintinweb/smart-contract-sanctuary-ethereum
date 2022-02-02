// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

/*
* @title Decentralize list address
* @author nobodyw, https://github.com/nobodyw
* @notice Administration system with whitelist and blacklist
*/
contract Admin is Ownable{

    mapping(address => bool) WhiteList;
    mapping(address => bool) BlackList;

    event Whitelisted(address userWhiteList, bool isWhiteList);
    event BlackListed(address userBlackList, bool isBlackList);

/*
* @notice The owner adds an address in the whiteList
* @dev If the address was blacklisted add to whitelist
*/
    function addToWhiteList(address _addressWhiteListed) external onlyOwner {
        require(!WhiteList[_addressWhiteListed], "The account is already WhiteListed");

        WhiteList[_addressWhiteListed] = true;
        BlackList[_addressWhiteListed] = false;
        emit Whitelisted(_addressWhiteListed, WhiteList[_addressWhiteListed]);
    }

/*
* @notice The owner adds an address in the blacklist
* @dev If the address was whitelisted add to blacklist
*/
    function addToBlackList(address _addressBlackListed) external onlyOwner {
        require(!BlackList[_addressBlackListed], "The account is already BlackListed");

        BlackList[_addressBlackListed] = true;
        WhiteList[_addressBlackListed] = false;
        emit BlackListed(_addressBlackListed, BlackList[_addressBlackListed]);
    }

/*
* @notice return true if address is in whitelist
*/
    function isWhitelisted(address _addressUser) external view returns(bool){
        return WhiteList[_addressUser];
    }

/*
* @notice return true if address is in blacklist
*/
    function isBlacklisted(address _addressUser) external view returns(bool){
        return BlackList[_addressUser];
    }

/*
* @notice cancels the user in all lists
*/
    function removeList(address _addressUser) external onlyOwner{
        WhiteList[_addressUser] = false;
        BlackList[_addressUser] = false;
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