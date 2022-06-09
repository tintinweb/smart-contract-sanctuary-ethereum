// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AuctionFactory is ReentrancyGuard {
    using Counters for Counters.Counter;
    //static
    Counters.Counter private _auctionIds;

    IERC721 public immutable nft;

    struct Auction {
        address payable seller;
        uint96 bidAmount;
        address bidder;
        uint96 auctionId;
        uint96 reservePrice;
        uint96 tokenId;
    }

    mapping(uint96 => Auction) public auctions;

    event AuctionCreated(
        uint indexed auctionId,
        address payable indexed seller,
        uint indexed tokenId,
        uint reservePrice
    );
    event AuctionResolved(uint auctionId, address buyer, uint price);
    event AuctionCanceled(uint auctionId);
    event Bid(uint auctionId, address bidder, uint bid);

    constructor(address _nft) {
        nft = IERC721(_nft);
    }

    function create(
        uint96 _tokenId,
        uint96 _reservePrice
    ) external payable nonReentrant {
        require(nft.ownerOf(_tokenId) == msg.sender, "You have no this token.");
        _auctionIds.increment();
        uint96 auctionId = uint96(_auctionIds.current());

        Auction storage auction = auctions[auctionId];
        auction.auctionId = auctionId;
        auction.seller = payable(msg.sender);
        auction.tokenId = _tokenId;
        auction.reservePrice = _reservePrice;

        IERC721(nft).transferFrom(auction.seller, address(this), auction.tokenId);

        emit AuctionCreated(
            auctionId,
            payable(msg.sender),
            _tokenId,
            _reservePrice
        );
    }

    function bid(uint96 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != payable(0), "Auction dose not exist.");
        require(auction.bidAmount < msg.value, "Insufficient fund");
        require(auction.seller != payable(msg.sender), "You are seller.");
        uint96 newBid = uint96(msg.value);

        if (auction.bidAmount > 0) {
            payable(auction.bidder).transfer(auction.bidAmount);
        }

        auction.bidAmount = newBid;
        if (msg.sender != auction.bidder) {
            auction.bidder = msg.sender;
        }
        emit Bid(_auctionId, msg.sender, newBid);
    }

    function sell(uint96 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != payable(0), "Auction dose not exist.");
        require(payable(msg.sender) == auction.seller, "You are not a seller.");
        require(auction.bidAmount > 0, "There is no bid.");

        // transfer tokens to highest bidder
        nft.transferFrom(address(this), auction.bidder, auction.tokenId);
        payable(auction.bidder).transfer(auction.bidAmount);

        emit AuctionResolved(_auctionId, auction.bidder, auction.bidAmount);
        delete auctions[_auctionId];
    }

    function cancel(uint96 _auctionId) external nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != payable(0), "Auction dose not exist.");
        require(payable(msg.sender) == auction.seller, "You are not a seller.");

        if (auction.bidAmount > 0)
            payable(auction.bidder).transfer(auction.bidAmount);
        IERC721(nft).transferFrom(address(this), auction.seller, auction.tokenId);

        emit AuctionCanceled(_auctionId);
        delete auctions[_auctionId];
    }

    function buy(uint96 _auctionId) external payable nonReentrant {
        Auction storage auction = auctions[_auctionId];
        require(auction.seller != payable(0), "Auction dose not exist.");
        require(auction.seller != payable(msg.sender), "You are seller.");
        require(auction.reservePrice <= msg.value, "Insufficient fund");

        if (auction.bidAmount > 0) {
            payable(auction.bidder).transfer(auction.bidAmount);
        }

        nft.transferFrom(address(this), msg.sender, auction.tokenId);
        payable(auction.seller).transfer(auction.reservePrice);

        emit AuctionResolved(_auctionId, msg.sender, auction.reservePrice);
        delete auctions[_auctionId];
    }

    function getAuction(uint96 _auctionId) external view returns (Auction memory) {
        require(auctions[_auctionId].seller != payable(0), "Auction dose not exist.");
        return auctions[_auctionId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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