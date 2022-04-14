// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";

contract Marketplace is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _orderIds;
    Counters.Counter private _ordersSold;
    address payable owner;
    uint256 listingPrice = 0.1 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    /**
     @param Fixed 固定价格
     @param Bid   拍卖
     */
    enum OrderType {
        Fixed,
        Bid
    }

    struct Order {
        uint256 orderId;
        OrderType orderType;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        uint256 endTime;
    }

    struct PlaceBidItem {
        address owner;
        uint256 createTime;
        uint256 price;
    }

    mapping(uint256 => Order) private _idToOrder;
    mapping(uint256 => PlaceBidItem[]) private _placeBidHistory;

    event OrderCreated(
        uint256 indexed orderId,
        OrderType orderType,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        uint256 endTime
    );

    event placeBidCreated(
        uint256 indexed orderId,
        address owner,
        uint256 createTime,
        uint256 price
    );

    event UpdateOrderEndTime(uint256 endTime);

    modifier checkOrderIdExists(uint256 orderId) {
        require(_idToOrder[orderId].orderId > 0, "order id does not exist.");
        _;
    }

    modifier onlyFixedOrder(uint256 orderId) {
        require(
            _idToOrder[orderId].orderType == OrderType.Fixed,
            "Please use Fixed to trade this order."
        );
        _;
    }

    modifier onlyBidOrder(uint256 orderId) {
        require(
            _idToOrder[orderId].orderType == OrderType.Bid,
            "Please use Bid to trade this order."
        );
        _;
    }

    modifier onlyActiveOrder(uint256 orderId) {
        require(
            _idToOrder[orderId].endTime > block.timestamp,
            "This order has ended."
        );
        _;
    }

    modifier onlyCloseOrder(uint256 orderId) {
        require(
            block.timestamp > _idToOrder[orderId].endTime,
            "The current order is not closed."
        );
        _;
    }

    function addOrderToMarket(
        OrderType orderType,
        address nftContract,
        uint256 tokenId,
        uint256 price,
        uint256 endMinutes
    ) public payable nonReentrant {
        require(price > listingPrice, "Price must be at least 0.1 ether");

        _orderIds.increment();
        uint256 orderId = _orderIds.current();

        uint256 endTime = block.timestamp + endMinutes * 1 minutes;

        _idToOrder[orderId] = Order(
            orderId,
            orderType,
            nftContract,
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            endTime
        );

        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);

        emit OrderCreated(
            orderId,
            orderType,
            nftContract,
            tokenId,
            msg.sender,
            address(0),
            price,
            endTime
        );
    }

    function sellOrderAndTransferOwnership(uint256 orderId)
    public
    payable
    nonReentrant
    checkOrderIdExists(orderId)
    onlyFixedOrder(orderId)
    onlyActiveOrder(orderId)
    {
        Order memory order = _idToOrder[orderId];
        require(
            msg.value == order.price,
            "Please submit the asking price in order to complete the purchase"
        );

        _idToOrder[orderId].seller.transfer(msg.value - listingPrice);
        IERC721(_idToOrder[orderId].nftContract).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
        _idToOrder[orderId].owner = payable(msg.sender);
        _ordersSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function placeBid(uint256 orderId, uint256 price)
    public
    nonReentrant
    checkOrderIdExists(orderId)
    onlyBidOrder(orderId)
    onlyActiveOrder(orderId)
    {
        require(msg.sender.balance > price, "Insufficient available balance.");

        Order memory order = _idToOrder[orderId];

        uint256 maxPrice = order.price;
        if (_placeBidHistory[orderId].length > 0) {
            uint256 historyIndex = _getMaxPricePlaceBidHistoryId(orderId);
            maxPrice = _placeBidHistory[orderId][historyIndex].price;
        }
        require(
            price > maxPrice,
            "The current price is less than the current high price."
        );

        uint256 nowTime = block.timestamp;

        PlaceBidItem memory item = PlaceBidItem(msg.sender, nowTime, price);

        _placeBidHistory[orderId].push(item);

        if ((nowTime + 5 minutes) > order.endTime) {
            uint256 newEndTime = order.endTime + 5 minutes;
            _idToOrder[orderId].endTime = newEndTime;
            emit UpdateOrderEndTime(newEndTime);
        }

        emit placeBidCreated(orderId, msg.sender, nowTime, price);
    }

    function _getMaxPricePlaceBidHistoryId(uint256 orderId)
    internal
    view
    returns (uint256)
    {
        PlaceBidItem[] memory historys = _placeBidHistory[orderId];

        uint256 maxHistoryIndex = 0;

        for (uint256 i = 1; i < historys.length; i++) {
            if (historys[i].price > historys[maxHistoryIndex].price) {
                maxHistoryIndex = i;
            }
        }

        return maxHistoryIndex;
    }

    function claimOrderAndTransferOwnership(uint256 orderId)
    public
    payable
    nonReentrant
    checkOrderIdExists(orderId)
    onlyBidOrder(orderId)
    onlyCloseOrder(orderId)
    {
        Order memory order = _idToOrder[orderId];

        require(
            _placeBidHistory[orderId].length > 0,
            "There are no user bids for this order."
        );

        uint256 maxHistoryIndex = _getMaxPricePlaceBidHistoryId(orderId);

        require(
            msg.sender == _placeBidHistory[orderId][maxHistoryIndex].owner,
            "The current user did not win the bid."
        );

        require(
            msg.value == _placeBidHistory[orderId][maxHistoryIndex].price,
            "Please submit the asking price in order to complete the purchase."
        );

        _idToOrder[orderId].seller.transfer(msg.value - listingPrice);
        IERC721(_idToOrder[orderId].nftContract).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
        _idToOrder[orderId].owner = payable(msg.sender);
        _ordersSold.increment();
        payable(owner).transfer(listingPrice);
    }

    function isClaimOrder(uint256 orderId)
    public
    view
    checkOrderIdExists(orderId)
    onlyBidOrder(orderId)
    onlyCloseOrder(orderId)
    returns (bool)
    {
        if (_placeBidHistory[orderId].length == 0) {
            return false;
        }

        uint256 maxHistoryIndex = _getMaxPricePlaceBidHistoryId(orderId);
        return _placeBidHistory[orderId][maxHistoryIndex].owner == msg.sender;
    }

    function getPlaceBidHistory(uint256 orderId)
    public
    view
    checkOrderIdExists(orderId)
    onlyBidOrder(orderId)
    returns (PlaceBidItem[] memory)
    {
        return _placeBidHistory[orderId];
    }

    function cancelOrder(uint256 orderId)
    public
    payable
    nonReentrant
    checkOrderIdExists(orderId)
    onlyCloseOrder(orderId)
    {
        Order memory order = _idToOrder[orderId];
        IERC721(order.nftContract).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
    }

    function getOrderById(uint256 orderId)
    public
    view
    checkOrderIdExists(orderId)
    returns (Order memory)
    {
        return _idToOrder[orderId];
    }

    function getUnsoldOrders() public view returns (Order[] memory) {
        uint256 orderCount = _orderIds.current();
        uint256 unsoldOrderCount = _orderIds.current() - _ordersSold.current();
        uint256 currentIndex = 0;

        Order[] memory orders = new Order[](unsoldOrderCount);
        for (uint256 i = 0; i < orderCount; i++) {
            if (_idToOrder[i + 1].owner == address(0)) {
                uint256 currentId = i + 1;
                Order memory currentOrder = _idToOrder[currentId];
                orders[currentIndex] = currentOrder;
                currentIndex += 1;
            }
        }

        return orders;
    }

    function getOrdersByOwner() public view returns (Order[] memory) {
        uint256 totalOrderCount = _orderIds.current();
        uint256 orderCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalOrderCount; i++) {
            if (_idToOrder[i + 1].owner == msg.sender) {
                orderCount += 1;
            }
        }

        Order[] memory orders = new Order[](orderCount);
        for (uint256 i = 0; i < totalOrderCount; i++) {
            if (_idToOrder[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                Order memory currentOrder = _idToOrder[currentId];
                orders[currentIndex] = currentOrder;
                currentIndex += 1;
            }
        }

        return orders;
    }
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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