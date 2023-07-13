// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { LibUtils } from "../libraries/LibUtils.sol";
import { LibERC721 } from "../libraries/LibERC721.sol";
import { LibIdentity } from "../libraries/LibIdentity.sol";
import { LibMarketplace, Listing, MarketplaceLayout, TokenListingData, TokenType, ListingCounters } from "../libraries/LibMarketplace.sol";
import { IERC721 } from "../interfaces/IERC721.sol";
import { IIdentity } from "../interfaces/IIdentity.sol";

contract MarketplaceFacet {
  modifier listingCompliance(
    TokenType tokenType,
    uint256 tokenId,
    uint256 price
  ) {
    require(tokenType <= TokenType.NFT, "MarketplaceFacet: Token type doesn't exist");

    if (tokenType == TokenType.NFT) {
      require(LibERC721.ownerOf(tokenId) == LibUtils.msgSender(), "MarketplaceFacet: Not owner of token");
      require(tokenId <= LibERC721.totalSupply(), "MarketplaceFacet: Token ID out of bounds");
    }
    // else if (tokenType == TokenType.Scroll) {
    //   require(LibIdentity.getOwner(tokenId) == LibUtils.msgSender(), "MarketplaceFacet: Not owner of scroll");
    //   require(tokenId <= LibIdentity.scrollSupply(), "MarketplaceFacet: Scroll ID out of bounds");
    // }

    require(price > 0, "MarketplaceFacet: Price not set");
    _;
  }

  function createListing(TokenType tokenType, uint256 tokenId, uint256 price) public listingCompliance(tokenType, tokenId, price) {
    MarketplaceLayout storage ls = LibMarketplace.getStorage();
    require(!ls.token[tokenType][tokenId].isListed, "MarketplaceFacet: Token is already listed");
    address sender = LibUtils.msgSender();
    uint256 time = block.timestamp;
    uint256 listingId = ls.listingCounts.totalListings;

    ls.listings[listingId] = Listing({
      id: listingId,
      seller: sender,
      sell_to: address(0),
      tokenId: tokenId,
      token_type: tokenType,
      price: price,
      sold_on: 0,
      sold_to: address(0),
      cancelled: false,
      created_on: time,
      modified_on: time
    });

    ls.token[tokenType][tokenId] = TokenListingData({ isListed: true, listingId: listingId });
    ls.userListings[sender].push(listingId);

    LibMarketplace.increaseCounters(ls.listingCounts, 1, 1);
    LibMarketplace.increaseCounters(ls.userCounts[sender], 1, 1);
  }

  function createPrivateListing(
    TokenType tokenType,
    uint256 tokenId,
    uint256 price,
    address sell_to
  ) public listingCompliance(tokenType, tokenId, price) {
    MarketplaceLayout storage ls = LibMarketplace.getStorage();
    require(!ls.token[tokenType][tokenId].isListed, "MarketplaceFacet: Token is already listed");
    require(sell_to != address(0), "MarketplaceFacet: Buyer not set");
    address sender = LibUtils.msgSender();
    uint256 time = block.timestamp;
    uint256 listingId = ls.listingCounts.totalListings;

    ls.listings[listingId] = Listing({
      id: listingId,
      seller: sender,
      sell_to: sell_to,
      tokenId: tokenId,
      token_type: tokenType,
      price: price,
      sold_on: 0,
      sold_to: address(0),
      cancelled: false,
      created_on: time,
      modified_on: time
    });

    ls.token[tokenType][tokenId] = TokenListingData({ isListed: true, listingId: listingId });
    ls.userListings[sender].push(listingId);

    LibMarketplace.increaseCounters(ls.listingCounts, 1, 1);
    LibMarketplace.increaseCounters(ls.userCounts[sender], 1, 1);
  }

  function cancelListing(uint256 listingId) public {
    Listing storage currentListing = LibMarketplace.getStorage().listings[listingId];
    require(currentListing.seller == LibUtils.msgSender(), "MarketplaceFacet: Not listing seller");

    LibMarketplace.cancelListing(currentListing.token_type, currentListing.tokenId);
  }

  function updateListingPrice(uint256 listingId, uint256 newPrice) public {
    Listing storage currentListing = LibMarketplace.getStorage().listings[listingId];
    require(currentListing.seller == LibUtils.msgSender(), "MarketplaceFacet: Not listing seller");

    currentListing.price = newPrice;
    currentListing.modified_on = block.timestamp;
  }

  function executeListing(uint256 listingId) public payable {
    MarketplaceLayout storage ls = LibMarketplace.getStorage();
    Listing storage currentListing = ls.listings[listingId];
    require(LibUtils.msgSender() != currentListing.seller, "MarketplaceFacet: Buyer cannot be seller");
    TokenListingData storage currentToken = ls.token[currentListing.token_type][currentListing.tokenId];

    require(currentListing.sell_to == address(0), "MarketplaceFacet: Listing is private");
    require(msg.value >= currentListing.price, "MarketplaceFacet: Not enough ether sent");

    address buyer = LibUtils.msgSender();
    currentListing.sold_to = buyer;
    currentListing.sold_on = block.timestamp;
    currentToken.isListed = false;
    currentToken.listingId = 0;

    LibMarketplace.decreaseCounters(ls.listingCounts, 0, 1);
    LibMarketplace.decreaseCounters(ls.userCounts[currentListing.seller], 0, 1);

    payable(currentListing.seller).transfer(msg.value);

    if (currentListing.token_type == TokenType.NFT) {
      IERC721(address(this)).safeTransferFrom(currentListing.seller, buyer, currentListing.tokenId, "");
    }
    // else if (currentListing.token_type == TokenType.Scroll) {
    //   IIdentity(address(this)).transferScroll(currentListing.seller, buyer, currentListing.tokenId);
    // }
  }

  function executePrivateListing(uint256 listingId) public payable {
    MarketplaceLayout storage ls = LibMarketplace.getStorage();
    Listing storage currentListing = ls.listings[listingId];
    require(LibUtils.msgSender() != currentListing.seller, "MarketplaceFacet: Buyer cannot be seller");
    TokenListingData storage currentToken = ls.token[currentListing.token_type][currentListing.tokenId];

    address buyer = LibUtils.msgSender();
    require(currentListing.sell_to == buyer, "MarketplaceFacet: Reserved for different address");
    require(msg.value >= currentListing.price, "MarketplaceFacet: Not enough ether sent");

    currentListing.sold_to = buyer;
    currentListing.sold_on = block.timestamp;
    currentToken.isListed = false;
    currentToken.listingId = 0;

    LibMarketplace.decreaseCounters(ls.listingCounts, 0, 1);
    LibMarketplace.decreaseCounters(ls.userCounts[currentListing.seller], 0, 1);

    payable(currentListing.seller).transfer(msg.value);

    if (currentListing.token_type == TokenType.NFT) {
      IERC721(address(this)).safeTransferFrom(currentListing.seller, buyer, currentListing.tokenId, "");
    }
    // else if (currentListing.token_type == TokenType.Scroll) {
    //   IIdentity(address(this)).transferScroll(currentListing.seller, buyer, currentListing.tokenId);
    // }
  }

  function getListings(uint256 startId, uint256 endId) public view returns (Listing[] memory) {
    unchecked {
      require(endId >= startId, "Invalid query range");
      MarketplaceLayout storage ls = LibMarketplace.getStorage();
      uint256 listingIdx;
      uint256 endIdLimit = ls.listingCounts.totalListings;

      if (endId > endIdLimit) {
        endId = endIdLimit;
      }

      if (startId < endId) {
        uint256 rangeLength = endId - startId;
        if (rangeLength < endIdLimit) {
          endIdLimit = rangeLength;
        }
      } else {
        endIdLimit = 0;
      }
      Listing[] memory listings = new Listing[](endIdLimit);
      if (endIdLimit == 0) {
        return listings;
      }

      for (uint256 i = startId; i != endId && listingIdx != endIdLimit; ++i) {
        listings[listingIdx++] = ls.listings[i];
      }
      assembly {
        mstore(listings, listingIdx)
      }
      return listings;
    }
  }

  function getActiveListings(uint256 startId, uint256 endId) public view returns (Listing[] memory) {
    unchecked {
      require(endId >= startId, "Invalid query range");
      MarketplaceLayout storage ls = LibMarketplace.getStorage();
      uint256 listingIdx;
      uint256 endIdLimit = ls.listingCounts.totalListings;
      uint256 listingsMaxLength = ls.listingCounts.activeListings;

      if (endId > endIdLimit) {
        endId = endIdLimit;
      }

      if (startId < endId) {
        uint256 rangeLength = endId - startId;
        if (rangeLength < listingsMaxLength) {
          listingsMaxLength = rangeLength;
        }
      } else {
        listingsMaxLength = 0;
      }
      Listing[] memory listings = new Listing[](listingsMaxLength);
      if (listingsMaxLength == 0) {
        return listings;
      }

      Listing memory currentListing;

      for (uint256 i = startId; i != endId && listingIdx != listingsMaxLength; ++i) {
        currentListing = ls.listings[i];
        if (currentListing.cancelled || currentListing.sold_on > 0) {
          continue;
        } else {
          listings[listingIdx++] = currentListing;
        }
      }
      assembly {
        mstore(listings, listingIdx)
      }
      return listings;
    }
  }

  function getListingsForAddress(address seller) public view returns (Listing[] memory) {
    unchecked {
      MarketplaceLayout storage ls = LibMarketplace.getStorage();
      uint256 listingIdx;
      uint256 endId = ls.userCounts[seller].totalListings;
      uint256[] memory userListings = ls.userListings[seller];

      Listing[] memory listings = new Listing[](endId);
      if (endId == 0) {
        return listings;
      }

      for (uint256 i = 0; i != endId && listingIdx != endId; ++i) {
        listings[listingIdx++] = ls.listings[userListings[i]];
      }
      assembly {
        mstore(listings, listingIdx)
      }
      return listings;
    }
  }

  function getActiveListingsForAddress(address seller) public view returns (Listing[] memory) {
    unchecked {
      MarketplaceLayout storage ls = LibMarketplace.getStorage();
      uint256 listingIdx;
      uint256 endId = ls.userCounts[seller].totalListings;
      uint256 listingsMaxLength = ls.userCounts[seller].activeListings;
      uint256[] memory userListings = ls.userListings[seller];

      Listing[] memory listings = new Listing[](listingsMaxLength);
      if (listingsMaxLength == 0) {
        return listings;
      }

      Listing memory currentListing;

      for (uint256 i = 0; i != endId && listingIdx != listingsMaxLength; ++i) {
        currentListing = ls.listings[userListings[i]];
        if (currentListing.cancelled || currentListing.sold_on > 0) {
          continue;
        } else {
          listings[listingIdx++] = currentListing;
        }
      }
      assembly {
        mstore(listings, listingIdx)
      }
      return listings;
    }
  }

  function getListingCounts() public view returns (ListingCounters memory) {
    return LibMarketplace.getStorage().listingCounts;
  }

  function getListingCountsForAddress(address user) public view returns (ListingCounters memory) {
    return LibMarketplace.getStorage().userCounts[user];
  }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.3
// Creator: Chiru Labs

pragma solidity ^0.8.20;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721 {
  /**
   * The caller must own the token or be an approved operator.
   */
  error ApprovalCallerNotOwnerNorApproved();

  /**
   * The token does not exist.
   */
  error ApprovalQueryForNonexistentToken();

  /**
   * Cannot query the balance for the zero address.
   */
  error BalanceQueryForZeroAddress();

  /**
   * Cannot mint to the zero address.
   */
  error MintToZeroAddress();

  /**
   * The quantity of tokens minted must be more than zero.
   */
  error MintZeroQuantity();

  /**
   * The token does not exist.
   */
  error OwnerQueryForNonexistentToken();

  /**
   * The caller must own the token or be an approved operator.
   */
  error TransferCallerNotOwnerNorApproved();

  /**
   * The token must be owned by `from`.
   */
  error TransferFromIncorrectOwner();

  /**
   * Cannot safely transfer to a contract that does not implement the
   * ERC721Receiver interface.
   */
  error TransferToNonERC721ReceiverImplementer();

  /**
   * Cannot transfer to the zero address.
   */
  error TransferToZeroAddress();

  /**
   * The token does not exist.
   */
  error URIQueryForNonexistentToken();

  /**
   * The `extraData` cannot be set on an unintialized ownership slot.
   */
  error OwnershipNotInitializedForExtraData();

  // =============================================================
  //                            STRUCTS
  // =============================================================

  struct TokenOwnership {
    // The address of the owner.
    address addr;
    // Stores the start time of ownership with minimal overhead for tokenomics.
    uint64 startTimestamp;
    // Whether the token has been burned.
    bool burned;
    // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
    uint24 extraData;
  }

  // =============================================================
  //                         TOKEN COUNTERS
  // =============================================================

  /**
   * @dev Returns the total number of tokens in existence.
   * Burned tokens will reduce the count.
   * To get the total number of tokens minted, please see {_totalMinted}.
   */
  function totalSupply() external view returns (uint256);

  // =============================================================
  //                            IERC721
  // =============================================================

  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

  /**
   * @dev Emitted when `owner` enables or disables
   * (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Returns the number of tokens in `owner`'s account.
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
   * @dev Safely transfers `tokenId` token from `from` to `to`,
   * checking first that contract recipients are aware of the ERC721 protocol
   * to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move
   * this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement
   * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external payable;

  /**
   * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
   */
  function safeTransferFrom(address from, address to, uint256 tokenId) external payable;

  /**
   * @dev Transfers `tokenId` from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
   * whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token
   * by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(address from, address to, uint256 tokenId) external payable;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the
   * zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external payable;

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom}
   * for any token owned by the caller.
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
   * See {setApprovalForAll}.
   */
  function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

interface IIdentity {
  function transferScroll(address from, address to, uint256 scrollId) external;
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { LibUtils } from "./LibUtils.sol";
// import { LibIdentity } from "./LibIdentity.sol";
import { LibMarketplace, TokenType } from "./LibMarketplace.sol";

interface IERC721Receiver {
  function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

enum UtilityTokens {
  none,
  Eraser
}

struct TokenApprovalRef {
  address value;
}

struct ChipData {
  bool burned;
  uint256 iteration;
}

struct StorageLayout {
  string name;
  string symbol;
  uint16 maxSupply;
  uint16 creatorSupply;
  uint16 creatorMaxSupply;
  bool burnActive;
  uint256 _currentIndex;
  uint256 _burnCounter;
  uint256 chipsBurned;
  uint256 maxReroll;
  address storageUnitAddr;
  mapping(uint256 => bool) chipBurned;
  mapping(uint256 => uint256) _packedOwnerships;
  mapping(address => uint256) _packedAddressData;
  mapping(uint256 => TokenApprovalRef) _tokenApprovals;
  mapping(address => mapping(address => bool)) _operatorApprovals;
}

//solhint-disable no-inline-assembly, reason-string, no-empty-blocks
library LibERC721 {
  // =============================================================
  //                           CONSTANTS
  // =============================================================
  string internal constant CHIP_SVG =
    '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" height="100%" width="100%" viewBox="0 0 58 58"><path style="fill:#56A157;" d="M49,0c0,2.761-2.239,5-5,5s-5-2.239-5-5H0v58h39c0-2.761,2.239-5,5-5s5,2.239,5,5h9V0H49z"/><polygon style="fill:#EBDA6C;" points="0,0 0,8 8,0 "/><path style="fill:#EDDC6E;" d="M43.033,10H14.967C12.224,10,10,12.224,10,14.967V20.5c0,0.828,0.672,1.5,1.5,1.5h0  c0.828,0,1.5,0.672,1.5,1.5v11c0,0.828-0.672,1.5-1.5,1.5h0c-0.828,0-1.5,0.672-1.5,1.5v5.533C10,45.776,12.224,48,14.967,48h28.067  C45.776,48,48,45.776,48,43.033V14.967C48,12.224,45.776,10,43.033,10z"/><g><circle style="fill:#EDDC6E;" cx="3" cy="50" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="55" cy="3" r="1"/><circle style="fill:#EDDC6E;" cx="55" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="48" r="1"/><circle style="fill:#EDDC6E;" cx="53" cy="34" r="1"/><circle style="fill:#EDDC6E;" cx="55" cy="36" r="1"/><circle style="fill:#EDDC6E;" cx="53" cy="44" r="1"/><circle style="fill:#EDDC6E;" cx="55" cy="46" r="1"/><circle style="fill:#EDDC6E;" cx="53" cy="24" r="1"/><circle style="fill:#EDDC6E;" cx="55" cy="26" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="45" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="43" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="40" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="38" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="35" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="33" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="30" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="28" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="25" r="1"/><circle style="fill:#EDDC6E;" cx="5" cy="23" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="10" r="1"/><circle style="fill:#EDDC6E;" cx="16" cy="3" r="1"/><circle style="fill:#EDDC6E;" cx="12" cy="3" r="1"/><circle style="fill:#EDDC6E;" cx="3" cy="13" r="1"/><circle style="fill:#EDDC6E;" cx="36" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="34" cy="53" r="1"/><circle style="fill:#EDDC6E;" cx="31" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="29" cy="53" r="1"/><circle style="fill:#EDDC6E;" cx="26" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="24" cy="53" r="1"/><circle style="fill:#EDDC6E;" cx="21" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="19" cy="53" r="1"/><circle style="fill:#EDDC6E;" cx="16" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="14" cy="53" r="1"/><circle style="fill:#EDDC6E;" cx="11" cy="55" r="1"/><circle style="fill:#EDDC6E;" cx="9" cy="53" r="1"/></g><path style="fill:#414141;" d="M41.687,45H16.313C14.483,45,13,43.517,13,41.687V16.313C13,14.483,14.483,13,16.313,13h25.375  C43.517,13,45,14.483,45,16.313v25.375C45,43.517,43.517,45,41.687,45z"/><g><path style="fill:#AFB6BB;" d="M40.446,24.385c-1.09-2.48-3.927-3.962-7.59-3.962c-2.146,0-4.434,0.507-6.614,1.464   c-2.862,1.258-5.25,3.163-6.725,5.365c-1.567,2.34-1.938,4.75-1.044,6.786C19.563,36.519,22.4,38,26.063,38   c2.147,0,4.434-0.507,6.615-1.464c2.862-1.258,5.25-3.163,6.725-5.365C40.97,28.831,41.341,26.421,40.446,24.385z M37.741,30.059   c-1.266,1.89-3.35,3.54-5.868,4.646C29.944,35.552,27.935,36,26.063,36c-2.845,0-4.998-1.034-5.759-2.767   c-0.609-1.388-0.299-3.116,0.875-4.868c1.266-1.891,3.35-3.541,5.868-4.646c1.928-0.848,3.937-1.296,5.809-1.296   c2.845,0,4.999,1.034,5.759,2.767C39.225,26.577,38.915,28.307,37.741,30.059z"/><path style="fill:#AFB6BB;" d="M33,28h-7c-0.552,0-1,0.447-1,1s0.448,1,1,1h7c0.552,0,1-0.447,1-1S33.552,28,33,28z"/></g></svg>';
  bytes32 internal constant STORAGE_SLOT = keccak256("ERC721A.contracts.storage.ERC721A");
  uint256 internal constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
  uint256 internal constant _BITMASK_BURNED = 1 << 224;
  uint256 internal constant _BITPOS_NUMBER_BURNED = 128;
  uint256 internal constant _BITMASK_NEXT_INITIALIZED = 1 << 225;
  uint256 internal constant _BITMASK_ADDRESS = (1 << 160) - 1;
  uint256 internal constant _BITPOS_NUMBER_MINTED = 64;
  uint256 internal constant _BITPOS_START_TIMESTAMP = 160;
  uint256 internal constant _BITPOS_EXTRA_DATA = 232;
  uint256 internal constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;
  uint256 internal constant _startTokenId = 1;

  function getStorage() internal pure returns (StorageLayout storage strg) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  // =============================================================
  //                        MINT OPERATIONS
  // =============================================================

  function _mint(address to, uint256 quantity) internal {
    StorageLayout storage ds = getStorage();
    uint256 startTokenId = ds._currentIndex;

    require(quantity > 0, "LibERC721: Cant mint 0 tokens");
    require(totalSupply() + quantity <= ds.maxSupply, "LibERC721: Max supply exceeded");
    bytes32 transferEventSig = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;
    uint256 bitMaskAddress = (1 << 160) - 1;

    unchecked {
      ds._packedAddressData[to] += quantity * ((1 << 64) | 1);
      ds._packedOwnerships[startTokenId] = _packOwnershipData(to, _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0));

      uint256 toMasked;
      uint256 end = startTokenId + quantity;

      assembly {
        toMasked := and(to, bitMaskAddress)
        log4(0, 0, transferEventSig, 0, toMasked, startTokenId)
        for {
          let tokenId := add(startTokenId, 1)
        } iszero(eq(tokenId, end)) {
          tokenId := add(tokenId, 1)
        } {
          log4(0, 0, transferEventSig, 0, toMasked, tokenId)
        }
      }
      require(toMasked != 0, "LibERC721: Cant mint to zero address");
      ds._currentIndex = end;
    }
  }

  function _safeMint(address to, uint256 quantity, bytes memory _data) internal {
    StorageLayout storage ds = getStorage();
    _mint(to, quantity);

    unchecked {
      if (to.code.length != 0) {
        uint256 end = ds._currentIndex;
        uint256 index = end - quantity;
        do {
          if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
            revert("LibERC721: Transfer to non ERC721Receiver");
          }
        } while (index < end);
        // Reentrancy protection.
        // solhint-disable-next-line reason-string
        if (ds._currentIndex != end) revert();
      }
    }
  }

  // =============================================================
  //                        BURN OPERATIONS
  // =============================================================

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  function _burn(uint256 tokenId, bool approvalCheck) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);
    address from = address(uint160(prevOwnershipPacked));
    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (approvalCheck) {
      if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
        if (!isApprovedForAll(from, LibUtils.msgSender())) revert("LibERC721: Call not authorized");
    }

    _beforeTokenTransfers(from, address(0), tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      ds._packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;
      ds._packedOwnerships[tokenId] = _packOwnershipData(
        from,
        (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
      );

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, address(0), tokenId);
    _afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
      ds._burnCounter++;
    }
  }

  function transferFrom(address from, address to, uint256 tokenId) internal {
    StorageLayout storage ds = getStorage();
    uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

    if (address(uint160(prevOwnershipPacked)) != from) revert("LibERC721: Transfer from incorrect owner");

    (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

    if (!_isSenderApprovedOrOwner(approvedAddress, from, LibUtils.msgSender()))
      if (!isApprovedForAll(from, LibUtils.msgSender()) || LibUtils.msgSender() != address(this)) revert("LibERC721: Caller not owner nor approved");

    if (to == address(0)) revert("LibERC721: Transfer to zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    assembly {
      if approvedAddress {
        sstore(approvedAddressSlot, 0)
      }
    }

    unchecked {
      --ds._packedAddressData[from];
      ++ds._packedAddressData[to];

      ds._packedOwnerships[tokenId] = _packOwnershipData(to, _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked));

      if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
        uint256 _nextTokenId = tokenId + 1;
        if (ds._packedOwnerships[_nextTokenId] == 0) {
          if (_nextTokenId != ds._currentIndex) {
            ds._packedOwnerships[_nextTokenId] = prevOwnershipPacked;
          }
        }
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
    transferFrom(from, to, tokenId);
    if (to.code.length != 0)
      if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
        revert("LibERC721: Transfer to non ERC721 receiver");
      }
  }

  function isApprovedForAll(address owner, address operator) internal view returns (bool) {
    return getStorage()._operatorApprovals[owner][operator];
  }

  function _isSenderApprovedOrOwner(address approvedAddress, address owner, address msgSender) internal pure returns (bool result) {
    assembly {
      owner := and(owner, _BITMASK_ADDRESS)
      msgSender := and(msgSender, _BITMASK_ADDRESS)
      result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
    }
  }

  function _checkContractOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) internal returns (bool) {
    try IERC721Receiver(to).onERC721Received(LibUtils.msgSender(), from, tokenId, _data) returns (bytes4 retval) {
      return retval == IERC721Receiver(to).onERC721Received.selector;
    } catch (bytes memory reason) {
      require(reason.length > 0, "LibERC721: Transfer to non ERC721Receiver");
      assembly {
        revert(add(32, reason), mload(reason))
      }
    }
  }

  function _beforeTokenTransfers(address from, address to, uint256 tokenId, uint256 quantity) internal {}

  function _afterTokenTransfers(address from, address, uint256 tokenId, uint256) internal {
    if (from != address(0)) {
      // if (balanceOf(from) == 0) {
      //   if (LibIdentity.hasIdentity(from)) LibIdentity.removeIdentity(from);
      // }

      // if (LibIdentity.hasScroll(tokenId)) {
      //   LibIdentity.removeToken(LibIdentity.getStorage().tokenToScroll[tokenId]);
      // }

      if (LibMarketplace.isListed(TokenType.NFT, tokenId)) LibMarketplace.cancelListing(TokenType.NFT, tokenId);
    }
  }

  function _nextInitializedFlag(uint256 quantity) internal pure returns (uint256 result) {
    // For branchless setting of the `nextInitialized` flag.
    assembly {
      // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
      result := shl(225, eq(quantity, 1))
    }
  }

  function _nextExtraData(address from, address to, uint256 prevOwnershipPacked) internal view returns (uint256) {
    uint24 extraData = uint24(prevOwnershipPacked >> 232);
    return uint256(_extraData(from, to, extraData)) << 232;
  }

  function _extraData(address from, address to, uint24 previousExtraData) internal view returns (uint24) {}

  function _packOwnershipData(address owner, uint256 flags) internal view returns (uint256 result) {
    uint256 bitMaskAddress = (1 << 160) - 1;
    assembly {
      // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
      owner := and(owner, bitMaskAddress)
      // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
      result := or(owner, or(shl(160, timestamp()), flags))
    }
  }

  function nextTokenId() internal view returns (uint256) {
    return getStorage()._currentIndex;
  }

  function balanceOf(address owner) internal view returns (uint256) {
    require(owner != address(0), "LibERC721: Invalid address");
    return getStorage()._packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
  }

  function ownerOf(uint256 tokenId) internal view returns (address) {
    return address(uint160(_packedOwnershipOf(tokenId)));
  }

  function totalSupply() internal view returns (uint256) {
    StorageLayout storage ds = getStorage();
    // Counter underflow is impossible as _burnCounter cannot be incremented
    // more than `_currentIndex - _startTokenId` times.
    unchecked {
      return ds._currentIndex - ds._burnCounter - _startTokenId;
    }
  }

  function _packedOwnershipOf(uint256 tokenId) internal view returns (uint256 packed) {
    StorageLayout storage ds = getStorage();
    if (_startTokenId <= tokenId) {
      packed = ds._packedOwnerships[tokenId];
      if (packed & _BITMASK_BURNED == 0) {
        if (packed == 0) {
          if (tokenId >= ds._currentIndex) revert("LibERC721: Owner query for non existing token");
          for (;;) {
            unchecked {
              packed = ds._packedOwnerships[--tokenId];
            }
            if (packed == 0) continue;
            return packed;
          }
        }
        return packed;
      }
    }
    revert("LibERC721: Owner query for non existing token");
  }

  function _getApprovedSlotAndAddress(uint256 tokenId) internal view returns (uint256 approvedAddressSlot, address approvedAddress) {
    TokenApprovalRef storage tokenApproval = getStorage()._tokenApprovals[tokenId];
    assembly {
      approvedAddressSlot := tokenApproval.slot
      approvedAddress := sload(approvedAddressSlot)
    }
  }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.20;

