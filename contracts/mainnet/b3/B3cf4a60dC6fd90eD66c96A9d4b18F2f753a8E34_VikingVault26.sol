// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Fees.sol";
 
contract VikingVault26 is Context, Ownable, Fees {
    using SafeERC20 for IERC20;

    /// @notice enum Status contains multiple status.
    enum Status { Collecting, Staking, Completed }

    struct VaultInfo {
        Status status; // vault status
        uint256 stakingPeriod; // the timestamp length of staking vault.
        uint256 startTimestamp;  // timestamp when the vault start accouring rewards.
        uint256 stopTimestamp; // the timestamp to end the staking vault.
        uint256 totalVaultShares; // total stakeholder tokens deposited into Vault.
        uint256 totalVaultRewards; // amount of tokens to reward this vault.
    }

    struct RewardInfo {
        uint256 lastRewardUpdateTimeStamp;
        uint256 rewardRate; // rewardRate is totalVaultRewards / stakingPeriod.
        uint256 pendingVaultRewards; // the rewards pending so far. 
        uint256 claimedVaultRewards; // claimed rewards for the vault.
        uint256 remainingVaultRewards; // remaining rewards for this vault.        
    }
    
    IERC20 public token;
    VaultInfo public vault;
    RewardInfo private _reward;
    mapping(address => uint256) private _balances;

    error NotAuthorized();
    error NoZeroValues();
    error MaxStaked();
    error AddRewardsFailed();
    error DepositFailed();
    error RewardFailed();
    error WithdrawFailed();
    error NotCollecting();  
    error NotStaking();
    error NotCompleted();

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount, uint256 rewards);
    event StakingStarted();
    event StakingCompleted();

    /// @notice modifier checks if a user is staking.
    /// @param account The account address to check.
    modifier isStakeholder(address account) {
        if (_balances[account] == 0) revert NotAuthorized();
        _;
    }

    /// @notice modifier checks that contract is in status Collecting.
    modifier isCollecting() {
        if (vault.status != Status.Collecting) revert NotCollecting();
        _;
    }

    /// @notice modifier checks that contract has status Staking.
    modifier isStaking() {
        if (vault.status != Status.Staking) revert NotStaking();
        _;
    }

    /// @notice modifier checks that contract has status Completed.
    modifier isCompleted() {
        if (vault.status != Status.Completed) revert NotCompleted();
        _;
    }

    /// @notice modifier checks for zero values.
    /// @param amount The user amount to deposit in Wei.
    modifier noZeroValues(uint256 amount) {
        if (_msgSender() == address(0) || amount <= 0) revert NoZeroValues();
        _;
    }

    /// @notice modifier sets a max limit to 1 million tokens staked per user.
    modifier limiter(uint256 amount) {
        uint256 balance = _balances[_msgSender()];
        uint256 totalBalance = balance + amount;
        if (totalBalance > 1000000000000000000000000) revert MaxStaked();
        _;
    }

    /// @notice modifier updates the vault reward stats.
    modifier updateVaultRewards() {
        require(_reward.remainingVaultRewards > 0);
        
        uint256 _currentValue = _reward.rewardRate * (block.timestamp - _reward.lastRewardUpdateTimeStamp);
        _reward.pendingVaultRewards += _currentValue;
        _reward.remainingVaultRewards -= _currentValue;
        _reward.lastRewardUpdateTimeStamp = block.timestamp;
        _;
    }

    /// @notice Constructor for VikingVault, staking contract.
    /// @param Token The token used for staking.
    constructor(address Token) {
        token = IERC20(Token);
        feeAddress = _msgSender();
        vault.stakingPeriod = 26 weeks; // 6 months staking period.
        withdrawFeePeriod = vault.stakingPeriod; // 6 months fee period.
        withdrawPenaltyPeriod = 4 weeks; // 4 weeks penalty period.
        withdrawFee = 700; // 7% withdraw fee.
        vault.status = Status.Collecting; 
    }   

    /// @notice receive function reverts and returns the funds to the sender.
    receive() external payable {
        revert("not payable receive");
    }

