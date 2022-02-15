// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/ILiquidityGauge.sol";
import "../interfaces/ILocker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// @title A contract that defines the functions shared by all accumulators 
/// @author StakeDAO
contract BaseAccumulator {
    using SafeERC20 for IERC20;
    /* ========== STATE VARIABLES ========== */
    address public governance;
    address public locker;
    address public tokenReward;
    address public gauge;

    /* ========== EVENTS ========== */
    event GaugeSet(address oldGauge, address newGauge);
    event RewardNotified(address gauge, address tokenReward, uint256 amount);
    event LockerSet(address oldLocker, address newLocker);
    event GovernanceSet(address oldGov, address newGov);
    event TokenRewardSet(address oldTr, address newTr);
    event TokenDeposited(address token, uint256 amount);
    event ERC20Rescued(address token, uint256 amount);

    /* ========== CONSTRUCTOR ========== */
    constructor(address _tokenReward) {
        tokenReward = _tokenReward;
        governance = msg.sender;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /// @notice Notify the reward using an extra token
    /// @param _tokenReward token address to notify
    /// @param _amount amount to notify
    function notifyExtraReward(address _tokenReward, uint256 _amount) external {
        require(msg.sender == governance, "!gov");
        _notifyReward(_tokenReward, _amount);
    }

    /// @notice Notify the reward using all balance of extra token
    /// @param _tokenReward token address to notify
    function notifyAllExtraReward(address _tokenReward) external {
        require(msg.sender == governance, "!gov");
        uint256 amount = IERC20(_tokenReward).balanceOf(address(this));
        _notifyReward(_tokenReward, amount);
    }

    /// @notice Notify the new reward to the LGV4
    /// @param _tokenReward token to notify
    /// @param _amount amount to notify
    function _notifyReward(address _tokenReward, uint256 _amount) internal {
        require(gauge != address(0), "gauge not set");
        require(_amount > 0, "set an amount > 0");
        uint256 balanceBefore = IERC20(_tokenReward).balanceOf(address(this));
        require(balanceBefore >= _amount, "amount not enough");
        if (ILiquidityGauge(gauge).reward_data(_tokenReward).distributor != address(0)) {
            IERC20(_tokenReward).approve(gauge, _amount);
            ILiquidityGauge(gauge).deposit_reward_token(_tokenReward, _amount);
            uint256 balanceAfter = IERC20(_tokenReward).balanceOf(address(this));
            require(balanceBefore - balanceAfter == _amount, "wrong amount notified");
            emit RewardNotified(gauge, _tokenReward, _amount);
        }
    }

    /// @notice Deposit token into the accumulator
    /// @param _token token to deposit
    /// @param _amount amount to deposit
    function depositToken(address _token, uint256 _amount) external {
        require(_amount > 0, "set an amount > 0");
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        emit TokenDeposited(_token, _amount);
    }

    /// @notice Sets gauge for the accumulator which will receive and distribute the rewards
    /// @dev Can be called only by the governance
    /// @param _gauge gauge address 
    function setGauge(address _gauge) external {
        require(msg.sender == governance, "!gov");
        require(_gauge != address(0), "can't be zero address");
        emit GaugeSet(gauge, _gauge);
        gauge = _gauge;
    }

    /// @notice Allows the governance to set the new governance
    /// @dev Can be called only by the governance
    /// @param _governance governance address 
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!gov");
        require(_governance != address(0), "can't be zero address");
        emit GovernanceSet(governance, _governance);
        governance = _governance;
    }

    /// @notice Allows the governance to set the locker
    /// @dev Can be called only by the governance
    /// @param _locker locker address 
    function setLocker(address _locker) external {
        require(msg.sender == governance, "!gov");
        require(_locker != address(0), "can't be zero address");
        emit LockerSet(locker, _locker);
        locker = _locker;
    }

    /// @notice Allows the governance to set the token reward
    /// @dev Can be called only by the governance
    /// @param _tokenReward token reward address 
    function setTokenReward(address _tokenReward) external {
        require(msg.sender == governance, "!gov");
        require(_tokenReward != address(0), "can't be zero address");
        emit TokenRewardSet(tokenReward, _tokenReward);
        tokenReward = _tokenReward;
    }

    /// @notice A function that rescue any ERC20 token
	/// @param _token token address 
	/// @param _amount amount to rescue
	/// @param _recipient address to send token rescued
	function rescueERC20(
		address _token,
		uint256 _amount,
		address _recipient
	) external {
        require(msg.sender == governance, "!gov");
        require(_amount > 0, "set an amount > 0");
		require(_recipient != address(0), "can't be zero address");
		IERC20(_token).safeTransfer(_recipient, _amount);
		emit ERC20Rescued(_token, _amount);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./BaseAccumulator.sol";

/// @title A contract that accumulates FXS rewards and notifies them to the LGV4
/// @author StakeDAO
contract FxsAccumulator is BaseAccumulator {
    /* ========== CONSTRUCTOR ========== */
    constructor(address _tokenReward) BaseAccumulator(_tokenReward) {}

    /* ========== MUTATIVE FUNCTIONS ========== */
    /// @notice Claims rewards from the locker and notifies it to the LGV4
    /// @param _amount amount to notify
    function claimAndNotify(uint256 _amount) external {
        require(locker != address(0), "locker not set");
        ILocker(locker).claimFXSRewards(address(this));
        _notifyReward(tokenReward, _amount);
    }

    /// @notice Claims rewards from the locker and notify all to the LGV4
    function claimAndNotifyAll() external {
        require(locker != address(0), "locker not set");
        ILocker(locker).claimFXSRewards(address(this));
        uint256 amount = IERC20(tokenReward).balanceOf(address(this)); 
        _notifyReward(tokenReward, amount);
    }
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

interface ILocker {
	function createLock(uint256, uint256) external;

	function increaseAmount(uint256) external;

	function increaseUnlockTime(uint256) external;

	function release() external;

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
}