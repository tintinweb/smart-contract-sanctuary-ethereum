/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.7;

contract StakingStateMigrateTest {
    /// @notice This struct stores information regarding a user stakes
    struct Stake {
        uint256 stakedAt;
        uint256 stakedAmount;
    }

    /// @notice Mapping to store user stakes.
    mapping(address => mapping(uint256 => Stake)) public stakes;

    /// @notice Array to store users with active stakes
    address[] public activeStakeOwners;

    /// @notice Mapping to store user stake ids in array
    mapping(address => uint256[]) public userStakeIds;

    /// @notice This struct stores information regarding a user unstakes
    struct UnStake {
        uint256 stakedAt;
        uint256 unStakedAt;
        uint256 stakedAmount;
        uint256 penalty;
    }

    /// @notice Mapping to store user unstakes.
    mapping(address => mapping(uint256 => UnStake)) public unStakes;

     /// @notice Mapping to store user unstake ids in array
    mapping(address => uint256[]) public userUnStakeIds;

    /// @notice Mapping to store total amount staked of a user
    mapping(address => uint256) public userStakedAmount;

    function migrateStakingState(
        address[] memory _addresses,
        uint256[] memory _stakeIds,
        uint256[] memory _stakedAmounts,
        uint256[] memory _stakedAtArray
    ) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address _staker = _addresses[i];
            uint256 _stakeId = _stakeIds[i];
            uint256 _stakedAmount = _stakedAmounts[i];
            stakes[_staker][_stakeId] = Stake(_stakedAtArray[i], _stakedAmount);
            userStakeIds[_staker].push(_stakeId);
            userStakedAmount[_staker] += _stakedAmount;
        }
    }

    function migrateUnstakingState(
        address[] memory _addresses,
        uint256[] memory _unstakeIds,
        uint256[] memory _stakedAtArray,
        uint256[] memory _unstakedAtArray,
        uint256[] memory _unstakedAmountArray,
        uint256[] memory _penaltyArray
    ) external {
        for (uint256 i = 0; i < _addresses.length; i++) {
            address staker = _addresses[i];
            uint256 stakeId = _unstakeIds[i];
            unStakes[staker][stakeId] = UnStake(
                _stakedAtArray[i],
                _unstakedAtArray[i],
                _unstakedAmountArray[i],
                _penaltyArray[i]
            );
            userUnStakeIds[staker].push(stakeId);
        }
    }
}