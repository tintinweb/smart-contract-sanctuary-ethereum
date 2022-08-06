// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/MerkleProofUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

/**
 * @title Allows the owner of an NFT to list it in auction.
 * @notice NFTs in auction are escrowed in the contract.
 */
contract StreetlabAuctionHouse is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /**
     * @notice Emitted when a bid is placed.
     * @param auctionId The id of the auction this bid was for.
     * @param bidder The address of the bidder.
     * @param amount The amount of the bid.
     * @param endTime The new end time of the auction (which may have been set or extended by this bid).
     */
    event ReserveAuctionBidPlaced(
        uint256 indexed auctionId,
        address indexed bidder,
        uint256 amount,
        uint256 endTime
    );
    /**
     * @notice Emitted when an auction is cancelled.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was cancelled.
     */
    event ReserveAuctionCanceled(uint256 indexed auctionId);
    /**
     * @notice Emitted when an auction is canceled by a Foundation admin.
     * @dev When this occurs, the highest bidder (if there was a bid) is automatically refunded.
     * @param auctionId The id of the auction that was cancelled.
     * @param reason The reason for the cancellation.
     */
    event ReserveAuctionCanceledByAdmin(
        uint256 indexed auctionId,
        string reason
    );
    /**
     * @notice Emitted when an NFT is listed for auction.
     * @param seller The address of the seller.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param startTime The time at which this auction will start accepting bids.
     * '0' will start on first bid.
     * @param duration The duration of the auction.
     * @param extensionDuration The duration of the auction extension window.
     * @param reservePrice The reserve price to kick off the auction.
     * @param allowlistMerkleRoot Root hash of addresses for allowlist.
     * @param auctionId The id of the auction that was created.
     */
    event ReserveAuctionCreated(
        address indexed seller,
        address indexed nftContract,
        uint256 indexed tokenId,
        uint256 startTime,
        uint256 duration,
        uint256 extensionDuration,
        uint256 reservePrice,
        bytes32 allowlistMerkleRoot,
        uint256 auctionId
    );
    /**
     * @notice Emitted when an auction that has already ended is finalized,
     * indicating that the NFT has been transferred and revenue from the sale distributed.
     * @dev The amount of the highest bid / final sale price for this auction
     * is `protocolFee` + `creatorFee` + `sellerRev`.
     * @param auctionId The id of the auction that was finalized.
     * @param seller The address of the seller.
     * @param bidder The address of the highest bidder that won the NFT.
     * @param amount The final bid amount.
     */
    event ReserveAuctionFinalized(
        uint256 indexed auctionId,
        address indexed seller,
        address indexed bidder,
        uint256 amount
    );
    /**
     * @notice Emitted when an auction is invalidated due to other market activity.
     * @dev This occurs when the NFT is sold another way, such as with `buy` or `acceptOffer`.
     * @param auctionId The id of the auction that was invalidated.
     */
    event ReserveAuctionInvalidated(uint256 indexed auctionId);
    /**
     * @notice Emitted when the auction's reserve price is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param reservePrice The new reserve price for the auction.
     */
    event ReserveAuctionPriceUpdated(
        uint256 indexed auctionId,
        uint256 reservePrice
    );
    /**
     * @notice Emitted when the auction's allowlist merkle root is changed.
     * @dev This is only possible if the auction has not received any bids.
     * @param auctionId The id of the auction that was updated.
     * @param allowlistMerkleRoot Root hash of addresses for allowlist.
     */
    event ReserveAuctionAllowlistUpdated(
        uint256 indexed auctionId,
        bytes32 allowlistMerkleRoot
    );

    /// @notice Confirms that the reserve price is not zero.
    modifier onlyValidAuctionConfig(uint256 reservePrice) {
        require(
            reservePrice != 0,
            "reserve price must be set to non zero value"
        );
        _;
    }

    /// @notice The auction configuration for a specific NFT.
    struct ReserveAuction {
        /// @notice The address of the NFT contract.
        address nftContract;
        /// @notice The id of the NFT.
        uint256 tokenId;
        /// @notice The owner of the NFT which listed it in auction.
        address payable seller;
        /// @notice The time at which this auction will start accepting bids.
        /// @dev If set to '0', auction starts on first bid.
        uint256 startTime;
        /// @notice The time at which this auction will not accept any new bids.
        /// @dev This is `0` until the first bid is placed.
        uint256 endTime;
        /// @notice The current highest bidder in this auction.
        /// @dev This is `address(0)` until the first bid is placed.
        address payable bidder;
        /// @notice The latest price of the NFT in this auction.
        /// @dev This is set to the reserve price, and then to the highest bid once the auction has started.
        uint256 amount;
        /// @dev Root hash of addresses for allowlist
        bytes32 allowlistMerkleRoot;
        /// @notice Whether anyone can bid or only genesis holders
        bool publicBid;
    }

    /**
     * @notice A global id for auctions of any type.
     */
    uint256 private nextAuctionId;

    /// @notice The auction configuration for a specific auction id.
    mapping(address => mapping(uint256 => uint256))
        private nftContractToTokenIdToAuctionId;
    /// @notice The auction id for a specific NFT.
    /// @dev This is deleted when an auction is finalized or canceled.
    mapping(uint256 => ReserveAuction) private auctionIdToAuction;

    /// @notice How long an auction lasts for once the first bid has been received.
    uint256 private immutable DURATION;

    /// @notice The window for auction extensions, any bid placed in the final 15 minutes
    /// of an auction will reset the time remaining to 15 minutes.
    uint256 private constant EXTENSION_DURATION = 15 minutes;

    /// @notice Caps the max duration that may be configured so that overflows will not occur.
    uint256 private constant MAX_MAX_DURATION = 1000 days;

    /// @notice Minimum percentage increment of the outstanding bid to place a new bid.
    uint256 private immutable MIN_PERCENT_INCREMENT_DENOMINATOR;

    /// @notice Streetlab Genesis contract address
    address private immutable STREETLAB_GENESIS_ADDRESS;

    /**
     * @notice Configures the duration for auctions.
     * @param duration The duration for auctions, in seconds.
     */
    constructor(
        uint256 duration,
        uint256 minPercentIncrement,
        address streetlabGenesis
    ) {
        // constructor(uint256 duration) {
        require(duration <= MAX_MAX_DURATION, "exceeds max duration");
        require(duration >= EXTENSION_DURATION, "less than extension duration");
        DURATION = duration;
        MIN_PERCENT_INCREMENT_DENOMINATOR = minPercentIncrement;
        STREETLAB_GENESIS_ADDRESS = streetlabGenesis;
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This farms the initialize call out to inherited contracts as needed to initialize mutable variables.
     */
    function initialize() external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        _initializeNFTMarketAuction();
    }

    /**
     * @notice Called once to configure the contract after the initial proxy deployment.
     * @dev This sets the initial auction id to 1, making the first auction cheaper
     * and id 0 represents no auction found.
     */
    function _initializeNFTMarketAuction() internal onlyInitializing {
        nextAuctionId = 1;
    }

    /**
     * @notice Returns id to assign to the next auction.
     */
    function _getNextAndIncrementAuctionId() internal returns (uint256) {
        // AuctionId cannot overflow 256 bits.
        unchecked {
            return nextAuctionId++;
        }
    }

    /**
     * @notice Allows Foundation to cancel an auction, refunding the bidder and returning the NFT to
     * the seller (if not active buy price set).
     * This should only be used for extreme cases such as DMCA takedown requests.
     * @param auctionId The id of the auction to cancel.
     * @param reason The reason for the cancellation (a required field).
     */
    function adminCancelReserveAuction(
        uint256 auctionId,
        string calldata reason
    ) external onlyOwner nonReentrant {
        require(bytes(reason).length != 0, "cannot cancel without reason");
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(auction.amount != 0, "no such auction");

        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        // Return the NFT to the owner.
        _transferFromEscrowIfAvailable(
            auction.nftContract,
            auction.tokenId,
            auction.seller
        );

        if (auction.bidder != address(0)) {
            // Refund the highest bidder if any bids were placed in this auction.
            AddressUpgradeable.sendValue(
                payable(auction.bidder),
                auction.amount
            );
        }

        emit ReserveAuctionCanceledByAdmin(auctionId, reason);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, it may be canceled by the seller.
     * @dev The NFT is transferred back to the owner unless there is still a buy price set.
     * @param auctionId The id of the auction to cancel.
     */
    function cancelReserveAuction(uint256 auctionId) external nonReentrant {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );
        require(auction.endTime == 0, "cannot update auction in progress");

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        // Transfer the NFT unless it still has a buy price set.
        _transferFromEscrowIfAvailable(
            auction.nftContract,
            auction.tokenId,
            auction.seller
        );

        emit ReserveAuctionCanceled(auctionId);
    }

    /**
     * @notice Creates an auction for the given NFT.
     * The NFT is held in escrow until the auction is finalized or canceled.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @param reservePrice The initial reserve price for the auction.
     * @param startTime The time at which this auction will start accepting bids.
     * '0' will start on first bid.
     * @param allowlistMerkleRoot Merkle tree root hash of addresses for allowlist
     */
    function createReserveAuction(
        address nftContract,
        uint256 tokenId,
        uint256 reservePrice,
        uint256 startTime,
        bytes32 allowlistMerkleRoot
    ) external nonReentrant onlyValidAuctionConfig(reservePrice) {
        uint256 auctionId = _getNextAndIncrementAuctionId();

        // If the `msg.sender` is not the owner of the NFT, transferring into escrow should fail.
        _transferToEscrow(nftContract, tokenId);

        // This check must be after _transferToEscrow in case auto-settle was required
        require(
            nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0,
            "auction already listed"
        );
        // Store the auction details
        nftContractToTokenIdToAuctionId[nftContract][tokenId] = auctionId;
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        auction.nftContract = nftContract;
        auction.tokenId = tokenId;
        auction.startTime = startTime != 0 ? startTime : block.timestamp;
        auction.seller = payable(msg.sender);
        auction.amount = reservePrice;
        auction.allowlistMerkleRoot = allowlistMerkleRoot;

        emit ReserveAuctionCreated(
            msg.sender,
            nftContract,
            tokenId,
            auction.startTime,
            DURATION,
            EXTENSION_DURATION,
            reservePrice,
            allowlistMerkleRoot,
            auctionId
        );
    }

    /**
     * @notice Once the countdown has expired for an auction, anyone can settle the auction.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param auctionId The id of the auction to settle.
     */
    function finalizeReserveAuction(uint256 auctionId) external nonReentrant {
        require(
            auctionIdToAuction[auctionId].endTime != 0,
            "cannot finalize already settled auction"
        );
        _finalizeReserveAuction({auctionId: auctionId, keepInEscrow: false});
    }

    /**
     * @notice Place a bid in an auction.
     * A bidder may place a bid which is at least the amount defined by `getMinBidAmount`.
     * If this is the first bid on the auction, the countdown will begin.
     * If there is already an outstanding bid, the previous bidder will be refunded at this time
     * and if the bid is placed in the final moments of the auction, the countdown may be extended.
     * @dev `amount` - `msg.value` is withdrawn from the bidder's FETH balance.
     * @param auctionId The id of the auction to bid on.
     */
    /* solhint-disable-next-line code-complexity */
    function placeBid(uint256 auctionId, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        uint256 amount = msg.value;
        require(auction.amount != 0, "no such auction");

        uint256 startTime = auction.startTime;
        uint256 endTime = auction.endTime;

        require(startTime <= block.timestamp, "auction is not started");

        if (endTime == 0) {
            require(
                amount >= auction.amount,
                "cannot bid lower than reserve price"
            );

            // Be a genesis holder 1 duration past startTime
            if (startTime + DURATION < block.timestamp) {
                auction.publicBid = true;
            } else {
                require(
                    IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).balanceOf(msg.sender) >
                        0 ||
                        (proof.length > 0 &&
                            auction.allowlistMerkleRoot != 0 &&
                            _isInAllowList(
                                msg.sender,
                                auction.allowlistMerkleRoot,
                                proof
                            )),
                    "not allowed to bid"
                );
            }

            // Store the bid details.
            auction.amount = amount;
            auction.bidder = payable(msg.sender);

            // On the first bid, set the endTime to now + duration.
            unchecked {
                // Duration is always set to 24hrs so the below can't overflow.
                endTime = block.timestamp + DURATION;
            }
            auction.endTime = endTime;
        } else {
            require(endTime >= block.timestamp, "cannot bid on ended auction");
            require(
                auction.publicBid ||
                    IERC721Upgradeable(STREETLAB_GENESIS_ADDRESS).balanceOf(msg.sender) >
                    0 ||
                    (proof.length > 0 &&
                        auction.allowlistMerkleRoot != 0 &&
                        _isInAllowList(
                            msg.sender,
                            auction.allowlistMerkleRoot,
                            proof
                        )),
                "not allowed to bid"
            );
            require(
                auction.bidder != msg.sender,
                "cannot rebid over outstanding bid"
            );
            uint256 minIncrement = _getMinIncrement(auction.amount);
            require(amount >= minIncrement, "bid must be at least min amount");

            // Cache and update bidder state
            uint256 originalAmount = auction.amount;
            address payable originalBidder = auction.bidder;
            auction.amount = amount;
            auction.bidder = payable(msg.sender);

            unchecked {
                // When a bid outbids another, check to see if a time extension should apply.
                // We confirmed that the auction has not ended, so endTime is always >= the current timestamp.
                // Current time plus extension duration (always 15 mins) cannot overflow.
                uint256 endTimeWithExtension = block.timestamp +
                    EXTENSION_DURATION;
                if (endTime < endTimeWithExtension) {
                    endTime = endTimeWithExtension;
                    auction.endTime = endTime;
                }
            }

            // Refund the previous bidder
            AddressUpgradeable.sendValue(originalBidder, originalAmount);
        }

        emit ReserveAuctionBidPlaced(auctionId, msg.sender, amount, endTime);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param reservePrice The new reserve price for this auction.
     */
    function updateReservePrice(uint256 auctionId, uint256 reservePrice)
        external
        onlyValidAuctionConfig(reservePrice)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );
        require(auction.endTime == 0, "cannot update auction in progress");
        require(auction.amount != reservePrice, "price already set");

        // Update the current reserve price.
        auction.amount = reservePrice;

        emit ReserveAuctionPriceUpdated(auctionId, reservePrice);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param auctionId The id of the auction to change.
     * @param allowlistMerkleRoot Merkle tree root hash of addresses for allowlist
     */
    function updateAllowlist(uint256 auctionId, bytes32 allowlistMerkleRoot)
        external
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        require(
            auction.seller == msg.sender,
            "only auction owner can update it"
        );

        // Update the current reserve price.
        auction.allowlistMerkleRoot = allowlistMerkleRoot;

        emit ReserveAuctionAllowlistUpdated(auctionId, allowlistMerkleRoot);
    }

    /**
     * @notice If an auction has been created but has not yet received bids, the reservePrice may be
     * changed by the seller.
     * @param account address to verify
     * @param root merkle root to verify against
     * @param proof merkle proof to verify
     * @return true if in allowlist merkle root, false otherwise
     */
    function _isInAllowList(
        address account,
        bytes32 root,
        bytes32[] calldata proof
    ) internal pure returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(account));
        return MerkleProofUpgradeable.verify(proof, root, leaf);
    }

    /**
     * @notice Settle an auction that has already ended.
     * This will send the NFT to the highest bidder and distribute revenue for this sale.
     * @param keepInEscrow If true, the NFT will be kept in escrow to save gas by avoiding
     * redundant transfers if the NFT should remain in escrow, such as when the new owner
     * sets a buy price or lists it in a new auction.
     */
    function _finalizeReserveAuction(uint256 auctionId, bool keepInEscrow)
        private
    {
        ReserveAuction memory auction = auctionIdToAuction[auctionId];

        require(
            auction.endTime < block.timestamp,
            "cannot finalize auction in progress"
        );

        // Remove the auction.
        delete nftContractToTokenIdToAuctionId[auction.nftContract][
            auction.tokenId
        ];
        delete auctionIdToAuction[auctionId];

        if (!keepInEscrow) {
            // The seller was authorized when the auction was originally created
            _transferERC721(
                auction.nftContract,
                auction.tokenId,
                auction.bidder,
                address(0)
            );
        }

        // Distribute revenue for this sale.
        AddressUpgradeable.sendValue(auction.seller, auction.amount);

        emit ReserveAuctionFinalized(
            auctionId,
            auction.seller,
            auction.bidder,
            auction.amount
        );
    }

    /**
     * @dev If an auction is found:
     *  - If the auction is over, it will settle the auction and confirm the new seller won the auction.
     *  - If the auction has not received a bid, it will invalidate the auction.
     *  - If the auction is in progress, this will revert.
     */
    function _transferFromEscrow(
        address nftContract,
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        if (auctionId != 0) {
            ReserveAuction storage auction = auctionIdToAuction[auctionId];
            if (auction.endTime == 0) {
                // The auction has not received any bids yet so it may be invalided.

                require(
                    authorizeSeller == address(0) ||
                        auction.seller == authorizeSeller,
                    "not matching seller"
                );

                // Remove the auction.
                delete nftContractToTokenIdToAuctionId[nftContract][tokenId];
                delete auctionIdToAuction[auctionId];

                emit ReserveAuctionInvalidated(auctionId);
            } else {
                // If the auction has ended, the highest bidder will be the new owner
                // and if the auction is in progress, this will revert.

                // `authorizeSeller != address(0)` does not apply here since an unsettled auction must go
                // through this path to know who the authorized seller should be.
                require(
                    auction.bidder == authorizeSeller,
                    "not matching seller"
                );

                // Finalization will revert if the auction has not yet ended.
                _finalizeReserveAuction({
                    auctionId: auctionId,
                    keepInEscrow: true
                });
            }
            // The seller authorization has been confirmed.
            authorizeSeller = address(0);
        }

        _transferERC721(nftContract, tokenId, recipient, authorizeSeller);
    }

    /**
     * @dev Checks if there is an auction for this NFT before allowing the transfer to continue.
     */
    function _transferFromEscrowIfAvailable(
        address nftContract,
        uint256 tokenId,
        address recipient
    ) internal {
        if (nftContractToTokenIdToAuctionId[nftContract][tokenId] == 0) {
            // No auction was found
            IERC721Upgradeable(nftContract).transferFrom(
                address(this),
                recipient,
                tokenId
            );
        }
    }

    function _transferToEscrow(address nftContract, uint256 tokenId) internal {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        if (auctionId == 0) {
            // NFT is not in auction
            IERC721Upgradeable(nftContract).transferFrom(
                msg.sender,
                address(this),
                tokenId
            );
            return;
        }
        // Using storage saves gas since most of the data is not needed
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            // Reserve price set, confirm the seller is a match
            require(auction.seller == msg.sender, "not matching seller");
        } else {
            // Auction in progress, confirm the highest bidder is a match
            require(auction.bidder == msg.sender, "not matching seller");

            // Finalize auction but leave NFT in escrow, reverts if the auction has not ended
            _finalizeReserveAuction({auctionId: auctionId, keepInEscrow: true});
        }
    }

    /**
     * @notice Returns the minimum amount a bidder must spend to participate in an auction.
     * Bids must be greater than or equal to this value or they will revert.
     * @param auctionId The id of the auction to check.
     * @return minimum The minimum amount for a bid to be accepted.
     */
    function getMinBidAmount(uint256 auctionId)
        external
        view
        returns (uint256 minimum)
    {
        ReserveAuction storage auction = auctionIdToAuction[auctionId];
        if (auction.endTime == 0) {
            return auction.amount;
        }
        return _getMinIncrement(auction.amount);
    }

    /**
     * @notice Returns auction details for a given auctionId.
     * @param auctionId The id of the auction to lookup.
     */
    function getReserveAuctionFromId(uint256 auctionId)
        public
        view
        returns (ReserveAuction memory auction)
    {
        ReserveAuction storage auctionStorage = auctionIdToAuction[auctionId];
        auction = ReserveAuction(
            auctionStorage.nftContract,
            auctionStorage.tokenId,
            auctionStorage.seller,
            auctionStorage.startTime,
            auctionStorage.endTime,
            auctionStorage.bidder,
            auctionStorage.amount,
            auctionStorage.allowlistMerkleRoot,
            auctionStorage.publicBid
        );
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     * @return auctionId The id of the auction, or 0 if no auction is found.
     */
    function getReserveAuctionIdFor(address nftContract, uint256 tokenId)
        public
        view
        returns (uint256 auctionId)
    {
        auctionId = nftContractToTokenIdToAuctionId[nftContract][tokenId];
    }

    /**
     * @notice Returns the auctionId for a given NFT, or 0 if no auction is found.
     * @dev If an auction is canceled, it will not be returned. However the auction may be over and pending finalization.
     * @param nftContract The address of the NFT contract.
     * @param tokenId The id of the NFT.
     */
    function getReserveAuction(address nftContract, uint256 tokenId)
        external
        view
        returns (ReserveAuction memory auction)
    {
        return
            getReserveAuctionFromId(
                getReserveAuctionIdFor(nftContract, tokenId)
            );
    }

    /**
     * @dev Returns the seller that has the given NFT in escrow for an auction,
     * or bubbles the call up for other considerations.
     */
    function _getSellerFor(address nftContract, uint256 tokenId)
        internal
        view
        returns (address payable seller)
    {
        seller = auctionIdToAuction[
            nftContractToTokenIdToAuctionId[nftContract][tokenId]
        ].seller;
        if (seller == address(0)) {
            seller = payable(IERC721Upgradeable(nftContract).ownerOf(tokenId));
        }
    }

    function _isInActiveAuction(address nftContract, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionId = nftContractToTokenIdToAuctionId[nftContract][
            tokenId
        ];
        return
            auctionId != 0 &&
            auctionIdToAuction[auctionId].endTime >= block.timestamp;
    }

    /**
     * @dev Determines the minimum amount when increasing an existing offer or bid.
     */
    function _getMinIncrement(uint256 currentAmount)
        internal
        view
        returns (uint256)
    {
        uint256 minIncrement = currentAmount;
        unchecked {
            minIncrement /= MIN_PERCENT_INCREMENT_DENOMINATOR;
        }
        if (minIncrement == 0) {
            // Since minIncrement reduces from the currentAmount, this cannot overflow.
            // The next amount must be at least 1 wei greater than the current.
            return currentAmount + 1;
        }

        return minIncrement + currentAmount;
    }

    function _transferERC721(
        address nftContract,
        uint256 tokenId,
        address recipient,
        address authorizeSeller
    ) internal {
        require(authorizeSeller == address(0), "seller not found");
        IERC721Upgradeable(nftContract).transferFrom(address(this), recipient, tokenId);
    }

    /**
     * @notice This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[1000] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProofUpgradeable {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
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
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
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
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
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
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
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