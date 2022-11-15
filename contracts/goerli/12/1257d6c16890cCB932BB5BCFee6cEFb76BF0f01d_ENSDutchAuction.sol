// SPDX-License-Identifier: MIT

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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

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

interface IENSRegistry {
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function setOwner(bytes32 node, address owner) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external;
    function setResolver(bytes32 node, address resolver) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);
    event Transfer(bytes32 indexed node, address owner);
    event NewResolver(bytes32 indexed node, address resolver);
    event NewTTL(bytes32 indexed node, uint64 ttl);
}

contract ENSDutchAuction is IERC721Receiver {

    struct Auction {
        address seller;
        address buyer;
        uint256 price;
        uint256 start;
        uint256 end;
        uint256 tokenId;
        bool active;
    }

    uint256 public startingPrice = 100000 ether;
    IERC721 public ENSContract = IERC721(0x03dEfa67d96eeE16f8AFa91781289Fc8C38465A3);
    IENSRegistry public ens = IENSRegistry(0x00000000000C2E074eC69A0dFb2997BA6C7d2e1e);
    address payable public treasury;

    mapping(uint256 => Auction) private auctions;
    uint256[] private auctionIds;

    event AuctionCreated(address indexed seller, uint256 indexed tokenId, uint256 price, uint256 start, uint256 end);
    event AuctionEnded(address indexed seller, address indexed buyer, uint256 indexed tokenId, uint256 price);

    constructor(address payable _treasury) {
        treasury = _treasury;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes calldata) external override returns (bytes4) {
        require(msg.sender == address(ENSContract), "only ENS contract can call this function");
        // require(ens.owner(keccak256(abi.encodePacked(tokenId))) == address(this), "only ENS domains owned by this contract can be listed");
        require(auctions[tokenId].active == false, "auction already exists for this domain");
        auctions[tokenId] = Auction({
            seller: from,
            buyer: address(0),
            price: startingPrice,
            start: block.timestamp,
            end: block.timestamp + 3 weeks,
            tokenId: tokenId,
            active: true
        });
        auctionIds.push(tokenId);
        emit AuctionCreated(from, tokenId, startingPrice, block.timestamp, block.timestamp + 3 weeks);
        return this.onERC721Received.selector;
    }

    function buy(uint256 tokenId) external payable {
        Auction storage auction = auctions[tokenId];
        require(auction.active == true, "auction not active");
        require(msg.value >= auction.price, "not enough funds");
        require(block.timestamp < auction.end, "auction ended");
        uint256 price = getAuctionCurrentPrice(tokenId);
        uint256 commission = price / 10;
        uint256 sellerAmount = price - commission;
        auction.active = false;
        auction.buyer = msg.sender;
        ENSContract.safeTransferFrom(address(this), msg.sender, tokenId);
        treasury.transfer(commission);
        payable(auction.seller).transfer(sellerAmount);
        emit AuctionEnded(auction.seller, msg.sender, tokenId, price);
    }

    function getAuctionCurrentPrice(uint256 tokenId) public view returns (uint256) {
        Auction storage auction = auctions[tokenId];
        require(auction.active, "not active");        
        uint256 daysPassed = (block.timestamp - auction.start) / 1 days;
        uint256 price = auction.price;
        for (uint256 i = 0; i < daysPassed; i++) {
            price = price / 2;
        }
        return price;
    }

    /**
     * @dev Returns the auction information for a given token ID.
    */
    function getAuction(uint256 tokenId) public view returns (address seller, uint256 basePrice, uint256 startTime, uint256 endTime, uint256 currentPrice, bool isActive) {
        Auction storage auction = auctions[tokenId];
        return (auction.seller, auction.price, auction.start, auction.end, getAuctionCurrentPrice(tokenId), auction.active);
    }

    /**
        * @dev Returns all the active auctions
    */
    function getActiveAuctions() public view returns (Auction[] memory) {
        Auction[] memory activeAuctions = new Auction[](auctionIds.length);
        uint256 activeAuctionsCount = 0;
        for (uint256 i = 0; i < auctionIds.length; i++) {
            Auction storage auction = auctions[auctionIds[i]];
            if (auction.active) {
                activeAuctions[activeAuctionsCount] = auction;
                activeAuctionsCount++;
            }
        }
        return activeAuctions;
    }

    /**
        * @dev Withdraws an NFT if the auction has ended without a winner.
    */
    function withdraw(uint256 tokenId) external {
        Auction storage auction = auctions[tokenId];
        require(auction.seller == msg.sender, "not seller");
        require(auction.active, "not active");
        require(block.timestamp > auction.end, "too early");
        ENSContract.safeTransferFrom(address(this), msg.sender, tokenId);
        auction.active = false;
    }

    /** 
        * @dev Withdraws all funds from the contract.
    */
    function withdraw() external {
        treasury.transfer(address(this).balance);
    }
    
}