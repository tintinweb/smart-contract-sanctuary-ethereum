// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import {IFraxswap} from "@interfaces/IFraxFarm.sol";

/// @notice Provides the price of pitchFXS token in FRAX (wei)

contract PriceOraclePitchFXS {
    address public constant PITCHFXS_FRAXSWAP = address(0x0a92aC70B5A187fB509947916a8F63DD31600F80);
    address public constant PITCHFXS = address(0x11EBe21e9d7BF541A18e1E3aC94939018Ce88F0b);
    address public constant FRAX = address(0x853d955aCEf822Db058eb8505911ED77F175b99e);

    function getUSDPrice(address token) external view returns (uint256 priceInWei) {
        require(token == PITCHFXS, "!PITCHFXS");
        require(
            IFraxswap(PITCHFXS_FRAXSWAP).token0() == PITCHFXS && IFraxswap(PITCHFXS_FRAXSWAP).token1() == FRAX,
            "!TokenOrder"
        );

        // get the reserves from fraxswap
        (uint112 token0Reserve, uint112 token2Reserve, ) = IFraxswap(PITCHFXS_FRAXSWAP).getReserves();

        // convert to uint256 for return value
        uint256 token0Amt = uint256(token0Reserve);
        uint256 token1Amt = uint256(token2Reserve);

        // price is in FRAX wei
        priceInWei = (1e18 * token1Amt) / token0Amt;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IFraxswap {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

/// @notice Minimalistic IFraxFarmUniV3
interface IFraxFarmUniV3TokenPositions {
    function uni_token0() external view returns (address);

    function uni_token1() external view returns (address);
}

interface IFraxswapERC20 {
    function decimals() external view returns (uint8);
}

interface IFraxFarm {
    function owner() external view returns (address);

    function stakingToken() external view returns (address);

    function fraxPerLPToken() external view returns (uint256);

    function calcCurCombinedWeight(address account)
        external
        view
        returns (
            uint256 old_combined_weight,
            uint256 new_vefxs_multiplier,
            uint256 new_combined_weight
        );

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

    function getReward(address destination_address, bool also_claim_extra) external returns (uint256[] memory);

    function vefxs_max_multiplier() external view returns (uint256);

    function vefxs_boost_scale_factor() external view returns (uint256);

    function vefxs_per_frax_for_max_boost() external view returns (uint256);

    function getProxyFor(address addr) external view returns (address);

    function sync() external;

    function nominateNewOwner(address _owner) external;

    function acceptOwnership() external;

    function updateRewardAndBalance(address acct, bool sync) external;

    function setRewardVars(
        address reward_token_address,
        uint256 _new_rate,
        address _gauge_controller_address,
        address _rewards_distributor_address
    ) external;

    function calcCurrLockMultiplier(address account, uint256 stake_idx)
        external
        view
        returns (uint256 midpoint_lock_multiplier);

    function staker_designated_proxies(address staker_address) external view returns (address);
}

interface IFraxFarmERC20 is IFraxFarm {
    struct LockedStake {
        bytes32 kek_id;
        uint256 start_timestamp;
        uint256 liquidity;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
    }

    /// TODO this references the public getter for `lockedStakes` in the contract
    function lockedStakes(address account, uint256 stake_idx) external view returns (LockedStake memory);

    function lockedStakesOf(address account) external view returns (LockedStake[] memory);

    function lockedStakesOfLength(address account) external view returns (uint256);

    function lockAdditional(bytes32 kek_id, uint256 addl_liq) external;

    function lockLonger(bytes32 kek_id, uint256 _newUnlockTimestamp) external;

    function stakeLocked(uint256 liquidity, uint256 secs) external returns (bytes32);

    function withdrawLocked(bytes32 kek_id, address destination_address) external returns (uint256);
}

interface IFraxFarmUniV3 is IFraxFarm, IFraxFarmUniV3TokenPositions {
    struct LockedNFT {
        uint256 token_id; // for Uniswap V3 LPs
        uint256 liquidity;
        uint256 start_timestamp;
        uint256 ending_timestamp;
        uint256 lock_multiplier; // 6 decimals of precision. 1x = 1000000
        int24 tick_lower;
        int24 tick_upper;
    }

    function uni_tick_lower() external view returns (int24);

    function uni_tick_upper() external view returns (int24);

    function uni_required_fee() external view returns (uint24);

    function lockedNFTsOf(address account) external view returns (LockedNFT[] memory);

    function lockedNFTsOfLength(address account) external view returns (uint256);

    function lockAdditional(
        uint256 token_id,
        uint256 token0_amt,
        uint256 token1_amt,
        uint256 token0_min_in,
        uint256 token1_min_in,
        bool use_balof_override
    ) external;

    function stakeLocked(uint256 token_id, uint256 secs) external;

    function withdrawLocked(uint256 token_id, address destination_address) external;
}