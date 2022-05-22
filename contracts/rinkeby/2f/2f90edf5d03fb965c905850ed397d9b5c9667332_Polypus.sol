/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.14;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// improvement suggestions :
// - switch to ERC1155
// - use an abstraction to support sub-collections, fungibles & ERC1155
// - use a red-black binary tree
// - optimize
// - use NFTs to represent positions
// - use custom errors
// - use wad or ray for valueToLoan
// - rename valueToLoan
// - use only singular for mappings
// - borrow less than full nft value
// - borrow from multiple markets at once
// - change Storage contract name to name not confusing with parameter type
// - create solhint plugin to disallow more than 100-lines files
// - allow callback on transfer (ofc strict reentrency checks to do)
// - add natspec to every func and contract
// - use ERC721's onERC721Received hook to auto borrow on transfer

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

interface ICEth {
    function mint() external payable;

    function redeemUnderlying(uint256) external returns (uint256);
}

/// @notice config constants for Polypus
abstract contract Config {
    /// RINKEBY ///
    ICEth internal constant CETH =
        ICEth(0xd6801a1DfFCd0a410336Ef88DeF4320D6DF1883e);
}

uint256 constant RAY = 1e27;
uint256 constant WAD = 1 ether;

/// @notice half of an order book, only loan offers
/// @notice made by suppliers for borrowers
/// @dev this is a double-linked list
struct OfferBook {
    bool isActive;
    mapping(uint256 => Offer) offer;
    uint256 firstId;
    uint256 numberOfOffers;
    mapping(address => uint256) offerIdOf;
    uint256 available;
    // mapping(address => BorrowerPosition) borrowerPositionOf;
}

/// @notice loan offer of `supplier`
struct Offer {
    bool isRemoved;
    uint256 amount;
    uint256 valueToLoan;
    uint256 nextId;
    uint256 prevId;
    address supplier;
}

/// @notice 27-decimals fixed-point number
/// @dev this struct must be used systematically to avoid confusions
struct Ray {
    uint256 ray;
}

/// @notice amount or valueToLoan is out of range
error valueOutOfRange();
error alreadyRemoved();
error removeNonExistentOffer();
error unavailableMarket();
error insertForExistentSupplier();
error etherTransferFailed();
error notEnoughLiquidityAvailable();

/// @notice Storage for Polypus protocol
abstract contract Storage {
    uint256 public numberOfBooks;
    uint256 public minimumDepositableValue;
    uint256 public minimumValueToLoan;
    uint256 public loanDuration;

    /// @dev asset (nft) => OfferBook
    mapping(IERC721 => OfferBook) public bookOf;

    constructor() {
        minimumDepositableValue = 1 ether / 100; // 0.01
        minimumValueToLoan = 0.005 ether;
        loanDuration = 2 weeks;
    }
}

library WadRayMath {
    function mul(Ray memory a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a.ray * b.ray) / RAY});
    }

    function div(Ray memory a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a.ray * RAY) / b.ray});
    }

    /// @notice returns a WAD
    function mulByWad(Ray memory a, uint256 b) internal pure returns (uint256) {
        return (a.ray * b) / RAY;
    }

    /// @notice is `a` less than `b`
    function lt(Ray memory a, Ray memory b) internal pure returns (bool) {
        return a.ray < b.ray;
    }

    /// @notice is `a` greater or equal to `b`
    function gte(Ray memory a, Ray memory b) internal pure returns (bool) {
        return a.ray >= b.ray;
    }

    function divWadByRay(uint256 a, Ray memory b)
        internal
        pure
        returns (Ray memory)
    {
        return Ray({ray: (a * (RAY * RAY)) / (b.ray * WAD)});
    }

    function divToRay(uint256 a, uint256 b) internal pure returns (Ray memory) {
        return Ray({ray: (a * RAY) / b});
    }
}

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// compiler doesn't allow visibility on free functions
/* solhint-disable func-visibility */

/// @notice places the offer in the book sorted from best to worst offer
function insertLogic(
    OfferBook storage book,
    uint256 amount,
    uint256 valueToLoan
) returns (uint256 newId) {
    uint256 firstId = book.firstId;
    uint256 cursor = firstId;
    newId = ++book.numberOfOffers; // id 0 is reserved to null
    book.offer[newId].amount = amount;
    book.offer[newId].valueToLoan = valueToLoan;
    uint256 prevId = cursor;

    while (book.offer[cursor].valueToLoan >= valueToLoan) {
        prevId = cursor;
        cursor = book.offer[cursor].nextId;
    }
    if (cursor == firstId) {
        insertAsFirst(book, newId, cursor);
    } else {
        insertBetween(book, newId, prevId, cursor);
    }
}

