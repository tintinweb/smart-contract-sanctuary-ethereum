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

// contracts/Box.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title A box containing some value
/// @author Mr Tumeric A. Gardner
/// @notice You can use this contract for only the most basic simulation
/// @dev All function calls are currently implemented without..
/// @custom:experimental This is an experimental contract.
contract Box is Ownable {
  string private value;
  bool public shouldRevert;
  mapping (string => uint) public testMapping;

  // Emitted when the stored value changes
  event ValueChanged(string newValue);
  event ShouldRevertChanged(bool newValue);

  constructor(string memory initialValue) {
    value = initialValue;
    shouldRevert = false;
  }

  function switchShouldRevert() public onlyOwner {
    shouldRevert = !shouldRevert;
    emit ShouldRevertChanged(shouldRevert);
  }

  function updateMapping(string memory _testKey, uint _testVal) public {
    testMapping[_testKey] = _testVal;
  }

  function getMapping(string memory _testKey) public view returns (uint) {
    return testMapping[_testKey];
  }

  function testRevert() pure public {
    require(false, "Call has been reverted!");
  }

  /// @notice Allow to change the value stored in the Box
  /// @notice Only the Owner can call this function
  /// @dev The Alexandr N. Tetearing algorithm could increase precision
  /// @param newValue The new value to be stored in the box state
  function changeValueCouldRevert(string calldata newValue) public {
    require(!shouldRevert, "Set to revert");
    value = newValue;
    emit ValueChanged(newValue);
  }

  /// @notice Allow to change the value stored in the Box
  /// @notice Only the Owner can call this function
  /// @dev The Alexandr N. Tetearing algorithm could increase precision
  /// @param newValue The new value to be stored in the box state
  function changeValueOwner(string calldata newValue) public onlyOwner {
    value = newValue;
    emit ValueChanged(newValue);
  }

  /// @notice Allow to simulate changing the value stored in the Box
  /// @dev The Alexandr N. Tetearing algorithm could increase precision
  /// @param newValue The new value to be stored in the box state
  /// @custom:event-only This function simply emit an event.
  function changeValueDryRun(string calldata newValue) public {
    emit ValueChanged(newValue);
  }

  /// @notice Returns current value in the box.
  /// @dev Returns only a string.
  /// @return The current value of in the box state
  function getValue() public view returns (string memory) {
    require(!shouldRevert, "Set to revert");
    return value;
  }

  /// @notice Returns current version of the contract.
  /// @dev Returns only a string.
  /// @return The current version of the contract
  function getVersion() virtual public pure returns (string memory) {
    return "V1";
  }
}