// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.7;

interface IDepositor {
	function deposit(uint256 amount, bool lock, bool stake, address user) external;
	function minter() external returns(address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

interface ILiquidityGauge {

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
    function reward_tokens(uint256 _i) external view returns(address);

    // solhint-disable-next-line
    function reward_data(address _tokenReward) external view returns(Reward memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVeSDT {
	struct LockedBalance {
		int128 amount;
		uint256 end;
	}

	function create_lock(uint256 _value, uint256 _unlock_time) external;

	function increase_amount(uint256 _value) external;

	function increase_unlock_time(uint256 _unlock_time) external;

	function withdraw() external;

	function deposit_for(address, uint256) external;

	function locked(address) external returns(LockedBalance memory);

	function balanceOf(address) external returns(uint256); 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/IDepositor.sol";
import "../interfaces/IVeSDT.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// Claim rewards contract:
// 1) Users can claim rewards from pps gauge and directly receive all tokens collected.
// 2) Users can choose to direcly lock tokens supported by lockers (FXS, ANGLE) and receive the others not supported.
// 3) Users can choose to direcly lock tokens supported by lockers (FXS, ANGLE) and stake sdToken into the gauge, then receives the others not supported.
contract ClaimRewards {
	// using SafeERC20 for IERC20;
	address public constant SDT = 0x73968b9a57c6E53d41345FD57a6E6ae27d6CDB2F;
	address public constant veSDT = 0x0C30476f66034E11782938DF8e4384970B6c9e8a;
	address public governance;

	mapping(address => address) public depositors;
	mapping(address => uint256) public depositorsIndex;
	mapping(address => uint256) public gauges;

	struct LockStatus {
		bool[] locked;
		bool[] staked;
		bool lockSDT;
	}

	uint256 public depositorsCount;

	uint256 private constant MAX_REWARDS = 8;

	event GaugeEnabled(address gauge);
	event GaugeDisabled(address gauge);
	event DepositorEnabled(address token, address depositor);
	event Recovered(address token, uint256 amount);
	event RewardsClaimed(address[] gauges);
	event GovernanceChanged(address oldG, address newG);

	constructor() {
		governance = msg.sender;
	}

	modifier onlyGovernance() {
		require(msg.sender == governance, "!gov");
		_;
	}

	/// @notice A function to claim rewards from all the gauges supplied
	/// @param _gauges Gauges from which rewards are to be claimed
	function claimRewards(address[] calldata _gauges) external {
		uint256 gaugeLength = _gauges.length;
		for (uint256 index = 0; index < gaugeLength; ++index) {
			require(gauges[_gauges[index]] > 0, "Gauge not enabled");
			ILiquidityGauge(_gauges[index]).claim_rewards_for(msg.sender, msg.sender);
		}
		emit RewardsClaimed(_gauges);
	}

	/// @notice A function that allows the user to claim, lock and stake tokens retrieved from gauges
	/// @param _gauges Gauges from which rewards are to be claimed
	/// @param _lockStatus Status of locks for each reward token suppported by depositors and for SDT
	function claimAndLock(address[] memory _gauges, LockStatus memory _lockStatus) external {
		LockStatus memory lockStatus = _lockStatus;
		require(lockStatus.locked.length == lockStatus.staked.length, "different length");
		require(lockStatus.locked.length == depositorsCount, "different depositors length");

		uint256 gaugeLength = _gauges.length;
		// Claim rewards token from gauges
		for (uint256 index = 0; index < gaugeLength; ++index) {
			address gauge = _gauges[index];
			require(gauges[gauge] > 0, "Gauge not enabled");
			ILiquidityGauge(gauge).claim_rewards_for(msg.sender, address(this));
			// skip the first reward token, it is SDT for any LGV4
			// it loops at most until max rewards, it is hardcoded on LGV4
			for (uint256 i = 1; i < MAX_REWARDS; ++i) {
				address token = ILiquidityGauge(gauge).reward_tokens(i);
				if (token == address(0)) {
					break;
				}
				address depositor = depositors[token];
				uint256 balance = IERC20(token).balanceOf(address(this));
				if (balance != 0) {
					if (depositor != address(0) && lockStatus.locked[depositorsIndex[depositor]]) {
						IERC20(token).approve(depositor, balance);
						if (lockStatus.staked[depositorsIndex[depositor]]) {
							IDepositor(depositor).deposit(balance, false, true, msg.sender);
						} else {
							IDepositor(depositor).deposit(balance, false, false, msg.sender);
						}
					} else {
						SafeERC20.safeTransfer(IERC20(token), msg.sender, balance);
					}
					uint256 balanceLeft = IERC20(token).balanceOf(address(this));
					require(balanceLeft == 0, "wrong amount sent");
				}
			}
		}

		// Lock SDT for veSDT or send to the user if any
		uint256 balanceBefore = IERC20(SDT).balanceOf(address(this));
		if (balanceBefore != 0) {
			if (lockStatus.lockSDT && IVeSDT(veSDT).balanceOf(msg.sender) > 0) {
				IERC20(SDT).approve(veSDT, balanceBefore);
				IVeSDT(veSDT).deposit_for(msg.sender, balanceBefore);
			} else {
				SafeERC20.safeTransfer(IERC20(SDT), msg.sender, balanceBefore);
			}
			require(IERC20(SDT).balanceOf(address(this)) == 0, "wrong amount sent");
		}

		emit RewardsClaimed(_gauges);
	}

	/// @notice A function that rescue any ERC20 token
	/// @param _token token address
	/// @param _amount amount to rescue
	/// @param _recipient address to send token rescued
	function rescueERC20(
		address _token,
		uint256 _amount,
		address _recipient
	) external onlyGovernance {
		require(_recipient != address(0), "can't be zero address");
		SafeERC20.safeTransfer(IERC20(_token), _recipient, _amount);

		emit Recovered(_token, _amount);
	}

	/// @notice A function that enable a gauge
	/// @param _gauge gauge address to enable
	function enableGauge(address _gauge) external onlyGovernance {
		require(_gauge != address(0), "can't be zero address");
		require(gauges[_gauge] == 0, "already enabled");
		++gauges[_gauge];
		emit GaugeEnabled(_gauge);
	}

	/// @notice A function that disable a gauge
	/// @param _gauge gauge address to disable
	function disableGauge(address _gauge) external onlyGovernance {
		require(_gauge != address(0), "can't be zero address");
		require(gauges[_gauge] == 1, "already disabled");
		--gauges[_gauge];
		emit GaugeDisabled(_gauge);
	}

	/// @notice A function that add a new depositor for a specific token
	/// @param _token token address
	/// @param _depositor depositor address
	function addDepositor(address _token, address _depositor) external onlyGovernance {
		require(_token != address(0), "can't be zero address");
		require(_depositor != address(0), "can't be zero address");
		require(depositors[_token] == address(0), "already added");
		depositors[_token] = _depositor;
		depositorsIndex[_depositor] = depositorsCount;
		++depositorsCount;
		emit DepositorEnabled(_token, _depositor);
	}

	/// @notice A function that set the governance address
	/// @param _governance governance address
	function setGovernance(address _governance) external onlyGovernance {
		require(_governance != address(0), "can't be zero address");
		emit GovernanceChanged(governance, _governance);
		governance = _governance;
	}
}