//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./IRewardIVKLIMToken.sol";

contract LPStaking is Ownable {

    struct StakeHolder {
        uint256 amount;
        uint256 timeStartStake;
        uint256 reward;
    }

    address public tokenLP;
    address public rewardableToken;
    uint256 public rewardTime; 
    uint256 public timeToUnstake; 
    uint8 public rewardPercentage; 

    StakeHolder[] _stakeHolders;
    mapping (address => uint256) _stakeHoldersIds;

    event Staked(address stakeHoldersAddress, uint256 amount, uint256 timeStartStake);
    event Unstaked(address stakeHoldersAddress, uint256 amount, uint256 unstakeTime);
    event Claimed(address stakeHoldersAddress, uint256 amount);

    event RewardTimeUpdated(uint256 amount);
    event TimeToUnstakeUpdated(uint256 amount);
    event RewardPercentageUpdated(uint8 amount);

    constructor(address tokenLPAddress, address rewardableTokenAddress) {
        tokenLP = tokenLPAddress;
        rewardableToken = rewardableTokenAddress;
        //just for comfort checking has stake or not
        _stakeHolders.push();
        rewardTime = 600; // 10 min
        rewardPercentage = 20; //20 %
        timeToUnstake = 1200; //20 min
    }

    modifier hasStakeHolder(address stakeHolderAddress) {
        uint256 holdersId = _stakeHoldersIds[stakeHolderAddress];
        require(holdersId > 0, "LPStaking: User has not staked yet");
        _;
    }

    function setRewardTime(uint256 newRewardTime) external onlyOwner {
        rewardTime = newRewardTime;

        emit RewardTimeUpdated(rewardTime);
    }

    function setTimeToUnstake(uint256 newTimeToUnstake) external onlyOwner {
        require(newTimeToUnstake > rewardTime, "LPStaking: newTimeToUnstake must be more than rewardTime");
        timeToUnstake = newTimeToUnstake;

        emit TimeToUnstakeUpdated(timeToUnstake);
    }

    function setRewardPercentage(uint8 newRewardPercentage) external onlyOwner {
        rewardPercentage = newRewardPercentage;

        emit RewardPercentageUpdated(rewardPercentage);
    }

    function stake(uint256 amount) external {
        address sender = msg.sender;
        uint256 balance = IERC20(tokenLP).balanceOf(sender);
        require(balance >= amount, "LPStaking: amount more than balance");
        IERC20(tokenLP).transferFrom(sender, address(this), amount);

        uint256 holdersId = _stakeHoldersIds[sender];

        if(holdersId == 0) {
            holdersId = _addStaker(sender);
        }

        StakeHolder storage stakeHolder = _stakeHolders[holdersId];
        uint256 timeStamp = block.timestamp;

        //calculate current reward
        uint256 amountInStake = stakeHolder.amount;
        uint256 countCycles = (timeStamp - stakeHolder.timeStartStake) / rewardTime;
        uint256 reward = amountInStake * countCycles * rewardPercentage / 100;

        //update stake data
        stakeHolder.timeStartStake = timeStamp;
        stakeHolder.reward += reward;
        stakeHolder.amount += amount;

        emit Staked(sender, amount, timeStamp);
    }

    function claim() public {
        address sender = msg.sender;
        _claim(sender);
    }

    function unstake() external {
        address sender = msg.sender;
        _unstake(sender);
    }

    function _claim(address stakeHolderAddress) internal hasStakeHolder(stakeHolderAddress) {
        uint256 holdersId = _stakeHoldersIds[stakeHolderAddress];

        StakeHolder storage stakeHolder = _stakeHolders[holdersId];
        
        uint256 timeStamp = block.timestamp;
        require(timeStamp > stakeHolder.timeStartStake + rewardTime, "LPStaking: time for reward hasn't passed");
        require(stakeHolder.amount > 0, "LPStaking: not amount in stake");
      
        //calculate current reward
        uint256 amountInStake = stakeHolder.amount;
        uint256 countCycles = (timeStamp - stakeHolder.timeStartStake) / rewardTime;
        uint256 reward = amountInStake * countCycles * rewardPercentage / 100;
        reward += stakeHolder.reward;
        
        stakeHolder.timeStartStake = timeStamp;
        stakeHolder.reward = 0;

        IRewardIVKLIMToken(rewardableToken).mint(stakeHolderAddress, reward);
      
        emit Claimed(stakeHolderAddress, reward);
    }

    function _unstake(address stakeHolderAddress) internal hasStakeHolder(stakeHolderAddress) {
        uint256 timeStamp = block.timestamp;
        uint256 holdersId = _stakeHoldersIds[stakeHolderAddress];
        StakeHolder storage stakeHolder = _stakeHolders[holdersId];
        require(timeStamp > stakeHolder.timeStartStake + timeToUnstake, "LPStaking: time for unstake hasn't passed");
        claim();
        
        uint256 amount = stakeHolder.amount;
        stakeHolder.amount = 0;

        IERC20(tokenLP).transfer(stakeHolderAddress, amount);

        emit Unstaked(stakeHolderAddress, amount, block.timestamp);
    }

    function _addStaker(address stakerAddress) internal returns(uint256){
        _stakeHolders.push();
        uint256 id = _stakeHolders.length - 1;
        _stakeHoldersIds[stakerAddress] = id;
        return id;
    }

    function getStakeHolder(address stakeHolderAddress) public view hasStakeHolder(stakeHolderAddress) returns (StakeHolder memory) {
        uint256 holdersId = _stakeHoldersIds[stakeHolderAddress];
        return _stakeHolders[holdersId];
    }

    function getTotalStakeHolderReward(address stakeHolderAddress) public view returns (uint256) {
        uint256 timeStamp = block.timestamp;

        StakeHolder memory stakeHolder = getStakeHolder(stakeHolderAddress);

        uint256 amountInStake = stakeHolder.amount;
        uint256 countCycles = (timeStamp - stakeHolder.timeStartStake) / rewardTime;
        uint256 reward = amountInStake * countCycles * rewardPercentage / 100;
        reward += stakeHolder.reward;

        return reward;
    }

    function getStakeHoldersLength() public view returns (uint256) {
        return _stakeHolders.length;
    }

    function isStakeHolder(address stakeHolderAddress) public view returns (bool){
        uint256 holdersId = _stakeHoldersIds[stakeHolderAddress];

        return holdersId > 0;
    }
}

pragma solidity >=0.7.0 <0.9.0;

// SPDX-License-Identifier: MIT

abstract contract Ownable {
    address private currentOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function  owner() public view returns(address ownerAddress) {
        return currentOwner;
    }

    function _transferOwnership(address newOwner) internal {
        address oldAddress = owner();
        currentOwner = newOwner;
        emit OwnershipTransferred(oldAddress, currentOwner);
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

pragma solidity ^0.8.0;

interface IRewardIVKLIMToken {
    function mint(address to, uint value) external ;
}