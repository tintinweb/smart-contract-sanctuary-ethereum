// SPDX-License-Identifier: MIT
// Creator: andreitoma8
pragma solidity ^0.8.4;

import "Ownable.sol";
import "Pausable.sol";
import "IERC20.sol";

interface IToken is IERC20 {
    function mintForRewards(address to, uint256 amount) external;
}

contract Staking is Ownable, Pausable {
    // Address and Interface to the Token
    IToken public token;

    // Minimum amount to stake
    uint256 public minStake = 100 * 10**18;

    // Flexible stake rewards per hour. A fraction calculated as x/10.000.000 to get the percentage
    uint256 public flexStakeRPH = 23; // 0.00022%/h or 2.156% APR

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public threeMonthsRPL = 75; // 0.75% (or 3% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public sixMonthsRPL = 200; // 2% (or 4% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public twelveMonthsRPL = 600; // 50% (or 6% APR)

    // Three months lock rewards as % with 2 decimals(10% = 1000)
    uint256 public twentyFourMonthsRPL = 1600; // 16% (or 8% APR)

    // Total amount of tokens staked
    uint256 public totalTokensStaked;

    // Total rewards paid trough staking
    uint256 public totalRewardsPaid;

    // Stake Types
    enum StakeType {
        THREE_MONTHS,
        SIX_MONTHS,
        TWELVE_MONTHS,
        TWENTY_FOUR_MONTHS
    }

    // Staker info struct
    struct Staker {
        // The deposited tokens of the Staker
        uint256 deposited;
        // Last time of details update for Deposit
        uint256 timeOfLastUpdate;
        // Calculated, but unclaimed rewards. These are calculated each time
        // a user writes to the contract.
        uint256 unclaimedRewards;
        // Time when pople can withdraw with rewards
        uint256 timeOfRewardsEligibility;
    }

    // Struct for token lock info
    struct TokenLock {
        uint256 timeOfUnlock;
        uint256 amount;
        StakeType typeOfStake;
        uint256 rewards;
    }

    // Mapping of staker address to staker info
    mapping(address => Staker) public stakers;

    // Mapping of address to token locks
    mapping(address => TokenLock[]) public userLocks;

    constructor(IToken _token) {
        token = _token;
    }

    // If address has no Staker struct, initiate one. If address already has a stake,
    // calculate the rewards and add them to unclaimedRewards, reset the last time of
    // deposit and then add _amount to the already deposited amount.
    // Receive the amount staked.
    function stake(uint256 _amount) external whenNotPaused {
        require(_amount >= minStake, "Amount smaller than minimimum deposit");
        require(
            token.balanceOf(msg.sender) >= _amount,
            "Can't stake more than you own"
        );
        if (stakers[msg.sender].deposited == 0) {
            stakers[msg.sender].deposited = _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
            stakers[msg.sender].unclaimedRewards = 0;
            stakers[msg.sender].timeOfRewardsEligibility =
                block.timestamp +
                1209600;
        } else {
            uint256 rewards = calculateRewards(msg.sender);
            stakers[msg.sender].unclaimedRewards += rewards;
            stakers[msg.sender].deposited += _amount;
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        token.transferFrom(msg.sender, address(this), _amount);
        totalTokensStaked += _amount;
    }

    // Compound the rewards and reset the last time of update for Deposit info
    function stakeRewards() external whenNotPaused {
        require(
            block.timestamp > stakers[msg.sender].timeOfRewardsEligibility,
            "Two weeks have not passed from your first stake"
        );
        require(stakers[msg.sender].deposited > 0, "You have no deposit");
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].deposited += rewards;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        token.mintForRewards(address(this), rewards);
        totalTokensStaked += rewards;
    }

    // Mint rewards for msg.sender
    function claimRewards() external {
        require(
            block.timestamp > stakers[msg.sender].timeOfRewardsEligibility,
            "Two weeks have not passed from your first stake"
        );
        uint256 rewards = calculateRewards(msg.sender) +
            stakers[msg.sender].unclaimedRewards;
        require(rewards > 0, "You have no rewards");
        stakers[msg.sender].unclaimedRewards = 0;
        stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        token.mintForRewards(msg.sender, rewards);
        totalRewardsPaid += rewards;
    }

    // Withdraw specified amount of staked tokens
    function withdraw(uint256 _amount) external {
        require(
            stakers[msg.sender].deposited >= _amount,
            "Can't withdraw more than you have"
        );
        uint256 _rewards = calculateRewards(msg.sender);
        stakers[msg.sender].deposited -= _amount;
        if (_amount == stakers[msg.sender].deposited) {
            stakers[msg.sender].timeOfLastUpdate = 0;
        } else {
            stakers[msg.sender].timeOfLastUpdate = block.timestamp;
        }
        stakers[msg.sender].unclaimedRewards = _rewards;
        token.transfer(msg.sender, _amount);
        totalTokensStaked -= _amount;
    }

    // Lock tokens to gain a better APR
    // User can select a amount to lock and a period to lock for
    function lockTokens(uint256 _amount, StakeType _stakeType)
        external
        whenNotPaused
    {
        TokenLock memory _lock;
        _lock.amount = _amount;
        _lock.typeOfStake;
        if (_stakeType == StakeType.THREE_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 7889231;
            _lock.rewards = (_amount * threeMonthsRPL) / 10000;
        } else if (_stakeType == StakeType.SIX_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 15778463;
            _lock.rewards = (_amount * sixMonthsRPL) / 10000;
        } else if (_stakeType == StakeType.TWELVE_MONTHS) {
            _lock.timeOfUnlock = block.timestamp + 31556926;
            _lock.rewards = (_amount * twelveMonthsRPL) / 10000;
        } else {
            _lock.timeOfUnlock = block.timestamp + 63113852;
            _lock.rewards = (_amount * twentyFourMonthsRPL) / 10000;
        }
        userLocks[msg.sender].push(_lock);
        token.transferFrom(msg.sender, address(this), _amount);
        totalTokensStaked += _amount;
    }

    // Users can unlock their deposits after the locked time and get the rewards
    // or can unlock their deposits before, without getting any rewards
    function unlockTokens(uint256 _tokenLockIndex) external {
        require(
            _tokenLockIndex < userLocks[msg.sender].length,
            "Index out of range!"
        );
        TokenLock memory _lock = userLocks[msg.sender][_tokenLockIndex];
        uint256 _rewards;
        if (_lock.timeOfUnlock <= block.timestamp) {
            _rewards = _lock.rewards;
        }
        userLocks[msg.sender][_tokenLockIndex] = userLocks[msg.sender][
            userLocks[msg.sender].length - 1
        ];
        userLocks[msg.sender].pop();
        token.transfer(msg.sender, _lock.amount);
        if (_rewards > 0) {
            token.mintForRewards(msg.sender, _rewards);
            totalRewardsPaid += _rewards;
        }
        totalTokensStaked -= _lock.amount;
    }

    // Allows the owner to pause token transfers
    function pause() external onlyOwner {
        _pause();
    }

    // Allows the owner to unpause token transfers
    function unpause() external onlyOwner {
        _unpause();
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals(10% = 1000)
    function setRewardsThreeMonths(uint256 _rewards) external onlyOwner {
        threeMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsSixMonths(uint256 _rewards) external onlyOwner {
        sixMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsTwelveMonths(uint256 _rewards) external onlyOwner {
        twelveMonthsRPL = _rewards;
    }

    // Set rewards for token locking as % for the whole lock with 2 decimals (10% = 1000)
    function setRewardsTwentyFourMonths(uint256 _rewards) external onlyOwner {
        twentyFourMonthsRPL = _rewards;
    }

    // Get total rewards paid
    function getTotalRewardsPaid() external view returns (uint256) {
        return totalRewardsPaid;
    }

    // Get total amount staked
    function getTotalAmountStaked() external view returns (uint256) {
        return totalTokensStaked;
    }

    // Function useful for fron-end that returns user stake, rewards and token locks by address
    function getUserInfo(address _user)
        public
        view
        returns (
            uint256 _stake,
            uint256 _rewards,
            TokenLock[] memory _tokenLocks
        )
    {
        _stake = stakers[_user].deposited;
        _rewards = calculateRewards(_user) + stakers[_user].unclaimedRewards;
        return (_stake, _rewards, userLocks[_user]);
    }

    // Calculate the rewards since the last update on Deposit info
    function calculateRewards(address _staker)
        internal
        view
        returns (uint256 rewards)
    {
        if (stakers[_staker].timeOfLastUpdate == 0) {
            return 0;
        } else {
            return (((((block.timestamp - stakers[_staker].timeOfLastUpdate) *
                stakers[_staker].deposited) * flexStakeRPH) / 3600) / 10000000);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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