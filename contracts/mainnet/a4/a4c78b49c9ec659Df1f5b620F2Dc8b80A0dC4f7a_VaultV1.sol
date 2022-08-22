// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFeeRegistry {
	function totalFees() external view returns (uint256);

	function multisigPart() external view returns (uint256);

	function accumulatorPart() external view returns (uint256);

	function veSDTPart() external view returns (uint256);

	function maxFees() external view returns (uint256);

	function feeDenominator() external view returns (uint256);

	function multiSig() external view returns (address);

	function accumulator() external view returns (address);

	function veSDTFeeProxy() external view returns (address);

	function setOwner(address _address) external;

	function setFees(
		uint256 _multi,
		uint256 _accumulator,
		uint256 _veSDT
	) external;

	function setMultisig(address _multi) external;

	function setAccumulator(address _accumulator) external;

	function setVeSDTFeeProxy(address _feeProxy) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

interface ILiquidityGaugeStratFrax {
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

	function claim_rewards(address _addr, address _recipient) external;

	// solhint-disable-next-line
	function claim_rewards_for(address _user, address _recipient) external;

	// // solhint-disable-next-line
	// function claim_rewards_for(address _user) external;

	// solhint-disable-next-line
	function deposit(
		uint256 _value,
		address _addr,
		bool _claim_reward
	) external;

	// solhint-disable-next-line
	function reward_tokens(uint256 _i) external view returns (address);

	function reward_count() external view returns (uint256);

	function initialized() external view returns (bool);

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

	function commit_transfer_ownership(address) external;

	function initialize(
		address _admin,
		address _SDT,
		address _voting_escrow,
		address _veBoost_proxy,
		address _distributor,
		uint256 _pid,
		address _poolRegistry
	) external;

