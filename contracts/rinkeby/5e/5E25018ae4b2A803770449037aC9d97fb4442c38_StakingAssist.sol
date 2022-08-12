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
 * @title Staking
 * @author gotbit
 */

import '@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import {IPancakeRouter02} from 'pancakeswap-peripheral/contracts/interfaces/IPancakeRouter02.sol';

import {StakingShadow} from './StakingShadow.sol';
import './utils/IWETH.sol';

contract Staking is Ownable {
    using SafeERC20 for IERC20Metadata;
    using SafeERC20 for IERC20;
    using Address for address;

    enum Status {
        NULL, // NULL
        DEPOSITED, // User deposits tokens
        REQUESTED, // User requests withdraw
        WITHDRAWED // User withdrawed tokens
    }

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
        Status status;
    }

    enum HistoryType {
        NULL,
        CLAIM,
        FULFILL,
        PURCHASE
    }

    struct History {
        HistoryType historyType;
        uint256 timestamp;
        address user;
        uint256 stableAmount;
        string strategyName;
    }

    // constants
    uint256 public constant YEAR = 360 days;

    // config
    IERC20 public stableToken;
    IPancakeRouter02 public router;
    IWETH public WETH;
    StakingShadow public stakingShadow;

    uint256 public minPeriod = 1 hours;

    // global vars
    // token -> StrategyParamaeters
    mapping(IERC20Metadata => TokenParameters) public tokensParameters;

    // strategyName -> StrategyParamaeters
    mapping(string => StrategyParameters) public strategiesParameters;
    // withdrawId -> strategyName -> token -> TokenManager
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => TokenManager)))
        public tokenManager;
    // strategyName -> token -> isLegalToken
    mapping(string => mapping(IERC20Metadata => bool)) public isLegalToken;
    // token -> deposited
    mapping(IERC20Metadata => uint256) public deposited;

    mapping(address => uint256[]) public userDeposits;

    IERC20Metadata[] private _registeredTokens;
    string[] private _strategies;
    Deposit[] public _deposits;
    uint256 public currentDepositId;
    // strategyName -> bank
    mapping(string => uint256) public stableTokenBank;

    uint256 public slippageX1000 = 20;

    History[] private _history;

    /// MODIFIERS

    /// @dev checks if user is initial depositer
    /// @param depositId id of deposit
    modifier onlyHolder(uint256 depositId) {
        require(msg.sender == _deposits[depositId].user, 'Not owner');
        _;
    }

    /// @dev checks if deposit is exist
    /// @param depositId id of deposit
    modifier exists(uint256 depositId) {
        require(_deposits.length > depositId, 'Not existing');
        _;
    }

    event Deposited(uint256 indexed timestamp, uint256 indexed depositId);
    event Requested(uint256 indexed timestamp, uint256 indexed depositId);
    event Withdrawed(uint256 indexed timestamp, uint256 indexed depositId);
    event ClaimedTokens(
        uint256 indexed timestamp,
        address indexed token,
        uint256 deposit
    );
    event FulfilledDeposited(
        uint256 indexed timestamp,
        string indexed strategyName,
        uint256 withdrawId
    );
    event AddLegalToken(uint256 indexed timestamp, address indexed token);
    event SetLegalTokenForStrategy(
        uint256 indexed timestamp,
        string strategyName,
        address token,
        bool isLegal
    );
    event ChangeSwapPath(uint256 indexed timestamp, address token, address[] newSwapPath);
    event AddStrategy(
        uint256 indexed timestamp,
        string strategyName,
        bool isSafe,
        uint256 rateX1000
    );
    event SetStrategyPause(uint256 indexed timestamp, string strategyName, bool isPause);
    event AddBank(uint256 indexed timestamp, string strategyName, uint256 amount);
    event SetSlippage(uint256 indexed timestamp, uint256 newSlippageX1000);

    constructor(
        IERC20 stableToken_,
        IWETH weth_,
        IPancakeRouter02 router_,
        address owner_,
        StakingShadow stakingShadow_
    ) {
        stableToken = stableToken_;
        WETH = weth_;
        router = router_;
        stakingShadow = stakingShadow_;
        _transferOwnership(owner_);
    }

    receive() external payable {}

    /// USER FUNCTIONS

    /// @dev deposits user's tokens for project
    /// @param strategyName name of selected strategy for deposit
    /// @param amount amount of tokens to deposit
    /// @param period period of deposit
    /// @param token selected token for deposit
    function deposit(
        string memory strategyName,
        uint256 amount,
        uint256 period,
        IERC20Metadata token
    ) external {
        token.safeTransferFrom(msg.sender, address(this), amount);
        _deposit(strategyName, amount, period, token);
    }

    /// @dev deposits native user's tokens for project
    /// @param strategyName name of selected strategy for deposit
    /// @param period period of deposit
    function depositEth(string memory strategyName, uint256 period) external payable {
        uint256 amount = msg.value;
        WETH.deposit{value: amount}();
        _deposit(strategyName, amount, period, IERC20Metadata(address(WETH)));
    }

    /// @dev deposits user's tokens for project
    /// @param strategyName name of selected strategy for deposit
    /// @param amount amount of tokens to deposit
    /// @param period period of deposit
    /// @param token selected token for deposit
    function _deposit(
        string memory strategyName,
        uint256 amount,
        uint256 period,
        IERC20Metadata token
    ) internal {
        require(isLegalToken[strategyName][token], 'Illegal token');
        require(period >= minPeriod, 'period < minPeriod');
        require(amount > 0, 'amount = 0');
        require(!strategiesParameters[strategyName].isPaused, 'Strategy is paused');

        deposited[token] += amount;
        uint256 reward = calculateReward(strategyName, amount, period);

        _deposits.push(
            Deposit({
                id: currentDepositId,
                strategyName: strategyName,
                user: msg.sender,
                token: token,
                deposited: amount,
                reward: reward,
                timestamp: block.timestamp,
                period: period,
                status: Status.DEPOSITED,
                withdrawId: 0,
                endTimestamp: 0
            })
        );
        userDeposits[msg.sender].push(currentDepositId);

        emit Deposited(block.timestamp, currentDepositId);
        currentDepositId++;
    }

    /// @dev requests tokens to withdraw (if enough tokens withdraw)
    /// @param depositId id of target deposit
    function requestWithdraw(uint256 depositId)
        external
        exists(depositId)
        onlyHolder(depositId)
    {
        Deposit storage deposit_ = _deposits[depositId];
        require(deposit_.status == Status.DEPOSITED, 'Is not DEPOSITED');

        if (_withdrawFromBank(depositId)) {
            return;
        }

        uint256 withdrawId = strategiesParameters[deposit_.strategyName].withdrawId;
        deposit_.status = Status.REQUESTED;
        deposit_.withdrawId = withdrawId;
        TokenManager storage tm = tokenManager[withdrawId][deposit_.strategyName][
            deposit_.token
        ];

        tm.deposited += deposit_.deposited;
        if (deposit_.period + deposit_.timestamp <= block.timestamp) {
            tm.reward += deposit_.reward;
        } else {
            uint256 realReward = (deposit_.reward *
                (block.timestamp - deposit_.timestamp)) / deposit_.period;
            deposit_.reward = realReward;
            tm.reward += realReward;
        }

        deposit_.endTimestamp = block.timestamp > deposit_.timestamp + deposit_.period
            ? deposit_.timestamp + deposit_.period
            : block.timestamp;

        emit Requested(block.timestamp, depositId);
    }

    /// @dev withdraws tokens from bank
    /// @param depositId id of target deposit
    /// @param result can or cannot withdraw from bank
    function _withdrawFromBank(uint256 depositId)
        internal
        exists(depositId)
        onlyHolder(depositId)
        returns (bool result)
    {
        Deposit storage deposit_ = _deposits[depositId];
        deposit_.status = Status.WITHDRAWED;

        (bool can, uint256 stableTokenTotal, uint256 totalAmount) = canWithdraw(
            depositId
        );
        if (!can) return false;

        stableToken.approve(address(router), stableTokenTotal);
        if (address(deposit_.token) == address(WETH))
            stableTokenBank[deposit_.strategyName] -= router.swapTokensForExactETH(
                totalAmount,
                stableTokenTotal,
                tokensParameters[deposit_.token].reverseSwapPath,
                msg.sender,
                block.timestamp
            )[0];
        else if (address(deposit_.token) == address(stableToken))
            IERC20(deposit_.token).safeTransfer(msg.sender, totalAmount);
        else {
            stableTokenBank[deposit_.strategyName] -= router.swapTokensForExactTokens(
                totalAmount,
                stableTokenTotal,
                tokensParameters[deposit_.token].reverseSwapPath,
                msg.sender,
                block.timestamp
            )[0];
        }

        deposit_.endTimestamp = block.timestamp > deposit_.timestamp + deposit_.period
            ? deposit_.timestamp + deposit_.period
            : block.timestamp;
        deposit_.reward = totalAmount - deposit_.deposited;

        emit Withdrawed(block.timestamp, depositId);
        return true;
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
        exists(depositId)
        returns (
            bool can,
            uint256 stableTokenTotal,
            uint256 totalAmount
        )
    {
        Deposit memory deposit_ = _deposits[depositId];

        totalAmount = deposit_.deposited;
        if (deposit_.period + deposit_.timestamp <= block.timestamp)
            totalAmount += deposit_.reward;
        else
            totalAmount +=
                (deposit_.reward * (block.timestamp - deposit_.timestamp)) /
                deposit_.period;

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

    /// @dev withdraws tokens (if enough tokens withdraw)
    /// @param depositId id of target deposit
    function withdraw(uint256 depositId)
        external
        exists(depositId)
        onlyHolder(depositId)
    {
        Deposit storage deposit_ = _deposits[depositId];
        require(deposit_.status == Status.REQUESTED, 'Is not REQUESTED');
        require(
            tokenManager[deposit_.withdrawId][deposit_.strategyName][deposit_.token]
                .bank
                .fulfilled,
            'Not proceed'
        );

        uint256 transferAmount = calculateWithdrawAmount(depositId);
        // require(transferAmount > 0, 'Zero transfer amount');

        deposit_.status = Status.WITHDRAWED;
        if (address(deposit_.token) != address(WETH))
            deposit_.token.safeTransfer(msg.sender, transferAmount);
        else {
            WETH.withdraw(transferAmount);
            payable(msg.sender).transfer(transferAmount);
        }

        emit Withdrawed(block.timestamp, depositId);
    }

    /// ADMIN FUNCTIONS

    /// @dev claims tokens from deposits (ONLY OWNER)
    function claimTokens(uint256 maxStableAmount) external onlyOwner {
        require(maxStableAmount > 0, 'max = 0');

        uint256 length = _registeredTokens.length;
        uint256 totalStableAmount = 0;
        for (uint256 i; i < length; i++) {
            if (totalStableAmount == maxStableAmount) break;

            IERC20Metadata token = _registeredTokens[i];
            uint256 tokenDeposit = deposited[token];
            if (tokenDeposit == 0) continue;

            uint256 stableAmount = 0;
            if (address(token) == address(stableToken)) {
                stableAmount = tokenDeposit;

                if (stableAmount + totalStableAmount > maxStableAmount) {
                    stableAmount = tokenDeposit = maxStableAmount - totalStableAmount; // stable to stable
                    stableToken.safeTransfer(msg.sender, stableAmount);
                    deposited[token] -= tokenDeposit;
                    totalStableAmount += stableAmount;

                    emit ClaimedTokens(block.timestamp, address(token), stableAmount);
                    break;
                } else {
                    stableToken.safeTransfer(msg.sender, stableAmount);
                    deposited[token] = 0;
                }
            } else {
                stableAmount = router.getAmountsOut(
                    tokenDeposit,
                    tokensParameters[token].swapPath
                )[tokensParameters[token].swapPath.length - 1];

                token.approve(address(router), tokenDeposit);
                if (stableAmount + totalStableAmount > maxStableAmount) {
                    stableAmount = maxStableAmount - totalStableAmount;

                    tokenDeposit = router.getAmountsOut( // tokenDeposit < tokenDeposit old
                        stableAmount,
                        tokensParameters[token].reverseSwapPath
                    )[tokensParameters[token].reverseSwapPath.length - 1];

                    uint256[] memory amounts = router.swapExactTokensForTokens(
                        tokenDeposit,
                        _subSlippage(stableAmount),
                        tokensParameters[token].swapPath,
                        msg.sender,
                        block.timestamp
                    );

                    stableAmount = amounts[amounts.length - 1];
                    totalStableAmount += stableAmount;
                    deposited[token] -= amounts[0];

                    emit ClaimedTokens(block.timestamp, address(token), stableAmount);
                    break;
                } else {
                    uint256[] memory amounts = router.swapExactTokensForTokens(
                        tokenDeposit,
                        _subSlippage(stableAmount),
                        tokensParameters[token].swapPath,
                        msg.sender,
                        block.timestamp
                    );
                    stableAmount = amounts[amounts.length - 1];
                    deposited[token] = 0;
                }
            }
            totalStableAmount += stableAmount;
            emit ClaimedTokens(block.timestamp, address(token), stableAmount);
        }
        require(totalStableAmount > 0, 'Nothing to claim');
        _history.push(
            History({
                historyType: HistoryType.CLAIM,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: totalStableAmount,
                strategyName: ''
            })
        );
    }

    /// @dev fulfills pending requests for rewards (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillDeposited(string memory strategyName, uint256 amountMaxInStable)
        external
        onlyOwner
    {
        address(stakingShadow).functionDelegateCall(
            abi.encodeCall(
                StakingShadow.fulfillDeposited,
                (strategyName, amountMaxInStable)
            )
        );
    }

    /// @dev calculates withdraw amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return depositedInTokens deposited amount in tokens
    /// @return rewardInTokens reward amount in tokens
    /// @return depositedInStableTokenForTokens deposited amount in stable token for token
    /// @return rewardInStableTokenForTokens reward amount in stable token for token
    /// @return depositedInStableTokens deposited amount in stable token
    /// @return rewardInStableTokens reward amount in stable token
    function calculateWithdrawAmountAdmin(string memory strategyName)
        public
        view
        returns (
            uint256[] memory depositedInTokens,
            uint256[] memory rewardInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256[] memory rewardInStableTokenForTokens,
            uint256 depositedInStableTokens,
            uint256 rewardInStableTokens
        )
    {
        depositedInTokens = new uint256[](_registeredTokens.length);
        rewardInTokens = new uint256[](_registeredTokens.length);
        depositedInStableTokenForTokens = new uint256[](_registeredTokens.length);
        rewardInStableTokenForTokens = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            TokenManager memory tm = tokenManager[
                strategiesParameters[strategyName].withdrawId
            ][strategyName][token];

            uint256 depositedInStableTokenForToken;
            uint256 rewardInStableTokenForToken;
            if (address(token) == address(stableToken)) {
                depositedInStableTokenForToken = tm.deposited;
                rewardInStableTokenForToken = tm.reward;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tm.deposited != 0)
                    depositedInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(
                            tm.deposited,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );

                if (tm.reward != 0)
                    rewardInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(tm.reward, tokensParameters[token].swapPath)[
                            lastIndex
                        ]
                    );
            }
            depositedInTokens[i] = tm.deposited;
            rewardInTokens[i] = tm.reward;
            depositedInStableTokenForTokens[i] = depositedInStableTokenForToken;
            rewardInStableTokenForTokens[i] = rewardInStableTokenForToken;
            depositedInStableTokens += depositedInStableTokenForToken;
            rewardInStableTokens += rewardInStableTokenForToken;
        }
    }

    /// @dev returns value plus slippage
    /// @param value value for convertion
    ///
    /// @return slippageValue value after convertions
    function _addSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 + slippageX1000)) / 1000;
    }

    /// @dev returns value minus slippage
    /// @param value value for multiplying
    ///
    /// @return slippageValue value after convertions
    function _subSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 - slippageX1000)) / 1000;
    }

    /// CONFIG FUNCTIONS

    /// @dev registers new token (ONLY OWNER)
    /// @param token address of token to register
    /// @param swapPath path for swap to stable token
    function registerToken(IERC20Metadata token, address[] memory swapPath)
        external
        onlyOwner
    {
        require(isCorrectSwapPath(token, swapPath), 'Wrong swap path');
        require(address(tokensParameters[token].token) == address(0), 'Token added');

        _registeredTokens.push(token);
        tokensParameters[token] = TokenParameters({
            token: token,
            swapPath: swapPath,
            reverseSwapPath: reversePath(swapPath),
            symbol: token.symbol(),
            name: token.name(),
            decimals: token.decimals()
        });

        emit AddLegalToken(block.timestamp, address(token));
    }

    /// @dev sets legal tokens for specific strategy
    /// @param strategyName name of strategy
    /// @param token token address
    /// @param isLegal is legal or not
    function setTokenForStrategy(
        string memory strategyName,
        IERC20Metadata token,
        bool isLegal
    ) external onlyOwner {
        require(
            tokensParameters[token].token != IERC20Metadata(address(0)),
            'unregistered token'
        );
        require(isLegalToken[strategyName][token] != isLegal, 'Same isLegal');
        isLegalToken[strategyName][token] = isLegal;

        emit SetLegalTokenForStrategy(
            block.timestamp,
            strategyName,
            address(token),
            isLegal
        );
    }

    /// @dev changes legal token's swap path (checks last item of path equals to `token`) (ONLY OWNER)
    /// @param token address of token
    /// @param newSwapPath new swap path to stable token for token
    function changeSwapPath(IERC20Metadata token, address[] memory newSwapPath)
        external
        onlyOwner
    {
        require(
            tokensParameters[token].token != IERC20Metadata(address(0)),
            'unregistered token'
        );
        require(isCorrectSwapPath(token, newSwapPath), 'Wrong swap path');
        if (newSwapPath.length == tokensParameters[token].swapPath.length) {
            uint256 length = newSwapPath.length;
            bool different = true;
            for (uint256 i; i < length; i++)
                different =
                    tokensParameters[token].swapPath[i] == newSwapPath[i] &&
                    different;
            require(!different, 'Spaw path same');
        }
        tokensParameters[token] = TokenParameters({
            token: token,
            swapPath: newSwapPath,
            reverseSwapPath: reversePath(newSwapPath),
            symbol: token.symbol(),
            name: token.name(),
            decimals: token.decimals()
        });

        emit ChangeSwapPath(block.timestamp, address(token), newSwapPath);
    }

    /// @dev adds new strategy for deposit (ONLY OWNER)
    /// @param strategyName name of strategy
    /// @param isSafe always gets deposit + reward or not
    /// @param rateX1000 rate of strategy multiply by 1000
    function addStrategy(
        string memory strategyName,
        bool isSafe,
        uint256 rateX1000
    ) external onlyOwner {
        require(
            strategiesParameters[strategyName].rateX1000 == 0,
            'Name must be different'
        );
        strategiesParameters[strategyName] = StrategyParameters({
            name: strategyName,
            isSafe: isSafe,
            rateX1000: rateX1000,
            isPaused: false,
            withdrawId: 1
        });
        _strategies.push(strategyName);

        emit AddStrategy(block.timestamp, strategyName, isSafe, rateX1000);
    }

    /// @dev sets pause for strategy (ONLY OWNER)
    /// @param strategyName name of strategy to be removed
    /// @param isPause name of strategy to be removed
    function setStrategyPause(string memory strategyName, bool isPause)
        external
        onlyOwner
    {
        require(strategiesParameters[strategyName].isPaused != isPause, 'Same pause');
        strategiesParameters[strategyName].isPaused = isPause;

        emit SetStrategyPause(block.timestamp, strategyName, isPause);
    }

    /// @dev transfer from owner stable tokens for fulfilling
    /// @param amount amount of transferable stable tokens
    function purchaseStableTokens(string memory strategyName, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, 'amount = 0');
        require(
            strategiesParameters[strategyName].rateX1000 != 0,
            'Strategy is not exist'
        );
        stableToken.safeTransferFrom(msg.sender, address(this), amount);
        stableTokenBank[strategyName] += amount;

        _history.push(
            History({
                historyType: HistoryType.PURCHASE,
                timestamp: block.timestamp,
                user: msg.sender,
                stableAmount: amount,
                strategyName: strategyName
            })
        );

        emit AddBank(block.timestamp, strategyName, amount);
    }

    /// @dev sets new value of slippage
    /// @param newSlippageX1000 new value of slippage multiply by 1000
    function setSlippage(uint256 newSlippageX1000) external onlyOwner {
        slippageX1000 = newSlippageX1000;
        emit SetSlippage(block.timestamp, newSlippageX1000);
    }

    /// UTILITY FUNCTIONS

    /// @dev reverses path
    /// @param path path for swap
    ///
    /// @return reversePath reverse path for swap
    function reversePath(address[] memory path) public pure returns (address[] memory) {
        uint256 length = path.length;
        address[] memory reversePath_ = new address[](length);
        for (uint256 i; i < length; i++) reversePath_[length - i - 1] = path[i];
        return reversePath_;
    }

    /// @dev calculates reward for deposit
    /// @param strategyName name of depost's strategy
    /// @param amount amount of tokens
    /// @param period to deposit
    function calculateReward(
        string memory strategyName,
        uint256 amount,
        uint256 period
    ) public view returns (uint256) {
        return
            (strategiesParameters[strategyName].rateX1000 * amount * period) /
            (1000 * YEAR);
    }

    /// @dev calculates total withdraw amount for deposit
    /// @param depositId id of deposit
    ///
    /// @return withdrawAmount amount to withdraw
    function calculateWithdrawAmount(uint256 depositId)
        public
        view
        exists(depositId)
        returns (uint256)
    {
        Deposit memory deposit_ = _deposits[depositId];
        if (deposit_.status == Status.DEPOSITED)
            return
                deposit_.deposited +
                (deposit_.reward * (block.timestamp - deposit_.timestamp)) /
                deposit_.period;

        TokenManager memory tm = tokenManager[deposit_.withdrawId][deposit_.strategyName][
            deposit_.token
        ];

        if (!tm.bank.fulfilled && deposit_.status == Status.REQUESTED)
            return deposit_.deposited + deposit_.reward;
        if (deposit_.withdrawId == 0 && deposit_.status == Status.WITHDRAWED)
            return deposit_.deposited + deposit_.reward;

        uint256 transferAmount;
        if (strategiesParameters[deposit_.strategyName].isSafe) {
            transferAmount = deposit_.deposited + deposit_.reward;
        } else if (tm.bank.fullDeposited && tm.bank.fullReward) {
            transferAmount = deposit_.deposited + deposit_.reward;
        } else if (tm.bank.fullDeposited && !tm.bank.fullReward) {
            uint256 reward = (deposit_.reward * tm.bank.reward) / tm.reward;
            transferAmount = deposit_.deposited + reward;
        } else {
            transferAmount = (deposit_.deposited * tm.bank.deposited) / tm.deposited;
        }

        return transferAmount;
    }

    /// @dev checks if swap path is correct
    /// @param token token to swap
    /// @param swapPath path for swap
    ///
    /// @return isCorrect is correct
    function isCorrectSwapPath(IERC20Metadata token, address[] memory swapPath)
        public
        view
        returns (bool)
    {
        if (swapPath.length == 0 && address(token) == address(stableToken)) return true;
        router.getAmountsOut(10**token.decimals(), swapPath);
        return
            swapPath[0] == address(token) &&
            swapPath[swapPath.length - 1] == address(stableToken);
    }

    // /// INFO FUNCTIONS

    /// @dev returns parameters for token
    /// @param token address of token
    ///
    /// @return tokenParameter token parameter
    function getTokenParameters(IERC20Metadata token)
        external
        view
        returns (TokenParameters memory)
    {
        return tokensParameters[token];
    }

    /// @dev returns token manager
    /// @param withdrawId id of withdraw
    /// @param strategyName name of strategy
    /// @param token address of token
    ///
    /// @return tokenManager token manager
    function getTokenManager(
        uint256 withdrawId,
        string memory strategyName,
        IERC20Metadata token
    ) external view returns (TokenManager memory) {
        return tokenManager[withdrawId][strategyName][token];
    }

    /// @dev returns list of users deposits
    ///
    /// @return userDeposits list of user deposits
    function getStrategyNames() external view returns (string[] memory) {
        return _strategies;
    }

    /// @dev returns list of users deposits
    /// @param user address user
    ///
    /// @return userDeposits list of user deposits
    function getUserDeposits(address user) external view returns (uint256[] memory) {
        return userDeposits[user];
    }

    /// @dev returns list of deposits
    ///
    /// @return depostis list of deposits
    function getDeposits() external view returns (Deposit[] memory) {
        return _deposits;
    }

    /// @dev returns list of registered tokens
    ///
    /// @return depostis list of registered tokens
    function getRegistredTokens() external view returns (IERC20Metadata[] memory) {
        return _registeredTokens;
    }

    /// @dev returns history of tx
    ///
    /// @return history history of tx
    function getHistory() external view returns (History[] memory) {
        return _history;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title StakingAssist
 * @author gotbit
 */

import './Staking.sol';

contract StakingAssist {
    Staking public staking;

    struct AdminInfo {
        Staking.StrategyParameters strategy;
        uint256 depositedAmountDeposits;
        uint256 requestedAmountDeposits;
        uint256 totalToClaim;
        uint256 depositStable;
        uint256 rewardStable;
    }

    struct TokenPrice {
        address token;
        string name;
        string symbol;
        uint8 decimals;
        uint256 stableAmount;
    }

    constructor(Staking staking_) {
        staking = staking_;
    }

    /// @dev returns list of strategies
    ///
    /// @return strategies list of strategies
    function getStrategies() public view returns (Staking.StrategyParameters[] memory) {
        string[] memory strategies = staking.getStrategyNames();
        uint256 length = strategies.length;

        Staking.StrategyParameters[]
            memory strategiesParameters_ = new Staking.StrategyParameters[](length);
        for (uint256 i; i < length; ++i) {
            (
                string memory name,
                bool isSafe,
                uint256 rateX1000,
                bool isPaused,
                uint256 withdrawId
            ) = staking.strategiesParameters(strategies[i]);
            strategiesParameters_[i] = Staking.StrategyParameters({
                name: name,
                isSafe: isSafe,
                rateX1000: rateX1000,
                isPaused: isPaused,
                withdrawId: withdrawId
            });
        }
        return strategiesParameters_;
    }

    /// @dev returns list of strategies
    /// @param strategyName name of strategy
    ///
    /// @return tokens list of available tokens
    function getStrategyTokens(string memory strategyName)
        external
        view
        returns (Staking.TokenParameters[] memory)
    {
        IERC20Metadata[] memory tokens = staking.getRegistredTokens();
        uint256 tokenLength = tokens.length;
        uint256 length;

        for (uint256 i; i < tokenLength; ++i)
            if (staking.isLegalToken(strategyName, tokens[i])) ++length;

        Staking.TokenParameters[] memory tokensParameters = new Staking.TokenParameters[](
            length
        );
        uint256 realIndex;
        for (uint256 i; i < tokenLength; ++i)
            if (staking.isLegalToken(strategyName, tokens[i])) {
                (
                    IERC20Metadata token,
                    string memory symbol,
                    string memory name,
                    uint256 decimals
                ) = staking.tokensParameters(tokens[i]);
                tokensParameters[realIndex].token = token;
                tokensParameters[realIndex].symbol = symbol;
                tokensParameters[realIndex].name = name;
                tokensParameters[realIndex].decimals = decimals;
                ++realIndex;
            }
        return tokensParameters;
    }

    /// @dev returns list of admin info per strategy
    ///
    /// @return adminInfos list of admin info per strategy
    function getAdminInfo() external view returns (AdminInfo[] memory) {
        uint256 totalToClaim = _totalToClaim();

        Staking.StrategyParameters[] memory strategies = getStrategies();
        uint256 length = strategies.length;
        AdminInfo[] memory adminInfos = new AdminInfo[](length);

        for (uint256 i; i < length; ++i) {
            string memory strategyName = strategies[i].name;

            (
                ,
                ,
                ,
                ,
                uint256 depositedInStableTokens,
                uint256 rewardInStableTokens
            ) = staking.calculateWithdrawAmountAdmin(strategyName);

            adminInfos[i] = AdminInfo({
                strategy: strategies[i],
                depositedAmountDeposits: _amountOfDeposits(
                    strategyName,
                    Staking.Status.DEPOSITED
                ),
                requestedAmountDeposits: _amountOfDeposits(
                    strategyName,
                    Staking.Status.REQUESTED
                ),
                totalToClaim: totalToClaim,
                depositStable: depositedInStableTokens,
                rewardStable: rewardInStableTokens
            });
        }
        return adminInfos;
    }

    /// @dev returns list of deposits of user with `status` from `offset` to `offset` + `limit`
    /// @param user address of user
    /// @param status status of deposit (Status.NULL returns all deposit)
    /// @param offset start index
    /// @param limit length of list
    ///
    /// @return deposits list of deposits of user with status
    function getUserDepositsStatus(
        address user,
        Staking.Status status,
        uint256 offset,
        uint256 limit
    ) external view returns (Staking.Deposit[] memory) {
        uint256[] memory userDeposits = staking.getUserDeposits(user);
        Staking.Deposit[] memory deposits = staking.getDeposits();

        Staking.Deposit[] memory deposits_ = new Staking.Deposit[](limit);

        if (status == Staking.Status.NULL) {
            for (uint256 i; i < limit; ++i) {
                if (userDeposits.length <= offset + i) break;
                deposits_[i] = deposits[userDeposits[offset + i]];
            }
        } else {
            // find real offset (takes count the status)
            uint256 realOffset = 0;
            for (uint256 i; i < userDeposits.length; ++i) {
                if (realOffset >= offset) break; // edge case: offset == 0
                if (deposits[userDeposits[i]].status == status) ++realOffset;
            }

            uint256 realIndex = 0;
            for (uint256 i; i < userDeposits.length; ++i) {
                if (realOffset + i >= userDeposits.length || i >= limit) break;
                if (deposits[userDeposits[realOffset + i]].status == status)
                    deposits_[realIndex++] = deposits[userDeposits[realOffset + i]];
            }
        }
        return deposits_;
    }

    /// @dev returns list of history with `historyType` from `offset` to `offset` + `limit`
    /// @param historyType status of deposit (Status.NULL returns all deposit)
    /// @param offset start index
    /// @param limit length of list
    ///
    /// @return history list of history with type
    function getHistoryType(
        Staking.HistoryType historyType,
        uint256 offset,
        uint256 limit
    ) external view returns (Staking.History[] memory) {
        Staking.History[] memory history = staking.getHistory();
        Staking.History[] memory history_ = new Staking.History[](limit);

        if (historyType == Staking.HistoryType.NULL) {
            for (uint256 i; i < limit; ++i) {
                if (history.length <= offset + i) break;
                history_[i] = history[offset + i];
            }
        } else {
            // find real offset (takes count the type)
            uint256 realOffset = 0;
            for (uint256 i; i < history.length; ++i) {
                if (realOffset >= offset) break; // edge case: offset == 0
                if (history[i].historyType == historyType) ++realOffset;
            }

            uint256 realIndex = 0;
            for (uint256 i; i < history.length; ++i) {
                if (realOffset + i >= history.length || i >= limit) break;
                if (history[realOffset + i].historyType == historyType)
                    history_[realIndex++] = history[realOffset + i];
            }
        }
        return history_;
    }

    /// @dev returns list of tokens' prices
    ///
    /// @return tokenPrices list of tokens' prices
    function getTokenPrices() external view returns (TokenPrice[] memory) {
        IERC20Metadata[] memory tokens = staking.getRegistredTokens();
        uint256 length = tokens.length;
        TokenPrice[] memory tokenPrices = new TokenPrice[](length);
        for (uint256 i; i < length; ++i) {
            if (address(tokens[i]) == address(staking.stableToken())) {
                tokenPrices[i] = TokenPrice({
                    token: address(tokens[i]),
                    name: tokens[i].name(),
                    symbol: tokens[i].symbol(),
                    decimals: tokens[i].decimals(),
                    stableAmount: 10**tokens[i].decimals()
                });
            } else {
                uint256 decimalsHalf = tokens[i].decimals() / 2;
                uint256[] memory amounts = staking.router().getAmountsOut(
                    10**(tokens[i].decimals() - decimalsHalf),
                    staking.getTokenParameters(tokens[i]).swapPath
                );
                tokenPrices[i] = TokenPrice({
                    token: address(tokens[i]),
                    name: tokens[i].name(),
                    symbol: tokens[i].symbol(),
                    decimals: tokens[i].decimals(),
                    stableAmount: amounts[amounts.length - 1] * 10**decimalsHalf
                });
            }
        }
        return tokenPrices;
    }

    /// @dev returns deposit amount in token for strategy
    /// @param strategyName name of strategy
    /// @param token address of token
    ///
    /// @return deposit amount of deposits in token
    /// @return reward amount of rewards in token
    function getDepositAmount(string memory strategyName, address token)
        external
        view
        returns (uint256 deposit, uint256 reward)
    {
        Staking.Deposit[] memory deposits = staking.getDeposits();
        uint256 length = deposits.length;

        for (uint256 i; i < length; ++i) {
            if (!_stringEq(deposits[i].strategyName, strategyName)) continue;
            if (address(deposits[i].token) != token) continue;
            if (deposits[i].status != Staking.Status.DEPOSITED) continue;

            deposit += deposits[i].deposited;
            reward += deposits[i].reward;
        }
    }

    /// @dev returns amount of stable tokens to claim by admin
    ///
    /// @return totalStableAmount amount of stable token can be claimed by admin
    function _totalToClaim() internal view returns (uint256) {
        IERC20Metadata[] memory registeredTokens = staking.getRegistredTokens();

        uint256 length = registeredTokens.length;
        uint256 totalStableAmount = 0;
        for (uint256 i; i < length; i++) {
            IERC20Metadata token = registeredTokens[i];
            uint256 tokenDeposit = staking.deposited(token);
            if (tokenDeposit == 0) continue;

            uint256 stableAmount = 0;
            if (address(token) == address(staking.stableToken())) {
                stableAmount = tokenDeposit;
            } else {
                stableAmount = staking.router().getAmountsOut(
                    tokenDeposit,
                    staking.getTokenParameters(token).swapPath
                )[staking.getTokenParameters(token).swapPath.length - 1];
            }
            totalStableAmount += stableAmount;
        }
        return totalStableAmount;
    }

    /// @dev returns amount of deposit in strategy with status
    /// @param strategyName name of strategy
    /// @param status status of deposit
    ///
    /// @return amount of deposits
    function _amountOfDeposits(string memory strategyName, Staking.Status status)
        internal
        view
        returns (uint256)
    {
        uint256 amount;
        Staking.Deposit[] memory deposits = staking.getDeposits();
        uint256 length = deposits.length;
        for (uint256 i; i < length; ++i)
            if (
                deposits[i].status == status &&
                _stringEq(deposits[i].strategyName, strategyName)
            ) ++amount;
        return amount;
    }

    /// @dev compare two strings
    /// @param s1 first string
    /// @param s2 second string
    ///
    /// @return equality of strings
    function _stringEq(string memory s1, string memory s2) internal pure returns (bool) {
        return keccak256(abi.encodePacked(s1)) == keccak256(abi.encodePacked(s2));
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

    enum HistoryType {
        NULL,
        CLAIM,
        FULFILL,
        PURCHASE
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
        private tokenManager;

    uint256[3] private gap1;

    IERC20Metadata[] private _registeredTokens;

    uint256[4] private gap2;

    uint256 private slippageX1000 = 20;
    History[] private _history;

    /// -------------------------------------------

    event FulfilledDeposited(
        uint256 indexed timestamp,
        string indexed strategyName,
        uint256 withdrawId
    );

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
            uint256[] memory rewardInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256[] memory rewardInStableTokenForTokens,
            uint256 depositedInStableTokens,
            uint256 rewardInStableTokens
        ) = calculateWithdrawAmountAdmin(strategyName);

        uint256 length = _registeredTokens.length;
        uint256 totalStableTokens = amountMaxInStable;

        require(depositedInStableTokens + rewardInStableTokens > 0, 'Nothing fulfill');
        stableToken.approve(address(router), amountMaxInStable);

        if (
            strategiesParameters[strategyName].isSafe ||
            depositedInStableTokens + rewardInStableTokens <= amountMaxInStable
        ) {
            require(
                depositedInStableTokens + rewardInStableTokens <= amountMaxInStable,
                'need > max'
            );
            totalStableTokens = depositedInStableTokens + rewardInStableTokens;
            stableToken.safeTransferFrom(
                msg.sender,
                address(this),
                depositedInStableTokens + rewardInStableTokens
            );

            for (uint256 i; i < length; i++) {
                IERC20Metadata token = _registeredTokens[i];
                TokenManager storage tm = tokenManager[withdrawId][strategyName][token];

                tm.bank.deposited = depositedInTokens[i];
                tm.bank.reward = rewardInTokens[i];

                uint256 amountOut = tm.bank.deposited + tm.bank.reward;
                uint256 amountInMax = depositedInStableTokenForTokens[i] +
                    rewardInStableTokenForTokens[i];
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
                tm.bank.fullReward = true;
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
            stableToken.safeTransferFrom(msg.sender, address(this), amountMaxInStable);

            if (depositedInStableTokens <= amountMaxInStable) {
                uint256 lessRewardInStable = amountMaxInStable - depositedInStableTokens;
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = tokenManager[withdrawId][strategyName][
                        token
                    ];
                    tm.bank.deposited = depositedInTokens[i];
                    tm.bank.reward =
                        (lessRewardInStable * rewardInTokens[i]) /
                        rewardInStableTokens;

                    uint256 amountOut = tm.bank.deposited + tm.bank.reward;
                    uint256 amountInMax = depositedInStableTokenForTokens[i] +
                        (lessRewardInStable * rewardInStableTokenForTokens[i]) /
                        rewardInStableTokens;

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
                    tm.bank.fullReward = false;
                }
            } else {
                uint256 lessDepositedInStable = amountMaxInStable;
                for (uint256 i; i < length; i++) {
                    IERC20Metadata token = _registeredTokens[i];
                    TokenManager storage tm = tokenManager[withdrawId][strategyName][
                        token
                    ];

                    tm.bank.deposited =
                        (lessDepositedInStable * depositedInTokens[i]) /
                        depositedInStableTokens;
                    tm.bank.reward = 0;

                    uint256 amountOut = tm.bank.deposited + tm.bank.reward;
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
                    tm.bank.fullReward = false;
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

    /// @dev calculates withdraw amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    ///
    /// @return depositedInTokens deposited amount in tokens
    /// @return rewardInTokens reward amount in tokens
    /// @return depositedInStableTokenForTokens deposited amount in stable token for token
    /// @return rewardInStableTokenForTokens reward amount in stable token for token
    /// @return depositedInStableTokens deposited amount in stable token
    /// @return rewardInStableTokens reward amount in stable token
    function calculateWithdrawAmountAdmin(string memory strategyName)
        public
        view
        returns (
            uint256[] memory depositedInTokens,
            uint256[] memory rewardInTokens,
            uint256[] memory depositedInStableTokenForTokens,
            uint256[] memory rewardInStableTokenForTokens,
            uint256 depositedInStableTokens,
            uint256 rewardInStableTokens
        )
    {
        depositedInTokens = new uint256[](_registeredTokens.length);
        rewardInTokens = new uint256[](_registeredTokens.length);
        depositedInStableTokenForTokens = new uint256[](_registeredTokens.length);
        rewardInStableTokenForTokens = new uint256[](_registeredTokens.length);

        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            TokenManager memory tm = tokenManager[
                strategiesParameters[strategyName].withdrawId
            ][strategyName][token];

            uint256 depositedInStableTokenForToken;
            uint256 rewardInStableTokenForToken;
            if (address(token) == address(stableToken)) {
                depositedInStableTokenForToken = tm.deposited;
                rewardInStableTokenForToken = tm.reward;
            } else {
                uint256 lastIndex = tokensParameters[token].swapPath.length - 1;

                if (tm.deposited != 0)
                    depositedInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(
                            tm.deposited,
                            tokensParameters[token].swapPath
                        )[lastIndex]
                    );

                if (tm.reward != 0)
                    rewardInStableTokenForToken = _addSlippage(
                        router.getAmountsOut(tm.reward, tokensParameters[token].swapPath)[
                            lastIndex
                        ]
                    );
            }
            depositedInTokens[i] = tm.deposited;
            rewardInTokens[i] = tm.reward;
            depositedInStableTokenForTokens[i] = depositedInStableTokenForToken;
            rewardInStableTokenForTokens[i] = rewardInStableTokenForToken;
            depositedInStableTokens += depositedInStableTokenForToken;
            rewardInStableTokens += rewardInStableTokenForToken;
        }
    }

    /// @dev returns value plus slippage
    /// @param value value for convertion
    ///
    /// @return slippageValue value after convertions
    function _addSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 + slippageX1000)) / 1000;
    }

    /// @dev returns value minus slippage
    /// @param value value for multiplying
    ///
    /// @return slippageValue value after convertions
    function _subSlippage(uint256 value) internal view returns (uint256 slippageValue) {
        return (value * (1000 - slippageX1000)) / 1000;
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