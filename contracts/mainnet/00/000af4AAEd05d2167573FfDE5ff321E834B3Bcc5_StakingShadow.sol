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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingShadow
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import {IPancakeRouter02} from 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';
import './utils/IWETH.sol';

contract StakingShadow is Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
    using Address for address;

    struct TokenParameters {
        IERC20Metadata token;
        address[] swapPath;
        address[] reverseSwapPath;
        string symbol;
        string name;
        uint256 decimals;
    }

    struct StrategyParameters {
        string name;
        bool isSafe;
        uint256 rateX1000;
        bool isPaused;
        uint256 withdrawId;
    }

    struct Bank {
        bool fulfilled;
        bool fullDeposited;
        bool fullReward;
        uint256 deposited;
        uint256 reward;
        // uint256 updateTimestamp;
    }

    struct TokenManager {
        uint256 deposited;
        uint256 reward;
        Bank bank;
    }

    enum Status {
        NULL, // NULL
        DEPOSITED, // User deposits tokens
        REQUESTED, // User requests withdraw
        WITHDRAWED // User withdrawed tokens
    }

    struct Deposit {
        uint256 id;
        string strategyName;
        address user;
        IERC20Metadata token;
        uint256 deposited;
        uint256 reward;
        uint256 timestamp;
        uint256 withdrawId;
        uint256 period;
        uint256 endTimestamp;
        uint256 lastRewardId;
        Status status;
    }

    enum HistoryType {
        NULL,
        CLAIM,
        FULFILL,
        PURCHASE,
        REWARD
    }

    struct History {
        HistoryType historyType;
        uint256 timestamp;
        address user;
        uint256 stableAmount;
        string strategyName;
    }
    /// duplication storage capacity ---------------

    // config
    IERC20 private stableToken;
    IPancakeRouter02 private router;

    uint256[3] private gap0;

    mapping(IERC20Metadata => TokenParameters) private tokensParameters;
    mapping(string => StrategyParameters) private strategiesParameters;
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => TokenManager)))
        private _tokenManager;

    uint256[2] private gap1;

    mapping(string => mapping(IERC20Metadata => uint256)) private totalRewards;
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => uint256[2])))
        private _rewardFulfillRatesByIds;
    uint256 private _currentRewardId;
    uint256 lastRewardsFulfillTimestamp;
    uint256 claimOffset = 5 days;

    uint256 private gap2;

    IERC20Metadata[] private _registeredTokens;

    uint256 private gap3;

    Deposit[] public _deposits;

    uint256 private gap4;

    mapping(string => uint256) public stableTokenBank;
    uint256 private slippageX1000 = 20;
    History[] private _history;

    /// -------------------------------------------

    event FulfilledDeposited(
        uint256 indexed timestamp,
        string indexed strategyName,
        uint256 withdrawId
    );
    event FulfilledRewards(uint256 indexed timestamp, string indexed strategyName);

    /// @dev fulfills pending requests for rewards (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillDeposited(string memory strategyName, uint256 amountMaxInStable)
        external
    {
        require(amountMaxInStable > 0, 'max = 0');
        uint256 withdrawId = strategiesParameters[strategyName].withdrawId;
        (
            uint256[] memory depositedInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256 depositedInStableTokens
        ) = calculateWithdrawAmountAdmin(strategyName);

        uint256 length = _registeredTokens.length;
        uint256 totalStableTokens = amountMaxInStable;

        require(depositedInStableTokens > 0, 'Nothing fulfill');
        stableToken.approve(address(router), amountMaxInStable);

        if (
            strategiesParameters[strategyName].isSafe ||
            depositedInStableTokens <= amountMaxInStable
        ) {
            require(depositedInStableTokens <= amountMaxInStable, 'need > max');
            totalStableTokens = depositedInStableTokens;
            stableToken.safeTransferFrom(
                msg.sender,
                address(this),
                depositedInStableTokens
            );

            for (uint256 i; i < length; i++) {
                IERC20Metadata token = _registeredTokens[i];
                TokenManager storage tm = _tokenManager[withdrawId][strategyName][token];

                tm.bank.deposited = depositedInTokens[i];

                uint256 amountOut = tm.bank.deposited;
                uint256 amountInMax = depositedInStableTokenForTokens[i];
                if (address(token) != address(stableToken) && amountOut != 0) {
                    uint256[] memory amounts = router.swapTokensForExactTokens(
                        amountOut,
                        amountInMax,
                        tokensParameters[token].reverseSwapPath,
                        address(this),
                        block.timestamp
                    );
                    uint256 left = amountInMax - amounts[0];
                    if (left > 0) {
                        stableToken.safeTransfer(msg.sender, left);
                        totalStableTokens -= left;
                    }
                }

                tm.bank.fulfilled = true;
                tm.bank.fullDeposited = true;
            }

            _history.push(
                History({
                    historyType: HistoryType.FULFILL,
                    timestamp: block.timestamp,
                    user: msg.sender,
                    stableAmount: totalStableTokens,
                    strategyName: strategyName
                })
            );
        } else {
            if (depositedInStableTokens <= amountMaxInStable) {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    depositedInStableTokens
                );
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = _tokenManager[withdrawId][strategyName][
                        token
                    ];
                    tm.bank.deposited = depositedInTokens[i];

                    uint256 amountOut = tm.bank.deposited;
                    uint256 amountInMax = depositedInStableTokenForTokens[i];

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }

                    tm.bank.fulfilled = true;
                    tm.bank.fullDeposited = true;
                }
            } else {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountMaxInStable
                );
                uint256 lessDepositedInStable = amountMaxInStable;
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = _tokenManager[withdrawId][strategyName][
                        token
                    ];

                    tm.bank.deposited =
                        (lessDepositedInStable * depositedInTokens[i]) /
                        depositedInStableTokens;

                    uint256 amountOut = tm.bank.deposited;
                    uint256 amountInMax = (lessDepositedInStable *
                        depositedInStableTokenForTokens[i]) / depositedInStableTokens;

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }

                    tm.bank.fulfilled = true;
                    tm.bank.fullDeposited = false;
                }
            }
        }

        _history.push(
            History({
                historyType: HistoryType.FULFILL,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: totalStableTokens,
                strategyName: strategyName
            })
        );

        strategiesParameters[strategyName].withdrawId++;

        emit FulfilledDeposited(
            block.timestamp,
            strategyName,
            strategiesParameters[strategyName].withdrawId - 1
        );
    }

    /// @dev fulfills pending requests for rewards (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillRewards(string memory strategyName, uint256 amountMaxInStable)
        external
    {
        require(amountMaxInStable > 0, 'max = 0');
        (
            uint256[] memory rewardsInTokens,
            uint256[] memory rewardsInStable,
            uint256 _totalRewards
        ) = calculateWithdrawAmountAdminRewards(strategyName);

        uint256 length = _registeredTokens.length;
        uint256 totalStableTokens = amountMaxInStable;

        require(_totalRewards > 0, 'Nothing fulfill');
        stableToken.approve(address(router), amountMaxInStable);

        if (
            strategiesParameters[strategyName].isSafe ||
            _totalRewards <= amountMaxInStable
        ) {
            require(_totalRewards <= amountMaxInStable, 'need > max');

            stableToken.safeTransferFrom(msg.sender, address(this), _totalRewards);

            for (uint256 i; i < length; i++) {
                IERC20Metadata token = _registeredTokens[i];

                uint256 amountOut = rewardsInTokens[i];
                uint256 amountInMax = rewardsInStable[i];
                if (address(token) != address(stableToken) && amountOut != 0) {
                    uint256[] memory amounts = router.swapTokensForExactTokens(
                        amountOut,
                        amountInMax,
                        tokensParameters[token].reverseSwapPath,
                        address(this),
                        block.timestamp
                    );
                    uint256 left = amountInMax - amounts[0];
                    if (left > 0) {
                        stableToken.safeTransfer(msg.sender, left);
                        totalStableTokens -= left;
                    }
                }
                _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][0] = 1;
                _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][1] = 1;
            }
        } else {
            if (_totalRewards <= amountMaxInStable) {
                stableToken.safeTransferFrom(msg.sender, address(this), _totalRewards);
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];

                    uint256 amountOut = rewardsInTokens[i];
                    uint256 amountInMax = rewardsInStable[i];

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        0
                    ] = 1;
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        1
                    ] = 1;
                }
            } else {
                stableToken.safeTransferFrom(
                    msg.sender,
                    address(this),
                    amountMaxInStable
                );
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];

                    uint256 amountOut = (rewardsInTokens[i] * amountMaxInStable) /
                        _totalRewards;
                    uint256 amountInMax = (rewardsInStable[i] * amountMaxInStable) /
                        _totalRewards;

                    if (address(token) != address(stableToken) && amountOut != 0) {
                        uint256[] memory amounts = router.swapTokensForExactTokens(
                            amountOut,
                            amountInMax,
                            tokensParameters[token].reverseSwapPath,
                            address(this),
                            block.timestamp
                        );
                        uint256 left = amountInMax - amounts[0];
                        if (left > 0) {
                            stableToken.safeTransfer(msg.sender, left);
                            totalStableTokens -= left;
                        }
                    }
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        0
                    ] = amountMaxInStable;
                    _rewardFulfillRatesByIds[_currentRewardId][strategyName][token][
                        1
                    ] = _totalRewards;
                }
            }
        }
        _currentRewardId++;
        lastRewardsFulfillTimestamp = block.timestamp;
        _history.push(
            History({
                historyType: HistoryType.REWARD,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: totalStableTokens,
                strategyName: strategyName
            })
        );
        emit FulfilledRewards(block.timestamp, strategyName);
    }

    /// @dev calculates withdraw amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return depositedInTokens deposited amount in tokens
    /// @return depositedInStableTokenForTokens deposited amount in stable token for token
    /// @return depositedInStableTokens deposited amount in stable token
    function calculateWithdrawAmountAdmin(string memory strategyName)
        public
        view
        returns (
            uint256[] memory depositedInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256 depositedInStableTokens
        )
    {
        depositedInTokens = new uint256[](_registeredTokens.length);
        depositedInStableTokenForTokens = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            TokenManager memory tm = _tokenManager[
                strategiesParameters[strategyName].withdrawId
            ][strategyName][token];

            uint256 depositedInStableTokenForToken;
            if (address(token) == address(stableToken)) {
                depositedInStableTokenForToken = tm.deposited;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tm.deposited != 0)
                    depositedInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(
                            tm.deposited,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            depositedInTokens[i] = tm.deposited;
            depositedInStableTokenForTokens[i] = depositedInStableTokenForToken;
            depositedInStableTokens += depositedInStableTokenForToken;
        }
    }

    /// @dev calculates withdraw rewards amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return rewardsInTokens
    /// @return rewardsInStable
    /// @return _totalRewards
    function calculateWithdrawAmountAdminRewards(string memory strategyName)
        public
        view
        returns (
            uint256[] memory rewardsInTokens,
            uint256[] memory rewardsInStable,
            uint256 _totalRewards
        )
    {
        rewardsInTokens = new uint256[](_registeredTokens.length);
        rewardsInStable = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            uint256 tokenRewards = totalRewards[strategyName][token];

            uint256 rewardsInStableTokenForTokens;
            if (address(token) == address(stableToken)) {
                rewardsInStableTokenForTokens = tokenRewards;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tokenRewards != 0)
                    rewardsInStableTokenForTokens = _addSlippage(
                        router.getAmountsOut(
                            tokenRewards,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            rewardsInTokens[i] = tokenRewards;
            rewardsInStable[i] = rewardsInStableTokenForTokens;
            _totalRewards += rewardsInStableTokenForTokens;
        }
    }

    /// @dev returns bool flag can be fulfilled deposit from bank
    /// @param depositId id of deposit
    ///
    /// @return can bool flag
    /// @return stableTokenTotal amount of stable tokens to swap
    /// @return totalAmount amount of token to fulfill deposit
    function canWithdraw(uint256 depositId)
        public
        view
        returns (
            bool can,
            uint256 stableTokenTotal,
            uint256 totalAmount
        )
    {
        Deposit memory deposit_ = _deposits[depositId];

        totalAmount = deposit_.deposited;

        // require(totalAmount > 0, 'totalAmount = 0');

        if (address(deposit_.token) == address(stableToken))
            return (
                totalAmount <= stableTokenBank[deposit_.strategyName],
                totalAmount,
                totalAmount
            );

        // else
        uint256[] memory amounts = router.getAmountsOut(
            totalAmount,
            tokensParameters[deposit_.token].swapPath
        );
        stableTokenTotal = _addSlippage(amounts[amounts.length - 1]);
        return (
            stableTokenTotal <= stableTokenBank[deposit_.strategyName],
            stableTokenTotal,
            totalAmount
        );
    }

    /// @dev returns value plus slippage
    /// @param value value for convertion
    ///
    /// @return slippageValue value after convertions
    function _addSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 + slippageX1000)) / 1000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

pragma solidity >=0.6.2;

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

pragma solidity >=0.6.2;

import './IPancakeRouter01.sol';

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}