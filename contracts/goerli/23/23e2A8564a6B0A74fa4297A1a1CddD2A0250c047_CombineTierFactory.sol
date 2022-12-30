// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import {ClonesUpgradeable as Clones} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {Factory} from "../factory/Factory.sol";
import {CombineTier, CombineTierConfig} from "./CombineTier.sol";

/// @title CombineTierFactory
/// @notice Factory for creating and deploying `CombineTier` contracts.
contract CombineTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address public immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new CombineTier());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// @inheritdoc Factory
    function _createChild(
        bytes memory data_
    ) internal virtual override returns (address) {
        CombineTierConfig memory config_ = abi.decode(
            data_,
            (CombineTierConfig)
        );
        address clone_ = Clones.clone(implementation);
        CombineTier(clone_).initialize(config_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with Source.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @return New `CombineTier` child contract address.
    function createChildTyped(
        CombineTierConfig memory config_
    ) external returns (CombineTier) {
        return CombineTier(createChild(abi.encode(config_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import {IFactory} from "./IFactory.sol";
import {ReentrancyGuardUpgradeable as ReentrancyGuard} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

    constructor() {
        // Technically `ReentrancyGuard` is initializable but allowing it to be
        // initialized is a foot-gun as the status will be set to _NOT_ENTERED.
        // This would allow re-entrant behaviour upon initialization of the
        // `Factory` and is unnecessary as the reentrancy guard always restores
        // _NOT_ENTERED after every call anyway.
        _disableInitializers();
    }

    /// Implements `IFactory`.
    ///
    /// `_createChild` hook must be overridden to actually create child
    /// contract.
    ///
    /// Implementers may want to overload this function with a typed equivalent
    /// to expose domain specific structs etc. to the compiled ABI consumed by
    /// tooling and other scripts. To minimise gas costs for deployment it is
    /// expected that the tooling will consume the typed ABI, then encode the
    /// arguments and pass them to this function directly.
    ///
    /// @param data_ ABI encoded data to pass to child contract constructor.
    function _createChild(
        bytes memory data_
    ) internal virtual returns (address);

    /// Implements `IFactory`.
    ///
    /// Calls the `_createChild` hook that inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewChild` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(
        bytes memory data_
    ) public virtual override nonReentrant returns (address) {
        // Create child contract using hook.
        address child_ = _createChild(data_);
        // Ensure the child at this address has not previously been deployed.
        require(!contracts[child_], "DUPLICATE_CHILD");
        // Register child contract address to `contracts` mapping.
        contracts[child_] = true;
        // Emit `NewChild` event with child contract address.
        emit IFactory.NewChild(msg.sender, child_);
        return child_;
    }

    /// Implements `IFactory`.
    ///
    /// Checks if address is registered as a child contract of this factory.
    ///
    /// @param maybeChild_ Address of child contract to look up.
    /// @return Returns `true` if address is a contract created by this
    /// contract factory, otherwise `false`.
    function isChild(
        address maybeChild_
    ) external view virtual override returns (bool) {
        return contracts[maybeChild_];
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

interface IFactory {
    /// Whenever a new child contract is deployed, a `NewChild` event
    /// containing the new child contract address MUST be emitted.
    /// @param sender `msg.sender` that deployed the contract (factory).
    /// @param child address of the newly deployed child.
    event NewChild(address sender, address child);

    /// Factories that clone a template contract MUST emit an event any time
    /// they set the implementation being cloned. Factories that deploy new
    /// contracts without cloning do NOT need to emit this.
    /// @param sender `msg.sender` that deployed the implementation (factory).
    /// @param implementation address of the implementation contract that will
    /// be used for future clones if relevant.
    event Implementation(address sender, address implementation);

    /// Creates a new child contract.
    ///
    /// @param data_ Domain specific data for the child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_) external returns (address);

    /// Checks if address is registered as a child contract of this factory.
    ///
    /// Addresses that were not deployed by `createChild` MUST NOT return
    /// `true` from `isChild`. This is CRITICAL to the security guarantees for
    /// any contract implementing `IFactory`.
    ///
    /// @param maybeChild_ Address to check registration for.
    /// @return `true` if address was deployed by this contract factory,
    /// otherwise `false`.
    function isChild(address maybeChild_) external view returns (bool);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import {TierwiseCombine} from "./libraries/TierwiseCombine.sol";
import {ITierV2} from "./ITierV2.sol";
import {TierV2} from "./TierV2.sol";
import "../interpreter/deploy/IExpressionDeployerV1.sol";
import "../interpreter/run/LibEncodedDispatch.sol";
import "../interpreter/run/LibStackTop.sol";
import "../interpreter/run/LibInterpreterState.sol";
import "../interpreter/run/LibContext.sol";

import {ERC165CheckerUpgradeable as ERC165Checker} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";

SourceIndex constant REPORT_ENTRYPOINT = SourceIndex.wrap(0);
SourceIndex constant REPORT_FOR_TIER_ENTRYPOINT = SourceIndex.wrap(1);

uint256 constant REPORT_MIN_OUTPUTS = 1;
uint constant REPORT_MAX_OUTPUTS = 1;

uint constant REPORT_FOR_TIER_MIN_OUTPUTS = 1;
uint constant REPORT_FOR_TIER_MAX_OUTPUTS = 1;

/// All config used during initialization of a CombineTier.
/// @param combinedTiersLength The first N values in the constants array of the
/// stateConfig MUST be all the combined tiers that are known statically. Of
/// course some tier addresses MAY only be known at runtime and so these cannot
/// be included. For those that are included there will be additional deploy
/// time checks to ensure compatibility with each other (i.e. reportUnits).
/// @param stateConfig Source to run for both report and reportForTier as
/// sources 0 and 1 respectively.
struct CombineTierConfig {
    address expressionDeployer;
    address interpreter;
    uint256 combinedTiersLength;
    StateConfig stateConfig;
}

/// @title CombineTier
/// @notice Allows combining the reports from any `ITierV2` contracts.
/// The value at the top of the stack after executing the Rain expression will be
/// used as the return of all `ITierV2` functions exposed by `CombineTier`.
contract CombineTier is TierV2 {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibUint256Array for uint256;
    using LibUint256Array for uint256[];
    using LibInterpreterState for InterpreterState;

    event Initialize(address sender, CombineTierConfig config);

    IInterpreterV1 internal interpreter;
    address internal expression;

    constructor() {
        _disableInitializers();
    }

    function initialize(
        CombineTierConfig calldata config_
    ) external initializer {
        __TierV2_init();
        interpreter = IInterpreterV1(config_.interpreter);
        expression = IExpressionDeployerV1(config_.expressionDeployer)
            .deployExpression(
                config_.stateConfig,
                LibUint256Array.arrayFrom(
                    REPORT_MIN_OUTPUTS,
                    REPORT_FOR_TIER_MIN_OUTPUTS
                )
            );

        // Integrity check for all known combined tiers.
        for (uint256 i_ = 0; i_ < config_.combinedTiersLength; i_++) {
            require(
                ERC165Checker.supportsInterface(
                    address(uint160(config_.stateConfig.constants[i_])),
                    type(ITierV2).interfaceId
                ),
                "ERC165_TIERV2"
            );
        }

        emit Initialize(msg.sender, config_);
    }

    /// @inheritdoc ITierV2
    function report(
        address account_,
        uint256[] memory callerContext_
    ) external view virtual override returns (uint256) {
        (uint[] memory stack_, ) = interpreter.eval(
            LibEncodedDispatch.encode(
                expression,
                REPORT_ENTRYPOINT,
                REPORT_MAX_OUTPUTS
            ),
            LibContext.build(
                uint256(uint160(account_)).arrayFrom().matrixFrom(),
                callerContext_,
                new SignedContext[](0)
            )
        );
        return stack_.asStackTopAfter().peek();
    }

    /// @inheritdoc ITierV2
    function reportTimeForTier(
        address account_,
        uint256 tier_,
        uint256[] memory callerContext_
    ) external view returns (uint256) {
        (uint[] memory stack_, ) = interpreter.eval(
            LibEncodedDispatch.encode(
                expression,
                REPORT_FOR_TIER_ENTRYPOINT,
                REPORT_FOR_TIER_MAX_OUTPUTS
            ),
            LibContext.build(
                LibUint256Array
                    .arrayFrom(uint256(uint160(account_)), tier_)
                    .matrixFrom(),
                callerContext_,
                new SignedContext[](0)
            )
        );
        return stack_.asStackTopAfter().peek();
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./TierReport.sol";
import "../../math/SaturatingMath.sol";

library TierwiseCombine {
    using Math for uint256;
    using SaturatingMath for uint256;

    /// Every lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_EVERY = 0;
    /// Only one lte check in `selectLte` must pass.
    uint256 internal constant LOGIC_ANY = 1;

    /// Select the minimum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MIN = 0;
    /// Select the maximum block number from passing blocks in `selectLte`.
    uint256 internal constant MODE_MAX = 1;
    /// Select the first block number that passes in `selectLte`.
    uint256 internal constant MODE_FIRST = 2;

    /// Performs a tierwise saturating subtraction of two reports.
    /// Intepret as "# of blocks older report was held before newer report".
    /// If older report is in fact newer then `0` will be returned.
    /// i.e. the diff cannot be negative, older report as simply spent 0 blocks
    /// existing before newer report, if it is in truth the newer report.
    /// @param newerReport_ Block to subtract from.
    /// @param olderReport_ Block to subtract.
    function saturatingSub(
        uint256 newerReport_,
        uint256 olderReport_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 newerBlock_ = TierReport.reportTimeForTier(
                    newerReport_,
                    tier_
                );
                uint256 olderBlock_ = TierReport.reportTimeForTier(
                    olderReport_,
                    tier_
                );
                uint256 diff_ = newerBlock_.saturatingSub(olderBlock_);
                ret_ = TierReport.updateTimeAtTier(ret_, tier_ - 1, diff_);
            }
            return ret_;
        }
    }

    /// Given a list of reports, selects the best tier in a tierwise fashion.
    /// The "best" criteria can be configured by `logic_` and `mode_`.
    /// Logic can be "every" or "any", which means that the reports for a given
    /// tier must either all or any be less than or equal to the reference
    /// `blockNumber_`.
    /// Mode can be "min", "max", "first" which selects between all the block
    /// numbers for a given tier that meet the lte criteria.
    /// IMPORTANT: If the output of `selectLte` is used to write to storage
    /// care must be taken to ensure that "upcoming" tiers relative to the
    /// `blockNumber_` are not overwritten inappropriately. Typically this
    /// function should be used as a filter over reads only from an upstream
    /// source of truth.
    /// @param reports_ The list of reports to select over.
    /// @param blockNumber_ The block number that tier blocks must be lte.
    /// @param logic_ `LOGIC_EVERY` or `LOGIC_ANY`.
    /// @param mode_ `MODE_MIN`, `MODE_MAX` or `MODE_FIRST`.
    function selectLte(
        uint256 logic_,
        uint256 mode_,
        uint256 blockNumber_,
        uint256[] memory reports_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 ret_;
            uint256 block_;
            bool anyLte_;
            uint256 length_ = reports_.length;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 accumulator_;
                // Nothing lte the reference block for this tier yet.
                anyLte_ = false;

                // Initialize the accumulator for this tier.
                if (mode_ == MODE_MIN) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                } else {
                    accumulator_ = 0;
                }

                // Filter all the blocks at the current tier from all the
                // reports against the reference tier and each other.
                for (uint256 i_ = 0; i_ < length_; i_++) {
                    block_ = TierReport.reportTimeForTier(reports_[i_], tier_);

                    if (block_ <= blockNumber_) {
                        // Min and max need to compare current value against
                        // the accumulator.
                        if (mode_ == MODE_MIN) {
                            accumulator_ = block_.min(accumulator_);
                        } else if (mode_ == MODE_MAX) {
                            accumulator_ = block_.max(accumulator_);
                        } else if (mode_ == MODE_FIRST && !anyLte_) {
                            accumulator_ = block_;
                        }
                        anyLte_ = true;
                    } else if (logic_ == LOGIC_EVERY) {
                        // Can short circuit for an "every" check.
                        accumulator_ = TierConstants.NEVER_REPORT;
                        break;
                    }
                }
                if (!anyLte_) {
                    accumulator_ = TierConstants.NEVER_REPORT;
                }
                ret_ = TierReport.updateTimeAtTier(
                    ret_,
                    tier_ - 1,
                    accumulator_
                );
            }
            return ret_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {ITierV2} from "../ITierV2.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtTimeFromReport`: Returns the highest status achieved relative to
/// a block timestamp and report. Statuses gained after that block are ignored.
/// - `tierTime`: Returns the timestamp that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateTimesForTierRange`: Updates a report with a timestamp for every
///    tier in a range.
/// - `updateReportWithTierAtTime`: Updates a report to a new tier.
/// @dev Utilities to consistently read, write and manipulate tiers in reports.
/// The low-level bit shifting can be difficult to get right so this
/// factors that out.
library TierReport {
    /// Enforce upper limit on tiers so we can do unchecked math.
    /// @param tier_ The tier to enforce bounds on.
    modifier maxTier(uint256 tier_) {
        require(tier_ <= TierConstants.MAX_TIER, "MAX_TIER");
        _;
    }

    /// Returns the highest tier achieved relative to a block timestamp
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.timestamp` but not always. Tiers gained after the
    /// reference time are ignored.
    ///
    /// When the `report` comes from a later block than the `timestamp_` this
    /// means the user must have held the tier continuously from `timestamp_`
    /// _through_ to the report time.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITierV2`.
    /// @param timestamp_ The timestamp to check the tiers against.
    /// @return tier_ The highest tier held since `timestamp_` as per `report`.
    function tierAtTimeFromReport(
        uint256 report_,
        uint256 timestamp_
    ) internal pure returns (uint256 tier_) {
        unchecked {
            for (tier_ = 0; tier_ < 8; tier_++) {
                if (uint32(uint256(report_ >> (tier_ * 32))) > timestamp_) {
                    break;
                }
            }
        }
    }

    /// Returns the timestamp that a given tier has been held since from a
    /// report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtTimeFromReport`.
    ///
    /// @param report_ The report to read a timestamp from.
    /// @param tier_ The Tier to read the timestamp for.
    /// @return The timestamp the tier has been held since.
    function reportTimeForTier(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            // ZERO is a special case. Everyone has always been at least ZERO,
            // since block 0.
            if (tier_ == 0) {
                return 0;
            }

            uint256 offset_ = (tier_ - 1) * 32;
            return uint256(uint32(uint256(report_ >> offset_)));
        }
    }

    /// Resets all the tiers above the reference tier to 0xFFFFFFFF.
    ///
    /// @param report_ Report to truncate with high bit 1s.
    /// @param tier_ Tier to truncate above (exclusive).
    /// @return Truncated report.
    function truncateTiersAbove(
        uint256 report_,
        uint256 tier_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a timestamp for a given tier.
    /// More gas efficient than `updateTimesForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the time for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param timestamp_ The new block number for `tier_`.
    /// @return The newly updated `report_`.
    function updateTimeAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 timestamp_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            return
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIME) << offset_)) |
                uint256(timestamp_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param timestamp_ The timestamp to set for every tier in the range.
    /// @return The updated report.
    function updateTimesForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure maxTier(endTier_) returns (uint256) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIME) << offset_
                        )) |
                    uint256(timestamp_ << offset_);
            }
            return report_;
        }
    }

    /// Updates a report to a new status.
    ///
    /// Internally dispatches to `truncateTiersAbove` and
    /// `updateBlocksForTierRange`.
    /// The dispatch is based on whether the new tier is above or below the
    /// current tier.
    /// The `startTier_` MUST match the result of `tierAtBlockFromReport`.
    /// It is expected the caller will know the current tier when
    /// calling this function and need to do other things in the calling scope
    /// with it.
    ///
    /// @param report_ The report to update.
    /// @param startTier_ The tier to start updating relative to. Data above
    /// this tier WILL BE LOST so probably should be the current tier.
    /// @param endTier_ The new highest tier held, at the given timestamp_.
    /// @param timestamp_ The timestamp_ to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtTime(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 timestamp_
    ) internal pure returns (uint256) {
        return
            endTier_ < startTier_
                ? truncateTiersAbove(report_, endTier_)
                : updateTimesForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    timestamp_
                );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITierV2
