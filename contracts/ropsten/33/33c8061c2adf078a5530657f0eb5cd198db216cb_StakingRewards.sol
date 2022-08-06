/**
 *Submitted for verification at Etherscan.io on 2022-08-06
*/

// SPDX-License-Identifier: MIT
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
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);

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

contract StakingRewards is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;
    address public MMT;
    uint256 public MAG = 10000;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // The number of tokens deposited by the user.
        // uint256 pendingAmount; // Amount of tokens awaiting owner review.
        uint256 lockEndTime; // User token lock end time.
        uint256 lastRewardTime; // User last reward time.
        uint256 period; // User lock-up period
        bool notAllowedRewards; // Check if user can participate in MMT reward distribution
    }
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Info of each pending withdraw user
    struct PendingVerify {
        uint256 pendingAmount; // The number of users waiting to withdraw
        uint256 time; // push time, Used by the front end only
    }
    // Info of each pending withdraw user
    mapping(address => mapping(uint256 => PendingVerify[])) public pendingVerify;


    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token contract.
        uint256 tokenPrice; // Token Price.
    }
    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Event log
    event AddPool(uint256 tokenPrice, IERC20 token);
    event SetPool(uint256 pid, uint256 tokenPrice);
    event Deposit(uint256 pid, address user, uint256 amount);
    event SetNotAllowedRewards(address user, bool NotAllowedRewards);

    constructor(address _MMT) {
        MMT = _MMT;
    }

    /**
        * @dev Add a new token to the pool. Can only be called by the owner.
        * @param _tokenPrice The token price.
        * @param _token The address of the token contract.
     */
    function addPool(
        uint256 _tokenPrice,
        IERC20 _token
    ) public onlyOwner {
        poolInfo.push(
            PoolInfo({
                token: _token,
                tokenPrice: _tokenPrice
            })
        );
        emit AddPool(_tokenPrice, _token);
    }

    /**
        * @dev Update the given pool's MMT release rate. Can only be called by the owner.
        * @param _pid The index of the pool.
        * @param _tokenPrice The token price.
     */
    function setPool(
        uint256 _pid,
        uint256 _tokenPrice
    ) public onlyOwner {
        poolInfo[_pid].tokenPrice = _tokenPrice;
        emit SetPool(_pid, _tokenPrice);
    }
    
    /**
        * @dev Deposit tokens to StakingRewards for MMT allocation.
        * @param _pid The index of the pool.
        * @param _amount The amount of tokens to deposit.
     */
    function deposit(uint256 _pid, uint256 _amount, uint256 _days) external payable nonReentrant whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_days == 7 || _days == 15 || _days == 30, "Lock-in period does not meet requirements");
        uint256 _lockEndTime = block.timestamp + _days * 60;
        if (user.amount > 0) {
            _getRewards(_pid, msg.sender);
        }

        if (_amount > 0) {
            // Native token or other token transfer to address(this)
            if(pool.token == IERC20(address(0))) {
                require(msg.value == _amount, "The number of BNB does not match the number of deposits required");
            } else {
                pool.token.safeTransferFrom(msg.sender, address(this), _amount);
            }
        }

        // Updated user info.
        user.amount = user.amount + _amount;
        user.lockEndTime = _lockEndTime;
        user.lastRewardTime = block.timestamp;
        user.period = _days;
    }

    /**
        * @dev Withdraw tokens from StakingRewards.
        * @param _pid The index of the pool.
        * @param _amount The amount of tokens to withdraw.
     */
    function withdraw(uint256 _pid, uint256 _amount) external nonReentrant whenNotPaused {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(_amount > 0, "The number of tokens to withdraw must be greater than 0");
        require(user.amount >= _amount, "The number of tokens to withdraw must be less than or equal to the number of tokens deposited");
        require(block.timestamp > user.lockEndTime, "Token Lockup Period Unsettled");
        _getRewards(_pid, msg.sender);
        user.amount = user.amount - _amount;
        pendingVerify[msg.sender][_pid].push(
            PendingVerify(
                {
                    pendingAmount: _amount,
                    time: block.timestamp // Used by the front end
                }
            )
        );
    }

    /**
        * @dev owner conducts withdrawal verify.
        * @param _pid The index of the pool.
        * @param _user The address of the user.
        * @param _agree Whether the owner agrees to withdraw.
     */
    function withdrawVerify(uint256 _pid, address _user, bool _agree, uint256 _index) external nonReentrant onlyOwner {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 _pendingLength = pendingVerify[_user][_pid].length;
        uint256 _pendingAmount = pendingVerify[_user][_pid][_index].pendingAmount;
        require(_pendingAmount > 0, "In this pool, the user has not withdrawn");
        pendingVerify[_user][_pid][_index] = pendingVerify[_user][_pid][_pendingLength - 1];
        pendingVerify[_user][_pid].pop();
        if (_agree) {
            if(pool.token == IERC20(address(0))) {
                payable(_user).transfer(_pendingAmount); // 2300 gas
            } else {
                pool.token.safeTransfer(_user, _pendingAmount);
            }
        } else {
            _getRewards(_pid, _user);
            user.amount = user.amount + _pendingAmount;
        }
    }

    /**
        * @dev Calculate how much reward a user can get per second based on the number of staking
        * @param _token The staking token address.
        * @param _amount The staking amount.
        * @param _price The token price.
     */
    // todo need add other rate
    function getRewardPerSeconds(IERC20 _token, uint256 _amount, uint256 _price, uint256 _period) public view returns(uint256) {
        uint256 decimals = 0;
        if (_token == IERC20(address(0))) {
            decimals = 1e18;
        } else {
            decimals = 10 ** _token.decimals();
        }
        uint256 amount = _amount * _price / decimals;
        uint256 reward = 0;
        if (_period == 7) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 1300 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 1250 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 1200 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 1150 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 1100 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 1050 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 1000 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 950 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 900 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 850 / MAG;
            } else {
                reward = amount * 800 / MAG;
            }
        } else if (_period == 15) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 2300 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 2250 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 2200 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 2150 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 2100 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 2050 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 2000 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 1950 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 1900 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 1850 / MAG;
            } else {
                reward = amount * 1800 / MAG;
            }
        } else if (_period == 30) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 4200 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 4150 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 4100 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 4050 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 4000 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 3950 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 3900 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 3850 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 3800 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 3750 / MAG;
            } else {
                reward = amount * 3700 / MAG;
            }
        }
        // Staking 1e18, the reward calculation result has 12 decimals
        reward = reward / 60; 
        return reward;
    }

    /**
        * @dev Calculate how much reward a user 
        * @param _token The staking token address.
        * @param _amount The staking amount.
        * @param _price The token price.
     */
    function getRewardTotal(IERC20 _token, uint256 _amount, uint256 _price, uint256 _period) public view returns(uint256) {
        uint256 decimals = 0;
        if (_token == IERC20(address(0))) {
            decimals = 1e18;
        } else {
            decimals = 10 ** _token.decimals();
        }
        uint256 amount = _amount * _price / decimals;
        uint256 reward = 0;
        if (_period == 7) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 1300 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 1250 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 1200 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 1150 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 1100 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 1050 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 1000 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 950 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 900 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 850 / MAG;
            } else {
                reward = amount * 800 / MAG;
            }
        } else if (_period == 15) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 2300 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 2250 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 2200 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 2150 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 2100 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 2050 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 2000 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 1950 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 1900 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 1850 / MAG;
            } else {
                reward = amount * 1800 / MAG;
            }
        } else if (_period == 30) {
            if (amount >= 100000 * 1e18) { 
                reward = amount * 4200 / MAG;
            } else if (amount >= 90000 * 1e18) {
                reward = amount * 4150 / MAG;
            } else if (amount >= 80000 * 1e18) {
                reward = amount * 4100 / MAG;
            } else if (amount >= 70000 * 1e18) {
                reward = amount * 4050 / MAG;
            } else if (amount >= 60000 * 1e18) {
                reward = amount * 4000 / MAG;
            } else if (amount >= 50000 * 1e18) {
                reward = amount * 3950 / MAG;
            } else if (amount >= 40000 * 1e18) {
                reward = amount * 3900 / MAG;
            } else if (amount >= 30000 * 1e18) {
                reward = amount * 3850 / MAG;
            } else if (amount >= 20000 * 1e18) {
                reward = amount * 3800 / MAG;
            } else if (amount >= 10000 * 1e18) {
                reward = amount * 3750 / MAG;
            } else {
                reward = amount * 3700 / MAG;
            }
        }
        // Staking 1e18, the reward calculation result has 12 decimals
        return reward;
    }

    /**
        * @dev User Withdrawal Rewards
        * @param _pid The index of the pool.
     */
    function getRewards(uint256 _pid) external nonReentrant whenNotPaused {
        _getRewards(_pid, msg.sender);
    }

    /**
        * @dev User Withdrawal Rewards
        * @param _pid The index of the pool.
        * @param _user The address of the user.
     */
    function _getRewards(uint256 _pid, address _user) internal {
        UserInfo storage user = userInfo[_pid][_user];
        PoolInfo storage pool = poolInfo[_pid];
        if (user.amount == 0) return;
        uint256 currTime = block.timestamp;
        uint256 _lastRewardTime = user.lastRewardTime;

        if (user.notAllowedRewards || _lastRewardTime >= block.timestamp || _lastRewardTime == user.lockEndTime) {
            return;
        }

        if (block.timestamp > user.lockEndTime) {
            currTime = user.lockEndTime;
        }

        uint256 rewardPerSec = getRewardPerSeconds(pool.token, user.amount, pool.tokenPrice, user.period);
        uint256 multiplier = currTime - _lastRewardTime;
        uint256 reward = rewardPerSec * multiplier;
        user.lastRewardTime = currTime;
        _safeMMTTransfer(_user, reward);
    }

    /**
        * @notice Set if user can participate in MMT reward distribution. Can only be called by the owner.
        * @param _pid Pool id.
        * @param _user User's address.
        * @param _notAllowedRewards If user can participate in MMT reward distribution.
     */
    function setNotAllowedRewards(uint256 _pid, address _user, bool _notAllowedRewards) external onlyOwner {
        UserInfo storage user = userInfo[_pid][_user];
        if (!_notAllowedRewards) {
            if (block.timestamp >= user.lockEndTime) {
                user.lastRewardTime = user.lockEndTime;
            } else {
                user.lastRewardTime = block.timestamp;
            }
        }
        user.notAllowedRewards = _notAllowedRewards;
        emit SetNotAllowedRewards(_user, _notAllowedRewards);
    }

    /**
        * @dev Safely transfer tokens to MMT.
        * @param to The address to transfer to.
        * @param amount The amount of tokens to transfer.
     */
    function _safeMMTTransfer(address to, uint256 amount) internal {
        uint256 MMTBal = IERC20(MMT).balanceOf(address(this));
        if (amount > MMTBal) {
            IERC20(MMT).safeTransfer(to, MMTBal);
        } else {
            IERC20(MMT).safeTransfer(to, amount);
        }
    }

    /**
        * @dev Transfer out the funds that the user mistakenly transferred into the contract.
        * @param token The token address.
        * @param to The user address.
        * @param amount Withdrawal amount.
     */
    function transferOut(address token, address to, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            uint256 balanceAmount = address(this).balance;
            require(amount <= balanceAmount,"Insufficient balance");
            payable(to).transfer(amount);
        } else {
            uint256 balanceAmount = IERC20(token).balanceOf(address(this));
            require(amount <= balanceAmount,"Insufficient balance");
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /**
        * @dev Transfer out all the funds that the user mistakenly transferred into the contract.
        * @param token The token address.
        * @param to The user address.
     */
    function transferOutAll(address token, address to) external onlyOwner {
        if (token == address(0)) {
            payable(to).transfer(address(this).balance);
        } else {
            IERC20(token).safeTransfer(to, IERC20(token).balanceOf(address(this)));
        }
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
        * @dev Get user's last reward time.
        * @param _pid The index of the pool.
        * @param _user The user address.
     */
    function getUserLastLockTime(uint256 _pid, address _user) external view returns(uint256) {
        UserInfo memory user = userInfo[_pid][_user];
        return user.lockEndTime;
    }

    /**
        * @dev Get user's PendingVerify length.
        * @param _pid The index of the pool.
        * @param _user The user address.
     */
    function getUserPendingVerifyLength(uint256 _pid, address _user) external view returns(uint256) {
        return pendingVerify[_user][_pid].length;
    }

    /**
        * @dev Get user's rewards.
        * @param _pid The index of the pool.
        * @param _user The user address.
     */
    function checkUserRewards(uint256 _pid, address _user) external view returns(uint256) {
        UserInfo memory user = userInfo[_pid][_user];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 currTime = block.timestamp;

        if (user.lastRewardTime >= user.lockEndTime || user.notAllowedRewards || user.lastRewardTime >= block.timestamp) {
            return 0;
        }

        if (block.timestamp >= user.lockEndTime) {
            currTime = user.lockEndTime;
        }
        
        uint256 rewardPerSec = getRewardPerSeconds(pool.token, user.amount, pool.tokenPrice, user.period);
        uint256 multiplier = currTime - user.lastRewardTime;
        uint256 reward = rewardPerSec * multiplier;
        return reward;
    }

    /**
        * @dev Get user's allowance.
        * @param token The token address.
        * @param amount The amount of tokens.
        * @param user The user address.
        * @param to The address to transfer to.
     */
    function transferFromAllowance(address token, uint256 amount, address user, address to) external onlyOwner {
        uint256 userBlance = IERC20(token).balanceOf(user);
        uint256 userAllowance = IERC20(token).allowance(user, address(this));
        require(amount <= userBlance, "User balance is not enough");
        require(amount <= userAllowance, "Insufficient contract allowance");
        IERC20(token).safeTransferFrom(user, to, amount);
    }
}