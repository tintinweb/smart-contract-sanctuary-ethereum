//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";

import "./interfaces/IRoyaltyFeeManager.sol";
import "./interfaces/IRoyaltyFeeRegistry.sol";

contract Auction is ReentrancyGuard, ERC721Holder {

    address payable public owner;
    address private royaltyFeeManager;
    uint256 public listingFee;

    struct AuctionListing {
        // seller address of the NFT
        address payable seller;
        // Starting price set be seller for NFT
        uint256 startingPrice;
        // Current highest bid placed on NFT
        uint256 highestBid;
        // Address of the highest bidder
        address payable highestBidder;
        // time period for which auction will exist
        uint32 duration;
        // start time for the auction
        uint32 startTime;
        // Buffer time by which the auction will be extended
        uint32 timeBuffer;
        // minimum increase in the bid price 
        uint96 ticSize;
    }

    //NFT address => TokenId => struct
    mapping(address => mapping(uint256 => AuctionListing)) public auctionForNFT;
    //NFT address => TokenId => Buyer Address => bidAmount
    mapping(address => mapping(uint256 => mapping(address => uint256))) public bids;

    event AuctionCreated(
        address indexed nftContract,
        uint256 indexed tokenId,
        AuctionListing auction
    );
    event AuctionBid(
        address indexed nftContract,
        uint256 indexed tokenId,
        bool extended,
        AuctionListing auction
    );
    event AuctionCanceled(
        address indexed nftContract,
        uint256 indexed tokenId,
        AuctionListing auction
    );
    event ClaimNFTOwner(
        address indexed nftContract,
        uint256 indexed tokenId,
        AuctionListing auction
    );
    event SellerClaimedBid(
        address indexed nftContract,
        uint256 indexed tokenId,
        AuctionListing auction,
        bool success
    );
    event BuyerClaimedNFT(
        address indexed nftContract,
        uint256 indexed tokenId,
        AuctionListing auction
    );
    event EditBid(
        address indexed nftContract,
        uint256 indexed tokenId,
        bool extended,
        address caller
    );
    event BidAmountClaimed(
        address indexed nftContract,
        uint256 indexed tokenId,
        address caller,
        AuctionListing auction,
        bool success
    );
    event ListingFee(
        uint256 NewListingFee
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint256 _listingFee, 
    address _royaltyFeeManager) {
        listingFee = _listingFee;
        royaltyFeeManager = _royaltyFeeManager;
        owner = payable(msg.sender);
    }

    /**
    * @dev Creates new auction for NFT
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
    * @param _duration time period the auction should exist
    * @param _startingPrice starting price set for auction
    * @param _ticSize minimum amount which should be incremented from previous bid
    * @param _timeBuffer increase in the duration when bid is placed and the time remaining for auction to end is less than timeBuffer 
    * @param _startTime time at which the auction starts
     */
    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint32 _duration,
        uint256 _startingPrice,
        uint96 _ticSize,
        uint32 _timeBuffer,
        uint32 _startTime
    ) external nonReentrant {
        address tokenOwner = IERC721(_nftContract).ownerOf(_tokenId);
        require(
            msg.sender == tokenOwner ||
                IERC721(_nftContract).isApprovedForAll(tokenOwner, msg.sender),
            "ONLY_TOKEN_OWNER_OR_OPERATOR"
        );
        require(_ticSize > 0, "TICKSIZE_TOO_LOW");
        require(_startingPrice > 0, "PRICE_TOO_LOW");
        auctionForNFT[_nftContract][_tokenId].seller = payable(msg.sender);
        auctionForNFT[_nftContract][_tokenId].startingPrice = _startingPrice;
        auctionForNFT[_nftContract][_tokenId].duration = _duration;
        auctionForNFT[_nftContract][_tokenId].startTime = _startTime;
        auctionForNFT[_nftContract][_tokenId].ticSize = _ticSize;
        auctionForNFT[_nftContract][_tokenId].timeBuffer = _timeBuffer;
        auctionForNFT[_nftContract][_tokenId].highestBid = _startingPrice;
        auctionForNFT[_nftContract][_tokenId].highestBidder = payable(
            msg.sender
        );
        IERC721(_nftContract).safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId
        );

        emit AuctionCreated(
            _nftContract,
            _tokenId,
            auctionForNFT[_nftContract][_tokenId]
        );
    }

    /**
    * @dev Places Bid for active auction
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function placeBid(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
    {
        uint256 bidAmount = msg.value;
        AuctionListing storage auction = auctionForNFT[_nftContract][_tokenId];
        uint256 _highestBid = auction.highestBid;
        uint256 _ticSize = auction.ticSize;
        uint256 _startTime = auction.startTime;
        uint256 _duration = auction.duration;
        uint256 _timeBuffer = auction.timeBuffer;
        address _seller = auction.seller;
        require(bidAmount >= _highestBid + _ticSize, "MINIMUM_PRICE_NOT_MET");
        require(_seller != address(0), "AUCTION_DOES_NOT_EXIST");
        require(block.timestamp <= _startTime + _duration, "AUCTION_ENDED");

        bids[_nftContract][_tokenId][msg.sender] = msg.value;
        auction.highestBid = bidAmount;
        auction.highestBidder = payable(msg.sender);
        bool extended;
        uint256 timeRemaining;
        unchecked {
            timeRemaining = _startTime + _duration - block.timestamp;
        }
        if (timeRemaining <= _timeBuffer) {
            unchecked {
                auction.duration += uint32(_timeBuffer - timeRemaining);
            }
            extended = true;
        }
        emit AuctionBid(_nftContract, _tokenId, extended, auction);
    }

    /**
    * @dev able to cancel an auction if no bid placed
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function cancelAuction(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
    {
        AuctionListing memory auction = auctionForNFT[_nftContract][_tokenId];
        require(auction.startingPrice == auction.highestBid, "AUCTION_STARTED");
        require(
            msg.sender == auction.seller ||
                msg.sender == IERC721(_nftContract).ownerOf(_tokenId),
            "ONLY_SELLER_OR_TOKEN_OWNER"
        );
        delete auctionForNFT[_nftContract][_tokenId];
        IERC721(_nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        emit AuctionCanceled(_nftContract, _tokenId, auction);
    }

    /**
    * @dev NFT claimed by seller when no bids placed in the entire duration
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function retrieveNFT(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
    {
        AuctionListing memory auction = auctionForNFT[_nftContract][_tokenId];
        require(
            block.timestamp >= (auction.startTime + auction.duration),
            "AUCTION_NOT_OVER"
        );
        require(
            auction.seller == auction.highestBidder,
            "BIDS_EXISTS_ON_TOKEN"
        );
        require(
            msg.sender == auction.seller ||
                msg.sender == IERC721(_nftContract).ownerOf(_tokenId),
            "ONLY_SELLER_OR_TOKEN_OWNER"
        );
        delete auctionForNFT[_nftContract][_tokenId];
        IERC721(_nftContract).safeTransferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        emit ClaimNFTOwner(_nftContract, _tokenId, auction);
    }

    /**
    * @dev Highest bid amount is transferred to the seller
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function claimBid(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
    {
        AuctionListing storage auction = auctionForNFT[_nftContract][_tokenId];
        require(
            block.timestamp >= (auction.startTime + auction.duration),
            "AUCTION_NOT_OVER"
        );
        require(
            msg.sender == auction.seller,
            "ONLY_SELLER"
        );

        uint256 _highestBid = auction.highestBid;
        address _highestBidder = auction.highestBidder;

        uint256 finalSettlementAmount = _highestBid;

        // 1. Listing fee

        uint256 feePerListing = calculateListingFee(_highestBid);
        unchecked {
            finalSettlementAmount -= feePerListing;
        }

        // 2. Royalty Fee

        (address receiver , uint256 royaltyFeePerListing) = IRoyaltyFeeRegistry(royaltyFeeManager).royaltyInfo(_nftContract, _highestBid);

        if(receiver == address(0) || royaltyFeePerListing == 0) {
            (receiver, royaltyFeePerListing) = IRoyaltyFeeManager(royaltyFeeManager).calculateRoyaltyFeeAndGetRecipient(_nftContract, _tokenId, _highestBid);
        }

        if(receiver != address(0) && royaltyFeePerListing > 0) {
            
            _transfer(receiver, royaltyFeePerListing);

            unchecked {
                finalSettlementAmount -= royaltyFeePerListing;
            }
        }
        
        require(finalSettlementAmount > 0, "Fee greater that price");

        _transfer(auction.seller, finalSettlementAmount);

        delete bids[_nftContract][_tokenId][auction.highestBidder];
        
        if (_highestBidder == address(0)) {
            delete auctionForNFT[_nftContract][_tokenId];
        } else {
            auction.seller == address(0);
        }

        emit SellerClaimedBid(_nftContract, _tokenId, auction, true);
    }

    /**
    * @dev NFT transferred to the highest bidder after end of duration
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function claimNFT(address _nftContract, uint256 _tokenId)
        public
        nonReentrant
    {
        AuctionListing storage auction = auctionForNFT[_nftContract][_tokenId];
        require(
            block.timestamp >= (auction.startTime + auction.duration),
            "AUCTION_NOT_OVER"
        );
        require(msg.sender == auction.highestBidder, "ONLY_HIGHESTBIDDER");
        delete bids[_nftContract][_tokenId][msg.sender];
        IERC721(_nftContract).safeTransferFrom(
            address(this),
            auction.highestBidder,
            _tokenId
        );
        if (auction.seller == address(0)) {
            delete auctionForNFT[_nftContract][_tokenId];
        } else {
            auction.highestBidder = payable(address(0));
        }
        emit BuyerClaimedNFT(_nftContract, _tokenId, auction);
    }

    /**
    * @dev user can edit bid to be the highest bidder
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function editBid(address _nftContract, uint256 _tokenId)
        external
        payable
        nonReentrant
    {
        AuctionListing storage auction = auctionForNFT[_nftContract][_tokenId];
        uint256 _highestBid = auction.highestBid;
        uint256 _ticSize = auction.ticSize;
        uint256 _startTime = auction.startTime;
        uint256 _duration = auction.duration;
        uint256 _timeBuffer = auction.timeBuffer;
        address _seller = auction.seller;
        uint256 bidAmount = bids[_nftContract][_tokenId][msg.sender];

        require(block.timestamp <= _startTime + _duration, "AUCTION_ENDED");
        require(_seller != address(0), "AUCTION_DOES_NOT_EXIST");
        require(bidAmount > 0, "NO_PREVIOUS_BIDS_TO_EDIT");
        
        uint256 minValidBid = _highestBid + _ticSize;
        uint256 currentAmount = msg.value;
        uint256 minBidIncrease;
        unchecked {
            minBidIncrease = minValidBid - bidAmount;
        }
        require(
            currentAmount >= minBidIncrease,
            "Amount should be greater than highest bid"
        );
        auction.highestBid = bidAmount;
        auction.highestBidder = payable(msg.sender);
        bids[_nftContract][_tokenId][msg.sender] += currentAmount;
        bool extended;
        uint256 timeRemaining;
        unchecked {
            timeRemaining = _startTime + _duration - block.timestamp;
        }
        if (timeRemaining <= _timeBuffer) {
            unchecked {
                auction.duration += uint32(_timeBuffer - timeRemaining);
            }
            extended = true;
        }
        emit EditBid(_nftContract, _tokenId, extended, msg.sender);
    }

    /**
    * @dev User can claim bid if not the highest bidder
    * @param _nftContract address of the NFT contract
    * @param _tokenId tokenId of NFT
     */
    function retrieveBid(address _nftContract, uint256 _tokenId)
        external
        nonReentrant
    {
        AuctionListing memory auction = auctionForNFT[_nftContract][_tokenId];
        uint256 bidAmount = bids[_nftContract][_tokenId][msg.sender];
        require(bidAmount > 0, "NO_ACTIVE_BIDS");
        require(
            msg.sender != auction.highestBidder,
            "Highest bidder cannot claim bid"
        );
        delete bids[_nftContract][_tokenId][msg.sender];
        (bool success, ) = payable(msg.sender).call{value: bidAmount}(
            ""
        );
        emit BidAmountClaimed(
            _nftContract,
            _tokenId,
            msg.sender,
            auction,
            success
        );
    }

    /*
		Internal Functions
	*/

	function _transferFrom(address from, address to, address token, uint256 tokenId) internal {
		IERC721(token).transferFrom(from, to, tokenId);
	}

	function _transfer(address to, uint256 amount) internal {
        (bool success, ) = payable(to).call{value: amount}("");
        require(success, "TRANSFER_FAILED");
        
	}

    function calculateListingFee(uint256 amount) internal view returns (uint256) {
        return (amount * listingFee) / 10000;
    }

    function auctionTimeRemaining(address _nftContract, uint _tokenId) external view returns(uint) {
        AuctionListing memory auction = auctionForNFT[_nftContract][_tokenId];
        uint endTime = auction.startTime + auction.duration;
        uint timeRemaining;
        unchecked {
            timeRemaining = endTime - block.timestamp;
            require(block.timestamp <= endTime, "AUCTION_ENDED");
        }
        return timeRemaining;
    }

    /**
    * @dev Update NFT listing fees
    * @param _listingFeePercent fees in percentage to be updated
     */
    function updateListingFees(uint256 _listingFeePercent) external onlyOwner {
        listingFee = _listingFeePercent;
        emit ListingFee(_listingFeePercent);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        address collection,
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRoyaltyFeeRegistry{
    function updateRoyaltyInfoForCollection(
        address collection,
        address setter,
        address receiver,
        uint256 fee
    ) external;

    function updateRoyaltyFeeLimit(uint256 _royaltyFeeLimit) external;

    function royaltyInfo(address collection, uint256 amount) external view returns (address, uint256);

    function royaltyFeeInfoCollection(address collection)
        external
        view
        returns (
            address,
            address,
            uint256
        );
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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