// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IGovernable {

    function getGovernanceAddress() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IStakingConfig.sol";

interface IStaking {

    function getStakingConfig() external view returns (IStakingConfig);

//    function getValidators() external view returns (address[] memory);

//    function isValidatorActive(address validator) external view returns (bool);

//    function isValidator(address validator) external view returns (bool);

    function getValidatorStatus(address validator) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

    function getValidatorStatusAtEpoch(address validator, uint64 epoch) external view returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    );

//    function getValidatorByOwner(address owner) external view returns (address);

//    function registerValidator(address validator, uint16 commissionRate, uint256 amount) payable external;

    function addValidator(address validator) external;

    function activateValidator(address validator) external;

    function disableValidator(address validator) external;

//    function releaseValidatorFromJail(address validator) external;

//    function changeValidatorCommissionRate(address validator, uint16 commissionRate) external;

    function changeValidatorOwner(address validator, address newOwner) external;

    function getValidatorDelegation(address validator, address delegator) external view returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    );

    function delegate(address validator, uint256 amount) payable external;

    function undelegate(address validator, uint256 amount) external;

//    function getValidatorFee(address validator) external view returns (uint256);

//    function getPendingValidatorFee(address validator) external view returns (uint256);

//    function claimValidatorFee(address validator) external;

    function getDelegatorFee(address validator, address delegator) external view returns (uint256);

    function getPendingDelegatorFee(address validator, address delegator) external view returns (uint256);

    function claimDelegatorFee(address validator) external;

    function claimStakingRewards(address validatorAddress) external;

    function claimPendingUndelegates(address validator) external;

    function calcAvailableForRedelegateAmount(address validator, address delegator) external view returns (uint256 amountToStake, uint256 rewardsDust);

    function calcAvailableForDelegateAmount(uint256 amount) external view returns (uint256 amountToStake, uint256 dust);

    function redelegateDelegatorFee(address validator) external;

    function currentEpoch() external view returns (uint64);

    function nextEpoch() external view returns (uint64);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IGovernable.sol";

interface IStakingConfig is IGovernable {

    function getActiveValidatorsLength() external view returns (uint32);

    function setActiveValidatorsLength(uint32 newValue) external;

    function getEpochBlockInterval() external view returns (uint32);

    function setEpochBlockInterval(uint32 newValue) external;

    function getMisdemeanorThreshold() external view returns (uint32);

    function setMisdemeanorThreshold(uint32 newValue) external;

    function getFelonyThreshold() external view returns (uint32);

    function setFelonyThreshold(uint32 newValue) external;

    function getValidatorJailEpochLength() external view returns (uint32);

    function setValidatorJailEpochLength(uint32 newValue) external;

    function getUndelegatePeriod() external view returns (uint32);

    function setUndelegatePeriod(uint32 newValue) external;

    function getMinValidatorStakeAmount() external view returns (uint256);

    function setMinValidatorStakeAmount(uint256 newValue) external;

    function getMinStakingAmount() external view returns (uint256);

    function setMinStakingAmount(uint256 newValue) external;

    function getGovernanceAddress() external view override returns (address);

    function setGovernanceAddress(address newValue) external;

    function getTreasuryAddress() external view returns (address);

    function setTreasuryAddress(address newValue) external;

    function getLockPeriod() external view returns (uint64);

    function setLockPeriod(uint64 newValue) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IStaking.sol";

interface ITokenStaking is IStaking {

    function getErc20Token() external view returns (IERC20);

