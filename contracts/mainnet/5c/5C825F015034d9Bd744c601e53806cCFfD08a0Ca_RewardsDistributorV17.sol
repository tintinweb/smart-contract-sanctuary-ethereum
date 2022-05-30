// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import {TimeLockedToken} from './TimeLockedToken.sol';

import {OwnableUpgradeable} from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {SafeDecimalMath} from '../lib/SafeDecimalMath.sol';
import {PreciseUnitMath} from '../lib/PreciseUnitMath.sol';
import {Math} from '../lib/Math.sol';
import {Errors, _require} from '../lib/BabylonErrors.sol';

import {IBabController} from '../interfaces/IBabController.sol';
import {IGarden} from '../interfaces/IGarden.sol';
import {IStrategy} from '../interfaces/IStrategy.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {IPriceOracle} from '../interfaces/IPriceOracle.sol';
import {IProphets} from '../interfaces/IProphets.sol';
import {IHeart} from '../interfaces/IHeart.sol';

/**
 * @title Rewards Distributor implementing the BABL Mining Program and other Rewards to Strategists and Stewards
 * @author Babylon Finance
 * Rewards Distributor contract is a smart contract used to calculate and distribute all the BABL rewards
 * of the BABL Mining Program along the time reserved for executed strategies. It implements a supply curve
 * to distribute 500K BABL along the time.
 * The supply curve is designed to optimize the long-term sustainability of the protocol.
 * The rewards are front-loaded but they last for more than 10 years, slowly decreasing quarter by quarter.
 * For that, it houses the state of the protocol power along the time as each strategy power is compared
 * to the whole protocol usage as well as profits of each strategy counts.
 * Rewards Distributor also is responsible for the calculation and delivery of other rewards as bonuses
 * to specific profiles, which are actively contributing to the protocol growth and their communities
 * (Garden creators, Strategists and Stewards).
 */