/// @notice inserts the id as the best offer in the book
function insertAsFirst(
    OfferBook storage book,
    uint256 newId,
    uint256 nextId
) {
    book.firstId = newId;
    book.offer[newId].nextId = nextId;
    if (nextId != 0) {
        book.offer[nextId].prevId = newId;
    }
}

/// @notice inserts `newId` between `prevId` and `nextId`
function insertBetween(
    OfferBook storage book,
    uint256 newId,
    uint256 prevId,
    uint256 nextId
) {
    if (nextId != 0) {
        book.offer[nextId].prevId = newId;
    }
    book.offer[newId].nextId = nextId;
    book.offer[newId].prevId = prevId;
    book.offer[prevId].nextId = newId;
}

/* solhint-disable func-visibility */

library OfferBookLib {
    /// @return newId the id of the newly created offer
    /// @dev amount and valueToLoan must have been checked before calling
    /// @dev amount and valueToLoan must both be above 0
    function insert(
        OfferBook storage book,
        uint256 amount,
        uint256 valueToLoan,
        address supplier
    ) external returns (uint256 newId) {
        if (amount == 0 || valueToLoan == 0) {
            revert valueOutOfRange();
        }
        if (book.offerIdOf[supplier] != 0) {
            revert insertForExistentSupplier();
        }

        newId = insertLogic(book, amount, valueToLoan);
        book.offer[newId].supplier = supplier;
        book.available += amount;
    }

    /// @notice removes the offer from the book
    function remove(OfferBook storage book, uint256 offerId) external {
        if (offerId > book.numberOfOffers) {
            revert removeNonExistentOffer();
        }
        if (book.offer[offerId].isRemoved) {
            revert alreadyRemoved();
        }

        book.offer[offerId].isRemoved = true;
        book.offerIdOf[book.offer[offerId].supplier] = 0;
        uint256 nextId = book.offer[offerId].nextId;
        uint256 prevId = book.offer[offerId].prevId;

        if (offerId == book.firstId) {
            book.firstId = nextId;
        }
        if (prevId != 0) {
            book.offer[prevId].nextId = nextId;
        }
        if (nextId != 0) {
            book.offer[nextId].prevId = prevId;
        }

        book.available -= book.offer[offerId].amount;
    }

    /// @notice changes the amount of an update, considers it as a new offer
    /// @dev as ordering depends on valueToLoan only,
    /// @dev it doesn't need to be redone
    function updateAmount(
        OfferBook storage book,
        uint256 newAmount,
        uint256 id
    ) external {
        uint256 newId = ++book.numberOfOffers;

        book.offer[newId] = book.offer[id];
        book.offer[id].isRemoved = true;
        book.offer[newId].amount = newAmount;
        book.offer[book.offer[id].prevId].nextId = newId;
        book.offer[book.offer[id].nextId].prevId = newId;
        book.available = book.available - book.offer[id].amount + newAmount;
    }
}

/// @notice all variables needed for the borrow function logic
struct BorrowVars {
    Offer cursor;
    uint256 cursorId;
    Ray collateralToMatch;
    Ray offerValueInAsset;
    uint256 borrowedAmount;
}

