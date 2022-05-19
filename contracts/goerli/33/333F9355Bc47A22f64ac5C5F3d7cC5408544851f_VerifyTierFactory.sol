// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {Factory} from "../factory/Factory.sol";
import {VerifyTier} from "./VerifyTier.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title VerifyTierFactory
/// @notice Factory for creating and deploying `VerifyTier` contracts.
contract VerifyTierFactory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address public immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new VerifyTier());
        emit Implementation(msg.sender, implementation_);
        implementation = implementation_;
    }

    /// @inheritdoc Factory
    function _createChild(bytes calldata data_)
        internal
        virtual
        override
        returns (address)
    {
        address verify_ = abi.decode(data_, (address));
        address clone_ = Clones.clone(implementation);
        VerifyTier(clone_).initialize(verify_);
        return clone_;
    }

    /// Typed wrapper for `createChild` with `Verify`.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param verify_ `Verify` of the `VerifyTier` logic.
    /// @return New `VerifyTier` child contract address.
    function createChildTyped(address verify_) external returns (VerifyTier) {
        return VerifyTier(this.createChild(abi.encode(verify_)));
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {IFactory} from "./IFactory.sol";
// solhint-disable-next-line max-line-length
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Factory
/// @notice Base contract for deploying and registering child contracts.
abstract contract Factory is IFactory, ReentrancyGuard {
    /// @dev state to track each deployed contract address. A `Factory` will
    /// never lie about deploying a child, unless `isChild` is overridden to do
    /// so.
    mapping(address => bool) private contracts;

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
    function _createChild(bytes calldata data_)
        internal
        virtual
        returns (address);

    /// Implements `IFactory`.
    ///
    /// Calls the `_createChild` hook that inheriting contracts must override.
    /// Registers child contract address such that `isChild` is `true`.
    /// Emits `NewChild` event.
    ///
    /// @param data_ Encoded data to pass down to child contract constructor.
    /// @return New child contract address.
    function createChild(bytes calldata data_)
        external
        virtual
        override
        nonReentrant
        returns (address)
    {
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
    function isChild(address maybeChild_)
        external
        view
        virtual
        override
        returns (bool)
    {
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
pragma solidity =0.8.10;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "./ReadOnlyTier.sol";
import "../verify/libraries/VerifyConstants.sol";
import {State, Verify} from "../verify/Verify.sol";
import "./libraries/TierReport.sol";

/// @title VerifyTier
///
/// @dev A contract that is `VerifyTier` expects to derive tiers from the time
/// the account was approved by the underlying `Verify` contract. The approval
/// block numbers defer to `State.since` returned from `Verify.state`.
contract VerifyTier is ReadOnlyTier, Initializable {
    /// Result of initializing.
    /// @param sender `msg.sender` that initialized the contract.
    /// @param verify The `Verify` contract checked for reports.ww
    event Initialize(address sender, address verify);
    /// The contract to check to produce reports.
    Verify private verify;

    /// Sets the `verify` contract.
    /// @param verify_ The contract to check to produce reports.
    function initialize(address verify_) external initializer {
        require(verify_ != address(0), "0_ADDRESS");
        verify = Verify(verify_);
        emit Initialize(msg.sender, verify_);
    }

    /// Every tier will be the `State.since` block if `account_` is approved
    /// otherwise every tier will be uninitialized.
    /// @inheritdoc ITier
    function report(address account_) public view override returns (uint256) {
        State memory state_ = verify.state(account_);
        if (
            // This is comparing an enum variant so it must be equal.
            // slither-disable-next-line incorrect-equality
            verify.statusAtBlock(state_, block.number) ==
            VerifyConstants.STATUS_APPROVED
        ) {
            return
                TierReport.updateBlocksForTierRange(
                    TierConstants.NEVER_REPORT,
                    TierConstants.TIER_ZERO,
                    TierConstants.TIER_EIGHT,
                    state_.approvedSince
                );
        } else {
            return TierConstants.NEVER_REPORT;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITier} from "./ITier.sol";
import {TierReport} from "./libraries/TierReport.sol";

/// @title ReadOnlyTier
/// @notice `ReadOnlyTier` is a base contract that other contracts
/// are expected to inherit.
///
/// It does not allow `setStatus` and expects `report` to derive from
/// some existing onchain data.
///
/// @dev A contract inheriting `ReadOnlyTier` cannot call `setTier`.
///
/// `ReadOnlyTier` is abstract because it does not implement `report`.
/// The expectation is that `report` will derive tiers from some
/// external data source.
abstract contract ReadOnlyTier is ITier {
    /// Always reverts because it is not possible to set a read only tier.
    /// @inheritdoc ITier
    function setTier(
        address,
        uint256,
        bytes calldata
    ) external pure override {
        revert("SET_TIER");
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title ITier
/// @notice `ITier` is a simple interface that contracts can
/// implement to provide membership lists for other contracts.
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
/// The high level requirements for a contract implementing `ITier`:
/// - MUST represent held tiers as a `uint`.
/// - MUST implement `report`.
///   - The report is a `uint256` that SHOULD represent the block each tier has
///     been continuously held since encoded as `uint32`.
///   - The encoded tiers start at `1`; Tier `0` is implied if no tier has ever
///     been held.
///   - Tier `0` is NOT encoded in the report, it is simply the fallback value.
///   - If a tier is lost the block data is erased for that tier and will be
///     set if/when the tier is regained to the new block.
///   - If a tier is held but the historical block information is not available
///     the report MAY return `0x00000000` for all held tiers.
///   - Tiers that are lost or have never been held MUST return `0xFFFFFFFF`.
/// - SHOULD implement `setTier`.
///   - Contracts SHOULD revert with `SET_TIER` error if they cannot
///     meaningfully set a tier directly.
///     For example a contract that can only derive a membership tier by
///     reading the state of an external contract cannot set tiers.
///   - Contracts implementing `setTier` SHOULD error with `SET_ZERO_TIER`
///     if tier 0 is being set.
/// - MUST emit `TierChange` when `setTier` successfully writes a new tier.
///   - Contracts that cannot meaningfully set a tier are exempt.
///
/// So the four possible states and report values are:
/// - Tier is held and block is known: Block is in the report
/// - Tier is held but block is NOT known: `0` is in the report
/// - Tier is NOT held: `0xFF..` is in the report
/// - Tier is unknown: `0xFF..` is in the report
interface ITier {
    /// Every time a tier changes we log start and end tier against the
    /// account.
    /// This MAY NOT be emitted if reports are being read from the state of an
    /// external contract.
    /// The start tier MAY be lower than the current tier as at the block this
    /// event is emitted in.
    /// @param sender The `msg.sender` that authorized the tier change.
    /// @param account The account changing tier.
    /// @param startTier The previous tier the account held.
    /// @param endTier The newly acquired tier the account now holds.
    /// @param data The associated data for the tier change.
    event TierChange(
        address sender,
        address account,
        uint256 startTier,
        uint256 endTier,
        bytes data
    );

    /// @notice Users can set their own tier by calling `setTier`.
    ///
    /// The contract that implements `ITier` is responsible for checking
    /// eligibility and/or taking actions required to set the tier.
    ///
    /// For example, the contract must take/refund any tokens relevant to
    /// changing the tier.
    ///
    /// Obviously the user is responsible for any approvals for this action
    /// prior to calling `setTier`.
    ///
    /// When the tier is changed a `TierChange` event will be emmited as:
    /// ```
    /// event TierChange(address account, uint startTier, uint endTier);
    /// ```
    ///
    /// The `setTier` function includes arbitrary data as the third
    /// parameter. This can be used to disambiguate in the case that
    /// there may be many possible options for a user to achieve some tier.
    ///
    /// For example, consider the case where tier 3 can be achieved
    /// by EITHER locking 1x rare NFT or 3x uncommon NFTs. A user with both
    /// could use `data` to explicitly state their intent.
    ///
    /// NOTE however that _any_ address can call `setTier` for any other
    /// address.
    ///
    /// If you implement `data` or anything that changes state then be very
    /// careful to avoid griefing attacks.
    ///
    /// The `data` parameter can also be ignored by the contract implementing
    /// `ITier`. For example, ERC20 tokens are fungible so only the balance
    /// approved by the user is relevant to a tier change.
    ///
    /// The `setTier` function SHOULD prevent users from reassigning
    /// tier 0 to themselves.
    ///
    /// The tier 0 status represents never having any status.
    /// @dev Updates the tier of an account.
    ///
    /// The implementing contract is responsible for all checks and state
    /// changes required to set the tier. For example, taking/refunding
    /// funds/NFTs etc.
    ///
    /// Contracts may disallow directly setting tiers, preferring to derive
    /// reports from other onchain data.
    /// In this case they should `revert("SET_TIER");`.
    ///
    /// @param account Account to change the tier for.
    /// @param endTier Tier after the change.
    /// @param data Arbitrary input to disambiguate ownership
    /// (e.g. NFTs to lock).
    function setTier(
        address account,
        uint256 endTier,
        bytes calldata data
    ) external;

    /// @notice A tier report is a `uint256` that contains each of the block
    /// numbers each tier has been held continously since as a `uint32`.
    /// There are 9 possible tier, starting with tier 0 for `0` offset or
    /// "never held any tier" then working up through 8x 4 byte offsets to the
    /// full 256 bits.
    ///
    /// Low bits = Lower tier.
    ///
    /// In hexadecimal every 8 characters = one tier, starting at tier 8
    /// from high bits and working down to tier 1.
    ///
    /// `uint32` should be plenty for any blockchain that measures block times
    /// in seconds, but reconsider if deploying to an environment with
    /// significantly sub-second block times.
    ///
    /// ~135 years of 1 second blocks fit into `uint32`.
    ///
    /// `2^8 / (365 * 24 * 60 * 60)`
    ///
    /// When a user INCREASES their tier they keep all the block numbers they
    /// already had, and get new block times for each increased tiers they have
    /// earned.
    ///
    /// When a user DECREASES their tier they return to `0xFFFFFFFF` (never)
    /// for every tier level they remove, but keep their block numbers for the
    /// remaining tiers.
    ///
    /// GUIs are encouraged to make this dynamic very clear for users as
    /// round-tripping to a lower status and back is a DESTRUCTIVE operation
    /// for block times.
    ///
    /// The intent is that downstream code can provide additional benefits for
    /// members who have maintained a certain tier for/since a long time.
    /// These benefits can be provided by inspecting the report, and by
    /// on-chain contracts directly,
    /// rather than needing to work with snapshots etc.
    /// @dev Returns the earliest block the account has held each tier for
    /// continuously.
    /// This is encoded as a uint256 with blocks represented as 8x
    /// concatenated uint32.
    /// I.e. Each 4 bytes of the uint256 represents a u32 tier start time.
    /// The low bits represent low tiers and high bits the high tiers.
    /// Implementing contracts should return 0xFFFFFFFF for lost and
    /// never-held tiers.
    ///
    /// @param account Account to get the report for.
    /// @return The report blocks encoded as a uint256.
    function report(address account) external view returns (uint256);
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {ITier} from "../ITier.sol";
import "./TierConstants.sol";

/// @title TierReport
/// @notice `TierReport` implements several pure functions that can be
/// used to interface with reports.
/// - `tierAtBlockFromReport`: Returns the highest status achieved relative to
/// a block number and report. Statuses gained after that block are ignored.
/// - `tierBlock`: Returns the block that a given tier has been held
/// since according to a report.
/// - `truncateTiersAbove`: Resets all the tiers above the reference tier.
/// - `updateBlocksForTierRange`: Updates a report with a block
/// number for every tier in a range.
/// - `updateReportWithTierAtBlock`: Updates a report to a new tier.
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

    /// Returns the highest tier achieved relative to a block number
    /// and report.
    ///
    /// Note that typically the report will be from the _current_ contract
    /// state, i.e. `block.number` but not always. Tiers gained after the
    /// reference block are ignored.
    ///
    /// When the `report` comes from a later block than the `blockNumber` this
    /// means the user must have held the tier continuously from `blockNumber`
    /// _through_ to the report block.
    /// I.e. NOT a snapshot.
    ///
    /// @param report_ A report as per `ITier`.
    /// @param blockNumber_ The block number to check the tiers against.
    /// @return The highest tier held since `blockNumber` as per `report`.
    function tierAtBlockFromReport(uint256 report_, uint256 blockNumber_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            for (uint256 i_ = 0; i_ < 8; i_++) {
                if (uint32(uint256(report_ >> (i_ * 32))) > blockNumber_) {
                    return i_;
                }
            }
            return TierConstants.MAX_TIER;
        }
    }

    /// Returns the block that a given tier has been held since from a report.
    ///
    /// The report MUST encode "never" as 0xFFFFFFFF. This ensures
    /// compatibility with `tierAtBlockFromReport`.
    ///
    /// @param report_ The report to read a block number from.
    /// @param tier_ The Tier to read the block number for.
    /// @return The block number this has been held since.
    function tierBlock(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
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
    function truncateTiersAbove(uint256 report_, uint256 tier_)
        internal
        pure
        maxTier(tier_)
        returns (uint256)
    {
        unchecked {
            uint256 offset_ = tier_ * 32;
            uint256 mask_ = (TierConstants.NEVER_REPORT >> offset_) << offset_;
            return report_ | mask_;
        }
    }

    /// Updates a report with a block number for a given tier.
    /// More gas efficient than `updateBlocksForTierRange` if only a single
    /// tier is being modified.
    /// The tier at/above the given tier is updated. E.g. tier `0` will update
    /// the block for tier `1`.
    /// @param report_ Report to use as the baseline for the updated report.
    /// @param tier_ The tier level to update.
    /// @param blockNumber_ The new block number for `tier_`.
    function updateBlockAtTier(
        uint256 report_,
        uint256 tier_,
        uint256 blockNumber_
    ) internal pure maxTier(tier_) returns (uint256) {
        unchecked {
            uint256 offset_ = tier_ * 32;
            return
                (report_ &
                    ~uint256(uint256(TierConstants.NEVER_TIER) << offset_)) |
                uint256(blockNumber_ << offset_);
        }
    }

    /// Updates a report with a block number for every tier in a range.
    ///
    /// Does nothing if the end status is equal or less than the start tier.
    /// @param report_ The report to update.
    /// @param startTier_ The tier at the start of the range (exclusive).
    /// @param endTier_ The tier at the end of the range (inclusive).
    /// @param blockNumber_ The block number to set for every tier in the
    /// range.
    /// @return The updated report.
    function updateBlocksForTierRange(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) internal pure maxTier(endTier_) returns (uint256) {
        unchecked {
            uint256 offset_;
            for (uint256 i_ = startTier_; i_ < endTier_; i_++) {
                offset_ = i_ * 32;
                report_ =
                    (report_ &
                        ~uint256(
                            uint256(TierConstants.NEVER_TIER) << offset_
                        )) |
                    uint256(blockNumber_ << offset_);
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
    /// @param endTier_ The new highest tier held, at the given block number.
    /// @param blockNumber_ The block number to update the highest tier to, and
    /// intermediate tiers from `startTier_`.
    /// @return The updated report.
    function updateReportWithTierAtBlock(
        uint256 report_,
        uint256 startTier_,
        uint256 endTier_,
        uint256 blockNumber_
    ) internal pure returns (uint256) {
        return
            endTier_ < startTier_
                ? truncateTiersAbove(report_, endTier_)
                : updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @title TierConstants
/// @notice Constants for use with tier logic.
library TierConstants {
    /// NEVER is 0xFF.. as it is infinitely in the future.
    /// NEVER for an entire report.
    uint256 internal constant NEVER_REPORT = type(uint256).max;
    /// NEVER for a single tier.
    uint32 internal constant NEVER_TIER = type(uint32).max;

    /// Always is 0 as it is the genesis block.
    /// Tiers can't predate the chain but they can predate an `ITier` contract.
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
pragma solidity =0.8.10;

/// Summary statuses derived from a `State` by comparing the `Since` times
/// against a specific block number.
library VerifyConstants {
    /// Account has not interacted with the system yet or was removed.
    uint256 internal constant STATUS_NIL = 0;
    /// Account has added evidence for themselves.
    uint256 internal constant STATUS_ADDED = 1;
    /// Approver has reviewed added/approve evidence and approved the account.
    uint256 internal constant STATUS_APPROVED = 2;
    /// Banner has reviewed a request to ban an account and banned it.
    uint256 internal constant STATUS_BANNED = 3;
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "./IVerifyCallback.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./libraries/VerifyConstants.sol";

/// Records the block a verify session reaches each status.
/// If a status is not reached it is left as UNINITIALIZED, i.e. 0xFFFFFFFF.
/// Most accounts will never be banned so most accounts will never reach every
/// status, which is a good thing.
/// @param addedSince Block the address was added else 0xFFFFFFFF.
/// @param approvedSince Block the address was approved else 0xFFFFFFFF.
/// @param bannedSince Block the address was banned else 0xFFFFFFFF.
struct State {
    uint32 addedSince;
    uint32 approvedSince;
    uint32 bannedSince;
}

/// Structure of arbitrary evidence to support any action taken.
/// Priviledged roles are expected to provide evidence just as applicants as an
/// audit trail will be preserved permanently in the logs.
/// @param account The account this evidence is relevant to.
/// @param data Arbitrary bytes representing evidence. MAY be e.g. a reference
/// to a sufficiently decentralised external system such as an IPFS hash.
struct Evidence {
    address account;
    bytes data;
}

/// Config to initialize a Verify contract with.
/// @param admin The address to ASSIGN ALL ADMIN ROLES to initially. This
/// address is free and encouraged to delegate fine grained permissions to
/// many other sub-admin addresses, then revoke it's own "root" access.
/// @param callback The address of the `IVerifyCallback` contract if it exists.
/// MAY be `address(0)` to signify that callbacks should NOT run.
struct VerifyConfig {
    address admin;
    address callback;
}

/// @title Verify
/// Trust-minimised contract to record the state of some verification process.
/// When some off-chain identity is to be reified on chain there is inherently
/// some multi-party, multi-faceted trust relationship. For example, the DID
/// (Decentralized Identifiers) specification from W3C outlines that the
/// controller and the subject of an identity are two different entities.
///
/// This is because self-identification is always problematic to the point of
/// being uselessly unbelievable.
///
/// For example, I can simply say "I am the queen of England" and what
/// onchain mechanism could possibly check, let alone stop me?
/// The same problem exists in any situation where some priviledge or right is
/// associated with identity. Consider passports, driver's licenses,
/// celebrity status, age, health, accredited investor, social media account,
/// etc. etc.
///
/// Typically crypto can't and doesn't want to deal with this issue. The usual
/// scenario is that some system demands personal information, which leads to:
///
/// - Data breaches that put individual's safety at risk. Consider the December
///   2020 leak from Ledger that dumped 270 000 home addresses and phone
///   numbers, and another million emails, of hardware wallet owners on a
///   public forum.
/// - Discriminatory access, undermining an individual's self-sovereign right
///   to run a full node, self-host a GUI and broadcast transactions onchain.
///   Consider the dydx airdrop of 2021 where metadata about a user's access
///   patterns logged on a server were used to deny access to presumed
///   Americans over regulatory fears.
/// - An entrenched supply chain of centralized actors from regulators, to
///   government databases, through KYC corporations, platforms, etc. each of
///   which holds an effective monopoly over, and ability to manipulate user's
///   "own" identity.
///
/// These examples and others are completely antithetical to and undermine the
/// safety of an opt-in, permissionless system based on pseudonomous actors
/// self-signing actions into a shared space.
///
/// That said, one can hardly expect a permissionless pseudonomous system
/// founded on asynchronous value transfers to succeed without at least some
/// concept of curation and reputation.
///
/// Anon, will you invest YOUR money in anon's project?
///
/// Clearly for every defi blue chip there are 10 000 scams and nothing onchain
/// can stop a scam, this MUST happen at the social layer.
///
/// Rain protocol is agnostic to how this verification happens. A government
/// regulator is going to want a government issued ID cross-referenced against
/// international sanctions. A fan of some social media influencer wants to
/// see a verified account on that platform. An open source software project
/// should show a github profile. A security token may need evidence from an
/// accountant showing accredited investor status. There are so many ways in
/// which BOTH sides of a fundraise may need to verify something about
/// themselves to each other via a THIRD PARTY that Rain cannot assume much.
///
/// The trust model and process for Rain verification is:
///
/// - There are many `Verify` contracts, each represents a specific
///   verification method with a (hopefully large) set of possible reviewers.
/// - The verifyee compiles some evidence that can be referenced in some
///   relevant system. It could be a session ID in a KYC provider's database or
///   a tweet from a verified account, etc. The evidence is passed to the
///   `Verify` contract as raw bytes so it is opaque onchain, but visible as an
///   event to verifiers.
/// - The verifyee calls `add` _for themselves_ to initialize their state and
///   emit the evidence for their account, after which they _cannot change_
///   their submission without appealing to someone who can remove. This costs
///   gas, so why don't we simply ask the user to sign something and have an
///   approver verify the signed data? Because we want to leverage both the
///   censorship resistance and asynchronous nature of the underlying
///   blockchain. Assuming there are N possible approvers, we want ANY 1 of
///   those N approvers to be able to review and approve an application. If the
///   user is forced to submit their application directly to one SPECIFIC
///   approver we lose this property. In the gasless model the user must then
///   rely on their specific approver both being online and not to censor the
///   request. It's also possible that many accounts add the same evidence,
///   after all it will be public in the event logs, so it is important for
///   approvers to verify the PAIRING between account and evidence.
/// - ANY account with the `APPROVER` role can review the evidence by
///   inspecting the event logs. IF the evidence is valid then the `approve`
///   function should be called by the approver. Approvers MAY also approve and
///   implicitly add any account atomically if the account did not previously
///   add itself.
/// - ANY account with the `BANNER` role can veto either an add OR a prior
///   approval. In the case of a false positive, i.e. where an account was
///   mistakenly approved, an appeal can be made to a banner to update the
///   status. Bad accounts SHOULD BE BANNED NOT REMOVED. When an account is
///   removed, its onchain state is once again open for the attacker to
///   resubmit new fraudulent evidence and potentially be reapproved.
///   Once an account is banned, any attempt by the account holder to change
///   their status, or an approver to approve will be rejected. Downstream
///   consumers of a `State` MUST check for an existing ban. Banners MAY ban
///   and implicity add any account atomically if the account did not
///   previously add itself.
///   - ANY account with the `REMOVER` role can scrub the `State` from an
///   account. Of course, this is a blockchain so the state changes are all
///   still visible to full nodes and indexers in historical data, in both the
///   onchain history and the event logs for each state change. This allows an
///   account to appeal to a remover in the case of a MISTAKEN BAN or also in
///   the case of a MISTAKEN ADD (e.g. mistake in evidence), effecting a
///   "hard reset" at the contract storage level.
///
/// Banning some account with an invalid session is NOT required. It is
/// harmless for an added session to remain as `Status.Added` indefinitely.
/// For as long as no approver decides to approve some invalid added session it
/// MUST be treated as equivalent to a ban by downstream contracts. This is
/// important so that admins are only required to spend gas on useful actions.
///
/// In addition to `Approve`, `Ban`, `Remove` there are corresponding events
/// `RequestApprove`, `RequestBan`, `RequestRemove` that allow for admins to be
/// notified that some new evidence must be considered that may lead to each
/// action. `RequestApprove` is automatically submitted as part of the `add`
/// call, but `RequestBan` and `RequestRemove` must be manually called
///
/// Rain uses standard Open Zeppelin `AccessControl` and is agnostic to how the
/// approver/remover/banner roles and associated admin roles are managed.
/// Ideally the more credibly neutral qualified parties assigend to each role
/// for each `Verify` contract the better. This improves the censorship
/// resistance of the verification process and the responsiveness of the
/// end-user experience.
///
/// Ideally the admin account assigned at deployment would renounce their admin
/// rights after establishing a more granular and appropriate set of accounts
/// with each specific role.
///
/// There is no requirement that any of the priviledged accounts with roles are
/// a single-key EOA, they may be multisig accounts or even a DAO with formal
/// governance processes mediated by a smart contract.
///
/// Every action emits an associated event and optionally calls an onchain
/// callback on a `IVerifyCallback` contract set during initialize. As each
/// action my be performed in bulk dupes are not rolled back, instead the
/// events are emitted for every time the action is called and the callbacks
/// and onchain state changes are deduped. For example, an approve may be
/// called twice for a single account, but by different approvers, potentially
/// submitting different evidence for each approval. In this case the block of
/// the first approve will be used and the onchain callback will be called for
/// the first transaction only, but BOTH approvals will emit an event. This
/// logic is applied per-account, per-action across a batch of evidences.
contract Verify is AccessControl, Initializable {
    /// Any state never held is UNINITIALIZED.
    /// Note that as per default evm an unset state is 0 so always check the
    /// `addedSince` block on a `State` before trusting an equality check on
    /// any other block number.
    /// (i.e. removed or never added)
    uint32 private constant UNINITIALIZED = type(uint32).max;

    /// Emitted when the `Verify` contract is initialized.
    event Initialize(address sender, VerifyConfig config);

    /// Emitted when evidence is first submitted to approve an account.
    /// The requestor is always the `msg.sender` of the user calling `add`.
    /// @param sender The `msg.sender` that submitted its own evidence.
    /// @param evidence The evidence to support an approval.
    /// NOT written to contract storage.
    event RequestApprove(address sender, Evidence evidence);
    /// Emitted when a previously added account is approved.
    /// @param sender The `msg.sender` that approved `account`.
    /// @param evidence The approval data.
    event Approve(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be banned.
    /// The requestor is expected to provide supporting data for the ban.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a ban of `account`.
    /// @param evidence Account + data the `requestor` feels will strengthen
    /// its case for the ban. NOT written to contract storage.
    event RequestBan(address sender, Evidence evidence);
    /// Emitted when an added or approved account is banned.
    /// @param sender The `msg.sender` that banned `account`.
    /// @param evidence Account + the evidence to support a ban.
    /// NOT written to contract storage.
    event Ban(address sender, Evidence evidence);

    /// Currently approved accounts can request that any account be removed.
    /// The requestor is expected to provide supporting data for the removal.
    /// The requestor MAY themselves be banned if vexatious.
    /// @param sender The `msg.sender` requesting a removal of `account`.
    /// @param evidence `Evidence` to justify a removal.
    event RequestRemove(address sender, Evidence evidence);
    /// Emitted when an account is scrubbed from blockchain state.
    /// Historical logs still visible offchain of course.
    /// @param sender The `msg.sender` that removed `account`.
    /// @param evidence `Evidence` to justify the removal.
    event Remove(address sender, Evidence evidence);

    /// Admin role for `APPROVER`.
    bytes32 public constant APPROVER_ADMIN = keccak256("APPROVER_ADMIN");
    /// Role for `APPROVER`.
    bytes32 public constant APPROVER = keccak256("APPROVER");

    /// Admin role for `REMOVER`.
    bytes32 public constant REMOVER_ADMIN = keccak256("REMOVER_ADMIN");
    /// Role for `REMOVER`.
    bytes32 public constant REMOVER = keccak256("REMOVER");

    /// Admin role for `BANNER`.
    bytes32 public constant BANNER_ADMIN = keccak256("BANNER_ADMIN");
    /// Role for `BANNER`.
    bytes32 public constant BANNER = keccak256("BANNER");

    /// Account => State
    mapping(address => State) private states;

    /// Optional IVerifyCallback contract.
    /// MAY be address 0.
    IVerifyCallback public callback;

    /// Initializes the `Verify` contract e.g. as cloned by a factory.
    /// @param config_ The config required to initialize the contract.
    function initialize(VerifyConfig calldata config_) external initializer {
        require(config_.admin != address(0), "0_ACCOUNT");

        // `APPROVER_ADMIN` can admin each other in addition to
        // `APPROVER` addresses underneath.
        _setRoleAdmin(APPROVER_ADMIN, APPROVER_ADMIN);
        _setRoleAdmin(APPROVER, APPROVER_ADMIN);

        // `REMOVER_ADMIN` can admin each other in addition to
        // `REMOVER` addresses underneath.
        _setRoleAdmin(REMOVER_ADMIN, REMOVER_ADMIN);
        _setRoleAdmin(REMOVER, REMOVER_ADMIN);

        // `BANNER_ADMIN` can admin each other in addition to
        // `BANNER` addresses underneath.
        _setRoleAdmin(BANNER_ADMIN, BANNER_ADMIN);
        _setRoleAdmin(BANNER, BANNER_ADMIN);

        // It is STRONGLY RECOMMENDED that the `admin_` delegates specific
        // admin roles then revokes the `X_ADMIN` roles. From themselves.
        // It is ALSO RECOMMENDED that each of the sub-`X_ADMIN` roles revokes
        // their admin rights once sufficient approvers/removers/banners have
        // been assigned, if possible. Admins can instantly/atomically assign
        // and revoke admin priviledges from each other, so a compromised key
        // can irreperably damage a `Verify` contract instance.
        _grantRole(APPROVER_ADMIN, config_.admin);
        _grantRole(REMOVER_ADMIN, config_.admin);
        _grantRole(BANNER_ADMIN, config_.admin);

        callback = IVerifyCallback(config_.callback);

        emit Initialize(msg.sender, config_);
    }

    function _updateEvidenceRef(
        uint256[] memory refs_,
        Evidence memory evidence_,
        uint256 refsIndex_
    ) private pure {
        uint256 ptr_;
        assembly {
            ptr_ := evidence_
        }
        refs_[refsIndex_] = ptr_;
    }

    function _resizeRefs(uint256[] memory refs_, uint256 newLength_)
        private
        pure
    {
        require(newLength_ <= refs_.length, "BAD_RESIZE");
        assembly {
            mstore(refs_, newLength_)
        }
    }

    function _refsAsEvidences(uint256[] memory refs_)
        private
        pure
        returns (Evidence[] memory)
    {
        Evidence[] memory evidences_;
        assembly {
            evidences_ := refs_
        }
        return evidences_;
    }

    /// Typed accessor into states.
    /// @param account_ The account to return the current `State` for.
    function state(address account_) external view returns (State memory) {
        return states[account_];
    }

    /// Derives a single `Status` from a `State` and a reference block number.
    /// @param state_ The raw `State` to reduce into a `Status`.
    /// @param blockNumber_ The block number to compare `State` against.
    function statusAtBlock(State memory state_, uint256 blockNumber_)
        public
        pure
        returns (uint256)
    {
        // The state hasn't even been added so is picking up block zero as the
        // evm fallback value. In this case if we checked other blocks using
        // a `<=` equality they would incorrectly return `true` always due to
        // also having a `0` fallback value.
        // Using `< 1` here to silence slither.
        if (state_.addedSince < 1) {
            return VerifyConstants.STATUS_NIL;
        }
        // Banned takes priority over everything.
        else if (state_.bannedSince <= blockNumber_) {
            return VerifyConstants.STATUS_BANNED;
        }
        // Approved takes priority over added.
        else if (state_.approvedSince <= blockNumber_) {
            return VerifyConstants.STATUS_APPROVED;
        }
        // Added is lowest priority.
        else if (state_.addedSince <= blockNumber_) {
            return VerifyConstants.STATUS_ADDED;
        }
        // The `addedSince` block is after `blockNumber_` so `Status` is nil
        // relative to `blockNumber_`.
        else {
            return VerifyConstants.STATUS_NIL;
        }
    }

    /// Requires that `msg.sender` is approved as at the current block.
    modifier onlyApproved() {
        require(
            statusAtBlock(states[msg.sender], block.number) ==
                VerifyConstants.STATUS_APPROVED,
            "ONLY_APPROVED"
        );
        _;
    }

    /// @dev Builds a new `State` for use by `add` and `approve`.
    function newState() private view returns (State memory) {
        return State(uint32(block.number), UNINITIALIZED, UNINITIALIZED);
    }

    /// An account adds their own verification evidence.
    /// Internally `msg.sender` is used; delegated `add` is not supported.
    /// @param data_ The evidence to support approving the `msg.sender`.
    function add(bytes calldata data_) external {
        State memory state_ = states[msg.sender];
        uint256 currentStatus_ = statusAtBlock(state_, block.number);
        require(
            currentStatus_ != VerifyConstants.STATUS_APPROVED &&
                currentStatus_ != VerifyConstants.STATUS_BANNED,
            "ALREADY_EXISTS"
        );
        // An account that hasn't already been added need a new state.
        // If an account has already been added but not approved or banned
        // they can emit many `RequestApprove` events without changing
        // their state. This facilitates multi-step workflows for the KYC
        // provider, e.g. to implement a commit+reveal scheme or simply
        // request additional evidence from the applicant before final
        // verdict.
        if (currentStatus_ == VerifyConstants.STATUS_NIL) {
            states[msg.sender] = newState();
        }
        Evidence memory evidence_ = Evidence(msg.sender, data_);
        emit RequestApprove(msg.sender, evidence_);

        // Call the `afterAdd_` hook to allow inheriting contracts to enforce
        // requirements.
        // The inheriting contract MUST `require` or otherwise enforce its
        // needs to rollback a bad add.
        IVerifyCallback callback_ = callback;
        if (address(callback_) != address(0)) {
            Evidence[] memory evidences_ = new Evidence[](1);
            evidences_[0] = evidence_;
            callback_.afterAdd(msg.sender, evidences_);
        }
    }

    /// An `APPROVER` can review added evidence and approve accounts.
    /// Typically many approvals would be submitted in a single call which is
    /// more convenient and gas efficient than sending individual transactions
    /// for every approval. However, as there are many individual agents
    /// acting concurrently and independently this requires that the approval
    /// process be infallible so that no individual approval can rollback the
    /// entire batch due to the actions of some other approver/banner. It is
    /// possible to approve an already approved or banned account. The
    /// `Approve` event will always emit but the approved block will only be
    /// set if it was previously uninitialized. A banned account will always
    /// be seen as banned when calling `statusAtBlock` regardless of the
    /// approval block, even if the approval is more recent than the ban. The
    /// only way to reset a ban is to remove and reapprove the account.
    /// @param evidences_ All evidence for all approvals.
    function approve(Evidence[] memory evidences_) external onlyRole(APPROVER) {
        unchecked {
            State memory state_;
            uint256[] memory addedRefs_ = new uint256[](evidences_.length);
            uint256[] memory approvedRefs_ = new uint256[](evidences_.length);
            uint256 additions_ = 0;
            uint256 approvals_ = 0;

            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                Evidence memory evidence_ = evidences_[i_];
                state_ = states[evidence_.account];
                // If the account hasn't been added an approver can still add
                // and approve it on their behalf.
                if (state_.addedSince < 1) {
                    state_ = newState();

                    _updateEvidenceRef(addedRefs_, evidence_, additions_);
                    additions_++;
                }
                // If the account hasn't been approved we approve it. As there
                // are many approvers operating independently and concurrently
                // we do NOT `require` the approval be unique, but we also do
                // NOT change the block as the oldest approval is most
                // important. However we emit an event for every approval even
                // if the state does not change.
                // It is possible to approve a banned account but
                // `statusAtBlock` will ignore the approval time for any banned
                // account and use the banned block only.
                if (state_.approvedSince == UNINITIALIZED) {
                    state_.approvedSince = uint32(block.number);
                    states[evidence_.account] = state_;

                    _updateEvidenceRef(approvedRefs_, evidence_, approvals_);
                    approvals_++;
                }

                // Always emit an `Approve` event even if we didn't write to
                // storage. This ensures that supporting evidence hits the logs
                // for offchain review.
                emit Approve(msg.sender, evidence_);
            }
            IVerifyCallback callback_ = callback;
            if (address(callback_) != address(0)) {
                if (additions_ > 0) {
                    _resizeRefs(addedRefs_, additions_);
                    callback_.afterAdd(
                        msg.sender,
                        _refsAsEvidences(addedRefs_)
                    );
                }
                if (approvals_ > 0) {
                    _resizeRefs(approvedRefs_, approvals_);
                    callback_.afterApprove(
                        msg.sender,
                        _refsAsEvidences(approvedRefs_)
                    );
                }
            }
        }
    }

    /// Any approved address can request some address be approved.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request approvals for.
    function requestApprove(Evidence[] calldata evidences_)
        external
        onlyApproved
    {
        unchecked {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestApprove(msg.sender, evidences_[i_]);
            }
        }
    }

    /// A `BANNER` can ban an added OR approved account.
    /// @param evidences_ All evidence appropriate for all bans.
    function ban(Evidence[] calldata evidences_) external onlyRole(BANNER) {
        unchecked {
            State memory state_;
            uint256[] memory addedRefs_ = new uint256[](evidences_.length);
            uint256[] memory bannedRefs_ = new uint256[](evidences_.length);
            uint256 additions_ = 0;
            uint256 bans_ = 0;
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                Evidence memory evidence_ = evidences_[i_];
                state_ = states[evidence_.account];

                // There is no requirement that an account be formerly added
                // before it is banned. For example some fraud may be detected
                // in an affiliated `Verify` contract and the evidence can be
                // used to ban the same address in the current contract. In
                // this case the account will be added and banned in this call.
                if (state_.addedSince < 1) {
                    state_ = newState();

                    _updateEvidenceRef(addedRefs_, evidence_, additions_);
                    additions_++;
                }
                // Respect prior bans by leaving onchain storage as-is.
                if (state_.bannedSince == UNINITIALIZED) {
                    state_.bannedSince = uint32(block.number);
                    states[evidence_.account] = state_;

                    _updateEvidenceRef(bannedRefs_, evidence_, bans_);
                    bans_++;
                }

                // Always emit a `Ban` event even if we didn't write state. This
                // ensures that supporting evidence hits the logs for offchain
                // review.
                emit Ban(msg.sender, evidence_);
            }
            IVerifyCallback callback_ = callback;
            if (address(callback_) != address(0)) {
                if (additions_ > 0) {
                    _resizeRefs(addedRefs_, additions_);
                    callback_.afterAdd(
                        msg.sender,
                        _refsAsEvidences(addedRefs_)
                    );
                }
                if (bans_ > 0) {
                    _resizeRefs(bannedRefs_, bans_);
                    callback_.afterBan(
                        msg.sender,
                        _refsAsEvidences(bannedRefs_)
                    );
                }
            }
        }
    }

    /// Any approved address can request some address be banned.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request banning for.
    function requestBan(Evidence[] calldata evidences_) external onlyApproved {
        unchecked {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestBan(msg.sender, evidences_[i_]);
            }
        }
    }

    /// A `REMOVER` can scrub state mapping from an account.
    /// A malicious account MUST be banned rather than removed.
    /// Removal is useful to reset the whole process in case of some mistake.
    /// @param evidences_ All evidence to suppor the removal.
    function remove(Evidence[] memory evidences_) external onlyRole(REMOVER) {
        unchecked {
            State memory state_;
            uint256[] memory removedRefs_ = new uint256[](evidences_.length);
            uint256 removals_ = 0;
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                Evidence memory evidence_ = evidences_[i_];
                state_ = states[evidences_[i_].account];
                if (state_.addedSince > 0) {
                    delete (states[evidence_.account]);
                    _updateEvidenceRef(removedRefs_, evidence_, removals_);
                    removals_++;
                }
                emit Remove(msg.sender, evidence_);
            }
            IVerifyCallback callback_ = callback;
            if (address(callback_) != address(0)) {
                if (removals_ > 0) {
                    _resizeRefs(removedRefs_, removals_);
                    callback_.afterRemove(
                        msg.sender,
                        _refsAsEvidences(removedRefs_)
                    );
                }
            }
        }
    }

    /// Any approved address can request some address be removed.
    /// Frivolous requestors SHOULD expect to find themselves banned.
    /// @param evidences_ Array of evidences to request removal of.
    function requestRemove(Evidence[] calldata evidences_)
        external
        onlyApproved
    {
        unchecked {
            for (uint256 i_ = 0; i_ < evidences_.length; i_++) {
                emit RequestRemove(msg.sender, evidences_[i_]);
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

import {Evidence} from "./Verify.sol";

/// Deployers of `Verify` contracts (e.g. via `VerifyFactory`) may want to
/// apply additional processing and/or restrictions to each of the basic
/// verification actions. Examples may be reading from onchain state or
/// requiring token transfers to complete before allowing an add/approve to
/// complete successfully. The reason this is an interface rather than
/// implementors extending `Verify` directly is that it allows for more
/// implementations to sit under a single `VerifyFactory` which in turn allows
/// a more readily composed ecosystem of verified accounts.
///
/// There's no reentrancy concerns for external calls from the `Verify`
/// contract to the `IVerifyCallback` contract because:
/// - All the callbacks happen after state changes in `Verify`
/// - All `Verify` actions are bound to the authority of the `msg.sender`
/// The `IVerifyCallback` contract can and should rollback transactions if
/// their restrictions/processing requirements are not met, but otherwise have
/// no more authority over the `Verify` state than anon users.
///
/// The security model for platforms consuming `Verify` contracts is that they
/// should index or otherwise filter children from the `VerifyFactory` down to
/// those that also set a supported `IVerifyCallback` contract. The factory is
/// completely agnostic to callback concerns and doesn't even require that a
/// callback contract be set at all.
interface IVerifyCallback {
    /// Additional processing after a batch of additions.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param adder_ The `msg.sender` that authorized the additions.
    /// MAY be the addee without any specific role.
    /// @param evidences_ All evidences associated with the additions.
    function afterAdd(address adder_, Evidence[] calldata evidences_) external;

    /// Additional processing after a batch of approvals.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param approver_ The `msg.sender` that authorized the approvals.
    /// @param evidences_ All evidences associated with the approvals.
    function afterApprove(address approver_, Evidence[] calldata evidences_)
        external;

    /// Additional processing after a batch of bannings.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param banner_ The `msg.sender` that authorized the bannings.
    /// @param evidences_ All evidences associated with the bannings.
    function afterBan(address banner_, Evidence[] calldata evidences_) external;

    /// Additional processing after a batch of removals.
    /// SHOULD revert/rollback transactions if processing fails.
    /// @param remover_ The `msg.sender` that authorized the removals.
    /// @param evidences_ All evidences associated with the removals.
    function afterRemove(address remover_, Evidence[] calldata evidences_)
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

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
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
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
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

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
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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