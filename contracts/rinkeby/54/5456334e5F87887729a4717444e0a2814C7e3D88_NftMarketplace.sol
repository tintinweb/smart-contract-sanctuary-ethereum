// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NftMareketPlace__PriceMustBeAboveZero();
error NftMarketplace__ItemNotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address _nftAddress, uint256 _tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address _nftAddress, uint256 _tokenId);
error NftMarketplace__PriceNotMet(address _nftAddress, uint256 _tokenId);
error NftMarketplace__NoProceeds();

contract NftMarketplace is ReentrancyGuard {
    struct Listing {           
        address seller;        
        uint256 price;         
        // address tokenPrice;     //TODO: integrate chainlink to fetch realtime price
        // string title;       
        // string description; 
        // uint256 dateCreated;
    }                          

    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 tokenId,
        uint256 price
    );

    event ItemCanceled(address _owner, address _nftAddress, uint256 _tokenId);

    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId,
        uint256 price
    );

    /////////////////////
    // Mappings        //
    /////////////////////

    //NFT contract address -> NFT Token ID -> Listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;

    // buyer address to amount received .keep track of sellers earnings
    mapping(address => uint256) private s_proceeds;

    /////////////////////
    // Modifiers       //
    /////////////////////

    modifier notListed(
        address _nftAddress,
        uint256 _tokenId,
        address _owner
    ) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price > 0) {
            revert NftMarketplace__AlreadyListed(_nftAddress, _tokenId);
        }
        _;
    }

    modifier isListed(address _nftAddress, uint256 _tokenId) {
        Listing memory listing = s_listings[_nftAddress][_tokenId];
        if (listing.price <= 0) {
            revert NftMarketplace__NotListed(_nftAddress, _tokenId);
        }
        _;
    }

    modifier isOwner(
        address _nftAddress,
        uint256 _tokenId,
        address _spender
    ) {
        IERC721 nft = IERC721(_nftAddress);
        address owner = nft.ownerOf(_tokenId);
        if (_spender != owner) {
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    /*
     * @notice Method for listing NFT
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     * @param _price sale price for each item
     */
    function listItem(
        address _itemAddress,
        uint256 _tokenId,
        uint256 _price
    )
        external
        notListed(_itemAddress, _tokenId, msg.sender)
        isOwner(_itemAddress, _tokenId, msg.sender)
    {
        if (_price <= 0) {
            revert NftMareketPlace__PriceMustBeAboveZero();
        }
        /*
        There are 2 ways to manage listing:
            1. ❌ Let the contract hold NFT - user wont be able to see NFT in his wallet
            2. ✅ Let the owner hold the NFT, give marketplace (revokable) approval to sell the NFT for them    
                - uses ERC721's `getApproved` method
        */

        IERC721 nft = IERC721(_itemAddress);
        if (nft.getApproved(_tokenId) != address(this)) {
            revert NftMarketplace__ItemNotApprovedForMarketplace();
        }

        //add to the mapping
        s_listings[_itemAddress][_tokenId] = Listing(msg.sender, _price);

        emit ItemListed(address(this), _itemAddress, _tokenId, _price);
    }

    /*
     * @notice Method for cancelling listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     */
    function cancelListing(address _nftAddress, uint256 _tokenId)
        external
        isOwner(_nftAddress, _tokenId, msg.sender)
        isListed(_nftAddress, _tokenId)
    {
        delete (s_listings[_nftAddress][_tokenId]);
        emit ItemCanceled(msg.sender, _nftAddress, _tokenId);
    }

    /*
     * @notice Method for updating listing
     * @param nftAddress Address of NFT contract
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     */
    function updateListing(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _newPrice
    )
        external
        isListed(_nftAddress, _tokenId)
        nonReentrant
        isOwner(_nftAddress, _tokenId, msg.sender)
    {
        s_listings[_nftAddress][_tokenId].price = _newPrice;
        emit ItemListed(msg.sender, _nftAddress, _tokenId, _newPrice);
    }

    /*
     * @notice Method to buy an NFT
     * @param _nftAddress Address of NFT contract
     * @param _tokenId Token ID of NFT
     */
    function buyItem(address _nftAddress, uint256 _tokenId)
        external
        payable
        isListed(_nftAddress, _tokenId)
        nonReentrant
    {
        Listing memory listedItem = s_listings[_nftAddress][_tokenId];
        if (msg.value <= listedItem.price) {
            revert NftMarketplace__PriceNotMet(_nftAddress, _tokenId);
        }

        //update earnings of the seller
        s_proceeds[listedItem.seller] = s_proceeds[listedItem.seller] + msg.value;
        //transfer the NFT asset
        IERC721(_nftAddress).safeTransferFrom(listedItem.seller, msg.sender, _tokenId);
        /*NOTE: here we dont just send the moneyt to seller - because "Pull Over Push" in solidity 
            - i.e. minimize risk in moeny transfer
            - let users push the 'withdraw money' button, instead of sending them directly from this fn
        */
        //unlist this item
        delete (s_listings[_nftAddress][_tokenId]);
        emit ItemBought(msg.sender, _nftAddress, _tokenId, listedItem.price);
    }

    /*
     * @notice Method to withdraw proceedings from sales
     */
    function withdrawProceeds() external {
        //compute all tokens collected by seller
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;

        //make payment
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed!");
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getListing(address nftAddress, uint256 tokenId)
        external
        view
        returns (Listing memory)
    {
        return s_listings[nftAddress][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }
}

/*
    1. `listItem` : List NFTs on the marketplace ✅
    2. `buyItem` : Buy the NFTs ✅
    3. `updateListing` : update price, name, description, img ✅
    4. `cancelListing` : cancel a listing ✅
    5. `withdrawProceeds` : withdraw payment for all my bought NFTs ✅  
*/

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