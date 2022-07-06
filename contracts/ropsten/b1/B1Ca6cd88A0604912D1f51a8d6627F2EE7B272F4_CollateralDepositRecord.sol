// SPDX-License-Identifier: UNLICENSED
import "./interfaces/ICollateralDepositRecord.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

pragma solidity =0.8.7;

contract CollateralDepositRecord is ICollateralDepositRecord, Ownable {
  uint256 private _globalDepositCap;
  uint256 private _globalDepositAmount;
  uint256 private _accountDepositCap;
  mapping(address => uint256) private _accountToNetDeposit;
  mapping(address => bool) private _allowedHooks;

  modifier onlyAllowedHooks() {
    require(_allowedHooks[msg.sender], "Caller not allowed");
    _;
  }

  constructor(uint256 _newGlobalDepositCap, uint256 _newAccountDepositCap) {
    _globalDepositCap = _newGlobalDepositCap;
    _accountDepositCap = _newAccountDepositCap;
  }

  function recordDeposit(address _sender, uint256 _amount) external override onlyAllowedHooks {
    require(_amount + _globalDepositAmount <= _globalDepositCap, "Global deposit cap exceeded");
    require(
      _amount + _accountToNetDeposit[_sender] <= _accountDepositCap,
      "Account deposit cap exceeded"
    );
    _globalDepositAmount += _amount;
    _accountToNetDeposit[_sender] += _amount;
  }

  function recordWithdrawal(address _sender, uint256 _amount) external override onlyAllowedHooks {
    if (_globalDepositAmount > _amount) {
      _globalDepositAmount -= _amount;
    } else {
      _globalDepositAmount = 0;
    }
    if (_accountToNetDeposit[_sender] > _amount) {
      _accountToNetDeposit[_sender] -= _amount;
    } else {
      _accountToNetDeposit[_sender] = 0;
    }
  }

  function setGlobalDepositCap(uint256 _newGlobalDepositCap) external override onlyOwner {
    _globalDepositCap = _newGlobalDepositCap;
    emit GlobalDepositCapChanged(_globalDepositCap);
  }

  function setAccountDepositCap(uint256 _newAccountDepositCap) external override onlyOwner {
    _accountDepositCap = _newAccountDepositCap;
    emit AccountDepositCapChanged(_newAccountDepositCap);
  }

  function setAllowedHook(address _hook, bool _allowed) external override onlyOwner {
    _allowedHooks[_hook] = _allowed;
    emit AllowedHooksChanged(_hook, _allowed);
  }

  function getGlobalDepositCap() external view override returns (uint256) {
    return _globalDepositCap;
  }

  function getGlobalDepositAmount() external view override returns (uint256) {
    return _globalDepositAmount;
  }

  function getAccountDepositCap() external view override returns (uint256) {
    return _accountDepositCap;
  }

  function getNetDeposit(address _account) external view override returns (uint256) {
    return _accountToNetDeposit[_account];
  }

  function isHookAllowed(address _hook) external view override returns (bool) {
    return _allowedHooks[_hook];
  }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.7;

/// @notice Enforces Collateral deposit caps.
interface ICollateralDepositRecord {
  /// @dev Emitted via `setGlobalDepositCap()`.
  /// @param amount New global deposit cap
  event GlobalDepositCapChanged(uint256 amount);

  /// @dev Emitted via `setAccountDepositCap()`.
  /// @param amount New account deposit cap
  event AccountDepositCapChanged(uint256 amount);

  /// @dev Emitted via `setAllowedHook()`.
  /// @param hook Hook with changed permissions
  /// @param allowed Whether the hook is allowed
  event AllowedHooksChanged(address hook, bool allowed);

  /**
   * @dev This function will be called by a Collateral hook before the fee
   * is subtracted from the initial `amount` passed in.
   *
   * Only callable by allowed hooks.
   *
   * Reverts if the incoming deposit brings either total over their
   * respective caps.
   *
   * `finalAmount` is added to both the global and account-specific
   * deposit totals.
   * @param sender The account making the Collateral deposit
   * @param finalAmount The amount actually deposited by the user
   */
  function recordDeposit(address sender, uint256 finalAmount) external;

  /**
   * @notice Called by a Collateral hook before the fee is subtracted from
   * the amount withdrawn from the Strategy.
   * @dev `finalAmount` is subtracted from both the global and
   * account-specific deposit totals.
   *
   * Only callable by allowed hooks.
   * @param sender The account making the Collateral withdrawal
   * @param finalAmount The amount actually withdrawn by the user
   */
  function recordWithdrawal(address sender, uint256 finalAmount) external;

  /**
   * @notice Sets the global cap on assets backing Collateral in circulation.
   * @dev Only callable by owner().
   * @param newGlobalDepositCap The new global deposit cap
   */
  function setGlobalDepositCap(uint256 newGlobalDepositCap) external;

  /**
   * @notice Sets the cap on net Base Token deposits per user.
   * @dev Only callable by owner().
   * @param newAccountDepositCap The new account deposit cap
   */
  function setAccountDepositCap(uint256 newAccountDepositCap) external;

  /**
   * @notice Sets if a contract is allowed to record deposits
   * and withdrawals.
   * @dev Only callable by owner().
   * @param hook The contract address
   * @param allowed Whether or not the contract will be allowed
   */
  function setAllowedHook(address hook, bool allowed) external;

  /**
   * @notice Gets the maximum Base Token amount that is allowed to be
   * deposited (net of withdrawals).
   * @dev Deposits are not allowed if `globalDepositAmount` exceeds
   * the `globalDepositCap`.
   * @return Base Token amount
   */
  function getGlobalDepositCap() external view returns (uint256);

  /// @return Net total of Base Token deposited.
  function getGlobalDepositAmount() external view returns (uint256);

  /**
   * @dev An account will not be allowed to deposit if their net deposits
   * exceed `accountDepositCap`.
   * @return The cap on net Base Token deposits per user
   */
  function getAccountDepositCap() external view returns (uint256);

  /**
   * @param account The account to retrieve net deposits for
   * @return The net total amount of Base Token deposited by a user
   */
  function getNetDeposit(address account) external view returns (uint256);

  /**
   * @notice Returns whether the contract is allowed to record deposits and
   * withdrawals.
   * @param hook The contract to retrieve allowed status for
   * @return Whether the contract is allowed
   */
  function isHookAllowed(address hook) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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