    function distributeRewards(address validatorAddress, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "./IStakingConfig.sol";
import "../libs/ValidatorUtil.sol";

interface IValidatorStorage {

    function getValidator(address) external view returns (Validator memory);

    function validatorOwners(address) external view returns (address);

    function create(
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) external;

    function activate(address validatorAddress) external returns (Validator memory);

    function disable(address validatorAddress) external returns (Validator memory);

    function change(address validatorAddress, uint64 epoch) external;

    function changeOwner(address validatorAddress, address newOwner) external returns (Validator memory);

//    function activeValidatorsList() external view returns (address[] memory);

    function isOwner(address validatorAddress, address addr) external view returns (bool);

    function migrate(Validator calldata validator) external;

    function getValidators() external view returns (address[] memory);
}

pragma solidity ^0.8.0;

struct DelegationOpDelegate {
    // @dev stores the last sum(delegated)-sum(undelegated)
    uint112 amount;
    uint64 epoch;
    // last epoch when reward was claimed
    uint64 claimEpoch;
}

struct DelegationOpUndelegate {
    uint112 amount;
    uint64 epoch;
}

struct ValidatorDelegation {
    DelegationOpDelegate[] delegateQueue;
    uint64 delegateGap;
    DelegationOpUndelegate[] undelegateQueue;
    uint64 undelegateGap;
    uint112 withdrawnAmount;
    uint64 withdrawnEpoch;
}

library DelegationUtil {

//    function add(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        // if last pending delegate has the same next epoch then its safe to just increase total
//        // staked amount because it can't affect current validator set, but otherwise we must create
//        // new record in delegation queue with the last epoch (delegations are ordered by epoch)
//        if (self.delegateQueue.length > 0) {
//            DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
//            // if we already have pending snapshot for the next epoch then just increase new amount,
//            // otherwise create next pending snapshot. (tbh it can't be greater, but what we can do here instead?)
//            if (recentDelegateOp.epoch >= epoch) {
//                recentDelegateOp.amount += amount;
//            } else {
//                self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : recentDelegateOp.amount + amount}));
//            }
//        } else {
//            // there is no any delegations at al, lets create the first one
//            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : amount}));
//        }
//    }

//    function addInitial(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        require(self.delegateQueue.length == 0, "Delegation: already delegated");
//        self.delegateQueue.push(DelegationOpDelegate({amount : amount, epoch: epoch, claimEpoch : epoch}));
//    }

    // @dev before call check that queue is not empty
//    function shrinkDelegations(
//        ValidatorDelegation storage self,
//        uint112 amount,
//        uint64 epoch
//    ) internal {
//        // pull last item
//        DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
//        // calc next delegated amount
//        uint112 nextDelegatedAmount = recentDelegateOp.amount - amount;
//        if (nextDelegatedAmount == 0) {
//            delete self.delegateQueue[self.delegateQueue.length - 1];
//            self.delegateGap++;
//        } else if (recentDelegateOp.epoch >= epoch) {
//            // decrease total delegated amount for the next epoch
//            recentDelegateOp.amount = nextDelegatedAmount;
//        } else {
//            // there is no pending delegations, so lets create the new one with the new amount
//            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch: epoch, amount : nextDelegatedAmount}));
//        }
//        // stash withdrawn amount
//        if (epoch > self.withdrawnEpoch) {
//            self.withdrawnEpoch = epoch;
//            self.withdrawnAmount = amount;
//        } else if (epoch == self.withdrawnEpoch) {
//            self.withdrawnAmount += amount;
//        }
//    }

//    function getWithdrawn(
//        ValidatorDelegation memory self,
//        uint64 epoch
//    ) internal pure returns (uint112) {
//        return epoch >= self.withdrawnEpoch ? 0 : self.withdrawnAmount;
//    }

//    function calcWithdrawalAmount(ValidatorDelegation memory self, uint64 beforeEpochExclude, bool checkEpoch) internal pure returns (uint256 amount) {
//        while (self.undelegateGap < self.undelegateQueue.length) {
//            DelegationOpUndelegate memory undelegateOp = self.undelegateQueue[self.undelegateGap];
//            if (checkEpoch && undelegateOp.epoch > beforeEpochExclude) {
//                break;
//            }
//            amount += uint256(undelegateOp.amount);
//            ++self.undelegateGap;
//        }
//    }

//    function getStaked(ValidatorDelegation memory self) internal pure returns (uint256) {
//        return self.delegateQueue[self.delegateQueue.length - 1].amount;
//    }

}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

library MathUtils {

    function saturatingMultiply(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
        if (a == 0) return 0;
        uint256 c = a * b;
        if (c / a != b) return type(uint256).max;
        return c;
    }
    }

    function saturatingAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return type(uint256).max;
        return c;
    }
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(floor((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideFloor(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        return
        saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b) / c // can't fail because of assumption 2.
        );
    }

    // Preconditions:
    //  1. a may be arbitrary (up to 2 ** 256 - 1)
    //  2. b * c < 2 ** 256
    // Returned value: min(ceil((a * b) / c), 2 ** 256 - 1)
    function multiplyAndDivideCeil(
        uint256 a,
        uint256 b,
        uint256 c
    ) internal pure returns (uint256) {
        require(c != 0, "c == 0");
        return
        saturatingAdd(
            saturatingMultiply(a / c, b),
            ((a % c) * b + (c - 1)) / c // can't fail because of assumption 2.
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

contract Multicall {

    function multicall(bytes[] calldata data) external returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            // this is an optimized a bit multicall w/o using of Address library (it safes a lot of bytecode)
            results[i] = _fastDelegateCall(data[i]);
        }
        return results;
    }

    function _fastDelegateCall(bytes memory data) private returns (bytes memory _result) {
        (bool success, bytes memory returnData) = address(this).delegatecall(data);
        if (success) {
            return returnData;
        }
        if (returnData.length > 0) {
            assembly {
                revert(add(32, returnData), mload(returnData))
            }
        } else {
            revert();
        }
    }
}

pragma solidity ^0.8.0;

struct ValidatorSnapshot {
    uint96 totalRewards;
    uint112 totalDelegated;
    uint32 slashesCount;
    uint16 commissionRate;
}

library SnapshotUtil {

    // @dev ownerFee_(18+4-4=18) = totalRewards_18 * commissionRate_4 / 1e4
    function getOwnerFee(ValidatorSnapshot memory self) internal pure returns (uint256) {
        return uint256(self.totalRewards) * self.commissionRate / 1e4;
    }

    function create(
        ValidatorSnapshot storage self,
        uint112 initialStake,
        uint16 commissionRate
    ) internal {
        self.totalRewards = 0;
        self.totalDelegated = initialStake;
        self.slashesCount = 0;
        self.commissionRate = commissionRate;
    }

//    function slash(ValidatorSnapshot storage self) internal returns (uint32) {
//        self.slashesCount += 1;
//        return self.slashesCount;
//    }

    function safeDecreaseDelegated(
        ValidatorSnapshot storage self,
        uint112 amount
    ) internal {
        require(self.totalDelegated >= amount, "ValidatorSnapshot: insufficient balance");
        self.totalDelegated -= amount;
    }
}

pragma solidity ^0.8.0;

enum ValidatorStatus {
    NotFound,
    Active,
    Pending,
    Jail
}

struct Validator {
    address validatorAddress;
    address ownerAddress;
    ValidatorStatus status;
    uint64 changedAt;
    uint64 jailedBefore;
    uint64 claimedAt;
}

library ValidatorUtil {

//    function isActive(Validator memory self) internal pure returns (bool) {
//        return self.status == ValidatorStatus.Active;
//    }
//
//    function isOwner(
//        Validator memory self,
//        address addr
//    ) internal pure returns (bool) {
//        return self.ownerAddress == addr;
//    }

//    function create(
//        Validator storage self,
//        address validatorAddress,
//        address validatorOwner,
//        ValidatorStatus status,
//        uint64 epoch
//    ) internal {
//        require(self.status == ValidatorStatus.NotFound, "Validator: already exist");
//        self.validatorAddress = validatorAddress;
//        self.ownerAddress = validatorOwner;
//        self.status = status;
//        self.changedAt = epoch;
//    }

//    function activate(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
//        self.status = ValidatorStatus.Active;
//        return self;
//    }

//    function disable(
//        Validator storage self
//    ) internal returns (Validator memory vldtr) {
//        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
//        self.status = ValidatorStatus.Pending;
//        return self;
//    }

//    function jail(
//        Validator storage self,
//        uint64 beforeEpoch
//    ) internal {
//        require(self.status != ValidatorStatus.NotFound, "Validator: not found");
//        self.jailedBefore = beforeEpoch;
//        self.status = ValidatorStatus.Jail;
//    }

//    function unJail(
//        Validator storage self,
//        uint64 epoch
//    ) internal {
//        // make sure validator is in jail
//        require(self.status == ValidatorStatus.Jail, "Validator: bad status");
//        // only validator owner
//        require(msg.sender == self.ownerAddress, "Validator: only owner");
//        require(epoch >= self.jailedBefore, "Validator: still in jail");
//        forceUnJail(self);
//    }

    // @dev release validator from jail
//    function forceUnJail(
//        Validator storage self
//    ) internal {
//        // update validator status
//        self.status = ValidatorStatus.Active;
//        self.jailedBefore = 0;
//    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../staking/extension/TokenStaking.sol";
import "../staking/StakingConfig.sol";

contract AnkrTokenStaking is TokenStaking {

    function initialize(IStakingConfig stakingConfig, IERC20 ankrToken) external initializer {
        __TokenStaking_init(stakingConfig, ankrToken);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IStaking.sol";
import "../libs/ValidatorUtil.sol";
import "../libs/SnapshotUtil.sol";
import "../libs/DelegationUtil.sol";

/*
 * abstract BaseStaking contract implements common methods and constants needed for epoch staking
 * base layer of contract
 */
abstract contract BaseStaking is Initializable, IStaking {

    /**
     * This constant indicates precision of storing compact balances in the storage or floating point. Since default
     * balance precision is 256 bits it might gain some overhead on the storage because we don't need to store such huge
     * amount range. That is why we compact balances in uint112 values instead of uint256. By managing this value
     * you can set the precision of your balances, aka min and max possible staking amount. This value depends
     * mostly on your asset price in USD, for example ETH costs 4000$ then if we use 1 ether precision it takes 4000$
     * as min amount that might be problematic for users to do the stake. We can set 1 gwei precision and in this case
     * we increase min staking amount in 1e9 times, but also decreases max staking amount or total amount of staked assets.
     *
     * Here is an universal formula, if your asset is cheap in USD equivalent, like ~1$, then use 1 ether precision,
     * otherwise it might be better to use 1 gwei precision or any other amount that your want.
     *
     * Also be careful with setting `minValidatorStakeAmount` and `minStakingAmount`, because these values has
     * the same precision as specified here. It means that if you set precision 1 ether, then min staking amount of 10
     * tokens should have 10 raw value. For 1 gwei precision 10 tokens min amount should be stored as 10000000000.
     *
     * For the 112 bits we have ~32 decimals lg(2**112)=33.71 (lets round to 32 for simplicity). We split this amount
     * into integer (24) and for fractional (8) parts. It means that we can have only 8 decimals after zero.
     *
     * Based in current params we have next min/max values:
     * - min staking amount: 0.00000001 or 1e-8
     * - max staking amount: 1000000000000000000000000 or 1e+24
     *
     * WARNING: precision must be a 1eN format (A=1, N>0)
     */
    uint256 internal constant BALANCE_COMPACT_PRECISION = 1e10;
    /**
     * Here is min/max commission rates. Lets don't allow to set more than 30% of validator commission, because it's
     * too big commission for validator. Commission rate is a percents divided by 100 stored with 0 decimals as percents*100 (=pc/1e2*1e4)
     *
     * Here is some examples:
     * + 0.3% => 0.3*100=30
     * + 3% => 3*100=300
     * + 30% => 30*100=3000
     */
    uint16 internal constant COMMISSION_RATE_MIN_VALUE = 0; // 0%
    uint16 internal constant COMMISSION_RATE_MAX_VALUE = 3000; // 30%
    /**
     * This gas limit is used for internal transfers, BSC doesn't support berlin and it
     * might cause problems with smart contracts who used to stake transparent proxies or
     * beacon proxies that have a lot of expensive SLOAD instructions.
     */
    uint64 internal constant TRANSFER_GAS_LIMIT = 30_000;
    /**
     * Some items are stored in the queues and we must iterate though them to
     * execute one by one. Somtimes gas might not be enough for the tx execution.
     */
    uint32 internal constant CLAIM_BEFORE_GAS = 100_000;

    // validator events
    event ValidatorAdded(address indexed validator, address owner, uint8 status, uint16 commissionRate);
    event ValidatorModified(address indexed validator, address owner, uint8 status, uint16 commissionRate);
    event ValidatorRemoved(address indexed validator);
    event ValidatorOwnerClaimed(address indexed validator, uint256 amount, uint64 epoch);
    event ValidatorSlashed(address indexed validator, uint32 slashes, uint64 epoch);
    event ValidatorJailed(address indexed validator, uint64 epoch);
    event ValidatorDeposited(address indexed validator, uint256 amount, uint64 epoch);
    event ValidatorReleased(address indexed validator, uint64 epoch);

    // staker events
    event Delegated(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Undelegated(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Claimed(address indexed validator, address indexed staker, uint256 amount, uint64 epoch);
    event Redelegated(address indexed validator, address indexed staker, uint256 amount, uint256 dust, uint64 epoch);

    // mapping from validator address to validator
    mapping(address => Validator) internal _validatorsMap;
    // mapping from validator owner to validator address
    mapping(address => address) internal _validatorOwners;
    // list of all validators that are in validators mapping
    address[] internal _activeValidatorsList;
    // mapping with stakers to validators at epoch (validator -> delegator -> delegation)
    mapping(address => mapping(address => ValidatorDelegation)) internal _validatorDelegations;
    // mapping with validator snapshots per each epoch (validator -> epoch -> snapshot)
    mapping(address => mapping(uint64 => ValidatorSnapshot)) internal _validatorSnapshots;
    // chain config with params
    IStakingConfig internal _stakingConfig;
    // reserve some gap for the future upgrades
    uint256[50 - 7] private __reserved;

    modifier onlyFromGovernance() virtual {
        require(msg.sender == _stakingConfig.getGovernanceAddress(), "Staking: only governance");
        _;
    }

    function __BaseStaking_init(IStakingConfig stakingConfig) internal onlyInitializing {
        _stakingConfig = stakingConfig;
    }

    function getStakingConfig() external view virtual override returns (IStakingConfig) {
        return _stakingConfig;
    }

    /*
     * @return last confirmed epoch
     */
    function currentEpoch() public view override virtual returns (uint64) {
        return uint64(block.number / _stakingConfig.getEpochBlockInterval());
    }

    /*
     * @return pending epoch
     */
    function nextEpoch() public view override virtual returns (uint64) {
        return currentEpoch() + 1;
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../libs/Multicall.sol";
import "../libs/ValidatorUtil.sol";
import "../libs/SnapshotUtil.sol";
import "../libs/DelegationUtil.sol";

import "../interfaces/IStakingConfig.sol";
import "../interfaces/IStaking.sol";

import "./ValidatorRegistry.sol";
import "../libs/MathUtils.sol";

abstract contract Staking is ValidatorRegistry, Multicall {

    using SnapshotUtil for ValidatorSnapshot;

    struct ValidatorPool {
        address validatorAddress; // address of validator
        uint96 totalRewards; // total rewards available for delegators
        uint256 sharesSupply; // total shares supply
        uint256 unlocked; // amount unlocked to claim
    }

    /*
     * @dev delegator data
     */
    struct DelegationHistory {
        Delegation[] delegations; // existing delegations
        /**
         * last epoch when made unlock
         * needed to give ability to undelegate only after UndelegatePeriod
         */
        uint64 lastUnlockEpoch;
        uint256 unlockedAmount; // amount not participating in staking
        uint256 delegationGap;
    }

    /*
     * @dev record with delegation data for particular epoch
     */
    struct Delegation {
        uint64 epoch; // particular epoch of record
        uint112 amount; // delegated amount in particular epoch
        /*
         * @dev amount - fromShares(validatorPool, shares) = rewards
         */
        uint256 shares; // amount represented in shares (give ability to accumulate rewards)
        uint96 claimed; // claimed amount of rewards
    }

    /*
     * validator => delegator => delegations
     * @dev history of staker for particular validator
     */
    mapping(address => mapping(address => DelegationHistory)) internal _delegationHistory;

    /*
     * validator pools (validator => pool)
     * @dev all existing pools of validators
     */
    mapping(address => ValidatorPool) internal _validatorPools;

    /*
     * allocated shares (validator => staker => shares)
     * @dev total delegator shares and delegated amount of validator pool
     */
    mapping(address => mapping(address => uint256)) internal _stakerShares;
    mapping(address => mapping(address => uint112)) internal _stakerAmounts;

    uint64 public _MIGRATION_EPOCH;
    bool internal _VALIDATORS_MIGRATED;
    mapping(address => bool) public isMigratedDelegator;

    // reserve some gap for the future upgrades
    uint256[25 - 6] private __reserved;

    /*
     * used by frontend
     * @return amount - undelegated amount + available rewards
     */
    function getDelegatorFee(address validator, address delegator) external override view returns (uint256 amount) {
        uint64 epoch = nextEpoch();
        if (_delegationHistory[validator][delegator].lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() < epoch) {
            amount += _delegationHistory[validator][delegator].unlockedAmount;
        }
        amount += _calcRewards(validator, delegator);
    }

    function getPendingDelegatorFee(address validator, address delegator) external override view returns (uint256) {
        uint64 epoch = nextEpoch();
        if (_delegationHistory[validator][delegator].lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() >= epoch) {
            return _delegationHistory[validator][delegator].unlockedAmount;
        }
        return 0;
    }

    /*
     * used by front-end
     * @return staking rewards available for claim
     */
    function getStakingRewards(address validator, address delegator) external view returns (uint256) {
        return _calcRewards(validator, delegator);
    }

    /*
     * used by front-end
     * @notice calculate available for redelegate amount of rewards
     * @return amountToStake - amount of rewards ready to restake
     * @return rewardsDust - not stakeable part of rewards
     */
    function calcAvailableForRedelegateAmount(address validator, address delegator) external view override returns (uint256 amountToStake, uint256 rewardsDust) {
        uint256 claimableRewards = _calcRewards(validator, delegator);
        return calcAvailableForDelegateAmount(claimableRewards);
    }

    /**
     * @notice should use it for split re/delegate amount into stake-able and dust
     * @return amountToStake - amount possible to stake without dust part
     * @return dust - not stakeable part
     */
    function calcAvailableForDelegateAmount(uint256 amount) public pure override returns (uint256 amountToStake, uint256 dust) {
        amountToStake = (amount / BALANCE_COMPACT_PRECISION) * BALANCE_COMPACT_PRECISION;
        dust = amount - amountToStake;
        return (amountToStake, dust);
    }

    /*
     * @dev collect diff between delegated amount and current shares amount
     */
    function _calcRewards(address validator, address delegator) internal view returns (uint256 rewards) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        for (uint256 i = history.delegationGap; i < delegations.length; i++) {
            // diff between current shares value and delegated amount is profit
            uint256 balance = _fromShares(validatorPool, delegations[i].shares) - delegations[i].claimed;
            uint256 amount = uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
            if (balance > amount) {
                rewards += balance - amount;
            }
        }
    }

    /*
     * used by frontend
     * @return atEpoch - epoch of last delegation
     * @return delegatedAmount - current delegated amount
     */
    function getValidatorDelegation(address validator, address delegator) external view override returns (
        uint256 delegatedAmount,
        uint64 atEpoch
    ) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        if (history.delegations.length - history.delegationGap == 0) {
            return (0, 0);
        }
        (, delegatedAmount) = _calcTotal(history);
        delegatedAmount = delegatedAmount * BALANCE_COMPACT_PRECISION;

        atEpoch = history.delegations[history.delegations.length - 1].epoch;
    }

    function _calcTotal(DelegationHistory memory history) internal pure returns (uint256 shares, uint256 amount) {
        Delegation[] memory delegations = history.delegations;
        uint256 length = delegations.length;

        for (uint i = history.delegationGap; i < length; i++) {
            shares += delegations[i].shares;
            amount += delegations[i].amount;
        }
    }

    /*
     * used by frontend
     * @return amount ready to be unlocked
     */
    function calcUnlockedDelegatedAmount(address validator, address delegator) public view returns (uint256) {
        return _calcUnlocked(validator, delegator) * BALANCE_COMPACT_PRECISION;
    }

    function _calcUnlocked(address validator, address delegator) internal view returns (uint256 unlockedAmount) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;
        uint256 length = delegations.length;

        uint64 lockPeriod = _stakingConfig.getLockPeriod();
        uint64 epoch = nextEpoch();

        for (uint i; i < length && delegations[i].epoch + lockPeriod < epoch; i++) {
            unlockedAmount += uint256(delegations[i].amount);
        }
    }

    /*
     * used by frontend
     * @notice claim available rewards and unlocked amount
     */
    function claimDelegatorFee(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        // collect rewards from records
        uint256 claimAmount = _claimRewards(validator, msg.sender);
        // collect unlocked
        claimAmount += _claimUnlocked(validator, msg.sender, epoch);

        _safeTransferWithGasLimit(payable(msg.sender), claimAmount);
        emit Claimed(validator, msg.sender, claimAmount, epoch);
    }

    /*
     * used by frontend
     * @notice claim only available rewards
     */
    function claimStakingRewards(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        uint256 amount = _claimRewards(validator, msg.sender);
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev extract extra balance from shares and deduct it
     * @return rewards amount to withdraw
     */
    function _claimRewards(address validator, address delegator) internal returns (uint96 availableRewards) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;

        // get storage instance
        Delegation[] storage storageDelegations = _delegationHistory[validator][delegator].delegations;

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint96 recordReward;
        // look at all records
        for (uint i = history.delegationGap; i < delegations.length; i++) {
            // calculate diff between shares and delegated amount
            uint256 balance = _fromShares(validatorPool, delegations[i].shares) - delegations[i].claimed;
            uint256 amount = uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
            if (balance > amount) {
                recordReward = uint96(balance - amount);
                availableRewards += recordReward;
                delegations[i].claimed += recordReward;
                // write to storage
                storageDelegations[i] = delegations[i];
            }
        }
    }

    /*
     * used by frontend
     * @notice claim only unlocked delegates
     */
    function claimPendingUndelegates(address validator) external override {
        migrateDelegator(msg.sender);
        uint64 epoch = nextEpoch();
        uint256 amount = _claimUnlocked(validator, msg.sender, epoch);
        // transfer unlocked
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        // emit event
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev will not revert tx because used in pair with rewards methods
     * @return unlocked amount to send
     */
    function _claimUnlocked(address validator, address delegator, uint64 epoch) internal returns (uint256 unlockedAmount) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        unlockedAmount = history.unlockedAmount;

        // if nothing to unlock return zero
        if (unlockedAmount == 0) {
            return unlockedAmount;
        }
        // if unlock not happened return zero
        if (history.lastUnlockEpoch + _stakingConfig.getUndelegatePeriod() >= epoch) {
            return 0;
        }

        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        require(validatorPool.unlocked >= unlockedAmount, "nothing to undelegate");

        // update validator pool
        validatorPool.unlocked -= unlockedAmount;
        _validatorPools[validator] = validatorPool;

        // reset state
        _delegationHistory[validator][delegator].unlockedAmount = 0;
    }

    /*
     * used by frontend
     * @notice get delegations queue as-is
     * @return list of delegations
     */
    function getDelegateQueue(address validator, address delegator) public view returns (Delegation[] memory queue) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;
        queue = new Delegation[](delegations.length - history.delegationGap);
        for (uint gap; history.delegationGap < delegations.length; gap++) {
            Delegation memory delegation = delegations[history.delegationGap++];
            queue[gap] = delegation;
        }
    }

    function _toShares(ValidatorPool memory validatorPool, uint256 amount) internal view returns (uint256) {
        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        if (totalDelegated == 0) {
            return amount;
        } else {
            return MathUtils.multiplyAndDivideCeil(
                amount,
                validatorPool.sharesSupply,
                totalDelegated + validatorPool.totalRewards
            );
        }
    }

    function fromShares(address validator, uint256 shares) external view returns (uint256) {
        return _fromShares(_getValidatorPool(validator), shares);
    }

    function _fromShares(ValidatorPool memory validatorPool, uint256 shares) internal view returns (uint256) {
        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        if (totalDelegated == 0) {
            return shares;
        } else {
            return MathUtils.multiplyAndDivideFloor(
                shares,
                totalDelegated + validatorPool.totalRewards,
                validatorPool.sharesSupply
            );
        }
    }

    /*
     * used by frontend
     * @notice undelegate an amount of unlocked delegations
     */
    function undelegate(address validator, uint256 amount) external override {
        migrateDelegator(msg.sender);
        _undelegate(validator, msg.sender, amount);
    }

    /*
     * @dev before new undelegate already unlocked should be claimed
     * @dev if not, existing unlocked amount will be available only in nextEpoch + getUndelegatePeriod
     * @dev rewards should be claimed during undelegate, because stashed records will not produce new reward
     */
    function _undelegate(address validator, address delegator, uint256 amount) internal {
        require(amount >= BALANCE_COMPACT_PRECISION, "too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 totalDelegated = getTotalDelegated(validatorPool.validatorAddress);
        require(totalDelegated > 0, "insufficient balance");

        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        require(uint256(compactAmount) * BALANCE_COMPACT_PRECISION == amount, "overflow");
        require(compactAmount <= _stakerAmounts[validator][delegator], "insufficient balance");

        uint64 beforeEpoch = nextEpoch();

        (uint96 claimed, uint256 shares) = _stashUnlocked(validatorPool, delegator, compactAmount, beforeEpoch);

        // deduct unlocked amount in shares from spentShare to get reward
        uint256 stashed = _fromShares(validatorPool, shares);
        uint96 totalRewards;
        if (stashed > amount) {
            totalRewards = uint96(stashed - amount);
        }

        // remove amount from validator
        _removeDelegate(validator, compactAmount, beforeEpoch);

        // update delegator state
        _stakerAmounts[validator][delegator] -= compactAmount;
        _stakerShares[validator][delegator] -= shares;
        // add pending
        validatorPool.unlocked += amount;
        // remove claimed rewards from pool
        validatorPool.totalRewards -= totalRewards;
        // deduct undelegated shares
        validatorPool.sharesSupply -= shares;

        // save the state
        _validatorPools[validator] = validatorPool;
        // send rewards from stashed
        _safeTransferWithGasLimit(payable(delegator), totalRewards - claimed);
        // emit event
        emit Claimed(validator, delegator, totalRewards - claimed, beforeEpoch);
        emit Undelegated(validator, delegator, amount, beforeEpoch);
    }

    /*
     * @dev removes amount from unlocked records
     * @dev fulfilled records deleted
     * @return usedShares - spent shares for reward
     * @return rewards - amount of claimed rewards
     */
    function _stashUnlocked(
        ValidatorPool memory validatorPool,
        address delegator,
        uint112 expectedAmount,
        uint64 beforeEpoch
    ) internal returns (uint96 claimed, uint256 spentShares) {

        DelegationHistory memory history = _delegationHistory[validatorPool.validatorAddress][delegator];
        Delegation[] memory delegations = history.delegations;

        // work with memory because we can't copy array
        Delegation[] storage storageDelegations = _delegationHistory[validatorPool.validatorAddress][delegator].delegations;

        uint64 lockPeriod = _stakingConfig.getLockPeriod();
        uint256 unlockedAmount = uint256(expectedAmount) * BALANCE_COMPACT_PRECISION;

        while(history.delegationGap < delegations.length && delegations[history.delegationGap].epoch + lockPeriod < beforeEpoch && expectedAmount > 0) {
            if (delegations[history.delegationGap].amount > expectedAmount) {
                // calculate particular part of shares to remove
                // shares = expected / amount * shares;
                uint256 ratio = MathUtils.multiplyAndDivideFloor(expectedAmount * BALANCE_COMPACT_PRECISION, (1e18 / BALANCE_COMPACT_PRECISION), delegations[history.delegationGap].amount);
                uint256 shares = ratio * delegations[history.delegationGap].shares / 1e18;
                uint96 spentClaimed = uint96(ratio * delegations[history.delegationGap].claimed / 1e18);

                delegations[history.delegationGap].amount -= expectedAmount;
                delegations[history.delegationGap].shares -= shares;
                delegations[history.delegationGap].claimed -= spentClaimed;

                spentShares += shares;
                claimed += spentClaimed;
                // expected amount is filled
                expectedAmount = 0;
                // save changes to storage
                storageDelegations[history.delegationGap] = delegations[history.delegationGap];
                break;
            }
            expectedAmount -= delegations[history.delegationGap].amount;
            claimed += delegations[history.delegationGap].claimed;
            spentShares += delegations[history.delegationGap].shares;
            delete storageDelegations[history.delegationGap];
            history.delegationGap++;
        }

        require(expectedAmount == 0, "still locked");

        // save new state
        _delegationHistory[validatorPool.validatorAddress][delegator].delegationGap = history.delegationGap;
        _delegationHistory[validatorPool.validatorAddress][delegator].unlockedAmount += unlockedAmount;
        _delegationHistory[validatorPool.validatorAddress][delegator].lastUnlockEpoch = beforeEpoch;
    }

    function _getValidatorPool(address validator) internal view returns (ValidatorPool memory) {
        ValidatorPool memory validatorPool = _validatorPools[validator];
        validatorPool.validatorAddress = validator;
        return validatorPool;
    }

    /*
     * used by frontend
     * @notice make new delegation using available rewards
     */
    function redelegateDelegatorFee(address validator) external override {
        migrateDelegator(msg.sender);
        uint256 rewards = _claimRewards(validator, msg.sender);
        uint256 dust;
        (rewards, dust) = calcAvailableForDelegateAmount(rewards);
        require(rewards > 0, "too low");
        uint64 sinceEpoch = nextEpoch();
        _delegateUnsafe(validator, msg.sender, rewards, sinceEpoch);
        _safeTransferWithGasLimit(payable(msg.sender), dust);
        emit Redelegated(validator, msg.sender, rewards, dust, sinceEpoch);
    }

    function _delegate(address validator, address delegator, uint256 amount) internal {
        migrateDelegator(msg.sender);
        require(amount >= _stakingConfig.getMinStakingAmount(), "less than min");
        // get next epoch
        uint64 sinceEpoch = nextEpoch();
        _delegateUnsafe(validator, delegator, amount, sinceEpoch);
        // emit event
        emit Delegated(validator, delegator, amount, sinceEpoch);
    }

    /*
     * @dev check values before this method
     */
    function _delegateUnsafe(address validator, address delegator, uint256 amount, uint64 sinceEpoch) internal override {
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        require(uint256(compactAmount) * BALANCE_COMPACT_PRECISION == amount, "overflow");
        // add delegated amount to validator snapshot, revert if validator not exist

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 shares = _toShares(validatorPool, amount);
        // increase total accumulated shares for the staker
        _stakerShares[validator][delegator] += shares;
        // increase total accumulated amount for the staker
        _stakerAmounts[validator][delegator] += compactAmount;
        validatorPool.sharesSupply += shares;
        // save validator pool
        _addDelegate(validator, compactAmount, sinceEpoch);

        _adjustDelegation(validator, delegator, sinceEpoch, shares, compactAmount);

        _validatorPools[validator] = validatorPool;
    }

    function _adjustDelegation(address validator, address delegator, uint64 epoch, uint256 shares, uint112 amount) internal {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] storage delegations = _delegationHistory[validator][delegator].delegations;
        uint256 length = delegations.length;

        if (length - history.delegationGap > 0 && delegations[length - 1].epoch >= epoch) {
            delegations[length - 1].amount = delegations[length - 1].amount + amount;
            delegations[length - 1].shares += shares;
        } else {
            delegations.push(Delegation(epoch, amount, shares, 0));
        }
    }

    function _addReward(address validator, uint96 amount) internal override {
        _validatorPools[validator].totalRewards += amount;
    }

    //  __  __ _                 _   _
    // |  \/  (_) __ _ _ __ __ _| |_(_) ___  _ __
    // | |\/| | |/ _` | '__/ _` | __| |/ _ \| '_ \
    // | |  | | | (_| | | | (_| | |_| | (_) | | | |
    // |_|  |_|_|\__, |_|  \__,_|\__|_|\___/|_| |_|
    //           |___/

    function migrateValidators() external onlyFromGovernance {
        address[] memory validators = _activeValidatorsList;
        require(!_VALIDATORS_MIGRATED, "already migrated");

        for (uint256 i; i < validators.length; i++) {
            address validatorAddress = validators[i];
            // migrate validator to new storage contract
            Validator memory validator = _validatorsMap[validatorAddress];
            _validatorStorage.migrate(validator);
            delete _validatorsMap[validatorAddress];

            // create validatorPool using validator snapshot
            (,,uint256 totalDelegated,,,,,,) = getValidatorStatus(validatorAddress);
            ValidatorPool memory validatorPool = ValidatorPool(validatorAddress, 0, totalDelegated, 0);
            _validatorPools[validatorAddress] = validatorPool;
        }

        _MIGRATION_EPOCH = nextEpoch();
        _VALIDATORS_MIGRATED = true;
    }

    function migrateDelegator(address delegator) public {
        address[] memory validators = _validatorStorage.getValidators();

        if (isMigratedDelegator[delegator]) {
            return;
        }
        isMigratedDelegator[delegator] = true;

        require(validators.length > 0, "no validators");

        ValidatorDelegation memory delegations;
        DelegationHistory memory history;

        for (uint256 i; i < validators.length; i++) {
            address validatorAddress = validators[i];
            // first of all claim all rewards
            _transferDelegatorRewards(validatorAddress, delegator);

            delegations = _validatorDelegations[validatorAddress][delegator];
            ValidatorPool memory validatorPool = _validatorPools[validatorAddress];
            Delegation[] storage newDelegations = _delegationHistory[validatorAddress][delegator].delegations;

            {
                if (delegations.delegateQueue.length - delegations.delegateGap > 0) {
                    uint112 staked = delegations.delegateQueue[delegations.delegateQueue.length - 1].amount;
                    // merge all records in one with the earliest epoch and latest staked amount
                    newDelegations.push(
                        Delegation(delegations.delegateQueue[delegations.delegateGap].epoch, staked, uint256(staked) * BALANCE_COMPACT_PRECISION, 0)
                    );
                    _stakerAmounts[validatorAddress][delegator] = staked;
                    _stakerShares[validatorAddress][delegator] = uint256(staked) * BALANCE_COMPACT_PRECISION;
                }
            }

            {
                uint112 undelegated;
                for (uint256 j = delegations.undelegateGap; j < delegations.undelegateQueue.length; j++) {
                    undelegated += delegations.undelegateQueue[j].amount;
                    history.lastUnlockEpoch = delegations.undelegateQueue[j].epoch;
                }
                _delegationHistory[validatorAddress][delegator].lastUnlockEpoch = history.lastUnlockEpoch;
                _delegationHistory[validatorAddress][delegator].unlockedAmount = uint256(undelegated) * BALANCE_COMPACT_PRECISION;
                validatorPool.unlocked += uint256(undelegated) * BALANCE_COMPACT_PRECISION;
            }

            delete _validatorDelegations[validatorAddress][delegator];
            _validatorPools[validatorAddress] = validatorPool;
            _delegationHistory[validatorAddress][delegator].delegations = newDelegations;
        }
    }

    // modified method from EpochStaking
    function _transferDelegatorRewards(address validator, address delegator) internal {
        // next epoch to claim all rewards including pending
        uint64 beforeEpochExclude = _MIGRATION_EPOCH;
        // claim rewards and undelegates
        uint256 availableFunds = _processDelegateQueue(validator, delegator, beforeEpochExclude);
        // for transfer claim mode just all rewards to the user
        _safeTransferWithGasLimit(payable(delegator), availableFunds);
        // emit event
        emit Claimed(validator, delegator, availableFunds, beforeEpochExclude);
    }

    function _processDelegateQueue(address validator, address delegator, uint64 beforeEpochExclude) internal view returns (uint256 availableFunds) {
        ValidatorDelegation memory delegation = _validatorDelegations[validator][delegator];
        uint64 delegateGap = delegation.delegateGap;
        // lets iterate delegations from delegateGap to queueLength
        for (; delegateGap < delegation.delegateQueue.length; delegateGap++) {
            // pull delegation
            DelegationOpDelegate memory delegateOp = delegation.delegateQueue[delegateGap];
            if (delegateOp.epoch >= beforeEpochExclude) {
                break;
            }
            (uint256 extracted, /* uint64 claimedAt */) = _extractClaimable(delegation, delegateGap, validator, beforeEpochExclude);
            availableFunds += extracted;
        }
    }

    // extract rewards from claimEpoch to nextDelegationEpoch or beforeEpoch
    function _extractClaimable(
        ValidatorDelegation memory delegation,
        uint64 gap,
        address validator,
        uint256 beforeEpoch
    ) internal view returns (uint256 availableFunds, uint64 lastEpoch) {
        DelegationOpDelegate memory delegateOp = delegation.delegateQueue[gap];
        // if delegateOp was created before field claimEpoch added
        if (delegateOp.claimEpoch == 0) {
            delegateOp.claimEpoch = delegateOp.epoch;
        }

        // we must extract claimable rewards before next delegation
        uint256 nextDelegationEpoch;
        if (gap < delegation.delegateQueue.length - 1) {
            nextDelegationEpoch = delegation.delegateQueue[gap + 1].epoch;
        }

        for (; delegateOp.claimEpoch < beforeEpoch && (nextDelegationEpoch == 0 || delegateOp.claimEpoch < nextDelegationEpoch); delegateOp.claimEpoch++) {
            ValidatorSnapshot memory validatorSnapshot = _validatorSnapshots[validator][delegateOp.claimEpoch];
            if (validatorSnapshot.totalDelegated == 0) {
                continue;
            }
            (uint256 delegatorFee, /*uint256 ownerFee*/, /*uint256 systemFee*/) = _calcValidatorSnapshotEpochPayout(validatorSnapshot);
            availableFunds += delegatorFee * delegateOp.amount / validatorSnapshot.totalDelegated;
        }
        return (availableFunds, delegateOp.claimEpoch);
    }

    function _calcValidatorSnapshotEpochPayout(ValidatorSnapshot memory validatorSnapshot) internal view returns (uint256 delegatorFee, uint256 ownerFee, uint256 systemFee) {
        // detect validator slashing to transfer all rewards to treasury
        if (validatorSnapshot.slashesCount >= _stakingConfig.getMisdemeanorThreshold()) {
            return (delegatorFee, ownerFee, systemFee = validatorSnapshot.totalRewards);
        } else if (validatorSnapshot.totalDelegated == 0) {
            return (delegatorFee, ownerFee = validatorSnapshot.totalRewards, systemFee);
        }
        ownerFee = validatorSnapshot.getOwnerFee();
        delegatorFee = validatorSnapshot.totalRewards - ownerFee;
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = recipient.call{value : amount, gas : TRANSFER_GAS_LIMIT}("");
        require(success, "transfer failed");
    }

    receive() external virtual payable {
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IStakingConfig.sol";

contract StakingConfig is Initializable, IStakingConfig {

    event ActiveValidatorsLengthChanged(uint32 prevValue, uint32 newValue);
    event EpochBlockIntervalChanged(uint32 prevValue, uint32 newValue);
    event MisdemeanorThresholdChanged(uint32 prevValue, uint32 newValue);
    event FelonyThresholdChanged(uint32 prevValue, uint32 newValue);
    event ValidatorJailEpochLengthChanged(uint32 prevValue, uint32 newValue);
    event UndelegatePeriodChanged(uint32 prevValue, uint32 newValue);
    event MinValidatorStakeAmountChanged(uint256 prevValue, uint256 newValue);
    event MinStakingAmountChanged(uint256 prevValue, uint256 newValue);
    event GovernanceAddressChanged(address prevValue, address newValue);
    event TreasuryAddressChanged(address prevValue, address newValue);
    event LockPeriodChanged(uint64 prevValue, uint64 newValue);

    struct Slot0 {
        uint32 activeValidatorsLength;
        uint32 epochBlockInterval;
        uint32 misdemeanorThreshold;
        uint32 felonyThreshold;
        uint32 validatorJailEpochLength;
        uint32 undelegatePeriod;
        uint256 minValidatorStakeAmount;
        uint256 minStakingAmount;
        address governanceAddress;
        address treasuryAddress;
        uint64 lockPeriod;
    }

    Slot0 private _slot0;

    function initialize(
        uint32 activeValidatorsLength,
        uint32 epochBlockInterval,
        uint32 misdemeanorThreshold,
        uint32 felonyThreshold,
        uint32 validatorJailEpochLength,
        uint32 undelegatePeriod,
        uint256 minValidatorStakeAmount,
        uint256 minStakingAmount,
        address governanceAddress,
        address treasuryAddress,
        uint64 lockPeriod
    ) external initializer {
        _slot0.activeValidatorsLength = activeValidatorsLength;
        emit ActiveValidatorsLengthChanged(0, activeValidatorsLength);
        _slot0.epochBlockInterval = epochBlockInterval;
        emit EpochBlockIntervalChanged(0, epochBlockInterval);
        _slot0.misdemeanorThreshold = misdemeanorThreshold;
        emit MisdemeanorThresholdChanged(0, misdemeanorThreshold);
        _slot0.felonyThreshold = felonyThreshold;
        emit FelonyThresholdChanged(0, felonyThreshold);
        _slot0.validatorJailEpochLength = validatorJailEpochLength;
        emit ValidatorJailEpochLengthChanged(0, validatorJailEpochLength);
        _slot0.undelegatePeriod = undelegatePeriod;
        emit UndelegatePeriodChanged(0, undelegatePeriod);
        _slot0.minValidatorStakeAmount = minValidatorStakeAmount;
        emit MinValidatorStakeAmountChanged(0, minValidatorStakeAmount);
        _slot0.minStakingAmount = minStakingAmount;
        emit MinStakingAmountChanged(0, minStakingAmount);
        _slot0.governanceAddress = governanceAddress;
        emit GovernanceAddressChanged(address(0x00), governanceAddress);
        _slot0.treasuryAddress = treasuryAddress;
        emit TreasuryAddressChanged(address(0x00), treasuryAddress);
        _slot0.lockPeriod = lockPeriod;
        emit LockPeriodChanged(0, lockPeriod);
    }

    modifier onlyFromGovernance() virtual {
        require(msg.sender == _slot0.governanceAddress, "Staking: only governance");
        _;
    }

    function getSlot0() external view returns (Slot0 memory) {
        return _slot0;
    }

    function getActiveValidatorsLength() external view override returns (uint32) {
        return _slot0.activeValidatorsLength;
    }

    function setActiveValidatorsLength(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _slot0.activeValidatorsLength;
        _slot0.activeValidatorsLength = newValue;
        emit ActiveValidatorsLengthChanged(prevValue, newValue);
    }

    function getEpochBlockInterval() external view override returns (uint32) {
        return _slot0.epochBlockInterval;
    }

    function setEpochBlockInterval(uint32 newValue) external override onlyFromGovernance {
        require(newValue > 0, "StakingConfig: too low");
        uint32 prevValue = _slot0.epochBlockInterval;
        _slot0.epochBlockInterval = newValue;
        emit EpochBlockIntervalChanged(prevValue, newValue);
    }

    function getMisdemeanorThreshold() external view override returns (uint32) {
        return _slot0.misdemeanorThreshold;
    }

    function setMisdemeanorThreshold(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _slot0.misdemeanorThreshold;
        _slot0.misdemeanorThreshold = newValue;
        emit MisdemeanorThresholdChanged(prevValue, newValue);
    }

    function getFelonyThreshold() external view override returns (uint32) {
        return _slot0.felonyThreshold;
    }

    function setFelonyThreshold(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _slot0.felonyThreshold;
        _slot0.felonyThreshold = newValue;
        emit FelonyThresholdChanged(prevValue, newValue);
    }

    function getValidatorJailEpochLength() external view override returns (uint32) {
        return _slot0.validatorJailEpochLength;
    }

    function setValidatorJailEpochLength(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _slot0.validatorJailEpochLength;
        _slot0.validatorJailEpochLength = newValue;
        emit ValidatorJailEpochLengthChanged(prevValue, newValue);
    }

    function getUndelegatePeriod() external view override returns (uint32) {
        return _slot0.undelegatePeriod;
    }

    function setUndelegatePeriod(uint32 newValue) external override onlyFromGovernance {
        uint32 prevValue = _slot0.undelegatePeriod;
        _slot0.undelegatePeriod = newValue;
        emit UndelegatePeriodChanged(prevValue, newValue);
    }

    function getMinValidatorStakeAmount() external view override returns (uint256) {
        return _slot0.minValidatorStakeAmount;
    }

    function setMinValidatorStakeAmount(uint256 newValue) external override onlyFromGovernance {
        uint256 prevValue = _slot0.minValidatorStakeAmount;
        _slot0.minValidatorStakeAmount = newValue;
        emit MinValidatorStakeAmountChanged(prevValue, newValue);
    }

    function getMinStakingAmount() external view override returns (uint256) {
        return _slot0.minStakingAmount;
    }

    function setMinStakingAmount(uint256 newValue) external override onlyFromGovernance {
        uint256 prevValue = _slot0.minStakingAmount;
        _slot0.minStakingAmount = newValue;
        emit MinStakingAmountChanged(prevValue, newValue);
    }

    function getGovernanceAddress() external view override returns (address) {
        return _slot0.governanceAddress;
    }

    function setGovernanceAddress(address newValue) external override onlyFromGovernance {
        require(newValue != address(0), "StakingConfig: zero address");
        address prevValue = _slot0.governanceAddress;
        _slot0.governanceAddress = newValue;
        emit GovernanceAddressChanged(prevValue, newValue);
    }

    function getTreasuryAddress() external view override returns (address) {
        return _slot0.treasuryAddress;
    }

    function setTreasuryAddress(address newValue) external override onlyFromGovernance {
        require(newValue != address(0), "StakingConfig: zero address");
        address prevValue = _slot0.treasuryAddress;
        _slot0.treasuryAddress = newValue;
        emit TreasuryAddressChanged(prevValue, newValue);
    }

    function getLockPeriod() external view override returns (uint64) {
        return _slot0.lockPeriod;
    }

    function setLockPeriod(uint64 newValue) external override onlyFromGovernance {
        uint64 prevValue = _slot0.lockPeriod;
        _slot0.lockPeriod = newValue;
        emit LockPeriodChanged(prevValue, newValue);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../interfaces/IStaking.sol";
import "../libs/ValidatorUtil.sol";
import "../libs/SnapshotUtil.sol";
import "./BaseStaking.sol";
import "../interfaces/IValidatorStorage.sol";

abstract contract ValidatorRegistry is BaseStaking {

    using SnapshotUtil for ValidatorSnapshot;

    event ValidatorStorageChanged(address prevValue, address newValue);

    IValidatorStorage internal _validatorStorage;

    // reserve some gap for the future upgrades
    uint256[25 - 1] private __reserved;


    function getValidatorStorage() external view returns (IValidatorStorage) {
        return _validatorStorage;
    }

    function getTotalDelegated(address validatorAddress) public view returns (uint256) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        return uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
    }

    /*
     * used by frontend
     */
    function getValidatorStatus(address validatorAddress) public view override returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        ownerAddress = validator.ownerAddress;
        status = uint8(validator.status);
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
        changedAt = validator.changedAt;
        totalRewards = snapshot.totalRewards;
    }

    /*
     * used by frontend
     */
    function getValidatorStatusAtEpoch(address validatorAddress, uint64 epoch) public view override returns (
        address ownerAddress,
        uint8 status,
        uint256 totalDelegated,
        uint32 slashesCount,
        uint64 changedAt,
        uint64 jailedBefore,
        uint64 claimedAt,
        uint16 commissionRate,
        uint96 totalRewards
    ) {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        ValidatorSnapshot memory snapshot = _touchValidatorSnapshotImmutable(validator, epoch);
        ownerAddress = validator.ownerAddress;
        status = uint8(validator.status);
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION;
        changedAt = validator.changedAt;
        totalRewards = snapshot.totalRewards;
        return (ownerAddress, status, totalDelegated,0,changedAt, 0, 0, 0, totalRewards);
    }

    function _touchValidatorSnapshot(Validator memory validator, uint64 epoch) internal returns (ValidatorSnapshot storage) {
        ValidatorSnapshot storage snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // we must save last affected epoch for this validator to be able to restore total delegated
        // amount in the future (check condition upper)
        if (epoch > validator.changedAt) {
            _validatorStorage.change(validator.validatorAddress, epoch);
        }
        return snapshot;
    }

    function _touchValidatorSnapshotImmutable(Validator memory validator, uint64 epoch) internal view returns (ValidatorSnapshot memory) {
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][epoch];
        // if snapshot is already initialized then just return it
        if (snapshot.totalDelegated > 0) {
            return snapshot;
        }
        // find previous snapshot to copy parameters from it
        ValidatorSnapshot memory lastModifiedSnapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        // last modified snapshot might store zero value, for first delegation it might happen and its not critical
        snapshot.totalDelegated = lastModifiedSnapshot.totalDelegated;
        snapshot.commissionRate = lastModifiedSnapshot.commissionRate;
        // return existing or new snapshot
        return snapshot;
    }

    function addValidator(address account) external onlyFromGovernance virtual override {
        _addValidator(account, account, ValidatorStatus.Active, 0, nextEpoch());
    }

    function _delegateUnsafe(address validator, address delegator, uint256 amount, uint64 sinceEpoch) internal virtual;

    function _addValidator(address validatorAddress, address validatorOwner, ValidatorStatus status, uint16 commissionRate, uint64 sinceEpoch) internal {
        // validator commission rate
        require(commissionRate >= COMMISSION_RATE_MIN_VALUE && commissionRate <= COMMISSION_RATE_MAX_VALUE, "bad commission");
        // init validator default params
        _validatorStorage.create(validatorAddress, validatorOwner, status, sinceEpoch);
        // push initial validator snapshot at zero epoch with default params
        _validatorSnapshots[validatorAddress][sinceEpoch].create(0, commissionRate);
        // delegate initial stake to validator owner
        // emit event
        emit ValidatorAdded(validatorAddress, validatorOwner, uint8(status), commissionRate);
    }

    function activateValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorStorage.activate(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function disableValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator memory validator = _validatorStorage.disable(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function changeValidatorOwner(address validatorAddress, address newOwner) external override {
        require(_validatorStorage.isOwner(validatorAddress, msg.sender), "only owner");
        Validator memory validator = _validatorStorage.changeOwner(validatorAddress, newOwner);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validator.validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function _depositFee(address validatorAddress, uint256 amount) internal {
        // make sure validator is active
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 epoch = currentEpoch();
        // increase total pending rewards for validator for current epoch
        ValidatorSnapshot storage currentSnapshot = _touchValidatorSnapshot(validator, epoch);
        currentSnapshot.totalRewards += uint96(amount);
        // validator data might be changed during _touchValidatorSnapshot()
        _addReward(validatorAddress, uint96(amount));
        // emit event
        emit ValidatorDeposited(validatorAddress, amount, epoch);
    }

    function _addReward(address validatorAddress, uint96 amount) internal virtual;

    function _addDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        // make sure validator exists at least
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        require(validator.status != ValidatorStatus.NotFound, "not found");
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + increase total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        ValidatorSnapshot storage validatorSnapshot = _touchValidatorSnapshot(validator, epoch);
        validatorSnapshot.totalDelegated += amount;
    }

    function _removeDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        Validator memory validator = _validatorStorage.getValidator(validatorAddress);
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + decrease total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        _touchValidatorSnapshot(validator, epoch).safeDecreaseDelegated(amount);
    }

    function setValidatorStorage(address validatorStorage) external onlyFromGovernance {
        emit ValidatorStorageChanged(address(_validatorStorage), validatorStorage);
        _validatorStorage = IValidatorStorage(validatorStorage);
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "../../interfaces/ITokenStaking.sol";

import "../Staking.sol";

contract TokenStaking is Staking, ITokenStaking {

    // address of the erc20 token
    IERC20 internal _erc20Token;
    // reserve some gap for the future upgrades
    uint256[100 - 2] private __reserved;

    function __TokenStaking_init(IStakingConfig chainConfig, IERC20 erc20Token) internal onlyInitializing {
        __BaseStaking_init(chainConfig);
        _erc20Token = erc20Token;
    }

    function getErc20Token() external view override returns (IERC20) {
        return _erc20Token;
    }

    function delegate(address validatorAddress, uint256 amount) payable external override {
        require(msg.value == 0, "ERC20 expected");
        require(_erc20Token.transferFrom(msg.sender, address(this), amount), "failed to transfer");
        _delegate(validatorAddress, msg.sender, amount);
    }

    function distributeRewards(address validatorAddress, uint256 amount) external override {
        require(_erc20Token.transferFrom(msg.sender, address(this), amount), "failed to transfer");
        _depositFee(validatorAddress, amount);
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal override {
        require(_erc20Token.transfer(recipient, amount), "failed to safe transfer");
    }

    receive() external override payable {
        revert();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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