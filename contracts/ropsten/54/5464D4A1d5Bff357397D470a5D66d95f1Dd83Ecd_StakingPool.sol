// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.13;

/**
 * @title StakingPool
 * @author Tim Loh
 */
contract StakingPool {
    struct StakingPoolInfo {
        uint256 stakeDurationDays;
        // address stakeTokenAddress;
        // uint256 stakeTokenDecimals;
        // address rewardTokenAddress;
        // uint256 rewardTokenDecimals;
        uint256 poolAprWei; // pool APR in wei
        bool isOpen; // true if staking pool allows staking
        bool isActive; // true if staking pool allows claim rewards and unstake
        bool isInitialized; // true if staking pool has been initialized
    }

    uint256 public constant TOKEN_MAX_DECIMALS = 18;

    mapping(bytes32 => StakingPoolInfo) private _stakingPools;

    /**
     * @dev See {IStakingPool-getStakingPoolInfo}.
     */
    /*
    function getStakingPoolInfo(bytes32 poolId)
        external
        view
        virtual
        returns (
            uint256 stakeDurationDays,
            address,
            uint256,
            address,
            uint256,
            uint256 poolAprWei,
            bool isOpen,
            bool isActive
        )
    {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");

        stakeDurationDays = _stakingPools[poolId].stakeDurationDays;
        // stakeTokenAddress = _stakingPools[poolId].stakeTokenAddress;
        // stakeTokenDecimals = _stakingPools[poolId].stakeTokenDecimals;
        // rewardTokenAddress = _stakingPools[poolId].rewardTokenAddress;
        // rewardTokenDecimals = _stakingPools[poolId].rewardTokenDecimals;
        poolAprWei = _stakingPools[poolId].poolAprWei;
        isOpen = _stakingPools[poolId].isOpen;
        isActive = _stakingPools[poolId].isActive;
    }
    */

    /**
     * @dev See {IStakingPool-closeStakingPool}.
     */
    /*
    function closeStakingPool(bytes32 poolId) external virtual {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(_stakingPools[poolId].isOpen, "SPool: closed");

        _stakingPools[poolId].isOpen = false;

        // emit StakingPoolClosed(poolId, msg.sender);
    }
    */

    /**
     * @dev See {IStakingPool-createStakingPool}.
     */
    /*
    function createStakingPool(
        bytes32 poolId,
        uint256 stakeDurationDays,
        address stakeTokenAddress,
        uint256 stakeTokenDecimals,
        address rewardTokenAddress,
        uint256 rewardTokenDecimals,
        uint256 poolAprWei
    ) external virtual {
        require(stakeDurationDays > 0, "SPool: stake duration");
        require(stakeTokenAddress != address(0), "SPool: stake token");
        require(
            stakeTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SPool: stake decimals"
        );
        require(rewardTokenAddress != address(0), "SPool: reward token");
        require(
            rewardTokenDecimals <= TOKEN_MAX_DECIMALS,
            "SPool: reward decimals"
        );
        require(
            stakeTokenAddress != rewardTokenAddress ||
                stakeTokenDecimals == rewardTokenDecimals,
            "SPool: decimals different"
        );
        require(poolAprWei > 0, "SPool: pool APR");

        require(!_stakingPools[poolId].isInitialized, "SPool: exists");

        _stakingPools[poolId] = StakingPoolInfo({
            stakeDurationDays: stakeDurationDays,
            // stakeTokenAddress: stakeTokenAddress,
            // stakeTokenDecimals: stakeTokenDecimals,
            // rewardTokenAddress: rewardTokenAddress,
            // rewardTokenDecimals: rewardTokenDecimals,
            poolAprWei: poolAprWei,
            isOpen: true,
            isActive: true,
            isInitialized: true
        });

        // emit StakingPoolCreated(
        //     poolId,
        //     msg.sender,
        //     stakeDurationDays,
        //     stakeTokenAddress,
        //     stakeTokenDecimals,
        //     rewardTokenAddress,
        //     rewardTokenDecimals,
        //     poolAprWei
        // );
    }
    */

    /**
     * @dev See {IStakingPool-openStakingPool}.
     */
    function openStakingPool(bytes32 poolId) external virtual {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(!_stakingPools[poolId].isOpen, "SPool: opened");

        _stakingPools[poolId].isOpen = true;

        // emit StakingPoolOpened(poolId, msg.sender);
    }

    /**
     * @dev See {IStakingPool-resumeStakingPool}.
     */
    /*
    function resumeStakingPool(bytes32 poolId) external virtual {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(!_stakingPools[poolId].isActive, "SPool: active");

        _stakingPools[poolId].isActive = true;

        // emit StakingPoolResumed(poolId, msg.sender);
    }
    */

    /**
     * @dev See {IStakingPool-suspendStakingPool}.
     */
    /*
    function suspendStakingPool(bytes32 poolId) external virtual {
        require(_stakingPools[poolId].isInitialized, "SPool: uninitialized");
        require(_stakingPools[poolId].isActive, "SPool: suspended");

        _stakingPools[poolId].isActive = false;

        // emit StakingPoolSuspended(poolId, msg.sender);
    }
    */
}