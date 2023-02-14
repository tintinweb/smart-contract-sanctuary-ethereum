// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IApeCoinStaking {
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }

    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }

    event ClaimRewards(address indexed user, uint256 amount, address recipient);
    event ClaimRewardsNft(address indexed user, uint256 indexed poolId, uint256 amount, uint256 tokenId);
    event ClaimRewardsPairNft(address indexed user, uint256 amount, uint256 mainTypePoolId, uint256 mainTokenId, uint256 bakcTokenId);
    event Deposit(address indexed user, uint256 amount, address recipient);
    event DepositNft(address indexed user, uint256 indexed poolId, uint256 amount, uint256 tokenId);
    event DepositPairNft(address indexed user, uint256 amount, uint256 mainTypePoolId, uint256 mainTokenId, uint256 bakcTokenId);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event UpdatePool(uint256 indexed poolId, uint256 lastRewardedBlock, uint256 stakedAmount, uint256 accumulatedRewardsPerShare);
    event Withdraw(address indexed user, uint256 amount, address recipient);
    event WithdrawNft(address indexed user, uint256 indexed poolId, uint256 amount, address recipient, uint256 tokenId);
    event WithdrawPairNft(address indexed user, uint256 amount, uint256 mainTypePoolId, uint256 mainTokenId, uint256 bakcTokenId);

    function addTimeRange(
        uint256 _poolId,
        uint256 _amount,
        uint256 _startTimestamp,
        uint256 _endTimeStamp,
        uint256 _capPerPosition
    ) external;

    function addressPosition(address) external view returns (uint256 stakedAmount, int256 rewardsDebt);

    function apeCoin() external view returns (address);

    function bakcToMain(uint256, uint256) external view returns (uint248 tokenId, bool isPaired);

    function claimApeCoin(address _recipient) external;

    function claimBAKC(PairNft[] memory _baycPairs, PairNft[] memory _maycPairs, address _recipient) external;

    function claimBAYC(uint256[] memory _nfts, address _recipient) external;

    function claimMAYC(uint256[] memory _nfts, address _recipient) external;

    function claimSelfApeCoin() external;

    function claimSelfBAKC(PairNft[] memory _baycPairs, PairNft[] memory _maycPairs) external;

    function claimSelfBAYC(uint256[] memory _nfts) external;

    function claimSelfMAYC(uint256[] memory _nfts) external;

    function depositApeCoin(uint256 _amount, address _recipient) external;

    function depositBAKC(PairNftDepositWithAmount[] memory _baycPairs, PairNftDepositWithAmount[] memory _maycPairs) external;

    function depositBAYC(SingleNft[] memory _nfts) external;

    function depositMAYC(SingleNft[] memory _nfts) external;

    function depositSelfApeCoin(uint256 _amount) external;

    function getAllStakes(address _address) external view returns (DashboardStake[] memory);

    function getApeCoinStake(address _address) external view returns (DashboardStake memory);

    function getBakcStakes(address _address) external view returns (DashboardStake[] memory);

    function getBaycStakes(address _address) external view returns (DashboardStake[] memory);

    function getMaycStakes(address _address) external view returns (DashboardStake[] memory);

    function getPoolsUI() external view returns (PoolUI memory, PoolUI memory, PoolUI memory, PoolUI memory);

    function getSplitStakes(address _address) external view returns (DashboardStake[] memory);

    function getTimeRangeBy(uint256 _poolId, uint256 _index) external view returns (TimeRange memory);

    function mainToBakc(uint256, uint256) external view returns (uint248 tokenId, bool isPaired);

    function nftContracts(uint256) external view returns (address);

    function nftPosition(uint256, uint256) external view returns (uint256 stakedAmount, int256 rewardsDebt);

    function owner() external view returns (address);

    function pendingRewards(uint256 _poolId, address _address, uint256 _tokenId) external view returns (uint256);

    function pools(
        uint256
    )
        external
        view
        returns (uint48 lastRewardedTimestampHour, uint16 lastRewardsRangeIndex, uint96 stakedAmount, uint96 accumulatedRewardsPerShare);

    function removeLastTimeRange(uint256 _poolId) external;

    function renounceOwnership() external;

    function rewardsBy(uint256 _poolId, uint256 _from, uint256 _to) external view returns (uint256, uint256);

    function stakedTotal(address _address) external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function updatePool(uint256 _poolId) external;

    function withdrawApeCoin(uint256 _amount, address _recipient) external;

    function withdrawBAKC(PairNftWithdrawWithAmount[] memory _baycPairs, PairNftWithdrawWithAmount[] memory _maycPairs) external;

    function withdrawBAYC(SingleNft[] memory _nfts, address _recipient) external;

    function withdrawMAYC(SingleNft[] memory _nfts, address _recipient) external;

    function withdrawSelfApeCoin(uint256 _amount) external;

    function withdrawSelfBAYC(SingleNft[] memory _nfts) external;

    function withdrawSelfMAYC(SingleNft[] memory _nfts) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "interfaces/IApeCoinStaking.sol";

