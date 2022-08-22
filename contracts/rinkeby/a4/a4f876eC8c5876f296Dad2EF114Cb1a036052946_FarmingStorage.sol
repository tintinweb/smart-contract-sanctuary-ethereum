// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedProxy_New } from './../interfaces/IGovernedProxy_New.sol';
import { IFarmingStorage } from './IFarmingStorage.sol';

contract FarmingStorage is IFarmingStorage {
    uint256 test0 = 0;
    address private managerProxyAddress;
    address private token0;
    address private token1;
    // Accumulated rewards that a virtual LP token would have collected
    // when staked since the inception of this farming pool
    uint256 private accruedRewardsPerToken;
    // Amount of LP tokens staked in this farming pool
    uint256 private stakedTokenAmount;

    // Number of allocation points assigned to this pool.
    // The higher the allocation points the more this farming pool pays out.
    uint256 private allocPoints;
    // LP tokens in this farming pool will be locked for some amount of time before they can be withdrawn.
    uint256 private lockingPeriodInSeconds;

    // Whenever a staker adds a new amount of LP tokens to this farming pool
    // a LockingParcel is created which tracks the lockTime
    // that these LP tokens were added to this farming pool.
    struct LockingParcel {
        uint256 lockTime;
        uint256 amount;
    }

    // The `LockingParcels` are created consecutively for each staker
    // and tracked in this mapping for each staker.
    // stakerAddress => index of LockingParcel => LockingParcel
    mapping(address => mapping(uint256 => LockingParcel)) private lockingParcels;

    // To be able to add a new LockingParcel in the mapping `lockingParcels`, we
    // track the next free index for adding a LockingParcel to the mapping `lockingParcels`.
    // stakerAddress => next free index for adding a LockingParcel
    mapping(address => uint256) private newestLockingParcelIndexes;

    // When a staker withdraws/removes their LP tokens from this farming pool,
    // we update this index to track which of the `LockingParcels`
    // have been already withdrawn/removed. Since the `LockingParcels`
    // have been created consecutively a staker removes/withdraws the oldest/lowest-indexed
    // parcels first. The oldestLockingParcelIndex is the oldest, currently active, locking parcel.
    // stakerAddress => oldest/lowest-indexed `LockingParcel` that has not been withdrawn/removed yet
    mapping(address => uint256) private oldestLockingParcelIndexes;

    // When a staker calls a storage mutative function (meaning one of the functions stake/withdraw/exit/getReward),
    // the rewards owed to this staker are calculated and updated, we then set the rewardPerTokenPaid value
    // to the global accruedRewardsPerToken value.
    // Those rewards have not been paid yet, but they rather represent a quantity
    // to be subtracted from accruedRewardPerToken in order to get what is owed
    // to the staker for the last time period since this staker called a storage mutative function.
    // stakerAddress => rewardPerTokenPaid
    mapping(address => uint256) private rewardPerTokenPaid;
    // stakerAddress => owed rewards to the staker (rewards that have not been payed out to the staker yet)
    mapping(address => uint256) private owedRewards;
    // stakerAddress => amount of LP tokens staked by the staker
    mapping(address => uint256) private balances;

    // If maxPoolRewardPerTokenPerSecond is set low enough then the farming pool payout is NOT related to
    // the totalRewardRate anymore but instead related to this maxPoolRewardPerTokenPerSecond value.
    // The maxPoolRewardPerTokenPerSecond value can only reduce the amount of payout that this pool
    // receives from the totalRewardRate, it will not cause the farming pool to payout more than
    // the usual portion of the totalRewardRate that this pool receives.
    // If maxPoolRewardPerTokenPerSecond is set to 0, the maxPoolRewardPerTokenPerSecond value is ignored.
    uint256 private maxPoolRewardPerTokenPerSecond;

    constructor(
        address _managerProxyAddress,
        address _token0,
        address _token1,
        uint256 _lockingPeriodInSeconds,
        uint256 _allocPoints
    ) public {
        managerProxyAddress = _managerProxyAddress;
        token0 = _token0;
        token1 = _token1;
        lockingPeriodInSeconds = _lockingPeriodInSeconds;
        allocPoints = _allocPoints;
    }

    modifier requireManager() {
        require(
            msg.sender ==
                address(IGovernedProxy_New(address(uint160(managerProxyAddress))).implementation()),
            'FarmingStorage: FORBIDDEN, not Manager'
        );
        _;
    }

    function getOldestLockingParcelIndex(address _stakerAddress) external view returns (uint256) {
        return oldestLockingParcelIndexes[_stakerAddress];
    }

    function getMaxPoolRewardPerTokenPerSecond() external view returns (uint256) {
        return maxPoolRewardPerTokenPerSecond;
    }

    function getNewestLockingParcelIndex(address _stakerAddress) external view returns (uint256) {
        return newestLockingParcelIndexes[_stakerAddress];
    }

    function getLockingParcel(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256 amount, uint256 lockTime)
    {
        return (
            lockingParcels[_stakerAddress][_index].amount,
            lockingParcels[_stakerAddress][_index].lockTime
        );
    }

    function getLockingParcelAmount(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256)
    {
        return lockingParcels[_stakerAddress][_index].amount;
    }

    function getLockingParcelLockTime(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256)
    {
        return lockingParcels[_stakerAddress][_index].lockTime;
    }

    function getAllocPoints() external view returns (uint256) {
        return allocPoints;
    }

    function getLockingPeriodInSeconds() external view returns (uint256) {
        return lockingPeriodInSeconds;
    }

    function getBalance(address _account) external view returns (uint256) {
        return balances[_account];
    }

    function getManagerProxyAddress() external view returns (address) {
        return managerProxyAddress;
    }

    function getRewardPerTokenPaid(address _account) external view returns (uint256) {
        return rewardPerTokenPaid[_account];
    }

    function getOwedRewards(address _account) external view returns (uint256) {
        return owedRewards[_account];
    }

    function getStakedTokenAmount() external view returns (uint256) {
        return stakedTokenAmount;
    }

    function getAccruedRewardsPerToken() external view returns (uint256) {
        return accruedRewardsPerToken;
    }

    function getToken0() external view returns (address) {
        return token0;
    }

    function getToken1() external view returns (address) {
        return token1;
    }

    function setToken0(address _token0) external requireManager {
        token0 = _token0;
    }

    function setToken1(address _token1) external requireManager {
        token1 = _token1;
    }

    function setManagerProxyAddress(address _managerProxyAddress) external requireManager {
        managerProxyAddress = _managerProxyAddress;
    }

    function setMaxPoolRewardPerTokenPerSecond(uint256 _maxPoolRewardPerTokenPerSecond)
        external
        requireManager
    {
        maxPoolRewardPerTokenPerSecond = _maxPoolRewardPerTokenPerSecond;
    }

    function setStakedTokenAmount(uint256 _stakedTokenAmount) external requireManager {
        stakedTokenAmount = _stakedTokenAmount;
    }

    function setBalance(address _account, uint256 _balance) external requireManager {
        balances[_account] = _balance;
    }

    function setOwedRewards(address _account, uint256 _owedRewards) external requireManager {
        owedRewards[_account] = _owedRewards;
    }

    function setAllocPoints(uint256 _allocPoints) external requireManager {
        allocPoints = _allocPoints;
    }

    function setRewardPerTokenPaid(address _account, uint256 _rewardPerTokenPaid)
        external
        requireManager
    {
        rewardPerTokenPaid[_account] = _rewardPerTokenPaid;
    }

    function setAccruedRewardsPerToken(uint256 _accruedRewardsPerToken) external requireManager {
        accruedRewardsPerToken = _accruedRewardsPerToken;
    }

    function setLockingPeriodInSeconds(uint256 _lockingPeriodInSeconds) external requireManager {
        lockingPeriodInSeconds = _lockingPeriodInSeconds;
    }

    function setOldestLockingParcelIndex(address _stakerAddress, uint256 _index)
        external
        requireManager
    {
        oldestLockingParcelIndexes[_stakerAddress] = _index;
    }

    function setNewestLockingParcelIndex(address _stakerAddress, uint256 _index)
        external
        requireManager
    {
        newestLockingParcelIndexes[_stakerAddress] = _index;
    }

    function setLockingParcel(
        address _stakerAddress,
        uint256 _index,
        uint256 _amount,
        uint256 _lockTime
    ) external requireManager {
        lockingParcels[_stakerAddress][_index].amount = _amount;
        lockingParcels[_stakerAddress][_index].lockTime = _lockTime;
    }

    function setLockingParcelAmount(
        address _stakerAddress,
        uint256 _index,
        uint256 _amount
    ) external requireManager {
        lockingParcels[_stakerAddress][_index].amount = _amount;
    }

    function setLockingParcelLockTime(
        address _stakerAddress,
        uint256 _index,
        uint256 _lockTime
    ) external requireManager {
        lockingParcels[_stakerAddress][_index].lockTime = _lockTime;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

contract IUpgradeProposal is IProposal {
    function impl() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy_New {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external view returns (IGovernedContract);

    function implementation() external view returns (IGovernedContract);

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    function() external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);

    // It must check that the caller is the proxy
    // and copy all required data from the old address.
    function migrate(IGovernedContract _oldImpl) external;

    // It must check that the caller is the proxy
    // and self destruct to the new address.
    function destroy(IGovernedContract _newImpl) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFarmingStorage {
    function getBalance(address _account) external view returns (uint256);

    function getManagerProxyAddress() external view returns (address);

    function getRewardPerTokenPaid(address _account) external view returns (uint256);

    function getOldestLockingParcelIndex(address _stakerAddress) external view returns (uint256);

    function getNewestLockingParcelIndex(address _stakerAddress) external view returns (uint256);

    function getMaxPoolRewardPerTokenPerSecond() external view returns (uint256);

    function getLockingParcel(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256, uint256);

    function getLockingParcelAmount(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256);

    function getLockingParcelLockTime(address _stakerAddress, uint256 _index)
        external
        view
        returns (uint256);

    function getOwedRewards(address _account) external view returns (uint256);

    function getLockingPeriodInSeconds() external view returns (uint256);

    function getStakedTokenAmount() external view returns (uint256);

    function getToken0() external view returns (address);

    function getToken1() external view returns (address);

    function getAccruedRewardsPerToken() external view returns (uint256);

    function getAllocPoints() external view returns (uint256);

    function setStakedTokenAmount(uint256 _stakedTokenAmount) external;

    function setMaxPoolRewardPerTokenPerSecond(uint256 _maxPoolRewardPerTokenPerSecond) external;

    function setAllocPoints(uint256 _allocPoints) external;

    function setManagerProxyAddress(address _managerProxyAddress) external;

    function setToken0(address _token0) external;

    function setToken1(address _token1) external;

    function setLockingParcel(
        address _stakerAddress,
        uint256 _index,
        uint256 _amount,
        uint256 _lockTime
    ) external;

    function setLockingParcelAmount(
        address _stakerAddress,
        uint256 _index,
        uint256 _amount
    ) external;

    function setLockingParcelLockTime(
        address _stakerAddress,
        uint256 _index,
        uint256 _lockTime
    ) external;

    function setOldestLockingParcelIndex(address _stakerAddress, uint256 _index) external;

    function setNewestLockingParcelIndex(address _stakerAddress, uint256 _index) external;

    function setBalance(address _account, uint256 _balance) external;

    function setOwedRewards(address _account, uint256 _owedRewards) external;

    function setRewardPerTokenPaid(address _account, uint256 _rewardPerTokenPaid) external;

    function setAccruedRewardsPerToken(uint256 _accruedRewardsPerToken) external;

    function setLockingPeriodInSeconds(uint256 _lockingPeriodInSeconds) external;
}