import { LibERC721 } from "./LibERC721.sol";

struct IdentityExternal {
  uint16 attachedToken;
  ScrollFieldExternal[] fields;
}

struct ScrollFieldExternal {
  uint256 id;
  string name;
  string data;
}

struct ScrollExternal {
  address owner;
  uint8 fieldCount;
  uint8 unlockedFields;
  uint16 attachedToken;
  bool isAttached;
  ScrollFieldExternal[] fields;
}

struct ScrollField {
  string name;
  string data;
}

struct Scroll {
  address owner;
  uint8 fieldCount;
  uint8 unlockedFields;
  uint16 attachedToken;
  bool isAttached;
  mapping(uint8 => ScrollField) fields;
}

struct UserData {
  uint256 attachedScroll;
  uint256 scrollCount;
}

struct IdentityLayout {
  uint256 maxFields;
  uint256 scrollSupply;
  uint256 identitiesRecorded;
  mapping(uint256 => Scroll) scrolls;
  mapping(address => UserData) userData;
  mapping(uint256 => uint256) tokenToScroll;
}

library LibIdentity {
  bytes32 internal constant IDENTITY_DATA_SLOT = keccak256("user.identity.data.layout");

  function getStorage() internal pure returns (IdentityLayout storage strg) {
    bytes32 slot = IDENTITY_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function mint(address owner, uint256 quantity) internal {
    IdentityLayout storage ids = getStorage();
    if (quantity > 1) {
      for (uint i = 0; i < quantity; i++) {
        ids.scrollSupply++;
        ids.scrolls[ids.scrollSupply].owner = owner;
        ids.userData[owner].scrollCount++;
      }
    } else {
      ids.scrollSupply++;
      ids.scrolls[ids.scrollSupply].owner = owner;

      ids.userData[owner].scrollCount++;
    }
  }

  function transfer(address from, address to, uint256 scrollId) internal {
    IdentityLayout storage ids = getStorage();

    ids.scrolls[scrollId].owner = to;

    ids.userData[from].scrollCount--;
    ids.userData[to].scrollCount++;
  }

  function removeIdentity(address user) internal {
    IdentityLayout storage ids = getStorage();

    ids.scrolls[ids.userData[user].attachedScroll].isAttached = false;
    delete ids.userData[user].attachedScroll;
    ids.identitiesRecorded--;
  }

  function removeToken(uint256 scrollId) internal {
    Scroll storage currentScroll = getStorage().scrolls[scrollId];

    currentScroll.attachedToken = 0;
  }

  function scrollSupply() internal view returns (uint256) {
    return getStorage().scrollSupply;
  }

  function getOwner(uint256 scrollId) internal view returns (address) {
    return getStorage().scrolls[scrollId].owner;
  }

  function isTransferable(uint256 scrollId) internal view returns (bool) {
    return getStorage().scrolls[scrollId].attachedToken == 0;
  }

  function isAttached(uint256 scrollId) internal view returns (bool) {
    return getStorage().scrolls[scrollId].isAttached;
  }

  function hasScroll(uint256 tokenId) internal view returns (bool) {
    return getStorage().tokenToScroll[tokenId] > 0;
  }

  function hasIdentity(address user) internal view returns (bool) {
    return getStorage().userData[user].attachedScroll > 0;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

enum TokenType {
  NFT
}

struct Listing {
  uint256 id;
  address seller;
  address sell_to;
  uint256 tokenId;
  TokenType token_type;
  uint256 price;
  uint256 sold_on;
  address sold_to;
  bool cancelled;
  uint256 created_on;
  uint256 modified_on;
}

struct ListingCounters {
  uint256 totalListings;
  uint256 activeListings;
}

struct TokenListingData {
  bool isListed;
  uint256 listingId;
}

struct MarketplaceLayout {
  ListingCounters listingCounts;
  mapping(uint256 => Listing) listings;
  mapping(address => ListingCounters) userCounts;
  mapping(address => uint256[]) userListings;
  mapping(TokenType => mapping(uint256 => TokenListingData)) token;
}

library LibMarketplace {
  bytes32 internal constant MARKETPLACE_DATA_SLOT = keccak256("erc721.marketplace.storage.layout");

  function getStorage() internal pure returns (MarketplaceLayout storage strg) {
    bytes32 slot = MARKETPLACE_DATA_SLOT;
    assembly {
      strg.slot := slot
    }
  }

  function increaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings += total;
    strg.activeListings += active;
  }

  function decreaseCounters(ListingCounters storage strg, uint256 total, uint256 active) internal {
    strg.totalListings -= total;
    strg.activeListings -= active;
  }

  function cancelListing(TokenType tokenType, uint256 tokenId) internal {
    MarketplaceLayout storage ls = getStorage();
    TokenListingData storage currentToken = ls.token[tokenType][tokenId];
    Listing storage currentListing = ls.listings[currentToken.listingId];

    currentListing.cancelled = true;
    currentListing.modified_on = block.timestamp;
    ls.token[tokenType][tokenId] = TokenListingData({ isListed: false, listingId: 0 });

    decreaseCounters(ls.listingCounts, 0, 1);
    decreaseCounters(ls.userCounts[currentListing.seller], 0, 1);
  }

  function isListed(TokenType tokenType, uint256 tokenId) internal view returns (bool) {
    return getStorage().token[tokenType][tokenId].isListed;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// solhint-disable no-inline-assembly
library LibUtils {
  function msgSender() internal view returns (address sender_) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
      }
    } else {
      sender_ = msg.sender;
    }
  }

  function numberToString(uint256 value) internal pure returns (string memory str) {
    assembly {
      let m := add(mload(0x40), 0xa0)
      mstore(0x40, m)
      str := sub(m, 0x20)
      mstore(str, 0)

      let end := str

      // prettier-ignore
      // solhint-disable-next-line no-empty-blocks
      for { let temp := value } 1 {} {
        str := sub(str, 1)
        mstore8(str, add(48, mod(temp, 10)))
        temp := div(temp, 10)
        if iszero(temp) { break }
      }

      let length := sub(end, str)
      str := sub(str, 0x20)
      mstore(str, length)
    }
  }

  function addressToString(address _addr) internal pure returns (string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
      str[2 + i * 2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3 + i * 2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function bytes32ToString(bytes32 value) internal pure returns (string memory) {
    bytes memory result = new bytes(64);

    for (uint256 i = 0; i < 32; i++) {
      uint8 b = uint8(value[i]);
      result[i * 2] = _hexChar(b >> 4);
      result[i * 2 + 1] = _hexChar(b & 0x0f);
    }

    return string(abi.encodePacked("0x", result));
  }

  function _hexChar(uint8 b) internal pure returns (bytes1) {
    if (b < 10) {
      return bytes1(uint8(b + 48)); // 0-9
    } else {
      return bytes1(uint8(b + 87)); // a-f
    }
  }

  function getMax(uint256[6] memory nums) internal pure returns (uint256 maxNum) {
    maxNum = nums[0];
    for (uint256 i = 1; i < nums.length; i++) {
      if (nums[i] > maxNum) maxNum = nums[i];
    }
  }

  function compareStrings(string memory str1, string memory str2) internal pure returns (bool) {
    return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
  }
}