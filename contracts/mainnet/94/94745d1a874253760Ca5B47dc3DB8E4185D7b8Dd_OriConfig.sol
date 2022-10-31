//SPDX-License-Identifier: MIT
//author: Evabase core team
pragma solidity 0.8.16;

import "./interfaces/IOriConfig.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Ori Config Center
 * @author ace
 * @notice  Manage all configs for ori protocol.
 * each config the type of item key is bytes32, the item value type is bytes32/bytes too.
 */
contract OriConfig is IOriConfig, Ownable {
    mapping(bytes32 => bytes32) private _bytes32items;
    mapping(bytes32 => bytes) private _bytesitems;

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32) {
        return _bytes32items[key];
    }

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address) {
        uint256 value = uint256(_bytes32items[key]);
        require(value <= type(uint160).max, "Over uint160 max");
        return address(uint160(value));
    }

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256) {
        return uint256(_bytes32items[key]);
    }

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external onlyOwner {
        uint160 value160 = uint160(value);
        require(value160 != uint256(_bytes32items[key]), "same value");
        bytes32 b32 = bytes32(uint256(value160));
        _bytes32items[key] = b32;
        emit Changed(key, b32);
    }

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external onlyOwner {
        require(value != uint256(_bytes32items[key]), "same value");
        bytes32 b32 = bytes32(value);
        _bytes32items[key] = b32;
        emit Changed(key, b32);
    }

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external onlyOwner {
        require(uint256(value) != uint256(_bytes32items[key]), "same value");
        _bytes32items[key] = value;
        emit Changed(key, value);
    }

    /**
     * @dev Returns the bytes.
     */
    function getBytes(bytes32 key) external view returns (bytes memory) {
        return _bytesitems[key];
    }

    /**
     * @notice  set the configuration item value to a bytes.
     *
     * Emits an `ChangedBytes` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function setBytes(bytes32 key, bytes memory value) external onlyOwner {
        _bytesitems[key] = value;
        emit ChangedBytes(key, value);
    }
}

//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity 0.8.16;

/**
 * @title Ori Config Center
 * @author ysqi
 * @notice  Manage all configs for ori protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface IOriConfig {
    /*
     * @notice White list change event
     * @param key
     * @param value is the new value.
     */
    event ChangeWhite(address indexed key, bool value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event ChangedBytes(bytes32 indexed key, bytes value);

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view returns (bytes32);

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view returns (address);

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view returns (uint256);

    /**
     * @notice Reset the configuration item value to an address.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetAddress(bytes32 key, address value) external;

    /**
     * @notice Reset the configuration item value to a uint256.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function resetUint256(bytes32 key, uint256 value) external;

    /**
     * @notice Reset the configuration item value to a bytes32.
     *
     * Emits an `Changed` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function reset(bytes32 key, bytes32 value) external;

    /**
     * @dev Returns the bytes.
     */
    function getBytes(bytes32 key) external view returns (bytes memory);

    /**
     * @notice  set the configuration item value to a bytes.
     *
     * Emits an `ChangedBytes` event.
     *
     * Requirements:
     *
     * - Only the administrator can call it.
     *
     * @param key is the key of configuration item.
     * @param value is the new value of the given item `key`.
     */
    function setBytes(bytes32 key, bytes memory value) external;
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