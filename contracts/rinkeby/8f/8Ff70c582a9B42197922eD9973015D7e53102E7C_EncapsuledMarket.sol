/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



pragma solidity ^0.8.0;


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

// File: encapsuledMarket.sol


pragma solidity 0.8.10;


contract EncapsuledMarket {

    IERC721 tokensContract;
    address contractOwner;
    address royaltiesAddress = 0xA551B27aEB7E6cB6A8ee60A0774eEc8bA14a47d8;
    uint royaltiesPerc = 10;

    struct Listing {
        bool isForSale;
        uint index;
        address seller;
        uint minValue;          // in ether
        address onlySellTo;     // specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint index;
        address bidder;
        uint value;
    }

    // A record of tokens that are listed for sale at a specific minimum value, and perhaps to a specific person
    mapping (uint => Listing) public tokensListedForSale;

    // A record of the highest token bids
    mapping (uint => Bid) public tokenBids;

    // A record of pending ETH withdrawls by address
    mapping (address => uint) public pendingWithdrawals;

    event TokenOnSale(uint indexed tokenIndex, uint minValue, address indexed toAddress);
    event TokenBidEntered(uint indexed tokenIndex, uint value, address indexed fromAddress);
    event TokenBidWithdrawn(uint indexed tokenIndex, uint value, address indexed fromAddress);
    event TokenBought(uint indexed tokenIndex, uint value, address indexed fromAddress, address indexed toAddress);
    event TokenNoLongerForSale(uint indexed tokenIndex);

    /* Initializes contract with an instance of the contract, and sets deployer as owner */
    constructor(address initialAddress) {
        if (initialAddress == address(0x0)) revert();
        tokensContract = IERC721(initialAddress);
        contractOwner = msg.sender;
    }

    /* Returns the contract address currently being used */
    function tokensAddress() public view returns (address) {
      return address(tokensContract);
    }

    /* Allows the owner of the contract to set a new royalty percentage */
    function setRoyaltiesPerc(uint newPerc) public {
      if (msg.sender != contractOwner) revert();
      if (newPerc > 10) revert();
      royaltiesPerc = newPerc;
    }
    
    /* Allows the owner of the contract to set a new contract address */
    function setContract(address newAddress) public {
      if (msg.sender != contractOwner) revert();
      tokensContract = IERC721(newAddress);
    }

    /* Allows the owner of the contract to set a new contract address for the royalties */
    function setRoyaltiesAddress(address newAddress) public {
      if (msg.sender != contractOwner) revert();
      royaltiesAddress = newAddress;
    }
    
    /* Allows the owner of a token to cancel the listing */
    function tokenNoLongerForSale(uint tokenIndex) public {
        if (tokensContract.ownerOf(tokenIndex) != msg.sender) revert();
        tokensListedForSale[tokenIndex] = Listing(false, tokenIndex, msg.sender, 0, address(0x0));
        emit TokenNoLongerForSale(tokenIndex);
    }

    /* Allows a token owner to list it for sale */
    function listTokenForSale(uint tokenIndex, uint minSalePriceInWei) public {
        if (tokensContract.ownerOf(tokenIndex) != msg.sender) revert();
        tokensListedForSale[tokenIndex] = Listing(true, tokenIndex, msg.sender, minSalePriceInWei, address(0x0));
        emit TokenOnSale(tokenIndex, minSalePriceInWei, address(0x0));
    }

    /* Allows a token owner to list it for sale to a specific address */
    function listTokenForSaleToAddress(uint tokenIndex, uint minSalePriceInWei, address toAddress) public {
        if (tokensContract.ownerOf(tokenIndex) != msg.sender) revert();
        if (tokensContract.getApproved(tokenIndex) != address(this)) revert();
        tokensListedForSale[tokenIndex] = Listing(true, tokenIndex, msg.sender, minSalePriceInWei, toAddress);
        emit TokenOnSale(tokenIndex, minSalePriceInWei, toAddress);
    }

    /* Allows users to buy a token listed for sale */
    function buyToken(uint tokenIndex) payable public {
        Listing memory listing = tokensListedForSale[tokenIndex];
        if (!listing.isForSale) revert();                // token not actually for sale
        if (listing.onlySellTo != address(0x0) && listing.onlySellTo != msg.sender) revert();  // token not supposed to be sold to this user
        if (msg.value < listing.minValue) revert();      // Didn't send enough ETH
        address seller = listing.seller;
        if (seller != tokensContract.ownerOf(tokenIndex)) revert(); // Seller no longer owner of token

        tokensContract.safeTransferFrom(seller, msg.sender, tokenIndex);
        tokenNoLongerForSale(tokenIndex);
        pendingWithdrawals[seller] += msg.value * (100-royaltiesPerc)/100;
        pendingWithdrawals[royaltiesAddress] += msg.value * royaltiesPerc/100;
        emit TokenBought(tokenIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = tokenBids[tokenIndex];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        }
    }

    /* Allows users to retrieve ETH from sales */
    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* Allows users to enter bids for any token */
    function enterBidForToken(uint tokenIndex) payable public {
        if (tokensContract.ownerOf(tokenIndex) == address(0x0)) revert();
        if (tokensContract.ownerOf(tokenIndex) == msg.sender) revert();
        if (msg.value == 0) revert();
        Bid memory existing = tokenBids[tokenIndex];
        if (msg.value <= existing.value) revert();
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        tokenBids[tokenIndex] = Bid(true, tokenIndex, msg.sender, msg.value);
        emit TokenBidEntered(tokenIndex, msg.value, msg.sender);
    }

    /* Allows token owners to accept bids for their tokens */
    function acceptBidForToken(uint tokenIndex, uint minPrice) public {
        if (tokensContract.ownerOf(tokenIndex) != msg.sender) revert();
        address seller = msg.sender;
        Bid memory bid = tokenBids[tokenIndex];
        if (bid.value == 0) revert();
        if (bid.value < minPrice) revert();

        address bidder = bid.bidder;
        tokensContract.safeTransferFrom(msg.sender, bidder, tokenIndex);
        tokensListedForSale[tokenIndex] = Listing(false, tokenIndex, bidder, 0, address(0x0));
        uint amount = bid.value;
        tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        pendingWithdrawals[seller] += amount * (100-royaltiesPerc)/100;
        pendingWithdrawals[royaltiesAddress] += amount * royaltiesPerc/100;
        emit TokenBought(tokenIndex, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForToken(uint tokenIndex) public {
        if (tokensContract.ownerOf(tokenIndex) == address(0x0)) revert();
        if (tokensContract.ownerOf(tokenIndex) == msg.sender) revert();
        Bid memory bid = tokenBids[tokenIndex];
        if (bid.bidder != msg.sender) revert();
        emit TokenBidWithdrawn(tokenIndex, bid.value, msg.sender);
        uint amount = bid.value;
        tokenBids[tokenIndex] = Bid(false, tokenIndex, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }

}