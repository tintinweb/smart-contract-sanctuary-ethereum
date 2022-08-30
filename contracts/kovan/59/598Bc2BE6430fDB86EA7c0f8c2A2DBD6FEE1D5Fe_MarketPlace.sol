// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;
pragma abicoder v2; // solhint-disable-line
import "./mixins/MarketTreasuryNode.sol";
import "./mixins/roles/MarketAdminRole.sol";
import "./mixins/NFTMarketCore.sol";
import "./mixins/SendValueWithFallbackWithdraw.sol";
import "./mixins/NFTMarketCreators.sol";
import "./mixins/NFTMarketFees.sol";
import "./mixins/NFTMarketAuction.sol";
import "./mixins/NFTMarketReserveAuction.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @title A market for NFTs on Foundation.
 * @dev This top level file holds no data directly to ease future upgrades.
 */
contract MarketPlace is
    MarketTreasuryNode,
    MarketAdminRole,
    NFTMarketCore,
    ReentrancyGuardUpgradeable,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw,
    NFTMarketFees,
    NFTMarketAuction,
    NFTMarketReserveAuction
{
    /**
     * @notice Called once to configure the contract after the initial deployment.
     * @dev This farms the initialize call out to inherited contracts as needed.
     */
    function initialize(address treasury) public initializer {
        MarketTreasuryNode._initializeMarketTreasuryNode(treasury);
        NFTMarketAuction._initializeNFTMarketAuction();
        NFTMarketReserveAuction._initializeNFTMarketReserveAuction();
    }

    /**
     * @notice Allows Foundation to update the market configuration.
     */
    function adminUpdateConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration,
        uint256 primaryFeeBasisPoints,
        uint256 secondaryFeeBasisPoints
    ) public onlyMarketAdmin {
        _updateReserveAuctionConfig(minPercentIncrementInBasisPoints, duration);
        _updateMarketFees(
            primaryFeeBasisPoints,
            secondaryFeeBasisPoints
        );
    }

    /**
     * @dev Checks who the seller for an NFT is, this will check escrow or return the current owner if not in escrow.
     * This is a no-op function required to avoid compile errors.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        override(NFTMarketCore, NFTMarketReserveAuction)
        returns (address)
    {
        return super._getSellerFor(nftContract, tokenId);
    }

    /**
     * @notice Allows Market to update the treasury contract address.
     */
    function adminUpdateContract(address treasury) external onlyMarketAdmin {
        _updateMarketTreasury(treasury);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @notice A mixin that stores a reference to the Market treasury contract.
 */
abstract contract MarketTreasuryNode is Initializable {
    using AddressUpgradeable for address;

    address private treasury;

    /**
     * @dev Called once after the initial deployment to set the Market treasury address.
     */
    function _initializeMarketTreasuryNode(address _treasury)
        internal
        initializer
    {
        require(
            _treasury.isContract(),
            "MarketTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    /**
     * @notice Returns the address of the Market treasury.
     */
    function getMarketTreasury() public view returns (address) {
        return treasury;
    }

    /**
     * @notice Updates the address of the Market treasury.
     */
    function _updateMarketTreasury(address _treasury) internal {
        require(
            _treasury.isContract(),
            "MarketTreasuryNode: Address is not a contract"
        );
        treasury = _treasury;
    }

    // `______gap` is added to each mixin to allow adding new data slots or additional mixins in an upgrade-safe way.
    uint256[2000] private __gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "../../interfaces/IAdminRole.sol";

import "../MarketTreasuryNode.sol";

/**
 * @notice Allows a contract to leverage an admin role defined by the market contract.
 */
abstract contract MarketAdminRole is MarketTreasuryNode {
    // This file uses 0 data slots (other than what's included via MarketTreasuryNode)

    modifier onlyMarketAdmin() {
        require(
            IAdminRole(getMarketTreasury()).isAdmin(msg.sender),
            "MarketAdminRole: caller does not have the Admin role"
        );
        _;
    }

    function _isMarketAdmin() internal view returns (bool) {
        return IAdminRole(getMarketTreasury()).isAdmin(msg.sender);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

/**
 * @notice A place for common modifiers and functions used by various NFTMarket mixins, if any.
 * @dev This also leaves a gap which can be used to add a new mixin to the top of the inheritance tree.
 */
abstract contract NFTMarketCore {
    /**
     * @dev If the auction did not have an escrowed seller to return, this falls back to return the current owner.
     * This allows functions to calculate the correct fees before the NFT has been listed in auction.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        returns (address)
    {
        return IERC721Upgradeable(nftContract).ownerOf(tokenId);
    }

    // 50 slots were consumed by adding ReentrancyGuardUpgradeable
    uint256[950] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice Attempt to send ETH and if the transfer fails or runs out of gas, store the balance
 * for future withdrawal instead.
 */
abstract contract SendValueWithFallbackWithdraw is ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address payable;
    using SafeMathUpgradeable for uint256;

    mapping(address => uint256) private pendingWithdrawals;

    event WithdrawPending(address indexed user, uint256 amount);
    event Withdrawal(address indexed user, uint256 amount);

    /**
     * @notice Returns how much funds are available for manual withdraw due to failed transfers.
     */
    function getPendingWithdrawal(address user) public view returns (uint256) {
        return pendingWithdrawals[user];
    }

    /**
     * @notice Allows a user to manually withdraw funds which originally failed to transfer to themselves.
     */
    function withdraw() public {
        withdrawFor(payable(msg.sender));
    }

    /**
     * @notice Allows anyone to manually trigger a withdrawal of funds which originally failed to transfer for a user.
     */
    function withdrawFor(address payable user) public nonReentrant {
        uint256 amount = pendingWithdrawals[user];
        require(amount > 0, "No funds are pending withdrawal");
        pendingWithdrawals[user] = 0;
        user.sendValue(amount);
        emit Withdrawal(user, amount);
    }

    /**
     * @dev Attempt to send a user ETH with a reasonably low gas limit of 20k,
     * which is enough to send to contracts as well.
     */
    function _sendValueWithFallbackWithdrawWithLowGasLimit(
        address user,
        uint256 amount
    ) internal {
        _sendValueWithFallbackWithdraw(user, amount, 20000);
    }

    /**
     * @dev Attempt to send a user or contract ETH with a moderate gas limit of 90k,
     * which is enough for a 5-way split.
     */
    function _sendValueWithFallbackWithdrawWithMediumGasLimit(
        address user,
        uint256 amount
    ) internal {
        _sendValueWithFallbackWithdraw(user, amount, 210000);
    }

    /**
     * @dev Attempt to send a user or contract ETH and if it fails store the amount owned for later withdrawal.
     */
    function _sendValueWithFallbackWithdraw(
        address user,
        uint256 amount,
        uint256 gasLimit
    ) private {
        if (amount == 0 || user == address(0)) {
            return;
        }
        // Cap the gas to prevent consuming all available gas to block a tx from completing successfully
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = payable(user).call{value: amount, gas: gasLimit}("");
        if (!success) {
            // Record failed sends for a withdrawal later
            // Transfers could fail if sent to a multisig with non-trivial receiver logic
            // solhint-disable-next-line reentrancy
            pendingWithdrawals[user] = pendingWithdrawals[user].add(amount);
            emit WithdrawPending(user, amount);
        }
    }

    uint256[499] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "../interfaces/INFT721.sol";

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

/**
 * @notice A mixin for associating creators to NFTs.
 * @dev In the future this may store creators directly in order to support NFTs created on a different platform.
 */
abstract contract NFTMarketCreators is
    ReentrancyGuardUpgradeable // Adding this unused mixin to help with linearization
{
    /**
     * @dev If the creator is not available then 0x0 is returned. Downstream this indicates that the creator
     * fee should be sent to the current seller instead.
     * This may apply when selling NFTs that were not minted on Foundation.
     */
    function _getCreator(address nftContract, uint256 tokenId)
        internal
        view
        returns (address)
    {
        try INFT721(nftContract).tokenCreator(tokenId) returns (
            address creator
        ) {
            return creator;
        } catch {
            return address(0);
        }
    }

    /**
     * @dev Returns the creator and a destination address for any payments to the creator,
     * returns address(0) if the creator is unknown.
     */
    function _getCreatorAndPaymentAddress(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        internal
        view
        returns (
            address payable,
            address payable,
            uint256
        )
    {
        address creator = _getCreator(nftContract, tokenId);
        try INFT721(nftContract).royaltyInfo(tokenId, price) returns (
            address payable tokenCreatorPaymentAddress,
            uint256 amount
        ) {
            if (tokenCreatorPaymentAddress != address(0)) {
                return (payable(creator), tokenCreatorPaymentAddress, amount);
            }
        } catch // solhint-disable-next-line no-empty-blocks
        {
            // Fall through to return (creator, creator) below
        }
        return (payable(creator), payable(creator), 0);
    }

    // 500 slots were added via the new SendValueWithFallbackWithdraw mixin
    uint256[500] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./MarketTreasuryNode.sol";
import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketCreators.sol";
import "./SendValueWithFallbackWithdraw.sol";

/**
 * @notice A mixin to distribute funds when an NFT is sold.
 */
abstract contract NFTMarketFees is
    Constants,
    Initializable,
    MarketTreasuryNode,
    NFTMarketCore,
    NFTMarketCreators,
    SendValueWithFallbackWithdraw
{
    using SafeMathUpgradeable for uint256;

    event MarketFeesUpdated(
        uint256 primaryFeeBasisPoints,
        uint256 secondaryFeeBasisPoints
    );

    uint256 private _primaryFeeBasisPoints;
    uint256 private _secondaryFeeBasisPoints;
    uint256 private _secondaryCreatorFeeBasisPoints;

    mapping(address => mapping(uint256 => bool))
        private nftContractToTokenIdToFirstSaleCompleted;

    /**
     * @notice Returns true if the given NFT has not been sold in this market previously and is being sold by the creator.
     */
    function getIsPrimary(address nftContract, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return
            _getIsPrimary(
                nftContract,
                tokenId,
                _getCreator(nftContract, tokenId),
                _getSellerFor(nftContract, tokenId)
            );
    }

    /**
     * @dev A helper that determines if this is a primary sale given the current seller.
     * This is a minor optimization to use the seller if already known instead of making a redundant lookup call.
     */
    function _getIsPrimary(
        address nftContract,
        uint256 tokenId,
        address creator,
        address seller
    ) private view returns (bool) {
        return
            !nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] &&
            creator == seller;
    }

    /**
     * @notice Returns the current fee configuration in basis points.
     */
    function getFeeConfig()
        public
        view
        returns (
            uint256 primaryFeeBasisPoints,
            uint256 secondaryFeeBasisPoints,
            uint256 secondaryCreatorFeeBasisPoints
        )
    {
        return (
            _primaryFeeBasisPoints,
            _secondaryFeeBasisPoints,
            _secondaryCreatorFeeBasisPoints
        );
    }

    /**
     * @notice Returns how funds will be distributed for a sale at the given price point.
     * @dev This could be used to present exact fee distributing on listing or before a bid is placed.
     */
    function getFees(
        address nftContract,
        uint256 tokenId,
        uint256 price
    )
        public
        view
        returns (
            uint256 marketFee,
            uint256 creatorSecondaryFee,
            uint256 ownerRev
        )
    {
        (marketFee, , creatorSecondaryFee, , ownerRev) = _getFees(
            nftContract,
            tokenId,
            _getSellerFor(nftContract, tokenId),
            price
        );
    }

    /**
     * @dev Calculates how funds should be distributed for the given sale details.
     * If this is a primary sale, the creator revenue will appear as `ownerRev`.
     */
    function _getFees(
        address nftContract,
        uint256 tokenId,
        address seller,
        uint256 price
    )
        private
        view
        returns (
            uint256 marketFee,
            address creatorSecondaryFeeTo,
            uint256 creatorSecondaryFee,
            address ownerRevTo,
            uint256 ownerRev
        )
    {
        // The tokenCreatorPaymentAddress replaces the creator as the fee recipient.
        (
            address creator,
            address tokenCreatorPaymentAddress,
            uint256 loyaltyAmount
        ) = _getCreatorAndPaymentAddress(nftContract, tokenId, price);
        uint256 marketFeeBasisPoints;
        if (_getIsPrimary(nftContract, tokenId, creator, seller)) {
            marketFeeBasisPoints = _primaryFeeBasisPoints;
            // On a primary sale, the creator is paid the remainder via `ownerRev`.
            ownerRevTo = tokenCreatorPaymentAddress;
        } else {
            marketFeeBasisPoints = _secondaryFeeBasisPoints;

            // If there is no creator then funds go to the seller instead.
            if (tokenCreatorPaymentAddress != address(0)) {
                // SafeMath is not required when dividing by a constant value > 0.
                if (loyaltyAmount > 0) {
                    creatorSecondaryFee = loyaltyAmount;
                }
                creatorSecondaryFeeTo = tokenCreatorPaymentAddress;
            }

            if (seller == creator) {
                ownerRevTo = tokenCreatorPaymentAddress;
            } else {
                ownerRevTo = seller;
            }
        }
        // SafeMath is not required when dividing by a constant value > 0.
        marketFee = price.mul(marketFeeBasisPoints) / BASIS_POINTS;
        ownerRev = price.sub(marketFee).sub(creatorSecondaryFee);
    }

    /**
     * @dev Distributes funds to market, creator, and NFT owner after a sale.
     */
    function _distributeFunds(
        address nftContract,
        uint256 tokenId,
        address seller,
        uint256 price
    )
        internal
        returns (
            uint256 marketFee,
            uint256 creatorFee,
            uint256 ownerRev
        )
    {
        address creatorFeeTo;
        address ownerRevTo;
        (marketFee, creatorFeeTo, creatorFee, ownerRevTo, ownerRev) = _getFees(
            nftContract,
            tokenId,
            seller,
            price
        );

        // Anytime fees are distributed that indicates the first sale is complete,
        // which will not change state during a secondary sale.
        // This must come after the `_getFees` call above as this state is considered in the function.
        nftContractToTokenIdToFirstSaleCompleted[nftContract][tokenId] = true;

        _sendValueWithFallbackWithdrawWithLowGasLimit(
            getMarketTreasury(),
            marketFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(
            creatorFeeTo,
            creatorFee
        );
        _sendValueWithFallbackWithdrawWithMediumGasLimit(ownerRevTo, ownerRev);
    }

    /**
     * @notice Allows Market to change the market fees.
     */
    function _updateMarketFees(
        uint256 primaryFeeBasisPoints,
        uint256 secondaryFeeBasisPoints
    ) internal {
        require(
            primaryFeeBasisPoints < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );
        require(
            secondaryFeeBasisPoints < BASIS_POINTS,
            "NFTMarketFees: Fees >= 100%"
        );
        _primaryFeeBasisPoints = primaryFeeBasisPoints;
        _secondaryFeeBasisPoints = secondaryFeeBasisPoints;

        emit MarketFeesUpdated(
            primaryFeeBasisPoints,
            secondaryFeeBasisPoints
        );
    }

    uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

/**
 * @notice An abstraction layer for auctions.
 * @dev This contract can be expanded with reusable calls and data as more auction types are added.
 */
abstract contract NFTMarketAuction {
    /**
     * @dev A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    function _initializeNFTMarketAuction() internal {
        nextAuctionId = 1;
    }

    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        return nextAuctionId++;
    }

    uint256[1000] private ______gap;
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;
pragma abicoder v2; // solhint-disable-line

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "./Constants.sol";
import "./NFTMarketCore.sol";
import "./NFTMarketFees.sol";
import "./SendValueWithFallbackWithdraw.sol";
import "./NFTMarketAuction.sol";
import "./roles/MarketAdminRole.sol";

/**
 * @notice Manages a reserve price auction for NFTs.
 */
abstract contract NFTMarketReserveAuction is
    Constants,
    MarketAdminRole,
    NFTMarketCore,
    ReentrancyGuardUpgradeable,
    SendValueWithFallbackWithdraw,
    NFTMarketFees,
    NFTMarketAuction
{
    using SafeMathUpgradeable for uint256;

    struct ReserveAuction {
        address nftContract;
        uint256 tokenId;
        address seller;
        uint256 duration;
        uint256 extensionDuration;
        uint256 endTime;
        address bidder;
        uint256 amount;
        bool canAuction;
    }
    mapping(address => mapping(uint256 => uint256))
        private nftContractToTokenIdToAuctionId;
    mapping(uint256 => ReserveAuction) private auctionIdToAuction;

    uint256 private _minPercentIncrementInBasisPoints;

    uint256 private _duration;

    // Cap the max duration so that overflows will not occur
    uint256 private constant MAX_MAX_DURATION = 1000 days;

    uint256 private constant EXTENSION_DURATION = 1 minutes;

    event ReserveAuctionConfigUpdated(
        uint256 minPercentIncrementInBasisPoints,
        uint256 maxBidIncrementRequirement,
        uint256 duration,
        uint256 extensionDuration,
        uint256 goLiveDate
    );

    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 tokenId,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        uint256 auctionId,
        bool canAuction
    );
    event ReserveAuctionUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );

    event ReserveAuctionCanceled(uint256 indexed auctionId);
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 endTime
    );
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 marketFee,
        uint256 creatorFee,
        uint256 ownerRev
    );
    event ReserveAuctionCanceledByAdmin(
        uint256 indexed auctionId,
        string reason
    );

    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        require(
            reservePrice > 0,
            "NFTMarketReserveAuction: Reserve price must be at least 1 wei"
        );
        _;
    }

    /**
     * @notice Returns auction details for a given auctionId.
     */
    function getReserveAuction(uint256 auctionId)
        public
        view
        returns (ReserveAuction memory)
    {
        return auctionIdToAuction[auctionId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @dev Returns the seller that put a given NFT into escrow,
     * or bubbles the call up to check the current owner if the NFT is not currently in escrow.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        virtual
        override
        returns (address)
    {
        address seller = auctionIdToAuction[
            nftContractToTokenIdToAuctionId[nftContract][tokenId]
        ].seller;
        if (seller == address(0)) {
            return super._getSellerFor(nftContract, tokenId);
        }
        return seller;
    }

    /**
     * @notice Returns the current configuration for reserve auctions.
     */
    function getReserveAuctionConfig()
        public
        view
        returns (uint256 minPercentIncrementInBasisPoints, uint256 duration)
    {
        minPercentIncrementInBasisPoints = _minPercentIncrementInBasisPoints;
        duration = _duration;
    }

    function _initializeNFTMarketReserveAuction() internal {
        _duration = 24 hours; // A sensible default value
    }

    function _updateReserveAuctionConfig(
        uint256 minPercentIncrementInBasisPoints,
        uint256 duration
    ) internal {
        require(
            minPercentIncrementInBasisPoints <= BASIS_POINTS,
            "NFTMarketReserveAuction: Min increment must be <= 100%"
        );
        // Cap the max duration so that overflows will not occur
        require(
            duration <= MAX_MAX_DURATION,
            "NFTMarketReserveAuction: Duration must be <= 1000 days"
        );
        require(
            duration >= EXTENSION_DURATION,
            "NFTMarketReserveAuction: Duration must be >= EXTENSION_DURATION"
        );
        _minPercentIncrementInBasisPoints = minPercentIncrementInBasisPoints;
        _duration = duration;

        // We continue to emit unused configuration variables to simplify the subgraph integration.
        emit ReserveAuctionConfigUpdated(
            minPercentIncrementInBasisPoints,
            0,
            duration,
            EXTENSION_DURATION,
            0
        );
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice
    ) external onlyValidAuctionConfig(reservePrice) nonReentrant {
        // If an auction is already in progress then the NFT would be in escrow and the modifier would have failed
        uint256 auctionId = _getNextAndIncrementAuctionId();
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        auctionIdToAuction[auctionId].nftContract = nftContract;
        auctionIdToAuction[auctionId].tokenId = tokenId;
        auctionIdToAuction[auctionId].seller = address(msg.sender);
        auctionIdToAuction[auctionId].duration = _duration;
        auctionIdToAuction[auctionId].extensionDuration = EXTENSION_DURATION;
        auctionIdToAuction[auctionId].amount = reservePrice;
        if (_isMarketAdmin()) {
            auctionIdToAuction[auctionId].canAuction = true;
        }

        IERC721Upgradeable(nftContract).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            _duration,
            EXTENSION_DURATION,
            reservePrice,
            auctionId,
            auctionIdToAuction[auctionId].canAuction
        );
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the configuration
     * such as the reservePrice may be changed by the seller.
     */
    function updateReserveAuction(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction: Not your auction"
        );
        require(
            auction.endTime == 0,
            "NFTMarketReserveAuction: Auction in progress"
        );

        auction.amount = reservePrice;

        emit ReserveAuctionUpdated(auctionId, reservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * The NFT is returned to the seller from escrow.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "NFTMarketReserveAuction: Not your auction"
        );
        require(
            auction.endTime == 0,
            "NFTMarketReserveAuction: Auction in progress"
        );
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice A bidder may place a bid which is at least the value defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moment of the auction, the countdown may be extended.
     */
    function placeBid(uint256 auctionId) external payable nonReentrant {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.canAuction == true,
            "NFTMarketReserveAuction: Auction not found"
        );

        if (auction.endTime == 0) {
            // If this is the first bid, ensure it's >= the reserve price
            require(
                auction.amount <= msg.value,
                "NFTMarketReserveAuction: Bid must be at least the reserve price"
            );
        } else {
            // If this bid outbids another, confirm that the bid is at least x% greater than the last
            require(
                auction.endTime >= block.timestamp,
                "NFTMarketReserveAuction: Auction is over"
            );
            require(
                auction.bidder != msg.sender,
                "NFTMarketReserveAuction: You already have an outstanding bid"
            );
            uint256 minAmount = _getMinBidAmountForReserveAuction(
                auction.amount
            );
            require(
                msg.value >= minAmount,
                "NFTMarketReserveAuction: Bid amount too low"
            );
        }

        if (auction.endTime == 0) {
            auction.amount = msg.value;
            auction.bidder = msg.sender;
            // On the first bid, the endTime is now + duration
            auction.endTime = block.timestamp + auction.duration;
        } else {
            // Cache and update bidder state before a possible reentrancy (via the value transfer)
            uint256 originalAmount = auction.amount;
            address originalBidder = auction.bidder;
            auction.amount = msg.value;
            auction.bidder = msg.sender;

            // When a bid outbids another, check to see if a time extension should apply.
            if (auction.endTime - block.timestamp < auction.extensionDuration) {
                auction.endTime = block.timestamp + auction.extensionDuration;
            }

            // Refund the previous bidder
            _sendValueWithFallbackWithdrawWithLowGasLimit(
                originalBidder,
                originalAmount
            );
        }

        emit ReserveAuctionBidPlaced(
            auctionId,
            msg.sender,
            msg.value,
            auction.endTime
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute funds.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.endTime > 0,
            "NFTMarketReserveAuction: Auction was already settled"
        );
        require(
            auction.endTime < block.timestamp,
            "NFTMarketReserveAuction: Auction still in progress"
        );
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.bidder,
            auction.tokenId
        );

        (
            uint256 marketFee,
            uint256 creatorFee,
            uint256 ownerRev
        ) = _distributeFunds(
                auction.nftContract,
                auction.tokenId,
                auction.seller,
                auction.amount
            );

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            marketFee,
            creatorFee,
            ownerRev
        );
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     */
    function getMinBidAmount(uint256 auctionId) public view returns (uint256) {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinBidAmountForReserveAuction(auction.amount);
    }

    /**
     * @dev Determines the minimum bid amount when outbidding another user.
     */
    function _getMinBidAmountForReserveAuction(uint256 currentBidAmount)
        private
        view
        returns (uint256)
    {
        uint256 minIncrement = currentBidAmount.mul(
            _minPercentIncrementInBasisPoints
        ) / BASIS_POINTS;
        if (minIncrement == 0) {
            // The next bid must be at least 1 wei greater than the current.
            return currentBidAmount.add(1);
        }
        return minIncrement.add(currentBidAmount);
    }

    /**
     * @notice Allows Market to cancel an auction, refunding the bidder and returning the NFT to the seller.
     * This should only be used for extreme cases such as DMCA takedown requests. The reason should always be provided.
     */
    function adminCancelReserveAuction(uint256 auctionId, string memory reason)
        public
        onlyMarketAdmin
    {
        require(
            bytes(reason).length > 0,
            "NFTMarketReserveAuction: Include a reason for this cancellation"
        );
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.amount > 0,
            "NFTMarketReserveAuction: Auction not found"
        );
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        IERC721Upgradeable(auction.nftContract).transferFrom(
            address(this),
            auction.seller,
            auction.tokenId
        );

        if (auction.bidder != address(0)) {
            _sendValueWithFallbackWithdrawWithMediumGasLimit(
                auction.bidder,
                auction.amount
            );
        }
        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice Allows Market to approve the auction for listing in market place;
     */
    function approveAuctionByAdmin(
        uint256 auctionId,
        bool status,
        string memory reason
    ) external onlyMarketAdmin {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.canAuction == false && auction.amount > 0,
            "Already approved or auction don't exist"
        );
        require(auction.endTime == 0, "Auction already started");

        if (status) {
            auctionIdToAuction[auctionId].canAuction = true;
        } else {
            adminCancelReserveAuction(auctionId, reason);
        }
    }

    uint256[1000] private ______gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
        bool isTopLevelCall = !_initializing;
        // require(
        //     (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
        //     "Initializable: contract is already initialized"
        // );
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        // require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

/**
 * @notice Interface for AdminRole which wraps the default admin role from
 * OpenZeppelin's AccessControl for easy integration.
 */
interface IAdminRole {
    function isAdmin(address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
// solhint-disable

pragma solidity 0.8.4;

interface INFT721 {
    function tokenCreator(uint256 tokenId) external view returns (address);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address payable receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity 0.8.4;

/**
 * @dev Constant values shared across mixins.
 */
abstract contract Constants {
    uint256 internal constant BASIS_POINTS = 10000;
}