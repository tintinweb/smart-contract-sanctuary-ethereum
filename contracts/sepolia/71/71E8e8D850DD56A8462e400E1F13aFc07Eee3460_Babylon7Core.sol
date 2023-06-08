// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

import "./interfaces/IBabylon7Core.sol";
import "./interfaces/IRandomProvider.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/Ownable2StepUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/// @title Babylon7Core
/// @notice Babylon7Core is the main contract of Babylon7. It implements the logic of listings with raffles:
/// creation, participation, canceling, settling, refunding, and transferring funds to the listing creator
/// @dev Babylon7Core inherits from the IBabylon7Core interface.
contract Babylon7Core is Initializable, IBabylon7Core, Ownable2StepUpgradeable, ReentrancyGuardUpgradeable {
    /// @dev Random provider for Chainlink VRF interactions
    IRandomProvider public randomProvider;
    /// @dev identifier of the last listing, acts as a counter
    /// existing listingIds start from 1
    uint256 public lastListingId;
    /// @dev Maximum duration for active listing sellout, after that a listing can be canceled by refund
    uint256 public maxListingDuration;
    /// @dev Minimum donation to the treasury
    uint256 public minDonationBps;
    /// @dev Address of the Babylon7 treasury
    address public treasury;

    /// @dev collection address => tokenId => id of a listing
    mapping(address => mapping(uint256 => uint256)) internal _ids;
    /// @dev id of a listing => a listing info
    mapping(uint256 => ListingInfo) internal _listingInfos;
    /// @dev id of a listing => a listing restrictions
    mapping(uint256 => ListingRestrictions) internal _listingRestrictions;
    /// @dev id of a listing => participant address => num of tickets
    mapping(uint256 => mapping(address => uint256)) internal _participations;
    /// @dev id of a listing => id of a ticket => participant address
    mapping(uint256 => mapping(uint256 => address)) internal _ticketsOwners;

    uint256 private constant BASIS_POINTS = 10000;
    uint256 private constant MINIMUM_MAX_LISTING_DURATION = 2 hours;

    /// @notice Emitted when a listing is created
    /// @param listingId identifier of a created listing
    /// @param creator wallet address of a listing creator
    /// @param token contract address of a raffled token
    /// @param tokenId identifier of a raffled token
    /// @param allowlistRoot a Merkle tree root of an allowlist
    /// @param reserved a number of tickets that are reserved for an allowlist
    /// @param maxPerAddress a number of tickets that can be purchased by a single wallet
    event ListingCreated(
        uint256 indexed listingId,
        address indexed creator,
        address indexed token,
        uint256 tokenId,
        bytes32 allowlistRoot,
        uint256 reserved,
        uint256 maxPerAddress
    );

    /// @notice Emitted when a listing enters the Canceled state
    /// @param listingId identifier of a listing
    event ListingCanceled(uint256 indexed listingId);

    /// @notice Emitted when a listing enters the Finalized state
    /// @param listingId identifier of a listing
    event ListingFinalized(uint256 indexed listingId);

    /// @notice Emitted when a listing enters the Resolving state
    /// @param listingId identifier of a listing
    /// @param randomRequestId identifier of a Chainlink VRF random request
    event ListingResolving(uint256 indexed listingId, uint256 randomRequestId);

    /// @notice Emitted when a listing enters the Successful state
    /// @param listingId identifier of a listing
    /// @param winnerIndex identifier of a winning ticket
    /// @param winner wallet address of a listing winner
    event ListingSuccessful(uint256 indexed listingId, uint256 winnerIndex, address winner);

    /// @notice Emitted when listing restrictions are updated
    /// @param listingId identifier of a listing
    /// @param allowlistRoot a Merkle tree root of an allowlist
    /// @param reserved a number of tickets that is reserved for an allowlist
    /// @param mintedFromReserve a number of tickets that were minted by wallets from an allowlist
    /// @param maxPerAddress a number of tickets that can be purchased by a single wallet
    event ListingRestrictionsUpdated(
        uint256 indexed listingId,
        bytes32 allowlistRoot,
        uint256 reserved,
        uint256 mintedFromReserve,
        uint256 maxPerAddress
    );

    /// @notice Emitted when tickets are purchased
    /// @param listingId identifier of a listing
    /// @param participant wallet address of a participant
    /// @param ticketsAmount a number of tickets that were purchased
    event NewParticipant(uint256 indexed listingId, address indexed participant, uint256 ticketsAmount);

    error ActiveListingForItemAlreadyExists();
    error DonationOutOfRange();
    error EarlyParticipation();
    error IncorrectMaxListingDuration();
    error IncorrectMinDonationBps();
    error IncorrectRestrictions();
    error IncorrectValue();
    error ListingStateNotActive();
    error ListingStateNotCanceled();
    error ListingStateNotResolving();
    error ListingStateNotSuccessful();
    error MaxPerAddressExceed();
    error NoTicketsAvailable();
    error NotOverdue();
    error OnlyCreator();
    error OnlyRandomProvider();
    error TokenNotApproved();
    error TransferCreatorFail();
    error TransferRefundFail();
    error TransferTreasuryFail();
    error ZeroSold();
    error ZeroTickets();

    /// @notice Initializer for the contract
    /// @dev Babylon7Core is deployed using TransparentUpgradeableProxy pattern
    /// @param minDonationBps_ donation basis points lower limit
    /// @param treasury_ address of the treasury contract
    function initialize(uint256 minDonationBps_, address treasury_) external initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        minDonationBps = minDonationBps_;
        maxListingDuration = MINIMUM_MAX_LISTING_DURATION;
        treasury = treasury_;
    }

    /// @notice Creates a new listing for a raffled item with a new identifier
    /// @param item ListingItem structure with info about a raffled token
    /// @param restrictions ListingRestrictions structure with all listing restrictions info
    /// @param timeStart timestamp when a listing will be open to participating in
    /// @param price amount of native currency charged per 1 ticket
    /// @param totalTickets total number of tickets in a listing
    /// @param donationBps basis points that a creator is willing to donate
    function createListing(
        ListingItem calldata item,
        ListingRestrictions calldata restrictions,
        uint256 timeStart,
        uint256 price,
        uint256 totalTickets,
        uint256 donationBps
    ) external {
        uint256 listingId = _ids[item.token][item.identifier];

        if (
            listingId != 0 &&
            (_listingInfos[listingId].state == ListingState.Active ||
                _listingInfos[listingId].state == ListingState.Resolving)
        ) revert ActiveListingForItemAlreadyExists();

        if (!_checkApproval(msg.sender, item)) revert TokenNotApproved();
        if (totalTickets == 0) revert ZeroTickets();
        if (donationBps < minDonationBps || donationBps > BASIS_POINTS) revert DonationOutOfRange();

        if (restrictions.reserved > totalTickets || restrictions.maxPerAddress > totalTickets)
            revert IncorrectRestrictions();

        listingId = lastListingId + 1;
        _ids[item.token][item.identifier] = listingId;
        ListingInfo storage listing = _listingInfos[listingId];
        listing.item = item;
        listing.creator = msg.sender;
        listing.price = price;
        listing.timeStart = timeStart > block.timestamp ? timeStart : block.timestamp;
        listing.totalTickets = totalTickets;
        listing.donationBps = donationBps;
        listing.creationTimestamp = block.timestamp;

        ListingRestrictions storage listingRestrictions = _listingRestrictions[listingId];
        listingRestrictions.allowlistRoot = restrictions.allowlistRoot;
        listingRestrictions.reserved = restrictions.reserved;
        listingRestrictions.maxPerAddress = restrictions.maxPerAddress;
        lastListingId = listingId;

        emit ListingCreated(
            listingId,
            msg.sender,
            item.token,
            item.identifier,
            restrictions.allowlistRoot,
            restrictions.reserved,
            restrictions.maxPerAddress
        );
    }

    /// @notice Allows to participate in an existing listing
    /// @dev protected from reentrancy by ReentrancyGuard modifier
    /// @param id identifier of a listing
    /// @param tickets number of tickets a user is willing to purchase
    /// @param allowlistProof a Merkle tree proof that a user is in an allowlist
    function participate(uint256 id, uint256 tickets, bytes32[] calldata allowlistProof) external payable nonReentrant {
        ListingInfo storage listing = _listingInfos[id];
        if (tickets == 0) revert ZeroTickets();
        if (listing.state != ListingState.Active) revert ListingStateNotActive();
        if (!_checkApproval(listing.creator, listing.item)) revert TokenNotApproved();
        if (block.timestamp < listing.timeStart) revert EarlyParticipation();
        uint256 current = listing.currentTickets;
        uint256 projectedTotalTickets = current + tickets;
        if (projectedTotalTickets > listing.totalTickets) revert NoTicketsAvailable();
        uint256 totalPrice = listing.price * tickets;
        if (msg.value != totalPrice) revert IncorrectValue();

        ListingRestrictions storage restrictions = _listingRestrictions[id];

        uint256 participations = _participations[id][msg.sender] + tickets;
        if (participations > restrictions.maxPerAddress) revert MaxPerAddressExceed();
        _participations[id][msg.sender] = participations;

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        if (MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
            uint256 allowlistLeft = restrictions.reserved - restrictions.mintedFromReserve;
            if (allowlistLeft != 0) {
                if (allowlistLeft <= tickets) {
                    restrictions.mintedFromReserve = restrictions.reserved;
                } else {
                    restrictions.mintedFromReserve += tickets;
                }

                emit ListingRestrictionsUpdated(
                    id,
                    restrictions.allowlistRoot,
                    restrictions.reserved,
                    restrictions.mintedFromReserve,
                    restrictions.maxPerAddress
                );
            }
        } else {
            uint256 available = (listing.totalTickets + restrictions.mintedFromReserve) -
                current -
                restrictions.reserved;

            if (available < tickets) revert NoTicketsAvailable();
        }

        for (uint i = current; i < projectedTotalTickets; i++) {
            _ticketsOwners[id][i] = msg.sender;
        }

        listing.currentTickets = projectedTotalTickets;

        emit NewParticipant(id, msg.sender, tickets);

        if (listing.currentTickets == listing.totalTickets) {
            listing.randomRequestId = randomProvider.requestRandom(id);
            listing.state = ListingState.Resolving;

            emit ListingResolving(id, listing.randomRequestId);
        }
    }

    /// @notice Allows creator to update restrictions of an existing listing
    /// @dev can only be called for active listing by a creator of a listing
    /// @param id identifier of a listing
    /// @param newRestrictions ListingRestrictions structure with new listing restrictions info
    function updateListingRestrictions(uint256 id, ListingRestrictions calldata newRestrictions) external {
        ListingInfo storage listing = _listingInfos[id];
        uint256 totalTickets = listing.totalTickets;
        if (listing.state != ListingState.Active) revert ListingStateNotActive();
        if (msg.sender != listing.creator) revert OnlyCreator();

        ListingRestrictions storage restrictions = _listingRestrictions[id];
        restrictions.allowlistRoot = newRestrictions.allowlistRoot;

        uint256 reserveFloor = restrictions.mintedFromReserve;
        uint256 reserveCeiling = (totalTickets - listing.currentTickets + restrictions.mintedFromReserve);

        if (newRestrictions.reserved <= reserveCeiling) {
            restrictions.reserved = newRestrictions.reserved <= reserveFloor ? reserveFloor : newRestrictions.reserved;
        } else {
            restrictions.reserved = reserveCeiling;
        }

        restrictions.maxPerAddress = newRestrictions.maxPerAddress >= totalTickets
            ? totalTickets
            : newRestrictions.maxPerAddress;

        emit ListingRestrictionsUpdated(
            id,
            restrictions.allowlistRoot,
            restrictions.reserved,
            restrictions.mintedFromReserve,
            restrictions.maxPerAddress
        );
    }

    /// @notice Settles existing active listing
    /// @dev can only be called on listing with at least 1 ticket bought and only by a listing creator
    /// @param id identifier of a listing
    function settleListing(uint256 id) external {
        ListingInfo storage listing = _listingInfos[id];
        if (listing.state != ListingState.Active) revert ListingStateNotActive();
        if (msg.sender != listing.creator) revert OnlyCreator();
        if (listing.currentTickets == 0) revert ZeroSold();

        listing.randomRequestId = randomProvider.requestRandom(id);
        listing.state = ListingState.Resolving;

        emit ListingResolving(id, listing.randomRequestId);
    }

    /// @notice Cancels an existing listing
    /// @dev can be performed by a listing creator if a listing is active or by anyone if a random request is overdue
    /// @param id identifier of a listing
    function cancelListing(uint256 id) external {
        ListingInfo storage listing = _listingInfos[id];
        if (listing.state == ListingState.Resolving) {
            if (!randomProvider.isRequestOverdue(listing.randomRequestId)) revert NotOverdue();
        } else {
            if (listing.state != ListingState.Active) revert ListingStateNotActive();
            if (msg.sender != listing.creator) revert OnlyCreator();
        }

        listing.state = ListingState.Canceled;

        emit ListingCanceled(id);
    }

    /// @notice Transfers funds accumulated from purchased tickets to a listing creator and the treasury
    /// @dev can be performed by anyone but only on listings in the successful state
    /// @param id identifier of a listing
    function transferETHToCreator(uint256 id) external nonReentrant {
        ListingInfo storage listing = _listingInfos[id];
        if (listing.state != ListingState.Successful) revert ListingStateNotSuccessful();
        listing.state = ListingState.Finalized;

        bool sent;
        uint256 creatorPayout = listing.currentTickets * listing.price;
        uint256 donation = (creatorPayout * listing.donationBps) / BASIS_POINTS;

        if (donation != 0) {
            creatorPayout -= donation;
            (sent, ) = treasury.call{value: donation}("");
            if (!sent) revert TransferTreasuryFail();
        }

        if (creatorPayout != 0) {
            (sent, ) = listing.creator.call{value: creatorPayout}("");
            if (!sent) revert TransferCreatorFail();
        }

        emit ListingFinalized(id);
    }

    /// @notice Transfers funds back to the participant from a canceled listing
    /// @dev if a listing creator revoked an item approval, or a listing didn't sell out in maxListingDuration
    /// then the listing cancels
    /// @param id identifier of a listing
    function refund(uint256 id) external nonReentrant {
        ListingInfo storage listing = _listingInfos[id];

        if (
            (listing.state == ListingState.Active && (listing.timeStart + maxListingDuration <= block.timestamp)) ||
            (listing.state == ListingState.Resolving && randomProvider.isRequestOverdue(listing.randomRequestId)) ||
            ((listing.state == ListingState.Active || listing.state == ListingState.Resolving) &&
                !_checkApproval(listing.creator, listing.item))
        ) {
            listing.state = ListingState.Canceled;

            emit ListingCanceled(id);
        }

        if (listing.state != ListingState.Canceled) revert ListingStateNotCanceled();

        uint256 tickets = _participations[id][msg.sender];
        if (tickets == 0) revert ZeroTickets();
        _participations[id][msg.sender] = 0;

        uint256 amount = tickets * listing.price;
        (bool sent, ) = msg.sender.call{value: amount}("");

        if (!sent) revert TransferRefundFail();
    }

    /// @inheritdoc IBabylon7Core
    function resolveWinner(uint256 id, uint256 random) external override {
        if (msg.sender != address(randomProvider)) revert OnlyRandomProvider();
        ListingInfo storage listing = _listingInfos[id];
        if (listing.state != ListingState.Resolving) revert ListingStateNotResolving();
        uint256 winnerIndex = random % listing.currentTickets;
        address winner = _ticketsOwners[id][winnerIndex];
        listing.winner = winner;
        listing.state = ListingState.Successful;

        if (listing.item.itemType == ItemType.ERC1155) {
            IERC1155(listing.item.token).safeTransferFrom(
                listing.creator,
                winner,
                listing.item.identifier,
                listing.item.amount,
                ""
            );
        } else if (listing.item.itemType == ItemType.ERC721) {
            IERC721(listing.item.token).safeTransferFrom(listing.creator, winner, listing.item.identifier);
        }

        emit ListingSuccessful(id, winnerIndex, winner);
    }

    /// @notice Changes maxListingDuration parameter
    /// @dev called only by the owner
    /// @param newMaxListingDuration new maxListingDuration parameter
    function setMaxListingDuration(uint256 newMaxListingDuration) external onlyOwner {
        if (newMaxListingDuration < MINIMUM_MAX_LISTING_DURATION) revert IncorrectMaxListingDuration();
        maxListingDuration = newMaxListingDuration;
    }

    /// @notice Changes randomProvider
    /// @dev called only by the owner
    /// @param newRandomProvider new randomProvider
    function setRandomProvider(IRandomProvider newRandomProvider) external onlyOwner {
        randomProvider = newRandomProvider;
    }

    /// @notice Changes minDonationBps parameter
    /// @dev called only by the owner
    /// @param newMinDonationBps new minDonationBps value
    function setMinDonationBps(uint256 newMinDonationBps) external onlyOwner {
        if (newMinDonationBps > BASIS_POINTS) revert IncorrectMinDonationBps();
        minDonationBps = newMinDonationBps;
    }

    /// @notice Changes treasury
    /// @dev called only by the owner
    /// @param newTreasury new treasury address
    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    /// @notice Checks if an item is approved and owned by a listing creator
    /// @param creator address of a listing creator
    /// @param item an item to be raffled
    /// @return boolean if an item is approved and owned or not
    function _checkApproval(address creator, ListingItem memory item) internal view returns (bool) {
        if (item.itemType == ItemType.ERC721) {
            address owner = IERC721(item.token).ownerOf(item.identifier);
            address operator = IERC721(item.token).getApproved(item.identifier);
            return (owner == creator && address(this) == operator);
        } else if (item.itemType == ItemType.ERC1155) {
            bool approved = IERC1155(item.token).isApprovedForAll(creator, address(this));
            uint256 amount = IERC1155(item.token).balanceOf(creator, item.identifier);
            return (approved && (amount >= item.amount));
        }

        return false;
    }

    /// @notice External function to verify if an item is approved and owned by a listing creator
    /// @param creator address of a listing creator
    /// @param item an item to be raffled
    /// @return boolean if an item is approved and owned or not
    function checkApproval(address creator, ListingItem calldata item) external view returns (bool) {
        return _checkApproval(creator, item);
    }

    /// @notice Provides a number of tickets that a particular address can purchase in a particular listing at
    /// the current moment
    /// @dev used by the frontend
    /// @param id identifier of a listing
    /// @param user wallet address of a user
    /// @param allowlistProof a Merkle tree proof that a user is in an allowlist
    /// @return a number of tickets that user can purchase
    function getAvailableToParticipate(
        uint256 id,
        address user,
        bytes32[] calldata allowlistProof
    ) external view returns (uint256) {
        ListingInfo storage listing = _listingInfos[id];
        ListingRestrictions storage restrictions = _listingRestrictions[id];
        uint256 current = listing.currentTickets;
        uint256 total = listing.totalTickets;
        uint256 available = total - current;

        if (
            (listing.state == ListingState.Active) &&
            _checkApproval(listing.creator, listing.item) &&
            (block.timestamp >= listing.timeStart) &&
            (available != 0) &&
            (restrictions.maxPerAddress > _participations[id][user])
        ) {
            uint256 leftForAddress = restrictions.maxPerAddress - _participations[id][user];
            bytes32 leaf = keccak256(abi.encodePacked(user));
            if (!MerkleProof.verify(allowlistProof, restrictions.allowlistRoot, leaf)) {
                available = (total + restrictions.mintedFromReserve) - current - restrictions.reserved;
            }

            return available >= leftForAddress ? leftForAddress : available;
        }

        return 0;
    }

    /// @notice Returns an address that purchased a ticketId in a listing
    /// @param id identifier of a listing
    /// @param ticketId identifier of a ticket
    /// @return wallet address of a participant
    function getTicketOwner(uint256 id, uint256 ticketId) external view returns (address) {
        return _ticketsOwners[id][ticketId];
    }

    /// @notice Returns the latest listing id for a raffled item
    /// @dev if the particular item was raffled several times, the latest listing id will be returned
    /// @param token contract address of a raffled item
    /// @param tokenId identifier of a raffled item
    /// @return listing id
    function getListingId(address token, uint256 tokenId) external view returns (uint256) {
        return _ids[token][tokenId];
    }

    /// @inheritdoc IBabylon7Core
    function getListingInfo(uint256 id) external view override returns (ListingInfo memory) {
        return _listingInfos[id];
    }

    /// @notice Returns a number of tickets of a user in a listing
    /// @param id identifier of a listing
    /// @param user wallet address of a user
    /// @return a number of tickets of a user in a listing
    function getListingParticipations(uint256 id, address user) external view returns (uint256) {
        return _participations[id][user];
    }

    /// @notice Returns restriction for a listing
    /// @param id identifier of a listing
    /// @return ListingRestrictions structure for a listing
    function getListingRestrictions(uint256 id) external view returns (ListingRestrictions memory) {
        return _listingRestrictions[id];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

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
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(bytes32[] calldata proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuilds the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value from the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i]
                ? (leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++])
                : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            unchecked {
                return hashes[totalHashes - 1];
            }
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IBabylon7Core {
    /// @dev Indicates type of a token
    enum ItemType {
        ERC721,
        ERC1155
    }

    /// @dev Storage struct that contains all information about raffled token
    struct ListingItem {
        /// @dev Type of a token
        ItemType itemType;
        /// @dev Address of a token
        address token;
        /// @dev Token identifier
        uint256 identifier;
        /// @dev Amount of tokens
        uint256 amount;
    }

    /// @dev Indicates state of a listing
    enum ListingState {
        Active,
        Resolving,
        Successful,
        Finalized,
        Canceled
    }

    /// @dev Storage struct that contains all required information for a specific listing
    struct ListingInfo {
        /// @dev Token that is provided for a raffle
        ListingItem item;
        /// @dev Indicates current state of a listing
        ListingState state;
        /// @dev Address of a listing creator
        address creator;
        /// @dev Address of a listing winner
        address winner;
        /// @dev ETH price per 1 ticket
        uint256 price;
        /// @dev Timestamp when listing starts
        uint256 timeStart;
        /// @dev Total amount of tickets to be sold
        uint256 totalTickets;
        /// @dev Current amount of sold tickets
        uint256 currentTickets;
        /// @dev Basis points of donation
        uint256 donationBps;
        /// @dev Requiest id from Chainlink VRF
        uint256 randomRequestId;
        /// @dev Timestamp of creation
        uint256 creationTimestamp;
    }

    /// @dev Storage struct that contains all restriction for a specific listing
    struct ListingRestrictions {
        /// @dev Root of an allowlist Merkle tree
        bytes32 allowlistRoot;
        /// @dev Amount of tickets reserved for an allowlist
        uint256 reserved;
        /// @dev Amount of tickets bought by allowlisted users
        uint256 mintedFromReserve;
        /// @dev Amount of maximum tickets per 1 address
        uint256 maxPerAddress;
    }

    /// @notice Determines the winner of a raffle based on the provided random number, then transfers
    /// the item to the winner
    /// @dev called by the Chainlink VRF service only through the Random Provider contract
    /// @param id identifier of a listing
    /// @param random a random number provided by the Chainlink VRF
    function resolveWinner(uint256 id, uint256 random) external;

    /// @notice Returns all info about a listing with a specific id
    /// @param id identifier of a listing
    /// @return ListingInfo struct for a listing
    function getListingInfo(uint256 id) external view returns (ListingInfo memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.19;

interface IRandomProvider {
    /// @notice Returns whether the request is overdue or not
    /// @param requestId identifier of a request
    /// @return boolean whether the request is overdue or not
    function isRequestOverdue(uint256 requestId) external view returns (bool);

    /// @notice Makes a random number request to the Chainlink VRF Coordinator
    /// @dev the overdue criteria is whether 24 hours passed
    /// @param listingId identifier of a listing
    /// @return requestId identifier of a request
    function requestRandom(uint256 listingId) external returns (uint256);
}