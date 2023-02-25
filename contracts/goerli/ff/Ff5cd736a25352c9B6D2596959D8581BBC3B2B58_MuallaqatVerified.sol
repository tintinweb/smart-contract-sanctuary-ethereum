/*
    Copyright 2022, Abdullah Al-taheri .

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/// @title MuallaqatVerified Contract
/// @author Abdullah Al-taheri

pragma solidity ^0.8.18;


import "@openzeppelin/contracts/access/Ownable.sol";


contract MuallaqatVerified is Ownable  {

    enum LEVELS{
        Star,
        Gem,
        Fire,
        Crown,
        GOAT
    }


    struct UserLevel {
        LEVELS userLevel;
        uint256 expirationDate;
    }
    event Activity (
        address userAddress,
        LEVELS userLevel,
        uint256 expirationDate
    );
    struct LevelDataStruct {
        uint256 expirationDate;
        uint256 fees;
    }
    mapping(address => UserLevel) private users;
    mapping(uint256 => LevelDataStruct) private LevelData;
    // ADMIN FUNCTIONS
  
    function setLevel(
        uint256 level,
        uint256 level_fees,
        uint256 level_expiration_date
  
    ) public onlyOwner  {
        LevelData[level].fees = level_fees;
        LevelData[level].expirationDate = level_expiration_date;
       
    }
    // constructor
    constructor() {
        LevelData[0] = LevelDataStruct(86400 * 30, 0.01 ether);
        LevelData[1] = LevelDataStruct(86400 * 30 * 4,  0.1 ether);
        LevelData[2] = LevelDataStruct(86400 * 30 * 8,  0.2 ether);
        LevelData[3] = LevelDataStruct(86400 * 30 * 12, 1 ether);
        LevelData[4] = LevelDataStruct(86400 * 30 * 120, 20 ether);
    }


    function updateUserAdmin( 
        address _userAddress,
        uint256 level,
        uint256 expirationDate
    ) public onlyOwner   {
        users[_userAddress] = UserLevel(
            LEVELS(level),
            expirationDate
        );
    }
    function verifyUser(address _userAddress,uint256 level) public onlyOwner {
        users[_userAddress].userLevel = LEVELS(level);
        users[_userAddress].expirationDate =  block.timestamp + LevelData[level].expirationDate;
        emit Activity(_userAddress, users[_userAddress].userLevel, users[_userAddress].expirationDate);
    }
    function updateLevel(uint256 level) public payable  {
        require(msg.value >= LevelData[level].fees,  "Not enought ether ");
        // make sure user is not already verified and show "User already verified"
        require(users[msg.sender].expirationDate < block.timestamp, "User already verified");
        users[msg.sender].userLevel = LEVELS(level);
        users[msg.sender].expirationDate = block.timestamp + LevelData[level].expirationDate;
        emit Activity(msg.sender, LEVELS(level), users[msg.sender].expirationDate);
        // transfer fees to owner
        payable(owner()).transfer(msg.value);
    }

    // get user data
    function getUserData(address userAddress) public view returns (UserLevel memory) {
        return users[userAddress];
    }



    // get all leve data 
    function getLevelData() public view returns (LevelDataStruct [5] memory) {
        return [
            LevelData[0],
            LevelData[1],
            LevelData[2],
            LevelData[3],
            LevelData[4]
        ];
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