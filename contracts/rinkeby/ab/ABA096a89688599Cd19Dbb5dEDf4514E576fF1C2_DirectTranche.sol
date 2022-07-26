pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/DirectTranche.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./BaseTranche.sol";

/**
  * @notice A pass through tranche to the underlying gauge
  * @dev Use where STAX wants a direct position on the gauge, and will always use
  * it's own veFXS
  */
contract DirectTranche is BaseTranche {
    using SafeERC20 for IERC20;

    /// @notice The underlying gauge and staking token, set at construction 
    /// @dev New cloned instances use these fixed addresses.
    // immutable such that it persists in the bytecode of the template.
    address public immutable _underlyingGaugeAddress;
    address public immutable _stakingTokenAddress;

    constructor(address _underlyingGauge, address _stakingToken) {
        _underlyingGaugeAddress = _underlyingGauge;
        _stakingTokenAddress = _stakingToken;
    }

    function trancheType() external pure returns (TrancheType) {
        return TrancheType.Direct;
    }

    function trancheVersion() external pure returns (uint256) {
        return 1;
    }

    function _initialize() internal override {
        underlyingGauge = IFraxGauge(_underlyingGaugeAddress);
        stakingToken = IERC20(_stakingTokenAddress);

        // Set allowance to max on initialization, rather than
        // one-by-one later.
        stakingToken.safeIncreaseAllowance(address(underlyingGauge), type(uint256).max);
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal override returns (bytes32) {
        underlyingGauge.stakeLocked(liquidity, secs);

        // Need to access the underlying gauge to get the new lock info, it's not returned by the stakeLocked function.
        IFraxGauge.LockedStake[] memory _lockedStakes = underlyingGauge.lockedStakesOf(address(this));
        uint256 lockedStakesLength = _lockedStakes.length;
        return _lockedStakes[lockedStakesLength-1].kek_id;
    }

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal override {
        underlyingGauge.lockAdditional(kek_id, addl_liq);
        emit AdditionalLocked(address(this), kek_id, addl_liq);
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal override returns (uint256 withdrawnAmount) {      
        uint256 stakingTokensBefore = stakingToken.balanceOf(destination_address);
        underlyingGauge.withdrawLocked(kek_id, destination_address);
        uint256 stakingTokensAfter = stakingToken.balanceOf(destination_address);
        withdrawnAmount = stakingTokensAfter - stakingTokensBefore;
    }

    function lockedStakes() external view override returns (IFraxGauge.LockedStake[] memory) {
        return underlyingGauge.lockedStakesOf(address(this));
    }

    function getRewards(address[] calldata /*rewardTokens*/) external override returns (uint256[] memory rewardAmounts) {
        // The requested rewardToken addresses aren't used when pulling rewards from the gauge, as we can
        // send directly to the requested destination (rather than pulling here and then having to send to dest in a second step)
        rewardAmounts = underlyingGauge.getReward(owner());
        emit RewardClaimed(address(this), rewardAmounts);
    }

    function setVeFXSProxy(address _proxy) external override onlyOwner {
        underlyingGauge.stakerSetVeFXSProxy(_proxy);
        emit VeFXSProxySet(_proxy);
    }

    function toggleMigrator(address migrator_address) external override onlyOwner {
        underlyingGauge.stakerToggleMigrator(migrator_address);
        emit MigratorToggled(migrator_address);
    }

    function getAllRewardTokens() external view returns (address[] memory) {
        return underlyingGauge.getAllRewardTokens();
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (investments/frax-gauge/tranche/BaseTranche.sol)

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "../../../interfaces/investments/frax-gauge/tranche/ITranche.sol";
import "../../../interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol";

import "../../../common/CommonEventsAndErrors.sol";
import "../../../common/Executable.sol";

/**
  * @notice The abstract base contract for all tranche implementations
  * 
  * Owner of each tranche: LiquidityOps
  */
abstract contract BaseTranche is ITranche, Ownable {
    using SafeERC20 for IERC20;

    /// @notice Whether this tranche has been initialized yet or not.
    /// @dev A tranche can only be initialized once
    /// factory template deployments are pushed manually, and should then be disabled
    /// (such that they can't be initialized)
    bool public initialized;
    
    /// @notice The registry used to create/initialize this instance.
    /// @dev Tranche implementations have access to call some methods of the registry
    ///      which created it.
    ITrancheRegistry public registry;

    /// @notice The underlying frax gauge that this tranche is staking into.
    IFraxGauge public underlyingGauge;

    /// @notice The token which is being staked.
    IERC20 public stakingToken;

    /// @notice The total amount of stakingToken locked in this tranche.
    ///         This includes not yet withdrawn tokens in expired locks
    ///         Withdrawn tokens decrement this total.
    uint256 internal _totalLocked;

    /// @notice If this tranche is disabled, it cannot be used for new tranche instances
    ///         and new desposits can not be taken.
    ///         Withdrawals of expired locks can still take place.
    bool private _disabled;

    /// @notice The implementation used to clone this instance
    uint256 public fromImplId;

    error OnlyOwnerOrRegistry(address caller);

    /// @notice Initialize the newly cloned instance.
    /// @dev When deploying new template implementations, setDisabled() should be called on
    ///      them such that they can't be initialized by others.
    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external override returns (address, address) {
        if (initialized) revert AlreadyInitialized();
        if (_disabled) revert InactiveTranche(address(this));

        registry = ITrancheRegistry(_registry);                
        fromImplId = _fromImplId;
        _transferOwnership(_newOwner);

        initialized = true;

        _initialize();

        return (address(underlyingGauge), address(stakingToken));
    }

    /// @notice Derived classes to implement any custom initialization
    function _initialize() internal virtual;

    /// @notice Whether or not this tranche implementation is disabled for future use.
    function disabled() external view override returns (bool) {
        return _disabled;
    }

    /// @notice The total amount of LP locked in this tranche.
    function totalLocked() external view returns (uint256) {
        return _totalLocked;
    }

    /// @dev The old registry or the owner can re-point to a new registry, in case of registry upgrade.
    function setRegistry(address _registry) external override onlyOwnerOrRegistry {
        registry = ITrancheRegistry(_registry);
        emit RegistrySet(_registry);
    }

    /// @notice The registry or the owner can disable this tranche instance
    function setDisabled(bool isDisabled) external override onlyOwnerOrRegistry {
        _disabled = isDisabled;
        emit SetDisabled(isDisabled);
    }

    /// @notice Lock LP in the underlying gauge/vault, for a given duration
    function stakeLocked(uint256 liquidity, uint256 secs) external override onlyOwner isOpenForStaking(liquidity) returns (bytes32) {
        _totalLocked += liquidity;
        return _stakeLocked(liquidity, secs);
    }

    function _stakeLocked(uint256 liquidity, uint256 secs) internal virtual returns (bytes32);

    /// @notice Lock additional LP in the underlying gauge/vault, to an existing lock
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external override onlyOwner isOpenForStaking(addl_liq) {
        _totalLocked += addl_liq;
        _lockAdditional(kek_id, addl_liq);
    }

    function _lockAdditional(bytes32 kek_id, uint256 addl_liq) internal virtual;

    /// @notice Withdraw LP from expired locks
    function withdrawLocked(bytes32 kek_id, address destination_address) external override onlyOwner returns (uint256 withdrawnAmount) {      
        withdrawnAmount = _withdrawLocked(kek_id, destination_address);
        _totalLocked -= withdrawnAmount;
    }

    function _withdrawLocked(bytes32 kek_id, address destination_address) internal virtual returns (uint256 withdrawnAmount);

    /// @notice Owner can recoer tokens
    function recoverToken(address _token, address _to, uint256 _amount) external onlyOwner {
        IERC20(_token).safeTransfer(_to, _amount);
        emit CommonEventsAndErrors.TokenTransferred(address(this), _to, address(_token), _amount);
    }

    /// @notice Execute is provided for the owner (LiquidityOps), in case there are future operations on the underlying gauge/vault
    /// which need to be called.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bytes memory) {
        return Executable.execute(_to, _value, _data);
    }

    /// @notice Is this tranche active and the total locked is less than maxTrancheSize
    function willAcceptLock(uint256 maxTrancheSize) external view override returns (bool) {
        return (
            !_disabled &&
            _totalLocked < maxTrancheSize
        );
    }

    /// @notice Does this tranche have sufficient LP in it, and it's active/open for staking
    modifier isOpenForStaking(uint256 _liquidity) {
        if (_disabled || !initialized) revert InactiveTranche(address(this));

        // Check this tranche has enough liquidity
        uint256 balance = stakingToken.balanceOf(address(this));
        if (balance < _liquidity) revert CommonEventsAndErrors.InsufficientTokens(address(stakingToken), _liquidity, balance);

        // Also check that this tranche implementation is still open for staking
        // Worth the gas to have the kill switch on the implementation id.
        // Any automation (eg keeper) will simulate first, so gas shouldn't be wasted on revert.
        if (registry.implDetails(fromImplId).closedForStaking) revert ITrancheRegistry.InvalidTrancheImpl(fromImplId);

        _;
    }

    modifier onlyOwnerOrRegistry() {
        if (msg.sender != owner() && msg.sender != address(registry)) revert OnlyOwnerOrRegistry(msg.sender);
        _;
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITranche.sol)

import "../../../external/frax/IFraxGauge.sol";

interface ITranche {
    enum TrancheType {
        Direct,
        ConvexVault
    }

    event RegistrySet(address indexed registry);
    event SetDisabled(bool isDisabled);
    event RewardClaimed(address indexed trancheAddress, uint256[] rewardData);
    event AdditionalLocked(address indexed staker, bytes32 kekId, uint256 liquidity);
    event VeFXSProxySet(address indexed proxy);
    event MigratorToggled(address indexed migrator);

    error InactiveTranche(address tranche);
    error AlreadyInitialized();
    
    function disabled() external view returns (bool);
    function willAcceptLock(uint256 liquidity) external view returns (bool);
    function lockedStakes() external view returns (IFraxGauge.LockedStake[] memory);

    function initialize(address _registry, uint256 _fromImplId, address _newOwner) external returns (address, address);
    function setRegistry(address _registry) external;
    function setDisabled(bool isDisabled) external;
    function setVeFXSProxy(address _proxy) external;
    function toggleMigrator(address migrator_address) external;

    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32 kek_id);
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256 withdrawnAmount);
    function getRewards(address[] calldata rewardTokens) external returns (uint256[] memory rewardAmounts);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/investments/frax-gauge/tranche/ITrancheRegistry.sol)

interface ITrancheRegistry {
    struct ImplementationDetails {
        // The reference tranche implementation which is to be cloned
        address implementation;

        // If true, new/additional locks cannot be added into this tranche type
        bool closedForStaking;

        // If true, no staking allowed and these tranches have no rewards
        // to claim or tokens to withdraw. So fully deprecated.
        bool disabled;
    }

    event TrancheCreated(uint256 indexed implId, address indexed tranche, address stakingAddress, address stakingToken);
    event TrancheImplCreated(uint256 indexed implId, address indexed implementation);
    event ImplementationDisabled(uint256 indexed implId, bool value);
    event ImplementationClosedForStaking(uint256 indexed implId, bool value);
    event AddedExistingTranche(uint256 indexed implId, address indexed tranche);

    error OnlyOwnerOperatorTranche(address caller);
    error InvalidTrancheImpl(uint256 implId);
    error TrancheAlreadyExists(address tranche);
    error UnknownTranche(address tranche);

    function createTranche(uint256 _implId) external returns (address tranche, address underlyingGaugeAddress, address stakingToken);
    function implDetails(uint256 _implId) external view returns (ImplementationDetails memory details);
    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bytes memory);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/CommonEventsAndErrors.sol)

/// @notice A collection of common errors thrown within the STAX contracts
library CommonEventsAndErrors {
    event TokenTransferred(address indexed from, address indexed to, address indexed token, uint256 amount);

    error InsufficientTokens(address token, uint256 required, uint256 balance);
    error InvalidToken(address token);
    error InvalidParam();
    error InvalidAddress(address addr);
    error OnlyOwner(address caller);
    error OnlyOwnerOrOperators(address caller);
}

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (common/Executable.sol)

/// @notice An inlined library function to add a generic execute() function to contracts.
/// @dev As this is a powerful funciton, care and consideration needs to be taken when 
///      adding into contracts, and on who can call.
library Executable {
    error UnknownFailure();

    /// @notice Call a function on another contract, where the msg.sender will be this contract
    /// @param _to The address of the contract to call
    /// @param _value Any eth to send
    /// @param _data The encoded function selector and args.
    /// @dev If the underlying function reverts, this willl revert where the underlying revert message will bubble up.
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = _to.call{value: _value}(_data);
        
        if (success) {
            return returndata;
        } else if (returndata.length > 0) {
            // Look for revert reason and bubble it up if present
            // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L232
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert UnknownFailure();
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

pragma solidity ^0.8.4;
// SPDX-License-Identifier: GPL-3.0-or-later
// STAX (interfaces/external/curve/IFraxGauge.sol)

// ref: https://github.com/FraxFinance/frax-solidity/blob/master/src/hardhat/contracts/Staking/FraxUnifiedFarm_ERC20.sol

interface IFraxGauge {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external;

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
    function getAllRewardTokens() external view returns (address[] memory);
    function getReward(address destination_address) external returns (uint256[] memory);

    function stakerSetVeFXSProxy(address proxy_address) external;
    function stakerToggleMigrator(address migrator_address) external;

    function lock_time_min() external view returns (uint256);
    function lock_time_for_max_multiplier() external view returns (uint256);
}