	function add_reward(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IProxyVault {
	enum VaultType {
		Erc20Baic,
		Other1,
		Other2
	}

	function initialize(
		address _owner,
		address _stakingAddress,
		address _stakingToken,
		address _rewardsAddress
	) external;

	function usingProxy() external returns (address);

	function rewards() external returns (address);

	function getReward() external;

	function getReward(bool _claim) external;

	function getReward(bool _claim, address[] calldata _rewardTokenList) external;

	function earned() external view returns (address[] memory token_addresses, uint256[] memory total_earned);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "../interfaces/ILiquidityGaugeStratFrax.sol";
import "../interfaces/IProxyVault.sol";
import "../interfaces/IFeeRegistry.sol";

interface IFraxFarmBase {
	function totalLiquidityLocked() external view returns (uint256);

	function lockedLiquidityOf(address account) external view returns (uint256);

	function toggleValidVeFXSProxy(address proxy_address) external;

	function proxyToggleStaker(address staker_address) external;

	function stakerSetVeFXSProxy(address proxy_address) external;

	function getReward(address destination_address) external returns (uint256[] memory);
}

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

		(bool success, ) = recipient.call{ value: amount }("");
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

		(bool success, bytes memory returndata) = target.call{ value: value }(data);
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

contract StakingProxyBase is IProxyVault {
	using SafeERC20 for IERC20;

	address public constant FXS = address(0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0);
	address public constant VE_FXS_PROXY = address(0xCd3a267DE09196C48bbB1d9e842D7D7645cE448f);
	address public constant FEE_REGISTRY = address(0x0f1dc3Bd5fE8a3034d6Df0A411Efc7916830d19c);

	address public owner; //owner of the vault
	address public stakingAddress; //LP staking contract address
	address public stakingToken; //LP token address
	address public override rewards; //stake dao reward liquidity gauge address
	address public override usingProxy; //address of Liquid Locker being used

	uint256 public constant FEE_DENOMINATOR = 10000;

	constructor() {}

	function vaultType() external pure virtual returns (VaultType) {
		return VaultType.Erc20Baic;
	}

	function vaultVersion() external pure virtual returns (uint256) {
		return 1;
	}

	modifier onlyOwner() {
		require(owner == msg.sender, "!auth");
		_;
	}

	modifier onlyAdmin() {
		require(VE_FXS_PROXY == msg.sender, "!auth_admin_here");
		_;
	}

	//initialize vault
	function initialize(
		address _owner,
		address _stakingAddress,
		address _stakingToken,
		address _rewardsAddress
	) external virtual override {}

	/// @notice help to change stake dao liquidity gauge address for reward
	/// @param _rewardsAddress address for new liquity gauge
	/// @dev need to be called by each user for each personal vault
	/// @dev when a pool change the Liquidity gauge reward address
	function changeRewards(address _rewardsAddress) external onlyOwner {
		require(ILiquidityGaugeStratFrax(rewards).initialized(), "pool not initialized yet");

		//remove from old rewards and claim
		uint256 bal = 0;
		if (ILiquidityGaugeStratFrax(rewards).initialized()) {
			bal = ILiquidityGaugeStratFrax(rewards).balanceOf(address(this));
			if (bal > 0) {
				ILiquidityGaugeStratFrax(rewards).withdraw(bal, owner, false);
			}
			ILiquidityGaugeStratFrax(rewards).claim_rewards(address(this), owner);
		}

		//set to new rewards
		rewards = _rewardsAddress;

		// deposit in new rewards
		if (bal > 0) {
			ILiquidityGaugeStratFrax(rewards).deposit(bal, owner, false);
		}

		//update balance
		_checkpointRewards();
	}

	/// @notice call internal _setVeFXSProxy function
	/// @param _proxy address of the proxy
	function setVeFXSProxy(address _proxy) external onlyAdmin {
		_setVeFXSProxy(_proxy);
	}

	/// @notice set proxy address on staking contract
	/// @param _proxyAddress proxy address
	function _setVeFXSProxy(address _proxyAddress) internal {
		IFraxFarmBase(stakingAddress).stakerSetVeFXSProxy(_proxyAddress);
		usingProxy = _proxyAddress;
	}

	function getReward() external virtual override {}

	function getReward(bool _claim) external virtual override {}

	function getReward(bool _claim, address[] calldata _rewardTokenList) external virtual override {}

	function earned()
		external
		view
		virtual
		override
		returns (address[] memory token_addresses, uint256[] memory total_earned)
	{}

	/// @notice internal function for checkpoint
	function _checkpointRewards() internal {
		//if rewards are active, checkpoint
		if (ILiquidityGaugeStratFrax(rewards).initialized()) {
			//using liquidity shares from staking contract will handle rebasing tokens correctly
			uint256 userLiq = IFraxFarmBase(stakingAddress).lockedLiquidityOf(address(this));
			//get current balance of reward contract
			uint256 bal = ILiquidityGaugeStratFrax(rewards).balanceOf(address(this));
			if (userLiq >= bal) {
				//add the difference to reward contract
				ILiquidityGaugeStratFrax(rewards).deposit(userLiq - bal, owner, false);
			} else {
				//remove the difference from the reward contract
				ILiquidityGaugeStratFrax(rewards).withdraw(bal - userLiq, owner, false);
			}
		}
	}

	/// @notice internal function to apply fees to fxs and send remaining to owner
	function _processFxs() internal {
		//get fee rate from booster
		uint256 multisigFee = IFeeRegistry(FEE_REGISTRY).multisigPart();
		uint256 accumulatorFee = IFeeRegistry(FEE_REGISTRY).accumulatorPart();
		uint256 veSDTFee = IFeeRegistry(FEE_REGISTRY).veSDTPart();
		
		//send fxs fees to fee deposit
		uint256 fxsBalance = IERC20(FXS).balanceOf(address(this));
		uint256 sendMulti = (fxsBalance * multisigFee) / FEE_DENOMINATOR;
		uint256 sendAccum = (fxsBalance * accumulatorFee) / FEE_DENOMINATOR;
		uint256 sendveSDT = (fxsBalance * veSDTFee) / FEE_DENOMINATOR;
		
		if (sendMulti > 0) {
			IERC20(FXS).transfer(IFeeRegistry(FEE_REGISTRY).multiSig(), sendMulti);
		}
		if (sendveSDT > 0) {
			IERC20(FXS).transfer(IFeeRegistry(FEE_REGISTRY).veSDTFeeProxy(), sendveSDT);
		}
		if (sendAccum > 0) {
			IERC20(FXS).transfer(IFeeRegistry(FEE_REGISTRY).accumulator(), sendAccum);
		}
		
		//transfer remaining fxs to owner
		uint256 sendAmount = IERC20(FXS).balanceOf(address(this));
		if (sendAmount > 0) {
			IERC20(FXS).transfer(owner, sendAmount);
		}
	}

	/// @notice internal function to get extra rewards from the liquidity gauge
	function _processExtraRewards() internal {
		if (ILiquidityGaugeStratFrax(rewards).initialized()) {
			//check if there is a balance because the reward contract could have be activated later
			//dont use _checkpointRewards since difference of 0 will still call deposit() and cost gas
			uint256 bal = ILiquidityGaugeStratFrax(rewards).balanceOf(address(this));
			uint256 userLiq = IFraxFarmBase(stakingAddress).lockedLiquidityOf(address(this));
			if (bal == 0 && userLiq > 0) {
				//bal == 0 and liq > 0 can only happen if rewards were turned on after staking
				ILiquidityGaugeStratFrax(rewards).deposit(userLiq, owner, false);
			}
			ILiquidityGaugeStratFrax(rewards).claim_rewards(address(this), owner);
		}
	}

	/// @notice internal function to transfer other reward tokens besides fxs(which needs to have fees applied)
	/// @param _tokens list of token to transfer addresses
	function _transferTokens(address[] memory _tokens) internal {
		//transfer all tokens
		for (uint256 i = 0; i < _tokens.length; i++) {
			if (_tokens[i] != FXS) {
				uint256 bal = IERC20(_tokens[i]).balanceOf(address(this));
				if (bal > 0) {
					IERC20(_tokens[i]).safeTransfer(owner, bal);
				}
			}
		}
	}
}

interface IFraxFarmERC20 {
	struct LockedStake {
		bytes32 kek_id;
		uint256 start_timestamp;
		uint256 liquidity;
		uint256 ending_timestamp;
		uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
	}

	function owner() external view returns (address);

	function stakingToken() external view returns (address);

	function fraxPerLPToken() external view returns (uint256);

	function calcCurCombinedWeight(address account)
		external
		view
		returns (
			uint256 old_combined_weight,
			uint256 new_vefxs_multiplier,
			uint256 new_combined_weight
		);

	function lockedStakesOf(address account) external view returns (LockedStake[] memory);

	function lockedStakesOfLength(address account) external view returns (uint256);

	function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

	function stakeLocked(uint256 liquidity, uint256 secs) external;

	function withdrawLocked(bytes32 kek_id, address destination_address) external;

	function periodFinish() external view returns (uint256);

	function getAllRewardTokens() external view returns (address[] memory);

	function earned(address account) external view returns (uint256[] memory new_earned);

	function totalLiquidityLocked() external view returns (uint256);

	function lockedLiquidityOf(address account) external view returns (uint256);

	function totalCombinedWeight() external view returns (uint256);

	function combinedWeightOf(address account) external view returns (uint256);

	function lockMultiplier(uint256 secs) external view returns (uint256);

	function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

	function userStakedFrax(address account) external view returns (uint256);

	function proxyStakedFrax(address proxy_address) external view returns (uint256);

	function maxLPForMaxBoost(address account) external view returns (uint256);

	function minVeFXSForMaxBoost(address account) external view returns (uint256);

	function minVeFXSForMaxBoostProxy(address proxy_address) external view returns (uint256);

	function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

	function toggleValidVeFXSProxy(address proxy_address) external;

	function proxyToggleStaker(address staker_address) external;

	function stakerSetVeFXSProxy(address proxy_address) external;

	function getReward(address destination_address) external returns (uint256[] memory);

	function vefxs_max_multiplier() external view returns (uint256);

	function vefxs_boost_scale_factor() external view returns (uint256);

	function vefxs_per_frax_for_max_boost() external view returns (uint256);

	function getProxyFor(address addr) external view returns (address);

	function sync() external;
}

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
	// Booleans are more expensive than uint256 or any type that takes up a full
	// word because each write operation emits an extra SLOAD to first read the
	// slot's contents, replace the bits taken up by the boolean, and then write
	// back. This is the compiler's defense against contract upgrades and
	// pointer aliasing, and it cannot be disabled.

	// The values being non-zero value makes deployment a bit more expensive,
	// but in exchange the refund on every call to nonReentrant will be lower in
	// amount. Since refunds are capped to a percentage of the total
	// transaction's gas, it is best to keep them low in cases like this one, to
	// increase the likelihood of the full refund coming into effect.
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}

	/**
	 * @dev Prevents a contract from calling itself, directly or indirectly.
	 * Calling a `nonReentrant` function from another `nonReentrant`
	 * function is not supported. It is possible to prevent this from happening
	 * by making the `nonReentrant` function external, and make it call a
	 * `private` function that does the actual work.
	 */
	modifier nonReentrant() {
		// On the first call to nonReentrant, _notEntered will be true
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		// Any calls to nonReentrant after this point will fail
		_status = _ENTERED;

		_;

		// By storing the original value once again, a refund is triggered (see
		// https://eips.ethereum.org/EIPS/eip-2200)
		_status = _NOT_ENTERED;
	}
}

pragma solidity ^0.8.7;

contract VaultV1 is StakingProxyBase, ReentrancyGuard {
	using SafeERC20 for IERC20;

	constructor() {}

	/// @notice return type of the vault
	function vaultType() external pure override returns (VaultType) {
		return VaultType.Erc20Baic;
	}

	/// @notice return version of the vault
	function vaultVersion() external pure override returns (uint256) {
		return 1;
	}

	/// @notice initialize the vault
	/// @param _owner owner of the vault
	/// @param _stakingAddress LP staking contract address
	/// @param _stakingToken LP token address
	/// @param _rewardsAddress stake dao reward liquidity gauge address
	function initialize(
		address _owner,
		address _stakingAddress,
		address _stakingToken,
		address _rewardsAddress
	) external override {
		require(owner == address(0), "already init");
		//set variables
		owner = _owner;
		stakingAddress = _stakingAddress;
		stakingToken = _stakingToken;
		rewards = _rewardsAddress;

		//set infinite approval
		IERC20(stakingToken).approve(_stakingAddress, type(uint256).max);
	}

	/// @notice create a new locked state of _secs timelength
	/// @param _liquidity amount to deposit
	/// @param _secs locking time in seconds
	function stakeLocked(uint256 _liquidity, uint256 _secs) external onlyOwner nonReentrant {
		if (_liquidity > 0) {
			//pull tokens from user
			IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _liquidity);

			//stake
			IFraxFarmERC20(stakingAddress).stakeLocked(_liquidity, _secs);
		}

		//checkpoint rewards
		_checkpointRewards();
	}

