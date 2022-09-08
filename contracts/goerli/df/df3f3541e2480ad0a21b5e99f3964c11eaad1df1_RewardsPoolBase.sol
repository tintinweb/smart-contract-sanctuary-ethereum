/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/RewardsPoolBase.sol


pragma solidity 0.8.9;




/** @dev Base pool contract used in all other pools. 
Users can stake tokens and get rewards based on the percentage of total staked tokens.
After deployment, owner can send funds and then start the pool. 
When it's started a check is done to verify enough rewards are available. 
Users can claim their rewards at any point, as well as withdraw their stake.
The owner can extend the pool by setting a new end time and sending more rewards if needed.
Rewards are kept track of using the accumulatedRewardMultiplier.
This variable represents the accumulated reward per token staked from the start until now.
Based on the difference between the accumulatedRewardMultiplier at the time of your stake and withdrawal, 
we calculate the amount of tokens you can claim.
For example, you enter when the accumulatedRewardMultiplier is 5 and exit at 20. You staked 100 tokens.
Your reward is (20 - 5) * 100 = 1500 tokens.
*/
contract RewardsPoolBase is Ownable {
    using SafeERC20 for IERC20;

    uint256 internal constant PRECISION = 1 ether;

    uint256 public totalStaked;
    uint256[] private totalClaimed;
    uint256[] private totalSpentRewards;

    uint256[] public rewardPerSecond;
    address[] public rewardsTokens;

    IERC20 public immutable stakingToken;

    uint256 public startTimestamp;
    uint256 public endTimestamp;
    uint256 private lastRewardTimestamp;

    uint256 public extensionDuration;
    uint256[] public extensionRewardPerSecond;

    uint256[] public accumulatedRewardMultiplier;

    uint256 public immutable stakeLimit;
    uint256 public immutable contractStakeLimit;

    string public name;

    struct UserInfo {
        uint256 firstStakedTimestamp;
        uint256 amountStaked; // How many tokens the user has staked.
        uint256[] rewardDebt; //
        uint256[] tokensOwed; // How many tokens the contract owes to the user.
    }

    mapping(address => UserInfo) public userInfo;

    struct Campaign {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256[] rewardPerSecond;
    }

    Campaign[] public previousCampaigns;

    event Started(uint256 startTimestamp, uint256 endTimestamp, uint256[] rewardsPerSecond);
    event Staked(address indexed user, uint256 amount);
    event Claimed(address indexed user, uint256 amount, address token);
    event Withdrawn(address indexed user, uint256 amount);
    event Exited(address indexed user, uint256 amount);
    event Extended(uint256 newStartTimestamp, uint256 newEndTimestamp, uint256[] newRewardsPerSecond);

    /** @param _stakingToken The token to stake
     * @param _rewardsTokens The reward tokens
     * @param _stakeLimit Maximum amount of tokens that can be staked per user
     * @param _contractStakeLimit Maximum amount of tokens that can be staked in total
     * @param _name Name of the pool
     */
    constructor(
        IERC20 _stakingToken,
        address[] memory _rewardsTokens,
        uint256 _stakeLimit,
        uint256 _contractStakeLimit,
        string memory _name
    ) {
        require(address(_stakingToken) != address(0), 'RewardsPoolBase: invalid staking token');

        require(_stakeLimit != 0 && _contractStakeLimit != 0, 'RewardsPoolBase: invalid stake limit');

        require(_rewardsTokens.length > 0, 'RewardsPoolBase: empty rewardsTokens');

        for (uint256 i = 0; i < _rewardsTokens.length; i++) {
            for (uint256 j = i + 1; j < _rewardsTokens.length; j++) {
                require(
                    address(_rewardsTokens[i]) != address(_rewardsTokens[j]),
                    'RewardsPoolBase: duplicate rewards token'
                );
            }
        }

        stakingToken = _stakingToken;
        rewardsTokens = _rewardsTokens;
        stakeLimit = _stakeLimit;
        contractStakeLimit = _contractStakeLimit;

        uint256[] memory empty = new uint256[](rewardsTokens.length);
        accumulatedRewardMultiplier = empty;
        totalClaimed = empty;
        totalSpentRewards = empty;

        name = _name;
    }

    /** @dev Start the pool. Funds for rewards will be checked and staking will be opened.
     * @param _startTimestamp The start time of the pool
     * @param _endTimestamp The end time of the pool
     * @param _rewardPerSecond Amount of rewards given per second
     */
    function start(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] calldata _rewardPerSecond
    ) external virtual onlyOwner {
        _start(_startTimestamp, _endTimestamp, _rewardPerSecond);
    }

    function _start(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] calldata _rewardPerSecond
    ) internal {
        require(startTimestamp == 0, 'RewardsPoolBase: already started');
        require(
            _startTimestamp >= block.timestamp && _endTimestamp > _startTimestamp,
            'RewardsPoolBase: invalid start or end'
        );

        require(_rewardPerSecond.length == rewardsTokens.length, 'RewardsPoolBase: invalid rewardPerSecond');
        rewardPerSecond = _rewardPerSecond;

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            uint256 rewardsAmount = calculateRewardsAmount(_startTimestamp, _endTimestamp, rewardPerSecond[i]);

            uint256 balance = IERC20(rewardsTokens[i]).balanceOf(address(this));

            require(balance >= rewardsAmount, 'RewardsPoolBase: not enough rewards');
        }

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lastRewardTimestamp = _startTimestamp;

        emit Started(startTimestamp, endTimestamp, rewardPerSecond);
    }

    /** @dev Cancels the scheduled start. Can only be done before the start.
     */
    function cancel() external virtual onlyOwner {
        _cancel();
    }

    function _cancel() internal {
        require(block.timestamp < startTimestamp, 'RewardsPoolBase: No start scheduled or already started');

        rewardPerSecond = new uint256[](0);
        startTimestamp = 0;
        endTimestamp = 0;
        lastRewardTimestamp = 0;
    }

    /** @dev Stake an amount of tokens
     * @param _tokenAmount The amount to be staked
     */
    function stake(uint256 _tokenAmount) public virtual {
        _stake(_tokenAmount, msg.sender, true);
    }

    function _stake(
        uint256 _tokenAmount,
        address _staker,
        bool _chargeStaker
    ) internal {
        uint256 currentTimestamp = block.timestamp;
        require(
            (startTimestamp > 0 && currentTimestamp > startTimestamp) &&
                (currentTimestamp <= endTimestamp + extensionDuration),
            'RewardsPoolBase: staking is not started or is finished or no extension taking in place'
        );

        UserInfo storage user = userInfo[_staker];
        require(
            (user.amountStaked + _tokenAmount <= stakeLimit) && (totalStaked + _tokenAmount <= contractStakeLimit),
            'RewardsPoolBase: stake limit reached'
        );

        require(_tokenAmount > 0, 'RewardsPoolBase: cannot stake 0');

        // if no amount has been staked this is considered the initial stake
        if (user.amountStaked == 0) {
            user.firstStakedTimestamp = currentTimestamp;
        }

        updateRewardMultipliers(); // Update the accumulated multipliers for everyone
        _updateUserAccruedReward(_staker); // Update the accrued reward for this specific user

        user.amountStaked = user.amountStaked + _tokenAmount;
        totalStaked = totalStaked + _tokenAmount;

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            user.rewardDebt[i] = (user.amountStaked * accumulatedRewardMultiplier[i]) / PRECISION; // Update user reward debt for each token
        }

        emit Staked(_staker, _tokenAmount);

        stakingToken.safeTransferFrom(address(_chargeStaker ? _staker : msg.sender), address(this), _tokenAmount);
    }

    /** @dev Claim all your rewards, this will not remove your stake
     */
    function claim() public virtual {
        _claim(msg.sender);
    }

    function _claim(address _claimer) internal {
        UserInfo storage user = userInfo[_claimer];
        updateRewardMultipliers();
        _updateUserAccruedReward(_claimer);

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            uint256 reward = user.tokensOwed[i];
            user.tokensOwed[i] = 0;
            totalClaimed[i] = totalClaimed[i] + reward;

            emit Claimed(_claimer, reward, rewardsTokens[i]);

            IERC20(rewardsTokens[i]).safeTransfer(_claimer, reward);
        }
    }

    /** @dev Withdrawing a portion or all of staked tokens. This will not claim your rewards
     * @param _tokenAmount The amount to be withdrawn
     */
    function withdraw(uint256 _tokenAmount) public virtual {
        _withdraw(_tokenAmount, msg.sender);
    }

    function _withdraw(uint256 _tokenAmount, address _withdrawer) internal {
        require(_tokenAmount > 0, 'RewardsPoolBase: cannot withdraw 0');

        UserInfo storage user = userInfo[_withdrawer];

        updateRewardMultipliers(); // Update the accumulated multipliers for everyone
        _updateUserAccruedReward(_withdrawer); // Update the accrued reward for this specific user

        user.amountStaked = user.amountStaked - _tokenAmount;
        totalStaked = totalStaked - _tokenAmount;

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            uint256 totalDebt = (user.amountStaked * accumulatedRewardMultiplier[i]) / PRECISION; // Update user reward debt for each token
            user.rewardDebt[i] = totalDebt;
        }

        emit Withdrawn(_withdrawer, _tokenAmount);

        stakingToken.safeTransfer(address(_withdrawer), _tokenAmount);
    }

    /** @dev Claim all rewards and withdraw all staked tokens. Exits from the rewards pool
     */
    function exit() public virtual {
        _exit(msg.sender);
    }

    function _exit(address exiter) internal {
        UserInfo storage user = userInfo[exiter];

        emit Exited(exiter, user.amountStaked);

        _claim(exiter);
        _withdraw(user.amountStaked, exiter);
    }

    /** @dev Returns the amount of tokens the user has staked
     * @param _userAddress The user to get the balance of
     */
    function balanceOf(address _userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        return user.amountStaked;
    }

    /**
		@dev Updates the accumulated reward multipliers for everyone and each token
	 */
    function updateRewardMultipliers() public {
        uint256 currentTimestamp = block.timestamp;

        if (currentTimestamp > endTimestamp && extensionDuration > 0) {
            _updateRewardMultipliers(endTimestamp);
            _applyExtension(endTimestamp, endTimestamp + extensionDuration, extensionRewardPerSecond);
            _updateRewardMultipliers(currentTimestamp);
        } else {
            _updateRewardMultipliers(currentTimestamp);
        }
    }

    /**
     * @dev updates the accumulated reward multipliers for everyone and each token
     */
    function _updateRewardMultipliers(uint256 _currentTimestamp) internal {
        if (_currentTimestamp <= lastRewardTimestamp) {
            return;
        }

        uint256 applicableTimestamp = (_currentTimestamp < endTimestamp) ? _currentTimestamp : endTimestamp;

        uint256 secondsSinceLastReward = applicableTimestamp - lastRewardTimestamp;

        if (secondsSinceLastReward == 0) {
            return;
        }

        if (totalStaked == 0) {
            lastRewardTimestamp = applicableTimestamp;
            return;
        }

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            uint256 newReward = secondsSinceLastReward * rewardPerSecond[i]; // Get newly accumulated reward
            uint256 rewardMultiplierIncrease = (newReward * PRECISION) / totalStaked; // Calculate the multiplier increase
            accumulatedRewardMultiplier[i] = accumulatedRewardMultiplier[i] + rewardMultiplierIncrease; // Add the multiplier increase to the accumulated multiplier
        }

        lastRewardTimestamp = applicableTimestamp;
    }

    /** @dev Updates the accumulated reward for the user
     * @param _userAddress the address of the updated user
     */
    function _updateUserAccruedReward(address _userAddress) internal {
        UserInfo storage user = userInfo[_userAddress];

        uint256 rewardsTokensLength = rewardsTokens.length;

        if (user.rewardDebt.length == 0) {
            // Initialize user struct

            uint256[] memory empty = new uint256[](rewardsTokensLength);
            user.rewardDebt = empty;
            user.tokensOwed = empty;
        }

        if (user.amountStaked == 0) {
            return;
        }

        for (uint256 tokenIndex = 0; tokenIndex < rewardsTokensLength; tokenIndex++) {
            uint256 totalDebt = (user.amountStaked * accumulatedRewardMultiplier[tokenIndex]) / PRECISION;
            uint256 pendingDebt = totalDebt - user.rewardDebt[tokenIndex];

            if (pendingDebt > 0) {
                user.tokensOwed[tokenIndex] = user.tokensOwed[tokenIndex] + pendingDebt;
                user.rewardDebt[tokenIndex] = totalDebt;
            }
        }
    }

    /**
		@dev Checks if the staking has started
	 */
    function hasStakingStarted() external view returns (bool) {
        return (startTimestamp > 0 && block.timestamp >= startTimestamp);
    }

    /** @dev Returns the amount of reward debt of a specific token and user
     * @param _userAddress the address of the updated user
     * @param _index index of the reward token to check
     */
    function getUserRewardDebt(address _userAddress, uint256 _index) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        return user.rewardDebt[_index];
    }

    /** @dev Returns the amount of reward owed of a specific token and user
     * @param _userAddress the address of the updated user
     * @param _index index of the reward token to check
     */
    function getUserOwedTokens(address _userAddress, uint256 _index) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        return user.tokensOwed[_index];
    }

    /** @dev Calculates the reward at a specific time
     * @param _userAddress the address of the user
     * @param _tokenIndex the index of the reward token you are interested
     * @param _time the time to check the reward at
     */
    function getUserAccumulatedReward(
        address _userAddress,
        uint256 _tokenIndex,
        uint256 _time
    ) external view returns (uint256) {
        uint256 applicableTimestamp = (_time < endTimestamp) ? _time : endTimestamp;
        uint256 secondsSinceLastReward = applicableTimestamp - lastRewardTimestamp;

        uint256 newReward = secondsSinceLastReward * rewardPerSecond[_tokenIndex]; // Get newly accumulated reward
        uint256 rewardMultiplierIncrease = (newReward * PRECISION) / totalStaked; // Calculate the multiplier increase
        uint256 currentMultiplier = accumulatedRewardMultiplier[_tokenIndex] + rewardMultiplierIncrease; // Simulate the multiplier increase to the accumulated multiplier

        UserInfo storage user = userInfo[_userAddress];

        uint256 totalDebt = (user.amountStaked * currentMultiplier) / PRECISION; // Simulate the current debt
        uint256 pendingDebt = totalDebt - user.rewardDebt[_tokenIndex]; // Simulate the pending debt
        return user.tokensOwed[_tokenIndex] + pendingDebt;
    }

    /** @dev Returns the length of the owed tokens in the user info
     */
    function getUserTokensOwedLength(address _userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        return user.tokensOwed.length;
    }

    /** @dev Returns the length of the reward debt in the user info
     */
    function getUserRewardDebtLength(address _userAddress) external view returns (uint256) {
        UserInfo storage user = userInfo[_userAddress];
        return user.rewardDebt.length;
    }

    /** @dev Returns the amount of reward tokens
     */
    function getRewardTokensCount() external view returns (uint256) {
        return rewardsTokens.length;
    }

    /** @dev Returns the amount of previous campaigns
     */
    function getPreviousCampaignsCount() external view returns (uint256) {
        return previousCampaigns.length;
    }

    /**
     * @dev Extends the rewards period and updates the rates. 
     When the current campaign is still going on, the extension will be scheduled and started when the campaign ends.
     The extension can be cancelled until it starts. After it starts, the rewards are locked in and cannot be withdraw.
     * @param _durationTime duration of the campaign (how many seconds the campaign will have)
     * @param _rewardPerSecond array with new rewards per second for each token
     */
    function extend(uint256 _durationTime, uint256[] calldata _rewardPerSecond) external virtual onlyOwner {
        _extend(_durationTime, _rewardPerSecond);
    }

    function _extend(uint256 _durationTime, uint256[] calldata _rewardPerSecond) internal virtual {
        require(extensionDuration == 0, 'RewardsPoolBase: there is already an extension');

        require(_durationTime > 0, 'RewardsPoolBase: duration must be greater than 0');

        uint256 rewardPerSecondLength = _rewardPerSecond.length;
        require(rewardPerSecondLength == rewardsTokens.length, 'RewardsPoolBase: invalid rewardPerSecond');

        uint256 currentTimestamp = block.timestamp;
        bool ended = currentTimestamp > endTimestamp;

        uint256 newStartTimestamp = ended ? currentTimestamp : endTimestamp;
        uint256 newEndTimestamp = newStartTimestamp + _durationTime;

        for (uint256 i = 0; i < rewardPerSecondLength; i++) {
            uint256 newRewards = calculateRewardsAmount(newStartTimestamp, newEndTimestamp, _rewardPerSecond[i]);

            // We need to check if we have enough balance available in the contract to pay for the extension
            uint256 availableBalance = getAvailableBalance(i);

            require(availableBalance >= newRewards, 'RewardsPoolBase: not enough rewards to extend');
        }

        if (ended) {
            _updateRewardMultipliers(endTimestamp);
            _applyExtension(newStartTimestamp, newEndTimestamp, _rewardPerSecond);
        } else {
            extensionDuration = _durationTime;
            extensionRewardPerSecond = _rewardPerSecond;
        }
    }

    function _applyExtension(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256[] memory _rewardPerSecond
    ) internal {
        uint256 rewardPerSecondLength = rewardPerSecond.length;
        for (uint256 i = 0; i < rewardPerSecondLength; i++) {
            uint256 spentRewards = calculateRewardsAmount(startTimestamp, endTimestamp, rewardPerSecond[i]);
            totalSpentRewards[i] = totalSpentRewards[i] + spentRewards;
        }

        previousCampaigns.push(Campaign(startTimestamp, endTimestamp, rewardPerSecond));

        rewardPerSecond = _rewardPerSecond;
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        lastRewardTimestamp = _startTimestamp;

        extensionDuration = 0;
        delete extensionRewardPerSecond;

        emit Extended(_startTimestamp, _endTimestamp, _rewardPerSecond);
    }

    /**
     * @dev Cancels the schedules extension
     */
    function cancelExtension() external virtual onlyOwner {
        _cancelExtension();
    }

    function _cancelExtension() internal {
        require(extensionDuration > 0, 'RewardsPoolBase: there is no extension scheduled');
        require(block.timestamp < endTimestamp, 'RewardsPoolBase: cannot cancel extension after it has started');

        extensionDuration = 0;
        delete extensionRewardPerSecond;
    }

    /**
     *@dev Calculates the available amount of reward tokens that are not locked
     *@param _rewardTokenIndex the index of the reward token to check
     */
    function getAvailableBalance(uint256 _rewardTokenIndex) public view returns (uint256) {
        address rewardToken = rewardsTokens[_rewardTokenIndex];
        uint256 balance = IERC20(rewardToken).balanceOf(address(this));

        if (startTimestamp == 0) {
            return balance;
        }

        uint256 spentRewards = calculateRewardsAmount(startTimestamp, endTimestamp, rewardPerSecond[_rewardTokenIndex]);

        if (extensionDuration > 0) {
            uint256 spentExtensionRewards = calculateRewardsAmount(
                endTimestamp,
                endTimestamp + extensionDuration,
                extensionRewardPerSecond[_rewardTokenIndex]
            );

            spentRewards = spentRewards + spentExtensionRewards;
        }

        uint256 availableBalance = balance -
            (totalSpentRewards[_rewardTokenIndex] + spentRewards - totalClaimed[_rewardTokenIndex]);

        if (rewardToken == address(stakingToken)) {
            availableBalance = availableBalance - totalStaked;
        }

        return availableBalance;
    }

    /** @dev Withdraw tokens other than the staking and reward token, for example rewards from liquidity mining
     * @param _recipient The address to whom the rewards will be transferred
     * @param _token The address of the rewards contract
     */
    function withdrawTokens(address _recipient, address _token) external onlyOwner {
        uint256 currentReward = IERC20(_token).balanceOf(address(this));
        require(currentReward > 0, 'RewardsPoolBase: no rewards');

        require(_token != address(stakingToken), 'RewardsPoolBase: cannot withdraw staking token');

        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            require(_token != rewardsTokens[i], 'RewardsPoolBase: cannot withdraw reward token');
        }

        IERC20(_token).safeTransfer(_recipient, currentReward);
    }

    /** @dev Withdraw excess rewards not needed for current campaign and extension
     * @param _recipient The address to whom the rewards will be transferred
     */
    function withdrawExcessRewards(address _recipient) external onlyOwner {
        uint256 rewardsTokensLength = rewardsTokens.length;

        for (uint256 i = 0; i < rewardsTokensLength; i++) {
            uint256 balance = getAvailableBalance(i);

            if (balance > 0) {
                IERC20(rewardsTokens[i]).safeTransfer(_recipient, balance);
            }
        }
    }

    /** @dev Calculates the amount of rewards given in a specific period
     * @param _startTimestamp The start time of the period
     * @param _endTimestamp The end time of the period
     * @param _rewardPerSecond The reward per second
     */
    function calculateRewardsAmount(
        uint256 _startTimestamp,
        uint256 _endTimestamp,
        uint256 _rewardPerSecond
    ) internal pure returns (uint256) {
        uint256 rewardsPeriodSeconds = _endTimestamp - _startTimestamp;
        return _rewardPerSecond * rewardsPeriodSeconds;
    }
}