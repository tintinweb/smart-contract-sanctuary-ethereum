// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {Factory} from "../factory/Factory.sol";
import {EmissionsERC20, EmissionsERC20Config} from "./EmissionsERC20.sol";
import {ITier} from "../tier/ITier.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

/// @title EmissionsERC20Factory
/// @notice Factory for deploying and registering `EmissionsERC20` contracts.
contract EmissionsERC20Factory is Factory {
    /// Template contract to clone.
    /// Deployed by the constructor.
    address public immutable implementation;

    /// Build the reference implementation to clone for each child.
    constructor() {
        address implementation_ = address(new EmissionsERC20());
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
        EmissionsERC20Config memory config_ = abi.decode(
            data_,
            (EmissionsERC20Config)
        );
        address clone_ = Clones.clone(implementation);
        EmissionsERC20(clone_).initialize(config_);
        return clone_;
    }

    /// Allows calling `createChild` with `EmissionsERC20Config` struct.
    /// Use original `Factory` `createChild` function signature if function
    /// parameters are already encoded.
    ///
    /// @param config_ `EmissionsERC20` constructor configuration.
    /// @return New `EmissionsERC20` child contract address.
    function createChildTyped(EmissionsERC20Config calldata config_)
        external
        returns (EmissionsERC20)
    {
        return EmissionsERC20(this.createChild(abi.encode(config_)));
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

import "../tier/libraries/TierConstants.sol";
import {ERC20Config} from "../erc20/ERC20Config.sol";
import "./IClaim.sol";
import "../tier/ReadOnlyTier.sol";
import {RainVM, State} from "../vm/RainVM.sol";
import {VMState, StateConfig} from "../vm/libraries/VMState.sol";
// solhint-disable-next-line max-line-length
import {AllStandardOps, ALL_STANDARD_OPS_START, ALL_STANDARD_OPS_LENGTH} from "../vm/ops/AllStandardOps.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

/// Constructor config.
/// @param allowDelegatedClaims True if accounts can call `claim` on behalf of
/// another account.
/// @param Constructor config for the ERC20 token minted according to emissions
/// schedule in `claim`.
/// @param Constructor config for the `ImmutableSource` that defines the
/// emissions schedule for claiming.
struct EmissionsERC20Config {
    bool allowDelegatedClaims;
    ERC20Config erc20Config;
    StateConfig vmStateConfig;
}

/// @title EmissionsERC20
/// @notice Mints itself according to some predefined schedule. The schedule is
/// expressed as a rainVM script and the `claim` function is world-callable.
/// Intended behaviour is to avoid sybils infinitely minting by putting the
/// claim functionality behind a `ITier` contract. The emissions contract
/// itself implements `ReadOnlyTier` and every time a claim is processed it
/// logs the block number of the claim against every tier claimed. So the block
/// numbers in the tier report for `EmissionsERC20` are the last time that tier
/// was claimed against this contract. The simplest way to make use of this
/// information is to take the max block for the underlying tier and the last
/// claim and then diff it against the current block number.
/// See `test/Claim/EmissionsERC20.sol.ts` for examples, including providing
/// staggered rewards where more tokens are minted for higher tier accounts.
contract EmissionsERC20 is
    Initializable,
    RainVM,
    VMState,
    ERC20Upgradeable,
    IClaim,
    ReadOnlyTier
{
    /// Contract has initialized.
    /// @param sender `msg.sender` initializing the contract (factory).
    /// @param allowDelegatedClaims True if accounts can call `claim` on behalf
    /// of another account.
    event Initialize(address sender, bool allowDelegatedClaims);

    /// @dev local opcode to put claimant account on the stack.
    uint256 private constant OPCODE_CLAIMANT_ACCOUNT = 0;
    /// @dev local opcodes length.
    uint256 internal constant LOCAL_OPS_LENGTH = 1;

    /// @dev local offset for local ops.
    uint256 private immutable localOpsStart;

    /// Address of the immutable rain script deployed as a `VMState`.
    address private vmStatePointer;

    /// Whether the claimant must be the caller of `claim`. If `false` then
    /// accounts other than claimant can claim. This may or may not be
    /// desirable depending on the emissions schedule. For example, a linear
    /// schedule will produce the same end result for the claimant regardless
    /// of who calls `claim` or when but an exponential schedule is more
    /// profitable if the claimant waits longer between claims. In the
    /// non-linear case delegated claims would be inappropriate as third
    /// party accounts could grief claimants by claiming "early", thus forcing
    /// opportunity cost on claimants who would have preferred to wait.
    bool public allowDelegatedClaims;

    /// Each claim is modelled as a report so that the claim report can be
    /// diffed against the upstream report from a tier based emission scheme.
    mapping(address => uint256) private reports;

    /// Constructs the emissions schedule source, opcodes and ERC20 to mint.
    constructor() {
        localOpsStart = ALL_STANDARD_OPS_START + ALL_STANDARD_OPS_LENGTH;
    }

    /// @param config_ source and token config. Also controls delegated claims.
    function initialize(EmissionsERC20Config memory config_)
        external
        initializer
    {
        __ERC20_init(config_.erc20Config.name, config_.erc20Config.symbol);
        _mint(
            config_.erc20Config.distributor,
            config_.erc20Config.initialSupply
        );

        vmStatePointer = _snapshot(_newState(config_.vmStateConfig));

        /// Log some deploy state for use by claim/opcodes.
        allowDelegatedClaims = config_.allowDelegatedClaims;

        emit Initialize(msg.sender, config_.allowDelegatedClaims);
    }

    /// @inheritdoc RainVM
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view override {
        unchecked {
            if (opcode_ < localOpsStart) {
                AllStandardOps.applyOp(
                    state_,
                    opcode_ - ALL_STANDARD_OPS_START,
                    operand_
                );
            } else {
                opcode_ -= localOpsStart;
                require(opcode_ < LOCAL_OPS_LENGTH, "MAX_OPCODE");
                // There's only one opcode, which stacks the account address.
                address account_ = abi.decode(context_, (address));
                state_.stack[state_.stackIndex] = uint256(uint160(account_));
                state_.stackIndex++;
            }
        }
    }

    /// Reports from the claim contract function differently to most tier
    /// contracts. When the report is uninitialized it is `0` NOT `0xFF..`. The
    /// intent is that the claim report is compatible with an "every" selectLte
    /// against tiers that might be gating claims. It's important that we use
    /// every for this check as the underlying tier doing the gating MUST be
    /// respected on every claim even for users that have previously claimed as
    /// they could have lost tiers since their last claim.
    /// The standard "uninitialized is 0xFF.." logic can be simulated in a rain
    /// script as `REPORT(this, account) IF(ISZERO(DUP(0)), never, DUP(0))` if
    /// desired by the deployer (adjusting the DUP index to taste).
    /// @inheritdoc ITier
    function report(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return reports[account_];
    }

    /// Calculates the claim without processing it.
    /// Read only method that may be useful downstream both onchain and
    /// offchain if a claimant wants to check the claim amount before deciding
    /// whether to process it.
    /// As this is read only there are no checks against delegated claims. It
    /// is possible to return a value from `calculateClaim` and to not be able
    /// to process the claim with `claim` if `msg.sender` is not the
    /// `claimant_`.
    /// @param claimant_ Address to calculate current claim for.
    function calculateClaim(address claimant_) public view returns (uint256) {
        State memory state_ = _restore(vmStatePointer);
        eval(abi.encode(claimant_), state_, 0);
        return state_.stack[state_.stackIndex - 1];
    }

    /// Processes the claim for `claimant_`.
    /// - Enforces `allowDelegatedClaims` if it is `true` so that `msg.sender`
    /// must also be `claimant_`.
    /// - Takes the return from `calculateClaim` and mints for `claimant_`.
    /// - Records the current block as the claim-tier for this contract.
    /// - emits a `Claim` event as per `IClaim`.
    /// @param claimant_ address receiving minted tokens. MUST be `msg.sender`
    /// if `allowDelegatedClaims` is `false`.
    /// @param data_ NOT used onchain. Forwarded to `Claim` event for potential
    /// additional offchain processing.
    /// @inheritdoc IClaim
    function claim(address claimant_, bytes calldata data_) external {
        // Disallow delegated claims if appropriate.
        if (!allowDelegatedClaims) {
            require(msg.sender == claimant_, "DELEGATED_CLAIM");
        }

        // Mint the claim.
        uint256 amount_ = calculateClaim(claimant_);
        _mint(claimant_, amount_);

        // Record the current block as the latest claim.
        // This can be diffed/combined with external reports in future claim
        // calculations.
        reports[claimant_] = TierReport.updateBlocksForTierRange(
            TierConstants.NEVER_REPORT,
            TierConstants.TIER_ZERO,
            TierConstants.TIER_EIGHT,
            block.number
        );
        emit TierChange(
            msg.sender,
            claimant_,
            TierConstants.TIER_ZERO,
            TierConstants.TIER_EIGHT,
            // `data_` is emitted under `Claim`.
            ""
        );
        emit Claim(msg.sender, claimant_, data_);
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

/// Constructor config for standard Open Zeppelin ERC20.
/// @param name Name as defined by Open Zeppelin ERC20.
/// @param symbol Symbol as defined by Open Zeppelin ERC20.
/// @param distributor Distributor address of the initial supply.
/// MAY be zero.
/// @param initialSupply Initial supply to mint.
/// MAY be zero.
struct ERC20Config {
    string name;
    string symbol;
    address distributor;
    uint256 initialSupply;
}

// SPDX-License-Identifier: CAL
pragma solidity ^0.8.0;

/// @title IClaim
/// @notice Embodies the idea of processing a claim for some kind of reward.
interface IClaim {
    /// `Claim` is emitted whenever `claim` is called to signify that the claim
    /// has been processed. Makes no assumptions about what is being claimed,
    /// not even requiring an "amount" or similar. Instead there is a generic
    /// `data` field where contextual information can be logged for offchain
    /// processing.
    /// @param sender `msg.sender` authorizing the claim.
    /// @param claimant The claimant receiving the `Claim`.
    /// @param data Associated data for the claim call.
    event Claim(address sender, address claimant, bytes data);

    /// Process a claim for `claimant`.
    /// It is up to the implementing contract to define what a "claim" is, but
    /// broadly it is expected to be some kind of reward.
    /// Implementing contracts MAY allow addresses other than `claimant` to
    /// process a claim but be careful if doing so to avoid griefing!
    /// Implementing contracts MAY allow `claim` to be called arbitrarily many
    /// times, or restrict themselves to a single or several calls only.
    /// @param claimant The address that will receive the result of this claim.
    function claim(address claimant, bytes calldata data) external;
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

import "hardhat/console.sol";

/// Everything required to evaluate and track the state of a rain script.
/// As this is a struct it will be in memory when passed to `RainVM` and so
/// will be modified by reference internally. This is important for gas
/// efficiency; the stack, arguments and stackIndex will likely be mutated by
/// the running script.
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
struct State {
    uint256 stackIndex;
    uint256[] stack;
    bytes[] sources;
    uint256[] constants;
    uint256[] arguments;
}

/// @dev Number of provided opcodes for `RainVM`.
uint256 constant RAIN_VM_OPS_LENGTH = 5;

/// @title RainVM
/// @notice micro VM for implementing and executing custom contract DSLs.
/// Libraries and contracts map opcodes to `view` functionality then RainVM
/// runs rain scripts using these opcodes. Rain scripts dispatch as pairs of
/// bytes. The first byte is an opcode to run and the second byte is a value
/// the opcode can use contextually to inform how to run. Typically opcodes
/// will read/write to the stack to produce some meaningful final state after
/// all opcodes have been dispatched.
///
/// The only thing required to run a rain script is a `State` struct to pass
/// to `eval`, and the index of the source to run. Additional context can
/// optionally be provided to be used by opcodes. For example, an `ITier`
/// contract can take the input of `report`, abi encode it as context, then
/// expose a local opcode that copies this account to the stack. The state will
/// be mutated by reference rather than returned by `eval`, this is to make it
/// very clear to implementers that the inline mutation is occurring.
///
/// Rain scripts run "top to bottom", i.e. "left to right".
/// See the tests for examples on how to construct rain script in JavaScript
/// then pass to `ImmutableSource` contracts deployed by a factory that then
/// run `eval` to produce a final value.
///
/// There are only 4 "core" opcodes for `RainVM`:
/// - `0`: Skip self and optionally additional opcodes, `0 0` is a noop.
///   DEPRECATED! DON'T USE SKIP!
///   See https://github.com/beehive-innovation/rain-protocol/issues/262
/// - `1`: Copy value from either `constants` or `arguments` at index `operand`
///   to the top of the stack. High bit of `operand` is `0` for `constants` and
///   `1` for `arguments`.
/// - `2`: Duplicates the value at stack index `operand_` to the top of the
///   stack.
/// - `3`: Zipmap takes N values from the stack, interprets each as an array of
///   configurable length, then zips them into `arguments` and maps a source
///   from `sources` over these. See `zipmap` for more details.
///
/// To do anything useful the contract that inherits `RainVM` needs to provide
/// opcodes to build up an internal DSL. This may sound complex but it only
/// requires mapping opcode integers to functions to call, and reading/writing
/// values to the stack as input/output for these functions. Further, opcode
/// packs are provided in rain that any inheriting contract can use as a normal
/// solidity library. See `MathOps.sol` opcode pack and the
/// `CalculatorTest.sol` test contract for an example of how to dispatch
/// opcodes and handle the results in a wrapping contract.
///
/// RainVM natively has no concept of branching logic such as `if` or loops.
/// An opcode pack could implement these similar to the core zipmap by lazily
/// evaluating a source from `sources` based on some condition, etc. Instead
/// some simpler, eagerly evaluated selection tools such as `min` and `max` in
/// the `MathOps` opcode pack are provided. Future versions of `RainVM` MAY
/// implement lazy `if` and other similar patterns.
///
/// The `eval` function is `view` because rain scripts are expected to compute
/// results only without modifying any state. The contract wrapping the VM is
/// free to mutate as usual. This model encourages exposing only read-only
/// functionality to end-user deployers who provide scripts to a VM factory.
/// Removing all writes removes a lot of potential foot-guns for rain script
/// authors and allows VM contract authors to reason more clearly about the
/// input/output of the wrapping solidity code.
///
/// Internally `RainVM` makes heavy use of unchecked math and assembly logic
/// as the opcode dispatch logic runs on a tight loop and so gas costs can ramp
/// up very quickly. Implementing contracts and opcode packs SHOULD require
/// that opcodes they receive do not exceed the codes they are expecting.
abstract contract RainVM {
    /// DEPRECATED! DONT USE SKIP!
    /// `0` is a skip as this is the fallback value for unset solidity bytes.
    /// Any additional "whitespace" in rain scripts will be noops as `0 0` is
    /// "skip self". The val can be used to skip additional opcodes but take
    /// care to not underflow the source itself.
    uint256 private constant OP_SKIP = 0;
    /// `1` copies a value either off `constants` or `arguments` to the top of
    /// the stack. The high bit of the operand specifies which, `0` for
    /// `constants` and `1` for `arguments`.
    uint256 private constant OP_VAL = 1;
    /// `2` Duplicates the value at index `operand_` to the top of the stack.
    uint256 private constant OP_DUP = 2;
    /// `3` takes N values off the stack, interprets them as an array then zips
    /// and maps a source from `sources` over them. The source has access to
    /// the original constants using `1 0` and to zipped arguments as `1 1`.
    uint256 private constant OP_ZIPMAP = 3;
    /// `4` ABI encodes the entire stack and logs it to the hardhat console.
    uint256 private constant OP_DEBUG = 4;

    /// Zipmap is rain script's native looping construct.
    /// N values are taken from the stack as `uint256` then split into `uintX`
    /// values where X is configurable by `operand_`. Each 1 increment in the
    /// operand size config doubles the number of items in the implied arrays.
    /// For example, size 0 is 1 `uint256` value, size 1 is
    /// `2x `uint128` values, size 2 is 4x `uint64` values and so on.
    ///
    /// The implied arrays are zipped and then copied into `arguments` and
    /// mapped over with a source from `sources`. Each iteration of the mapping
    /// copies values into `arguments` from index `0` but there is no attempt
    /// to zero out any values that may already be in the `arguments` array.
    /// It is the callers responsibility to ensure that the `arguments` array
    /// is correctly sized and populated for the mapped source.
    ///
    /// The `operand_` for the zipmap opcode is split into 3 components:
    /// - 3 low bits: The index of the source to use from `sources`.
    /// - 2 middle bits: The size of the loop, where 0 is 1 iteration
    /// - 3 high bits: The number of vals to be zipped from the stack where 0
    ///   is 1 value to be zipped.
    ///
    /// This is a separate function to avoid blowing solidity compile stack.
    /// In the future it may be moved inline to `eval` for gas efficiency.
    ///
    /// See https://en.wikipedia.org/wiki/Zipping_(computer_science)
    /// See https://en.wikipedia.org/wiki/Map_(higher-order_function)
    /// @param context_ Domain specific context the wrapping contract can
    /// provide to passthrough back to its own opcodes.
    /// @param state_ The execution state of the VM.
    /// @param operand_ The operand_ associated with this dispatch to zipmap.
    function zipmap(
        bytes memory context_,
        State memory state_,
        uint256 operand_
    ) internal view {
        unchecked {
            uint256 sourceIndex_;
            uint256 stepSize_;
            uint256 offset_;
            uint256 valLength_;
            // assembly here to shave some gas.
            assembly {
                // rightmost 3 bits are the index of the source to use from
                // sources in `state_`.
                sourceIndex_ := and(operand_, 0x07)
                // bits 4 and 5 indicate size of the loop. Each 1 increment of
                // the size halves the bits of the arguments to the zipmap.
                // e.g. 256 `stepSize_` would copy all 256 bits of the uint256
                // into args for the inner `eval`. A loop size of `1` would
                // shift `stepSize_` by 1 (halving it) and meaning the uint256
                // is `eval` as 2x 128 bit values (runs twice). A loop size of
                // `2` would run 4 times as 64 bit values, and so on.
                //
                // Slither false positive here for the shift of constant `256`.
                // slither-disable-next-line incorrect-shift
                stepSize_ := shr(and(shr(3, operand_), 0x03), 256)
                // `offset_` is used by the actual bit shifting operations and
                // is precalculated here to save some gas as this is a hot
                // performance path.
                offset_ := sub(256, stepSize_)
                // bits 5+ determine the number of vals to be zipped. At least
                // one value must be provided so a `valLength_` of `0` is one
                // value to loop over.
                valLength_ := add(shr(5, operand_), 1)
            }
            state_.stackIndex -= valLength_;

            uint256[] memory baseVals_ = new uint256[](valLength_);
            for (uint256 a_ = 0; a_ < valLength_; a_++) {
                baseVals_[a_] = state_.stack[state_.stackIndex + a_];
            }

            for (uint256 step_ = 0; step_ < 256; step_ += stepSize_) {
                for (uint256 a_ = 0; a_ < valLength_; a_++) {
                    state_.arguments[a_] =
                        (baseVals_[a_] << (offset_ - step_)) >>
                        offset_;
                }
                eval(context_, state_, sourceIndex_);
            }
        }
    }

    /// Evaluates a rain script.
    /// The main workhorse of the rain VM, `eval` runs any core opcodes and
    /// dispatches anything it is unaware of to the implementing contract.
    /// For a script to be useful the implementing contract must override
    /// `applyOp` and dispatch non-core opcodes to domain specific logic. This
    /// could be mathematical operations for a calculator, tier reports for
    /// a membership combinator, entitlements for a minting curve, etc.
    ///
    /// Everything required to coordinate the execution of a rain script to
    /// completion is contained in the `State`. The context and source index
    /// are provided so the caller can provide additional data and kickoff the
    /// opcode dispatch from the correct source in `sources`.
    function eval(
        bytes memory context_,
        State memory state_,
        uint256 sourceIndex_
    ) internal view {
        // State needs to start with the stack index at a valid position which
        // may not be the case in general.
        require(state_.stackIndex <= state_.stack.length, "STACK_OVERFLOW");

        // Everything in eval can be checked statically, there are no dynamic
        // runtime values read from the stack that can cause out of bounds
        // behaviour. E.g. sourceIndex in zipmap and size of a skip are both
        // taken from the operand in the source, not the stack. A program that
        // operates out of bounds SHOULD be flagged by static code analysis and
        // avoided by end-users.
        unchecked {
            uint256 i_ = 0;
            uint256 opcode_;
            uint256 operand_;
            uint256 len_;
            uint256 sourceLocation_;
            uint256 constantsLocation_;
            uint256 argumentsLocation_;
            uint256 stackLocation_;
            assembly {
                stackLocation_ := mload(add(state_, 0x20))
                sourceLocation_ := mload(
                    add(
                        mload(add(state_, 0x40)),
                        add(0x20, mul(sourceIndex_, 0x20))
                    )
                )
                constantsLocation_ := mload(add(state_, 0x60))
                argumentsLocation_ := mload(add(state_, 0x80))
                len_ := mload(sourceLocation_)
            }

            // Loop until complete.
            while (i_ < len_) {
                assembly {
                    i_ := add(i_, 2)
                    let op_ := mload(add(sourceLocation_, i_))
                    opcode_ := byte(30, op_)
                    operand_ := byte(31, op_)
                }
                if (opcode_ < RAIN_VM_OPS_LENGTH) {
                    if (opcode_ == OP_VAL) {
                        assembly {
                            let location_ := argumentsLocation_
                            if iszero(and(operand_, 0x80)) {
                                location_ := constantsLocation_
                            }

                            let valIndex_ := and(operand_, 0x7F)
                            // Attempted to read beyond constants/arguments.
                            if iszero(lt(valIndex_, mload(location_))) {
                                revert(0, 0)
                            }

                            let stackIndex_ := mload(state_)
                            // Copy value to stack.
                            mstore(
                                add(
                                    stackLocation_,
                                    add(0x20, mul(stackIndex_, 0x20))
                                ),
                                mload(
                                    add(
                                        location_,
                                        add(0x20, mul(valIndex_, 0x20))
                                    )
                                )
                            )
                            mstore(state_, add(stackIndex_, 1))
                        }
                    } else if (opcode_ == OP_DUP) {
                        assembly {
                            let stackIndex_ := mload(state_)
                            // DUPing data past the values on the stack.
                            if iszero(lt(operand_, stackIndex_)) {
                                revert(0, 0)
                            }
                            mstore(
                                add(
                                    stackLocation_,
                                    add(0x20, mul(stackIndex_, 0x20))
                                ),
                                mload(
                                    add(
                                        stackLocation_,
                                        add(0x20, mul(operand_, 0x20))
                                    )
                                )
                            )
                            mstore(state_, add(stackIndex_, 1))
                        }
                    } else if (opcode_ == OP_ZIPMAP) {
                        zipmap(context_, state_, operand_);
                    } else if (opcode_ == OP_DEBUG) {
                        console.logBytes(abi.encode(state_));
                    } else {
                        // SKIP was deprecated and is now removed. This is due
                        // to skip making it impossible to statically analyse
                        // a script to calculate a valid stack length ahead of
                        // time.
                        require(opcode_ != OP_SKIP, "SKIP_REMOVED");
                    }
                } else {
                    applyOp(context_, state_, opcode_, operand_);
                }
                // The stack index may be the same as the length as this means
                // the stack is full. But we cannot write past the end of the
                // stack. This also catches a stack index that underflows due
                // to unchecked or assembly math. This check MAY be redundant
                // with standard OOB checks on the stack array due to indexing
                // into it, but is a required guard in the case of VM assembly.
                // Future versions of the VM will precalculate all stack
                // movements at deploy time rather than runtime as this kind of
                // accounting adds nontrivial gas across longer scripts that
                // include many opcodes.
                // Note: This check would NOT be safe in the case that some
                // opcode used assembly in a way that can underflow the stack
                // as this would allow a malicious rain script to write to the
                // stack length and/or the stack index.
                require(
                    state_.stackIndex <= state_.stack.length,
                    "STACK_OVERFLOW"
                );
            }
        }
    }

    /// Every contract that implements `RainVM` should override `applyOp` so
    /// that useful opcodes are available to script writers.
    /// For an example of a simple and efficient `applyOp` implementation that
    /// dispatches over several opcode packs see `CalculatorTest.sol`.
    /// Implementing contracts are encouraged to handle the dispatch with
    /// unchecked math as the dispatch is a critical performance path and
    /// default solidity checked math can significantly increase gas cost for
    /// each opcode dispatched. Consider that a single zipmap could loop over
    /// dozens of opcode dispatches internally.
    /// Stack is modified by reference NOT returned.
    /// @param context_ Bytes that the implementing contract can passthrough
    /// to be ready internally by its own opcodes. RainVM ignores the context.
    /// @param state_ The RainVM state that tracks the execution progress.
    /// @param opcode_ The current opcode to dispatch.
    /// @param operand_ Additional information to inform the opcode dispatch.
    function applyOp(
        bytes memory context_,
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view virtual {} //solhint-disable-line no-empty-blocks
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../RainVM.sol";
import "../../sstore2/SSTORE2.sol";

/// Config required to build a new `State`.
/// @param sources Sources verbatim.
/// @param constants Constants verbatim.
/// @param stackLength Sets the length of the uint256[] of the stack.
/// @param argumentsLength Sets the length of the uint256[] of the arguments.
struct StateConfig {
    bytes[] sources;
    uint256[] constants;
    uint256 stackLength;
    uint256 argumentsLength;
}

/// @title StateSnapshot
/// @notice Deploys everything required to build a fresh `State` for rainVM
/// execution as an evm contract onchain. Uses SSTORE2 to abi encode rain
/// script into evm bytecode, then stores an immutable pointer to the resulting
/// contract. Allows arbitrary length rain script source, constants and stack.
/// Gas scales for reads much better for longer data than attempting to put
/// all the source into storage.
/// See https://github.com/0xsequence/sstore2
contract VMState {
    /// A new shapshot has been deployed onchain.
    /// @param sender `msg.sender` of the deployer.
    /// @param pointer Pointer to the onchain snapshot contract.
    /// @param state `State` of the snapshot that was deployed.
    event Snapshot(address sender, address pointer, State state);

    /// Builds a new `State` from `StateConfig`.
    /// Empty stack and arguments with stack index 0.
    /// @param config_ State config to build the new `State`.
    function _newState(StateConfig memory config_)
        internal
        pure
        returns (State memory)
    {
        require(config_.sources.length > 0, "0_SOURCES");
        return
            State(
                0,
                new uint256[](config_.stackLength),
                config_.sources,
                config_.constants,
                new uint256[](config_.argumentsLength)
            );
    }

    /// Snapshot a RainVM state as an immutable onchain contract.
    /// Usually `State` will be new as per `newState` but can be a snapshot of
    /// an "in flight" execution state also.
    /// @param state_ The state to snapshot.
    function _snapshot(State memory state_) internal returns (address) {
        address pointer_ = SSTORE2.write(abi.encode(state_));
        emit Snapshot(msg.sender, pointer_, state_);
        return pointer_;
    }

    /// Builds a fresh state for rainVM execution from all construction data.
    /// This can be passed directly to `eval` for a `RainVM` contract.
    /// @param pointer_ The pointer (address) of the snapshot to restore.
    function _restore(address pointer_) internal view returns (State memory) {
        return abi.decode(SSTORE2.read(pointer_), (State));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of
  data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
    error WriteError();

    /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
    function write(bytes memory _data) internal returns (address pointer) {
        // Append 00 to _data so contract can't be called
        // Build init code
        bytes memory code = Bytecode.creationCodeFor(
            abi.encodePacked(hex"00", _data)
        );

        // Deploy contract using create
        assembly {
            pointer := create(0, add(code, 32), mload(code))
        }

        // Address MUST be non-zero
        if (pointer == address(0)) revert WriteError();
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
    function read(address _pointer) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
    function read(address _pointer, uint256 _start)
        internal
        view
        returns (bytes memory)
    {
        return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
    }

    /**
    @notice Reads the contents of the `_pointer` code as data, skips the first
    byte
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
    function read(
        address _pointer,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory) {
        return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;

library Bytecode {
    error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

    /**
    @notice Generate a creation code that results on a contract with `_code` as
    bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
    function creationCodeFor(bytes memory _code)
        internal
        pure
        returns (bytes memory)
    {
        /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

        return
            abi.encodePacked(
                hex"63",
                uint32(_code.length),
                hex"80_60_0E_60_00_39_60_00_F3",
                _code
            );
    }

    /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
    function codeSize(address _addr) internal view returns (uint256 size) {
        assembly {
            size := extcodesize(_addr)
        }
    }

    /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
    function codeAt(
        address _addr,
        uint256 _start,
        uint256 _end
    ) internal view returns (bytes memory oCode) {
        uint256 csize = codeSize(_addr);
        if (csize == 0) return bytes("");

        if (_start > csize) return bytes("");
        if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end);

        unchecked {
            uint256 reqSize = _end - _start;
            uint256 maxSize = csize - _start;

            uint256 size = maxSize < reqSize ? maxSize : reqSize;

            assembly {
                // allocate output byte array - this could also be done without
                // assembly
                // by using o_code = new bytes(size)
                oCode := mload(0x40)
                // new "memory end" including padding
                mstore(
                    0x40,
                    add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f)))
                )
                // store length in memory
                mstore(oCode, size)
                // actually retrieve the code, this needs assembly
                extcodecopy(_addr, add(oCode, 0x20), _start, size)
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State, RainVM, RAIN_VM_OPS_LENGTH} from "../RainVM.sol";
// solhint-disable-next-line max-line-length
import {EVMConstantOps, EVM_CONSTANT_OPS_LENGTH} from "./evm/EVMConstantOps.sol";
// solhint-disable-next-line max-line-length
import {FixedPointMathOps, FIXED_POINT_MATH_OPS_LENGTH} from "./math/FixedPointMathOps.sol";
import {IERC20Ops, IERC20_OPS_LENGTH} from "./token/IERC20Ops.sol";
import {IERC721Ops, IERC721_OPS_LENGTH} from "./token/IERC721Ops.sol";
import {IERC1155Ops, IERC1155_OPS_LENGTH} from "./token/IERC1155Ops.sol";
import {LogicOps, LOGIC_OPS_LENGTH} from "./math/LogicOps.sol";
import {MathOps, MATH_OPS_LENGTH} from "./math/MathOps.sol";
import {TierOps, TIER_OPS_LENGTH} from "./tier/TierOps.sol";

uint256 constant ALL_STANDARD_OPS_START = RAIN_VM_OPS_LENGTH;
uint256 constant FIXED_POINT_MATH_OPS_START = EVM_CONSTANT_OPS_LENGTH;
uint256 constant MATH_OPS_START = FIXED_POINT_MATH_OPS_START +
    FIXED_POINT_MATH_OPS_LENGTH;
uint256 constant LOGIC_OPS_START = MATH_OPS_START + MATH_OPS_LENGTH;
uint256 constant TIER_OPS_START = LOGIC_OPS_START + LOGIC_OPS_LENGTH;
uint256 constant IERC20_OPS_START = TIER_OPS_START + TIER_OPS_LENGTH;
uint256 constant IERC721_OPS_START = IERC20_OPS_START + IERC20_OPS_LENGTH;
uint256 constant IERC1155_OPS_START = IERC721_OPS_START + IERC721_OPS_LENGTH;
uint256 constant ALL_STANDARD_OPS_LENGTH = IERC1155_OPS_START +
    IERC1155_OPS_LENGTH;

/// @title AllStandardOps
/// @notice RainVM opcode pack to expose all other packs.
library AllStandardOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            if (opcode_ < FIXED_POINT_MATH_OPS_START) {
                EVMConstantOps.applyOp(state_, opcode_, operand_);
            } else if (opcode_ < TIER_OPS_START) {
                if (opcode_ < MATH_OPS_START) {
                    FixedPointMathOps.applyOp(
                        state_,
                        opcode_ - FIXED_POINT_MATH_OPS_START,
                        operand_
                    );
                } else if (opcode_ < LOGIC_OPS_START) {
                    MathOps.applyOp(state_, opcode_ - MATH_OPS_START, operand_);
                } else {
                    LogicOps.applyOp(
                        state_,
                        opcode_ - LOGIC_OPS_START,
                        operand_
                    );
                }
            } else if (opcode_ < IERC20_OPS_START) {
                TierOps.applyOp(state_, opcode_ - TIER_OPS_START, operand_);
            } else {
                if (opcode_ < IERC721_OPS_START) {
                    IERC20Ops.applyOp(
                        state_,
                        opcode_ - IERC20_OPS_START,
                        operand_
                    );
                } else if (opcode_ < IERC1155_OPS_START) {
                    IERC721Ops.applyOp(
                        state_,
                        opcode_ - IERC721_OPS_START,
                        operand_
                    );
                } else {
                    IERC1155Ops.applyOp(
                        state_,
                        opcode_ - IERC1155_OPS_START,
                        operand_
                    );
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

/// @dev Opcode for the block number.
uint256 constant OPCODE_BLOCK_NUMBER = 0;
/// @dev Opcode for the block timestamp.
uint256 constant OPCODE_BLOCK_TIMESTAMP = 1;
/// @dev Opcode for the `msg.sender`.
uint256 constant OPCODE_SENDER = 2;
/// @dev Opcode for `this` address of the current contract.
uint256 constant OPCODE_THIS_ADDRESS = 3;
/// @dev Number of provided opcodes for `BlockOps`.
uint256 constant EVM_CONSTANT_OPS_LENGTH = 4;

/// @title EVMConstantOps
/// @notice RainVM opcode pack to access constants from the EVM environment.
library EVMConstantOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < EVM_CONSTANT_OPS_LENGTH, "MAX_OPCODE");
            // Stack the current `block.number`.
            if (opcode_ == OPCODE_BLOCK_NUMBER) {
                state_.stack[state_.stackIndex] = block.number;
            }
            // Stack the current `block.timestamp`.
            else if (opcode_ == OPCODE_BLOCK_TIMESTAMP) {
                // solhint-disable-next-line not-rely-on-time
                state_.stack[state_.stackIndex] = block.timestamp;
            } else if (opcode_ == OPCODE_SENDER) {
                // Stack the `msg.sender`.
                state_.stack[state_.stackIndex] = uint256(uint160(msg.sender));
            } else {
                state_.stack[state_.stackIndex] = uint256(
                    uint160(address(this))
                );
            }
            state_.stackIndex++;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../math/FixedPointMath.sol";

/// @dev Opcode for multiplication.
uint256 constant OPCODE_SCALE18_MUL = 0;
/// @dev Opcode for division.
uint256 constant OPCODE_SCALE18_DIV = 1;
/// @dev Opcode to rescale some fixed point number to 18 OOMs in situ.
uint256 constant OPCODE_SCALE18 = 2;
/// @dev Opcode to rescale an 18 OOMs fixed point number to scale N.
uint256 constant OPCODE_SCALEN = 3;
/// @dev Opcode to rescale an arbitrary fixed point number by some OOMs.
uint256 constant OPCODE_SCALE_BY = 4;
/// @dev Opcode for stacking the definition of one.
uint256 constant OPCODE_ONE = 5;
/// @dev Opcode for stacking number of fixed point decimals used.
uint256 constant OPCODE_DECIMALS = 6;
/// @dev Number of provided opcodes for `FixedPointMathOps`.
uint256 constant FIXED_POINT_MATH_OPS_LENGTH = 7;

/// @title FixedPointMathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
library FixedPointMathOps {
    using FixedPointMath for uint256;

    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        unchecked {
            require(opcode_ < FIXED_POINT_MATH_OPS_LENGTH, "MAX_OPCODE");

            if (opcode_ < OPCODE_SCALE18) {
                uint256 baseIndex_ = state_.stackIndex - 2;
                if (opcode_ == OPCODE_SCALE18_MUL) {
                    state_.stack[baseIndex_] =
                        state_.stack[baseIndex_].scale18(operand_) *
                        state_.stack[baseIndex_ + 1];
                } else if (opcode_ == OPCODE_SCALE18_DIV) {
                    state_.stack[baseIndex_] =
                        state_.stack[baseIndex_].scale18(operand_) /
                        state_.stack[baseIndex_ + 1];
                }
                state_.stackIndex--;
            } else if (opcode_ < OPCODE_ONE) {
                uint256 baseIndex_ = state_.stackIndex - 1;
                if (opcode_ == OPCODE_SCALE18) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scale18(
                        operand_
                    );
                } else if (opcode_ == OPCODE_SCALEN) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleN(
                        operand_
                    );
                } else if (opcode_ == OPCODE_SCALE_BY) {
                    state_.stack[baseIndex_] = state_.stack[baseIndex_].scaleBy(
                        int8(uint8(operand_))
                    );
                }
            } else {
                if (opcode_ == OPCODE_ONE) {
                    state_.stack[state_.stackIndex] = FP_ONE;
                    state_.stackIndex++;
                } else if (opcode_ == OPCODE_DECIMALS) {
                    state_.stack[state_.stackIndex] = FP_DECIMALS;
                    state_.stackIndex++;
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

/// @dev The scale of all fixed point math. This is adopting the conventions of
/// both ETH (wei) and most ERC20 tokens, so is hopefully uncontroversial.
uint256 constant FP_DECIMALS = 18;
/// @dev The number `1` in the standard fixed point math scaling. Most of the
/// differences between fixed point math and regular math is multiplying or
/// dividing by `ONE` after the appropriate scaling has been applied.
uint256 constant FP_ONE = 1e18;

/// @title FixedPointMath
/// @notice Sometimes we want to do math with decimal values but all we have
/// are integers, typically uint256 integers. Floats are very complex so we
/// don't attempt to simulate them. Instead we provide a standard definition of
/// "one" as 10 ** 18 and scale everything up/down to this as fixed point math.
/// Overflows are errors as per Solidity.
library FixedPointMath {
    /// Scale a fixed point decimal of some scale factor to match `DECIMALS`.
    /// @param a_ Some fixed point decimal value.
    /// @param aDecimals_ The number of fixed decimals of `a_`.
    /// @return `a_` scaled to match `DECIMALS`.
    function scale18(uint256 a_, uint256 aDecimals_)
        internal
        pure
        returns (uint256)
    {
        uint256 decimals_;
        if (FP_DECIMALS == aDecimals_) {
            return a_;
        } else if (FP_DECIMALS > aDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - aDecimals_;
            }
            return a_ * 10**decimals_;
        } else {
            unchecked {
                decimals_ = aDecimals_ - FP_DECIMALS;
            }
            return a_ / 10**decimals_;
        }
    }

    /// Scale a fixed point decimals of `DECIMALS` to some other scale.
    /// @param a_ A `DECIMALS` fixed point decimals.
    /// @param targetDecimals_ The new scale of `a_`.
    /// @return `a_` rescaled from `DECIMALS` to `targetDecimals_`.
    function scaleN(uint256 a_, uint256 targetDecimals_)
        internal
        pure
        returns (uint256)
    {
        uint256 decimals_;
        if (targetDecimals_ == FP_DECIMALS) {
            return a_;
        } else if (FP_DECIMALS > targetDecimals_) {
            unchecked {
                decimals_ = FP_DECIMALS - targetDecimals_;
            }
            return a_ / 10**decimals_;
        } else {
            unchecked {
                decimals_ = targetDecimals_ - FP_DECIMALS;
            }
            return a_ * 10**decimals_;
        }
    }

    /// Scale a fixed point up or down by `scaleBy_` orders of magnitude.
    /// The caller MUST ensure the end result matches `DECIMALS` if other
    /// functions in this library are to work correctly.
    /// Notably `scaleBy` is a SIGNED integer so scaling down by negative OOMS
    /// is supported.
    /// @param a_ Some integer of any scale.
    /// @param scaleBy_ OOMs to scale `a_` up or down by.
    /// @return `a_` rescaled according to `scaleBy_`.
    function scaleBy(uint256 a_, int8 scaleBy_)
        internal
        pure
        returns (uint256)
    {
        if (scaleBy_ == 0) {
            return a_;
        } else if (scaleBy_ > 0) {
            return a_ * 10**uint8(scaleBy_);
        } else {
            uint256 posScaleDownBy_;
            unchecked {
                posScaleDownBy_ = uint8(-scaleBy_);
            }
            return a_ / 10**posScaleDownBy_;
        }
    }

    /// Fixed point multiplication in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` multiplied by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * b_) / FP_ONE;
    }

    /// Fixed point division in native scale decimals.
    /// Both `a_` and `b_` MUST be `DECIMALS` fixed point decimals.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return `a_` divided by `b_` to `DECIMALS` fixed point decimals.
    function fixedPointDiv(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        return (a_ * FP_ONE) / b_;
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Opcode for `IERC20` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC20` `totalSupply`.
uint256 constant OPCODE_TOTAL_SUPPLY = 1;
/// @dev Number of provided opcodes for `IERC20Ops`.
uint256 constant IERC20_OPS_LENGTH = 2;

/// @title IERC20Ops
/// @notice RainVM opcode pack to read the IERC20 interface.
library IERC20Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < IERC20_OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stackIndex--;
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC20(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `totalSupply`.
            else if (opcode_ == OPCODE_TOTAL_SUPPLY) {
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC20(
                    address(uint160(state_.stack[baseIndex_]))
                ).totalSupply();
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @dev Opcode for `IERC721` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC721` `ownerOf`.
uint256 constant OPCODE_OWNER_OF = 1;
/// @dev Number of provided opcodes for `IERC721Ops`.
uint256 constant IERC721_OPS_LENGTH = 2;

/// @title IERC721Ops
/// @notice RainVM opcode pack to read the IERC721 interface.
library IERC721Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256
    ) internal view {
        unchecked {
            require(opcode_ < IERC721_OPS_LENGTH, "MAX_OPCODE");

            state_.stackIndex--;
            uint256 baseIndex_ = state_.stackIndex - 1;
            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stack[baseIndex_] = IERC721(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(address(uint160(state_.stack[state_.stackIndex])));
            }
            // Stack the return of `ownerOf`.
            else if (opcode_ == OPCODE_OWNER_OF) {
                state_.stack[baseIndex_] = uint256(
                    uint160(
                        IERC721(address(uint160(state_.stack[baseIndex_])))
                            .ownerOf(state_.stack[state_.stackIndex])
                    )
                );
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/// @dev Opcode for `IERC1155` `balanceOf`.
uint256 constant OPCODE_BALANCE_OF = 0;
/// @dev Opcode for `IERC1155` `balanceOfBatch`.
uint256 constant OPCODE_BALANCE_OF_BATCH = 1;
/// @dev Number of provided opcodes for `IERC1155Ops`.
uint256 constant IERC1155_OPS_LENGTH = 2;

/// @title IERC1155Ops
/// @notice RainVM opcode pack to read the IERC1155 interface.
library IERC1155Ops {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < IERC1155_OPS_LENGTH, "MAX_OPCODE");

            // Stack the return of `balanceOf`.
            if (opcode_ == OPCODE_BALANCE_OF) {
                state_.stackIndex -= 2;
                uint256 baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                ).balanceOf(
                        address(uint160(state_.stack[baseIndex_ + 1])),
                        state_.stack[baseIndex_ + 2]
                    );
            }
            // Stack the return of `balanceOfBatch`.
            // Operand will be the length
            else if (opcode_ == OPCODE_BALANCE_OF_BATCH) {
                uint256 len_ = operand_ + 1;
                address[] memory addresses_ = new address[](len_);
                uint256[] memory ids_ = new uint256[](len_);

                // Consumes (2 * len_ + 1) inputs and produces len_ outputs.
                state_.stackIndex = state_.stackIndex - (len_ + 1);
                uint256 baseIndex_ = state_.stackIndex - len_;

                IERC1155 token_ = IERC1155(
                    address(uint160(state_.stack[baseIndex_]))
                );
                for (uint256 i_ = 0; i_ < len_; i_++) {
                    addresses_[i_] = address(
                        uint160(state_.stack[baseIndex_ + i_ + 1])
                    );
                    ids_[i_] = state_.stack[baseIndex_ + len_ + i_ + 1];
                }

                uint256[] memory balances_ = token_.balanceOfBatch(
                    addresses_,
                    ids_
                );

                for (uint256 i_ = 0; i_ < len_; i_++) {
                    state_.stack[baseIndex_ + i_] = balances_[i_];
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";

/// @dev Number of provided opcodes for `LogicOps`.
/// The opcodes are NOT listed on the library as they are all internal to
/// the assembly and yul doesn't seem to support using solidity constants
/// as switch case values.
uint256 constant LOGIC_OPS_LENGTH = 7;

/// @title LogicOps
/// @notice RainVM opcode pack to perform some basic logic operations.
library LogicOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < LOGIC_OPS_LENGTH, "MAX_OPCODE");
        assembly {
            let stackIndex_ := mload(state_)
            // This is the start of the stack, adjusted for the leading length
            // 32 bytes.
            // i.e. reading from stackLocation_ gives the first value of the
            // stack and NOT its length.
            let stackTopLocation_ := add(
                // pointer to the stack.
                mload(add(state_, 0x20)),
                add(
                    // length of the stack
                    0x20,
                    // index of the stack
                    mul(stackIndex_, 0x20)
                )
            )

            switch opcode_
            // ISZERO
            case 0 {
                // The stackIndex_ doesn't change for iszero as there is
                // one input and output. ISZERO reads one value so the stack
                // index needs to be nonzero.
                if iszero(stackIndex_) {
                    revert(0, 0)
                }
                let location_ := sub(stackTopLocation_, 0x20)
                mstore(location_, iszero(mload(location_)))
            }
            // EAGER_IF
            // Eager because BOTH x_ and y_ must be eagerly evaluated
            // before EAGER_IF will select one of them. If both x_ and y_
            // are cheap (e.g. constant values) then this may also be the
            // simplest and cheapest way to select one of them.
            case 1 {
                // EAGER_IF reads 3 values.
                if lt(stackIndex_, 3) {
                    revert(0, 0)
                }
                // decrease stack index by 2 (3 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 2))
                let location_ := sub(stackTopLocation_, 0x60)
                switch mload(location_)
                // false => use second value
                case 0 {
                    mstore(location_, mload(add(location_, 0x40)))
                }
                // true => use first value
                default {
                    mstore(location_, mload(add(location_, 0x20)))
                }
            }
            // EQUAL_TO
            case 2 {
                // EQUAL_TO reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    eq(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // LESS_THAN
            case 3 {
                // LESS_THAN reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    lt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // GREATER_THAN
            case 4 {
                // GREATER_THAN reads 2 values.
                if lt(stackIndex_, 2) {
                    revert(0, 0)
                }
                // decrease stack index by 1 (2 inputs, 1 output)
                mstore(state_, sub(stackIndex_, 1))
                let location_ := sub(stackTopLocation_, 0x40)
                mstore(
                    location_,
                    gt(mload(location_), mload(add(location_, 0x20)))
                )
            }
            // EVERY
            // EVERY is either the first item if every item is nonzero, else 0.
            // operand_ is the length of items to check.
            // EVERY of length `0` is a noop.
            case 5 {
                // EVERY reads operand_ values.
                if lt(stackIndex_, operand_) {
                    revert(0, 0)
                }
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is zero then EVERY is a failed check.
                        if iszero(mload(cursor_)) {
                            mstore(location_, 0)
                            break
                        }
                    }
                }
            }
            // ANY
            // ANY is the first nonzero item, else 0.
            // operand_ id the length of items to check.
            // ANY of length `0` is a noop.
            case 6 {
                // ANY reads operand_ values.
                if lt(stackIndex_, operand_) {
                    revert(0, 0)
                }
                if iszero(iszero(operand_)) {
                    // decrease stack index by 1 less than the operand_
                    mstore(state_, sub(stackIndex_, sub(operand_, 1)))
                    let location_ := sub(stackTopLocation_, mul(operand_, 0x20))
                    for {
                        let cursor_ := location_
                    } lt(cursor_, stackTopLocation_) {
                        cursor_ := add(cursor_, 0x20)
                    } {
                        // If anything is NOT zero then ANY is a successful
                        // check and can short-circuit.
                        let item_ := mload(cursor_)
                        if iszero(iszero(item_)) {
                            // Write the usable value to the top of the stack.
                            mstore(location_, item_)
                            break
                        }
                    }
                }
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../math/SaturatingMath.sol";

/// @dev Opcode for addition.
uint256 constant OPCODE_ADD = 0;
/// @dev Opcode for saturating addition.
uint256 constant OPCODE_SATURATING_ADD = 1;
/// @dev Opcode for subtraction.
uint256 constant OPCODE_SUB = 2;
/// @dev Opcode for saturating subtraction.
uint256 constant OPCODE_SATURATING_SUB = 3;
/// @dev Opcode for multiplication.
uint256 constant OPCODE_MUL = 4;
/// @dev Opcode for saturating multiplication.
uint256 constant OPCODE_SATURATING_MUL = 5;
/// @dev Opcode for division.
uint256 constant OPCODE_DIV = 6;
/// @dev Opcode for modulo.
uint256 constant OPCODE_MOD = 7;
/// @dev Opcode for exponentiation.
uint256 constant OPCODE_EXP = 8;
/// @dev Opcode for minimum.
uint256 constant OPCODE_MIN = 9;
/// @dev Opcode for maximum.
uint256 constant OPCODE_MAX = 10;
/// @dev Number of provided opcodes for `MathOps`.
uint256 constant MATH_OPS_LENGTH = 11;

/// @title MathOps
/// @notice RainVM opcode pack to perform basic checked math operations.
/// Underflow and overflow will error as per default solidity behaviour.
/// SaturatingMath opcodes are provided as "core" math because the VM has no
/// ability to lazily execute code, which means that overflows cannot be
/// guarded with conditional logic. Saturation is a quick and dirty solution to
/// overflow that is valid in many situations.
library MathOps {
    using SaturatingMath for uint256;

    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal pure {
        require(opcode_ < MATH_OPS_LENGTH, "MAX_OPCODE");
        uint256 baseIndex_;
        uint256 top_;
        unchecked {
            baseIndex_ = state_.stackIndex - operand_;
            top_ = state_.stackIndex - 1;
        }
        uint256 cursor_ = baseIndex_;
        uint256 accumulator_ = state_.stack[cursor_];

        // Addition.
        if (opcode_ == OPCODE_ADD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ += state_.stack[cursor_];
            }
        }
        // Saturating addition.
        else if (opcode_ == OPCODE_SATURATING_ADD) {
            unchecked {
                while (cursor_ < top_ && accumulator_ < type(uint256).max) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingAdd(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Subtraction.
        else if (opcode_ == OPCODE_SUB) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ -= state_.stack[cursor_];
            }
        }
        // Saturating subtraction.
        else if (opcode_ == OPCODE_SATURATING_SUB) {
            unchecked {
                while (cursor_ < top_ && 0 < accumulator_) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingSub(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Multiplication.
        // Slither false positive here complaining about dividing before
        // multiplying but both are mututally exclusive according to `opcode_`.
        else if (opcode_ == OPCODE_MUL) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ *= state_.stack[cursor_];
            }
        }
        // Saturating multiplication.
        else if (opcode_ == OPCODE_SATURATING_MUL) {
            unchecked {
                while (cursor_ < top_ && accumulator_ < type(uint256).max) {
                    cursor_++;
                    accumulator_ = accumulator_.saturatingMul(
                        state_.stack[cursor_]
                    );
                }
            }
        }
        // Division.
        else if (opcode_ == OPCODE_DIV) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ /= state_.stack[cursor_];
            }
        }
        // Modulo.
        else if (opcode_ == OPCODE_MOD) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ %= state_.stack[cursor_];
            }
        }
        // Exponentiation.
        else if (opcode_ == OPCODE_EXP) {
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                accumulator_ = accumulator_**state_.stack[cursor_];
            }
        }
        // Minimum.
        else if (opcode_ == OPCODE_MIN) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ < accumulator_) {
                    accumulator_ = item_;
                }
            }
        }
        // Maximum.
        else if (opcode_ == OPCODE_MAX) {
            uint256 item_;
            while (cursor_ < top_) {
                unchecked {
                    cursor_++;
                }
                item_ = state_.stack[cursor_];
                if (item_ > accumulator_) {
                    accumulator_ = item_;
                }
            }
        }

        unchecked {
            state_.stack[baseIndex_] = accumulator_;
            state_.stackIndex = baseIndex_ + 1;
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

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
    function saturatingAdd(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 c_ = a_ + b_;
            return c_ < a_ ? type(uint256).max : c_;
        }
    }

    /// Saturating subtraction.
    /// @param a_ Minuend.
    /// @param b_ Subtrahend.
    /// @return Maximum of a_ - b_ and 0.
    function saturatingSub(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            return a_ > b_ ? a_ - b_ : 0;
        }
    }

    /// Saturating multiplication.
    /// @param a_ First term.
    /// @param b_ Second term.
    /// @return Minimum of a_ * b_ and max uint256.
    function saturatingMul(uint256 a_, uint256 b_)
        internal
        pure
        returns (uint256)
    {
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
pragma solidity =0.8.10;

import {State} from "../../RainVM.sol";
import "../../../tier/libraries/TierReport.sol";
import "../../../tier/libraries/TierwiseCombine.sol";

/// @dev Opcode to call `report` on an `ITier` contract.
uint256 constant OPCODE_REPORT = 0;
/// @dev Opcode to stack a report that has never been held for all tiers.
uint256 constant OPCODE_NEVER = 1;
/// @dev Opcode to stack a report that has always been held for all tiers.
uint256 constant OPCODE_ALWAYS = 2;
/// @dev Opcode to calculate the tierwise diff of two reports.
uint256 constant OPCODE_SATURATING_DIFF = 3;
/// @dev Opcode to update the blocks over a range of tiers for a report.
uint256 constant OPCODE_UPDATE_BLOCKS_FOR_TIER_RANGE = 4;
/// @dev Opcode to tierwise select the best block lte a reference block.
uint256 constant OPCODE_SELECT_LTE = 5;
/// @dev Number of provided opcodes for `TierOps`.
uint256 constant TIER_OPS_LENGTH = 6;

/// @title TierOps
/// @notice RainVM opcode pack to operate on tier reports.
/// The opcodes all map to functions from `ITier` and associated libraries such
/// as `TierConstants`, `TierwiseCombine`, and `TierReport`. For each, the
/// order of consumed values on the stack corresponds to the order of arguments
/// to interface/library functions.
library TierOps {
    function applyOp(
        State memory state_,
        uint256 opcode_,
        uint256 operand_
    ) internal view {
        unchecked {
            require(opcode_ < TIER_OPS_LENGTH, "MAX_OPCODE");
            uint256 baseIndex_;
            // Stack the report returned by an `ITier` contract.
            // Top two stack vals are used as `ITier` contract and address
            // to check the report for.
            if (opcode_ == OPCODE_REPORT) {
                state_.stackIndex -= 1;
                baseIndex_ = state_.stackIndex - 1;
                state_.stack[baseIndex_] = ITier(
                    address(uint160(state_.stack[baseIndex_]))
                ).report(address(uint160(state_.stack[baseIndex_ + 1])));
            }
            // Stack a report that has never been held at any tier.
            else if (opcode_ == OPCODE_NEVER) {
                state_.stack[state_.stackIndex] = TierConstants.NEVER_REPORT;
                state_.stackIndex++;
            }
            // Stack a report that has always been held at every tier.
            else if (opcode_ == OPCODE_ALWAYS) {
                state_.stack[state_.stackIndex] = TierConstants.ALWAYS;
                state_.stackIndex++;
            }
            // Stack the tierwise saturating subtraction of two reports.
            // If the older report is newer than newer report the result will
            // be `0`, else a tierwise diff in blocks will be obtained.
            // The older and newer report are taken from the stack.
            else if (opcode_ == OPCODE_SATURATING_DIFF) {
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 newerReport_ = state_.stack[baseIndex_];
                uint256 olderReport_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierwiseCombine.saturatingSub(
                    newerReport_,
                    olderReport_
                );
                state_.stackIndex++;
            }
            // Stacks a report with updated blocks over tier range.
            // The start and end tier are taken from the low and high bits of
            // the `operand_` respectively.
            // The report to update and block number to update to are both
            // taken from the stack.
            else if (opcode_ == OPCODE_UPDATE_BLOCKS_FOR_TIER_RANGE) {
                uint256 startTier_ = operand_ & 0x0f; // & 00001111
                uint256 endTier_ = (operand_ >> 4) & 0x0f; // & 00001111
                state_.stackIndex -= 2;
                baseIndex_ = state_.stackIndex;
                uint256 report_ = state_.stack[baseIndex_];
                uint256 blockNumber_ = state_.stack[baseIndex_ + 1];
                state_.stack[baseIndex_] = TierReport.updateBlocksForTierRange(
                    report_,
                    startTier_,
                    endTier_,
                    blockNumber_
                );
                state_.stackIndex++;
            }
            // Stacks the result of a `selectLte` combinator.
            // All `selectLte` share the same stack and argument handling.
            // Takes the `logic_` and `mode_` from the `operand_` high bits.
            // `logic_` is the highest bit.
            // `mode_` is the 2 highest bits after `logic_`.
            // The other bits specify how many values to take from the stack
            // as reports to compare against each other and the block number.
            else if (opcode_ == OPCODE_SELECT_LTE) {
                uint256 logic_ = operand_ >> 7;
                uint256 mode_ = (operand_ >> 5) & 0x3; // & 00000011
                uint256 reportsLength_ = operand_ & 0x1F; // & 00011111

                // Need one more than reports length to include block number.
                state_.stackIndex -= reportsLength_ + 1;
                baseIndex_ = state_.stackIndex;
                uint256 cursor_ = baseIndex_;

                uint256[] memory reports_ = new uint256[](reportsLength_);
                for (uint256 a_ = 0; a_ < reportsLength_; a_++) {
                    reports_[a_] = state_.stack[cursor_];
                    cursor_++;
                }
                uint256 blockNumber_ = state_.stack[cursor_];

                state_.stack[baseIndex_] = TierwiseCombine.selectLte(
                    reports_,
                    blockNumber_,
                    logic_,
                    mode_
                );
                state_.stackIndex++;
            }
        }
    }
}

// SPDX-License-Identifier: CAL
pragma solidity =0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
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
    function saturatingSub(uint256 newerReport_, uint256 olderReport_)
        internal
        pure
        returns (uint256)
    {
        unchecked {
            uint256 ret_;
            for (uint256 tier_ = 1; tier_ <= 8; tier_++) {
                uint256 newerBlock_ = TierReport.tierBlock(newerReport_, tier_);
                uint256 olderBlock_ = TierReport.tierBlock(olderReport_, tier_);
                uint256 diff_ = newerBlock_.saturatingSub(olderBlock_);
                ret_ = TierReport.updateBlockAtTier(ret_, tier_ - 1, diff_);
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
        uint256[] memory reports_,
        uint256 blockNumber_,
        uint256 logic_,
        uint256 mode_
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
                    block_ = TierReport.tierBlock(reports_[i_], tier_);

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
                ret_ = TierReport.updateBlockAtTier(
                    ret_,
                    tier_ - 1,
                    accumulator_
                );
            }
            return ret_;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
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

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

	function logInt(int p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int)", p0));
	}

	function logUint(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint)", p0));
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

	function log(uint p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint)", p0, p1));
	}

	function log(uint p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string)", p0, p1));
	}

	function log(uint p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool)", p0, p1));
	}

	function log(uint p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address)", p0, p1));
	}

	function log(string memory p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint)", p0, p1));
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

	function log(bool p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint)", p0, p1));
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

	function log(address p0, uint p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint)", p0, p1));
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

	function log(uint p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
	}

	function log(uint p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
	}

	function log(uint p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
	}

	function log(uint p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
	}

	function log(uint p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
	}

	function log(uint p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
	}

	function log(uint p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
	}

	function log(uint p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
	}

	function log(uint p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
	}

	function log(uint p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
	}

	function log(uint p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
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

	function log(string memory p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
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

	function log(string memory p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
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

	function log(bool p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
	}

	function log(bool p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
	}

	function log(bool p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
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

	function log(bool p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
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

	function log(bool p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
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

	function log(address p0, uint p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
	}

	function log(address p0, uint p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
	}

	function log(address p0, uint p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
	}

	function log(address p0, uint p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
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

	function log(address p0, bool p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
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

	function log(address p0, address p1, uint p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
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

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
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

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
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

	function log(bool p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, bool p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, uint p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, bool p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
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

	function log(address p0, address p1, address p2, uint p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}