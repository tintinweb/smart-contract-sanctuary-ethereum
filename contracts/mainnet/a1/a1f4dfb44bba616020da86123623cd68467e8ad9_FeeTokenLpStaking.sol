/**
 *Submitted for verification at Etherscan.io on 2022-02-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
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

contract FeeTokenLpStaking is Ownable { 
    IERC20 public immutable FeeToken;
    IERC20 public immutable FeeTokenLpPair;
    uint256 public totalStakedAmount;
    uint256 public rewardsPool;
    uint256 public rewardsPerBlock;

    mapping(address /* Account */ => Stake /* Stake details */) public stakes;

    event STAKE(address indexed account, uint256 indexed amount);
    event UNSTAKE(address indexed account, uint256 indexed amount);
    event REWARDS_CLAIMED(address indexed account, uint256 indexed rewards);
    event REWARDS_POOL(address indexed account, uint256 amount);
    event REWARDS_PER_BLOCK(uint256 oldRewardsPerBlock, uint256 newRewardsPerBlock);


    struct Stake {
        address user;
        uint256 amount;
        uint256 rewardsBlockNumber;
        uint256 totalClaimedRewards;
    }

    constructor(IERC20 _feeToken, IERC20 _feeTokenLpAddress) {
        FeeToken = _feeToken;
        FeeTokenLpPair = _feeTokenLpAddress;
        rewardsPerBlock = 10 ether;
    }

    function deposit(uint256 _amount) external {
        FeeToken.transferFrom(_msgSender(), address(this), _amount);
        rewardsPool += _amount;
        emit REWARDS_POOL(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) external onlyOwner {
        require(_amount <= rewardsPool, "FeeTokenStaking: amount exceed rewardsPool");
        rewardsPool -= _amount;
        FeeToken.transfer(_msgSender(), _amount);
    }

    function updateRewardsPerBlock(uint256 _rewardsPerBlock) external onlyOwner {
        emit REWARDS_PER_BLOCK(rewardsPerBlock, _rewardsPerBlock);
        rewardsPerBlock = _rewardsPerBlock;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "FeeTokenStaking: Amount must be greater than zero");

        FeeTokenLpPair.transferFrom(_msgSender(), address(this), _amount);
        totalStakedAmount += _amount;

        stakes[_msgSender()] = Stake(
            _msgSender(),
            stakes[_msgSender()].amount + _amount,
            block.number,
            stakes[_msgSender()].totalClaimedRewards
        );

        emit STAKE(_msgSender(), _amount);
    }

    function unstake() external {
        uint256 _amount = stakes[_msgSender()].amount;
        require(_amount > 0, "FeeTokenStaking: No active stakes found");
        _claimRewards(); // claim stake rewards
        _unstake(_amount);
    }

    function emergencyUnStake() external {
        uint256 _amount = stakes[_msgSender()].amount;
        require(_amount > 0, "FeeTokenStaking: No active stakes found");
        _unstake(_amount);
    }

    function _unstake(uint256 _amount) private {
        Stake storage _stake = stakes[_msgSender()];

        totalStakedAmount -= _amount;
        _stake.amount -= _amount;
        FeeTokenLpPair.transfer(_msgSender(), _amount);
        emit UNSTAKE(_msgSender(), _amount);
    }

    function claimRewards() external {
        require(stakes[_msgSender()].amount > 0, "FeeTokenStaking: No active stakes found");
        _claimRewards();
    }


    function pendingRewards(address _account) public view returns(uint256 _rewardsAmount) {
        uint256 _stakedBalance = stakes[_account].amount;
        if(_stakedBalance <= 0) return 0;

        uint256 _startRewardsBlock = stakes[_account].rewardsBlockNumber;
        uint256 _currentBlock = block.number;
        uint256 _totalStakedBlock = _currentBlock - _startRewardsBlock;
        uint256 _stakePercentage = (_stakedBalance * 100) / totalStakedAmount;
        uint256 _rewardsPerBlock = (rewardsPerBlock * _stakePercentage) / 100;
        _rewardsAmount = _totalStakedBlock * _rewardsPerBlock;
    }

    function _claimRewards() private {
        uint256 _rewardsAmount = pendingRewards(_msgSender());

        stakes[_msgSender()].rewardsBlockNumber = block.number; // update rewardsBlockNumber
        stakes[_msgSender()].totalClaimedRewards += _rewardsAmount;

        rewardsPool -= _rewardsAmount;
        FeeToken.transfer(_msgSender(), _rewardsAmount);
        emit REWARDS_CLAIMED(_msgSender(), _rewardsAmount);
    }

}