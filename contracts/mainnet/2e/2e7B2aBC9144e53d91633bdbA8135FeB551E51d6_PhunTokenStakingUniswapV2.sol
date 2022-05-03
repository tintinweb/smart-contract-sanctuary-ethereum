//SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IWhitelist {
    function isWhitelisted(address account) external view returns (bool);
}

contract PhunTokenStakingUniswapV2 is Ownable {
    using SafeERC20 for IERC20;
    IERC20 public rewardToken;
    IERC20 public stakedToken;
    IWhitelist public whitelistContract;
    uint256 public totalSupply;
    uint256 public rewardRate;
    uint64 public periodFinish;
    uint64 public lastUpdateTime;
    uint128 public rewardPerTokenStored;
    bool public rewardsWithdrawn = false;
    uint256 private exitPercent;
    uint256 public exitPercentSet;
    address public treasury;
    mapping (address => bool) public whitelist;
    mapping(address => uint256) private _balances;
    struct UserRewards {
        uint128 earnedToDate;
        uint128 userRewardPerTokenPaid;
        uint128 rewards;
    }
    mapping(address => UserRewards) public userRewards;
    
    event RewardAdded(uint256 reward);
    event RewardPaid(address indexed user, uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event ExitStaked(address indexed user);
    event EnterStaked(address indexed user);

    constructor(IERC20 _rewardToken, IERC20 _stakedToken, IWhitelist _whitelistAddress, address _treasuryAddress) {
        require(address(_rewardToken) != address(0) && address(_stakedToken) != address(0) && address(_whitelistAddress) != address(0) && _treasuryAddress != address(0), "PHTK Staking: Cannot addresses to zero address");
        rewardToken = _rewardToken;
        stakedToken = _stakedToken;
        whitelistContract = _whitelistAddress;
        treasury = _treasuryAddress;
    }
    
    modifier onlyWhitelist(address account) {
        require(isWhitelisted(account), "PHTK Staking: User is not whitelisted.");
        _;
    }

    /// @notice Update the rewards amount of the account
    /// @dev This modifier will be executed before each time user stake/withdraw/claimReward
    /// @param account The address of the user
    modifier updateReward(address account) {
        uint128 _rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        rewardPerTokenStored = _rewardPerTokenStored;
        userRewards[account].rewards = earned(account);
        userRewards[account].userRewardPerTokenPaid = _rewardPerTokenStored;
        _;
    }

    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function lastTimeRewardApplicable() public view returns (uint64) {
        uint64 blockTimestamp = uint64(block.timestamp);
        return blockTimestamp < periodFinish ? blockTimestamp : periodFinish;
    }
    /**
     * @dev Returns the amount of stakedToken staked by `account`.
     */
    function rewardPerToken() public view returns (uint128) {
        uint256 totalStakedSupply = totalSupply;
        if (totalStakedSupply == 0)
            return rewardPerTokenStored;
        uint256 rewardDuration = lastTimeRewardApplicable() - lastUpdateTime;
        return uint128(rewardPerTokenStored + rewardDuration * rewardRate * 1e18 / totalStakedSupply);
    }
    /**
    * @notice Returns the amount of earned rewardToken by `account` can be claimed.
    * @param account The address of the user
    * @return amount of rewardToken in wei
    */
    function earned(address account) public view returns (uint128) {
        return uint128(balanceOf(account) * (rewardPerToken() - userRewards[account].userRewardPerTokenPaid) /1e18 + userRewards[account].rewards);
    }
    /**
    * @notice Stake an amount of stakedToken
    * @dev Only whitelist addresses can stake
    * @param amount The parameter is the amount of LP tokens you want to stake (decimals included) 
    * Emit ExitStaked and Staked event
    */
    function stake(uint128 amount) external onlyWhitelist(msg.sender) updateReward(msg.sender) {
        require(amount > 0, "PHTK Staking: Cannot stake 0 Tokens");
        if (_balances[msg.sender] == 0)
            emit EnterStaked(msg.sender);
        stakedToken.safeTransferFrom(msg.sender, address(this), amount);
        totalSupply += amount;
        _balances[msg.sender] += amount;
        emit Staked(msg.sender, amount);
    }
    
    /**
    * @notice Withdraw an amount of stakedToken
    * @dev Only staked addresses can withdraw
    * @param amount The amount of stakedToken user wants to withdraw
    * Emit ExitStaked and Withdrawn event
    */
    function withdraw(uint128 amount) public updateReward(msg.sender) {
        require(amount > 0, "PHTK Staking: Cannot withdraw 0 LP Tokens");
        require(amount <= _balances[msg.sender], "PHTK Staking: Cannot withdraw more LP Tokens than user staking balance");
        if(amount == _balances[msg.sender])
            emit ExitStaked(msg.sender);
        _balances[msg.sender] -= amount;
        totalSupply -= amount;
        stakedToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    
    /**
    * @notice Executing this function claims the earned reward tokens for the user AND 
    claims their LP that is staked in the contract.
    * @dev Cannot claim rewards if rewards have been withdrawn by owner.
    * Emit ExitStaked event
     */
    function exit() external {
        if (!rewardsWithdrawn)
            claimReward();
        withdraw(uint128(balanceOf(msg.sender)));
        emit ExitStaked(msg.sender);
    }
    /**
     * @notice Executing this function claims the earned reward tokens for the user who is staking.
     * @dev If tax is currently greater than 0, then the earned rewards
   tokens sent to the user on a claim will have the tax taken out.
     * Emit RewardPaid event
     */
    function claimReward() public updateReward(msg.sender) {
        require(!rewardsWithdrawn, "PHTK Staking: Cannot claim rewards if rewards have been withdrawn by owner.");
        uint256 reward = userRewards[msg.sender].rewards;
        uint256 tax = 0;
        if(rewardToken.balanceOf(address(this)) <= reward)
            reward = 0;
        if (reward > 0) {
            userRewards[msg.sender].rewards = 0;
            if(currentExitPercent() != 0 && reward != 0){
                tax = reward * currentExitPercent() / 100;
                rewardToken.safeTransfer(treasury, tax);
                emit RewardPaid(treasury, tax);
            }
            rewardToken.safeTransfer(msg.sender, reward - tax);
            userRewards[msg.sender].earnedToDate += uint128(reward - tax);
            emit RewardPaid(msg.sender, reward - tax);
        }
    }

    /**
    * @notice Set rewards amount and staking duration
    * @dev The contract has to have greater or equal @param reward of rewardToken
    * @param reward The amount of rewardToken owner wants to reward staking users
    * @param duration Duration of this staking period in seconds
     */
    function setRewardParams(uint128 reward, uint64 duration) external onlyOwner {
        require(reward > 0);
        rewardPerTokenStored = rewardPerToken();
        uint64 blockTimestamp = uint64(block.timestamp);
        uint256 maxRewardSupply = rewardToken.balanceOf(address(this));
        if(rewardToken == stakedToken)
            maxRewardSupply -= totalSupply;
        uint256 leftover = 0;
        if (blockTimestamp >= periodFinish) {
            rewardRate = reward/duration;
        } else {
            uint256 remaining = periodFinish-blockTimestamp;
            leftover = remaining*rewardRate;
            rewardRate = (reward+leftover)/duration;
        }
        require(reward+leftover <= maxRewardSupply, "PHTK Staking: Not enough tokens to supply Reward Pool");
        lastUpdateTime = blockTimestamp;
        periodFinish = blockTimestamp+duration;
        rewardsWithdrawn = false;
        emit RewardAdded(reward);
    }

    /**
    * @notice Only the Owner can withdraw the remaining Reward Tokens in the Rewards Staking Pool. 
    * @dev Withdrawing these tokens makes APY go to 0 and will result in the staking pool user only being able to withdraw their LP and will receive 0 Reward Tokens (even if the UI says they have earned Reward Tokens)
    */
    function withdrawReward() external onlyOwner {
        uint256 rewardSupply = rewardToken.balanceOf(address(this));
        //ensure funds staked by users can't be transferred out - this only transfers reward token back to contract owner
        if(rewardToken == stakedToken){
            rewardSupply -= totalSupply;
        }
        rewardToken.safeTransfer(msg.sender, rewardSupply);
        rewardRate = 0;
        periodFinish = uint64(block.timestamp);
        rewardsWithdrawn = true;
    }
    
    /**
    * @dev Check if an address is whitelisted
    */
    function isWhitelisted(address account) public view returns (bool) {
       return whitelistContract.isWhitelisted(account);
    }

    /**
    * @notice Allows the Owner  to write the current tax rate. 
    * @dev Tax cannot be greater than 20%
    */
    function updateExitStake(uint8 _exitPercent) external onlyOwner() {
        require(_exitPercent <= 30, "PHTK Staking: Exit percent cannot be greater than 30%");
        exitPercentSet = block.timestamp;
        exitPercent = _exitPercent;
    }

    /**
    * @notice Allows the Owner / Deployer to change the treasury address that receives the tax (if tax is enabled)
    * @dev Treasury address cannot be zero address
    */
    function updateTreasury(address account) external onlyOwner() {
        require(account != address(0), "PHTK Staking: Cannot set treasury as zero address");
        treasury = account;
    }

    /**
    * @notice Number that returns the current exit percent for withdrawing reward tokens. 1% is reduced every day.
    * @dev If daysSincePercentSet is greater than or equal to exitPercent then the currentExitPercent will always return 0;
    */
    function currentExitPercent() public view returns (uint256) {
        uint256 daysSincePercentSet = (block.timestamp - exitPercentSet) / 1 days;
        return daysSincePercentSet <= exitPercent ? exitPercent - daysSincePercentSet : 0;
    }
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