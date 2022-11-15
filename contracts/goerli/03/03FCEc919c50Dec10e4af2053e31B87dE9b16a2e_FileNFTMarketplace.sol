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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

error FileNFTMarketplace__PriceNotMet(uint256 tokenId, uint256 price);
error FileNFTMarketplace__NotListed(address seller, uint256 tokenId);
error FileNFTMarketplace__AlreadyListed(address seller, uint256 tokenId);
error FileNFTMarketplace__NoProceeds();
error FileNFTMarketplace__NotApprovedForMarketplace();
error FileNFTMarketplace__ListAmountMustBeAboveZero();
error FileNFTMarketplace__AlreadyHaveThisNFT();

contract FileNFTMarketplace is ReentrancyGuard {
    struct Listing {
        uint256 price;
        uint256 amount;
    }

    event ItemListed(
        address indexed seller,
        uint256 indexed tokenId,
        uint256 price,
        uint256 indexed amount
    );

    event ItemCanceled(address indexed seller, uint256 indexed tokenId);

    event ItemBought(
        address indexed seller,
        uint256 indexed tokenId,
        address buyer,
        uint256 price,
        uint256 indexed amountRemain
    );

    event ItemSoldOut(address indexed seller, uint256 indexed tokenId, address buyer);

    // seller => tokenID => listing
    mapping(address => mapping(uint256 => Listing)) private s_listings;
    mapping(address => uint256) private s_proceeds;
    address immutable i_nftAddress;

    constructor(address nftAddress) {
        i_nftAddress = nftAddress;
    }

    modifier notListed(uint256 tokenId, address spender) {
        Listing memory listing = s_listings[spender][tokenId];
        if (listing.amount > 0) {
            revert FileNFTMarketplace__AlreadyListed(spender, tokenId);
        }
        _;
    }

    modifier isListed(uint256 tokenId, address spender) {
        Listing memory listing = s_listings[spender][tokenId];
        if (listing.amount <= 0) {
            revert FileNFTMarketplace__NotListed(spender, tokenId);
        }
        _;
    }

    modifier AmountChecker(uint256 amount) {
        if (amount <= 0) {
            revert FileNFTMarketplace__ListAmountMustBeAboveZero();
        }
        _;
    }

    /////////////////////
    // Main Functions //
    /////////////////////

    /*
     * @notice Method for listing NFT
     * @param tokenId Token ID of NFT
     * @param price sale price for each item
     * @param listAmount nft amount prepare for sale
     */
    function listItem(
        // address nftAddress,
        uint256 tokenId,
        uint256 price,
        uint256 listAmount
    ) external notListed(tokenId, msg.sender) AmountChecker(listAmount) {
        uint256 nftBalance = getNftBalanceAndGetApproved(msg.sender, tokenId);
        nftBalance = checkHasEnoughNftAmount(nftBalance, listAmount);
        s_listings[msg.sender][tokenId] = Listing(price, nftBalance);
        emit ItemListed(msg.sender, tokenId, price, nftBalance);
    }

    /*
     * @notice Method for cancelling listing
     * @param tokenId Token ID of NFT
     */
    function cancelListing(
        // address nftAddress,
        uint256 tokenId
    ) external isListed(tokenId, msg.sender) {
        delete (s_listings[msg.sender][tokenId]);
        emit ItemCanceled(msg.sender, tokenId);
    }

    /*
     * @notice Method for buying listing
     * @notice Buyer can buy only one piece of NFT at one time.
     * @notice Buyer can buy only if he don't have this NFT.
     * @param seller Address of NFT owner
     * @param tokenId Token ID of NFT
     */

    //For file distribution system, the marketplace only alow buyer to buy only one file-nft each time.
    function buyItem(
        address seller,
        uint256 tokenId
    ) external payable isListed(tokenId, seller) nonReentrant {
        Listing memory listedItem = s_listings[seller][tokenId];
        if (msg.value < listedItem.price) {
            revert FileNFTMarketplace__PriceNotMet(tokenId, listedItem.price);
        }
        uint256 buyerBalance = getNftBalance(msg.sender, tokenId);
        if (buyerBalance > 0) {
            revert FileNFTMarketplace__AlreadyHaveThisNFT();
        }
        s_proceeds[seller] += msg.value;
        if (listedItem.amount == 1) {
            delete (s_listings[seller][tokenId]);
            emit ItemSoldOut(seller, tokenId, msg.sender);
        } else {
            s_listings[seller][tokenId].amount -= 1;
        }
        IERC1155(i_nftAddress).safeTransferFrom(seller, msg.sender, tokenId, 1, "");
        emit ItemBought(seller, tokenId, msg.sender, listedItem.price, listedItem.amount - 1);
    }

    /*
     * @notice Method for updating listing
     * @param tokenId Token ID of NFT
     * @param newPrice Price in Wei of the item
     * @param newAmount adjusted nft amount prepare for sale
     */
    function updateListing(
        uint256 tokenId,
        uint256 newPrice,
        uint256 newAmount
    ) external isListed(tokenId, msg.sender) nonReentrant AmountChecker(newAmount) {
        uint256 nftBalance = getNftBalanceAndGetApproved(msg.sender, tokenId);
        nftBalance = checkHasEnoughNftAmount(nftBalance, newAmount);
        s_listings[msg.sender][tokenId] = Listing(newPrice, nftBalance);
        emit ItemListed(msg.sender, tokenId, newPrice, nftBalance);
    }

    /*
     * @notice Method for withdrawing proceeds from sales
     */
    function withdrawProceeds() external nonReentrant {
        uint256 proceeds = s_proceeds[msg.sender];
        if (proceeds <= 0) {
            revert FileNFTMarketplace__NoProceeds();
        }
        s_proceeds[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        require(success, "Transfer failed");
    }

    /////////////////////
    // Utils Functions //
    /////////////////////

    // Return the smaller one of the two balances
    function checkHasEnoughNftAmount(
        uint256 nftBalance,
        uint256 listAmount
    ) internal pure returns (uint256) {
        return (listAmount < nftBalance ? listAmount : nftBalance);
    }

    function getNftBalanceAndGetApproved(
        address someAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        IERC1155 nft = IERC1155(i_nftAddress);
        if (!nft.isApprovedForAll(someAddress, address(this))) {
            revert FileNFTMarketplace__NotApprovedForMarketplace();
        }
        uint256 nftBalance = nft.balanceOf(someAddress, tokenId);
        return nftBalance;
    }

    function getNftBalance(address someAddress, uint256 tokenId) public view returns (uint256) {
        IERC1155 nft = IERC1155(i_nftAddress);
        uint256 nftBalance = nft.balanceOf(someAddress, tokenId);
        return nftBalance;
    }

    /////////////////////
    // Getter Functions //
    /////////////////////

    function getListing(address seller, uint256 tokenId) external view returns (Listing memory) {
        return s_listings[seller][tokenId];
    }

    function getProceeds(address seller) external view returns (uint256) {
        return s_proceeds[seller];
    }

    function getNftAddress() external view returns (address) {
        return i_nftAddress;
    }
}