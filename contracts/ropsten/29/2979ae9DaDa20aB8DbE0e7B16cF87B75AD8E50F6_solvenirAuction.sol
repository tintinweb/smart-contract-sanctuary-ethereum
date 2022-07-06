//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract solvenirAuction is ReentrancyGuard {

    address payable public owner;
    uint public listingFee;

    //NFT address => TokenId => struct
    mapping(address => mapping(uint256 => Auction)) public auctionForNFT;
    //NFT address => TokenId => Buyer Address => bidAmount
    mapping(address => mapping(uint256 => mapping(address => uint))) public bids;

    struct Auction {
        address payable seller;
        uint256 startingPrice;
        uint256 highestBid;
        address payable highestBidder;
        uint32 duration;
        uint32 startTime;
        uint32 timeBuffer;
        uint96 ticSize;
    }

    event AuctionCreated(address indexed nftContract, uint indexed tokenId, Auction auction);
    event AuctionBid(address indexed nftContract, uint256 indexed tokenId, bool extended, Auction auction);
    event AuctionCanceled(address indexed nftContract, uint256 indexed tokenId, Auction auction);
    event ClaimNFTOwner(address indexed nftContract, uint256 indexed tokenId, Auction auction);
    event SellerClaimedBid(address indexed nftContract, uint256 indexed tokenId, Auction auction, bool success);
    event BuyerClaimedNFT(address indexed nftContract, uint256 indexed tokenId, Auction auction);
    event EditBid(address indexed nftContract, uint256 indexed tokenId, bool extended, address caller);
    event BidAmountClaimed(address indexed nftContract, uint256 indexed tokenId, address caller, Auction auction, bool success);
    event ListingFee(uint NewListingFee);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // create auction for NFT, called by NFT owner or spender
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
        require(msg.sender == tokenOwner || IERC721(_nftContract).isApprovedForAll(tokenOwner, msg.sender), "ONLY_TOKEN_OWNER_OR_OPERATOR");
        require(_startingPrice > 0, "PRICE_TOO_LOW");

        auctionForNFT[_nftContract][_tokenId].seller = payable(msg.sender);
        auctionForNFT[_nftContract][_tokenId].startingPrice = _startingPrice;
        auctionForNFT[_nftContract][_tokenId].duration = _duration;
        auctionForNFT[_nftContract][_tokenId].startTime = _startTime;
        auctionForNFT[_nftContract][_tokenId].ticSize = _ticSize;
        auctionForNFT[_nftContract][_tokenId].timeBuffer = _timeBuffer;
        auctionForNFT[_nftContract][_tokenId].highestBid = _startingPrice;
        auctionForNFT[_nftContract][_tokenId].highestBidder = payable(msg.sender);

        IERC721(_nftContract).safeTransferFrom(msg.sender, address(this), _tokenId);
    
        emit AuctionCreated(_nftContract, _tokenId, auctionForNFT[_nftContract][_tokenId]);
    }

    //place bid function called by buyer
    function placeBid(
        address _nftContract,
        uint256 _tokenId
    ) external payable nonReentrant {
        
        uint bidAmount = msg.value;
        Auction storage auction = auctionForNFT[_nftContract][_tokenId];

        uint _highestBid = auction.highestBid;
        uint _ticSize = auction.ticSize;
        uint _startTime = auction.startTime;
        uint _duration = auction.duration;
        uint _timeBuffer = auction.timeBuffer;
        address _seller = auction.seller;

        require(bidAmount >= _highestBid + _ticSize, "MINIMUM_PRICE_NOT_MET"); 
        require(_seller != address(0), "AUCTION_DOES_NOT_EXIST");
        require(block.timestamp <= _startTime + _duration, "AUCTION_ENDED");
        
        bids[_nftContract][_tokenId][msg.sender] = msg.value;
        auction.highestBid = bidAmount;
        auction.highestBidder = payable(msg.sender);

        bool extended;
        uint timeRemaining;
        unchecked {
            timeRemaining = _startTime + _duration - block.timestamp;
        }
        if(timeRemaining <= _timeBuffer) {
            unchecked {
                auction.duration += uint32(_timeBuffer - timeRemaining);
            }
            extended = true;
        }

        emit AuctionBid(_nftContract, _tokenId, extended, auction);
    }

    //Called by seller if no bids placed
    function cancelAuction(
        address _nftContract, 
        uint256 _tokenId
    ) external nonReentrant {
        
        Auction memory auction = auctionForNFT[_nftContract][_tokenId];
        require(auction.startingPrice == auction.highestBid, "AUCTION_STARTED");
        require(msg.sender == auction.seller || msg.sender == IERC721(_nftContract).ownerOf(_tokenId), "ONLY_SELLER_OR_TOKEN_OWNER");

        delete auctionForNFT[_nftContract][_tokenId];
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit AuctionCanceled(_nftContract, _tokenId, auction);
    }

    // NFT claimed by seller when no bids placed in the entire duration
    function claimNFTOwner(
        address _nftContract, 
        uint256 _tokenId
    ) external nonReentrant {

        Auction memory auction = auctionForNFT[_nftContract][_tokenId];
        require(block.timestamp >= (auction.startTime + auction.duration), "AUCTION_NOT_OVER");
        require(auction.seller == auction.highestBidder, "BIDS_EXISTS_ON_TOKEN");
        require(msg.sender == auction.seller || msg.sender == IERC721(_nftContract).ownerOf(_tokenId), "ONLY_SELLER_OR_TOKEN_OWNER");

        delete auctionForNFT[_nftContract][_tokenId];
        IERC721(_nftContract).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit ClaimNFTOwner(_nftContract, _tokenId, auction);
        
    }

    // Highest bid amount is transferred to the seller
    function claimBidSeller(
        address _nftContract, 
        uint256 _tokenId
    ) external nonReentrant {
        
        Auction storage auction = auctionForNFT[_nftContract][_tokenId];
        require(block.timestamp >= (auction.startTime + auction.duration), "AUCTION_NOT_OVER");
        require(msg.sender == auction.seller || msg.sender == IERC721(_nftContract).ownerOf(_tokenId), "ONLY_SELLER_OR_TOKEN_OWNER");
        
        uint fee = listingFee;
        uint valueWithoutFee;

        delete bids[_nftContract][_tokenId][auction.highestBidder];
        unchecked {
            valueWithoutFee = auction.highestBid - fee;
        }
        (bool success, ) = payable(msg.sender).call{value: valueWithoutFee}("");

        if(auction.highestBidder == address(0)) {
            delete auctionForNFT[_nftContract][_tokenId];
        } else {
            auction.seller == address(0);
        }

        emit SellerClaimedBid(_nftContract, _tokenId, auction, success);
        
    }

    // NFT transferred to the highest bidder after end of duration
    function claimNFTBidder(
        address _nftContract,
        uint256 _tokenId
    ) public nonReentrant {

        Auction storage auction = auctionForNFT[_nftContract][_tokenId];
        require(block.timestamp >= (auction.startTime + auction.duration), "AUCTION_NOT_OVER");
        require(msg.sender == auction.highestBidder, "ONLY_HIGHESTBIDDER");
        delete bids[_nftContract][_tokenId][msg.sender];

        IERC721(_nftContract).safeTransferFrom(address(this), auction.highestBidder, _tokenId);

        if(auction.seller == address(0)) {
            delete auctionForNFT[_nftContract][_tokenId];
        } else {
            auction.highestBidder = payable(address(0));
        }

        emit BuyerClaimedNFT(_nftContract, _tokenId, auction);
    }

    // user can edit bid to be the highest bidder
    function editBid(
        address _nftContract,
        uint256 _tokenId
    ) external payable nonReentrant {
        
        Auction storage auction = auctionForNFT[_nftContract][_tokenId];

        uint _highestBid = auction.highestBid;
        uint _ticSize = auction.ticSize;
        uint _startTime = auction.startTime;
        uint _duration = auction.duration;
        uint _timeBuffer = auction.timeBuffer;
        address _seller = auction.seller;

        require(block.timestamp <= _startTime + _duration, "AUCTION_ENDED");
        require(_seller != address(0), "AUCTION_DOES_NOT_EXIST");

        uint bidAmount = bids[_nftContract][_tokenId][msg.sender];
        uint minValidBid = _highestBid + _ticSize;
        uint currentAmount = msg.value;
        uint minBidIncrease;

        unchecked {
            minBidIncrease = minValidBid - bidAmount;
        }
        require(currentAmount >= minBidIncrease, "Amount should be greater than highest bid");

        auction.highestBid = bidAmount;
        auction.highestBidder = payable(msg.sender);
        bids[_nftContract][_tokenId][msg.sender] += currentAmount;

        bool extended;
        uint timeRemaining;
        unchecked {
            timeRemaining = _startTime + _duration - block.timestamp;
        }
        if(timeRemaining <= _timeBuffer) {
            unchecked {
                auction.duration += uint32(_timeBuffer - timeRemaining);
            }
            extended = true;
        }

        emit EditBid(_nftContract, _tokenId, extended, msg.sender);
    }

    // User can claim bid if not the highest bidder
    function claimBidAmount(
        address _nftContract,
        uint256 _tokenId
    ) external payable nonReentrant {

        Auction memory auction = auctionForNFT[_nftContract][_tokenId];
        uint bidAmount = bids[_nftContract][_tokenId][msg.sender];
        require(bidAmount > 0, "NO_ACTIVE_BIDS");
        require(msg.sender != auction.highestBidder, "Highest bidder cannot claim bid");

        delete bids[_nftContract][_tokenId][msg.sender];
        (bool success, ) = payable(msg.sender).call{value: auction.highestBid}("");

        emit BidAmountClaimed(_nftContract, _tokenId, msg.sender, auction, success);
    }

    // Listing fees updated by calling this function
    function updateFees(uint _listingFee) external onlyOwner {

        listingFee = _listingFee;
        emit ListingFee(_listingFee);
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