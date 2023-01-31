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

    function getValidators() external view returns (address[] memory);

    function isValidatorActive(address validator) external view returns (bool);

    function isValidator(address validator) external view returns (bool);

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

    function getValidatorByOwner(address owner) external view returns (address);

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

//    function getPendingDelegatorFee(address validator, address delegator) external view returns (uint256);

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

    function add(
        ValidatorDelegation storage self,
        uint112 amount,
        uint64 epoch
    ) internal {
        // if last pending delegate has the same next epoch then its safe to just increase total
        // staked amount because it can't affect current validator set, but otherwise we must create
        // new record in delegation queue with the last epoch (delegations are ordered by epoch)
        if (self.delegateQueue.length > 0) {
            DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
            // if we already have pending snapshot for the next epoch then just increase new amount,
            // otherwise create next pending snapshot. (tbh it can't be greater, but what we can do here instead?)
            if (recentDelegateOp.epoch >= epoch) {
                recentDelegateOp.amount += amount;
            } else {
                self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : recentDelegateOp.amount + amount}));
            }
        } else {
            // there is no any delegations at al, lets create the first one
            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch : epoch, amount : amount}));
        }
    }

    function addInitial(
        ValidatorDelegation storage self,
        uint112 amount,
        uint64 epoch
    ) internal {
        require(self.delegateQueue.length == 0, "Delegation: already delegated");
        self.delegateQueue.push(DelegationOpDelegate({amount : amount, epoch: epoch, claimEpoch : epoch}));
    }

    // @dev before call check that queue is not empty
    function shrinkDelegations(
        ValidatorDelegation storage self,
        uint112 amount,
        uint64 epoch
    ) internal {
        // pull last item
        DelegationOpDelegate storage recentDelegateOp = self.delegateQueue[self.delegateQueue.length - 1];
        // calc next delegated amount
        uint112 nextDelegatedAmount = recentDelegateOp.amount - amount;
        if (nextDelegatedAmount == 0) {
            delete self.delegateQueue[self.delegateQueue.length - 1];
            self.delegateGap++;
        } else if (recentDelegateOp.epoch >= epoch) {
            // decrease total delegated amount for the next epoch
            recentDelegateOp.amount = nextDelegatedAmount;
        } else {
            // there is no pending delegations, so lets create the new one with the new amount
            self.delegateQueue.push(DelegationOpDelegate({epoch : epoch, claimEpoch: epoch, amount : nextDelegatedAmount}));
        }
        // stash withdrawn amount
        if (epoch > self.withdrawnEpoch) {
            self.withdrawnEpoch = epoch;
            self.withdrawnAmount = amount;
        } else if (epoch == self.withdrawnEpoch) {
            self.withdrawnAmount += amount;
        }
    }

    function getWithdrawn(
        ValidatorDelegation memory self,
        uint64 epoch
    ) internal pure returns (uint112) {
        return epoch >= self.withdrawnEpoch ? 0 : self.withdrawnAmount;
    }

    function calcWithdrawalAmount(ValidatorDelegation memory self, uint64 beforeEpochExclude, bool checkEpoch) internal pure returns (uint256 amount) {
        while (self.undelegateGap < self.undelegateQueue.length) {
            DelegationOpUndelegate memory undelegateOp = self.undelegateQueue[self.undelegateGap];
            if (checkEpoch && undelegateOp.epoch > beforeEpochExclude) {
                break;
            }
            amount += uint256(undelegateOp.amount);
            ++self.undelegateGap;
        }
    }

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

    function isActive(Validator memory self) internal pure returns (bool) {
        return self.status == ValidatorStatus.Active;
    }

    function isOwner(
        Validator memory self,
        address addr
    ) internal pure returns (bool) {
        return self.ownerAddress == addr;
    }

    function create(
        Validator storage self,
        address validatorAddress,
        address validatorOwner,
        ValidatorStatus status,
        uint64 epoch
    ) internal {
        require(self.status == ValidatorStatus.NotFound, "Validator: already exist");
        self.validatorAddress = validatorAddress;
        self.ownerAddress = validatorOwner;
        self.status = status;
        self.changedAt = epoch;
    }

    function activate(
        Validator storage self
    ) internal returns (Validator memory vldtr) {
        require(self.status == ValidatorStatus.Pending, "Validator: bad status");
        self.status = ValidatorStatus.Active;
        return self;
    }

    function disable(
        Validator storage self
    ) internal returns (Validator memory vldtr) {
        require(self.status == ValidatorStatus.Active || self.status == ValidatorStatus.Jail, "Validator: bad status");
        self.status = ValidatorStatus.Pending;
        return self;
    }

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

    function __BaseStaking_init(IStakingConfig stakingConfig) internal {
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

    /*
     * @dev sharesSupply / (totalDelegated * 1e8 + totalRewards) is current ratio
     */
    struct ValidatorPool {
        address validatorAddress; // address of validator
        uint112 totalDelegated; // compact total delegated amount
        uint256 sharesSupply; // total shares supply
        uint256 totalRewards; // total rewards available for delegators
        uint112 unlockedDelegation; // amount unlocked to claim
    }

    /*
     * @dev delegator data
     */
    struct DelegationHistory {
        Delegation[] delegations; // existing delegations
        uint64 delegationGap;
        /**
         * last epoch when made unlock
         * needed to give ability to undelegate only after UndelegatePeriod
         */
        uint64 lastUnlockEpoch;
        uint112 unlockedAmount; // amount not participating in staking
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

    // reserve some gap for the future upgrades
    uint256[50 - 4] private __reserved;

    /*
     * @return address of staking config contract
     */
    function getStakingConfig() external view override returns (IStakingConfig) {
        return _stakingConfig;
    }

    //    function getShares(address validator, address delegator) external view returns (uint256) {
    //        return _stakerShares[validator][delegator];
    //    }

    /*
     * used by frontend
     * @return amount - undelegated amount + available rewards
     */
    function getDelegatorFee(address validator, address delegator) external override view returns (uint256 amount) {
        amount += uint256(_delegationHistory[validator][delegator].unlockedAmount) * BALANCE_COMPACT_PRECISION;
        amount += _calcRewards(validator, delegator);
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

        for (uint i = history.delegationGap; i < delegations.length; i++) {
            // diff between current shares value and delegated amount is profit
            rewards += _fromShares(validatorPool, delegations[i].shares) - uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
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

    function _calcUnlocked(address validator, address delegator) public view returns (uint256 unlockedAmount) {
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
        uint64 epoch = nextEpoch();
        // collect rewards from records
        uint256 claimAmount = _claimRewards(validator, msg.sender);
        // collect unlocked
        claimAmount += uint256(_claimUnlocked(validator, msg.sender, epoch)) * BALANCE_COMPACT_PRECISION;

        _safeTransferWithGasLimit(payable(msg.sender), claimAmount);
        emit Claimed(validator, msg.sender, claimAmount, epoch);
    }

    /*
     * used by frontend
     * @notice claim only available rewards
     */
    function claimStakingRewards(address validator) external override {
        uint64 epoch = nextEpoch();
        uint256 amount = _claimRewards(validator, msg.sender);
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev extract extra balance from shares and deduct it
     * @return rewards amount to withdraw
     */
    function _claimRewards(address validator, address delegator) internal returns (uint256 availableRewards) {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] memory delegations = history.delegations;

        // get storage instance
        Delegation[] storage storageDelegations = _delegationHistory[validator][delegator].delegations;

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 rewardInShares;
        uint256 usedShares;
        uint256 recordReward;
        // look at all records
        for (uint i = history.delegationGap; i < delegations.length; i++) {
            // calculate diff between shares and delegated amount
            // calculation in shares is more accurate
            recordReward = _fromShares(validatorPool, delegations[i].shares) - uint256(delegations[i].amount) * BALANCE_COMPACT_PRECISION;
            // add reward to collected
            availableRewards += recordReward;
            // subtract reward in shares
            //            rewardInShares = recordReward;
            rewardInShares = _toShares(validatorPool, recordReward);
            delegations[i].shares -= rewardInShares;
            usedShares += rewardInShares;
            // now fromShares(delegations[i].shares) should be equal in value to delegations[i].amount

            // write to storage
            storageDelegations[i] = delegations[i];
        }

        require(validatorPool.sharesSupply >= usedShares, "used more then exist");
        require(validatorPool.totalRewards >= availableRewards, "not enough rewards");

        // subtract collected shares from supply
        validatorPool.sharesSupply -= usedShares;
        // subtract collected rewards from pool
        validatorPool.totalRewards -= availableRewards;
        // save changes
        _validatorPools[validator] = validatorPool;
    }

    /*
     * used by frontend
     * @notice claim only unlocked delegates
     */
    function claimPendingUndelegates(address validator) external override {
        uint64 epoch = nextEpoch();
        uint256 amount = uint256(_claimUnlocked(validator, msg.sender, epoch)) * BALANCE_COMPACT_PRECISION;
        // transfer unlocked
        _safeTransferWithGasLimit(payable(msg.sender), amount);
        // emit event
        emit Claimed(validator, msg.sender, amount, epoch);
    }

    /*
     * @dev will not revert tx because used in pair with rewards methods
     * @return unlocked amount to send
     */
    function _claimUnlocked(address validator, address delegator, uint64 epoch) internal returns (uint112 unlockedAmount) {
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
        require(validatorPool.unlockedDelegation > 0, "nothing to undelegate");

        // update validator pool
        validatorPool.unlockedDelegation -= unlockedAmount;
        _validatorPools[validator] = validatorPool;

        // reset state
        _delegationHistory[validator][delegator].unlockedAmount = 0;
//        _delegationHistory[validator][delegator].unlockedShares = 0;
        // TODO: do we need save shares if they not grow?
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

    /*
     * @notice convert amount to shares using validator's pool
     */
    function toShares(address validator, uint256 amount) public view returns (uint256) {
        return _toShares(_getValidatorPool(validator), amount);
    }

    function _toShares(ValidatorPool memory validator, uint256 amount) internal pure returns (uint256) {
        uint256 total = uint256(validator.totalDelegated) * BALANCE_COMPACT_PRECISION + validator.totalRewards;
        if (total == 0) {
            return amount;
        } else {
            return MathUtils.multiplyAndDivideCeil(
                amount,
                validator.sharesSupply,
                total
            );
        }
    }

    /*
     * @notice convert shares to amount using validator's pool
     */
    function fromShares(address validator, uint256 amount) public view returns (uint256) {
        return _fromShares(_getValidatorPool(validator), amount);
    }

    function _fromShares(ValidatorPool memory validator, uint256 shares) internal pure returns (uint256) {
        uint256 total = uint256(validator.totalDelegated) * BALANCE_COMPACT_PRECISION + validator.totalRewards;
        if (total == 0) {
            return shares;
        } else {
            return MathUtils.multiplyAndDivideFloor(
                shares,
                total,
                validator.sharesSupply
            );
        }
    }

    /*
     * used by frontend
     * @notice undelegate an amount of unlocked delegations
     */
    function undelegate(address validator, uint256 amount) external override {
        _undelegate(validator, msg.sender, amount);
    }

    /*
     * @dev before new undelegate already unlocked should be claimed
     * @dev if not, existing unlocked amount will be available only in nextEpoch + getUndelegatePeriod
     * @dev rewards should be claimed during undelegate, because stashed records will not produce new reward
     */
    function _undelegate(address validator, address delegator, uint256 amount) internal {
        // check minimum delegate amount
        require(amount >= _stakingConfig.getMinStakingAmount() && amount != 0, "too low");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");

        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        require(validatorPool.totalDelegated > 0, "insufficient balance");

        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        require(compactAmount <= _stakerAmounts[validator][delegator], "insufficient balance");

        // calculate shares and make sure user have enough balance
        uint256 shares = _toShares(validatorPool, amount);
        // check that users has enough shares
        require(shares <= _stakerShares[validator][delegator], "not enough shares");

        uint64 beforeEpoch = nextEpoch();

        (uint256 rewards, uint256 spentShares) = _stashUnlocked(validatorPool, delegator, compactAmount, beforeEpoch);
        _removeDelegate(validator, compactAmount, beforeEpoch);

        // update delegator state
        _stakerAmounts[validator][delegator] -= compactAmount;
        _stakerShares[validator][delegator] -= spentShares;
        // add stashed amount
        validatorPool.unlockedDelegation += compactAmount;
        // deduct undelegated amount
        validatorPool.totalDelegated -= compactAmount;
        // deduct undelegated shares
        validatorPool.sharesSupply -= spentShares;
        // deduct rewards
        validatorPool.totalRewards -= rewards;
        // save the state
        _validatorPools[validator] = validatorPool;
        // send rewards from stashed
        _safeTransferWithGasLimit(payable(delegator), rewards);
        // emit event
        emit Claimed(validator, delegator, rewards, beforeEpoch);
        emit Undelegated(validator, delegator, amount, beforeEpoch);
    }

    /*
     * @dev removes amount from unlocked records
     * @dev fulfilled records deleted
     * @return usedShares - spent shares for reward
     * @return rewards - amount of claimed rewards
     * @return unlockedShares - shares unlocked in queue
     */
    function _stashUnlocked(ValidatorPool memory validatorPool, address delegator, uint112 expectedAmount, uint64 beforeEpoch) internal returns (uint256 rewards, uint256 spentShares) {
        DelegationHistory memory history = _delegationHistory[validatorPool.validatorAddress][delegator];
        Delegation[] memory delegations = history.delegations;

        // work with memory because we can't copy array
        Delegation[] storage storageDelegations = _delegationHistory[validatorPool.validatorAddress][delegator].delegations;

        uint256 length = delegations.length;

        uint64 lockPeriod = _stakingConfig.getLockPeriod();

        uint112 unlockedAmount;

        for (; history.delegationGap < length && delegations[history.delegationGap].epoch + lockPeriod < beforeEpoch && expectedAmount > 0; history.delegationGap++) {
            // if record fulfill unlockedAm
            if (delegations[history.delegationGap].amount <= expectedAmount) {
                // record can be deleted
                spentShares += delegations[history.delegationGap].shares;
                unlockedAmount += delegations[history.delegationGap].amount;
                // reduce expected for further records
                expectedAmount = expectedAmount - delegations[history.delegationGap].amount;

                // delete from storage
                delete storageDelegations[history.delegationGap];
            } else {
                // deduct undelegated amount
                uint256 shares = _toShares(validatorPool, uint256(expectedAmount) * BALANCE_COMPACT_PRECISION);
                delegations[history.delegationGap].amount -= expectedAmount;
                delegations[history.delegationGap].shares -= shares;
                spentShares += shares;
                unlockedAmount += expectedAmount;

                // expected amount is filled
                expectedAmount = 0;

                // save changes to storage
                storageDelegations[history.delegationGap] = delegations[history.delegationGap];
                break;
            }
        }

        require(expectedAmount == 0, "still locked");
        // deduct unlocked amount in shares from spentShare to get reward
        rewards = _fromShares(validatorPool, spentShares - _toShares(validatorPool, uint256(unlockedAmount) * BALANCE_COMPACT_PRECISION));

        // save new state
        _delegationHistory[validatorPool.validatorAddress][delegator].delegationGap = history.delegationGap;
        //        _delegationHistory[validatorPool.validatorAddress][delegator].unlockedShares += unlockedShares;
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
        uint256 rewards = _claimRewards(validator, msg.sender);
        uint256 dust;
        (rewards, dust) = calcAvailableForDelegateAmount(rewards);
        _delegate(validator, msg.sender, rewards);
        _safeTransferWithGasLimit(payable(msg.sender), dust);
        emit Redelegated(validator, msg.sender, rewards, dust, 0);
        // TODO: add epoch
    }

    function _delegate(address validator, address delegator, uint256 amount) internal {
        require(amount != 0, "too low");
        require(amount >= _stakingConfig.getMinStakingAmount(), "less than min");
        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
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
        uint112 compactAmount = uint112(amount / BALANCE_COMPACT_PRECISION);
        // add delegated amount to validator snapshot, revert if validator not exist
        _addDelegate(validator, compactAmount, sinceEpoch);

        ValidatorPool memory validatorPool = _getValidatorPool(validator);

        uint256 shares = _toShares(validatorPool, amount);
        // increase total accumulated shares for the staker
        _stakerShares[validator][delegator] += shares;
        // increase total accumulated amount for the staker
        _stakerAmounts[validator][delegator] += compactAmount;
        // increase staking params for ratio calculation
        validatorPool.totalDelegated += compactAmount;
        validatorPool.sharesSupply += shares;
        // save validator pool
        _validatorPools[validator] = validatorPool;

        _adjustDelegation(validator, delegator, sinceEpoch, shares, compactAmount);
    }

    function _adjustDelegation(address validator, address delegator, uint64 epoch, uint256 shares, uint112 amount) internal {
        DelegationHistory memory history = _delegationHistory[validator][delegator];
        Delegation[] storage delegations = _delegationHistory[validator][delegator].delegations;
        uint256 length = delegations.length;

        if (length - history.delegationGap > 0 && delegations[length - 1].epoch >= epoch) {
            delegations[length - 1].amount = delegations[length - 1].amount + amount;
            delegations[length - 1].shares += shares;
        } else {
            delegations.push(Delegation(epoch, amount, shares));
        }
    }

    // not used yet
    //    function calcLocked(address validator, address delegator) public view returns (uint256 lockedAmount) {
    //        DelegationHistory memory history = _delegationHistory[validator][delegator];
    //        Delegation[] memory delegations = history.delegations;
    //
    //        uint64 lockPeriod = _stakingConfig.getLockPeriod();
    //        uint64 epoch = currentEpoch();
    //
    //        for (uint i = delegations.length - 1; i > history.delegationGap && delegations[i].epoch + lockPeriod > epoch; i--) {
    //            lockedAmount += delegations[i].amount;
    //        }
    //    }

    function _addReward(address validator, uint256 amount) internal override {
        ValidatorPool memory validatorPool = _getValidatorPool(validator);
        validatorPool.totalRewards += amount;
        _validatorPools[validator] = validatorPool;
    }

    function _safeTransferTo(address recipient, uint256 amount) internal virtual {
        require(address(this).balance >= amount, "not enough balance");
        payable(recipient).transfer(amount);
    }

    function _unsafeTransfer(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = payable(address(recipient)).call{value : amount}("");
        require(success);
    }

    function _safeTransferWithGasLimit(address payable recipient, uint256 amount) internal virtual {
        (bool success,) = recipient.call{value : amount, gas : TRANSFER_GAS_LIMIT}("");
        require(success, "transfer failed");
    }

    receive() external payable {
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
        address prevValue = _slot0.governanceAddress;
        _slot0.governanceAddress = newValue;
        emit GovernanceAddressChanged(prevValue, newValue);
    }

    function getTreasuryAddress() external view override returns (address) {
        return _slot0.treasuryAddress;
    }

    function setTreasuryAddress(address newValue) external override onlyFromGovernance {
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

abstract contract ValidatorRegistry is BaseStaking {

    using ValidatorUtil for Validator;
    using SnapshotUtil for ValidatorSnapshot;

//    function __ValidatorRegistry_init(IStakingConfig stakingConfig) internal {
//        _stakingConfig = stakingConfig;
//    }

    function getStakingConfig() external view virtual override returns (IStakingConfig) {
        return _stakingConfig;
    }

    /*
     * used by frontend
     */
    function getValidatorStatus(address validatorAddress) external view override returns (
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
        Validator memory validator = _validatorsMap[validatorAddress];
        ValidatorSnapshot memory snapshot = _validatorSnapshots[validator.validatorAddress][validator.changedAt];
        return (
        ownerAddress = validator.ownerAddress,
        status = uint8(validator.status),
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION,
        slashesCount = snapshot.slashesCount,
        changedAt = validator.changedAt,
        jailedBefore = validator.jailedBefore,
        claimedAt = validator.claimedAt,
        commissionRate = snapshot.commissionRate,
        totalRewards = snapshot.totalRewards
        );
    }

    /*
     * used by frontend
     */
    function getValidatorStatusAtEpoch(address validatorAddress, uint64 epoch) external view override returns (
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
        Validator memory validator = _validatorsMap[validatorAddress];
        ValidatorSnapshot memory snapshot = _touchValidatorSnapshotImmutable(validator, epoch);
        return (
        ownerAddress = validator.ownerAddress,
        status = uint8(validator.status),
        totalDelegated = uint256(snapshot.totalDelegated) * BALANCE_COMPACT_PRECISION,
        slashesCount = snapshot.slashesCount,
        changedAt = validator.changedAt,
        jailedBefore = validator.jailedBefore,
        claimedAt = validator.claimedAt,
        commissionRate = snapshot.commissionRate,
        totalRewards = snapshot.totalRewards
        );
    }

    function getValidatorByOwner(address owner) external view override returns (address) {
        return _validatorOwners[owner];
    }

//    function releaseValidatorFromJail(address validatorAddress) external override {
//        Validator storage validator = _validatorsMap[validatorAddress];
//        validator.unJail(currentEpoch());
//        _releaseValidatorFromJail(validator);
//    }
//
//    function forceUnJailValidator(address validatorAddress) external onlyFromGovernance {
//        Validator storage validator = _validatorsMap[validatorAddress];
//        validator.forceUnJail();
//        _releaseValidatorFromJail(validator);
//    }

//    function _releaseValidatorFromJail(Validator storage validator) internal {
//        address validatorAddress = validator.validatorAddress;
//        _activeValidatorsList.push(validatorAddress);
//        // emit event
//        emit ValidatorReleased(validatorAddress, currentEpoch());
//    }

    function _touchValidatorSnapshot(Validator storage validator, uint64 epoch) internal returns (ValidatorSnapshot storage) {
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
            validator.changedAt = epoch;
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

//    function registerValidator(address validatorAddress, uint16 commissionRate, uint256) payable external virtual override {
//        uint256 initialStake = msg.value;
//        // // initial stake amount should be greater than minimum validator staking amount
//        require(initialStake >= _stakingConfig.getMinValidatorStakeAmount(), "too low");
//        require(initialStake % BALANCE_COMPACT_PRECISION == 0, "no remainder");
//        // add new validator as pending
//        _addValidator(validatorAddress, msg.sender, ValidatorStatus.Pending, commissionRate, initialStake, nextEpoch());
//    }

    function addValidator(address account) external onlyFromGovernance virtual override {
        _addValidator(account, account, ValidatorStatus.Active, 0, 0, nextEpoch());
    }

    function _delegateUnsafe(address validator, address delegator, uint256 amount, uint64 sinceEpoch) internal virtual;

    function _addValidator(address validatorAddress, address validatorOwner, ValidatorStatus status, uint16 commissionRate, uint256 initialStake, uint64 sinceEpoch) internal {
        // validator commission rate
        require(commissionRate >= COMMISSION_RATE_MIN_VALUE && commissionRate <= COMMISSION_RATE_MAX_VALUE, "bad commission");
        // init validator default params
        _validatorsMap[validatorAddress].create(validatorAddress, validatorOwner, status, sinceEpoch);
        // save validator owner
        require(_validatorOwners[validatorOwner] == address(0x00), "owner in use");
        _validatorOwners[validatorOwner] = validatorAddress;
        // add new validator to array
        if (status == ValidatorStatus.Active) {
            _activeValidatorsList.push(validatorAddress);
        }
        // push initial validator snapshot at zero epoch with default params
        _validatorSnapshots[validatorAddress][sinceEpoch].create(uint112(initialStake / BALANCE_COMPACT_PRECISION), commissionRate);
        // delegate initial stake to validator owner
        _delegateUnsafe(validatorAddress, validatorOwner, initialStake, sinceEpoch);
        emit Delegated(validatorAddress, validatorOwner, initialStake, sinceEpoch);
        // emit event
        emit ValidatorAdded(validatorAddress, validatorOwner, uint8(status), commissionRate);
    }

    function _removeValidatorFromActiveList(address validatorAddress) internal {
        // find index of validator in validator set
        int256 indexOf = - 1;
        for (uint256 i; i < _activeValidatorsList.length; i++) {
            if (_activeValidatorsList[i] != validatorAddress) continue;
            indexOf = int256(i);
            break;
        }
        // remove validator from array (since we remove only active it might not exist in the list)
        if (indexOf >= 0) {
            if (_activeValidatorsList.length > 1 && uint256(indexOf) != _activeValidatorsList.length - 1) {
                _activeValidatorsList[uint256(indexOf)] = _activeValidatorsList[_activeValidatorsList.length - 1];
            }
            _activeValidatorsList.pop();
        }
    }

    function activateValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator storage validator = _validatorsMap[validatorAddress];
        validator.activate();
        _activeValidatorsList.push(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function disableValidator(address validatorAddress) external onlyFromGovernance virtual override {
        Validator storage validator = _validatorsMap[validatorAddress];
        validator.disable();
        _removeValidatorFromActiveList(validatorAddress);
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

//    function changeValidatorCommissionRate(address validatorAddress, uint16 commissionRate) external override {
//        require(commissionRate >= COMMISSION_RATE_MIN_VALUE && commissionRate <= COMMISSION_RATE_MAX_VALUE, "bad commission");
//        Validator storage validator = _validatorsMap[validatorAddress];
//        require(validator.status != ValidatorStatus.NotFound, "not found");
//        require(validator.isOwner(msg.sender), "only owner");
//        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
//        snapshot.commissionRate = commissionRate;
//        emit ValidatorModified(validator.validatorAddress, validator.ownerAddress, uint8(validator.status), commissionRate);
//    }

    function changeValidatorOwner(address validatorAddress, address newOwner) external override {
        require(newOwner != address(0x0), "new owner cannot be zero address");
        Validator storage validator = _validatorsMap[validatorAddress];
        require(validator.ownerAddress == msg.sender, "only owner");
        require(_validatorOwners[newOwner] == address(0x00), "owner in use");
        delete _validatorOwners[validator.ownerAddress];
        validator.ownerAddress = newOwner;
        _validatorOwners[newOwner] = validatorAddress;
        ValidatorSnapshot storage snapshot = _touchValidatorSnapshot(validator, nextEpoch());
        emit ValidatorModified(validator.validatorAddress, validator.ownerAddress, uint8(validator.status), snapshot.commissionRate);
    }

    function isValidatorActive(address account) external view override returns (bool) {
        if (!_validatorsMap[account].isActive()) {
            return false;
        }
        address[] memory topValidators = getValidators();
        for (uint256 i; i < topValidators.length; i++) {
            if (topValidators[i] == account) return true;
        }
        return false;
    }

    function isValidator(address account) external view override returns (bool) {
        return _validatorsMap[account].status != ValidatorStatus.NotFound;
    }

    // used by frontend
    function getValidators() public view override returns (address[] memory) {
        uint256 n = _activeValidatorsList.length;
        address[] memory orderedValidators = new address[](n);
        for (uint256 i; i < n; i++) {
            orderedValidators[i] = _activeValidatorsList[i];
        }
        // we need to select k top validators out of n
        uint256 k = _stakingConfig.getActiveValidatorsLength();
        if (k > n) {
            k = n;
        }
        for (uint256 i = 0; i < k; i++) {
            uint256 nextValidator = i;
            Validator memory currentMax = _validatorsMap[orderedValidators[nextValidator]];
            ValidatorSnapshot memory maxSnapshot = _validatorSnapshots[currentMax.validatorAddress][currentMax.changedAt];
            for (uint256 j = i + 1; j < n; j++) {
                Validator memory current = _validatorsMap[orderedValidators[j]];
                ValidatorSnapshot memory currentSnapshot = _validatorSnapshots[current.validatorAddress][current.changedAt];
                if (maxSnapshot.totalDelegated < currentSnapshot.totalDelegated) {
                    nextValidator = j;
                    currentMax = current;
                    maxSnapshot = currentSnapshot;
                }
            }
            address backup = orderedValidators[i];
            orderedValidators[i] = orderedValidators[nextValidator];
            orderedValidators[nextValidator] = backup;
        }
        // this is to cut array to first k elements without copying
        assembly {
            mstore(orderedValidators, k)
        }
        return orderedValidators;
    }

    function _depositFee(address validatorAddress, uint256 amount) internal {
        // make sure validator is active
        Validator storage validator = _validatorsMap[validatorAddress];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        uint64 epoch = currentEpoch();
        // increase total pending rewards for validator for current epoch
        ValidatorSnapshot storage currentSnapshot = _touchValidatorSnapshot(validator, epoch);
        currentSnapshot.totalRewards += uint96(amount);
        // validator data might be changed during _touchValidatorSnapshot()
        _addReward(validatorAddress, amount);
        // emit event
        emit ValidatorDeposited(validatorAddress, amount, epoch);
    }

    function _addReward(address validatorAddress, uint256 amount) internal virtual;

    function _addDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        // make sure amount is greater than min staking amount
        // make sure validator exists at least
        Validator storage validator = _validatorsMap[validatorAddress];
        require(validator.status != ValidatorStatus.NotFound, "not found");
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + increase total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        ValidatorSnapshot storage validatorSnapshot = _touchValidatorSnapshot(validator, epoch);
        validatorSnapshot.totalDelegated += amount;
        _validatorsMap[validatorAddress] = validator;
    }

    function _removeDelegate(address validatorAddress, uint112 amount, uint64 epoch) internal {
        Validator storage validator = _validatorsMap[validatorAddress];
        // Lets upgrade next snapshot parameters:
        // + find snapshot for the next epoch after current block
        // + decrease total delegated amount in the next epoch for this validator
        // + re-save validator because last affected epoch might change
        _touchValidatorSnapshot(validator, epoch).safeDecreaseDelegated(amount);
    }

//    function _slashValidator(address validatorAddress) internal {
//        // make sure validator exists
//        Validator storage validator = _validatorsMap[validatorAddress];
//        uint64 epoch = currentEpoch();
//        // increase slashes for current epoch
//        uint32 slashesCount = _touchValidatorSnapshot(validator, epoch).slash();
//        _validatorsMap[validatorAddress] = validator;
//        // if validator has a lot of misses then put it in jail for 1 week (if epoch is 1 day)
//        if (slashesCount == _stakingConfig.getFelonyThreshold()) {
//            _validatorsMap[validatorAddress].jail(currentEpoch() + _stakingConfig.getValidatorJailEpochLength());
//            _removeValidatorFromActiveList(validatorAddress);
//            emit ValidatorJailed(validatorAddress, epoch);
//        }
//        // emit event
//        emit ValidatorSlashed(validatorAddress, slashesCount, epoch);
//    }
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

    function __TokenStaking_init(IStakingConfig chainConfig, IERC20 erc20Token) internal {
        _stakingConfig = chainConfig;
        _erc20Token = erc20Token;
    }

    function getErc20Token() external view override returns (IERC20) {
        return _erc20Token;
    }

//    function registerValidator(address validatorAddress, uint16 commissionRate, uint256 amount) external payable virtual override(ValidatorRegistry, IStaking) {
//        require(msg.value == 0, "TokenStaking: ERC20 expected");
//        // initial stake amount should be greater than minimum validator staking amount
//        require(amount >= _stakingConfig.getMinValidatorStakeAmount(), "too low");
//        require(amount % BALANCE_COMPACT_PRECISION == 0, "no remainder");
//        // transfer tokens
//        require(_erc20Token.transferFrom(msg.sender, address(this), amount), "TokenStaking: failed to transfer");
//        // add new validator as pending
//        _addValidator(validatorAddress, msg.sender, ValidatorStatus.Pending, commissionRate, amount, nextEpoch());
//    }

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

    function _unsafeTransfer(address payable recipient, uint256 amount) internal override {
        require(_erc20Token.transfer(recipient, amount), "failed to unsafe transfer");
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