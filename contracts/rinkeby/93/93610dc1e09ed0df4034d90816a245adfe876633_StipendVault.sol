//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {Ownable} from "./Ownable.sol";

interface StipendToken{
    function mint(address, uint256) external returns (bool);
}

contract StipendVault is Ownable{
    using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure

    address public stipend; // Token to be paid as reward

    uint256 public rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant STAKER_SHARE_PRECISION = 1e12; // A big number to perform mul and div operations
    address public POE;
    uint256 public minimumForBoost = 10 * 1e18;

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 weight; // effective weight from amount staked
        uint256 rewards; // The reward tokens quantity the user can harvest
        uint256 lastRewardedBlock; // Last block number the user had their rewards calculated
    }

    // Staking pool
    struct Pool {
        IERC20 stakeToken; // Token to be staked
        uint256 tokensStaked; // Total tokens staked
        uint256 totalWeight; // Total weight across all stakers in this pool
        address[] stakers; // Stakers in this pool
    }

    Pool[] public pools; // Staking pools

    // Mapping poolId => staker address => PoolStaker
    mapping(uint256 => mapping(address => PoolStaker)) public poolStakers;

    // Events
    event Deposit(address indexed user, uint256 indexed poolId, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed poolId, uint256 amount);
    event HarvestRewards(address indexed user, uint256 indexed poolId, uint256 amount);
    event PoolCreated(uint256 poolId);

    // Constructor
    constructor(address _rewardTokenAddress, uint256 _rewardTokensPerBlock, address AuthToken) {
        stipend = _rewardTokenAddress;
        rewardTokensPerBlock = _rewardTokensPerBlock;
        POE = AuthToken;
    }

    /**
     * @dev Create a new staking pool
     */
    function createPool(IERC20 _stakeToken) external onlyOwner {
        Pool memory pool;
        pool.stakeToken =  _stakeToken;
        pools.push(pool);
        uint256 poolId = pools.length - 1;
        emit PoolCreated(poolId);
    }

        /// @dev set POE Contract address
    function setPOEContractAddress(address _new) external onlyOwner{
        POE = _new;
    }

        /// @dev set POE Contract address
    function setMinimumForBoost(uint256 _new) external onlyOwner{
        minimumForBoost = _new;
    }

            /// @dev set POE Contract address
    function setRewardsPerBlock(uint256 _new) external onlyOwner{
        rewardTokensPerBlock = _new;
    }

    function stakerEarningRate(uint256 _poolId, address _staker) public view returns(uint256) {
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][_staker];

        uint256 accounting = staker.weight * rewardTokensPerBlock;
        return accounting / pool.totalWeight;
    }

    /**
     * @dev Add staker address to the pool stakers if it's not there already
     * We don't have to remove it because if it has amount 0 it won't affect rewards.
     * (but it might save gas in the long run)
     */
    function addStakerToPoolIfInexistent(uint256 _poolId, address depositingStaker, uint256 _amount) private {
        Pool storage pool = pools[_poolId];
        for (uint256 i; i < pool.stakers.length; i++) {
            address existingStaker = pool.stakers[i];
            if (existingStaker == depositingStaker) return;
        }
        pool.totalWeight += estimateWeight(_amount, depositingStaker);
        pool.stakers.push(msg.sender);
    }

    /**
     * @dev Deposit tokens to an existing pool
     */
    function deposit(uint256 _poolId, uint256 _amount) external {
        require(_amount > 0, "Deposit amount can't be zero");
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];

        uint256 accounting = staker.weight;

        // Update pool stakers
        updateStakersRewards(_poolId);
        addStakerToPoolIfInexistent(_poolId, msg.sender, _amount);

        // Update current staker
        staker.amount = staker.amount + _amount;
        staker.lastRewardedBlock = block.number;
        staker.weight = estimateWeight(staker.amount, msg.sender);

        // Update pool
        pool.tokensStaked = pool.tokensStaked + _amount;

        if(accounting > 0){
            uint256 weightIncrease = staker.weight - accounting;
            pool.totalWeight += weightIncrease;
        }

        // Deposit tokens
        emit Deposit(msg.sender, _poolId, _amount);
        pool.stakeToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
    }

    /**
     * @dev Withdraw all tokens from an existing pool
     */
    function withdraw(uint256 _poolId) external {
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];
        uint256 amount = staker.amount;
        uint256 weight = staker.weight;
        uint256 weightToSubtract = weight;

        require(amount > 0, "Withdraw amount can't be zero");

        // Update pool stakers
        updateStakersRewards(_poolId);

        // Pay rewards
        harvestRewards(_poolId);

        // Update staker
        staker.amount = 0;
        staker.weight = 0;

        // Update pool
        pool.tokensStaked = pool.tokensStaked - amount;
        pool.totalWeight = pool.totalWeight - weightToSubtract;

        // Withdraw tokens
        emit Withdraw(msg.sender, _poolId, amount);
        pool.stakeToken.safeTransfer(
            address(msg.sender),
            amount
        );
    }

    /**
     * @dev Harvest user rewards from a given pool id
     */
    function harvestRewards(uint256 _poolId) public {
        updateStakersRewards(_poolId);
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];
        uint256 rewardsToHarvest = staker.rewards;
        staker.rewards = 0;
        emit HarvestRewards(msg.sender, _poolId, rewardsToHarvest);
        StipendToken(stipend).mint(msg.sender, rewardsToHarvest);
    }

    function estimateWeight(uint256 _amount, address staker) public view returns(uint256){
        uint256 stakingWeight = 0;
        if(IERC20(POE).balanceOf(staker) != 1){ // cuck  the non-hoomans outright
                stakingWeight = _amount / 10;
            }
            else if(IERC20(POE).balanceOf(staker) == 1){
                uint256 accounting = _amount;
                if (accounting >= minimumForBoost){
                    stakingWeight += minimumForBoost * 9; // 10x boost on minimum deposit
                }
                if (accounting <= minimumForBoost * 100){
                    stakingWeight += accounting; // 1x weight for small deposits
                }
                if (minimumForBoost * 100 < accounting && accounting <= minimumForBoost * 1000){
                    stakingWeight += minimumForBoost * 50;
                    accounting = accounting / 2;
                    stakingWeight += accounting; // 0.5x weight for medium deposits after cutoff
                }
                if(minimumForBoost * 1000 < accounting && accounting <= minimumForBoost * 10000){
                    stakingWeight += minimumForBoost * 500;
                    accounting = accounting / 4;
                    stakingWeight += accounting; // 0.25x weight for large deposits after cutoff
                }
                if(minimumForBoost * 10000 < accounting){
                    stakingWeight += minimumForBoost * 2750;
                    accounting = accounting / 8;
                    stakingWeight += accounting; // 0.125x weight for whale deposits after cutoff
                }
            }
        return stakingWeight;
    }

    /**
     * @dev Loops over all stakers from a pool, updating their accumulated rewards according
     * to their participation in the pool.
     */
    function updateStakersRewards(uint256 _poolId) private {
        Pool storage pool = pools[_poolId];
        for (uint256 i; i < pool.stakers.length; i++) {
            address stakerAddress = pool.stakers[i];
            PoolStaker storage staker = poolStakers[_poolId][stakerAddress];
            if (staker.amount == 0) return;
            uint256 stakedAmount = staker.amount;
            uint256 stakingWeight = 0;
            if(IERC20(POE).balanceOf(stakerAddress) != 1){ // cuck  the non-hoomans outright
                stakingWeight = stakedAmount / 10;
            }
            else if(IERC20(POE).balanceOf(stakerAddress) == 1){
                uint256 accounting = stakedAmount;
                if (accounting >= minimumForBoost){
                    stakingWeight += minimumForBoost * 9; // 10x boost on minimum deposit
                }
                if (accounting <= minimumForBoost * 100){
                    stakingWeight += accounting; // 1x weight for small deposits
                }
                if (minimumForBoost * 100 < accounting && accounting <= minimumForBoost * 1000){
                    stakingWeight += minimumForBoost * 50;
                    accounting = accounting / 2;
                    stakingWeight += accounting; // 0.5x weight for medium deposits after cutoff
                }
                if(minimumForBoost * 1000 < accounting && accounting <= minimumForBoost * 10000){
                    stakingWeight += minimumForBoost * 500;
                    accounting = accounting / 4;
                    stakingWeight += accounting; // 0.25x weight for large deposits after cutoff
                }
                if(minimumForBoost * 10000 < accounting){
                    stakingWeight += minimumForBoost * 2750;
                    accounting = accounting / 8;
                    stakingWeight += accounting; // 0.125x weight for whale deposits after cutoff
                }
            }

            staker.weight = stakingWeight; //update staker weight

            
            uint256 stakerShare = (stakingWeight * STAKER_SHARE_PRECISION / pool.totalWeight);
            uint256 blocksSinceLastReward = block.number - staker.lastRewardedBlock;
            uint256 rewards = (blocksSinceLastReward * rewardTokensPerBlock * stakerShare) / STAKER_SHARE_PRECISION;
            staker.lastRewardedBlock = block.number;
            staker.rewards = staker.rewards + rewards;
        }
    }
}