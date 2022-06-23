/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

//SPDX-License-Identifier: MIT

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


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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


pragma solidity 0.8.15;


// Definition of custom errors
error AmountLessThanStakedAmountOrZero();
error CallerNotGovernance();
error EtherNotAccepted();
error InputLengthMismatch();
error InsufficientFunds();
error NoPendingRewardsToClaim();
error NoStakeFound();
error RewardDistributionPeriodHasExpired();
error RewardPerBlockIsNotSet();
error ZeroAddress();
error ZeroInput();

/// @title Unipilot Staking
/// @notice Contract for staking Unipilot to earn rewards

contract UnipilotStaking {
    using SafeERC20 for IERC20Metadata;

    // Info of each user
    struct UserInfo {
        address rewardToken; // Should hold address of the current reward token - used to reset user reward debt
        uint256 amount; // Amount of pilot tokens staked by the user
        uint256 rewardDebt; // Reward debt
    }

    // To determine transaction type
    enum TxType {
        STAKE,
        UNSTAKE,
        CLAIM,
        EMERGENCY
    }

    // Address of the pilot token
    IERC20Metadata public immutable pilotToken;

    // Address of the reward token
    IERC20Metadata public rewardToken;

    // Address of the governance
    address public governance;

    // Precision factor for multiple calculations
    uint256 public constant ONE = 1e18;

    // Accumulated reward per pilot token
    uint256 public accRewardPerPilot;

    // Last update block for rewards
    uint256 public lastUpdateBlock;

    // Total pilot tokens staked
    uint256 public totalPilotStaked;

    // Reward to distribute per block
    uint256 public currentRewardPerBlock;

    // Current end block for the current reward period
    uint256 public periodEndBlock;

    // Info of each user that stakes Pilot tokens
    mapping(address => UserInfo) public userInfo;

    event StakeOrUnstakeOrClaim(
        address indexed user,
        uint256 amount,
        uint256 pendingReward,
        TxType txType
    );
    event NewRewardPeriod(
        uint256 numberBlocksToDistributeRewards,
        uint256 newRewardPerBlock,
        uint256 rewardToDistribute,
        uint256 rewardExpirationBlock
    );
    event GovernanceChanged(
        address indexed oldGovernance,
        address indexed newGovernance
    );
    event RewardTokenChanged(
        address indexed oldRewardToken,
        address indexed newRewardToken
    );
    event FundsMigrated(
        address indexed _newVersion,
        IERC20Metadata[] _tokens,
        uint256[] _amounts
    );

    /**
     * @notice Constructor
     * @param _governance governance address of unipilot staking
     * @param _rewardToken address of the reward token
     * @param _pilotToken address of the pilot token
     */
    constructor(
        address _governance,
        address _rewardToken,
        address _pilotToken
    ) {
        if (
            _governance == address(0) ||
            _rewardToken == address(0) ||
            _pilotToken == address(0)
        ) {
            revert ZeroAddress();
        }
        governance = _governance;
        rewardToken = IERC20Metadata(_rewardToken);
        pilotToken = IERC20Metadata(_pilotToken);
        emit GovernanceChanged(address(0), _governance);
        emit RewardTokenChanged(address(0), _rewardToken);
    }

    /**
     * @dev Throws if ether is received
     */
    receive() external payable {
        revert EtherNotAccepted();
    }

    /**
     * @dev Throws if called by any account other than the governance
     */
    modifier onlyGovernance() {
        if (msg.sender != governance) {
            revert CallerNotGovernance();
        }
        _;
    }

    /**
     * @notice Updates the governance of this contract
     * @param _newGovernance address of the new governance of this contract
     * @dev Only callable by Governance
     */
    function setGovernance(address _newGovernance) external onlyGovernance {
        if (_newGovernance == address(0)) {
            revert ZeroAddress();
        }
        emit GovernanceChanged(governance, _newGovernance);
        governance = _newGovernance;
    }

    /**
     * @notice Updates the reward token.
     * @param _newRewardToken address of the new reward token
     * @dev Only callable by Governance. It also resets reward distribution accounting
     */
    function updateRewardToken(address _newRewardToken)
        external
        onlyGovernance
    {
        if (_newRewardToken == address(0)) {
            revert ZeroAddress();
        }

        // Resetting reward distribution accounting
        accRewardPerPilot = 0;
        lastUpdateBlock = _lastRewardBlock();

        emit RewardTokenChanged(address(rewardToken), _newRewardToken);

        // Updating reward token address
        rewardToken = IERC20Metadata(_newRewardToken);
    }

    /**
     * @notice Updates the reward per block
     * @param _reward total reward to distribute
     * @param _rewardDurationInBlocks total number of blocks in which the '_reward' should be distributed
     * @dev Only callable by Governance. Enter both params in decimal format
     */
    function updateRewards(uint256 _reward, uint256 _rewardDurationInBlocks)
        external
        onlyGovernance
    {
        if (_rewardDurationInBlocks == 0) {
            revert ZeroInput();
        }

        // Update reward distribution accounting
        _updateRewardPerPilotAndLastBlock();

        // Adjust the current reward per block
        // If reward distribution duration is expired
        if (block.number >= periodEndBlock) {
            if (_reward == 0) {
                revert ZeroInput();
            }

            // Upscaling '_reward' to 18 decimals before calculating 'currentRewardPerBlock'
            currentRewardPerBlock = (_reward * ONE) / _rewardDurationInBlocks;
        }
        // Otherwise, reward distribution duration isn't expired
        else {
            // Upscaling '_reward' to 18 decimals before calculating 'currentRewardPerBlock'
            currentRewardPerBlock =
                ((_reward * ONE) +
                    ((periodEndBlock - block.number) * currentRewardPerBlock)) /
                _rewardDurationInBlocks;
        }

        // Setting rewards expiration block
        periodEndBlock = block.number + _rewardDurationInBlocks;

        emit NewRewardPeriod(
            _rewardDurationInBlocks,
            currentRewardPerBlock,
            _reward,
            periodEndBlock
        );
    }

    /**
     * @notice Updates the reward distribution duration end block
     * @param _expireDurationInBlocks number of blocks after which reward distribution should be halted
     * @dev Only callable by Governance
     */
    function updateRewardEndBlock(uint256 _expireDurationInBlocks)
        external
        onlyGovernance
    {
        periodEndBlock = block.number + _expireDurationInBlocks;
    }

    /**
     * @notice Migrates the funds to another address.
     * @param _newVersion receiver address of the funds
     * @param _tokens list of token addresses
     * @param _amounts list of funds amount
     * @dev Only callable by Governance.
     */
    function migrateFunds(
        address _newVersion,
        IERC20Metadata[] calldata _tokens,
        uint256[] calldata _amounts
    ) external onlyGovernance {
        if (_newVersion == address(0)) {
            revert ZeroAddress();
        }

        if (_tokens.length != _amounts.length) {
            revert InputLengthMismatch();
        }

        // Declaring outside the loop to save gas
        IERC20Metadata tokenAddress;
        uint256 amount;

        for (uint256 i; i < _tokens.length; ) {
            // Local copy to save gas
            tokenAddress = _tokens[i];
            amount = _amounts[i];

            if (address(tokenAddress) == address(0)) {
                revert ZeroAddress();
            }

            if (amount == 0) {
                revert ZeroInput();
            }

            if (amount > tokenAddress.balanceOf(address(this))) {
                revert InsufficientFunds();
            }

            tokenAddress.safeTransfer(_newVersion, amount);
            unchecked {
                ++i;
            }
        }
        emit FundsMigrated(_newVersion, _tokens, _amounts);
    }

    /**
     * @notice Stake pilot tokens. Also triggers a claim.
     * @param _amount amount of pilot tokens to stake
     */
    function stake(uint256 _amount) external {
        if (_amount == 0) {
            revert ZeroInput();
        }

        if (currentRewardPerBlock == 0) {
            revert RewardPerBlockIsNotSet();
        }

        if (block.number >= periodEndBlock) {
            revert RewardDistributionPeriodHasExpired();
        }

        if (rewardToken.balanceOf(address(this)) == 0) {
            revert InsufficientFunds();
        }

        _stakeOrUnstakeOrClaim(_amount, TxType.STAKE);
    }

    /**
     * @notice Unstake pilot tokens. Also triggers a reward claim.
     * @param _amount amount of pilot tokens to unstake
     */
    function unstake(uint256 _amount) external {
        if ((_amount > userInfo[msg.sender].amount) || _amount == 0) {
            revert AmountLessThanStakedAmountOrZero();
        }
        _stakeOrUnstakeOrClaim(_amount, TxType.UNSTAKE);
    }

    /**
     * @notice Unstake all staked pilot tokens without caring about rewards, EMERGENCY ONLY
     */
    function emergencyUnstake() external {
        if (userInfo[msg.sender].amount > 0) {
            _stakeOrUnstakeOrClaim(
                userInfo[msg.sender].amount,
                TxType.EMERGENCY
            );
        } else {
            revert NoStakeFound();
        }
    }

    /**
     * @notice Claim pending rewards.
     */
    function claim() external {
        _stakeOrUnstakeOrClaim(userInfo[msg.sender].amount, TxType.CLAIM);
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param _user address of the user
     * @return pending rewards of the user
     */
    function calculatePendingRewards(address _user)
        external
        view
        returns (uint256)
    {
        uint256 newAccRewardPerPilot;

        if (totalPilotStaked != 0) {
            newAccRewardPerPilot =
                accRewardPerPilot +
                (((_lastRewardBlock() - lastUpdateBlock) *
                    (currentRewardPerBlock * ONE)) / totalPilotStaked);
            // If checking user pending rewards in the block in which reward token is updated
            if (newAccRewardPerPilot == 0) {
                return 0;
            }
        } else {
            return 0;
        }

        uint256 rewardDebt = userInfo[_user].rewardDebt;

        // Reset debt if user is checking rewards after reward token changed
        if (userInfo[_user].rewardToken != address(rewardToken)) {
            rewardDebt = 0;
        }

        uint256 pendingRewards = ((userInfo[_user].amount *
            newAccRewardPerPilot) / ONE) - rewardDebt;

        // Downscale if reward token has less than 18 decimals
        if (_computeScalingFactor(rewardToken) != 1) {
            // Downscaling pending rewards before transferring to the user
            pendingRewards = _downscale(pendingRewards);
        }
        return pendingRewards;
    }

    /**
     * @notice Return last block where trading rewards were distributed
     */
    function lastRewardBlock() external view returns (uint256) {
        return _lastRewardBlock();
    }

    /**
     * @notice Stake/ Unstake pilot tokens and also distributes reward
     * @param _amount amount of pilot tokens to stake or unstake. 0 if claim tx.
     * @param _txType type of the transaction
     */
    function _stakeOrUnstakeOrClaim(uint256 _amount, TxType _txType) private {
        // Update reward distribution accounting
        _updateRewardPerPilotAndLastBlock();

        // Reset debt if reward token has changed
        _resetDebtIfNewRewardToken();

        UserInfo storage user = userInfo[msg.sender];

        uint256 pendingRewards;

        // Distribute rewards if not emergency unstake
        if (TxType.EMERGENCY != _txType) {
            // Distribute rewards if not new stake
            if (user.amount > 0) {
                // Calculate pending rewards
                pendingRewards = _calculatePendingRewards(msg.sender);

                // Downscale if reward token has less than 18 decimals
                if (_computeScalingFactor(rewardToken) != 1) {
                    // Downscaling pending rewards before transferring to the user
                    pendingRewards = _downscale(pendingRewards);
                }

                // If there are rewards to distribute
                if (pendingRewards > 0) {
                    if (pendingRewards > rewardToken.balanceOf(address(this))) {
                        revert InsufficientFunds();
                    }

                    // Transferring rewards to the user
                    rewardToken.safeTransfer(msg.sender, pendingRewards);
                }
                // If there are no pending rewards and tx is of claim then revert
                else if (TxType.CLAIM == _txType) {
                    revert NoPendingRewardsToClaim();
                }
            }
            // Claiming rewards without any stake
            else if (TxType.CLAIM == _txType) {
                revert NoPendingRewardsToClaim();
            }
        }

        if (TxType.STAKE == _txType) {
            // Transfer Pilot tokens to this contract
            pilotToken.safeTransferFrom(msg.sender, address(this), _amount);

            // Increase user pilot staked amount
            user.amount += _amount;

            // Increase total pilot staked amount
            totalPilotStaked += _amount;
        } else if (TxType.UNSTAKE == _txType || TxType.EMERGENCY == _txType) {
            // Decrease user pilot staked amount
            user.amount -= _amount;

            // Decrease total pilot staked amount
            totalPilotStaked -= _amount;

            // Transfer Pilot tokens back to the sender
            pilotToken.safeTransfer(msg.sender, _amount);
        }

        // Adjust user debt
        user.rewardDebt = (user.amount * accRewardPerPilot) / ONE;

        emit StakeOrUnstakeOrClaim(
            msg.sender,
            _amount,
            pendingRewards,
            _txType
        );
    }

    /**
     * @notice Resets user reward debt if reward token has changed
     */
    function _resetDebtIfNewRewardToken() private {
        // Reset debt if user reward token is different than current reward token
        if (userInfo[msg.sender].rewardToken != address(rewardToken)) {
            // Don't reset debt if reward token is null as it indicates that reward token hasn't changed since contract deployment
            if (userInfo[msg.sender].rewardToken != address(0)) {
                userInfo[msg.sender].rewardDebt = 0;
            }
            userInfo[msg.sender].rewardToken = address(rewardToken);
        }
    }

    /**
     * @notice Updates accumulated reward to distribute per pilot token. Also updates the last block in which rewards are distributed
     */
    function _updateRewardPerPilotAndLastBlock() private {
        if (totalPilotStaked == 0) {
            lastUpdateBlock = block.number;
            return;
        }

        accRewardPerPilot +=
            ((_lastRewardBlock() - lastUpdateBlock) *
                (currentRewardPerBlock * ONE)) /
            totalPilotStaked;

        if (block.number != lastUpdateBlock) {
            lastUpdateBlock = _lastRewardBlock();
        }
    }

    /**
     * @notice Calculate pending rewards for a user
     * @param _user address of the user
     */
    function _calculatePendingRewards(address _user)
        private
        view
        returns (uint256)
    {
        return
            ((userInfo[_user].amount * accRewardPerPilot) / ONE) -
            userInfo[_user].rewardDebt;
    }

    /**
     * @notice Return last block where rewards must be distributed
     */
    function _lastRewardBlock() private view returns (uint256) {
        return block.number < periodEndBlock ? block.number : periodEndBlock;
    }

    /**
     * @notice Returns a scaling factor that, when multiplied to a token amount for `token`, normalizes its balance as if
     * it had 18 decimals.
     */
    function _computeScalingFactor(IERC20Metadata _token)
        private
        view
        returns (uint256)
    {
        // Tokens that don't implement the `decimals` method are not supported.
        uint256 tokenDecimals = _token.decimals();

        // Tokens with more than 18 decimals are not supported.
        uint256 decimalsDifference = 18 - tokenDecimals;
        return 10**decimalsDifference;
    }

    /**
     * @notice Reverses the upscaling applied to `amount`, resulting in a smaller or equal value depending on
     * whether it needed scaling or not
     */
    function _downscale(uint256 _amount) private view returns (uint256) {
        return _amount / _computeScalingFactor(rewardToken);
    }
}