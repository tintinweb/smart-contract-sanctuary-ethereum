// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./libraries/LockedBalance.sol";

error VOXETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
error VOXETH_Cannot_Deposit_To_Address_Zero();
error VOXETH_Cannot_Deposit_To_VOXETH();
error VOXETH_Cannot_Withdraw_To_Address_Zero();
error VOXETH_Cannot_Withdraw_To_VOXETH();
error VOXETH_Cannot_Withdraw_To_Market();
error VOXETH_Escrow_Expired();
error VOXETH_Escrow_Not_Found();
error VOXETH_Expiration_Too_Far_In_Future();
/// @param amount The current allowed amount the spender is authorized to transact for this account.
error VOXETH_Insufficient_Allowance(uint256 amount);
/// @param amount The current available (unlocked) token count of this account.
error VOXETH_Insufficient_Available_Funds(uint256 amount);
/// @param amount The current number of tokens this account has for the given lockup expiry bucket.
error VOXETH_Insufficient_Escrow(uint256 amount);
error VOXETH_Invalid_Lockup_Duration();
error VOXETH_Market_Must_Be_A_Contract();
error VOXETH_Must_Deposit_Non_Zero_Amount();
error VOXETH_Must_Lockup_Non_Zero_Amount();
error VOXETH_No_Funds_To_Withdraw();
error VOXETH_Only_FND_Market_Allowed();
error VOXETH_Too_Much_ETH_Provided();
error VOXETH_Transfer_To_Address_Zero_Not_Allowed();
error VOXETH_Transfer_To_VOXETH_Not_Allowed();

/**
 * @title An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 * @notice VOXETH is an [ERC-20 token](https://eips.ethereum.org/EIPS/eip-20) modeled after
 * [WETH9](https://etherscan.io/address/0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2#code).
 * It has the added ability to lockup tokens for 24-25 hours - during this time they may not be
 * transferred or withdrawn, except by our market contract which requested the lockup in the first place.
 * @dev Locked balances are rounded up to the next hour.
 * They are grouped by the expiration time of the lockup into what we refer to as a lockup "bucket".
 * At any time there may be up to 25 buckets but never more than that which prevents loops from exhausting gas limits.
 * VOXETH is an upgradeable contract. 
 * Overtime we will progressively decentralize, potentially giving upgrade permissions
 * to a DAO ownership or removing the permissions entirely.
 */