contract RewardsDistributor is OwnableUpgradeable, IRewardsDistributor {
    using LowGasSafeMath for uint256;
    using LowGasSafeMath for int256;
    using PreciseUnitMath for uint256;
    using PreciseUnitMath for int256;
    using SafeDecimalMath for uint256;
    using SafeDecimalMath for int256;
    using Math for uint256;
    using Math for int256;

    /* ========== Events ========== */

    /* ============ Modifiers ============ */
    /**
     * Throws if the call is not from a valid strategy
     */
    function _onlyStrategy(address _strategy) private view {
        address garden = address(IStrategy(_strategy).garden());
        _isGarden(garden);
        _isGardenStrategy(garden, _strategy);
    }

    /**
     * Throws if the sender is not the controller
     */
    function _onlyGovernanceOrEmergency() private view {
        _require(
            msg.sender == controller.owner() ||
                msg.sender == controller.EMERGENCY_OWNER() ||
                msg.sender == address(controller),
            Errors.ONLY_GOVERNANCE_OR_EMERGENCY
        );
    }

    /**
     * Throws if Rewards Distributor is paused
     */
    function _onlyUnpaused() private view {
        // Do not execute if Globally or individually paused
        _require(!controller.isPaused(address(this)), Errors.ONLY_UNPAUSED);
    }

    /**
     * Throws if not an official Babylon garden
     */
    function _isGarden(address _garden) private view {
        _require(controller.isGarden(_garden), Errors.ONLY_ACTIVE_GARDEN);
    }

    /**
     * Throws if not an official Babylon strategy of that garden
     */
    function _isGardenStrategy(address _garden, address _strategy) private view {
        _require(IGarden(_garden).isGardenStrategy(_strategy), Errors.STRATEGY_GARDEN_MISMATCH);
    }

    /**
     * Throws if a malicious reentrant call is detected
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        _require(status != ENTERED, Errors.REENTRANT_CALL);
        // Any calls to nonReentrant after this point will fail
        status = ENTERED;
        _;
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        status = NOT_ENTERED;
    }

    /* ============ Constants ============ */
    // 500K BABL allocated to this BABL Mining Program, the first quarter is Q1_REWARDS
    // and the following quarters will follow the supply curve using a decay rate
    uint256 private constant Q1_REWARDS = 53_571_428_571_428_600e6; // First quarter (epoch) BABL rewards
    // 12% quarterly decay rate (each 90 days)
    // (Rewards on Q1 = 1,12 * Rewards on Q2) being Q1= Quarter 1, Q2 = Quarter 2
    uint256 private constant DECAY_RATE = 12e16;
    // Duration of its EPOCH in days  // BABL & profits split from the protocol
    uint256 private constant EPOCH_DURATION = 90 days;
    // DAI normalize asset
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // Reentrancy guard countermeasure
    uint256 private constant NOT_ENTERED = 1;
    uint256 private constant ENTERED = 2;
    // NFT Prophets
    IProphets private constant PROPHETS_NFT = IProphets(0x26231A65EF80706307BbE71F032dc1e5Bf28ce43);
    uint256 private constant DEFAULT_BABL_CAP = 15_000e18;

    /* ============ State Variables ============ */

    // solhint-disable-next-line
    uint256 private START_TIME; // Starting time of the rewards distribution

    // solhint-disable-next-line
    uint256 private strategistBABLPercentage;
    // solhint-disable-next-line
    uint256 private stewardsBABLPercentage;
    // solhint-disable-next-line
    uint256 private lpsBABLPercentage;
    // solhint-disable-next-line
    uint256 private strategistProfitPercentage;
    // solhint-disable-next-line
    uint256 private stewardsProfitPercentage;
    // solhint-disable-next-line
    uint256 private lpsProfitPercentage;
    // solhint-disable-next-line
    uint256 private profitProtocolFee;
    // solhint-disable-next-line
    uint256 private gardenCreatorBonus;

    /* ============ Structs ============ */

    struct ProtocolPerTimestamp {
        uint256 principal; // DEPRECATED
        uint256 time; // DEPRECATED
        uint256 quarterBelonging; // DEPRECATED
        uint256 timeListPointer; // DEPRECATED
        uint256 power; // DEPRECATED
    }

    struct ProtocolPerQuarter {
        // Protocol allocation checkpoints per timestamp per each quarter along the time
        uint256 quarterPrincipal; // DEPRECATED
        uint256 quarterNumber; // DEPRECATED
        uint256 quarterPower; //  Accumulated Protocol power for each quarter
        uint96 supplyPerQuarter; // DEPRECATED
    }

    struct GardenPowerByTimestamp {
        // Garden allocation checkpoints per timestamp per each garden
        uint256 avgGardenBalance; // Checkpoint to keep track on garden supply
        uint256 lastDepositAt; // Checkpoint timestamps
        uint256 accGardenPower; // Garden power checkpoint (power is proportional to = principal * duration)
    }
    struct ContributorPerGarden {
        // Checkpoints to keep track on the evolution of each contributor vs. each garden
        uint256 lastDepositAt; // Last deposit timestamp of each contributor in each garden
        uint256 initialDepositAt; // Checkpoint of the initial deposit
        uint256[] timeListPointer; // DEPRECATED, but still needed during beta gardens migration
        uint256 pid; // DEPRECATED, but still needed during beta gardens migration
        // Sub-mapping of contributor details, updated info after beta will be only at position [0]
        mapping(uint256 => TimestampContribution) tsContributions;
    }

    struct TimestampContribution {
        // Sub-mapping with all checkpoints for deposits and withdrawals of garden users
        uint256 avgBalance; // User avg balance in each garden along the time
        uint256 timestamp; // DEPRECATED
        uint256 timePointer; // DEPRECATED
        uint256 power; // Contributor power
    }
    struct Checkpoints {
        uint256 fromTime; // checkpoint block timestamp
        uint256 tokens; // User garden tokens in the checkpoint
        uint256 supply; // DEPRECATED
        uint256 prevBalance; // Previous user balance (backward compatibility for beta users)
    }

    /* ============ State Variables ============ */

    // Instance of the Controller contract
    IBabController private controller;

    // BABL Token contract
    TimeLockedToken public override babltoken;

    // Protocol total allocation points. Must be the sum of all allocation points (strategyPrincipal)
    // in all ongoing strategies during mining program.
    uint256 private miningProtocolPrincipal; // Protocol principal (only related to mining program)
    mapping(uint256 => ProtocolPerTimestamp) private protocolPerTimestamp; // DEPRECATED
    uint256[] private timeList; // DEPRECATED
    uint256 private miningProtocolPower; // Mining protocol power along the time

    // Mapping of the accumulated protocol per each active quarter
    mapping(uint256 => ProtocolPerQuarter) private protocolPerQuarter;
    // Check if the protocol per quarter data has been initialized
    mapping(uint256 => bool) private isProtocolPerQuarter;

    mapping(address => mapping(uint256 => uint256)) private rewardsPowerOverhead; // DEPRECATED
    // Contributor power control
    // Contributor details per garden
    mapping(address => mapping(address => ContributorPerGarden)) private contributorPerGarden;
    mapping(address => mapping(address => Checkpoints)) private checkpoints; // DEPRECATED
    // Garden power control
    // Garden power details per garden. Updated info after beta will be only at position [0]
    mapping(address => mapping(uint256 => GardenPowerByTimestamp)) private gardenPowerByTimestamp;
    mapping(address => uint256[]) private gardenTimelist; // DEPRECATED, but still needed during beta gardens migration
    mapping(address => uint256) private gardenPid; // DEPRECATED, but still needed during beta gardens migration

    struct StrategyPerQuarter {
        // Acumulated strategy power per each quarter along the time
        uint256 quarterPrincipal; // DEPRECATED
        uint256 betaInitializedAt; // Only used for beta strategies
        uint256 quarterPower; //  Accumulated strategy power for each quarter
        bool initialized; // True if the strategy has checkpoints in that quarter already
    }
    struct StrategyPricePerTokenUnit {
        // Take control over the price per token changes along the time when normalizing into DAI
        uint256 preallocated; // Strategy capital preallocated before each checkpoint
        uint256 pricePerTokenUnit; // Last average price per allocated tokens per strategy normalized into DAI
    }
    // Acumulated strategy power per each quarter along the time
    mapping(address => mapping(uint256 => StrategyPerQuarter)) private strategyPerQuarter;
    // Pro-rata oracle price allowing re-allocations and unwinding of any capital value
    mapping(address => StrategyPricePerTokenUnit) private strategyPricePerTokenUnit;

    // Reentrancy guard countermeasure
    uint256 private status;

    // Customized profit sharing (if any)
    // [0]: _strategistProfit , [1]: _stewardsProfit, [2]: _lpProfit
    mapping(address => uint256[3]) private gardenProfitSharing;
    mapping(address => bool) private gardenCustomProfitSharing;

    uint256 private miningUpdatedAt; // Timestamp of last strategy capital update
    mapping(address => uint256) private strategyPrincipal; // Last known strategy principal normalized into DAI

    // Mapping re-used to trigger governance migrations into checkpoints for an address
    // Address can be garden or an individual user
    // Usage:
    // a) to migrate the whole garden => betaAddressMigrated[_garden][_garden] = true
    // b) to migrate a user for all gardens at once => betaAddressMigrated[_contributor][_contributor] = true
    // Note: do not re-use it in the following format => [_garden][_contributor] as it was previously used for another older migration to avoid issues.
    mapping(address => mapping(address => bool)) private betaAddressMigrated;
    mapping(address => bool) private betaOldMigrations; // DEPRECATED

    uint256 private bablProfitWeight;
    uint256 private bablPrincipalWeight;

    // A record of garden token checkpoints for each address of each garden, by index
    // garden -> address -> index checkpoint -> checkpoint struct data
    mapping(address => mapping(address => mapping(uint256 => Checkpoints))) private gardenCheckpoints;

    // The number of checkpoints for each address of each garden
    // garden -> address -> number of checkpoints
    mapping(address => mapping(address => uint256)) private numCheckpoints;
    // Benchmark creates up to 3 segments to differentiate between cool strategies and bad strategies
    // First 2 values benchmark[0] and benchmark[1] represent returned/allocated % min and max thresholds to create 3 segments
    // benchmark[0] value: Used to define the threshold between very bad strategies and not cool strategies
    // benchmark[0] = minThreshold default 0 (e.g. 90e16 represents profit of -10 %)
    // It separates segment 1 (very bad strategies) and segment 2 (not cool strategies)
    // benchmark[1] value: Used to define the threshold between not good/cool strategies and cool/good strategies
    // benchmark[1] = maxThreshold default 0 (e.g. 103e16 represents profit of +3 %)
    // It separates segment 2 (not cool strategies) and segment 3 (cool strategies)
    // benchmark[2] value: Used to set a penalty (if any) for very bad strategies (segment 1)
    // benchmark[2] = Segment1 Penalty default 0 (e.g. 50e16 represents 1/2 = 50% = half rewards penalty)
    // benchmark[3] value: Used to set a penalty (if any) for not cool strategies (segment 2)
    // benchmark[3] = Segment 2 Penalty/Boost default 0 (e.g. 1e18 represents 1 = 100% = no rewards penalty)
    // becnhmark[4] value: Used to set a boost (if any) for cool strategies (segment 3)
    // becnhmark[4] = Segment 3 Boost default 1e18 (e.g. 2e18 represents 2 = 200% = rewards boost x2)
    uint256[5] private benchmark;
    uint256 private maxBablCap;

    /* ============ Constructor ============ */

    function initialize(TimeLockedToken _bablToken, IBabController _controller) public initializer {
        OwnableUpgradeable.__Ownable_init();
        _require(address(_bablToken) != address(0) && address(_controller) != address(0), Errors.ADDRESS_IS_ZERO);
        babltoken = _bablToken;
        controller = _controller;

        profitProtocolFee = controller.protocolPerformanceFee();

        strategistProfitPercentage = 10e16; // 10%
        stewardsProfitPercentage = 5e16; // 5%
        lpsProfitPercentage = 80e16; // 80%

        strategistBABLPercentage = 10e16; // 10%
        stewardsBABLPercentage = 10e16; // 10%
        lpsBABLPercentage = 80e16; // 80%
        gardenCreatorBonus = 10e16; // 10%

        bablProfitWeight = 65e16; // 65% (BIP-7 will change it into 95%)
        bablPrincipalWeight = 35e16; // 35% (BIP-7 will change it into 5%)

        status = NOT_ENTERED;
        // BABL Mining program was started by bip#1
        START_TIME = block.timestamp;
        // Benchmark conditions to apply to BABL rewards are initialized as 0
        // Backward compatibility manages benchmark[4] value that must be always >= 1e18
        benchmark[4] = 1e18; // default value
    }

    /* ============ External Functions ============ */

    /**
     * Function that adds/substract the capital received to the total principal of the protocol per timestamp
     * @param _capital                Amount of capital in any type of asset to be normalized into DAI
     * @param _addOrSubstract         Whether we are adding or substracting capital
     */
    function updateProtocolPrincipal(uint256 _capital, bool _addOrSubstract) external override {
        _onlyStrategy(msg.sender);
        // All strategies are now part of the Mining Program
        _updateProtocolPrincipal(msg.sender, _capital, _addOrSubstract);
    }

    /**
     * Function used by each garden to signal each deposit and withdrawal in checkpoints to be used for rewards
     * @param _garden                Address of the garden
     * @param _contributor           Address of the contributor
     * @param _previousBalance       Previous balance of the contributor
     * @param _tokenDiff             Amount difference in this deposit/withdraw
     * @param _addOrSubstract        Whether the contributor is adding (true) or withdrawing capital (false)
     */
    function updateGardenPowerAndContributor(
        address _garden,
        address _contributor,
        uint256 _previousBalance,
        uint256 _tokenDiff,
        bool _addOrSubstract
    ) external override nonReentrant {
        _isGarden(msg.sender);
        uint256 newBalance = _addOrSubstract ? _previousBalance.add(_tokenDiff) : _previousBalance.sub(_tokenDiff);
        // Creates a new user checkpoint
        _writeCheckpoint(_garden, _contributor, newBalance, _previousBalance);
    }

    /**
     * Sending BABL as part of the claim process (either by sig or standard claim)
     * If it is the Heart Garden, the claim is done by the garden during each strategy finalization
     * This is due to the Heart Garden is auto-compounding all rewards
     *
     */
    function sendBABLToContributor(address _to, uint256 _babl) external override nonReentrant returns (uint256) {
        _isGarden(msg.sender);
        return _sendBABLToAddress(_to, _babl);
    }

    /** PRIVILEGE FUNCTION
     * Set customized profit shares for a specific garden by the gardener
     * @param _garden               Address of the garden
     * @param _strategistShare      New % of strategistShare
     * @param _stewardsShare        New % of stewardsShare
     * @param _lpShare              New % of lpShare
     */
    function setProfitRewards(
        address _garden,
        uint256 _strategistShare,
        uint256 _stewardsShare,
        uint256 _lpShare
    ) external override {
        _onlyGovernanceOrEmergency();
        _isGarden(_garden);
        _setProfitRewards(_garden, _strategistShare, _stewardsShare, _lpShare);
    }

    /** PRIVILEGE FUNCTION
     * Migrates by governance: (2 options)
     * a) the whole garden or a user for all gardens into checkpoints deprecating c-power
     * @param _address              Array of Address to migrate (garden or user)
     * @param _toMigrate            Bool to migrate (true) or redo (false)
     */
    function migrateAddressToCheckpoints(address _address, bool _toMigrate) external override {
        _onlyGovernanceOrEmergency();
        betaAddressMigrated[_address][_address] = _toMigrate;
    }

    /** PRIVILEGE FUNCTION
     * Change default BABL shares % by the governance
     * @param _newMiningParams      Array of new mining params to be set by government
     */
    function setBABLMiningParameters(uint256[12] memory _newMiningParams) external override {
        // _newMiningParams[0]: _strategistShare
        // _newMiningParams[1]: _stewardsShare
        // _newMiningParams[2]: _lpShare
        // _newMiningParams[3]: _creatorBonus
        // _newMiningParams[4]: _profitWeight
        // _newMiningParams[5]: _principalWeight
        // _newMiningParams[6]: _benchmark[0] to differentiate from very bad strategies and not cool strategies
        // _newMiningParams[7]: _benchmark[1] to differentiate from not cool strategies and cool strategies
        // _newMiningParams[8]: _benchmark[2] penalty to be applied to very bad strategies in benchmark segment 1
        // _newMiningParams[9]: _benchmark[3] penalty to be applied to not cool strategies in benchmark segment 2
        // _newMiningParams[10]: _benchmark[4] boost/bonus to be applied to cool strategies in benchmark segment 3
        // _newMiningParams[11]: _bablCap Max BABL Cap
        _onlyGovernanceOrEmergency();
        _require(
            _newMiningParams[0].add(_newMiningParams[1]).add(_newMiningParams[2]) == 1e18 &&
                _newMiningParams[3] <= 1e18 &&
                _newMiningParams[4].add(_newMiningParams[5]) == 1e18 &&
                _newMiningParams[6] <= _newMiningParams[7] &&
                _newMiningParams[8] <= _newMiningParams[9] &&
                _newMiningParams[9] <= _newMiningParams[10] &&
                _newMiningParams[10] >= 1e18,
            Errors.INVALID_MINING_VALUES
        );
        strategistBABLPercentage = _newMiningParams[0];
        stewardsBABLPercentage = _newMiningParams[1];
        lpsBABLPercentage = _newMiningParams[2];
        gardenCreatorBonus = _newMiningParams[3];
        bablProfitWeight = _newMiningParams[4];
        bablPrincipalWeight = _newMiningParams[5];
        benchmark[0] = _newMiningParams[6]; // minThreshold dividing segment 1 and 2 (if any)
        benchmark[1] = _newMiningParams[7]; // maxThreshold dividing segment 2 and 3 (if any)
        benchmark[2] = _newMiningParams[8]; // penalty for segment 1
        benchmark[3] = _newMiningParams[9]; // penalty/boost for segment 2
        benchmark[4] = _newMiningParams[10]; // boost for segment 3
        maxBablCap = _newMiningParams[11]; // Max BABL Cap
    }

    /* ========== View functions ========== */

    /**
     * Calculates the profits and BABL that a contributor should receive from a series of finalized strategies
     * @param _garden                   Garden to which the strategies and the user must belong to
     * @param _contributor              Address of the contributor to check
     * @param _finalizedStrategies      List of addresses of the finalized strategies to check
     * @return Array of size 7 with the following distribution:
     * rewards[0]: Strategist BABL
     * rewards[1]: Strategist Profit
     * rewards[2]: Steward BABL
     * rewards[3]: Steward Profit
     * rewards[4]: LP BABL
     * rewards[5]: total BABL
     * rewards[6]: total Profits
     * rewards[7]: Creator bonus
     */
    function getRewards(
        address _garden,
        address _contributor,
        address[] calldata _finalizedStrategies
    ) external view override returns (uint256[] memory) {
        _isGarden(_garden);
        uint256[] memory totalRewards = new uint256[](8);
        if (_garden == address(IHeart(controller.heart()).heartGarden())) {
            // No claim available at heartGarden as all rewards were auto-compounded
            // during strategy finalization
            return totalRewards;
        }
        (, , uint256 claimedAt, , , , , , ) = IGarden(_garden).getContributor(_contributor);
        for (uint256 i = 0; i < _finalizedStrategies.length; i++) {
            // Security check
            _isGardenStrategy(_garden, _finalizedStrategies[i]);

            uint256[] memory tempRewards = new uint256[](8);

            tempRewards = _getStrategyProfitsAndBABL(_garden, _finalizedStrategies[i], _contributor, claimedAt);
            totalRewards[0] = totalRewards[0].add(tempRewards[0]);
            totalRewards[1] = totalRewards[1].add(tempRewards[1]);
            totalRewards[2] = totalRewards[2].add(tempRewards[2]);
            totalRewards[3] = totalRewards[3].add(tempRewards[3]);
            totalRewards[4] = totalRewards[4].add(tempRewards[4]);
            totalRewards[5] = totalRewards[5].add(tempRewards[5]);
            totalRewards[6] = totalRewards[6].add(tempRewards[6]);
            totalRewards[7] = totalRewards[7].add(tempRewards[7]);
        }

        return totalRewards;
    }

    /**
     * Gets the baseline amount of BABL rewards for a given strategy
     * @param _strategy     Strategy to check
     */
    function getStrategyRewards(address _strategy) external view override returns (uint256) {
        IStrategy strategy = IStrategy(_strategy);
        // ts[0]: executedAt, ts[1]: exitedAt, ts[2]: updatedAt
        uint256[] memory ts = new uint256[](3);
        (, , , , ts[0], ts[1], ts[2]) = strategy.getStrategyState();
        _require(ts[1] != 0, Errors.STRATEGY_IS_NOT_OVER_YET);
        if (ts[1] >= START_TIME) {
            // We avoid gas consuming once a strategy got its BABL rewards during its finalization
            uint256 rewards = strategy.strategyRewards();
            if (rewards != 0) {
                return rewards;
            }
            // str[0]: capitalAllocated, str[1]: capitalReturned
            uint256[] memory str = new uint256[](2);
            (, , , , , , str[0], str[1], , , , , , ) = strategy.getStrategyDetails();
            // If the calculation was not done earlier we go for it
            (uint256 numQuarters, uint256 startingQuarter) = _getRewardsWindow(ts[0], ts[1]);
            uint256 percentage = 1e18;
            for (uint256 i = 0; i < numQuarters; i++) {
                // Initialization timestamp at the end of the first slot where the strategy starts its execution
                uint256 slotEnding = START_TIME.add(startingQuarter.add(i).mul(EPOCH_DURATION));
                // We calculate each epoch
                uint256 strategyPower = strategyPerQuarter[_strategy][startingQuarter.add(i)].quarterPower;
                uint256 protocolPower = protocolPerQuarter[startingQuarter.add(i)].quarterPower;
                _require(strategyPower <= protocolPower, Errors.OVERFLOW_IN_POWER);
                if (i.add(1) == numQuarters) {
                    // last quarter - we need to take proportional supply for that timeframe despite
                    // the epoch has not finished yet
                    percentage = block.timestamp.sub(slotEnding.sub(EPOCH_DURATION)).preciseDiv(
                        slotEnding.sub(slotEnding.sub(EPOCH_DURATION))
                    );
                }
                uint256 rewardsPerQuarter =
                    strategyPower
                        .preciseDiv(protocolPower)
                        .preciseMul(_tokenSupplyPerQuarter(startingQuarter.add(i)))
                        .preciseMul(percentage);
                rewards = rewards.add(rewardsPerQuarter);
            }
            // Apply rewards weight related to principal and profit and related to benchmark
            return _getBenchmarkRewards(str[1], str[0], rewards, ts[0], _strategy);
        } else {
            return 0;
        }
    }

    /**
     * Get token power at a specific block for an account
     *
     * @param _garden       Address of the garden
     * @param _address      Address to get prior balance for
     * @param _blockTime  Block timestamp to get token power at
     * @return Timestamp initializedAt timestamp (if any)
     * @return Balance power in garden tokens for an account just prior to a specific blockTime
     * @return Checkpoint prior checkpoint to a specific blockTime (if any)
     */
    function getPriorBalance(
        address _garden,
        address _address,
        uint256 _blockTime
    )
        public
        view
        virtual
        override
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        // We get the previous (prior) balance to _blockTime timestamp
        // Actually it also acts as a flashloan protection along the time
        _blockTime = _blockTime.sub(1);
        uint256 nCheckpoints = numCheckpoints[_garden][_address];
        ContributorPerGarden storage contributor = contributorPerGarden[_garden][_address];
        // beta user if initializedAt > 0
        uint256 initializedAt = contributor.initialDepositAt;
        uint256 balance = ERC20(_garden).balanceOf(_address);
        if (nCheckpoints == 0 && !(initializedAt > 0)) {
            return (0, 0, 0);
        } else if (nCheckpoints == 0 && initializedAt > 0) {
            // Backward compatible for beta users, initial deposit > 0 but still no checkpoints
            // It also consider burning for bad strategist
            return (initializedAt, balance, 0);
        }
        // There are at least one checkpoint from this point
        // First check most recent balance
        if (gardenCheckpoints[_garden][_address][nCheckpoints - 1].fromTime <= _blockTime) {
            // Burning security protection at userTokens
            // It only limit the balance in case of burnt tokens and only if using last checkpoint
            return (
                gardenCheckpoints[_garden][_address][nCheckpoints - 1].fromTime,
                gardenCheckpoints[_garden][_address][nCheckpoints - 1].tokens > balance
                    ? balance
                    : gardenCheckpoints[_garden][_address][nCheckpoints - 1].tokens,
                nCheckpoints - 1
            );
        }
        // Next check implicit zero balance
        if (gardenCheckpoints[_garden][_address][0].fromTime > _blockTime && !(initializedAt > 0)) {
            // backward compatible
            return (0, 0, 0);
        } else if (gardenCheckpoints[_garden][_address][0].fromTime > _blockTime && initializedAt > 0) {
            // Backward compatible for beta users, initial deposit > 0 but lost initial checkpoints
            // First checkpoint stored its previous balance so we use it to guess the user past
            return (initializedAt, gardenCheckpoints[_garden][_address][0].prevBalance, 0);
        }
        // It has more checkpoints but the time is between different checkpoints, we look for it
        uint256 lower = 0;
        uint256 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint256 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoints memory cp = gardenCheckpoints[_garden][_address][center];
            if (cp.fromTime == _blockTime) {
                return (cp.fromTime, cp.tokens, center);
            } else if (cp.fromTime < _blockTime) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return (
            gardenCheckpoints[_garden][_address][lower].fromTime,
            gardenCheckpoints[_garden][_address][lower].tokens,
            lower
        );
    }

    /**
     * Check the mining program state for a specific quarter and strategy
     * @param _quarterNum      Number of quarter
     * @param _strategy        Address of strategy
     */
    function checkMining(uint256 _quarterNum, address _strategy)
        external
        view
        override
        returns (uint256[17] memory miningData)
    {
        miningData[0] = START_TIME;
        miningData[1] = miningUpdatedAt;
        miningData[2] = miningProtocolPrincipal;
        miningData[3] = miningProtocolPower;
        miningData[4] = protocolPerQuarter[_quarterNum].quarterPower;
        miningData[5] = strategyPrincipal[_strategy];
        miningData[6] = strategyPricePerTokenUnit[_strategy].preallocated;
        miningData[7] = strategyPricePerTokenUnit[_strategy].pricePerTokenUnit;
        miningData[8] = strategyPerQuarter[_strategy][_quarterNum].quarterPower;
        miningData[9] = _tokenSupplyPerQuarter(_quarterNum);
        miningData[10] = bablProfitWeight;
        miningData[11] = bablPrincipalWeight;
        miningData[12] = benchmark[0];
        miningData[13] = benchmark[1];
        miningData[14] = benchmark[2];
        miningData[15] = benchmark[3];
        miningData[16] = benchmark[4];
    }

    /**
     * Check the garden profit sharing % if different from default
     * @param _garden     Address of the garden
     */
    function getGardenProfitsSharing(address _garden) external view override returns (uint256[3] memory) {
        if (gardenCustomProfitSharing[_garden]) {
            // It has customized values
            return gardenProfitSharing[_garden];
        } else {
            return [strategistProfitPercentage, stewardsProfitPercentage, lpsProfitPercentage];
        }
    }

    /**
     * Get an estimation of user rewards for active strategies
     * @param _strategy        Address of the strategy to estimate BABL rewards
     * @param _contributor     Address of the garden contributor
     * @return Array of size 8 with the following distribution:
     * rewards[0]: Strategist BABL
     * rewards[1]: Strategist Profit
     * rewards[2]: Steward BABL
     * rewards[3]: Steward Profit
     * rewards[4]: LP BABL
     * rewards[5]: total BABL
     * rewards[6]: total Profits
     * rewards[7]: Creator bonus
     */
    function estimateUserRewards(address _strategy, address _contributor)
        external
        view
        override
        returns (uint256[] memory)
    {
        // strategyDetails array mapping:
        // strategyDetails[0]: executedAt
        // strategyDetails[1]: exitedAt
        // strategyDetails[2]: updatedAt
        // strategyDetails[3]: enteredAt
        // strategyDetails[4]: totalPositiveVotes
        // strategyDetails[5]: totalNegativeVotes
        // strategyDetails[6]: capitalAllocated
        // strategyDetails[7]: capitalReturned
        // strategyDetails[8]: expectedReturn
        // strategyDetails[9]: strategyRewards
        // strategyDetails[10]: profitValue
        // strategyDetails[11]: distanceValue
        // strategyDetails[12]: startingGardenSupply
        // strategyDetails[13]: endingGardenSupply
        // profitData array mapping:
        // profitData[0]: profit
        // profitData[1]: distance

        uint256[] memory rewards = new uint256[](8);
        if (IStrategy(_strategy).isStrategyActive()) {
            address garden = address(IStrategy(_strategy).garden());
            (address strategist, uint256[] memory strategyDetails, bool[] memory profitData) =
                _estimateStrategyRewards(_strategy);
            // Get the contributor share % within the strategy window out of the total garden and users
            uint256 contributorShare = _getSafeUserSharePerStrategy(garden, _contributor, strategyDetails);
            rewards = _getRewardsPerRole(
                garden,
                _strategy,
                strategist,
                _contributor,
                contributorShare,
                strategyDetails,
                profitData
            );
            // add Prophets NFT bonus if staked in the garden
            rewards = _boostRewards(garden, _contributor, rewards, strategyDetails);
        }
        return rewards;
    }

    /**
     * Get a safe user share position within a strategy of a garden
     * @param _garden          Address of the garden
     * @param _contributor     Address of the garden contributor
     * @param _strategy        Address of the strategy
     * @return % deserved share per user
     */
    function getSafeUserSharePerStrategy(
        address _garden,
        address _contributor,
        address _strategy
    ) external view returns (uint256) {
        (, uint256[] memory strategyDetails, ) = IStrategy(_strategy).getStrategyRewardsContext();
        // strategyDetails[0] = executedAt
        // strategyDetails[1] = exitedAt
        // strategyDetails[13] = endingGardenSupply
        return _getSafeUserSharePerStrategy(_garden, _contributor, strategyDetails);
    }

    /**
     * Get an estimation of strategy BABL rewards for active strategies in the mining program
     * @param _strategy        Address of the strategy to estimate BABL rewards
     * @return the estimated BABL rewards
     */
    function estimateStrategyRewards(address _strategy) external view override returns (uint256) {
        if (IStrategy(_strategy).isStrategyActive()) {
            (, uint256[] memory strategyDetails, ) = _estimateStrategyRewards(_strategy);
            return strategyDetails[9];
        } else {
            return 0;
        }
    }

    /* ============ Internal Functions ============ */

    /**
     * @dev internal function to write a checkpoint for contributor token power
     * @param _garden        Address of the garden
     * @param _address       Address for the checkpoint
     * @param _newBalance    The new token balance
     * @param _prevBalance   The previous user token balance
     */
    function _writeCheckpoint(
        address _garden,
        address _address,
        uint256 _newBalance,
        uint256 _prevBalance
    ) internal {
        uint256 blockTime = block.timestamp;
        uint256 nCheckpoints = numCheckpoints[_garden][_address];
        if (nCheckpoints > 0 && gardenCheckpoints[_garden][_address][nCheckpoints - 1].fromTime == blockTime) {
            gardenCheckpoints[_garden][_address][nCheckpoints - 1].tokens = _newBalance;
        } else {
            // We only store previous Balance in case of the first checkpoint
            // to get backward compatibility for beta addresses
            if (nCheckpoints == 0) {
                gardenCheckpoints[_garden][_address][nCheckpoints] = Checkpoints(
                    blockTime,
                    _newBalance,
                    0,
                    _prevBalance
                );
            } else {
                gardenCheckpoints[_garden][_address][nCheckpoints] = Checkpoints(blockTime, _newBalance, 0, 0);
            }
            numCheckpoints[_garden][_address] = nCheckpoints + 1;
        }
    }

    /**
     * Update the protocol principal checkpoints
     * @param _strategy         Strategy which is adding/removing principal
     * @param _capital          Capital to update
     * @param _addOrSubstract   Adding (true) or removing (false)
     */
    function _updateProtocolPrincipal(
        address _strategy,
        uint256 _capital,
        bool _addOrSubstract
    ) internal {
        address reserveAsset = IGarden(IStrategy(_strategy).garden()).reserveAsset();
        // To compare strategy power between all strategies we normalize their capital into DAI
        // Then, we need to take control of getPrice fluctuations along the time
        uint256 pricePerTokenUnit = _getStrategyPricePerTokenUnit(reserveAsset, _strategy, _capital, _addOrSubstract);
        _capital = _capital.preciseMul(pricePerTokenUnit).mul(10**uint256(18).sub(ERC20(reserveAsset).decimals()));
        // Create or/and update the protocol quarter checkpoints if mining program is activated
        _updateProtocolPowerPerQuarter();
        // We update the strategy power per quarter normalized in DAI if mining program is activated
        _updateStrategyPowerPerQuarter(_strategy);
        // The following function call _updatePrincipal must be always executed
        // after _updateProtocolPowerPerQuarter and _updateStrategyPowerPerQuarter
        _updatePrincipal(_strategy, _capital, _addOrSubstract);
        // The following time set should always be executed at the end
        miningUpdatedAt = block.timestamp;
    }

    /**
     * Update the principal considered part of the mining program either Protocol or Strategies
     * @param _strategy         Strategy address
     * @param _capital          Capital normalized into DAI to add or substract for accurate
     * comparisons between strategies
     * @param _addOrSubstract   Whether or not we are adding or unwinding capital to the strategy under mining
     */
    function _updatePrincipal(
        address _strategy,
        uint256 _capital,
        bool _addOrSubstract
    ) private {
        if (!_addOrSubstract) {
            // Substracting capital
            // Failsafe condition
            uint256 amount = _capital > strategyPrincipal[_strategy] ? strategyPrincipal[_strategy] : _capital;
            miningProtocolPrincipal = miningProtocolPrincipal.sub(amount);
            strategyPrincipal[_strategy] = strategyPrincipal[_strategy].sub(amount);
        } else {
            // Adding capital
            miningProtocolPrincipal = miningProtocolPrincipal.add(_capital);
            strategyPrincipal[_strategy] = strategyPrincipal[_strategy].add(_capital);
        }
    }

    /**
     * Add protocol power timestamps for each quarter
     */
    function _updateProtocolPowerPerQuarter() private {
        uint256[] memory data = new uint256[](4);
        // data[0]: previous quarter, data[1]: current quarter, data[2]: timeDifference, data[3]: debtPower
        data[0] = miningUpdatedAt == 0 ? 1 : _getQuarter(miningUpdatedAt);
        data[1] = _getQuarter(block.timestamp);
        data[2] = block.timestamp.sub(miningUpdatedAt);
        ProtocolPerQuarter storage protocolCheckpoint = protocolPerQuarter[data[1]];
        data[3] = miningUpdatedAt == 0 ? 0 : miningProtocolPrincipal.mul(data[2]);
        if (!isProtocolPerQuarter[data[1]]) {
            // The quarter is not initialized yet, we then create it
            if (miningUpdatedAt > 0) {
                // A new epoch has started with either a new strategy execution or finalization checkpoint
                if (data[0] == data[1].sub(1)) {
                    // There were no intermediate epoch without checkpoints, we are in the next epoch
                    // We need to divide the debtPower between previous epoch and current epoch
                    // We re-initialize the protocol power in the new epoch adding only the corresponding
                    // to its duration
                    protocolCheckpoint.quarterPower = data[3]
                        .mul(block.timestamp.sub(START_TIME.add(data[1].mul(EPOCH_DURATION).sub(EPOCH_DURATION))))
                        .div(data[2]);
                    // We now update the previous quarter with its proportional pending debtPower
                    protocolPerQuarter[data[1].sub(1)].quarterPower = protocolPerQuarter[data[1].sub(1)]
                        .quarterPower
                        .add(data[3].sub(protocolCheckpoint.quarterPower));
                } else {
                    // There were some intermediate epochs without checkpoints - we need to create
                    // missing checkpoints and update the last (current) one.
                    // We have to update all the quarters since last update
                    for (uint256 i = 0; i <= data[1].sub(data[0]); i++) {
                        ProtocolPerQuarter storage newCheckpoint = protocolPerQuarter[data[0].add(i)];
                        uint256 slotEnding = START_TIME.add(data[0].add(i).mul(EPOCH_DURATION));
                        if (i == 0) {
                            // We are in the first quarter to update (corresponding to miningUpdatedAt timestamp)
                            // We add the corresponding proportional part
                            newCheckpoint.quarterPower = newCheckpoint.quarterPower.add(
                                data[3].mul(slotEnding.sub(miningUpdatedAt)).div(data[2])
                            );
                        } else if (i < data[1].sub(data[0])) {
                            // We are in an intermediate quarter without checkpoints - need to create and update it
                            newCheckpoint.quarterPower = data[3].mul(EPOCH_DURATION).div(data[2]);
                        } else {
                            // We are in the last (current) quarter
                            // We update its proportional remaining debt power
                            protocolCheckpoint.quarterPower = data[3]
                                .mul(
                                block.timestamp.sub(START_TIME.add(data[1].mul(EPOCH_DURATION).sub(EPOCH_DURATION)))
                            )
                                .div(data[2]);
                        }
                    }
                }
            }
            isProtocolPerQuarter[data[1]] = true;
        } else {
            // Quarter checkpoint already created
            // We update the power of the quarter by adding the new difference between last quarter
            // checkpoint and this checkpoint
            protocolCheckpoint.quarterPower = protocolCheckpoint.quarterPower.add(data[3]);
            miningProtocolPower = miningProtocolPower.add(data[3]);
        }
    }

    /**
     * Updates the strategy power per quarter for rewards calculations of each strategy out of the whole protocol
     * @param _strategy    Strategy address
     */
    function _updateStrategyPowerPerQuarter(address _strategy) private {
        uint256[] memory data = new uint256[](5);
        // data[0]: executedAt, data[1]: updatedAt, data[2]: time difference, data[3]: quarter, data[4]: debtPower
        (, , , , data[0], , data[1]) = IStrategy(_strategy).getStrategyState();
        if (data[1] < START_TIME) {
            // We check the initialization only for beta gardens, quarter = 1
            StrategyPerQuarter storage betaStrategyCheckpoint = strategyPerQuarter[_strategy][1];
            if (betaStrategyCheckpoint.betaInitializedAt == 0) {
                betaStrategyCheckpoint.betaInitializedAt = block.timestamp;
            }
            // Only for strategies starting before mining and still executing, get proportional
            // Exited strategies before the mining starts, are not eligible of this standard setup
            data[1] = betaStrategyCheckpoint.betaInitializedAt;
        }
        data[2] = block.timestamp.sub(data[1]);
        data[3] = _getQuarter(block.timestamp);
        StrategyPerQuarter storage strategyCheckpoint = strategyPerQuarter[_strategy][data[3]];
        // We calculate the debt Power since last checkpoint (if any)
        data[4] = strategyPrincipal[_strategy].mul(data[2]);
        if (!strategyCheckpoint.initialized) {
            // The strategy quarter is not yet initialized then we create it
            // If it the first checkpoint in the first executing epoch - keep power 0
            if (data[3] > _getQuarter(data[0])) {
                // Each time a running strategy has a new checkpoint on a new (different) epoch than
                // previous checkpoints.
                // debtPower is the proportional power of the strategy for this quarter from previous checkpoint
                // We need to iterate since last checkpoint
                (uint256 numQuarters, uint256 startingQuarter) = _getRewardsWindow(data[1], block.timestamp);

                // There were intermediate epochs without checkpoints - we need to create their corresponding
                //  checkpoints and update the last one
                // We have to update all the quarters including where the previous checkpoint is and
                // the one where we are now
                for (uint256 i = 0; i < numQuarters; i++) {
                    StrategyPerQuarter storage newCheckpoint = strategyPerQuarter[_strategy][startingQuarter.add(i)];
                    uint256 slotEnding = START_TIME.add(startingQuarter.add(i).mul(EPOCH_DURATION));
                    if (i == 0) {
                        // We are in the first quarter to update, we add the proportional pending part
                        newCheckpoint.quarterPower = newCheckpoint.quarterPower.add(
                            data[4].mul(slotEnding.sub(data[1])).div(data[2])
                        );
                    } else if (i > 0 && i.add(1) < numQuarters) {
                        // We are updating an intermediate quarter
                        newCheckpoint.quarterPower = data[4].mul(EPOCH_DURATION).div(data[2]);
                        newCheckpoint.initialized = true;
                    } else {
                        // We are updating the current quarter of this strategy checkpoint
                        newCheckpoint.quarterPower = data[4]
                            .mul(block.timestamp.sub(START_TIME.add(data[3].mul(EPOCH_DURATION).sub(EPOCH_DURATION))))
                            .div(data[2]);
                    }
                }
            }
            strategyCheckpoint.initialized = true;
        } else {
            // We are in the same quarter than previous checkpoints for this strategy
            // We update the power of the quarter by adding the new difference between
            // last quarter checkpoint and this checkpoint
            strategyCheckpoint.quarterPower = strategyCheckpoint.quarterPower.add(data[4]);
        }
    }

    /**
     * Sends profits and BABL tokens rewards to an address (contributor or heart garden) after a claim is requested to the protocol.
     * @param _to        Address to send the BABL tokens to
     * @param _babl      Amount of BABL to send
     *
     */
    function _sendBABLToAddress(address _to, uint256 _babl) internal returns (uint256) {
        _onlyUnpaused();
        uint256 bablBal = babltoken.balanceOf(address(this));
        uint256 bablToSend = _babl > bablBal ? bablBal : _babl;
        _require(bablToSend <= (maxBablCap != 0 ? maxBablCap : DEFAULT_BABL_CAP), Errors.MAX_BABL_CAP_REACHED);
        SafeERC20.safeTransfer(babltoken, _to, bablToSend);
        return bablToSend;
    }

    /**
     * Set a customized profit rewards
     * @param _garden           Address of the garden
     * @param _strategistShare  New sharing profit % for strategist
     * @param _stewardsShare    New sharing profit % for stewards
     * @param _lpShare          New sharing profit % for lp
     */
    function _setProfitRewards(
        address _garden,
        uint256 _strategistShare,
        uint256 _stewardsShare,
        uint256 _lpShare
    ) internal {
        _require(_strategistShare.add(_stewardsShare).add(_lpShare) == 95e16, Errors.PROFIT_SHARING_MISMATCH);
        // [0]: _strategistProfit , [1]: _stewardsProfit, [2]: _lpProfit
        if (
            _strategistShare != strategistProfitPercentage ||
            _stewardsShare != stewardsProfitPercentage ||
            _lpShare != lpsProfitPercentage
        ) {
            // Different from standard %
            gardenCustomProfitSharing[_garden] = true;
            gardenProfitSharing[_garden][0] = _strategistShare;
            gardenProfitSharing[_garden][1] = _stewardsShare;
            gardenProfitSharing[_garden][2] = _lpShare;
        }
    }

    /* ========== Internal View functions ========== */

    /**
     * Get the price per token to be used in the adding or substraction normalized to DAI (supports multiple asset)
     * @param _reserveAsset     Garden reserve asset address
     * @param _strategy         Strategy address
     * @param _capital          Capital in reserve asset to add or substract
     * @param _addOrSubstract   Whether or not we are adding or unwinding capital to the strategy
     * @return pricePerToken value
     */
    function _getStrategyPricePerTokenUnit(
        address _reserveAsset,
        address _strategy,
        uint256 _capital,
        bool _addOrSubstract
    ) private returns (uint256) {
        // Normalizing into DAI
        IPriceOracle oracle = IPriceOracle(controller.priceOracle());
        uint256 pricePerTokenUnit = oracle.getPrice(_reserveAsset, DAI);
        StrategyPricePerTokenUnit storage strPpt = strategyPricePerTokenUnit[_strategy];
        if (strPpt.preallocated == 0) {
            // First adding checkpoint
            strPpt.preallocated = _capital;
            strPpt.pricePerTokenUnit = pricePerTokenUnit;
            return pricePerTokenUnit;
        } else {
            // We are controlling pair reserveAsset-DAI fluctuations along the time
            if (_addOrSubstract) {
                strPpt.pricePerTokenUnit = (
                    ((strPpt.pricePerTokenUnit.mul(strPpt.preallocated)).add(_capital.mul(pricePerTokenUnit))).div(1e18)
                )
                    .preciseDiv(strPpt.preallocated.add(_capital));
                strPpt.preallocated = strPpt.preallocated.add(_capital);
            } else {
                // We use the previous pricePerToken in a substract instead of a new price
                // (as allocated capital used previous prices not the current one)
                // Failsafe condition
                uint256 amount = _capital > strPpt.preallocated ? strPpt.preallocated : _capital;
                strPpt.preallocated = strPpt.preallocated.sub(amount);
            }
            return strPpt.pricePerTokenUnit;
        }
    }

    /* ========== Internal View functions ========== */

    /**
     * Get an estimation of user rewards for active strategies
     * @param _garden               Address of the garden
     * @param _strategy             Address of the strategy to estimate rewards
     * @param _strategist           Address of the strategist
     * @param _contributor          Address of the garden contributor
     * @param _contributorShare     Contributor share in a specific time
     * @param _strategyDetails      Details of the strategy in that specific moment
     * @param _profitData           Array of profit Data (if profit as well distance)
     * @return Array of size 8 with the following distribution:
     * rewards[0]: Strategist BABL
     * rewards[1]: Strategist Profit
     * rewards[2]: Steward BABL
     * rewards[3]: Steward Profit
     * rewards[4]: LP BABL
     * rewards[5]: total BABL
     * rewards[6]: total Profits
     * rewards[7]: Creator bonus
     */
    function _getRewardsPerRole(
        address _garden,
        address _strategy,
        address _strategist,
        address _contributor,
        uint256 _contributorShare,
        uint256[] memory _strategyDetails,
        bool[] memory _profitData
    ) internal view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](8);
        // Get strategist BABL rewards in case the contributor is also the strategist of the strategy
        rewards[0] = _strategist == _contributor ? _getStrategyStrategistBabl(_strategyDetails, _profitData) : 0;
        // Get strategist profit
        rewards[1] = (_strategist == _contributor && _profitData[0])
            ? _getStrategyStrategistProfits(_garden, _strategyDetails[10])
            : 0;
        // Get steward rewards
        rewards[2] = _getStrategyStewardBabl(_strategy, _contributor, _strategyDetails, _profitData);
        // If not profits _getStrategyStewardsProfits should not execute
        rewards[3] = _profitData[0]
            ? _getStrategyStewardProfits(_garden, _strategy, _contributor, _strategyDetails, _profitData)
            : 0;
        // Get LP rewards
        // Contributor share is fluctuating along the way in each new deposit
        rewards[4] = _getStrategyLPBabl(_strategyDetails[9], _contributorShare);
        // Total BABL including creator bonus (if any)
        rewards[5] = _getCreatorBonus(_garden, _contributor, rewards[0].add(rewards[2]).add(rewards[4]));
        // Total profit
        rewards[6] = rewards[1].add(rewards[3]);
        // Creator bonus
        rewards[7] = rewards[5] > (rewards[0].add(rewards[2]).add(rewards[4]))
            ? rewards[5].sub(rewards[0].add(rewards[2]).add(rewards[4]))
            : 0;
        return rewards;
    }

    /**
     * Guess the contributor power in a past timestamp (it is kept for smoother transition)
     * Will be deprecated soon, kept only for beta users and old strategies not migrated
     * Still used but only for betaUser && oldStrategy && users not migrated
     * @param _garden       Address of the garden where the contributor belongs to
     * @param _contributor  Address of the contributor
     * @param _time         Timestamp to check power
     * @return uint256      Contributor power during that period
     */
    function _getContributorPower(
        address _garden,
        address _contributor,
        uint256 _time,
        uint256 _gardenSupply
    ) internal view returns (uint256) {
        ContributorPerGarden storage contributor = contributorPerGarden[_garden][_contributor];
        GardenPowerByTimestamp storage gardenData = gardenPowerByTimestamp[_garden][0];
        if (contributor.initialDepositAt == 0 || contributor.initialDepositAt > _time) {
            return 0;
        } else {
            (, uint256 balance, ) = getPriorBalance(_garden, _contributor, contributor.lastDepositAt);
            uint256 supply = _gardenSupply > 0 ? _gardenSupply : ERC20(_garden).totalSupply();
            // First we need to get an updatedValue of user and garden power since lastDeposits as of block.timestamp
            uint256 updatedPower =
                contributor.tsContributions[0].power.add((block.timestamp.sub(contributor.lastDepositAt)).mul(balance));
            uint256 updatedGardenPower =
                gardenData.accGardenPower.add((block.timestamp.sub(gardenData.lastDepositAt)).mul(supply));
            // We then time travel back to when the strategy exitedAt
            // Calculate the power at "_time" timestamp
            uint256 timeDiff = block.timestamp.sub(_time);
            uint256 userPowerDiff = contributor.tsContributions[0].avgBalance.mul(timeDiff);
            uint256 gardenPowerDiff = gardenData.avgGardenBalance.mul(timeDiff);
            // Avoid underflow conditions 0 at user, 1 at garden
            updatedPower = updatedPower > userPowerDiff ? updatedPower.sub(userPowerDiff) : 0;
            updatedGardenPower = updatedGardenPower > gardenPowerDiff ? updatedGardenPower.sub(gardenPowerDiff) : 1;
            uint256 virtualPower = updatedPower.preciseDiv(updatedGardenPower);
            if (virtualPower > 1e18) {
                virtualPower = 1e18; // Overflow limit
            }
            return virtualPower;
        }
    }

    /**
     * Get a safe user share position within a strategy of a garden
     * @param _garden               Address of the garden
     * @param _contributor          Address of the garden contributor
     * @param _strData              Strategy data (executedAt, exitedAt and endingGardenSupply)
     * @return % deserved share per user
     */
    function _getSafeUserSharePerStrategy(
        address _garden,
        address _contributor,
        uint256[] memory _strData
    ) internal view returns (uint256) {
        // _strData[0] = executedAt
        // _strData[1] = exitedAt
        // _strData[13] = endingGardenSupply
        uint256 endTime = _strData[1] > 0 ? _strData[1] : block.timestamp;
        uint256 cp = numCheckpoints[_garden][_contributor];
        bool betaUser =
            !betaAddressMigrated[_contributor][_contributor] &&
                (cp == 0 || gardenCheckpoints[_garden][_contributor][0].fromTime >= endTime) &&
                contributorPerGarden[_garden][_contributor].initialDepositAt > 0;
        bool oldStrategy = _strData[0] < gardenPowerByTimestamp[_garden][0].lastDepositAt;
        if (betaUser && oldStrategy && !betaAddressMigrated[_garden][_garden]) {
            // Backward compatibility for old strategies
            return _getContributorPower(_garden, _contributor, endTime, _strData[13]);
        }
        // Take the closest position prior to _endTime
        (uint256 timestamp, uint256 balanceEnd, uint256 cpEnd) = getPriorBalance(_garden, _contributor, endTime);
        if (balanceEnd < 1e10) {
            // zero or dust balance
            // Avoid gas consuming
            return 0;
        }
        uint256 startTime = _strData[0];
        uint256 finalSupplyEnd = (_strData[1] > 0 && _strData[13] > 0) ? _strData[13] : ERC20(_garden).totalSupply();
        // At this point, all strategies must be started or even finished startTime != 0
        if (timestamp > startTime) {
            if (cp > 0) {
                // User has any checkpoint
                // If the user balance fluctuated during the strategy duration, we take real average balance
                uint256 avgBalance = _getAvgBalance(_garden, _contributor, startTime, cpEnd, endTime);
                // Avoid specific malicious attacks
                balanceEnd = avgBalance > balanceEnd ? balanceEnd : avgBalance;
            } else {
                // no checkpoints
                // if deposited before endTime, take proportional
                // if deposited after endTime, take nothing
                balanceEnd = timestamp < endTime
                    ? balanceEnd.mul(endTime.sub(timestamp)).div(endTime.sub(startTime))
                    : 0;
            }
        }
        return balanceEnd.preciseDiv(finalSupplyEnd);
    }

    /**
     * Get Avg Address Balance in a garden between two points
     * Address represents any user but it can also be the garden itself
     * @param _garden           Garden address
     * @param _address          Address to get avg balance
     * @param _start            Start timestamp
     * @param _cpEnd            End time checkpoint number
     * @param _endTime          End timestamp
     * @return Avg address token balance within a garden
     */
    function _getAvgBalance(
        address _garden,
        address _address,
        uint256 _start,
        uint256 _cpEnd,
        uint256 _endTime
    ) internal view returns (uint256) {
        (, uint256 prevBalance, uint256 cpStart) = getPriorBalance(_garden, _address, _start);
        if (_start == _endTime) {
            // Avoid underflow
            return prevBalance;
        } else {
            uint256 addressPower;
            uint256 timeDiff;
            // We calculate the avg balance of an address within a time range
            // avg balance = addressPower / total period considered
            // addressPower = sum(balance x time of each period between checkpoints)
            // Initializing addressPower since the last known checkpoint _endTime
            // addressPower since _cpEnd checkpoint is "balance x time difference (endTime - checkpoint timestamp)"
            addressPower = gardenCheckpoints[_garden][_address][_cpEnd].tokens.mul(
                _endTime.sub(gardenCheckpoints[_garden][_address][_cpEnd].fromTime)
            );
            // Then, we add addressPower data from periods between all intermediate checkpoints (if any)
            // periods between starting checkpoint and ending checkpoint (if any)
            // We go from the newest checkpoint to the oldest
            for (uint256 i = _cpEnd; i > cpStart; i--) {
                // We only take proportional addressPower of cpStart checkpoint (from _start onwards)
                // Usually [cpStart].fromTime <= _start except when cpStart == 0 AND beta addresses
                // Those cases are handled below to add previous address power happening before the first checkpoint
                Checkpoints memory userPrevCheckpoint = gardenCheckpoints[_garden][_address][i.sub(1)];
                timeDiff = gardenCheckpoints[_garden][_address][i].fromTime.sub(
                    userPrevCheckpoint.fromTime > _start ? userPrevCheckpoint.fromTime : _start
                );
                addressPower = addressPower.add(userPrevCheckpoint.tokens.mul(timeDiff));
            }
            // We now handle the previous addressPower of beta addresses (if applicable)
            uint256 fromTimeCp0 = gardenCheckpoints[_garden][_address][0].fromTime;
            if (cpStart == 0 && fromTimeCp0 > _start) {
                // Beta address with previous balance before _start
                addressPower = addressPower.add(prevBalance.mul(fromTimeCp0.sub(_start)));
            }
            // avg balance = addressPower / total period of the "strategy" considered
            return addressPower.div(_endTime.sub(_start));
        }
    }

    /**
     * Boost BABL Rewards in case of a staked NFT prophet
     * It considers a proportional % in case of staking happened after strategy execution
     * @param _garden           Garden address
     * @param _contributor      Contributor address
     * @param _rewards          Precalculated rewards array
     * @param _strategyDetails  Array with strategy context
     * @return Rewards array with boosted rewards (if any)
     */
    function _boostRewards(
        address _garden,
        address _contributor,
        uint256[] memory _rewards,
        uint256[] memory _strategyDetails
    ) internal view returns (uint256[] memory) {
        // _prophetBonus[0]: NFT id
        // _prophetBonus[1]: BABL loot
        // _prophetBonus[2]: strategist NFT bonus
        // _prophetBonus[3]: steward NFT bonus (voter)
        // _prophetBonus[4]: LP NFT bonus
        // _prophetBonus[5]: creator bonus
        // _prophetBonus[6]: stake NFT ts
        uint256[7] memory prophetBonus = PROPHETS_NFT.getStakedProphetAttrs(_contributor, _garden);
        // We calculate the percentage to apply or if any, depending on staking ts
        uint256 percentage = _getNFTPercentage(prophetBonus[6], _strategyDetails[0], _strategyDetails[1]);
        if (prophetBonus[0] != 0 && percentage > 0) {
            // Has staked a prophet in the garden before the strategy finished
            _rewards[0] = _rewards[0].add(_rewards[0].multiplyDecimal(prophetBonus[2].preciseMul(percentage)));
            _rewards[2] = _rewards[2].add(_rewards[2].multiplyDecimal(prophetBonus[3].preciseMul(percentage)));
            _rewards[4] = _rewards[4].add(_rewards[4].multiplyDecimal(prophetBonus[4].preciseMul(percentage)));
            _rewards[7] = _rewards[7].add(_rewards[7].multiplyDecimal(prophetBonus[5].preciseMul(percentage)));
            _rewards[5] = _rewards[0].add(_rewards[2]).add(_rewards[4]).add(_rewards[7]);
        }
        return _rewards;
    }

    /**
     * Get the percentage to apply the NFT prophet bonus, if any depending on staking ts
     * @param _stakedAt        Timestamp when the NFT was staked (if any)
     * @param _executedAt      Strategy executedAt timestamp
     * @param _exitedAt        Strategy exitedAt timestamp (it can be finished or not == 0)
     * @return the estimated proportional percentage to apply from NFT bonuses
     */
    function _getNFTPercentage(
        uint256 _stakedAt,
        uint256 _executedAt,
        uint256 _exitedAt
    ) internal view returns (uint256) {
        if (_stakedAt == 0) {
            // un-staked
            return 0;
        } else if (_stakedAt <= _executedAt && _executedAt > 0) {
            // NFT staked before the strategy was executed
            // gets 100% of Prophet bonuses
            return 1e18;
            // From this point stakeAt > executedAt
        } else if (_stakedAt < _exitedAt && _exitedAt > 0) {
            // NFT staked after the strategy was executed + strategy finished
            // gets proportional
            return (_exitedAt.sub(_stakedAt)).preciseDiv(_exitedAt.sub(_executedAt));
        } else if (_stakedAt < block.timestamp && _exitedAt == 0) {
            // Strategy still live
            // gets proportional
            return (block.timestamp.sub(_stakedAt)).preciseDiv(block.timestamp.sub(_executedAt));
        } else {
            // Strategy finalized before or in the same block than staking the NFT
            // NFT is not eligible then for this strategy
            return 0;
        }
    }

    /**
     * Get the rewards for a specific contributor activately contributing in strategies of a specific garden
     * @param _garden               Garden address responsible of the strategies to calculate rewards
     * @param _strategy             Strategy address
     * @param _contributor          Contributor address
     * @param _claimedAt            User last claim timestamp

     * @return Array of size 8 with the following distribution:
     * rewards[0]: Strategist BABL 
     * rewards[1]: Strategist Profit
     * rewards[2]: Steward BABL
     * rewards[3]: Steward Profit
     * rewards[4]: LP BABL
     * rewards[5]: Total BABL
     * rewards[6]: Total Profits
     * rewards[7]: Creator bonus
     */
    function _getStrategyProfitsAndBABL(
        address _garden,
        address _strategy,
        address _contributor,
        uint256 _claimedAt
    ) private view returns (uint256[] memory) {
        uint256[] memory rewards = new uint256[](8);
        (address strategist, uint256[] memory strategyDetails, bool[] memory profitData) =
            IStrategy(_strategy).getStrategyRewardsContext();

        // strategyDetails array mapping:
        // strategyDetails[0]: executedAt
        // strategyDetails[1]: exitedAt
        // strategyDetails[2]: updatedAt
        // strategyDetails[3]: enteredAt
        // strategyDetails[4]: totalPositiveVotes
        // strategyDetails[5]: totalNegativeVotes
        // strategyDetails[6]: capitalAllocated
        // strategyDetails[7]: capitalReturned
        // strategyDetails[8]: expectedReturn
        // strategyDetails[9]: strategyRewards
        // strategyDetails[10]: profitValue
        // strategyDetails[11]: distanceValue
        // strategyDetails[12]: startingGardenSupply
        // strategyDetails[13]: endingGardenSupply
        // profitData array mapping:
        // profitData[0]: profit
        // profitData[1]: distance

        // Positive strategies not yet claimed
        // Users might get BABL rewards if they join the garden before the strategy ends
        // Contributor power will check their exact contribution (avoiding flashloans)
        if (strategyDetails[1] > _claimedAt) {
            // Get the contributor share until the the strategy exit timestamp
            uint256 contributorShare = _getSafeUserSharePerStrategy(_garden, _contributor, strategyDetails);
            rewards = _getRewardsPerRole(
                _garden,
                _strategy,
                strategist,
                _contributor,
                contributorShare,
                strategyDetails,
                profitData
            );
            // add Prophets NFT bonus if staked in the garden
            rewards = _boostRewards(_garden, _contributor, rewards, strategyDetails);
        }
        return rewards;
    }

    /**
     * Get the BABL rewards (Mining program) for a Steward profile
     * @param _strategy             Strategy address
     * @param _contributor          Contributor address
     * @param _strategyDetails      Strategy details data
     * @param _profitData           Strategy profit data
     */
    function _getStrategyStewardBabl(
        address _strategy,
        address _contributor,
        uint256[] memory _strategyDetails,
        bool[] memory _profitData
    ) private view returns (uint256) {
        // Assumptions:
        // It executes in all cases as non profited strategies can also give BABL rewards to those who voted against

        int256 userVotes = IStrategy(_strategy).getUserVotes(_contributor);
        uint256 totalVotes = _strategyDetails[4].add(_strategyDetails[5]);

        uint256 bablCap;
        // Get proportional voter (stewards) rewards in case the contributor was also a steward of the strategy
        uint256 babl;
        if (userVotes > 0 && _profitData[0] && _profitData[1]) {
            // Voting in favor of the execution of the strategy with profits and positive distance
            // Negative votes in this case will not receive BABL so we divide only by positive votes
            babl = _strategyDetails[9].multiplyDecimal(stewardsBABLPercentage).preciseMul(
                uint256(userVotes).preciseDiv(_strategyDetails[4])
            );
        } else if (userVotes > 0 && _profitData[0] && !_profitData[1]) {
            // Voting in favor positive profits but below expected return
            babl = _strategyDetails[9].multiplyDecimal(stewardsBABLPercentage).preciseMul(
                uint256(userVotes).preciseDiv(totalVotes)
            );
            // We discount the error of expected return vs real returns
            babl = babl.sub(babl.preciseMul(_strategyDetails[11].preciseDiv(_strategyDetails[8])));
        } else if (userVotes > 0 && !_profitData[0]) {
            // Voting in favor of a non profitable strategy get nothing
            babl = 0;
        } else if (userVotes < 0 && !_profitData[1]) {
            // Voting against a strategy that got results below expected return provides rewards
            // to the voter (helping the protocol to only have good strategies)
            // If no profit at all, the whole steward benefit goes to those voting against
            uint256 votesAccounting = _profitData[0] ? totalVotes : _strategyDetails[5];
            babl = _strategyDetails[9].multiplyDecimal(stewardsBABLPercentage).preciseMul(
                uint256(Math.abs(userVotes)).preciseDiv(votesAccounting)
            );

            bablCap = babl.mul(2); // Max cap
            // We add a bonus inverse to the error of expected return vs real returns
            babl = babl.add(babl.preciseMul(_strategyDetails[11].preciseDiv(_strategyDetails[8])));
            if (babl > bablCap) {
                // We limit 2x by a Cap
                babl = bablCap;
            }
        } else if (userVotes < 0 && _profitData[1]) {
            babl = 0;
        }
        return babl;
    }

    /**
     * Get the rewards for a Steward profile
     * @param _garden           Garden address
     * @param _strategy         Strategy address
     * @param _contributor      Contributor address
     * @param _strategyDetails  Strategy details data
     * @param _profitData       Strategy profit data
     */
    function _getStrategyStewardProfits(
        address _garden,
        address _strategy,
        address _contributor,
        uint256[] memory _strategyDetails,
        bool[] memory _profitData
    ) private view returns (uint256 stewardBabl) {
        // Assumptions:
        // Assumption that the strategy got profits. Should not execute otherwise.
        // Get proportional voter (stewards) rewards in case the contributor was also a steward of the strategy
        int256 userVotes = IStrategy(_strategy).getUserVotes(_contributor);
        uint256 totalVotes = _strategyDetails[4].add(_strategyDetails[5]);

        uint256 profitShare =
            gardenCustomProfitSharing[_garden] ? gardenProfitSharing[_garden][1] : stewardsProfitPercentage;
        if (userVotes > 0) {
            // If the strategy got profits equal or above expected return only positive votes counts,
            // so we divide by only positive
            // Otherwise, we divide by all total votes as also voters against will get some profits
            // if the strategy returned less than expected
            uint256 accountingVotes = _profitData[1] ? _strategyDetails[4] : totalVotes;
            stewardBabl = _strategyDetails[10].multiplyDecimal(profitShare).preciseMul(uint256(userVotes)).preciseDiv(
                accountingVotes
            );
        } else if ((userVotes < 0) && !_profitData[1]) {
            stewardBabl = _strategyDetails[10]
                .multiplyDecimal(profitShare)
                .preciseMul(uint256(Math.abs(userVotes)))
                .preciseDiv(totalVotes);
        } else if ((userVotes < 0) && _profitData[1]) {
            // Voted against a very profit strategy above expected returns, get no profit at all
            stewardBabl = 0;
        }
    }

    /**
     * Get the BABL rewards (Mining program) for a Strategist profile
     * @param _strategyDetails          Strategy details data
     * @param _profitData               Strategy details data
     */
    function _getStrategyStrategistBabl(uint256[] memory _strategyDetails, bool[] memory _profitData)
        private
        view
        returns (uint256)
    {
        // Assumptions:
        // We assume that the contributor is the strategist. Should not execute this function otherwise.
        uint256 babl;
        babl = _strategyDetails[9].multiplyDecimal(strategistBABLPercentage); // Standard calculation to be ponderated
        if (_profitData[0] && _profitData[1]) {
            uint256 bablCap = babl.mul(2); // Cap x2
            // Strategist get a bonus based on the profits with a max cap of x2
            babl = babl.preciseMul(_strategyDetails[7].preciseDiv(_strategyDetails[6]));
            if (babl > bablCap) {
                babl = bablCap;
            }
            return babl;
        } else if (_profitData[0] && !_profitData[1]) {
            // under expectations
            // The more the results are close to the expected the less penalization it might have
            return babl.sub(babl.sub(babl.preciseMul(_strategyDetails[7].preciseDiv(_strategyDetails[8]))));
        } else {
            // No positive profit, no BABL assigned to the strategist role
            return 0;
        }
    }

    /**
     * Get the rewards for a Strategist profile
     * @param _garden           Garden address
     * @param _profitValue      Strategy profit value
     */
    function _getStrategyStrategistProfits(address _garden, uint256 _profitValue) private view returns (uint256) {
        // Assumptions:
        // Only executes if the contributor was the strategist of the strategy
        // AND the strategy had profits
        uint256 profitShare =
            gardenCustomProfitSharing[_garden] ? gardenProfitSharing[_garden][0] : strategistProfitPercentage;
        return _profitValue.multiplyDecimal(profitShare);
    }

    /**
     * Get the BABL rewards (Mining program) for a LP profile
     * @param _strategyRewards      Strategy rewards
     * @param _contributorShare     Contributor share in the period
     */
    function _getStrategyLPBabl(uint256 _strategyRewards, uint256 _contributorShare) private view returns (uint256) {
        uint256 babl;
        // All params must have 18 decimals precision
        babl = _strategyRewards.multiplyDecimal(lpsBABLPercentage).preciseMul(_contributorShare);
        return babl;
    }

    /**
     * Calculates the BABL rewards supply for each quarter
     * @param _quarter      Number of the epoch (quarter)
     */
    function _tokenSupplyPerQuarter(uint256 _quarter) internal pure returns (uint256) {
        _require(_quarter >= 1, Errors.QUARTERS_MIN_1);
        if (_quarter >= 513) {
            return 0; // Avoid math overflow
        } else {
            uint256 firstFactor = (SafeDecimalMath.unit().add(DECAY_RATE)).powDecimal(_quarter.sub(1));
            return Q1_REWARDS.divideDecimal(firstFactor);
        }
    }

    /**
     * Calculates the quarter number for a specific time since START_TIME
     * @param _now      Timestamp to calculate its quarter
     */
    function _getQuarter(uint256 _now) internal view returns (uint256) {
        // Avoid underflow for active strategies during mining activation
        uint256 quarter = _now >= START_TIME ? (_now.sub(START_TIME).preciseDivCeil(EPOCH_DURATION)).div(1e18) : 0;
        return quarter.add(1);
    }

    /**
     * Calculates the range (starting quarter and ending quarter since START_TIME)
     * @param _from   Starting timestamp
     * @param _to     Ending timestamp
     */
    function _getRewardsWindow(uint256 _from, uint256 _to) internal view returns (uint256, uint256) {
        // Avoid underflow for active strategies during mining activation
        if (_from < START_TIME) {
            _from = START_TIME;
        }
        uint256 quarters = (_to.sub(_from).preciseDivCeil(EPOCH_DURATION)).div(1e18);

        uint256 startingQuarter = (_from.sub(START_TIME).preciseDivCeil(EPOCH_DURATION)).div(1e18);
        uint256 endingQuarter = (_to.sub(START_TIME).preciseDivCeil(EPOCH_DURATION)).div(1e18);

        if (
            startingQuarter != endingQuarter &&
            endingQuarter == startingQuarter.add(1) &&
            _to.sub(_from) < EPOCH_DURATION
        ) {
            quarters = quarters.add(1);
        }
        return (quarters.add(1), startingQuarter.add(1));
    }

    /**
     * Gives creator bonus to the user and returns original + bonus
     * @param _garden               Address of the garden
     * @param _contributor          Address of the contributor
     * @param _contributorBABL      BABL obtained in the strategy
     */
    function _getCreatorBonus(
        address _garden,
        address _contributor,
        uint256 _contributorBABL
    ) private view returns (uint256) {
        IGarden garden = IGarden(_garden);
        bool isCreator = garden.creator() == _contributor;
        uint8 creatorCount = garden.creator() != address(0) ? 1 : 0;
        for (uint8 i = 0; i < 4; i++) {
            address _extraCreator = garden.extraCreators(i);
            if (_extraCreator != address(0)) {
                creatorCount++;
                isCreator = isCreator || _extraCreator == _contributor;
            }
        }
        // Get a multiplier bonus in case the contributor is the garden creator
        if (creatorCount == 0) {
            // If there is no creator divide the creator bonus across al members
            return
                _contributorBABL.add(
                    _contributorBABL.multiplyDecimal(gardenCreatorBonus).div(IGarden(_garden).totalContributors())
                );
        } else {
            if (isCreator) {
                // Check other creators and divide by number of creators or members if creator address is 0
                return _contributorBABL.add(_contributorBABL.multiplyDecimal(gardenCreatorBonus).div(creatorCount));
            }
        }
        return _contributorBABL;
    }

    /**
     * Get an estimation of strategy BABL rewards for active strategies in the mining program
     * @param _strategy        Address of the strategy to estimate BABL rewards
     * Returns the strategist, strategyDetails needed as well as profit data
     */
    function _estimateStrategyRewards(address _strategy)
        internal
        view
        returns (
            address strategist,
            uint256[] memory strategyDetails,
            bool[] memory profitData
        )
    {
        // strategyDetails array mapping:
        // strategyDetails[0]: executedAt
        // strategyDetails[1]: exitedAt
        // strategyDetails[2]: updatedAt
        // strategyDetails[3]: enteredAt
        // strategyDetails[4]: totalPositiveVotes
        // strategyDetails[5]: totalNegativeVotes
        // strategyDetails[6]: capitalAllocated
        // strategyDetails[7]: capitalReturned
        // strategyDetails[8]: expectedReturn
        // strategyDetails[9]: strategyRewards
        // strategyDetails[10]: profitValue
        // strategyDetails[11]: distanceValue
        // strategyDetails[12]: startingGardenSupply
        // strategyDetails[13]: endingGardenSupply
        // strategyDetails[14]: maxTradeSlippagePercentage
        // profitData array mapping:
        // profitData[0]: profit
        // profitData[1]: distance

        (strategist, strategyDetails, profitData) = IStrategy(_strategy).getStrategyRewardsContext();
        if (strategyDetails[9] != 0 || strategyDetails[0] == 0) {
            // Already finished and got rewards or not executed yet (not active)
            return (strategist, strategyDetails, profitData);
        }
        // Strategy has not finished yet, lets try to estimate its mining rewards
        // As the strategy has not ended we replace the capital returned value by the NAV
        uint256 strategyNav = IStrategy(_strategy).getNAV();
        // We estimate final returns substracting slippage
        strategyDetails[7] = strategyNav.sub(strategyNav.preciseMul(strategyDetails[14]));
        profitData[0] = strategyDetails[7] >= strategyDetails[6];
        profitData[1] = strategyDetails[7] >= strategyDetails[8];
        strategyDetails[10] = profitData[0] ? strategyDetails[7].sub(strategyDetails[6]) : 0; // no profit
        // We consider that it potentially will have profits so the protocol will take profitFee
        // If 0 it does nothing
        strategyDetails[11] = profitData[1]
            ? strategyDetails[7].sub(strategyDetails[8])
            : strategyDetails[8].sub(strategyDetails[7]);
        // We take care about beta live strategies as they have a different start mining time != executedAt
        (uint256 numQuarters, uint256 startingQuarter) =
            _getRewardsWindow(
                (
                    (strategyDetails[0] > START_TIME)
                        ? strategyDetails[0]
                        : strategyPerQuarter[_strategy][1].betaInitializedAt
                ),
                block.timestamp
            );
        // We create an array of quarters since the begining of the strategy
        // We then fill with known + unknown data that has to be figured out
        uint256[] memory strategyPower = new uint256[](numQuarters);
        uint256[] memory protocolPower = new uint256[](numQuarters);
        for (uint256 i = 0; i < numQuarters; i++) {
            // We take the info of each epoch from current checkpoints
            // array[0] for the first quarter power checkpoint of the strategy
            strategyPower[i] = strategyPerQuarter[_strategy][startingQuarter.add(i)].quarterPower;
            protocolPower[i] = protocolPerQuarter[startingQuarter.add(i)].quarterPower;
            _require(strategyPower[i] <= protocolPower[i], Errors.OVERFLOW_IN_POWER);
        }
        strategyPower = _updatePendingPower(
            strategyPower,
            numQuarters,
            startingQuarter,
            strategyDetails[2],
            strategyPrincipal[_strategy]
        );
        protocolPower = _updatePendingPower(
            protocolPower,
            numQuarters,
            startingQuarter,
            miningUpdatedAt,
            miningProtocolPrincipal
        );
        strategyDetails[9] = _getBenchmarkRewards(
            strategyDetails[7],
            strategyDetails[6],
            _harvestStrategyRewards(strategyPower, protocolPower, startingQuarter, numQuarters),
            strategyDetails[0],
            _strategy
        );
    }

    /**
     * Harvest rewards of all epochs during estimation for each strategy
     * @param _strategyPower        Accumulated strategy power per epoch
     * @param _protocolPower        Accumulated protocol power per epoch
     * @param _startingQuarter      Starting quarter for calculations
     * @param _numQuarters          Total number of quarters for the calculation
     * @return the baseline estimated rewards for the strategy
     */
    function _harvestStrategyRewards(
        uint256[] memory _strategyPower,
        uint256[] memory _protocolPower,
        uint256 _startingQuarter,
        uint256 _numQuarters
    ) internal view returns (uint256) {
        uint256 strategyRewards;
        uint256 percentage = 1e18;
        for (uint256 i = 0; i < _numQuarters; i++) {
            if (i.add(1) == _numQuarters) {
                // last quarter - we need to take proportional supply for that timeframe despite
                // the epoch has not finished yet
                uint256 slotEnding = START_TIME.add(_startingQuarter.add(i).mul(EPOCH_DURATION));
                percentage = block.timestamp.sub(slotEnding.sub(EPOCH_DURATION)).preciseDiv(
                    slotEnding.sub(slotEnding.sub(EPOCH_DURATION))
                );
            }
            uint256 rewardsPerQuarter =
                _strategyPower[i]
                    .preciseDiv(_protocolPower[i] == 0 ? 1 : _protocolPower[i])
                    .preciseMul(_tokenSupplyPerQuarter(_startingQuarter.add(i)))
                    .preciseMul(percentage);
            strategyRewards = strategyRewards.add(rewardsPerQuarter);
        }
        return strategyRewards;
    }

    /**
     * Apply specific BABL mining weights to baseline BABL mining rewards based on mining benchmark params
     * Benchmark creates 3 different segments to differentiate between bad, break even or good strategies
     * @param _returned           Strategy capital returned
     * @param _allocated          Strategy capital allocated
     * @param _rewards            Strategy baseline BABL rewards
     * @param _executedAt         Strategy timestamp of initial execution
     */
    function _getBenchmarkRewards(
        uint256 _returned,
        uint256 _allocated,
        uint256 _rewards,
        uint256 _executedAt,
        address _strategy
    ) private view returns (uint256) {
        uint256 rewardsFactor;
        // Real time profit
        uint256 percentageProfit = _returned.preciseDiv(_allocated);
        if (address(IStrategy(_strategy).garden()) == address(IHeart(controller.heart()).heartGarden())) {
            // Any heart garden strategy get boosted by 150%
            rewardsFactor = 15e17;
        } else {
            // We categorize the strategy APY profits into one of the 3 segments (very bad, regular and cool strategies)
            // Bad and regular will be penalized from bigger penalization to lower
            // Cool strategies will be boosted
            // As we get real time profit (returned / allocated) we need to annualize the strategy profits (APY)
            // Time weighted profit if > 1e18 duration less than 1 year, < 1e18 longer than 1 year
            uint256 timedAPY =
                uint256(365 days).preciseDiv(block.timestamp > _executedAt ? block.timestamp.sub(_executedAt) : 1);
            uint256 returnedAPY; // initialization for absolute return APY (in reserve asset decimals)
            if (percentageProfit >= 1e18) {
                // Strategy is on positive profit
                // We calculate expected absolute returns in reserve asset decimals
                // If strategy is less than 1 year, APY earnings will be higher
                // else, APY earnings will be lower than today (we need to estimate annualized earnings)
                returnedAPY = _allocated.add(_returned.sub(_allocated).preciseMul(timedAPY));
            } else {
                // Strategy is in loss
                // We calculate expected absolute returns in reserve asset decimals
                // If strategy is less than 1 year, APY loses will be higher
                // else, APY loses will be lower than today (we need to estimate annualized loses)
                returnedAPY = _allocated.sub(_returned).preciseMul(timedAPY);
                returnedAPY = returnedAPY < _allocated ? _allocated.sub(returnedAPY) : 0;
            }
            // Now we normalize into 18 decimals the estimated APY profit percentage using expected return APY
            uint256 profitAPY = returnedAPY.preciseDiv(_allocated);
            // TODO: Replace _allocated by avgCapitalAllocated to handle adding or removing capital from strategy
            // with lower impact along the time
            if (profitAPY < benchmark[0]) {
                // Segment 1:
                // Bad strategy, usually gets penalty by benchmark[2] factor
                rewardsFactor = benchmark[2];
            } else if (profitAPY < benchmark[1]) {
                // Segment 2:
                // Not a cool strategy, can get penalty by benchmark[3] factor
                rewardsFactor = benchmark[3];
            } else {
                // Segment 3:
                // A real cool strategy, can get boost by benchmark[4] factor. Must be always >= 1e18
                rewardsFactor = benchmark[4];
            }
        }
        return
            _rewards.preciseMul(bablPrincipalWeight).add(
                _rewards.preciseMul(bablProfitWeight).preciseMul(percentageProfit).preciseMul(rewardsFactor)
            );
    }

    /**
     * Update pending power for each strategy and epoch during estimation
     * @param _powerToUpdate        Current power to be updated per epoch (power is principal x time)
     * @param _numQuarters          Total number of quarters for the calculation
     * @param _startingQuarter      Starting quarter (epoch)
     * @param _updatedAt            Updated timestamp
     * @param _principal            Principal of the strategy or protocol to update power
     * @return the updating power
     */
    function _updatePendingPower(
        uint256[] memory _powerToUpdate,
        uint256 _numQuarters,
        uint256 _startingQuarter,
        uint256 _updatedAt,
        uint256 _principal
    ) internal view returns (uint256[] memory) {
        uint256 lastQuarter = _getQuarter(_updatedAt); // quarter of last update
        uint256 currentQuarter = _getQuarter(block.timestamp); // current quarter
        uint256 timeDiff = block.timestamp.sub(_updatedAt); // 1sec to avoid division by zero
        // We check the pending power to be accounted until now, since last update for protocol and strategy
        uint256 powerDebt = _principal.mul(timeDiff);
        if (powerDebt > 0) {
            for (uint256 i = 0; i < _numQuarters; i++) {
                uint256 slotEnding = START_TIME.add(_startingQuarter.add(i).mul(EPOCH_DURATION));
                if (i == 0 && lastQuarter == _startingQuarter && lastQuarter < currentQuarter) {
                    // We are in the first quarter to update, we add the proportional pending part
                    _powerToUpdate[i] = _powerToUpdate[i].add(powerDebt.mul(slotEnding.sub(_updatedAt)).div(timeDiff));
                } else if (i > 0 && i.add(1) < _numQuarters && lastQuarter <= _startingQuarter.add(i)) {
                    // We are updating an intermediate quarter
                    // Should have 0 inside before updating
                    _powerToUpdate[i] = _powerToUpdate[i].add(powerDebt.mul(EPOCH_DURATION).div(timeDiff));
                } else if (_startingQuarter.add(i) == currentQuarter) {
                    // We are updating the current quarter of this strategy checkpoint or the last to update
                    // It can be a multiple quarter strategy or the only one that need proportional time
                    if (lastQuarter == currentQuarter) {
                        // Just add the powerDebt being in the same epoch, no need to get proportional
                        _powerToUpdate[i] = _powerToUpdate[i].add(powerDebt);
                    } else {
                        // should have 0 inside before updating in case of different epoch since last update
                        _powerToUpdate[i] = _powerToUpdate[i].add(
                            powerDebt.mul(block.timestamp.sub(slotEnding.sub(EPOCH_DURATION))).div(timeDiff)
                        );
                    }
                }
            }
        }
        return _powerToUpdate;
    }
}

