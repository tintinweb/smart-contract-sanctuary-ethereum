// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../settings/SettingRulesConfigurable.sol";
import "../settings/SettingsV1.sol";

// Oracle settings
//
// Pluggable contract which implements setting changes and can be evolved to new contracts
//
contract AuthoritySettingValidatorV1 is Ownable, SettingRulesConfigurable {
  // Constructor stub

  // -- don't accept raw ether
  receive() external payable {
    revert('unsupported');
  }

  // -- reject any other function
  fallback() external payable {
    revert('unsupported');
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

// import "hardhat/console.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./SettingsV1.sol";
import "./SettingValidatorV1.sol";

struct SettingRule {
  bool isFrozen;
  uint64 lockedUntil;
}

// Extends an ownable contract with functionality which allows configuring and freezing settings.
abstract contract SettingRulesConfigurable is Ownable, SettingValidatorV1 {

  // Change rules on a certain setting to support secure go-live of the network.
  // The key here is the keccak256(abi.encode(...setting.path)), iterated by the path levels, which allows locking granular settings or specific subsettings
  mapping(bytes32 => SettingRule) internal rules;

  event PathRuleSet(bytes32 indexed path0, bytes32 indexed pathIdx, bytes32[] path, SettingRule rule);

  // ExternalData interface used by authority
  function isValidUnlockedSetting(bytes32[] calldata path, uint64, bytes calldata) external view override isPathUnlocked_(path) returns (bool) {
    return true;
  }

  // -- GETTERS

  function getRule(bytes32[] calldata path) external view returns (SettingRule memory) {
    return rules[hashPath(path)];
  }

  // TODO future versions should check paths breadth-first. Since we don't need this yet and only require the structure, this is not yet implemented.
  function isPathUnlocked(bytes32[] calldata path) public view returns (bool) {
    bytes32 pathHash = hashPath(path);
    return rules[pathHash].isFrozen == false && rules[pathHash].lockedUntil < block.timestamp;
  }
  // -- SETTERS

  // Set irriversible rules on the abi-encoded values
  function setPathRule(bytes32[] calldata path, SettingRule calldata rule) external onlyOwner isPathUnlocked_(path) {
    require(path.length > 0, "400");
    bytes32 pathHash = hashPath(path);
    rules[pathHash] = rule;
    emit PathRuleSet(path[0], pathHash, path, rule);
  }

  // -- MODIFIERS

  // Check if a value (or it's rules) are unlocked for changes.
  modifier isPathUnlocked_(bytes32[] calldata path) {
    require(isPathUnlocked(path), "403");
    _;
  }
}

// More ideas here are to extend this with some setting-filter which (can) restrict updates to the values, eg: frozen-forever, frozen-TIMEdelay, supermajority, delayed-doubleconfirmation, ... we should watch out for complexity and impact to security models when looking into this.

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

function settingToPath(bytes32 setting) pure returns (bytes32[] memory) {
  bytes32[] memory path = new bytes32[](1);
  path[0] = setting;
  return path;
}

function hashPath(bytes32[] memory path) pure returns (bytes32) {
  return keccak256(abi.encode(path));
}

struct Setting {
  // Setting path identifier, the key. Can also encode array values.
  // Eg: [b32str("hardFork")]
  bytes32[] path;

  // Pacemaker block time where the change activates in seconds.
  // Code activates on the first block.timestamp > releaseTime.
  uint64 releaseTime;

  // Optional bbi-encoded bytes value. Can contain any structure.
  // Value encoding should be supported by the runtime at that future block height.
  // Eg: codebase url hints
  bytes value;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.14;

interface SettingValidatorV1 {
  function isValidUnlockedSetting(bytes32[] calldata path, uint64 releaseTime, bytes calldata value) external view returns (bool);
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