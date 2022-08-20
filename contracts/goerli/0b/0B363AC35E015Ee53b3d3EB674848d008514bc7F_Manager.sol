// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';
import { Pausable } from '../Pausable.sol';
import { StorageBase } from '../StorageBase.sol';
import { ManagerAutoProxy } from './ManagerAutoProxy.sol';

import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IFarmingProxy } from '../farmingProxy/IFarmingProxy.sol';
import { IFarmingStorage } from '../farmingStorage/IFarmingStorage.sol';
import { IManagerGovernedProxy } from './IManagerGovernedProxy.sol';
import { IManagerStorage } from './IManagerStorage.sol';
import { IManager } from './IManager.sol';
import { IGMI } from '../interfaces/IGMI.sol';

import { Math } from '../libraries/Math.sol';
import { SafeMath } from '../libraries/SafeMath.sol';

contract ManagerStorage is StorageBase, IManagerStorage {
    uint256 test = 0;
    address private factoryProxyAddress;
    // GMI-ETH LP token address on Ethereum
    address private LPTokenAddress;
    // GMIProxyAddress on Ethereum
    address private GMIProxyAddress;
    // Address of bot to manage this farming contract
    address private operatorAddress;
    // The farmingProxy at index x in the array allFarmingProxies
    // belongs to the farmingStorage at index x in the array allFarmingStorages
    address[] private allFarmingProxies;
    address[] private allFarmingStorages;
    // Total allocation points. It is the sum of all allocation points from all the farming pools.
    uint256 private totalAllocPoints;
    // Last time when a storage mutative function was called
    uint256 private lastUpdateTime;
    // Timestamp when the GMI reward payout to all farming pools ends
    uint256 private timePayoutEnds;
    // GMI reward payout rate of all farming pools;
    // For example, a totalRewardRate of 5 means that all farming pools together pay out
    // 5 GMI tokens per second
    uint256 private totalRewardRate;
    // FarmingProxy => FarmingStorage
    mapping(address => address) private farmingStorage;

    constructor(
        address _factoryProxyAddress,
        address _LPTokenAddress,
        address _GMIProxyAddress,
        address _operatorAddress
    ) public {
        factoryProxyAddress = _factoryProxyAddress;
        LPTokenAddress = _LPTokenAddress;
        GMIProxyAddress = _GMIProxyAddress;
        operatorAddress = _operatorAddress;
    }

    function getTotalRewardRate() external view returns (uint256) {
        return totalRewardRate;
    }

    function getTimePayoutEnds() external view returns (uint256) {
        return timePayoutEnds;
    }

    function getTotalAllocPoints() external view returns (uint256 _totalAllocPoints) {
        _totalAllocPoints = totalAllocPoints;
    }

    function getLPTokenAddress() external view returns (address _LPTokenAddress) {
        _LPTokenAddress = LPTokenAddress;
    }

    function getGMIProxyAddress() external view returns (address _GMIProxyAddress) {
        _GMIProxyAddress = GMIProxyAddress;
    }

    function getOperatorAddress() external view returns (address _operatorAddress) {
        _operatorAddress = operatorAddress;
    }

    function getFactoryProxyAddress() external view returns (address _factoryProxyAddress) {
        _factoryProxyAddress = factoryProxyAddress;
    }

    function getLastUpdateTime() external view returns (uint256) {
        return lastUpdateTime;
    }

    function getFarmingStorage(address _farmingProxy)
        external
        view
        returns (address _farmingStorage)
    {
        _farmingStorage = farmingStorage[_farmingProxy];
    }

    function getFarmingStorageByIndex(uint256 _index)
        external
        view
        returns (address _farmingStorage)
    {
        _farmingStorage = allFarmingStorages[_index];
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address _farmingProxy) {
        _farmingProxy = allFarmingProxies[_index];
    }

    function getAllFarmingProxiesCount() external view returns (uint256 _count) {
        _count = allFarmingProxies.length;
    }

    function getAllFarmingStoragesCount() external view returns (uint256 _count) {
        _count = allFarmingStorages.length;
    }

    function setTimePayoutEnds(uint256 _timePayoutEnds) external requireOwner {
        timePayoutEnds = _timePayoutEnds;
    }

    function setTotalRewardRate(uint256 _totalRewardRate) external requireOwner {
        totalRewardRate = _totalRewardRate;
    }

    function setFarmingStorage(address _farmingProxy, address _farmingStorage)
        external
        requireOwner
    {
        farmingStorage[_farmingProxy] = _farmingStorage;
    }

    function setOperatorAddress(address _operatorAddress) external requireOwner {
        operatorAddress = _operatorAddress;
    }

    function setTotalAllocPoints(uint256 _totalAllocPoints) external requireOwner {
        totalAllocPoints = _totalAllocPoints;
    }

    function setLPTokenAddress(address _LPTokenAddress) external requireOwner {
        LPTokenAddress = _LPTokenAddress;
    }

    function setGMIProxyAddress(address _GMIProxyAddress) external requireOwner {
        GMIProxyAddress = _GMIProxyAddress;
    }

    function setFactoryProxyAddress(address _factoryProxyAddress) external requireOwner {
        factoryProxyAddress = _factoryProxyAddress;
    }

    function setLastUpdateTime(uint256 _lastUpdateTime) external requireOwner {
        lastUpdateTime = _lastUpdateTime;
    }

    function pushFarmingProxy(address _farmingProxy) external requireOwner {
        allFarmingProxies.push(_farmingProxy);
    }

    function popFarmingProxy() external requireOwner {
        allFarmingProxies.pop();
    }

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxy) external requireOwner {
        allFarmingProxies[_index] = _farmingProxy;
    }

    function pushFarmingStorage(address _farmingStorage) external requireOwner {
        allFarmingStorages.push(_farmingStorage);
    }

    function popFarmingStorage() external requireOwner {
        allFarmingStorages.pop();
    }

    function setFarmingStorageByIndex(uint256 _index, address _farmingStorage)
        external
        requireOwner
    {
        allFarmingStorages[_index] = _farmingStorage;
    }
}

