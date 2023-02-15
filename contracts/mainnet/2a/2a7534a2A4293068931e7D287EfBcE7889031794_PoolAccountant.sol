// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title Errors library
library Errors {
    string public constant INVALID_COLLATERAL_AMOUNT = "1"; // Collateral must be greater than 0 or > defined limit
    string public constant INVALID_SHARE_AMOUNT = "2"; // Share must be greater than 0
    string public constant INVALID_INPUT_LENGTH = "3"; // Input array length must be greater than 0
    string public constant INPUT_LENGTH_MISMATCH = "4"; // Input array length mismatch with another array length
    string public constant NOT_WHITELISTED_ADDRESS = "5"; // Caller is not whitelisted to withdraw without fee
    string public constant MULTI_TRANSFER_FAILED = "6"; // Multi transfer of tokens has failed
    string public constant FEE_COLLECTOR_NOT_SET = "7"; // Fee Collector is not set
    string public constant NOT_ALLOWED_TO_SWEEP = "8"; // Token is not allowed to sweep
    string public constant INSUFFICIENT_BALANCE = "9"; // Insufficient balance to performs operations to follow
    string public constant INPUT_ADDRESS_IS_ZERO = "10"; // Input address is zero
    string public constant FEE_LIMIT_REACHED = "11"; // Fee must be less than MAX_BPS
    string public constant ALREADY_INITIALIZED = "12"; // Data structure, contract, or logic already initialized and can not be called again
    string public constant ADD_IN_LIST_FAILED = "13"; // Cannot add address in address list
    string public constant REMOVE_FROM_LIST_FAILED = "14"; // Cannot remove address from address list
    string public constant STRATEGY_IS_ACTIVE = "15"; // Strategy is already active, an inactive strategy is required
    string public constant STRATEGY_IS_NOT_ACTIVE = "16"; // Strategy is not active, an active strategy is required
    string public constant INVALID_STRATEGY = "17"; // Given strategy is not a strategy of this pool
    string public constant DEBT_RATIO_LIMIT_REACHED = "18"; // Debt ratio limit reached. It must be less than MAX_BPS
    string public constant TOTAL_DEBT_IS_NOT_ZERO = "19"; // Strategy total debt must be 0
    string public constant LOSS_TOO_HIGH = "20"; // Strategy reported loss must be less than current debt
    string public constant INVALID_MAX_BORROW_LIMIT = "21"; // Max borrow limit is beyond range.
    string public constant MAX_LIMIT_LESS_THAN_MIN = "22"; // Max limit should be greater than min limit.
    string public constant INVALID_SLIPPAGE = "23"; // Slippage should be less than MAX_BPS
    string public constant WRONG_RECEIPT_TOKEN = "24"; // Wrong receipt token address
    string public constant AAVE_FLASH_LOAN_NOT_ACTIVE = "25"; // aave flash loan is not active
    string public constant DYDX_FLASH_LOAN_NOT_ACTIVE = "26"; // DYDX flash loan is not active
    string public constant INVALID_FLASH_LOAN = "27"; // invalid-flash-loan
    string public constant INVALID_INITIATOR = "28"; // "invalid-initiator"
    string public constant INCORRECT_WITHDRAW_AMOUNT = "29"; // withdrawn amount is not correct
    string public constant NO_MARKET_ID_FOUND = "30"; // dydx flash loan no marketId found for token
    string public constant SAME_AS_PREVIOUS = "31"; // Input should not be same as previous value.
    string public constant INVALID_INPUT = "32"; // Generic invalid input error code
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Pausable interface
 */
interface IPausable {
    function paused() external view returns (bool);

    function stopEverything() external view returns (bool);

    function pause() external;

    function unpause() external;

    function shutdown() external;

    function open() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../../dependencies/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./IGovernable.sol";
import "./IPausable.sol";

interface IVesperPool is IGovernable, IPausable, IERC20Metadata {
    function calculateUniversalFee(uint256 profit_) external view returns (uint256 _fee);

    function deposit(uint256 collateralAmount_) external;

    function excessDebt(address strategy_) external view returns (uint256);

    function poolAccountant() external view returns (address);

    function poolRewards() external view returns (address);

    function reportEarning(uint256 profit_, uint256 loss_, uint256 payback_) external;

    function reportLoss(uint256 loss_) external;

    function sweepERC20(address fromToken_) external;

    function withdraw(uint256 share_) external;

    function keepers() external view returns (address[] memory);

    function isKeeper(address address_) external view returns (bool);

    function maintainers() external view returns (address[] memory);

    function isMaintainer(address address_) external view returns (bool);

    function pricePerShare() external view returns (uint256);

    function strategy(
        address strategy_
    )
        external
        view
        returns (
            bool _active,
            uint256 _interestFee, // Obsolete
            uint256 _debtRate, // Obsolete
            uint256 _lastRebalance,
            uint256 _totalDebt,
            uint256 _totalLoss,
            uint256 _totalProfit,
            uint256 _debtRatio,
            uint256 _externalDepositFee
        );

    function token() external view returns (IERC20);

    function tokensHere() external view returns (uint256);

    function totalDebtOf(address strategy_) external view returns (uint256);

    function totalValue() external view returns (uint256);

    function totalDebt() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../dependencies/openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../dependencies/openzeppelin/contracts/utils/Context.sol";
import "../Errors.sol";
import "../interfaces/vesper/IVesperPool.sol";
import "./PoolAccountantStorage.sol";

/// @title Accountant for Vesper pools which keep records of strategies.
contract PoolAccountant is Initializable, Context, PoolAccountantStorageV2 {
    using SafeERC20 for IERC20;

    string public constant VERSION = "5.1.0";
    uint256 public constant MAX_BPS = 10_000;

    event EarningReported(
        address indexed strategy,
        uint256 profit,
        uint256 loss,
        uint256 payback,
        uint256 strategyDebt,
        uint256 poolDebt,
        uint256 creditLine
    );
    event LossReported(address indexed strategy, uint256 loss);
    event StrategyAdded(address indexed strategy, uint256 debtRatio, uint256 externalDepositFee);
    event StrategyRemoved(address indexed strategy);
    event StrategyMigrated(address indexed oldStrategy, address indexed newStrategy);
    event UpdatedExternalDepositFee(address indexed strategy, uint256 oldFee, uint256 newFee);
    event UpdatedPoolExternalDepositFee(uint256 oldFee, uint256 newFee);
    event UpdatedStrategyDebtRatio(address indexed strategy, uint256 oldDebtRatio, uint256 newDebtRatio);

    /**
     * @dev This init function meant to be called after proxy deployment.
     * @dev DO NOT CALL it with proxy deploy
     * @param pool_ Address of Vesper pool proxy
     */
    function init(address pool_) public initializer {
        require(pool_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        pool = pool_;
    }

    modifier onlyGovernor() {
        require(IVesperPool(pool).governor() == _msgSender(), "not-the-governor");
        _;
    }

    modifier onlyKeeper() {
        require(
            IVesperPool(pool).governor() == _msgSender() || IVesperPool(pool).isKeeper(_msgSender()),
            "not-a-keeper"
        );
        _;
    }

    modifier onlyMaintainer() {
        require(
            IVesperPool(pool).governor() == _msgSender() || IVesperPool(pool).isMaintainer(_msgSender()),
            "not-a-maintainer"
        );
        _;
    }

    modifier onlyPool() {
        require(pool == _msgSender(), "not-a-pool");
        _;
    }

    /**
     * @notice Get available credit limit of strategy. This is the amount strategy can borrow from pool
     * @dev Available credit limit is calculated based on current debt of pool and strategy, current debt limit of pool and strategy.
     * credit available = min(pool's debt limit, strategy's debt limit, max debt per rebalance)
     * when some strategy do not pay back outstanding debt, this impact credit line of other strategy if totalDebt of pool >= debtLimit of pool
     * @param strategy_ Strategy address
     */
    function availableCreditLimit(address strategy_) external view returns (uint256) {
        return _availableCreditLimit(strategy_);
    }

    /**
     * @notice Debt above current debt limit
     * @param strategy_ Address of strategy
     */
    function excessDebt(address strategy_) external view returns (uint256) {
        return _excessDebt(strategy_);
    }

    /// @notice Return strategies array
    function getStrategies() external view returns (address[] memory) {
        return strategies;
    }

    /// @notice Return withdrawQueue
    function getWithdrawQueue() external view returns (address[] memory) {
        return withdrawQueue;
    }

    /**
     * @notice Get total debt of given strategy
     * @param strategy_ Strategy address
     */
    function totalDebtOf(address strategy_) external view returns (uint256) {
        return strategy[strategy_].totalDebt;
    }

    function _availableCreditLimit(address strategy_) internal view returns (uint256) {
        if (IVesperPool(pool).stopEverything()) {
            return 0;
        }
        uint256 _totalValue = IVesperPool(pool).totalValue();
        uint256 _maxDebt = (strategy[strategy_].debtRatio * _totalValue) / MAX_BPS;
        uint256 _currentDebt = strategy[strategy_].totalDebt;
        if (_currentDebt >= _maxDebt) {
            return 0;
        }
        uint256 _poolDebtLimit = (totalDebtRatio * _totalValue) / MAX_BPS;
        if (totalDebt >= _poolDebtLimit) {
            return 0;
        }
        uint256 _available = _maxDebt - _currentDebt;
        _available = _min(_min(IVesperPool(pool).tokensHere(), _available), _poolDebtLimit - totalDebt);
        return _available;
    }

    function _excessDebt(address strategy_) internal view returns (uint256) {
        uint256 _currentDebt = strategy[strategy_].totalDebt;
        if (IVesperPool(pool).stopEverything()) {
            return _currentDebt;
        }
        uint256 _maxDebt = (strategy[strategy_].debtRatio * IVesperPool(pool).totalValue()) / MAX_BPS;
        return _currentDebt > _maxDebt ? (_currentDebt - _maxDebt) : 0;
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /// @notice Recalculate pool external deposit fee.
    /// @dev As it uses state variables for calculation, make sure to call it only after updating state variables.
    function _recalculatePoolExternalDepositFee() internal {
        uint256 _len = strategies.length;
        uint256 _externalDepositFee;

        // calculate poolExternalDepositFee and weightedFee for each strategy
        if (totalDebtRatio > 0) {
            for (uint256 i; i < _len; i++) {
                _externalDepositFee +=
                    (strategy[strategies[i]].externalDepositFee * strategy[strategies[i]].debtRatio) /
                    totalDebtRatio;
            }
        }

        // Update externalDepositFee and emit event
        emit UpdatedPoolExternalDepositFee(externalDepositFee, externalDepositFee = _externalDepositFee);
    }

    /**
     * @dev When strategy report loss, its debtRatio decreases to get fund back quickly.
     * Reduction is debt ratio is reduction in credit limit
     */
    function _reportLoss(address strategy_, uint256 loss_) internal {
        require(strategy[strategy_].totalDebt >= loss_, Errors.LOSS_TOO_HIGH);
        strategy[strategy_].totalLoss += loss_;
        strategy[strategy_].totalDebt -= loss_;
        totalDebt -= loss_;
        uint256 _deltaDebtRatio = _min(
            (loss_ * MAX_BPS) / IVesperPool(pool).totalValue(),
            strategy[strategy_].debtRatio
        );
        strategy[strategy_].debtRatio -= _deltaDebtRatio;
        totalDebtRatio -= _deltaDebtRatio;
    }

    /************************************************************************************************
     *                                     Authorized function                                      *
     ***********************************************************************************************/

    ////////////////////////////// Only Governor //////////////////////////////

    /**
     * @notice Add strategy. Once strategy is added it can call rebalance and
     * borrow fund from pool and invest that fund in provider/lender.
     * @dev Recalculate pool level external deposit fee after all state variables are updated.
     * @param strategy_ Strategy address
     * @param debtRatio_ Pool fund allocation to this strategy
     * @param externalDepositFee_ External deposit fee of strategy
     */
    function addStrategy(address strategy_, uint256 debtRatio_, uint256 externalDepositFee_) public onlyGovernor {
        require(strategy_ != address(0), Errors.INPUT_ADDRESS_IS_ZERO);
        require(!strategy[strategy_].active, Errors.STRATEGY_IS_ACTIVE);
        totalDebtRatio = totalDebtRatio + debtRatio_;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        require(externalDepositFee_ <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        StrategyConfig memory newStrategy = StrategyConfig({
            active: true,
            interestFee: 0, // Obsolete
            debtRate: 0, // Obsolete
            lastRebalance: block.timestamp,
            totalDebt: 0,
            totalLoss: 0,
            totalProfit: 0,
            debtRatio: debtRatio_,
            externalDepositFee: externalDepositFee_
        });
        strategy[strategy_] = newStrategy;
        strategies.push(strategy_);
        withdrawQueue.push(strategy_);
        emit StrategyAdded(strategy_, debtRatio_, externalDepositFee_);

        // Recalculate pool level externalDepositFee. This should be called at the end of function
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Remove strategy and recalculate pool level external deposit fee.
     * @dev Revoke and remove strategy from array. Update withdraw queue.
     * Withdraw queue order should not change after remove.
     * Strategy can be removed only after it has paid all debt.
     * Use migrate strategy if debt is not paid and want to upgrade strategy.
     */
    function removeStrategy(uint256 index_) external onlyGovernor {
        address _strategy = strategies[index_];
        require(strategy[_strategy].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(strategy[_strategy].totalDebt == 0, Errors.TOTAL_DEBT_IS_NOT_ZERO);
        // Adjust totalDebtRatio
        totalDebtRatio -= strategy[_strategy].debtRatio;
        // Remove strategy
        delete strategy[_strategy];
        strategies[index_] = strategies[strategies.length - 1];
        strategies.pop();
        address[] memory _withdrawQueue = new address[](strategies.length);
        uint256 j;
        // After above update, withdrawQueue.length > strategies.length
        for (uint256 i; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] != _strategy) {
                _withdrawQueue[j] = withdrawQueue[i];
                j++;
            }
        }
        withdrawQueue = _withdrawQueue;
        emit StrategyRemoved(_strategy);

        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Update external deposit fee of strategy and recalculate pool level external deposit fee.
     * @param strategy_ Strategy address for which external deposit fee is being updated
     * @param externalDepositFee_ New external deposit fee
     */
    function updateExternalDepositFee(address strategy_, uint256 externalDepositFee_) external onlyGovernor {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(externalDepositFee_ <= MAX_BPS, Errors.FEE_LIMIT_REACHED);
        uint256 _oldExternalDepositFee = strategy[strategy_].externalDepositFee;
        // Write to storage
        strategy[strategy_].externalDepositFee = externalDepositFee_;
        emit UpdatedExternalDepositFee(strategy_, _oldExternalDepositFee, externalDepositFee_);

        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    ///////////////////////////// Only Keeper /////////////////////////////

    /**
     * @notice Recalculate pool external deposit fee. It is calculated using debtRatio and external deposit fee of each strategy.
     * @dev Whenever debtRatio changes recalculation is required. DebtRatio changes if strategy reports loss and in that case an
     * off chain application can watch for it and take action accordingly.
     * @dev This function is gas heavy hence we do not want to call during reportLoss.
     */
    function recalculatePoolExternalDepositFee() external onlyKeeper {
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @dev Transfer given ERC20 token to pool
     * @param fromToken_ Token address to sweep
     */
    function sweep(address fromToken_) external virtual onlyKeeper {
        IERC20(fromToken_).safeTransfer(pool, IERC20(fromToken_).balanceOf(address(this)));
    }

    ///////////////////////////// Only Maintainer /////////////////////////////
    /**
     * @notice Update debt ratio.
     * @dev A strategy is retired when debtRatio is 0
     * @dev As debtRatio impacts pool level external deposit fee hence recalculate it after updating debtRatio.
     * @param strategy_ Strategy address for which debt ratio is being updated
     * @param debtRatio_ New debt ratio
     */
    function updateDebtRatio(address strategy_, uint256 debtRatio_) external onlyMaintainer {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        // Update totalDebtRatio
        totalDebtRatio = (totalDebtRatio - strategy[strategy_].debtRatio) + debtRatio_;
        require(totalDebtRatio <= MAX_BPS, Errors.DEBT_RATIO_LIMIT_REACHED);
        emit UpdatedStrategyDebtRatio(strategy_, strategy[strategy_].debtRatio, debtRatio_);
        // Write to storage
        strategy[strategy_].debtRatio = debtRatio_;
        // Recalculate pool level externalDepositFee.
        _recalculatePoolExternalDepositFee();
    }

    /**
     * @notice Update withdraw queue. Withdraw queue is list of strategy in the order in which
     * funds should be withdrawn.
     * @dev Pool always keep some buffer amount to satisfy withdrawal request, any withdrawal
     * request higher than buffer will withdraw from withdraw queue. So withdrawQueue[0] will
     * be the first strategy where withdrawal request will be send.
     * @param withdrawQueue_ Ordered list of strategy.
     */
    function updateWithdrawQueue(address[] memory withdrawQueue_) external onlyMaintainer {
        uint256 _length = withdrawQueue_.length;
        require(_length == withdrawQueue.length && _length == strategies.length, Errors.INPUT_LENGTH_MISMATCH);
        for (uint256 i; i < _length; i++) {
            require(strategy[withdrawQueue_[i]].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        }
        withdrawQueue = withdrawQueue_;
    }

    //////////////////////////////// Only Pool ////////////////////////////////

    /**
     * @notice Decrease debt of strategy, also decrease totalDebt
     * @dev In case of withdraw from strategy, pool will decrease debt by amount withdrawn
     * @param strategy_ Strategy Address
     * @param decreaseBy_ Amount by which strategy debt will be decreased
     */
    function decreaseDebt(address strategy_, uint256 decreaseBy_) external onlyPool {
        // A strategy may send more than its debt. This should never fail
        decreaseBy_ = _min(strategy[strategy_].totalDebt, decreaseBy_);
        strategy[strategy_].totalDebt -= decreaseBy_;
        totalDebt -= decreaseBy_;
    }

    /**
     * @notice Migrate existing strategy to new strategy.
     * @dev Migrating strategy aka old and new strategy should be of same type.
     * @dev New strategy will replace old strategy in strategy mapping,
     * strategies array, withdraw queue.
     * @param old_ Address of strategy being migrated
     * @param new_ Address of new strategy
     */
    function migrateStrategy(address old_, address new_) external onlyPool {
        require(strategy[old_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(!strategy[new_].active, Errors.STRATEGY_IS_ACTIVE);
        StrategyConfig memory _newStrategy = StrategyConfig({
            active: true,
            interestFee: 0, // Obsolete
            debtRate: 0, // Obsolete
            lastRebalance: strategy[old_].lastRebalance,
            totalDebt: strategy[old_].totalDebt,
            totalLoss: 0,
            totalProfit: 0,
            debtRatio: strategy[old_].debtRatio,
            externalDepositFee: strategy[old_].externalDepositFee
        });
        delete strategy[old_];
        strategy[new_] = _newStrategy;

        // Strategies and withdrawQueue has same length but we still want
        // to iterate over them in different loop.
        for (uint256 i; i < strategies.length; i++) {
            if (strategies[i] == old_) {
                strategies[i] = new_;
                break;
            }
        }
        for (uint256 i; i < withdrawQueue.length; i++) {
            if (withdrawQueue[i] == old_) {
                withdrawQueue[i] = new_;
                break;
            }
        }
        emit StrategyMigrated(old_, new_);
    }

    /**
     * @dev Strategy call this in regular interval.
     * @param profit_ yield generated by strategy. Strategy get performance fee on this amount
     * @param loss_  Reduce debt ,also reduce debtRatio, increase loss in record.
     * @param payback_ strategy willing to payback outstanding above debtLimit. no performance fee on this amount.
     *  when governance has reduced debtRatio of strategy, strategy will report profit and payback amount separately.
     */
    function reportEarning(
        address strategy_,
        uint256 profit_,
        uint256 loss_,
        uint256 payback_
    ) external onlyPool returns (uint256 _actualPayback, uint256 _creditLine) {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        require(IVesperPool(pool).token().balanceOf(strategy_) >= (profit_ + payback_), Errors.INSUFFICIENT_BALANCE);
        if (loss_ > 0) {
            _reportLoss(strategy_, loss_);
        }

        uint256 _overLimitDebt = _excessDebt(strategy_);
        _actualPayback = _min(_overLimitDebt, payback_);
        if (_actualPayback > 0) {
            strategy[strategy_].totalDebt -= _actualPayback;
            totalDebt -= _actualPayback;
        }
        _creditLine = _availableCreditLimit(strategy_);
        if (_creditLine > 0) {
            strategy[strategy_].totalDebt += _creditLine;
            totalDebt += _creditLine;
        }
        if (profit_ > 0) {
            strategy[strategy_].totalProfit += profit_;
        }
        strategy[strategy_].lastRebalance = block.timestamp;
        emit EarningReported(
            strategy_,
            profit_,
            loss_,
            _actualPayback,
            strategy[strategy_].totalDebt,
            totalDebt,
            _creditLine
        );
        return (_actualPayback, _creditLine);
    }

    /**
     * @notice Update strategy loss.
     * @param strategy_ Strategy which incur loss
     * @param loss_ Loss of strategy
     */
    function reportLoss(address strategy_, uint256 loss_) external onlyPool {
        require(strategy[strategy_].active, Errors.STRATEGY_IS_NOT_ACTIVE);
        _reportLoss(strategy_, loss_);
        emit LossReported(strategy_, loss_);
    }

    ///////////////////////////////////////////////////////////////////////////
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

abstract contract PoolAccountantStorageV1 {
    address public pool; // Address of Vesper pool
    uint256 public totalDebtRatio; // Total debt ratio. This will keep some buffer amount in pool
    uint256 public totalDebt; // Total debt. Sum of debt of all strategies.
    address[] public strategies; // Array of strategies
    address[] public withdrawQueue; // Array of strategy in the order in which funds should be withdrawn.
}

abstract contract PoolAccountantStorageV2 is PoolAccountantStorageV1 {
    struct StrategyConfig {
        bool active;
        uint256 interestFee; // Obsolete in favor of universal fee
        uint256 debtRate; // Obsolete
        uint256 lastRebalance; // Timestamp of last rebalance. It is used in universal fee calculation
        uint256 totalDebt; // Total outstanding debt strategy has
        uint256 totalLoss; // Total loss that strategy has realized
        uint256 totalProfit; // Total gain that strategy has realized
        uint256 debtRatio; // % of asset allocation
        uint256 externalDepositFee; // External deposit fee of strategy
    }

    mapping(address => StrategyConfig) public strategy; // Strategy address to its configuration

    uint256 public externalDepositFee; // External deposit fee of Vesper pool
}