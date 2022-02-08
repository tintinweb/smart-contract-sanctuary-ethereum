// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./libraries/Bytes32Library.sol";
import "./libraries/StringLibrary.sol";

import "./interfaces/ITradePairs.sol";
import "./interfaces/IOrderBooks.sol";
import "./interfaces/IPortfolio.sol";
import "./interfaces/IDexManager.sol";


contract TradePairs is Ownable, ITradePairs , ReentrancyGuard {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using StringLibrary for string;
    using Bytes32Library for bytes32;

    // reference to OrderBooks contract (one sell or buy book)
    IOrderBooks private orderBooks;
    IPortfolio private portfolio;
    IDexManager private dexManager;

    // a dynamic array of trade pairs added to TradePairs contract
    bytes32[] private tradePairsArray;

    // order counter to build a unique handle for each new order
    uint private orderCounter;

    // mapping data structure for all trade pairs
    mapping (bytes32 => TradePair) private tradePairMap;
    // mapping  for allowed order types for a TradePair
    mapping (bytes32 => EnumerableSetUpgradeable.UintSet) private allowedOrderTypes;
    // mapping structure for all orders
    mapping (bytes32 => Order) private orderMap;


    event Executed(bytes32 indexed pair, uint price, uint quantity, bytes32 maker, bytes32 taker, uint feeMaker, uint feeTaker, bool feeMakerBase);
    event OrderStatusChanged(address indexed traderAddress, bytes32 indexed pair, bytes32 id,  uint price, uint totalamount, uint quantity,
        Side side, Type1 type1, Status status, uint quantityfilled, uint totalfee);
    event TradePairsInit(address orderBookAddress, address portofolioAddress, address tradePairsAddress);
    event TradePairAdded(bytes32 indexed pair, address baseToken, address quoteToken);
    event ParameterUpdated(bytes32 indexed pair, string param, uint oldValue, uint newValue);
    event UpdateOrder(bytes32 orderId);
    function addTradePair(bytes32[] memory _assets, address[] memory _addresses, uint[] memory _fees, uint[] memory _amounts, bool _isActive) public override {
        bytes32 _tradePairId = _assets[0];
        require(tradePairMap[_tradePairId].baseSymbol == '', "You already added this trade pair");
        bytes32 _buyBookId = string(abi.encodePacked(_tradePairId.bytes32ToString(), '-BUYBOOK')).stringToBytes32();
        bytes32 _sellBookId = string(abi.encodePacked(_tradePairId.bytes32ToString(), '-SELLBOOK')).stringToBytes32();
        tradePairMap[_tradePairId].baseSymbol = _assets[1];
        tradePairMap[_tradePairId].baseAddress = _addresses[0];
        tradePairMap[_tradePairId].baseDecimals = _amounts[0];
        tradePairMap[_tradePairId].baseDisplayDecimals = _amounts[1];
        tradePairMap[_tradePairId].quoteSymbol = _assets[2];
        tradePairMap[_tradePairId].quoteAddress = _addresses[1];
        tradePairMap[_tradePairId].quoteDecimals = _amounts[2];
        tradePairMap[_tradePairId].quoteDisplayDecimals = _amounts[3];
        tradePairMap[_tradePairId].minTradeAmount = _amounts[4];
        tradePairMap[_tradePairId].maxTradeAmount = _amounts[5];
        tradePairMap[_tradePairId].buyBookId = _buyBookId;
        tradePairMap[_tradePairId].sellBookId = _sellBookId;
        tradePairMap[_tradePairId].makerFee = _fees[0]; // makerFee=10 (0.10% = 10/10000)
        tradePairMap[_tradePairId].takerFee = _fees[1]; // takerFee=20 (0.20% = 20/10000)
        tradePairMap[_tradePairId].allowedSlippagePercent = _amounts[6]; // allowedSlippagePercent=20 (20% = 20/
        tradePairMap[_tradePairId].isActive = _isActive;
        EnumerableSetUpgradeable.UintSet storage enumSet = allowedOrderTypes[_tradePairId];
        tradePairMap[_tradePairId].pairPaused = false;       // addOrder is not paused by default
        tradePairMap[_tradePairId].addOrderPaused = false;   // pair is not paused by default
        enumSet.add(uint(Type1.LIMIT));   // LIMIT orders always allowed

        tradePairsArray.push(_tradePairId);
        emit TradePairAdded(_tradePairId, _addresses[0], _addresses[1]);
    }

    function pauseTradePair(bytes32 _tradePairId, bool _pairPaused) public override onlyOwner {
        tradePairMap[_tradePairId].pairPaused = _pairPaused;
    }

    function pauseAddOrder(bytes32 _tradePairId, bool _addOrderPaused) public override onlyOwner {
        tradePairMap[_tradePairId].addOrderPaused = _addOrderPaused;
    }

    function initialize(address _orderBooks, address _portfolio, address _dexManager) public onlyOwner {
        orderBooks = IOrderBooks(_orderBooks);
        portfolio = IPortfolio(_portfolio);
        dexManager = IDexManager(_dexManager);
        emit TradePairsInit(_orderBooks, _portfolio, _dexManager);
    }

    function getTradePairs() public override view returns (bytes32[] memory) {
        return tradePairsArray;
    }

    function getTradePairInfo(bytes32 _tradePairId) external view override returns (TradePair memory){
        return tradePairMap[_tradePairId];
    }

    function getMinTradeAmount(bytes32 _tradePairId) public override view returns (uint) {
        return tradePairMap[_tradePairId].minTradeAmount;
    }

    function setMinTradeAmount(bytes32 _tradePairId, uint256 _minTradeAmount) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].minTradeAmount;
        tradePairMap[_tradePairId].minTradeAmount = _minTradeAmount;
        emit ParameterUpdated(_tradePairId, "T-MINTRAMT", oldValue, _minTradeAmount);
    }


    function getMaxTradeAmount(bytes32 _tradePairId) public override view returns (uint) {
        return tradePairMap[_tradePairId].maxTradeAmount;
    }

    function setMaxTradeAmount(bytes32 _tradePairId, uint256 _maxTradeAmount) public override {
        uint oldValue = tradePairMap[_tradePairId].maxTradeAmount;
        tradePairMap[_tradePairId].maxTradeAmount = _maxTradeAmount;
        emit ParameterUpdated(_tradePairId, "T-MAXTRAMT", oldValue, _maxTradeAmount);
    }

    function addOrderType(bytes32 _tradePairId, Type1 _type) public override {
        allowedOrderTypes[_tradePairId].add(uint(_type));
        emit ParameterUpdated(_tradePairId, "T-OTYPADD", 0, uint(_type));
    }

    function removeOrderType(bytes32 _tradePairId, Type1 _type) public override onlyOwner {
        require(_type != Type1.LIMIT, "T-LONR-01");
        allowedOrderTypes[_tradePairId].remove(uint(_type));
        emit ParameterUpdated(_tradePairId, "T-OTYPREM", 0, uint(_type));
    }

    function getAllowedOrderTypes(bytes32 _tradePairId) public view returns (uint[] memory) {
        uint size = allowedOrderTypes[_tradePairId].length();
        uint[] memory allowed = new uint[](size);
        for (uint i=0; i<size; i++) {
            allowed[i] = allowedOrderTypes[_tradePairId].at(i);
        }
        return allowed;
    }

    function setDisplayDecimals(bytes32 _tradePairId, uint256 _displayDecimals, bool _isBase) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].baseDisplayDecimals;
        if (_isBase) {
            tradePairMap[_tradePairId].baseDisplayDecimals = _displayDecimals;
        } else {
            oldValue = tradePairMap[_tradePairId].quoteDisplayDecimals;
            tradePairMap[_tradePairId].quoteDisplayDecimals = _displayDecimals;
        }
        emit ParameterUpdated(_tradePairId, "T-DISPDEC", oldValue, _displayDecimals);
    }

    function getDisplayDecimals(bytes32 _tradePairId, bool _isBase) public override view returns (uint256) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseDisplayDecimals;
        } else {
            return tradePairMap[_tradePairId].quoteDisplayDecimals;
        }
    }

    function getDecimals(bytes32 _tradePairId, bool _isBase) public override view returns (uint256) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseDecimals;
        } else {
            return tradePairMap[_tradePairId].quoteDecimals;
        }
    }

    function getSymbol(bytes32 _tradePairId, bool _isBase) public override view returns (bytes32) {
        if (_isBase) {
            return tradePairMap[_tradePairId].baseSymbol;
        } else {
            return tradePairMap[_tradePairId].quoteSymbol;
        }
    }

    function updateFee(bytes32 _tradePairId, uint256 _fee, ITradePairs.RateType _rateType) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].makerFee;
        if (_rateType == ITradePairs.RateType.MAKER) {
            tradePairMap[_tradePairId].makerFee = _fee; // (_rate/100)% = _rate/10000: _rate=10 => 0.10%
            emit ParameterUpdated(_tradePairId, "T-MAKERRATE", oldValue, _fee);
        } else if (_rateType == ITradePairs.RateType.TAKER) {
            oldValue = tradePairMap[_tradePairId].takerFee;
            tradePairMap[_tradePairId].takerFee = _fee; // (_rate/100)% = _rate/10000: _rate=20 => 0.20%
            emit ParameterUpdated(_tradePairId, "T-TAKERRATE", oldValue, _fee);
        } // Ignore the rest for now
    }

    function getMakerFee(bytes32 _tradePairId) public view override returns (uint) {
        return tradePairMap[_tradePairId].makerFee;
    }

    function getTakerFee(bytes32 _tradePairId) public view override returns (uint) {
        return tradePairMap[_tradePairId].takerFee;
    }

    function setAllowedSlippagePercent(bytes32 _tradePairId, uint256 _allowedSlippagePercent) public override onlyOwner {
        uint oldValue = tradePairMap[_tradePairId].allowedSlippagePercent;
        tradePairMap[_tradePairId].allowedSlippagePercent = _allowedSlippagePercent;
        emit ParameterUpdated(_tradePairId, "T-SLIPPAGE", oldValue, _allowedSlippagePercent);
    }

    function getAllowedSlippagePercent(bytes32 _tradePairId) public override view returns (uint256) {
        return tradePairMap[_tradePairId].allowedSlippagePercent;
    }

    function getOrder(bytes32 _orderId) public view override returns (Order memory) {
        return orderMap[_orderId];
    }

    function getOrderId() public override returns (bytes32) {
        return keccak256(abi.encodePacked(orderCounter++));
    }

    // get remaining quantity for an Order struct - cheap pure function
    function getRemainingQuantity(Order memory _order) private pure returns (uint) {
        return _order.quantity - _order.quantityFilled;
    }

    // get quote amount
    function getQuoteAmount(bytes32 _tradePairId, uint _price, uint _quantity) private view returns (uint) {
        return  (_price * _quantity) / 10 ** tradePairMap[_tradePairId].baseDecimals;
    }

    function emitStatusUpdate(bytes32 _tradePairId, bytes32 _orderId) private {
        Order storage _order = orderMap[_orderId];
        emit OrderStatusChanged(_order.traderAddress, _tradePairId, _order.id,
            _order.price, _order.totalAmount, _order.quantity,
            _order.side, _order.type1, _order.status, _order.quantityFilled,
            _order.totalFee);
    }


    // Used to Round Down the fees to the display decimals to avoid dust
    function floor(uint a, uint m) pure private returns (uint256) {
        return (a / 10 ** m) * 10**m;
    }

    function decimalsOk(uint value, uint decimals, uint displayDecimals) public pure returns (bool) {
        return ((value % 10 ** decimals) % 10 ** (decimals - displayDecimals)) == 0;
    }

    // FRONTEND ENTRY FUNCTION TO CALL TO ADD ORDER
    function addOrder(bytes32 _tradePairId, uint _price, uint _quantity, Side _side, Type1 _type1) public override nonReentrant {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        require(!_tradePair.pairPaused, "T-PPAU-01");
        require(!_tradePair.addOrderPaused, "T-AOPA-01");
        require(_side == Side.BUY || _side == Side.SELL, "T-IVSI-01");
        require(allowedOrderTypes[_tradePairId].contains(uint(_type1)), "T-IVOT-01");
        require(decimalsOk(_quantity, _tradePair.baseDecimals, _tradePair.baseDisplayDecimals), "T-TMDQ-01");

        if (_type1 == Type1.LIMIT) {
            dexManager.addLimitOrder(_tradePairId, _price, _quantity, _side, msg.sender);
        } else if (_type1 == Type1.MARKET) {
            dexManager.addMarketOrder(_tradePairId, _quantity, _side, msg.sender);
        }
    }

    function doOrderCancel(bytes32 _tradePairId, bytes32 _orderId) private {
        TradePair storage _tradePair = tradePairMap[_tradePairId];
        Order storage _order = orderMap[_orderId];
        _order.status = Status.CANCELED;
        if (_order.side == Side.BUY) {
            orderBooks.cancelOrder(_tradePair.buyBookId, _orderId, _order.price);
            portfolio.adjustAvailable(IPortfolio.Tx.INCREASEAVAIL, _order.traderAddress, _tradePair.quoteSymbol,
                getQuoteAmount(_tradePairId, _order.price, getRemainingQuantity(_order)));
        } else {
            orderBooks.cancelOrder(_tradePair.sellBookId, _orderId, _order.price);
            portfolio.adjustAvailable(IPortfolio.Tx.INCREASEAVAIL, _order.traderAddress, _tradePair.baseSymbol, getRemainingQuantity(_order));
        }
        emitStatusUpdate(_tradePairId, _order.id);
    }

    // FRONTEND ENTRY FUNCTION TO CALL TO CANCEL ONE ORDER
    function cancelOrder(bytes32 _tradePairId, bytes32 _orderId) public override nonReentrant {
        Order storage _order = orderMap[_orderId];
        require(_order.traderAddress == msg.sender, "T-OOCC-01");
        require(_order.id != '', "T-EOID-01");
        require(!tradePairMap[_tradePairId].pairPaused, "T-PPAU-02");
        require(_order.quantityFilled < _order.quantity && (_order.status == Status.PARTIAL || _order.status== Status.NEW), "T-OAEX-01");
        doOrderCancel(_tradePairId, _order.id);
    }

    function cancelAllOrders(bytes32 _tradePairId, bytes32[] memory _orderIds) public override nonReentrant {
        require(!tradePairMap[_tradePairId].pairPaused, "T-PPAU-03");
        for (uint i = 0; i < _orderIds.length; i++) {
            Order storage _order = orderMap[_orderIds[i]];
            require(_order.traderAddress == msg.sender, "T-OOCC-02");
            if (_order.id != '' && _order.quantityFilled < _order.quantity && (_order.status == Status.PARTIAL || _order.status == Status.NEW)) {
                doOrderCancel(_tradePairId, _order.id);
            }
        }
    }

    fallback() external {}

    function getNBuyBook(bytes32 _tradePairId, uint _n) public view override returns (uint[] memory, uint[] memory) {
        // get highest (_type=1) N orders
        return orderBooks.getNOrders(tradePairMap[_tradePairId].buyBookId, _n, 1);
    }

    function getNSellBook(bytes32 _tradePairId, uint _n) public override view returns (uint[] memory, uint[] memory) {
        // get lowest (_type=0) N orders
        return orderBooks.getNOrders(tradePairMap[_tradePairId].sellBookId, _n, 0);
    }

    function updateOrder(bytes32 _orderId, Order memory _myOrder) public override {
        Order storage _order = orderMap[_orderId];
        _order.quantityFilled = _myOrder.quantityFilled;
        _order.status = _myOrder.status;
        _order.totalFee = _myOrder.totalFee;
        _order.traderAddress = _myOrder.traderAddress;
        _order.price = _myOrder.price;
        _order.quantity = _myOrder.quantity;
        _order.side = _myOrder.side;
        emit UpdateOrder(_orderId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

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
library EnumerableSetUpgradeable {
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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
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

pragma solidity ^0.8.3;

library Bytes32Library {

    // utility function to convert bytes32 to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

library StringLibrary {

    // utility function to convert string to bytes32
    function stringToBytes32(string memory _string) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(_string);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(_string, 32))
        }
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface ITradePairs {
    struct Order {
        bytes32 id;
        uint price;
        uint totalAmount;
        uint quantity;
        uint quantityFilled;
        uint totalFee;
        address traderAddress;
        Side side;
        Type1 type1;
        Status status;
    }
    struct TradePair {
        bytes32 baseSymbol;          // symbol for base asset
        bytes32 quoteSymbol;         // symbol for quote asset
        bytes32 buyBookId;           // identifier for the buyBook for TradePair
        bytes32 sellBookId;          // identifier for the sellBook for TradePair
        address baseAddress;         // address for base asset
        address quoteAddress;            // address for quote asset
        uint minTradeAmount;         // min trade for a TradePair expressed as amount = (price * quantity) / (10 ** quoteDecimals)
        uint maxTradeAmount;         // max trade for a TradePair expressed as amount = (price * quantity) / (10 ** quoteDecimals)
        uint makerFee;              // numerator for maker fee rate % to be used with a denominator of 10000
        uint takerFee;              // numerator for taker fee rate % to be used with a denominator of 10000
        uint baseDecimals;          // decimals for base asset
        uint baseDisplayDecimals;   // display decimals for base asset
        uint quoteDecimals;         // decimals for quote asset
        uint quoteDisplayDecimals;  // display decimals for quote asset
        uint allowedSlippagePercent;// numerator for allowed slippage rate % to be used with denominator 100
        bool addOrderPaused;           // boolean to control addOrder functionality per TradePair
        bool pairPaused;               // boolean to control addOrder and cancelOrder functionality per TradePair
        bool isActive;
    }

    function pauseTradePair(bytes32 _tradePairId, bool _pairPaused) external;
    function pauseAddOrder(bytes32 _tradePairId, bool _allowAddOrder) external;
    function addTradePair(bytes32[] memory _assets, address[] memory _addresses, uint[] memory _fees, uint256[] memory _amounts, bool _isActive) external;
    function getTradePairs() external view returns (bytes32[] memory);
    function getTradePairInfo(bytes32 _pid) external view returns (TradePair memory);
    function getOrder(bytes32 _orderUid) external view returns (Order memory);
    function getOrderId() external returns (bytes32);
    function getMinTradeAmount(bytes32 _tradePairId) external view returns (uint);
    function setMinTradeAmount(bytes32 _tradePairId, uint256 _minTradeAmount) external;
    function getMaxTradeAmount(bytes32 _tradePairId) external view returns (uint);
    function setMaxTradeAmount(bytes32 _tradePairId, uint256 _maxTradeAmount) external;
    function addOrderType(bytes32 _tradePairId, Type1 _type) external;
    function removeOrderType(bytes32 _tradePairId, Type1 _type) external;
    function getAllowedOrderTypes(bytes32 _tradePairId) external view returns (uint[] memory);
    function setDisplayDecimals(bytes32 _tradePairId, uint256 _displayDecimals, bool _isBase) external;
    function getDisplayDecimals(bytes32 _tradePairId, bool _isBase) external view returns (uint256);
    function getDecimals(bytes32 _tradePairId, bool _isBase) external view returns (uint256);
    function getSymbol(bytes32 _tradePairId, bool _isBase) external view returns (bytes32);
    function updateFee(bytes32 _tradePairId, uint256 _fee, RateType _rateType) external;
    function updateOrder(bytes32 _orderId, Order memory _myOrder) external;
    function getMakerFee(bytes32 _tradePairId) external view returns (uint);
    function getTakerFee(bytes32 _tradePairId) external view returns (uint);
    function setAllowedSlippagePercent(bytes32 _tradePairId, uint256 _allowedSlippagePercent) external;
    function getAllowedSlippagePercent(bytes32 _tradePairId) external view returns (uint256);
    function getNSellBook(bytes32 _tradePairId, uint _n) external view returns (uint[] memory, uint[] memory);
    function getNBuyBook(bytes32 _tradePairId, uint _n) external view returns (uint[] memory, uint[] memory);
    function cancelOrder(bytes32 _tradePairId, bytes32 _orderId) external;
    function cancelAllOrders(bytes32 _tradePairId, bytes32[] memory _orderIds) external;
    function addOrder(bytes32 _tradePairId, uint _price, uint _quantity, Side _side, Type1 _type1) external;

    enum Side     {BUY, SELL}
    enum Type1    {MARKET, LIMIT, STOP, STOPLIMIT}
    enum Status   {NEW, REJECTED, PARTIAL, FILLED, CANCELED, EXPIRED, KILLED}
    enum RateType {MAKER, TAKER}
    enum Type2    {GTC, FOK}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IOrderBooks {
    function getNOrders(bytes32 _orderBookID, uint n, uint _type) external view returns (uint[] memory, uint[] memory);
    function root(bytes32 _orderBookID) external view returns (uint);
    function first(bytes32 _orderBookID) external view returns (uint);
    function last(bytes32 _orderBookID) external view returns (uint);
    function next(bytes32 _orderBookID, uint price) external view returns (uint);
    function prev(bytes32 _orderBookID, uint price) external view returns (uint);
    function getHead(bytes32 _orderBookID, uint price ) external view returns (bytes32);
    function matchTrade(bytes32 _orderBookID, uint price, uint takerOrderRemainingQuantity, uint makerOrderRemainingQuantity)  external returns (uint);
    function addOrder(bytes32 _orderBookID, bytes32 _orderUid, uint _price) external;
    function cancelOrder(bytes32 _orderBookID, bytes32 _orderUid, uint _price) external;
    function orderListExists(bytes32 _orderBookID, uint _price) external view returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./ITradePairs.sol";

interface IPortfolio {
    function pauseDeposit(bool _paused) external;
    function updateTransferFeeRate(uint _rate, IPortfolio.Tx _rateType) external;
    function addToken(bytes32 _symbol, IERC20Upgradeable _token) external;
    function adjustAvailable(Tx _transaction, address _trader, bytes32 _symbol, uint _amount) external;
    function addExecution(ITradePairs.Order memory _maker, address _taker, bytes32 _baseSymbol, bytes32 _quoteSymbol,
        uint _baseAmount, uint _quoteAmount, uint _makerfeeCharged,
        uint _takerfeeCharged) external;
    function withdrawToken(address _to, bytes32 _symbol, uint _quantity) external;
    function depositToken(address _from, bytes32 _symbol, uint _quantity) external;
    enum Tx  {WITHDRAW, DEPOSIT, EXECUTION, INCREASEAVAIL, DECREASEAVAIL}

    event PortfolioUpdated(Tx indexed transaction, address indexed wallet, bytes32 indexed symbol,
        uint256 quantity, uint256 feeCharged, uint256 total, uint256 available);
}

pragma solidity ^0.8.0;

import "./ITradePairs.sol";

interface IDexManager {
    function addLimitOrder(bytes32 _tradePairId, uint _price, uint _quantity, ITradePairs.Side _side, address _traderAddress) external;
    function addMarketOrder(bytes32 _tradePairId, uint _quantity, ITradePairs.Side _side, address _traderAddress) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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