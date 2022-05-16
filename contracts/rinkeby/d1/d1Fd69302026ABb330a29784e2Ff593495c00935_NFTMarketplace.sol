//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./iNFT.sol"; 
import "./iNFTMarketplace.sol";

contract NFTMarketplace is iNFTMarketplace{


    enum Status {
        CREATED,
        LISTED,
        BOUGHT,
        CANCELLED
    }

    struct MarketItem {
      uint256 price;
      bool sold;
      Status status;
    }

    struct AuctionItem {
      uint256 endTimestamp;
      uint256 price;
      bool sold;
      uint256 minBid;
      uint256 maxBid;
      address lastBidder;
      Status status;
    }

    uint256 public auctionPeriodInSeconds = 3 * 24 * 60 * 60; //seconds


    iNFT nftAddress;
    mapping(uint256 => MarketItem) public itemsToSell;
    mapping(uint256 => AuctionItem) public itemsToSellFromAuction;
 
 
    constructor(iNFT _nftAddress) {
        nftAddress = _nftAddress;
    }

    function createItem() external override {
        nftAddress.safeMint(msg.sender);
    }

    function listItem(uint256 id, uint256 price) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        itemsToSell[id].price = price;
        itemsToSell[id].status = Status.LISTED;
    }

    function buyItem(uint256 id) external override payable {
        require(msg.value == itemsToSell[id].price);
        require(itemsToSell[id].price != 0);
        address owner = nftAddress.ownerOf(id);
        nftAddress.transferFrom(owner, msg.sender, id);
        payable(owner).transfer(msg.value);
        itemsToSell[id].status = Status.BOUGHT;
    }

    function cancel(uint256 id) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        require(itemsToSell[id].sold == false);
        itemsToSell[id].status = Status.CANCELLED;
    }


    function listItemOnAuction(uint256 id, uint256 minBid) external override {
        require(msg.sender == nftAddress.ownerOf(id));
        itemsToSellFromAuction[id].minBid = minBid;
        itemsToSellFromAuction[id].status = Status.LISTED;
        itemsToSellFromAuction[id].endTimestamp = block.timestamp + auctionPeriodInSeconds;
    }

    function makeBid(uint256 id) external override payable {
        require(msg.value > itemsToSellFromAuction[id].maxBid);
        require(msg.value > itemsToSellFromAuction[id].minBid);
        require(itemsToSellFromAuction[id].status == Status.LISTED);
        if (itemsToSellFromAuction[id].lastBidder != address(0)) {
            payable(itemsToSellFromAuction[id].lastBidder).transfer(itemsToSellFromAuction[id].maxBid);
        }   
        itemsToSellFromAuction[id].maxBid = msg.value;
        itemsToSellFromAuction[id].lastBidder = msg.sender;
    }

    function finishAuction(uint256 id) external override {
        require(itemsToSellFromAuction[id].endTimestamp <= block.timestamp);
        require(itemsToSellFromAuction[id].lastBidder != address(0));
        nftAddress.transferFrom(nftAddress.ownerOf(id), itemsToSellFromAuction[id].lastBidder, id);
        itemsToSellFromAuction[id].status = Status.BOUGHT;
    }

    function cancelAuction(uint256 id) external override {
        require(itemsToSellFromAuction[id].endTimestamp <= block.timestamp);
        require(msg.sender == nftAddress.ownerOf(id));
        if (itemsToSellFromAuction[id].lastBidder != address(0)) {
            nftAddress.transferFrom(nftAddress.ownerOf(id), itemsToSellFromAuction[id].lastBidder, itemsToSellFromAuction[id].maxBid);
        }
        itemsToSellFromAuction[id].status = Status.CANCELLED;
    }
    

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface iNFT is IERC721 {
    function safeMint(address to) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

interface iNFTMarketplace {
    function createItem() external;
    function listItem(uint256 id, uint256 price) external;
    function buyItem(uint256 id) external payable;
    function cancel(uint256 id) external;
    function listItemOnAuction(uint256 id, uint256 minBid) external;
    function makeBid(uint256 id) external payable;
    function finishAuction(uint256 id) external;
    function cancelAuction(uint256 id) external;
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