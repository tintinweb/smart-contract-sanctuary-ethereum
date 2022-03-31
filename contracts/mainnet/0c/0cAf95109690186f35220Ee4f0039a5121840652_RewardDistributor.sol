// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./external/@openzeppelin/security/Pausable.sol";
import "./external/spool-core/SpoolOwnable.sol";
import "./interfaces/IRewardDistributor.sol";

import "./external/@openzeppelin/token/ERC20/utils/SafeERC20.sol";

/**
 * @notice Implementation of the {IRewardDistributor} interface.
 *
 * @dev
 * This contract has the simple logic to distribute ERC20 tokens
 * to the desired address (e.g. SpoolStaking).
 * It can be called from the whitelisted addresses to pay the rewards.
 *
 * Reward tokens should be sent to this contract in advance.
 *
 * The contract is pausable by the Spool DAO or the pauser.
 */
contract RewardDistributor is Pausable, SpoolOwnable, IRewardDistributor {
	using SafeERC20 for IERC20;

	/* ========== STATE VARIABLES ========== */

	/// @notice Is the address reward distributor
	/// @dev e.g. Spool staking contract
	mapping(address => bool) public isDistributor;

	/// @notice Can the address pause the contract
	mapping(address => bool) public isPauser;

	/* ========== CONSTRUCTOR ========== */

	/**
	 * @notice Sets the Spool DAO owner contract
	 *
	 * @param _spoolOwner Spool DAO owner contract
	 */
	constructor(ISpoolOwner _spoolOwner) SpoolOwnable(_spoolOwner) {}

	/* ========== DISTRIBUTE REWARDS FUNCTIONS ========== */

	/**
	 * @notice Pay ERC20 token rewards to `account`
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account address to retrieve the token to
	 * @param tokens ERC20 tokens to send
	 * @param amounts amount of rewards to send
	 */
	function payRewards(
		address account,
		IERC20[] memory tokens,
		uint256[] memory amounts
	) external override whenNotPaused onlyDistributor {
		require(
			tokens.length == amounts.length,
			"RewardDistributor::payRewards: Tokens should be of same length as amounts"
		);

		for (uint256 i = 0; i < tokens.length; i++) {
			_payReward(account, tokens[i], amounts[i]);
		}
	}

	/**
	 * @notice Pay ERC20 token reward to `account`
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the distributor
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to send
	 * @param amount amount of reward to send
	 */
	function payReward(
		address account,
		IERC20 token,
		uint256 amount
	) external override whenNotPaused onlyDistributor {
		_payReward(account, token, amount);
	}

	/**
	 * @notice Pay ERC20 token reward to `account`
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to send
	 * @param amount amount of reward to send
	 */
	function _payReward(
		address account,
		IERC20 token,
		uint256 amount
	) private {
		token.safeTransfer(account, amount);
		emit RewardPaid(token, account, amount);
	}

	/* ========== OWNER FUNCTIONS ========== */

	/**
	 * @notice Retrieve the reward tokens from this contract
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to retrieve the token to
	 * @param token ERC20 token to retrieve
	 * @param amount amount to retrieve
	 */
	function retrieveRewards(
		address account,
		IERC20 token,
		uint256 amount
	) external onlyOwner {
		token.safeTransfer(account, amount);
		emit RewardRetrieved(token, account, amount);
	}

	/**
	 * @notice Add or remove the reward distributer
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to manage the distributer role for
	 * @param _set true to set the role, flase to remove
	 */
	function setDistributor(address account, bool _set) external onlyOwner {
		isDistributor[account] = _set;
		emit DistributorUpdated(account, _set);
	}

	/**
	 * @notice Add or remove the pauser role
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 *
	 * @param account address to manage the pauser role for
	 * @param _set true to set the role, flase to remove
	 */
	function setPauser(address account, bool _set) external onlyOwner {
		isPauser[account] = _set;
		emit PauserUpdated(account, _set);
	}

	/**
	 * @notice Resumes the reward distribution.
	 *
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the contract owner (Spool DAO)
	 */
	function unpause() external onlyOwner {
		_unpause();
	}

	/* ========== PAUSE FUNCTION ========== */

	/**
	 * @notice Stops the controller.
	 * @dev
	 * Requirements:
	 *
	 * - the caller must be the pauser or the contract owner (Spool DAO)
	 */
	function pause() external onlyPauser {
		_pause();
	}

	/* ========== RESTRICTION FUNCTIONS ========== */

	/**
	 * @notice Ensures the caller is the reward distributor
	 */
	function _onlyDistributor() private view {
		require(isDistributor[msg.sender], "RewardDistributor::_onlyDistributor: Not a distributor");
	}

	/**
	 * @notice Ensures that the caller is the pauser
	 */
	function _onlyPauser() private view {
		require(isPauser[msg.sender] || isSpoolOwner(), "Controller::_onlyPauser: Can only be invoked by pauser");
	}

	/* ========== MODIFIERS ========== */

	/**
	 * @notice Throws if the caller is not the distributor
	 */
	modifier onlyDistributor() {
		_onlyDistributor();
		_;
	}

	/**
	 * @notice Throws if the calling user is not pauser
	 */
	modifier onlyPauser() {
		_onlyPauser();
		_;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "./interfaces/ISpoolOwner.sol";

abstract contract SpoolOwnable {
    ISpoolOwner internal immutable spoolOwner;
    
    constructor(ISpoolOwner _spoolOwner) {
        require(
            address(_spoolOwner) != address(0),
            "SpoolOwnable::constructor: Spool owner contract address cannot be 0"
        );

        spoolOwner = _spoolOwner;
    }

    function isSpoolOwner() internal view returns(bool) {
        return spoolOwner.isSpoolOwner(msg.sender);
    }

    function _onlyOwner() internal view {
        require(isSpoolOwner(), "SpoolOwnable::onlyOwner: Caller is not the Spool owner");
    }

    modifier onlyOwner() {
        _onlyOwner();
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface ISpoolOwner {
    function isSpoolOwner(address user) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../external/@openzeppelin/token/ERC20/IERC20.sol";

interface IRewardDistributor {
	/* ========== FUNCTIONS ========== */

	function payRewards(
		address account,
		IERC20[] memory tokens,
		uint256[] memory amounts
	) external;

	function payReward(
		address account,
		IERC20 token,
		uint256 amount
	) external;

	/* ========== EVENTS ========== */

	event RewardPaid(IERC20 token, address indexed account, uint256 amount);
	event RewardRetrieved(IERC20 token, address indexed account, uint256 amount);
	event DistributorUpdated(address indexed user, bool set);
	event PauserUpdated(address indexed user, bool set);
}