contract MagicApeLens {
    uint256 constant PRECISION = 1e18;
    uint256 constant BPS_PRECISION = 1e4;
    address public constant APE_COIN_STAKING_CONTRACT = 0x5954aB967Bc958940b7EB73ee84797Dc8a2AFbb9;
    address public constant APE_COIN_CONTRACT = 0x4d224452801ACEd8B2F0aebE155379bb5D594381;

    struct PoolInfo {
        uint256 apr;
        uint256 stakedAmount;
        uint256 poolRewardsPerHour;
        uint256 poolRewardsPerDay;
        uint256 rewardPerHour;
        uint256 poolRewardsPerTokenPerDay;
    }

    function getApeCoinInfo() external view returns (PoolInfo memory info) {
        (IApeCoinStaking.PoolUI memory apeCoinInfo, , , ) = IApeCoinStaking(APE_COIN_STAKING_CONTRACT).getPoolsUI();
        return getPoolInfo(apeCoinInfo);
    }

    function getBAYCInfo() external view returns (PoolInfo memory info) {
        (, IApeCoinStaking.PoolUI memory baycInfo, , ) = IApeCoinStaking(APE_COIN_STAKING_CONTRACT).getPoolsUI();
        return getPoolInfo(baycInfo);
    }

    function getMAYCInfo() external view returns (PoolInfo memory info) {
        (, , IApeCoinStaking.PoolUI memory maycInfo, ) = IApeCoinStaking(APE_COIN_STAKING_CONTRACT).getPoolsUI();
        return getPoolInfo(maycInfo);
    }

    function getBAKCInfo() external view returns (PoolInfo memory info) {
        (, , , IApeCoinStaking.PoolUI memory bakcInfo) = IApeCoinStaking(APE_COIN_STAKING_CONTRACT).getPoolsUI();
        return getPoolInfo(bakcInfo);
    }

    function getPoolInfo(IApeCoinStaking.PoolUI memory poolUI) public pure returns (PoolInfo memory info) {
        uint256 poolRewardsPerHour = poolUI.currentTimeRange.rewardsPerHour;
        uint256 poolRewardsPerDay = poolRewardsPerHour * 24;
        uint256 poolRewardsPerTokenPerHour = computeRewardPerHour(uint256(poolRewardsPerHour), poolUI.stakedAmount);
        uint256 poolRewardsPerTokenPerDay = poolRewardsPerTokenPerHour * 24;
        uint256 apr = (poolRewardsPerTokenPerDay * 365 * BPS_PRECISION) / PRECISION;

        return
            PoolInfo(
                apr,
                poolUI.stakedAmount,
                poolRewardsPerHour,
                poolRewardsPerDay,
                poolRewardsPerTokenPerHour,
                poolRewardsPerTokenPerDay
            );
    }

    function computeRewardPerHour(uint256 poolRewardsPerHour, uint256 stakedAmount) public pure returns (uint256 rewardPerHour) {
        return (poolRewardsPerHour * PRECISION) / stakedAmount;
    }
}