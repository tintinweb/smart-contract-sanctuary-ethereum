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
        uint256 lastRewardId;
        Status status;
    }

    enum HistoryType {
        NULL,
        CLAIM,
        FULFILL,
        PURCHASE,
        REWARDS
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
    IERC20 private _stableToken;
    IPancakeRouter02 private _router;
    IWETH private _WETH;
    StakingShadow private _stakingShadow;

    uint256 public minPeriod = 1 hours;

    // global vars
    // token -> StrategyParamaeters
    mapping(IERC20Metadata => TokenParameters) private _tokensParameters;

    // strategyName -> StrategyParamaeters
    mapping(string => StrategyParameters) public strategiesParameters;
    // withdrawId -> strategyName -> token -> TokenManager
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => TokenManager)))
        private _tokenManager;
    // strategyName -> token -> isLegalToken
    mapping(string => mapping(IERC20Metadata => bool)) public isLegalToken;
    // token -> deposited
    mapping(IERC20Metadata => uint256) private _deposited;
    // strategyName -> token -> totalRewards
    mapping(string => mapping(IERC20Metadata => uint256)) public totalRewards;
    // rewardId -> strategyName -> token -> [rateNumerator, rateDenominator]
    mapping(uint256 => mapping(string => mapping(IERC20Metadata => uint256[2])))
        private _rewardFulfillRatesByIds;
    uint256 private _currentRewardId;
    uint256 public lastRewardsFulfillTimestamp;
    uint256 claimOffset = 5 days;
    mapping(address => uint256[]) private _userDeposits;

    IERC20Metadata[] private _registeredTokens;
    string[] private _strategies;
    Deposit[] private _deposits;
    uint256 private _currentDepositId;
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
    event FulfilledRewards(uint256 indexed timestamp, string indexed strategyName);
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
        _stableToken = stableToken_;
        _WETH = weth_;
        _router = router_;
        _stakingShadow = stakingShadow_;
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
        _WETH.deposit{value: amount}();
        _deposit(strategyName, amount, period, IERC20Metadata(address(_WETH)));
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

        _deposited[token] += amount;
        uint256 reward = calculateReward(strategyName, amount, period);

        _deposits.push(
            Deposit({
                id: _currentDepositId,
                strategyName: strategyName,
                user: msg.sender,
                token: token,
                deposited: amount,
                reward: reward,
                timestamp: block.timestamp,
                period: period,
                status: Status.DEPOSITED,
                withdrawId: 0,
                lastRewardId: _currentRewardId,
                endTimestamp: 0
            })
        );
        _userDeposits[msg.sender].push(_currentDepositId);
        totalRewards[strategyName][token] += reward;

        emit Deposited(block.timestamp, _currentDepositId);
        _currentDepositId++;
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
        TokenManager storage tm = _tokenManager[withdrawId][deposit_.strategyName][
            deposit_.token
        ];

        tm.deposited += deposit_.deposited;

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
        (bool _canClaim, string memory message) = canClaim(depositId);
        if (
            _canClaim ||
            keccak256(abi.encodePacked(message)) !=
            keccak256(abi.encodePacked('first claim after 30 days'))
        ) _claim(depositId);

        deposit_.status = Status.WITHDRAWED;

        (bool can, uint256 stableTokenTotal, uint256 totalAmount) = canWithdraw(
            depositId
        );
        if (!can) return false;

        _stableToken.approve(address(_router), stableTokenTotal);
        if (address(deposit_.token) == address(_WETH))
            stableTokenBank[deposit_.strategyName] -= _router.swapTokensForExactETH(
                totalAmount,
                stableTokenTotal,
                _tokensParameters[deposit_.token].reverseSwapPath,
                msg.sender,
                block.timestamp
            )[0];
        else if (address(deposit_.token) == address(_stableToken))
            IERC20(deposit_.token).safeTransfer(msg.sender, totalAmount);
        else {
            stableTokenBank[deposit_.strategyName] -= _router.swapTokensForExactTokens(
                totalAmount,
                stableTokenTotal,
                _tokensParameters[deposit_.token].reverseSwapPath,
                msg.sender,
                block.timestamp
            )[0];
        }

        deposit_.endTimestamp = block.timestamp > deposit_.timestamp + deposit_.period
            ? deposit_.timestamp + deposit_.period
            : block.timestamp;

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
        exists(depositId)
        returns (
            bool can,
            uint256 stableTokenTotal,
            uint256 totalAmount
        )
    {
        bytes memory returnedData = address(_stakingShadow).functionDelegateCall(
            abi.encodeCall(StakingShadow.canWithdraw, (depositId))
        );
        return abi.decode(returnedData, (bool, uint256, uint256));
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
            _tokenManager[deposit_.withdrawId][deposit_.strategyName][deposit_.token]
                .bank
                .fulfilled,
            'Not proceed'
        );

        uint256 transferAmount = calculateWithdrawAmount(depositId);
        // require(transferAmount > 0, 'Zero transfer amount');

        deposit_.status = Status.WITHDRAWED;
        if (address(deposit_.token) != address(_WETH))
            deposit_.token.safeTransfer(msg.sender, transferAmount);
        else {
            _WETH.withdraw(transferAmount);
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
            uint256 tokenDeposit = _deposited[token];
            if (tokenDeposit == 0) continue;

            uint256 stableAmount = 0;
            if (address(token) == address(_stableToken)) {
                stableAmount = tokenDeposit;

                if (stableAmount + totalStableAmount > maxStableAmount) {
                    stableAmount = tokenDeposit = maxStableAmount - totalStableAmount; // stable to stable
                    _stableToken.safeTransfer(msg.sender, stableAmount);
                    _deposited[token] -= tokenDeposit;
                    totalStableAmount += stableAmount;

                    emit ClaimedTokens(block.timestamp, address(token), stableAmount);
                    break;
                } else {
                    _stableToken.safeTransfer(msg.sender, stableAmount);
                    _deposited[token] = 0;
                }
            } else {
                stableAmount = _router.getAmountsOut(
                    tokenDeposit,
                    _tokensParameters[token].swapPath
                )[_tokensParameters[token].swapPath.length - 1];

                token.approve(address(_router), tokenDeposit);
                if (stableAmount + totalStableAmount > maxStableAmount) {
                    stableAmount = maxStableAmount - totalStableAmount;

                    tokenDeposit = _router.getAmountsOut( // tokenDeposit < tokenDeposit old
                        stableAmount,
                        _tokensParameters[token].reverseSwapPath
                    )[_tokensParameters[token].reverseSwapPath.length - 1];

                    uint256[] memory amounts = _router.swapExactTokensForTokens(
                        tokenDeposit,
                        _subSlippage(stableAmount),
                        _tokensParameters[token].swapPath,
                        msg.sender,
                        block.timestamp
                    );

                    stableAmount = amounts[amounts.length - 1];
                    totalStableAmount += stableAmount;
                    _deposited[token] -= amounts[0];

                    emit ClaimedTokens(block.timestamp, address(token), stableAmount);
                    break;
                } else {
                    uint256[] memory amounts = _router.swapExactTokensForTokens(
                        tokenDeposit,
                        _subSlippage(stableAmount),
                        _tokensParameters[token].swapPath,
                        msg.sender,
                        block.timestamp
                    );
                    stableAmount = amounts[amounts.length - 1];
                    _deposited[token] = 0;
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

    function _claim(uint256 depositId) internal {
        Deposit storage deposit_ = _deposits[depositId];
        IERC20Metadata token = deposit_.token;

        uint256 rewards = getRewardsToClaim(depositId);
        totalRewards[deposit_.strategyName][deposit_.token] -= deposit_.reward;
        deposit_.lastRewardId = _currentRewardId;
        if (address(token) == address(_WETH)) {
            _WETH.withdraw(rewards);
            payable(msg.sender).transfer(rewards);
        } else token.safeTransfer(deposit_.user, rewards);
    }

    function claimRewards(uint256 depositId)
        public
        exists(depositId)
        onlyHolder(depositId)
    {
        (bool _canClaim, string memory message) = canClaim(depositId);
        require(_canClaim, message);
        _claim(depositId);
    }

    function getRewardsToClaim(uint256 depositId) public view returns (uint256) {
        Deposit memory deposit_ = _deposits[depositId];
        uint256 amountToTransfer;

        for (uint256 i = deposit_.lastRewardId; i < _currentRewardId; ) {
            uint256 rateNumerator = _rewardFulfillRatesByIds[i][deposit_.strategyName][
                deposit_.token
            ][0];
            uint256 rateDenominator = _rewardFulfillRatesByIds[i][deposit_.strategyName][
                deposit_.token
            ][1];
            amountToTransfer += (deposit_.reward * rateNumerator) / rateDenominator;
            unchecked {
                ++i;
            }
        }
        return amountToTransfer;
    }

    function canClaim(uint256 depositId) public view returns (bool, string memory) {
        Deposit memory deposit_ = _deposits[depositId];
        if (deposit_.status != Status.DEPOSITED) return (false, 'Is not DEPOSITED');
        if (!(deposit_.lastRewardId < _currentRewardId)) return (false, 'claim later');
        if (block.timestamp - deposit_.timestamp < 30 days)
            return (false, 'first claim after 30 days');
        if (block.timestamp - lastRewardsFulfillTimestamp > claimOffset)
            return (false, 'Out of claim period');
        return (true, '');
    }

    /// @dev fulfills pending requests for withdrawing (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillDeposited(string memory strategyName, uint256 amountMaxInStable)
        external
        onlyOwner
    {
        address(_stakingShadow).functionDelegateCall(
            abi.encodeCall(
                StakingShadow.fulfillDeposited,
                (strategyName, amountMaxInStable)
            )
        );
    }

    /// @dev fulfills pending requests for withdrawing (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @param amountMaxInStable max amount that can be transfer from admin
    function fulfillRewards(string memory strategyName, uint256 amountMaxInStable)
        external
        onlyOwner
    {
        address(_stakingShadow).functionDelegateCall(
            abi.encodeCall(
                StakingShadow.fulfillRewards,
                (strategyName, amountMaxInStable)
            )
        );
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
            if (address(token) == address(_stableToken)) {
                depositedInStableTokenForToken = tm.deposited;
            } else {
                uint256 lastIndex = _tokensParameters[token].swapPath.length - 1;

                if (tm.deposited != 0)
                    depositedInStableTokenForToken = _addSlippage(
                        _router.getAmountsOut(
                            tm.deposited,
                            _tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            depositedInTokens[i] = tm.deposited;
            depositedInStableTokenForTokens[i] = depositedInStableTokenForToken;
            depositedInStableTokens += depositedInStableTokenForToken;
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
        require(address(_tokensParameters[token].token) == address(0), 'Token added');

        _registeredTokens.push(token);
        _tokensParameters[token] = TokenParameters({
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
            _tokensParameters[token].token != IERC20Metadata(address(0)),
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

    // /// @dev changes legal token's swap path (checks last item of path equals to `token`) (ONLY OWNER)
    // /// @param token address of token
    // /// @param newSwapPath new swap path to stable token for token
    // function changeSwapPath(IERC20Metadata token, address[] memory newSwapPath)
    //     external
    //     onlyOwner
    // {
    //     require(
    //         _tokensParameters[token].token != IERC20Metadata(address(0)),
    //         'unregistered token'
    //     );
    //     require(isCorrectSwapPath(token, newSwapPath), 'Wrong swap path');
    //     if (newSwapPath.length == _tokensParameters[token].swapPath.length) {
    //         uint256 length = newSwapPath.length;
    //         bool different = true;
    //         for (uint256 i; i < length; i++)
    //             different =
    //                 _tokensParameters[token].swapPath[i] == newSwapPath[i] &&
    //                 different;
    //         require(!different, 'Spaw path same');
    //     }
    //     _tokensParameters[token] = TokenParameters({
    //         token: token,
    //         swapPath: newSwapPath,
    //         reverseSwapPath: reversePath(newSwapPath),
    //         symbol: token.symbol(),
    //         name: token.name(),
    //         decimals: token.decimals()
    //     });

    //     emit ChangeSwapPath(block.timestamp, address(token), newSwapPath);
    // }

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
        _stableToken.safeTransferFrom(msg.sender, address(this), amount);
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

    function setClaimOffset(uint256 newClaimOffset) external onlyOwner {
        claimOffset = newClaimOffset;
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

        TokenManager memory tm = _tokenManager[deposit_.withdrawId][
            deposit_.strategyName
        ][deposit_.token];

        uint256 transferAmount;
        if (strategiesParameters[deposit_.strategyName].isSafe) {
            transferAmount = deposit_.deposited;
        } else {
            transferAmount = (deposit_.deposited * tm.bank.deposited) / tm.deposited;
        }

        return transferAmount;
    }

    /// @dev calculates withdraw rewards amount for class for admin (ONLY OWNER)
    /// @param strategyName name of deposit's strategy
    /// @return _totalRewards
    function calculateWithdrawAmountAdminRewards(string memory strategyName)
        public
        view
        returns (uint256 _totalRewards)
    {
        for (uint256 i; i < _registeredTokens.length; i++) {
            IERC20Metadata token = _registeredTokens[i];
            uint256 tokenRewards = totalRewards[strategyName][token];

            uint256 rewardsInStableTokenForTokens;
            if (address(token) == address(_stableToken)) {
                rewardsInStableTokenForTokens = tokenRewards;
            } else {
                uint256 lastIndex = _tokensParameters[token].swapPath.length - 1;

                if (tokenRewards != 0)
                    rewardsInStableTokenForTokens = _addSlippage(
                        _router.getAmountsOut(
                            tokenRewards,
                            _tokensParameters[token].swapPath
                        )[lastIndex]
                    );
            }
            _totalRewards += rewardsInStableTokenForTokens;
        }
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
        if (swapPath.length == 0 && address(token) == address(_stableToken)) return true;
        _router.getAmountsOut(10**token.decimals(), swapPath);
        return
            swapPath[0] == address(token) &&
            swapPath[swapPath.length - 1] == address(_stableToken);
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
        return _tokensParameters[token];
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
        return _tokenManager[withdrawId][strategyName][token];
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
        return _userDeposits[user];
    }

    // /// @dev returns list of deposits
    // ///
    // /// @return depostis list of deposits
    // function getDeposits() external view returns (Deposit[] memory) {
    //     return _deposits;
    // }

    function getDepositsLength() external view returns (uint256) {
        return _deposits.length;
    }

    function getDeposit(uint256 i) external view returns (Deposit memory) {
        return _deposits[i];
    }

    function getHistoryLength() external view returns (uint256) {
        return _history.length;
    }

    function getHistoryById(uint256 i) external view returns (History memory) {
        return _history[i];
    }

    /// @dev returns list of registered tokens
    ///
    /// @return depostis list of registered tokens
    function getRegistredTokens() external view returns (IERC20Metadata[] memory) {
        return _registeredTokens;
    }

    // /// @dev returns history of tx
    // ///
    // /// @return history history of tx
    // function getHistory() external view returns (History[] memory) {
    //     return _history;
    // }

    function router() external view returns (IPancakeRouter02) {
        return _router;
    }

    function stableToken() external view returns (IERC20) {
        return _stableToken;
    }

    function WETH() external view returns (IWETH) {
        return _WETH;
    }

    function stakingShadow() external view returns (StakingShadow) {
        return _stakingShadow;
    }

    function deposited(IERC20Metadata token) external view returns (uint256) {
        return _deposited[token];
    }

    function currentDepositId() external view returns (uint256) {
        return _currentDepositId;
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