contract Manager is Pausable, NonReentrant, ManagerAutoProxy, IManager {
    using SafeMath for uint256;
    uint256 test = 0;

    ManagerStorage public _storage;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _proxy,
        address _factoryProxyAddress,
        address _LPTokenAddress,
        address _GMIProxyAddress,
        address _operatorAddress
    ) public ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ManagerStorage(
            _factoryProxyAddress,
            _LPTokenAddress,
            _GMIProxyAddress,
            _operatorAddress
        );
    }

    /* ========== MODIFIERS ========== */

    modifier requireFarmingProxy() {
        require(
            _storage.getFarmingStorage(msg.sender) != address(0),
            'Manager: FORBIDDEN, not a farming proxy'
        );
        _;
    }

    modifier onlyFactoryImplementation() {
        require(
            msg.sender ==
                address(
                    IGovernedProxy_New(address(uint160(_storage.getFactoryProxyAddress())))
                        .implementation()
                ),
            'Manager: Not factory implementation!'
        );
        _;
    }

    modifier onlyOwnerOrOperator() {
        require(
            msg.sender == owner || msg.sender == _storage.getOperatorAddress(),
            'Manager: Not owner or operator!'
        );
        _;
    }

    /* ========== GOVERNANCE FUNCTIONS ========== */

    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IManagerGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new contract implementation
    function destroy(IGovernedContract _newImplementation) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImplementation));
        // Self destruct
        _destroy(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImplementation) external requireProxy {
        _migrate(_oldImplementation);
    }

    /* ========== VIEWS ========== */

    function getGMIImplementation() private view returns (address) {
        return
            address(
                IGovernedProxy_New(address(uint160(_storage.getGMIProxyAddress()))).implementation()
            );
    }

    // This function is used to calculate the GMI reward payout per LP token per second for a specific farming pool.
    // Farming pools with a longer locking period pay out more rewards because we set their allocPoints value higher.
    // Farming pools with many LP tokens staked are allocated a greater portion of the totalRewardRate.
    function rewardPerTokenPerSecondApplicable(address farmingProxy) public view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        uint256 poolStakedTokenAmount = farmingStorage.getStakedTokenAmount();

        // The totalRewardRate corresponds to the total amount of GMI tokens payed out by all farming pools per second.
        // We allocate a fraction of this totalRewardRate to each farming pool.
        //
        // This allocation is done manually by setting the allocPoints value of each farming pool.
        // The higher we set the allocPoints value for a farming pool, the larger the resulting pool's rewardRate is
        // (the pool's rewardRate being the amount of GMI tokens payed out by this pool per second).
        // In practice we intend to set higher allocPoints for pools which have a longer locking period, in a way that
        // it is more beneficial to stake in a farming pool with a longer locking period rather than staking and
        // compounding rewards from a farming pool with a shorter locking period.
        //
        // Another variable to take into account when balancing pools rewards is the amount of LP tokens staked in each
        // farming pool. In order to maintain higher rewards per LP token for farming pools with longer locking periods,
        // the fraction of totalRewardRate allocated to a pool must be proportional to the amount of LP tokens staked
        // in that pool, relative to the total amount of LP tokens staked across all farming pools.
        //
        // We use the following formula to determine the rewardRate of each farming pool:
        //
        // poolRewardRate = totalRewardRate * poolStakedTokenAmount * poolAllocPoints / SUM(stakedTokenAmount_i * poolAllocPoints_i)
        //
        // Where:
        //
        // poolStakedTokenAmount is the total amount of LP tokens staked in considered updateAllPools
        // poolAllocPoints is the allocPoints value set for considered pool
        // The SUM operator corresponds to an iterative sum across all farming pools
        // stakedTokenAmount_i is the total  amount of LP tokens staked in the farming pool at index i
        // allocPoints_i is the allocPoints value set for the farming pool at index i

        uint256 numerator = poolStakedTokenAmount * farmingStorage.getAllocPoints();
        uint256 denominator;
        uint256 length = _storage.getAllFarmingProxiesCount();
        for (uint256 index = 0; index < length; ++index) {
            farmingStorage = IFarmingStorage(_storage.getFarmingStorageByIndex(index));
            denominator += farmingStorage.getStakedTokenAmount() * farmingStorage.getAllocPoints();
        }

        if (poolStakedTokenAmount > 0) {
            // To reduce the negative effect of rounding, this value is multiplied by 10^18.
            uint256 poolRewardPerTokenPerSecond = _storage
                .getTotalRewardRate()
                .mul(1e18)
                .mul(numerator)
                .div(denominator)
                .div(poolStakedTokenAmount);
            uint256 maxPoolRewardPerTokenPerSecond = farmingStorage
                .getMaxPoolRewardPerTokenPerSecond();
            if (maxPoolRewardPerTokenPerSecond > 0) {
                return Math.min(maxPoolRewardPerTokenPerSecond, poolRewardPerTokenPerSecond);
            } else {
                return poolRewardPerTokenPerSecond;
            }
        }
        return 0;
    }

    // Accumulated rewards that a virtual LP token would have collected
    // when staked since the inception of the farmingProxy pool.
    function accruedRewardPerToken(address farmingProxy) public view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        if (farmingStorage.getStakedTokenAmount() == 0) {
            return farmingStorage.getAccruedRewardsPerToken();
        }
        return
            // The new accruedRewardPerToken value is calculated as the sum of the stored accruedRewardPerToken value
            // for considered pool and the amount of extra rewards per token accumulated in that pool since the last
            // time a storage mutative function was called.
            farmingStorage.getAccruedRewardsPerToken().add(
                lastTimeRewardApplicable().sub(_storage.getLastUpdateTime()).mul(
                    rewardPerTokenPerSecondApplicable(farmingProxy)
                )
            );
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return Math.min(block.timestamp, _storage.getTimePayoutEnds());
    }

    // Returns the rewards that a staker can claim on the farmingProxy pool.
    function owedRewards(address farmingProxy, address account) public view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return
            // stakedBalance * rewardsPerTokenPerNewTimePeriod + unclaimedRewards
            // `newTimePeriod` represents time passed since the last time a storage mutative function
            // was called by the staker to now (or the last timestamp that these farming pools pay out rewards).
            // `rewardsPerTokenPerNewTimePeriod` is the rewards that a LP token has
            // accumulated in the `newTimePeriod`.
            farmingStorage
            // stakedBalance
            .getBalance(account)
            // `rewardsPerTokenPerNewTimePeriod` represents the rewards accrued by a staker (per token staked)
            // since he/she last called a storage mutative function.
            // To reduce the negative effect of rounding, the value was multiplied by 10^18.
            // We need to divide by 10^18 to get back the original value.
            // `unclaimedRewards` (owed rewards to the staker that have not been payed out to the staker yet)
                .mul(
                    accruedRewardPerToken(farmingProxy).sub(
                        farmingStorage.getRewardPerTokenPaid(account)
                    )
                )
                .div(1e18)
                .add(farmingStorage.getOwedRewards(account));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // This function is called by the factory implementation at a new farming pool creation.
    // It registers a new FarmingProxy address, and FarmingStorage address in this manager contract.
    function registerPool(address _farmingProxy, address _farmingStorage)
        external
        whenNotPaused
        onlyFactoryImplementation
    {
        _storage.setFarmingStorage(_farmingProxy, _farmingStorage);
        _storage.pushFarmingStorage(_farmingStorage);
        _storage.pushFarmingProxy(_farmingProxy);
    }

    // This function is used by a staker to stake LP tokens in a farming pool.
    function _stake(
        address farmingProxy,
        uint256 amount,
        address account
    ) private noReentry whenNotPaused {
        updateAllPools(farmingProxy, account);

        require(amount > 0, 'Manager: Cannot stake 0');

        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        farmingStorage.setStakedTokenAmount(farmingStorage.getStakedTokenAmount().add(amount));

        farmingStorage.setBalance(account, farmingStorage.getBalance(account).add(amount));

        // A lockingParcel is created for the LP tokens that the staker just staked.
        // The `newestLockingParcelIndex` variable denotes the next free index for adding a LockingParcel.
        uint256 newestLockingParcelIndex = farmingStorage.getNewestLockingParcelIndex(account);
        farmingStorage.setLockingParcel(account, newestLockingParcelIndex, amount, block.timestamp);
        farmingStorage.setNewestLockingParcelIndex(account, newestLockingParcelIndex.add(1));

        IFarmingProxy(farmingProxy).safeTransferTokenFrom(
            _storage.getLPTokenAddress(),
            account,
            farmingProxy,
            amount
        );

        IFarmingProxy(farmingProxy).emitStaked(
            account,
            amount,
            newestLockingParcelIndex,
            block.timestamp
        );
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function stake(uint256 amount) external requireFarmingProxy {
        _stake(msg.sender, amount, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function stake(address farmingProxy, uint256 amount) external {
        _stake(farmingProxy, amount, msg.sender);
    }

    // This function can be used to check how many LP tokens can be already withdrawn.
    // It checks how many of the staker's LP tokens are not locked anymore if `checkIfUnlocked` is true.
    // Set `amount` and `limit` to the maximum uint256 value to get your maximum
    // availableAmount in LP tokens that can be withdrawn. If the staker has a significant amount of
    // locking parcels, use `offset` and `limit` for pagination.
    function availableToWithdraw(
        address farmingProxy,
        uint256 amount,
        address account,
        bool checkIfUnlocked,
        uint256 offset,
        uint256 limit
    ) public view returns (uint256 availableAmount, uint256 index) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        // The oldestLockingParcelIndex is the oldest/lowest-indexed, currently active, locking parcel.
        // It is the oldest/lowest-indexed `LockingParcel` that has not been withdrawn/removed yet.
        index = farmingStorage.getOldestLockingParcelIndex(account) + offset;
        uint256 lockingPeriodInSeconds = farmingStorage.getLockingPeriodInSeconds();

        uint256 unlockTime = block.timestamp - lockingPeriodInSeconds;

        while (
            // Check if we have already the requested amount of unlocked LP tokens reached.
            amount > availableAmount &&
            // Limit ensures we don't run out of gas in case the staker created too many locking parcels with small amounts.
            limit > 0 &&
            // Check lockingParcel exists.
            farmingStorage.getLockingParcelLockTime(account, index) != 0
        ) {
            // Check parcel is unlocked.
            if (
                checkIfUnlocked == true &&
                farmingStorage.getLockingParcelLockTime(account, index) > unlockTime
            ) {
                break;
            }
            availableAmount += farmingStorage.getLockingParcelAmount(account, index);
            index = index.add(1);
            limit = limit.sub(1);
        }
        return (availableAmount, index);
    }

    // This function is used by a staker to withdraw LP tokens from a farming pool.
    function _withdraw(
        address farmingProxy,
        uint256 amount,
        address account,
        bool checkIfUnlocked,
        uint256 limit
    ) private noReentry whenNotPaused {
        updateAllPools(farmingProxy, account);

        require(amount > 0, 'Manager: Cannot withdraw 0');

        // The oldestLockingParcelIndex is the oldest/lowest-indexed, currently active, locking parcel.
        // It is the oldest/lowest-indexed `LockingParcel` that has not been withdrawn/removed yet.
        (uint256 availableAmount, uint256 oldestLockingParcelIndex) = availableToWithdraw(
            farmingProxy,
            amount,
            account,
            checkIfUnlocked,
            0,
            limit
        );
        require(amount <= availableAmount, 'Manager: LP tokens are still locked. Amount too high.');

        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        // If amount < availableAmount we need to update the last lockingParcel with the leftoverAmount
        // (leftoverAmount = availableAmount - amount). The leftoverAmount has not been withdrawn yet
        // within this function call.
        if (amount < availableAmount) {
            oldestLockingParcelIndex = oldestLockingParcelIndex.sub(1);
            // Update the lockingParcel that was withdrawn from
            farmingStorage.setLockingParcelAmount(
                account,
                oldestLockingParcelIndex,
                availableAmount - amount
            );
        }

        farmingStorage.setOldestLockingParcelIndex(account, oldestLockingParcelIndex);

        farmingStorage.setStakedTokenAmount(farmingStorage.getStakedTokenAmount().sub(amount));
        farmingStorage.setBalance(account, farmingStorage.getBalance(account).sub(amount));

        IFarmingProxy(farmingProxy).safeTransferToken(
            _storage.getLPTokenAddress(),
            account,
            amount
        );

        // The `oldestLockingParcelIndex` points to the oldest, still active locking parcel.
        // It is the locking parcel index that is up for withdrawal next.
        // The `leftoverAmount = availableAmount - amount` is a value that
        // allows us to update the amount of a locking parcel in the subgraph in case
        // we partially withdraw a locking parcel in this smart contract.
        // 1. Example:        event Withdrawn(user, amount, 5, 0);
        // The locking parcels with indexes .., 3, 4 were completely withdrawn (meaning
        // the leftoverAmount relates to index 4 and is 0). The locking parcels with
        // indexes 5, 6, 7, ... are still active.
        // 2. Example:       event Withdrawn(user, amount, 5, 234)
        // The locking parcels with indexes .., 3, 4, were completely withdrawn while 5
        // was partially withdraw (meaning the leftoverAmount relates to index 5
        // and the amount of locking parcel with index 5 needs to be updated to 234 in
        // the subgraph). The locking parcels with indexes 5, 6, 7, ... are still active.
        IFarmingProxy(farmingProxy).emitWithdrawn(
            account,
            amount,
            oldestLockingParcelIndex,
            availableAmount - amount
        );
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function withdraw(uint256 amount, uint256 limit) external requireFarmingProxy {
        _withdraw(msg.sender, amount, tx.origin, true, limit);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function withdraw(
        address farmingProxy,
        uint256 amount,
        uint256 limit
    ) external {
        _withdraw(farmingProxy, amount, msg.sender, true, limit);
    }

    // This function is used by a staker to claim rewards from a farming pool.
    function _getReward(address farmingProxy, address account) private noReentry whenNotPaused {
        updateAllPools(farmingProxy, account);
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        uint256 reward = farmingStorage.getOwedRewards(account);

        if (reward > 0) {
            farmingStorage.setOwedRewards(account, 0);

            IGMI(getGMIImplementation()).mint(account, reward);

            IFarmingProxy(farmingProxy).emitRewardPaid(account, reward);
        }
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function getReward() external requireFarmingProxy {
        _getReward(msg.sender, tx.origin);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function getReward(address farmingProxy) external {
        _getReward(farmingProxy, msg.sender);
    }

    // This function is used by a staker to claim rewards from a farming pool
    // and withdraw all its LP tokens from that farming pool.
    function _exit(
        address farmingProxy,
        address account,
        uint256 limit
    ) private {
        (uint256 availableAmount, ) = availableToWithdraw(
            farmingProxy,
            uint256(-1),
            account,
            true,
            0,
            limit
        );

        _withdraw(farmingProxy, availableAmount, account, true, limit);

        _getReward(farmingProxy, account);
    }

    // This function should be called through the fallback function
    // of the FarmingProxy by an externally owned address.
    function exit(uint256 limit) external requireFarmingProxy {
        _exit(msg.sender, tx.origin, limit);
    }

    // This function can be called by a smart contract as well as
    // an externally owned address. It is meant for smart contracts because they
    // cannot call through the fallback function.
    function exit(address farmingProxy, uint256 limit) external {
        _exit(farmingProxy, msg.sender, limit);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    // The owner or operator of this contract can update the totalRewardRate.
    function updatePayout(uint256 reward, uint256 rewardsDuration) external onlyOwnerOrOperator {
        updateAllPools();

        // Do we need this check? Not sure.
        require(
            block.timestamp.add(rewardsDuration) >= _storage.getTimePayoutEnds(),
            'Manager: Cannot reduce existing period'
        );

        if (block.timestamp >= _storage.getTimePayoutEnds()) {
            _storage.setTotalRewardRate(reward.div(rewardsDuration));
        } else {
            uint256 remaining = _storage.getTimePayoutEnds().sub(block.timestamp);
            uint256 leftover = remaining.mul(_storage.getTotalRewardRate());
            uint256 totalRewardAmount = reward.add(leftover);
            _storage.setTotalRewardRate(totalRewardAmount.div(rewardsDuration));
        }

        _storage.setLastUpdateTime(block.timestamp);

        _storage.setTimePayoutEnds(block.timestamp.add(rewardsDuration));

        IManagerGovernedProxy(proxy).emitRewardAdded(reward, _storage.getTimePayoutEnds());
    }

    // The owner of this smart contract can update the token allocation points of a farming pool.
    function setAllocPoints(address farmingProxy, uint256 allocPoints) external onlyOwner {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));

        updateAllPools();

        _storage.setTotalAllocPoints(
            _storage.getTotalAllocPoints().sub(farmingStorage.getAllocPoints()).add(allocPoints)
        );
        farmingStorage.setAllocPoints(allocPoints);

        IFarmingProxy(farmingProxy).emitAllocPointsUpdate(allocPoints);
    }

    // This functions updates important farming pool variables whenever a staker
    // or the owner of this manager contract call a storage mutative function.
    // Be careful of gas spending! Manager should not manage too many pools
    // but for now this is not planned (only 6 pools).
    function updateAllPools() private {
        uint256 length = _storage.getAllFarmingProxiesCount();

        for (uint256 index = 0; index < length; ++index) {
            address farmingProxy = _storage.getFarmingProxyByIndex(index);
            IFarmingStorage farmingStorage = IFarmingStorage(
                _storage.getFarmingStorage(farmingProxy)
            );

            farmingStorage.setAccruedRewardsPerToken(accruedRewardPerToken(farmingProxy));
        }

        _storage.setLastUpdateTime(lastTimeRewardApplicable());
    }

    // This functions updates important farming pool variables whenever a staker
    // calls a storage mutative function. It also updates staker account specific variables.
    // Be careful of gas spending! Manager should not manage too many pools
    // but for now this is not planned (only 6 pools).
    function updateAllPools(address farmingProxy, address account) private {
        // Updates reward variables for all pools
        updateAllPools();

        // Updates staker account specific variables
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        farmingStorage.setOwedRewards(account, owedRewards(farmingProxy, account));
        farmingStorage.setRewardPerTokenPaid(account, farmingStorage.getAccruedRewardsPerToken());
    }

    function setMaxPoolRewardPerTokenPerSecondInBatches(
        address[] calldata farmingProxies,
        uint256[] calldata maxPoolRewardPerTokenPerSeconds
    ) external onlyOwnerOrOperator {
        updateAllPools();

        require(
            farmingProxies.length > 0 &&
                farmingProxies.length == maxPoolRewardPerTokenPerSeconds.length,
            'Manager::setMaxPoolRewardPerTokenPerSecondInBatches: error in lengths of arrays'
        );

        for (uint256 i = 0; i < farmingProxies.length; i++) {
            IFarmingStorage farmingStorage = IFarmingStorage(
                _storage.getFarmingStorage(farmingProxies[i])
            );
            farmingStorage.setMaxPoolRewardPerTokenPerSecond(maxPoolRewardPerTokenPerSeconds[i]);
            IFarmingProxy(farmingProxies[i]).emitMaxPoolRewardPerTokenPerSecondUpdated(
                maxPoolRewardPerTokenPerSeconds[i]
            );
        }
    }

    // This function can be used to return LP tokens to stakers. If `checkIfUnlocked` variable is true the
    // function execution will only succeed if the stakers have already enough unlocked LP tokens.
    function returnLPTokensInBatches(
        address farmingProxy,
        address[] calldata stakerAccounts,
        uint256[] calldata LPTokenAmounts,
        bool checkIfUnlocked,
        uint256 limit
    ) external onlyOwnerOrOperator {
        updateAllPools();

        require(
            stakerAccounts.length > 0 && stakerAccounts.length == LPTokenAmounts.length,
            'Manager::returnLPTokensInBatches: error in lengths of arrays'
        );

        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        // We need to update all staker account specific variables before withdrawing any LP tokens.
        for (uint256 i = 0; i < stakerAccounts.length; i++) {
            // Updates staker account specific variables
            farmingStorage.setOwedRewards(
                stakerAccounts[i],
                owedRewards(farmingProxy, stakerAccounts[i])
            );
            farmingStorage.setRewardPerTokenPaid(
                stakerAccounts[i],
                farmingStorage.getAccruedRewardsPerToken()
            );
        }

        for (uint256 i = 0; i < stakerAccounts.length; i++) {
            _withdraw(farmingProxy, LPTokenAmounts[i], stakerAccounts[i], checkIfUnlocked, limit);
        }
    }

    function setOperatorAddress(address _newOperatorAddress) external onlyOwner {
        _storage.setOperatorAddress(_newOperatorAddress);
    }

    function setLPTokenAddress(address _newLPTokenAddress) external onlyOwner {
        _storage.setLPTokenAddress(_newLPTokenAddress);
    }

    function setGMIProxyAddress(address _GMIProxyAddress) external onlyOwner {
        _storage.setGMIProxyAddress(_GMIProxyAddress);
    }

    function setTotalAllocPoints(uint256 _totalAllocPoints) external onlyFactoryImplementation {
        _storage.setTotalAllocPoints(_totalAllocPoints);
    }

    function setLockingPeriodInSeconds(address farmingProxy, uint256 lockingPeriod)
        external
        onlyOwner
    {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        farmingStorage.setLockingPeriodInSeconds(lockingPeriod);

        IFarmingProxy(farmingProxy).emitLockingPeriodUpdate(lockingPeriod);
    }

    /* ========== GETTER FUNCTIONS ========== */

    function getBalance(address farmingProxy, address account) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getBalance(account);
    }

    function getTotalRewardRate() external view returns (uint256) {
        return _storage.getTotalRewardRate();
    }

    function getFarmingStorage(address farmingProxy) external view returns (address) {
        return _storage.getFarmingStorage(farmingProxy);
    }

    function getFarmingProxyByIndex(uint256 index) external view returns (address) {
        return _storage.getFarmingProxyByIndex(index);
    }

    function getAllFarmingProxiesCount() external view returns (uint256) {
        return _storage.getAllFarmingProxiesCount();
    }

    function getLPTokenAddress() external view returns (address) {
        return _storage.getLPTokenAddress();
    }

    function getTotalAllocPoints() external view returns (uint256) {
        return _storage.getTotalAllocPoints();
    }

    function getTimePayoutEnds() external view returns (uint256) {
        return _storage.getTimePayoutEnds();
    }

    function getLastUpdateTime() external view returns (uint256) {
        return _storage.getLastUpdateTime();
    }

    // Expose FarmingStorage getter functions

    function getMaxPoolRewardPerTokenPerSecond(address farmingProxy)
        external
        view
        returns (uint256)
    {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return farmingStorage.getMaxPoolRewardPerTokenPerSecond();
    }

    function getLockingPeriodInSeconds(address farmingProxy) external view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return farmingStorage.getLockingPeriodInSeconds();
    }

    function getRewardPerTokenPaid(address farmingProxy, address staker)
        external
        view
        returns (uint256)
    {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return farmingStorage.getRewardPerTokenPaid(staker);
    }

    function getOwedRewards(address farmingProxy, address staker) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getOwedRewards(staker);
    }

    function getStakedTokenAmount(address farmingProxy) external view returns (uint256) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getStakedTokenAmount();
    }

    function getToken0(address farmingProxy) external view returns (address) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getToken0();
    }

    function getToken1(address farmingProxy) external view returns (address) {
        return IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getToken1();
    }

    function getAccruedRewardsPerToken(address farmingProxy) external view returns (uint256) {
        return
            IFarmingStorage(_storage.getFarmingStorage(farmingProxy)).getAccruedRewardsPerToken();
    }

    function getAllocPoints(address farmingProxy) external view returns (uint256) {
        IFarmingStorage farmingStorage = IFarmingStorage(_storage.getFarmingStorage(farmingProxy));
        return farmingStorage.getAllocPoints();
    }
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { ISporkRegistry } from '../interfaces/ISporkRegistry.sol';
import { IUpgradeProposal } from '../interfaces/IUpgradeProposal.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract ManagerGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy_New {
    uint256 test = 0;
    IGovernedContract public implementation;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'ManagerGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(implementation),
            'ManagerGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }

    event RewardAdded(uint256 reward, uint256 timePayoutEnds);

    constructor(address _implementation) public {
        implementation = IGovernedContract(_implementation);
    }

    function setSporkProxy(address payable _sporkProxy) external onlyImpl {
        spork_proxy = IGovernedProxy_New(_sporkProxy);
    }

    // Due to backward compatibility of old Energi proxies
    function impl() external view returns (IGovernedContract) {
        return implementation;
    }

    function emitRewardAdded(uint256 reward, uint256 timePayoutEnds) external onlyImpl {
        emit RewardAdded(reward, timePayoutEnds);
    }

    /**
     * Pre-create a new contract first.
     * Then propose upgrade based on that.
     */
    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        senderOrigin
        noReentry
        returns (IUpgradeProposal)
    {
        require(_newImplementation != implementation, 'ManagerGovernedProxy: Already active!');
        require(_newImplementation.proxy() == address(this), 'ManagerGovernedProxy: Wrong proxy!');

        ISporkRegistry spork_reg = ISporkRegistry(address(spork_proxy.impl()));
        IUpgradeProposal proposal = spork_reg.createUpgradeProposal.value(msg.value)(
            _newImplementation,
            _period,
            msg.sender
        );

        upgrade_proposals[address(proposal)] = _newImplementation;
        upgrade_proposal_list.push(proposal);

        emit UpgradeProposal(_newImplementation, proposal);

        return proposal;
    }

    /**
     * Once proposal is accepted, anyone can activate that.
     */
    function upgrade(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(newImplementation != implementation, 'ManagerGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(newImplementation) != address(0), 'ManagerGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'ManagerGovernedProxy: Not accepted!');

        IGovernedContract oldImplementation = implementation;

        newImplementation.migrate(oldImplementation);
        implementation = newImplementation;
        oldImplementation.destroy(newImplementation);

        // SECURITY: prevent downgrade attack
        _cleanupProposal(_proposal);

        // Return fee ASAP
        _proposal.destroy();

        emit Upgraded(newImplementation, _proposal);
    }

    /**
     * Map proposal to implementation
     */
    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation)
    {
        newImplementation = upgrade_proposals[address(_proposal)];
    }

    /**
     * Lists all available upgrades
     */
    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals) {
        uint256 len = upgrade_proposal_list.length;
        proposals = new IUpgradeProposal[](len);

        for (uint256 i = 0; i < len; ++i) {
            proposals[i] = upgrade_proposal_list[i];
        }

        return proposals;
    }

    /**
     * Once proposal is reject, anyone can start collect procedure.
     */
    function collectUpgradeProposal(IUpgradeProposal _proposal) external noReentry {
        IGovernedContract newImplementation = upgrade_proposals[address(_proposal)];
        require(address(newImplementation) != address(0), 'ManagerGovernedProxy: Not registered!');
        _proposal.collect();
        delete upgrade_proposals[address(_proposal)];

        _cleanupProposal(_proposal);
    }

    function _cleanupProposal(IUpgradeProposal _proposal) internal {
        delete upgrade_proposals[address(_proposal)];

        uint256 len = upgrade_proposal_list.length;
        for (uint256 i = 0; i < len; ++i) {
            if (upgrade_proposal_list[i] == _proposal) {
                upgrade_proposal_list[i] = upgrade_proposal_list[len - 1];
                upgrade_proposal_list.pop();
                break;
            }
        }
    }

    /**
     * Related to above
     */
    function proxy() external view returns (address) {
        return address(this);
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function migrate(IGovernedContract) external {
        revert('ManagerGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('ManagerGovernedProxy: Good try');
    }

    /**
     * Proxy all other calls to implementation.
     */
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory
        IGovernedContract implementation_m = implementation;

        // A dummy delegatecall opcode in the fallback function is necessary for
        // block explorers to pick up the Energi proxy-implementation pattern
        if (false) {
            (bool success, bytes memory data) = address(0).delegatecall(
                abi.encodeWithSignature('')
            );
            require(
                success && !success && data.length == 0 && data.length != 0,
                'ManagerGovernedProxy: delegatecall cannot be used'
            );
        }

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize)

            let res := call(sub(gas, 10000), implementation_m, callvalue, ptr, calldatasize, 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize)

            switch res
            case 0 {
                revert(ptr, returndatasize)
            }
            default {
                return(ptr, returndatasize)
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { GovernedContract } from '../GovernedContract.sol';
import { ManagerGovernedProxy } from './ManagerGovernedProxy.sol';

/**
 * ManagerAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract ManagerAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new ManagerGovernedProxy(_implementation));
        }
        proxy = _proxy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManagerStorage {
    function getTotalRewardRate() external view returns (uint256);

    function getTimePayoutEnds() external view returns (uint256);

    function getTotalAllocPoints() external view returns (uint256 _totalAllocPoints);

    function getLPTokenAddress() external view returns (address _LPTokenAddress);

    function getGMIProxyAddress() external view returns (address _GMIProxyAddress);

    function getOperatorAddress() external view returns (address _operatorAddress);

    function getFactoryProxyAddress() external view returns (address _factoryProxyAddress);

    function getLastUpdateTime() external view returns (uint256);

    function getAllFarmingStoragesCount() external view returns (uint256 _count);

    function getFarmingStorage(address _farmingProxy)
        external
        view
        returns (address _farmingStorage);

    function getFarmingStorageByIndex(uint256 _index)
        external
        view
        returns (address _farmingStorage);

    function getFarmingProxyByIndex(uint256 _index) external view returns (address _farmingProxy);

    function getAllFarmingProxiesCount() external view returns (uint256 _count);

    function setTimePayoutEnds(uint256 _timePayoutEnds) external;

    function setTotalRewardRate(uint256 _totalRewardRate) external;

    function setFarmingStorage(address _farmingProxy, address _farmingStorage) external;

    function setOperatorAddress(address _operatorAddress) external;

    function setTotalAllocPoints(uint256 _totalAllocPoints) external;

    function setLPTokenAddress(address _LPTokenAddress) external;

    function setGMIProxyAddress(address _GMIProxyAddress) external;

    function setFactoryProxyAddress(address _factoryProxyAddress) external;

    function setLastUpdateTime(uint256 _lastUpdateTime) external;

    function pushFarmingProxy(address _farmingProxy) external;

    function popFarmingProxy() external;

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxy) external;

    function pushFarmingStorage(address _farmingStorage) external;

    function popFarmingStorage() external;

    function setFarmingStorageByIndex(uint256 _index, address _farmingStorage) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManagerGovernedProxy {
    event RewardAdded(uint256 reward, uint256 timePayoutEnds);

    function emitRewardAdded(uint256 reward, uint256 timePayoutEnds) external;

    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IManager {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function availableToWithdraw(
        address farmingProxy,
        uint256 amount,
        address account,
        bool checkIfUnlocked,
        uint256 offset,
        uint256 limit
    ) external view returns (uint256 availableAmount, uint256 index);

    function registerPool(address _farmingProxy, address _farmingStorage) external;

    function accruedRewardPerToken(address farmingProxy) external view returns (uint256);

    function owedRewards(address farmingProxy, address account) external view returns (uint256);

    function returnLPTokensInBatches(
        address farmingProxy,
        address[] calldata stakerAccounts,
        uint256[] calldata LPTokenAmounts,
        bool checkIfUnlocked,
        uint256 limit
    ) external;

    function rewardPerTokenPerSecondApplicable(address farmingProxy)
        external
        view
        returns (uint256);

    function getBalance(address farmingProxy, address account) external view returns (uint256);

    function getLPTokenAddress() external view returns (address);

    function getTotalRewardRate() external view returns (uint256);

    function getRewardPerTokenPaid(address farmingProxy, address staker)
        external
        view
        returns (uint256);

    function getOwedRewards(address farmingProxy, address staker) external view returns (uint256);

    function getReward() external;

    function getReward(address farmingProxy) external;

    function stake(uint256 amount) external;

    function stake(address farmingProxy, uint256 amount) external;

    function withdraw(uint256 amount, uint256 limit) external;

    function withdraw(
        address farmingProxy,
        uint256 amount,
        uint256 limit
    ) external;

    function exit(uint256 limit) external;

    function exit(address farmingProxy, uint256 limit) external;

    function updatePayout(uint256 reward, uint256 rewardsDuration) external;

    function getStakedTokenAmount(address farmingProxy) external view returns (uint256);

    function getToken0(address farmingProxy) external view returns (address);

    function getToken1(address farmingProxy) external view returns (address);

    function getAccruedRewardsPerToken(address farmingProxy) external view returns (uint256);

    function getLastUpdateTime() external view returns (uint256);

    function getMaxPoolRewardPerTokenPerSecond(address farmingProxy)
        external
        view
        returns (uint256);

    function getTotalAllocPoints() external view returns (uint256);

    function getTimePayoutEnds() external view returns (uint256);

    function getLockingPeriodInSeconds(address farmingProxy) external view returns (uint256);

    function getAllocPoints(address farmingProxy) external view returns (uint256);

    function getFarmingStorage(address farmingProxy) external view returns (address);

    function getFarmingProxyByIndex(uint256 index) external view returns (address);

    function getAllFarmingProxiesCount() external view returns (uint256);

    // Mutative

    function setMaxPoolRewardPerTokenPerSecondInBatches(
        address[] calldata farmingProxies,
        uint256[] calldata maxPoolRewardPerTokenPerSeconds
    ) external;

    function setOperatorAddress(address _newOperatorAddress) external;

    function setLPTokenAddress(address _newLPTokenAddress) external;

    function setGMIProxyAddress(address _GMIProxyAddress) external;

    function setTotalAllocPoints(uint256 _totalAllocPoints) external;

    function setLockingPeriodInSeconds(address farmingProxy, uint256 lockingPeriod) external;

    function setAllocPoints(address farmingProxy, uint256 allocPoints) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow, so we distribute
        return (a / 2) + (b / 2) + (((a % 2) + (b % 2)) / 2);
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

interface IStorageBase {
    function setOwner(address _newOwner) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface ISporkRegistry {
    function createUpgradeProposal(
        IGovernedContract _implementation,
        uint256 _period,
        address payable _fee_payer
    ) external payable returns (IUpgradeProposal);

    function consensusGasLimits() external view returns (uint256 callGas, uint256 xferGas);
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

interface IGMI {
    function mint(address recipient, uint256 amount) external;
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

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFarmingProxy {
    event Staked(
        address indexed user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    );
    event Withdrawn(
        address indexed user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    );
    event RewardPaid(address indexed user, uint256 reward);
    event LockingPeriodUpdate(uint256 lockingPeriodInSeconds);
    event AllocPointsUpdate(uint256 allocPoints);
    event MaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond);

    function safeTransferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external;

    function safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function emitMaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond)
        external;

    function emitStaked(
        address user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    ) external;

    function emitWithdrawn(
        address user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    ) external;

    function emitRewardPaid(address user, uint256 reward) external;

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external;

    function emitAllocPointsUpdate(uint256 allocPoints) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(IGovernedContract _newOwner) external requireOwner {
        owner = address(uint160(address(_newOwner)));
    }

    function kill() external requireOwner {
        selfdestruct(msg.sender);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';
import { SafeMath } from './libraries/SafeMath.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    using SafeMath for uint256;

    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number.add(blocks);
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract is IGovernedContract {
    address public proxy;

    constructor(address _proxy) public {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // Function overridden in child contract
    function migrate(IGovernedContract _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    // Function overridden in child contract
    function destroy(IGovernedContract _newImpl) external requireProxy {
        _destroy(_newImpl);
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(IGovernedContract) internal {}

    function _destroy(IGovernedContract _newImpl) internal {
        selfdestruct(address(uint160(address(_newImpl))));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return tx.origin;
        } else {
            return msg.sender;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() internal {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _txOrigin() internal view returns (address payable) {
        return tx.origin;
    }
}