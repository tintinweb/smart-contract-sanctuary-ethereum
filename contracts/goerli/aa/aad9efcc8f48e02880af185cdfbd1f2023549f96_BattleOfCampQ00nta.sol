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

// SPDX-License-Identifier: UNLICENSED

import "openzeppelin/contracts/access/Ownable.sol";

pragma solidity ^0.8.17;

error NeedAHero();
error FailedToWithdraw();
error WrongValueSent();
error WarCryNotAvailable();
error CannotAttackYet();
error EpochNotActive();

contract BattleOfCampQ00nta is Ownable {
  address public KING_Q00NTA = 0xAf874Dd27A310124d96B15BAC55ece568d063bF9;
  address public SER_SHINESALOT = 0x30D167662cEfFB8708fc82E375d0785DF78D02Ba;

  LastCries public lastCries;
  PointTotals public pointTotals;

  bool public epochActive;

  struct LastCries {
    uint128 q00tants;
    uint128 q00nicorns;
  }

  struct PointTotals {
    uint32 q00tants;
    uint32 q00nicorns;
  }

  mapping(address => Balances) public balances;

  struct Balances {
    uint32 q00nicornBalance;
    uint32 q00tantBalance;
    uint32 reinforcementBalance;
    uint32 lastAttack;
    uint64 cost;
    uint128 spent;
  }

  function warCry() external {
    if (msg.sender != KING_Q00NTA && msg.sender != SER_SHINESALOT) revert NeedAHero();
    if (!epochActive) revert EpochNotActive();

    if (msg.sender == KING_Q00NTA && lastCries.q00tants < block.timestamp - 1 days) {
      lastCries.q00tants = uint128(block.timestamp);
    } else if (msg.sender == SER_SHINESALOT && lastCries.q00nicorns < block.timestamp - 1 days) {
      lastCries.q00nicorns = uint128(block.timestamp);
    } else {
      revert WarCryNotAvailable();
    }
  }

  function attackWithCorns() external payable {
    attack(false);
  }

  function attackWithQ00tants() external payable {
    attack(true);
  }

  function attack(bool isQ00tant) internal {
    if (msg.value < balances[msg.sender].cost) revert WrongValueSent();
    if (!canAttack(msg.sender)) revert CannotAttackYet();
    if (!epochActive) revert EpochNotActive();

    if (isQ00tant) {
      pointTotals.q00tants += totalPower();
    } else {
      pointTotals.q00nicorns += totalPower();
    }

    if (!isHyped(isQ00tant)) balances[msg.sender].cost = balances[msg.sender].cost * 2;

    balances[msg.sender].lastAttack = uint32(block.timestamp);
    balances[msg.sender].spent += uint128(msg.value);
  }

  function isHyped(bool isQ00tant) public view returns (bool) {
    uint128 lastCry = isQ00tant ? lastCries.q00tants : lastCries.q00nicorns;

    return lastCry > block.timestamp - 2 hours;
  }

  function totalPower() public view returns (uint32) {
    uint32 reinforcementPower = balances[msg.sender].reinforcementBalance * 10;
    return balances[msg.sender].q00tantBalance + balances[msg.sender].q00nicornBalance + reinforcementPower;
  }

  function canAttack(address attacker) internal view returns (bool) {
    return epochActive && timeSinceLastAttack(attacker) >= 55 minutes;
  }

  function timeSinceLastAttack(address attacker) public view returns (uint256) {
    return block.timestamp - balances[attacker].lastAttack;
  }

  function setQ00nicornBalances(address[] calldata _addresses, uint32[] calldata _counts) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      unchecked {
        balances[_addresses[i]].q00nicornBalance += _counts[i];
        balances[_addresses[i]].cost = 0.1 ether;
        ++i;
      }
    }
  }

  function setQ00tantBalances(address[] calldata _addresses, uint32[] calldata _counts) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      unchecked {
        balances[_addresses[i]].q00tantBalance += _counts[i];
        balances[_addresses[i]].cost = 0.1 ether;
        ++i;
      }
    }
  }

  function setReinforcementBalances(address[] calldata _addresses, uint32[] calldata _counts) external onlyOwner {
    for (uint256 i = 0; i < _addresses.length;) {
      unchecked {
        balances[_addresses[i]].reinforcementBalance += _counts[i];
        balances[_addresses[i]].cost = 0.1 ether;
        ++i;
      }
    }
  }

  function withdraw() external {
    uint256 amount = balances[msg.sender].spent;
    balances[msg.sender].spent = 0;

    (bool success, ) = msg.sender.call{ value: amount }("");
    if (!success) revert FailedToWithdraw();
  }

  function flipState() external onlyOwner {
    epochActive = !epochActive;
  }
}