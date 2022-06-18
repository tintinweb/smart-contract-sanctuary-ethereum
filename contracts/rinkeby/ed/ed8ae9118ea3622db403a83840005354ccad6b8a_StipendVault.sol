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

    uint256 private rewardTokensPerBlock; // Number of reward tokens minted per block
    uint256 private constant STAKER_SHARE_PRECISION = 1e12; // A big number to perform mul and div operations

    // Staking user for a pool
    struct PoolStaker {
        uint256 amount; // The tokens quantity the user has staked.
        uint256 rewards; // The reward tokens quantity the user can harvest
        uint256 lastRewardedBlock; // Last block number the user had their rewards calculated
    }

    // Staking pool
    struct Pool {
        IERC20 stakeToken; // Token to be staked
        uint256 tokensStaked; // Total tokens staked
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
    constructor(address _rewardTokenAddress, uint256 _rewardTokensPerBlock) {
        stipend = _rewardTokenAddress;
        rewardTokensPerBlock = _rewardTokensPerBlock;
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

    /**
     * @dev Add staker address to the pool stakers if it's not there already
     * We don't have to remove it because if it has amount 0 it won't affect rewards.
     * (but it might save gas in the long run)
     */
    function addStakerToPoolIfInexistent(uint256 _poolId, address depositingStaker) private {
        Pool storage pool = pools[_poolId];
        for (uint256 i; i < pool.stakers.length; i++) {
            address existingStaker = pool.stakers[i];
            if (existingStaker == depositingStaker) return;
        }
        pool.stakers.push(msg.sender);
    }

    /**
     * @dev Deposit tokens to an existing pool
     */
    function deposit(uint256 _poolId, uint256 _amount) external {
        require(_amount > 0, "Deposit amount can't be zero");
        Pool storage pool = pools[_poolId];
        PoolStaker storage staker = poolStakers[_poolId][msg.sender];

        // Update pool stakers
        updateStakersRewards(_poolId);
        addStakerToPoolIfInexistent(_poolId, msg.sender);

        // Update current staker
        staker.amount = staker.amount + _amount;
        staker.lastRewardedBlock = block.number;

        // Update pool
        pool.tokensStaked = pool.tokensStaked + _amount;

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
        require(amount > 0, "Withdraw amount can't be zero");

        // Update pool stakers
        updateStakersRewards(_poolId);

        // Pay rewards
        harvestRewards(_poolId);

        // Update staker
        staker.amount = 0;

        // Update pool
        pool.tokensStaked = pool.tokensStaked - amount;

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
            uint256 stakerShare = (stakedAmount * STAKER_SHARE_PRECISION / pool.tokensStaked);
            uint256 blocksSinceLastReward = block.number - staker.lastRewardedBlock;
            uint256 rewards = (blocksSinceLastReward * rewardTokensPerBlock * stakerShare) / STAKER_SHARE_PRECISION;
            staker.lastRewardedBlock = block.number;
            staker.rewards = staker.rewards + rewards;
        }
    }
}