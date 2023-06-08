/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

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


// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: @openzeppelin/contracts/interfaces/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;


// File: contracts/nftAveStaking.sol


pragma solidity 0.8.17;




contract Staking is Pausable, Ownable {

    event AmountStaked(address userAddress, uint256 level, uint256 amount);
    event Withdraw(address userAddress, uint256 withdrawAmount);
    event TokenRecovered(address tokenAddress, address walletAddress);

    IERC20 public token;
    uint256 public reserveAmount;

    struct UserDetail {
        uint256 level;
        uint256 amount;
        uint256 initialTime;
        uint256 endTime;
        uint256 rewardAmount;
        uint256 withdrawAmount;
        bool status;
    }

    struct Stake {
        uint256 rewardFeePermile;
        uint256 stakeLimit;
        uint256 month;
    }

    mapping(address =>mapping(uint256 => UserDetail)) internal users;
    mapping(uint256 => Stake) internal stakingDetails;

    constructor (IERC20 _token) {
        token = _token;
        stakingDetails[1] = Stake(475, 10 seconds, 1);      //!
        stakingDetails[2] = Stake(625, 10 seconds, 3);      //!
        stakingDetails[3] = Stake(700, 180 days, 6);
        stakingDetails[4] = Stake(800, 270 days, 9);
        stakingDetails[5] = Stake(900, 365 days, 12);
    }

    function stake(uint256 amount, uint256 level)
        external
        whenNotPaused
        returns(bool)
    {
        require(level > 0 && level <= 5, "Invalid level");
        require(!(users[msg.sender][level].status), "user already exist");
        users[msg.sender][level].amount = amount;
        users[msg.sender][level].level = level;
        users[msg.sender][level].endTime = block.timestamp + stakingDetails[level].stakeLimit;        
        users[msg.sender][level].initialTime = block.timestamp;
        users[msg.sender][level].status = true;
        token.transferFrom(msg.sender, address(this), amount);
        addReserve(level);
        emit AmountStaked(msg.sender, level, amount);
        return true;
    }

    function withdraw(uint256 level)
        external
        returns(bool)
    {
        require(level > 0 && level <= 5, "Invalid level");
        require(users[msg.sender][level].status, "user not exist");
        require(users[msg.sender][level].endTime <= block.timestamp, "staking end time is not reached");
        uint256 rewardAmount = getRewards(msg.sender, level);
        uint256 amount = rewardAmount + users[msg.sender][level].amount;
        token.transfer(msg.sender, amount);
        uint256 rAmount = rewardAmount + users[msg.sender][level].rewardAmount;
        uint256 wAmount = amount + users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(
            0, 0, 0, 0,
            rAmount,
            wAmount,
            false
        );
        emit Withdraw(msg.sender, amount);
        return true;
    }

    function emergencyWithdraw(uint256 level)
        external
        returns(uint256)
    {
        require(level > 0 && level <= 5, "Invalid level");
        require(block.timestamp <= users[msg.sender][level].endTime, "reward is available");
        require(users[msg.sender][level].status, "user not exist");
        uint256 stakedAmount = users[msg.sender][level].amount;
        token.transfer(msg.sender, users[msg.sender][level].amount);
        uint256 wAmount = users[msg.sender][level].amount + users[msg.sender][level].withdrawAmount;
        removeReserve(level);
        users[msg.sender][level] = UserDetail(
            0,0,0,0,
            users[msg.sender][level].rewardAmount,
            wAmount,
            false
        );
        emit Withdraw(msg.sender, stakedAmount);
        return stakedAmount; 
    }

    function getUserDetails(address account, uint256 level)
        external
        view
        returns(UserDetail memory, uint256 rewardAmount)
    {
        uint256 reward = getRewards(account, level);
        return (users[account][level], reward);
    }

    function getstakingDetails(uint256 level) external view returns(Stake memory){
        return (stakingDetails[level]);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function rewardCalculation(address account, uint256 level)
        internal
        view
        returns(uint256)
    {
        uint256 stakeAmount = users[account][level].amount;
        uint256 rewardRate = stakingDetails[users[account][level].level].rewardFeePermile;
        uint256 rewardAmount = ((stakeAmount * rewardRate * 10000) / 10000) / 12;
        rewardAmount = (rewardAmount * stakingDetails[level].month) / 10000;
        return rewardAmount;
    }

    function getRewards(address account, uint256 level)
        internal
        view
        returns(uint256)
    {
        if(users[account][level].endTime <= block.timestamp) {
            return rewardCalculation(account,level);
        }
        else {
            return 0;
        }
    }

    function addReserve(uint256 level) internal {
        uint256 rewardAmount = rewardCalculation(msg.sender,level);
        reserveAmount += (users[msg.sender][level].amount + rewardAmount);
    }

    function removeReserve(uint256 level) internal {
        uint256 rewardAmount = rewardCalculation(msg.sender,level);
        reserveAmount -= (users[msg.sender][level].amount + rewardAmount);
    }

    function recoverToken(address _tokenAddress, address walletAddress)
        external
        onlyOwner
    {
        require(walletAddress != address(0), "Null address");
        require(IERC20(_tokenAddress).balanceOf(address(this)) > reserveAmount, "Insufficient amount");
        uint256 amount = IERC20(_tokenAddress).balanceOf(address(this)) - reserveAmount;
        bool success = IERC20(_tokenAddress).transfer(
            walletAddress,
            amount
        );
        require(success, "tx failed");
        emit TokenRecovered(_tokenAddress, walletAddress);
    }

}