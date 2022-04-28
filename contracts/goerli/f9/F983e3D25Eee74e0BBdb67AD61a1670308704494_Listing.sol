// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./interfaces/IListingInitializer.sol";
import "./interfaces/IListingFactory.sol";

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Listing is Initializable, IListingInitializer, ReentrancyGuard {
  using Address for address;
  using Address for address payable;

  /**
   * @notice The different statuses an order can have during its course
   */
  enum OrderStatus {
    PLACED,
    DISMISSED,
    ONGOING,
    CANCELLED,
    DELIVERED,
    COMPLETED
  }

  /**
   * @notice The listing's details
   */
  struct ListingDetails {
    string title;
    uint256 price;
    uint256 bondFee;
    uint256 deliveryDays;
    uint256 revisions;
  }

  /**
   * @notice Each order details
   */
  struct Order {
    address payable client;
    OrderStatus status;
    uint256 startedAt;
    uint256 deliveredAt;
    uint256 completedAt;
    uint256 revisionsLeft;
    uint256 tips;
    bool underRevision;
    bool bondFeeWithdrawn;
  }

  /**
   * @notice The % neftie takes from an order
   */
  uint256 public constant ORDER_FEE = 15;

  /**
   * @notice The % neftie takes from a tip
   */
  uint256 public constant TIP_FEE = 5;

  /**
   * @notice The % neftie takes from a cancelled order
   */
  uint256 public constant CANCELLATION_FEE = 10;

  /**
   * @notice Maximum number of days an order can take to complete
   * @dev In days
   */
  uint256 public constant MAX_DELIVERY_DAYS = 10;

  /**
   * @notice Number of days the client has to request a revision after an order is delivered
   * @dev In days
   */
  uint256 public constant REVISION_TIMESPAN = 3 days;

  /**
   * @notice Number of days the client has to request a revision after an order is delivered
   * @dev In days
   */
  uint256 public constant WITHDRAW_TIMESPAN = 7 days;

  /**
   * @notice The factory used to create this contract
   */
  IListingFactory public immutable listingFactory;

  /**
   * @notice The owner of the contract (the seller)
   */
  address payable public seller;

  /**
   * @notice The listing's details
   */
  ListingDetails public listing;

  /**
   * @notice To keep track of the latest count and create
   * order ids
   */
  uint256 public lastOrderCount = 0;

  /**
   * @notice Map of orders indexed by the order id
   */
  mapping(bytes32 => Order) public orders;

  /**
   * @notice When an order is placed and is waiting for
   * the seller approval
   */
  event OrderPlaced(
    bytes32 indexed orderId,
    address indexed client,
    OrderStatus status,
    uint256 startedAt,
    uint256 revisionsLeft
  );

  /**
   * @notice When an order is approved by the seller
   */
  event OrderApproved(bytes32 indexed orderId);

  /**
   * @notice When an order is dismissed by either the seller or the client
   */
  event OrderDismissed(bytes32 indexed orderId, address author);

  /**
   * @notice When an order is cancelled
   */
  event OrderCancelled(bytes32 indexed orderId, address author);

  /**
   * @notice When an order is delivered
   */
  event OrderDelivered(bytes32 indexed orderId);

  /**
   * @notice When a revision is requested
   */
  event RevisionRequested(bytes32 indexed orderId);

  /**
   * @notice When a tip is sent to the seller
   */
  event Tip(bytes32 indexed orderId, uint256 amount);

  /**
   * @notice When the seller withdraws funds from the contract
   */
  event FundsWithdrawn(bytes32 indexed orderId);

  /**
   * @notice When the client withdraws the bond fee
   */
  event BondFeeWithdrawn(bytes32 indexed orderId);

  /**
   * @notice Allow only a moderator defined in the core contract
   */
  modifier onlyModerator() {
    require(
      listingFactory.coreContract().isModerator(msg.sender),
      "Only moderator"
    );
    _;
  }

  /**
   * @notice Allow only the seller (owner of the contract)
   */
  modifier onlySeller() {
    require(msg.sender == seller, "Only seller");
    _;
  }

  /**
   * @notice Allow only a given status
   */
  modifier onlyStatus(bytes32 _orderId, OrderStatus _status) {
    require(orders[_orderId].status == _status, "Not allowed by order status");
    _;
  }

  /**
   * @notice Allow only the client of an order
   */
  modifier onlyClient(bytes32 _orderId) {
    require(orders[_orderId].client == msg.sender, "Only client");
    _;
  }

  /**
   * @notice Allow either the client or the seller
   */
  modifier bothSellerOrClient(bytes32 _orderId) {
    require(
      orders[_orderId].client == msg.sender || seller == msg.sender,
      "Only client or seller"
    );
    _;
  }

  /**
   * @dev Assign the factory address upon creation of the contract
   */
  constructor(address _listingFactoryAddress) {
    require(
      _listingFactoryAddress.isContract(),
      "Listing factory is not a contract"
    );

    listingFactory = IListingFactory(_listingFactoryAddress);
  }

  /**
   * @notice Create a new listing
   * @param _seller Seller and owner of the contract
   * @param _title Title of the listing
   * @param _price Price of the listing
   * @param _bondFee A security fee the seller can set
   * @param _deliveryDays The number of days it takes to complete an order
   */
  function initialize(
    address payable _seller,
    string memory _title,
    uint256 _price,
    uint256 _bondFee,
    uint256 _deliveryDays,
    uint256 _revisions
  ) external override initializer {
    require(
      msg.sender == address(listingFactory),
      "Must be created with the ListingFactory"
    );
    require(bytes(_title).length > 0, "Title is required");
    require(_price > 0, "Price is required");
    require(_bondFee < _price, "Bond fee cannot be higher than price");
    require(_price + _bondFee >= _price, "Price + bond fee must be >= price");
    require(
      _deliveryDays > 0 && _deliveryDays <= MAX_DELIVERY_DAYS,
      "Invalid delivery days"
    );

    seller = _seller;
    listing.title = _title;
    listing.price = _price;
    listing.bondFee = _bondFee;
    listing.deliveryDays = _deliveryDays * 1 days;
    listing.revisions = _revisions;
  }

  /**
   * @notice Allows anyone to place an order request, by paying
   * the price + bond fee upfront
   */
  function placeOrder() external payable nonReentrant {
    require(
      msg.value >= listing.price + listing.bondFee,
      "Value must match listing price + bond fee"
    );
    require(
      msg.sender != seller,
      "A seller cannot place an order in its own listing"
    );

    // Refund any surplus to the client

    uint256 surplus = msg.value - (listing.price + listing.bondFee);

    if (surplus > 0) {
      payable(msg.sender).sendValue(surplus);
    }

    // Create order id

    unchecked {
      lastOrderCount++;
    }

    bytes32 orderId = keccak256(
      abi.encodePacked(lastOrderCount, msg.sender, block.timestamp)
    );

    // Save order

    uint256 current = block.timestamp;

    orders[orderId].client = payable(msg.sender);
    orders[orderId].status = OrderStatus.PLACED;
    orders[orderId].startedAt = current;
    orders[orderId].revisionsLeft = listing.revisions;
    orders[orderId].underRevision = false;
    orders[orderId].bondFeeWithdrawn = false;

    emit OrderPlaced(
      orderId,
      msg.sender,
      OrderStatus.PLACED,
      current,
      listing.revisions
    );
  }

  /**
   * @notice Seller can approve an order in status PLACED
   */
  function approveOrder(bytes32 _orderId)
    external
    onlySeller
    onlyStatus(_orderId, OrderStatus.PLACED)
  {
    orders[_orderId].status = OrderStatus.ONGOING;

    emit OrderApproved(_orderId);
  }

  /**
   * @notice Seller or client can dismiss an order request before it is
   * approved and the client will be refunded the price and bond fee.
   */
  function dismissOrder(bytes32 _orderId)
    external
    bothSellerOrClient(_orderId)
    onlyStatus(_orderId, OrderStatus.PLACED)
  {
    orders[_orderId].status = OrderStatus.DISMISSED;
    _refundClient(_orderId);
    emit OrderDismissed(_orderId, msg.sender);
  }

  /**
   * @notice Both the seller or the client can cancel an order any time, but there will
   * be different outcomes depending on who cancels it.
   *
   * If the order is cancelled by the seller:
   *   Client is refunded both the price and the bond fee
   *
   * If the order is cancelled by the client:
   *   If the deadline has not been reached, client is refunded the 90% of the price as a penalty
   *   for cancelling and the seller receives the bond fee. The remaining 10% is transferred
   *   to neftie's vault.
   *   If the order is past due, then the seller gets a full refund without any penalty.
   */
  function cancelOrder(bytes32 _orderId)
    external
    bothSellerOrClient(_orderId)
    onlyStatus(_orderId, OrderStatus.ONGOING)
  {
    orders[_orderId].status = OrderStatus.CANCELLED;

    if (msg.sender == seller || isOrderPastDue(_orderId)) {
      // Order was cancelled by seller or was past due
      _refundClient(_orderId);
    } else {
      // Order was cancelled by the client or was not past due
      seller.sendValue(listing.bondFee);

      uint256 penalty = (listing.price * CANCELLATION_FEE) / 100;
      orders[_orderId].client.sendValue(listing.price - penalty);
      _sendToVault(penalty);
    }

    emit OrderCancelled(_orderId, msg.sender);
  }

  /**
   * @notice Seller can mark the order as delivered
   * when they are done. To prevent fraud, funds are kept for x days
   * before they can be withdrawn in order to allow for disputes after
   * the delivery. Also, the client can only request revisions before
   * a specified number of days after the delivery.
   */
  function deliverOrder(bytes32 _orderId)
    external
    onlySeller
    onlyStatus(_orderId, OrderStatus.ONGOING)
  {
    orders[_orderId].status = OrderStatus.DELIVERED;
    orders[_orderId].deliveredAt = block.timestamp;
    orders[_orderId].underRevision = false;

    emit OrderDelivered(_orderId);
  }

  /**
   * @notice Client can request a revision if there are any left.
   * @dev Details are kept off-chain.
   */
  function requestRevision(bytes32 _orderId)
    external
    onlyClient(_orderId)
    onlyStatus(_orderId, OrderStatus.DELIVERED)
  {
    require(orders[_orderId].revisionsLeft > 0, "No revisions left");
    require(
      block.timestamp <= orders[_orderId].deliveredAt + REVISION_TIMESPAN,
      "Revision timespan has passed"
    );

    orders[_orderId].underRevision = true;
    orders[_orderId].status = OrderStatus.ONGOING;

    unchecked {
      orders[_orderId].revisionsLeft--;
    }

    emit RevisionRequested(_orderId);
  }

  /**
   * @notice Client can tip the seller once an order is delivered as many
   * times as they want. Neftie takes a cut.
   */
  function tipSeller(bytes32 _orderId)
    external
    payable
    onlyClient(_orderId)
    onlyStatus(_orderId, OrderStatus.DELIVERED)
  {
    require(msg.value > 0, "Tip must be greater than 0");

    uint256 cut = (msg.value * TIP_FEE) / 100;

    _sendToVault(cut);

    orders[_orderId].tips += msg.value - cut;

    emit Tip(_orderId, msg.value);
  }

  /**
   * @notice Seller can withdraw the funds associated to an order
   * and client can withdraw the bond fee.
   * Only once x days have passed since it was marked as delivered.
   */
  function withdrawOrderFunds(bytes32 _orderId)
    external
    bothSellerOrClient(_orderId)
    onlyStatus(_orderId, OrderStatus.DELIVERED)
  {
    require(
      block.timestamp > orders[_orderId].deliveredAt + WITHDRAW_TIMESPAN,
      "Cannot withdraw funds yet"
    );

    if (msg.sender == seller) {
      require(
        orders[_orderId].status == OrderStatus.DELIVERED,
        "Not allowed by order status"
      );

      orders[_orderId].status = OrderStatus.COMPLETED;
      orders[_orderId].completedAt = block.timestamp;

      uint256 orderFee = (listing.price * ORDER_FEE) / 100;
      seller.sendValue((listing.price - orderFee) + orders[_orderId].tips);
      _sendToVault(orderFee);

      emit FundsWithdrawn(_orderId);
    } else {
      require(
        orders[_orderId].status == OrderStatus.DELIVERED ||
          orders[_orderId].status == OrderStatus.COMPLETED,
        "Not allowed by order status"
      );
      require(
        orders[_orderId].bondFeeWithdrawn == false,
        "Bond fee already withdrawn"
      );

      orders[_orderId].bondFeeWithdrawn = true;
      seller.sendValue(listing.bondFee);

      emit BondFeeWithdrawn(_orderId);
    }
  }

  /**
   * @notice Returns the payable core contract address
   */
  function getCoreAddress() public returns (address payable coreAddress) {
    coreAddress = payable(address(listingFactory.coreContract()));
  }

  /**
   * @notice Determines if an order is past due
   */
  function isOrderPastDue(bytes32 _orderId) public view returns (bool) {
    return block.timestamp > orders[_orderId].startedAt + listing.deliveryDays;
  }

  /**
   * @notice Refund the client the price and the bond fee
   */
  function _refundClient(bytes32 _orderId) private {
    orders[_orderId].client.sendValue(listing.price);
    orders[_orderId].client.sendValue(listing.bondFee);
  }

  /**
   * @notice Transfer funds to the vault (platform fees)
   */
  function _sendToVault(uint256 amount) private {
    getCoreAddress().sendValue(amount);
  }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface IListingInitializer {
  function initialize(
    address payable _seller,
    string memory _title,
    uint256 _price,
    uint256 _bondFee,
    uint256 _deliveryDays,
    uint256 _revisions
  ) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./ICore.sol";

interface IListingFactory {
  function coreContract() external returns (ICore);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "./IRoles.sol";

interface ICore is IRoles {}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

interface IRoles {
  function isAdmin(address _target) external view returns (bool);

  function isModerator(address _target) external view returns (bool);
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