/// @notice `ITierV2` is a simple interface that contracts can implement to
/// provide membership lists for other contracts.
///
/// There are many use-cases for a time-preserving conditional membership list.
///
/// Some examples include:
///
/// - Self-serve whitelist to participate in fundraising
/// - Lists of users who can claim airdrops and perks
/// - Pooling resources with implied governance/reward tiers
/// - POAP style attendance proofs allowing access to future exclusive events
///
/// @dev Standard interface to a tiered membership.
///
/// A "membership" can represent many things:
/// - Exclusive access.
/// - Participation in some event or process.
/// - KYC completion.
/// - Combination of sub-memberships.
/// - Etc.
///
/// The high level requirements for a contract implementing `ITierV2`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the time each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the time data is erased for that tier and will be
///     set if/when the tier is regained to the new time.
///   - If a tier is held but the historical time information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
///   - Context can be a list of numbers that MAY pairwise define tiers such as
///     minimum thresholds, or MAY simply provide global context such as a
///     relevant NFT ID for example.
/// - MUST implement `reportTimeForTier`
///   - Functions exactly as `report` but only returns a single time for a
///     single tier
///   - MUST return the same time value `report` would for any given tier and
///     context combination.
///
/// So the four possible states and report values are:
/// - Tier is held and time is known: Timestamp is in the report
/// - Tier is held but time is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
///
/// The reason `context` is specified as a list of values rather than arbitrary
/// bytes is to allow clear and efficient compatibility with interpreter stacks.
/// Some N values can be taken from an interpreter stack and used directly as a
/// context, which would be difficult or impossible to ensure is safe for
/// arbitrary bytes.
interface ITierV2 {
    /// Same as report but only returns the time for a single tier.
    /// Often the implementing contract can calculate a single tier more
    /// efficiently than all 8 tiers. If the consumer only needs one or a few
    /// tiers it MAY be much cheaper to request only those tiers individually.
    /// This DOES NOT apply to all contracts, an obvious example is token
    /// balance based tiers which always return `ALWAYS` or `NEVER` for all
    /// tiers so no efficiency is gained.
    /// The return value is a `uint256` for gas efficiency but the values will
    /// be bounded by `type(uint32).max` as no single tier can report a value
    /// higher than this.
    function reportTimeForTier(
        address account,
        uint256 tier,
        uint256[] calldata context
    ) external view returns (uint256 time);

    /// Returns an 8 tier encoded report of 32 bit timestamps for the given
    /// account.
    ///
    /// Same as `ITier` (legacy interface) but with a list of values for
    /// `context` which allows a single underlying state to present many
    /// different reports dynamically.
    ///
    /// For example:
    /// - Staking ledgers can calculate different tier thresholds
    /// - NFTs can give different tiers based on different IDs
    /// - Snapshot ERC20s can give different reports based on snapshot ID
    ///
    /// `context` supercedes `setTier` function and `TierChange` event from
    /// `ITier` at the interface level.
    function report(
        address account,
        uint256[] calldata context
    ) external view returns (uint256 report);
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier time.
    uint32 internal constant NEVER_TIME = type(uint32).max;

    /// Always is 0 as negative timestamps are not possible/supported onchain.
    /// Tiers can't predate the chain but they can predate an `ITierV2`
    /// contract.
    uint256 internal constant ALWAYS = 0;

    /// Account has never held a tier.
    uint256 internal constant TIER_ZERO = 0;