contract VOXETH {
  using AddressUpgradeable for address payable;
  using LockedBalance for LockedBalance.Lockups;
  using Math for uint256;

  /// @notice Tracks an account's info.
  struct AccountInfo {
    /// @notice The number of tokens which have been unlocked already.
    uint96 freedBalance;
    /// @notice The first applicable lockup bucket for this account.
    uint32 lockupStartIndex;
    /// @notice Stores up to 25 buckets of locked balance for a user, one per hour.
    LockedBalance.Lockups lockups;
    /// @notice Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  /// @notice Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The VoxToVFX market contract with permissions to manage lockups.
  address payable private immutable voxToVFXMarket;

  // ERC-20 metadata fields
  /**
   * @notice The number of decimals the token uses.
   * @dev This method can be used to improve usability when displaying token amounts, but all interactions
   * with this contract use whole amounts not considering decimals.
   * @return 18
   */
  uint8 public constant decimals = 18;
  /**
   * @notice The name of the token.
   * @return VoxToVFX ETH
   */
  string public constant name = "VoxToVFXETH";
  /**
   * @notice The symbol of the token.
   * @return VOXETH
   */
  string public constant symbol = "VOXETH";

  // ERC-20 events
  /**
   * @notice Emitted when the allowance for a spender account is updated.
   * @param from The account the spender is authorized to transact for.
   * @param spender The account with permissions to manage VOXETH tokens for the `from` account.
   * @param amount The max amount of tokens which can be spent by the `spender` account.
   */
  event Approval(address indexed from, address indexed spender, uint256 amount);
  /**
   * @notice Emitted when a transfer of VOXETH tokens is made from one account to another.
   * @param from The account which is sending VOXETH tokens.
   * @param to The account which is receiving VOXETH tokens.
   * @param amount The number of VOXETH tokens which were sent.
   */
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  /**
   * @notice Emitted when VOXETH tokens are locked up by the VoxToVFX market for 24-25 hours
   * and may include newly deposited ETH which is added to the account's total VOXETH balance.
   * @param account The account which has access to the VOXETH after the `expiration`.
   * @param expiration The time at which the `from` account will have access to the locked VOXETH.
   * @param amount The number of VOXETH tokens which where locked up.
   * @param valueDeposited The amount of ETH added to their account's total VOXETH balance,
   * this may be lower than `amount` if available VOXETH was leveraged.
   */
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount, uint256 valueDeposited);
  /**
   * @notice Emitted when VOXETH tokens are unlocked by the VoxToVFX market.
   * @dev This event will not be emitted when lockups expire,
   * it's only for tokens which are unlocked before their expiry.
   * @param account The account which had locked VOXETH freed before expiration.
   * @param expiration The time this balance was originally scheduled to be unlocked.
   * @param amount The number of VOXETH tokens which were unlocked.
   */
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);
  /**
   * @notice Emitted when ETH is withdrawn from a user's account.
   * @dev This may be triggered by the user, an approved operator, or the VoxToVFX market.
   * @param from The account from which VOXETH was deducted in order to send the ETH.
   * @param to The address the ETH was sent to.
   * @param amount The number of tokens which were deducted from the user's VOXETH balance and transferred as ETH.
   */
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);

  /// @dev Allows the VoxToVFX market permission to manage lockups for a user.
  modifier onlyVoxToVFXMarket() {
    if (msg.sender != voxToVFXMarket) {
      revert VOXETH_Only_FND_Market_Allowed();
    }
    _;
  }

  /**
   * @notice Set immutable variables for the implementation contract.
   * @dev Using immutable instead of constants allows us to use different values on testnet.
   * @param _voxToVFXMarket The address of the VoxToVFX NFT marketplace.
   * @param _lockupDuration The minimum length of time to lockup tokens for when `BalanceLocked`, in seconds.
   */
  constructor(address payable _voxToVFXMarket, uint256 _lockupDuration) {
    if (!_voxToVFXMarket.isContract()) {
      revert VOXETH_Market_Must_Be_A_Contract();
    }
    voxToVFXMarket = _voxToVFXMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert VOXETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH (via `msg.value`) to the contract performs a `deposit` into the user's account.
   */
  receive() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Approves a `spender` as an operator with permissions to transfer from your account.
   * @dev To prevent attack vectors, clients SHOULD make sure to create user interfaces in such a way
   * that they set the allowance first to 0 before setting it to another value for the same spender.
   * We will add support for `increaseAllowance` in the future.
   * @param spender The address of the operator account that has approval to spend funds
   * from the `msg.sender`'s account.
   * @param amount The max number of VOXETH tokens from `msg.sender`'s account that this spender is
   * allowed to transact with.
   * @return success Always true.
   */
  function approve(address spender, uint256 amount) external returns (bool success) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and receive the equivalent amount in VOXETH tokens.
   * These tokens are not subject to any lockup period.
   */
  function deposit() external payable {
    depositFor(msg.sender);
  }

  /**
   * @notice Deposit ETH (via `msg.value`) and credit the `account` provided with the equivalent amount 
   * in VOXETH tokens.
   * These tokens are not subject to any lockup period.
   * @dev This may be used by the VoxToVFX market to credit a user's account with VOXETH tokens.
   * @param account The account to credit with VOXETH tokens.
   */
  function depositFor(address account) public payable {
    if (msg.value == 0) {
      revert VOXETH_Must_Deposit_Non_Zero_Amount();
    } else if (account == address(0)) {
      revert VOXETH_Cannot_Deposit_To_Address_Zero();
    } else if (account == address(this)) {
      revert VOXETH_Cannot_Deposit_To_VOXETH();
    }
    AccountInfo storage accountInfo = accountToInfo[account];
    // ETH value cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(msg.value);
    }
    emit Transfer(address(0), account, msg.value);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup and then create a new lockup, potentially for a different account.
   * @dev Used by the market when an offer for an NFT is increased.
   * This may be for a single account (increasing their offer)
   * or two different accounts (outbidding someone elses offer).
   * @param unlockFrom The account whose lockup is to be removed.
   * @param unlockExpiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param unlockAmount The number of tokens to be unlocked from `unlockFrom`'s account.
   * This will revert if the tokens were previously unlocked.
   * @param lockupFor The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param lockupAmount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `lockupAmount` and any delta will be taken from the account's available VOXETH balance.
   * @return expiration The expiration timestamp for the VOXETH tokens that were locked.
   */
  function marketChangeLockup(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address lockupFor,
    uint256 lockupAmount
  ) external payable onlyVoxToVFXMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketLockupFor(lockupFor, lockupAmount);
  }

  /**
   * @notice Used by the market contract only:
   * Lockup an account's VOXETH tokens for 24-25 hours.
   * @dev Used by the market when a new offer for an NFT is made.
   * @param account The account to which the funds are to be deposited for (via the `msg.value`) and tokens locked up.
   * @param amount The number of tokens to be locked up for the `lockupFor`'s account.
   * `msg.value` must be <= `amount` and any delta will be taken from the account's available VOXETH balance.
   * @return expiration The expiration timestamp for the VOXETH tokens that were locked.
   */
  function marketLockupFor(address account, uint256 amount)
    external
    payable
    onlyVoxToVFXMarket
    returns (uint256 expiration)
  {
    return _marketLockupFor(account, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Remove an account's lockup, making the VOXETH tokens available for transfer or withdrawal.
   * @dev Used by the market when an offer is invalidated, which occurs when an auction for the same NFT
   * receives its first bid or the buyer purchased the NFT another way, such as with `buy`.
   * @param account The account whose lockup is to be unlocked.
   * @param expiration The original lockup expiration for the tokens to be unlocked unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked from `account`.
   * This will revert if the tokens were previously unlocked.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyVoxToVFXMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes tokens from the user's available balance and returns ETH to the caller.
   * @dev Used by the market when a user's available VOXETH balance is used to make a purchase
   * including accepting a buy price or a private sale, or placing a bid in an auction.
   * @param from The account whose available balance is to be withdrawn from.
   * @param amount The number of tokens to be deducted from `unlockFrom`'s available balance and transferred as ETH.
   * This will revert if the tokens were previously unlocked.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyVoxToVFXMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract only:
   * Removes a lockup from the user's account and then returns ETH to the caller.
   * @dev Used by the market to extract unexpired funds as ETH to distribute for
   * a sale when the user's offer is accepted.
   * @param account The account whose lockup is to be removed.
   * @param expiration The original lockup expiration for the tokens to be unlocked.
   * This will revert if the lockup has already expired.
   * @param amount The number of tokens to be unlocked and withdrawn as ETH.
   */
  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyVoxToVFXMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Transfers an amount from your account.
   * @param to The address of the account which the tokens are transferred from.
   * @param amount The number of VOXETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds).
   */
  function transfer(address to, uint256 amount) external returns (bool success) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified if the `msg.sender` has approval.
   * @param from The address from which the available tokens are transferred from.
   * @param to The address to which the tokens are to be transferred.
   * @param amount The number of VOXETH tokens to be transferred.
   * @return success Always true (reverts if insufficient funds or not approved).
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool success) {
    if (to == address(0)) {
      revert VOXETH_Transfer_To_Address_Zero_Not_Allowed();
    } else if (to == address(this)) {
      revert VOXETH_Transfer_To_VOXETH_Not_Allowed();
    }
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(fromAccountInfo, amount, from);
    }
    _deductBalanceFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      toAccountInfo.freedBalance += uint96(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @notice Withdraw all tokens available in your account and receive ETH.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    if (amount == 0) {
      revert VOXETH_No_Funds_To_Withdraw();
    }
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified number of tokens from the `from` accounts available balance
   * and send ETH to the destination address, if the `msg.sender` has approval.
   * @param from The address from which the available funds are to be withdrawn.
   * @param to The destination address for the ETH to be transferred to.
   * @param amount The number of tokens to be withdrawn and transferred as ETH.
   */
  function withdrawFrom(
    address from,
    address payable to,
    uint256 amount
  ) external {
    if (amount == 0) {
      revert VOXETH_No_Funds_To_Withdraw();
    } else if (to == address(0)) {
      revert VOXETH_Cannot_Withdraw_To_Address_Zero();
    } else if (to == address(this)) {
      revert VOXETH_Cannot_Withdraw_To_VOXETH();
    } else if (to == address(voxToVFXMarket)) {
      revert VOXETH_Cannot_Withdraw_To_Market();
    }

    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowanceFrom(accountInfo, amount, from);
    }
    _deductBalanceFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowanceFrom(
    AccountInfo storage accountInfo,
    uint256 amount,
    address from
  ) private {
    uint256 spenderAllowance = accountInfo.allowance[msg.sender];
    if (spenderAllowance != type(uint256).max) {
      if (spenderAllowance < amount) {
        revert VOXETH_Insufficient_Allowance(spenderAllowance);
      }
      // The check above ensures allowance cannot underflow.
      unchecked {
        spenderAllowance -= amount;
      }
      accountInfo.allowance[msg.sender] = spenderAllowance;
      emit Approval(from, msg.sender, spenderAllowance);
    }
  }

  /**
   * @dev Removes an amount from the account's available VOXETH balance.
   */
  function _deductBalanceFrom(AccountInfo storage accountInfo, uint256 amount) private {
    uint96 freedBalance = accountInfo.freedBalance;
    // Free from escrow in order to consider any expired escrow balance
    if (freedBalance < amount) {
      revert VOXETH_Insufficient_Available_Funds(freedBalance);
    }
    // The check above ensures balance cannot underflow.
    unchecked {
      accountInfo.freedBalance = freedBalance - uint96(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   * Sets the next bucket that hasn't expired as the new start index.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    // If the first bucket (the oldest) is empty or not yet expired, no change to escrowStartIndex is required
    if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
      return accountInfo;
    }

    while (true) {
      // Total ETH cannot realistically overflow 96 bits.
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        accountInfo.lockups.del(escrowIndex);
        // Escrow index cannot overflow 32 bits.
        escrow = accountInfo.lockups.get(escrowIndex + 1);
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      // Escrow index cannot overflow 32 bits.
      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        ++escrowIndex;
      }

      // If the next bucket is expired, that's the new start index
      if (escrow.expiration >= block.timestamp) {
        break;
      }
    }

    // Escrow index cannot overflow 32 bits.
    unchecked {
      accountInfo.lockupStartIndex = uint32(escrowIndex);
    }
    return accountInfo;
  }

  /**
   * @notice Lockup an account's VOXETH tokens for 24-25 hours.
   */
  /* solhint-disable-next-line code-complexity */
  function _marketLockupFor(address account, uint256 amount) private returns (uint256 expiration) {
    if (account == address(0)) {
      revert VOXETH_Cannot_Deposit_For_Lockup_With_Address_Zero();
    }
    if (amount == 0) {
      revert VOXETH_Must_Lockup_Non_Zero_Amount();
    }

    // Block timestamp in seconds is small enough to never overflow
    unchecked {
      // Lockup expires after 24 hours, rounded up to the next hour for a total of [24-25) hours
      expiration = lockupDuration + block.timestamp.ceilDiv(lockupInterval) * lockupInterval;
    }

    // Update available escrow
    // Always free from escrow to ensure the max bucket count is <= 25
    AccountInfo storage accountInfo = _freeFromEscrow(account);
    if (msg.value < amount) {
      unchecked {
        // The if check above prevents an underflow here
        _deductBalanceFrom(accountInfo, amount - msg.value);
      }
    } else if (msg.value != amount) {
      // There's no reason to send msg.value more than the amount being locked up
      revert VOXETH_Too_Much_ETH_Provided();
    }

    // Add to locked escrow
    unchecked {
      // The number of buckets is always < 256 bits.
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          if (expiration > type(uint32).max) {
            revert VOXETH_Expiration_Too_Far_In_Future();
          }
          // Amount (ETH) will always be < 96 bits.
          accountInfo.lockups.set(escrowIndex, expiration, amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 96 bits.
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount, msg.value);
  }

  /**
   * @notice Remove an account's lockup, making the VOXETH tokens available for transfer or withdrawal.
   */
  function _marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 96 bits.
    unchecked {
      accountInfo.freedBalance += uint96(amount);
    }
  }

  /**
   * @dev Removes the specified amount from locked escrow, potentially before its expiration.
   */
  /* solhint-disable-next-line code-complexity */
  function _removeFromLockedBalance(
    address account,
    uint256 expiration,
    uint256 amount
  ) private returns (AccountInfo storage) {
    if (expiration < block.timestamp) {
      revert VOXETH_Escrow_Expired();
    }

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        accountInfo.lockups.del(escrowIndex);

        // Bump the escrow start index unless it's the last one
        unchecked {
          if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
            // The number of escrow buckets will never overflow 32 bits.
            ++accountInfo.lockupStartIndex;
          }
        }
      } else {
        if (escrow.totalAmount < amount) {
          revert VOXETH_Insufficient_Escrow(escrow.totalAmount);
        }
        // The require above ensures balance will not underflow.
        unchecked {
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 32 bits.
        unchecked {
          ++escrowIndex;
        }
        escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == expiration) {
          if (amount > escrow.totalAmount) {
            revert VOXETH_Insufficient_Escrow(escrow.totalAmount);
          }
          // The require above ensures balance will not underflow.
          unchecked {
            accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        if (escrow.expiration == 0) {
          revert VOXETH_Escrow_Not_Found();
        }
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to transact from the `account`'s balance.
   * @param account The owner of the funds.
   * @param operator The address with approval to spend from the `account`'s balance.
   * @return amount The number of tokens the `operator` is still allowed to transact with.
   */
  function allowance(address account, address operator) external view returns (uint256 amount) {
    AccountInfo storage accountInfo = accountToInfo[account];
    amount = accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account which is available to transfer or withdraw.
   * @dev This will automatically increase as soon as locked tokens reach their expiry date.
   * @param account The account to query the available balance of.
   * @return balance The available balance of the account.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Gets the VoxToVFX market address which has permissions to manage lockups.
   * @return market The VoxToVFX market contract address.
   */
  function getVoxToVFXMarket() external view returns (address market) {
    market = voxToVFXMarket;
  }

  /**
   * @notice Returns the balance and each outstanding (unexpired) lockup bucket for an account, grouped by expiry.
   * @dev `expires.length` == `amounts.length`
   * and `amounts[i]` is the number of tokens which will expire at `expires[i]`.
   * The results returned are sorted by expiry, with the earliest expiry date first.
   * @param account The account to query the locked balance of.
   * @return expiries The time at which each outstanding lockup bucket expires.
   * @return amounts The number of VOXETH tokens which will expire for each outstanding lockup bucket.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
          // Lockup count will never overflow 256 bits.
          ++lockedCount;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits.
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount != 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          ++i;
        }
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked VOXETH tokens.
   * @dev Use `balanceOf` to get the number of tokens available for transfer or withdrawal.
   * @param account The account to query the total balance of.
   * @return balance The total VOXETH balance tracked for this account.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits.
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; ++escrowIndex) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   * @return supply The total amount of ETH locked in this contract.
   * @dev It is possible for this to diverge from the total token count by transferring ETH on self destruct
   * but this is on-par with the WETH implementation and done for gas savings.
   */
  function totalSupply() external view returns (uint256 supply) {
    return address(this).balance;
  }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @title Library that handles locked balances efficiently using bit packing.
 */
library LockedBalance {
  /// @dev Tracks an account's total lockup per expiration time.
  struct Lockup {
    uint32 expiration;
    uint96 totalAmount;
  }

  struct Lockups {
    /// @dev Mapping from key to lockups.
    /// i) A key represents 2 lockups. The key for a lockup is `index / 2`.
    ///     For instance, elements with index 25 and 24 would map to the same key.
    /// ii) The `value` for the `key` is split into two 128bits which are used to store the metadata for a lockup.
    mapping(uint256 => uint256) lockups;
  }

  // Masks used to split a uint256 into two equal pieces which represent two individual Lockups.
  uint256 private constant last128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant first128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

  // Masks used to retrieve or set the totalAmount value of a single Lockup.
  uint256 private constant firstAmountBitsMask = 0xFFFFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant secondAmountBitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

  /**
   * @notice Clears the lockup at the index.
   */
  function del(Lockups storage lockups, uint256 index) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask);
      }
    }
  }

  /**
   * @notice Sets the Lockup at the provided index.
   */
  function set(
    Lockups storage lockups,
    uint256 index,
    uint256 expiration,
    uint256 totalAmount
  ) internal {
    unchecked {
      uint256 lockedBalanceBits = totalAmount | (expiration << 96);
      if (index % 2 == 0) {
        // set first 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask) | (lockedBalanceBits << 128);
      } else {
        // set last 128 bits.
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask) | lockedBalanceBits;
      }
    }
  }

  /**
   * @notice Sets only the totalAmount for a lockup at the index.
   */
  function setTotalAmount(
    Lockups storage lockups,
    uint256 index,
    uint256 totalAmount
  ) internal {
    unchecked {
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & firstAmountBitsMask) | (totalAmount << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & secondAmountBitsMask) | totalAmount;
      }
    }
  }

  /**
   * @notice Returns the Lockup at the provided index.
   * @dev To get the lockup stored in the *first* 128 bits (first slot/lockup):
   *       - we remove the last 128 bits (done by >> 128)
   *      To get the lockup stored in the *last* 128 bits (second slot/lockup):
   *       - we take the last 128 bits (done by % (2**128))
   *      Once the lockup is obtained:
   *       - get `expiration` by peaking at the first 32 bits (done by >> 96)
   *       - get `totalAmount` by peaking at the last 96 bits (done by % (2**96))
   */
  function get(Lockups storage lockups, uint256 index) internal view returns (Lockup memory balance) {
    unchecked {
      uint256 lockupMetadata = lockups.lockups[index / 2];
      if (lockupMetadata == 0) {
        return balance;
      }
      uint128 lockedBalanceBits;
      if (index % 2 == 0) {
        // use first 128 bits.
        lockedBalanceBits = uint128(lockupMetadata >> 128);
      } else {
        // use last 128 bits.
        lockedBalanceBits = uint128(lockupMetadata % (2**128));
      }
      // unpack the bits to retrieve the Lockup.
      balance.expiration = uint32(lockedBalanceBits >> 96);
      balance.totalAmount = uint96(lockedBalanceBits % (2**96));
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}