// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "openzeppelin-solidity/contracts/utils/Context.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @author vigan.abd
 * @title ThriveCoin Vesting Schedule
 *
 * @dev Implementation of the THRIVE Vesting Contract.
 *
 * ThriveCoin Vesting schedule contract is a generic smart contract that
 * provides locking and vesting calculation for single wallet.
 *
 * Vesting schedule is realized through allocating funds for stakeholder for
 * agreed vesting/locking schedule. The contract acts as a wallet for
 * stakeholder and they can withdraw funds once they become available
 * (see calcVestedAmount method). Funds become available periodically and the
 * stakeholder can check these details at any time by accessing the methods like
 * vested or available.
 *
 * NOTE: funds are sent to contract after instantiation!
 *
 * Implementation is based on these two smart contracts:
 * - https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.5/contracts/finance/VestingWallet.sol
 * - https://github.com/cpu-coin/CPUcoin/blob/master/contracts/IERC20Vestable.sol
 *
 * NOTE: extends openzeppelin v4.3.2 contracts:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/utils/Context.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/token/ERC20/utils/SafeERC20.sol
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.3.2/contracts/access/Ownable.sol
 */
contract ThriveCoinVestingSchedule is Context, Ownable {
  /**
   * @dev Events related to vesting contract
   */
  event VestingFundsClaimed(address indexed token, address indexed beneficiary, uint256 amount);
  event VestingFundsRevoked(
    address indexed token,
    address indexed beneficiary,
    address indexed refundDest,
    uint256 amount
  );
  event VestingBeneficiaryChanged(
    address indexed token,
    address indexed oldBeneficiary,
    address indexed newBeneficiary
  );

  /**
   * @dev Throws if called by any account other than the beneficiary.
   */
  modifier onlyBeneficiary() {
    require(beneficiary() == _msgSender(), "ThriveCoinVestingSchedule: only beneficiary can perform the action");
    _;
  }

  /**
   * @dev Throws if contract is revoked.
   */
  modifier notRevoked() {
    require(revoked() == false, "ThriveCoinVestingSchedule: contract is revoked");
    _;
  }

  uint256 private constant SECONDS_PER_DAY = 86400;

  /**
   * @dev ERC20 token address
   */
  address private immutable _token;

  /**
   * @dev Beneficiary address that is able to claim funds
   */
  address private _beneficiary;

  /**
   * @dev Total allocated amount
   */
  uint256 private _allocatedAmount;

  /**
   * @dev Start day of the vesting schedule
   */
  uint256 private _startDay;

  /**
   * @dev Vesting schedule duration in days
   */
  uint256 private _duration;

  /**
   * @dev Vesting schedule cliff period in days
   */
  uint256 private _cliffDuration;

  /**
   * @dev Vesting schedule unlock period/interval in days
   */
  uint256 private _interval;

  /**
   * @dev Flag that specifies if vesting schedule can be revoked
   */
  bool private immutable _revocable;

  /**
   * @dev Flag that specifies if vesting schedule is revoked
   */
  bool private _revoked;

  /**
   * @dev Flag that specifies if beneficiary can be changed
   */
  bool private immutable _immutableBeneficiary;

  /**
   * @dev Claimed amount so far
   */
  uint256 private _claimed;

  /**
   * @dev Daily claim limit
   */
  uint256 private _claimLimit;

  /**
   * @dev Last time (day) when funds were claimed
   */
  uint256 private _lastClaimedDay;

  /**
   * @dev Amount claimed so far during the day
   */
  uint256 private _dailyClaimedAmount;

  /**
   * @dev Initializes the vesting contract
   *
   * @param token_ - Specifies the ERC20 token that is stored in smart contract
   * @param beneficiary_ - The address that is able to claim funds
   * @param allocatedAmount_ - Specifies the total allocated amount for
   * vesting/locking schedule/period
   * @param startTime - Specifies vesting/locking schedule start day, can be a
   * date in future or past. The vesting schedule will calculate the available
   * amount for claiming (unlocked amount) based on this timestamp.
   * @param duration_ - Specifies the duration in days for vesting/locking
   * schedule. At the point in time where start time + duration is passed the
   * whole funds will be unlocked and the vesting/locking schedule would be
   * finished.
   * @param cliffDuration_ - Specifies the cliff period in days for schedule.
   * Until this point in time is reached funds can’t be claimed, and once this
   * time is passed some portion of funds will be unlocked based on schedule
   * calculation from `startTime`.
   * @param interval_ - Specifies how often the funds will be unlocked (in days).
   * e.g. if this one is 365 it means that funds get unlocked every year.
   * @param claimed_ - Is applicable only if the contract is migrated and
   * specifies the amount claimed so far. In most cases this is 0.
   * @param claimLimit_ - Specifies maximum amount that can be claimed/withdrawn
   * during the day
   * @param revocable_ - Specifies if the smart contract is revocable or not.
   * Once contract is revoked then no more funds can be claimed
   * @param immutableBeneficiary_ - Specifies whenever contract beneficiary can
   * be changed or not. Usually this one is enabled just in case if stakeholder
   * loses access to private key so in this case contract can change account for
   * claiming future funds.
   */
  constructor(
    address token_,
    address beneficiary_,
    uint256 allocatedAmount_,
    uint256 startTime, // unix epoch ms
    uint256 duration_, // in days
    uint256 cliffDuration_, // in days
    uint256 interval_, // in days
    uint256 claimed_, // already claimed, helpful for chain migrations
    uint256 claimLimit_,
    bool revocable_,
    bool immutableBeneficiary_
  ) {
    require(token_ != address(0), "ThriveCoinVestingSchedule: token is zero address");
    require(beneficiary_ != address(0), "ThriveCoinVestingSchedule: beneficiary is zero address");
    require(cliffDuration_ <= duration_, "ThriveCoinVestingSchedule: cliff duration greater than duration");
    require(interval_ >= 1, "ThriveCoinVestingSchedule: interval should be at least 1 day");

    _token = token_;
    _beneficiary = beneficiary_;
    _allocatedAmount = allocatedAmount_;
    _startDay = startTime / SECONDS_PER_DAY;
    _duration = duration_;
    _cliffDuration = cliffDuration_;
    _interval = interval_;
    _claimed = claimed_;
    _claimLimit = claimLimit_;
    _revocable = revocable_;
    _immutableBeneficiary = immutableBeneficiary_;
    _revoked = false;
  }

  /**
   * @dev Returns the address of ERC20 token.
   *
   * @return address
   */
  function token() public view virtual returns (address) {
    return _token;
  }

  /**
   * @dev Returns the address of the current beneficiary.
   *
   * @return address
   */
  function beneficiary() public view virtual returns (address) {
    return _beneficiary;
  }

  /**
   * @dev Returns the total amount allocated for vesting.
   *
   * @return uint256
   */
  function allocatedAmount() public view virtual returns (uint256) {
    return _allocatedAmount;
  }

  /**
   * @dev Returns the start day of the vesting schedule.
   *
   * NOTE: The result is returned in days of year, if you want to get the date
   * you should multiply result with 86400 (seconds for day)
   *
   * @return uint256
   */
  function startDay() public view virtual returns (uint256) {
    return _startDay;
  }

  /**
   * @dev Returns the vesting schedule duration in days unit.
   *
   * @return uint256
   */
  function duration() public view virtual returns (uint256) {
    return _duration;
  }

  /**
   * @dev Returns the vesting schedule cliff duration in days unit.
   *
   * @return uint256
   */
  function cliffDuration() public view virtual returns (uint256) {
    return _cliffDuration;
  }

  /**
   * @dev Returns interval in days of how often funds will be unlocked.
   *
   * @return uint256
   */
  function interval() public view virtual returns (uint256) {
    return _interval;
  }

  /**
   * @dev Returns the flag specifying if the contract is revocable.
   *
   * @return bool
   */
  function revocable() public view virtual returns (bool) {
    return _revocable;
  }

  /**
   * @dev Returns the flag specifying if the beneficiary can be changed after
   * contract instantiation.
   *
   * @return bool
   */
  function immutableBeneficiary() public view virtual returns (bool) {
    return _immutableBeneficiary;
  }

  /**
   * @dev Returns the amount claimed/withdrawn from contract so far.
   *
   * @return uint256
   */
  function claimed() public view virtual returns (uint256) {
    return _claimed;
  }

  /**
   * @dev Returns the amount unlocked so far.
   *
   * @return uint256
   */
  function vested() public view virtual returns (uint256) {
    return calcVestedAmount(block.timestamp);
  }

  /**
   * @dev Returns the amount that is available for claiming/withdrawing.
   *
   * @return uint256
   */
  function available() public view virtual returns (uint256) {
    return calcVestedAmount(block.timestamp) - claimed();
  }

  /**
   * @dev Returns the remaining locked amount
   *
   * @return uint256
   */
  function locked() public view virtual returns (uint256) {
    return allocatedAmount() - calcVestedAmount(block.timestamp);
  }

  /**
   * @dev Returns the flag that specifies if contract is revoked or not.
   *
   * @return bool
   */
  function revoked() public view virtual returns (bool) {
    return _revoked;
  }

  /**
   * @dev Returns the flag specifying that the contract is ready to be used.
   * The function returns true only if the contract has enough balance for
   * transferring total allocated amount - already claimed amount
   */
  function ready() public view virtual returns (bool) {
    uint256 bal = IERC20(_token).balanceOf(address(this));
    return bal >= _allocatedAmount - _claimed;
  }

  /**
   * @dev Calculates vested amount until specified timestamp.
   *
   * @param timestamp - Unix epoch time in seconds
   * @return uint256
   */
  function calcVestedAmount(uint256 timestamp) public view virtual returns (uint256) {
    uint256 start = startDay();
    uint256 length = duration();
    uint256 timestampInDays = timestamp / SECONDS_PER_DAY;
    uint256 totalAmount = allocatedAmount();

    if (timestampInDays < start + cliffDuration()) {
      return 0;
    }

    if (timestampInDays > start + length) {
      return totalAmount;
    }

    uint256 itv = interval();
    uint256 daysVested = timestampInDays - start;
    uint256 effectiveDaysVested = (daysVested / itv) * itv; // e.g. 303/4 => 300, 304/4 => 304

    return (totalAmount * effectiveDaysVested) / length;
  }

  /**
   * @dev Withdraws funds from smart contract to beneficiary. Withdrawal is
   * allowed only if amount is less or equal to available amount and daily limit
   * is zero or greater/equal to amount.
   *
   * @param amount - Amount that will be claimed by beneficiary
   */
  function claim(uint256 amount) public virtual onlyBeneficiary notRevoked {
    require(ready(), "ThriveCoinVestingSchedule: Contract is not fully initialized yet");

    uint256 availableBal = available();
    require(amount <= availableBal, "ThriveCoinVestingSchedule: amount exceeds available balance");

    uint256 limit = claimLimit();
    uint256 timestampInDays = block.timestamp / SECONDS_PER_DAY;
    if (_lastClaimedDay != timestampInDays) {
      _lastClaimedDay = timestampInDays;
      _dailyClaimedAmount = 0;
    }

    require(
      (amount + _dailyClaimedAmount) <= limit || limit == 0,
      "ThriveCoinVestingSchedule: amount exceeds claim limit"
    );

    _dailyClaimedAmount += amount;
    _claimed += amount;
    emit VestingFundsClaimed(_token, _beneficiary, amount);
    SafeERC20.safeTransfer(IERC20(_token), _beneficiary, amount);
  }

  /**
   * @dev Revokes the contract. After revoking no more funds can be claimed and
   * remaining amount is transferred back to contract owner
   */
  function revoke() public virtual onlyOwner notRevoked {
    require(ready(), "ThriveCoinVestingSchedule: Contract is not fully initialized yet");
    require(revocable(), "ThriveCoinVestingSchedule: contract is not revocable");

    uint256 contractBal = IERC20(_token).balanceOf(address(this));
    uint256 amount = allocatedAmount() - claimed();
    address dest = owner();
    _revoked = true;
    emit VestingFundsRevoked(_token, _beneficiary, dest, amount);
    SafeERC20.safeTransfer(IERC20(_token), dest, contractBal);
  }

  /**
   * @dev Changes the address of beneficiary. Once changed only new beneficiary
   * can claim the funds
   *
   * @param newBeneficiary - New beneficiary address that can claim funds from
   * now on
   */
  function changeBeneficiary(address newBeneficiary) public virtual onlyOwner {
    require(immutableBeneficiary() == false, "ThriveCoinVestingSchedule: beneficiary is immutable");

    emit VestingBeneficiaryChanged(_token, _beneficiary, newBeneficiary);
    _beneficiary = newBeneficiary;
  }

  /**
   * @dev Returns the max daily claimable amount.
   *
   * @return uint256
   */
  function claimLimit() public view virtual returns (uint256) {
    return _claimLimit;
  }

  /**
   * @dev Changes daily claim limit.
   *
   * @param newClaimLimit - New daily claim limit
   */
  function changeClaimLimit(uint256 newClaimLimit) public virtual onlyOwner {
    _claimLimit = newClaimLimit;
  }

  /**
   * @dev Returns the day when funds were claimed lastly.
   *
   * @return uint256
   */
  function lastClaimedDay() public view virtual returns (uint256) {
    return _lastClaimedDay;
  }

  /**
   * @dev Returns the amount claimed so far during the day.
   *
   * @return uint256
   */
  function dailyClaimedAmount() public view virtual returns (uint256) {
    uint256 timestampInDays = block.timestamp / SECONDS_PER_DAY;
    return timestampInDays == _lastClaimedDay ? _dailyClaimedAmount : 0;
  }

  /**
   * @dev Refunds contract balance that exceeds _allocatedAmount back to
   * contract owner
   */
  function refundExceedingBalance() public virtual onlyOwner {
    require(ready(), "ThriveCoinVestingSchedule: Contract is not fully initialized yet");

    uint256 maxClaimableAmount = allocatedAmount() - claimed();
    uint256 contractBal = IERC20(_token).balanceOf(address(this));
    uint256 amount = contractBal - maxClaimableAmount;
    address dest = owner();
    SafeERC20.safeTransfer(IERC20(_token), dest, amount);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

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