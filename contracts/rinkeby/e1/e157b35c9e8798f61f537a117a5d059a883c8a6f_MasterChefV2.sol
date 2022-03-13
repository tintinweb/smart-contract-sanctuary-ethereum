/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

/** 
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [////IMPORTANT]
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
     * ////IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}




/** 
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../IERC20.sol";
////import "../../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}




/** 
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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

    constructor () {
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




/** 
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../utils/Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/** 
 *  SourceUnit: d:\Projects\ibl\sc-capital-dao\contracts\staking\MasterChefV2.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.0;

////import "@openzeppelin/contracts/access/Ownable.sol";

////import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IStakingRewardVault {

    function transfer(address _receiver, uint256 _amount) external;

}

contract MasterChefV2 is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    uint256 internal constant REWARD_PER_SHARE_MULTIPLIER = 1e12;

    uint256 internal constant BLOCK_PER_HALF_YEAR = 1036800; // 5760 blocks/day * 180 days

    struct User {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastDepositAt;
    }

    struct Pool {
        IERC20 token;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 rewardPerShare;
        uint256 lockTime;
    }

    IStakingRewardVault public vault;

    IERC20 public token;

    Pool[] public pools;

    mapping(uint256 => mapping(address => User)) public users;

    uint256 public totalAllocPoint;

    uint256 public startBlock;

    mapping(address => bool) public tokenExisted;

    event PoolAdded(address token, uint256 allocPoint, uint256 lockTime);
    event PoolUpdated(uint256 pid, uint256 allocPoint, uint256 lockTime);

    event Staked(address user, uint256 pid, uint256 amount);
    event Unstaked(address user, uint256 pid, uint256 amount);

    event RewardWithdraw(address receiver, uint256 amount);

    modifier poolExist(uint256 _pid) {
        require(_pid < pools.length, "MasterChef: pool has not existed");
        _;
    }

    constructor(IStakingRewardVault _vault, IERC20 _token, uint256 _startBlock)
    {
        vault = _vault;
        token = _token;
        startBlock = _startBlock;
    }

    function getTotalPools() public view returns (uint256) {
        return pools.length;
    }

    function add(address _token, uint256 _allocPoint, uint256 _lockTime, bool _withUpdate)
        public
        onlyOwner
    {
        require(_token != address(0) && !tokenExisted[_token], "MasterChef: token is invalid");

        tokenExisted[_token] = true;

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        pools.push(Pool({
            token: IERC20(_token),
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            rewardPerShare: 0,
            lockTime: _lockTime
        }));

        totalAllocPoint += _allocPoint;

        emit PoolAdded(_token, _allocPoint, _lockTime);
    }

    function set(uint256 _pid, uint256 _allocPoint, uint256 _lockTime, bool _withUpdate)
        public
        onlyOwner
        poolExist(_pid)
    {
        if (_withUpdate) {
            massUpdatePools();
        }

        Pool storage pool = pools[_pid];

        if (pool.allocPoint != _allocPoint) {
            totalAllocPoint = totalAllocPoint - pool.allocPoint + _allocPoint;

            pool.allocPoint = _allocPoint;
        }

        if (pool.lockTime != _lockTime) {
            pool.lockTime = _lockTime;
        }

        emit PoolUpdated(_pid, _allocPoint, _lockTime);
    }

    function rewardToShare(uint256 _reward, uint256 _rewardPerShare) public pure returns (uint256) {
        return (_reward * REWARD_PER_SHARE_MULTIPLIER) / _rewardPerShare;
    }

    function shareToReward(uint256 _share, uint256 _rewardPerShare) public pure returns (uint256) {
        return (_share * _rewardPerShare) / REWARD_PER_SHARE_MULTIPLIER;
    }

    function pendingReward(uint256 _pid, address _account) public view returns (uint256) {
        if (_pid >= pools.length) {
            return 0;
        }

        Pool memory pool = pools[_pid];

        User memory user = users[_pid][_account];

        uint256 rewardPerShare = pool.rewardPerShare;

        uint256 supply = pool.token.balanceOf(address(this));

        if (block.number > pool.lastRewardBlock && supply != 0) {
            uint256 reward = getRewardManyBlock(pool.lastRewardBlock, block.number) * pool.allocPoint / totalAllocPoint;

            uint256 remaining = token.balanceOf(address(vault));

            if (reward > remaining) {
                reward = remaining;
            }

            if (reward > 0) {
                rewardPerShare += rewardToShare(reward, supply);
            }
        }

        return shareToReward(user.amount, rewardPerShare) - user.rewardDebt;
    }

    function massUpdatePools() public {
        uint256 length = pools.length;

        for (uint256 pid = 0; pid < length; pid++) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid)
        public
        poolExist(_pid)
        nonReentrant
    {
        Pool storage pool = pools[_pid];

        if (block.number <= pool.lastRewardBlock) {
            return;
        }

        uint256 supply = pool.token.balanceOf(address(this));

        if (supply == 0 || pool.allocPoint == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 reward = getRewardManyBlock(pool.lastRewardBlock, block.number) * pool.allocPoint / totalAllocPoint;

        uint256 remaining = token.balanceOf(address(vault));

        if (reward > remaining) {
            reward = remaining;
        }

        if (reward > 0) {
            vault.transfer(address(this), reward);

            pool.rewardPerShare += rewardToShare(reward, supply);
        }

        pool.lastRewardBlock = block.number;
    }

    function stake(uint256 _pid, uint256 _amount)
        public
    {
        address msgSender = _msgSender();

        Pool storage pool = pools[_pid];

        User storage user = users[_pid][msgSender];

        updatePool(_pid);

        if (user.amount > 0) {
            uint256 pending = shareToReward(user.amount, pool.rewardPerShare) - user.rewardDebt;

            if (pending > 0) {
                token.safeTransfer(msgSender, pending);
            }
        }

        if (_amount > 0) {
            pool.token.safeTransferFrom(msgSender, address(this), _amount);

            user.amount += _amount;

            if (block.timestamp >= user.lastDepositAt + pool.lockTime) {
                user.lastDepositAt = block.timestamp;
            }
        }

        user.rewardDebt = shareToReward(user.amount, pool.rewardPerShare);

        emit Staked(msgSender, _pid, _amount);
    }

    function unstake(uint256 _pid, uint256 _amount)
        public
    {
        address msgSender = _msgSender();

        Pool storage pool = pools[_pid];

        User storage user = users[_pid][msgSender];

        require(user.amount >= _amount, "MasterChef: amount exceeds stake");

        updatePool(_pid);

        uint256 pending = shareToReward(user.amount, pool.rewardPerShare) - user.rewardDebt;

        if (pending > 0) {
            token.safeTransfer(msgSender, pending);
        }

        if (_amount > 0) {
            require(block.timestamp >= user.lastDepositAt + pool.lockTime, "MasterChef: locking");

            user.amount -= _amount;

            pool.token.safeTransfer(msgSender, _amount);

            if (user.amount == 0) {
                user.lastDepositAt = 0;
            }
        }

        user.rewardDebt = shareToReward(user.amount, pool.rewardPerShare);

        emit Unstaked(msgSender, _pid, _amount);
    }

    function getRate(uint256 stage)
        public
        pure
        returns(uint256)
    {
        if (stage == 1) {
            return 200;

        } else if (stage == 2) {
            return 180;

        } else if (stage == 3) {
            return 160;

        } else if (stage == 4) {
            return 140;

        } else if (stage == 5) {
            return 120;

        } else if (stage >= 6 && stage <= 12) {
            return 100;

        } else if (stage >= 13 && stage <= 18) {
            return 80;

        } else if (stage >= 19 && stage <= 21) {
            return 60;

        } else {
            return 0;
        }
    }

    function getStage(uint256 currentBlock)
        public
        view
        returns(uint256)
    {
        return (currentBlock - startBlock) / BLOCK_PER_HALF_YEAR + 1;
    }

    function getRewardPerStage(uint256 stage)
        public
        pure
        returns(uint256)
    {
        return 1536000000 * 1e18 * getRate(stage) / 2160;
    }

    function getRewardPerBlock(uint256 stage)
        public
        pure
        returns(uint256)
    {
        return getRewardPerStage(stage) / BLOCK_PER_HALF_YEAR;
    }

    function getRewardManyBlock(uint256 blockFrom, uint256 blockTo)
        public
        view
        returns(uint256)
    {
        uint256 start = startBlock;

        if (blockFrom < start || blockFrom >= blockTo) {
            return 0;
        }

        uint256 reward = 0;

        uint256 stage = (blockFrom - start) / BLOCK_PER_HALF_YEAR + 1;

        for (uint256 i = stage; i <= 21; i++) {
            uint256 milestone = start + (BLOCK_PER_HALF_YEAR * i);

            if (blockFrom >= milestone) {
                continue;
            }

            uint256 rewardPerBlock = getRewardPerBlock(i);

            if (blockTo <= milestone) {
                reward += (blockTo - blockFrom) * rewardPerBlock;
                break;
            }

            reward += (milestone - blockFrom) * rewardPerBlock;

            blockFrom = milestone;
        }

        return reward;
    }

    function withdrawReward()
        public
        onlyOwner
    {
        address msgSender = _msgSender();

        uint256 stage = getStage(block.number);

        uint256 rewardPerBlock = getRewardPerBlock(stage);

        require(rewardPerBlock == 0, "MasterChef: can not withdraw");

        massUpdatePools();

        uint256 remaining = token.balanceOf(address(vault));

        require(remaining > 0, "MasterChef: no reward");

        vault.transfer(msgSender, remaining);

        emit RewardWithdraw(msgSender, remaining);
    }

}