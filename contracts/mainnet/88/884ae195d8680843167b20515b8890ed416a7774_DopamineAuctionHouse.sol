// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// DoapmineAuctionHouse is a modification of Nouns DAO's NounsAuctionHouse.sol:
/// https://github.com/nounsDAO/nouns-monorepo/blob/master/packages/nouns-contracts/contracts/NounsAuctionHouse.sol
/// Copyright licensing is under the GPL-3.0 license, as the above contract
/// is itself a modification of Zora's Auction House (GPL-3.0 licensed).
///
/// The following major changes were made from the original Nouns DAO contract:
/// - `SettleCurrentAndCreateNewAuction()` and `SettleAuction()` were unified
///   into a single `SettleAuction()` function that can be called, paused or not
/// - Auctions begin with `auction.settled = true` to make settlements simpler
/// - The semantics around pausing vs. unpausing were changed to orient around
///   suspension of NEW auctions (pausing has no effect on the current auction)
/// - `AuctionCreationFailed` event added to indicate failed auction creation
/// - Proxy was changed from OZ's TransparentUpgradeableProxy to OZ's UUPS proxy
/// - Support for WETH as a fallback for failed ETH refunds was removed
/// - Support for splitting auction revenue with another address was added
/// - Failed ETH refunds now emit `RefundFailed` events

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

import '../interfaces/Errors.sol';
import { IDopamineAuctionHouse } from "../interfaces/IDopamineAuctionHouse.sol";
import { IDopamineAuctionHouseToken } from "../interfaces/IDopamineAuctionHouseToken.sol";
import { DopamineAuctionHouseStorage } from "./DopamineAuctionHouseStorage.sol";

