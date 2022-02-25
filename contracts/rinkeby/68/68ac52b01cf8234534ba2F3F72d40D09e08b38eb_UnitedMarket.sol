// SPDX-License-Identifier: MIT License
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract UnitedMarket is ReentrancyGuard, Pausable, Ownable {
    mapping(address => bool) addressToSupportedContracts;
    mapping(uint256 => Collection) idToCollection;
    uint256 nbCollections;

    struct Collection {
        uint256 id;
        string name;
        address contractAddress;
        bool activated;
        uint16 royalties; // 4.50% -> 450 -> OS allows 2 digits after comma
        string imageUrl;
        string twitterId;
    }

    struct Offer {
        bool isForSale;
        uint256 collectionId;
        uint256 tokenId;
        address seller;
        uint256 minValue;
        address onlySellTo;
    }

    struct Bid {
        bool hasBid;
        uint256 collectionId;
        uint256 tokenId;
        address bidder;
        uint256 value;
    }

    mapping(uint256 => Offer) public tokenOfferedForSale;
    mapping(uint256 => Bid) public tokenBids;
    mapping(address => uint256) public pendingWithdrawals;

    event TokenOffered(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        uint256 minValue,
        address indexed toAddress
    );
    event TokenBidEntered(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        uint256 value,
        address indexed fromAddress
    );
    event TokenBidWithdrawn(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        uint256 value,
        address indexed fromAddress
    );
    event TokenBought(
        uint256 indexed collectionId,
        uint256 indexed tokenId,
        uint256 value,
        address indexed fromAddress,
        address toAddress
    );
    event TokenNoLongerForSale(
        uint256 indexed collectionId,
        uint256 indexed tokenId
    );

    constructor() {
        nbCollections = 0;
    }

    function pause() public whenNotPaused onlyOwner {
        _pause();
    }

    function unpause() public whenPaused onlyOwner {
        _unpause();
    }

    /* Returns the CryptoTokens contract address currently being used */
    function getCollections() public view returns (Collection[] memory) {
        Collection[] memory arr = new Collection[](nbCollections);
        for (uint256 i = 1; i <= nbCollections; i++) {
            Collection storage c = idToCollection[i];
            arr[i - 1] = c;
        }
        return arr;
    }

    function addCollection(string memory name, address newTokensAddress, uint16 royalties, string memory imageUrl, string memory twitterId)
        public
        onlyOwner
    {
        require(
            !addressToSupportedContracts[newTokensAddress],
            "Contract is already in the list."
        );
        nbCollections++;
        idToCollection[nbCollections] = Collection(
            nbCollections,
            name,
            newTokensAddress,
            true,
            royalties,
            imageUrl,
            twitterId
        );
        addressToSupportedContracts[newTokensAddress] = true;
    }

    /* Allows a CryptoToken owner to offer it for sale */
    function offerTokenForSale(
        uint256 collectionId,
        uint256 tokenId,
        uint256 minSalePriceInWei
    ) public whenNotPaused nonReentrant {
        require(
            idToCollection[collectionId].activated,
            "This collection is not supported."
        );
        require(
            tokenId <
                IERC721Enumerable(idToCollection[collectionId].contractAddress)
                    .totalSupply(),
            "token index not valid"
        );
        require(
            IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                tokenId
            ) == msg.sender,
            "you are not the owner of this token"
        );
        tokenOfferedForSale[tokenId] = Offer(
            true,
            collectionId,
            tokenId,
            msg.sender,
            minSalePriceInWei,
            address(0x0)
        );
        emit TokenOffered(
            collectionId,
            tokenId,
            minSalePriceInWei,
            address(0x0)
        );
    }

    function tokenNoLongerForSale(uint256 collectionId, uint256 tokenId)
        public
        nonReentrant
    {
        require(
            tokenId <=
                IERC721Enumerable(idToCollection[collectionId].contractAddress)
                    .totalSupply(),
            "token index not valid"
        );
        require(
            IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                tokenId
            ) == msg.sender,
            "you are not the owner of this token"
        );
        tokenOfferedForSale[tokenId] = Offer(
            false,
            collectionId,
            tokenId,
            msg.sender,
            0,
            address(0x0)
        );
        emit TokenNoLongerForSale(collectionId, tokenId);
    }

    /* Allows a CryptoToken owner to offer it for sale to a specific address */
    function offerTokenForSaleToAddress(
        uint256 collectionId,
        uint256 tokenId,
        uint256 minSalePriceInWei,
        address toAddress
    ) public whenNotPaused nonReentrant {
        require(tokenId < 10000, "Token id not valid");
        require(
            IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                tokenId
            ) == msg.sender,
            "you are not the owner of this token"
        );
        tokenOfferedForSale[tokenId] = Offer(
            true,
            collectionId,
            tokenId,
            msg.sender,
            minSalePriceInWei,
            toAddress
        );
        emit TokenOffered(collectionId, tokenId, minSalePriceInWei, toAddress);
    }

    /* Allows users to buy a CryptoToken offered for sale */
    function buyToken(uint256 collectionId, uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        require(tokenId < 10000, "token index not valid");
        Offer memory offer = tokenOfferedForSale[tokenId];
        require(offer.isForSale, "token is not for sale"); // token not actually for sale
        require(
            offer.onlySellTo == address(0x0) || offer.onlySellTo == msg.sender,
            "Not possible"
        );

        uint256 royaltiesPrice = 0;
        if (idToCollection[collectionId].royalties > 0) {
            royaltiesPrice = (offer.minValue * idToCollection[collectionId].royalties) / 100;
        }

        require(
            msg.value == offer.minValue + royaltiesPrice,
            "not enough ether"
        ); // Didn't send enough ETH
        address seller = offer.seller;
        require(seller != msg.sender, "seller == msg.sender");
        require(
            seller ==
                IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                    tokenId
                ),
            "seller no longer owner of token"
        ); // Seller no longer owner of token

        tokenOfferedForSale[tokenId] = Offer(
            false,
            collectionId,
            tokenId,
            msg.sender,
            0,
            address(0x0)
        );
        IERC721(idToCollection[collectionId].contractAddress).safeTransferFrom(
            seller,
            msg.sender,
            tokenId
        );
        pendingWithdrawals[seller] += msg.value;
        emit TokenBought(collectionId, tokenId, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = tokenBids[tokenId];
        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            pendingWithdrawals[msg.sender] += bid.value;
            tokenBids[tokenId] = Bid(
                false,
                collectionId,
                tokenId,
                address(0x0),
                0
            );
        }
    }

    /* Allows users to retrieve ETH from sales */
    function withdraw() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    /* Allows users to enter bids for any CryptoToken */
    function enterBidForToken(uint256 collectionId, uint256 tokenId)
        public
        payable
        whenNotPaused
        nonReentrant
    {
        if (tokenId >= 10000) revert("token index not valid");
        if (
            IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                tokenId
            ) == msg.sender
        ) revert("you already own this token");
        if (msg.value == 0) revert("cannot enter bid of zero");
        Bid memory existing = tokenBids[tokenId];
        if (msg.value <= existing.value) revert("your bid is too low");
        if (existing.value > 0) {
            // Refund the failing bid
            pendingWithdrawals[existing.bidder] += existing.value;
        }
        tokenBids[tokenId] = Bid(
            true,
            collectionId,
            tokenId,
            msg.sender,
            msg.value
        );
        emit TokenBidEntered(collectionId, tokenId, msg.value, msg.sender);
    }

    /* Allows CryptoToken owners to accept bids for their Tokens */
    function acceptBidForToken(
        uint256 collectionId,
        uint256 tokenId,
        uint256 minPrice
    ) public whenNotPaused nonReentrant {
        if (tokenId >= 10000) revert("token index not valid");
        if (
            IERC721(idToCollection[collectionId].contractAddress).ownerOf(
                tokenId
            ) != msg.sender
        ) revert("you do not own this token");
        address seller = msg.sender;
        Bid memory bid = tokenBids[tokenId];
        if (bid.value == 0) revert("cannot enter bid of zero");
        if (bid.value < minPrice) revert("your bid is too low");

        address bidder = bid.bidder;
        if (seller == bidder) revert("you already own this token");
        tokenOfferedForSale[tokenId] = Offer(
            false,
            collectionId,
            tokenId,
            bidder,
            0,
            address(0x0)
        );
        uint256 amount = bid.value;
        tokenBids[tokenId] = Bid(false, collectionId, tokenId, address(0x0), 0);
        IERC721(idToCollection[collectionId].contractAddress).safeTransferFrom(
            msg.sender,
            bidder,
            tokenId
        );
        pendingWithdrawals[seller] += amount;
        emit TokenBought(collectionId, tokenId, bid.value, seller, bidder);
    }

    /* Allows bidders to withdraw their bids */
    function withdrawBidForToken(uint256 collectionId, uint256 tokenId)
        public
        nonReentrant
    {
        if (tokenId >= 10000) revert("token index not valid");
        Bid memory bid = tokenBids[tokenId];
        if (bid.bidder != msg.sender)
            revert("the bidder is not message sender");
        emit TokenBidWithdrawn(collectionId, tokenId, bid.value, msg.sender);
        uint256 amount = bid.value;
        tokenBids[tokenId] = Bid(false, collectionId, tokenId, address(0x0), 0);
        // Refund the bid money
        payable(msg.sender).transfer(amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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