	/// @notice add to a current lock
	/// @param _kek_id id of deposit
	/// @param _add_liq amount to add to previous deposit
	function lockAdditional(bytes32 _kek_id, uint256 _add_liq) external onlyOwner nonReentrant {
		if (_add_liq > 0) {
			//pull tokens from user
			IERC20(stakingToken).safeTransferFrom(msg.sender, address(this), _add_liq);

			//add stake
			IFraxFarmERC20(stakingAddress).lockAdditional(_kek_id, _add_liq);
		}

		//checkpoint rewards
		_checkpointRewards();
	}

	/// @notice withdraw a staked position
	/// @param _kek_id id of deposit
	/// @param _claim bool for claim reward or not
	function withdrawLocked(bytes32 _kek_id, bool _claim) external onlyOwner nonReentrant {
		getReward(_claim);
		
		//withdraw directly to owner(msg.sender)
		IFraxFarmERC20(stakingAddress).withdrawLocked(_kek_id, msg.sender);

		//checkpoint rewards
		_checkpointRewards();
	}

	/// @notice helper function to combine earned tokens on staking contract and any tokens that are on this vault
	function earned() external view override returns (address[] memory _token_addresses, uint256[] memory _total_earned) {
		//get list of reward tokens

		address[] memory rewardTokens = IFraxFarmERC20(stakingAddress).getAllRewardTokens();
		uint256[] memory stakedearned = IFraxFarmERC20(stakingAddress).earned(address(this));

		uint256 extraRewardsLength = ILiquidityGaugeStratFrax(rewards).reward_count();

		_token_addresses = new address[](rewardTokens.length + extraRewardsLength);
		_total_earned = new uint256[](rewardTokens.length + extraRewardsLength);
		//add any tokens that happen to be already claimed but sitting on the vault
		//(ex. withdraw claiming rewards)
		for (uint256 i = 0; i < rewardTokens.length; i++) {
			_token_addresses[i] = rewardTokens[i];
			_total_earned[i] = stakedearned[i] + IERC20(rewardTokens[i]).balanceOf(address(this));
		}

		for (uint256 i = 0; i < extraRewardsLength; i++) {
			address token = ILiquidityGaugeStratFrax(rewards).reward_tokens(i);
			_token_addresses[i + rewardTokens.length] = token;
			_total_earned[i + rewardTokens.length] = ILiquidityGaugeStratFrax(rewards).claimable_reward(address(this), token);
		}
	}

