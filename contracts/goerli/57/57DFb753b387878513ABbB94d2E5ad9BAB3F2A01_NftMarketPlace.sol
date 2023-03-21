// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketPlace__NotDeterminedPrice();
error NftMarketPlace__doNotHaveTheAccessToSellThisNft();
error NftMarketPlace__thisNftIsAlreadyListed(
    address nftAddress,
    uint256 tokenId
);
error NftMarketPlace__NotEngthMoney();
error NftMarketPlace__NotTheOwnerOFNft(address nftAddress, uint256 tokenId);
error NftMarketPlace__NftNotListed();
error NftMarketPlace__DoNotHavebalanceToWithDraw();
error NftMarketPlace__Transactionfasild();

contract NftMarketPlace {
    // structure

    struct Listing {
        uint256 price;
        address seller;
    }

    // varibles

    // Mappinng
    // nftAddress => tokenId => {price , seller}
    mapping(address => mapping(uint256 => Listing)) private s_listNfts;

    // seller => balance
    mapping(address => uint256) s_proceed;

    // events
    event NftListed(
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );
    event NftTaken(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address indexed owner,
        uint256 price
    );

    event ItemListedCancled(
        address indexed owner,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // modifire

    modifier notListed(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    ) {
        Listing memory list = s_listNfts[nftAddress][tokenId];
        if (list.price > 0) {
            revert NftMarketPlace__thisNftIsAlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        Listing memory list = s_listNfts[nftAddress][tokenId];
        if (list.price <= 0) {
            revert NftMarketPlace__NftNotListed();
        }
        _;
    }

    modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address seller
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (owner != seller) {
            revert NftMarketPlace__NotTheOwnerOFNft(nftAddress, tokenId);
        }
        _;
    }

    //Main  functions
    function liestedNft(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notListed(nftAddress, tokenId, price)
        isOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NftMarketPlace__NotDeterminedPrice();
        }

        IERC721 nft = IERC721(nftAddress);

        if (nft.getApproved(tokenId) != address(this)) {
            revert NftMarketPlace__doNotHaveTheAccessToSellThisNft();
        }

        s_listNfts[nftAddress][tokenId] = Listing(price, msg.sender);
        emit NftListed(nftAddress, tokenId, price);
    }

    function cancleListedItem(
        address nftAddress,
        uint256 tokenId
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listNfts[nftAddress][tokenId]);
        emit ItemListedCancled(msg.sender, nftAddress, tokenId);
    }

    function butItem(
        address nftAddress,
        uint256 tokenId
    ) external payable isListed(nftAddress, tokenId) {
        Listing memory list = s_listNfts[nftAddress][tokenId];

        if (msg.value < list.price) {
            revert NftMarketPlace__NotEngthMoney();
        }

        s_proceed[list.seller] += msg.value;

        // Update Mapping
        delete (s_listNfts[nftAddress][tokenId]);

        IERC721 nft = IERC721(nftAddress);
        nft.safeTransferFrom(list.seller, msg.sender, tokenId);
        emit NftTaken(nftAddress, tokenId, msg.sender, list.price);
    }

    function updateListItem(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        isOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        if (newPrice <= 0) {
            revert NftMarketPlace__NotDeterminedPrice();
        }

        s_listNfts[nftAddress][tokenId].price = newPrice;
        emit NftListed(nftAddress, tokenId, newPrice);
    }

    function withDrawProceed() external payable {
        uint256 amount = s_proceed[msg.sender];

        if (amount <= 0) {
            revert NftMarketPlace__DoNotHavebalanceToWithDraw();
        }

        s_proceed[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");

        if (!success) {
            revert NftMarketPlace__Transactionfasild();
        }
    }

    // getFunstions

    function gatOwnerOfNtf(
        address nftAddress,
        uint256 tokenId
    ) public view returns (address) {
        return s_listNfts[nftAddress][tokenId].seller;
    }

    function getListing(
        address nftAddress,
        uint256 tokenId
    ) public view returns (Listing memory) {
        return s_listNfts[nftAddress][tokenId];
    }

    function getSellerBalance(address seller) public view returns (uint256) {
        return s_proceed[seller];
    }
}

// listNtf
// buyNft
// cancleListed
// updateListed
// Withdraw