/// @notice internal bits of logic for the borrow user interaction
abstract contract BorrowLogic is ERC721Holder, Config {
    using WadRayMath for uint256;
    using WadRayMath for Ray;
    using OfferBookLib for OfferBook;

    /// @notice updates the book and the vars to partially match remaining
    /// @notice assets with the best offer
    function matchAndUpdateOffer(OfferBook storage book, BorrowVars memory vars)
        internal
        returns (BorrowVars memory finalVars)
    {
        uint256 amountTakenFromOffer = vars.offerValueInAsset.mulByWad(
            vars.cursor.amount
        );
        finalVars.borrowedAmount = vars.borrowedAmount + amountTakenFromOffer;
        finalVars.cursor.amount = vars.cursor.amount - amountTakenFromOffer;
        book.updateAmount(finalVars.cursor.amount, vars.cursorId);
        finalVars.collateralToMatch.ray = 0;
    }

    /// @notice transfers the assets from the caller to the contract
    /// @dev caller must have approved the contract
    function takeAssets(IERC721 asset, uint256[] calldata tokenIds) internal {
        for (uint256 i; i < tokenIds.length; i++) {
            asset.transferFrom(msg.sender, address(this), tokenIds[i]);
        }
    }

    /// @notice checks that the market is active and takes the collateral
    function performPreChecks(
        OfferBook storage book,
        IERC721 asset,
        uint256[] calldata tokenIds
    ) internal {
        if (!book.isActive) {
            revert unavailableMarket();
        }

        takeAssets(asset, tokenIds);
    }

    /// @notice sends ETH to caller that is sitting in compound
    function sendEth(uint256 amount) internal {
        CETH.redeemUnderlying(amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice update borrowVars with the new best offer available
    function updateVars(OfferBook storage book, BorrowVars memory vars)
        internal
        view
        returns (BorrowVars memory)
    {
        Offer memory newCursor = book.offer[book.firstId];
        BorrowVars memory newVars = BorrowVars({
            cursor: newCursor,
            cursorId: book.firstId,
            collateralToMatch: vars.collateralToMatch,
            offerValueInAsset: newCursor.amount.divToRay(newCursor.valueToLoan),
            borrowedAmount: vars.borrowedAmount
        });
        return newVars;
    }
}

/// @notice getters for external queries of Polypus internal state
abstract contract Lens is Storage {
    function getOffer(IERC721 asset, uint256 offerId)
        external
        view
        returns (Offer memory)
    {
        return bookOf[asset].offer[offerId];
    }

    function getOfferIdOf(IERC721 asset, address supplier)
        external
        view
        returns (uint256)
    {
        return bookOf[asset].offerIdOf[supplier];
    }
}

/// @notice all entry points of the Polypus protocol
contract Polypus is Storage, Ownable, BorrowLogic, Lens {
    using OfferBookLib for OfferBook;
    using WadRayMath for Ray;
    using WadRayMath for uint256;

    /// ADMIN ///

    /// @notice makes an asset available on the market
    function createMarket(IERC721 asset) external onlyOwner {
        bookOf[asset].isActive = true;
    }

    /// PUBLIC ///

    /// @notice supplies to given market with given value to loan.
    /// @notice updates value to loan and adds the new liquidity.
    function supply(IERC721 asset, uint256 valueToLoan) external payable {
        OfferBook storage book = bookOf[asset];

        supplyChecks(asset, valueToLoan);

        uint256 alreadySupplied;
        uint256 prevOfferId = book.offerIdOf[msg.sender];

        if (prevOfferId != 0) {
            alreadySupplied = book.offer[prevOfferId].amount;
            if (msg.value + alreadySupplied < minimumDepositableValue) {
                revert valueOutOfRange();
            }
            book.remove(prevOfferId);
        } else if (msg.value < minimumDepositableValue) {
            revert valueOutOfRange();
        }

        book.offerIdOf[msg.sender] = book.insert(
            msg.value + alreadySupplied,
            valueToLoan,
            msg.sender
        );
    }

    /// @notice takes assets as collateral and gives
    /// @notice the maximum amount loanable to the caller
    function borrow(IERC721 asset, uint256[] calldata tokenIds)
        external
        returns (uint256)
    {
        OfferBook storage book = bookOf[asset];

        performPreChecks(book, asset, tokenIds);
        BorrowVars memory vars;
        vars.collateralToMatch = Ray({ray: tokenIds.length * RAY});
        do {
            vars = updateVars(book, vars);
            if (vars.cursorId == 0) {
                // reached the end
                revert notEnoughLiquidityAvailable();
            }
            if (vars.collateralToMatch.gte(vars.offerValueInAsset)) {
                book.remove(vars.cursorId);
                vars.collateralToMatch.ray -= vars.offerValueInAsset.ray;
                vars.borrowedAmount += vars.cursor.amount;
            } else {
                // entering this block ends the while loop
                vars = matchAndUpdateOffer(book, vars);
            }
        } while (vars.collateralToMatch.ray > 0);
        sendEth(vars.borrowedAmount);
        return vars.borrowedAmount;
    }

    /// @notice performs initial checks for the supply function
    function supplyChecks(IERC721 asset, uint256 valueToLoan) private {
        OfferBook storage book = bookOf[asset];

        if (valueToLoan < minimumValueToLoan) {
            revert valueOutOfRange();
        }
        if (!book.isActive) {
            revert unavailableMarket();
        }

        // CETH.mint{value: msg.value}();
    }
}