/// ------------------------------- PUBLIC METHODS -------------------------------

    /// Method to get the users erc20 balance.
    /// @param account The account of the user to check.
    /// @return user erc20 balance.
    function getAccountErc20Balance(address account) external view returns (uint256) {
        return token.balanceOf(account);
    }

    /// Method to get the users vault balance.
    /// @param account The account of the user to check.
    /// @return user balance staked in vault.
    function getAccountVaultBalance(address account) external view returns (uint256) {
        return _balances[account];
    }

    /// Method to get the vaults RewardInfo.
    function getRewardInfo() external view returns (
        uint256 lastRewardUpdateTimeStamp,
        uint256 rewardRate, 
        uint256 pendingVaultRewards,
        uint256 claimedVaultRewards, 
        uint256 remainingVaultRewards
    ) {
        return (
            _reward.lastRewardUpdateTimeStamp,
            _reward.rewardRate,
            _reward.pendingVaultRewards,
            _reward.claimedVaultRewards,
            _reward.remainingVaultRewards);
    }

    /// @notice Method to let a user deposit funds into the vault.
    /// @param amount The amount to be staked.
    function deposit(uint256 amount) external isCollecting limiter(amount) noZeroValues(amount) {
        _balances[_msgSender()] += amount;
        vault.totalVaultShares += amount;
        if (!_deposit(_msgSender(), amount)) revert DepositFailed();
        emit Deposit(_msgSender(), amount);
    }
    
    /// @notice Lets a user exit their position while status is Collecting. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Collecting.
    function exitWhileCollecting() external isStakeholder(_msgSender()) isCollecting {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _contractAmount, uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);
        vault.totalVaultShares -= _totalUserShares;
        
        // Pay 7% withdrawFee before withdraw.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(creator), _contractAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();

        emit ExitWithFees(_msgSender(), _withdrawAmount);
    }

    /// @notice Lets a user exit their position while staking. 
    /// @notice ATT. The user is subject to an 7% early withdraw fee.
    /// @dev Can only be executed while status is Staking.
    function exitWhileStaking() external isStakeholder(_msgSender()) isStaking updateVaultRewards {
        require(_msgSender() != address(0), "Not zero address");

        uint256 _totalUserShares = _balances[_msgSender()];
        delete _balances[_msgSender()];

        (uint256 _contractAmount, uint256 _feeAmount, uint256 _withdrawAmount) = super._calculateFee(_totalUserShares);

        // if withdrawPenaltyPeriod is over, calculate user rewards.
        if (block.timestamp >= (vault.startTimestamp + withdrawPenaltyPeriod)) {
            uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
            _withdrawAmount += _pendingUserReward;

            _reward.pendingVaultRewards -= _pendingUserReward;
            _reward.remainingVaultRewards -= _pendingUserReward;
            _reward.claimedVaultRewards += _pendingUserReward;
        }
        vault.totalVaultShares -= _totalUserShares;

        // Pay 7% in withdrawFee before the withdraw is transacted.
        if (!_withdraw(address(feeAddress), _feeAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(creator), _contractAmount)) revert ExitFeesFailed();
        if (!_withdraw(address(_msgSender()), _withdrawAmount)) revert WithdrawFailed();

        emit ExitWithFees(_msgSender(), _withdrawAmount);
    }

    /// @notice Let the user remove their stake and receive the accumulated rewards, without paying extra fees.
    function withdraw() external isStakeholder(_msgSender()) isCompleted {
        require(_msgSender() != address(0), "Not zero adress");
        
        uint256 _totalUserShares =  _balances[_msgSender()];
        delete _balances[_msgSender()];
    
        uint256 _pendingUserReward = _calculateUserReward(_totalUserShares);
        
        _reward.pendingVaultRewards -= _pendingUserReward;
        _reward.claimedVaultRewards += _pendingUserReward;
        vault.totalVaultShares -= _totalUserShares;

        if (!_withdraw(_msgSender(), _pendingUserReward)) revert RewardFailed();
        if (!_withdraw(_msgSender(), _totalUserShares)) revert WithdrawFailed();
        

        emit Withdraw(_msgSender(), _totalUserShares, _pendingUserReward);
    }

