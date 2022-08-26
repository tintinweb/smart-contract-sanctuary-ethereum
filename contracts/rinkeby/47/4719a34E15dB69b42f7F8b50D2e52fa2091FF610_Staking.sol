// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "./IERC20.sol";
import "./Strings.sol";
import "./Ownable.sol";

/**
 * @DEV Marks contract as UNAUDITED and unsafe for production until official reviews from Hwonder and Squeebo_nft 
 * 
 * 
 * 
 * @DEV Is not Liable for this contract being used in production and any faults in the current V1 development stage
 * 
 * 
 * 
 * 
 * @DEV Will be updating main branch with production-ready versions in the near future
 * 
 * 
 * 
 * 
 * @DEV highlights the claimRewards() function as unfinished and consequently unsafe.
 */

/**
 * @dev is a contract for staking ERC20 tokens for a specific amount of time for rewards
 * 
 * @dev Stakers can redeem reward tokens, restake rewards for extra rewards  OR claim rewards and unstake after a certain amount of days
 * 
 * @dev Reward System will be implemented within this contract 
 * 
 * @dev V2 Reward system will implement factory pattern
 */

contract Staking is Ownable {
    /**
     * @dev sets up time tracking mechanisms
     * 
     * what about block staking? Stake now, stake more later ?
     */

    using Strings for uint256;
    bool public timestampSet;
    uint256 private rewardsPercentage = 5;
    uint256 public initialTimestamp;
    uint256 public timePeriod;
    
 
     // ERC20 contract address
    IERC20 public erc20TokenContract;
    IERC20 public erc20RewardToken;

    // Events for staking, unstaking and claiming rewards
    event TokensStaked(address indexed from, uint256 amount);
    event TokensUnstaked(address indexed to, uint256 amount);
    event RewardClaimed(address indexed claimer, uint256 amount);

    error StakingFailed();
    error UnStakingFailed();
    error RewardsClaimFailed();
    
    constructor(IERC20 erc20TokenAddress) {
        // Set the erc20 contract address 
        require(address(erc20TokenAddress) != address(0), "Please enter a valid token address");
        erc20TokenContract = erc20TokenAddress;
    }
    // Staker Data
    struct Staker {
        uint256 stakeTime;
        uint256 rewards;
        bool isStaked;
        uint256 amount;
    }

    mapping (address => Staker) public stakers;

    function setTimestamp(uint256 _timePeriodInSeconds) public onlyOwner {
        // require(timePeriod  < block.timestamp, "Current Stake Cycle is still active");
        timestampSet = true;
        initialTimestamp = block.timestamp;
        timePeriod = initialTimestamp + _timePeriodInSeconds;
    }

    function resetTimeStamp() public onlyOwner {
        timestampSet = false;
    }

    function _getRewards (uint256 _amount) internal view returns (uint256) {
        return rewardsPercentage * _amount;
    } 

    /**
     * @dev sets the contract address of the reward token after deployment
     */
    function setRewardTokenAddress (address _tokenAddress) public onlyOwner returns (bool) {
        erc20RewardToken = IERC20(_tokenAddress);
        return true;
    }

    /**
     * @dev implements staking mechanism for by calling interface methods of the IERC20 standard
     * @dev will calculate rewards according to 'amount' of tokens staked
     */
    function stakeTokens(IERC20 token, uint256 amount) public {
        require(amount > 0, "You cannot stake zero tokens!");
        require(timestampSet == true, "Cannot stake, staking period not yet specified");
        require(token == IERC20(erc20TokenContract), "Wrong token, please stake the specified token only");

        if (stakers[msg.sender].isStaked == true ) {            
            token.transferFrom(msg.sender, address(this), amount);
            stakers[msg.sender].amount += amount;
            stakers[msg.sender].stakeTime += 6 days;
            stakers[msg.sender].rewards = stakers[msg.sender].rewards + _getRewards(stakers[msg.sender].amount);
        } else {
        bool success = token.transferFrom(msg.sender, address(this), amount);
        if (!success) {
            revert StakingFailed();
        }
        stakers[msg.sender]= Staker(amount, 6 days, true, _getRewards(amount));
        }
        emit TokensStaked(msg.sender, amount);
    } 

    function unStakeToken(uint256 amount) public returns (bool) {
        require(stakers[msg.sender].isStaked == true, "You cannot unstake at this time");
        require(stakers[msg.sender].stakeTime > timePeriod, "Your staking period is not yet over");
        require(stakers[msg.sender].amount > 0, "You do not have any tokens staked");
        require(amount > 0, "You cannot unstake zero tokens");

        /**
         * @dev autoclaims rewards if staker forgot to claim rewards before unstaking
         * @dev updates staker struct amount and rewards and changes isStaked State
         */
        if (block.timestamp >= timePeriod) {
            if (stakers[msg.sender].rewards > 0) claimRewards();
            stakers[msg.sender].amount -= amount;
            if (stakers[msg.sender].amount < 1) {
                stakers[msg.sender].isStaked = false;
                stakers[msg.sender].rewards = 0;
            } else {
                 stakers[msg.sender].isStaked = true;
                 stakers[msg.sender].rewards = _getRewards(stakers[msg.sender].amount) ;
            }
            erc20RewardToken.transfer(msg.sender, amount);
            stakers[msg.sender].stakeTime = 0 days;
            emit TokensUnstaked(msg.sender, amount);
        } else {
            revert("Tokens are only available after correct time period has elapsed");
        }
        return true;
    }

    /**
     * @dev calls IERC20 mint on the rewards token to the address of the claimer based on their % of rewards
     * @dev Rewards can only be claimed halfway through the staking period
     */
    function claimRewards() public {
        require(block.timestamp >= timePeriod, "Staking period not yet over, try again later");
        require(stakers[msg.sender].rewards > 0, "You cannot claim rewards at this time");
        require(stakers[msg.sender].isStaked == true, "Cannot claim rewards, not active staker");

        IERC20(erc20RewardToken).mint(msg.sender, stakers[msg.sender].rewards);

        emit RewardClaimed(msg.sender, stakers[msg.sender].rewards);
        stakers[msg.sender].rewards = 0;     
    }


    function getVaultTotalBalance () external view returns (uint256) {
      return IERC20(erc20TokenContract).balanceOf(address(this));
    } 

    function getIndividualStakerBalance () public view returns (uint256) {
        return stakers[msg.sender].amount;
    }

    function setRewardsPercentage (uint8 _percentage) public onlyOwner {
        rewardsPercentage = _percentage;
    }

}