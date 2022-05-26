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
	function reward_tokens(uint256 _i) external view returns (address);

	// solhint-disable-next-line
	function reward_data(address _tokenReward) external view returns (Reward memory);

	function balanceOf(address) external returns (uint256);

	function claimable_reward(address _user, address _reward_token) external view returns (uint256);

	function claimable_tokens(address _user) external returns (uint256);

	function user_checkpoint(address _user) external returns (bool);

	function commit_transfer_ownership(address) external;

	function claim_rewards(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ILocker {
	function createLock(uint256, uint256) external;

	function claimAllRewards(address[] calldata _tokens, address _recipient) external;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ISdToken {
	function setOperator(address _operator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface ITokenMinter {
	function mint(address, uint256) external;

	function burn(address, uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../interfaces/ITokenMinter.sol";
import "../interfaces/ILocker.sol";
import "../interfaces/ISdToken.sol";
import "../interfaces/ILiquidityGauge.sol";

/// @title Contract that accepts tokens and locks them
/// @author StakeDAO
contract BalancerDepositor {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */
	address public token;
	uint256 private constant MAXTIME = 364 * 86_400;
	uint256 private constant WEEK = 7 * 86_400;

	uint256 public lockIncentive = 10; //incentive to users who spend gas to lock token
	uint256 public constant FEE_DENOMINATOR = 10_000;

	address public gauge;
	address public governance;
	address public immutable locker;
	address public immutable minter;
	uint256 public incentiveToken = 0;
	uint256 public unlockTime;
	bool public relock = true;

	/* ========== EVENTS ========== */
	event Deposited(address indexed caller, address indexed user, uint256 amount, bool lock, bool stake);
	event IncentiveReceived(address indexed caller, uint256 amount);
	event TokenLocked(address indexed user, uint256 amount);
	event GovernanceChanged(address indexed newGovernance);
	event SdTokenOperatorChanged(address indexed newSdToken);
	event FeesChanged(uint256 newFee);

	/* ========== CONSTRUCTOR ========== */
	constructor(
		address _token,
		address _locker,
		address _minter
	) {
		governance = msg.sender;
		token = _token;
		locker = _locker;
		minter = _minter;
	}

	/* ========== RESTRICTED FUNCTIONS ========== */
	/// @notice Set the new governance
	/// @param _governance governance address 
	function setGovernance(address _governance) external {
		require(msg.sender == governance, "!auth");
		governance = _governance;
		emit GovernanceChanged(_governance);
	}

	/// @notice Set the new operator for minting sdToken
	/// @param _operator operator address
	function setSdTokenOperator(address _operator) external {
		require(msg.sender == governance, "!auth");
		ISdToken(minter).setOperator(_operator);
		emit SdTokenOperatorChanged(_operator);
	}

	/// @notice Enable the relock or not
	/// @param _relock relock status 
	function setRelock(bool _relock) external {
		require(msg.sender == governance, "!auth");
		relock = _relock;
	}

	/// @notice Set the gauge to deposit token yielded
	/// @param _gauge gauge address 
	function setGauge(address _gauge) external {
		require(msg.sender == governance, "!auth");
		gauge = _gauge;
	}

	/// @notice set the fees for locking incentive
	/// @param _lockIncentive contract must have tokens to lock
	function setFees(uint256 _lockIncentive) external {
		require(msg.sender == governance, "!auth");

		if (_lockIncentive >= 0 && _lockIncentive <= 30) {
			lockIncentive = _lockIncentive;
			emit FeesChanged(_lockIncentive);
		}
	}

	/* ========== MUTATIVE FUNCTIONS ========== */

	/// @notice Locks the tokens held by the contract
	/// @dev The contract must have tokens to lock
	function _lockToken() internal {
		uint256 tokenBalance = IERC20(token).balanceOf(address(this));

		// If there is Token available in the contract transfer it to the locker
		if (tokenBalance > 0) {
			IERC20(token).safeTransfer(locker, tokenBalance);
			emit TokenLocked(msg.sender, tokenBalance);
		}

		uint256 tokenBalanceStaker = IERC20(token).balanceOf(locker);
		// If the locker has no tokens then return
		if (tokenBalanceStaker == 0) {
			return;
		}

		ILocker(locker).increaseAmount(tokenBalanceStaker);

		if (relock) {
			uint256 unlockAt = block.timestamp + MAXTIME;
			uint256 unlockInWeeks = (unlockAt / WEEK) * WEEK;

			// it means that a 1 week + at least 1 second has been passed 
			// since last increased unlock time
			if (unlockInWeeks - unlockTime > 1) {
				ILocker(locker).increaseUnlockTime(unlockAt);
				unlockTime = unlockInWeeks;
			}
		}
	}

	/// @notice Lock tokens held by the contract
	/// @dev The contract must have Token to lock
	function lockToken() external {
		_lockToken();

		// If there is incentive available give it to the user calling lockToken
		if (incentiveToken > 0) {
			ITokenMinter(minter).mint(msg.sender, incentiveToken);
			emit IncentiveReceived(msg.sender, incentiveToken);
			incentiveToken = 0;
		}
	}

	/// @notice Deposit & Lock Token
	/// @dev User needs to approve the contract to transfer the token
	/// @param _amount The amount of token to deposit
	/// @param _lock Whether to lock the token
	/// @param _stake Whether to stake the token
	/// @param _user User to deposit for
	function deposit(
		uint256 _amount,
		bool _lock,
		bool _stake,
		address _user
	) public {
		require(_amount > 0, "!>0");
		require(_user != address(0), "!user");

		// If User chooses to lock Token
		if (_lock) {
			IERC20(token).safeTransferFrom(msg.sender, locker, _amount);
			_lockToken();

			if (incentiveToken > 0) {
				_amount = _amount + incentiveToken;
				emit IncentiveReceived(msg.sender, incentiveToken);
				incentiveToken = 0;
			}
		} else {
			//move tokens here
			IERC20(token).safeTransferFrom(msg.sender, address(this), _amount);
			//defer lock cost to another user
			uint256 callIncentive = (_amount * lockIncentive) / FEE_DENOMINATOR;
			_amount = _amount - callIncentive;
			incentiveToken = incentiveToken + callIncentive;
		}

		if (_stake && gauge != address(0)) {
			ITokenMinter(minter).mint(address(this), _amount);
			IERC20(minter).safeApprove(gauge, 0);
			IERC20(minter).safeApprove(gauge, _amount);
			ILiquidityGauge(gauge).deposit(_amount, _user);
		} else {
			ITokenMinter(minter).mint(_user, _amount);
		}

		emit Deposited(msg.sender, _user, _amount, _lock, _stake);
	}

	/// @notice Deposits all the token of a user & locks them based on the options choosen
	/// @dev User needs to approve the contract to transfer Token tokens
	/// @param _lock Whether to lock the token
	/// @param _stake Whether to stake the token
	/// @param _user User to deposit for 
	function depositAll(
		bool _lock,
		bool _stake,
		address _user
	) external {
		uint256 tokenBal = IERC20(token).balanceOf(msg.sender);
		deposit(tokenBal, _lock, _stake, _user);
	}
}