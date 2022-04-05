// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./libraries/EnumerableList.sol";
import "./interfaces/IERC721Verifiable.sol";
import "./commons/Ownable.sol";
import "./commons/Pausable.sol";
import "./commons/ContextMixin.sol";
import "./commons/NativeMetaTransaction.sol";

/**
 * @title MarketplaceV2
 * @notice It is the core contract of the Parcel protocol.



     /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$      
    | $$__  $$ /$$__  $$| $$__  $$ /$$__  $$| $$_____/| $$      
    | $$  \ $$| $$  \ $$| $$  \ $$| $$  \__/| $$      | $$      
    | $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$$$$   | $$      
    | $$____/ | $$__  $$| $$__  $$| $$      | $$__/   | $$      
    | $$      | $$  | $$| $$  \ $$| $$    $$| $$      | $$      
    | $$      | $$  | $$| $$  | $$|  $$$$$$/| $$$$$$$$| $$$$$$$$
    |__/      |__/  |__/|__/  |__/ \______/ |________/|________/



 */
contract MarketplaceV2 is Ownable, Pausable, NativeMetaTransaction {
  using Address for address;
  using SafeERC20 for IERC20;
  using EnumerableList for EnumerableList.AssetList;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @dev Maximum number of assets in an order.
  uint256 public constant MAX_BUNDLE_SIZE = 100;
  /// @dev Unsigned integer value used to extend execution cuts.
  uint256 public constant EXECUTION_CUT_DENOMINATOR = 1000000;

  /// @dev Interface id of ERC721 compatible contracts.
  bytes4 public constant INTERFACE_ID_ERC721 = bytes4(0x80ac58cd);
  /// @dev Interface id of ERC721Verifiable compatible contracts.
  bytes4 public constant INTERFACE_ID_ERC721VERIFIABLE =
    bytes4(keccak256("verifyFingerprint(uint256,bytes)"));

  /**
   * @dev Various statuses of orders.
   *
   * Created  - created orders can be validated, modified or executed
   * Canceled - orders were canceled by the original sellers
   * Executed - orders are executed, cannot be modified or canceled
   */
  enum OrderStatus {
    Created,
    Canceled,
    Executed
  }

  /// @dev Storage structure of an order.
  struct Order {
    address seller; // Address of the seller
    address token; // Address of the ERC20 token to be paid in
    uint256 price; // Amount of token above to be paid
    OrderStatus status; // Status of the order, here for storage packing
    uint64 expiresAt; // Expiration of the order, typed in a smaller integer to save gas
    uint64 lastUpdatedAt; // Last timestamp the order was updated, typed in a smaller integer to save gas
    EnumerableList.AssetList assets; // List of ERC721 compatible assets in the order, typed in a storage mapping
  }

  /// @dev Memory structure of an order, used in the external interfaces.
  struct OrderView {
    OrderStatus status; // Status of the order
    address seller; // Address of the seller
    address token; // Address of the ERC20 token to be paid in
    uint256 price; // Amount of token above to be paid
    uint256 expiresAt; // Expiration of the order
    uint256 lastUpdatedAt; // Last timestamp the order was updated
    Listable.Asset[] assets; // List of ERC721 compatible assets in the order, typed in a dynamic array
  }

  /// @dev Parameter structure relevant to each ERC20 compatible token.
  struct TokenParam {
    uint256 publicationFee; // Amount of token, when the token is used to pay publication fee
    uint256 executionCut; // Percentage of the share that the fee collector takes when an order is executed,
    // multiplied by EXECUTION_CUT_DENOMINATOR
  }

  // Events
  event FeeCollectorSet(
    address indexed oldFeeCollector,
    address indexed newFeeCollector
  );

  /**
   * @notice Event when a token is accepted.
   * isNew - true when the token is newly added in the protocol, otherwise false
   */
  event TokenAccepted(
    address indexed token,
    uint256 publicationFee,
    uint256 executionCut,
    bool isNew
  );

  /**
   * @notice Event when a token is declined.
   * isDeleted - true when the token is actually deleted in the protocol, otherwise false
   */
  event TokenDeclined(address indexed token, bool isDeleted);

  /**
   * @notice Event when a registry is accepted.
   * isNew - true when the registry is newly added in the protocol, otherwise false
   */
  event RegistryAccepted(address indexed registry, bool isNew);

  /**
   * @notice Event when a registry is declined.
   * isDeleted - true when the registry is actually deleted in the protocol, otherwise false
   */
  event RegistryDeclined(address indexed registry, bool isDeleted);

  event OrderCreated(
    uint256 id,
    address indexed seller,
    address token,
    uint256 price,
    uint256 expiresAt,
    Listable.Asset[] assets
  );

  event OrderModified(
    uint256 id,
    address indexed seller,
    address token,
    uint256 price,
    uint256 expiresAt,
    Listable.Asset[] assets
  );

  event OrderCanceled(uint256 id, address indexed seller);

  event OrderExecuted(
    uint256 id,
    address indexed seller,
    address indexed buyer,
    address token,
    uint256 price,
    Listable.Asset[] assets
  );

  /// @dev Address of the fee collector who takes publication and order execution fees.
  address payable public feeCollector;

  /// @dev Set of ERC20 compatible tokens that can be used for paying fees or paying order assets.
  EnumerableSet.AddressSet private acceptedTokens;
  /// @dev Parameters for each token.
  mapping(address => TokenParam) public tokenParams;
  /// @dev Set of ERC721 registries that can be traded in the protocol.
  EnumerableSet.AddressSet private acceptedRegistries;

  /**
   * @dev Array of orders.
   *
   * The elements never be deleted once created, only the status of orders change.
   * The index of each element is the id of the order.
   */
  Order[] private orders;

  // Administrator Operations
  /**
   * @dev Initialize this contract. Acts as a constructor
   *
   * @param _owner             - Owner
   * @param _feeCollector      - Fee collector
   * @param _acceptedToken     - Address of the ERC20 token accepted initially for the protocol
   * @param _publicationFee    - Initial publication fee for the accepted token
   * @param _executionCut      - Initial execution fee for the accepted token
   */
  constructor(
    address _owner,
    address _feeCollector,
    address _acceptedToken,
    uint256 _publicationFee,
    uint256 _executionCut
  ) {
    // EIP712 init
    _initializeEIP712("Parcel Marketplace", "2.0");

    // Address init
    setFeeCollector(_feeCollector);

    // accept initial token and registry
    acceptToken(_acceptedToken, _publicationFee, _executionCut);

    require(_owner != address(0), "New owner is invalid");
    transferOwnership(_owner);
  }

  /**
   * @dev Set the fee collector
   *
   * @param _newFeeCollector - fee collector
   */
  function setFeeCollector(address _newFeeCollector) public onlyOwner {
    require(_newFeeCollector != address(0), "New fee collector is invalid");

    feeCollector = payable(_newFeeCollector);

    emit FeeCollectorSet(feeCollector, _newFeeCollector);
  }

  /**
   * @dev Append a new ERC20 compatible token in the protocol.
   * At the same time, set the relevant parameters.
   * It just updates parameters only and doesn't add a new one if the token is registered already.
   *
   * @param _token          - Address of token, can be an ERC20 contract or a zero address in the case of the native ETH
   * @param _publicationFee - Amount of token that the fee collector takes when the token is used to pay the publication fee
   * @param _executionCut   - Percentage of the share that the fee collector takes when an order is paid in the token,
                            // multiply by EXECUTION_CUT_DENOMINATOR
   */
  function acceptToken(
    address _token,
    uint256 _publicationFee,
    uint256 _executionCut
  ) public onlyOwner {
    require(_token == address(0) || _token.isContract(), "Token is invalid");
    require(
      _executionCut < EXECUTION_CUT_DENOMINATOR,
      "Execution cut is incorrect"
    );

    TokenParam storage tokenParam = tokenParams[_token];
    tokenParam.publicationFee = _publicationFee;
    tokenParam.executionCut = _executionCut;

    bool isNew = acceptedTokens.add(_token);

    emit TokenAccepted(_token, _publicationFee, _executionCut, isNew);
  }

  /**
   * @dev Remove a ERC20 compatible token in the protocol.
   *
   * @param _token          - Address of token
   */
  function declineToken(address _token) public onlyOwner {
    delete tokenParams[_token];
    bool isDeleted = acceptedTokens.remove(_token);

    emit TokenDeclined(_token, isDeleted);
  }

  /**
   * @dev Append a new ERC721 registry in the protocol.
   *
   * @param _registry       - Address of registry
   */
  function acceptRegistry(address _registry) public onlyOwner {
    _requireERC721(_registry);

    bool isNew = acceptedRegistries.add(_registry);

    emit RegistryAccepted(_registry, isNew);
  }

  /**
   * @dev Remove a registry in the protocol.
   *
   * @param _registry       - Address of registry
   */
  function declineRegistry(address _registry) public onlyOwner {
    bool isDeleted = acceptedRegistries.remove(_registry);

    emit RegistryDeclined(_registry, isDeleted);
  }

  /**
   * @dev Pause external activities
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev Allow external activities
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  // Public Functions
  /**
   * @notice Retrieve addresses of tokens that can be used for paying fees or paying order assets.
   *
   * @return tokens         - Array of token addresses
   */
  function availableTokens() public view returns (address[] memory tokens) {
    uint256 length = acceptedTokens.length();
    tokens = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      tokens[i] = acceptedTokens.at(i);
    }
  }

  /**
   * @notice Retrieve addresses of registries that can be trade in the protocol.
   *
   * @return registries     - Array of registry addresses
   */
  function availableRegistries()
    public
    view
    returns (address[] memory registries)
  {
    uint256 length = acceptedRegistries.length();
    registries = new address[](length);
    for (uint256 i = 0; i < length; i++) {
      registries[i] = acceptedRegistries.at(i);
    }
  }

  /**
   * @notice Retrieve the length of orders array.
   * The returned number can be used as a next order number.
   */
  function numberOfOders() public view returns (uint256) {
    return orders.length;
  }

  /**
   * @notice Retrieve order and its' assets.
   * Return the order structure, and the validation.
   *
   * @param _id             - Order id
   * @return orderView      - Order data
   * @return isExecutable   - Order validation, true if the order is valid to be executed, otherwise false
   */
  function orderById(uint256 _id)
    public
    view
    returns (OrderView memory orderView, bool isExecutable)
  {
    orderView = _getOrderView(_id);
    isExecutable = _isExecutableOrder(orderView);
  }

  /**
   * @notice Check if an order is executable.
   *
   * @param _id             - Order id
   * @return                - true if the order is executable, otherwise false
   */
  function isExecutableOrder(uint256 _id) public view returns (bool) {
    return _isExecutableOrder(_getOrderView(_id));
  }

  /**
   * @notice Create an order and appends assets.
   * It doesn't validate anything. Validation will happen on order execution.
   * It takes only the publication fee.
   *
   * @param _token          - Address of the ERC20 token to be paid in
   * @param _price          - Amount of token above to be paid
   * @param _expiresAt      - Expiration of the order
   * @param _assets         - Assets composing the order
   * @param _feeToken       - Address of the ERC20 token used to pay publication fee,
   *                          It can be 0 and msg.value is used, for native ETH.
   */
  function createOrderWithAssets(
    address _token,
    uint256 _price,
    uint256 _expiresAt,
    Listable.Asset[] calldata _assets,
    address _feeToken
  ) external payable whenNotPaused {
    address sender = _msgSender();
    uint256 length = _assets.length;

    require(length <= MAX_BUNDLE_SIZE, "Assets exceeds the limit");
    require(_expiresAt > block.timestamp + 1 minutes, "Expiration is invalid");
    require(acceptedTokens.contains(_feeToken), "Fee token is not accepted");

    // publication fee
    uint256 publicationFee = tokenParams[_feeToken].publicationFee;
    if (publicationFee > 0) {
      if (_feeToken == address(0)) {
        // native ETH
        require(msg.value >= publicationFee, "Publication fee is incorrect");
        feeCollector.transfer(msg.value);
      } else {
        IERC20(_feeToken).safeTransferFrom(
          sender,
          feeCollector,
          publicationFee
        );
      }
    }

    // create order data
    uint256 id = orders.length;
    Order storage order = orders.push();
    // order.status = OrderStatus.Created;
    order.seller = sender;
    order.token = _token;
    order.price = _price;
    order.expiresAt = _safe64(
      _expiresAt,
      "Expiration timestamp exceeds 64 bits"
    );
    order.lastUpdatedAt = _safe64(
      block.timestamp,
      "block timestamp exceeds 64 bits"
    );

    // append assets
    for (uint256 i = 0; i < length; i++) {
      order.assets.add(_assets[i]);
    }

    emit OrderCreated(
      id,
      sender,
      _token,
      _price,
      _expiresAt,
      order.assets.values
    );
  }

  /**
   * @notice Modify an order.
   * Canceled, expired or already executed order cannot be modified.
   *
   * @param _id             - Order id
   * @param _token          - Address of the ERC20 token to be paid in
   * @param _price          - Amount of token above to be paid
   * @param _expiresAt      - Expiration of the order
   */
  function modifyOrderParam(
    uint256 _id,
    address _token,
    uint256 _price,
    uint256 _expiresAt
  ) public whenNotPaused {
    Order storage order = orders[_id]; // reverts when _id exceeds the length
    _requireModifiableOrder(order);
    require(_expiresAt > block.timestamp + 1 minutes, "Expiration is invalid");
    order.token = _token;
    order.price = _price;
    order.expiresAt = _safe64(
      _expiresAt,
      "Expiration timestamp exceeds 64 bits"
    );
    order.lastUpdatedAt = _safe64(
      block.timestamp,
      "block timestamp exceeds 64 bits"
    );

    emit OrderModified(
      _id,
      order.seller,
      _token,
      _price,
      _expiresAt,
      order.assets.values
    );
  }

  /**
   * @notice Modify an order by adding more assets.
   * Canceled, expired or already executed order cannot be modified.
   *
   * @param _id             - Order id
   * @param _token          - Address of the ERC20 token to be paid in
   * @param _price          - Amount of token above to be paid
   * @param _expiresAt      - Expiration of the order
   * @param _assets         - Assets to be added
   */
  function addAssetsInOrder(
    uint256 _id,
    address _token,
    uint256 _price,
    uint256 _expiresAt,
    Listable.Asset[] calldata _assets
  ) external whenNotPaused {
    uint256 length = _assets.length;

    require(length <= MAX_BUNDLE_SIZE, "Assets exceeds the limit");

    Order storage order = orders[_id]; // reverts when _id exceeds the length
    // append assets
    for (uint256 i = 0; i < length; i++) {
      order.assets.add(_assets[i]);
    }
    require(
      order.assets.length() <= MAX_BUNDLE_SIZE,
      "Order size exceeds the limit"
    );

    modifyOrderParam(_id, _token, _price, _expiresAt);
  }

  /**
   * @notice Modify an order by removing some assets.
   * Canceled, expired or already executed order cannot be modified.
   *
   * @param _id             - Order id
   * @param _token          - Address of the ERC20 token to be paid in
   * @param _price          - Amount of token above to be paid
   * @param _expiresAt      - Expiration of the order
   * @param _assets         - Assets to be removed
   */
  function removeAssetsInOrder(
    uint256 _id,
    address _token,
    uint256 _price,
    uint256 _expiresAt,
    Listable.Asset[] calldata _assets
  ) external whenNotPaused {
    uint256 length = _assets.length;

    require(length <= MAX_BUNDLE_SIZE, "Assets exceeds the limit");

    Order storage order = orders[_id]; // reverts when _id exceeds the length
    // remove assets
    for (uint256 i = 0; i < length; i++) {
      order.assets.remove(_assets[i]);
    }

    modifyOrderParam(_id, _token, _price, _expiresAt);
  }

  /**
   * @notice Cancel an order
   * Canceled, expired or already executed order cannot be canceled.
   *
   * @param _id             - Order id
   */
  function cancelOrder(uint256 _id) external whenNotPaused {
    Order storage order = orders[_id]; // reverts when _id exceeds the length
    _requireModifiableOrder(order);
    order.status = OrderStatus.Canceled;
    order.lastUpdatedAt = _safe64(
      block.timestamp,
      "block timestamp exceeds 64 bits"
    );

    emit OrderCanceled(_id, order.seller);
  }

  /**
   * @notice Execute an order
   * Canceled, expired or already executed order cannot be executed.
   *
   * @param _id             - Order id
   * @param _fingerprints   - Array of asset fingerprints
   */
  function executeOrder(uint256 _id, bytes[] memory _fingerprints)
    external
    payable
    whenNotPaused
  {
    address buyer = _msgSender();
    Order storage order = orders[_id]; // reverts when _id exceeds the length
    OrderView memory orderView = _getOrderView(_id);
    address seller = orderView.seller;

    // validate
    require(seller != buyer, "Sender is not allowed");
    require(orderView.status == OrderStatus.Created, "Order is not executable");
    require(block.timestamp < orderView.expiresAt, "Order is expired");
    require(acceptedTokens.contains(orderView.token), "Token is not accepted");
    require(orderView.price > 0, "Price is invalid");

    // update order status
    order.status = OrderStatus.Executed;
    order.lastUpdatedAt = _safe64(
      block.timestamp,
      "block timestamp exceeds 64 bits"
    );

    // process payment
    uint256 price = orderView.price;
    uint256 executionCut = tokenParams[orderView.token].executionCut;
    uint256 feeCollectorShareAmount = (price * executionCut) /
      EXECUTION_CUT_DENOMINATOR;

    if (orderView.token == address(0)) {
      // native ETH
      require(msg.value >= price, "Payment is incorrect");
      if (feeCollectorShareAmount > 0) {
        feeCollector.transfer(feeCollectorShareAmount);
      }
      payable(seller).transfer(price - feeCollectorShareAmount);
    } else {
      IERC20 token = IERC20(orderView.token);
      if (feeCollectorShareAmount > 0) {
        token.safeTransferFrom(buyer, feeCollector, feeCollectorShareAmount);
      }
      token.safeTransferFrom(buyer, seller, price - feeCollectorShareAmount);
    }

    // transfer assets
    uint256 length = orderView.assets.length;
    require(length > 0, "Order has no assets");
    require(length == _fingerprints.length, "Fingerprint length is incorrect");
    for (uint256 i = 0; i < length; i++) {
      Listable.Asset memory asset = orderView.assets[i];
      _requireERC721(asset.registry);
      IERC721Verifiable assetRegistry = IERC721Verifiable(asset.registry);
      uint256 assetId = asset.id;
      if (assetRegistry.supportsInterface(INTERFACE_ID_ERC721VERIFIABLE)) {
        require(
          assetRegistry.verifyFingerprint(assetId, _fingerprints[i]),
          "Fingerprint is invalid"
        );
      }
      require(
        acceptedRegistries.contains(asset.registry),
        "Registry is not accepted"
      );
      address assetOwner = assetRegistry.ownerOf(assetId); // reverts if the asset doesn't exist
      require(assetOwner == seller, "Asset owner is invalid");
      require(
        assetRegistry.getApproved(assetId) == address(this) ||
          assetRegistry.isApprovedForAll(assetOwner, address(this)),
        "Asset is not approved"
      );
      assetRegistry.safeTransferFrom(seller, buyer, assetId);
    }

    emit OrderExecuted(
      _id,
      seller,
      buyer,
      orderView.token,
      orderView.price,
      orderView.assets
    );
  }

  // Internal Methods
  /**
   * @dev Convert an order's storage data to memory data.
   * The memory structure is useful for the public interfaces,
   * because it is using a nested mapping in storage which can not be public.
   *
   * @param _id             - Order id
   * @return orderView      - Order data
   */
  function _getOrderView(uint256 _id)
    internal
    view
    returns (OrderView memory orderView)
  {
    if (_id >= orders.length) {
      return
        OrderView({
          status: OrderStatus.Created,
          seller: address(0),
          token: address(0),
          price: 0,
          expiresAt: 0,
          lastUpdatedAt: 0,
          assets: new Listable.Asset[](0)
        });
    }
    Order storage order = orders[_id]; // reverts when _id exceeds the length
    orderView = OrderView({
      status: order.status,
      seller: order.seller,
      token: order.token,
      price: order.price,
      expiresAt: order.expiresAt,
      lastUpdatedAt: order.lastUpdatedAt,
      assets: order.assets.values
    });
  }

  /**
   * @dev Validate if the order is executable.
   *
   * @param _orderView      - Order data
   * @return                - true if the order is executable, otherwise false
   */
  function _isExecutableOrder(OrderView memory _orderView)
    internal
    view
    returns (bool)
  {
    // check order params
    if (_orderView.seller == address(0)) return false;
    if (_orderView.status != OrderStatus.Created) return false;
    if (block.timestamp >= _orderView.expiresAt) return false;
    if (!acceptedTokens.contains(_orderView.token)) return false;
    if (_orderView.price == 0) return false;

    // check assets
    uint256 length = _orderView.assets.length;
    if (length == 0) return false;
    for (uint256 i = 0; i < length; i++) {
      Listable.Asset memory asset = _orderView.assets[i];
      if (!acceptedRegistries.contains(asset.registry)) return false;
      IERC721 assetRegistry = IERC721(asset.registry);
      if (!assetRegistry.supportsInterface(INTERFACE_ID_ERC721)) return false;
      uint256 assetId = asset.id;
      try assetRegistry.ownerOf(assetId) returns (address assetOwner) {
        if (assetOwner != _orderView.seller) return false;
        if (
          assetRegistry.getApproved(assetId) != address(this) &&
          !assetRegistry.isApprovedForAll(assetOwner, address(this))
        ) return false;
      } catch {
        return false;
      }
    }

    // order is executable
    return true;
  }

  /**
   * @dev Require the order is modifiable.
   * Canceled, expired or already executed order cannot be modified.
   * Revert if the order is not modifiable.
   * Update the last timestamp if updated successfully.
   *
   * @param _order          - Order data
   */
  function _requireModifiableOrder(Order storage _order) internal view {
    address sender = _msgSender();
    require(_order.seller == sender, "Sender has no permission");
    require(_order.status == OrderStatus.Created, "Order is not modifiable");
    require(block.timestamp < _order.expiresAt, "Order is expired");
  }

  /**
   * @dev Require the address is ERC721 compatible contract.
   *
   * @param _address        - Address
   */
  function _requireERC721(address _address) internal view {
    require(_address.isContract(), "Address is not contract");

    IERC721 registry = IERC721(_address);
    require(
      registry.supportsInterface(INTERFACE_ID_ERC721),
      "Address is not compatible"
    );
  }

  /**
   * @dev Convert uint256 to uint64.
   * Revert if it exceeds the range.
   */
  function _safe64(uint256 n, string memory errorMessage)
    internal
    pure
    returns (uint64)
  {
    require(n < 2**64, errorMessage);
    return uint64(n);
  }
}

