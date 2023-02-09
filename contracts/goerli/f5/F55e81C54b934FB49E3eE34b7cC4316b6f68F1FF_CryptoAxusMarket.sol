// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CryptoAxusAuction is Ownable, ReentrancyGuard {
    // Struct for the auction
    struct Auction {
        address mintingContract;
        address seller;
        uint256 tokenId;
        uint256 quantity;
        uint256 auctionId;
        uint256 highestBid;
        address highestBidder;
        uint256 endingTime;
        bool auctionComplete;
    }

    // Mapping of all active auctions
    mapping(uint256 => Auction) public auctions;

    // Event for when the highest bid is updated
    event NewBidRecieved(
        address indexed mintingContract,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 highestBid,
        address highestBidder,
        uint256 endingTime,
        bool auctionComplete
    );

    // Event for when the auction is complete
    event AuctionCompleted(
        address indexed mintingContract,
        address indexed seller,
        uint256 indexed tokenId,
        uint256 quantity,
        uint256 bid,
        address winner,
        bool auctionComplete
    );

    // Method to start an auction
    function startAuction(
        address _mintingContract,
        uint256 _tokenId,
        uint256 _quantity,
        uint256 _auctionId,
        uint256 _endingTime
    ) public nonReentrant {
        // Create a new auction with the given parameters
        require(
            block.timestamp < _endingTime,
            "CryptoAxusAuction:: Auction End time should be greater than current time."
        );

        Auction memory auction = Auction(
            _mintingContract,
            msg.sender,
            _tokenId,
            _quantity,
            _auctionId,
            0,
            address(0),
            _endingTime,
            false
        );
        // Add the auction to the mapping
        auctions[_auctionId] = auction;
    }

    function bid(uint256 _auctionId)
        public
        payable
        nonReentrant
    {
        // Get the auction from the mapping
        Auction storage auction = auctions[_auctionId];
        // Validate the bid
        require(
            msg.value > auction.highestBid,
            "CryptoAxusAuction:: Requires a higher bid."
        );
        require(
            auction.auctionComplete == false,
            "CryptoAxusAuction:: Auction completed."
        );
        require(
            block.timestamp < auction.endingTime,
            "CryptoAxusAuction:: Auction Ended."
        );

        // Transfer the previous bid back to the previous bidder
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        // Update the auction
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        emit NewBidRecieved(
            auction.mintingContract,
            auction.seller,
            auction.tokenId,
            auction.quantity,
            msg.value,
            msg.sender,
            auction.endingTime,
            false
        );
    }

    function _endAuction(Auction storage auction) internal {
        // Transfer the highest bid to the seller
        if (auction.highestBid > 0) {
            payable(auction.seller).transfer(auction.highestBid);
        }
        // Update the auction
        auction.auctionComplete = true;
        emit AuctionCompleted(
            auction.mintingContract,
            auction.seller,
            auction.tokenId,
            auction.quantity,
            auction.highestBid,
            auction.highestBidder,
            true
        );
    }

    function endAuctionByAuctioner(uint256 _auctionId) public nonReentrant {
        // Get the auction
        Auction storage auction = auctions[_auctionId];
        // Validate the call
        require(
            msg.sender == auction.seller,
            "CryptoAxusAuction:: Your not the auction owner."
        );
        require(
            auction.auctionComplete == false,
            "CryptoAxusAuction:: Auction Completed."
        );

        _endAuction(auction);
    }

    function endAuctionByOwner(uint256 _auctionId)
        public
        onlyOwner
        nonReentrant
    {
        // Get the auction
        Auction storage auction = auctions[_auctionId];
        // Validate the call
        require(
            auction.auctionComplete == false,
            "CryptoAxusAuction:: Auction Completed."
        );

        _endAuction(auction);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./CryptoAxusOffers.sol";

error NotApprovedForMarketplace();

contract CryptoAxusMarket is CryptoAxusOffers, Pausable {
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

    event ethRecieved(
        address walletAddress,
        uint256 amount
    );

    mapping(uint256 => MarketToken) private listings;

    function listToken(
        address mintingContract,
        uint256 tokenId,
        uint256 quantity,
        uint256 price,
        uint256 listingEndAt,
        uint256 marketTokenId
    ) public nonReentrant {
        require(
            price > 0,
            "CryptoAxusMarket:: Price is not valid for listings."
        );
        if (
            !IERC1155(mintingContract).isApprovedForAll(
                msg.sender,
                address(this)
            )
        ) {
            revert NotApprovedForMarketplace();
        }

        listings[marketTokenId] = MarketToken(
            marketTokenId,
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
            marketTokenId,
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

    function cancelListing(uint256 marketTokenId) public nonReentrant {
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

    function safeTransferFrom(
        address mintingContract,
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity,
        bytes memory data
    ) public nonReentrant onlyOwner {
        if (
            !IERC1155(mintingContract).isApprovedForAll(
                from,
                address(this)
            )
        ) {
            revert NotApprovedForMarketplace();
        }

        IERC1155(mintingContract).safeTransferFrom(
            from,
            to,
            tokenId,
            quantity,
            data
        );
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function holdAmount(address walletAddress) public payable {
        emit ethRecieved(walletAddress, msg.value);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./CryptoAxusAuction.sol";

contract CryptoAxusOffers is CryptoAxusAuction {
    // Mapping of tokenID to offers
    mapping(uint256 => mapping(address => mapping(address => uint256)))
        public offers;

    event OfferMade(
        address indexed walletAddress,
        address indexed mintingContract,
        address seller,
        uint256 tokenId,
        uint256 offerAmount
    );
    event OfferCanceled(
        address indexed walletAddress,
        address indexed mintingContract,
        address seller,
        uint256 tokenId,
        uint256 offerAmount
    );
    event OfferAccepted(
        address indexed walletAddress,
        address indexed seller,
        address indexed mintingContract,
        uint256 tokenId,
        uint256 offerAmount
    );

    // Make an offer
    function makeOffer(
        uint256 tokenId,
        address walletAddress,
        address seller,
        address mintingContract
    ) public payable nonReentrant {
        require(msg.value > 0, "CryptoAxusMarket:: Invalid offer amount.");
        offers[tokenId][walletAddress][mintingContract] += msg.value;
        emit OfferMade(walletAddress, mintingContract, seller,  tokenId, msg.value);
    }

    // Cancel an offer
    function cancelOffer(
        uint256 tokenId,
        address walletAddress,
        address seller,
        address mintingContract
    ) public nonReentrant {
        uint256 amount = offers[tokenId][walletAddress][mintingContract];
        require(amount > 0, "CryptoAxusMarket:: Offer not found.");

        _transferAmount(walletAddress, amount);
        offers[tokenId][walletAddress][mintingContract] = 0;
        emit OfferCanceled(walletAddress, mintingContract, seller, tokenId, amount);
    }

    // Accept an offer
    function acceptOffer(
        uint256 tokenId,
        address walletAddress,
        address seller,
        address mintingContract
    ) public nonReentrant {
        uint256 amount = offers[tokenId][walletAddress][mintingContract];

        require(amount > 0, "CryptoAxusMarket:: Offer not found.");

        _transferAmount(seller, amount);
        offers[tokenId][walletAddress][mintingContract] = 0;
        emit OfferAccepted(
            walletAddress,
            seller,
            mintingContract,
            tokenId,
            amount
        );
    }

    // Refund all offers
    function refundAllOffers(
        address[] memory _walletAddresses,
        address _mintingContract,
        uint256 _tokenId
    ) public onlyOwner {
        uint256 gas = gasleft() / _walletAddresses.length;
        for (uint256 i = 0; i < _walletAddresses.length; i++) {
            uint256 offerAmount = offers[_tokenId][_walletAddresses[i]][
                _mintingContract
            ];
            if (offerAmount > 0) {
                _transferAmount(_walletAddresses[i], offerAmount - gas);
                offers[_tokenId][_walletAddresses[i]][_mintingContract] = 0;
            }
        }
    }

    // Transfer an amount from the contract
    function transferAmount(address walletAddress, uint256 amount)
        public
        onlyOwner
    {
        require(amount > 0, "CryptoAxusMarket:: Not enough funds sent.");

        _transferAmount(walletAddress, amount);
    }

    // Helper function to transfer
    function _transferAmount(address walletAddress, uint256 amount) internal {
        (bool sent, bytes memory data) = payable(walletAddress).call{
            value: amount
        }("");
        require(sent, "Failed to transfer amount");
    }
}