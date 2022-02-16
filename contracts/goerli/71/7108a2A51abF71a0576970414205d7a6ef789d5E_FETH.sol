/*
  ･
   *　★
      ･ ｡
        　･　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
​
                      `                     .-:::::-.`              `-::---...```
                     `-:`               .:+ssssoooo++//:.`       .-/+shhhhhhhhhhhhhyyyssooo:
                    .--::.            .+ossso+/////++/:://-`   .////+shhhhhhhhhhhhhhhhhhhhhy
                  `-----::.         `/+////+++///+++/:--:/+/-  -////+shhhhhhhhhhhhhhhhhhhhhy
                 `------:::-`      `//-.``.-/+ooosso+:-.-/oso- -////+shhhhhhhhhhhhhhhhhhhhhy
                .--------:::-`     :+:.`  .-/osyyyyyyso++syhyo.-////+shhhhhhhhhhhhhhhhhhhhhy
              `-----------:::-.    +o+:-.-:/oyhhhhhhdhhhhhdddy:-////+shhhhhhhhhhhhhhhhhhhhhy
             .------------::::--  `oys+/::/+shhhhhhhdddddddddy/-////+shhhhhhhhhhhhhhhhhhhhhy
            .--------------:::::-` +ys+////+yhhhhhhhddddddddhy:-////+yhhhhhhhhhhhhhhhhhhhhhy
          `----------------::::::-`.ss+/:::+oyhhhhhhhhhhhhhhho`-////+shhhhhhhhhhhhhhhhhhhhhy
         .------------------:::::::.-so//::/+osyyyhhhhhhhhhys` -////+shhhhhhhhhhhhhhhhhhhhhy
       `.-------------------::/:::::..+o+////+oosssyyyyyyys+`  .////+shhhhhhhhhhhhhhhhhhhhhy
       .--------------------::/:::.`   -+o++++++oooosssss/.     `-//+shhhhhhhhhhhhhhhhhhhhyo
     .-------   ``````.......--`        `-/+ooooosso+/-`          `./++++///:::--...``hhhhyo
                                              `````
   *　
      ･ ｡
　　　　･　　ﾟ☆ ｡
  　　　 *　★ ﾟ･｡ *  ｡
          　　* ☆ ｡･ﾟ*.｡
      　　　ﾟ *.｡☆｡★　･
    *　　ﾟ｡·*･｡ ﾟ*
  　　　☆ﾟ･｡°*. ﾟ
　 ･ ﾟ*｡･ﾟ★｡
　　･ *ﾟ｡　　 *
　･ﾟ*｡★･
 ☆∴｡　*
･ ｡
*/

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IFethMarket.sol";
import "./libraries/LockedBalance.sol";

error FETH_Invalid_Lockup_Duration();
error FETH_Expiration_Too_Far_In_Future();
error FETH_Only_FND_Market_Allowed();
error FETH_No_Funds_To_Withdraw();
error FETH_Market_Must_Be_A_Contract();
error FETH_Transfer_To_Burn_Not_Allowed();
error FETH_Insufficient_Allowance(uint256 amount);
error FETH_Insufficient_Available_Funds(uint256 amount);
error FETH_Escrow_Expired();
error FETH_Insufficient_Escrow(uint256 amount);
error FETH_Can_Not_Deposit_For_Lockup_with_Address_Zero();
error FETH_Must_Deposit_Positive_Amount();
error FETH_Must_Deposit_Exact_Amount();
error FETH_Escrow_Not_Found();

/**
 * @notice An ERC-20 token which wraps ETH, potentially with a 1 day lockup period.
 */