	/*
    claim flow:
        claim rewards directly to the vault
        calculate fees to send to fee deposit
        send fxs to booster for fees
        get reward list of tokens that were received
        send all remaining tokens to owner

    A slightly less gas intensive approach could be to send rewards directly to booster and have it sort everything out.
    However that makes the logic a bit more complex as well as runs a few future proofing risks
    */

	/// @notice call getReward with true for claim
	function getReward() external override {
		getReward(true);
	}

	/// @notice get reward with claim option.
	/// @param _claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
	///there are tokens on this vault for cases such as withdraw() also calling claim.
	///can also be used to rescue tokens on the vault
	function getReward(bool _claim) public override {
		//claim
		if (_claim) {
			IFraxFarmERC20(stakingAddress).getReward(address(this));
		}
		
		//process fxs fees
		_processFxs();

		//get list of reward tokens
		address[] memory rewardTokens = IFraxFarmERC20(stakingAddress).getAllRewardTokens();
		//transfer
		_transferTokens(rewardTokens);

		//extra rewards
		_processExtraRewards();
	}

	/// @notice auxiliary function to supply token list(save a bit of gas + dont have to claim everything)
	/// @param _claim bool is for the off chance that rewardCollectionPause is true so getReward() fails but
	///there are tokens on this vault for cases such as withdraw() also calling claim.
	///can also be used to rescue tokens on the vault
	/// @param _rewardTokenList tokens list address
	function getReward(bool _claim, address[] calldata _rewardTokenList) external override {
		//claim
		if (_claim) {
			IFraxFarmERC20(stakingAddress).getReward(address(this));
		}

		//process fxs fees
		_processFxs();

		//transfer
		_transferTokens(_rewardTokenList);

		//extra rewards
		_processExtraRewards();
	}
}