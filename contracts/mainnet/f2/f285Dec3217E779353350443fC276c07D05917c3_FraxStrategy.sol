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
pragma solidity 0.8.7;

interface FeeDistro {
    function checkpoint() external;

    function getYield() external;

    function earned(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

/// @notice V1 Staking Interface
interface FraxStakingRewardsMultiGauge {
    // Locked liquidity for a given account
    function lockedLiquidityOf(address account) external view returns (uint256);

    // Total 'balance' used for calculating the percent of the pool the account owns
    // Takes into account the locked stake time multiplier
    function totalCombinedWeight() external view returns (uint256);

    // Total locked liquidity tokens
    function totalLiquidityLocked() external view returns (uint256);

    // Combined weight for a specific account
    function combinedWeightOf(address account) external view returns (uint256);

    function getReward() external returns (uint256[] memory);

    // Get the amount of FRAX 'inside' of the lp tokens
    function fraxPerLPToken() external view returns (uint256);

    function userStakedFrax(address account) external view returns (uint256);

    function minVeFXSForMaxBoost(address account) external view returns (uint256);

    function veFXSMultiplier(address account) external view returns (uint256);

    // Calculated the combined weight for an account
    function calcCurCombinedWeight(address account)
        external
        view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );

    // All the reward tokens
    function getAllRewardTokens() external view returns (address[] memory);

    // Multiplier amount, given the length of the lock
    function lockMultiplier(uint256 secs) external view returns (uint256);

    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    // Amount of reward tokens per LP token
    function rewardsPerToken() external view returns (uint256[] memory newRewardsPerTokenStored);

    function stakeLocked(uint256 liquidity, uint256 secs) external;

    function withdrawLocked(bytes32 kek_id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILocker {
	function createLock(uint256, uint256) external;

	function claimAllRewards(address[] calldata _tokens, address _recipient) external;

	function increaseAmount(uint256) external;

	function increaseUnlockTime(uint256) external;

	function release(address) external;

	function claimRewards(address,address) external;

	function claimFXSRewards(address) external;

	function execute(
		address,
		uint256,
		bytes calldata
	) external returns (bool, bytes memory);

	function setGovernance(address) external;

	function voteGaugeWeight(address, uint256) external;

	function setAngleDepositor(address) external;

	function setFxsDepositor(address) external;

	function setYieldDistributor(address) external;

	function setGaugeController(address) external;

	function setAccumulator(address _accumulator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @notice Locker Interface
interface LiquidityGauge {
    struct Reward {
        address token;
        address distributor;
        uint256 period_finish;
        uint256 rate;
        uint256 last_update;
        uint256 integral;
    }

    // solhint-disable-next-line
    function deposit_reward_token(address _rewardToken, uint256 _amount) external;

    // solhint-disable-next-line
    function claim_rewards_for(address _user, address _recipient) external;

    // // solhint-disable-next-line
    // function claim_rewards_for(address _user) external;

    // solhint-disable-next-line
    function deposit(uint256 _value, address _addr) external;

    // solhint-disable-next-line
    function reward_tokens(uint256 _i) external view returns (address);

    function withdraw(
        uint256 _value,
        address _addr,
        bool _claim_rewards
    ) external;

    // solhint-disable-next-line
    function reward_data(address _tokenReward) external view returns (Reward memory);

    function balanceOf(address) external returns (uint256);

    function claimable_reward(address _user, address _reward_token) external view returns (uint256);

    function user_checkpoint(address _user) external returns (bool);

    function initialized() external view returns (bool);

    function commit_transfer_ownership(address) external;

    function initialize(
        address _staking_token,
        address _admin,
        address _SDT,
        address _voting_escrow,
        address _veBoost_proxy,
        address _distributor,
        address _vault,
        address _sdt_distributor,
        string memory _symbol
    ) external;

    function reward_count() external view returns (uint256);

    function admin() external view returns (address);

    function add_reward(address rewardToken, address distributor) external;

    function set_claimer(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface SdtDistributorV2 {
    function distribute(address _gauge) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

import "contracts/interfaces/ILocker.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

////////////////////////////////////////////////////////////////
/// ---  ERRORS
///////////////////////////////////////////////////////////////

error DepositFailed();

error NotImplemented();

error WithdrawalFailed();

error WrongAmountDeposited();

error WithdrawalTransferFailed();

error TransferFromLockerFailed();

/// @notice  BaseStrategyV2 contract.
/// @dev     For new strategies only, upgrade can override storage vars.
contract BaseStrategyV2 {
    ////////////////////////////////////////////////////////////////
    /// --- STRUCTS & ENUMS
    ///////////////////////////////////////////////////////////////

    struct ClaimerReward {
        address rewardToken;
        uint256 amount;
    }

    enum MANAGEFEE {
        PERFFEE,
        VESDTFEE,
        ACCUMULATORFEE,
        CLAIMERREWARD
    }

    ////////////////////////////////////////////////////////////////
    /// --- IMMUTABLES & CONSTANTS
    ///////////////////////////////////////////////////////////////

    ILocker public immutable LOCKER;

    uint256 public constant BASE_FEE = 10_000;

    ////////////////////////////////////////////////////////////////
    /// --- STORAGE VARIABLES
    ///////////////////////////////////////////////////////////////

    address public governance;
    address public accumulator;

    address public sdtDistributor;
    address public rewardsReceiver;

    address public veSDTFeeProxy;
    address public vaultGaugeFactory;

    mapping(address => bool) public vaults;
    mapping(address => address) public gauges;
    mapping(address => uint256) public perfFee;
    mapping(address => uint256) public veSDTFee; // gauge -> fee
    mapping(address => address) public multiGauges;
    mapping(address => uint256) public accumulatorFee; // gauge -> fee
    mapping(address => uint256) public claimerRewardFee; // gauge -> fee

    ////////////////////////////////////////////////////////////////
    /// --- EVENTS
    ///////////////////////////////////////////////////////////////

    event GaugeSet(address _gauge, address _token);
    event VaultToggled(address _vault, bool _newState);

    event RewardReceiverSet(address _gauge, address _receiver);
    event Claimed(address _gauge, address _token, uint256 _amount);

    event Deposited(address _gauge, address _token, uint256 _amount);
    event Withdrawn(address _gauge, address _token, uint256 _amount);

    ////////////////////////////////////////////////////////////////
    /// --- MODIFIERS
    ///////////////////////////////////////////////////////////////

    modifier onlyGovernance() {
        require(msg.sender == governance, "!governance");
        _;
    }
    modifier onlyApprovedVault() {
        require(vaults[msg.sender], "!approved vault");
        _;
    }
    modifier onlyGovernanceOrFactory() {
        require(msg.sender == governance || msg.sender == vaultGaugeFactory, "!governance && !factory");
        _;
    }

    constructor(
        ILocker _locker,
        address _governance,
        address _accumulator,
        address _veSDTFeeProxy,
        address _sdtDistributor,
        address _receiver
    ) {
        LOCKER = _locker;

        governance = _governance;
        accumulator = _accumulator;

        veSDTFeeProxy = _veSDTFeeProxy;
        sdtDistributor = _sdtDistributor;

        rewardsReceiver = _receiver;
    }

    /// @notice function to set new fees
    /// @param _manageFee manageFee
    /// @param _gauge gauge address
    /// @param _newFee new fee to set
    function manageFee(
        MANAGEFEE _manageFee,
        address _gauge,
        uint256 _newFee
    ) external onlyGovernanceOrFactory {
        require(_gauge != address(0), "zero address");
        if (_manageFee == MANAGEFEE.PERFFEE) {
            // 0
            perfFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.VESDTFEE) {
            // 1
            veSDTFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.ACCUMULATORFEE) {
            //2
            accumulatorFee[_gauge] = _newFee;
        } else if (_manageFee == MANAGEFEE.CLAIMERREWARD) {
            // 3
            claimerRewardFee[_gauge] = _newFee;
        }
        require(
            perfFee[_gauge] + veSDTFee[_gauge] + accumulatorFee[_gauge] + claimerRewardFee[_gauge] <= BASE_FEE,
            "fee to high"
        );
    }

	/// @notice function to set accumulator
	/// @param _accumulator gauge address
	function setAccumulator(address _accumulator) external onlyGovernance {
        require(_accumulator != address(0), "zero address");
		accumulator = _accumulator;
	}

	/// @notice function to set veSDTFeeProxy
	/// @param _veSDTProxy veSDTProxy address
	function setVeSDTProxy(address _veSDTProxy) external onlyGovernance {
        require(_veSDTProxy != address(0), "zero address");
		veSDTFeeProxy = _veSDTProxy;
	}

    /// @notice function to set reward receiver
	/// @param _newRewardsReceiver reward receiver address
	function setRewardsReceiver(address _newRewardsReceiver) external onlyGovernance {
        require(_newRewardsReceiver != address(0), "zero address");
		rewardsReceiver = _newRewardsReceiver;
	}

    /// @notice function to set governance
	/// @param _newGovernance governance address
	function setGovernance(address _newGovernance) external onlyGovernance {
        require(_newGovernance != address(0), "zero address");
		governance = _newGovernance;
	}

    /// @notice function to set sdt didtributor
	/// @param _newSdtDistributor sdt distributor address 
	function setSdtDistributor(address _newSdtDistributor) external onlyGovernance {
        require(_newSdtDistributor != address(0), "zero address");
		sdtDistributor = _newSdtDistributor;
	}

    /// @notice function to set vault gauge factory
	/// @param _newVaultGaugeFactory vault gauge factory address 
	function setVaultGaugeFactory(address _newVaultGaugeFactory) external onlyGovernance {
		require(_newVaultGaugeFactory != address(0), "zero address");
		vaultGaugeFactory = _newVaultGaugeFactory;
	}

    ////////////////////////////////////////////////////////////////
    /// --- VIRTUAL FUNCTIONS
    ///////////////////////////////////////////////////////////////

    function deposit(address _token, uint256 _amount) external virtual onlyApprovedVault {}

    function deposit(
        address _token,
        uint256 _amount,
        uint256 _secs
    ) external virtual onlyApprovedVault {}

    function withdraw(address _token, uint256 _amount) external virtual onlyApprovedVault {}

    function withdraw(address _token, bytes32 kek_id) external virtual onlyApprovedVault {}

    function claim(address _gauge) external virtual {}

    function toggleVault(address _vault) external virtual onlyGovernanceOrFactory {}

    function setGauge(address _token, address _gauge) external virtual onlyGovernanceOrFactory {}

    function setMultiGauge(address _gauge, address _multiGauge) external virtual onlyGovernanceOrFactory {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "contracts/strategy/BaseStrategyV2.sol";
import "contracts/interfaces/FeeDistro.sol";
import "contracts/interfaces/FraxStaking.sol";
import "contracts/interfaces/LiquidityGauge.sol";
import "contracts/interfaces/SdtDistributorV2.sol";

/// @notice Frax Staking Handler.
///         Handle Staking and Withdraw to Frax Gauges through the Locker.
/// @author Stake Dao
contract FraxStrategy is BaseStrategyV2 {
	using SafeERC20 for IERC20;

	constructor(
		ILocker locker,
		address governance,
		address accumulator,
		address veSDTFeeProxy,
		address sdtDistributor,
		address receiver
	) BaseStrategyV2(locker, governance, accumulator, veSDTFeeProxy, sdtDistributor, receiver) {}

	/* ========== MUTATIVE FUNCTIONS ========== */
	/// @notice function to deposit into a gauge
	/// @param _token token address
	/// @param _amount amount to deposit
	/// @param _secs locking time in seconds
	function deposit(
		address _token,
		uint256 _amount,
		uint256 _secs
	) external override onlyApprovedVault {
		require(gauges[_token] != address(0), "!gauge");
		address gauge = gauges[_token];

		IERC20(_token).transferFrom(msg.sender, address(LOCKER), _amount);

		// Approve gauge through Locker.
		LOCKER.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, 0));
		LOCKER.execute(_token, 0, abi.encodeWithSignature("approve(address,uint256)", gauge, _amount));

		// Deposit through Locker.
		(bool success, ) = LOCKER.execute(
			gauge, // to
			0, // value
			abi.encodePacked(FraxStakingRewardsMultiGauge.stakeLocked.selector, _amount, _secs) // data
		);

		if (!success) {
			revert DepositFailed();
		}

		emit Deposited(gauge, _token, _amount);
	}

	// Withdrawing implies to get claim rewards also.
	/// @notice function to withdraw from a gauge
	/// @param _token token address
	/// @param _kek_id deposit id to withdraw
	function withdraw(address _token, bytes32 _kek_id) external override onlyApprovedVault {
		require(gauges[_token] != address(0), "!gauge");
		address gauge = gauges[_token];

		uint256 before = IERC20(_token).balanceOf(address(LOCKER));

		(bool success, ) = LOCKER.execute(
			gauge,
			0,
			abi.encodePacked(FraxStakingRewardsMultiGauge.withdrawLocked.selector, _kek_id)
		);

		if (!success) {
			revert WithdrawalFailed();
		}

		uint256 _after = IERC20(_token).balanceOf(address(LOCKER));
		uint256 net = _after - before;

		_transferFromLocker(_token, msg.sender, net);
		_distributeRewards(gauge);

		emit Withdrawn(gauge, _token, net);
	}

	/// @notice function to claim the reward and distribute it
	/// @param _token token address
	function claim(address _token) external override {
		address gauge = gauges[_token];
		require(gauge != address(0), "!gauge");

		(bool success, ) = LOCKER.execute(gauge, 0, abi.encode(FraxStakingRewardsMultiGauge.getReward.selector));
		require(success, "Claim failed!");

		_distributeRewards(gauge);
	}

	/// @notice internal function used for distributing rewards
	/// @param _gauge gauge address
	function _distributeRewards(address _gauge) internal {
		address[] memory rewardsToken = FraxStakingRewardsMultiGauge(_gauge).getAllRewardTokens();
		uint256 lenght = rewardsToken.length;

		SdtDistributorV2(sdtDistributor).distribute(multiGauges[_gauge]);

		for (uint256 i; i < lenght; ) {
			address rewardToken = rewardsToken[i];
			if (rewardToken == address(0)) {
				continue;
			}

			uint256 rewardBalance = IERC20(rewardToken).balanceOf(address(LOCKER));
			uint256 netBalance = _distributeFees(_gauge, rewardToken, rewardBalance);

			// Distribute net rewards to gauge.
			IERC20(rewardToken).approve(multiGauges[_gauge], netBalance);
			LiquidityGauge(multiGauges[_gauge]).deposit_reward_token(rewardToken, netBalance);

			emit Claimed(_gauge, rewardToken, rewardBalance);

			unchecked {
				++i;
			}
		}
	}

	/// @notice internal function used for distributing fees
	/// @param _gauge gauge address
	/// @param _rewardToken reward token address
	/// @param _rewardBalance amount of reward
	function _distributeFees(
		address _gauge,
		address _rewardToken,
		uint256 _rewardBalance
	) internal returns (uint256 netRewards) {
		uint256 multisigFee = (_rewardBalance * perfFee[_gauge]) / BASE_FEE;
		uint256 accumulatorPart = (_rewardBalance * accumulatorFee[_gauge]) / BASE_FEE;
		uint256 veSDTPart = (_rewardBalance * veSDTFee[_gauge]) / BASE_FEE;
		uint256 claimerPart = (_rewardBalance * claimerRewardFee[_gauge]) / BASE_FEE;

		// Distribute fees.
		_transferFromLocker(_rewardToken, msg.sender, claimerPart);
		_transferFromLocker(_rewardToken, veSDTFeeProxy, veSDTPart);
		_transferFromLocker(_rewardToken, accumulator, accumulatorPart);
		_transferFromLocker(_rewardToken, rewardsReceiver, multisigFee);

		// Update rewardAmount.
		netRewards = IERC20(_rewardToken).balanceOf(address(LOCKER));
		_transferFromLocker(_rewardToken, address(this), netRewards);
	}

	/// @notice internal function used for transfering token from locker
	/// @param _token token address
	/// @param _recipient receipient address
	/// @param _amount amount to transfert
	function _transferFromLocker(
		address _token,
		address _recipient,
		uint256 _amount
	) internal {
		(bool success, ) = LOCKER.execute(
			_token,
			0,
			abi.encodeWithSignature("transfer(address,uint256)", _recipient, _amount)
		);
		if (!success) {
			revert TransferFromLockerFailed();
		}
	}

	/// @notice only callable by approvedVault, used for allow delegating veFXS boost to a vault
	/// @param _to Address to sent the value to
	/// @param _data Call function data
	function proxyCall(address _to, bytes memory _data) external onlyApprovedVault {
		(bool success, ) = LOCKER.execute(_to, uint256(0), _data);
		require(success, "Proxy Call Fail");
	}

	// BaseStrategy Function
	/// @notice not implemented
	function deposit(address, uint256) external view override onlyApprovedVault {
		revert NotImplemented();
	}

	// BaseStrategy Function
	/// @notice not implemented
	function withdraw(address, uint256) external view override onlyApprovedVault {
		revert NotImplemented();
	}

	/// @notice function to toggle a vault
	/// @param _vault vault address
	function toggleVault(address _vault) external override onlyGovernanceOrFactory {
		require(_vault != address(0), "zero address");
		vaults[_vault] = !vaults[_vault];
		emit VaultToggled(_vault, vaults[_vault]);
	}

	/// @notice function to set a new gauge
	/// It permits to set it as  address(0), for disabling it
	/// in case of migration
	/// @param _token token address
	/// @param _gauge gauge address
	function setGauge(address _token, address _gauge) external override onlyGovernanceOrFactory {
		require(_token != address(0), "zero address");
		// Set new gauge
		gauges[_token] = _gauge;
		emit GaugeSet(_gauge, _token);
	}

	/// @notice function to set a multi gauge
	/// @param _gauge gauge address
	/// @param _multiGauge multi gauge address
	function setMultiGauge(address _gauge, address _multiGauge) external override onlyGovernanceOrFactory {
		multiGauges[_gauge] = _multiGauge;
	}

	/// @notice execute a function
	/// @param to Address to sent the value to
	/// @param value Value to be sent
	/// @param data Call function data
	function execute(
		address to,
		uint256 value,
		bytes calldata data
	) external onlyGovernance returns (bool, bytes memory) {
		(bool success, bytes memory result) = to.call{ value: value }(data);
		return (success, result);
	}
}