    /// Magic number for tier one.
    uint256 internal constant TIER_ONE = 1;
    /// Magic number for tier two.
    uint256 internal constant TIER_TWO = 2;
    /// Magic number for tier three.
    uint256 internal constant TIER_THREE = 3;
    /// Magic number for tier four.
    uint256 internal constant TIER_FOUR = 4;
    /// Magic number for tier five.
    uint256 internal constant TIER_FIVE = 5;
    /// Magic number for tier six.
    uint256 internal constant TIER_SIX = 6;
    /// Magic number for tier seven.
    uint256 internal constant TIER_SEVEN = 7;
    /// Magic number for tier eight.
    uint256 internal constant TIER_EIGHT = 8;
    /// Maximum tier is `TIER_EIGHT`.
    uint256 internal constant MAX_TIER = TIER_EIGHT;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title SaturatingMath
/// @notice Sometimes we neither want math operations to error nor wrap around
/// on an overflow or underflow. In the case of transferring assets an error
/// may cause assets to be locked in an irretrievable state within the erroring
/// contract, e.g. due to a tiny rounding/calculation error. We also can't have
/// assets underflowing and attempting to approve/transfer "infinity" when we
/// wanted "almost or exactly zero" but some calculation bug underflowed zero.
/// Ideally there are no calculation mistakes, but in guarding against bugs it
/// may be safer pragmatically to saturate arithmatic at the numeric bounds.
/// Note that saturating div is not supported because 0/0 is undefined.
library SaturatingMath {
    /// Saturating addition.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ + b_ and max uint256.
    function saturatingAdd(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being
            // zero, but the benefit is lost if 'b' is also tested.
            // https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a_ == 0) return 0;
            uint256 c_ = a_ * b_;
            return c_ / a_ != b_ ? type(uint256).max : c_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {ERC165Upgradeable as ERC165} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./ITierV2.sol";

abstract contract TierV2 is ITierV2, ERC165 {
    // solhint-disable-next-line func-name-mixedcase
    function __TierV2_init() internal onlyInitializing {
        __ERC165_init();
    }

    // @inheritdoc ERC165
    function supportsInterface(
        bytes4 interfaceId_
    ) public view virtual override returns (bool) {
        return
            interfaceId_ == type(ITierV2).interfaceId ||
            super.supportsInterface(interfaceId_);
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

/// Config required to build a new `State`.
/// @param sources Sources verbatim. These sources MUST be provided in their
/// sequential/index opcode form as the deployment process will need to index
/// into BOTH the integrity check and the final runtime function pointers.
/// This will be emitted in an event for offchain processing to use the indexed
/// opcode sources.
/// @param constants Constants verbatim. Constants are provided alongside sources
/// rather than inline as it allows us to avoid variable length opcodes and can
/// be more memory efficient if the same constant is referenced several times
/// from the sources.
struct StateConfig {
    bytes[] sources;
    uint256[] constants;
}

/// @title IExpressionDeployerV1
/// @notice Expressions are expected to be deployed onchain as immutable contract
/// code with a first class address like any other contract or account.
/// Technically this is optional in the sense that all the tools required to
/// eval some expression and define all its opcodes are available as libraries.
///
/// In practise there are enough advantages to deploying the sources directly
/// onchain as contract data and loading them from the interpreter at eval time:
///
/// - Loading and storing binary data is gas efficient as immutable contract data
/// - Expressions need to be immutable between their deploy time integrity check
///   and runtime evaluation
/// - Passing the address of an expression through calldata to an interpreter is
///   cheaper than passing an entire expression through calldata
/// - Conceptually a very simple approach, even if implementations like SSTORE2
///   are subtle under the hood
///
/// The expression deployer MUST perform an integrity check of the source code
/// before it puts the expression onchain at a known address. The integrity check
/// MUST at a minimum (it is free to do additional static analysis) calculate the
/// memory required to be allocated for the stack in total, and that no out of
/// bounds memory reads/writes occur within this stack. A simple example of an
/// invalid source would be one that pushes one value to the stack then attempts
/// to pops two values, clearly we cannot remove more values than we added.
///
/// Once the integrity check is complete the deployer MUST do any additional
/// processing required by its paired interpreter. For example, the expression
/// deployer MAY NEED to replace the indexed opcodes in the `StateConfig` sources
/// with real function pointers from the corresponding interpreter.
///
/// Interpreters MUST assume that expression deployers are malicious and fail
/// gracefully if the integrity check is corrupt/bypassed and/or function
/// pointers are incorrect, etc. i.e. the interpreter MUST always return a stack
/// from `eval` in a read only way or error. I.e. it is the expression deployer's
/// responsibility to do everything it can to prevent undefined behaviour in the
/// interpreter, and the interpreter's responsibility to handle the expression
/// deployer completely failing to do so.
interface IExpressionDeployerV1 {
    function deployExpression(
        StateConfig memory config,
        uint[] memory minOutputs
    ) external returns (address expressionAddress);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "./IInterpreterV1.sol";

library LibEncodedDispatch {
    function encode(
        address expressionPointer_,
        SourceIndex sourceIndex_,
        uint maxOutputs_
    ) internal pure returns (EncodedDispatch) {
        return
            EncodedDispatch.wrap(
                (uint(uint160(expressionPointer_)) << 32) |
                    (SourceIndex.unwrap(sourceIndex_) << 16) |
                    maxOutputs_
            );
    }

    function decode(
        EncodedDispatch dispatch_
    ) internal pure returns (address, SourceIndex, uint) {
        return (
            address(uint160(EncodedDispatch.unwrap(dispatch_) >> 32)),
            SourceIndex.wrap((EncodedDispatch.unwrap(dispatch_) >> 16) & 0xFF),
            EncodedDispatch.unwrap(dispatch_) & 0xFF
        );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

type SourceIndex is uint256;
type EncodedDispatch is uint256;
type StateNamespace is uint256;
type Operand is uint256;

interface IInterpreterV1 {
    function functionPointers() external view returns (bytes memory);

    function eval(
        EncodedDispatch dispatch,
        uint256[][] calldata context
    )
        external
        view
        returns (uint256[] memory stack, uint256[] memory stateChanges);

    function stateChanges(uint[] calldata stateChanges) external;

    function evalWithNamespace(
        StateNamespace namespace,
        EncodedDispatch dispatch,
        uint256[][] calldata context
    )
        external
        view
        returns (uint256[] memory stack, uint256[] memory stateChanges);

    function stateChangesWithNamespace(
        StateNamespace namespace,
        uint256[] calldata stateChanges
    ) external;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "./IInterpreterV1.sol";
import "../../array/LibUint256Array.sol";
import "../../bytes/LibBytes.sol";

/// Custom type to point to memory ostensibly in a stack.
type StackTop is uint256;

/// @title LibStackTop
/// @notice A `StackTop` is just a pointer to some memory. Ostensibly it is the
/// top of some stack used by the `RainInterpreter` so that means it can move "up" and
/// "down" (increment and decrement) by `uint256` (32 bytes) increments. In
/// general we're abusing that concept a bit to extend to things like the bottom
/// of a stack or a hypothetical maximum stack or even treating an arbitrary
/// `uint256[]` array as "a stack". In the future it's likely this lib and
/// concept will be renamed to reflect that it is used much more generally than
/// simply the top of some stack.
/// All the functions in `LibStackTop` operate on memory to read/write what is
/// referenced but the pointers and values themselves are typically input/output
/// of the functions. I.e. the stack top itself is not being mutated in-place,
/// typically the caller would have both the input stack top and the output
/// stack top in scope after calling library functions.
/// Most of the functions in this library are equivalent to each other via
/// composition, i.e. everything could be achieved with just `up`, `down`,
/// `pop`, `push`, `peek`. The reason there is so much duplication of logic is
/// that the Solidity compiler seems to fail at inlining equivalent logic quite
/// a lot sadly. There appears to be effort upstream towards improving the
/// function inlining by the optimizer so we should expect a lot of this library
/// to become redundant or even counterproductive in the future.
library LibStackTop {
    using LibStackTop for StackTop;
    using LibStackTop for uint256[];
    using LibStackTop for bytes;
    using LibUint256Array for uint256[];
    using LibBytes for uint256;

    /// Reads the value above the stack top. If the stack top is the current
    /// true stack top this is an out of bounds read. This is only useful if
    /// the stack was first moved down and the value it moved past needs to be
    /// read as part of the current operation.
    /// @param stackTop_ Position to read past/above.
    function peekUp(StackTop stackTop_) internal pure returns (uint256 a_) {
        assembly ("memory-safe") {
            a_ := mload(stackTop_)
        }
    }

    /// Read the value immediately below the given stack top. Equivalent to
    /// calling `pop` and discarding the `stackTopAfter_` value, so may be
    /// less gas than setting and discarding a value.
    /// @param stackTop_ The stack top to read below.
    /// @return a_ The value that was read.
    function peek(StackTop stackTop_) internal pure returns (uint256 a_) {
        assembly ("memory-safe") {
            a_ := mload(sub(stackTop_, 0x20))
        }
    }

    /// Reads 2 values below the given stack top.
    /// The following statements are equivalent but A may use gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// (uint a_, uint b_) = stackTop_.peek2();
    /// ```
    /// B:
    /// ```
    /// uint b_;
    /// (stackTop_, b_) = stackTop_.pop();
    /// uint a_ = stackTop_.peek();
    /// ```
    /// @param stackTop_ The stack top to peek below.
    function peek2(
        StackTop stackTop_
    ) internal pure returns (uint256 a_, uint256 b_) {
        assembly ("memory-safe") {
            a_ := mload(sub(stackTop_, 0x40))
            b_ := mload(sub(stackTop_, 0x20))
        }
    }

    /// Read the value immediately below the given stack top and return the
    /// stack top that points to the value that was read alongside the value.
    /// The following are equivalent but A may be cheaper if the compiler
    /// fails to inline some function calls:
    /// A:
    /// ```
    /// uint a_;
    /// (stackTop_, a_) = stackTop_.pop();
    /// ```
    /// B:
    /// ```
    /// stackTop_ = stackTop_.down();
    /// uint a_ = stackTop_.peekUp();
    /// ```
    /// @param stackTop_ The stack top to read below.
    /// @return stackTopAfter_ The stack top that points to the value that was
    /// read.
    /// @return a_ The value that was read.
    function pop(
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_, uint256 a_) {
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, 0x20)
            a_ := mload(stackTopAfter_)
        }
    }

    function consumeSentinel(
        StackTop stackTop_,
        StackTop stackBottom_,
        uint256 sentinel_,
        uint256 stepSize_
    ) internal pure returns (StackTop, uint256[] memory) {
        uint256[] memory array_;
        assembly ("memory-safe") {
            // Underflow is not allowed and pointing at position 0 in memory is
            // corrupt behaviour anyway.
            if iszero(stackBottom_) {
                revert(0, 0)
            }
            let sentinelLocation_ := 0
            let length_ := 0
            let step_ := mul(stepSize_, 0x20)
            for {
                stackTop_ := sub(stackTop_, 0x20)
                let end_ := sub(stackBottom_, 0x20)
            } gt(stackTop_, end_) {
                stackTop_ := sub(stackTop_, step_)
                length_ := add(length_, stepSize_)
            } {
                if eq(sentinel_, mload(stackTop_)) {
                    sentinelLocation_ := stackTop_
                    break
                }
            }
            // Sentinel MUST exist in the stack if consumer expects it to there.
            if iszero(sentinelLocation_) {
                revert(0, 0)
            }
            mstore(sentinelLocation_, length_)
            array_ := sentinelLocation_
        }
        return (stackTop_, array_);
    }

    function consumeStructs(
        StackTop stackTop_,
        StackTop stackBottom_,
        uint256 sentinel_,
        uint256 structSize_
    ) internal pure returns (StackTop, uint256[] memory) {
        uint256[] memory tempArray_;
        (stackTop_, tempArray_) = stackTop_.consumeSentinel(
            stackBottom_,
            sentinel_,
            structSize_
        );
        uint256 structsLength_ = tempArray_.length / structSize_;
        uint256[] memory refs_ = new uint256[](structsLength_);
        assembly ("memory-safe") {
            for {
                let refCursor_ := add(refs_, 0x20)
                let refEnd_ := add(refCursor_, mul(structsLength_, 0x20))
                let tempCursor_ := add(tempArray_, 0x20)
                let tempStepSize_ := mul(structSize_, 0x20)
            } lt(refCursor_, refEnd_) {
                refCursor_ := add(refCursor_, 0x20)
                tempCursor_ := add(tempCursor_, tempStepSize_)
            } {
                mstore(refCursor_, tempCursor_)
            }
        }
        return (stackTop_, refs_);
    }

    /// Write a value at the stack top location. Typically not useful if the
    /// given stack top is not subsequently moved past the written value , or
    /// if the given stack top is actually located somewhere below the "true"
    /// stack top.
    /// @param stackTop_ The stack top to write the value at.
    /// @param a_ The value to write.
    function set(StackTop stackTop_, uint256 a_) internal pure {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
        }
    }

    /// Store a `uint256` at the stack top position and return the stack top
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be less gas if the compiler fails to inline
    /// some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(a_);
    /// ```
    /// B:
    /// ```
    /// stackTop_.set(a_);
    /// stackTop_ = stackTop_.up();
    /// ```
    /// @param stackTop_ The stack top to write at.
    /// @param a_ The value to write.
    /// @return The stack top above where `a_` was written to.
    function push(
        StackTop stackTop_,
        uint256 a_
    ) internal pure returns (StackTop) {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
            stackTop_ := add(stackTop_, 0x20)
        }
        return stackTop_;
    }

    /// Store a `uint256[]` at the stack top position and return the stack top
    /// above the written values. The length of the array is NOT written to the
    /// stack, ONLY the array values are copied to the stack. The following
    /// statements are equivalent in functionality but A may be less gas if the
    /// compiler fails to inline some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(array_);
    /// ```
    /// B:
    /// ```
    /// unchecked {
    ///   for (uint i_ = 0; i_ < array_.length; i_++) {
    ///     stackTop_ = stackTop_.push(array_[i_]);
    ///   }
    /// }
    /// ```
    /// @param stackTop_ The stack top to write at.
    /// @param array_ The array of values to write.
    /// @return The stack top above the array.
    function push(
        StackTop stackTop_,
        uint256[] memory array_
    ) internal pure returns (StackTop) {
        array_.unsafeCopyValuesTo(StackTop.unwrap(stackTop_));
        return stackTop_.up(array_.length);
    }

    /// Store a `uint256[]` at the stack top position and return the stack top
    /// above the written values. The length of the array IS written to the
    /// stack.
    /// @param stackTop_ The stack top to write at.
    /// @param array_ The array of values and length to write.
    /// @return The stack top above the array.
    function pushWithLength(
        StackTop stackTop_,
        uint256[] memory array_
    ) internal pure returns (StackTop) {
        return stackTop_.push(array_.length).push(array_);
    }

    /// Store `bytes` at the stack top position and return the stack top above
    /// the written bytes. The length of the bytes is NOT written to the stack,
    /// ONLY the bytes are written. As `bytes` may be of arbitrary length, i.e.
    /// it MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackTop_ The stack top to write at.
    /// @param bytes_ The bytes to write at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPush(
        StackTop stackTop_,
        bytes memory bytes_
    ) internal pure returns (StackTop) {
        StackTop.unwrap(bytes_.asStackTop().up()).unsafeCopyBytesTo(
            StackTop.unwrap(stackTop_),
            bytes_.length
        );
        return stackTop_.upBytes(bytes_.length);
    }

    /// Store `bytes` at the stack top position and return the stack top above
    /// the written bytes. The length of the bytes IS written to the stack in
    /// addition to the bytes. As `bytes` may be of arbitrary length, i.e. it
    /// MAY NOT be a multiple of 32, the push is unaligned. The caller MUST
    /// ensure that this is safe in context of subsequent reads and writes.
    /// @param stackTop_ The stack top to write at.
    /// @param bytes_ The bytes to write with their length at the stack top.
    /// @return The stack top above the written bytes.
    function unalignedPushWithLength(
        StackTop stackTop_,
        bytes memory bytes_
    ) internal pure returns (StackTop) {
        return stackTop_.push(bytes_.length).unalignedPush(bytes_);
    }

    /// Store 8x `uint256` at the stack top position and return the stack top
    /// above the written value. The following statements are equivalent in
    /// functionality but A may be cheaper if the compiler fails to
    /// inline some function calls.
    /// A:
    /// ```
    /// stackTop_ = stackTop_.push(a_, b_, c_, d_, e_, f_, g_, h_);
    /// ```
    /// B:
    /// ```
    /// stackTop_ = stackTop_
    ///   .push(a_)
    ///   .push(b_)
    ///   .push(c_)
    ///   .push(d_)
    ///   .push(e_)
    ///   .push(f_)
    ///   .push(g_)
    ///   .push(h_);
    /// @param stackTop_ The stack top to write at.
    /// @param a_ The first value to write.
    /// @param b_ The second value to write.
    /// @param c_ The third value to write.
    /// @param d_ The fourth value to write.
    /// @param e_ The fifth value to write.
    /// @param f_ The sixth value to write.
    /// @param g_ The seventh value to write.
    /// @param h_ The eighth value to write.
    /// @return The stack top above where `h_` was written.
    function push(
        StackTop stackTop_,
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint256 f_,
        uint256 g_,
        uint256 h_
    ) internal pure returns (StackTop) {
        assembly ("memory-safe") {
            mstore(stackTop_, a_)
            mstore(add(stackTop_, 0x20), b_)
            mstore(add(stackTop_, 0x40), c_)
            mstore(add(stackTop_, 0x60), d_)
            mstore(add(stackTop_, 0x80), e_)
            mstore(add(stackTop_, 0xA0), f_)
            mstore(add(stackTop_, 0xC0), g_)
            mstore(add(stackTop_, 0xE0), h_)
            stackTop_ := add(stackTop_, 0x100)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(Operand, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 location_;
        assembly ("memory-safe") {
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
        }
        a_ = fn_(operand_, a_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Reduce a function N times, reading and writing inputs and the accumulated
    /// result on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param n_ The number of times to apply fn_ to accumulate a final result.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFnN(
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256) fn_,
        uint256 n_
    ) internal view returns (StackTop stackTopAfter_) {
        unchecked {
            uint256 bottom_;
            uint256 cursor_;
            uint256 a_;
            uint256 b_;
            assembly ("memory-safe") {
                bottom_ := sub(stackTop_, mul(n_, 0x20))
                a_ := mload(bottom_)
                stackTopAfter_ := add(bottom_, 0x20)
                cursor_ := stackTopAfter_
            }
            while (cursor_ < StackTop.unwrap(stackTop_)) {
                assembly ("memory-safe") {
                    b_ := mload(cursor_)
                }
                a_ = fn_(a_, b_);
                cursor_ += 0x20;
            }
            assembly ("memory-safe") {
                mstore(bottom_, a_)
            }
        }
    }

    function applyFnN(
        StackTop stackTop_,
        function(uint256) internal view fn_,
        uint256 n_
    ) internal view returns (StackTop stackTopAfter_) {
        uint256 cursor_;
        uint256 a_;
        assembly ("memory-safe") {
            stackTopAfter_ := sub(stackTop_, mul(n_, 0x20))
            cursor_ := stackTopAfter_
        }
        while (cursor_ < StackTop.unwrap(stackTop_)) {
            assembly ("memory-safe") {
                a_ := mload(cursor_)
                cursor_ := add(cursor_, 0x20)
            }
            fn_(a_);
        }
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x40)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
        }
        a_ = fn_(a_, b_, c_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint)
            internal
            view
            returns (uint256) fn_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 c_;
        uint d_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x60)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
            c_ := mload(add(stackTop_, 0x20))
            d_ := mload(add(stackTop_, 0x40))
        }
        a_ = fn_(a_, b_, c_, d_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param operand_ Operand is passed from the source instead of the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256) fn_,
        Operand operand_
    ) internal view returns (StackTop) {
        uint256 a_;
        uint256 b_;
        uint256 location_;
        assembly ("memory-safe") {
            stackTop_ := sub(stackTop_, 0x20)
            location_ := sub(stackTop_, 0x20)
            a_ := mload(location_)
            b_ := mload(stackTop_)
        }
        a_ = fn_(operand_, a_, b_);
        assembly ("memory-safe") {
            mstore(location_, a_)
        }
        return stackTop_;
    }

    function applyFn(
        StackTop stackTop_,
        function(uint256[] memory) internal view returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop stackTopAfter_) {
        (uint256 a_, uint256[] memory tail_) = stackTop_.list(length_);
        uint256 b_ = fn_(tail_);
        return tail_.asStackTop().push(a_).push(b_);
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return stackTopAfter_ The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop stackTopAfter_) {
        (uint256 b_, uint256[] memory tail_) = stackTop_.list(length_);
        stackTopAfter_ = tail_.asStackTop();
        (StackTop location_, uint256 a_) = stackTopAfter_.pop();
        location_.set(fn_(a_, b_, tail_));
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the array to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256) fn_,
        uint256 length_
    ) internal view returns (StackTop) {
        (uint256 c_, uint256[] memory tail_) = stackTop_.list(length_);
        (StackTop stackTopAfter_, uint256 b_) = tail_.asStackTop().pop();
        uint256 a_ = stackTopAfter_.peek();
        stackTopAfter_.down().set(fn_(a_, b_, c_, tail_));
        return stackTopAfter_;
    }

    /// Execute a function, reading and writing inputs and outputs on the stack.
    /// The caller MUST ensure this does not result in unsafe reads and writes.
    /// @param stackTop_ The stack top to read and write to.
    /// @param fn_ The function to run on the stack.
    /// @param length_ The length of the arrays to pass to fn_ from the stack.
    /// @return The new stack top above the outputs of fn_.
    function applyFn(
        StackTop stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory) fn_,
        uint256 length_
    ) internal view returns (StackTop) {
        StackTop csStart_ = stackTop_.down(length_);
        uint256[] memory cs_ = LibUint256Array.copyToNewUint256Array(
            StackTop.unwrap(csStart_),
            length_
        );
        (uint256 a_, uint256[] memory bs_) = csStart_.list(length_);

        uint256[] memory results_ = fn_(a_, bs_, cs_);
        require(results_.length == length_, "BAD_RESULT_LENGTH");
        StackTop bottom_ = bs_.asStackTop();
        LibUint256Array.unsafeCopyValuesTo(results_, StackTop.unwrap(bottom_));
        return bottom_.up(length_);
    }

