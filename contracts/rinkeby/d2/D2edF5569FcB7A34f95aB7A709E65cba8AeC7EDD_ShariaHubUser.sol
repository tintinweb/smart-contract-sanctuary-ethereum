/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: storage/ShariaHubStorageInterface.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;


/**
 * Interface for the eternal storage.
 * Thanks RocketPool!
 * https://github.com/rocket-pool/rocketpool/blob/master/contracts/interface/RocketStorageInterface.sol
 */
interface ShariaHubStorageInterface {

    //modifier for access in sets and deletes
    // modifier onlyEthicHubContracts() {_;}

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
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
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
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

pragma solidity ^0.8.9;


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
contract ShariaHubUser is Ownable {

    uint8 public version;
    ShariaHubStorageInterface public ShariaHubStorage;

    event UserStatusChanged(address target, string profile, bool isRegistered);

    constructor(address _ShariaHubStorage) {
        require(address(_ShariaHubStorage) != address(0), "Storage address cannot be zero address");

        ShariaHubStorage = ShariaHubStorageInterface(_ShariaHubStorage);
        version = 4;

        // Ownable.initialize(msg.sender);
    }

    /**
     * @dev Changes registration status of an address for participation.
     * @param target Address that will be registered/deregistered.
     * @param profile profile of user.
     * @param isRegistered New registration status of address.
     */
    function changeUserStatus(
        address target,
        string memory profile,
        bool isRegistered
        ) public onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        require(bytes(profile).length != 0);
        ShariaHubStorage.setBool(keccak256(abi.encodePacked("user", profile, target)), isRegistered);
        emit UserStatusChanged(target, profile, isRegistered);
    }


    /**
     * @dev delete an address for participation.
     * @param target Address that will be deleted.
     * @param profile profile of user.
     */
    function deleteUserStatus(address target, string memory profile) internal onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        require(bytes(profile).length != 0);
        ShariaHubStorage.deleteBool(keccak256(abi.encodePacked("user", profile, target)));
        emit UserStatusChanged(target, profile, false);
    }


    /**
     * @dev View registration status of an address for participation.
     * @return isRegistered boolean registration status of address for a specific profile.
     */
    function viewRegistrationStatus(address target, string memory profile) public view returns(bool isRegistered) {
        require(target != address(0), "Target address cannot be undefined");
        require(bytes(profile).length != 0);
        isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", profile, target)));
    }

    /**
     * @dev register a localNode address.
     */
    // function registerLocalNode(address target) external onlyOwner {
    //     require(target != address(0), "Target address cannot be undefined");
    //     bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "localNode", target)));
    //     if (!isRegistered) {
    //         changeUserStatus(target, "localNode", true);
    //     }
    // }

    /**
     * @dev unregister a localNode address.
     */
    // function unregisterLocalNode(address target) external onlyOwner {
    //     require(target != address(0), "Target address cannot be undefined");
    //     bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "localNode", target)));
    //     if (isRegistered) {
    //         deleteUserStatus(target, "localNode");
    //     }
    // }

    /**
     * @dev register a community address.
     */
    function registerCommunity(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "community", target)));
        if (!isRegistered) {
            changeUserStatus(target, "community", true);
        }
    }

    /**
     * @dev unregister a community address.
     */
    function unregisterCommunity(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "community", target)));
        if (isRegistered) {
            deleteUserStatus(target, "community");
        }
    }

    /**
     * @dev register a invertor address.
     */
    function registerInvestor(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        changeUserStatus(target, "investor", true);
    }

    /**
     * @dev unregister a investor address.
     */
    function unregisterInvestor(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "investor", target)));
        if (isRegistered) {
            deleteUserStatus(target, "investor");
        }
    }

    /**
     * @dev register a community representative address.
     */
    function registerRepresentative(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        changeUserStatus(target, "representative", true);
    }

    /**
     * @dev unregister a representative address.
     */
    function unregisterRepresentative(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "representative", target)));
        if (isRegistered) {
            deleteUserStatus(target, "representative");
        }
    }

    /**
     * @dev register a paymentGateway address.
     */
    function registerPaymentGateway(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        changeUserStatus(target, "paymentGateway", true);
    }

    /**
     * @dev unregister a paymentGateway address.
     */
    function unregisterPaymentGateway(address target) external onlyOwner {
        require(target != address(0), "Target address cannot be undefined");
        bool isRegistered = ShariaHubStorage.getBool(keccak256(abi.encodePacked("user", "paymentGateway", target)));
        if (isRegistered) {
            deleteUserStatus(target, "paymentGateway");
        }
    }
}