// SPDX-License-Identifier: MIT

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./Listable.sol";

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of Asset
 * type.
 *
 * Lists have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableList for EnumerableList.AssetList;
 *
 *     // Declare a list state variable
 *     EnumerableList.AssetList private mySet;
 * }
 * ```



     /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$      
    | $$__  $$ /$$__  $$| $$__  $$ /$$__  $$| $$_____/| $$      
    | $$  \ $$| $$  \ $$| $$  \ $$| $$  \__/| $$      | $$      
    | $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$$$$   | $$      
    | $$____/ | $$__  $$| $$__  $$| $$      | $$__/   | $$      
    | $$      | $$  | $$| $$  \ $$| $$    $$| $$      | $$      
    | $$      | $$  | $$| $$  | $$|  $$$$$$/| $$$$$$$$| $$$$$$$$
    |__/      |__/  |__/|__/  |__/ \______/ |________/|________/



 */
library EnumerableList {
  using Listable for Listable.Asset;

  struct AssetList {
    // Storage of list values
    Listable.Asset[] values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the list.
    mapping(bytes32 => uint256) indexes;
  }

  /**
   * @dev Add a value to a list. O(1).
   *
   * Returns true if the value was added to the list, that is if it was not
   * already present.
   */
  function add(AssetList storage list, Listable.Asset memory value)
    internal
    returns (bool)
  {
    if (!contains(list, value)) {
      list.values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      list.indexes[value.key()] = list.values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a list. O(1).
   *
   * Returns true if the value was removed from the list, that is if it was
   * present.
   */
  function remove(AssetList storage list, Listable.Asset memory value)
    internal
    returns (bool)
  {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = list.indexes[value.key()];

    if (valueIndex != 0) {
      // Equivalent to contains(list, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = list.values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      Listable.Asset storage lastvalue = list.values[lastIndex];

      // Move the last value to the index where the value to delete is
      list.values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      list.indexes[lastvalue.key()] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved value was stored
      list.values.pop();

      // Delete the index for the deleted slot
      delete list.indexes[value.key()];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the list. O(1).
   */
  function contains(AssetList storage list, Listable.Asset memory value)
    internal
    view
    returns (bool)
  {
    return list.indexes[value.key()] != 0;
  }

  /**
   * @dev Returns the number of values on the list. O(1).
   */
  function length(AssetList storage list) internal view returns (uint256) {
    return list.values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the list. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AssetList storage list, uint256 index)
    internal
    view
    returns (Listable.Asset memory)
  {
    require(list.values.length > index, "EnumerableList: index out of bounds");
    return list.values[index];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Verifiable is IERC721 {
  function verifyFingerprint(uint256, bytes memory)
    external
    view
    returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./ContextMixin.sol";

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
abstract contract Ownable is ContextMixin {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

import "./ContextMixin.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is ContextMixin {
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

pragma solidity ^0.8.3;

contract ContextMixin {
  function _msgSender() internal view returns (address sender) {
    if (msg.sender == address(this)) {
      bytes memory array = msg.data;
      uint256 index = msg.data.length;
      assembly {
        // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
        sender := and(
          mload(add(array, index)),
          0xffffffffffffffffffffffffffffffffffffffff
        )
      }
    } else {
      sender = msg.sender;
    }
    return sender;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
  bytes32 private constant META_TRANSACTION_TYPEHASH =
    keccak256(
      bytes(
        "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
      )
    );
  event MetaTransactionExecuted(
    address userAddress,
    address relayerAddress,
    bytes functionSignature
  );
  mapping(address => uint256) private nonces;

  /*
   * Meta transaction structure.
   * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
   * He should call the desired function directly in that case.
   */
  struct MetaTransaction {
    uint256 nonce;
    address from;
    bytes functionSignature;
  }

  function executeMetaTransaction(
    address userAddress,
    bytes memory functionSignature,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) public payable returns (bytes memory) {
    MetaTransaction memory metaTx = MetaTransaction({
      nonce: nonces[userAddress],
      from: userAddress,
      functionSignature: functionSignature
    });

    require(
      verify(userAddress, metaTx, sigR, sigS, sigV),
      "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
    );

    // increase nonce for user (to avoid re-use)
    nonces[userAddress] = nonces[userAddress] + 1;

    emit MetaTransactionExecuted(userAddress, msg.sender, functionSignature);

    // Append userAddress and relayer address at the end to extract it from calling context
    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returnData) = address(this).call(
      abi.encodePacked(functionSignature, userAddress)
    );

    if (!success) {
      /// @dev never return
      decodeRevert(returnData);
    }

    return returnData;
  }

  function hashMetaTransaction(MetaTransaction memory metaTx)
    internal
    pure
    returns (bytes32)
  {
    return
      keccak256(
        abi.encode(
          META_TRANSACTION_TYPEHASH,
          metaTx.nonce,
          metaTx.from,
          keccak256(metaTx.functionSignature)
        )
      );
  }

  function getNonce(address user) public view returns (uint256 nonce) {
    nonce = nonces[user];
  }

  function verify(
    address signer,
    MetaTransaction memory metaTx,
    bytes32 sigR,
    bytes32 sigS,
    uint8 sigV
  ) internal view returns (bool) {
    require(signer != address(0), "NMT#verify: INVALID_SIGNER");
    return
      signer ==
      ecrecover(
        toTypedMessageHash(hashMetaTransaction(metaTx)),
        sigV,
        sigR,
        sigS
      );
  }

  function decodeRevert(bytes memory result) internal pure {
    // Next 5 lines from https://ethereum.stackexchange.com/a/83577
    if (result.length < 68) revert("NMT#executeMetaTransaction: CALL_FAILED");
    assembly {
      result := add(result, 0x04)
    }
    revert(abi.decode(result, (string)));
  }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.3;

/**
 * @dev Library for listing ERC721 assets



     /$$$$$$$   /$$$$$$  /$$$$$$$   /$$$$$$  /$$$$$$$$ /$$      
    | $$__  $$ /$$__  $$| $$__  $$ /$$__  $$| $$_____/| $$      
    | $$  \ $$| $$  \ $$| $$  \ $$| $$  \__/| $$      | $$      
    | $$$$$$$/| $$$$$$$$| $$$$$$$/| $$      | $$$$$   | $$      
    | $$____/ | $$__  $$| $$__  $$| $$      | $$__/   | $$      
    | $$      | $$  | $$| $$  \ $$| $$    $$| $$      | $$      
    | $$      | $$  | $$| $$  | $$|  $$$$$$/| $$$$$$$$| $$$$$$$$
    |__/      |__/  |__/|__/  |__/ \______/ |________/|________/



 */
library Listable {
  struct Asset {
    address registry;
    uint256 id;
  }

  bytes32 internal constant ASSET_TYPEHASH =
    keccak256(bytes("Asset(address registry,uint256 id)"));

  /**
   * @dev Get the typed hash of the asset.
   */
  function key(Asset memory asset) internal pure returns (bytes32) {
    return keccak256(abi.encode(ASSET_TYPEHASH, asset.registry, asset.id));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

contract EIP712Base {
  struct EIP712Domain {
    string name;
    string version;
    address verifyingContract;
    bytes32 salt;
  }

  bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
    keccak256(
      bytes(
        "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
      )
    );
  bytes32 public domainSeparator;

  // supposed to be called once while initializing.
  // one of the contractsa that inherits this contract follows proxy pattern
  // so it is not possible to do this in a constructor
  function _initializeEIP712(string memory name, string memory version)
    internal
  {
    domainSeparator = keccak256(
      abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256(bytes(name)),
        keccak256(bytes(version)),
        address(this),
        bytes32(getChainId())
      )
    );
  }

  function getChainId() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }

  /**
   * Accept message hash and returns hash message in EIP712 compatible form
   * So that it can be used to recover signer from signature signed using EIP712 formatted data
   * https://eips.ethereum.org/EIPS/eip-712
   * "\\x19" makes the encoding deterministic
   * "\\x01" is the version byte to make it compatible to EIP-191
   */
  function toTypedMessageHash(bytes32 messageHash)
    internal
    view
    returns (bytes32)
  {
    return
      keccak256(abi.encodePacked("\x19\x01", domainSeparator, messageHash));
  }
}