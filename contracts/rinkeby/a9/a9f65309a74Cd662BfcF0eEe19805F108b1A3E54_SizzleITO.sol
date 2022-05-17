//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {Verifiable, IBouncerKYC} from "./interfaces/IBouncerKYC.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct Sales {
    uint256 total;
    mapping(address => uint256) perDay;
    mapping(address => uint256) balances;
    mapping(address => uint256) claims;
}

struct Bucket {
    uint256 amount;
    uint256 slope;
    uint256 shift;
}

struct Options {
    uint256 saleEndDate;
    uint256 claimStartDate;
    uint256 decimals;
    Bucket[3] buckets;
    address[] tokens;
    address[] tickers;
}

contract SizzleITO is Pausable, Verifiable {
    uint256 private constant DAYS_IN_YEAR = 365;
    uint256 private constant SECS_IN_DAY = 86400;

    IERC20 public token;

    Options internal options;

    Sales internal sales;

    mapping(address => address) internal tickers;

    event UserBalanceChanged(
        address indexed owner,
        address indexed source,
        uint256 valueIn,
        uint256 valueOut,
        uint80 roundId
    );

    constructor(
        IBouncerKYC _kyc,
        IERC20 _token,
        Options memory opts
    ) {
        kyc = _kyc;
        token = _token;

        options.saleEndDate = opts.saleEndDate;
        options.claimStartDate = opts.claimStartDate;

        options.decimals = opts.decimals;
        options.buckets[0] = opts.buckets[0];
        options.buckets[1] = opts.buckets[1];
        options.buckets[2] = opts.buckets[2];

        require(opts.tokens.length == opts.tickers.length, "SizzleITO: bad token length");
        for (uint i = 0; i < opts.tokens.length; i++) {
            tickers[opts.tokens[i]] = opts.tickers[i];
        }

        _pause();
    }

    function init() external whenPaused {
        SafeERC20.safeTransferFrom(
            token, 
            msg.sender, 
            address(this),
            options.buckets[0].amount +
                options.buckets[1].amount +
                options.buckets[2].amount
        );
        _unpause();
    }

    function balanceOf(address owner) external view returns (uint256) {
        return sales.balances[owner];
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function curve(Bucket memory bucket, uint256 value) private view returns (uint256) {
        return bucket.slope * value / options.decimals + bucket.shift;
    }

    function tokenOf(Bucket memory bucket, uint256 sold, uint256 value) internal view returns (uint256) {
        if (bucket.slope == 0) {
            return (options.decimals * value) / bucket.shift;
        }
        uint p = curve(bucket, sold);
        uint d = sqrt(p * p + 2 * value * bucket.slope) - p;
        return options.decimals * d / bucket.slope;
    }

    function priceOf(Bucket memory bucket, uint256 sold, uint256 value) internal view returns (uint256) {
        if (bucket.slope == 0) {
            return (bucket.shift * value) / options.decimals;
        }
        return (2 * curve(bucket, sold) + bucket.slope * value) * value / 2 * options.decimals;
    }

    function tokenOf(uint256 value) external view returns (uint256) {
        (, Bucket memory b) = this.getActiveBucket();
        return tokenOf(b, sales.total, value);
    }

    function priceOf(uint256 value) external view returns (uint256) {
        (, Bucket memory b) = this.getActiveBucket();
        return priceOf(b, sales.total, value);
    }

    function getActiveBucket() external view returns (uint256, Bucket memory) {
        uint256 bottomEdge = 0;
        uint256 topEdge = 0;
        uint256 i = 0;
        for (i = 0; i < 3; i++) { 
            topEdge += options.buckets[i].amount;
            if (bottomEdge <= sales.total && sales.total < topEdge) {
                break;
            }
            bottomEdge += options.buckets[i].amount;
        }
        return (i, options.buckets[i]);
    }

    function getBucketByIdx(uint256 i) external view returns (Bucket memory) {
        return options.buckets[i];
    }

    function buy(address source, uint256 value) external whenNotPaused isVerified payable returns (uint256) {
        require(block.timestamp < options.saleEndDate, "SizzleITO: sale is end");
    
        uint256 wvalue = 0;
        uint256 tokens = 0;
        uint80 roundID = 0;

        if (source == address(0)) {
            require(msg.value == value, "SizzleITO: bad msg.value");
            wvalue = value;
        } else {
            require(tickers[source] != address(0), "SizzleITO: bad source");
            SafeERC20.safeTransferFrom(IERC20(source), msg.sender, address(this), value);
            uint256 tickerDecimals = 10 ** AggregatorV3Interface(tickers[source]).decimals();
            int256 tickerValue = 0;
            (roundID, tickerValue,,,) = AggregatorV3Interface(tickers[source]).latestRoundData();
            wvalue = value * uint256(tickerValue) / tickerDecimals;
        }

        uint256 totalSold = sales.total;
        uint256 bottomEdge = 0;
        uint256 topEdge = 0;
        uint256 v; 
        uint256 t; 
        for (uint256 i = 0; wvalue > 0 && i < 3; i++) { 
            topEdge += options.buckets[i].amount;
            if (bottomEdge <= totalSold && totalSold < topEdge) {
                v = wvalue;
                t = tokenOf(options.buckets[i], totalSold, v);
                if (totalSold + t > topEdge) {
                    t = topEdge - totalSold;
                    v = priceOf(options.buckets[i], totalSold, t); 
                }
                totalSold += t;
                tokens += t;
                wvalue -= v;
            }
            v = 0; 
            t = 0;
            bottomEdge += options.buckets[i].amount;
        }

        sales.total += tokens;
        sales.balances[msg.sender] += tokens;
        sales.perDay[msg.sender] = sales.balances[msg.sender] / DAYS_IN_YEAR;

        emit UserBalanceChanged(
            msg.sender,
            source,
            value,
            tokens,
            roundID
        );

        return tokens;
    }

    function claimOf(address owner) external view returns (uint256) {
        uint256 value = 0;
        uint256 daysGone = (block.timestamp - options.claimStartDate) / SECS_IN_DAY;
        if (daysGone <= DAYS_IN_YEAR) {
            value = daysGone * sales.perDay[owner] - sales.claims[owner];
        } else {
            value = sales.balances[owner];
        }
        return value;
    }

    function claim() external whenNotPaused isVerified returns (uint256) {
        require(block.timestamp >= options.claimStartDate, "SizzleITO: bad claim date");

        uint256 value = 0;
        uint256 daysGone = (block.timestamp - options.claimStartDate) / SECS_IN_DAY;
        if (daysGone <= DAYS_IN_YEAR) {
            value = daysGone * sales.perDay[msg.sender] - sales.claims[msg.sender];
            if (value > sales.balances[msg.sender]) {
                value = sales.balances[msg.sender];
            }
        } else {
            value = sales.balances[msg.sender];
            sales.perDay[msg.sender] = 0;
        }
        sales.balances[msg.sender] -= value;

        require(value > 0, "SizzleITO: value must be more than zero");
        sales.claims[msg.sender] += value;

        SafeERC20.safeTransfer(token, msg.sender, value);
        return value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum Statuses {
    Failed,
    Verified
}

interface IBouncerKYC {
    function getStatus(address _user) external view returns (Statuses);
}

contract Verifiable {
    IBouncerKYC public kyc;

    modifier isVerified() {
        require(
            kyc.getStatus(msg.sender) == Statuses.Verified,
            "Verifiable: sender is not KYCed"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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