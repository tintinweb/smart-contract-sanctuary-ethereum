// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { IERC20 } from '@openzeppelin/contracts/token/ERC20/IERC20.sol';

import '../errors.sol';
import './DopamineAuctionHouseStorage.sol';
import { IDopamineAuctionHouse } from '../interfaces/IDopamineAuctionHouse.sol';
import { IDopamineAuctionHouseToken } from '../interfaces/IDopamineAuctionHouseToken.sol';
import { IWETH } from '../interfaces/IWETH.sol';

contract DopamineAuctionHouse is UUPSUpgradeable, DopamineAuctionHouseStorageV1, IDopamineAuctionHouse {

    // The minimum percentage difference between the last bid amount and the current bid.
    uint256 public constant MIN_BID_DIFF = 5;

    uint256 public constant MIN_TIME_BUFFER = 60 seconds;
    uint256 public constant MAX_TIME_BUFFER = 24 hours;

    uint256 public constant MIN_RESERVE_PRICE = 1 wei;
    uint256 public constant MAX_RESERVE_PRICE = 99 ether;

    uint256 public constant MIN_DURATION = 10 minutes;
    uint256 public constant MAX_DURATION = 1 weeks;

    uint256 private constant _UNLOCKED = 1;
    uint256 private constant _LOCKED = 2;

    modifier onlyAdmin() {
        if (msg.sender != admin) {
            revert AdminOnly();
        }
        _;
    }

    modifier whenNotPaused() {
        if (_paused != _UNLOCKED) {
            revert AuctionMustBePaused();
        }
        _;
    }

    modifier whenPaused() {
        if (_paused != _LOCKED) {
            revert AuctionMustBeUnpaused();
        }
        _;
    }

    modifier nonFunctionReentrant() {
        if (_locked != _UNLOCKED) {
            revert FunctionReentrant();
        }
        _locked = _LOCKED;
        _;
        _locked = _UNLOCKED;
    }

    /// @notice Initialize the Auctions contract.
    /// @param token_ NFT factory address, from which auctioned NFTs are minted.
    /// @param reserve_ Address of the Dopamine company treasury.
    /// @param dao_ Address of the Dopamine DAO treasury.
    /// @param treasurySplit_ Revenue split % between `dao_` and `reserve_`.
    /// @param timeBuffer_ Timeframe in epoch seconds auctions may be extended.
    /// @param reservePrice_ Minimal bidding price for auctions.
    /// @param duration_ How long in seconds an auction should stay open.
    function initialize(
        address token_,
        address payable reserve_,
        address payable dao_,
        uint256 treasurySplit_,
        uint256 timeBuffer_,
        uint256 reservePrice_,
        uint256 duration_
    ) onlyProxy external {
        if (address(token) != address(0)) {
            revert ContractAlreadyInitialized();
        }

        _paused = _UNLOCKED;
        _locked = _UNLOCKED;

        _pause();

        admin = msg.sender;
        token = IDopamineAuctionHouseToken(token_);
        dao = dao_;
        reserve = reserve_;

        setTreasurySplit(treasurySplit_);
        setTimeBuffer(timeBuffer_);
        setReservePrice(reservePrice_);
        setDuration(duration_);
    }

    /// @notice Settle the ongoing auction and create a new one.
    function settleCurrentAndCreateNewAuction() external override nonFunctionReentrant whenNotPaused {
        _settleAuction();
        _createAuction();
    }

    /// @notice Settle the ongoing auction.
    function settleAuction() external override whenPaused nonFunctionReentrant {
        _settleAuction();
    }

    /// @notice Place a bid for the current NFT being auctioned.
    /// @param tokenId The identifier of the NFT currently being auctioned.
    function createBid(uint256 tokenId) external payable override nonFunctionReentrant {
        Auction memory _auction = auction;

        if (block.timestamp > _auction.endTime) {
            revert AuctionExpired();
        }
        if (_auction.tokenId != tokenId) {
            revert AuctionBidTokenInvalid();
        }
        if (
            msg.value < reservePrice || 
            msg.value < _auction.amount + ((_auction.amount * MIN_BID_DIFF) / 100)
        ) {
            revert AuctionBidTooLow();
        }

        address payable lastBidder = _auction.bidder;

        // Notify if refund fails.
        if (lastBidder != address(0) && !_transferETH(lastBidder, _auction.amount)) {
            emit RefundFailed(lastBidder);
        }

        auction.amount = msg.value;
        auction.bidder = payable(msg.sender);

        // Extend the auction if the bid was received within `timeBuffer` of the auction end time
        bool extended = _auction.endTime - block.timestamp < timeBuffer;
        if (extended) {
            auction.endTime = _auction.endTime = block.timestamp + timeBuffer;
            emit AuctionExtended(_auction.tokenId, _auction.endTime);
        }

        emit AuctionBid(_auction.tokenId, msg.sender, msg.value, extended);
    }

    /// @notice Pause the current auction.
    function pause() external override onlyAdmin {
        _pause();
    }

    /// @notice Resumes an existing auction or creates a new auction.
    function unpause() external override onlyAdmin {
        _unpause();

        if (auction.startTime == 0 || auction.settled) {
            _createAuction();
        }
    }
        
    /// @notice Sets a new pending admin `newPendingAdmin`.
    /// @param newPendingAdmin The address of the new pending admin.
    function setPendingAdmin(address newPendingAdmin) public override onlyAdmin {
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(pendingAdmin);
    }

    /// @notice Convert the current `pendingAdmin` to the new `admin`.
	function acceptAdmin() public override {
        if (msg.sender != pendingAdmin) {
            revert PendingAdminOnly();
        }

		emit NewAdmin(admin, pendingAdmin);
		admin = pendingAdmin;
        pendingAdmin = address(0);
	}

    /// @notice Sets a new auctions bidding duration, `newDuration`.
    /// @dev `duration` refers to how long an individual auction remains open.
    /// @param newDuration New auction duration to set, in seconds.
    function setDuration(uint256 newDuration) public override onlyAdmin {
        if (newDuration < MIN_DURATION || newDuration > MAX_DURATION) {
            revert AuctionDurationInvalid();
        }
        duration = newDuration;
        emit AuctionDurationSet(duration);
    }

    /// @notice Sets a new treasury split, `newTreasurySplit`.
    /// @dev `treasurySplit` refers to % of sale revenue directed to treasury.
    /// @param newTreasurySplit The new treasury split to set, in percentage.
    function setTreasurySplit(uint256 newTreasurySplit) public override onlyAdmin {
        if (newTreasurySplit > 100) {
            revert AuctionTreasurySplitInvalid();
        }
        treasurySplit = newTreasurySplit;
        emit AuctionTreasurySplitSet(treasurySplit);
    }

    /// @notice Sets a new auction time buffer, `newTimeBuffer`.
    /// @dev Auctions extend if bid received within `timeBuffer` of auction end.
    /// @param newTimeBuffer The time buffer to set, in seconds since epoch.
    function setTimeBuffer(uint256 newTimeBuffer) public override onlyAdmin {
        if (newTimeBuffer < MIN_TIME_BUFFER || newTimeBuffer > MAX_TIME_BUFFER) {
            revert AuctionTimeBufferInvalid();
        }
        timeBuffer = newTimeBuffer;
        emit AuctionTimeBufferSet(timeBuffer);
    }

    /// @notice Sets a new auction reserve price, `newReservePrice`.
    /// @dev `reservePrice` represents the English auction starting price.
    /// @param newReservePrice The new reserve price to set, in wei.
    function setReservePrice(uint256 newReservePrice) public override onlyAdmin {
        if (newReservePrice < MIN_RESERVE_PRICE || newReservePrice > MAX_RESERVE_PRICE) {
            revert AuctionReservePriceInvalid();
        }
        reservePrice = newReservePrice;
        emit AuctionReservePriceSet(reservePrice);
    }

    function paused() public view returns (bool) {
        return _paused == _LOCKED;
    }

    /// @notice Puts the NFT produced by `token.mint()` up for auction.
    /// @dev If minting fails, the auction contract is paused.
    function _createAuction() internal {
        try token.mint() returns (uint256 tokenId) {
            uint256 startTime = block.timestamp;
            uint256 endTime = startTime + duration;

            auction = Auction({
                tokenId: tokenId,
                amount: 0,
                startTime: startTime,
                endTime: endTime,
                bidder: payable(0),
                settled: false
            });

            emit AuctionCreated(tokenId, startTime, endTime);
        } catch {
            _pause();
        }
    }

    /// @notice Settles the auction, transferring NFT to winning bidder.
    /// @dev If no bids are placed, the NFT is sent to the treasury.
    function _settleAuction() internal {
        Auction memory _auction = auction;

        if (_auction.startTime == 0) {
            revert AuctionNotYetStarted();
        }
        if (_auction.settled) {
            revert AuctionAlreadySettled();
        }
        if (block.timestamp < _auction.endTime) {
            revert AuctionOngoing();
        }

        auction.settled = true;

        if (_auction.bidder == address(0)) {
            token.transferFrom(address(this), dao, _auction.tokenId);
        } else {
            token.transferFrom(address(this), _auction.bidder, _auction.tokenId);
        }

        if (_auction.amount > 0) {
            uint256 treasuryProceeds = _auction.amount * treasurySplit / 100;
            uint256 teamProceeds = _auction.amount - treasuryProceeds;
            _transferETH(dao, treasuryProceeds);
            _transferETH(reserve, teamProceeds);
        }

        emit AuctionSettled(_auction.tokenId, _auction.bidder, _auction.amount);
    }

    /// @notice Transfer `value` worth of Eth to address `to`.
    /// @dev Only up to 30K worth of gas will be forwarded to callee.
    /// @return `true` if refund is successful, `false` otherwise.
    function _transferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    /// @notice Pauses the auctions contract if not paused.
    function _pause() internal whenNotPaused {
        _paused = _LOCKED;
        emit AuctionPaused(msg.sender);
    }

    /// @notice Unpauses the auctions contract if paused.
    function _unpause() internal whenPaused {
        _paused = _UNLOCKED;
        emit AuctionUnpaused(msg.sender);
    }

    /// @notice Performs authorization check for UUPS upgrades.
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

/// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

////////////////////////////////////////////////////////////////////////////////
///				 ░▒█▀▀▄░█▀▀█░▒█▀▀█░█▀▀▄░▒█▀▄▀█░▄█░░▒█▄░▒█░▒█▀▀▀              ///
///              ░▒█░▒█░█▄▀█░▒█▄▄█▒█▄▄█░▒█▒█▒█░░█▒░▒█▒█▒█░▒█▀▀▀              ///
///              ░▒█▄▄█░█▄▄█░▒█░░░▒█░▒█░▒█░░▒█░▄█▄░▒█░░▀█░▒█▄▄▄              ///
////////////////////////////////////////////////////////////////////////////////

// This file is a shared repository of all errors used in Dopamine's contracts.

////////////////////////////////////////////////////////////////////////////////
///                               DopamintPass                               /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Configured drop delay is invalid.
error DropDelayInvalid();

/// @notice DopamintPass drop hit allocated capacity.
error DropMaxCapacity();

/// @notice No such drop exists.
error DropNonExistent();

/// @notice Action cannot be completed as a current drop is ongoing.
error DropOngoing();

/// @notice Configured drop size is invalid.
error DropSizeInvalid();

/// @notice Insufficient time passed since last drop was created.
error DropTooEarly();

/// @notice Configured whitelist size is too large.
error DropWhitelistOverCapacity();

////////////////////////////////////////////////////////////////////////////////
///                          Dopamine Auction House                          ///
////////////////////////////////////////////////////////////////////////////////

/// @notice Auction has already been settled.
error AuctionAlreadySettled();

/// @notice The NFT specified in the auction bid is invalid.
error AuctionBidTokenInvalid();

/// @notice Bid placed was too low (see `reservePrice` and `MIN_BID_DIFF`).
error AuctionBidTooLow();

/// @notice Auction duration set is invalid.
error AuctionDurationInvalid();

/// @notice The auction has expired.
error AuctionExpired();

/// @notice Operation cannot be performed as auction is paused.
error AuctionMustBePaused();

/// @notice Operation cannot be performed as auction is unpaused.
error AuctionMustBeUnpaused();

/// @notice Auction has not yet started.
error AuctionNotYetStarted();

/// @notice Auction has yet to complete.
error AuctionOngoing();

/// @notice Reserve price set is invalid.
error AuctionReservePriceInvalid();

/// @notice Time buffer set is invalid.
error AuctionTimeBufferInvalid();

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

/// @notice Receiving contract does not implement the ERC721 wallet interface.
error SafeTransferUnsupported();

/// @notice Sender is not NFT owner, approved address, or owner operator.
error SenderUnauthorized();

/// @notice NFT collection has hit maximum supply capacity.
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
///                             Merkle Whitelist                             /// 
////////////////////////////////////////////////////////////////////////////////

/// @notice Proof for claim is invalid.
error ProofInvalid();

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '../interfaces/IDopamineAuctionHouse.sol';
import { IDopamineAuctionHouseToken } from '../interfaces/IDopamineAuctionHouseToken.sol';

contract DopamineAuctionHouseStorageV1 {

    // The Nouns ERC721 token contract.
    IDopamineAuctionHouseToken public token;

    // The address of the pending admin of the auction house contract.
    address public pendingAdmin;

    // The address of the admin of the auction house contract.
    address public admin;

    // The minimum amount of time left in an auction after a new bid is created
    uint256 public timeBuffer;

    // The minimum price accepted in an auction
    uint256 public reservePrice;

    // The percentage of auction proceeds to direct to the treasury
    uint256 public treasurySplit;

    // The duration of a single auction (seconds)
    uint256 public duration;

    // The active auction
    IDopamineAuctionHouse.Auction public auction;

    // DAO treasury address.
    address payable public dao;

    // Team multisig address
    address payable public reserve;

    // Marker preventing reentrancy.
    uint256 internal _locked;

    // Indicates whether or not auction is paused.
    uint256 internal _paused;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./IDopamineAuctionHouseEvents.sol";

interface IDopamineAuctionHouse is IDopamineAuctionHouseEvents {

    struct Auction {
        uint256 tokenId;
        uint256 amount;
        uint256 startTime;
        uint256 endTime;
        address payable bidder;
        bool settled;
    }

    function settleAuction() external;

    function settleCurrentAndCreateNewAuction() external;

    function pause() external;

    function unpause() external;

    function createBid(uint256 tokenId) external payable;

    function setTimeBuffer(uint256 timeBuffer) external;

    function setReservePrice(uint256 reservePrice) external;

    function setTreasurySplit(uint256 teamFeePercentage) external;

    function setPendingAdmin(address newPendingAdmin) external;

    function acceptAdmin() external;

    function setDuration(uint256 duration) external;

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

interface IDopamineAuctionHouseToken is IERC721 {

    function mint() external returns (uint256);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address dst, uint256 wad) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IDopamineAuctionHouseEvents {

    event AuctionCreated(
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 endTime
    );

    event AuctionBid(
        uint256 indexed tokenId,
        address bidder,
        uint256 value,
        bool extended
    );

    event AuctionExtended(
        uint256 indexed tokenId,
        uint256 endTime
    );

    event AuctionPaused(address pauser);

    event AuctionUnpaused(address unpauser);
    
    event AuctionSettled(
        uint256 indexed tokenId,
        address winner,
        uint256 amount
    );

    event AuctionTimeBufferSet(uint256 timeBuffer);

    event AuctionReservePriceSet(uint256 reservePrice);

    event AuctionTreasurySplitSet(uint256 teamFeePercentage);

    event AuctionDurationSet(uint256 duration);

    event NewPendingAdmin(address pendingAdmin);

    event NewAdmin(address oldAdmin, address newAdmin);

    event RefundFailed(address refunded);

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