/// @title Dopamine Auction House Contract
/// @notice The Dopamine auction house contract is an English auctions platform
///  that auctions NFTs of a given collection at `auctionDuration` intervals.
///  This contract specifically configures seasonal emissions for Dopamine tabs.
contract DopamineAuctionHouse is UUPSUpgradeable, DopamineAuctionHouseStorage, IDopamineAuctionHouse {

    /// @notice The min % difference a bidder must bid relative to the last bid.
    uint256 public constant MIN_BID_DIFF = 5;

    /// @notice The minimum time buffer in seconds that can be set for auctions.
    uint256 public constant MIN_AUCTION_BUFFER = 60 seconds;

    /// @notice The maximum time buffer in seconds that can be set for auctions.
    uint256 public constant MAX_AUCTION_BUFFER = 24 hours;

    /// @notice The minimum reserve price in wei that can be set for auctions.
    uint256 public constant MIN_RESERVE_PRICE = 1 wei;

    /// @notice The maximum reserve price in wei that can be set for auctions.
    uint256 public constant MAX_RESERVE_PRICE = 99 ether;

    /// @notice The minimum time period in seconds an auction can run for.
    uint256 public constant MIN_AUCTION_DURATION = 30 minutes;

    /// @notice The maximum time period in seconds an auction can run for.
    uint256 public constant MAX_AUCTION_DURATION = 1 weeks;

    /// @dev Gas-efficient reentrancy & suspension markers marking true / false.
    uint256 private constant _TRUE = 1;
    uint256 private constant _FALSE = 2;

    /// @dev This modifier restrict calls to only the admin.
    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        _;
    }

    /// @dev This modifier acts as a reentrancy guard.
    modifier nonReentrant() {
        if (_locked != _FALSE) {
            revert FunctionReentrant();
        }
        _locked = _TRUE;
        _;
        _locked = _FALSE;
    }

    /// @notice Initializes the Dopamine auction house contract.
    /// @param token_ The address of the NFT up for auction.
    /// @param reserve_ Address of the Dopamine reserve.
    /// @param treasury_ Address of the Dopamine treasury.
    /// @param treasurySplit_ Sale % given to `treasury_` (rest to `reserve_`).
    /// @param auctionBuffer_ Time window in seconds auctions may be extended.
    /// @param reservePrice_ The minimum bidding price for auctions in wei.
    /// @param auctionDuration_ How long in seconds an auction may be up for.
    function initialize(
        address token_,
        address payable reserve_,
        address payable treasury_,
        uint256 treasurySplit_,
        uint256 auctionBuffer_,
        uint256 reservePrice_,
        uint256 auctionDuration_
    ) onlyProxy external {
        if (address(token) != address(0)) {
            revert ContractAlreadyInitialized();
        }

        _suspended = _TRUE;
        _locked = _FALSE;

        admin = msg.sender;
        emit AdminChanged(address(0), admin);

        token = IDopamineAuctionHouseToken(token_);
        auction.settled = true;

        setTreasury(treasury_);
        setReserve(reserve_);
        setTreasurySplit(treasurySplit_);
        setAuctionBuffer(auctionBuffer_);
        setReservePrice(reservePrice_);
        setAuctionDuration(auctionDuration_);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function suspended() external view returns (bool) {
        return _suspended == _TRUE;
    }

    /// @inheritdoc IDopamineAuctionHouse
    function suspendNewAuctions() external onlyAdmin {
        if (_suspended == _TRUE) {
            revert AuctionAlreadySuspended();
        }
        _suspended = _TRUE;
        emit AuctionSuspended();
    }

    /// @inheritdoc IDopamineAuctionHouse
    function resumeNewAuctions() external onlyAdmin {

        // This function can only be called if auctions are currently suspended.
        if (_suspended == _FALSE) {
            revert AuctionNotSuspended();
        }

        // Unless auction settles and ensuing creation fails, resume auctions.
        if (!auction.settled || _createAuction()) {
            _suspended = _FALSE;
            emit AuctionResumed();
        }
    }

    /// @inheritdoc IDopamineAuctionHouse
    function settleAuction() external nonReentrant {
        _settleAuction();

        // If auctions are live, create a new auction but suspend under failure.
        if (_suspended != _TRUE && !_createAuction()) {
            _suspended = _TRUE;
            emit AuctionSuspended();
        }
    }

    /// @inheritdoc IDopamineAuctionHouse
    function createBid(uint256 tokenId) external payable nonReentrant {
        if (block.timestamp > auction.endTime) {
            revert AuctionExpired();
        }
        if (auction.tokenId != tokenId) {
            revert AuctionBidInvalid();
        }
        if (
            msg.value < reservePrice ||
            msg.value < auction.amount + ((auction.amount * MIN_BID_DIFF) / 100)
        ) {
            revert AuctionBidTooLow();
        }

        address payable lastBidder = auction.bidder;

        // Emit a `RefundFailed` event if the refund to the last bidder fails.
        // This only happens if the bidder is a contract not accepting payments.
        if (
            lastBidder != address(0) &&
            !_transferETH(lastBidder, auction.amount)
        )
        {
            _transferETH(treasury, auction.amount);
            emit RefundFailed(lastBidder);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend auction if bid is received within `auctionBuffer` of end time.
        bool extended = auction.endTime - block.timestamp < auctionBuffer;
        emit AuctionBid(auction.tokenId, msg.sender, msg.value, extended);

        if (extended) {
            auction.endTime = block.timestamp + auctionBuffer;
            emit AuctionExtended(tokenId, auction.endTime);
        }

    }

    /// @inheritdoc IDopamineAuctionHouse
    function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

        emit AdminChanged(admin, pendingAdmin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setPendingAdmin(address newPendingAdmin) public override onlyAdmin {
        pendingAdmin = newPendingAdmin;
        emit PendingAdminSet(pendingAdmin);
    }


    /// @inheritdoc IDopamineAuctionHouse
    function setTreasury(address payable newTreasury) public onlyAdmin {
        treasury = newTreasury;
        emit TreasurySet(treasury);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setReserve(address payable newReserve) public onlyAdmin {
        reserve = newReserve;
        emit ReserveSet(reserve);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setAuctionDuration(uint256 newAuctionDuration) public onlyAdmin {
        if (
            newAuctionDuration < MIN_AUCTION_DURATION ||
            newAuctionDuration > MAX_AUCTION_DURATION
        ) {
            revert AuctionDurationInvalid();
        }
        auctionDuration = newAuctionDuration;
        emit AuctionDurationSet(auctionDuration);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setTreasurySplit(uint256 newTreasurySplit)
        public override onlyAdmin
    {
        if (newTreasurySplit > 100) {
            revert AuctionTreasurySplitInvalid();
        }
        treasurySplit = newTreasurySplit;
        emit AuctionTreasurySplitSet(treasurySplit);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setAuctionBuffer(uint256 newAuctionBuffer)
        public
        override
        onlyAdmin
    {
        if (
            newAuctionBuffer < MIN_AUCTION_BUFFER ||
            newAuctionBuffer > MAX_AUCTION_BUFFER
        ) {
            revert AuctionBufferInvalid();
        }
        auctionBuffer = newAuctionBuffer;
        emit AuctionBufferSet(auctionBuffer);
    }

    /// @inheritdoc IDopamineAuctionHouse
    function setReservePrice(uint256 newReservePrice)
        public
        override
        onlyAdmin
    {
        if (
            newReservePrice < MIN_RESERVE_PRICE ||
            newReservePrice > MAX_RESERVE_PRICE
        ) {
            revert AuctionReservePriceInvalid();
        }
        reservePrice = newReservePrice;
        emit AuctionReservePriceSet(reservePrice);
    }

    /// @dev Puts the NFT produced by `token.mint()` up for auction.
    /// @return created True if auction creation succeeds, false otherwise.
    function _createAuction() internal returns (bool created) {
        try token.mint() returns (uint256 tokenId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + auctionDuration;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            created = true;
            emit AuctionCreated(tokenId, startTime, endTime);
        } catch {
            emit AuctionCreationFailed();
        }
    }

    /// @dev Settles the auction, transferring the NFT to the winning bidder.
    function _settleAuction() internal {
        if (auction.settled) {
            revert AuctionAlreadySettled();
        }

        if (block.timestamp < auction.endTime) {
            revert AuctionOngoing();
        }

        auction.settled = true;

        if (auction.bidder == address(0)) {
            token.transferFrom(address(this), treasury, auction.tokenId);
        } else {
            token.transferFrom(address(this), auction.bidder, auction.tokenId);
        }

        if (auction.amount > 0) {
            uint256 treasuryProceeds = auction.amount * treasurySplit / 100;
            uint256 reserveProceeds = auction.amount - treasuryProceeds;
            _transferETH(treasury, treasuryProceeds);
            if (reserveProceeds != 0) {
                _transferETH(reserve, reserveProceeds);
            }
        }

        emit AuctionSettled(auction.tokenId, auction.bidder, auction.amount);
    }

    /// @dev Transfers `value` wei to address `to`, forwarding a max of 30k gas.
    /// @return True if transfer is successful, False otherwise.
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /// @dev Performs an admin authorization check for UUPS upgrades.
    function _authorizeUpgrade(address) internal view override {
        if (msg.sender != admin) {
            revert UpgradeUnauthorized();
        }
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                              Dopamine Tab                                ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice Drop identifier is invalid.
error DropInvalid();

/// @notice Drop details may no longer be modified.
error DropImmutable();

/// @notice Drop hit max allocatable capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Drop starting index is incorrect.
error DropStartInvalid();

/// @notice Insufficient time passed since last drop was created.
error DropTooEarly();

/// @notice Configured allowlist size is too large.
error DropAllowlistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice Operation cannot be performed as auction is already suspended.
error AuctionAlreadySuspended();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidInvalid();

/// @notice Bid placed was too low.
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is not suspended.
error AuctionNotSuspended();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionBufferInvalid();

/// @notice Treasury split is invalid, must be in range [0, 100].
error AuctionTreasurySplitInvalid();

////////////////////////////////////////////////////////////////////////////////
///                              Miscellaneous                               ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Mismatch between input arrays.
error ArityMismatch();

/// @notice Block number being queried is invalid.
error BlockInvalid();

/// @notice Reentrancy vulnerability.
error FunctionReentrant();

/// @notice Number does not fit in 32 bytes.
error Uint32ConversionInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 Upgrades                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Contract already initialized.
error ContractAlreadyInitialized();

/// @notice Upgrade requires either admin or vetoer privileges.
error UpgradeUnauthorized();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-712                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Signature has expired and is no longer valid.
error SignatureExpired();

/// @notice Signature invalid.
error SignatureInvalid();

////////////////////////////////////////////////////////////////////////////////
///                                 EIP-721                                  ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Originating address does not own the NFT.
error OwnerInvalid();

/// @notice Receiving address cannot be the zero address.
error ReceiverInvalid();

/// @notice Receiving contract does not implement the ERC-721 wallet interface.
error SafeTransferUnsupported();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error SenderUnauthorized();

/// @notice NFT supply has hit maximum capacity.
error SupplyMaxCapacity();

/// @notice Token has already minted.
error TokenAlreadyMinted();

/// @notice NFT does not exist.
error TokenNonExistent();

////////////////////////////////////////////////////////////////////////////////
///                              Administrative                              ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Function callable only by the admin.
error AdminOnly();

/// @notice Function callable only by the minter.
error MinterOnly();

/// @notice Function callable only by the owner.
error OwnerOnly();

/// @notice Function callable only by the pending owner.
error PendingAdminOnly();

////////////////////////////////////////////////////////////////////////////////
///                                Governance                                ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Invalid number of actions proposed.
error ProposalActionCountInvalid();

/// @notice Proposal has already been settled.
error ProposalAlreadySettled();

/// @notice Inactive proposals may not be voted for.
error ProposalInactive();

/// @notice Proposal has failed to or has yet to be queued.
error ProposalNotYetQueued();

/// @notice Quorum threshold is invalid.
error ProposalQuorumThresholdInvalid();

/// @notice Proposal threshold is invalid.
error ProposalThresholdInvalid();

/// @notice Proposal has failed to or has yet to be successful.
error ProposalUnpassed();

/// @notice A proposal is currently running and must be settled first.
error ProposalUnsettled();

/// @notice Voting delay set is invalid.
error ProposalVotingDelayInvalid();

/// @notice Voting period set is invalid.
error ProposalVotingPeriodInvalid();

/// @notice Only the proposer may invoke this action.
error ProposerOnly();

/// @notice Function callable only by the vetoer.
error VetoerOnly();

/// @notice Veto power has been revoked.
error VetoPowerRevoked();

/// @notice Proposal already voted for.
error VoteAlreadyCast();

/// @notice Vote type is not valid.
error VoteInvalid();

/// @notice Voting power insufficient.
error VotingPowerInsufficient();

////////////////////////////////////////////////////////////////////////////////
///                                 Timelock                                 ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Invalid set timelock delay.
error TimelockDelayInvalid();

/// @notice Function callable only by the timelock itself.
error TimelockOnly();

/// @notice Duplicate transaction queued.
error TransactionAlreadyQueued();

/// @notice Transaction is not yet queued.
error TransactionNotYetQueued();

/// @notice Transaction executed prematurely.
error TransactionPremature();

/// @notice Transaction execution was reverted.
error TransactionReverted();

/// @notice Transaction is stale.
error TransactionStale();

////////////////////////////////////////////////////////////////////////////////
///                             Merkle Allowlist                             ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Claim drop identifier is invalid.
error ClaimInvalid();

/// @notice Proof for claim is invalid.
error ProofInvalid();

///////////////////////////////////////////////////////////////////////////////
///                           EIP-2981 Royalties                             ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Royalties are set too high.
error RoyaltiesTooHigh();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { IDopamineAuctionHouseEvents } from "./IDopamineAuctionHouseEvents.sol";

/// @title Dopamine DAO Auction House Interface
interface IDopamineAuctionHouse is IDopamineAuctionHouseEvents {

    /// @notice Auction struct that encapsulates the ongoing English auction.
    struct Auction {

        /// @notice The id of the NFT being auctioned.
        uint256 tokenId;

        /// @notice The highest bid in wei placed so far for the auction.
        uint256 amount;

        /// @notice The epoch timestamp at which the auction started.
        uint256 startTime;

        /// @notice The epoch timestamp projected for the auction to end.
        uint256 endTime;

        /// @notice The address of the bidder with the highest bid so far.
        address payable bidder;

        /// @notice A boolean indicating whether the auction has been settled.
        bool settled;
    }

    /// @notice Indicates whether new auctions are suspened or not.
    /// @return True if new auctions are suspended, False otherwise.
    function suspended() external view returns (bool);

    /// @notice Suspends new auctions from being created.
    /// @dev Reverts if not called by admin or auctions are already suspended.
    ///  Note that suspension does not interfere with the ongoing auction.
    function suspendNewAuctions() external;

    /// @notice Resumes creation of new auctions.
    /// @dev Reverts if not called by admin or auctions are already live.
    ///  If the existing auction has already settled, then a new auction will
    ///  be created. If minting on creation fails, the auction stays suspended.
    function resumeNewAuctions() external;

    /// @notice Settles ongoing auction and creates a new one if unsuspended.
    /// @dev Throws if current auction ongoing or already settled. 2 scenarios:
    ///  [Suspended]:   Current auction settles.
    ///  [Unsuspended]: Current auction settles, and a new auction is created.
    ///  If in the latter case creation fails, new auctions will be suspended.
    function settleAuction() external;

    /// @notice Place a bid for the current NFT being auctioned.
    /// @dev Reverts if invalid NFT specified, the auction has expired, or the
    ///  placed bid is not at least `MIN_BID_DIFF` % higher than the last bid.
    /// @param tokenId The identifier of the NFT currently being auctioned.
    function createBid(uint256 tokenId) external payable;

    /// @notice Sets a new pending admin `newPendingAdmin`.
    /// @dev This function throws if not called by the current admin.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) external;

    /// @notice Convert the current `pendingAdmin` to the new `admin`.
    /// @dev This function throws if not called by the current pending admin.
    function acceptAdmin() external;

    /// @notice Sets a new auctions bidding duration, `newAuctionDuration`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  auction duration is set too low or too high.
    /// @param newAuctionDuration New auction duration to set, in seconds.
    function setAuctionDuration(uint256 newAuctionDuration) external;

    /// @notice Sets a new treasury split, `newTreasurySplit`.
    /// @dev This function is only callable by the admin, and throws if the
    ///  new treasury split is set to a percentage above 100%.
    /// @param newTreasurySplit The new treasury split to set, as a percentage.
    function setTreasurySplit(uint256 newTreasurySplit) external;

    /// @notice Sets a new auction time buffer, `newAuctionBuffer`.
    /// @dev This function is only callable by the admin and throws if the time
    ///  buffer is set too low or too high.
    /// @param newAuctionBuffer The time buffer to set, in seconds since epoch.
    function setAuctionBuffer(uint256 newAuctionBuffer) external;

    /// @notice Sets a new auction reserve price, `newReservePrice`.
    /// @dev This function is only callable by the admin and throws if the
    ///  auction reserve price is set too low or too high.
    /// @param newReservePrice The new reserve price to set, in wei.
    function setReservePrice(uint256 newReservePrice) external;

    /// @notice Sets the treasury address to `newTreasury`.
    /// @dev This function is only callable by the admin.
    /// @param newTreasury The new treasury address to set.
    function setTreasury(address payable newTreasury) external;

    /// @notice Sets the reserve address to `newReserve`.
    /// @dev This function is only callable by the admin.
    /// @param newReserve The new reserve address to set.
    function setReserve(address payable newReserve) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title Dopamine DAO Auction House Token
/// @notice Any contract implementing the provided interface can be integrated
///  into the Dopamine DAO Auction House platform. Although originally intended
///  only for the Dopamine ERC-721 tab, it is possible that the auction platform 
///  will be reused for English auctions of other NFTs.
interface IDopamineAuctionHouseToken is IERC721 {

    function mint() external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

import { IDopamineAuctionHouse } from "../interfaces/IDopamineAuctionHouse.sol";
import { IDopamineAuctionHouseToken } from "../interfaces/IDopamineAuctionHouseToken.sol";

/// @title Dopamine Auction House Storage Contract
/// @dev Upgrades involving new storage variables should utilize a new contract
///  inheriting the prior storage contract. This would look like the following:
/// `contract DopamineAuctionHouseStorageV1 is DopamineAuctionHouseStorage {}`
/// `contract DopamineAuctionHouseStorageV2 is DopamineAuctionHouseStorageV1 {}`
contract DopamineAuctionHouseStorage {

    /// @notice Address of temporary admin that will become admin once accepted.
    address public pendingAdmin;

    /// @notice The address administering auctions and thus token emissions.
    address public admin;

    /// @notice The time window in seconds to extend bids that are placed within
    ///  `auctionBuffer` seconds from the auction's end time.
    uint256 public auctionBuffer;

    /// @notice The English auction starting reserve price.
    uint256 public reservePrice;

    /// @notice The percentage of auction revenue directed to the treasury.
    uint256 public treasurySplit;

    /// @notice The initial duration in seconds to allot for a single auction.
    uint256 public auctionDuration;

    /// @notice The address of the Dopamine treasury.
    address payable public treasury;

    /// @notice The address of the Dopamine reserve.
    address payable public reserve;

    /// @notice The Dopamine auction house ERC-721 token.
    IDopamineAuctionHouseToken public token;

    /// @notice The ongoing auction being run.
    IDopamineAuctionHouse.Auction public auction;

    /// @dev A uint marker for preventing reentrancy (locked = 1, unlocked = 2).
    uint256 internal _locked;

    /// @dev A boolean indicating whether or not the auction is suspended.
    uint256 internal _suspended;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
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
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.13;

////////////////////////////////////////////////////////////////////////////////
///              ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

/// @title Dopamine Auction House Events Interface
interface IDopamineAuctionHouseEvents {

    /// @notice Emits when a new auction is created.
    /// @param tokenId The id of the NFT put up for auction.
    /// @param startTime The timestamp in epoch seconds the auction was created.
    /// @param endTime The projected end time of the auction in epoch seconds.
    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime
    );

    /// @notice Emits when the auction for NFT `tokenId` is extended.
    /// @param tokenId The id of the NFT being auctioned.
    /// @param endTime The new auction end time as an epoch timestamp.
    event AuctionExtended(
        uint256 indexed tokenId,
        uint256 endTime
    );

    /// @notice Emits when auction for NFT of id `tokenId` is settled.
    /// @param tokenId The id of the NFT being auctioned.
    /// @param winner The address of the auction winner.
    /// @param amount The amount in wei the winner paid for the auction.
    event AuctionSettled(
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    /// @notice Emits when a new bid is placed for NFT of id `tokenId`.
    /// @param tokenId The id of the NFT being bid on.
    /// @param bidder The address which placed the bid.
    /// @param extended True if the bid triggered extension, False otherwise.
    event AuctionBid(
        uint256 indexed tokenId,
        address bidder,
        uint256 value,
        bool extended
    );

    /// @notice Emits when auction creation fails (due to NFT mint reverting).
    event AuctionCreationFailed();

    /// @notice Emits when a refund fails for bidder `bidder`.
    /// @param bidder The address of the bidder which does not accept payments.
    event RefundFailed(address bidder);

    /// @notice Emits when the auction is suspended.
    event AuctionSuspended();

    /// @notice Emits when the auction is unpaused.
    event AuctionResumed();

    /// @notice Emits when a new auctionbuffer `auctionBuffer` is set.
    /// @param auctionBuffer The new auction buffer to set, in seconds.
    event AuctionBufferSet(uint256 auctionBuffer);

    /// @notice Emits when a new auction reserve price, `reservePrice` is set.
    /// @param reservePrice The new auction reserve price in wei.
    event AuctionReservePriceSet(uint256 reservePrice);

    /// @notice Emits when a new auction treasury split `treasurySplit` is set.
    /// @param treasurySplit The percentage of auction revenue sent to treasury.
    event AuctionTreasurySplitSet(uint256 treasurySplit);

    /// @notice Emits when a new auction duration `auctionDuration` is set.
    /// @param auctionDuration The time in seconds an auction will run for.
    event AuctionDurationSet(uint256 auctionDuration);

    /// @notice Emits when a new pending admin `pendingAdmin` is set.
    /// @param pendingAdmin The new address of the pending admin that was set.
    event PendingAdminSet(address indexed pendingAdmin);

    /// @notice Emits when a new treasury address `treasury` is set.
    /// @param treasury The new address of the treasury that was set.
    event TreasurySet(address indexed treasury);

    /// @notice Emits when a new reserve address `reserve` is set.
    /// @param reserve The new address of the reserve that was set.
    event ReserveSet(address indexed reserve);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
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