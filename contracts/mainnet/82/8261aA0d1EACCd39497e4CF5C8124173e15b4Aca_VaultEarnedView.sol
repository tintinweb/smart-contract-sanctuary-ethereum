// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IConvexWrapperV2.sol";
import "./interfaces/IFraxFarmERC20.sol";
import "./interfaces/IRewards.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


contract VaultEarnedView{    

    constructor() {
    }

    //helper function to combine earned tokens on staking contract and any tokens that are on this vault
    function earned(address _stakingAddress, address _wrapper, address _extrarewards, address _vault) external returns (address[] memory token_addresses, uint256[] memory total_earned) {
        //simulate claim on wrapper
        IConvexWrapperV2(_wrapper).getReward(_vault);

        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20(_stakingAddress).getAllRewardTokens();
        uint256[] memory stakedearned = IFraxFarmERC20(_stakingAddress).earned(_vault);
        uint256 convexrewardCnt = IConvexWrapperV2(_wrapper).rewardLength();


        uint256 extraRewardsLength;
        if(_extrarewards != address(0)){
            extraRewardsLength = IRewards(_extrarewards).rewardTokenLength();
        }

        token_addresses = new address[](rewardTokens.length + extraRewardsLength + convexrewardCnt);
        total_earned = new uint256[](rewardTokens.length + extraRewardsLength + convexrewardCnt);

        //add any tokens that happen to be already claimed but sitting on the vault
        //(ex. withdraw claiming rewards)
        for(uint256 i = 0; i < rewardTokens.length; i++){
            token_addresses[i] = rewardTokens[i];
            total_earned[i] = stakedearned[i] + IERC20(rewardTokens[i]).balanceOf(_vault);
        }

        if(_extrarewards != address(0)){
            IRewards.EarnedData[] memory extraRewards = IRewards(_extrarewards).claimableRewards(_vault);
            for(uint256 i = 0; i < extraRewards.length; i++){
                token_addresses[i+rewardTokens.length] = extraRewards[i].token;
                total_earned[i+rewardTokens.length] = extraRewards[i].amount;
            }
        }

        //add convex farm earned tokens
        for(uint256 i = 0; i < convexrewardCnt; i++){
            IConvexWrapperV2.RewardType memory rinfo = IConvexWrapperV2(_wrapper).rewards(i);
            token_addresses[i+rewardTokens.length+extraRewardsLength] = rinfo.reward_token;
            //claimed so just look at local balance
            total_earned[i+rewardTokens.length+extraRewardsLength] = IERC20(rinfo.reward_token).balanceOf(_vault);
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IRewards{
    struct EarnedData {
        address token;
        uint256 amount;
    }
    
    function initialize(uint256 _pid, bool _startActive) external;
    function addReward(address _rewardsToken, address _distributor) external;
    function approveRewardDistributor(
        address _rewardsToken,
        address _distributor,
        bool _approved
    ) external;
    function deposit(address _owner, uint256 _amount) external;
    function withdraw(address _owner, uint256 _amount) external;
    function getReward(address _forward) external;
    function notifyRewardAmount(address _rewardsToken, uint256 _reward) external;
    function balanceOf(address account) external view returns (uint256);
    function claimableRewards(address _account) external view returns(EarnedData[] memory userRewards);
    function rewardTokens(uint256 _rid) external view returns (address);
    function rewardTokenLength() external view returns(uint256);
    function active() external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IFraxFarmERC20 {
    
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    function owner() external view returns (address);
    function stakingToken() external view returns (address);
    function fraxPerLPToken() external view returns (uint256);
    function calcCurCombinedWeight(address account) external view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );
    function lockedStakesOf(address account) external view returns (LockedStake[] memory);
    function lockedStakesOfLength(address account) external view returns (uint256);
    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;
    function lockLonger(bytes32 kek_id, uint256 new_ending_ts) external;
    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);
    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256);



    function periodFinish() external view returns (uint256);
    function getAllRewardTokens() external view returns (address[] memory);
    function earned(address account) external view returns (uint256[] memory new_earned);
    function totalLiquidityLocked() external view returns (uint256);
    function lockedLiquidityOf(address account) external view returns (uint256);
    function totalCombinedWeight() external view returns (uint256);
    function combinedWeightOf(address account) external view returns (uint256);
    function lockMultiplier(uint256 secs) external view returns (uint256);
    function rewardRates(uint256 token_idx) external view returns (uint256 rwd_rate);

    function userStakedFrax(address account) external view returns (uint256);
    function proxyStakedFrax(address proxy_address) external view returns (uint256);
    function maxLPForMaxBoost(address account) external view returns (uint256);
    function minVeFXSForMaxBoost(address account) external view returns (uint256);
    function minVeFXSForMaxBoostProxy(address proxy_address) external view returns (uint256);
    function veFXSMultiplier(address account) external view returns (uint256 vefxs_multiplier);

    function toggleValidVeFXSProxy(address proxy_address) external;
    function proxyToggleStaker(address staker_address) external;
    function stakerSetVeFXSProxy(address proxy_address) external;
    function getReward(address destination_address) external returns (uint256[] memory);
    function vefxs_max_multiplier() external view returns(uint256);
    function vefxs_boost_scale_factor() external view returns(uint256);
    function vefxs_per_frax_for_max_boost() external view returns(uint256);
    function getProxyFor(address addr) external view returns (address);

    function sync() external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IConvexWrapperV2{

   struct EarnedData {
        address token;
        uint256 amount;
    }

   struct RewardType {
        address reward_token;
        address reward_pool;
        uint128 reward_integral;
        uint128 reward_remaining;
    }

  function collateralVault() external view returns(address vault);
  function convexPoolId() external view returns(uint256 _poolId);
  function curveToken() external view returns(address);
  function convexToken() external view returns(address);
  function balanceOf(address _account) external view returns(uint256);
  function totalBalanceOf(address _account) external view returns(uint256);
  function deposit(uint256 _amount, address _to) external;
  function stake(uint256 _amount, address _to) external;
  function withdraw(uint256 _amount) external;
  function withdrawAndUnwrap(uint256 _amount) external;
  function getReward(address _account) external;
  function getReward(address _account, address _forwardTo) external;
  function rewardLength() external view returns(uint256);
  function rewards(uint256 _index) external view returns(RewardType memory rewardInfo);
  function earned(address _account) external returns(EarnedData[] memory claimable);
  function earnedView(address _account) external view returns(EarnedData[] memory claimable);
  function setVault(address _vault) external;
  function user_checkpoint(address[2] calldata _accounts) external returns(bool);
}

// SPDX-License-Identifier: MIT

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