//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./AccessControl.sol";

/**
 * @title Staking
 * @notice It is a staking pool for UniswapV2 LP tokens
 * (stake UniswapV2 LP tokens -> get INT).
 */
contract StakingPool is AccessControl, ReentrancyGuard
{
    using SafeERC20 for IERC20;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    struct UserInfo 
    {
        uint256 amount; // Amount of staked tokens provided by user
        uint256 rewardDebt; // Reward debt  
        uint256 timestamp; // The time when user staked tokens
        uint256 weight; // user weight increases 10 times each block
        uint256 startblock; // block when user setted his/her amount
    }



    // ten minutes in seconds
    uint256 private constant TEN_MINUTES = 600;

    // Precision factor for reward calculation
    uint256 public constant AMOUNT_MIN = 10**18;

    // Precision factor for reward calculation
    uint256 public constant PRECISION_FACTOR = 10**12;

    // address of INT token
    IERC20 public immutable claimToken;

    // address of LP token
    IERC20 public immutable stakedToken;

    // update time of claimable reward
    uint256 public updateTime;

    // UserInfo for users that stake tokens (stakedToken)
    mapping(address => UserInfo) public userInfo;

    // state of initial deposit function
    bool public _locked; 

    /**
     * @notice Constructor
     * @param claimToken_ reward token address
     * @param stakedToken_ token for stake
     */
    constructor(address claimToken_, address stakedToken_) 
    {
        claimToken = IERC20(claimToken_);
        stakedToken = IERC20(stakedToken_);
        
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _locked = false;
    }


    /**
     * @notice lock modifier needs to lock access to initial deposit function
     */
    modifier lock()
    {
        require(_locked == false, "StakingPool: Owner already deposited their funds");
        _;
        _locked = true;
    }

    /**
     * @notice initial deposit that can be called by owner
     * @param amount - amount of tokens to deposit
     */
    function initialDeposit(uint256 amount) 
    external 
    onlyRole(DEFAULT_ADMIN_ROLE)
    lock
    {
        SafeERC20.safeTransferFrom(claimToken, msg.sender, address(this), amount);
        userInfo[msg.sender].weight = 1;
        userInfo[msg.sender].startblock = 1;
        emit Deposit(msg.sender, amount);
    }


    /**
     * @notice tokens for claim that are in contract
     */
    function claimTokenSupply() external view returns(uint256)
    {
        return claimToken.balanceOf(address(this));
    }



    /**
     * @notice deposit LP tokens
     * @param amount - amount of tokens to deposit
     */
    function depositUniswapV2LP(uint256 amount)
    external
    nonReentrant
    {
        require(amount >= AMOUNT_MIN, "Staking: minimum amount is 1 INT");
        userInfo[msg.sender].amount += amount;
        userInfo[msg.sender].timestamp = block.timestamp;
        SafeERC20.safeTransferFrom(stakedToken, msg.sender, address(this), amount);

        if(userInfo[msg.sender].weight == 0)
        {
            userInfo[msg.sender].weight = 1;
            userInfo[msg.sender].startblock = block.number;
        }
        emit Deposit(msg.sender, amount);
    }

    /**
     * @notice allows user to withdraw all tokens he/she is staking
     */
    function withdrawAllUniswapV2LP()
    external
    nonReentrant
    {
        _withdrawUniswapV2LP(userInfo[msg.sender].amount);
        emit Withdraw(msg.sender, userInfo[msg.sender].amount);
    }



    /**
     * @notice allows user to withdraw tokens he/she is staking
     * @param amount - amount of tokens to withdraw
     */
    function withdrawUniswapV2LP(uint256 amount)
    external
    nonReentrant
    {
        _withdrawUniswapV2LP(amount);
        emit Withdraw(msg.sender, amount);
    }


     /**
     * @notice allows user to withdraw tokens he/she won by staking
     * @param amount - amount of tokens to withdraw
     */
    function claimRewardToken(uint256 amount)
    external
    nonReentrant
    {
        _claimRewardToken(amount);
        emit Withdraw(msg.sender, amount);
    }

    /**
     * @notice allows user to withdraw all tokens he/she won by staking
     */
    function claimAllRewardToken()
    external
    nonReentrant
    {
        _claimRewardToken(userInfo[msg.sender].rewardDebt);
        emit Withdraw(msg.sender, userInfo[msg.sender].rewardDebt);
    }


    /**
     * @notice allows admin to withdraw all tokens of the stake pool
     */
    function withdrawAllTokens()
    external
    nonReentrant
    onlyRole(DEFAULT_ADMIN_ROLE)
    {
        uint256 stakedTokenSupply = claimToken.balanceOf(address(this));
        require(stakedTokenSupply > 0, "Staking: balance is insufficient");
        SafeERC20.safeTransfer(claimToken, msg.sender, stakedTokenSupply);
        emit Withdraw(msg.sender, stakedTokenSupply);
    }

    /**
     * @notice shows token's that can be claimed
     */
    function tokensForClaim() external view returns(uint256)
    {    
        return userInfo[msg.sender].rewardDebt;
    }


    /**
     * @notice updates data of staking
     */
    function updateReward() external
    {
        _updateReward(msg.sender);
    }


    /**
     * @notice withdraw UniswapV2 LP tokens staked by user
     * @param amount - amount of tokens user wants to withdraw
     */
    function _withdrawUniswapV2LP(uint256 amount) internal
    {
        uint256 tokenAmount = userInfo[msg.sender].amount;
        require(tokenAmount >= amount, "Staking: insufficient amount");

        unchecked {
            userInfo[msg.sender].amount -= amount;
        }
        _updateReward(msg.sender);
        SafeERC20.safeTransfer(stakedToken, msg.sender, amount);
    }



    /**
     * @notice claim reward in amount that user won from staking
     * @param amount - amount of tokens user wants to withdraw
     */
    function _claimRewardToken(uint256 amount) internal
    {
        uint256 rewardAmount = userInfo[msg.sender].rewardDebt;
        require(rewardAmount >= amount, "Staking: insufficient amount");

        unchecked {
            userInfo[msg.sender].rewardDebt -= amount;
        }
        SafeERC20.safeTransfer(claimToken, msg.sender, amount);
    }



    /**
     * @notice Update reward variables of the staking pool to be up-to-date.
     * @notice - reward = (a * mult * weight) / 10^12
     * @param user - address of user for which to update
     */
    function _updateReward(address user) internal
    {
        uint256 previosTimestamp = userInfo[user].timestamp;
        uint256 interval = block.timestamp - previosTimestamp;
        uint256 userAmount = userInfo[user].amount;

        // to avoid user weight = 0
        if(block.number - userInfo[user].startblock > 0)
            userInfo[user].weight *= 10 * (block.number - userInfo[user].startblock);

        // calculate reward and update old data
        if(interval >= TEN_MINUTES)
        {
            userInfo[user].rewardDebt += (userAmount * _getMultiplier(interval, TEN_MINUTES) * userInfo[user].weight / PRECISION_FACTOR) ;
            userInfo[user].timestamp = block.timestamp;
            userInfo[user].startblock = block.number;
        }
    }



    /**
     * @notice Return reward multiplier over the given "value" and "interval" timestamp
     * @param value - time that was taken between current timestamp and previous
     * @param interval - time in seconds in which diapason to get multiplier
     * @return the multiplier
     */
    function _getMultiplier(uint256 value, uint256 interval)
    internal 
    pure 
    returns(uint256)
    {
        if(value < interval)
            return 1;

        return value / interval;
    }
}