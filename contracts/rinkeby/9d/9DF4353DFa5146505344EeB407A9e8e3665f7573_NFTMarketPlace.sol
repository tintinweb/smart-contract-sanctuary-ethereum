// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error NFTMarketPlace__PriceZero();
error NFTMarketPlace__NotApprovedForListing();
error NFTMarketPlace__AlreadyListed(address nftAddress, uint256 tokenId);
error NFTMarketPlace__NotNftOwner(
    address nftAddress,
    uint256 tokenId,
    address spender
);
error NFTMarketPlace__NotEnoughAmountSendToBuyNft(
    address nftAddress,
    address buyer,
    uint256 expectedAmount,
    uint256 recivedAmount
);
error NFTMarketPlace__NotListed(address nftAddress, uint256 tokenId);

error NFTMarketPlace__SellerNotFound(address seller);
error NFTMarketPlace__TransactionFailed();

contract NFTMarketPlace is ReentrancyGuard {
    struct NftListing {
        uint256 price;
        address seller;
    }

    event ItemListed(
        address indexed nftAddress,
        address indexed sender,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemBought(
        address indexed nftAddress,
        address indexed sender,
        uint256 indexed tokenId,
        uint256 price
    );

    event ItemCancelled(
        address indexed nftAddress,
        address indexed sender,
        uint256 indexed tokenId
    );

    mapping(address => mapping(uint256 => NftListing))
        private s_nftAddressToListing;

    //selleraddress => amount earned in nft
    mapping(address => uint256) private s_SellerMappedToAmount;

    constructor() {}

    modifier notAlreadyListed(address nftAddress, uint256 tokenId) {
        uint256 price = s_nftAddressToListing[nftAddress][tokenId].price;
        if (price > 0) {
            revert NFTMarketPlace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isNftOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        if (nft.ownerOf(tokenId) != spender) {
            revert NFTMarketPlace__NotNftOwner(nftAddress, tokenId, spender);
        }
        _;
    }

    modifier isListed(address nftAddress, uint256 tokenId) {
        NftListing memory nftListing = s_nftAddressToListing[nftAddress][
            tokenId
        ];
        if (nftListing.price <= 0) {
            revert NFTMarketPlace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    modifier isSellerExist(address seller) {
        if (s_SellerMappedToAmount[seller] <= 0) {
            revert NFTMarketPlace__SellerNotFound(seller);
        }
        _;
    }

    function ListItem(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        notAlreadyListed(nftAddress, tokenId)
        isNftOwner(nftAddress, tokenId, msg.sender)
    {
        if (price <= 0) {
            revert NFTMarketPlace__PriceZero();
        }

        IERC721 nft = IERC721(nftAddress);
        if (nft.getApproved(tokenId) != address(this)) {
            revert NFTMarketPlace__NotApprovedForListing();
        }

        s_nftAddressToListing[nftAddress][tokenId] = NftListing(
            price,
            msg.sender
        );

        emit ItemListed(nftAddress, msg.sender, tokenId, price);
    }

    function BuyNft(address nftAddress, uint256 tokenId)
        external
        payable
        isListed(nftAddress, tokenId)
        nonReentrant
    {
        NftListing memory nftListing = s_nftAddressToListing[nftAddress][
            tokenId
        ];
        if (msg.value < nftListing.price) {
            revert NFTMarketPlace__NotEnoughAmountSendToBuyNft(
                nftAddress,
                msg.sender,
                nftListing.price,
                msg.value
            );
        }

        //add amount send to seller account mapping
        s_SellerMappedToAmount[nftListing.seller] =
            s_SellerMappedToAmount[nftListing.seller] +
            msg.value;

        //as nft is bought remove it from mapping so others can't buy it
        delete (s_nftAddressToListing[nftAddress][tokenId]);

        //before calling this this contract must be approved to move tokens
        IERC721(nftAddress).safeTransferFrom(
            nftListing.seller,
            msg.sender,
            tokenId
        );

        emit ItemBought(nftAddress, msg.sender, tokenId, nftListing.price);
    }

    function CancelListing(address nftAddress, uint256 tokenId)
        external
        isListed(nftAddress, tokenId)
        isNftOwner(nftAddress, tokenId, msg.sender)
    {
        delete (s_nftAddressToListing[nftAddress][tokenId]);
        emit ItemCancelled(nftAddress, msg.sender, tokenId);
    }

    function UpdateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 price
    )
        external
        isListed(nftAddress, tokenId)
        isNftOwner(nftAddress, tokenId, msg.sender)
    {
        s_nftAddressToListing[nftAddress][tokenId].price = price;
        emit ItemListed(nftAddress, msg.sender, tokenId, price);
    }

    function WithdrawNft() external isSellerExist(msg.sender) nonReentrant {
        uint256 amount = s_SellerMappedToAmount[msg.sender];
        s_SellerMappedToAmount[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) {
            revert NFTMarketPlace__TransactionFailed();
        }
    }

    function getPrice(address nftAddress, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return s_nftAddressToListing[nftAddress][tokenId].price;
    }

    function getSeller(address nftAddress, uint256 tokenId)
        public
        view
        returns (address)
    {
        return s_nftAddressToListing[nftAddress][tokenId].seller;
    }

    function getTotalAmountEarnedFromNFT(address seller)
        public
        view
        returns (uint256)
    {
        return s_SellerMappedToAmount[seller];
    }
}

//Task
/**
 * 1 list nft on nftmarketplace -- that is put it on market place -nftdeployer
 * ---what is need to deploy nft - 1)token id 2)nft price 3)player
 * 2 buy user should be able to buy nft -- any user or nftdeployer
 * 3 cancel/remove nft -- nftdeployer should be able to cancle nft
 * 4 withdraw nftdeployer should be able to withdraw money for his/her nft prceeds
 */
//1:00:26:04

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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