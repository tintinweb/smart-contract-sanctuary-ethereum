// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MarketplaceV1 is Initializable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _orderIds;
    address payable owner;
    uint256 listingPrice;

    function initialize() public initializer {
        owner = payable(msg.sender);
        listingPrice = 0.1 ether;
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
        address contractAddr;
        uint256 tokenId;
        address payable seller;
        uint256 price;
        uint256 endTime;
    }

    struct Bid {
        address owner;
        uint256 createTime;
        uint256 price;
    }

    mapping(uint256 => Order) private _idToOrder;
    mapping(uint256 => Bid[]) private _orderBidHistory;

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
        address contractAddr,
        uint256 tokenId,
        uint256 price,
        uint256 endMinutes
    ) public payable {
        require(price > listingPrice, "Price must be at least 0.1 ether");

        _orderIds.increment();
        uint256 orderId = _orderIds.current();

        _idToOrder[orderId] = Order(
            orderId,
            orderType,
            contractAddr,
            tokenId,
            payable(msg.sender),
            price,
            block.timestamp + endMinutes * 1 minutes
        );

        IERC721Upgradeable(contractAddr).transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
    }

    function sellOrderAndTransferOwnership(uint256 orderId)
        public
        payable
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
        IERC721Upgradeable(_idToOrder[orderId].contractAddr).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
        payable(owner).transfer(listingPrice);
        delete _idToOrder[orderId];
    }

    function bidderBid(uint256 orderId, uint256 price)
        public
        checkOrderIdExists(orderId)
        onlyBidOrder(orderId)
        onlyActiveOrder(orderId)
    {
        require(msg.sender.balance > price, "Insufficient available balance.");

        Order memory order = _idToOrder[orderId];

        uint256 maxPrice = order.price;
        if (_orderBidHistory[orderId].length > 0) {
            uint256 historyIndex = _getMaxPriceOrderBidHistoryId(orderId);
            maxPrice = _orderBidHistory[orderId][historyIndex].price;
        }
        require(
            price > maxPrice,
            "The current price is less than the current high price."
        );

        uint256 nowTime = block.timestamp;

        Bid memory item = Bid(msg.sender, nowTime, price);

        _orderBidHistory[orderId].push(item);

        if ((nowTime + 5 minutes) > order.endTime) {
            uint256 newEndTime = order.endTime + 5 minutes;
            _idToOrder[orderId].endTime = newEndTime;
        }
    }

    function _getMaxPriceOrderBidHistoryId(uint256 orderId)
        internal
        view
        returns (uint256)
    {
        Bid[] memory historys = _orderBidHistory[orderId];

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
        checkOrderIdExists(orderId)
        onlyBidOrder(orderId)
        onlyCloseOrder(orderId)
    {
        Order memory order = _idToOrder[orderId];

        require(
            _orderBidHistory[orderId].length > 0,
            "There are no user bids for this order."
        );

        uint256 maxHistoryIndex = _getMaxPriceOrderBidHistoryId(orderId);

        require(
            msg.sender == _orderBidHistory[orderId][maxHistoryIndex].owner,
            "The current user did not win the bid."
        );

        require(
            msg.value == _orderBidHistory[orderId][maxHistoryIndex].price,
            "Please submit the asking price in order to complete the purchase."
        );

        _idToOrder[orderId].seller.transfer(msg.value - listingPrice);
        IERC721Upgradeable(_idToOrder[orderId].contractAddr).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
        payable(owner).transfer(listingPrice);

        delete _idToOrder[orderId];
        delete _orderBidHistory[orderId];
    }

    function isClaimOrder(uint256 orderId)
        public
        view
        checkOrderIdExists(orderId)
        onlyBidOrder(orderId)
        returns (bool)
    {
        if (
            _orderBidHistory[orderId].length == 0 ||
            _idToOrder[orderId].endTime > block.timestamp
        ) {
            return false;
        }

        uint256 maxHistoryIndex = _getMaxPriceOrderBidHistoryId(orderId);
        return _orderBidHistory[orderId][maxHistoryIndex].owner == msg.sender;
    }

    function getBidHistory(uint256 orderId)
        public
        view
        checkOrderIdExists(orderId)
        onlyBidOrder(orderId)
        returns (Bid[] memory)
    {
        return _orderBidHistory[orderId];
    }

    function cancelOrder(uint256 orderId)
        public
        payable
        checkOrderIdExists(orderId)
        onlyCloseOrder(orderId)
    {
        Order memory order = _idToOrder[orderId];
        IERC721Upgradeable(order.contractAddr).transferFrom(
            address(this),
            msg.sender,
            order.tokenId
        );
        if (order.orderType == OrderType.Bid) {
            delete _orderBidHistory[orderId];
        }
        delete _idToOrder[orderId];
    }

    function getUnsoldOrders() public view returns (Order[] memory) {
        uint256 totalOrderCount = _orderIds.current();
        uint256 orderCount = 0;
        uint256 currentIndex = 0;
        uint256 newTime = block.timestamp;

        for (uint256 i = 0; i < totalOrderCount; i++) {
            if (_idToOrder[i + 1].endTime > newTime) {
                orderCount += 1;
            }
        }

        Order[] memory orders = new Order[](orderCount);
        for (uint256 i = 0; i < totalOrderCount; i++) {
            Order memory currentOrder = _idToOrder[i + 1];
            if (currentOrder.endTime > newTime) {
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
            if (_idToOrder[i + 1].seller == msg.sender) {
                orderCount += 1;
            }
        }

        Order[] memory orders = new Order[](orderCount);
        for (uint256 i = 0; i < totalOrderCount; i++) {
            Order memory currentOrder = _idToOrder[i + 1];
            if (currentOrder.seller == msg.sender) {
                orders[currentIndex] = currentOrder;
                currentIndex += 1;
            }
        }

        return orders;
    }

    function getOrderByNFTAddressAndTokenID(address _nftAddr, uint256 _tokenId)
        public
        view
        returns (Order memory)
    {
        Order memory order;
        for (uint256 i = _orderIds.current(); i > 0; i--) {
            Order memory findOrder = _idToOrder[i];
            if (
                findOrder.contractAddr == _nftAddr &&
                findOrder.tokenId == _tokenId
            ) {
                order = findOrder;
                break;
            }
        }
        return order;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
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
library CountersUpgradeable {
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

import "../token/ERC721/IERC721Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}