/// ------------------------------- ADMIN METHODS -------------------------------

    /// @notice Add reward amount to the vault.
    /// @param amount The amount to deposit in Wei.
    /// @dev Restricted to onlyOwner.  
    function addRewards(uint256 amount) external onlyOwner {
        if (!_deposit(_msgSender(), amount)) revert AddRewardsFailed();
        
        vault.totalVaultRewards += amount;
        _reward.rewardRate = (vault.totalVaultRewards / vault.stakingPeriod);
        _reward.remainingVaultRewards += amount;
    }

    /// @notice Sets the contract status to Staking.
    function startStaking() external isCollecting onlyOwner {
        vault.status = Status.Staking;
        vault.startTimestamp = block.timestamp;
        vault.stopTimestamp = vault.startTimestamp + vault.stakingPeriod;
        _reward.lastRewardUpdateTimeStamp = vault.startTimestamp;

        emit StakingStarted();
    }

    /// @notice Sets the contract status to Completed.
    /// @dev modifier updateVaultRewards is called before status is set to Completed.
    function stopStaking() external isStaking onlyOwner {
        vault.status = Status.Completed;
        _reward.pendingVaultRewards += _reward.remainingVaultRewards;
        _reward.remainingVaultRewards = 0;
        emit StakingCompleted();
    }

    /// @notice Withdraw unexpected tokens sent to the VikingVault
    function inCaseTokensGetStuck(address _token) external {
        require(_msgSender() == address(creator), "code 0");
        require(_token != address(token), "code 1");

        uint256 amount = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(address(creator), amount);
    }
    
/// ------------------------------- PRIVATE METHODS -------------------------------

    /// @notice Internal function to deposit funds to vault.
    /// @param _from The from address that deposits the funds.
    /// @param _amount The amount to be deposited in Wei.
    /// @return true if valid.
    function _deposit(address _from, uint256 _amount) private returns (bool) {
        token.safeTransferFrom(_from, address(this), _amount);
        return true;
    }
 
    /// @notice Internal function to withdraw funds from the vault.
    /// @param _to The address that receives the withdrawn funds.
    /// @param _amount The amount to be withdrawn.
    /// @return true if valid.
    function _withdraw(address _to, uint256 _amount) private returns (bool){
        token.safeTransfer(_to, _amount);
        return true;
    }

    /// @notice Internal function to calculate the pending user rewards.
    /// @param _totalUserShares The total amount deposited to vault by user.
    /// @return pending user reward amount.
    function _calculateUserReward(uint256 _totalUserShares) private view returns (uint256) {
        require(_reward.pendingVaultRewards > 0, "No pending rewards");
        
        uint256 _userPercentOfVault = _totalUserShares * 100 / vault.totalVaultShares;
        uint256 _pendingUserReward = _reward.pendingVaultRewards * _userPercentOfVault / 100;

        return _pendingUserReward;
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Fees is Ownable {

    address internal creator = 0x0c051a1f4E209b00c8E7C00AD0ce79B3630a7401;
    address public feeAddress; // defaults to the Owner account.

    uint256 private creatorFee = 10;
    uint256 internal withdrawFeePeriod;
    uint256 internal withdrawPenaltyPeriod;
    uint256 internal withdrawFee;
 
    error ExitFeesFailed();
    
    event ExitWithFees(address indexed user, uint256 amount);

    /// @notice Internal function to calculate the early withdraw fees.
    /// @notice return contarctAmount, feeAmount and withdrawAmount.
    function _calculateFee(uint256 _amount) 
        internal 
        view 
        returns (
            uint256 contractAmount,
            uint256 feeAmount,
            uint256 withdrawAmount
        ) 
    {
        uint256 totFee = _amount * withdrawFee / 10000;
        
        contractAmount = totFee * creatorFee /10000;
        feeAmount = totFee - contractAmount;
        withdrawAmount = _amount - totFee; 
    }

    /// @notice Admin function to set a new fee address.
    function setFeeAddress(address _newFeeAddress) external onlyOwner {
        feeAddress = _newFeeAddress;
    }
    /// @notice Admin function to set a new withdraw fee.
    /// @notice example: 50 = 0.5%, 100 = 1%, 200 = 2%, 1000 = 10%.
    function setWithdrawFee(uint256 _newWithdrawFee) external onlyOwner {
        withdrawFee = _newWithdrawFee;
    }

    /// @notice Function returns the current withdraw fee.
    function getWithdrawFee() external view returns (uint256){
        return withdrawFee;
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