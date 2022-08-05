/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address internal owner;
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Owner-restricted function");
         _;
    }    
    function renounceOwnership() public onlyOwner {
        owner = address(0);
        emit OwnershipTransferred(address(0));
    }  
    event OwnershipTransferred(address owner);
}

contract OmukadeStaking is Ownable {
    
    address payable constant projectFeeReceiver = payable(0x1A23F9b70ae87ED057055E2371dFBEE137cC2269);    
    address constant public tokenAddress = 0x1FF9b2eE65D77D9Da33c5c6E584C40dd465a0A50;
    
    IERC20 immutable public token = IERC20(tokenAddress);
    uint8 constant TOKEN_DECIMALS = 9;

    struct Stake{
        uint256 stakeAmount;
        uint64 timeOfStake;        
        uint8 stakeDurationDays;
    }

    struct StakeWithPendRew{
        uint256 stakeAmount;
        uint256 pendingReward;
        uint64 timeOfStake;        
        uint8 stakeDurationDays;
    }
    
    mapping (address => Stake[]) public stakes;

    uint256 constant public INITIAL_STAKE = 1_000_000 * (10 ** TOKEN_DECIMALS);
    uint256 public totalRewards;

    uint256 public constant YEAR_SECONDS = 365 * 24 * 60 * 60;
    uint256 public constant DAY_SECONDS = 24 * 60 * 60;
    uint256 public constant YEAR_DAYS = 365;
    uint256 public constant PROCENT = 100;


    constructor () Ownable(msg.sender) {}

    receive() external payable {} 

    function deposit(uint256 amount, uint8 stakeDurationDays) public {
        uint256 maxReward = calculateMaxStakeReward(amount, stakeDurationDays);
        require(totalRewards + maxReward < INITIAL_STAKE, "Staking Pool Filled");
        require(stakeDurationDays == 3 || stakeDurationDays == 7 || stakeDurationDays == 30,
             "3, 7 or 30 day stake maturity allowed");
        require(amount > 1e9, "Stake amount too small");

        token.transferFrom(msg.sender, address(this), amount);
        Stake memory newStake =  Stake(amount, uint64(block.timestamp), stakeDurationDays);
        stakes[msg.sender].push(newStake); 

        totalRewards += maxReward;
    } 

    function withdraw(uint256 stakeIndex) public {
        Stake memory stake = stakes[msg.sender][stakeIndex];
        uint256 timeSinceStake = block.timestamp - stake.timeOfStake;
        require(stake.stakeDurationDays == 3 || 
                timeSinceStake / DAY_SECONDS > stake.stakeDurationDays, "Stake still time-locked");
        (uint256 stakingReward, uint256 remainder) = calculateStakeReward(stake);
        token.transfer(msg.sender, stakingReward);

        require(stake.stakeAmount > 0, "Already unstaked.");
        stakes[msg.sender][stakeIndex].stakeAmount = 0;

        totalRewards -= remainder;
    }   
 

    function calculateStakeReward(Stake memory stake) internal view returns (uint256,uint256) {

        uint256 stakeDurationSeconds = block.timestamp - stake.timeOfStake;
        uint256 stakeAPY = getAPY(stake.stakeDurationDays);
        if(stakeDurationSeconds/DAY_SECONDS > stake.stakeDurationDays){
            
            return (stake.stakeAmount + stake.stakeAmount * stakeAPY / PROCENT / YEAR_DAYS * stake.stakeDurationDays, 0);
        }
        else{
            return (stake.stakeAmount + stake.stakeAmount * stakeAPY / PROCENT / YEAR_SECONDS * stakeDurationSeconds,
                    stake.stakeAmount * stakeAPY / PROCENT / YEAR_DAYS * stake.stakeDurationDays - 
                    stake.stakeAmount * stakeAPY / PROCENT / YEAR_SECONDS * stakeDurationSeconds);
        }
    }
    
    function calculateStakeReward(uint256 stakeAmount, uint256 timeOfStake, uint256 stakeDurationDays) public view returns (uint256,uint256) {

        uint256 stakeDurationSeconds = block.timestamp - timeOfStake;
        uint256 stakeAPY = getAPY(stakeDurationDays);
        if(stakeDurationSeconds/DAY_SECONDS > stakeDurationDays){
            return (stakeAmount + stakeAmount * stakeAPY / PROCENT / YEAR_DAYS * stakeDurationDays, 0);
        }
        else{
            return (stakeAmount + stakeAmount * stakeAPY / PROCENT / YEAR_SECONDS * stakeDurationSeconds,
                    stakeAmount * stakeAPY / PROCENT / YEAR_DAYS * stakeDurationDays - 
                    stakeAmount * stakeAPY / PROCENT / YEAR_SECONDS * stakeDurationSeconds);
        }        
    }

    function calculateMaxStakeReward(uint256 stakeAmount, uint256 stakeDurationDays) public pure returns (uint256) {
        uint256 stakeAPY = getAPY(stakeDurationDays);
        return stakeAmount * stakeAPY / PROCENT / YEAR_DAYS * stakeDurationDays;
    }

    function getAPY(uint256 stakeDurationDays) public pure returns (uint256) {
        if(stakeDurationDays == 3)
            return 150;        
        else if(stakeDurationDays == 7)
            return 250;        
        else if(stakeDurationDays == 30)
            return 350;    
        else{
            return 0;
        }        
    }
    function numStakesForAddress(address account) public view returns (uint256) {
        uint256 len;
        for (uint256 i=0; i < stakes[account].length; i++){
            if(stakes[account][i].stakeAmount > 0){
                len++;
            }
        }
        return len;
    }

    function clearStuckBalance() external {
        payable(projectFeeReceiver).transfer(address(this).balance);
    }

    function stakesForAddress(address account) public view returns(Stake[] memory){
        return stakes[account];
    }

    function stakesForAddressWithPendRew(address account) public view returns(StakeWithPendRew[] memory, uint256[] memory, uint256){
        Stake[] memory stakes_ = stakes[account];
        uint256 numStakes = stakes_.length;
        uint256 ixs;
        uint256[] memory ixArray = new uint256[](numStakes);
        StakeWithPendRew[] memory stakesWReward = new StakeWithPendRew[](numStakes);
        for(uint256 i=0;i<numStakes;i++){             
            (uint256 stakeReward, ) = calculateStakeReward(stakes_[i]);
            StakeWithPendRew memory stakeWReward = StakeWithPendRew(
                stakes_[i].stakeAmount,
                stakeReward,
                stakes_[i].timeOfStake,
                stakes_[i].stakeDurationDays);
            
            if(stakes_[i].stakeAmount>0){
                stakesWReward[i] = stakeWReward;
                ixArray[ixs] = i;
                ixs++;
            }
        }
        return (stakesWReward, ixArray, ixs);
    }

    function fetchData(address account) public view returns (uint256, uint256, uint256){
        return (token.balanceOf(account), token.allowance(account, address(this)), numStakesForAddress(account));
    }
}