    /// Returns `length_` values from the stack as an array without allocating
    /// new memory. As arrays always start with their length, this requires
    /// writing the length value to the stack below the array values. The value
    /// that is overwritten in the process is also returned so that data is not
    /// lost. For example, imagine a stack `[ A B C D ]` and we list 2 values.
    /// This will write the stack to look like `[ A 2 C D ]` and return both `B`
    /// and a pointer to `2` represented as a `uint256[]`.
    /// The returned array is ONLY valid for as long as the stack DOES NOT move
    /// back into its memory. As soon as the stack moves up again and writes into
    /// the array it will be corrupt. The caller MUST ensure that it does not
    /// read from the returned array after it has been corrupted by subsequent
    /// stack writes.
    /// @param stackTop_ The stack top to read the values below into an array.
    /// @param length_ The number of values to include in the returned array.
    /// @return head_ The value that was overwritten with the length.
    /// @return tail_ The array constructed from the stack memory.
    function list(
        StackTop stackTop_,
        uint256 length_
    ) internal pure returns (uint256 head_, uint256[] memory tail_) {
        assembly ("memory-safe") {
            tail_ := sub(stackTop_, add(0x20, mul(length_, 0x20)))
            head_ := mload(tail_)
            mstore(tail_, length_)
        }
    }

