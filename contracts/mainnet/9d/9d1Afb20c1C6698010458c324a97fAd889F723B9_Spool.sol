// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./spool/SpoolExternal.sol";

/**
 * @notice Implementation of the central Spool contract.
 *
 * @dev
 * The Spool implementation is the central part of the system.
 * All the assets flow through this contract and are deposited
 * to the integrated protocols.
 *
 * Spool implementation consists of following contracts:
 * 1. BaseStorage: stores common variables with all the strategy adapters (they are execuret as delegatecode)
 * 2. SpoolBase: holds Spool state variables and provides some of the common vault functions
 * 3. SpoolStrategy: implements the logic of how to interact with the strategies
 * 4. SpoolDoHardWork: implements functions to process the do hard work
 * 5. SpoolReallocation: adjusts vault reallocation that takes place at the next do hard work
 * 6. SpoolExternal: exposes functons to interact with the Spool from the vault (deposit/withdraw/redeem)
 * 7. Spool: implements a constructor to deploy a contracts
 */
contract Spool is SpoolExternal {

    /**
     * @notice Initializes the central Spool contract values
     *
     * @param _spoolOwner the spool owner contract
     * @param _controller responsible for providing the source of truth
     * @param _fastWithdraw allows fast withdraw of user shares
     */
    constructor(
        ISpoolOwner _spoolOwner,
        IController _controller,
        address _fastWithdraw
    )
        SpoolBase(
            _spoolOwner,
            _controller,
            _fastWithdraw
        )
    {}
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 128 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";
import "./ISwapData.sol";

interface IBaseStrategy {
    function underlying() external view returns (IERC20);

    function getStrategyBalance() external view returns (uint128);

    function getStrategyUnderlyingWithRewards() external view returns(uint128);

    function process(uint256[] calldata, bool, SwapData[] calldata) external;

    function processReallocation(uint256[] calldata, ProcessReallocationData calldata) external returns(uint128);

    function processDeposit(uint256[] calldata) external;

    function fastWithdraw(uint128, uint256[] calldata, SwapData[] calldata) external returns(uint128);

    function claimRewards(SwapData[] calldata) external;

    function emergencyWithdraw(address recipient, uint256[] calldata data) external;

    function initialize() external;

    function disable() external;
}

struct ProcessReallocationData {
    uint128 sharesToWithdraw;
    uint128 optimizedShares;
    uint128 optimizedWithdrawnAmount;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IController {
    /* ========== FUNCTIONS ========== */

    function strategies(uint256 i) external view returns (address);

    function validStrategy(address strategy) external view returns (bool);

    function validVault(address vault) external view returns (bool);

    function getStrategiesCount() external view returns(uint8);

    function supportedUnderlying(IERC20 underlying)
        external
        view
        returns (bool);

    function getAllStrategies() external view returns (address[] memory);

    function verifyStrategies(address[] calldata _strategies) external view;

    function transferToSpool(
        address transferFrom,
        uint256 amount
    ) external;

    function checkPaused() external view;

    /* ========== EVENTS ========== */

    event EmergencyWithdrawStrategy(address indexed strategy);
    event EmergencyRecipientUpdated(address indexed recipient);
    event EmergencyWithdrawerUpdated(address indexed withdrawer, bool set);
    event PauserUpdated(address indexed user, bool set);
    event UnpauserUpdated(address indexed user, bool set);
    event VaultCreated(address indexed vault, address underlying, address[] strategies, uint256[] proportions,
        uint16 vaultFee, address riskProvider, int8 riskTolerance);
    event StrategyAdded(address strategy);
    event StrategyRemoved(address strategy);
    event VaultInvalid(address vault);
    event DisableStrategy(address strategy);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

/**
 * @notice Strict holding information how to swap the asset
 * @member slippage minumum output amount
 * @member path swap path, first byte represents an action (e.g. Uniswap V2 custom swap), rest is swap specific path
 */
struct SwapData {
    uint256 slippage; // min amount out
    bytes path; // 1st byte is action, then path 
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./vault/IVaultRestricted.sol";
import "./vault/IVaultIndexActions.sol";
import "./vault/IRewardDrip.sol";
import "./vault/IVaultBase.sol";
import "./vault/IVaultImmutable.sol";

interface IVault is IVaultRestricted, IVaultIndexActions, IRewardDrip, IVaultBase, IVaultImmutable {}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolBase {
    /* ========== FUNCTIONS ========== */

    function getCompletedGlobalIndex() external view returns(uint24);

    function getActiveGlobalIndex() external view returns(uint24);

    function isMidReallocation() external view returns (bool);

    /* ========== EVENTS ========== */

    event ReallocationTableUpdated(
        uint24 indexed index,
        bytes32 reallocationTableHash
    );

    event ReallocationTableUpdatedWithTable(
        uint24 indexed index,
        bytes32 reallocationTableHash,
        uint256[][] reallocationTable
    );
    
    event DoHardWorkCompleted(uint24 indexed index);

    event SetAllocationProvider(address actor, bool isAllocationProvider);
    event SetIsDoHardWorker(address actor, bool isDoHardWorker);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolDoHardWork {
    /* ========== EVENTS ========== */

    event DoHardWorkStrategyCompleted(address indexed strat, uint256 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../ISwapData.sol";

interface ISpoolExternal {
    /* ========== FUNCTIONS ========== */

    function deposit(address strategy, uint128 amount, uint256 index) external;

    function withdraw(address strategy, uint256 vaultProportion, uint256 index) external;

    function fastWithdrawStrat(address strat, address underlying, uint256 shares, uint256[] calldata slippages, SwapData[] calldata swapData) external returns(uint128);

    function redeem(address strat, uint256 index) external returns (uint128, uint128);

    function redeemUnderlying(uint128 amount) external;

    function redeemReallocation(address[] calldata vaultStrategies, uint256 depositProportions, uint256 index) external;

    function removeShares(address[] calldata vaultStrategies, uint256 vaultProportion) external returns(uint128[] memory);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolReallocation {
    event StartReallocation(uint24 indexed index);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface ISpoolStrategy {
    /* ========== FUNCTIONS ========== */

    function getUnderlying(address strat) external returns (uint128);
    
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external view returns(uint128);

    function addStrategy(address strat) external;

    function disableStrategy(address strategy, bool skipDisable) external;

    function runDisableStrategy(address strategy) external;

    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] calldata data
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDrip {
    /* ========== STRUCTS ========== */

    // The reward configuration struct, containing all the necessary data of a typical Synthetix StakingReward contract
    struct RewardConfiguration {
        uint32 rewardsDuration;
        uint32 periodFinish;
        uint192 rewardRate; // rewards per second multiplied by accuracy
        uint32 lastUpdateTime;
        uint224 rewardPerTokenStored;
        mapping(address => uint256) userRewardPerTokenPaid;
        mapping(address => uint256) rewards;
    }

    /* ========== FUNCTIONS ========== */

    function getActiveRewards(address account) external;
    function tokenBlacklist(IERC20 token) view external returns(bool);

    /* ========== EVENTS ========== */
    
    event RewardPaid(IERC20 token, address indexed user, uint256 reward);
    event RewardAdded(IERC20 indexed token, uint256 amount, uint256 duration);
    event RewardExtended(IERC20 indexed token, uint256 amount, uint256 leftover, uint256 duration, uint32 periodFinish);
    event RewardRemoved(IERC20 indexed token);
    event PeriodFinishUpdated(IERC20 indexed token, uint32 periodFinish);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "./IVaultDetails.sol";

interface IVaultBase {
    /* ========== FUNCTIONS ========== */

    function initialize(VaultInitializable calldata vaultInitializable) external;

    /* ========== STRUCTS ========== */

    struct User {
        uint128 instantDeposit; // used for calculating rewards
        uint128 activeDeposit; // users deposit after deposit process and claim
        uint128 owed; // users owed underlying amount after withdraw has been processed and claimed
        uint128 withdrawnDeposits; // users withdrawn deposit, used to calculate performance fees
        uint128 shares; // users shares after deposit process and claim
    }

    /* ========== EVENTS ========== */

    event Claimed(address indexed member, uint256 claimAmount);
    event Deposit(address indexed member, uint256 indexed index, uint256 amount);
    event Withdraw(address indexed member, uint256 indexed index, uint256 shares);
    event WithdrawFast(address indexed member, uint256 shares);
    event StrategyRemoved(uint256 i, address strategy);
    event TransferVaultOwner(address owner);
    event LowerVaultFee(uint16 fee);
    event UpdateName(string name);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

struct VaultDetails {
    address underlying;
    address[] strategies;
    uint256[] proportions;
    address creator;
    uint16 vaultFee;
    address riskProvider;
    int8 riskTolerance;
    string name;
}

struct VaultInitializable {
    string name;
    address owner;
    uint16 fee;
    address[] strategies;
    uint256[] proportions;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../../external/@openzeppelin/token/ERC20/IERC20.sol";

struct VaultImmutables {
    IERC20 underlying;
    address riskProvider;
    int8 riskTolerance;
}

interface IVaultImmutable {
    /* ========== FUNCTIONS ========== */

    function underlying() external view returns (IERC20);

    function riskProvider() external view returns (address);

    function riskTolerance() external view returns (int8);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultIndexActions {

    /* ========== STRUCTS ========== */

    struct IndexAction {
        uint128 depositAmount;
        uint128 withdrawShares;
    }

    struct LastIndexInteracted {
        uint128 index1;
        uint128 index2;
    }

    struct Redeem {
        uint128 depositShares;
        uint128 withdrawnAmount;
    }

    /* ========== EVENTS ========== */

    event VaultRedeem(uint indexed globalIndex);
    event UserRedeem(address indexed member, uint indexed globalIndex);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

interface IVaultRestricted {
    /* ========== FUNCTIONS ========== */
    
    function reallocate(
        address[] calldata vaultStrategies,
        uint256 newVaultProportions,
        uint256 finishedIndex,
        uint24 activeIndex
    ) external returns (uint256[] memory, uint256);

    function payFees(uint256 profit) external returns (uint256 feesPaid);

    /* ========== EVENTS ========== */

    event Reallocate(uint24 indexed index, uint256 newProportions);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

library Bitwise {
    function get8BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return (bitwiseData >> (8 * i)) & type(uint8).max;
    }

    // 14 bits is used for strategy proportions in a vault as FULL_PERCENT is 10_000
    function get14BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return (bitwiseData >> (14 * i)) & (16_383); // 16.383 is 2^14 - 1
    }

    function set14BitUintByIndex(uint256 bitwiseData, uint256 i, uint256 num14bit) internal pure returns(uint256) {
        return bitwiseData + (num14bit << (14 * i));
    }

    function reset14BitUintByIndex(uint256 bitwiseData, uint256 i) internal pure returns(uint256) {
        return bitwiseData & (~(16_383 << (14 * i)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/**
 * @notice Library to provide utils for hashing and hash compatison of Spool related data
 */
library Hash {
    function hashReallocationTable(uint256[][] memory reallocationTable) internal pure returns(bytes32) {
        return keccak256(abi.encode(reallocationTable));
    }

    function hashStrategies(address[] memory strategies) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(strategies));
    }

    function sameStrategies(address[] memory strategies1, address[] memory strategies2) internal pure returns(bool) {
        return hashStrategies(strategies1) == hashStrategies(strategies2);
    }

    function sameStrategies(address[] memory strategies, bytes32 strategiesHash) internal pure returns(bool) {
        return hashStrategies(strategies) == strategiesHash;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../external/@openzeppelin/utils/SafeCast.sol";


/**
 * @notice A collection of custom math ustils used throughout the system
 */
library Math {
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? b : a;
    }

    function getProportion128(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        return SafeCast.toUint128(((mul1 * mul2) / div));
    }

    function getProportion128Unchecked(uint256 mul1, uint256 mul2, uint256 div) internal pure returns (uint128) {
        unchecked {
            return uint128((mul1 * mul2) / div);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

/** @notice Handle setting zero value in a storage word as uint128 max value.
  *
  *  @dev
  *  The purpose of this is to avoid resetting a storage word to the zero value; 
  *  the gas cost of re-initializing the value is the same as setting the word originally.
  *  so instead, if word is to be set to zero, we set it to uint128 max.
  *
  *   - anytime a word is loaded from storage: call "get"
  *   - anytime a word is written to storage: call "set"
  *   - common operations on uints are also bundled here.
  *
  * NOTE: This library should ONLY be used when reading or writing *directly* from storage.
 */
library Max128Bit {
    uint128 internal constant ZERO = type(uint128).max;

    function get(uint128 a) internal pure returns(uint128) {
        return (a == ZERO) ? 0 : a;
    }

    function set(uint128 a) internal pure returns(uint128){
        return (a == 0) ? ZERO : a;
    }

    function add(uint128 a, uint128 b) internal pure returns(uint128 c){
        a = get(a);
        c = set(a + b);
    }
}

// SPDX-License-Identifier: BUSL-1.1

import "../interfaces/ISwapData.sol";

pragma solidity 0.8.11;

/// @notice Strategy struct for all strategies
struct Strategy {
    uint128 totalShares;

    /// @notice Denotes strategy completed index
    uint24 index;

    /// @notice Denotes whether strategy is removed
    /// @dev after removing this value can never change, hence strategy cannot be added back again
    bool isRemoved;

    /// @notice Pending geposit amount and pending shares withdrawn by all users for next index 
    Pending pendingUser;

    /// @notice Used if strategies "dohardwork" hasn't been executed yet in the current index
    Pending pendingUserNext;

    /// @dev Usually a temp variable when compounding
    mapping(address => uint256) pendingRewards;

    /// @dev Usually a temp variable when compounding
    uint128 pendingDepositReward;

    /// @notice Amount of lp tokens the strategy holds, NOTE: not all strategies use it
    uint256 lpTokens;

    // ----- REALLOCATION VARIABLES -----

    bool isInDepositPhase;

    /// @notice Used to store amount of optimized shares, so they can be substracted at the end
    /// @dev Only for temporary use, should be reset to 0 in same transaction
    uint128 optimizedSharesWithdrawn;

    /// @dev Underlying amount pending to be deposited from other strategies at reallocation 
    /// @dev resets after the strategy reallocation DHW is finished
    uint128 pendingReallocateDeposit;

    /// @notice Stores amount of optimized underlying amount when reallocating
    /// @dev resets after the strategy reallocation DHW is finished
    /// @dev This is "virtual" amount that was matched between this strategy and others when reallocating
    uint128 pendingReallocateOptimizedDeposit;

    // ------------------------------------

    /// @notice Total underlying amoung at index
    mapping(uint256 => TotalUnderlying) totalUnderlying;

    /// @notice Batches stored after each DHW with index as a key
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn amounts belonging to users
    mapping(uint256 => Batch) batches;

    /// @notice Batches stored after each DHW reallocating (if strategy was set to reallocate)
    /// @dev Holds information for vauls to redeem newly gained shares and withdrawn shares to complete reallocation
    mapping(uint256 => BatchReallocation) reallocationBatches;

    /// @notice Vaults holding this strategy shares
    mapping(address => Vault) vaults;

    /// @notice Future proof storage
    mapping(bytes32 => AdditionalStorage) additionalStorage;

    /// @dev Make sure to reset it to 0 after emergency withdrawal
    uint256 emergencyPending;
}

/// @notice Unprocessed deposit underlying amount and strategy share amount from users
struct Pending {
    uint128 deposit;
    uint128 sharesToWithdraw;
}

/// @notice Struct storing total underlying balance of a strategy for an index, along with total shares at same index
struct TotalUnderlying {
    uint128 amount;
    uint128 totalShares;
}

/// @notice Stored after executing DHW for each index.
/// @dev This is used for vaults to redeem their deposit.
struct Batch {
    /// @notice total underlying deposited in index
    uint128 deposited;
    uint128 depositedReceived;
    uint128 depositedSharesReceived;
    uint128 withdrawnShares;
    uint128 withdrawnReceived;
}

/// @notice Stored after executing reallocation DHW each index.
struct BatchReallocation {
    /// @notice Deposited amount received from reallocation
    uint128 depositedReallocation;

    /// @notice Received shares from reallocation
    uint128 depositedReallocationSharesReceived;

    /// @notice Used to know how much tokens was received for reallocating
    uint128 withdrawnReallocationReceived;

    /// @notice Amount of shares to withdraw for reallocation
    uint128 withdrawnReallocationShares;
}

/// @notice VaultBatches could be refactored so we only have 2 structs current and next (see how Pending is working)
struct Vault {
    uint128 shares;

    /// @notice Withdrawn amount as part of the reallocation
    uint128 withdrawnReallocationShares;

    /// @notice Index to action
    mapping(uint256 => VaultBatch) vaultBatches;
}

/// @notice Stores deposited and withdrawn shares by the vault
struct VaultBatch {
    /// @notice Vault index to deposited amount mapping
    uint128 deposited;

    /// @notice Vault index to withdrawn user shares mapping
    uint128 withdrawnShares;
}

/// @notice Used for reallocation calldata
struct VaultData {
    address vault;
    uint8 strategiesCount;
    uint256 strategiesBitwise;
    uint256 newProportions;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the withdraw part of the reallocation DHW
struct ReallocationWithdrawData {
    uint256[][] reallocationTable;
    StratUnderlyingSlippage[] priceSlippages;
    RewardSlippages[] rewardSlippages;
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice Calldata when executing reallocatin DHW
/// @notice Used in the deposit part of the reallocation DHW
struct ReallocationData {
    uint256[] stratIndexes;
    uint256[][] slippages;
}

/// @notice In case some adapters need extra storage
struct AdditionalStorage {
    uint256 value;
    address addressValue;
    uint96 value96;
}

/// @notice Strategy total underlying slippage, to verify validity of the strategy state
struct StratUnderlyingSlippage {
    uint128 min;
    uint128 max;
}

/// @notice Containig information if and how to swap strategy rewards at the DHW
/// @dev Passed in by the do-hard-worker
struct RewardSlippages {
    bool doClaim;
    SwapData[] swapData;
}

/// @notice Helper struct to compare strategy share between eachother
/// @dev Used for reallocation optimization of shares (strategy matching deposits and withdrawals between eachother when reallocating)
struct PriceData {
    uint128 totalValue;
    uint128 totalShares;
}

/// @notice Strategy reallocation values after reallocation optimization of shares was calculated 
struct ReallocationShares {
    uint128[] optimizedWithdraws;
    uint128[] optimizedShares;
    uint128[] totalSharesWithdrawn;
}

/// @notice Shared storage for multiple strategies
/// @dev This is used when strategies are part of the same proticil (e.g. Curve 3pool)
struct StrategiesShared {
    uint184 value;
    uint32 lastClaimBlock;
    uint32 lastUpdateBlock;
    uint8 stratsCount;
    mapping(uint256 => address) stratAddresses;
    mapping(bytes32 => uint256) bytesValues;
}

/// @notice Base storage shared betweek Spool contract and Strategies
/// @dev this way we can use same values when performing delegate call
/// to strategy implementations from the Spool contract
abstract contract BaseStorage {
    // ----- DHW VARIABLES -----

    /// @notice Force while DHW (all strategies) to be executed in only one transaction
    /// @dev This is enforced to increase the gas efficiency of the system
    /// Can be removed by the DAO if gas gost of the strategies goes over the block limit
    bool internal forceOneTxDoHardWork;

    /// @notice Global index of the system
    /// @dev Insures the correct strategy DHW execution.
    /// Every strategy in the system must be equal or one less than global index value
    /// Global index increments by 1 on every do-hard-work
    uint24 public globalIndex;

    /// @notice number of strategies unprocessed (by the do-hard-work) in the current index to be completed
    uint8 internal doHardWorksLeft;

    // ----- REALLOCATION VARIABLES -----

    /// @notice Used for offchain execution to get the new reallocation table.
    bool internal logReallocationTable;

    /// @notice number of withdrawal strategies unprocessed (by the do-hard-work) in the current index
    /// @dev only used when reallocating
    /// after it reaches 0, deposit phase of the reallocation can begin
    uint8 public withdrawalDoHardWorksLeft;

    /// @notice Index at which next reallocation is set
    uint24 public reallocationIndex;

    /// @notice 2D table hash containing information of how strategies should be reallocated between eachother
    /// @dev Created when allocation provider sets reallocation for the vaults
    /// This table is stored as a hash in the system and verified on reallocation DHW
    /// Resets to 0 after reallocation DHW is completed
    bytes32 internal reallocationTableHash;

    /// @notice Hash of all the strategies array in the system at the time when reallocation was set for index
    /// @dev this array is used for the whole reallocation period even if a strategy gets exploited when reallocating.
    /// This way we can remove the strategy from the system and not breaking the flow of the reallocaton
    /// Resets when DHW is completed
    bytes32 internal reallocationStrategiesHash;

    // -----------------------------------

    /// @notice Denoting if an address is the do-hard-worker
    mapping(address => bool) public isDoHardWorker;

    /// @notice Denoting if an address is the allocation provider
    mapping(address => bool) public isAllocationProvider;

    /// @notice Strategies shared storage
    /// @dev used as a helper storage to save common inoramation
    mapping(bytes32 => StrategiesShared) internal strategiesShared;

    /// @notice Mapping of strategy implementation address to strategy system values
    mapping(address => Strategy) public strategies;

    /// @notice Flag showing if disable was skipped when a strategy has been removed
    /// @dev If true disable can still be run 
    mapping(address => bool) internal _skippedDisable;

    /// @notice Flag showing if after removing a strategy emergency withdraw can still be executed
    /// @dev If true emergency withdraw can still be executed
    mapping(address => bool) internal _awaitingEmergencyWithdraw;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

/// @title Common Spool contracts constants
abstract contract BaseConstants {
    /// @dev 2 digits precision
    uint256 internal constant FULL_PERCENT = 100_00;

    /// @dev Accuracy when doing shares arithmetics
    uint256 internal constant ACCURACY = 10**30;
}

/// @title Contains USDC token related values
abstract contract USDC {
    /// @notice USDC token contract address
    IERC20 internal constant USDC_ADDRESS = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

import "../interfaces/ISpoolOwner.sol";

/// @title Logic to help check whether the caller is the Spool owner
abstract contract SpoolOwnable {
    /// @notice Contract that checks if address is Spool owner
    ISpoolOwner internal immutable spoolOwner;

    /**
     * @notice Sets correct initial values
     * @param _spoolOwner Spool owner contract address
     */
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    /**
     * @notice Checks if caller is Spool owner
     * @return True if caller is Spool owner, false otherwise
     */
    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }


    /// @notice Checks and throws if caller is not Spool owner
    function _onlyOwner() private view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    /// @notice Checks and throws if caller is not Spool owner
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "../interfaces/IController.sol";

/// @title Facilitates checking if the system is paused or not
abstract contract SpoolPausable {
    /* ========== STATE VARIABLES ========== */

    /// @notice The controller contract that is consulted for a strategy's and vault's validity
    IController public immutable controller;

    /**
     * @notice Sets initial values
     * @param _controller Controller contract address
     */
    constructor(IController _controller) {
        require(
            address(_controller) != address(0),
            "SpoolPausable::constructor: Controller contract address cannot be 0"
        );

        controller = _controller;
    }

    /* ========== MODIFIERS ========== */

    /// @notice Throws if system is paused
    modifier systemNotPaused() {
        controller.checkPaused();
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolBase.sol";
import "../shared/BaseStorage.sol";
import "../shared/SpoolOwnable.sol";
import "../shared/Constants.sol";

// libraries
import "../libraries/Hash.sol";

// other imports
import "../interfaces/IController.sol";
import "../shared/SpoolPausable.sol";

/**
 * @notice Implementation of the {ISpoolBase} interface.
 *
 * @dev
 * This implementation acts as the central code execution point of the Spool
 * system and is responsible for maintaining the balance sheet of each vault
 * based on the asynchronous deposit and withdraw system, redeeming vault
 * shares and withdrawals and performing doHardWork.
 */
abstract contract SpoolBase is
    ISpoolBase,
    BaseStorage,
    SpoolOwnable,
    SpoolPausable,
    BaseConstants
{

    /* ========== STATE VARIABLES ========== */

    /// @notice The fast withdraw contract that is used to quickly remove shares
    address internal immutable fastWithdraw;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Sets the contract initial values
     *
     * @dev 
     * Additionally, initializes the SPL reward data for
     * do hard work invocations.
     *
     * It performs certain pre-conditional validations to ensure the contract
     * has been initialized properly, such as valid addresses and reward configuration.
     *
     * @param _spoolOwner the spool owner contract address 
     * @param _controller the controller contract address
     * @param _fastWithdraw the fast withdraw contract address
     */
    constructor(
        ISpoolOwner _spoolOwner,
        IController _controller,
        address _fastWithdraw
    ) 
        SpoolOwnable(_spoolOwner)
        SpoolPausable(_controller)
    {
        require(
            _fastWithdraw != address(0),
            "BaseSpool::constructor: FastWithdraw address cannot be 0"
        );

        fastWithdraw = _fastWithdraw;
        
        globalIndex = 1;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Checks whether Spool is mid reallocation
     * @return _isMidReallocation True if Spool is mid reallocation
     */
    function isMidReallocation() public view override returns (bool _isMidReallocation) {
        if (reallocationIndex == globalIndex && !_isBatchComplete()) {
            _isMidReallocation = true;
        }
    }

    /**
     * @notice Returns strategy shares belonging to a vauld
     * @param strat Strategy address
     * @param vault Vault address
     * @return Shares for a specific vault - strategy combination
     */
    function getStratVaultShares(address strat, address vault) external view returns(uint128) {
        return strategies[strat].vaults[vault].shares;
    }

    /**
     * @notice Returns completed index (all strategies in the do hard work have been processed)
     * @return Completed index
     */
    function getCompletedGlobalIndex() public override view returns(uint24) {
        if (_isBatchComplete()) {
            return globalIndex;
        } 
        
        return globalIndex - 1;
    }

    /**
     * @notice Returns next possible index to interact with
     * @return Next active global index
     */
    function getActiveGlobalIndex() public override view returns(uint24) {
        return globalIndex + 1;
    }
    
    /**
     * @notice Check if batch complete
     * @return isComplete True if all strategies have the same index
     */
    function _isBatchComplete() internal view returns(bool isComplete) {
        if (doHardWorksLeft == 0) {
            isComplete = true;
        }
    }

    /**
     * @notice Decode revert message
     * @param _returnData Data returned by delegatecall
     * @return Revert string
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // if the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "SILENT";
        assembly {
        // slice the sig hash
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // all that remains is the revert string
    }

    /* ========== DELEGATECALL HELPERS ========== */

    /**
     * @notice this function allows static-calling an arbitrary write function from Spool, off-chain, and returning the result. The general purpose is for the calculation of
     * rewards in an implementation contract, where the reward calculation contains state changes that can't be easily gathered without calling from the Spool contract.
     * The require statement ensure that this comes from a static call off-chain, which can substitute an arbitrary address. 
     * The 'one' address is used. The zero address could be used, but due to the prevalence of zero address checks, the internal calls would likely fail.
     * It has the same level of security as finding any arbitrary address, including address zero.
     *
     * @param implementation Address which to relay the call to
     * @param payload Payload to relay to the implementation
     * @return Response returned by the relayed call
     */
    function relay(address implementation, bytes memory payload) external returns(bytes memory) {
        require(msg.sender == address(1));
        return _relay(implementation, payload);
    }

    /**
     * @notice Relays the particular action to the strategy via delegatecall.
     * @param strategy Strategy address to delegate the call to
     * @param payload Data to pass when delegating call
     * @return Response received when delegating call
     */
    function _relay(address strategy, bytes memory payload)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory data) = strategy.delegatecall(payload);
        if (!success) revert(_getRevertMsg(data));
        return data;
    }

    /* ========== CONFIGURATION ========== */

    /**
     * @notice Set allocation provider role for given user
     * Requirements:
     * - the caller must be the Spool owner (Spool DAO)
     *
     * @param user Address to set the role for
     * @param _isAllocationProvider Whether the user is assigned the role or not
     */
    function setAllocationProvider(address user, bool _isAllocationProvider) external onlyOwner {
        isAllocationProvider[user] = _isAllocationProvider;
        emit SetAllocationProvider(user, _isAllocationProvider);
    }

    /**
     * @notice Set doHardWorker role for given user
     * Requirements:
     * - the caller must be the Spool owner (Spool DAO)
     *
     * @param user Address to set the role for
     * @param _isDoHardWorker Whether the user is assigned the role or not
     */
    function setDoHardWorker(address user, bool _isDoHardWorker) external onlyOwner {
        isDoHardWorker[user] = _isDoHardWorker;
        emit SetIsDoHardWorker(user, _isDoHardWorker);
    }

    /**
     * @notice Set the flag to force "do hard work" to be executed in one transaction.
     * Requirements:
     * - the caller must be the Spool owner (Spool DAO)
     *
     * @param doForce Enable/disable running in one transactions
     */
    function setForceOneTxDoHardWork(bool doForce) external onlyOwner {
        forceOneTxDoHardWork = doForce;
    }

    /**
     * @notice Set the flag to log reallocation proportions on change.
     * Requirements:
     * - the caller must be the Spool owner (Spool DAO)
     *
     * @dev Used for offchain execution to get the new reallocation table.
     * @param doLog Whether to log or not
     */
    function setLogReallocationTable(bool doLog) external onlyOwner {
        logReallocationTable = doLog;
    }

    /**
     * @notice Set awaiting emergency withdraw flag for the strategy.
     *
     * @dev
     * Only for emergency case where withdrawing the first time doesn't fully work.
     *
     * Requirements:
     *
     * - the caller must be the Spool owner (Spool DAO)
     *
     * @param strat strategy to set
     * @param isAwaiting Flag value
     */
    function setAwaitingEmergencyWithdraw(address strat, bool isAwaiting) external onlyOwner {
        _awaitingEmergencyWithdraw[strat] = isAwaiting;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Ensures that given address is a valid vault
     */
    function _isVault(address vault) internal view {
        require(
            controller.validVault(vault),
            "NTVLT"
        );
    }

    /**
     * @notice Ensures that strategy wasn't removed
     */
    function _notRemoved(address strat) internal view {
        require(
            !strategies[strat].isRemoved,
            "OKSTRT"
        );
    }

    /**
     * @notice If batch is complete it resets reallocation variables and emits an event
     * @param isReallocation If true, reset the reallocation variables
     */
    function _finishDhw(bool isReallocation) internal {
        if (_isBatchComplete()) {
            // reset reallocation variables
            if (isReallocation) {
                reallocationIndex = 0;
                reallocationTableHash = 0;
            }

            emit DoHardWorkCompleted(globalIndex);
        }
    }

    /* ========== PRIVATE FUNCTIONS ========== */

    /**
     * @notice Ensures that the caller is the controller
     */
    function _onlyController() private view {
        require(
            msg.sender == address(controller),
            "OCTRL"
        );
    }

    /**
     * @notice Ensures that the caller is the fast withdraw
     */
    function _onlyFastWithdraw() private view {
        require(
            msg.sender == fastWithdraw,
            "OFWD"
        );
    }

    /**
     * @notice Ensures that there is no pending reallocation
     */
    function _noPendingReallocation() private view {
        require(
            reallocationTableHash == 0,
            "NORLC"
        );
    }

    /**
     * @notice Ensures that strategy is removed
     */
    function _onlyRemoved(address strat) private view {
        require(
            strategies[strat].isRemoved,
            "RMSTR"
        );
    }

    /**
     * @notice Verifies given strategies
     * @param strategies Array of strategies to verify
     */
    function _verifyStrategies(address[] memory strategies) internal view {
        controller.verifyStrategies(strategies);
    }

    /**
     * @notice Ensures that the caller is allowed to execute do hard work
     */
    function _onlyDoHardWorker() private view {
        require(
            isDoHardWorker[msg.sender],
            "ODHW"
        );
    }

    /**
     * @notice Verifies the reallocation table against the stored hash
     * @param reallocationTable The data to verify
     */
    function _verifyReallocationTable(uint256[][] memory reallocationTable) internal view {
        require(reallocationTableHash == Hash.hashReallocationTable(reallocationTable), "BRLC");
    }

    /**
     * @notice Verifies the reallocation strategies against the stored hash
     * @param strategies Array of strategies to verify
     */
    function _verifyReallocationStrategies(address[] memory strategies) internal view {
        require(Hash.sameStrategies(strategies, reallocationStrategiesHash), "BRLCSTR");
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if called by anyone else other than the controller
     */
    modifier onlyDoHardWorker() {
        _onlyDoHardWorker();
        _;
    }

    /**
     * @notice Throws if called by a non-valid vault
     */
    modifier onlyVault() {
        _isVault(msg.sender);
        _;
    }

    /**
     * @notice Throws if called by anyone else other than the controller
     */
    modifier onlyController() {
        _onlyController();
        _;
    }

    /**
     * @notice Throws if the caller is not fast withdraw
     */
    modifier onlyFastWithdraw() {
        _onlyFastWithdraw();
        _;
    }

    /**
     * @notice Throws if given array of strategies is not valid
     */
    modifier verifyStrategies(address[] memory strategies) {
        _verifyStrategies(strategies);
        _;
    }

    /**
     * @notice Throws if given array of reallocation strategies is not valid
     */
    modifier verifyReallocationStrategies(address[] memory strategies) {
        _verifyReallocationStrategies(strategies);
        _;
    }

    /**
     * @notice Throws if caller does not have the allocation provider role
     */
    modifier onlyAllocationProvider() {
        require(
            isAllocationProvider[msg.sender],
            "OALC"
        );
        _;
    }

    /**
     * @notice Ensures that there is no pending reallocation
     */
    modifier noPendingReallocation() {
        _noPendingReallocation();
        _;
    }

    /**
     * @notice Throws strategy is removed
     */
    modifier notRemoved(address strat) {
        _notRemoved(strat);
        _;
    }

    /**
     * @notice Throws strategy isn't removed
     */
    modifier onlyRemoved(address strat) {
        _onlyRemoved(strat);
        _;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolDoHardWork.sol";
import "./SpoolStrategy.sol";

/**
 * @notice Spool part of implementation dealing with the do hard work
 *
 * @dev
 * Do hard work is the process of interacting with other protocols.
 * This process aggregates many actions together to act in as optimized
 * manner as possible. It optimizes for underlying assets and gas cost.
 *
 * Do hard work (DHW) is executed periodically. As users are depositing
 * and withdrawing, these actions are stored in the buffer system.
 * When executed the deposits and withdrawals are matched against
 * eachother to minimize slippage and protocol fees. This means that
 * for a normal DHW only deposit or withdrawal is executed and never
 * both in the same index. Both can only be if the DHW is processing
 * the reallocation as well.
 *
 * Each strategy DHW is executed once per index and then incremented.
 * When all strategies are incremented to the same index, the batch
 * is considered complete. As soon as a new batch starts (first strategy
 * in the new batch is processed) global index is incremented.
 *
 * Global index is always one more or equal to the strategy index.
 * This constraints the system so that all strategy DHWs have to be
 * executed to complete the batch.
 *
 * Do hard work can only be executed by the whitelisted addresses.
 * The whitelisting can be done only by the Spool DAO.
 *
 * Do hard work actions:
 * - deposit
 * - withdrawal
 * - compound rewards
 * - reallocate assets across protocols
 *
 */
abstract contract SpoolDoHardWork is ISpoolDoHardWork, SpoolStrategy {

    /* ========== DO HARD WORK ========== */

    /**
     * @notice Executes do hard work of specified strategies.
     * 
     * @dev
     * Requirements:
     *
     * - caller must be a valid do hard worker
     * - provided strategies must be valid
     * - reallocation is not pending for current index
     * - if `forceOneTxDoHardWork` flag is true all strategies should be executed in one transaction
     * - at least one strategy must be processed
     * - the system should not be paused
     *
     * @param stratIndexes Array of strategy indexes
     * @param slippages Array of slippage values to be used when depositing into protocols (e.g. minOut)
     * @param rewardSlippages Array of values containing information of if and how to swap reward tokens to strategy underlying
     * @param allStrategies Array of all valid strategy addresses in the system
     */
    function batchDoHardWork(
        uint256[] memory stratIndexes,
        uint256[][] memory slippages,
        RewardSlippages[] memory rewardSlippages,
        address[] memory allStrategies
    ) 
        external
        systemNotPaused
        onlyDoHardWorker
        verifyStrategies(allStrategies)
    {
        // update global index if this are first strategies in index
        if (_isBatchComplete()) {
            globalIndex++;
            doHardWorksLeft = uint8(allStrategies.length);
        }

        // verify reallocation is not set for the current index
        if (reallocationIndex == globalIndex) {
            // if reallocation is set, verify it was disabled
            require(reallocationTableHash == 0, "RLC");
            // if yes, reset reallocation index
            reallocationIndex = 0;
        }
        
        require(
            stratIndexes.length > 0 &&
            stratIndexes.length == slippages.length &&
            stratIndexes.length == rewardSlippages.length,
            "BIPT"
        );

        // check if DHW is forcen to be executen on one transaction
        if (forceOneTxDoHardWork) {
            require(stratIndexes.length == allStrategies.length, "1TX");
        }

        // go over withdrawals and deposits
        for (uint256 i = 0; i < stratIndexes.length; i++) {
            address stratAddress = allStrategies[stratIndexes[i]];
            _doHardWork(stratAddress, slippages[i], rewardSlippages[i]);
            _updatePending(stratAddress);
            _finishStrategyDoHardWork(stratAddress);  
        }

        _updateDoHardWorksLeft(stratIndexes.length);

        // if DHW for index finished
        _finishDhw(false);
    }

    /**
     * @notice Process strategy DHW, deposit wnd withdraw
     * @dev Only executed when there is no reallocation for the DHW
     * @param strat Strategy address
     * @param slippages Array of slippage values to be used when depositing into protocols (e.g. minOut)
     * @param rewardSlippages Array of values containing information of if and how to swap reward tokens to strategy underlying
     */
    function _doHardWork(
        address strat,
        uint256[] memory slippages,
        RewardSlippages memory rewardSlippages
    ) private {
        Strategy storage strategy = strategies[strat];

        // Check if strategy wasn't exected in current index yet
        require(strategy.index < globalIndex, "SFIN");

        _process(strat, slippages, rewardSlippages.doClaim, rewardSlippages.swapData);
    }

    /* ========== DO HARD WORK when REALLOCATING ========== */

    /**
     * @notice Executes do hard work of specified strategies if reallocation is in progress.
     * 
     * @dev
     * Requirements:
     *
     * - caller must be a valid do hard worker
     * - provided strategies must be valid
     * - reallocation is pending for current index
     * - at least one strategy must be processed
     * - the system should not be paused
     *
     * @param withdrawData Reallocation values addressing withdrawal part of the reallocation DHW
     * @param depositData Reallocation values addressing deposit part of the reallocation DHW
     * @param allStrategies Array of all strategy addresses in the system for current set reallocation
     * @param isOneTransaction Flag denoting if the DHW should execute in one transaction
     */
    function batchDoHardWorkReallocation(
        ReallocationWithdrawData memory withdrawData,
        ReallocationData memory depositData,
        address[] memory allStrategies,
        bool isOneTransaction
    ) external systemNotPaused onlyDoHardWorker verifyReallocationStrategies(allStrategies) {
        if (_isBatchComplete()) {
            globalIndex++;
            
            doHardWorksLeft = uint8(allStrategies.length);
            withdrawalDoHardWorksLeft = uint8(allStrategies.length);
        }

        // verify reallocation is set for the current index, and not disabled
        require(
            reallocationIndex == globalIndex &&
            reallocationTableHash != 0,
            "XNRLC"
        );

        // add all indexes if DHW is in one transaction
        if (isOneTransaction) {
            require(
                    withdrawData.stratIndexes.length == allStrategies.length &&
                    depositData.stratIndexes.length == allStrategies.length,
                    "1TX"
                );
        } else {
            require(!forceOneTxDoHardWork, "F1TX");
            
            require(withdrawData.stratIndexes.length > 0 || depositData.stratIndexes.length > 0, "NOSTR");
        }

        // execute deposits and withdrawals
        _batchDoHardWorkReallocation(withdrawData, depositData, allStrategies);

        // update if DHW for index finished
        _finishDhw(true);
    }

    /**
     * @notice Executes do hard work of specified strategies if reallocation is in progress.
     * @param withdrawData Reallocation values addressing withdrawal part of the reallocation DHW
     * @param depositData Reallocation values addressing deposit part of the reallocation DHW
     * @param allStrategies Array of all strategy addresses in the system for current set reallocation
     */
    function _batchDoHardWorkReallocation(
        ReallocationWithdrawData memory withdrawData,
        ReallocationData memory depositData,
        address[] memory allStrategies
    ) private {
        // WITHDRAWALS
        // reallocation withdraw
        // process users deposit and withdrawals
        if (withdrawData.stratIndexes.length > 0) {
            // check parameters
            require(
                withdrawData.stratIndexes.length == withdrawData.slippages.length && 
                withdrawalDoHardWorksLeft >= withdrawData.stratIndexes.length,
                "BWI"
            );
            
            // verify if reallocation table matches the reallocationtable hash
            _verifyReallocationTable(withdrawData.reallocationTable);

            // get current strategy price data
            // this is later used to calculate the amount that can me matched
            // between 2 strategies when they deposit in eachother
            PriceData[] memory spotPrices = _getPriceData(withdrawData, allStrategies);

            // process the withdraw part of the reallocation
            // process the deposit and the withdrawal part of the users deposits/withdrawals
            _processWithdraw(
                withdrawData,
                allStrategies,
                spotPrices
            );

            // update number of strategies needing to be processed for the current reallocation DHW
            // can continue to deposit only when it reaches 0
            _updateWithdrawalDohardWorksleft(withdrawData.stratIndexes.length);
        }

        // check if withdrawal phase was finished before starting deposit
        require(
            !(depositData.stratIndexes.length > 0 && withdrawalDoHardWorksLeft > 0),
            "WNF"
        );

        // DEPOSITS
        // deposit reallocated amounts withdrawn above into strategies
        if (depositData.stratIndexes.length > 0) {
            // check parameters
            require(
                doHardWorksLeft >= depositData.stratIndexes.length &&
                depositData.stratIndexes.length == depositData.slippages.length,
                "BDI"
            );

            // deposit reallocated amounts into strategies
            // this only deals with the reallocated amounts as users were already processed in the withdrawal phase
            for (uint128 i = 0; i < depositData.stratIndexes.length; i++) {
                uint256 stratIndex = depositData.stratIndexes[i];
                address stratAddress = allStrategies[stratIndex];
                Strategy storage strategy = strategies[stratAddress];

                // verify the strategy was not removed (it could be removed in the middle of the DHW if the DHW was executed in multiple transactions)
                _notRemoved(stratAddress);
                require(strategy.isInDepositPhase, "SWNP");

                // deposit reallocation withdrawn amounts according to the calculations
                _doHardWorkDeposit(stratAddress, depositData.slippages[stratIndex]);
                // mark strategy as finished for the current index
                _finishStrategyDoHardWork(stratAddress);

                // remove the flag indicating strategy should deposit reallocated amount
                strategy.isInDepositPhase = false;
            }
            
            // update number of strategies left in the current index
            // if this reaches 0, DHW is considered complete
            _updateDoHardWorksLeft(depositData.stratIndexes.length);
        }
    }

    /**
      * @notice Executes user process and withdraw part of the do-hard-work for the specified strategies when reallocation is in progress.
      * @param withdrawData Reallocation values addressing withdrawal part of the reallocation DHW
      * @param allStrategies Array of all strategy addresses in the system for current set reallocation
      * @param spotPrices current strategy share price data, used to calculate the amount that can me matched between 2 strategies when reallcating
      */
    function _processWithdraw(
        ReallocationWithdrawData memory withdrawData,
        address[] memory allStrategies,
        PriceData[] memory spotPrices
    ) private {
        // go over reallocation table and calculate what amount of shares can be optimized when reallocating
        // we can optimize if two strategies deposit into eachother. With the `spotPrices` we can compare the strategy values.
        ReallocationShares memory reallocation = _optimizeReallocation(withdrawData, spotPrices);

        // go over withdrawals
        for (uint256 i = 0; i < withdrawData.stratIndexes.length; i++) {
            uint256 stratIndex = withdrawData.stratIndexes[i];
            address stratAddress = allStrategies[stratIndex];
            Strategy storage strategy = strategies[stratAddress];
            _notRemoved(stratAddress);
            require(!strategy.isInDepositPhase, "SWP");

            uint128 withdrawnReallocationReceived;
            {
                uint128 sharesToWithdraw = reallocation.totalSharesWithdrawn[stratIndex] - reallocation.optimizedShares[stratIndex];

                ProcessReallocationData memory processReallocationData = ProcessReallocationData(
                    sharesToWithdraw,
                    reallocation.optimizedShares[stratIndex],
                    reallocation.optimizedWithdraws[stratIndex]
                );
                
                // withdraw reallocation / returns non-optimized withdrawn amount
                withdrawnReallocationReceived = _doHardWorkReallocation(stratAddress, withdrawData.slippages[stratIndex], processReallocationData);
            }            

            // reallocate withdrawn to other strategies
            _depositReallocatedAmount(
                reallocation.totalSharesWithdrawn[stratIndex],
                withdrawnReallocationReceived,
                reallocation.optimizedWithdraws[stratIndex],
                allStrategies,
                withdrawData.reallocationTable[stratIndex]
            );

            _updatePending(stratAddress);

            strategy.isInDepositPhase = true;
        }
    }

    /**
     * @notice Process strategy DHW, including reallocation 
     * @dev Only executed when reallocation is set for the DHW
     * @param strat Strategy address
     * @param slippages Array of slippage values
     * @param processReallocationData Reallocation data (see ProcessReallocationData)
     * @return Received withdrawn reallocation
     */
    function _doHardWorkReallocation(
        address strat,
        uint256[] memory slippages,
        ProcessReallocationData memory processReallocationData
    ) private returns(uint128){
        Strategy storage strategy = strategies[strat];

        // Check if strategy wasn't exected in current index yet
        require(strategy.index < globalIndex, "SFIN");

        uint128 withdrawnReallocationReceived = _processReallocation(strat, slippages, processReallocationData);

        return withdrawnReallocationReceived;
    }

    /**
     * @notice Process deposit collected form the reallocation
     * @dev Only executed when reallocation is set for the DHW
     * @param strat Strategy address
     * @param slippages Array of slippage values
     */
    function _doHardWorkDeposit(
        address strat,
        uint256[] memory slippages
    ) private {
        _processDeposit(strat, slippages);
    }

    /**
     * @notice Calculate amount of shares that can be swapped between a pair of strategies (without withdrawing from the protocols)
     *
     * @dev This is done to ensure only the necessary amoun gets withdrawn from protocols and lower the total slippage and fee.
     * NOTE: We know strategies depositing into eachother must have the same underlying asset
     * The underlying asset is used to compare the amount ob both strategies withdrawing (depositing) into eachother. 
     *
     * Returns:
     * - amount of optimized collateral amount for each strategy
     * - amount of optimized shares for each strategy
     * - total non-optimized amount of shares for each strategy
     *
     * @param withdrawData Withdraw data (see WithdrawData)
     * @param priceData An array of price data (see PriceData)
     * @return reallocationShares Containing arrays showing the optimized share and underlying token amounts
     */
    function _optimizeReallocation(
        ReallocationWithdrawData memory withdrawData,
        PriceData[] memory priceData
    ) private pure returns (ReallocationShares memory) {
        // amount of optimized collateral amount for each strategy
        uint128[] memory optimizedWithdraws = new uint128[](withdrawData.reallocationTable.length);
        // amount of optimized shares for each strategy
        uint128[] memory optimizedShares = new uint128[](withdrawData.reallocationTable.length);
        // total non-optimized amount of shares for each strategy
        uint128[] memory totalShares = new uint128[](withdrawData.reallocationTable.length);
        
        // go over all the strategies (over reallcation table)
        for (uint128 i = 0; i < withdrawData.reallocationTable.length; i++) {
            for (uint128 j = i + 1; j < withdrawData.reallocationTable.length; j++) {
                // check if both strategies are depositing to eachother, if yes - optimize
                if (withdrawData.reallocationTable[i][j] > 0 && withdrawData.reallocationTable[j][i] > 0) {
                    // calculate strategy I underlying collateral amout withdrawing
                    uint128 amountI = uint128(withdrawData.reallocationTable[i][j] * priceData[i].totalValue / priceData[i].totalShares);
                    // calculate strategy I underlying collateral amout withdrawing
                    uint128 amountJ = uint128(withdrawData.reallocationTable[j][i] * priceData[j].totalValue / priceData[j].totalShares);

                    uint128 optimizedAmount;
                    
                    // check which strategy is withdrawing less
                    if (amountI > amountJ) {
                        optimizedAmount = amountJ;
                    } else {
                        optimizedAmount = amountI;
                    }
                    
                    // use the lesser value of both to save maximum possible optimized amount withdrawing
                    optimizedWithdraws[i] += optimizedAmount;
                    optimizedWithdraws[j] += optimizedAmount;
                }

                // sum total shares withdrawing for each strategy
                unchecked {
                    totalShares[i] += uint128(withdrawData.reallocationTable[i][j]);
                    totalShares[j] += uint128(withdrawData.reallocationTable[j][i]);
                }
            }

            // If we optimized for a strategy, calculate the total shares optimized back from the collateral amount.
            // The optimized shares amount will never be withdrawn from the strategy, as we know other strategies are
            // depositing to the strategy in the equal amount and we know how to mach them.
            if (optimizedWithdraws[i] > 0) {
                optimizedShares[i] = Math.getProportion128(optimizedWithdraws[i], priceData[i].totalShares, priceData[i].totalValue);
            }
        }

        ReallocationShares memory reallocationShares = ReallocationShares(
            optimizedWithdraws,
            optimizedShares,
            totalShares
        );
        
        return reallocationShares;
    }

    /**
     * @notice Get urrent strategy price data, containing total balance and total shares
     * @dev Also verify if the total strategy value is according to the defined values
     *
     * @param withdrawData Withdraw data (see WithdrawData)
     * @param allStrategies Array of strategy addresses
     * @return Price data (see PriceData)
     */
    function _getPriceData(
        ReallocationWithdrawData memory withdrawData,
        address[] memory allStrategies
    ) private returns(PriceData[] memory) {
        PriceData[] memory spotPrices = new PriceData[](allStrategies.length);

        for (uint128 i = 0; i < allStrategies.length; i++) {
            // claim rewards before getting the price
            if (withdrawData.rewardSlippages[i].doClaim) {
                _claimRewards(allStrategies[i], withdrawData.rewardSlippages[i].swapData);
            }
            
            for (uint128 j = 0; j < allStrategies.length; j++) {
                // if a strategy is withdrawing in reallocation get its spot price
                if (withdrawData.reallocationTable[i][j] > 0) {
                    // if strategy is removed treat it's value as 0
                    if (!strategies[allStrategies[i]].isRemoved) {
                        spotPrices[i].totalValue = _getStratValue(allStrategies[i]);
                    }

                    spotPrices[i].totalShares = strategies[allStrategies[i]].totalShares;

                    require(
                        spotPrices[i].totalValue >= withdrawData.priceSlippages[i].min &&
                        spotPrices[i].totalValue <= withdrawData.priceSlippages[i].max,
                        "BPRC"
                    );
                
                    break;
                }
            }
        }

        return spotPrices;
    }

    /**
      * @notice Processes reallocated amount deposits.
      * @param reallocateSharesToWithdraw Reallocate shares to withdraw
      * @param withdrawnReallocationReceived Received withdrawn reallocation
      * @param optimizedWithdraw Optimized withdraw
      * @param _strategies Array of strategy addresses
      * @param stratReallocationShares Array of strategy reallocation shares
      */
    function _depositReallocatedAmount(
        uint128 reallocateSharesToWithdraw,
        uint128 withdrawnReallocationReceived,
        uint128 optimizedWithdraw,
        address[] memory _strategies,
        uint256[] memory stratReallocationShares
    ) private {
        for (uint256 i = 0; i < stratReallocationShares.length; i++) {
            if (stratReallocationShares[i] > 0) {
                Strategy storage depositStrategy = strategies[_strategies[i]];

                // add actual withdrawn deposit
                depositStrategy.pendingReallocateDeposit +=
                    Math.getProportion128(withdrawnReallocationReceived, stratReallocationShares[i], reallocateSharesToWithdraw);

                // add optimized deposit
                depositStrategy.pendingReallocateOptimizedDeposit +=
                    Math.getProportion128(optimizedWithdraw, stratReallocationShares[i], reallocateSharesToWithdraw);
            }
        }
    }

    /* ========== SHARED FUNCTIONS ========== */

    /**
     * @notice After strategy DHW is complete increment strategy index
     * @param strat Strategy address
     */
    function _finishStrategyDoHardWork(address strat) private {
        Strategy storage strategy = strategies[strat];
        
        strategy.index++;

        emit DoHardWorkStrategyCompleted(strat, strategy.index);
    }

    /**
     * @notice After strategy DHW process update strategy pending values
     * @dev set pending next as pending and reset pending next
     * @param strat Strategy address
     */
    function _updatePending(address strat) private {
        Strategy storage strategy = strategies[strat];

        Pending memory pendingUserNext = strategy.pendingUserNext;
        strategy.pendingUser = pendingUserNext;
        
        if (
            pendingUserNext.deposit != Max128Bit.ZERO || 
            pendingUserNext.sharesToWithdraw != Max128Bit.ZERO
        ) {
            strategy.pendingUserNext = Pending(Max128Bit.ZERO, Max128Bit.ZERO);
        }
    }

    /**
     * @notice Update the number of "do hard work" processes left.
     * @param processedCount Number of completed actions
     */
    function _updateDoHardWorksLeft(uint256 processedCount) private {
        doHardWorksLeft -= uint8(processedCount);
    }

    /**
     * @notice Update the number of "withdrawal do hard work" processes left.
     * @param processedCount Number of completed actions
     */
    function _updateWithdrawalDohardWorksleft(uint256 processedCount) private {
        withdrawalDoHardWorksLeft -= uint8(processedCount);
    }

    /**
     * @notice Hash a reallocation table after it was updated
     * @param reallocationTable 2D table showing amount of shares withdrawing to each strategy
     */
    function _hashReallocationTable(uint256[][] memory reallocationTable) internal {
        reallocationTableHash = Hash.hashReallocationTable(reallocationTable);
        if (logReallocationTable) {
            // this is only meant to be emitted when debugging
            emit ReallocationTableUpdatedWithTable(reallocationIndex, reallocationTableHash, reallocationTable);
        } else {
            emit ReallocationTableUpdated(reallocationIndex, reallocationTableHash);
        }
    }

    /**
     * @notice Calculate and store the hash of the given strategy array
     * @param strategies Strategy addresses to hash
     */
    function _hashReallocationStrategies(address[] memory strategies) internal {
        reallocationStrategiesHash = Hash.hashStrategies(strategies);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolExternal.sol";
import "./SpoolReallocation.sol";

/**
 * @notice Exposes spool functions to set and redeem actions.
 *
 * @dev
 * Most of the functions are restricted to vaults. The action is
 * recorded in the buffer system and is processed at the next
 * do hard work.
 * A user cannot interact with any of the Spool functions directly.
 *
 * Complete interaction with Spool consists of 4 steps
 * 1. deposit
 * 2. redeem shares
 * 3. withdraw
 * 4. redeem underlying asset
 *
 * Redeems (step 2. and 4.) are done at the same time. Redeem is
 * processed automatically on first vault interaction after the DHW
 * is completed.
 *
 * As the system works asynchronously, between every step
 * a do hard work needs to be executed. The shares and actual
 * withdrawn amount are only calculated at the time of action (DHW). 
 */
abstract contract SpoolExternal is ISpoolExternal, SpoolReallocation {
    using Bitwise for uint256;
    using SafeERC20 for IERC20;
    using Max128Bit for uint128;

    /* ========== DEPOSIT ========== */

    /**
     * @notice Allows a vault to queue a deposit to a strategy.
     *
     * @dev
     * Requirements:
     *
     * - the caller must be a vault
     * - strategy shouldn't be removed
     *
     * @param strat Strategy address to deposit to
     * @param amount Amount to deposit
     * @param index Global index vault is depositing at (active global index)
     */
    function deposit(address strat, uint128 amount, uint256 index)
        external
        override
        onlyVault
        notRemoved(strat)
    {
        Strategy storage strategy = strategies[strat];
        Pending storage strategyPending = _getStrategyPending(strategy, index);

        Vault storage vault = strategy.vaults[msg.sender];
        VaultBatch storage vaultBatch = vault.vaultBatches[index];

        // save to storage
        strategyPending.deposit = strategyPending.deposit.add(amount);
        vaultBatch.deposited += amount;
    }

    /* ========== WITHDRAW ========== */

    /**
     * @notice Allows a vault to queue a withdrawal from a strategy.
     *
     * @dev
     * Requirements:
     *
     * - the caller must be a vault
     * - strategy shouldn't be removed
     *
     * @param strat Strategy address to withdraw from
     * @param vaultProportion Proportion of all vault-strategy shares a vault wants to withdraw, denoted in basis points (10_000 is 100%)
     * @param index Global index vault is depositing at (active global index)
     */
    function withdraw(address strat, uint256 vaultProportion, uint256 index)
        external
        override
        onlyVault
    {
        Strategy storage strategy = strategies[strat];
        Pending storage strategyPending = _getStrategyPending(strategy, index);

        Vault storage vault = strategy.vaults[msg.sender];
        VaultBatch storage vaultBatch = vault.vaultBatches[index];

        // calculate new shares to withdraw
        uint128 sharesToWithdraw = Math.getProportion128(vault.shares, vaultProportion, ACCURACY);

        // save to storage
        strategyPending.sharesToWithdraw = strategyPending.sharesToWithdraw.add(sharesToWithdraw);
        vaultBatch.withdrawnShares += sharesToWithdraw;
    }

    /* ========== DEPOSIT/WITHDRAW SHARED ========== */

    /**
     * @notice Get strategy pending struct, depending on if the strategy do hard work has already been executed in the current index
     * @param strategy Strategy data (see Strategy struct)
     * @param interactingIndex Global index for which to get the struct
     * @return pending Storage struct containing all unprocessed deposits and withdrawals for the `interactingIndex`
     */
    function _getStrategyPending(Strategy storage strategy, uint256 interactingIndex) private view returns (Pending storage pending) {
        // if index we are interacting with (active global index) is same as strategy index, then DHW has already been executed in index
        if (_isNextStrategyIndex(strategy, interactingIndex)) {
            pending = strategy.pendingUser;
        } else {
            pending = strategy.pendingUserNext;
        }
    }

    /* ========== REDEEM ========== */

    /**
     * @notice Allows a vault to redeem deposit and withdrawals for the processed index.
     * @dev
     *
     * Requirements:
     *
     * - the caller must be a valid vault
     *
     * @param strat Strategy address
     * @param index Global index the vault is redeeming for
     * @return Received vault received shares from the deposit and received vault underlying withdrawn amounts
     */
    function redeem(address strat, uint256 index)
        external
        override
        onlyVault
        returns (uint128, uint128)
    {
        Strategy storage strategy = strategies[strat];
        Batch storage batch = strategy.batches[index];
        Vault storage vault = strategy.vaults[msg.sender];
        VaultBatch storage vaultBatch = vault.vaultBatches[index];

        uint128 vaultBatchDeposited = vaultBatch.deposited;
        uint128 vaultBatchWithdrawnShares = vaultBatch.withdrawnShares;

        uint128 vaultDepositReceived = 0;
        uint128 vaultWithdrawnReceived = 0;
        uint128 vaultShares = vault.shares;

        // Make calculations if deposit in vault batch was performed
        if (vaultBatchDeposited > 0 && batch.deposited > 0) {
            vaultDepositReceived = Math.getProportion128(batch.depositedReceived, vaultBatchDeposited, batch.deposited);
            // calculate new vault-strategy shares
            // new shares are calculated at the DHW time, here vault only
            // takes the proportion of the vault deposit compared to the total deposit
            vaultShares += Math.getProportion128(batch.depositedSharesReceived, vaultBatchDeposited, batch.deposited);

            // reset to 0 to get the gas reimbursement
            vaultBatch.deposited = 0;
        }

        // Make calculations if withdraw in vault batch was performed
        if (vaultBatchWithdrawnShares > 0 && batch.withdrawnShares > 0) {
            // Withdrawn recieved represents the total underlying a strategy got back after DHW has processed the withdrawn shares.
            // This is stored at the DHW time, here vault only takes the proportion
            // of the vault shares withdrwan compared to the total shares withdrawn
            vaultWithdrawnReceived = Math.getProportion128(batch.withdrawnReceived, vaultBatchWithdrawnShares, batch.withdrawnShares);
            // substract all the shares withdrawn in the index after collecting the withdrawn recieved
            vaultShares -= vaultBatchWithdrawnShares;

            // reset to 0 to get the gas reimbursement
            vaultBatch.withdrawnShares = 0;
        }

        // store the updated shares
        vault.shares = vaultShares;

        return (vaultDepositReceived, vaultWithdrawnReceived);
    }

    /**
     * @notice Redeem underlying token
     * @dev
     * This function is only called by the vault after the vault redeem is processed
     * As redeem is called by each strategy separately, we don't want to transfer the
     * withdrawn underlyin tokens x amount of times. 
     *
     * Requirements:
     * - Can only be invoked by vault
     *
     * @param amount Amount to redeem
     */
    function redeemUnderlying(uint128 amount) external override onlyVault {
        IVault(msg.sender).underlying().safeTransfer(msg.sender, amount);
    }

    /* ========== REDEEM REALLOCATION ========== */

    /**
     * @notice Redeem vault shares after reallocation has been processed for the vault
     * @dev
     *
     * Requirements:
     * - Can only be invoked by vault
     *
     * @param vaultStrategies Array of vault strategy addresses
     * @param depositProportions Values representing how the vault has deposited it's withdrawn shares 
     * @param index Index at which the reallocation was perofmed
     */
    function redeemReallocation(
        address[] memory vaultStrategies,
        uint256 depositProportions,
        uint256 index
    ) external override onlyVault {
        // count number of strategies we deposit into
        uint128 depositStratsCount = 0;
        for (uint256 i = 0; i < vaultStrategies.length; i++) {
            uint256 prop = depositProportions.get14BitUintByIndex(i);
            if (prop > 0) {
                depositStratsCount++;
            }
        }

        // init deposit and withdrawal strategy arrays
        address[] memory withdrawStrats = new address[](vaultStrategies.length - depositStratsCount);
        address[] memory depositStrats = new address[](depositStratsCount);
        uint256[] memory depositProps = new uint256[](depositStratsCount);

        // fill deposit and withdrawal strategy arrays 
        {
            uint128 k = 0;
            uint128 l = 0;
            for (uint256 i = 0; i < vaultStrategies.length; i++) {
                uint256 prop = depositProportions.get14BitUintByIndex(i);
                if (prop > 0) {
                    depositStrats[k] = vaultStrategies[i];
                    depositProps[k] = prop;
                    k++;
                } else {
                    withdrawStrats[l] = vaultStrategies[i];
                    l++;
                }
            }
        }

        uint256 totalVaultWithdrawnReceived = 0;

        // calculate total withdrawal amount 
        for (uint256 i = 0; i < withdrawStrats.length; i++) {
            Strategy storage strategy = strategies[withdrawStrats[i]];
            BatchReallocation storage reallocationBatch = strategy.reallocationBatches[index];
            Vault storage vault = strategy.vaults[msg.sender];
            
            // if we withdrawed from strategy, claim and spread across deposits
            uint256 vaultWithdrawnReallocationShares = vault.withdrawnReallocationShares;
            if (vaultWithdrawnReallocationShares > 0) {
                // if batch withdrawn shares is 0, reallocation was canceled as a strategy was removed
                // if so, skip calculation and reset withdrawn reallcoation shares to 0
                if (reallocationBatch.withdrawnReallocationShares > 0) {
                    totalVaultWithdrawnReceived += 
                        (reallocationBatch.withdrawnReallocationReceived * vaultWithdrawnReallocationShares) / reallocationBatch.withdrawnReallocationShares;
                    // substract the shares withdrawn from in the reallocation
                    vault.shares -= uint128(vaultWithdrawnReallocationShares);
                }
                
                vault.withdrawnReallocationShares = 0;
            }
        }

        // calculate how the withdrawn amount was deposited to the depositing strategies
        uint256 vaultWithdrawnReceivedLeft = totalVaultWithdrawnReceived;
        uint256 lastDepositStratIndex = depositStratsCount - 1;
        for (uint256 i = 0; i < depositStratsCount; i++) {
            Strategy storage depositStrategy = strategies[depositStrats[i]];
            Vault storage depositVault = depositStrategy.vaults[msg.sender];
            BatchReallocation storage reallocationBatch = depositStrategy.reallocationBatches[index];
            if (reallocationBatch.depositedReallocation > 0) {
                // calculate reallocation strat deposit amount
                uint256 depositAmount;
                // if the strategy is last among the depositing ones, use the amount left to calculate the new shares
                // (same pattern was used when distributing the withdrawn shares to the depositing strategies - last strategy got what was left of shares)
                if (i < lastDepositStratIndex) {
                    depositAmount = (totalVaultWithdrawnReceived * depositProps[i]) / FULL_PERCENT;
                    vaultWithdrawnReceivedLeft -= depositAmount;
                } else { // if strat is last, use deposit left
                    depositAmount = vaultWithdrawnReceivedLeft;
                }

                // based on calculated deposited amount calculate/redeem the new strategy shares belonging to a vault
                depositVault.shares += 
                    SafeCast.toUint128((reallocationBatch.depositedReallocationSharesReceived * depositAmount) / reallocationBatch.depositedReallocation);
            }
        }
    }

    /* ========== FAST WITHDRAW ========== */

    /**
     * @notice Instantly withdraw shares from a strategy and return recieved underlying tokens.
     * @dev
     * User can execute the withdrawal of his shares from the vault at any time (except when
     * the reallocation is pending) without waiting for the DHW to process it. This is done
     * independently of other events. The gas cost is paid entirely by the user.
     * Withdrawn amount is sent back to the caller (FastWithdraw) contract, that later on,
     * sends it to a user.
     *
     * Requirements:
     *
     * - the caller must be a fast withdraw contract
     * - strategy shouldn't be removed
     *
     * @param strat Strategy address
     * @param underlying Address of underlying asset
     * @param shares Amount of shares to withdraw
     * @param slippages Strategy slippage values verifying the validity of the strategy state
     * @param swapData Array containig data to swap unclaimed strategy reward tokens for underlying asset
     * @return Withdrawn Underlying asset withdrarn amount
     */
    function fastWithdrawStrat(
        address strat,
        address underlying,
        uint256 shares,
        uint256[] memory slippages,
        SwapData[] memory swapData
    )
        external
        override
        onlyFastWithdraw
        notRemoved(strat)
        returns(uint128)
    {
        // returns withdrawn amount
        return  _fastWithdrawStrat(strat, underlying, shares, slippages, swapData);
    }

    /* ========== REMOVE SHARES (prepare for fast withdraw) ========== */

    /**
     * @notice Remove vault shares.
     *
     * @dev 
     * Called by the vault when a user requested a fast withdraw
     * These shares are either withdrawn from the strategies immidiately or
     * stored as user-strategy shares in the FastWithdraw contract.
     *
     * Requirements:
     *
     * - can only be called by the vault
     *
     * @param vaultStrategies Array of strategy addresses
     * @param vaultProportion Proportion of all vault-strategy shares a vault wants to remove, denoted in basis points (10_000 is 100%)
     * @return Array of removed shares per strategy
     */
    function removeShares(
        address[] memory vaultStrategies,
        uint256 vaultProportion
    )
        external
        override
        onlyVault
        returns(uint128[] memory)
    {
        uint128[] memory removedShares = new uint128[](vaultStrategies.length);

        for (uint128 i = 0; i < vaultStrategies.length; i++) {
            _notRemoved(vaultStrategies[i]);
            Strategy storage strategy = strategies[vaultStrategies[i]];

            Vault storage vault = strategy.vaults[msg.sender];

            uint128 sharesToWithdraw = Math.getProportion128(vault.shares, vaultProportion, ACCURACY);

            removedShares[i] = sharesToWithdraw;
            vault.shares -= sharesToWithdraw;
        }
        
        return removedShares;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolReallocation.sol";
import "./SpoolDoHardWork.sol";

// libraries
import "../libraries/Bitwise.sol";

// other imports
import "../interfaces/IVault.sol";

/**
 * @notice Spool part of implementation dealing with the reallocation of assets
 *
 * @dev
 * Allocation provider can update vault allocation across strategies.
 * This requires vault to withdraw from some and deposit to other strategies.
 * This happens across multiple vaults. The system handles all vault reallocations
 * at once and optimizes it between eachother and users.
 *
 */
abstract contract SpoolReallocation is ISpoolReallocation, SpoolDoHardWork {
    using Bitwise for uint256;

    /* ========== SET REALLOCATION ========== */

    /**
     * @notice Set vaults to reallocate on next do hard work
     * Requirements:
     * - Caller must have allocation provider role
     * - Vaults array must not be empty
     * - Vaults must be valid
     * - Strategies must be valid
     * - If reallocation was already initialized before:
     *    - Reallocation table hash must be set
     *    - Reallocation table must be valid
     *
     * @param vaults Array of vault addresses
     * @param strategies Array of strategy addresses
     * @param reallocationTable Reallocation details
     */
    function reallocateVaults(
        VaultData[] memory vaults,
        address[] memory strategies,
        uint256[][] memory reallocationTable
    ) external onlyAllocationProvider {
        require(vaults.length > 0, "NOVRLC");

        uint24 activeGlobalIndex = getActiveGlobalIndex();

        // If reallocation was already initialized before,
        // verify state and parameters before continuing
        if (reallocationIndex > 0) {
            // If reallocation was started for index and table hash is 0,
            // the reallocation was canceled. Prevent from setting it in same index again.
            require(reallocationTableHash != 0, "RLCSTP");
            // check if reallocation can still be set for same global index as before
            require(reallocationIndex == activeGlobalIndex, "RLCINP");
            // verifies strategies agains current reallocation strategies hash
            _verifyReallocationStrategies(strategies);
            _verifyReallocationTable(reallocationTable);
        } else { // if new reallocation, init empty reallocation shares table
            // verifies all system strategies using Controller contract
            _verifyStrategies(strategies);
            // hash and save strategies
            // this strategies hash is then used to verify strategies during the reallocation
            // if the strat is exploited and removed from the system, this hash is used to be consistent
            // with reallocation table ordering as system strategies change.
            _hashReallocationStrategies(strategies);
            reallocationIndex = activeGlobalIndex;
            reallocationTable = new uint256[][](strategies.length);

            for (uint256 i = 0; i < strategies.length; i++) {
                reallocationTable[i] = new uint256[](strategies.length);
            }

            emit StartReallocation(reallocationIndex);
        }

        // loop over vaults
        for (uint128 i = 0; i < vaults.length; i++) {
            // check if address is a valid vault
            _isVault(vaults[i].vault);

            // reallocate vault
            //address[] memory vaultStrategies = _buildVaultStrategiesArray(vaults[i].strategiesBitwise, vaults[i].strategiesCount, strategies);
            (uint256[] memory withdrawProportions, uint256 depositProportions) = 
                IVault(vaults[i].vault).reallocate(
                    _buildVaultStrategiesArray(vaults[i].strategiesBitwise, vaults[i].strategiesCount, strategies),
                    vaults[i].newProportions,
                    getCompletedGlobalIndex(), // NOTE: move to var if call stack not too deeep
                    activeGlobalIndex);

            // withdraw and deposit from vault strategies
            for (uint128 j = 0; j < vaults[i].strategiesCount; j++) {
                if (withdrawProportions[j] > 0) {
                    uint256 withdrawStratIndex = vaults[i].strategiesBitwise.get8BitUintByIndex(j);

                    (uint128 newSharesWithdrawn) = 
                        _reallocateVaultStratWithdraw(
                            vaults[i].vault,
                            strategies[withdrawStratIndex],
                            withdrawProportions[j],
                            activeGlobalIndex
                        );

                    _updateDepositReallocationForStrat(
                        newSharesWithdrawn,
                        vaults[i],
                        depositProportions,
                        reallocationTable[withdrawStratIndex]
                    );
                }
            }
        }        

        // Hash reallocation proportions
        _hashReallocationTable(reallocationTable);
    }

    /**
     * @notice Remove shares from strategy to set them for a reallocation
     * @param vaultAddress Vault address
     * @param strat Strategy address to remove shares
     * @param vaultProportion Proportion of all vault-strategy shares a vault wants to reallocate
     * @param index Global index we're reallocating for
     * @return newSharesWithdrawn New shares withdrawn fro reallocation
     */
    function _reallocateVaultStratWithdraw(
        address vaultAddress,
        address strat, 
        uint256 vaultProportion,
        uint256 index
    )
        private returns (uint128 newSharesWithdrawn)
    {
        Strategy storage strategy = strategies[strat];
        Vault storage vault = strategy.vaults[vaultAddress];
        VaultBatch storage vaultBatch = vault.vaultBatches[index];

        // calculate new shares to withdraw
        uint128 unwithdrawnVaultShares = vault.shares - vaultBatch.withdrawnShares;

        // if strategy wasn't executed in current batch yet, also substract unprocessed withdrawal shares in current batch

        if(!_isNextStrategyIndex(strategy, index)) {
            VaultBatch storage vaultBatchPrevious = vault.vaultBatches[index - 1];
            unwithdrawnVaultShares -= vaultBatchPrevious.withdrawnShares;
        }

        // return data
        newSharesWithdrawn = Math.getProportion128(unwithdrawnVaultShares, vaultProportion, ACCURACY);

        // save to storage
        vault.withdrawnReallocationShares = newSharesWithdrawn;
    }

    /**
     * @notice Checks whether the given index is next index for the strategy
     * @param strategy Strategy data (see Strategy struct)
     * @param interactingIndex Index to check
     * @return isNextStrategyIndex True if given index is the next strategy index
     */
    function _isNextStrategyIndex(
        Strategy storage strategy,
        uint256 interactingIndex
    ) internal view returns (bool isNextStrategyIndex) {
        if (strategy.index + 1 == interactingIndex) {
            isNextStrategyIndex = true;
        }
    }

    /**
     * @notice Update deposit reallocation for strategy
     * @param sharesWithdrawn Withdrawn shares
     * @param vaultData Vault data (see VaultData struct)
     * @param depositProportions Deposit proportions
     * @param stratReallocationTable Strategy reallocation table
     */
    function _updateDepositReallocationForStrat(
        uint128 sharesWithdrawn,
        VaultData memory vaultData,
        uint256 depositProportions,
        uint256[] memory stratReallocationTable
    ) private pure {
        // sharesToDeposit = sharesWithdrawn * deposit_strat%
        uint128 sharesWithdrawnleft = sharesWithdrawn;
        uint128 lastDepositedIndex = 0;
        for (uint128 i = 0; i < vaultData.strategiesCount; i++) {

            uint256 stratDepositProportion = depositProportions.get14BitUintByIndex(i);
            if (stratDepositProportion > 0) {
                uint256 globalStratIndex = vaultData.strategiesBitwise.get8BitUintByIndex(i);
                uint128 withdrawnSharesForStrat = Math.getProportion128(sharesWithdrawn, stratDepositProportion, FULL_PERCENT);
                stratReallocationTable[globalStratIndex] += withdrawnSharesForStrat;
                sharesWithdrawnleft -= withdrawnSharesForStrat;
                lastDepositedIndex = i;
            }
        }

        // add shares left from rounding error to last deposit strat
        stratReallocationTable[lastDepositedIndex] += sharesWithdrawnleft;
    }

    /* ========== SHARED ========== */

    /**
     * @notice Build vault strategies array from a 256bit word.
     * @dev Each vault index takes 8bits.
     *
     * @param bitwiseAddressIndexes Bitwise address indexes
     * @param strategiesCount Strategies count
     * @param strategies Array of strategy addresses
     * @return vaultStrategies Array of vault strategy addresses
     */
    function _buildVaultStrategiesArray(
        uint256 bitwiseAddressIndexes,
        uint8 strategiesCount,
        address[] memory strategies
    ) private pure returns(address[] memory vaultStrategies) {
        vaultStrategies = new address[](strategiesCount);

        for (uint128 i = 0; i < strategiesCount; i++) {
            uint256 stratIndex = bitwiseAddressIndexes.get8BitUintByIndex(i);
            vaultStrategies[i] = strategies[stratIndex];
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.11;

// extends
import "../interfaces/spool/ISpoolStrategy.sol";
import "./SpoolBase.sol";

// libraries
import "../external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "../libraries/Max/128Bit.sol";
import "../libraries/Math.sol";

// other imports
import "../interfaces/IBaseStrategy.sol";

/**
 * @notice Spool part of implementation dealing with strategy related processing
 */
abstract contract SpoolStrategy is ISpoolStrategy, SpoolBase {
    using SafeERC20 for IERC20;

    /* ========== VIEWS ========== */

    /**
     * @notice Returns the amount of funds the vault caller has in total
     * deployed to a particular strategy.
     *
     * @dev
     * Although not set as a view function due to the delegatecall
     * instructions performed by it, its value can be acquired
     * without actually executing the function by both off-chain
     * and on-chain code via simulating the transaction's execution.
     *
     * @param strat strategy address
     *
     * @return amount
     */
    function getUnderlying(address strat) external override returns (uint128) {
        Strategy storage strategy = strategies[strat];

        uint128 totalStrategyShares = strategy.totalShares;
        if (totalStrategyShares == 0) return 0;

        return Math.getProportion128(_totalUnderlying(strat), strategy.vaults[msg.sender].shares, totalStrategyShares);
    }

    /**
     * @notice Returns total strategy underlying value.
     * @param strat Strategy address
     * @return Total strategy underlying value
     */
    function getStratUnderlying(address strat) external returns (uint128) {
        return _totalUnderlying(strat); // deletagecall
    }

    /**
     * @notice Get total vault underlying at index.
     *
     * @dev
     * NOTE: Call ONLY if vault shares are correct for the index.
     *       Meaning vault has just redeemed for this index or this is current index.
     *
     * @param strat strategy address
     * @param index index in total underlying
     * @return Total vault underlying at index
     */
    function getVaultTotalUnderlyingAtIndex(address strat, uint256 index) external override view returns(uint128) {
        Strategy storage strategy = strategies[strat];
        Vault storage vault = strategy.vaults[msg.sender];
        TotalUnderlying memory totalUnderlying = strategy.totalUnderlying[index];

        if (totalUnderlying.totalShares > 0) {
            return Math.getProportion128(totalUnderlying.amount, vault.shares, totalUnderlying.totalShares);
        }
        
        return 0;
    }
    
    /**
     * @notice Yields the total underlying funds of a strategy.
     *
     * @dev
     * The function is not set as view given that it performs a delegate call
     * instruction to the strategy.
     * @param strategy Strategy address
     * @return Total underlying funds
     */
    function _totalUnderlying(address strategy)
        internal
        returns (uint128)
    {
        bytes memory data = _relay(
            strategy,
            abi.encodeWithSelector(IBaseStrategy.getStrategyBalance.selector)
        );

        return abi.decode(data, (uint128));
    }

    /**
     * @notice Get strategy total underlying balance including rewards
     * @param strategy Strategy address
     * @return strategyBačance Returns strategy balance with the rewards
     */
    function _getStratValue(
        address strategy
    ) internal returns(uint128) {
        bytes memory data = _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.getStrategyUnderlyingWithRewards.selector
            )
        );

        return abi.decode(data, (uint128));
    }

    /**
     * @notice Returns pending rewards for a strategy
     * @param strat Strategy for which to return rewards
     * @param reward Reward address
     * @return Pending rewards
     */
    function getPendingRewards(address strat, address reward) external view returns(uint256) {
        return strategies[strat].pendingRewards[reward];
    }

    /**
     * @notice Returns strat address in shared strategies mapping for index
     * @param sharedKey Shared strategies key
     * @param index Strategy addresses index
     * @return Strategy address
     */
    function getStratSharedAddress(bytes32 sharedKey, uint256 index) external view returns(address) {
        return strategiesShared[sharedKey].stratAddresses[index];
    }

    /* ========== MUTATIVE EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Adds and initializes a new strategy
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the controller
     * - reallcation must not be pending
     * - strategy shouldn't be previously removed
     *
     * @param strat Strategy to be added
     */
    function addStrategy(address strat)
        external
        override
        onlyController
        noPendingReallocation
        notRemoved(strat)
    {
        Strategy storage strategy = strategies[strat];

        strategy.index = globalIndex;
        // init as max zero, so first user interaction will be cheaper (non-zero to non-zero storage change)
        strategy.pendingUser = Pending(Max128Bit.ZERO, Max128Bit.ZERO);
        strategy.pendingUserNext = Pending(Max128Bit.ZERO, Max128Bit.ZERO);

        // initialize strategy specific values
        _initializeStrategy(strat);
    }

    /**
     * @notice Disables a strategy by liquidating all actively deployed funds
     * within it to its underlying collateral.
     *
     * @dev
     * This function is invoked whenever a strategy is disabled at the controller
     * level as an emergency.
     *
     * Requirements:
     *
     * - the caller must be the controller
     * - strategy shouldn't be previously removed
     *
     * @param strat strategy being disabled
     * @param skipDisable flag to skip executing strategy specific disable function
     *  NOTE: Should always be false, except if `IBaseStrategy.disable` is failing and there is no other way
     */
    function disableStrategy(
        address strat,
        bool skipDisable
    )
        external
        override
        onlyController
        notRemoved(strat)
    {
        if (isMidReallocation()) { // when reallocating
            _disableStrategyWhenReallocating(strat);
        } else { // no reallocation in progress
            _disableStrategyNoReallocation(strat);
        }

        Strategy storage strategy = strategies[strat];

        strategy.isRemoved = true;

        if (!skipDisable) {
            _disableStrategy(strat);
        } else {
            _skippedDisable[strat] = true;
        }

        _awaitingEmergencyWithdraw[strat] = true;
    }

    /**
     * @notice Disable strategy when reallocating
     * @param strat Strategy to disable
     */
    function _disableStrategyWhenReallocating(address strat) private {
        Strategy storage strategy = strategies[strat];

        if(strategy.index < globalIndex) {
            // is in withdrawal phase
            if (!strategy.isInDepositPhase) {
                // decrease do hard work withdrawals left
                if (withdrawalDoHardWorksLeft > 0) {
                    withdrawalDoHardWorksLeft--;
                }
            } else {
                // if user withdrawal was already performed, collect withdrawn amount to be emergency withdrawn
                // NOTE: `strategy.index + 1` has to be used as the strategy index has not increased yet
                _removeNondistributedWithdrawnReceived(strategy, strategy.index + 1);
            }

            _decreaseDoHardWorksLeft(true);

            // save waiting reallocation deposit to be emergency withdrawn
            strategy.emergencyPending += strategy.pendingReallocateDeposit;
            strategy.pendingReallocateDeposit = 0;
        }
    }

    /**
     * @notice Disable strategy when there is no reallocation
     * @param strat Strategy to disable
     */
    function _disableStrategyNoReallocation(address strat) private {
        Strategy storage strategy = strategies[strat];

        // check if the strategy has already been processed in ongoing do hard work
        if (strategy.index < globalIndex) {
            _decreaseDoHardWorksLeft(false);
        } else if (!_isBatchComplete()) {
            // if user withdrawal was already performed, collect withdrawn amount to be emergency withdrawn
            _removeNondistributedWithdrawnReceived(strategy, strategy.index);
        }

        // if reallocation is set to be processed, reset reallocation table to cancel it for set index
        if (reallocationTableHash != 0) {
            reallocationTableHash = 0;
        }
    }

    /**
     * @notice Decrease "do hard work" actions left
     * @notice isMidReallocation Whether system is mid-reallocation
     */
    function _decreaseDoHardWorksLeft(bool isMidReallocation) private {
        if (doHardWorksLeft > 0) {
            doHardWorksLeft--;
            // check if this was last strategy, to complete the do hard work
            _finishDhw(isMidReallocation);
        }
    }

    /**
     * @notice Removes the nondistributed amounts recieved, if any
     * @dev used when emergency withdrawing
     *
     * @param strategy Strategy address
     * @param index index remove from
     */
    function _removeNondistributedWithdrawnReceived(Strategy storage strategy, uint256 index) private {
        strategy.emergencyPending += strategy.batches[index].withdrawnReceived;
        strategy.batches[index].withdrawnReceived = 0;

        strategy.totalUnderlying[index].amount = 0;
    }

    /**
     * @notice Liquidating all actively deployed funds within a strategy after it was disabled.
     *
     * @dev
     * Requirements:
     *
     * - the caller must be the controller
     * - the strategy must be disabled
     * - the strategy must be awaiting emergency withdraw
     *
     * @param strat strategy being disabled
     * @param data data to perform the withdrawal
     * @param withdrawRecipient recipient of the withdrawn funds
     */
    function emergencyWithdraw(
        address strat,
        address withdrawRecipient,
        uint256[] memory data
    )
        external
        override
        onlyController
        onlyRemoved(strat)
    {

        if (_awaitingEmergencyWithdraw[strat]) {
            _emergencyWithdraw(strat, withdrawRecipient, data);

            _awaitingEmergencyWithdraw[strat] = false;
        } else if (strategies[strat].emergencyPending > 0) {
            IBaseStrategy(strat).underlying().transfer(withdrawRecipient, strategies[strat].emergencyPending);
            strategies[strat].emergencyPending = 0;
        }
    }

    /**
     * @notice Runs strategy specific disable function if it was skipped when disabling the strategy.
     * Requirements:
     * - the caller must be the controller
     * - the strategy must be disabled
     *
     * @param strat Strategy to remove
     */
    function runDisableStrategy(address strat)
        external
        override
        onlyController
        onlyRemoved(strat)
    {
        require(_skippedDisable[strat], "SDEX");

        _disableStrategy(strat);
        _skippedDisable[strat] = false;
    }

    /* ========== MUTATIVE INTERNAL FUNCTIONS ========== */

    /**
     * @notice Invokes the process function on the strategy to process teh pending actions
     * @dev executed deposit or withdrawal and compound of the reward tokens
     *
     * @param strategy Strategy address
     * @param slippages Array of slippage parameters to apply when depositing or withdrawing
     * @param harvestRewards Whether to harvest (swap and deposit) strategy rewards or not
     * @param swapData Array containig data to swap unclaimed strategy reward tokens for underlying asset
     */
    function _process(
        address strategy,
        uint256[] memory slippages,
        bool harvestRewards,
        SwapData[] memory swapData
    ) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.process.selector,
                slippages,
                harvestRewards,
                swapData
            )
        );
    }

    /**
     * @notice Invoke process reallocation for a strategy
     * @dev This is the first par of the strategy DHW when reallocating
     *
     * @param strategy Strategy address
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param processReallocationData Reallocation values used when processing
     * @return withdrawnUnderlying Actual withdrawn reallocation underlying assets received
     */
    function _processReallocation(
        address strategy,
        uint256[] memory slippages,
        ProcessReallocationData memory processReallocationData
    ) internal returns(uint128) {
        bytes memory data = _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.processReallocation.selector,
                slippages,
                processReallocationData
            )
        );

        // return actual withdrawn reallocation underlying assets received
        return abi.decode(data, (uint128));
    }

    /**
     * @notice Invoke process deposit for a strategy
     * @param strategy Strategy address
     * @param slippages Array of slippage parameters to apply when depositing
     */
    function _processDeposit(
        address strategy,
        uint256[] memory slippages
    ) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.processDeposit.selector,
                slippages
            )
        );
    }

    /**
     * @notice Invoke fast withdraw for a strategy
     * @param strategy Strategy to withdraw from
     * @param underlying Asset to withdraw
     * @param shares Amount of shares to withdraw
     * @param slippages Array of slippage parameters to apply when withdrawing
     * @param swapData Swap slippage and path array
     * @return Withdrawn amount
     */
    function _fastWithdrawStrat(
        address strategy,
        address underlying,
        uint256 shares,
        uint256[] memory slippages,
        SwapData[] memory swapData
    ) internal returns(uint128) {
        bytes memory data = _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.fastWithdraw.selector,
                shares,
                slippages,
                swapData
            )
        );

        (uint128 withdrawnAmount) = abi.decode(data, (uint128));

        IERC20(underlying).safeTransfer(msg.sender, withdrawnAmount);

        return withdrawnAmount;
    }

    /**
     * @notice Invoke claim rewards for a strategy
     * @param strategy Strategy address
     * @param swapData Swap slippage and path
     */
    function _claimRewards(
        address strategy,
        SwapData[] memory swapData
    ) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.claimRewards.selector,
                swapData
            )
        );
    }

    /**
     * @notice Invokes the emergencyWithdraw function on a strategy
     * @param strategy Strategy to which to relay the call to
     * @param recipient Address to which to withdraw to
     * @param data Strategy specific data to perorm energency withdraw  on a strategy
     */
    function _emergencyWithdraw(address strategy, address recipient, uint256[] memory data) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(
                IBaseStrategy.emergencyWithdraw.selector,
                recipient,
                data
            )
        );
    }

    /**
     * @notice Initializes strategy specific values
     * @param strategy Strategy to initialize
     */
    function _initializeStrategy(address strategy) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(IBaseStrategy.initialize.selector)
        );
    }

    /**
     * @notice Cleans strategy specific values after disabling
     * @param strategy Strategy to disable
     */
    function _disableStrategy(address strategy) internal {
        _relay(
            strategy,
            abi.encodeWithSelector(IBaseStrategy.disable.selector)
        );
    }
}