contract RewardsDistributorV17 is RewardsDistributor {}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBabController} from '../interfaces/IBabController.sol';
import {TimeLockRegistry} from './TimeLockRegistry.sol';
import {IRewardsDistributor} from '../interfaces/IRewardsDistributor.sol';
import {VoteToken} from './VoteToken.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Errors, _require} from '../lib/BabylonErrors.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {IBabController} from '../interfaces/IBabController.sol';

/**
 * @title TimeLockedToken
 * @notice Time Locked ERC20 Token
 * @author Babylon Finance
 * @dev Contract which gives the ability to time-lock tokens specially for vesting purposes usage
 *
 * By overriding the balanceOf() and transfer() functions in ERC20,
 * an account can show its full, post-distribution balance and use it for voting power
 * but only transfer or spend up to an allowed amount
 *
 * A portion of previously non-spendable tokens are allowed to be transferred
 * along the time depending on each vesting conditions, and after all epochs have passed, the full
 * account balance is unlocked. In case on non-completion vesting period, only the Time Lock Registry can cancel
 * the delivery of the pending tokens and only can cancel the remaining locked ones.
 */

abstract contract TimeLockedToken is VoteToken {
    using LowGasSafeMath for uint256;

    /* ============ Events ============ */

    /// @notice An event that emitted when a new lockout ocurr
    event NewLockout(
        address account,
        uint256 tokenslocked,
        bool isTeamOrAdvisor,
        uint256 startingVesting,
        uint256 endingVesting
    );

    /// @notice An event that emitted when a new Time Lock is registered
    event NewTimeLockRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a new Rewards Distributor is registered
    event NewRewardsDistributorRegistration(address previousAddress, address newAddress);

    /// @notice An event that emitted when a cancellation of Lock tokens is registered
    event Cancel(address account, uint256 amount);

    /// @notice An event that emitted when a claim of tokens are registered
    event Claim(address _receiver, uint256 amount);

    /// @notice An event that emitted when a lockedBalance query is done
    event LockedBalance(address _account, uint256 amount);

    /* ============ Modifiers ============ */

    modifier onlyTimeLockRegistry() {
        require(
            msg.sender == address(timeLockRegistry),
            'TimeLockedToken:: onlyTimeLockRegistry: can only be executed by TimeLockRegistry'
        );
        _;
    }

    modifier onlyTimeLockOwner() {
        if (address(timeLockRegistry) != address(0)) {
            require(
                msg.sender == Ownable(timeLockRegistry).owner(),
                'TimeLockedToken:: onlyTimeLockOwner: can only be executed by the owner of TimeLockRegistry'
            );
        }
        _;
    }
    modifier onlyUnpaused() {
        // Do not execute if Globally or individually paused
        _require(!IBabController(controller).isPaused(address(this)), Errors.ONLY_UNPAUSED);
        _;
    }

    /* ============ State Variables ============ */

    // represents total distribution for locked balances
    mapping(address => uint256) distribution;

    /// @notice The profile of each token owner under its particular vesting conditions
    /**
     * @param team Indicates whether or not is a Team member or Advisor (true = team member/advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct VestedToken {
        bool teamOrAdvisor;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => VestedToken) public vestedToken;

    // address of Time Lock Registry contract
    IBabController public controller;

    // address of Time Lock Registry contract
    TimeLockRegistry public timeLockRegistry;

    // address of Rewards Distriburor contract
    IRewardsDistributor public rewardsDistributor;

    // Enable Transfer of ERC20 BABL Tokens
    // Only Minting or transfers from/to TimeLockRegistry and Rewards Distributor can transfer tokens until the protocol is fully decentralized
    bool private tokenTransfersEnabled;
    bool private tokenTransfersWereDisabled;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) VoteToken(_name, _symbol) {
        tokenTransfersEnabled = true;
    }

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disables transfers of ERC20 BABL Tokens
     */
    function disableTokensTransfers() external onlyOwner {
        require(!tokenTransfersWereDisabled, 'BABL must flow');
        tokenTransfersEnabled = false;
        tokenTransfersWereDisabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Allows transfers of ERC20 BABL Tokens
     * Can only happen after the protocol is fully decentralized.
     */
    function enableTokensTransfers() external onlyOwner {
        tokenTransfersEnabled = true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Time Lock Registry contract to control token vesting conditions
     *
     * @notice Set the Time Lock Registry contract to control token vesting conditions
     * @param newTimeLockRegistry Address of TimeLockRegistry contract
     */
    function setTimeLockRegistry(TimeLockRegistry newTimeLockRegistry) external onlyTimeLockOwner returns (bool) {
        require(address(newTimeLockRegistry) != address(0), 'cannot be zero address');
        require(address(newTimeLockRegistry) != address(this), 'cannot be this contract');
        require(address(newTimeLockRegistry) != address(timeLockRegistry), 'must be new TimeLockRegistry');
        emit NewTimeLockRegistration(address(timeLockRegistry), address(newTimeLockRegistry));

        timeLockRegistry = newTimeLockRegistry;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Set the Rewards Distributor contract to control either BABL Mining or profit rewards
     *
     * @notice Set the Rewards Distriburor contract to control both types of rewards (profit and BABL Mining program)
     * @param newRewardsDistributor Address of Rewards Distributor contract
     */
    function setRewardsDistributor(IRewardsDistributor newRewardsDistributor) external onlyOwner returns (bool) {
        require(address(newRewardsDistributor) != address(0), 'cannot be zero address');
        require(address(newRewardsDistributor) != address(this), 'cannot be this contract');
        require(address(newRewardsDistributor) != address(rewardsDistributor), 'must be new Rewards Distributor');
        emit NewRewardsDistributorRegistration(address(rewardsDistributor), address(newRewardsDistributor));

        rewardsDistributor = newRewardsDistributor;

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Register new token lockup conditions for vested tokens defined only by Time Lock Registry
     *
     * @notice Tokens are completely delivered during the registration however lockup conditions apply for vested tokens
     * locking them according to the distribution epoch periods and the type of recipient (Team, Advisor, Investor)
     * Emits a transfer event showing a transfer to the recipient
     * Only the registry can call this function
     * @param _receiver Address to receive the tokens
     * @param _amount Tokens to be transferred
     * @param _profile True if is a Team Member or Advisor
     * @param _vestingBegin Unix Time when the vesting for that particular address
     * @param _vestingEnd Unix Time when the vesting for that particular address
     * @param _lastClaim Unix Time when the claim was done from that particular address
     *
     */
    function registerLockup(
        address _receiver,
        uint256 _amount,
        bool _profile,
        uint256 _vestingBegin,
        uint256 _vestingEnd,
        uint256 _lastClaim
    ) external onlyTimeLockRegistry returns (bool) {
        require(balanceOf(msg.sender) >= _amount, 'insufficient balance');
        require(_receiver != address(0), 'cannot be zero address');
        require(_receiver != address(this), 'cannot be this contract');
        require(_receiver != address(timeLockRegistry), 'cannot be the TimeLockRegistry contract itself');
        require(_receiver != msg.sender, 'the owner cannot lockup itself');

        // update amount of locked distribution
        distribution[_receiver] = distribution[_receiver].add(_amount);

        VestedToken storage newVestedToken = vestedToken[_receiver];

        newVestedToken.teamOrAdvisor = _profile;
        newVestedToken.vestingBegin = _vestingBegin;
        newVestedToken.vestingEnd = _vestingEnd;
        newVestedToken.lastClaim = _lastClaim;

        // transfer tokens to the recipient
        _transfer(msg.sender, _receiver, _amount);
        emit NewLockout(_receiver, _amount, _profile, _vestingBegin, _vestingEnd);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors as it does not apply to investors.
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function cancelVestedTokens(address lockedAccount) external onlyTimeLockRegistry returns (uint256) {
        return _cancelVestedTokensFromTimeLock(lockedAccount);
    }

    /**
     * GOVERNANCE FUNCTION. Each token owner can claim its own specific tokens with its own specific vesting conditions from the Time Lock Registry
     *
     * @dev Claim msg.sender tokens (if any available in the registry)
     */
    function claimMyTokens() external {
        // claim msg.sender tokens from timeLockRegistry
        uint256 amount = timeLockRegistry.claim(msg.sender);
        // After a proper claim, locked tokens of Team and Advisors profiles are under restricted special vesting conditions so they automatic grant
        // rights to the Time Lock Registry to only retire locked tokens if non-compliance vesting conditions take places along the vesting periods.
        // It does not apply to Investors under vesting (their locked tokens cannot be removed).
        if (vestedToken[msg.sender].teamOrAdvisor == true) {
            approve(address(timeLockRegistry), amount);
        }
        // emit claim event
        emit Claim(msg.sender, amount);
    }

    /**
     * GOVERNANCE FUNCTION. Get unlocked balance for an account
     *
     * @notice Get unlocked balance for an account
     * @param account Account to check
     * @return Amount that is unlocked and available eg. to transfer
     */
    function unlockedBalance(address account) public returns (uint256) {
        // totalBalance - lockedBalance
        return balanceOf(account).sub(lockedBalance(account));
    }

    /**
     * GOVERNANCE FUNCTION. View the locked balance for an account
     *
     * @notice View locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */

    function viewLockedBalance(address account) public view returns (uint256) {
        // distribution of locked tokens
        // get amount from distributions

        uint256 amount = distribution[account];
        uint256 lockedAmount = amount;

        // Team and investors cannot transfer tokens in the first year
        if (vestedToken[account].vestingBegin.add(365 days) > block.timestamp && amount != 0) {
            return lockedAmount;
        }

        // in case of vesting has passed, all tokens are now available, if no vesting lock is 0 as well
        if (block.timestamp >= vestedToken[account].vestingEnd || amount == 0) {
            lockedAmount = 0;
        } else if (amount != 0) {
            // in case of still under vesting period, locked tokens are recalculated
            lockedAmount = amount.mul(vestedToken[account].vestingEnd.sub(block.timestamp)).div(
                vestedToken[account].vestingEnd.sub(vestedToken[account].vestingBegin)
            );
        }
        return lockedAmount;
    }

    /**
     * GOVERNANCE FUNCTION. Get locked balance for an account
     *
     * @notice Get locked balance for an account
     * @param account Account to check
     * @return Amount locked in the time of checking
     */
    function lockedBalance(address account) public returns (uint256) {
        // get amount from distributions locked tokens (if any)
        uint256 lockedAmount = viewLockedBalance(account);
        // in case of vesting has passed, all tokens are now available so we set mapping to 0 only for accounts under vesting
        if (
            block.timestamp >= vestedToken[account].vestingEnd &&
            msg.sender == account &&
            lockedAmount == 0 &&
            vestedToken[account].vestingEnd != 0
        ) {
            delete distribution[account];
        }
        emit LockedBalance(account, lockedAmount);
        return lockedAmount;
    }

    /**
     * PUBLIC FUNCTION. Get the address of Time Lock Registry
     *
     * @notice Get the address of Time Lock Registry
     * @return Address of the Time Lock Registry
     */
    function getTimeLockRegistry() external view returns (address) {
        return address(timeLockRegistry);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Approval of allowances of ERC20 with special conditions for vesting
     *
     * @notice Override of "Approve" function to allow the `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender` except in the case of spender is Time Lock Registry
     * and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint256 rawAmount) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::approve: spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::approve: spender cannot be the msg.sender');

        uint96 amount;
        if (rawAmount == uint256(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, 'TimeLockedToken::approve: amount exceeds 96 bits');
        }

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        if ((spender == address(timeLockRegistry)) && (amount < allowance(msg.sender, address(timeLockRegistry)))) {
            amount = safe96(
                allowance(msg.sender, address(timeLockRegistry)),
                'TimeLockedToken::approve: cannot decrease allowance to timelockregistry'
            );
        }
        _approve(msg.sender, spender, amount);
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the Increase of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically increases the allowance granted to `spender` by the caller.
     *
     * @dev This is an override with respect to the fulfillment of vesting conditions along the way
     * However an user can increase allowance many times, it will never be able to transfer locked tokens during vesting period
     * @return Whether or not the increaseAllowance succeeded
     */
    function increaseAllowance(address spender, uint256 addedValue) public override nonReentrant returns (bool) {
        require(
            unlockedBalance(msg.sender) >= allowance(msg.sender, spender).add(addedValue) ||
                spender == address(timeLockRegistry),
            'TimeLockedToken::increaseAllowance:Not enough unlocked tokens'
        );
        require(spender != address(0), 'TimeLockedToken::increaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::increaseAllowance:Spender cannot be the msg.sender');
        _approve(msg.sender, spender, allowance(msg.sender, spender).add(addedValue));
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the decrease of allowances of ERC20 with special conditions for vesting
     *
     * @notice Atomically decrease the allowance granted to `spender` by the caller.
     *
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an override with respect to the fulfillment of vesting conditions along the way
     * An user cannot decrease the allowance to the Time Lock Registry who is in charge of vesting conditions
     * @return Whether or not the decreaseAllowance succeeded
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public override nonReentrant returns (bool) {
        require(spender != address(0), 'TimeLockedToken::decreaseAllowance:Spender cannot be zero address');
        require(spender != msg.sender, 'TimeLockedToken::decreaseAllowance:Spender cannot be the msg.sender');
        require(
            allowance(msg.sender, spender) >= subtractedValue,
            'TimeLockedToken::decreaseAllowance:Underflow condition'
        );

        // There is no option to decreaseAllowance to timeLockRegistry in case of vested tokens
        require(
            address(spender) != address(timeLockRegistry),
            'TimeLockedToken::decreaseAllowance:cannot decrease allowance to timeLockRegistry'
        );

        _approve(msg.sender, spender, allowance(msg.sender, spender).sub(subtractedValue));
        return true;
    }

    /* ============ Internal Only Function ============ */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Override the _transfer of ERC20 BABL tokens only allowing the transfer of unlocked tokens
     *
     * @dev Transfer function which includes only unlocked tokens
     * Locked tokens can always be transfered back to the returns address
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal override onlyUnpaused {
        require(_from != address(0), 'TimeLockedToken:: _transfer: cannot transfer from the zero address');
        require(_to != address(0), 'TimeLockedToken:: _transfer: cannot transfer to the zero address');
        require(
            _to != address(this),
            'TimeLockedToken:: _transfer: do not transfer tokens to the token contract itself'
        );

        require(balanceOf(_from) >= _value, 'TimeLockedToken:: _transfer: insufficient balance');

        // check if enough unlocked balance to transfer
        require(unlockedBalance(_from) >= _value, 'TimeLockedToken:: _transfer: attempting to transfer locked funds');
        super._transfer(_from, _to, _value);
        // voting power
        _moveDelegates(
            delegates[_from],
            delegates[_to],
            safe96(_value, 'TimeLockedToken:: _transfer: uint96 overflow')
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Disable BABL token transfer until certain conditions are met
     *
     * @dev Override the _beforeTokenTransfer of ERC20 BABL tokens until certain conditions are met:
     * Only allowing minting or transfers from Time Lock Registry and Rewards Distributor until transfers are allowed in the controller
     * Transferring to owner allows re-issuance of funds through registry
     *
     * @param _from The address to send tokens from
     * @param _to The address that will receive the tokens
     * @param _value The amount of tokens to be transferred
     */

    // Disable garden token transfers. Allow minting and burning.
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _value
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _value);
        _require(
            _from == address(0) ||
                _from == address(timeLockRegistry) ||
                _from == address(rewardsDistributor) ||
                _to == address(timeLockRegistry) ||
                tokenTransfersEnabled,
            Errors.BABL_TRANSFERS_DISABLED
        );
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel and remove locked tokens due to non-completion of  vesting period
     * applied only by Time Lock Registry and specifically to Team or Advisors
     *
     * @dev Cancel distribution registration
     * @param lockedAccount that should have its still locked distribution removed due to non-completion of its vesting period
     */
    function _cancelVestedTokensFromTimeLock(address lockedAccount) internal onlyTimeLockRegistry returns (uint256) {
        require(distribution[lockedAccount] != 0, 'TimeLockedToken::cancelTokens:Not registered');

        // get an update on locked amount from distributions at this precise moment
        uint256 loosingAmount = lockedBalance(lockedAccount);

        require(loosingAmount > 0, 'TimeLockedToken::cancelTokens:There are no more locked tokens');
        require(
            vestedToken[lockedAccount].teamOrAdvisor == true,
            'TimeLockedToken::cancelTokens:cannot cancel locked tokens to Investors'
        );

        // set distribution mapping to 0
        delete distribution[lockedAccount];

        // set tokenVested mapping to 0
        delete vestedToken[lockedAccount];

        // transfer only locked tokens back to TimeLockRegistry Owner (msg.sender)
        require(
            transferFrom(lockedAccount, address(timeLockRegistry), loosingAmount),
            'TimeLockedToken::cancelTokens:Transfer failed'
        );

        // emit cancel event
        emit Cancel(lockedAccount, loosingAmount);

        return loosingAmount;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity 0.7.6;

/// @title Optimized overflow and underflow safe math operations
/// @notice Contains methods for doing math operations that revert on overflow or underflow for minimal gas cost
library LowGasSafeMath {
    /// @notice Returns x + y, reverts if sum overflows uint256
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    /// @notice Returns x - y, reverts if underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    /// @notice Returns x * y, reverts if overflows
    /// @param x The multiplicand
    /// @param y The multiplier
    /// @return z The product of x and y
    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(x == 0 || (z = x * y) / x == y);
    }

    /// @notice Returns x + y, reverts if overflows or underflows
    /// @param x The augend
    /// @param y The addend
    /// @return z The sum of x and y
    function add(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x + y) >= x == (y >= 0));
    }

    /// @notice Returns x - y, reverts if overflows or underflows
    /// @param x The minuend
    /// @param y The subtrahend
    /// @return z The difference of x and y
    function sub(int256 x, int256 y) internal pure returns (int256 z) {
        require((z = x - y) <= x == (y >= 0));
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        return a / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {UniversalERC20} from '../lib/UniversalERC20.sol';

library SafeDecimalMath {
    using LowGasSafeMath for uint256;
    using UniversalERC20 for IERC20;

    /* Number of decimal places in the representations. */
    uint8 internal constant decimals = 18;

    /* The number representing 1.0. */
    uint256 internal constant UNIT = 10**uint256(decimals);

    /**
     * @return Provides an interface to UNIT.
     */
    function unit() internal pure returns (uint256) {
        return UNIT;
    }

    /**
     * @return The result of multiplying x and y, interpreting the operands as fixed-point
     * decimals.
     *
     * @dev A unit factor is divided out after the product of x and y is evaluated,
     * so that product must be less than 2**256. As this is an integer division,
     * the internal division always rounds down. This helps save on gas. Rounding
     * is more expensive on gas.
     */
    function multiplyDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        return x.mul(y) / UNIT;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of the specified precision unit.
     *
     * @dev The operands should be in the form of a the specified unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function _multiplyDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        /* Divide by UNIT to remove the extra factor introduced by the product. */
        uint256 quotientTimesTen = x.mul(y) / (precisionUnit / 10);

        if (quotientTimesTen % 10 >= 5) {
            quotientTimesTen += 10;
        }

        return quotientTimesTen / 10;
    }

    /**
     * @return The result of safely multiplying x and y, interpreting the operands
     * as fixed-point decimals of a standard unit.
     *
     * @dev The operands should be in the standard unit factor which will be
     * divided out after the product of x and y is evaluated, so that product must be
     * less than 2**256.
     *
     * Unlike multiplyDecimal, this function rounds the result to the nearest increment.
     * Rounding is useful when you need to retain fidelity for small decimal numbers
     * (eg. small fractions or percentages).
     */
    function multiplyDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _multiplyDecimalRound(x, y, UNIT);
    }

    /**
     * @return The result of safely dividing x and y. The return value is a high
     * precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and UNIT must be less than 2**256. As
     * this is an integer division, the result is always rounded down.
     * This helps save on gas. Rounding is more expensive on gas.
     */
    function divideDecimal(uint256 x, uint256 y) internal pure returns (uint256) {
        /* Reintroduce the UNIT factor that will be divided out by y. */
        return x.mul(UNIT).div(y);
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * decimal in the precision unit specified in the parameter.
     *
     * @dev y is divided after the product of x and the specified precision unit
     * is evaluated, so the product of x and the specified precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function _divideDecimalRound(
        uint256 x,
        uint256 y,
        uint256 precisionUnit
    ) private pure returns (uint256) {
        uint256 resultTimesTen = x.mul(precisionUnit * 10).div(y);

        if (resultTimesTen % 10 >= 5) {
            resultTimesTen += 10;
        }

        return resultTimesTen / 10;
    }

    /**
     * @return The result of safely dividing x and y. The return value is as a rounded
     * standard precision decimal.
     *
     * @dev y is divided after the product of x and the standard precision unit
     * is evaluated, so the product of x and the standard precision unit must
     * be less than 2**256. The result is rounded to the nearest increment.
     */
    function divideDecimalRound(uint256 x, uint256 y) internal pure returns (uint256) {
        return _divideDecimalRound(x, y, UNIT);
    }

    /**
     * Normalizing amount decimals between tokens
     * @param _from       ERC20 asset address
     * @param _to     ERC20 asset address
     * @param _amount Value _to normalize (e.g. capital)
     */
    function normalizeAmountTokens(
        address _from,
        address _to,
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 fromDecimals = IERC20(_from).universalDecimals();
        uint256 toDecimals = IERC20(_to).universalDecimals();

        if (fromDecimals == toDecimals) {
            return _amount;
        }
        if (toDecimals > fromDecimals) {
            return _amount.mul(10**(toDecimals - (fromDecimals)));
        }
        return _amount.div(10**(fromDecimals - (toDecimals)));
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

import {SignedSafeMath} from '@openzeppelin/contracts/math/SignedSafeMath.sol';

import {LowGasSafeMath} from './LowGasSafeMath.sol';

/**
 * @title PreciseUnitMath
 * @author Set Protocol
 *
 * Arithmetic for fixed-point numbers with 18 decimals of precision. Some functions taken from
 * dYdX's BaseMath library.
 *
 * CHANGELOG:
 * - 9/21/20: Added safePower function
 */
library PreciseUnitMath {
    using LowGasSafeMath for uint256;
    using SignedSafeMath for int256;

    // The number One in precise units.
    uint256 internal constant PRECISE_UNIT = 10**18;
    int256 internal constant PRECISE_UNIT_INT = 10**18;

    // Max unsigned integer value
    uint256 internal constant MAX_UINT_256 = type(uint256).max;
    // Max and min signed integer value
    int256 internal constant MAX_INT_256 = type(int256).max;
    int256 internal constant MIN_INT_256 = type(int256).min;

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function decimals() internal pure returns (uint256) {
        return 18;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnit() internal pure returns (uint256) {
        return PRECISE_UNIT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function preciseUnitInt() internal pure returns (int256) {
        return PRECISE_UNIT_INT;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxUint256() internal pure returns (uint256) {
        return MAX_UINT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function maxInt256() internal pure returns (int256) {
        return MAX_INT_256;
    }

    /**
     * @dev Getter function since constants can't be read directly from libraries.
     */
    function minInt256() internal pure returns (int256) {
        return MIN_INT_256;
    }

    /**
     * @dev Multiplies value a by value b (result is rounded down). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(b).div(PRECISE_UNIT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded towards zero). It's assumed that the value b is the
     * significand of a number with 18 decimals precision.
     */
    function preciseMul(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(b).div(PRECISE_UNIT_INT);
    }

    /**
     * @dev Multiplies value a by value b (result is rounded up). It's assumed that the value b is the significand
     * of a number with 18 decimals precision.
     */
    function preciseMulCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0 || b == 0) {
            return 0;
        }
        return a.mul(b).sub(1).div(PRECISE_UNIT).add(1);
    }

    /**
     * @dev Divides value a by value b (result is rounded down).
     */
    function preciseDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        return a.mul(PRECISE_UNIT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded towards 0).
     */
    function preciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return a.mul(PRECISE_UNIT_INT).div(b);
    }

    /**
     * @dev Divides value a by value b (result is rounded up or away from 0).
     */
    function preciseDivCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, 'Cant divide by 0');

        return a > 0 ? a.mul(PRECISE_UNIT).sub(1).div(b).add(1) : 0;
    }

    /**
     * @dev Divides value a by value b (result is rounded down - positive numbers toward 0 and negative away from 0).
     */
    function divDown(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, 'Cant divide by 0');
        require(a != MIN_INT_256 || b != -1, 'Invalid input');

        int256 result = a.div(b);
        if (a ^ b < 0 && a % b != 0) {
            result -= 1;
        }

        return result;
    }

    /**
     * @dev Multiplies value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseMul(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(b), PRECISE_UNIT_INT);
    }

    /**
     * @dev Divides value a by value b where rounding is towards the lesser number.
     * (positive values are rounded towards zero and negative values are rounded away from 0).
     */
    function conservativePreciseDiv(int256 a, int256 b) internal pure returns (int256) {
        return divDown(a.mul(PRECISE_UNIT_INT), b);
    }

    /**
     * @dev Performs the power on a specified value, reverts on overflow.
     */
    function safePower(uint256 a, uint256 pow) internal pure returns (uint256) {
        require(a > 0, 'Value must be positive');

        uint256 result = 1;
        for (uint256 i = 0; i < pow; i++) {
            uint256 previousResult = result;

            // Using safemath multiplication prevents overflows
            result = previousResult.mul(a);
        }

        return result;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Original version by Synthetix.io
    https://docs.synthetix.io/contracts/source/libraries/safedecimalmath

    Adapted by Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

// Libraries
import './SafeDecimalMath.sol';

// https://docs.synthetix.io/contracts/source/libraries/math
library Math {
    using LowGasSafeMath for uint256;
    using SafeDecimalMath for uint256;

    /**
     * @dev Uses "exponentiation by squaring" algorithm where cost is 0(logN)
     * vs 0(N) for naive repeated multiplication.
     * Calculates x^n with x as fixed-point and n as regular unsigned int.
     * Calculates to 18 digits of precision with SafeDecimalMath.unit()
     */
    function powDecimal(uint256 x, uint256 n) internal pure returns (uint256) {
        // https://mpark.github.io/programming/2014/08/18/exponentiation-by-squaring/

        uint256 result = SafeDecimalMath.unit();
        while (n > 0) {
            if (n % 2 != 0) {
                result = result.multiplyDecimal(x);
            }
            x = x.multiplyDecimal(x);
            n /= 2;
        }
        return result;
    }

    function abs(int256 x) internal pure returns (int256) {
        return x >= 0 ? x : -x;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Original version by Synthetix.io
    https://docs.synthetix.io/contracts/source/libraries/safedecimalmath

    Adapted by Babylon Finance.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

// solhint-disable

/**
 * @notice Forked from https://github.com/balancer-labs/balancer-core-v2/blob/master/contracts/lib/helpers/BalancerErrors.sol
 * @dev Reverts if `condition` is false, with a revert reason containing `errorCode`. Only codes up to 999 are
 * supported.
 */
function _require(bool condition, uint256 errorCode) pure {
    if (!condition) _revert(errorCode);
}

/**
 * @dev Reverts with a revert reason containing `errorCode`. Only codes up to 999 are supported.
 */
function _revert(uint256 errorCode) pure {
    // We're going to dynamically create a revert string based on the error code, with the following format:
    // 'BAB#{errorCode}'
    // where the code is left-padded with zeroes to three digits (so they range from 000 to 999).
    //
    // We don't have revert strings embedded in the contract to save bytecode size: it takes much less space to store a
    // number (8 to 16 bits) than the individual string characters.
    //
    // The dynamic string creation algorithm that follows could be implemented in Solidity, but assembly allows for a
    // much denser implementation, again saving bytecode size. Given this function unconditionally reverts, this is a
    // safe place to rely on it without worrying about how its usage might affect e.g. memory contents.
    assembly {
        // First, we need to compute the ASCII representation of the error code. We assume that it is in the 0-999
        // range, so we only need to convert three digits. To convert the digits to ASCII, we add 0x30, the value for
        // the '0' character.

        let units := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let tenths := add(mod(errorCode, 10), 0x30)

        errorCode := div(errorCode, 10)
        let hundreds := add(mod(errorCode, 10), 0x30)

        // With the individual characters, we can now construct the full string. The "BAB#" part is a known constant
        // (0x42414223): we simply shift this by 24 (to provide space for the 3 bytes of the error code), and add the
        // characters to it, each shifted by a multiple of 8.
        // The revert reason is then shifted left by 200 bits (256 minus the length of the string, 7 characters * 8 bits
        // per character = 56) to locate it in the most significant part of the 256 slot (the beginning of a byte
        // array).

        let revertReason := shl(200, add(0x42414223000000, add(add(units, shl(8, tenths)), shl(16, hundreds))))

        // We can now encode the reason in memory, which can be safely overwritten as we're about to revert. The encoded
        // message will have the following layout:
        // [ revert reason identifier ] [ string location offset ] [ string length ] [ string contents ]

        // The Solidity revert reason identifier is 0x08c739a0, the function selector of the Error(string) function. We
        // also write zeroes to the next 28 bytes of memory, but those are about to be overwritten.
        mstore(0x0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        // Next is the offset to the location of the string, which will be placed immediately after (20 bytes away).
        mstore(0x04, 0x0000000000000000000000000000000000000000000000000000000000000020)
        // The string length is fixed: 7 characters.
        mstore(0x24, 7)
        // Finally, the string itself is stored.
        mstore(0x44, revertReason)

        // Even if the string is only 7 bytes long, we need to return a full 32 byte slot containing it. The length of
        // the encoded message is therefore 4 + 32 + 32 + 32 = 100.
        revert(0, 100)
    }
}

library Errors {
    // Max deposit limit needs to be under the limit
    uint256 internal constant MAX_DEPOSIT_LIMIT = 0;
    // Creator needs to deposit
    uint256 internal constant MIN_CONTRIBUTION = 1;
    // Min Garden token supply >= 0
    uint256 internal constant MIN_TOKEN_SUPPLY = 2;
    // Deposit hardlock needs to be at least 1 block
    uint256 internal constant DEPOSIT_HARDLOCK = 3;
    // Needs to be at least the minimum
    uint256 internal constant MIN_LIQUIDITY = 4;
    // _reserveAssetQuantity is not equal to msg.value
    uint256 internal constant MSG_VALUE_DO_NOT_MATCH = 5;
    // Withdrawal amount has to be equal or less than msg.sender balance
    uint256 internal constant MSG_SENDER_TOKENS_DO_NOT_MATCH = 6;
    // Tokens are staked
    uint256 internal constant TOKENS_STAKED = 7;
    // Balance too low
    uint256 internal constant BALANCE_TOO_LOW = 8;
    // msg.sender doesn't have enough tokens
    uint256 internal constant MSG_SENDER_TOKENS_TOO_LOW = 9;
    //  There is an open redemption window already
    uint256 internal constant REDEMPTION_OPENED_ALREADY = 10;
    // Cannot request twice in the same window
    uint256 internal constant ALREADY_REQUESTED = 11;
    // Rewards and profits already claimed
    uint256 internal constant ALREADY_CLAIMED = 12;
    // Value have to be greater than zero
    uint256 internal constant GREATER_THAN_ZERO = 13;
    // Must be reserve asset
    uint256 internal constant MUST_BE_RESERVE_ASSET = 14;
    // Only contributors allowed
    uint256 internal constant ONLY_CONTRIBUTOR = 15;
    // Only controller allowed
    uint256 internal constant ONLY_CONTROLLER = 16;
    // Only creator allowed
    uint256 internal constant ONLY_CREATOR = 17;
    // Only keeper allowed
    uint256 internal constant ONLY_KEEPER = 18;
    // Fee is too high
    uint256 internal constant FEE_TOO_HIGH = 19;
    // Only strategy allowed
    uint256 internal constant ONLY_STRATEGY = 20;
    // Only active allowed
    uint256 internal constant ONLY_ACTIVE = 21;
    // Only inactive allowed
    uint256 internal constant ONLY_INACTIVE = 22;
    // Address should be not zero address
    uint256 internal constant ADDRESS_IS_ZERO = 23;
    // Not within range
    uint256 internal constant NOT_IN_RANGE = 24;
    // Value is too low
    uint256 internal constant VALUE_TOO_LOW = 25;
    // Value is too high
    uint256 internal constant VALUE_TOO_HIGH = 26;
    // Only strategy or protocol allowed
    uint256 internal constant ONLY_STRATEGY_OR_CONTROLLER = 27;
    // Normal withdraw possible
    uint256 internal constant NORMAL_WITHDRAWAL_POSSIBLE = 28;
    // User does not have permissions to join garden
    uint256 internal constant USER_CANNOT_JOIN = 29;
    // User does not have permissions to add strategies in garden
    uint256 internal constant USER_CANNOT_ADD_STRATEGIES = 30;
    // Only Protocol or garden
    uint256 internal constant ONLY_PROTOCOL_OR_GARDEN = 31;
    // Only Strategist
    uint256 internal constant ONLY_STRATEGIST = 32;
    // Only Integration
    uint256 internal constant ONLY_INTEGRATION = 33;
    // Only garden and data not set
    uint256 internal constant ONLY_GARDEN_AND_DATA_NOT_SET = 34;
    // Only active garden
    uint256 internal constant ONLY_ACTIVE_GARDEN = 35;
    // Contract is not a garden
    uint256 internal constant NOT_A_GARDEN = 36;
    // Not enough tokens
    uint256 internal constant STRATEGIST_TOKENS_TOO_LOW = 37;
    // Stake is too low
    uint256 internal constant STAKE_HAS_TO_AT_LEAST_ONE = 38;
    // Duration must be in range
    uint256 internal constant DURATION_MUST_BE_IN_RANGE = 39;
    // Max Capital Requested
    uint256 internal constant MAX_CAPITAL_REQUESTED = 41;
    // Votes are already resolved
    uint256 internal constant VOTES_ALREADY_RESOLVED = 42;
    // Voting window is closed
    uint256 internal constant VOTING_WINDOW_IS_OVER = 43;
    // Strategy needs to be active
    uint256 internal constant STRATEGY_NEEDS_TO_BE_ACTIVE = 44;
    // Max capital reached
    uint256 internal constant MAX_CAPITAL_REACHED = 45;
    // Capital is less then rebalance
    uint256 internal constant CAPITAL_IS_LESS_THAN_REBALANCE = 46;
    // Strategy is in cooldown period
    uint256 internal constant STRATEGY_IN_COOLDOWN = 47;
    // Strategy is not executed
    uint256 internal constant STRATEGY_IS_NOT_EXECUTED = 48;
    // Strategy is not over yet
    uint256 internal constant STRATEGY_IS_NOT_OVER_YET = 49;
    // Strategy is already finalized
    uint256 internal constant STRATEGY_IS_ALREADY_FINALIZED = 50;
    // No capital to unwind
    uint256 internal constant STRATEGY_NO_CAPITAL_TO_UNWIND = 51;
    // Strategy needs to be inactive
    uint256 internal constant STRATEGY_NEEDS_TO_BE_INACTIVE = 52;
    // Duration needs to be less
    uint256 internal constant DURATION_NEEDS_TO_BE_LESS = 53;
    // Can't sweep reserve asset
    uint256 internal constant CANNOT_SWEEP_RESERVE_ASSET = 54;
    // Voting window is opened
    uint256 internal constant VOTING_WINDOW_IS_OPENED = 55;
    // Strategy is executed
    uint256 internal constant STRATEGY_IS_EXECUTED = 56;
    // Min Rebalance Capital
    uint256 internal constant MIN_REBALANCE_CAPITAL = 57;
    // Not a valid strategy NFT
    uint256 internal constant NOT_STRATEGY_NFT = 58;
    // Garden Transfers Disabled
    uint256 internal constant GARDEN_TRANSFERS_DISABLED = 59;
    // Tokens are hardlocked
    uint256 internal constant TOKENS_HARDLOCKED = 60;
    // Max contributors reached
    uint256 internal constant MAX_CONTRIBUTORS = 61;
    // BABL Transfers Disabled
    uint256 internal constant BABL_TRANSFERS_DISABLED = 62;
    // Strategy duration range error
    uint256 internal constant DURATION_RANGE = 63;
    // Checks the min amount of voters
    uint256 internal constant MIN_VOTERS_CHECK = 64;
    // Ge contributor power error
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_WINDOW = 65;
    // Not enough reserve set aside
    uint256 internal constant NOT_ENOUGH_RESERVE = 66;
    // Garden is already public
    uint256 internal constant GARDEN_ALREADY_PUBLIC = 67;
    // Withdrawal with penalty
    uint256 internal constant WITHDRAWAL_WITH_PENALTY = 68;
    // Withdrawal with penalty
    uint256 internal constant ONLY_MINING_ACTIVE = 69;
    // Overflow in supply
    uint256 internal constant OVERFLOW_IN_SUPPLY = 70;
    // Overflow in power
    uint256 internal constant OVERFLOW_IN_POWER = 71;
    // Not a system contract
    uint256 internal constant NOT_A_SYSTEM_CONTRACT = 72;
    // Strategy vs Garden mismatch
    uint256 internal constant STRATEGY_GARDEN_MISMATCH = 73;
    // Minimum quarters is 1
    uint256 internal constant QUARTERS_MIN_1 = 74;
    // Too many strategy operations
    uint256 internal constant TOO_MANY_OPS = 75;
    // Only operations
    uint256 internal constant ONLY_OPERATION = 76;
    // Strat params wrong length
    uint256 internal constant STRAT_PARAMS_LENGTH = 77;
    // Garden params wrong length
    uint256 internal constant GARDEN_PARAMS_LENGTH = 78;
    // Token names too long
    uint256 internal constant NAME_TOO_LONG = 79;
    // Contributor power overflows over garden power
    uint256 internal constant CONTRIBUTOR_POWER_OVERFLOW = 80;
    // Contributor power window out of bounds
    uint256 internal constant CONTRIBUTOR_POWER_CHECK_DEPOSITS = 81;
    // Contributor power window out of bounds
    uint256 internal constant NO_REWARDS_TO_CLAIM = 82;
    // Pause guardian paused this operation
    uint256 internal constant ONLY_UNPAUSED = 83;
    // Reentrant intent
    uint256 internal constant REENTRANT_CALL = 84;
    // Reserve asset not supported
    uint256 internal constant RESERVE_ASSET_NOT_SUPPORTED = 85;
    // Withdrawal/Deposit check min amount received
    uint256 internal constant RECEIVE_MIN_AMOUNT = 86;
    // Total Votes has to be positive
    uint256 internal constant TOTAL_VOTES_HAVE_TO_BE_POSITIVE = 87;
    // Signer has to be valid
    uint256 internal constant INVALID_SIGNER = 88;
    // Nonce has to be valid
    uint256 internal constant INVALID_NONCE = 89;
    // Garden is not public
    uint256 internal constant GARDEN_IS_NOT_PUBLIC = 90;
    // Setting max contributors
    uint256 internal constant MAX_CONTRIBUTORS_SET = 91;
    // Profit sharing mismatch for customized gardens
    uint256 internal constant PROFIT_SHARING_MISMATCH = 92;
    // Max allocation percentage
    uint256 internal constant MAX_STRATEGY_ALLOCATION_PERCENTAGE = 93;
    // new creator must not exist
    uint256 internal constant NEW_CREATOR_MUST_NOT_EXIST = 94;
    // only first creator can add
    uint256 internal constant ONLY_FIRST_CREATOR_CAN_ADD = 95;
    // invalid address
    uint256 internal constant INVALID_ADDRESS = 96;
    // creator can only renounce in some circumstances
    uint256 internal constant CREATOR_CANNOT_RENOUNCE = 97;
    // no price for trade
    uint256 internal constant NO_PRICE_FOR_TRADE = 98;
    // Max capital requested
    uint256 internal constant ZERO_CAPITAL_REQUESTED = 99;
    // Unwind capital above the limit
    uint256 internal constant INVALID_CAPITAL_TO_UNWIND = 100;
    // Mining % sharing does not match
    uint256 internal constant INVALID_MINING_VALUES = 101;
    // Max trade slippage percentage
    uint256 internal constant MAX_TRADE_SLIPPAGE_PERCENTAGE = 102;
    // Max gas fee percentage
    uint256 internal constant MAX_GAS_FEE_PERCENTAGE = 103;
    // Mismatch between voters and votes
    uint256 internal constant INVALID_VOTES_LENGTH = 104;
    // Only Rewards Distributor
    uint256 internal constant ONLY_RD = 105;
    // Fee is too LOW
    uint256 internal constant FEE_TOO_LOW = 106;
    // Only governance or emergency
    uint256 internal constant ONLY_GOVERNANCE_OR_EMERGENCY = 107;
    // Strategy invalid reserve asset amount
    uint256 internal constant INVALID_RESERVE_AMOUNT = 108;
    // Heart only pumps once a week
    uint256 internal constant HEART_ALREADY_PUMPED = 109;
    // Heart needs garden votes to pump
    uint256 internal constant HEART_VOTES_MISSING = 110;
    // Not enough fees for heart
    uint256 internal constant HEART_MINIMUM_FEES = 111;
    // Invalid heart votes length
    uint256 internal constant HEART_VOTES_LENGTH = 112;
    // Heart LP tokens not received
    uint256 internal constant HEART_LP_TOKENS = 113;
    // Heart invalid asset to lend
    uint256 internal constant HEART_ASSET_LEND_INVALID = 114;
    // Heart garden not set
    uint256 internal constant HEART_GARDEN_NOT_SET = 115;
    // Heart asset to lend is the same
    uint256 internal constant HEART_ASSET_LEND_SAME = 116;
    // Heart invalid ctoken
    uint256 internal constant HEART_INVALID_CTOKEN = 117;
    // Price per share is wrong
    uint256 internal constant PRICE_PER_SHARE_WRONG = 118;
    // Heart asset to purchase is same
    uint256 internal constant HEART_ASSET_PURCHASE_INVALID = 119;
    // Reset hardlock bigger than timestamp
    uint256 internal constant RESET_HARDLOCK_INVALID = 120;
    // Invalid referrer
    uint256 internal constant INVALID_REFERRER = 121;
    // Only Heart Garden
    uint256 internal constant ONLY_HEART_GARDEN = 122;
    // Max BABL Cap to claim by sig
    uint256 internal constant MAX_BABL_CAP_REACHED = 123;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_BABL = 124;
    // Claim garden NFT
    uint256 internal constant CLAIM_GARDEN_NFT = 125;
    // Not enough collateral
    uint256 internal constant NOT_ENOUGH_COLLATERAL = 126;
    // Amount too low
    uint256 internal constant AMOUNT_TOO_LOW = 127;
    // Amount too high
    uint256 internal constant AMOUNT_TOO_HIGH = 128;
    // Not enough to repay debt
    uint256 internal constant SLIPPAGE_TOO_HIH = 129;
    // Invalid amount
    uint256 internal constant INVALID_AMOUNT = 130;
    // Not enough BABL
    uint256 internal constant NOT_ENOUGH_AMOUNT = 131;
    // Error minting
    uint256 internal constant MINT_ERROR = 132;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IBabController
 * @author Babylon Finance
 *
 * Interface for interacting with BabController
 */
interface IBabController {
    /* ============ Functions ============ */

    function createGarden(
        address _reserveAsset,
        string memory _name,
        string memory _symbol,
        string memory _tokenURI,
        uint256 _seed,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards,
        uint256[] memory _profitSharing
    ) external payable returns (address);

    function removeGarden(address _garden) external;

    function addReserveAsset(address _reserveAsset) external;

    function removeReserveAsset(address _reserveAsset) external;

    function updateProtocolWantedAsset(address _wantedAsset, bool _wanted) external;

    function updateGardenAffiliateRate(address _garden, uint256 _affiliateRate) external;

    function addAffiliateReward(
        address _depositor,
        address _referrer,
        uint256 _reserveAmount
    ) external;

    function claimRewards() external;

    function editPriceOracle(address _priceOracle) external;

    function editMardukGate(address _mardukGate) external;

    function editGardenValuer(address _gardenValuer) external;

    function editTreasury(address _newTreasury) external;

    function editHeart(address _newHeart) external;

    function editRewardsDistributor(address _rewardsDistributor) external;

    function editGardenFactory(address _newGardenFactory) external;

    function editGardenNFT(address _newGardenNFT) external;

    function editStrategyNFT(address _newStrategyNFT) external;

    function editStrategyFactory(address _newStrategyFactory) external;

    function setOperation(uint8 _kind, address _operation) external;

    function setMasterSwapper(address _newMasterSwapper) external;

    function addKeeper(address _keeper) external;

    function addKeepers(address[] memory _keepers) external;

    function removeKeeper(address _keeper) external;

    function enableGardenTokensTransfers() external;

    function editLiquidityReserve(address _reserve, uint256 _minRiskyPairLiquidityEth) external;

    function patchIntegration(address _old, address _new) external;

    function gardenCreationIsOpen() external view returns (bool);

    function owner() external view returns (address);

    function EMERGENCY_OWNER() external view returns (address);

    function guardianGlobalPaused() external view returns (bool);

    function guardianPaused(address _address) external view returns (bool);

    function setPauseGuardian(address _guardian) external;

    function setGlobalPause(bool _state) external returns (bool);

    function setSomePause(address[] memory _address, bool _state) external returns (bool);

    function isPaused(address _contract) external view returns (bool);

    function priceOracle() external view returns (address);

    function gardenValuer() external view returns (address);

    function heart() external view returns (address);

    function gardenNFT() external view returns (address);

    function strategyNFT() external view returns (address);

    function rewardsDistributor() external view returns (address);

    function gardenFactory() external view returns (address);

    function treasury() external view returns (address);

    function ishtarGate() external view returns (address);

    function mardukGate() external view returns (address);

    function strategyFactory() external view returns (address);

    function masterSwapper() external view returns (address);

    function gardenTokensTransfersEnabled() external view returns (bool);

    function bablMiningProgramEnabled() external view returns (bool);

    function allowPublicGardens() external view returns (bool);

    function enabledOperations(uint256 _kind) external view returns (address);

    function getGardens() external view returns (address[] memory);

    function getReserveAssets() external view returns (address[] memory);

    function getOperations() external view returns (address[20] memory);

    function isGarden(address _garden) external view returns (bool);

    function protocolWantedAssets(address _wantedAsset) external view returns (bool);

    function gardenAffiliateRates(address _wantedAsset) external view returns (uint256);

    function affiliateRewards(address _user) external view returns (uint256);

    function patchedIntegrations(address _integration) external view returns (address);

    function isValidReserveAsset(address _reserveAsset) external view returns (bool);

    function isValidKeeper(address _keeper) external view returns (bool);

    function isSystemContract(address _contractAddress) external view returns (bool);

    function protocolPerformanceFee() external view returns (uint256);

    function protocolManagementFee() external view returns (uint256);

    function minLiquidityPerReserve(address _reserve) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {IERC1271} from '../interfaces/IERC1271.sol';

import {IBabController} from './IBabController.sol';

/**
 * @title IEmergencyGarden
 */
interface IEmergencyGarden {
    /* ============ Write ============ */

    function wrap() external;
}

/**
 * @title IStrategyGarden
 */
interface IStrategyGarden {
    /* ============ Write ============ */

    function finalizeStrategy(
        uint256 _profits,
        int256 _returns,
        uint256 _burningAmount
    ) external;

    function allocateCapitalToStrategy(uint256 _capital) external;

    function expireCandidateStrategy() external;

    function addStrategy(
        string memory _name,
        string memory _symbol,
        uint256[] calldata _stratParams,
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes calldata _opEncodedDatas
    ) external;

    function payKeeper(address payable _keeper, uint256 _fee) external;

    function updateStrategyRewards(
        address _strategy,
        uint256 _newTotalBABLAmount,
        uint256 _newCapitalReturned,
        uint256 _newRewardsToSetAside
    ) external;
}

/**
 * @title IAdminGarden
 */
interface IAdminGarden {
    /* ============ Write ============ */
    function initialize(
        address _reserveAsset,
        IBabController _controller,
        address _creator,
        string memory _name,
        string memory _symbol,
        uint256[] calldata _gardenParams,
        uint256 _initialContribution,
        bool[] memory _publicGardenStrategistsStewards
    ) external payable;

    function makeGardenPublic() external;

    function transferCreatorRights(address _newCreator, uint8 _index) external;

    function addExtraCreators(address[4] memory _newCreators) external;

    function setPublicRights(bool _publicStrategist, bool _publicStewards) external;

    function delegateVotes(address _token, address _address) external;

    function updateCreators(address _newCreator, address[4] memory _newCreators) external;

    function updateGardenParams(uint256[13] memory _newParams) external;

    function verifyGarden(uint256 _verifiedCategory) external;

    function resetHardlock(uint256 _hardlockStartsAt) external;
}

/**
 * @title IGarden
 */
interface ICoreGarden {
    /* ============ Constructor ============ */

    /* ============ View ============ */

    function privateGarden() external view returns (bool);

    function publicStrategists() external view returns (bool);

    function publicStewards() external view returns (bool);

    function controller() external view returns (IBabController);

    function creator() external view returns (address);

    function isGardenStrategy(address _strategy) external view returns (bool);

    function getContributor(address _contributor)
        external
        view
        returns (
            uint256 lastDepositAt,
            uint256 initialDepositAt,
            uint256 claimedAt,
            uint256 claimedBABL,
            uint256 claimedRewards,
            uint256 withdrawnSince,
            uint256 totalDeposits,
            uint256 nonce,
            uint256 lockedBalance
        );

    function reserveAsset() external view returns (address);

    function verifiedCategory() external view returns (uint256);

    function canMintNftAfter() external view returns (uint256);

    function customIntegrationsEnabled() external view returns (bool);

    function hardlockStartsAt() external view returns (uint256);

    function totalContributors() external view returns (uint256);

    function gardenInitializedAt() external view returns (uint256);

    function minContribution() external view returns (uint256);

    function depositHardlock() external view returns (uint256);

    function minLiquidityAsset() external view returns (uint256);

    function minStrategyDuration() external view returns (uint256);

    function maxStrategyDuration() external view returns (uint256);

    function reserveAssetRewardsSetAside() external view returns (uint256);

    function absoluteReturns() external view returns (int256);

    function totalStake() external view returns (uint256);

    function minVotesQuorum() external view returns (uint256);

    function minVoters() external view returns (uint256);

    function maxDepositLimit() external view returns (uint256);

    function strategyCooldownPeriod() external view returns (uint256);

    function getStrategies() external view returns (address[] memory);

    function extraCreators(uint256 index) external view returns (address);

    function getFinalizedStrategies() external view returns (address[] memory);

    function strategyMapping(address _strategy) external view returns (bool);

    function keeperDebt() external view returns (uint256);

    function totalKeeperFees() external view returns (uint256);

    function lastPricePerShare() external view returns (uint256);

    function lastPricePerShareTS() external view returns (uint256);

    function pricePerShareDecayRate() external view returns (uint256);

    function pricePerShareDelta() external view returns (uint256);

    /* ============ Write ============ */

    function deposit(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        address _referrer
    ) external payable;

    function depositBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        address _referrer,
        bytes memory signature
    ) external;

    function withdraw(
        uint256 _amountIn,
        uint256 _minAmountOut,
        address payable _to,
        bool _withPenalty,
        address _unwindStrategy
    ) external;

    function withdrawBySig(
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        bool _withPenalty,
        address _unwindStrategy,
        uint256 _pricePerShare,
        uint256 _strategyNAV,
        uint256 _fee,
        address _signer,
        bytes memory signature
    ) external;

    function claimReturns(address[] calldata _finalizedStrategies) external;

    function claimAndStakeReturns(uint256 _minAmountOut, address[] calldata _finalizedStrategies) external;

    function claimRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _fee,
        address signer,
        bytes memory signature
    ) external;

    function claimAndStakeRewardsBySig(
        uint256 _babl,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        uint256 _pricePerShare,
        uint256 _fee,
        address _signer,
        bytes memory _signature
    ) external;

    function stakeBySig(
        uint256 _amountIn,
        uint256 _profits,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _nonceHeart,
        uint256 _maxFee,
        address _to,
        uint256 _pricePerShare,
        address _signer,
        bytes memory _signature
    ) external;

    function claimNFT() external;
}

interface IERC20Metadata {
    function name() external view returns (string memory);
}

interface IGarden is ICoreGarden, IAdminGarden, IStrategyGarden, IEmergencyGarden, IERC20, IERC20Metadata, IERC1271 {
    struct Contributor {
        uint256 lastDepositAt;
        uint256 initialDepositAt;
        uint256 claimedAt;
        uint256 claimedBABL;
        uint256 claimedRewards;
        uint256 withdrawnSince;
        uint256 totalDeposits;
        uint256 nonce;
        uint256 lockedBalance;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IGarden} from '../interfaces/IGarden.sol';

/**
 * @title IStrategy
 * @author Babylon Finance
 *
 * Interface for strategy
 */
interface IStrategy {
    function initialize(
        address _strategist,
        address _garden,
        address _controller,
        uint256 _maxCapitalRequested,
        uint256 _stake,
        uint256 _strategyDuration,
        uint256 _expectedReturn,
        uint256 _maxAllocationPercentage,
        uint256 _maxGasFeePercentage,
        uint256 _maxTradeSlippagePercentage
    ) external;

    function resolveVoting(
        address[] calldata _voters,
        int256[] calldata _votes,
        uint256 fee
    ) external;

    function updateParams(uint256[5] calldata _params) external;

    function sweep(address _token, uint256 _newSlippage) external;

    function setData(
        uint8[] calldata _opTypes,
        address[] calldata _opIntegrations,
        bytes memory _opEncodedData
    ) external;

    function executeStrategy(uint256 _capital, uint256 fee) external;

    function getNAV() external view returns (uint256);

    function opEncodedData() external view returns (bytes memory);

    function getOperationsCount() external view returns (uint256);

    function getOperationByIndex(uint8 _index)
        external
        view
        returns (
            uint8,
            address,
            bytes memory
        );

    function finalizeStrategy(
        uint256 fee,
        string memory _tokenURI,
        uint256 _minReserveOut
    ) external;

    function unwindStrategy(uint256 _amountToUnwind, uint256 _strategyNAV) external;

    function invokeFromIntegration(
        address _target,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes memory);

    function invokeApprove(
        address _spender,
        address _asset,
        uint256 _quantity
    ) external;

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken
    ) external returns (uint256);

    function trade(
        address _sendToken,
        uint256 _sendQuantity,
        address _receiveToken,
        uint256 _overrideSlippage
    ) external returns (uint256);

    function handleWeth(bool _isDeposit, uint256 _wethAmount) external;

    function updateStrategyRewards(uint256 _newTotalBABLRewards, uint256 _newCapitalReturned) external;

    function getStrategyDetails()
        external
        view
        returns (
            address,
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            uint256
        );

    function getStrategyState()
        external
        view
        returns (
            address,
            bool,
            bool,
            bool,
            uint256,
            uint256,
            uint256
        );

    function getStrategyRewardsContext()
        external
        view
        returns (
            address,
            uint256[] memory,
            bool[] memory
        );

    function isStrategyActive() external view returns (bool);

    function getUserVotes(address _address) external view returns (int256);

    function strategist() external view returns (address);

    function enteredAt() external view returns (uint256);

    function enteredCooldownAt() external view returns (uint256);

    function stake() external view returns (uint256);

    function strategyRewards() external view returns (uint256);

    function maxCapitalRequested() external view returns (uint256);

    function maxAllocationPercentage() external view returns (uint256);

    function maxTradeSlippagePercentage() external view returns (uint256);

    function maxGasFeePercentage() external view returns (uint256);

    function expectedReturn() external view returns (uint256);

    function duration() external view returns (uint256);

    function totalPositiveVotes() external view returns (uint256);

    function totalNegativeVotes() external view returns (uint256);

    function capitalReturned() external view returns (uint256);

    function capitalAllocated() external view returns (uint256);

    function garden() external view returns (IGarden);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {TimeLockedToken} from '../token/TimeLockedToken.sol';

/**
 * @title IRewardsDistributor
 * @author Babylon Finance
 *
 * Interface for the rewards distributor in charge of the BABL Mining Program.
 */

interface IRewardsDistributor {
    /* ========== View functions ========== */

    function babltoken() external view returns (TimeLockedToken);

    function getStrategyRewards(address _strategy) external view returns (uint256);

    function getRewards(
        address _garden,
        address _contributor,
        address[] calldata _finalizedStrategies
    ) external view returns (uint256[] memory);

    function getGardenProfitsSharing(address _garden) external view returns (uint256[3] memory);

    function checkMining(uint256 _quarterNum, address _strategy) external view returns (uint256[17] memory);

    function estimateUserRewards(address _strategy, address _contributor) external view returns (uint256[] memory);

    function estimateStrategyRewards(address _strategy) external view returns (uint256);

    function getPriorBalance(
        address _garden,
        address _contributor,
        uint256 _timestamp
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /* ============ External Functions ============ */

    function setProfitRewards(
        address _garden,
        uint256 _strategistShare,
        uint256 _stewardsShare,
        uint256 _lpShare
    ) external;

    function migrateAddressToCheckpoints(address _garden, bool _toMigrate) external;

    function setBABLMiningParameters(uint256[12] memory _newMiningParams) external;

    function updateProtocolPrincipal(uint256 _capital, bool _addOrSubstract) external;

    function updateGardenPowerAndContributor(
        address _garden,
        address _contributor,
        uint256 _previousBalance,
        uint256 _tokenDiff,
        bool _addOrSubstract
    ) external;

    function sendBABLToContributor(address _to, uint256 _babl) external returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ITokenIdentifier} from './ITokenIdentifier.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface IPriceOracle {
    /* ============ Functions ============ */

    function getPrice(address _assetOne, address _assetTwo) external view returns (uint256);

    function getPriceNAV(address _assetOne, address _assetTwo) external view returns (uint256);

    function updateReserves(address[] memory list) external;

    function updateMaxTwapDeviation(int24 _maxTwapDeviation) external;

    function updateTokenIdentifier(ITokenIdentifier _tokenIdentifier) external;

    function getCompoundExchangeRate(address _asset, address _finalAsset) external view returns (uint256);

    function getCreamExchangeRate(address _asset, address _finalAsset) external view returns (uint256);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @title IProphets
 * @author Babylon Finance
 *
 * Interface for interacting with the Prophets NFT
 */
interface IProphets is IERC721 {
    /* ============ Functions ============ */

    function getStakedProphetAttrs(address _owner, address _stakedAt) external view returns (uint256[7] memory);

    function stake(uint256 _id, address _target) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
import {IGarden} from './IGarden.sol';

/**
 * @title IHeart
 * @author Babylon Finance
 *
 * Interface for interacting with the Heart
 */
interface IHeart {
    // View functions

    function getVotedGardens() external view returns (address[] memory);

    function heartGarden() external view returns (IGarden);

    function getGardenWeights() external view returns (uint256[] memory);

    function minAmounts(address _reserve) external view returns (uint256);

    function assetToCToken(address _asset) external view returns (address);

    function bondAssets(address _asset) external view returns (uint256);

    function assetToLend() external view returns (address);

    function assetForPurchases() external view returns (address);

    function lastPumpAt() external view returns (uint256);

    function lastVotesAt() external view returns (uint256);

    function tradeSlippage() external view returns (uint256);

    function weeklyRewardAmount() external view returns (uint256);

    function bablRewardLeft() external view returns (uint256);

    function getFeeDistributionWeights() external view returns (uint256[] memory);

    function getTotalStats() external view returns (uint256[7] memory);

    function votedGardens(uint256 _index) external view returns (address);

    function gardenWeights(uint256 _index) external view returns (uint256);

    function feeDistributionWeights(uint256 _index) external view returns (uint256);

    function totalStats(uint256 _index) external view returns (uint256);

    // Non-view

    function pump() external;

    function voteProposal(uint256 _proposalId, bool _isApprove) external;

    function resolveGardenVotesAndPump(address[] memory _gardens, uint256[] memory _weights) external;

    function resolveGardenVotes(address[] memory _gardens, uint256[] memory _weights) external;

    function updateMarkets() external;

    function setHeartGardenAddress(address _heartGarden) external;

    function updateFeeWeights(uint256[] calldata _feeWeights) external;

    function updateAssetToLend(address _assetToLend) external;

    function updateAssetToPurchase(address _purchaseAsset) external;

    function updateBond(address _assetToBond, uint256 _bondDiscount) external;

    function lendFusePool(address _assetToLend, uint256 _lendAmount) external;

    function borrowFusePool(address _assetToBorrow, uint256 _borrowAmount) external;

    function repayFusePool(address _borrowedAsset, uint256 _amountToRepay) external;

    function protectBABL(
        uint256 _bablPriceProtectionAt,
        uint256 _bablPrice,
        uint256 _pricePurchasingAsset,
        uint256 _slippage,
        address _hopToken
    ) external;

    function trade(
        address _fromAsset,
        address _toAsset,
        uint256 _fromAmount,
        uint256 _minAmount
    ) external;

    function sellWantedAssetToHeart(address _assetToSell, uint256 _amountToSell) external;

    function addReward(uint256 _bablAmount, uint256 _weeklyRate) external;

    function setMinTradeAmount(address _asset, uint256 _minAmount) external;

    function setTradeSlippage(uint256 _tradeSlippage) external;

    function bondAsset(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _minAmountOut,
        address _referrer
    ) external;

    function bondAssetBySig(
        address _assetToBond,
        uint256 _amountToBond,
        uint256 _amountIn,
        uint256 _minAmountOut,
        uint256 _nonce,
        uint256 _maxFee,
        uint256 _priceInBABL,
        uint256 _pricePerShare,
        uint256 _fee,
        address _contributor,
        address _referrer,
        bytes memory _signature
    ) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';
import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import {TimeLockedToken} from './TimeLockedToken.sol';
import {AddressArrayUtils} from '../lib/AddressArrayUtils.sol';

import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';

/**
 * @title TimeLockRegistry
 * @notice Register Lockups for TimeLocked ERC20 Token BABL (e.g. vesting)
 * @author Babylon Finance
 * @dev This contract allows owner to register distributions for a TimeLockedToken
 *
 * To register a distribution, register method should be called by the owner.
 * claim() should be called only by the BABL Token smartcontract (modifier onlyBABLToken)
 *  when any account registered to receive tokens make its own claim
 * If case of a mistake, owner can cancel registration before the claim is done by the account
 *
 * Note this contract address must be setup in the TimeLockedToken's contract pointing
 * to interact with (e.g. setTimeLockRegistry() function)
 */

contract TimeLockRegistry is Ownable {
    using LowGasSafeMath for uint256;
    using Address for address;
    using AddressArrayUtils for address[];

    /* ============ Events ============ */

    event Register(address receiver, uint256 distribution);
    event Cancel(address receiver, uint256 distribution);
    event Claim(address account, uint256 distribution);

    /* ============ Modifiers ============ */

    modifier onlyBABLToken() {
        require(msg.sender == address(token), 'only BABL Token');
        _;
    }

    /* ============ State Variables ============ */

    // time locked token
    TimeLockedToken public token;

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param receiver Account being registered
     * @param investorType Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingStarting Date When the vesting begins for such token owner
     * @param distribution Tokens amount that receiver is due to get
     */
    struct Registration {
        address receiver;
        uint256 distribution;
        bool investorType;
        uint256 vestingStartingDate;
    }

    /**
     * @notice The profile of each token owner under vesting conditions and its special conditions
     * @param team Indicates whether or not is a Team member (true = team member / advisor, false = private investor)
     * @param vestingBegin When the vesting begins for such token owner
     * @param vestingEnd When the vesting ends for such token owner
     * @param lastClaim When the last claim was done
     */
    struct TokenVested {
        bool team;
        bool cliff;
        uint256 vestingBegin;
        uint256 vestingEnd;
        uint256 lastClaim;
    }

    /// @notice A record of token owners under vesting conditions for each account, by index
    mapping(address => TokenVested) public tokenVested;

    // mapping from token owners under vesting conditions to BABL due amount (e.g. SAFT addresses, team members, advisors)
    mapping(address => uint256) public registeredDistributions;

    // array of all registrations
    address[] public registrations;

    // total amount of tokens registered
    uint256 public totalTokens;

    // vesting for Team Members
    uint256 private constant teamVesting = 365 days * 4;

    // vesting for Investors and Advisors
    uint256 private constant investorVesting = 365 days * 3;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    /**
     * @notice Construct a new Time Lock Registry and gives ownership to sender
     * @param _token TimeLockedToken contract to use in this registry
     */
    constructor(TimeLockedToken _token) {
        token = _token;
    }

    /* ============ External Functions ============ */

    /* ============ External Getter Functions ============ */

    /**
     * Gets registrations
     *
     * @return  address[]        Returns list of registrations
     */

    function getRegistrations() external view returns (address[] memory) {
        return registrations;
    }

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register multiple investors/team in a batch
     * @param _registrations Registrations to process
     */
    function registerBatch(Registration[] memory _registrations) external onlyOwner {
        for (uint256 i = 0; i < _registrations.length; i++) {
            register(
                _registrations[i].receiver,
                _registrations[i].distribution,
                _registrations[i].investorType,
                _registrations[i].vestingStartingDate
            );
        }
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION
     *
     * @notice Register new account under vesting conditions (Team, Advisors, Investors e.g. SAFT purchaser)
     * @param receiver Address belonging vesting conditions
     * @param distribution Tokens amount that receiver is due to get
     */
    function register(
        address receiver,
        uint256 distribution,
        bool investorType,
        uint256 vestingStartingDate
    ) public onlyOwner {
        require(receiver != address(0), 'TimeLockRegistry::register: cannot register the zero address');
        require(
            receiver != address(this),
            'TimeLockRegistry::register: Time Lock Registry contract cannot be an investor'
        );
        require(distribution != 0, 'TimeLockRegistry::register: Distribution = 0');
        require(
            registeredDistributions[receiver] == 0,
            'TimeLockRegistry::register:Distribution for this address is already registered'
        );
        require(vestingStartingDate >= 1614553200, 'Cannot register earlier than March 2021'); // 1614553200 is UNIX TIME of 2021 March the 1st
        require(
            vestingStartingDate <= block.timestamp.add(30 days),
            'Cannot register more than 30 days ahead in the future'
        );
        require(totalTokens.add(distribution) <= IERC20(token).balanceOf(address(this)), 'Not enough tokens');

        totalTokens = totalTokens.add(distribution);
        // register distribution
        registeredDistributions[receiver] = distribution;
        registrations.push(receiver);

        // register token vested conditions
        TokenVested storage newTokenVested = tokenVested[receiver];
        newTokenVested.team = investorType;
        newTokenVested.vestingBegin = vestingStartingDate;

        if (newTokenVested.team == true) {
            newTokenVested.vestingEnd = vestingStartingDate.add(teamVesting);
        } else {
            newTokenVested.vestingEnd = vestingStartingDate.add(investorVesting);
        }
        newTokenVested.lastClaim = vestingStartingDate;

        tokenVested[receiver] = newTokenVested;

        // emit register event
        emit Register(receiver, distribution);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel distribution registration
     * @dev A claim has not to be done earlier
     * @param receiver Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelRegistration(address receiver) external onlyOwner returns (bool) {
        require(registeredDistributions[receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[receiver];

        // set distribution mapping to 0
        delete registeredDistributions[receiver];

        // set tokenVested mapping to 0
        delete tokenVested[receiver];

        // remove from the list of all registrations
        registrations.remove(receiver);

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // emit cancel event
        emit Cancel(receiver, amount);

        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Cancel distribution registration in case of mistake and before a claim is done
     *
     * @notice Cancel already delivered tokens. It might only apply when non-completion of vesting period of Team members or Advisors
     * @dev An automatic override allowance is granted during the claim process
     * @param account Address that should have it's distribution removed
     * @return Whether or not it succeeded
     */
    function cancelDeliveredTokens(address account) external onlyOwner returns (bool) {
        uint256 loosingAmount = token.cancelVestedTokens(account);

        // emit cancel event
        emit Cancel(account, loosingAmount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Recover tokens in Time Lock Registry smartcontract address by the owner
     *
     * @notice Send tokens from smartcontract address to the owner.
     * It might only apply after a cancellation of vested tokens
     * @param amount Amount to be recovered by the owner of the Time Lock Registry smartcontract from its balance
     * @return Whether or not it succeeded
     */
    function transferToOwner(uint256 amount) external onlyOwner returns (bool) {
        SafeERC20.safeTransfer(token, msg.sender, amount);
        return true;
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Claim locked tokens by the registered account
     *
     * @notice Claim tokens due amount.
     * @dev Claim is done by the user in the TimeLocked contract and the contract is the only allowed to call
     * this function on behalf of the user to make the claim
     * @return The amount of tokens registered and delivered after the claim
     */
    function claim(address _receiver) external onlyBABLToken returns (uint256) {
        require(registeredDistributions[_receiver] != 0, 'Not registered');

        // get amount from distributions
        uint256 amount = registeredDistributions[_receiver];
        TokenVested storage claimTokenVested = tokenVested[_receiver];

        claimTokenVested.lastClaim = block.timestamp;

        // set distribution mapping to 0
        delete registeredDistributions[_receiver];

        // decrease total tokens
        totalTokens = totalTokens.sub(amount);

        // register lockup in TimeLockedToken
        // this will transfer funds from this contract and lock them for sender
        token.registerLockup(
            _receiver,
            amount,
            claimTokenVested.team,
            claimTokenVested.vestingBegin,
            claimTokenVested.vestingEnd,
            claimTokenVested.lastClaim
        );

        // set tokenVested mapping to 0
        delete tokenVested[_receiver];

        // emit claim event
        emit Claim(_receiver, amount);

        return amount;
    }

    /* ============ Getter Functions ============ */

    function checkVesting(address address_)
        external
        view
        returns (
            bool team,
            uint256 start,
            uint256 end,
            uint256 last
        )
    {
        TokenVested storage checkTokenVested = tokenVested[address_];

        return (
            checkTokenVested.team,
            checkTokenVested.vestingBegin,
            checkTokenVested.vestingEnd,
            checkTokenVested.lastClaim
        );
    }

    function checkRegisteredDistribution(address address_) external view returns (uint256 amount) {
        return registeredDistributions[address_];
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ERC20} from '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import {IVoteToken} from '../interfaces/IVoteToken.sol';
import {ReentrancyGuard} from '@openzeppelin/contracts/utils/ReentrancyGuard.sol';
import {LowGasSafeMath} from '../lib/LowGasSafeMath.sol';
import {Context} from '@openzeppelin/contracts/utils/Context.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
import {Address} from '@openzeppelin/contracts/utils/Address.sol';

/**
 * @title VoteToken
 * @notice Custom token which tracks voting power for governance
 * @dev This is an abstraction of a fork of the Compound governance contract
 * VoteToken is used by BABL to allow tracking voting power
 * Checkpoints are created every time state is changed which record voting power
 * Inherits standard ERC20 behavior
 */

abstract contract VoteToken is Context, ERC20, Ownable, IVoteToken, ReentrancyGuard {
    using LowGasSafeMath for uint256;
    using Address for address;

    /* ============ Events ============ */

    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /* ============ Modifiers ============ */

    /* ============ State Variables ============ */

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256('EIP712Domain(string name,uint256 chainId,address verifyingContract)');

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256('Delegation(address delegatee,uint256 nonce,uint256 expiry)');

    /// @dev A record of votes checkpoints for each account, by index
    mapping(address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /* ============ Functions ============ */

    /* ============ Constructor ============ */

    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {}

    /* ============ External Functions ============ */

    /* ===========  Token related Gov Functions ====== */

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegating votes from msg.sender to delegatee
     *
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */

    function delegate(address delegatee) external override {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * PRIVILEGED GOVERNANCE FUNCTION. Delegate votes using signature to 'delegatee'
     *
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external override {
        address signatory;
        bytes32 domainSeparator =
            keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked('\x19\x01', domainSeparator, structHash));
        if (prefix) {
            bytes32 digestHash = keccak256(abi.encodePacked('\x19Ethereum Signed Message:\n32', digest));
            signatory = ecrecover(digestHash, v, r, s);
        } else {
            signatory = ecrecover(digest, v, r, s);
        }

        require(balanceOf(signatory) > 0, 'VoteToken::delegateBySig: invalid delegator');
        require(signatory != address(0), 'VoteToken::delegateBySig: invalid signature');
        require(nonce == nonces[signatory], 'VoteToken::delegateBySig: invalid nonce');
        nonces[signatory]++;
        require(block.timestamp <= expiry, 'VoteToken::delegateBySig: signature expired');
        return _delegate(signatory, delegatee);
    }

    /**
     * GOVERNANCE FUNCTION. Check Delegate votes using signature to 'delegatee'
     *
     * @notice Get current voting power for an account
     * @param account Account to get voting power for
     * @return Voting power for an account
     */
    function getCurrentVotes(address account) external view virtual override returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * GOVERNANCE FUNCTION. Get voting power at a specific block for an account
     *
     * @param account Account to get voting power for
     * @param blockNumber Block to get voting power at
     * @return Voting power for an account at specific block
     */
    function getPriorVotes(address account, uint256 blockNumber) external view virtual override returns (uint96) {
        require(blockNumber < block.number, 'BABLToken::getPriorVotes: not yet determined');
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function getMyDelegatee() external view override returns (address) {
        return delegates[msg.sender];
    }

    function getDelegatee(address account) external view override returns (address) {
        return delegates[account];
    }

    function getCheckpoints(address account, uint32 id)
        external
        view
        override
        returns (uint32 fromBlock, uint96 votes)
    {
        Checkpoint storage getCheckpoint = checkpoints[account][id];
        return (getCheckpoint.fromBlock, getCheckpoint.votes);
    }

    function getNumberOfCheckpoints(address account) external view override returns (uint32) {
        return numCheckpoints[account];
    }

    /* ============ Internal Only Function ============ */

    /**
     * GOVERNANCE FUNCTION. Make a delegation
     *
     * @dev Internal function to delegate voting power to an account
     * @param delegator The address of the account delegating votes from
     * @param delegatee The address to delegate votes to
     */

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = safe96(_balanceOf(delegator), 'VoteToken::_delegate: uint96 overflow');
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _balanceOf(address account) internal view virtual returns (uint256) {
        return balanceOf(account);
    }

    /**
     * GOVERNANCE FUNCTION. Move the delegates
     *
     * @dev Internal function to move delegates between accounts
     * @param srcRep The address of the account delegating votes from
     * @param dstRep The address of the account delegating votes to
     * @param amount The voting power to move
     */
    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            // It must not revert but do nothing in cases of address(0) being part of the move
            // Sub voting amount to source in case it is not the zero address (e.g. transfers)
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, 'VoteToken::_moveDelegates: vote amount underflows');
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                // Add it to destination in case it is not the zero address (e.g. any transfer of tokens or delegations except a first mint to a specific address)
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, 'VoteToken::_moveDelegates: vote amount overflows');
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    /**
     * GOVERNANCE FUNCTION. Internal function to write a checkpoint for voting power
     *
     * @dev internal function to write a checkpoint for voting power
     * @param delegatee The address of the account delegating votes to
     * @param nCheckpoints The num checkpoint
     * @param oldVotes The previous voting power
     * @param newVotes The new voting power
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(block.number, 'VoteToken::_writeCheckpoint: block number exceeds 32 bits');

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint32
     *
     * @dev internal function to convert from uint256 to uint32
     */
    function safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to convert from uint256 to uint96
     *
     * @dev internal function to convert from uint256 to uint96
     */
    function safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    /**
     * INTERNAL FUNCTION. Internal function to add two uint96 numbers
     *
     * @dev internal safe math function to add two uint96 numbers
     */
    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    /**
     * INTERNAL FUNCTION. Internal function to subtract two uint96 numbers
     *
     * @dev internal safe math function to subtract two uint96 numbers
     */
    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * INTERNAL FUNCTION. Internal function to get chain ID
     *
     * @dev internal function to get chain ID
     */
    function getChainId() internal pure returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: Apache-2.0

/*
    Copyright 2020 Set Labs Inc.

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache License, Version 2.0
*/

pragma solidity 0.7.6;

/**
 * @title AddressArrayUtils
 * @author Set Protocol
 *
 * Utility functions to handle Address Arrays
 */
library AddressArrayUtils {
    /**
     * Finds the index of the first occurrence of the given element.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns (index and isIn) for the first occurrence starting from index 0
     */
    function indexOf(address[] memory A, address a) internal pure returns (uint256, bool) {
        uint256 length = A.length;
        for (uint256 i = 0; i < length; i++) {
            if (A[i] == a) {
                return (i, true);
            }
        }
        return (uint256(-1), false);
    }

    /**
     * Returns true if the value is present in the list. Uses indexOf internally.
     * @param A The input array to search
     * @param a The value to find
     * @return Returns isIn for the first occurrence starting from index 0
     */
    function contains(address[] memory A, address a) internal pure returns (bool) {
        (, bool isIn) = indexOf(A, a);
        return isIn;
    }

    /**
     * Returns true if there are 2 elements that are the same in an array
     * @param A The input array to search
     * @return Returns boolean for the first occurrence of a duplicate
     */
    function hasDuplicate(address[] memory A) internal pure returns (bool) {
        require(A.length > 0, 'A is empty');

        for (uint256 i = 0; i < A.length - 1; i++) {
            address current = A[i];
            for (uint256 j = i + 1; j < A.length; j++) {
                if (current == A[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    /**
     * @param A The input array to search
     * @param a The address to remove
     * @return Returns the array with the object removed.
     */
    function remove(address[] memory A, address a) internal pure returns (address[] memory) {
        (uint256 index, bool isIn) = indexOf(A, a);
        if (!isIn) {
            revert('Address not in array.');
        } else {
            (address[] memory _A, ) = pop(A, index);
            return _A;
        }
    }

    /**
     * Removes specified index from array
     * @param A The input array to search
     * @param index The index to remove
     * @return Returns the new array and the removed entry
     */
    function pop(address[] memory A, uint256 index) internal pure returns (address[] memory, address) {
        uint256 length = A.length;
        require(index < A.length, 'Index must be < A length');
        address[] memory newAddresses = new address[](length - 1);
        for (uint256 i = 0; i < index; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = index + 1; j < length; j++) {
            newAddresses[j - 1] = A[j];
        }
        return (newAddresses, A[index]);
    }

    /**
     * Returns the combination of the two arrays
     * @param A The first array
     * @param B The second array
     * @return Returns A extended by B
     */
    function extend(address[] memory A, address[] memory B) internal pure returns (address[] memory) {
        uint256 aLength = A.length;
        uint256 bLength = B.length;
        address[] memory newAddresses = new address[](aLength + bLength);
        for (uint256 i = 0; i < aLength; i++) {
            newAddresses[i] = A[i];
        }
        for (uint256 j = 0; j < bLength; j++) {
            newAddresses[aLength + j] = B[j];
        }
        return newAddresses;
    }

    /*
      Unfortunately Solidity does not support convertion of the fixed array to dynamic array so these functions are
      required. This functionality would be supported in the future so these methods can be removed.
    */
    function toDynamic(address _one, address _two) internal pure returns (address[] memory) {
        address[] memory arr = new address[](2);
        arr[0] = _one;
        arr[1] = _two;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](3);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        return arr;
    }

    function toDynamic(
        address _one,
        address _two,
        address _three,
        address _four
    ) internal pure returns (address[] memory) {
        address[] memory arr = new address[](4);
        arr[0] = _one;
        arr[1] = _two;
        arr[2] = _three;
        arr[3] = _four;
        return arr;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IVoteToken {
    function delegate(address delegatee) external;

    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bool prefix
    ) external;

    function getCurrentVotes(address account) external view returns (uint96);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint96);

    function getMyDelegatee() external view returns (address);

    function getDelegatee(address account) external view returns (address);

    function getCheckpoints(address account, uint32 id) external view returns (uint32 fromBlock, uint96 votes);

    function getNumberOfCheckpoints(address account) external view returns (uint32);
}

interface IVoteTokenWithERC20 is IVoteToken, IERC20 {}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

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

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.7.6;

import {SafeERC20} from '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import {IERC20} from '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import {SafeMath} from '@openzeppelin/contracts/math/SafeMath.sol';

library UniversalERC20 {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal returns (bool) {
        if (amount == 0) {
            return true;
        }

        if (isETH(token)) {
            address(uint160(to)).transfer(amount);
            return true;
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        if (amount == 0) {
            return;
        }

        if (isETH(token)) {
            require(from == msg.sender && msg.value >= amount, 'msg.value is zero');
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        if (!isETH(token)) {
            if (amount > 0 && token.allowance(address(this), to) > 0) {
                token.safeApprove(to, 0);
            }
            token.safeApprove(to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (isETH(token)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function universalDecimals(IERC20 token) internal view returns (uint256) {
        if (isETH(token)) {
            return 18;
        }

        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSignature('decimals()'));

        return success ? abi.decode(data, (uint256)) : 18;
    }

    function isETH(IERC20 token) internal pure returns (bool) {
        return address(token) == address(ZERO_ADDRESS) || address(token) == address(ETH_ADDRESS);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title SignedSafeMath
 * @dev Signed math operations with safety checks that revert on error.
 */
library SignedSafeMath {
    int256 constant private _INT256_MIN = -2**255;

    /**
     * @dev Returns the multiplication of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == -1 && b == _INT256_MIN), "SignedSafeMath: multiplication overflow");

        int256 c = a * b;
        require(c / a == b, "SignedSafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two signed integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "SignedSafeMath: division by zero");
        require(!(b == -1 && a == _INT256_MIN), "SignedSafeMath: division overflow");

        int256 c = a / b;

        return c;
    }

    /**
     * @dev Returns the subtraction of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a), "SignedSafeMath: subtraction overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two signed integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a), "SignedSafeMath: addition overflow");

        return c;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {ICurveMetaRegistry} from './ICurveMetaRegistry.sol';
import {IPickleJarRegistry} from './IPickleJarRegistry.sol';
import {IConvexRegistry} from './IConvexRegistry.sol';
import {IYearnVaultRegistry} from './IYearnVaultRegistry.sol';

/**
 * @title IPriceOracle
 * @author Babylon Finance
 *
 * Interface for interacting with PriceOracle
 */
interface ITokenIdentifier {
    /* ============ View Functions ============ */

    function identifyTokens(address _tokenIn, address _tokenOut)
        external
        view
        returns (
            uint8,
            uint8,
            address,
            address
        );

    function convexPools(address _pool) external view returns (bool);

    function jars(address _jar) external view returns (uint8);

    function pickleGauges(address _gauge) external view returns (bool);

    function visors(address _visor) external view returns (bool);

    function vaults(address _vault) external view returns (bool);

    function aTokenToAsset(address _aToken) external view returns (address);

    function cTokenToAsset(address _cToken) external view returns (address);

    function jarRegistry() external view returns (IPickleJarRegistry);

    function vaultRegistry() external view returns (IYearnVaultRegistry);

    function curveMetaRegistry() external view returns (ICurveMetaRegistry);

    function convexRegistry() external view returns (IConvexRegistry);

    /* ============ Functions ============ */

    function updateVisor(address[] calldata _vaults, bool[] calldata _values) external;

    function refreshAAveReserves() external;

    function refreshCompoundTokens() external;

    function updateYearnVaults() external;

    function updatePickleJars() external;

    function updateConvexPools() external;

    function updateYearnVault(address[] calldata _vaults, bool[] calldata _values) external;

    function updateAavePair(address[] calldata _aaveTokens, address[] calldata _underlyings) external;

    function updateCompoundPair(address[] calldata _cTokens, address[] calldata _underlyings) external;
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title ICurveMetaRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the curve registries
 */
interface ICurveMetaRegistry {
    /* ============ Functions ============ */

    function updatePoolsList() external;

    function updateCryptoRegistries() external;

    /* ============ View Functions ============ */

    function isPool(address _poolAddress) external view returns (bool);

    function gaugeToPool(address _gaugeAddress) external view returns (address);

    function getGauge(address _pool) external view returns (address);

    function getCoinAddresses(address _pool, bool _getUnderlying) external view returns (address[8] memory);

    function getNCoins(address _pool) external view returns (uint256);

    function getLpToken(address _pool) external view returns (address);

    function getPoolFromLpToken(address _lpToken) external view returns (address);

    function getVirtualPriceFromLpToken(address _pool) external view returns (uint256);

    function isMeta(address _pool) external view returns (bool);

    function getUnderlyingAndRate(address _pool, uint256 _i) external view returns (address, uint256);

    function findPoolForCoins(
        address _fromToken,
        address _toToken,
        uint256 _i
    ) external view returns (address);

    function getCoinIndices(
        address _pool,
        address _fromToken,
        address _toToken
    )
        external
        view
        returns (
            uint256,
            uint256,
            bool
        );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IPickleJarRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the pickle jars
 */
interface IPickleJarRegistry {
    /* ============ Functions ============ */

    function updateJars(
        address[] calldata _jars,
        bool[] calldata _values,
        bool[] calldata _uniflags
    ) external;

    /* ============ View Functions ============ */

    function jars(address _jarAddress) external view returns (bool);

    function noSwapParam(address _jarAddress) external view returns (bool);

    function isUniv3(address _jarAddress) external view returns (bool);

    function getJarStrategy(address _jarAddress) external view returns (address);

    function getJarGauge(address _jarAddress) external view returns (address);

    function getJarFromGauge(address _gauge) external view returns (address);

    function getAllJars() external view returns (address[] memory);

    function getAllGauges() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

import {IBooster} from './external/convex/IBooster.sol';

/**
 * @title IConvexRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the convex pools
 */
interface IConvexRegistry {
    /* ============ Functions ============ */

    function updateCache() external;

    /* ============ View Functions ============ */

    function getPid(address _asset) external view returns (bool, uint256);

    function convexPools(address _convexAddress) external view returns (bool);

    function booster() external view returns (IBooster);

    function getRewardPool(address _asset) external view returns (address reward);

    function getConvexInputToken(address _pool) external view returns (address inputToken);

    function getAllConvexPools() external view returns (address[] memory);
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.7.6;

/**
 * @title IYearnVaultRegistry
 * @author Babylon Finance
 *
 * Interface for interacting with all the pickle jars
 */
interface IYearnVaultRegistry {
    /* ============ Functions ============ */

    function updateVaults(address[] calldata _jars, bool[] calldata _values) external;

    /* ============ View Functions ============ */

    function vaults(address _vaultAddress) external view returns (bool);

    function getAllVaults() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

interface IBooster {
    function depositAll(uint256 _pid, bool _stake) external returns (bool);

    function poolInfo(uint256)
        external
        view
        returns (
            address,
            address,
            address,
            address,
            address,
            bool
        );

    function deposit(
        uint256 _pid,
        uint256 _amount,
        bool _stake
    ) external returns (bool);

    function withdraw(uint256 _pid, uint256 _amount) external returns (bool);

    function withdrawAll(uint256 _pid) external returns (bool);

    function poolLength() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}