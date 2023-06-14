// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IConvexHandler.sol";
import "../interfaces/pools/ILpToken.sol";
import "../interfaces/vendor/IRewardStaking.sol";
import "../interfaces/vendor/IBooster.sol";
import "../interfaces/vendor/IBaseRewardPool.sol";
import "../interfaces/ICurveRegistryCache.sol";
import "../interfaces/IController.sol";

contract ConvexHandler is IConvexHandler {
    using SafeERC20 for IERC20;

    uint256 internal constant _CLIFF_COUNT = 1000;
    uint256 internal constant _CLIFF_SIZE = 100_000e18;
    uint256 internal constant _MAX_CVX_SUPPLY = 100_000_000e18;
    address internal constant _CVX_TOKEN = address(0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B);

    IController public immutable controller;

    constructor(address _controller) {
        controller = IController(_controller);
    }

    /// @notice Deposits a Curve LP token on Convex and stakes the Convex
    /// Curve LP token in the respective CRV rewards contract on Convex.
    /// @param _curvePool Curve Pool for which LP tokens should be deposited
    /// @param _amount Amount of Curve LP tokens to deposit
    function deposit(address _curvePool, uint256 _amount) external {
        uint256 pid = controller.curveRegistryCache().getPid(_curvePool);
        IBooster(controller.convexBooster()).deposit(pid, _amount, true);
    }

    /// @notice Withdraws Curve LP tokens from Convex.
    /// @dev Curve LP tokens get unstaked from the Convex CRV rewards contract.
    /// @param _curvePool Curve pool for which LP tokens should be withdrawn.
    /// @param _amount Amount of Curve LP tokens to withdraw.
    function withdraw(address _curvePool, uint256 _amount) external {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        IBaseRewardPool(rewardPool).withdrawAndUnwrap(_amount, true);
    }

    /// @notice Claims CRV, CVX and extra rewards from Convex on behalf of a Root pool.
    /// @param _curvePool Curve pool from which LP tokens have been deposited on Convex.
    /// @param _rootPool Root pool for which rewards will be claimed.
    function claimEarnings(address _curvePool, address _rootPool) external {
        _claimConvexReward(_curvePool, _rootPool);
    }

    /// @notice Claims CRV, CVX and extra rewards from Convex for multiple Curve LP tokens staked.
    /// @param _curvePools List of Curve pools from which LP tokens have been deposited
    /// @param _rootPool Root pool for which rewards will be claimed.
    function claimBatchEarnings(address[] memory _curvePools, address _rootPool) external {
        for (uint256 i; i < _curvePools.length; i++) {
            address pool = _curvePools[i];
            _claimConvexReward(pool, _rootPool);
        }
    }

    function getRewardPool(address _curvePool) public view returns (address) {
        return controller.curveRegistryCache().getRewardPool(_curvePool);
    }

    function _claimConvexReward(address _curvePool, address _rootPool) internal {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        IBaseRewardPool(rewardPool).getReward(_rootPool, true);
    }

    /// @notice Gets total amount of CRV earned by an account from staking an amount of
    /// Curve LP tokens via Convex for a single Curve pool.
    /// @param _account Account which staked an amount of Curve LP tokens.
    /// @param _curvePool Curve pool for which earned CRV should be computed.
    /// @return Total amount of CRV earned.
    function getCrvEarned(address _account, address _curvePool) public view returns (uint256) {
        address rewardPool = controller.curveRegistryCache().getRewardPool(_curvePool);
        return IBaseRewardPool(rewardPool).earned(_account);
    }

    /// @notice Gets total amount of CRV earned by an account from staking multiple Curve
    /// LP tokens via Convex.
    /// @param _account Account which staked Curve LP tokens.
    /// @param _curvePools List of Curve pools for which earned CRV should be computed.
    /// @return Total amount of CRV earned.
    function getCrvEarnedBatch(address _account, address[] memory _curvePools)
        external
        view
        returns (uint256)
    {
        uint256 totalCrvEarned;
        for (uint256 i; i < _curvePools.length; i++) {
            address pool = _curvePools[i];
            totalCrvEarned += getCrvEarned(_account, pool);
        }
        return totalCrvEarned;
    }

    /// @notice Computes how much CVX can be claimed for an amount of CRV earned
    /// @dev Not easily computable from the CVX token contract
    /// @param crvAmount Amount of CRV for which CVX will be minted pro rata.
    /// @return CVX amount that would be minted.
    function computeClaimableConvex(uint256 crvAmount) external view returns (uint256) {
        uint256 cvxTotalSupply = IERC20(_CVX_TOKEN).totalSupply();
        uint256 cliff = cvxTotalSupply / _CLIFF_SIZE;
        if (cliff >= _CLIFF_COUNT) {
            return 0;
        }
        uint256 remaining = _CLIFF_COUNT - cliff;
        uint256 cvxEarned = (crvAmount * remaining) / _CLIFF_COUNT;
        uint256 amountTillMax = _MAX_CVX_SUPPLY - cvxTotalSupply;
        if (cvxEarned > amountTillMax) {
            cvxEarned = amountTillMax;
        }
        return cvxEarned;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface IConvexHandler {
    function deposit(address _curvePool, uint256 _amount) external;

    function claimBatchEarnings(address[] memory _curvePools, address _rootPool) external;

    function getRewardPool(address _curvePool) external view returns (address);

    function getCrvEarned(address _account, address _curvePool) external view returns (uint256);

    function getCrvEarnedBatch(address _account, address[] memory _curvePools)
        external
        view
        returns (uint256);

    function computeClaimableConvex(uint256 crvAmount) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface ILpToken is IERC20Metadata {
    function mint(address account, uint256 amount) external returns (uint256);

    function burn(address _owner, uint256 _amount) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRewardStaking {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function stakeAll() external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim)
        external
        returns (bool);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface IBooster {
    function poolInfo(uint256 pid)
        external
        view
        returns (
            address lpToken,
            address token,
            address gauge,
            address crvRewards,
            address stash,
            bool shutdown
        );

    function poolLength() external view returns (uint256);

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function earmarkRewards(uint256 _pid) external returns (bool);

    function isShutdown() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IBaseRewardPool {
    function stakeFor(address, uint256) external;

    function stake(uint256) external;

    function stakeAll() external returns (bool);

    function withdraw(uint256 amount, bool claim) external returns (bool);

    function withdrawAndUnwrap(uint256 amount, bool claim) external returns (bool);

    function earned(address account) external view returns (uint256);

    function getReward() external;

    function getReward(address _account, bool _claimExtras) external;

    function extraRewardsLength() external view returns (uint256);

    function extraRewards(uint256 _pid) external view returns (address);

    function rewardToken() external view returns (address);

    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./vendor/IBooster.sol";
import "../libraries/CurvePoolUtils.sol";

interface ICurveRegistryCache {
    function BOOSTER() external view returns (IBooster);

    function initPool(address pool_) external;

    function initPool(address pool_, uint256 pid_) external;

    function lpToken(address pool_) external view returns (address);

    function assetType(address pool_) external view returns (CurvePoolUtils.AssetType);

    function isRegistered(address pool_) external view returns (bool);

    function hasCoinDirectly(address pool_, address coin_) external view returns (bool);

    function hasCoinAnywhere(address pool_, address coin_) external view returns (bool);

    function basePool(address pool_) external view returns (address);

    function coinIndex(address pool_, address coin_) external view returns (int128);

    function nCoins(address pool_) external view returns (uint256);

    function coinIndices(
        address pool_,
        address from_,
        address to_
    )
        external
        view
        returns (
            int128,
            int128,
            bool
        );

    function decimals(address pool_) external view returns (uint256[] memory);

    function interfaceVersion(address pool_) external view returns (uint256);

    function poolFromLpToken(address lpToken_) external view returns (address);

    function coins(address pool_) external view returns (address[] memory);

    function getPid(address _pool) external view returns (uint256);

    function getRewardPool(address _pool) external view returns (address);

    function isShutdownPid(uint256 pid_) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./pools/IRootPool.sol";
import "./IOracle.sol";
import "./tokenomics/IInflationManager.sol";
import "./tokenomics/ILpTokenStaker.sol";
import "./ICurveRegistryCache.sol";

interface IController {
    event PoolAdded(address indexed pool);
    event PoolRemoved(address indexed pool);
    event PoolShutdown(address indexed pool);
    event ConvexBoosterSet(address convexBooster);
    event CurveHandlerSet(address curveHandler);
    event ConvexHandlerSet(address convexHandler);
    event CurveRegistryCacheSet(address curveRegistryCache);
    event InflationManagerSet(address inflationManager);
    event PriceOracleSet(address priceOracle);
    event WeightUpdateMinDelaySet(uint256 weightUpdateMinDelay);

    struct WeightUpdate {
        address rootPoolAddress;
        IRootPool.PoolWeight[] weights;
    }

    // inflation manager

    function inflationManager() external view returns (IInflationManager);

    function setInflationManager(address manager) external;

    // views
    function curveRegistryCache() external view returns (ICurveRegistryCache);

    /// lp token staker
    function setLpTokenStaker(address _lpTokenStaker) external;

    function lpTokenStaker() external view returns (ILpTokenStaker);

    // oracle
    function priceOracle() external view returns (IOracle);

    function setPriceOracle(address oracle) external;

    // pool functions

    function listPools() external view returns (address[] memory);

    function listActivePools() external view returns (address[] memory);

    function isPool(address poolAddress) external view returns (bool);

    function isActivePool(address poolAddress) external view returns (bool);

    function addPool(address poolAddress) external;

    function shutdownPool(address poolAddress) external;

    function removePool(address poolAddress) external;

    function rootToken() external view returns (address);

    function lastWeightUpdate(address poolAddress) external view returns (uint256);

    function updateWeights(WeightUpdate memory update) external;

    function updateAllWeights(WeightUpdate[] memory weights) external;

    // handler functions

    function convexBooster() external view returns (address);

    function curveHandler() external view returns (address);

    function convexHandler() external view returns (address);

    function setConvexBooster(address _convexBooster) external;

    function setCurveHandler(address _curveHandler) external;

    function setConvexHandler(address _convexHandler) external;

    function setCurveRegistryCache(address curveRegistryCache_) external;

    function emergencyMinter() external view returns (address);

    function setWeightUpdateMinDelay(uint256 delay) external;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "../interfaces/vendor/ICurvePoolV2.sol";
import "../interfaces/vendor/ICurvePoolV1.sol";
import "./ScaledMath.sol";

library CurvePoolUtils {
    using ScaledMath for uint256;

    uint256 internal constant _DEFAULT_IMBALANCE_THRESHOLD = 0.02e18;

    enum AssetType {
        USD,
        ETH,
        BTC,
        OTHER,
        CRYPTO
    }

    struct PoolMeta {
        address pool;
        uint256 numberOfCoins;
        AssetType assetType;
        uint256[] decimals;
        uint256[] prices;
        uint256[] thresholds;
    }

    function ensurePoolBalanced(PoolMeta memory poolMeta) internal view {
        uint256 fromDecimals = poolMeta.decimals[0];
        uint256 fromBalance = 10**fromDecimals;
        uint256 fromPrice = poolMeta.prices[0];
        for (uint256 i = 1; i < poolMeta.numberOfCoins; i++) {
            uint256 toDecimals = poolMeta.decimals[i];
            uint256 toPrice = poolMeta.prices[i];
            uint256 toExpectedUnscaled = (fromBalance * fromPrice) / toPrice;
            uint256 toExpected = toExpectedUnscaled.convertScale(
                uint8(fromDecimals),
                uint8(toDecimals)
            );

            uint256 toActual;

            if (poolMeta.assetType == AssetType.CRYPTO) {
                // Handling crypto pools
                toActual = ICurvePoolV2(poolMeta.pool).get_dy(0, i, fromBalance);
            } else {
                // Handling other pools
                toActual = ICurvePoolV1(poolMeta.pool).get_dy(0, int128(uint128(i)), fromBalance);
            }

            require(
                _isWithinThreshold(toExpected, toActual, poolMeta.thresholds[i]),
                "pool is not balanced"
            );
        }
    }

    function _isWithinThreshold(
        uint256 a,
        uint256 b,
        uint256 imbalanceTreshold
    ) internal pure returns (bool) {
        if (imbalanceTreshold == 0) imbalanceTreshold = _DEFAULT_IMBALANCE_THRESHOLD;
        if (a > b) return (a - b).divDown(a) <= imbalanceTreshold;
        return (b - a).divDown(b) <= imbalanceTreshold;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

import "./ILpToken.sol";
import "./IRewardManager.sol";
import "../IOracle.sol";

interface IRootPool {
    event Deposit(
        address indexed sender,
        address indexed receiver,
        uint256 depositedAmount,
        uint256 lpReceived
    );
    event Withdraw(address indexed account, uint256 amount);
    event NewWeight(address indexed curvePool, uint256 newWeight);
    event NewMaxIdleCurveLpRatio(uint256 newRatio);
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);
    event HandledDepeggedCurvePool(address curvePool_);
    event HandledInvalidConvexPid(address curvePool_, uint256 pid_);
    event CurvePoolAdded(address curvePool_);
    event CurvePoolRemoved(address curvePool_);
    event Shutdown();
    event DepegThresholdUpdated(uint256 newThreshold);
    event MaxDeviationUpdated(uint256 newMaxDeviation);

    struct PoolWeight {
        address poolAddress;
        uint256 weight;
    }

    struct PoolWithAmount {
        address poolAddress;
        uint256 amount;
    }

    function underlying() external view returns (IERC20Metadata);

    function lpToken() external view returns (ILpToken);

    function rewardManager() external view returns (IRewardManager);

    function depositFor(
        address _account,
        uint256 _amount,
        uint256 _minLpReceived,
        bool stake
    ) external payable returns (uint256);

    function deposit(uint256 _amount, uint256 _minLpReceived) external payable returns (uint256);

    function deposit(
        uint256 _amount,
        uint256 _minLpReceived,
        bool stake
    ) external payable returns (uint256);

    function exchangeRate() external view returns (uint256);

    function usdExchangeRate() external view returns (uint256);

    function allCurvePools() external view returns (address[] memory);

    function curvePoolsCount() external view returns (uint256);

    function getCurvePoolAtIndex(uint256 _index) external view returns (address);

    function unstakeAndWithdraw(uint256 _amount, uint256 _minAmount) external returns (uint256);

    function withdraw(uint256 _amount, uint256 _minAmount) external returns (uint256);

    function updateWeights(PoolWeight[] memory poolWeights) external;

    function getWeight(address curvePool) external view returns (uint256);

    function getWeights() external view returns (PoolWeight[] memory);

    function getAllocatedUnderlying() external view returns (PoolWithAmount[] memory);

    function removeCurvePool(address pool) external;

    function addCurvePool(address pool) external;

    function totalCurveLpBalance(address curvePool_) external view returns (uint256);

    function rebalancingRewardActive() external view returns (bool);

    function totalDeviationAfterWeightUpdate() external view returns (uint256);

    function computeTotalDeviation() external view returns (uint256);

    /// @notice returns the total amount of funds held by this pool in terms of underlying
    function totalUnderlying() external view returns (uint256);

    function getTotalAndPerPoolUnderlying()
        external
        view
        returns (
            uint256 totalUnderlying_,
            uint256 totalAllocated_,
            uint256[] memory perPoolUnderlying_
        );

    /// @notice same as `totalUnderlying` but returns a cached version
    /// that might be slightly outdated if oracle prices have changed
    /// @dev this is useful in cases where we want to reduce gas usage and do
    /// not need a precise value
    function cachedTotalUnderlying() external view returns (uint256);

    function handleInvalidConvexPid(address pool) external;

    function shutdownPool() external;

    function isShutdown() external view returns (bool);

    function handleDepeggedCurvePool(address curvePool_) external;

    function isBalanced() external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface IOracle {
    event TokenUpdated(address indexed token, address feed, uint256 maxDelay, bool isEthPrice);

    /// @notice returns the price in USD of symbol.
    function getUSDPrice(address token) external view returns (uint256);

    /// @notice returns if the given token is supported for pricing.
    function isTokenSupported(address token) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface IInflationManager {
    event TokensClaimed(address indexed pool, uint256 rootAmount);
    event RebalancingRewardHandlerAdded(address indexed pool, address indexed handler);
    event RebalancingRewardHandlerRemoved(address indexed pool, address indexed handler);
    event PoolWeightsUpdated();

    function executeInflationRateUpdate() external;

    function updatePoolWeights() external;

    /// @notice returns the weights of the Root pools to know how much inflation
    /// each of them will receive, as well as the total amount of USD value in all the pools
    function computePoolWeights()
        external
        view
        returns (
            address[] memory _pools,
            uint256[] memory poolWeights,
            uint256 totalUSDValue
        );

    function computePoolWeight(address pool)
        external
        view
        returns (uint256 poolWeight, uint256 totalUSDValue);

    function currentInflationRate() external view returns (uint256);

    function getCurrentPoolInflationRate(address pool) external view returns (uint256);

    function handleRebalancingRewards(
        address account,
        uint256 deviationBefore,
        uint256 deviationAfter
    ) external;

    function addPoolRebalancingRewardHandler(address poolAddress, address rebalancingRewardHandler)
        external;

    function removePoolRebalancingRewardHandler(
        address poolAddress,
        address rebalancingRewardHandler
    ) external;

    function rebalancingRewardHandlers(address poolAddress)
        external
        view
        returns (address[] memory);

    function hasPoolRebalancingRewardHandlers(address poolAddress, address handler)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface ILpTokenStaker {
    event LpTokenStaked(address indexed account, uint256 amount);
    event LpTokenUnstaked(address indexed account, uint256 amount);
    event TokensClaimed(address indexed pool, uint256 rootAmount);
    event Shutdown();

    function stake(uint256 amount, address rootPool) external;

    function unstake(uint256 amount, address rootPool) external;

    function stakeFor(
        uint256 amount,
        address rootPool,
        address account
    ) external;

    function unstakeFor(
        uint256 amount,
        address rootPool,
        address account
    ) external;

    function unstakeFrom(uint256 amount, address account) external;

    function getUserBalanceForPool(address rootPool, address account)
        external
        view
        returns (uint256);

    function getBalanceForPool(address rootPool) external view returns (uint256);

    function updateBoost(address user) external;

    function claimROOTRewardsForPool(address pool) external;

    function claimableCnc(address pool) external view returns (uint256);

    function checkpoint(address pool) external returns (uint256);

    function shutdown() external;

    function getBoost(address user) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurvePoolV2 {
    function token() external view returns (address);

    function coins(uint256 i) external view returns (address);

    function factory() external view returns (address);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function exchange_underlying(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy,
        address receiver
    ) external returns (uint256);

    function add_liquidity(
        uint256[2] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[2] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function add_liquidity(
        uint256[3] memory amounts,
        uint256 min_mint_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function add_liquidity(uint256[3] memory amounts, uint256 min_mint_amount)
        external
        returns (uint256);

    function remove_liquidity(
        uint256 _amount,
        uint256[2] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[2] memory min_amounts)
        external;

    function remove_liquidity(
        uint256 _amount,
        uint256[3] memory min_amounts,
        bool use_eth,
        address receiver
    ) external;

    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts)
        external;

    function remove_liquidity_one_coin(
        uint256 token_amount,
        uint256 i,
        uint256 min_amount,
        bool use_eth,
        address receiver
    ) external returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[] memory amounts)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 token_amount, uint256 i)
        external
        view
        returns (uint256);

    function get_virtual_price() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

interface ICurvePoolV1 {
    function get_virtual_price() external view returns (uint256);

    function add_liquidity(uint256[8] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[7] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[6] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[5] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[4] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount) external;

    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external;

    function remove_liquidity_imbalance(uint256[4] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[3] calldata amounts, uint256 max_burn_amount)
        external;

    function remove_liquidity_imbalance(uint256[2] calldata amounts, uint256 max_burn_amount)
        external;

    function lp_token() external view returns (address);

    function A_PRECISION() external view returns (uint256);

    function A_precise() external view returns (uint256);

    function remove_liquidity(uint256 _amount, uint256[3] calldata min_amounts) external;

    function exchange(
        int128 from,
        int128 to,
        uint256 _from_amount,
        uint256 _min_to_amount
    ) external;

    function coins(uint256 i) external view returns (address);

    function balances(uint256 i) external view returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 _dx
    ) external view returns (uint256);

    function calc_token_amount(uint256[4] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_token_amount(uint256[2] calldata amounts, bool deposit)
        external
        view
        returns (uint256);

    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);

    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

library ScaledMath {
    uint256 internal constant DECIMALS = 18;
    uint256 internal constant ONE = 10**DECIMALS;

    function mulDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * b) / ONE;
    }

    function mulDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * b) / (10**decimals);
    }

    function divDown(uint256 a, uint256 b) internal pure returns (uint256) {
        return (a * ONE) / b;
    }

    function divDown(
        uint256 a,
        uint256 b,
        uint256 decimals
    ) internal pure returns (uint256) {
        return (a * 10**decimals) / b;
    }

    function divUp(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        return ((a * ONE) - 1) / b + 1;
    }

    function mulDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * b) / int256(ONE);
    }

    function mulDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * b) / uint128(ONE);
    }

    function mulDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * b) / int256(10**decimals);
    }

    function divDown(int256 a, int256 b) internal pure returns (int256) {
        return (a * int256(ONE)) / b;
    }

    function divDownUint128(uint128 a, uint128 b) internal pure returns (uint128) {
        return (a * uint128(ONE)) / b;
    }

    function divDown(
        int256 a,
        int256 b,
        uint256 decimals
    ) internal pure returns (int256) {
        return (a * int256(10**decimals)) / b;
    }

    function convertScale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function convertScale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        if (fromDecimals == toDecimals) return a;
        if (fromDecimals > toDecimals) return downscale(a, fromDecimals, toDecimals);
        return upscale(a, fromDecimals, toDecimals);
    }

    function upscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a * (10**(toDecimals - fromDecimals));
    }

    function downscale(
        uint256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (uint256) {
        return a / (10**(fromDecimals - toDecimals));
    }

    function upscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a * int256(10**(toDecimals - fromDecimals));
    }

    function downscale(
        int256 a,
        uint8 fromDecimals,
        uint8 toDecimals
    ) internal pure returns (int256) {
        return a / int256(10**(fromDecimals - toDecimals));
    }

    function intPow(uint256 a, uint256 n) internal pure returns (uint256) {
        uint256 result = ONE;
        for (uint256 i; i < n; ) {
            result = mulDown(result, a);
            unchecked {
                ++i;
            }
        }
        return result;
    }

    function absSub(uint256 a, uint256 b) internal pure returns (uint256) {
        unchecked {
            return a >= b ? a - b : b - a;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.20;

interface IRewardManager {
    event ClaimedRewards(uint256 claimedCrv, uint256 claimedCvx);
    event SoldRewardTokens(uint256 targetTokenReceived);
    event ExtraRewardAdded(address reward);
    event ExtraRewardRemoved(address reward);
    event ExtraRewardsCurvePoolSet(address extraReward, address curvePool);
    event FeesSet(uint256 feePercentage);
    event FeesEnabled(uint256 feePercentage);
    event EarningsClaimed(
        address indexed claimedBy,
        uint256 rootEarned,
        uint256 crvEarned,
        uint256 cvxEarned
    );

    struct RewardMeta {
        uint256 earnedIntegral;
        uint256 lastEarned;
        mapping(address => uint256) accountIntegral;
        mapping(address => uint256) accountShare;
    }

    function accountCheckpoint(address account) external;

    function poolCheckpoint() external returns (bool);

    function addExtraReward(address reward) external returns (bool);

    function addBatchExtraRewards(address[] memory rewards) external;

    function pool() external view returns (address);

    function setFeePercentage(uint256 _feePercentage) external;

    function claimableRewards(address account)
        external
        view
        returns (
            uint256 rootRewards,
            uint256 crvRewards,
            uint256 cvxRewards
        );

    function claimEarnings()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function claimPoolEarningsAndSellRewardTokens() external;
}