contract FETH is IFethMarket {
  using AddressUpgradeable for address payable;
  using Math for uint256;
  using LockedBalance for LockedBalance.Lockups;
  /// @dev Tracks an account's info.
  struct AccountInfo {
    /// @dev The amount of ETH which has been unlocked already.
    uint96 freedBalance;
    /// @dev The first applicable lockup bucket for this account.
    uint32 lockupStartIndex;
    /// @dev Stores up to 25 buckets of locked balance for a user, one per hour.
    LockedBalance.Lockups lockups;
    /// @dev Returns the amount which a spender is still allowed to withdraw from this account.
    mapping(address => uint256) allowance;
  }

  // ERC-20 metadata fields
  string public constant name = "Foundation Wrapped Ether";
  string public constant symbol = "FETH";
  uint8 public constant decimals = 18;

  // Lockup configuration
  /// @notice The minimum lockup period in seconds.
  uint256 private immutable lockupDuration;
  /// @notice The interval to which lockup expiries are rounded, limiting the max number of outstanding lockup buckets.
  uint256 private immutable lockupInterval;

  /// @notice The Foundation market contract with permissions to manage lockups.
  address payable public immutable foundationMarket;

  /// @dev Stores per-account details.
  mapping(address => AccountInfo) private accountToInfo;

  // ERC-20 events
  event Approval(address indexed from, address indexed spender, uint256 amount);
  event Transfer(address indexed from, address indexed to, uint256 amount);

  // Custom events
  event ETHWithdrawn(address indexed from, address indexed to, uint256 amount);
  event BalanceLocked(address indexed account, uint256 indexed expiration, uint256 amount);
  event BalanceUnlocked(address indexed account, uint256 indexed expiration, uint256 amount);

  /// @dev Allows the Foundation market permission to manage lockups for a user.
  modifier onlyFoundationMarket() {
    if (msg.sender != foundationMarket) {
      revert FETH_Only_FND_Market_Allowed();
    }
    _;
  }

  constructor(address payable _foundationMarket, uint256 _lockupDuration) {
    if (!_foundationMarket.isContract()) {
      revert FETH_Market_Must_Be_A_Contract();
    }
    foundationMarket = _foundationMarket;
    lockupDuration = _lockupDuration;
    lockupInterval = _lockupDuration / 24;
    if (lockupInterval * 24 != _lockupDuration || _lockupDuration == 0) {
      revert FETH_Invalid_Lockup_Duration();
    }
  }

  /**
   * @notice Transferring ETH to the contract performs a deposit.
   */
  receive() external payable {
    deposit();
  }

  /**
   * @notice Deposit ETH and receive FETH which is not subject to any lockup period.
   */
  function deposit() public payable {
    AccountInfo storage accountInfo = accountToInfo[msg.sender];
    // ETH value cannot realistically overflow 96 bits
    unchecked {
      accountInfo.freedBalance += uint96(msg.value);
    }
    emit Transfer(address(0), msg.sender, msg.value);
  }

  /**
   * @notice Used by the market contract:
   * Adds funds to an account which are locked for a period of time.
   */
  function marketDepositFor(address account, uint256 amount)
    external
    payable
    onlyFoundationMarket
    returns (uint256 expiration)
  {
    return _marketDepositFor(account, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes available balance and returns ETH to the caller.
   */
  function marketWithdrawFrom(address from, uint256 amount) external onlyFoundationMarket {
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(from, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Removes an account's lockup and returns ETH to the caller.
   */
  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _removeFromLockedBalance(account, expiration, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(account, msg.sender, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup, making the ETH available.
   */
  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external onlyFoundationMarket {
    _marketUnlockFor(account, expiration, amount);
  }

  /**
   * @notice Used by the market contract:
   * Remove an account's lockup and deposit a new one, any surplus becomes available.
   */
  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable onlyFoundationMarket returns (uint256 expiration) {
    _marketUnlockFor(unlockFrom, unlockExpiration, unlockAmount);
    return _marketDepositFor(depositFor, depositAmount);
  }

  /**
   * @notice Withdraw all ETH available to your account.
   */
  function withdrawAvailableBalance() external {
    AccountInfo storage accountInfo = _freeFromEscrow(msg.sender);
    uint256 amount = accountInfo.freedBalance;
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    delete accountInfo.freedBalance;

    // With the external call after state changes, we do not need a nonReentrant guard
    payable(msg.sender).sendValue(amount);

    emit ETHWithdrawn(msg.sender, msg.sender, amount);
  }

  /**
   * @notice Withdraw the specified amount and sends ETH to the destination address.
   */
  function withdrawFrom(
    address from,
    address payable to,
    uint256 amount
  ) external {
    if (amount == 0) {
      revert FETH_No_Funds_To_Withdraw();
    }
    AccountInfo storage accountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(accountInfo, amount);
    }
    _deductFrom(accountInfo, amount);

    // With the external call after state changes, we do not need a nonReentrant guard
    to.sendValue(amount);

    emit ETHWithdrawn(from, to, amount);
  }

  /**
   * @notice Approves the spender to transfer from your account.
   */
  function approve(address spender, uint256 amount) external returns (bool) {
    accountToInfo[msg.sender].allowance[spender] = amount;
    emit Approval(msg.sender, spender, amount);
    return true;
  }

  /**
   * @notice Transfers an amount from your account.
   */
  function transfer(address to, uint256 amount) external returns (bool) {
    return transferFrom(msg.sender, to, amount);
  }

  /**
   * @notice Transfers an amount from the account specified.
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) public returns (bool) {
    if (to == address(0) || to == address(this)) {
      revert FETH_Transfer_To_Burn_Not_Allowed();
    }
    AccountInfo storage fromAccountInfo = _freeFromEscrow(from);
    if (from != msg.sender) {
      _deductAllowance(fromAccountInfo, amount);
    }
    _deductFrom(fromAccountInfo, amount);
    AccountInfo storage toAccountInfo = accountToInfo[to];

    // Total ETH cannot realistically overflow 96 bits
    unchecked {
      toAccountInfo.freedBalance += uint96(amount);
    }

    emit Transfer(from, to, amount);

    return true;
  }

  /**
   * @dev Require msg.sender has been approved and deducts the amount from the available allowance.
   */
  function _deductAllowance(AccountInfo storage accountInfo, uint256 amount) private {
    if (accountInfo.allowance[msg.sender] != type(uint256).max) {
      if (accountInfo.allowance[msg.sender] < amount) {
        revert FETH_Insufficient_Allowance(accountInfo.allowance[msg.sender]);
      }
      // The require ensures allowance cannot underflow
      unchecked {
        accountInfo.allowance[msg.sender] -= amount;
      }
    }
  }

  /**
   * @dev Removes an amount from the account's available funds.
   */
  function _deductFrom(AccountInfo storage accountInfo, uint256 amount) private {
    // Free from escrow in order to consider any expired escrow balance
    if (accountInfo.freedBalance < amount) {
      revert FETH_Insufficient_Available_Funds(accountInfo.freedBalance);
    }
    // The check above ensures balance cannot underflow
    unchecked {
      accountInfo.freedBalance -= uint96(amount);
    }
  }

  /**
   * @dev Moves expired escrow to the available balance.
   */
  function _freeFromEscrow(address account) private returns (AccountInfo storage) {
    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    // If the first bucket is not ready to be freed, no change to escrowStartIndex is required
    if (escrow.expiration == 0) {
      return accountInfo;
    }
    if (escrow.expiration >= block.timestamp) {
      return accountInfo;
    }

    while (true) {
      // Total ETH will not realistically overflow 96 bits
      unchecked {
        accountInfo.freedBalance += escrow.totalAmount;
        accountInfo.lockups.del(escrowIndex);
        escrow = accountInfo.lockups.get(escrowIndex + 1);
      }

      // If the next bucket is empty, the start index is set to the previous bucket
      if (escrow.expiration == 0) {
        break;
      }

      unchecked {
        // Increment the escrow start index if the next bucket is not empty
        escrowIndex++;
      }

      // If the next bucket is expired, that's the new start index
      if (escrow.expiration >= block.timestamp) {
        break;
      }
    }

    // Escrow index will not realistically overflow 32 bits
    unchecked {
      accountInfo.lockupStartIndex = uint32(escrowIndex);
    }
    return accountInfo;
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
      revert FETH_Escrow_Expired();
    }

    AccountInfo storage accountInfo = accountToInfo[account];
    uint256 escrowIndex = accountInfo.lockupStartIndex;
    LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);

    if (escrow.expiration == expiration) {
      // If removing from the first bucket, we may be able to delete it
      if (escrow.totalAmount == amount) {
        accountInfo.lockups.del(escrowIndex);

        // Bump the escrow start index unless it's the last one
        if (accountInfo.lockups.get(escrowIndex + 1).expiration != 0) {
          // The number of escrow buckets will never overflow 32 bits
          unchecked {
            accountInfo.lockupStartIndex++;
          }
        }
      } else {
        if (escrow.totalAmount < amount) {
          revert FETH_Insufficient_Escrow(escrow.totalAmount);
        }
        // The require above ensures balance will not underflow
        unchecked {
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
        }
      }
    } else {
      // Removing from the 2nd+ bucket
      while (true) {
        // The number of escrow buckets will never overflow 32 bits
        unchecked {
          escrowIndex++;
        }
        escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == expiration) {
          if (amount > escrow.totalAmount) {
            revert FETH_Insufficient_Escrow(escrow.totalAmount);
          }
          // The require above ensures balance will not underflow
          unchecked {
            accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount - amount);
          }
          // We may have an entry with 0 totalAmount but expiration will be set
          break;
        }
        if (escrow.expiration == 0) {
          revert FETH_Escrow_Not_Found();
        }
      }
    }

    emit BalanceUnlocked(account, expiration, amount);
    return accountInfo;
  }

  function _marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) private {
    AccountInfo storage accountInfo = _removeFromLockedBalance(account, expiration, amount);
    // Total ETH cannot realistically overflow 96 bits
    unchecked {
      accountInfo.freedBalance += uint96(amount);
    }
  }

  /* solhint-disable-next-line code-complexity */
  function _marketDepositFor(address account, uint256 amount) private returns (uint256 expiration) {
    if (account == address(0)) {
      revert FETH_Can_Not_Deposit_For_Lockup_with_Address_Zero();
    }
    if (amount == 0) {
      revert FETH_Must_Deposit_Positive_Amount();
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
      // The if above prevents underflow with delta, and the require prevents underflow of freed balance
      unchecked {
        uint256 delta = amount - msg.value;
        if (accountInfo.freedBalance < delta) {
          revert FETH_Insufficient_Available_Funds(accountInfo.freedBalance);
        }
        accountInfo.freedBalance -= uint96(delta);
      }
    } else if (msg.value != amount) {
      revert FETH_Must_Deposit_Exact_Amount();
    }

    // Add to locked escrow
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          if (expiration > type(uint32).max) {
            revert FETH_Expiration_Too_Far_In_Future();
          }
          // Amount (ETH) will always be < 96 bits
          accountInfo.lockups.set(escrowIndex, expiration, amount);
          break;
        }
        if (escrow.expiration == expiration) {
          // Total ETH will always be < 96 bits
          accountInfo.lockups.setTotalAmount(escrowIndex, escrow.totalAmount + amount);
          break;
        }
      }
    }

    emit BalanceLocked(account, expiration, amount);
  }

  /**
   * @notice Returns the total amount of ETH locked in this contract.
   */
  function totalSupply() external view returns (uint256) {
    /* It is possible for this to diverge from the total token count by transferring ETH on self destruct
       but this is on-par with the WETH implementation and done for gas savings. */
    return address(this).balance;
  }

  /**
   * @notice Returns the amount which a spender is still allowed to withdraw from the owner.
   */
  function allowance(address account, address operator) public view returns (uint256) {
    AccountInfo storage accountInfo = accountToInfo[account];
    return accountInfo.allowance[operator];
  }

  /**
   * @notice Returns the balance of an account, available to transfer or withdraw.
   */
  function balanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add expired lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0 || escrow.expiration >= block.timestamp) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the total balance of an account, including locked up funds.
   */
  function totalBalanceOf(address account) external view returns (uint256 balance) {
    AccountInfo storage accountInfo = accountToInfo[account];
    balance = accountInfo.freedBalance;

    // Total ETH cannot realistically overflow 96 bits and escrowIndex will always be < 256 bits
    unchecked {
      // Add all lockups
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        balance += escrow.totalAmount;
      }
    }
  }

  /**
   * @notice Returns the configuration which is applied when balance is locked.
   */
  function getLockupConfiguration() external view returns (uint256 duration, uint256 interval) {
    return (lockupDuration, lockupInterval);
  }

  /**
   * @notice Returns the balance and each outstanding lockup bucket for an account.
   */
  function getLockups(address account) external view returns (uint256[] memory expiries, uint256[] memory amounts) {
    AccountInfo storage accountInfo = accountToInfo[account];

    // Count lockups
    uint256 lockedCount;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          lockedCount++;
        }
      }
    }

    // Allocate arrays
    expiries = new uint256[](lockedCount);
    amounts = new uint256[](lockedCount);

    // Populate results
    uint256 i;
    // The number of buckets is always < 256 bits
    unchecked {
      for (uint256 escrowIndex = accountInfo.lockupStartIndex; ; escrowIndex++) {
        LockedBalance.Lockup memory escrow = accountInfo.lockups.get(escrowIndex);
        if (escrow.expiration == 0) {
          break;
        }
        if (escrow.expiration >= block.timestamp && escrow.totalAmount > 0) {
          expiries[i] = escrow.expiration;
          amounts[i] = escrow.totalAmount;
          i++;
        }
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

/**
 * @notice Interface for functions the market uses in FETH.
 */
interface IFethMarket {
  function marketDepositFor(address account, uint256 amount) external payable returns (uint256 expiration);

  function marketWithdrawFrom(address from, uint256 amount) external;

  function marketWithdrawLocked(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketUnlockFor(
    address account,
    uint256 expiration,
    uint256 amount
  ) external;

  function marketChangeDeposit(
    address unlockFrom,
    uint256 unlockExpiration,
    uint256 unlockAmount,
    address depositFor,
    uint256 depositAmount
  ) external payable returns (uint256 expiration);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.0;

library LockedBalance {
  /// @dev Tracks an account's total lockup per expiration time.
  struct Lockup {
    uint32 expiration;
    uint96 totalAmount;
  }

  struct Lockups {
    mapping(uint256 => uint256) lockups;
  }

  uint256 private constant last128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant first128BitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000000000000000000000000000;

  uint256 private constant firstAmountBitsMask = 0xFFFFFFFF000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
  uint256 private constant secondAmountBitsMask = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000;

  function get(Lockups storage lockups, uint256 index) internal view returns (Lockup memory) {
    unchecked {
      uint256 lockupMetadata = lockups.lockups[index / 2];
      Lockup memory balance;
      if (lockupMetadata == 0) {
        return balance;
      }
      uint128 lockedBalanceBits;
      if (index % 2 == 0) {
        lockedBalanceBits = uint128(lockupMetadata >> 128);
      } else {
        lockedBalanceBits = uint128(lockupMetadata % (2**128));
      }
      balance.expiration = uint32(lockedBalanceBits >> 96);
      balance.totalAmount = uint96(lockedBalanceBits % (2**96));
      return balance;
    }
  }

  function set(
    Lockups storage lockups,
    uint256 index,
    uint256 expiration,
    uint256 totalAmount
  ) internal {
    unchecked {
      uint256 lockedBalanceBits = totalAmount | (expiration << 96);
      if (index % 2 == 0) {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & last128BitsMask) | (lockedBalanceBits << 128);
      } else {
        index /= 2;
        lockups.lockups[index] = (lockups.lockups[index] & first128BitsMask) | lockedBalanceBits;
      }
    }
  }

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
}