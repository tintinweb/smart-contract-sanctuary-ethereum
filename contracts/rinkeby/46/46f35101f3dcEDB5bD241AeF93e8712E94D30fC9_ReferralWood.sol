//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";


contract ReferralWood is Ownable {

    struct Chest {
        uint256 priceInEth;
        uint256 amountOfReferralsToUnlock;
    }

    struct User {
        uint8 currentLevel;
        address payable referrer;
        address[] referrals; // 3 user refferals
    }

    constructor() {
        for (uint8 i; i < 7; i++) {
            chestsList[i].amountOfReferralsToUnlock = 3**(i+1); // set amount of users to unlock for every chest in list
        }
    }

    mapping(uint8 => Chest) public chestsList;
    mapping(address => User) public usersList; 
    mapping(address => mapping(uint8 => uint16)) public referralsNumberOnLevel; // first nest is level, second is referrals on current level

    function setPrice(uint8 _numberOfChest, uint256 _priceInEth) external onlyOwner() {
        require(_numberOfChest < 7, "Chest total is 7");
        chestsList[_numberOfChest].priceInEth = _priceInEth;
    }

    function joinTo(address payable _referrer) public payable { 
        require(msg.value >= chestsList[usersList[msg.sender].currentLevel].priceInEth, "Insufficient funds to buy a chest"); 
        if(msg.value > chestsList[usersList[msg.sender].currentLevel].priceInEth) { // cashback if user sent more then chest price
            payable(msg.sender).transfer(msg.value - chestsList[usersList[msg.sender].currentLevel].priceInEth);
        }
        if(usersList[msg.sender].referrer == address(0)) {    // if user not registered yet
            usersList[msg.sender].referrer = _referrer;
        } 
        address payable referrer = usersList[msg.sender].referrer;
        if (usersList[referrer].referrals.length < 3) {  // add referral if referrer has empty slotes
            usersList[referrer].referrals.push(msg.sender);
            referralsNumberOnLevel[referrer][0] += 1;
        } else {
            bool brake;
            address[] memory currentLevelReferrals;  // array for user referrals on current nested level
            address[] memory nextLevelReferrals = usersList[referrer].referrals;   // array for user referrals on next nested level
            for(uint8 level; level < 7 && !brake; level++) {
                currentLevelReferrals = nextLevelReferrals;
                delete nextLevelReferrals;
                if(referralsNumberOnLevel[referrer][level] < chestsList[level].amountOfReferralsToUnlock) {
                    for(uint16 referralNumber; referralNumber < currentLevelReferrals.length && !brake; referralNumber++) { 
                        if(usersList[currentLevelReferrals[referralNumber]].referrals.length < 3) {
                            usersList[currentLevelReferrals[referralNumber]].referrals.push(msg.sender); 
                            referralsNumberOnLevel[referrer][level] += 1;
                            brake = true;
                        } else {
                            for(uint8 i; i < 3; i++) {
                                nextLevelReferrals[i] = usersList[currentLevelReferrals[referralNumber]].referrals[i];
                            }
                        }
                    }
                } else {
                    if(level == 0) {
                        nextLevelReferrals = usersList[referrer].referrals;
                    }
                    if(level == usersList[referrer].currentLevel) {
                        referrer.transfer(chestsList[usersList[referrer].currentLevel].priceInEth);
                        usersList[referrer].currentLevel += 1;
                    }
                }
            }
        }
    }

    function parent() public view returns(address) {
        return usersList[msg.sender].referrer;
    }

    function userLevel(address _user) public view returns(uint8) {
        return usersList[_user].currentLevel;
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