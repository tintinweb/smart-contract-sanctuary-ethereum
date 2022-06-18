//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {IERC20} from "./IERC20.sol";
import {SafeERC20} from "./SafeERC20.sol";
import {Ownable} from "./Ownable.sol";

contract StipendVault is Ownable{
    using SafeERC20 for IERC20; // Wrappers around ERC20 operations that throw on failure

    address public stipend; // Token to be paid as reward

    uint256 public rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant STAKER_SHARE_PRECISION = 1e12; // A big number to perform mul and div operations
    address public POE;
    uint256 public maxPercent = 10; // pool deposits over this % receives maximum nerf to weight

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
    function setMaxPercent(uint256 _new) external onlyOwner{
        maxPercent = _new;
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
        pool.tokensStaked += _amount;
        pool.totalWeight += estimateWeight(_amount, depositingStaker, _poolId);
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
        staker.weight = estimateWeight(staker.amount, msg.sender, _poolId);

        // Update pool
        pool.tokensStaked = pool.tokensStaked + _amount;

        if(accounting > 0){
            pool.totalWeight = pool.totalWeight + staker.weight - accounting;
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
    function withdrawAll(uint256 _poolId) external {
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
     * @dev Withdraw all tokens from an existing pool
     */
    function withdraw(uint256 _poolId, uint256 _amount) external {
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];
        uint256 prevAmount = staker.amount;
        uint256 weight = staker.weight;

        require(_amount > 0, "Withdraw amount can't be zero");
        require(prevAmount >= _amount, "Cannot withdraw more than total account deposit!");

        // Update pool stakers
        updateStakersRewards(_poolId);

        // Pay rewards
        harvestRewards(_poolId);

        // Update staker & pool
        staker.amount = prevAmount - _amount;
        pool.tokensStaked = pool.tokensStaked - _amount;

        staker.weight = estimateWeight(staker.amount, msg.sender, _poolId);
        
        pool.totalWeight = pool.totalWeight + staker.weight - weight;

        // Withdraw tokens
        emit Withdraw(msg.sender, _poolId, _amount);
        pool.stakeToken.safeTransfer(
            address(msg.sender),
            _amount
        );
    }

    /**
    * @dev Emergency withdraw all user tokens from pool.
    * WARNING: Forfeits all rewards
    * Backup if pool rewards are bugged so deposits don't get rugged.
    **/
    function emergencyWithdraw(uint256 _poolId) external {
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];
        uint256 amount = staker.amount;
        uint256 weight = staker.weight;
        uint256 weightToSubtract = weight;

        require(amount > 0, "Withdraw amount can't be zero");

        // Update pool stakers
        updateStakersRewards(_poolId);

        // Update staker
        staker.amount = 0;
        staker.weight = 0;
        staker.rewards = 0;

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
        IERC20(stipend).transfer(msg.sender, rewardsToHarvest);
    }

    function estimateWeight(uint256 _amount, address staker, uint256 _poolId) public view returns(uint256) {
        Pool storage pool = pools[_poolId];
        uint256 stakingWeight = 0;

        uint256 inversebrah = pool.tokensStaked / _amount; // get inverse of % of user deposit

        if(IERC20(POE).balanceOf(staker) != 1){ // cuck  the non-hoomans outright - 99% tax to non human
                stakingWeight = _amount / 100;
            }
        else if(IERC20(POE).balanceOf(staker) == 1){
            if(inversebrah <= maxPercent){
                stakingWeight = _amount / 20; // ASSUMING maxPercent = 10 (default): 95% tax on staker controlling >10% of pool
            }
            if(maxPercent < inversebrah && inversebrah <= maxPercent * 10){
                stakingWeight = _amount / 10; // 90% tax on staker controlling 1-10% of pool
            }
            if(maxPercent * 10 < inversebrah && inversebrah <= maxPercent * 100){
                stakingWeight = _amount / 5; // 80% tax on staker controlling 0.1-1% of pool
            }
            if(maxPercent * 100 < inversebrah && inversebrah <= maxPercent * 1000){
                stakingWeight = _amount / 2; // 50% tax on staker controlling 0.01-0.1% of pool
            }
            if(inversebrah > maxPercent * 1000){
                stakingWeight = _amount; // no tax on staker controlling < 0.01% of pool
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
            uint256 prevWeight = staker.weight;
            if (staker.amount == 0) return;
            uint256 stakedAmount = staker.amount;

            uint256 stakingWeight = estimateWeight(stakedAmount, stakerAddress, _poolId);
            if(stakingWeight != prevWeight){
                pool.totalWeight = pool.totalWeight + stakingWeight - prevWeight;
            }

            uint256 stakerShare = (stakingWeight * STAKER_SHARE_PRECISION / pool.totalWeight);
            uint256 blocksSinceLastReward = block.number - staker.lastRewardedBlock;
            uint256 rewards = (blocksSinceLastReward * rewardTokensPerBlock * stakerShare) / STAKER_SHARE_PRECISION;
            staker.lastRewardedBlock = block.number;
            staker.rewards = staker.rewards + rewards;
        }
    }
}