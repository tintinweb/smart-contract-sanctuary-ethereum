// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";

struct ContractConfiguration {
  uint256 firstNumber;
  uint256 secondNumber;
  uint256 thirdNumber;
  uint256 fourthNumber;
  uint256 fifthNumber;
  uint256 sixthNumber;
  address ourAddress;
}

/**
  @title ArgTest
  @author fellow human
  @notice it's an ArgTest
*/
contract ArgTest is Ownable {

  ContractConfiguration public config;

  uint256 public immutable firstNumber;
  uint256 public immutable secondNumber;
  uint256 public immutable thirdNumber;
  uint256 public immutable fourthNumber;
  uint256 public immutable fifthNumber;
  uint256 public immutable sixthNumber;
  address public immutable ourAddress;

  constructor(ContractConfiguration memory _config) {
    config = _config;

    firstNumber = _config.firstNumber;
    secondNumber = _config.secondNumber;
    thirdNumber = _config.thirdNumber;
    fourthNumber = _config.fourthNumber;
    fifthNumber = _config.fifthNumber;
    sixthNumber = _config.sixthNumber;
    ourAddress = _config.ourAddress;
  }

  /// @notice it returns a number
  /// @return the number
  function aNumber() external view returns (uint256) {

  }

  /// @dev I am an internal thing
  function internalThing() internal pure returns (string memory) {
    return "lol";
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