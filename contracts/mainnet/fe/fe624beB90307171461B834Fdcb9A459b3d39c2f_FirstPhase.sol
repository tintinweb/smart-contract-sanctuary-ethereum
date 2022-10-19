// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// interface
import {IFirstPhase} from "./IFirstPhase.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// library
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Release} from "../lib/Release.sol";
import {Time} from "../lib/Time.sol";

// contracts
import {Operation, Ownables} from "../utils/Operation.sol";
import {DateTime} from "../utils/DateTime.sol";

contract FirstPhase is IFirstPhase, Operation, DateTime {
    using SafeERC20 for IERC20;

    using Time for Time.Timestamp;
    Time.Timestamp private _timestamp;

    using Release for Release.Data;
    mapping(address => Release.Data) private _release;

    IERC20 public immutable Token;

    uint256 public immutable TotalMonth;

    constructor(
        address e,
        uint256 total_month,
        address[2] memory owners
    ) payable Ownables(owners) {
        Token = IERC20(e);
        TotalMonth = total_month;
    }

    uint256 private locked;
    modifier lock() {
        require(locked == 0, "FirstPhase: LOCKED");
        locked = 1;
        _;
        locked = 0;
    }

    modifier Authorization(bytes32 opHash) {
        _checkAuthorization(opHash);
        _;
    }

    function getRecordHash(
        address account,
        uint256 amount,
        uint16 lockMon
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount, lockMon));
    }

    function getRecordBatchHash(
        address[] memory accounts,
        uint256[] memory amounts,
        uint16[] memory lockMons
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(accounts, amounts, lockMons));
    }

    function record(
        address account,
        uint256 amount,
        uint16 lockMon
    ) public lock Authorization(getRecordHash(account, amount, lockMon)) {
        _record(account, amount, lockMon);
        emit Record(account, amount);
    }

    function recordBatch(
        address[] memory accounts,
        uint256[] memory amounts,
        uint16[] memory lockMons
    ) public lock Authorization(getRecordBatchHash(accounts, amounts, lockMons)) {
        uint256 aci = accounts.length;
        require(aci == accounts.length && aci == lockMons.length, "FirstPhase: data is not legitimate");
        for (uint256 i = 0; i < aci; i++) {
            _record(accounts[i], amounts[i], lockMons[i]);
        }
        emit Records(accounts, amounts);
    }

    function withdraw() public lock {
        _withdraw(_msgSender());
    }

    function withdrawWith(address account) public lock {
        _withdraw(account);
    }

    function _record(
        address account,
        uint256 amount,
        uint16 lockMon
    ) private {
        _release[account]._record(amount, _timestamp._getCurrentTime(), lockMon, _msgSender());
    }

    function _withdraw(address account) private {
        uint256 currentDay = _timestamp._getCurrentTime();
        uint256 amount = _calculate(account, currentDay);
        require(amount > uint256(0), "FirstPhase: insufficient available assets");
        _release[account]._withdraw(amount, currentDay, account);
        Token.safeTransfer(account, amount);
        emit Withdraw(account, amount);
    }

    function _calculate(address account, uint256 currentDay) private returns (uint256) {
        uint256 len = _release[account]._deposits.length;
        uint256 total = 0;
        for (uint256 i = 0; i < len; i++) {
            uint256 diff_month = differenceSeveralMonths(currentDay, _release[account]._recent_timemap);
            (uint256 amount, bool finish) = _release[account]._calculateRelease(diff_month, TotalMonth, i);
            if (amount == 0) continue;
            _release[account]._extract(i, amount);
            if (finish) _release[account]._finish(i);
            total += amount;
        }
        return total;
    }

    function setTestTime(uint256 test_time) external onlyOwner {
        _timestamp._setCurrentTime(test_time);
    }

    function getTime() public view returns (uint256) {
        return _timestamp._getCurrentTime();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IFirstPhase {
    event Record(address account, uint256 amount);
    event Records(address[] account, uint256[] amount);

    event Withdraw(address account, uint256 amount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Release {
    struct Basic {
        uint256 _total;
        uint256 _locked;
        uint256 _available;
        uint256 _extracted;
        bool isInit;
    }

    struct Record {
        uint256 _timemap;
        uint256 _amount;
        uint256 _extracted;
        uint16 _lockMon;
        address _operator;
    }

    struct Withdraw {
        uint256 _timemap;
        uint256 _amount;
        address _operator;
    }

    struct Data {
        Basic _basic;
        Withdraw[] _withdraws;
        Record[] _deposits;
        uint256 _recent_timemap;
    }

    modifier isInit(Data storage h) {
        require(h._basic.isInit == true, "Release: account does not exist");
        _;
    }

    modifier insufficient(Data storage h, uint256 amount) {
        require(h._basic._available >= amount, "Release: insufficient available assets");
        _;
    }

    function _record(
        Data storage h,
        uint256 amount,
        uint256 timemap,
        uint16 lockMon,
        address operator
    ) internal {
        if (h._basic.isInit == false) h._basic.isInit = true;
        if (h._recent_timemap == 0) h._recent_timemap = timemap;

        h._deposits.push(
            Record({_amount: amount, _timemap: timemap, _lockMon: lockMon, _operator: operator, _extracted: 0})
        );
        h._basic._total += amount;
        h._basic._available += amount;
    }

    function _withdraw(
        Data storage h,
        uint256 amount,
        uint256 timemap,
        address operator
    ) internal isInit(h) insufficient(h, amount) {
        h._withdraws.push(Withdraw({_amount: amount, _timemap: timemap, _operator: operator}));

        h._basic._available -= amount;
        h._basic._extracted += amount;

        h._recent_timemap = timemap;
    }

    function _lock(Data storage h, uint256 amount) internal isInit(h) insufficient(h, amount) {
        h._basic._available -= amount;
        h._basic._locked += amount;
    }

    function _ulock(Data storage h, uint256 amount) internal isInit(h) {
        require(h._basic._locked >= amount, "Release: insufficient lock-in assets");
        h._basic._locked -= amount;
        h._basic._available += amount;
    }

    function _extract(
        Data storage h,
        uint256 n,
        uint256 amount
    ) internal isInit(h) {
        require(
            h._deposits[n]._extracted + amount <= h._deposits[n]._amount,
            "Release: insufficient assets to be extracted"
        );
        h._deposits[n]._extracted += amount;
    }

    function _finish(Data storage h, uint256 n) internal isInit(h) {
        require(h._deposits[n]._amount == h._deposits[n]._extracted, "Release: there are also remaining assets");
        delete (h._deposits[n]);
    }

    function _calculateRelease(
        Data storage h,
        uint256 diff_month,
        uint256 total_month,
        uint256 n
    ) internal isInit(h) returns (uint256 release, bool finish) {
        if (diff_month <= h._deposits[n]._lockMon) {
            release = 0;
        } else {
            h._deposits[n]._lockMon = 0;
            release = (h._deposits[n]._amount / total_month) * diff_month;
            if (release + h._deposits[n]._extracted >= h._deposits[n]._amount) {
                release = h._deposits[n]._amount - h._deposits[n]._extracted;
                finish = true;
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title Control the current timestamp for easy debugging
 * @dev If it is not in development mode, please do not modify the current time
 */
library Time {
    struct Timestamp {
        uint256 _current_time;
    }

    function _getCurrentTime(Timestamp storage timestamp) internal view returns (uint256) {
        if (timestamp._current_time > 0) {
            return timestamp._current_time;
        } else {
            return block.timestamp;
        }
    }

    function _setCurrentTime(Timestamp storage timestamp, uint256 time_map) internal {
        timestamp._current_time = time_map;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

abstract contract DateTime {
    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 constant DAY_IN_SECONDS = 86400;
    uint256 constant YEAR_IN_SECONDS = 31536000;
    uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 constant HOUR_IN_SECONDS = 3600;
    uint256 constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function leapYearsBefore(uint256 year) public pure returns (uint256) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            return 31;
        } else if (month == 4 || month == 6 || month == 9 || month == 11) {
            return 30;
        } else if (isLeapYear(year)) {
            return 29;
        } else {
            return 28;
        }
    }

    function parseTimestamp(uint256 timestamp) internal pure returns (_DateTime memory dt) {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint256 secondsInMonth;
        for (i = 1; i <= 12; i++) {
            secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint256 timestamp) public pure returns (uint16) {
        uint256 secondsAccountedFor = 0;
        uint16 year;
        uint256 numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
            if (isLeapYear(uint16(year - 1))) {
                secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
            } else {
                secondsAccountedFor -= YEAR_IN_SECONDS;
            }
            year -= 1;
        }
        return year;
    }

    function getMonth(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint256 timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint256 timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function differenceSeveralMonths(uint256 new_time, uint256 old_time) public pure returns (uint256 diff_month) {
        _DateTime memory diff_time = parseTimestamp((new_time - old_time));
        uint256 diff_year = uint256(diff_time.year - ORIGIN_YEAR);
        if (diff_year > 0) {
            diff_month += (12 * diff_year);
        }
        diff_month += (uint256(diff_time.month) - 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IOperation {
    function applicationOperation(bytes32 opHash) external;

    function authorizedOperation(bytes32 opHash) external;

    event ApplicationOperation(address from, bytes32 opHash);

    event AuthorizedOperation(address from, bytes32 opHash);

    event AllDone(bytes32 opHash);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IOperation.sol";
import "./Ownables.sol";

abstract contract Operation is IOperation, Ownables {
    struct Op {
        bool isAuthorized;
        bool isVaild;
        mapping(address => bool) auth;
    }
    mapping(bytes32 => Op) private _operation_hash;

    modifier Existential(bytes32 opHash) {
        _checkOperation(opHash);
        _;
    }

    modifier Complete(bytes32 opHash) {
        _;
        address[2] memory _o = Owners();
        if ((_operation_hash[opHash].auth[_o[0]] == true) && (_operation_hash[opHash].auth[_o[1]] == true)) {
            _operation_hash[opHash].isAuthorized = true;
            emit AllDone(opHash);
        }
    }

    function _closeOperation(bytes32 opHash) private {
        delete (_operation_hash[opHash]);
    }

    function _checkOperation(bytes32 opHash) internal view virtual {
        require(_operation_hash[opHash].isVaild == true, "Operation: operation does not exist");
    }

    function _checkAuthorization(bytes32 opHash) internal virtual {
        require(_operation_hash[opHash].isAuthorized == true, "Operation: authorization is not complete");
        _closeOperation(opHash);
    }

    function authorizedOperation(bytes32 opHash) public onlyOwner Existential(opHash) Complete(opHash) {
        require(_operation_hash[opHash].auth[_msgSender()] == false, "Operation: do not repeat the operation");
        _operation_hash[opHash].auth[_msgSender()] = true;
        emit AuthorizedOperation(_msgSender(), opHash);
    }

    function applicationOperation(bytes32 opHash) public {
        require(_operation_hash[opHash].isVaild == false, "Operation: operation already exists");
        _operation_hash[opHash].isVaild = true;
        emit ApplicationOperation(_msgSender(), opHash);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract Ownables is Context {
    address[2] private _owner_array;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address[2] memory owners) {
        _owner_array = owners;
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
    function Owners() public view virtual returns (address[2] memory) {
        return _owner_array;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(
            (_owner_array[0] == _msgSender() || _owner_array[1] == _msgSender()),
            "Ownable: caller is not the owner"
        );
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
        _owner_array[0] == _msgSender() ? _owner_array[0] = newOwner : _owner_array[1] = newOwner;
        emit OwnershipTransferred(_msgSender(), newOwner);
    }
}