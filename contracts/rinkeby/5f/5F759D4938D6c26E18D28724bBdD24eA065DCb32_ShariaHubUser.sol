/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// File: reputation/ShariaHubReputationInterface.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ShariaHubReputationInterface {
//    modifier onlyUsersContract(){_;}
//    modifier onlyLendingContract(){_;}
    function burnReputation(uint delayDays)  external;
    function incrementReputation(uint completedProjectsByTier)  external;
    function initLocalNodeReputation(address localNode)  external;
    function initCommunityReputation(address community)  external;
    function getCommunityReputation(address target) external view returns(uint256);
    function getLocalNodeReputation(address target) external view returns(uint256);
}

// File: storage/ShariaHubStorageInterface.sol


pragma solidity ^0.8.9;


/**
 * Interface for the eternal storage.
 * Thanks RocketPool!
 * https://github.com/rocket-pool/rocketpool/blob/master/contracts/interface/RocketStorageInterface.sol
 */
interface ShariaHubStorageInterface {

    //modifier for access in sets and deletes
//    modifier onlyShariaHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string memory _value) external;
    function setBytes(bytes32 _key, bytes memory _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory );
    function getBytes(bytes32 _key) external view returns (bytes memory );
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

// File: ShariaHubBase.sol


pragma solidity ^0.8.9;



contract ShariaHubBase {

    uint8 public version;

    ShariaHubStorageInterface public ShariaHubStorage;

    constructor(address _storageAddress) {
        require(_storageAddress != address(0));
        ShariaHubStorage = ShariaHubStorageInterface(_storageAddress);
    }

}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: user/ShariaHubUser.sol

/*
    Smart contract of user status.

    Copyright (C) 2018 ShariaHub

    This file is part of platform contracts.

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

pragma solidity ^0.8.9;




/* @title User
@dev This is an extension to add user
*/
contract ShariaHubUser is Ownable, ShariaHubBase {


    event UserStatusChanged(address target, string profile, bool isRegistered);

    constructor(address _storageAddress)
        ShariaHubBase(_storageAddress)
        
    {
        // Version
        version = 1;
    }

    /**
     * @dev Changes registration status of an address for participation.
     * @param target Address that will be registered/deregistered.
     * @param profile profile of user.
     * @param isRegistered New registration status of address.
     */
    function changeUserStatus(address target, string memory profile, bool isRegistered)
        public
        onlyOwner
    {
        require(target != address(0));
        require(bytes(profile).length != 0);
        ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", profile, target)), isRegistered);
        emit UserStatusChanged(target, profile, isRegistered);
    }

    /**
     * @dev Changes registration statuses of addresses for participation.
     * @param targets Addresses that will be registered/deregistered.
     * @param profile profile of user.
     * @param isRegistered New registration status of addresses.
     */
    function changeUsersStatus(address[] memory targets, string memory profile, bool isRegistered)
        public
        onlyOwner
    {
        require(targets.length > 0);
        require(bytes(profile).length != 0);
        for (uint i = 0; i < targets.length; i++) {
            changeUserStatus(targets[i], profile, isRegistered);
        }
    }

    /**
     * @dev View registration status of an address for participation.
     * @return isRegistered boolean registration status of address for a specific profile.
     */
    function viewRegistrationStatus(address target, string memory profile)
        view public
        returns(bool isRegistered)
    {
        require(target != address(0));
        require(bytes(profile).length != 0);
        isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", profile, target)));
    }

    /**
     * @dev register a localNode address.
     */
    function registerLocalNode(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "localNode", target)));
        if (!isRegistered) {
            ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", "localNode", target)), true);
            ShariaHubReputationInterface rep = ShariaHubReputationInterface (ShariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", "reputation"))));
            rep.initLocalNodeReputation(target);
        }
    }

    /**
     * @dev register a community address.
     */
    function registerCommunity(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "community", target)));
        if (!isRegistered) {
            ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", "community", target)), true);
            ShariaHubReputationInterface rep = ShariaHubReputationInterface(ShariaHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", "reputation"))));
            rep.initCommunityReputation(target);
        }
    }

    /**
     * @dev register a invertor address.
     */
    function registerInvestor(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", "investor", target)), true);
    }

    /**
     * @dev register a community representative address.
     */
    function registerRepresentative(address target)
        external
        onlyOwner
    {
        require(target != address(0));
        ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", "representative", target)), true);
    }


}