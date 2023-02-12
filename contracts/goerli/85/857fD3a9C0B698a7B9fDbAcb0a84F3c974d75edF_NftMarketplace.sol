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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

error NftMarketplace__PriceMustBeAboveZero();
error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__PriceNotMet(
    address nftAddress,
    uint256 tokenId,
    uint256 price
);
error NftMarketplace__NoProceeds();
error NftMarketplace__TransferFailed();

/**
 * @title NftMarketplace
 * @author jrmunchkin
 * @notice This contract creates a NFT marketplace where any Nft collection can be listed or bought
 * Every user can withdraw the ETH from their sold NFT.
 */
contract NftMarketplace {
    struct Listing {
        uint256 price;
        address seller;
    }
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;

    event NftListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NftBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    event NftCanceled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ProceedsWithdraw(address indexed seller, uint256 amount);

    /**
     * @notice Modifier to check that the NFT has not been already listed
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     */
    modifier notListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price > 0)
            revert NftMarketplace__AlreadyListed(_nftAddress, _tokenId);
        _;
    }

    /**
     * @notice Modifier to check that the NFT belongs to the spender
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @param _spender User who wish to use the NFT
     */
    modifier isOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _spender
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);
        if (_spender != owner) revert NftMarketplace__NotOwner();
        _;
    }

    /**
     * @notice Modifier to check that the NFT has already been listed
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     */
    modifier isListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price <= 0)
            revert NftMarketplace__NotListed(_nftAddress, _tokenId);
        _;
    }

    /**
     * @notice Allow user to list any NFT thanks to the NFT contract address and the token id
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @param _price Price the user wish to sell his NFT
     * @dev emit an event NftListed when the NFT has been listed
     * use modifier notListed to check that the NFT has not been already listed
     * use modifier isOwner to check that the NFT belongs to the user
     */
    function listNft(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _price
    )
        external
        notListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) revert NftMarketplace__PriceMustBeAboveZero();
        IERC721 nft = IERC721(_nftAddress);
        if (nft.getApproved(_tokenId) != address(this))
            revert NftMarketplace__NotApprovedForMarketplace();
        s_listings[_nftAddress][_tokenId] = Listing(_price, msg.sender);
        emit NftListed(msg.sender, _nftAddress, _tokenId, _price);
    }

    /**
     * @notice Allow user to buy any NFT thanks to the NFT contract address and the token id
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @dev emit an event NftBought when the NFT has been bought
     * use modifier isListed to check that the NFT has already been listed
     */
    function buyNft(
        address _nftAddress,
        uint256 _tokenId
    ) external payable isListed(_nftAddress, _tokenId) {
        Listing memory listedItem = s_listings[_nftAddress][_tokenId];
        if (msg.value < listedItem.price)
            revert NftMarketplace__PriceNotMet(
                _nftAddress,
                _tokenId,
                listedItem.price
            );
        s_proceeds[listedItem.seller] =
            s_proceeds[listedItem.seller] +
            msg.value;
        delete (s_listings[_nftAddress][_tokenId]);
        IERC721(_nftAddress).safeTransferFrom(
            listedItem.seller,
            msg.sender,
            _tokenId
        );
        emit NftBought(msg.sender, _nftAddress, _tokenId, listedItem.price);
    }

    /**
     * @notice Allow user to cancel listing of any NFT thanks to the NFT contract address and the token id
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @dev emit an event NftCanceled when the NFT has been canceled
     * use modifier isOwner to check that the NFT belongs to the user
     * use modifier isListed to check that the NFT has already been listed
     */
    function cancelNftListing(
        address _nftAddress,
        uint256 _tokenId
    )
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        delete (s_listings[_nftAddress][_tokenId]);
        emit NftCanceled(msg.sender, _nftAddress, _tokenId);
    }

    /**
     * @notice Allow user to update listing of any NFT thanks to the NFT contract address and the token id
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @param _newPrice New price the user wish to sell his NFT
     * @dev emit an event NftListed when the NFT has been listed
     * use modifier isOwner to check that the NFT belongs to the user
     * use modifier isListed to check that the NFT has already been listed
     */
    function updateNftListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftAddress, _tokenId)
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        if (_newPrice <= 0) revert NftMarketplace__PriceMustBeAboveZero();
        s_listings[_nftAddress][_tokenId].price = _newPrice;
        emit NftListed(msg.sender, _nftAddress, _tokenId, _newPrice);
    }

    /**
     * @notice Allow user to withdraw all the ETH of his sold NFT
     * @dev emit an event proceedsWithdraw when the ETH have been withdraw
     */
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) revert NftMarketplace__NoProceeds();
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) revert NftMarketplace__TransferFailed();
        emit ProceedsWithdraw(msg.sender, proceeds);
    }

    /**
     * @notice Get the listing of any NFT thanks to the NFT contract address and the token id
     * @param _nftAddress Address of the NFT collection
     * @param _tokenId Token id of the NFT item
     * @return listing Listing of the NFT
     */
    function getListing(
        address _nftAddress,
        uint256 _tokenId
    ) external view returns (Listing memory) {
        return s_listings[_nftAddress][_tokenId];
    }

    /**
     * @notice Get the amount of proceeds of a specific user
     * @param _seller Address of the user
     * @return amount Amount to proceed
     */
    function getProceeds(address _seller) external view returns (uint256) {
        return s_proceeds[_seller];
    }
}