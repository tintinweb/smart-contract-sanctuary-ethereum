//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AuctionContract {
  struct Auction {
    bool inserted;
    address payable consignor;
    uint256 auctionEndTime;
    uint256 minimumPrice;
    address highestBidder;
    uint256 highestBid;
  }
  // Key of mapping is tokenId
  mapping(uint256 => Auction) public auctions;

  mapping(address => uint256) pendingRefunds;

  IERC721 public immutable nftContract;

  constructor(address nftContractAddress_) {
    nftContract = IERC721(nftContractAddress_);
  }

  event OpenAuctionSuccess(
    uint256 tokenId,
    address consignor, 
    uint256 biddingDuration, 
    uint256 minimunPrice);
  event BidSuccess(
    uint256 tokenId,
    address bidder, 
    uint256 price
  );
  event withdrawSuccess(
    address signer,
    uint price
  );
  event AuctionEndSuccess(
    uint256 tokenId, 
    address winner, 
    uint256 amount
  );

  function openAuction(
    uint256 tokenId,
    uint256 biddingDuration,
    uint256 minimumPrice
  ) external {
    require(nftContract.ownerOf(tokenId) == msg.sender, "Not onwer of NFT");
    require(!auctions[tokenId].inserted, "Auction already exsit");

    Auction storage newAution = auctions[tokenId];
    newAution.inserted = true;
    newAution.consignor = payable(msg.sender);
    newAution.auctionEndTime = block.timestamp + biddingDuration;
    newAution.minimumPrice = minimumPrice;

    emit OpenAuctionSuccess(
      tokenId, 
      msg.sender,
      biddingDuration, 
      minimumPrice
    );
  }

  function bid(uint256 tokenId) external payable {
    Auction storage auction = auctions[tokenId];

    require(auction.inserted, "Auction not found");
    require(block.timestamp < auction.auctionEndTime, "Auction already ended");
    require(msg.value > auction.minimumPrice, "Bid not high enough");
    require(msg.value > auction.highestBid, "Bid not high enough");

    if (auction.highestBid != 0) {
      pendingRefunds[auction.highestBidder] += auction.highestBid;
    }

    auction.highestBidder = msg.sender;
    auction.highestBid = msg.value;

    emit BidSuccess(
      tokenId,
      msg.sender,
      msg.value
    );
  }

  function withdraw() external returns (bool) {
    uint256 amount = pendingRefunds[msg.sender];

    if (amount > 0) {
      pendingRefunds[msg.sender] = 0;

      if (!payable(msg.sender).send(amount)) {
        pendingRefunds[msg.sender] = amount;
        return false;
      }
    }

    emit withdrawSuccess(msg.sender, amount);

    return true;
  }

  function auctionEnd(uint256 tokenId) external {
    Auction storage auction = auctions[tokenId];

    require(auction.inserted, "Auction not found");
    require(block.timestamp > auction.auctionEndTime, "Auction not yet ended");

    address highestBidder = auction.highestBidder;
    uint256 highestBid = auction.highestBid;
    address payable consignor = auction.consignor;
    delete auctions[tokenId];

    // TODO: In case transfer NFT is fail?
    nftContract.safeTransferFrom(consignor, highestBidder, tokenId);
    consignor.transfer(highestBid);

    emit AuctionEndSuccess(tokenId, highestBidder, highestBid);
  }

  function get(uint256 tokenId)
    external
    view
    returns (
      bool inserted,
      address consignor,
      uint256 auctionEndTime,
      uint256 minimumPrice,
      uint256 highestBid,
      address highestBidder
    )
  {
    return (
      auctions[tokenId].inserted,
      auctions[tokenId].consignor,
      auctions[tokenId].auctionEndTime,
      auctions[tokenId].minimumPrice,
      auctions[tokenId].highestBid,
      auctions[tokenId].highestBidder
    );
  }

  function setAuctionOutDate(uint256 tokenId) external {
    auctions[tokenId].auctionEndTime = block.timestamp;
  }
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