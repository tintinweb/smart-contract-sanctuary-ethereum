/**
 *Submitted for verification at Etherscan.io on 2023-05-25
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-24
 */

/**
 *Submitted for verification at BscScan.com on 2022-03-04
 */

// SPDX-License-Identifier: none
pragma solidity ^0.8.7;

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

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ERC20 {
    function totalSupply() external view returns (uint256 theTotalSupply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)
        external
        returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value)
        external
        returns (bool success);

    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
}

/// @title Auction contract for NFT marketplace
/// @notice This contract can be used for NFT which will accept ETH as payment
contract NFTAuction {
    // Auction has to be unique for each NFT
    struct Auction {
        uint256 bidPeriod; // Bid active time
        uint256 auctionEndPeriod;
        uint256 minPrice; // Minimum price to bid
        uint256 buyNowPrice; // Can be bought at any moment by providing this price
        uint256 nftHighestBid;
        bool pack;
        uint256[] tokenIds;
        address nftHighestBidder;
        address nftSeller;
    }

    // Rent struct
    struct Rent {
        address owner;
        uint256 rentPrice;
        uint256 rentEndTime;
        uint256 rentedAt;
        address tenant;
        uint256 ownerPercent;
        bool autoRent;
    }

    mapping(uint256 => Rent) public rents;
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    mapping(address => uint256) failedTransferCredits;

    // Count for bids and sales
    uint256 public nftOnSale;

    // Default value if not specified by the seller
    uint256 defaultBidPeriod; // To be set in constructor

    // EVENTS
    event NFTAuctionCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint256 bidPeriod
    );
    event SaleCreated(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 buyNowPrice
    );
    event BidMade(
        address nftContractAddress,
        uint256 tokenId,
        address bidder,
        uint256 ethAmount
    );
    event AuctionPeriodUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 auctionEndPeriod
    );
    event NFTTransferredAndSellerPaid(
        address nftContractAddress,
        uint256 tokenId,
        address nftSeller,
        uint256 highestBid,
        address highestBidder
    );
    event AuctionSettled(
        address nftContractAddress,
        uint256 tokenId,
        address auctionSettler
    );
    event AuctionWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address nftOwner
    );
    event BidWithdrawn(
        address nftContractAddress,
        uint256 tokenId,
        address highestBidder
    );
    event MinPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newMinPrice
    );
    event BuyNowPriceUpdated(
        address nftContractAddress,
        uint256 tokenId,
        uint256 newBuyNowPrice
    );
    event HighestBidTaken(address nftContractAddress, uint256 tokenId);
    event Rented(address rentAddress, uint256 tokenId);

    // Constructor
    constructor() {
        defaultBidPeriod = 180;
        //  2630000; //1 month
    }

    /**
        MODIFIERS
     */
    modifier isAuctionNotStartedByOwner(
        address nftContractAddress,
        uint256 tokenId
    ) {
        require(
            nftContractAuctions[nftContractAddress][tokenId].nftSeller !=
                msg.sender,
            "Auction already started by owner"
        );
        if (
            nftContractAuctions[nftContractAddress][tokenId].nftSeller !=
            address(0)
        ) {
            require(
                msg.sender == IERC721(nftContractAddress).ownerOf(tokenId),
                "Seller does not own NFT"
            );
        }
        _;
    }

    modifier auctionOngoing(address nftContractAddress, uint256 tokenId) {
        require(
            isAuctionOngoing(nftContractAddress, tokenId),
            "Auction has ended !"
        );
        _;
    }

    modifier priceGreaterThanZero(uint256 price) {
        require(price > 0, "Price should to be greater than Zero.");
        _;
    }

    // Minimum price should be 80% of the buy price
    modifier minPriceDoesNotExceedLimit(uint256 buyNowPrice, uint256 minPrice) {
        require(
            buyNowPrice == 0 || getPortionOfBid(buyNowPrice, 80) >= minPrice,
            "MinPrice > 80% of BuyNowPrice"
        );
        _;
    }

    modifier notNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender != nftContractAuctions[nftContractAddress][tokenId].nftSeller,
            "Owner cannot buy their own NFT"
        );
        _;
    }

    modifier onlyNftSeller(address nftContractAddress, uint256 tokenId) {
        require(
            msg.sender == nftContractAuctions[nftContractAddress][tokenId].nftSeller,
            "Only NFT seller"
        );
        _;
    }

    modifier bidAmountMeetsRequirement(address nftContractAddress,uint256 tokenId,uint256 amount) 
    {
        require(doesBidMeetsRequirement(nftContractAddress, tokenId, amount),
            "Not enough funds to bid"
        );
        _;
    }

    modifier minimumBidNotMade(address nftContractAddress, uint256 tokenId) {
        require(!isMinimumBidMade(nftContractAddress, tokenId),"Auction has a valid bid"
        );
        _;
    }

    modifier isAuctionOver(address nftContractAddress, uint256 tokenId) {
        require(!isAuctionOngoing(nftContractAddress, tokenId),"Auction is not over yet"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify zero address");
        _;
    }

    /**
        MODIFIERS END
     */

    // Auction Check Function
    function isAuctionOngoing(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 auctionEndTimestamp = nftContractAuctions[nftContractAddress][tokenId].bidPeriod;
        return (auctionEndTimestamp == 0 ||block.timestamp < auctionEndTimestamp);
    }

    // Check if a bid is made
    function isBidMade(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        return (nftContractAuctions[nftContractAddress][tokenId].nftHighestBid >0);
    }

    // If minPrice is set by seller, check that the highest bid meets or exceeds that price
    function isMinimumBidMade(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 minPrice = nftContractAuctions[nftContractAddress][tokenId].minPrice;
        return
            minPrice > 0 && (nftContractAuctions[nftContractAddress][tokenId].nftHighestBid > minPrice);
    }

    // If buyNowPrice is set by seller, check if highest bid meets that price
    function isBuyNowPriceMet(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (bool)
    {
        uint256 buyNowPrice = nftContractAuctions[nftContractAddress][tokenId].buyNowPrice;
        return
        buyNowPrice > 0 && (nftContractAuctions[nftContractAddress][tokenId].nftHighestBid >= buyNowPrice);
    }

    // Get the percentage of the total bid for fees calculation
    function getPortionOfBid(uint256 totalBid, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        return (totalBid * percentage) / 100;
    }

    /**
     * Check that a bid is applicable for the purchase of NFT
     * If sale is made, bid needs to meet buyNowPrice
     *
     */
    function doesBidMeetsRequirement(address nftContractAddress,uint256 tokenId,uint256 amount) internal view returns (bool) {
        uint256 prevHighestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
        return amount > prevHighestBid;
    }

    // Get auction bid period of NFT
    function getAuctionBidPeriod(address nftContractAddress, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        uint256 auctionBidPeriod = nftContractAuctions[nftContractAddress][tokenId].bidPeriod;
        if (auctionBidPeriod == 0) {
            return defaultBidPeriod;
        } else {
            return auctionBidPeriod;
        }
    }

    /**
        RENT
    **/

    // User puts their nft on rent.
    // Inserts price and rentEndTime for the user who rents
    function putOnRent(
        uint256 _time,                      //rent end time in unix timestamp
        uint256 _price,
        uint256 _ownerPercent,          
        bool _autoRent,
        uint256 tokenId,
        address nftContractAddress
    ) external {
        require(_ownerPercent < 100, "Owner cannot take full share");
        rents[tokenId].owner = msg.sender;
        rents[tokenId].rentPrice = _price;
        rents[tokenId].rentEndTime = _time;  
        rents[tokenId].ownerPercent = _ownerPercent;
        rents[tokenId].autoRent = _autoRent;

        IERC721(nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    // User who put their nfts on rent can remove it from the list
    function removeFromRent(uint256 _tokenId, address nftContractAddress)external{
        require(rents[_tokenId].owner == msg.sender, "You are not the owner");
        require(rents[_tokenId].rentEndTime + rents[_tokenId].rentedAt < block.timestamp,
            "Already on rent by someone"
        );
        rents[_tokenId].owner = address(0);
        rents[_tokenId].rentPrice = 0;
        rents[_tokenId].rentEndTime = 0;
        rents[_tokenId].tenant = address(0);
        rents[_tokenId].ownerPercent = 0;
        rents[_tokenId].autoRent = false;

        IERC721(nftContractAddress).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
    }

    // Another user can rent the nfts which are available to rent
    function rent(uint256 _tokenId, address nftContractAddress)external payable
    {
        uint256 rentAmount = rents[_tokenId].rentPrice;
        require(rents[_tokenId].owner != address(0), "Nft not on rent");
        require(rents[_tokenId].owner != msg.sender, "Owner cannot rent NFT");
        if (rents[_tokenId].autoRent == false) {
            require(rents[_tokenId].rentedAt == 0, "Nft needs to be claimed");
            require(msg.value >= rentAmount, "Price higher than amount sent");
            rents[_tokenId].tenant = msg.sender;
            rents[_tokenId].rentedAt = block.timestamp;
            address owner = rents[_tokenId].owner;

            // Send bnb to owner of nft
            payable(owner).transfer(msg.value);
        } else {
            require(msg.value >= rentAmount, "Price higher than amount sent");
            require(
                rents[_tokenId].rentEndTime + rents[_tokenId].rentedAt <
                    block.timestamp,
                "Already on rent"
            );
            rents[_tokenId].tenant = msg.sender;
            rents[_tokenId].rentedAt = block.timestamp;
            address owner = rents[_tokenId].owner;

            // Send bnb to owner of nft
            payable(owner).transfer(msg.value);
        }
    }

    /**
     RENT END
    **/

    /**
        AUCTIONS
     */
    // Transfer NFT to Auction Contract
    function transferNftToAuctionContract(address nftContractAddress,uint256 tokenId) internal {
        address nftSeller = nftContractAuctions[nftContractAddress][tokenId]
            .nftSeller;

        if (IERC721(nftContractAddress).ownerOf(tokenId) == nftSeller) {
            IERC721(nftContractAddress).transferFrom(
                nftSeller,
                address(this),
                tokenId
            );
            require(
                IERC721(nftContractAddress).ownerOf(tokenId) == address(this),
                "NFT Transfer Failed"
            );
        } else {
            require(
                IERC721(nftContractAddress).ownerOf(tokenId) == address(this),
                "Seller doesn't own NFT"
            );
        }
    }

    // Setting up auction
    function setupAuction(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _minPrice,
        uint256 _buyNowPrice
    ) internal minPriceDoesNotExceedLimit(_buyNowPrice, _minPrice) {
        Auction storage auctions = nftContractAuctions[nftContractAddress][tokenId];
        auctions.minPrice = _minPrice;
        auctions.buyNowPrice = _buyNowPrice;
        auctions.nftSeller = msg.sender;
        transferNftToAuctionContract(nftContractAddress, tokenId);
    }

    // Setting up new auction for NFT
    function setupNewNftAuction(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _minPrice,
        uint256 _buyNowPrice
    ) internal {
        setupAuction(nftContractAddress, tokenId, _minPrice, _buyNowPrice);
        emit NFTAuctionCreated(
            nftContractAddress,
            tokenId,
            msg.sender,
            _minPrice,
            _buyNowPrice,
            getAuctionBidPeriod(nftContractAddress, tokenId)
        );
    }

    // Create default auction using default bid period time
    function createDefaultAuction(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _minPrice,
        uint256 _buyNowPrice
    )
        external
        isAuctionNotStartedByOwner(nftContractAddress, tokenId)
        priceGreaterThanZero(_minPrice)
    {
        setupNewNftAuction(
            nftContractAddress,
            tokenId,
            _minPrice,
            _buyNowPrice
        );

        // increment total sale number
        nftOnSale++;
    }

    function createNewNftAuction(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _minPrice,
        uint256 _buyNowPrice,
        uint256 bidPeriod
    )
        external
        isAuctionNotStartedByOwner(nftContractAddress, tokenId)
        priceGreaterThanZero(_minPrice)
    {
        Auction storage auctions = nftContractAuctions[nftContractAddress][
            tokenId
        ];

        auctions.bidPeriod = bidPeriod;
        setupNewNftAuction(
            nftContractAddress,
            tokenId,
            _minPrice,
            _buyNowPrice
        );

        // increment total sale number
        nftOnSale++;
    }

    /**
        AUCTIONS END
    */

    /**
        SALES
    */
    function setupSale(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _buyNowPrice
    ) internal {
        Auction storage auctions = nftContractAuctions[nftContractAddress][tokenId];
        auctions.buyNowPrice = _buyNowPrice;
        auctions.nftSeller = msg.sender;

        IERC721(nftContractAddress).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    function createSale(
        address nftContractAddress,
        uint256 tokenId,
        uint256 _buyNowPrice
    )
        external
        isAuctionNotStartedByOwner(nftContractAddress, tokenId)   
        priceGreaterThanZero(_buyNowPrice)
    {
        setupSale(nftContractAddress, tokenId, _buyNowPrice);
        emit SaleCreated(nftContractAddress, tokenId, msg.sender, _buyNowPrice); 

        // increment total sale number
        nftOnSale++;
    }

    function createSaleForPack(
        address nftContractAddress,
        uint256[] memory _tokenIds,
        uint256 _buyNowPrice
    ) external priceGreaterThanZero(_buyNowPrice) {
        require(_tokenIds.length <= 4, "Less or equal to 4");
        uint256 len = _tokenIds.length;
        for (uint256 i = 0; i < len; i++) {   ////
            Auction storage auctions = nftContractAuctions[nftContractAddress][
                _tokenIds[i]
            ];
            for (uint256 j = 0; j < len; j++) {
                auctions.tokenIds.push(_tokenIds[j]);
            }
            auctions.pack = true;
            auctions.buyNowPrice = _buyNowPrice;
            auctions.nftSeller = msg.sender;
            IERC721(nftContractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenIds[i]
            );
        }
    }

    function removePack(address nftContractAddress, uint256[] memory _tokenIds)
        external
        returns (bool)
    {
        uint256 len = _tokenIds.length;
        require(len <= 4, "Less or equal to 4");
        address seller = nftContractAuctions[nftContractAddress][_tokenIds[0]].nftSeller;
        require(msg.sender == seller, "Only seller can remove");
        for (uint256 i = 0; i < len; i++) {
            Auction storage auctions = nftContractAuctions[nftContractAddress][ _tokenIds[i] ];
            for (uint256 j = 0; j < len; j++) {
                delete auctions.tokenIds[j];
            }
            auctions.pack = false;
            auctions.buyNowPrice = 0;
            auctions.nftSeller = address(0);
            IERC721(nftContractAddress).transferFrom(address(this),msg.sender,_tokenIds[i]);
        }
        return true;
    }

    function buyPack(address nftContractAddress, uint256[] memory _tokenIds)external payable returns (bool)
    {
        uint256 len = _tokenIds.length;
        require(len <= 4, "Less or equal to 4");
        address seller = nftContractAuctions[nftContractAddress][_tokenIds[0]].nftSeller;
        for (uint256 i = 0; i < len; i++) {
            Auction storage auctions = nftContractAuctions[nftContractAddress][_tokenIds[i] ];
            require(msg.value >= auctions.buyNowPrice, "Amount send is less than the pack price");
            for (uint256 j = 0; j < len; j++) {
                delete auctions.tokenIds[j];
            }
            auctions.pack = false;
            auctions.buyNowPrice = 0;
            auctions.nftSeller = address(0);
            IERC721(nftContractAddress).transferFrom(address(this),msg.sender,_tokenIds[i]);
        }
        // Sending funds to recipient
        bool sent = payable(seller).send(msg.value);
        // In case of failure
        if (!sent) {
            failedTransferCredits[seller] += msg.value;
        }
        return true;
    }

    function tokensInPack(address nftContractAddress, uint256 tokenId)external view returns (uint256[] memory ids)
    {
        return nftContractAuctions[nftContractAddress][tokenId].tokenIds;
    }

    function buyNow(address nftContractAddress, uint256 tokenId)external payable notNftSeller(nftContractAddress, tokenId) returns (bool)
    {
        Auction storage auctions = nftContractAuctions[nftContractAddress][tokenId];
        uint256 buyNowPrice = auctions.buyNowPrice;
        address seller = auctions.nftSeller;
        auctions.nftHighestBidder = msg.sender;
        // Check that it is on sale
        require(buyNowPrice != 0, "Cannot send 0 price");
        require(msg.value >= buyNowPrice, "Price not met for instant sale");    // unable to buy even paying more then asked amount #updated
        // Reset buyNowPrice
        auctions.buyNowPrice = 0;
        IERC721(nftContractAddress).transferFrom(address(this),msg.sender,tokenId);
        // Sending funds to recipient
        bool sent = payable(seller).send(msg.value);
        // In case of failure
        if (!sent) {
            failedTransferCredits[seller] += msg.value;
        }
        // decrease total sale number
        nftOnSale--;
        return true;
    }

    /**
        SALES END
     */

    /**
        BID FUNCTIONS
     */
    function _makeBid(address nftContractAddress, uint256 tokenId) internal notNftSeller(nftContractAddress, tokenId)
                                                  bidAmountMeetsRequirement(nftContractAddress, tokenId, msg.value)
    {
        reversePreviousBidAndUpdateHighestBid(nftContractAddress, tokenId);
        emit BidMade(nftContractAddress, tokenId, msg.sender, msg.value);

        updateOngoingAuction(nftContractAddress, tokenId);
    }

    function makeBid(address nftContractAddress, uint256 tokenId)
        external
        payable
        auctionOngoing(nftContractAddress, tokenId)
    {
        _makeBid(nftContractAddress, tokenId);
    }

    /**
        BID FUNCTIONS END
     */

    /**
        UPDATE AUCTION
     */
    function updateOngoingAuction(address nftContractAddress, uint256 tokenId)
        internal
    {
        if (isBuyNowPriceMet(nftContractAddress, tokenId)) {
            // transferNftToAuctionContract(nftContractAddress, tokenId);
            transferNftAndPaySeller(nftContractAddress, tokenId);
        }

        // minPrice not set
        // if( isMinimumBidMade(nftContractAddress, tokenId)){
        //     transferNftToAuctionContract(nftContractAddress, tokenId);
        //     updateAuctionEnd(nftContractAddress, tokenId);
        // }
    }

    function updateAuctionEnd(address nftContractAddress, uint256 tokenId) internal
    {
        // auction end should be now + bidEndPeriod
        uint256 auctionEndPeriod = nftContractAuctions[nftContractAddress][tokenId].auctionEndPeriod;
        auctionEndPeriod = getAuctionBidPeriod(nftContractAddress, tokenId) + block.timestamp;
        emit AuctionPeriodUpdated(nftContractAddress,tokenId,auctionEndPeriod);
    }

    /**
        UPDATE AUCTION END
     */

    /**
        RESET FUNCTIONS
     */
    // Reset all auction related parameters for an NFT
    // This removes an NFT as an item up for sale
    function resetAuction(address nftContractAddress, uint256 tokenId)internal{
        Auction storage auctions = nftContractAuctions[nftContractAddress][tokenId];
        auctions.auctionEndPeriod = 0;
        auctions.bidPeriod = 0;
        auctions.buyNowPrice = 0;
        auctions.minPrice = 0;
        auctions.nftHighestBid = 0;
        auctions.nftHighestBidder = address(0);
        auctions.nftSeller = address(0);
    }

    // This removes an NFT as having no active bids
    function resetBids(address nftContractAddress, uint256 tokenId) internal {
        Auction storage auctions = nftContractAuctions[nftContractAddress][
            tokenId
        ];
        auctions.nftHighestBidder = address(0);
        auctions.nftHighestBid = 0;
    }

    /**
        RESET FUNCTIONS END
     */

    /**
        UPDATE BIDS
     */
    // Functions to reverse bids and update bid parameters
    // Ensures that contract only holds the highest bids
    function updateHighestBid(address nftContractAddress, uint256 tokenId)internal
    {
        nftContractAuctions[nftContractAddress][tokenId].nftHighestBid = msg.value;
        nftContractAuctions[nftContractAddress][tokenId].nftHighestBidder = msg.sender;
    }

    function reverseAndResetPreviousBid(address nftContractAddress,uint256 tokenId) internal
     {
        address nftHighestBidder = nftContractAuctions[nftContractAddress][tokenId].nftHighestBidder;
        uint256 nftHighestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
        resetBids(nftContractAddress, tokenId);
        payout(nftHighestBidder, nftHighestBid);
    }

    function reversePreviousBidAndUpdateHighestBid(address nftContractAddress,uint256 _tokenId) internal {
        address prevNftHighestBidder = nftContractAuctions[nftContractAddress][_tokenId].nftHighestBidder;
        uint256 prevNftHighestBid = nftContractAuctions[nftContractAddress][_tokenId].nftHighestBid;
        updateHighestBid(nftContractAddress, _tokenId);
        if (prevNftHighestBidder != address(0)) {
            payout(prevNftHighestBidder, prevNftHighestBid);
        }
    }

    /**
        UPDATE BIDS
     */

    /** 
        TRANSFER NFT AND PAY SELLER
     */
    function transferNftAndPaySeller(address nftContractAddress,uint256 tokenId) internal {
        Auction storage auctions = nftContractAuctions[nftContractAddress][tokenId];
        address _nftSeller = auctions.nftSeller;
        address _highestBidder = auctions.nftHighestBidder;
        uint256 _highestBid = auctions.nftHighestBid;
        payFeesAndSeller(nftContractAddress, tokenId, _nftSeller, _highestBid);
        resetBids(nftContractAddress, tokenId);
        IERC721(nftContractAddress).transferFrom(address(this),_highestBidder, tokenId);
        resetAuction(nftContractAddress, tokenId);
        emit NFTTransferredAndSellerPaid(nftContractAddress,tokenId,_nftSeller,_highestBid,_highestBidder);
    }

    // Pay fees, seller
    function payFeesAndSeller(address nftContractAddress,uint256 tokenId,address _nftSeller,uint256 _highestBid) internal {
        // Pay seller
        payout(_nftSeller, _highestBid);
    }

    function payout(address recipient, uint256 amount) internal {
        // Sending funds to recipient
        bool sent = payable(recipient).send(amount);

        // In case of failure
        if (!sent) {
            failedTransferCredits[recipient] += amount;
        }
    }

    /** 
        TRANSFER NFT AND PAY SELLER END
     */

    /**
        SETTLE AND WITHDRAW
     */
    function settleAuction(address nftContractAddress, uint256 tokenId)external isAuctionOver(nftContractAddress, tokenId)
    {
        if (isMinimumBidMade(nftContractAddress, tokenId)) {
            transferNftAndPaySeller(nftContractAddress, tokenId);
        } else {
            IERC721(nftContractAddress).transferFrom(address(this), msg.sender, tokenId);
        }
        emit AuctionSettled(nftContractAddress, tokenId, msg.sender);
        // decrement total sale number
        nftOnSale--;
    }

    function withdrawAuction(address nftContractAddress, uint256 tokenId)external onlyNftSeller(nftContractAddress, tokenId)
    {
        address seller = nftContractAuctions[nftContractAddress][tokenId].nftSeller;
        IERC721(nftContractAddress).transferFrom(address(this), seller, tokenId);
        resetAuction(nftContractAddress, tokenId);
        emit AuctionWithdrawn(nftContractAddress, tokenId, msg.sender);
        // decrement total sale number
        nftOnSale--;
    }

    function withdrawBid(address nftContractAddress, uint256 tokenId) external {
        address nftHighestBidder = nftContractAuctions[nftContractAddress][tokenId].nftHighestBidder;
        require(nftHighestBidder == msg.sender, "Cannot withdraw");
        uint256 highestBid = nftContractAuctions[nftContractAddress][tokenId].nftHighestBid;
        resetBids(nftContractAddress, tokenId);
        payout(nftHighestBidder, highestBid);
        emit BidWithdrawn(nftContractAddress, tokenId, nftHighestBidder);
    }

    /**
        SETTLE AND WITHDRAW END
     */

    /**
        UPDATE AUCTION
     */
    function updateMinimumPrice(address nftContractAddress, uint256 tokenId, uint256 newMinPrice) external
        onlyNftSeller(nftContractAddress, tokenId)
        minimumBidNotMade(nftContractAddress, tokenId)
        priceGreaterThanZero(newMinPrice)
        minPriceDoesNotExceedLimit(nftContractAuctions[nftContractAddress][tokenId].buyNowPrice, newMinPrice)
    {
        nftContractAuctions[nftContractAddress][tokenId].minPrice = newMinPrice;
        emit MinPriceUpdated(nftContractAddress, tokenId, newMinPrice);
        if (isMinimumBidMade(nftContractAddress, tokenId)) {
            transferNftToAuctionContract(nftContractAddress, tokenId);
            updateAuctionEnd(nftContractAddress, tokenId);
        }
    }

    function updateBuyNowPrice(address nftContractAddress,uint256 tokenId, uint256 newBuyNowPrice)external
                                                            onlyNftSeller(nftContractAddress, tokenId)
                                                            priceGreaterThanZero(newBuyNowPrice)
                                                            minPriceDoesNotExceedLimit ( 
                                                                newBuyNowPrice,
                                                                nftContractAuctions[nftContractAddress][tokenId].minPrice
                                                            )
    {
        nftContractAuctions[nftContractAddress][tokenId].buyNowPrice = newBuyNowPrice;

        emit BuyNowPriceUpdated(nftContractAddress, tokenId, newBuyNowPrice);

        if (isBuyNowPriceMet(nftContractAddress, tokenId)) {
            transferNftToAuctionContract(nftContractAddress, tokenId);
            transferNftAndPaySeller(nftContractAddress, tokenId);
        }
    }

    // NFT seller can end the auction by accepting the current highest bid
    function takeHighestBid(address nftContractAddress, uint256 tokenId)external
        onlyNftSeller(nftContractAddress, tokenId)
    {
        require(isBidMade(nftContractAddress, tokenId), "Cannot payout 0 bid");
        transferNftToAuctionContract(nftContractAddress, tokenId);
        transferNftAndPaySeller(nftContractAddress, tokenId);
        // decrement total sale number
        nftOnSale--;
        emit HighestBidTaken(nftContractAddress, tokenId);
    }

    // Query the owner of NFT deposited for auction
    function ownerOfNft(address nftContractAddress, uint256 tokenId)external view returns (address)
    {
        address nftSeller = nftContractAuctions[nftContractAddress][tokenId].nftSeller;
        require(nftSeller != address(0), "NFT not deposited");
        return nftSeller;
    }

    // This allows user to claim their bid amount, if the transfer of a bid has failed
    function withdrawFailedCredits() external {
        uint256 amount = failedTransferCredits[msg.sender];

        require(amount != 0, "No credits to withdraw");

        failedTransferCredits[msg.sender] = 0;

        bool successfulWithdraw = payable(msg.sender).send(amount);
        require(successfulWithdraw, "Withdraw failed");
    }
    /**
        UPDATE AUCTION END
     */
}