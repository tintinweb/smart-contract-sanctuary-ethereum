//SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title  A decentraliced delivery
 * @author Ivan M.M
 * @notice You can use this contract to make decentrliced orders
 */
contract DeDelivery is AccessControl, ReentrancyGuard {
    using Counters for Counters.Counter;
    using Address for address payable;

    bytes32 public constant ADMIN_ROLE   = keccak256("ADMIN_ROLE");
    bytes32 public constant PARTNER_ROLE = keccak256("PARTNER_ROLE");
    bytes32 public constant RIDER_ROLE   = keccak256("RIDER_ROLE");
    
    Counters.Counter private _partnerCounter;
    Counters.Counter private _ordersCounter;
    
    //* Fee section
    uint256          private daoFee;
    address payable  private daoAddress;

    enum OrderState {
        NotStarted,
        InProcess,
        RiderSelected,
        Completed,
        Canceled
    }

    // Multihash struct to store IPFS CID's
    struct IPFSHash {
        bytes32 hash_;
        uint8 hashFunction;
        uint8 size;
    }

    // Signature struct for delivery validation
    struct OrderSignature {
        bytes32 r;
        bytes32 s;
        uint8   v;
    }

    struct Order {
        uint256         orderId;
        uint256         partnerId;
        uint256         nonce;
        IPFSHash        ipfsHash;
        address         client;
        uint64          total;
        uint64          riderPrice;
        OrderState      state;
        OrderSignature  sign;
        address         chosenRider;
    }

    struct Partner {
        IPFSHash info;
        address partnerAddress;
    }

    struct Rider {
        // bool occupied; // true free, false occupied
        uint256 activeOrder;
        string telegramUser;
    }

    // City => PartnersIds[]
    mapping(uint256 => uint256[]) private _partners;

    // PartnerId => PartnerInfo
    mapping(uint256 => Partner)   private _partnerInfo;

    // Riders
    mapping(address => Rider)     private _riders;

    // Orders
    mapping(uint256 => Order)     private _orders;
    mapping(address => uint256[]) private _ordersByClient;
    mapping(address => uint256[]) private _ordersByPartner;
    mapping(address => uint256[]) private _ordersByRider;


    event PartnerAdded(
        uint256 indexed partnerId, 
        uint256 indexed cityId, 
        address partnerAddress
    );
    
    event RiderAdded(
        address indexed riderAddress, 
        string telegramUser
    );

    event OrderAdded(
        uint256 indexed orderId, 
        address indexed client, 
        uint256 nonce, 
        uint64 orderTotal, 
        uint256 indexed partnerId
    );

    event OrderDelivered(
        uint256 indexed orderId, 
        address indexed client, 
        address indexed partnerAddress, 
        uint256 partnerId, 
        uint256 partnerTotal
    );

    event RiderAssigned(
        address indexed riderAssigned, 
        uint256 indexed orderId
    );

    event RiderPaid(
        address indexed riderAddress, 
        uint256 indexed orderId, 
        uint256 total
    );

    event PartnerPaid(
        address indexed partnerAddress, 
        uint256 indexed orderId, 
        uint256 total
    );

    /**
     * @notice Checks if sender is owner or chosen rider
     * @param orderId The order ID
     */
    modifier onlyPartnerRiderOwner(uint256 orderId) {
        require(
            hasRole(RIDER_ROLE, msg.sender)
            || 
            _orders[orderId].client == msg.sender
            ||
            _partnerInfo[_orders[orderId].partnerId].partnerAddress == msg.sender,
            "Neither partner nor rider nor client"
        );
        _;
    }

    /**
     * @notice Checks if orderId is valid
     * @param orderId The order ID
     */
    modifier validOrder(uint256 orderId) {
        require(
            orderId < _ordersCounter.current(),
            "Use a valid order ID"
        );
        require(
            _orders[orderId].state != OrderState.Completed && _orders[orderId].state != OrderState.Canceled,
            "Order already delivered or canceled"
        );
        _;
    }

    /**
     * @notice Constructor sets initial roles and DAO Address
     * @param daoAddress_ DAO's address
     */
    constructor(address daoAddress_, uint256 daoFee_) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);

        daoAddress = payable(daoAddress_);
        daoFee = daoFee_;
        
        // Starts at 1
        _partnerCounter.increment();
        _ordersCounter.increment();
    }

    receive() external payable {
        payable(msg.sender).sendValue(msg.value);
    }

    fallback() external payable {
        // ...
    }

    /**
     * @notice Set new partner only for admins
     * @param city City ID from JSON relational doc
     * @param partnerAddress To get paid after
     */
    function setNewPartner(
        bytes32 ipfsHash, 
        uint8 ipfsHashFunction, 
        uint8 ipfsSize, 
        uint256 city, 
        address partnerAddress
    ) 
        external 
        onlyRole(ADMIN_ROLE)
    {
        require(!hasRole(PARTNER_ROLE, partnerAddress), "Partner already stored");
        require(partnerAddress != address(0), "Zero address");

        uint256 partnerId = _partnerCounter.current();
        _partnerCounter.increment();

        IPFSHash memory multihash;
        multihash.hash_        = ipfsHash;
        multihash.hashFunction = ipfsHashFunction;
        multihash.size         = ipfsSize;

        Partner memory partner;
        partner.info = multihash;
        partner.partnerAddress = partnerAddress;

        _partners[city].push(partnerId);
        _partnerInfo[partnerId] = partner;

        _grantRole(PARTNER_ROLE, partnerAddress);
        emit PartnerAdded(partnerId, city, partnerAddress);
    }

    /**
     * @notice Set new rider
     *              Required:
     *                - Address is not zero address and is not already stored
     */
    function setNewRider(address riderAddress, string calldata telegramUser) external onlyRole(ADMIN_ROLE) {
        require(riderAddress != address(0), "Zero address");
        require(!hasRole(RIDER_ROLE, riderAddress), "Rider already stored");

        Rider memory rider;
        rider.activeOrder = 0;
        rider.telegramUser = telegramUser;

        _riders[riderAddress] = rider;
        _grantRole(RIDER_ROLE, riderAddress);
        emit RiderAdded(riderAddress, telegramUser);
    }

    /**
     * @notice Set DAO address
     *              Required:
     *                - `daoAddress_` should not be zero
     * 
     * @param daoAddress_ The new DAO Address to set
     */
    function setDAOAddress(address daoAddress_) external onlyRole(ADMIN_ROLE) {
        require(daoAddress_ != address(0), "Zero address");
        daoAddress = payable(daoAddress_);
    }

    /**
     * @notice Store new order in mapping _orders
     *              Required:
     *                - Price (param and sended) is > 0
     *                - Sender is not zero Address
     *   
     * @param ipfsHash IPFS hexadecimal part
     * @param ipfsHashFunction Hash number from IPFS hash
     * @param ipfsSize Size of hexadecimal IPFS hash 
     * @param partnerId The partner id to retrieve it address
     * @param actualNonce Client actual nonce when make order
     * @param r_ ECDSA first param of the signed nonce
     * @param s_ ECDSA second param of the signed nonce
     * @param v_ ECDSA third param in integer of the 2 last digits in signed nonce
     * @dev NonReentrant to avoid reentrancy attacks and payable that stores in the SC the price until order is delivered 
     */
    function storeOrder(
        bytes32 ipfsHash, 
        uint8 ipfsHashFunction, 
        uint8 ipfsSize, 
        uint256 partnerId, 
        uint256 actualNonce, 
        bytes32 r_, 
        bytes32 s_, 
        uint8 v_,
        uint64 riderPrice
    ) 
        external 
        payable 
        nonReentrant 
    {
        require(msg.sender != address(0), "Sender is zero address");
        require(msg.value > 0, "Zero orders not supported");
        
        uint256 orderId = _ordersCounter.current();
        _ordersCounter.increment();
        emit OrderAdded(orderId, msg.sender, actualNonce, uint64(msg.value), partnerId);

        uint64 orderTotal = uint64(msg.value) - riderPrice;

        OrderSignature memory signature;
        signature.r = r_;
        signature.s = s_;
        signature.v = v_;

        IPFSHash memory multihash;
        multihash.hash_        = ipfsHash;
        multihash.hashFunction = ipfsHashFunction;
        multihash.size         = ipfsSize;

        Order memory order;
        order.orderId      = orderId;
        order.ipfsHash     = multihash;
        order.partnerId    = partnerId;
        order.state        = OrderState.NotStarted;
        order.nonce        = actualNonce;
        order.client       = msg.sender;
        order.total        = orderTotal;
        order.riderPrice  = riderPrice;
        order.sign         = signature;
        
        _orders[orderId] = order;
        _ordersByPartner[_partnerInfo[partnerId].partnerAddress].push(orderId);
        _ordersByClient[msg.sender].push(orderId);
    }

    /**
     * @notice Start an order by partner
     *              Required:
     *                - `orderId` partner is caller
     *
     * @param orderId The order ID
     */
    function startOrder(uint256 orderId) external onlyPartnerRiderOwner(orderId) validOrder(orderId) {
        require(_orders[orderId].state == OrderState.NotStarted, "Order in process");
        _orders[orderId].state = OrderState.InProcess;
    }

    /**
     * @notice Rider select function for orders
     *              Required:
     *                - Registered rider and not occupied
     *                - Not delivered order
     *                - Rider not assigned yet
     *
     * @param orderId Order ID to set rider
     */
    function riderSelect(uint256 orderId) external onlyRole(RIDER_ROLE) validOrder(orderId) {
        Order storage order = _orders[orderId];
        require(_riders[msg.sender].activeOrder == 0, "Busy rider or non exists");
        require(order.chosenRider == address(0), "Already assigned");

        // Order update
        _ordersByRider[msg.sender].push(orderId);
        order.chosenRider = msg.sender;
        order.state = OrderState.RiderSelected;

        // Rider update
        _riders[msg.sender].activeOrder = orderId;
        emit RiderAssigned(msg.sender, orderId);
    } 

    /**
     * @notice This function delivers an order and pays partner and DAO
     *              Required:
     *                - Sender MUST BE the orderer
     *                - Order not delivered by the rider/owner
     *
     * @param orderId The order ID
     * @param hashedMessage The hashed nonce when QR is read
     * @param r ECDSA first param
     * @param s ECDSA second param
     * @param v ECDSA third param
     */
    function deliverOrder(
        uint256 orderId, 
        bytes32 hashedMessage, 
        bytes32 r, 
        bytes32 s, 
        uint8 v
    ) 
        external 
        payable 
        nonReentrant 
        validOrder(orderId) 
    {
        Order storage order = _orders[orderId];
        order.state = OrderState.Completed;

        require(order.chosenRider != address(0), "Rider not selected yet");
        require(verifyOrderClient(orderId, hashedMessage, r, s, v), "Not client");
        
        // DAO
        uint256 daoTotal = calculatePercentage(order.total, daoFee);
        
        // Rider
        uint256 riderTotal = order.riderPrice;
        _riders[order.chosenRider].activeOrder = 0;
        emit RiderPaid(order.chosenRider, orderId, riderTotal);

        // Partner
        Partner memory partner = _partnerInfo[order.partnerId];
        uint256 partnerTotal = order.total - daoTotal;
        emit PartnerPaid(partner.partnerAddress, orderId, partnerTotal);

        // Money distribution
        payable(partner.partnerAddress).sendValue(partnerTotal);
        payable(order.chosenRider).sendValue(riderTotal);
        daoAddress.sendValue(daoTotal);

        emit OrderDelivered(orderId, order.client, partner.partnerAddress, order.partnerId, partnerTotal);
    }

    /**
     * @notice Cancel the order and return to client the paid only for Admin
     * @param orderId The order ID to cancel
     */
    function cancelOrder(uint256 orderId) public payable nonReentrant validOrder(orderId) onlyRole(ADMIN_ROLE) {
        Order storage order = _orders[orderId];
        order.state = OrderState.Canceled;

        // Return money to client
        payable(order.client).sendValue(order.total);
        payable(order.client).sendValue(order.riderPrice);
    }

    /**
     * @notice Reject the order and return to client the paid only for partner
     * @param orderId The order ID to reject
     */
    function rejectOrder(uint256 orderId) external payable validOrder(orderId) {
        require(_partnerInfo[_orders[orderId].partnerId].partnerAddress == msg.sender, "Not partner");
        require(_orders[orderId].state == OrderState.NotStarted, "Order already started");
        
        Order storage order = _orders[orderId];
        order.state = OrderState.Canceled;

        // Return money to client
        payable(order.client).sendValue(order.total);
        payable(order.client).sendValue(order.riderPrice);
    }

    //? Riders functions
    
    /**
     * @notice Get Telegram user from rider
     * @param address_ The rider address
     * @return telegramUser The telegram user of rider
     *! @dev Check the security implications!
     */
    function getRiderTelegramUser(address address_) external view returns (string memory) {
        return _riders[address_].telegramUser;
    }

    /**
     * @notice Get active order by rider
     * @return orderId The order active by rider
     */
    function getActiveOrder() external view returns (uint256) {
        return _riders[msg.sender].activeOrder;
    }

    /**
     * @notice Get all orders if caller is a non-occupied rider
     * @return orders All the orders that are not any rider assigned
     */
    function getAllOrders() external view returns (uint256[] memory) {
        require(_riders[msg.sender].activeOrder == 0, "You are already occupied");

        uint256 totalOrders = _ordersCounter.current() - 1;
        uint256[] memory orders = new uint256[](totalOrders);
        uint256 c = 0;

        for(uint256 i=1; i <= totalOrders;){
            if(_orders[i].chosenRider == address(0)){
                orders[c] = _orders[i].orderId;
                unchecked{
                    ++c;
                }
            }
            unchecked {
                ++i;
            }
        }

        return orders;
    }

    //? Partners functions

    /**
     * @notice Get IPFS info for a partner
     * @param partnerId Partner Id to search its IPFS hash
     * @return multiHash the IPFS multihash of partner
     *! @dev Check the security implications!
     */
    function getPartnerInfo(uint256 partnerId) external view returns (IPFSHash memory) {
        return _partnerInfo[partnerId].info;
    }

    /**
     * @notice Get all the partners relationed with a city id
     * @param locId City id
     * @return partners The partners in this city
     */
    function getPartners(uint256 locId) external view returns (uint256[] memory) {
        return _partners[locId];
    }

    //? Orders functions

    /**
     * @notice Returns IPFSHash struct that contains in multihash IPFS CID with order information
     * @param orderId The order ID
     * @return ipfsHash Order info in multihash form
     */
    function getOrderInfo(uint256 orderId) external view validOrder(orderId) onlyPartnerRiderOwner(orderId) returns (IPFSHash memory) {
        return _orders[orderId].ipfsHash;
    }

    /**
     * @notice Returns the state of the order
     * @param orderId The order ID
     * @return state Order state
     */
    function getOrderState(uint256 orderId) external view validOrder(orderId) returns (OrderState) {
        return _orders[orderId].state;
    }

    /**
     * @notice Returns all the orders by client in O(1)
     * @return orders All the orders of the sender
     */
    function getOrdersByClient() external view returns (Order[] memory) {
        uint256 clientOrdersLength = _ordersByClient[msg.sender].length;
        
        Order[] memory orders = new Order[](clientOrdersLength);
        
        for(uint256 i=0; i < clientOrdersLength;){
            orders[i] = _orders[_ordersByClient[msg.sender][i]];
            unchecked {
                ++i;
            }
        }

        return orders;
    }

    /**
     * @notice Returns all the orders by rider in O(1)
     * @return orders All the orders of the sender
     */
    function getOrdersByRider() external view returns (Order[] memory) {
        uint256 riderOrdersLength = _ordersByRider[msg.sender].length;
        
        Order[] memory orders = new Order[](riderOrdersLength);
        
        for(uint256 i=0; i < riderOrdersLength;){
            orders[i] = _orders[_ordersByRider[msg.sender][i]];
            unchecked {
                ++i;
            }
        }

        return orders;
    }

    /**
     * @notice Returns all the orders by partner in O(1)
     * @return orders All the orders of the sender
     */
    function getOrdersByPartner() external view returns (Order[] memory) {
        uint256 partnerOrdersLength = _ordersByPartner[msg.sender].length;
        
        Order[] memory orders = new Order[](partnerOrdersLength);
        
        for(uint256 i=0; i < partnerOrdersLength;){
            orders[i] = _orders[_ordersByPartner[msg.sender][i]];
            unchecked {
                ++i;
            }
        }

        return orders;
    }

    //? Private functions

    /**
     * @notice This function verify client's order signature. If signer != client, reverts in callback
     * @param orderId The valid order ID
     * @param hashedMessage The hashed nonce when QR is read
     * @param r ECDSA first param
     * @param s ECDSA second param
     * @param v ECDSA third param
     * @return signerVerified Hashed message signed is valid
     **@dev EIP-712 works perfectly
     */
    function verifyOrderClient(
        uint256 orderId, 
        bytes32 hashedMessage, 
        bytes32 r, 
        bytes32 s, 
        uint8 v
    ) 
        private 
        view 
        returns (bool) 
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(abi.encodePacked(prefix, hashedMessage));
        address signer = ecrecover(prefixedHashMessage, v, r, s);
        return (signer == _orders[orderId].client);
    }

    /**
     * @notice Calculate the percentage of the total order price
     * @param number The total price
     * @param percentage Percentage in basis points
     * @return partOf The percentage (percentage) of total (number)
     * @dev Used by delivery ops.
     **@dev Simple, works perfectly
     */
    function calculatePercentage(uint256 number, uint256 percentage) private pure returns (uint256) {
        return number * percentage / 10000; 
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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