// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

import { StorageBase } from '../StorageBase.sol';
import { Ownable } from '../Ownable.sol';
import { FarmingStorage } from '../farmingStorage/FarmingStorage.sol';
import { FactoryAutoProxy } from './FactoryAutoProxy.sol';
import { FarmingProxy } from '../farmingProxy/FarmingProxy.sol';

import { ILPToken } from '../interfaces/ILPToken.sol';
import { IFactoryStorage } from './IFactoryStorage.sol';
import { IFactory } from './IFactory.sol';
import { IManager } from '../manager/IManager.sol';
import { IStorageBase } from '../interfaces/IStorageBase.sol';
import { IGovernedContract } from '../interfaces/IGovernedContract.sol';
import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IFactoryGovernedProxy } from './IFactoryGovernedProxy.sol';

import { SafeMath } from '../libraries/SafeMath.sol';

contract FactoryStorage is StorageBase, IFactoryStorage {
  uint test = 0;
    address private managerProxy;

    address[] private farmingProxies;

    constructor(address _managerProxy) public {
        managerProxy = _managerProxy;
    }

    function getManagerProxy() external view returns (address) {
        return managerProxy;
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address) {
        return farmingProxies[_index];
    }

    function getFarmingProxiesCount() external view returns (uint256) {
        return farmingProxies.length;
    }

    function pushFarmingProxy(address _farmingProxyAddress) external requireOwner {
        farmingProxies.push(_farmingProxyAddress);
    }

    function popFarmingProxy() external requireOwner {
        farmingProxies.pop();
    }

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxyAddress)
        external
        requireOwner
    {
        farmingProxies[_index] = _farmingProxyAddress;
    }

    function setManagerProxy(address _managerProxy) external requireOwner {
        managerProxy = _managerProxy;
    }
}