    /// Cast a `uint256[]` array to a stack top. The stack top will point to the
    /// length of the array, NOT its first value.
    /// @param array_ The array to cast to a stack top.
    /// @return stackTop_ The stack top that points to the length of the array.
    function asStackTop(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := array_
        }
    }

    /// Cast a stack top to an array. The value immediately above the stack top
    /// will be treated as the length of the array, so the proceeding length
    /// values will be the items of the array. The caller MUST ensure the values
    /// above the stack top constitute a valid array. The retured array will be
    /// corrupt if/when the stack subsequently moves into it and writes to those
    /// memory locations. The caller MUST ensure that it does NOT read from the
    /// returned array after the stack writes over it.
    /// @param stackTop_ The stack top that will be cast to an array.
    /// @return array_ The array above the stack top.
    function asUint256Array(
        StackTop stackTop_
    ) internal pure returns (uint256[] memory array_) {
        assembly ("memory-safe") {
            array_ := stackTop_
        }
    }

    /// Cast a stack top to bytes. The value immediately above the stack top will
    /// be treated as the length of the `bytes`, so the proceeding length bytes
    /// will be the data of the `bytes`. The caller MUST ensure the length and
    /// bytes above the stack top constitute valid `bytes` data. The returned
    /// `bytes` will be corrupt if/when the stack subsequently moves into it and
    /// writes to those memory locations. The caller MUST ensure that it does
    /// NOT read from the returned bytes after the stack writes over it.
    /// @param stackTop_ The stack top that will be cast to bytes.
    /// @return bytes_ The bytes above the stack top.
    function asBytes(
        StackTop stackTop_
    ) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := stackTop_
        }
    }

    /// Cast a `uint256[]` array to a stack top after its length. The stack top
    /// will point to the first item of the array, NOT its length.
    /// @param array_ The array to cast to a stack top.
    /// @return stackTop_ The stack top that points to the first item of the array.
    function asStackTopUp(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := add(array_, 0x20)
        }
    }

    function asStackTopAfter(
        uint256[] memory array_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := add(array_, add(0x20, mul(mload(array_), 0x20)))
        }
    }

    /// Cast `bytes` to a stack top. The stack top will point to the length of
    /// the `bytes`, NOT the first byte.
    /// @param bytes_ The `bytes` to cast to a stack top.
    /// @return stackTop_ The stack top that points to the length of the bytes.
    function asStackTop(
        bytes memory bytes_
    ) internal pure returns (StackTop stackTop_) {
        assembly ("memory-safe") {
            stackTop_ := bytes_
        }
    }

    /// Returns the stack top 32 bytes above/past the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @return The stack top 32 bytes above the passed stack top.
    function up(StackTop stackTop_) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + 0x20);
        }
    }

    /// Returns the stack top `n_ * 32` bytes above/past the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The multiplier on the stack movement. MAY be zero.
    /// @return The stack top `n_ * 32` bytes above/past the passed stack top.
    function up(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + 0x20 * n_);
        }
    }

    /// Returns the stack top `n_` bytes above/past the passed stack top.
    /// The returned stack top MAY NOT be aligned with the passed stack top for
    /// subsequent 32 byte reads and writes. The caller MUST ensure that it is
    /// safe to read and write data relative to the returned stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The number of bytes to move.
    /// @return The stack top `n_` bytes above/past the passed stack top.
    function upBytes(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) + n_);
        }
    }

    /// Returns the stack top 32 bytes below/before the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @return The stack top 32 bytes below/before the passed stack top.
    function down(StackTop stackTop_) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) - 0x20);
        }
    }

    /// Returns the stack top `n_ * 32` bytes below/before the passed stack top.
    /// @param stackTop_ The stack top at the starting position.
    /// @param n_ The multiplier on the movement.
    /// @return The stack top `n_ * 32` bytes below/before the passed stack top.
    function down(
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        unchecked {
            return StackTop.wrap(StackTop.unwrap(stackTop_) - 0x20 * n_);
        }
    }

    /// Convert two stack top values to a single stack index. A stack index is
    /// the distance in 32 byte increments between two stack positions. The
    /// calculations assumes the two stack positions are aligned. The caller MUST
    /// ensure the alignment of both values. The calculation is unchecked and MAY
    /// underflow. The caller MUST ensure that the stack top is always above the
    /// stack bottom.
    /// @param stackBottom_ The lower of the two values.
    /// @param stackTop_ The higher of the two values.
    /// @return The stack index as 32 byte distance between the two stack
    /// positions.
    function toIndex(
        StackTop stackBottom_,
        StackTop stackTop_
    ) internal pure returns (uint256) {
        unchecked {
            return
                (StackTop.unwrap(stackTop_) - StackTop.unwrap(stackBottom_)) /
                0x20;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title Uint256Array
/// @notice Things we want to do carefully and efficiently with uint256 arrays
/// that Solidity doesn't give us native tools for.
library LibUint256Array {
    using LibUint256Array for uint256[];

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ a single integer to build an array around.
    /// @return the newly allocated array including a_ as a single item.
    function arrayFrom(uint256 a_) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ the first integer to build an array around.
    /// @param b_ the second integer to build an array around.
    /// @return the newly allocated array including a_ and b_ as the only items.
    function arrayFrom(
        uint256 a_,
        uint256 b_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](3);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](4);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](5);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
        }
        return array_;
    }

    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256 c_,
        uint256 d_,
        uint256 e_,
        uint f_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](6);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
            mstore(add(array_, 0x60), c_)
            mstore(add(array_, 0x80), d_)
            mstore(add(array_, 0xA0), e_)
            mstore(add(array_, 0xC0), f_)
        }
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The head of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](1);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
        }
        array_.extend(tail_);
        return array_;
    }

    /// Building arrays from literal components is a common task that introduces
    /// boilerplate that is either inefficient or error prone.
    /// @param a_ The first item of the new array.
    /// @param b_ The second item of the new array.
    /// @param tail_ The tail of the new array.
    /// @return The new array.
    function arrayFrom(
        uint256 a_,
        uint256 b_,
        uint256[] memory tail_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory array_ = new uint256[](2);
        assembly ("memory-safe") {
            mstore(add(array_, 0x20), a_)
            mstore(add(array_, 0x40), b_)
        }
        array_.extend(tail_);
        return array_;
    }

    function matrixFrom(
        uint256[] memory a_
    ) internal pure returns (uint256[][] memory) {
        uint256[][] memory matrix_ = new uint256[][](1);
        assembly ("memory-safe") {
            mstore(add(matrix_, 0x20), a_)
        }
        return matrix_;
    }

    /// Solidity provides no way to change the length of in-memory arrays but
    /// it also does not deallocate memory ever. It is always safe to shrink an
    /// array that has already been allocated, with the caveat that the
    /// truncated items will effectively become inaccessible regions of memory.
    /// That is to say, we deliberately "leak" the truncated items, but that is
    /// no worse than Solidity's native behaviour of leaking everything always.
    /// The array is MUTATED in place so there is no return value and there is
    /// no new allocation or copying of data either.
    /// @param array_ The array to truncate.
    /// @param newLength_ The new length of the array after truncation.
    function truncate(
        uint256[] memory array_,
        uint256 newLength_
    ) internal pure {
        require(newLength_ <= array_.length, "OOB_TRUNCATE");
        assembly ("memory-safe") {
            mstore(array_, newLength_)
        }
    }

    /// Extends `base_` with `extend_` by allocating additional `extend_.length`
    /// uints onto `base_`. Reverts if some other memory has been allocated
    /// after `base_` already, in which case it is NOT safe to copy inline.
    /// If `base_` is large this MAY be significantly more efficient than
    /// allocating `base_.length + extend_.length` for an entirely new array and
    /// copying both `base_` and `extend_` into the new array one item at a
    /// time in Solidity.
    /// The Solidity compiler MAY rearrange sibling statements in a code block
    /// EVEN IF THE OPTIMIZER IS DISABLED such that it becomes unsafe to use
    /// `extend` for memory allocated in different code blocks. It is ONLY safe
    /// to `extend` arrays that were allocated in the same lexical scope and you
    /// WILL see subtle errors that revert transactions otherwise.
    /// i.e. the `new` keyword MUST appear in the same code block as `extend`.
    /// @param base_ The base integer array that will be extended by `extend_`.
    /// @param extend_ The integer array that extends `base_`.
    function extend(
        uint256[] memory base_,
        uint256[] memory extend_
    ) internal pure {
        uint256 freeMemoryPointer_;
        assembly ("memory-safe") {
            // Solidity stores free memory pointer at 0x40
            freeMemoryPointer_ := mload(0x40)
            let baseLength_ := mload(base_)
            let extendLength_ := mload(extend_)

            // The freeMemoryPointer_ does NOT point to the end of `base_` so
            // it is NOT safe to copy `extend_` over the top of already
            // allocated memory. This happens whenever some memory is allocated
            // after `base_` is allocated but before `extend` is called.
            if gt(
                freeMemoryPointer_,
                add(base_, add(0x20, mul(0x20, baseLength_)))
            ) {
                revert(0, 0)
            }

            // Move the free memory pointer by the length of extend_, excluding
            // the length slot of extend as that will NOT be copied to `base_`.
            mstore(0x40, add(freeMemoryPointer_, mul(0x20, extendLength_)))

            // Update the length of base to be the length of base+extend.
            mstore(base_, add(baseLength_, extendLength_))
        }

        unsafeCopyValuesTo(extend_, freeMemoryPointer_);
    }

    /// Copies `inputs_` to `outputCursor_` with NO attempt to check that this
    /// is safe to do so. The caller MUST ensure that there exists allocated
    /// memory at `outputCursor_` in which it is safe and appropriate to copy
    /// ALL `inputs_` to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(inputs_.length * 32 bytes)]` will be
    /// overwritten. The length of `inputs_` is NOT copied to the output
    /// location, ONLY the `uint256` values of the `inputs_` array are copied.
    /// There is no return value as memory is modified directly.
    /// @param inputs_ The input array that will be copied from EXCLUDING the
    /// length at the start of the array in memory.
    /// @param outputCursor_ Location in memory that the values will be copied
    /// to linearly.
    function unsafeCopyValuesTo(
        uint256[] memory inputs_,
        uint256 outputCursor_
    ) internal pure {
        uint256 inputCursor_;
        assembly ("memory-safe") {
            inputCursor_ := add(inputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, inputs_.length);
    }

    /// Copies `length_` 32 byte words from `inputCursor_` to a newly allocated
    /// uint256[] array with NO attempt to check that the inputs are sane.
    /// This function is safe in that the outputs are guaranteed to be copied
    /// to newly allocated memory so no existing data will be overwritten.
    /// This function is subtle in that the `inputCursor_` is NOT validated in
    /// any way so the caller MUST ensure it points to a sensible memory
    /// location to read (e.g. to exclude the length from input arrays etc.).
    /// @param inputCursor_ The start of the memory that will be copied to the
    /// newly allocated array.
    /// @param length_ Number of 32 byte words to copy starting at
    /// `inputCursor_` to the items of the newly allocated array.
    /// @return The newly allocated `uint256[]` array.
    function copyToNewUint256Array(
        uint256 inputCursor_,
        uint256 length_
    ) internal pure returns (uint256[] memory) {
        uint256[] memory outputs_ = new uint256[](length_);
        uint256 outputCursor_;
        assembly ("memory-safe") {
            outputCursor_ := add(outputs_, 0x20)
        }
        unsafeCopyValuesTo(inputCursor_, outputCursor_, length_);
        return outputs_;
    }

    /// Copies `length_` uint256 values starting from `inputsCursor_` to
    /// `outputCursor_` with NO attempt to check that this is safe to do so.
    /// The caller MUST ensure that there exists allocated memory at
    /// `outputCursor_` in which it is safe and appropriate to copy
    /// `length_ * 32` bytes to. Anything that was already written to memory at
    /// `[outputCursor_:outputCursor_+(length_ * 32 bytes)]` will be
    /// overwritten.
    /// There is no return value as memory is modified directly.
    /// @param inputCursor_ The starting position in memory that data will be
    /// copied from.
    /// @param outputCursor_ The starting position in memory that data will be
    /// copied to.
    /// @param length_ The number of 32 byte (i.e. `uint256`) values that will
    /// be copied.
    function unsafeCopyValuesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 length_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let end_ := add(inputCursor_, mul(0x20, length_))
            } lt(inputCursor_, end_) {
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibBytes
/// @notice Things we want to do carefully and efficiently with `bytes` in memory
/// that Solidity doesn't give us native tools for.
library LibBytes {
    /// Copy an arbitrary number of bytes from one location in memory to another.
    /// As we can only read/write bytes in 32 byte chunks we first have to loop
    /// over 32 byte values to copy then handle any unaligned remaining data. The
    /// remaining data will be appropriately masked with the existing data in the
    /// final chunk so as to not write past the desired length. Note that the
    /// final unaligned write will be more gas intensive than the prior aligned
    /// writes. The writes are completely unsafe, the caller MUST ensure that
    /// sufficient memory is allocated and reading/writing the requested number
    /// of bytes from/to the requested locations WILL NOT corrupt memory in the
    /// opinion of solidity or other subsequent read/write operations.
    /// @param inputCursor_ The starting location in memory to read from.
    /// @param outputCursor_ The starting location in memory to write to.
    /// @param remaining_ The number of bytes to read/write.
    function unsafeCopyBytesTo(
        uint256 inputCursor_,
        uint256 outputCursor_,
        uint256 remaining_
    ) internal pure {
        assembly ("memory-safe") {
            for {

            } iszero(lt(remaining_, 0x20)) {
                remaining_ := sub(remaining_, 0x20)
                inputCursor_ := add(inputCursor_, 0x20)
                outputCursor_ := add(outputCursor_, 0x20)
            } {
                mstore(outputCursor_, mload(inputCursor_))
            }

            if gt(remaining_, 0) {
                let mask_ := shr(
                    mul(remaining_, 8),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
                // preserve existing bytes
                mstore(
                    outputCursor_,
                    or(
                        // input
                        and(mload(inputCursor_), not(mask_)),
                        and(mload(outputCursor_), mask_)
                    )
                )
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/IInterpreterV1.sol";
import "../deploy/IExpressionDeployerV1.sol";
import "./LibStackTop.sol";
import "../../type/LibCast.sol";
import "../../type/LibConvert.sol";
import "../../array/LibUint256Array.sol";
import "../../memory/LibMemorySize.sol";
import {SafeCastUpgradeable as SafeCast} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "../../kv/LibMemoryKV.sol";
import "hardhat/console.sol";

enum DebugStyle {
    Stack,
    Constant,
    Context,
    Source
}

type FullyQualifiedNamespace is uint256;

/// Everything required to evaluate and track the state of a Rain expression.
/// As this is a struct it will be in memory when passed to `RainInterpreter` and so
/// will be modified by reference internally. This is important for gas
/// efficiency; the stack, arguments and stackIndex will likely be mutated by
/// the running expression.
/// @param stackIndex Opcodes write to the stack at the stack index and can
/// consume from the stack by decrementing the index and reading between the
/// old and new stack index.
/// IMPORANT: The stack is never zeroed out so the index must be used to
/// find the "top" of the stack as the result of an `eval`.
/// @param stack Stack is the general purpose runtime state that opcodes can
/// read from and write to according to their functionality.
/// @param sources Sources available to be executed by `eval`.
/// Notably `ZIPMAP` can also select a source to execute by index.
/// @param constants Constants that can be copied to the stack by index by
/// `VAL`.
/// @param arguments `ZIPMAP` populates arguments which can be copied to the
/// stack by `VAL`.
struct InterpreterState {
    StackTop stackBottom;
    StackTop constantsBottom;
    MemoryKV stateKV;
    FullyQualifiedNamespace namespace;
    uint256[][] context;
    bytes[] compiledSources;
}

string constant DEBUG_DELIMETER = "~~~";

library LibInterpreterState {
    using SafeCast for uint256;
    using LibMemorySize for uint256;
    using LibMemorySize for uint256[];
    using LibMemorySize for bytes;
    using LibUint256Array for uint256[];
    using LibUint256Array for uint256;
    using LibInterpreterState for InterpreterState;
    using LibStackTop for uint256[];
    using LibStackTop for StackTop;
    using LibStackTop for bytes;
    using LibCast for uint256;
    using LibCast for function(InterpreterState memory, SourceIndex, StackTop)
        view
        returns (StackTop);
    using LibCast for function(InterpreterState memory, Operand, StackTop)
        view
        returns (StackTop)[];
    using LibConvert for uint256[];

    function debugArray(uint256[] memory array_) internal view {
        console.log(DEBUG_DELIMETER);
        for (uint256 i_ = 0; i_ < array_.length; i_++) {
            console.log(i_, array_[i_]);
        }
        console.log(DEBUG_DELIMETER);
    }

    function debugStack(
        StackTop stackBottom_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        uint256 length_ = stackBottom_.toIndex(stackTop_);
        debugArray(
            StackTop.unwrap(stackTop_.down(length_)).copyToNewUint256Array(
                length_
            )
        );
        return stackTop_;
    }

    function debugStack(
        InterpreterState memory state_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        return debugStack(state_.stackBottom, stackTop_);
    }

    /// Console log various aspects of the Interpreter state.
    /// Gas intensive and relies on hardhat console so not intended for
    /// production but great for debugging Rain expressions.
    function debug(
        InterpreterState memory state_,
        StackTop stackTop_,
        DebugStyle debugStyle_
    ) internal view returns (StackTop) {
        if (debugStyle_ == DebugStyle.Source) {
            for (uint256 i_ = 0; i_ < state_.compiledSources.length; i_++) {
                console.logBytes(state_.compiledSources[i_]);
            }
        } else {
            if (debugStyle_ == DebugStyle.Stack) {
                state_.debugStack(stackTop_);
            } else if (debugStyle_ == DebugStyle.Constant) {
                debugArray(state_.constantsBottom.down().asUint256Array());
            } else {
                for (uint256 i_ = 0; i_ < state_.context.length; i_++) {
                    debugArray(state_.context[i_]);
                }
            }
        }
        return stackTop_;
    }

    function serialize(
        StateConfig memory config_,
        uint256 stackLength_,
        bytes memory opcodeFunctionPointers_
    ) internal pure returns (bytes memory) {
        unchecked {
            uint256 size_ = 0;
            size_ += stackLength_.size();
            size_ += config_.constants.size();
            for (uint256 i_ = 0; i_ < config_.sources.length; i_++) {
                size_ += config_.sources[i_].size();
            }
            bytes memory serialized_ = new bytes(size_);
            StackTop cursor_ = serialized_.asStackTop().up();

            // Copy stack length.
            cursor_ = cursor_.push(stackLength_);

            // Then the constants.
            cursor_ = cursor_.pushWithLength(config_.constants);

            // Last the sources.
            bytes memory source_;
            for (uint256 i_ = 0; i_ < config_.sources.length; i_++) {
                source_ = config_.sources[i_];
                compile(source_, opcodeFunctionPointers_);
                cursor_ = cursor_.unalignedPushWithLength(source_);
            }
            return serialized_;
        }
    }

    function deserialize(
        bytes memory serialized_
    ) internal pure returns (InterpreterState memory) {
        unchecked {
            InterpreterState memory state_;

            // Context will probably be overridden by the caller according to the
            // context scratch that we deserialize so best to just set it empty
            // here.
            state_.context = new uint256[][](0);

            StackTop cursor_ = serialized_.asStackTop().up();
            // The end of processing is the end of the state bytes.
            StackTop end_ = cursor_.upBytes(cursor_.peek());

            // Read the stack length and build a stack.
            cursor_ = cursor_.up();
            uint256 stackLength_ = cursor_.peek();

            // The stack is never stored in stack bytes so we allocate a new
            // array for it with length as per the indexes and point the state
            // at it.
            uint256[] memory stack_ = new uint256[](stackLength_);
            state_.stackBottom = stack_.asStackTopUp();

            // Reference the constants array and move cursor past it.
            cursor_ = cursor_.up();
            state_.constantsBottom = cursor_;
            cursor_ = cursor_.up(cursor_.peek());

            // Rebuild the sources array.
            uint256 i_ = 0;
            StackTop lengthCursor_ = cursor_;
            uint256 sourcesLength_ = 0;
            while (StackTop.unwrap(lengthCursor_) < StackTop.unwrap(end_)) {
                lengthCursor_ = lengthCursor_
                    .upBytes(lengthCursor_.peekUp())
                    .up();
                sourcesLength_++;
            }
            state_.compiledSources = new bytes[](sourcesLength_);
            while (StackTop.unwrap(cursor_) < StackTop.unwrap(end_)) {
                state_.compiledSources[i_] = cursor_.asBytes();
                cursor_ = cursor_.upBytes(cursor_.peekUp()).up();
                i_++;
            }
            return state_;
        }
    }

    /// Given a source in opcodes compile to an equivalent source with real
    /// function pointers for a given Interpreter contract. The "compilation"
    /// involves simply replacing the opcode with the pointer at the index of
    /// the opcode. i.e. opcode 4 will be replaced with `pointers_[4]`.
    /// Relies heavily on the integrity checks ensuring opcodes used are not OOB
    /// and that the pointers provided are valid and in the correct order.
    /// Hopefully it goes without saying that the list of pointers MUST NOT be
    /// user defined, otherwise any source can be compiled with a completely
    /// different mapping between opcodes and dispatched functions.
    function compile(
        bytes memory source_,
        bytes memory pointers_
    ) internal pure {
        assembly ("memory-safe") {
            for {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                let sourceLength_ := mload(source_)
                let pointersBottom_ := add(pointers_, 2)
                let cursor_ := add(source_, 2)
                let end_ := add(source_, sourceLength_)
            } lt(cursor_, end_) {
                cursor_ := add(cursor_, 4)
            } {
                let data_ := mload(cursor_)
                let pointer_ := and(
                    replaceMask_,
                    mload(
                        add(pointersBottom_, mul(2, and(data_, replaceMask_)))
                    )
                )
                mstore(cursor_, or(and(data_, preserveMask_), pointer_))
            }
        }
    }

    /// Evaluates a Rain expression.
    /// The main workhorse of the rain Interpreter, `eval` runs any core opcodes
    /// and dispatches anything it is unaware of to the implementing contract.
    /// For an expression to be useful the implementing contract must override
    /// `applyOp` and dispatch non-core opcodes to domain specific logic. This
    /// could be mathematical operations for a calculator, tier reports for
    /// a membership combinator, entitlements for a minting curve, etc.
    ///
    /// Everything required to coordinate the execution of a Rain expression to
    /// completion is contained in the `State`. The context and source index
    /// are provided so the caller can provide additional data and kickoff the
    /// opcode dispatch from the correct source in `sources`.
    function eval(
        InterpreterState memory state_,
        SourceIndex sourceIndex_,
        StackTop stackTop_
    ) internal view returns (StackTop) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(add(state_, 0xA0)),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                function(InterpreterState memory, Operand, StackTop)
                    internal
                    view
                    returns (StackTop) fn_;
                Operand operand_;
                cursor_ += 4;
                {
                    uint256 op_;
                    assembly ("memory-safe") {
                        op_ := mload(cursor_)
                        operand_ := and(op_, 0xFFFF)
                        fn_ := and(shr(16, op_), 0xFFFF)
                    }
                }
                stackTop_ = fn_(state_, operand_, stackTop_);
            }
            return stackTop_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../interpreter/run/LibStackTop.sol";
import "../interpreter/run/LibInterpreterState.sol";
import "../interpreter/deploy/LibIntegrityState.sol";

/// @title LibCast
/// @notice Additional type casting logic that the Solidity compiler doesn't
/// give us by default. A type cast (vs. conversion) is considered one where the
/// structure is unchanged by the cast. The cast does NOT (can't) check that the
/// input is a valid output, for example any integer MAY be cast to a function
/// pointer but almost all integers are NOT valid function pointers. It is the
/// calling context that MUST ensure the validity of the data, the cast will
/// merely retype the data in place, generally without additional checks.
/// As most structures in solidity have the same memory structure as a `uint256`
/// or fixed/dynamic array of `uint256` there are many conversions that can be
/// done with near zero or minimal overhead.
library LibCast {
    /// Retype an integer to an opcode function pointer.
    /// @param u_ The integer to cast to an opcode function pointer.
    /// @return fn_ The opcode function pointer.
    function asOpFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype an array of integers to an array of opcode function pointers.
    /// @param us_ The array of integers to cast to an array of opcode fuction
    /// pointers.
    /// @return fns_ The array of opcode function pointers.
    function asOpcodeFunctionPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }

    /// Retype an integer to an integrity function pointer.
    /// @param u_ The integer to cast to an integrity function pointer.
    /// @return fn_ The integrity function pointer.
    function asIntegrityFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(IntegrityState memory, Operand, StackTop)
                internal
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype an integer to a pointer to the interpreter eval function.
    /// @param u_ The integer to cast to the eval function.
    /// @return fn_ The eval function.
    function asEvalFunctionPointer(
        uint256 u_
    )
        internal
        pure
        returns (
            function(InterpreterState memory, SourceIndex, StackTop)
                view
                returns (StackTop) fn_
        )
    {
        assembly ("memory-safe") {
            fn_ := u_
        }
    }

    /// Retype a stack move function pointer to an integer.
    /// Provided the origin of the function pointer is solidity and NOT yul, the
    /// returned integer will be valid to run if retyped back via yul. If the
    /// origin of the function pointer is yul then we cannot guarantee anything
    /// about the validity beyond the correctness of the yul code in question.
    ///
    /// Function pointers as integers are NOT portable across contracts as the
    /// code in different contracts is different so function pointers will point
    /// to a different, incompatible part of the code.
    ///
    /// Function pointers as integers lose the information about their signature
    /// so MUST ONLY be called in an appropriate context once restored.
    /// @param fn_ The stack move function pointer to integerify.
    /// @return u_ The integer of the function pointer.
    function asUint256(
        function(uint256) view returns (uint256) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256(
        function(IntegrityState memory, Operand, StackTop)
            internal
            view
            returns (StackTop) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256Array(
        function(IntegrityState memory, Operand, StackTop)
            internal
            view
            returns (StackTop)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asUint256(bool bool_) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := bool_
        }
    }

    function asUint256(
        function(InterpreterState memory, SourceIndex, StackTop)
            view
            returns (StackTop) fn_
    ) internal pure returns (uint256 u_) {
        assembly ("memory-safe") {
            u_ := fn_
        }
    }

    function asUint256Array(
        function(InterpreterState memory, Operand, StackTop)
            view
            returns (StackTop)[]
            memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asUint256Array(
        function(uint256) pure returns (uint256)[] memory fns_
    ) internal pure returns (uint256[] memory us_) {
        assembly ("memory-safe") {
            us_ := fns_
        }
    }

    function asAddresses(
        uint256[] memory us_
    ) internal pure returns (address[] memory addresses_) {
        assembly ("memory-safe") {
            addresses_ := us_
        }
    }

    function asIntegrityPointers(
        uint256[] memory us_
    )
        internal
        pure
        returns (
            function(IntegrityState memory, Operand, StackTop)
                view
                returns (StackTop)[]
                memory fns_
        )
    {
        assembly ("memory-safe") {
            fns_ := us_
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../run/LibStackTop.sol";
import {MathUpgradeable as Math} from "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";

import "../run/IInterpreterV1.sol";

struct IntegrityState {
    // Sources first as we read it in assembly.
    bytes[] sources;
    uint256 constantsLength;
    StackTop stackBottom;
    StackTop stackMaxTop;
    function(IntegrityState memory, Operand, StackTop)
        view
        returns (StackTop)[] integrityFunctionPointers;
}

library LibIntegrityState {
    using LibIntegrityState for IntegrityState;
    using LibStackTop for StackTop;
    using Math for uint256;

    function syncStackMaxTop(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure {
        if (
            StackTop.unwrap(stackTop_) >
            StackTop.unwrap(integrityState_.stackMaxTop)
        ) {
            integrityState_.stackMaxTop = stackTop_;
        }
    }

    function ensureIntegrity(
        IntegrityState memory integrityState_,
        SourceIndex sourceIndex_,
        StackTop stackTop_,
        uint minStackOutputs_
    ) internal view returns (StackTop) {
        unchecked {
            uint256 cursor_;
            uint256 end_;
            assembly ("memory-safe") {
                cursor_ := mload(
                    add(
                        mload(integrityState_),
                        add(0x20, mul(0x20, sourceIndex_))
                    )
                )
                end_ := add(cursor_, mload(cursor_))
            }

            // Loop until complete.
            while (cursor_ < end_) {
                uint256 opcode_;
                Operand operand_;
                cursor_ += 4;
                assembly ("memory-safe") {
                    let op_ := mload(cursor_)
                    operand_ := and(op_, 0xFFFF)
                    opcode_ := and(shr(16, op_), 0xFFFF)
                }
                // We index into the function pointers here to ensure that any
                // opcodes that we don't have a pointer for will error.
                stackTop_ = integrityState_.integrityFunctionPointers[opcode_](
                    integrityState_,
                    operand_,
                    stackTop_
                );
            }
            require(
                minStackOutputs_ <=
                    integrityState_.stackBottom.toIndex(stackTop_),
                "MIN_FINAL_STACK"
            );
            return stackTop_;
        }
    }

    function push(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.up();
        integrityState_.syncStackMaxTop(stackTopAfter_);
    }

    function push(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.up(n_);
        integrityState_.syncStackMaxTop(stackTopAfter_);
    }

    function popUnderflowCheck(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure {
        require(
            // Stack bottom may be non-zero so check we are above it.
            (StackTop.unwrap(stackTop_) >=
                StackTop.unwrap(integrityState_.stackBottom)) &&
                // If we underflowed zero then we will be above the stack max
                // top. Assumes that at least 1 item was popped so we can do a
                // strict inequality check here.
                (StackTop.unwrap(stackTop_) <
                    StackTop.unwrap(integrityState_.stackMaxTop)),
            "STACK_UNDERFLOW"
        );
    }

    function pop(
        IntegrityState memory integrityState_,
        StackTop stackTop_
    ) internal pure returns (StackTop stackTopAfter_) {
        stackTopAfter_ = stackTop_.down();
        integrityState_.popUnderflowCheck(stackTopAfter_);
    }

    function pop(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        uint256 n_
    ) internal pure returns (StackTop) {
        if (n_ > 0) {
            stackTop_ = stackTop_.down(n_);
            integrityState_.popUnderflowCheck(stackTop_);
        }
        return stackTop_;
    }

    function applyFnN(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256),
        uint256 n_
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, n_));
    }

    function applyFnN(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256) internal view,
        uint256 n_
    ) internal pure returns (StackTop) {
        return integrityState_.pop(stackTop_, n_);
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(Operand, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view
    ) internal pure returns (StackTop) {
        return integrityState_.pop(stackTop_, 2);
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 2));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(Operand, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 2));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256) internal view returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 3));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint)
            internal
            view
            returns (uint256)
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, 4));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256[] memory) internal view returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        return integrityState_.push(integrityState_.pop(stackTop_, length_));
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ + 2)
                );
        }
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256, uint256, uint256[] memory)
            internal
            view
            returns (uint256),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ + 3)
                );
        }
    }

    function applyFn(
        IntegrityState memory integrityState_,
        StackTop stackTop_,
        function(uint256, uint256[] memory, uint256[] memory)
            internal
            view
            returns (uint256[] memory),
        uint256 length_
    ) internal pure returns (StackTop) {
        unchecked {
            return
                integrityState_.push(
                    integrityState_.pop(stackTop_, length_ * 2 + 1),
                    length_
                );
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @title LibConvert
/// @notice Type conversions that require additional structural changes to
/// complete safely. These are NOT mere type casts and involve additional
/// reads and writes to complete, such as recalculating the length of an array.
/// The convention "toX" is adopted from Rust to imply the additional costs and
/// consumption of the source to produce the target.
library LibConvert {
    /// Convert an array of integers to `bytes` data. This requires modifying
    /// the length in situ as the integer array length is measured in 32 byte
    /// increments while the length of `bytes` is the literal number of bytes.
    /// @return bytes_ The integer array converted to `bytes` data.
    function toBytes(
        uint256[] memory is_
    ) internal pure returns (bytes memory bytes_) {
        assembly ("memory-safe") {
            bytes_ := is_
            // Length in bytes is 32x the length in uint256
            mstore(bytes_, mul(0x20, mload(bytes_)))
        }
    }

    function unsafeTo16BitBytes(
        uint256[] memory is_
    ) internal pure returns (bytes memory) {
        unchecked {
            // We will keep 2 bytes (16 bits) from each integer.
            bytes memory bytes_ = new bytes(is_.length * 2);
            assembly ("memory-safe") {
                let replaceMask_ := 0xFFFF
                let preserveMask_ := not(replaceMask_)
                for {
                    let cursor_ := add(is_, 0x20)
                    let end_ := add(cursor_, mul(mload(is_), 0x20))
                    let bytesCursor_ := add(bytes_, 0x02)
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    bytesCursor_ := add(bytesCursor_, 0x02)
                } {
                    let data_ := mload(bytesCursor_)
                    mstore(
                        bytesCursor_,
                        or(and(preserveMask_, data_), mload(cursor_))
                    )
                }
            }
            return bytes_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.10;

/// @title LibMemorySize
/// @notice Reports the size in bytes of type data that represents contigious
/// regions of memory. Pointers to regions of memory that may not be congigious
/// are not supported, e.g. fields on structs may point to dynamic data that is
/// separate to the struct. Length slots for dynamic data are included in the
/// size and the size is always measured in bytes.
library LibMemorySize {
    /// Reports the size of a `uint256` in bytes. Is always 32.
    /// @return 32.
    function size(uint256) internal pure returns (uint256) {
        return 0x20;
    }

    /// Reports the size of a `uint256[]` in bytes. Is the size of the length
    /// slot (32 bytes) plus the length of the array multiplied by 32 bytes per
    /// item.
    /// @return The size of the array data including its length slot size.
    function size(uint256[] memory array_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + (array_.length * 0x20);
        }
    }

    /// Reports the size of `bytes` data. Is the size of the length slot
    /// (32 bytes) plus the number of bytes as per its length.
    /// @return The size of the `bytes` data including its length slot size.
    function size(bytes memory bytes_) internal pure returns (uint256) {
        unchecked {
            return 0x20 + bytes_.length;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

import "../math/Binary.sol";

type MemoryKV is uint;
type MemoryKVKey is uint;
type MemoryKVPtr is uint;
type MemoryKVVal is uint;

library LibMemoryKV {
    function readPtrVal(MemoryKVPtr ptr_) internal pure returns (MemoryKVVal) {
        // This is ALWAYS a bug. It means the caller did not check if the ptr is
        // nonzero before trying to read from it.
        require(MemoryKVPtr.unwrap(ptr_) > 0, "INVALID_PTR");
        MemoryKVVal v_;
        assembly ("memory-safe") {
            v_ := mload(add(ptr_, 0x20))
        }
        return v_;
    }

    function getPtr(
        MemoryKV kv_,
        MemoryKVKey k_
    ) internal pure returns (MemoryKVPtr) {
        uint mask_ = MASK_16BIT;
        MemoryKVPtr ptr_;
        assembly ("memory-safe") {
            // loop until k found or give up if ptr is zero
            for {
                ptr_ := and(kv_, mask_)
            } iszero(iszero(ptr_)) {
                ptr_ := mload(add(ptr_, 0x40))
            } {
                if eq(k_, mload(ptr_)) {
                    break
                }
            }
        }
        return ptr_;
    }

    function setVal(
        MemoryKV kv_,
        MemoryKVKey k_,
        MemoryKVVal v_
    ) internal pure returns (MemoryKV) {
        MemoryKVPtr ptr_ = getPtr(kv_, k_);
        uint mask_ = MASK_16BIT;
        // update
        if (MemoryKVPtr.unwrap(ptr_) > 0) {
            assembly ("memory-safe") {
                mstore(add(ptr_, 0x20), v_)
            }
        }
        // insert
        else {
            assembly ("memory-safe") {
                // allocate new memory
                ptr_ := mload(0x40)
                mstore(0x40, add(ptr_, 0x60))
                // set k/v/ptr
                mstore(ptr_, k_)
                mstore(add(ptr_, 0x20), v_)
                mstore(add(ptr_, 0x40), and(kv_, mask_))
                // kv must point to new insertion and update array len
                kv_ := or(
                    // inc len by 2
                    shl(16, add(shr(16, kv_), 2)),
                    // set ptr
                    ptr_
                )
            }
        }
        return kv_;
    }

    function toUint256Array(
        MemoryKV kv_
    ) internal pure returns (uint[] memory) {
        unchecked {
            uint ptr_ = MemoryKV.unwrap(kv_) & MASK_16BIT;
            uint length_ = MemoryKV.unwrap(kv_) >> 16;
            uint[] memory arr_ = new uint[](length_);
            assembly ("memory-safe") {
                for {
                    let cursor_ := add(arr_, 0x20)
                    let end_ := add(cursor_, mul(mload(arr_), 0x20))
                } lt(cursor_, end_) {
                    cursor_ := add(cursor_, 0x20)
                    ptr_ := mload(add(ptr_, 0x40))
                } {
                    // key
                    mstore(cursor_, mload(ptr_))
                    cursor_ := add(cursor_, 0x20)
                    // value
                    mstore(cursor_, mload(add(ptr_, 0x20)))
                }
            }
            return arr_;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.15;

/// @dev Binary 1.
uint constant B_1 = 2 ** 1 - 1;
/// @dev Binary 11.
uint constant B_11 = 2 ** 2 - 1;
/// @dev Binary 111.
uint constant B_111 = 2 ** 3 - 1;
/// @dev Binary 1111.
uint constant B_1111 = 2 ** 4 - 1;
/// @dev Binary 11111.
uint constant B_11111 = 2 ** 5 - 1;
/// @dev Binary 111111.
uint constant B_111111 = 2 ** 6 - 1;
/// @dev Binary 1111111.
uint constant B_1111111 = 2 ** 7 - 1;
/// @dev Binary 11111111.
uint constant B_11111111 = 2 ** 8 - 1;
/// @dev Binary 111111111.
uint constant B_111111111 = 2 ** 9 - 1;
/// @dev Binary 1111111111.
uint constant B_1111111111 = 2 ** 10 - 1;
/// @dev Binary 11111111111.
uint constant B_11111111111 = 2 ** 11 - 1;
/// @dev Binary 111111111111.
uint constant B_111111111111 = 2 ** 12 - 1;
/// @dev Binary 1111111111111.
uint constant B_1111111111111 = 2 ** 13 - 1;
/// @dev Binary 11111111111111.
uint constant B_11111111111111 = 2 ** 14 - 1;
/// @dev Binary 111111111111111.
uint constant B_111111111111111 = 2 ** 15 - 1;
/// @dev Binary 1111111111111111.
uint constant B_1111111111111111 = 2 ** 16 - 1;

/// @dev Bitmask for 1 bit.
uint constant MASK_1BIT = B_1;
/// @dev Bitmask for 2 bits.
uint constant MASK_2BIT = B_11;
/// @dev Bitmask for 3 bits.
uint constant MASK_3BIT = B_111;
/// @dev Bitmask for 4 bits.
uint constant MASK_4BIT = B_1111;
/// @dev Bitmask for 5 bits.
uint constant MASK_5BIT = B_11111;
/// @dev Bitmask for 6 bits.
uint constant MASK_6BIT = B_111111;
/// @dev Bitmask for 7 bits.
uint constant MASK_7BIT = B_1111111;
/// @dev Bitmask for 8 bits.
uint constant MASK_8BIT = B_11111111;
/// @dev Bitmask for 9 bits.
uint constant MASK_9BIT = B_111111111;
/// @dev Bitmask for 10 bits.
uint constant MASK_10BIT = B_1111111111;
/// @dev Bitmask for 11 bits.
uint constant MASK_11BIT = B_11111111111;
/// @dev Bitmask for 12 bits.
uint constant MASK_12BIT = B_111111111111;
/// @dev Bitmask for 13 bits.
uint constant MASK_13BIT = B_1111111111111;
/// @dev Bitmask for 14 bits.
uint constant MASK_14BIT = B_11111111111111;
/// @dev Bitmask for 15 bits.
uint constant MASK_15BIT = B_111111111111111;
/// @dev Bitmask for 16 bits.
uint constant MASK_16BIT = B_1111111111111111;

// SPDX-License-Identifier: CAL
pragma solidity =0.8.17;

import "../../array/LibUint256Array.sol";

import {SignatureCheckerUpgradeable as SignatureChecker} from "@openzeppelin/contracts-upgradeable/utils/cryptography/SignatureCheckerUpgradeable.sol";
import {ECDSAUpgradeable as ECDSA} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

struct SignedContext {
    address signer;
    bytes signature;
    uint256[] context;
}

library LibContext {
    using LibUint256Array for uint256[];

    function base() internal view returns (uint256[] memory) {
        return
            LibUint256Array.arrayFrom(
                uint(uint160(msg.sender)),
                uint(uint160(address(this)))
            );
    }

    function hash(SignedContext[] memory signedContexts_) internal pure returns (bytes32) {
        return keccak256(abi.encode(signedContexts_));
    }

    function build(
        uint256[][] memory baseContext_,
        uint256[] memory callingContext_,
        SignedContext[] memory signedContexts_
    ) internal view returns (uint256[][] memory) {
        unchecked {
            uint256[] memory signers_ = new uint256[](signedContexts_.length);

            // - LibContext.base() + whatever we are provided.
            // - calling context always even if empty
            // - signed contexts + signers if they exist else nothing.
            uint256 contextLength_ = 1 +
                baseContext_.length +
                1 +
                (signedContexts_.length > 0 ? signedContexts_.length + 1 : 0);

            uint256[][] memory context_ = new uint256[][](contextLength_);
            uint256 offset_ = 0;
            context_[offset_] = LibContext.base();

            for (uint256 i_ = 0; i_ < baseContext_.length; i_++) {
                offset_++;
                context_[offset_] = baseContext_[i_];
            }

            // Calling context is added unconditionally so that a 0 length array
            // is simply an empty column. We don't want callers to be able to
            // manipulate the overall structure of context columns that the
            // expression indexes into.
            offset_++;
            context_[offset_] = callingContext_;

            if (signedContexts_.length > 0) {
                offset_++;
                context_[offset_] = signers_;

                for (uint256 i_ = 0; i_ < signedContexts_.length; i_++) {
                    require(
                        SignatureChecker.isValidSignatureNow(
                            signedContexts_[i_].signer,
                            ECDSA.toEthSignedMessageHash(
                                keccak256(abi.encodePacked(signedContexts_[i_].context))
                            ),
                            signedContexts_[i_].signature
                        ),
                        "INVALID_SIGNATURE"
                    );

                    signers_[i_] = uint256(uint160(signedContexts_[i_].signer));
                    offset_++;
                    context_[offset_] = signedContexts_[i_].context;
                }
            }

            return context_;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface.
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            supportsERC165InterfaceUnchecked(account, type(IERC165Upgradeable).interfaceId) &&
            !supportsERC165InterfaceUnchecked(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && supportsERC165InterfaceUnchecked(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = supportsERC165InterfaceUnchecked(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!supportsERC165InterfaceUnchecked(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function supportsERC165InterfaceUnchecked(address account, bytes4 interfaceId) internal view returns (bool) {
        // prepare call
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);

        // perform static call
        bool success;
        uint256 returnSize;
        uint256 returnValue;
        assembly {
            success := staticcall(30000, account, add(encodedParams, 0x20), mload(encodedParams), 0x00, 0x20)
            returnSize := returndatasize()
            returnValue := mload(0x00)
        }

        return success && returnSize >= 0x20 && returnValue > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../AddressUpgradeable.sol";
import "../../interfaces/IERC1271Upgradeable.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureCheckerUpgradeable {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable.tryRecover(hash, signature);
        if (error == ECDSAUpgradeable.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271Upgradeable.isValidSignature.selector, hash, signature)
        );
        return (success &&
            result.length == 32 &&
            abi.decode(result, (bytes32)) == bytes32(IERC1271Upgradeable.isValidSignature.selector));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271Upgradeable {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}