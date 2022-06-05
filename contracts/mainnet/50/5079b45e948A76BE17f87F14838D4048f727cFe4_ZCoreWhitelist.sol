// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

contract ZCoreWhitelist is Ownable{

    // Represents the total number of accounts we want to have in our whitelist.
    // Value of this will be set with the constructor when we deploy.
    // uint  public maxWhitelistedAddresses;

    // This logic creates a mapping of address to boolean
    // default value is false. It will be set to true when an address joins.
    mapping(address => bool) public whitelistedAddresses;
    address[] public allAddresses;

    // This variable will keep track of the number of whitelisted addresses. 
    // It will increase until the maximum number is reached.
    uint public numAddressesWhitelisted;
    bool public paused = false;

    // Takes an input that will set the value of maxWhitelistAddress
    // Owner will put the value at the time of deployment
    constructor() {        
    } 

    function addAddressToWhitelist() public {
        require(!whitelistedAddresses[msg.sender], "Sender has already been whitelisted");
        require(!paused, "The contract is paused!");

        // Sets the callers address to true.
        // This makes it a legible whitelisted addres
        whitelistedAddresses[msg.sender] = true;
        allAddresses.push(msg.sender);

        // This will increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function isUserWhiteListed(address _user) public view returns (bool) {
        return whitelistedAddresses[_user];
    }
/**
    function isWhiteListed() public view returns (bool) {
        return whitelistedAddresses[msg.sender];
    }    
**/    
 }