contract Factory is Ownable, FactoryAutoProxy, IFactory {
    using SafeMath for uint256;
    uint test = 0;

    FactoryStorage public _storage;

    bool public initialized = false;

    constructor(address _proxy) public FactoryAutoProxy(_proxy, address(this)) {}

    // Initialize contract. This function can only be called once
    function initialize(address _managerProxy) external onlyOwner {
        require(!initialized, 'Factory: already initialized');
        _storage = new FactoryStorage(_managerProxy);
        initialized = true;
    }

    // This function allows to set sporkProxy address after deployment in order to enable upgrades
    function setSporkProxy(address payable _sporkProxy) public onlyOwner {
        IFactoryGovernedProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called in order to upgrade to a new Factory implementation
    function destroy(IGovernedContract _newImplementation) external requireProxy {
        IStorageBase(address(_storage)).setOwner(address(_newImplementation));

        // Self destruct
        _destroy(_newImplementation);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(IGovernedContract _oldImplementation) external requireProxy {
        _migrate(_oldImplementation);
    }

    function managerImplementation() private view returns (address _managerImplementation) {
        _managerImplementation = address(
            IGovernedProxy_New(address(uint160(_storage.getManagerProxy()))).implementation()
        );
    }

    // The reward payout of the farming pool with the shortest locking period is called 'base reward payout'. If the
    // allocPoints value of this farming pool with the shortest locking period is set to 1, then the allocPoints values
    // of the other farming pools can be seen as multipliers to the base reward payout (the other factor influencing the
    // reward payout being the amount of LP tokens staked). Using a high allocPoints value here will cause the farming
    // pool to payout more rewards.
    function deploy(uint256 lockingPeriodInSeconds, uint256 allocPoints) external onlyOwner {
        IManager(managerImplementation()).setTotalAllocPoints(
            IManager(managerImplementation()).getTotalAllocPoints().add(allocPoints)
        );

        address LPTokenAddress = IManager(managerImplementation()).getLPTokenAddress();

        address token0 = ILPToken(LPTokenAddress).token0();
        address token1 = ILPToken(LPTokenAddress).token1();

        address farmingStorageAddress = address(
            new FarmingStorage(
                _storage.getManagerProxy(),
                token0,
                token1,
                lockingPeriodInSeconds,
                allocPoints
            )
        );

        // Deploy farmingProxy via CREATE2
        bytes memory bytecode = abi.encodePacked(
            type(FarmingProxy).creationCode,
            abi.encode(_storage.getManagerProxy())
        );

        bytes32 salt = keccak256(abi.encode(_storage.getFarmingProxiesCount() + 1));

        address farmingProxyAddress;
        assembly {
            farmingProxyAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        // Register farmingProxy, and farmingStorage into manager
        IManager(managerImplementation()).registerPool(farmingProxyAddress, farmingStorageAddress);

        _storage.pushFarmingProxy(farmingProxyAddress);

        // Emit pool creation event
        IFactoryGovernedProxy(address(uint160(proxy))).emitPoolCreated(
            token0,
            token1,
            farmingProxyAddress,
            LPTokenAddress,
            _storage.getFarmingProxiesCount(),
            lockingPeriodInSeconds,
            allocPoints
        );
    }

    function getFarmingProxiesCount() external view returns (uint256) {
        return _storage.getFarmingProxiesCount();
    }

    function getFarmingProxyByIndex(uint256 _index) external view returns (address) {
        return _storage.getFarmingProxyByIndex(_index);
    }
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

interface ILPToken {
    function token0() external view returns (address);

    function token1() external view returns (address);
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

interface IERC20 {
    function name() external view returns (string memory _name);

    function symbol() external view returns (string memory _symbol);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
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

import { IGovernedProxy_New } from './../interfaces/IGovernedProxy_New.sol';
import { IFarmingStorage } from './IFarmingStorage.sol';

contract FarmingStorage is IFarmingStorage {
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

// Energi Governance system is the fundamental part of Energi Core.

// NOTE: It's not allowed to change the compiler due to byte-to-byte
//       match requirement.

pragma solidity 0.5.16;

import { NonReentrant } from '../NonReentrant.sol';

import { IGovernedProxy_New } from '../interfaces/IGovernedProxy_New.sol';
import { IManager } from '../manager/IManager.sol';
import { IFarmingProxy } from './IFarmingProxy.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

/**
 * SC-9: This contract has no chance of being updated. It must be stupid simple.
 *
 * If another upgrade logic is required in the future - it can be done as proxy stage II.
 */
contract FarmingProxy is NonReentrant, IFarmingProxy {
    address public managerProxyAddress;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        require(tx.origin == msg.sender, 'FarmingProxy: FORBIDDEN, not a direct call');
        _;
    }

    modifier requireManager() {
        require(msg.sender == manager(), 'FarmingProxy: FORBIDDEN, not Manager');
        _;
    }

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

    constructor(address _managerProxyAddress) public {
        managerProxyAddress = _managerProxyAddress;
    }

    function manager() private view returns (address _manager) {
        _manager = address(
            IGovernedProxy_New(address(uint160(managerProxyAddress))).implementation()
        );
    }

    function safeTransferTokenFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) external noReentry requireManager {
        IERC20(_token).transferFrom(_from, _to, _amount);
    }

    function safeTransferToken(
        address _token,
        address _to,
        uint256 _amount
    ) external noReentry requireManager {
        IERC20(_token).transfer(_to, _amount);
    }

    function emitMaxPoolRewardPerTokenPerSecondUpdated(uint256 maxPoolRewardPerTokenPerSecond)
        external
        requireManager
    {
        emit MaxPoolRewardPerTokenPerSecondUpdated(maxPoolRewardPerTokenPerSecond);
    }

    function emitStaked(
        address user,
        uint256 amount,
        uint256 newestLockingParcelIndex,
        uint256 lockTime
    ) external requireManager {
        emit Staked(user, amount, newestLockingParcelIndex, lockTime);
    }

    function emitWithdrawn(
        address user,
        uint256 amount,
        uint256 oldestLockingParcelIndex,
        uint256 leftoverAmountLockingParcel
    ) external requireManager {
        emit Withdrawn(user, amount, oldestLockingParcelIndex, leftoverAmountLockingParcel);
    }

    function emitRewardPaid(address user, uint256 reward) external requireManager {
        emit RewardPaid(user, reward);
    }

    function emitLockingPeriodUpdate(uint256 lockingPeriodInSeconds) external requireManager {
        emit LockingPeriodUpdate(lockingPeriodInSeconds);
    }

    function emitAllocPointsUpdate(uint256 allocPoints) external requireManager {
        emit AllocPointsUpdate(allocPoints);
    }

    function proxy() external view returns (address) {
        return address(this);
    }

    // Proxy all other calls to Manager.
    function() external payable senderOrigin {
        // SECURITY: senderOrigin() modifier is mandatory

        IManager _manager = IManager(manager());

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())

            let res := call(sub(gas(), 10000), _manager, callvalue(), ptr, calldatasize(), 0, 0)
            // NOTE: returndatasize should allow repeatable calls
            //       what should save one opcode.
            returndatacopy(ptr, 0, returndatasize())

            switch res
            case 0 {
                revert(ptr, returndatasize())
            }
            default {
                return(ptr, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactoryStorage {
    function getFarmingProxyByIndex(uint256 _index) external view returns (address);

    function getFarmingProxiesCount() external view returns (uint256);

    function pushFarmingProxy(address _farmingProxyAddress) external;

    function popFarmingProxy() external;

    function setFarmingProxyByIndex(uint256 _index, address _farmingProxyAddress) external;

    function getManagerProxy() external view returns (address);

    function setManagerProxy(address _managerProxy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactoryGovernedProxy {
    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address pool,
        address lpPair,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds,
        uint256 allocPoints
    );

    function emitPoolCreated(
        address token0,
        address token1,
        address pool,
        address lpPair,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds,
        uint256 allocPoints
    ) external;

    function spork_proxy() external view returns (address payable);

    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.5.16;

interface IFactory {
    function deploy(uint256 lockingPeriodInSeconds, uint256 allocPoints) external;

    function getFarmingProxiesCount() external view returns (uint256);

    function getFarmingProxyByIndex(uint256 _index) external view returns (address);
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
contract FactoryGovernedProxy is NonReentrant, IGovernedContract, IGovernedProxy_New {
  uint test = 0;
    IGovernedContract public implementation;
    IGovernedProxy_New public spork_proxy;
    mapping(address => IGovernedContract) public upgrade_proposals;
    IUpgradeProposal[] public upgrade_proposal_list;

    modifier senderOrigin() {
        // Internal calls are expected to use implementation directly.
        // That's due to use of call() instead of delegatecall() on purpose.
        // solium-disable-next-line security/no-tx-origin
        require(tx.origin == msg.sender, 'FactoryGovernedProxy: Only direct calls are allowed!');
        _;
    }

    modifier onlyImpl() {
        require(
            msg.sender == address(implementation),
            'FactoryGovernedProxy: Only calls from implementation are allowed!'
        );
        _;
    }

    event PoolCreated(
        address indexed token0,
        address indexed token1,
        address pool,
        address lpPair,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds,
        uint256 allocPoints
    );

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

    // Emit PoolCreated event
    function emitPoolCreated(
        address token0,
        address token1,
        address pool,
        address lpPair,
        uint256 allPoolsLength,
        uint256 lockingPeriodInSeconds,
        uint256 allocPoints
    ) external onlyImpl {
        emit PoolCreated(
            token0,
            token1,
            pool,
            lpPair,
            allPoolsLength,
            lockingPeriodInSeconds,
            allocPoints
        );
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
        require(_newImplementation != implementation, 'FactoryGovernedProxy: Already active!');
        require(_newImplementation.proxy() == address(this), 'FactoryGovernedProxy: Wrong proxy!');

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
        require(newImplementation != implementation, 'FactoryGovernedProxy: Already active!');
        // in case it changes in the flight
        require(address(newImplementation) != address(0), 'FactoryGovernedProxy: Not registered!');
        require(_proposal.isAccepted(), 'FactoryGovernedProxy: Not accepted!');

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
        require(address(newImplementation) != address(0), 'FactoryGovernedProxy: Not registered!');
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
        revert('FactoryGovernedProxy: Good try');
    }

    /**
     * SECURITY: prevent on-behalf-of calls
     */
    function destroy(IGovernedContract) external {
        revert('FactoryGovernedProxy: Good try');
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
                'FactoryGovernedProxy: delegatecall cannot be used'
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
import { FactoryGovernedProxy } from './FactoryGovernedProxy.sol';

/**
 * FactoryAutoProxy is a version of GovernedContract which deploys its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 * If you want a new governed contract to create a proxy, pass address(0) when deploying
 * otherwise, you can pass a proxy address like in normal GovernedContract
 */

contract FactoryAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) public GovernedContract(_proxy) {
        if (_proxy == address(0)) {
            _proxy = address(new FactoryGovernedProxy(_implementation));
        }
        proxy = _proxy;
    }
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