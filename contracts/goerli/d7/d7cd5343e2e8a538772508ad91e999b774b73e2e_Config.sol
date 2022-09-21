//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./interfaces/ConfigInterface.sol";
import "./lib/Constants.sol";
import {Ownable} from "oz/access/Ownable.sol";

/**
 * @title  Config Center
 * @author ysqi
 * @notice  Manage all configs for nftvoter protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
contract Config is ConfigInterface, Ownable {
    mapping(bytes32 => bytes32) private _items;

    constructor() {
        _items[KEY_VOTE_CANCEL_FEE] = bytes32(uint256(0.1 * 1e4)); //1%
        _items[KEY_VOTE_CANCEL_FEE_RECEIVER] = bytes32(uint256(uint160(msg.sender)));
        _items[KEY_ORI_TAX_RECEIVER] = bytes32(uint256(uint160(msg.sender)));
    }

    function owner() public view override(ConfigInterface, Ownable) returns (address) {
        return Ownable.owner();
    }

    /**
     * @dev Returns the value of the given configuration item.
     */
    function get(bytes32 key) external view override returns (bytes32) {
        return _items[key];
    }

    /**
     * @dev Returns value of the given configuration item.
     * Safely convert the bytes32 value to address before returning.
     */
    function getAddress(bytes32 key) external view override returns (address) {
        uint256 value = uint256(_items[key]);
        require(value <= type(uint160).max, "Over uint160 max");
        return address(uint160(value));
    }

    /**
     * @dev Returns value of the given configuration item.
     */
    function getUint256(bytes32 key) external view override returns (uint256) {
        return uint256(_items[key]);
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
    function resetAddress(bytes32 key, address value) external override {
        reset(key, bytes32(uint256(uint160(value))));
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
    function resetUint256(bytes32 key, uint256 value) external override {
        reset(key, bytes32(value));
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
    function reset(bytes32 key, bytes32 value) public override onlyOwner {
        require(uint256(value) != uint256(_items[key]), "same value");
        _items[key] = value;
        emit Changed(key, value);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Config Center
 * @author ysqi
 * @notice  Manage all configs for nttvoter protocol.
 * each config the type of item key is bytes32, the item value type is bytes32 too.
 */
interface ConfigInterface {
    /*
     * @notice Configuration change event
     * @param key
     * @param value is the new value.
     */
    event Changed(bytes32 indexed key, bytes32 value);

    function owner() external view returns (address);

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
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @dev the key of trade fee receiver
 * key= Keccak-256(KEY_ORI_TAX_RECEIVER)
 */
bytes32 constant KEY_ORI_TAX_RECEIVER = 0xbc8378c341cc1e99afa602b3a2f6ed732baaa175989ee07ef7cdb098ff3286d3;

/**
 * @dev
 */
bytes32 constant KEY_VOTE_CANCEL_FEE_RECEIVER = 0xb7c55bf209a75a5dfac723c0a43aefe1ecc4f32bf3545d8bc7fe9ebf80d2404b;

bytes32 constant KEY_VOTE_CANCEL_FEE = 0x0792ddd065b2799bd31414a0ea136022cdcedd222353debd2ea1b84fcbd71509;

uint256 constant FACTOR_DENOMINATOR = 10_000;

uint16 constant MinQuoteIncreaseFactor = 500; // 5%

uint256 constant MIN_STARTING_PRICE = 0.01 * 1e18; //0.01 ETH

uint256 constant VOTING_LOCKOUT_DURATION = 2 days;

uint256 constant VOTE_WEIGHT_FACTOR_DENOMINATOR = 10_000;

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