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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/StakingRewardsInterface.sol";

contract StakingRewards is
    Ownable,
    Pausable,
    ReentrancyGuard,
    StakingRewardsInterface
{
    using SafeERC20 for IERC20;

    /* ========== STATE VARIABLES ========== */

    /// @notice The staking token address
    IERC20 public stakingToken;

    /// @notice The list of rewards tokens
    address[] public rewardsTokens;

    /// @notice The reward tokens mapping
    mapping(address => bool) public rewardsTokensMap;

    /// @notice The period finish timestamp of every reward token
    mapping(address => uint256) public periodFinish;

    /// @notice The reward rate of every reward token
    mapping(address => uint256) public rewardRate;

    /// @notice The reward duration of every reward token
    mapping(address => uint256) public rewardsDuration;

    /// @notice The last updated timestamp of every reward token
    mapping(address => uint256) public lastUpdateTime;

    /// @notice The reward per token of every reward token
    mapping(address => uint256) public rewardPerTokenStored;

    /// @notice The reward per token paid to users of every reward token
    mapping(address => mapping(address => uint256)) public rewardPerTokenPaid;

    /// @notice The unclaimed rewards to users of every reward token
    mapping(address => mapping(address => uint256)) public rewards;

    /// @notice The helper contract that could stake, withdraw and claim rewards for users
    address public helperContract;

    /// @notice The total amount of the staking token staked in the contract
    uint256 private _totalSupply;

    /// @notice The user balance of the staking token staked in the contract
    mapping(address => uint256) private _balances;

    /* ========== CONSTRUCTOR ========== */

    constructor(address _stakingToken, address _helperContract) {
        stakingToken = IERC20(_stakingToken);
        helperContract = _helperContract;
    }

    /* ========== VIEWS ========== */

    /**
     * @notice Return the total amount of the staking token staked in the contract.
     * @return The total supply
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @notice Return user balance of the staking token staked in the contract.
     * @return The user balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Return the last time reward is applicable.
     * @param _rewardsToken The reward token address
     * @return The last applicable timestamp
     */
    function lastTimeRewardApplicable(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        return
            getBlockTimestamp() < periodFinish[_rewardsToken]
                ? getBlockTimestamp()
                : periodFinish[_rewardsToken];
    }

    /**
     * @notice Return the reward token amount per staking token.
     * @param _rewardsToken The reward token address
     * @return The reward token amount
     */
    function rewardPerToken(address _rewardsToken)
        public
        view
        returns (uint256)
    {
        // Return 0 if the rewards token is not supported.
        if (!rewardsTokensMap[_rewardsToken]) {
            return 0;
        }

        if (_totalSupply == 0) {
            return rewardPerTokenStored[_rewardsToken];
        }

        // rewardPerTokenStored + [(lastTimeRewardApplicable - lastUpdateTime) * rewardRate / _totalSupply]
        return
            rewardPerTokenStored[_rewardsToken] +
            (((lastTimeRewardApplicable(_rewardsToken) -
                lastUpdateTime[_rewardsToken]) *
                rewardRate[_rewardsToken] *
                1e18) / _totalSupply);
    }

    /**
     * @notice Return the reward token amount a user earned.
     * @param _rewardsToken The reward token address
     * @param account The user address
     * @return The reward token amount
     */
    function earned(address _rewardsToken, address account)
        public
        view
        returns (uint256)
    {
        // Return 0 if the rewards token is not supported.
        if (!rewardsTokensMap[_rewardsToken]) {
            return 0;
        }

        // rewards + (rewardPerToken - rewardPerTokenPaid) * _balances
        return
            (_balances[account] *
                (rewardPerToken(_rewardsToken) -
                    rewardPerTokenPaid[_rewardsToken][account])) /
            1e18 +
            rewards[_rewardsToken][account];
    }

    /**
     * @notice Return the reward rate.
     * @param _rewardsToken The reward token address
     * @return The reward rate
     */
    function getRewardRate(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return rewardRate[_rewardsToken];
    }

    /**
     * @notice Return the reward token for duration.
     * @param _rewardsToken The reward token address
     * @return The reward token amount
     */
    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256)
    {
        return rewardRate[_rewardsToken] * rewardsDuration[_rewardsToken];
    }

    /**
     * @notice Return the amount of reward tokens.
     * @return The amount of reward tokens
     */
    function getRewardsTokenCount() external view returns (uint256) {
        return rewardsTokens.length;
    }

    /**
     * @notice Return all the reward tokens.
     * @return All the reward tokens
     */
    function getAllRewardsTokens() external view returns (address[] memory) {
        return rewardsTokens;
    }

    /**
     * @notice Return the staking token.
     * @return The staking token
     */
    function getStakingToken() external view returns (address) {
        return address(stakingToken);
    }

    /**
     * @notice Return the current block timestamp.
     * @return The current block timestamp
     */
    function getBlockTimestamp() public view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice Stake the staking token.
     * @param amount The amount of the staking token
     */
    function stake(uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(msg.sender)
    {
        _stakeFor(msg.sender, amount);
    }

    /**
     * @notice Stake the staking token for other user.
     * @param account The user address
     * @param amount The amount of the staking token
     */
    function stakeFor(address account, uint256 amount)
        external
        nonReentrant
        whenNotPaused
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _stakeFor(account, amount);
    }

    function _stakeFor(address account, uint256 amount) internal {
        require(amount > 0, "invalid amount");
        _totalSupply = _totalSupply + amount;
        _balances[account] = _balances[account] + amount;
        stakingToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(account, amount);
    }

    /**
     * @notice Withdraw the staked token.
     * @param amount The amount of the staking token
     */
    function withdraw(uint256 amount)
        public
        nonReentrant
        updateReward(msg.sender)
    {
        _withdrawFor(msg.sender, amount);
    }

    /**
     * @notice Withdraw the staked token for other user.
     * @dev This function can only be called by helper.
     * @param account The user address
     * @param amount The amount of the staking token
     */
    function withdrawFor(address account, uint256 amount)
        public
        nonReentrant
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _withdrawFor(account, amount);
    }

    function _withdrawFor(address account, uint256 amount) internal {
        require(amount > 0, "invalid amount");
        _totalSupply = _totalSupply - amount;
        _balances[account] = _balances[account] - amount;
        stakingToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(account, amount);
    }

    /**
     * @notice Claim rewards for the message sender.
     */
    function getReward() public nonReentrant updateReward(msg.sender) {
        _getRewardFor(msg.sender);
    }

    /**
     * @notice Claim rewards for an account.
     * @dev This function can only be called by helper.
     * @param account The user address
     */
    function getRewardFor(address account)
        public
        nonReentrant
        updateReward(account)
    {
        require(msg.sender == helperContract, "unauthorized");
        require(account != address(0), "invalid account");
        _getRewardFor(account);
    }

    function _getRewardFor(address account) internal {
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            uint256 reward = rewards[rewardsTokens[i]][account];
            uint256 remain = IERC20(rewardsTokens[i]).balanceOf(address(this));
            if (reward > 0 && reward <= remain) {
                rewards[rewardsTokens[i]][account] = 0;
                IERC20(rewardsTokens[i]).safeTransfer(account, reward);
                emit RewardPaid(account, rewardsTokens[i], reward);
            }
        }
    }

    /**
     * @notice Withdraw all the staked tokens and claim rewards.
     */
    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    /**
     * @notice Set new reward amount.
     * @dev Make sure the admin deposits `reward` of reward tokens into the contract before calling this function.
     * @param rewardsToken The reward token address
     * @param reward The reward amount
     */
    function notifyRewardAmount(address rewardsToken, uint256 reward)
        external
        onlyOwner
        updateReward(address(0))
    {
        require(rewardsTokensMap[rewardsToken], "reward token not supported");

        if (getBlockTimestamp() >= periodFinish[rewardsToken]) {
            rewardRate[rewardsToken] = reward / rewardsDuration[rewardsToken];
        } else {
            uint256 remaining = periodFinish[rewardsToken] -
                getBlockTimestamp();
            uint256 leftover = remaining * rewardRate[rewardsToken];
            rewardRate[rewardsToken] =
                (reward + leftover) /
                rewardsDuration[rewardsToken];
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint256 balance = IERC20(rewardsToken).balanceOf(address(this));
        require(
            rewardRate[rewardsToken] <= balance / rewardsDuration[rewardsToken],
            "reward rate too high"
        );

        lastUpdateTime[rewardsToken] = getBlockTimestamp();
        periodFinish[rewardsToken] =
            getBlockTimestamp() +
            rewardsDuration[rewardsToken];
        emit RewardAdded(rewardsToken, reward);
    }

    /**
     * @notice Seize the accidentally deposited tokens.
     * @dev Thes staking tokens cannot be seized.
     * @param tokenAddress The token address
     * @param tokenAmount The token amount
     */
    function recoverToken(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(
            tokenAddress != address(stakingToken),
            "cannot withdraw staking token"
        );
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    /**
     * @notice Set the rewards duration.
     * @param rewardsToken The reward token address
     * @param duration The new duration
     */
    function setRewardsDuration(address rewardsToken, uint256 duration)
        external
        onlyOwner
    {
        require(rewardsTokensMap[rewardsToken], "reward token not supported");
        require(
            getBlockTimestamp() > periodFinish[rewardsToken],
            "previous rewards not complete"
        );
        _setRewardsDuration(rewardsToken, duration);
    }

    /**
     * @notice Support new rewards token.
     * @param rewardsToken The reward token address
     * @param duration The duration
     */
    function addRewardsToken(address rewardsToken, uint256 duration)
        external
        onlyOwner
    {
        require(
            !rewardsTokensMap[rewardsToken],
            "rewards token already supported"
        );

        rewardsTokens.push(rewardsToken);
        rewardsTokensMap[rewardsToken] = true;
        emit RewardsTokenAdded(rewardsToken);

        _setRewardsDuration(rewardsToken, duration);
    }

    /**
     * @notice Set the helper contract.
     * @param helper The helper contract address
     */
    function setHelperContract(address helper) external onlyOwner {
        helperContract = helper;
        emit HelperContractSet(helper);
    }

    /**
     * @notice Pause the staking.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause the staking.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    function _setRewardsDuration(address rewardsToken, uint256 duration)
        internal
    {
        rewardsDuration[rewardsToken] = duration;
        emit RewardsDurationUpdated(rewardsToken, duration);
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Update the reward information.
     * @param user The user address
     */
    modifier updateReward(address user) {
        for (uint256 i = 0; i < rewardsTokens.length; i++) {
            address token = rewardsTokens[i];
            rewardPerTokenStored[token] = rewardPerToken(token);
            lastUpdateTime[token] = lastTimeRewardApplicable(token);
            if (user != address(0)) {
                rewards[token][user] = earned(token, user);
                rewardPerTokenPaid[token][user] = rewardPerTokenStored[token];
            }
        }
        _;
    }

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when new reward tokens are added
     */
    event RewardAdded(address rewardsToken, uint256 reward);

    /**
     * @notice Emitted when user staked
     */
    event Staked(address indexed user, uint256 amount);

    /**
     * @notice Emitted when user withdrew
     */
    event Withdrawn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when rewards are paied
     */
    event RewardPaid(
        address indexed user,
        address rewardsToken,
        uint256 reward
    );

    /**
     * @notice Emitted when a reward duration is updated
     */
    event RewardsDurationUpdated(address rewardsToken, uint256 newDuration);

    /**
     * @notice Emitted when a token is recovered by admin
     */
    event Recovered(address token, uint256 amount);

    /**
     * @notice Emitted when a reward token is added
     */
    event RewardsTokenAdded(address rewardsToken);

    /**
     * @notice Emitted when new helper contract is set
     */
    event HelperContractSet(address helper);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./StakingRewards.sol";
import "./interfaces/ITokenInterface.sol";
import "./interfaces/StakingRewardsFactoryInterface.sol";

contract StakingRewardsFactory is Ownable, StakingRewardsFactoryInterface {
    using SafeERC20 for IERC20;

    /// @notice The list of staking rewards contract
    address[] private _stakingRewards;

    /// @notice The staking token - staking rewards contract mapping
    mapping(address => address) private _stakingRewardsMap;

    /// @notice The underlying - staking token mapping
    mapping(address => address) public _stakingTokenMap;

    /**
     * @notice Emitted when a staking rewards contract is deployed
     */
    event StakingRewardsCreated(
        address indexed stakingRewards,
        address indexed stakingToken
    );

    /**
     * @notice Emitted when a staking rewards contract is removed
     */
    event StakingRewardsRemoved(address indexed stakingToken);

    /**
     * @notice Emitted when tokens are seized
     */
    event TokenSeized(address token, uint256 amount);

    /**
     * @notice Return the amount of staking reward contracts.
     * @return The amount of staking reward contracts
     */
    function getStakingRewardsCount() external view returns (uint256) {
        return _stakingRewards.length;
    }

    /**
     * @notice Return all the staking reward contracts.
     * @return All the staking reward contracts
     */
    function getAllStakingRewards() external view returns (address[] memory) {
        return _stakingRewards;
    }

    /**
     * @notice Return the staking rewards contract of a given staking token
     * @param stakingToken The staking token
     * @return The staking reward contracts
     */
    function getStakingRewards(address stakingToken)
        external
        view
        returns (address)
    {
        return _stakingRewardsMap[stakingToken];
    }

    /**
     * @notice Return the staking token of a given underlying token
     * @param underlying The underlying token
     * @return The staking token
     */
    function getStakingToken(address underlying)
        external
        view
        returns (address)
    {
        return _stakingTokenMap[underlying];
    }

    /**
     * @notice Create staking reward contracts.
     * @param stakingTokens The staking token list
     */
    function createStakingRewards(
        address[] calldata stakingTokens,
        address helperContract
    ) external onlyOwner {
        for (uint256 i = 0; i < stakingTokens.length; i++) {
            address stakingToken = stakingTokens[i];
            address underlying = ITokenInterface(stakingToken).underlying();
            require(underlying != address(0), "invalid underlying");
            require(
                _stakingRewardsMap[stakingToken] == address(0),
                "staking rewards contract already exist"
            );

            // Create a new staking rewards contract.
            StakingRewards sr = new StakingRewards(
                stakingToken,
                helperContract
            );
            sr.transferOwnership(msg.sender);

            _stakingRewards.push(address(sr));
            _stakingRewardsMap[stakingToken] = address(sr);
            _stakingTokenMap[underlying] = stakingToken;
            emit StakingRewardsCreated(address(sr), stakingToken);
        }
    }

    /**
     * @notice Remove a staking reward contract.
     * @param stakingToken The staking token
     */
    function removeStakingRewards(address stakingToken) external onlyOwner {
        address underlying = ITokenInterface(stakingToken).underlying();
        require(underlying != address(0), "invalid underlying");
        require(
            _stakingRewardsMap[stakingToken] != address(0),
            "staking rewards contract not exist"
        );

        for (uint256 i = 0; i < _stakingRewards.length; i++) {
            if (_stakingRewardsMap[stakingToken] == _stakingRewards[i]) {
                _stakingRewards[i] = _stakingRewards[
                    _stakingRewards.length - 1
                ];
                delete _stakingRewards[_stakingRewards.length - 1];
                _stakingRewards.pop();
                break;
            }
        }
        _stakingRewardsMap[stakingToken] = address(0);
        _stakingTokenMap[underlying] = address(0);
        emit StakingRewardsRemoved(stakingToken);
    }

    /**
     * @notice Seize tokens in this contract.
     * @param token The token
     * @param amount The amount
     */
    function seize(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit TokenSeized(token, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITokenInterface {
    function underlying() external view returns (address);

    function supplyRatePerBlock() external view returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface StakingRewardsFactoryInterface {
    function getStakingRewardsCount() external view returns (uint256);

    function getAllStakingRewards() external view returns (address[] memory);

    function getStakingRewards(address stakingToken)
        external
        view
        returns (address);

    function getStakingToken(address underlying)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface StakingRewardsInterface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function lastTimeRewardApplicable(address _rewardsToken)
        external
        view
        returns (uint256);

    function rewardPerToken(address _rewardsToken)
        external
        view
        returns (uint256);

    function earned(address _rewardsToken, address account)
        external
        view
        returns (uint256);

    function getRewardRate(address _rewardsToken)
        external
        view
        returns (uint256);

    function getRewardForDuration(address _rewardsToken)
        external
        view
        returns (uint256);

    function getRewardsTokenCount() external view returns (uint256);

    function getAllRewardsTokens() external view returns (address[] memory);

    function getStakingToken() external view returns (address);

    function stake(uint256 amount) external;

    function stakeFor(address account, uint256 amount) external;

    function withdraw(uint256 amount) external;

    function withdrawFor(address account, uint256 amount) external;

    function getReward() external;

    function getRewardFor(address account) external;

    function exit() external;
}