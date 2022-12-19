/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC1155/IERC1155.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;


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

// File: new/CryptoAxusMarkett.sol


pragma solidity ^0.8.4;




error NotApprovedForMarketplace();

contract CryptoAxusMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private marketTokenIds;
    address payable deployer;

    constructor() {
        deployer = payable(msg.sender);
    }

    struct MarketToken {
        uint256 marketTokenId;
        address mintingContract;
        uint256 tokenId;
        uint256 quantity;
        address payable seller;
        address payable buyer;
        uint256 price;
        uint256 listingEndAt;
        bool isSold;
    }

    event MarketTokenListed(
        uint256 indexed marketTokenId,
        address indexed mintingContract,
        uint256 tokenId,
        uint256 quantity,
        address indexed seller,
        uint256 price,
        uint256 listedAt,
        uint256 listingEndAt,
        bool isSold
    );

    event MarketTokenSold(
        uint256 marketTokenId,
        address indexed mintingContract,
        uint256 tokenId,
        uint256 quantity,
        address indexed seller,
        address indexed buyer,
        uint256 price,
        uint256 soldAt,
        bool isSold
    );

    event CanceledListing(
        uint256 marketTokenId,
        address indexed mintingContract,
        uint256 tokenId,
        uint256 quantity,
        address indexed seller,
        uint256 price,
        uint256 canceledAt
    );

    mapping(uint256 => MarketToken) private listings;

    function listToken(
        address mintingContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 listingEndAt
    ) public nonReentrant {
        require(
            price > 0,
            "CryptoAxusMarket:: Price is not valid for listings."
        );
        if (!IERC1155(mintingContract).isApprovedForAll(msg.sender, address(this))) {
            revert NotApprovedForMarketplace();
        }
        marketTokenIds.increment();

        listings[marketTokenIds.current()] = MarketToken(
            marketTokenIds.current(),
            mintingContract,
            tokenId,
            quantity,
            payable(msg.sender),
            payable(address(0)),
            price,
            listingEndAt,
            false
        );

        emit MarketTokenListed(
            marketTokenIds.current(),
            mintingContract,
            tokenId,
            quantity,
            msg.sender,
            price,
            block.timestamp,
            listingEndAt,
            false
        );
    }

    function saleToken(
        uint256 marketTokenId,
        uint256 quantity,
        bytes memory data
    ) public payable nonReentrant {
        MarketToken memory listing = listings[marketTokenId];
        require(
            msg.value == listing.price * quantity,
            "CryptoAxusMarket:: Sent amount not equal to asking price."
        );

        require(
            block.timestamp <= listing.listingEndAt,
            "CryptoAxusMarket:: Listing time expired."
        );
        require(
            quantity <= listing.quantity,
            "CryptoAxusMarket:: Claimed quantity not valid."
        );
        require(
            address(0) != listing.seller,
            "CryptoAxusMarket:: Nft not listed."
        );

        IERC1155(listing.mintingContract).safeTransferFrom(
            listing.seller,
            msg.sender,
            listing.tokenId,
            quantity,
            data
        );
        
        payable(listing.seller).transfer(msg.value);
        uint256 newQuantity = listing.quantity - quantity;
        listings[marketTokenId].quantity = newQuantity;
        emit MarketTokenSold(
            marketTokenId,
            listing.mintingContract,
            listing.tokenId,
            quantity,
            listing.seller,
            msg.sender,
            listing.price,
            block.timestamp,
            true
        );
    }

    function cancelListing(uint256 marketTokenId) public {
        MarketToken memory listing = listings[marketTokenId];
        require(
            listing.price > 0,
            "CryptoAxusMarket:: nft not listed for sale."
        );
        require(
            listings[marketTokenId].quantity > 0,
            "CryptoAxusMarket:: nft not listed for sale."
        );
        require(
            block.timestamp <= listing.listingEndAt,
            "CryptoAxusMarket:: Listing time expired."
        );
        require(
            listing.seller == msg.sender,
            "CryptoAxusMarket:: you're not the seller."
        );
        listings[marketTokenId].price = 0;
        listings[marketTokenId].seller = payable(address(0));
        listings[marketTokenId].quantity = 0;

        emit CanceledListing(
            marketTokenId,
            listing.mintingContract,
            listing.tokenId,
            listing.quantity,
            listing.seller,
            listing.price,
            block.timestamp
        );
    }
}