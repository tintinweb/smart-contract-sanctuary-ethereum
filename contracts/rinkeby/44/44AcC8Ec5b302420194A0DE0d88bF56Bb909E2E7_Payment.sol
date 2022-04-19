// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";

contract Payment is Ownable{

    uint256 private lockingAmount;
    uint256 private lockingPeriod;

    mapping(string => address) private vanityName;
    mapping (address => uint256) private lockedBalance;
    mapping (address => uint256) private lockedDuration;
    mapping (address => string) private lastVanityName;

    constructor() {
        lockingAmount = 1 ether;
        lockingPeriod = 5 minutes;
    }

    function setLockingAmount(uint256 _newAmount) public onlyOwner {
        lockingAmount = _newAmount;
    }

    function getLockingAmount() public view returns (uint256) {
        return lockingAmount;
    }

    function setLockingPeriod(uint256 _newPeriod) public onlyOwner {
        lockingAmount = _newPeriod;
    }

    function getLockingPeriod() public view returns (uint256) {
        return lockingPeriod;
    }

    function getVanityOwner(string memory _vanityName) public view returns (address) {
        address currentOwner = vanityName[_vanityName];
        uint256 expiryTime = lockedDuration[currentOwner];
        if (expiryTime < block.timestamp)
            return address(0);
        else
            return vanityName[_vanityName];
    }

    function getLockedBalance(address _user) public view returns (uint256) {
        return lockedBalance[_user];
    }

    function getLockedDuration(address _user) public view returns (uint256) {
        if (lockedDuration[_user] < block.timestamp)
            return 0;
        else
            return lockedDuration[_user];
    }

    function getLastVanityName(address _user) public view returns (string memory) {
        return lastVanityName[_user];
    }

    function registerVanityName(string memory _vanityName) public payable {
        require(lockedBalance[msg.sender] == 0, "Registration amount already deposited");
        require(msg.value == lockingAmount, "Deposited amount is invalid");
        
        bytes32 nameHash = getHash(_vanityName);
        
        require(occupied[nameHash] == false, "Hash Already occupied");
        require(getHashOwner(nameHash) == msg.sender, "Caller has not reserved the name");
        require(hashMatching[msg.sender] == nameHash, "Name is not matched with the reserved Hash");
        require(getVanityOwner(_vanityName) == address(0), "Vanity name is already taken");
        
        occupied[nameHash] = true;
        uint256 lockedTime = block.timestamp + lockingPeriod;
        
        vanityName[_vanityName] = msg.sender;
        lockedBalance[msg.sender] = msg.value;
        lockedDuration[msg.sender] = lockedTime;
        lastVanityName[msg.sender] = _vanityName;
    }

    function renewRegistration() public {
        require(lockedBalance[msg.sender] == lockingAmount, "Insufficient locked amount");
        require(getVanityOwner(lastVanityName[msg.sender]) == address(0), "Vanity name is taken");

        vanityName[lastVanityName[msg.sender]] = msg.sender;
        lockedDuration[msg.sender] = block.timestamp + lockingPeriod;
    }

    function withdraw() public {
        require(lockedBalance[msg.sender] > 0, "Insufficient Amount");
        require(lockedDuration[msg.sender] < block.timestamp, "Locked duration is not completed");
        uint256 withdrawalAmount = lockedBalance[msg.sender];
        payable(msg.sender).transfer(withdrawalAmount);
    }

    mapping(bytes32 => address) private reserved;
    mapping(address => bytes32) private hashMatching;
    mapping(bytes32 => bool) private occupied;

    function getHashOwner(bytes32 _hash) public view returns (address) {
        address currentOwner = reserved[_hash];
        if (occupied[_hash] == false)
            return currentOwner;
        else {
            if (lockedDuration[currentOwner] > block.timestamp)
                return currentOwner;          
            else
                return address(0);
        }
    }

    function reserveHash(bytes32 _hash) public {
        require(getHashOwner(_hash) == address(0), "Hash is already reserved");
        reserved[_hash] = msg.sender;
        hashMatching[msg.sender] = _hash;
        occupied[_hash] = false;
    }

    function getHash(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
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