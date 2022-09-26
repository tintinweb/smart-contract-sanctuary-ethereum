// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/IDutchAuction.sol";
import "./Market.sol";

contract DutchAuction is IDutchAuction, Market {

    struct SaleDetail {
        uint256 itemId;
        uint256 duration;
        uint256 startedAt;
        uint256 startingPrice;
        uint256 endingPrice;
    }

    mapping(uint256 => SaleDetail) public saleDetails; // Recording auction details

    constructor(address registry) Market(registry) {
    }

    /**
        Create a new auction item
     */
    function newSale(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 startingPrice,
        uint256 endingPrice,
        address paymentToken
    ) external {

        require(startingPrice >= endingPrice, "starting price smaller than ending price");

        uint256 itemId = IRegistry(registry).createMarketItem(
            tokenContract, tokenId, msg.sender, paymentToken, uint16(SaleType.DUTCH_AUCTION));

        newSaleDetail(itemId, duration, startingPrice, endingPrice);

        // Transfer the token to the market contract during the auction
        try IERC721(tokenContract).transferFrom(msg.sender, address(this), tokenId) {
            emit AuctionCreated(
                itemId,
                duration,
                msg.sender,
                startingPrice,
                endingPrice,
                paymentToken
            );
        } catch Error(string memory _err) {
            clearItem(itemId);
            delete saleDetails[itemId];

            emit Failure(_err);
            revert("token transfer failed");
        }
    }

    /**
        Bid to an item
     */
    function bid(uint256 itemId, uint256 amount) external payable {

        MarketItem memory item = getMarketItem(itemId);

        // Check the item is on auction sale
        require(item.saleType == uint16(SaleType.DUTCH_AUCTION), "not an dutch auction item");

        // Do not allow bidding his own item
        require(item.seller != msg.sender, "can't bid to your own item");

        uint256 price = getCurrentPrice(itemId);
        require(amount >= price, "amount too low");

        //buyMarketItem(itemId, item.paymentToken, offer);

        require(item.saleType == uint16(SaleType.DUTCH_AUCTION), "not dutch auction");

        uint256 tokenId = item.tokenId;
        address tokenContract = item.tokenContract;

        address payable seller = payable(item.seller);

        uint256 saleFee = (price * getMarketFee()) / 1000;

        try IERC721(tokenContract).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId
        ) {
            handlePayment(seller, msg.sender, price, saleFee, item.paymentToken);

            emit AuctionEnded(
                itemId,
                seller,
                msg.sender,
                amount
            );

            clearItem(itemId);
            delete saleDetails[itemId];
        } catch Error(string memory _err) {
            emit Failure(_err);
            revert("token transfer failed");
        }
    }

    /**
        Cancel an auction
     */
    function cancelSale(uint256 itemId) public {
        MarketItem memory item = getMarketItem(itemId);

        // item should be on auction sale
        require(item.saleType == uint(SaleType.DUTCH_AUCTION),"not an auction item");

        // only seller or owner can cancel the auction
        require(msg.sender == item.seller || msg.sender == owner(), "only seller or owner can cancel");

        // return the item to the seller
        IERC721(item.tokenContract).safeTransferFrom(address(this), item.seller, item.tokenId);

        emit AuctionCanceled(
            itemId,
            item.seller
        );

        clearItem(itemId);
        delete saleDetails[itemId];
    }

    /**
        Get the current price while time elapses
     */
    function getCurrentPrice(uint256 itemId) public view returns (uint256) {
        SaleDetail memory auction = saleDetails[itemId];
        require(auction.startedAt > 0, "auction not started");
        uint256 secondsPassed = block.timestamp - auction.startedAt;

        if(secondsPassed >= auction.duration) {
            return auction.endingPrice;
        } else {
            uint256 totalPriceChange = auction.startingPrice - auction.endingPrice;
            uint256 currentPriceChange = totalPriceChange * secondsPassed / auction.duration;
            return auction.startingPrice - currentPriceChange;
        }
    }

    /**
        Create a new auction detail
     */
    function newSaleDetail(
        uint256 itemId,         
        uint256 duration,
        uint256 startingPrice,
        uint256 endingPrice
    ) private {
        saleDetails[itemId] = SaleDetail(
            itemId,
            duration,
            block.timestamp,
            startingPrice,
            endingPrice
        );
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

import "./IMarket.sol";

interface IDutchAuction is IMarket {

    event AuctionCreated(
        uint256 indexed itemId,
        uint256 duration,
        address indexed seller,
        uint256 startingPrice,
        uint256 endingPrice,
        address paymentToken
    );

    event AuctionEnded(
        uint256 indexed itemId,
        address seller,
        address winner,
        uint256 endingPrice
    );

    event AuctionCanceled(
        uint256 indexed itemId,
        address seller
    );

    function newSale(
        address tokenContract,
        uint256 tokenId,
        uint256 duration,
        uint256 startingPrice,
        uint256 endingPrice,
        address paymentToken
    ) external;

    function bid(uint256 itemId, uint256 amount) external payable;

    function cancelSale(uint256 itemId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IRegistry.sol";

contract Market is ReentrancyGuard, Ownable, Pausable {

    address public registry; // Registry is where all the market items are recorded

    /**
        Enum for market types 
        (it can be extended since enum is just uint)
     */
    enum SaleType { SALE, ENGLISH_AUCTION, DUTCH_AUCTION }

    constructor(address registery_) {
        registry = registery_;
    }

    receive() external payable {}

    fallback() external payable {}

    /**
        Set registry address
     */
    function setRegistry(address registry_) external onlyOwner {
        registry = registry_;
    }

    /**
        Pause the market
     */
    function pause() public onlyOwner {
        _pause();
    }

    /**
        Unpause the market
     */
    function unpause() public onlyOwner {
        _unpause();
    }

    /**
        Get the detail of market item from the registry
     */
    function getMarketItem(uint256 itemId) public view returns (MarketItem memory) {
        MarketItem memory item = IRegistry(registry).getMarketItem(itemId);
        require(item.seller != address(0), "item not exist");
        return item;
    }

    /**
        Delete market item from the registry
     */
    function clearItem(uint256 itemId) public {
        IRegistry(registry).deleteMarketItem(itemId);
    }

    /**
        Handle payment
     */
    function handlePayment(
        address seller, 
        address buyer, 
        uint256 price, 
        uint256 saleFee, 
        address paymentToken
    ) internal {
        if (paymentToken == address(0)) {
            (bool success, ) = seller.call{value: price - saleFee}("");
            require(success, "payment failed.");
        } else {
            IERC20(paymentToken).transferFrom(
                buyer,
                address(this),
                saleFee
            );
            IERC20(paymentToken).transferFrom(
                buyer,
                seller,
                price - saleFee
            );
        }
    }

    /**
        Get market fee
     */
    function getMarketFee() public view returns (uint256) {
        return IRegistry(registry).getMarketFee();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IMarket {
    event Failure(string err);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

struct MarketItem {
    uint256 itemId;        // market item id
    address tokenContract; // the address of the token contract
    uint256 tokenId;       // original token id from the token contract
    address seller;
    address paymentToken;  // payment token
    uint16 saleType;     // default type is MARKET
}

interface IRegistry {

    event MarketItemCreated(
        uint256 indexed itemId,
        address indexed tokenContract,
        uint256 indexed tokenId,
        address seller,
        address paymentToken,
        uint16 saleType
    );

    event MarketItemDeleted(
        uint256 indexed itemId
    );


    function createMarketItem(
        address tokenContract, 
        uint256 tokenId,
        address seller,
        address paymentToken,
        uint16 saleType
    ) external returns (uint256);

    function getMarketItem(uint256 itemId) external view returns (MarketItem memory);

    function deleteMarketItem(uint256 itemId) external;

    function getMarketFee() external view returns (uint16);

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