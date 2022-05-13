// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./interfaces/IFraxFarmERC20.sol";
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';


/*
This is a utility library which is mainly used for off chain calculations
*/
contract PoolUtilities{
    address public constant convexProxy = address(0x59CFCD384746ec3035299D90782Be065e466800B);
    address public constant vefxs = address(0xc8418aF6358FFddA74e09Ca9CC3Fe03Ca6aDC5b0);

    //get weighted reward rates of a specific staking contract(rate per weight unit)
    function weightedRewardRates(address _stakingAddress) public view returns (uint256[] memory weightedRates) {
        //get list of reward tokens
        address[] memory rewardTokens = IFraxFarmERC20(_stakingAddress).getAllRewardTokens();
        //get total weight of all stakers
        uint256 totalWeight = IFraxFarmERC20(_stakingAddress).totalCombinedWeight();

        weightedRates = new uint256[](rewardTokens.length);

        if(totalWeight == 0) return weightedRates;

        //calc weighted reward rates
        for (uint256 i = 0; i < rewardTokens.length; i++){ 
            weightedRates[i] = IFraxFarmERC20(_stakingAddress).rewardRates(i) * 1e18 / totalWeight;
        }
    }

    //get boosted reward rate of user at a specific staking contract
    //returns amount user receives per second based on weight/liq ratio
    //%return = userBoostedRewardRate * timeFrame * price of reward / price of LP / 1e18
    function userBoostedRewardRates(address _stakingAddress, address _vaultAddress) external view returns (uint256[] memory boostedRates) {
        //get list of reward tokens
        uint256[] memory wrr = weightedRewardRates(_stakingAddress);

        //get user liquidity and weight
        uint256 userLiq = IFraxFarmERC20(_stakingAddress).lockedLiquidityOf(_vaultAddress);
        uint256 userWeight = IFraxFarmERC20(_stakingAddress).combinedWeightOf(_vaultAddress);

        boostedRates = new uint256[](wrr.length);

        if(userLiq == 0) return boostedRates;

        //calc boosted rates
        for (uint256 i = 0; i < wrr.length; i++){ 
            boostedRates[i] = wrr[i] * userWeight / userLiq;
        }
    }

    
    //get convex vefxs multiplier for a specific staking contract
    function veFXSMultiplier(address _stakingAddress) public view returns (uint256 vefxs_multiplier) {
        uint256 vefxs_bal_to_use = IERC20(vefxs).balanceOf(convexProxy);
        uint256 vefxs_max_multiplier = IFraxFarmERC20(_stakingAddress).vefxs_max_multiplier();

        // First option based on fraction of total veFXS supply, with an added scale factor
        uint256 mult_optn_1 = (vefxs_bal_to_use * vefxs_max_multiplier * IFraxFarmERC20(_stakingAddress).vefxs_boost_scale_factor()) 
                            / (IERC20(vefxs).totalSupply() * 1e18);

        // Second based on old method, where the amount of FRAX staked comes into play
        uint256 mult_optn_2;
        {
            uint256 veFXS_needed_for_max_boost;

            // Need to use proxy-wide FRAX balance if applicable, to prevent exploiting
            veFXS_needed_for_max_boost = IFraxFarmERC20(_stakingAddress).minVeFXSForMaxBoostProxy(convexProxy);

            if (veFXS_needed_for_max_boost > 0){ 
                uint256 user_vefxs_fraction = (vefxs_bal_to_use * 1e18) / veFXS_needed_for_max_boost;
                
                mult_optn_2 = (user_vefxs_fraction * vefxs_max_multiplier) / 1e18;
            }
            else mult_optn_2 = 0; // This will happen with the first stake, when user_staked_frax is 0
        }

        // Select the higher of the two
        vefxs_multiplier = (mult_optn_1 > mult_optn_2 ? mult_optn_1 : mult_optn_2);

        // Cap the boost to the vefxs_max_multiplier
        if (vefxs_multiplier > vefxs_max_multiplier) vefxs_multiplier = vefxs_max_multiplier;
    }
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
    function stakeLocked(uint256 liquidity, uint256 secs) external;
    function withdrawLocked(bytes32 kek_id, address destination_address) external;



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