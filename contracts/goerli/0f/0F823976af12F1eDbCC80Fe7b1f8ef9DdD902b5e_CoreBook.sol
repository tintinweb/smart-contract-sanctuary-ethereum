// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { ReentrancyGuardUpgradeable } from '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import { OwnableUpgradeable } from '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import { SafeERC20Upgradeable as SafeERC20, IERC20Upgradeable as IERC20 } from '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import { StringsUpgradeable as Strings } from '@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol';
import { ICoreBook } from './interfaces/ICoreBook.sol';
import { IWETH } from './interfaces/IWETH.sol';

contract CoreBook is ICoreBook, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20 for IERC20;

    address public wCORE;
    uint256 public CORE_Price;
    uint256 public ListingFeeUSD;
    uint256 public CancelFeeUSD;

    mapping(uint256 => Order) private orderId;
    mapping(bytes32 => uint256[]) public pairs;
    mapping(bytes32 => uint256) public activePairOrders;
    mapping(address => uint256[]) public userOrders;
    mapping(IERC20 => bool) public restrictedTokens;
    mapping(address => bool) public restrictedUsers;
    mapping(address => bool) private updaters;

    uint256 private currentId;
    uint256 public activeOrderCount;

    uint16 public tax;
    address payable public taxWallet;

    bool public isPaused;

    mapping(address => mapping(address => uint256[])) public pairs2;
    mapping(address => mapping(address => uint256)) public activePairOrders2;

    uint256[46] __gap;

    modifier notPaused() {
        require(!isPaused, "Contract is Paused to new orders");
        _;
    }

    modifier notRestrictedUser() {
        require(!restrictedUsers[msg.sender], "User is blocked from CoreBook");
        _;
    }

    modifier notRestrictedTokens(IERC20 sellToken, IERC20[] memory buyTokens) {
        require(!restrictedTokens[sellToken], "Sell token is restricted");
        for(uint i = 0; i < buyTokens.length; i++) {
            require(!restrictedTokens[buyTokens[i]], "Buy token is restricted");
        }
        _;
    }

    modifier onlyUpdaters() {
        require(updaters[msg.sender], 'Only updaters allowed');
        _;
    }

    /**
     * @notice Initialize the CoreBook contract and populate configuration values.
     * @dev This function can only be called once.
     */
    function initialize( 
        address _wcore,
        uint256 _initialCOREPrice,
        uint256 _fees,
        address payable _taxWallet, 
        uint16 _tax
    ) external initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        wCORE = _wcore;
        CORE_Price = _initialCOREPrice;
        ListingFeeUSD = _fees;
        CancelFeeUSD = _fees;
        taxWallet = _taxWallet;
        tax = _tax;
        currentId = 1;

        emit COREPriceUpdated(_initialCOREPrice, 0, block.timestamp);
        emit ListingFeeUpdated(_fees, 0, block.timestamp);
        emit CancelFeeUpdated(_fees, 0, block.timestamp);
    }

    receive() external override payable {
        emit Received(msg.sender, msg.value);
    }

    // Order Creation and Management Functions

    /**
     * @notice Creates an order to sell an ERC20 token.
     * @dev For orders selling CORE use createOrderCore()
     * @param _sellToken The ERC20 token to be sold
     * @param _sellAmount The amount of _sellToken to be sold
     * @param _buyTokens The ERC20 token(s) to accept as payment. Can use wCORE for CORE
     * @param _buyAmounts The token amount(s) required to buy
     * @param _allOrNone Whether to allow buyers to purchase partial amounts of the sell order
     */
     function createOrderERC20(
        IERC20 _sellToken, 
        uint256 _sellAmount, 
        IERC20[] memory _buyTokens, 
        uint256[] memory _buyAmounts, 
        bool _allOrNone
    ) external override payable notPaused notRestrictedUser notRestrictedTokens(_sellToken, _buyTokens) nonReentrant {
        uint256 listingFeeCORE = ((ListingFeeUSD * 10**18) / CORE_Price);
        require(msg.value == listingFeeCORE, 'Listing Fee not covered');
        uint32 _startTime = uint32(block.timestamp);
        uint32 _endTime = type(uint32).max;
        uint256 _orderId = currentId++;

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = _sellToken;
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = _startTime;
        orderId[_orderId].endTime = _endTime;
        orderId[_orderId].tax = tax;

        for(uint i = 0; i < _buyTokens.length; i++) {
            _addToPairArray2(address(_sellToken), address(_buyTokens[i]), _orderId);
        }
        activeOrderCount++;
        userOrders[msg.sender].push(_orderId);

        _sellToken.safeTransferFrom(msg.sender, address(this), _sellAmount);
        _safeTransferETHWithFallback(taxWallet, listingFeeCORE);

        emit OrderCreated(_orderId, _startTime, _endTime, _sellToken, _sellAmount, _buyTokens, _buyAmounts);
    }

    /**
     * @notice Creates an order to sell CORE for ERC20 token(s).
     * @dev For orders selling ERC20 tokens use createOrderERC20()
     * @param _sellAmount The amount of CORE to be sold
     * @param _buyTokens The ERC20 token(s) to accept as payment
     * @param _buyAmounts The token amount(s) required to buy
     * @param _allOrNone Whether to allow buyers to purchase partial amounts of the sell order
     */
     function createOrderCore(
        uint256 _sellAmount, 
        IERC20[] memory _buyTokens, 
        uint256[] memory _buyAmounts, 
        bool _allOrNone
    ) external override payable notPaused notRestrictedUser notRestrictedTokens(IERC20(wCORE), _buyTokens) nonReentrant {
        uint256 listingFeeCORE = ((ListingFeeUSD * 10**18) / CORE_Price);
        require(_sellAmount + listingFeeCORE == msg.value, 'Wrong CORE amount sent');
        uint32 _startTime = uint32(block.timestamp);
        uint32 _endTime = type(uint32).max;
        uint256 _orderId = currentId++;

        orderId[_orderId].lister = payable(msg.sender);
        orderId[_orderId].sellToken = IERC20(wCORE);
        orderId[_orderId].sellAmount = _sellAmount;
        orderId[_orderId].buyTokens = _buyTokens;
        orderId[_orderId].buyAmounts = _buyAmounts;
        orderId[_orderId].allOrNone = _allOrNone;
        orderId[_orderId].startTime = _startTime;
        orderId[_orderId].endTime = _endTime;
        orderId[_orderId].tax = tax;

        for(uint i = 0; i < _buyTokens.length; i++) {
            _addToPairArray2(wCORE, address(_buyTokens[i]), _orderId);
        }
        activeOrderCount++;
        userOrders[msg.sender].push(_orderId);

        _safeTransferETHWithFallback(taxWallet, listingFeeCORE);

        emit OrderCreated(_orderId, _startTime, _endTime, IERC20(wCORE), _sellAmount, _buyTokens, _buyAmounts);
    }

    /**
     * @notice Edit _buyAmounts for all _buyTokens in an existing order.
     * @dev Only callable by Lister
     * @dev _buyToken Array must match array in storage
     * @param _id The OrderId to be updated 
     * @param _buyTokens The ERC20 token(s) that exist in the order
     * @param _buyAmounts The new token amount(s) required to buy
     */
    function editOrderPricesAll(uint256 _id, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts) external override notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(_orderStatus(_id) == 1, "Order is not active");
        uint256 lt = _buyTokens.length;
        uint256 la = _buyAmounts.length;
        require(lt == la && la == orderId[_id].buyTokens.length, "Must update all prices");

        uint256 _oldBuyAmount;
        for(uint i = 0; i < lt; i++) {
            require(_buyTokens[i] == orderId[_id].buyTokens[i], "Tokens misordered");
            _oldBuyAmount = orderId[_id].buyAmounts[i];
            orderId[_id].buyAmounts[i] = _buyAmounts[i];
            emit OrderSinglePriceEdited(_id, _buyTokens[i], _oldBuyAmount, _buyAmounts[i]);
        }
    }

    /**
     * @notice Edit _buyAmounts for a single _buyToken in an existing order.
     * @dev Only callable by Lister
     * @dev The _buyToken must exist at specified _index
     * @param _id The OrderId to be updated
     * @param _index The index that the _buyToken is at in storage 
     * @param _buyToken The ERC20 token that exists in the order
     * @param _buyAmount The new token amount required to buy
     */
     function editOrderPriceSingle(uint256 _id, uint256 _index, IERC20 _buyToken, uint256 _buyAmount) external override notPaused nonReentrant {
        require(msg.sender == orderId[_id].lister, "Only Lister can edit");
        require(_orderStatus(_id) == 1, "Order is not active");
        require(_buyToken == orderId[_id].buyTokens[_index], "Token does not exist at index");

        uint256 _oldBuyAmount = orderId[_id].buyAmounts[_index];
        orderId[_id].buyAmounts[_index] = _buyAmount;

        emit OrderSinglePriceEdited(_id, _buyToken, _oldBuyAmount, _buyAmount);
    }

    /**
     * @notice Claim refund on an expired sell order.
     * @dev Only callable by Lister
     * @param _id The OrderId to be refunded
     */
    function claimRefundOnExpire(uint256 _id) external override nonReentrant {
        require(msg.sender == orderId[_id].lister || msg.sender == owner(), 'Only Lister caan initiate refund');
        require(_orderStatus(_id) == 3, 'Order has not expired');
        require(!orderId[_id].failed && !orderId[_id].canceled, 'Refund already claimed');
        orderId[_id].failed = true;
        activeOrderCount--;
        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wCORE)) {
            _safeTransferETHWithFallback(orderId[_id].lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(orderId[_id].lister, orderId[_id].sellAmount);
        }
        

        emit OrderRefunded(_id, orderId[_id].lister, orderId[_id].sellToken, orderId[_id].sellAmount, msg.sender);
    }

    /**
     * @notice Cancel an active order.
     * @dev Only callable by Lister
     * @param _id The OrderId to be canceled
     */
    function cancelOrder(uint256 _id) external override payable nonReentrant {
        uint256 cancelFeeCORE = ((CancelFeeUSD * 10**18) / CORE_Price);
        require(msg.value == cancelFeeCORE, 'Cancel Fee not covered');
        address payable _lister = orderId[_id].lister;
        require(msg.sender == _lister, "Only Lister can cancel");
        require(_orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        activeOrderCount--;

        IERC20 _token = orderId[_id].sellToken;
        IERC20[] memory buyTokens = orderId[_id].buyTokens;
        for(uint i = 0; i < buyTokens.length; i++){
            bytes32 pair = _getPairHash(address(_token), address(buyTokens[i]));
            activePairOrders[pair]--;
        }

        uint256 _amount = orderId[_id].sellAmount;
        
        if(address(_token) == wCORE) {
            _safeTransferETHWithFallback(_lister, _amount);
        } else {
            _token.safeTransfer(_lister, _amount);
        }

        _safeTransferETHWithFallback(taxWallet, cancelFeeCORE);

        emit OrderCanceled(_id, _lister, _token, _amount, msg.sender, block.timestamp);
    }

    // Order Fulfillment Functions

    /**
     * @notice Buy tokens from an order with an ERC20 token.
     * @dev Matches the buyToken to the provided index
     * @param _id The OrderId to be executed
     * @param index The index of the buyToken
     * @param _token the ERC20 token to be used for the execution
     * @param _id The amount of _token to be spent on the order
     */
     function executeOrderERC20(uint256 _id, uint256 index, IERC20 _token, uint256 _amount) external override notRestrictedUser nonReentrant {
        require(_orderStatus(_id) == 1 && !orderId[_id].settled, 'Order has already been settled or canceled');
        require(block.timestamp <= orderId[_id].endTime, 'Order has expired');
        require(_token == orderId[_id].buyTokens[index], "Invalid Token");

        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            _fulfillFullOrderERC20(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            _fulfillPartialOrderERC20(msg.sender, _id, index, _token, _amount);
        }
    }

    /**
     * @notice Buy tokens from an order with CORE.
     * @dev Matches CORE to the provided index
     * @dev msg.value is the amount of CORE to be spent on the order
     * @param _id The OrderId to be executed
     * @param index The index of CORE
     */
     function executeOrderCore(uint256 _id, uint256 index) external override payable notRestrictedUser nonReentrant {
        require(_orderStatus(_id) == 1 && !orderId[_id].settled, 'Order has already been settled or canceled');
        require(block.timestamp <= orderId[_id].endTime, 'Order has expired');
        IERC20 _token = IERC20(wCORE);
        require(_token == orderId[_id].buyTokens[index], "Invalid Token");

        uint256 _amount = msg.value;
        uint256 orderBuyAmount = orderId[_id].buyAmounts[index];
        if(_amount == orderBuyAmount) {
            _fulfillFullOrderCore(msg.sender, _id, _token, _amount);
        } else {
            require(!orderId[_id].allOrNone, "Order is All or None");
            require(_amount < orderBuyAmount, "Invalid Amount");
            _fulfillPartialOrderCore(msg.sender, _id, index, _token, _amount);
        }
    }

    // Getter Functions

    /**
     * @notice Returns the order status for a given order.
     * @param _id The OrderId to be checked
     * @return The order status code
     */
     function orderStatus(uint256 _id) external override view returns (uint8) {
        return _orderStatus(_id);
    }

    /**
     * @notice Returns all active orders.
     * @return _activeOrders An array of all active OrderIds
     */
     function getAllActiveOrders() external override view returns (uint256[] memory _activeOrders) {
        uint256 length = activeOrderCount;
        _activeOrders = new uint256[](length);
        uint256 z = 0;
        for(uint256 i = 1; i <= currentId; i++) {
            if(_orderStatus(i) == 1) {
                _activeOrders[z] = i;
                z++;
            } else {
                continue;
            }
        }
    }

    /**
     * @notice Returns all orders and their statuses.
     * @return orders An array of all OrderIds
     * @return status An array of all statuses
     */
    function getAllOrders() external override view returns (uint256[] memory orders, uint8[] memory status) {
        orders = new uint256[](currentId);
        status = new uint8[](currentId);
        for(uint256 i = 1; i < currentId; i++) {
            orders[i - 1] = i;
            status[i - 1] = _orderStatus(i);
        }
    }

    /**
     * @notice Returns all active orders for a token pair.
     * @param tokenA the first token of the pair
     * @param tokenB the second token of the pair
     * @return _activeOrders An array of all active OrderIds for the given pair
     */
     function getAllActiveOrdersForPair(address tokenA, address tokenB) external override view returns (uint256[] memory _activeOrders) {
        bytes32 pair = _getPairHash(tokenA, tokenB); 
        uint256 l = activePairOrders[pair];
        uint256 m = pairs[pair].length;
        _activeOrders = new uint256[](l);
        uint256 z = 0;
        for(uint256 i = 0; i < m; i++) {
            if(_orderStatus(pairs[pair][i]) == 1) {
                _activeOrders[z] = pairs[pair][i];
                z++;
            } else {
                continue;
            }
        }
    }

    /**
     * @notice Returns all orders and statuses for a token pair.
     * @param tokenA the first token of the pair
     * @param tokenB the second token of the pair
     * @return orders An array of all OrderIds for the given pair
     * @return status An array of all statuses for the given pair
     */
     function getAllOrdersForPair(address tokenA, address tokenB) external override view returns (uint256[] memory orders, uint8[] memory status) {
        bytes32 pair = _getPairHash(tokenA, tokenB);
        orders = pairs[pair];
        uint256 length = orders.length;
        status = new uint8[](length);
        for(uint256 i = 0; i < length; i++) {
            status[i] = _orderStatus(orders[i]);
        }
    }

    /**
     * @notice Returns all buyTokens and buyAmounts for a given order.
     * @param _id The orderId to return the BuyOptions for.
     * @return buyTokens An array of all buyTokens for the given orderId
     * @return buyAmounts An array of all buyAmounts for the given orderId
     */
     function getOrderBuyOptions(uint256 _id) external override view returns (IERC20[] memory buyTokens, uint256[] memory buyAmounts) {
        buyTokens = orderId[_id].buyTokens;
        buyAmounts = orderId[_id].buyAmounts;
    }

    /**
     * @notice Returns all buyTokens and buyAmounts for a given order.
     * @param _id The orderId to return the BuyOptions for.
     */
    function getOrderInfo(
        uint256 _id
    ) external override view returns (
        address lister,
        uint32 startTime,
        uint32 endTime,
        bool allOrNone,
        uint16 orderTax,
        bool settled,
        bool canceled,
        bool failed,
        IERC20 sellToken,
        uint256 sellAmount,
        IERC20[] memory buyTokens, 
        uint256[] memory buyAmounts
    ) {
        lister = orderId[_id].lister;
        startTime = orderId[_id].startTime;
        endTime = orderId[_id].endTime;
        allOrNone = orderId[_id].allOrNone;
        orderTax = orderId[_id].tax;
        settled = orderId[_id].settled;
        canceled = orderId[_id].canceled;
        failed = orderId[_id].failed;
        sellToken = orderId[_id].sellToken;
        sellAmount = orderId[_id].sellAmount;
        buyTokens = orderId[_id].buyTokens;
        buyAmounts = orderId[_id].buyAmounts;
    }

    /**
     * @notice Returns the hash of a pair.
     * @dev Token order does not matter. tokens will be sorted.
     * @param tokenA the first token of the pair
     * @param tokenB the second token of the pair
     * @return pair A bytes32 hash of two tokens in a pair
     */
    function getPairHash(address tokenA, address tokenB) external override pure returns (bytes32 pair) {
        return _getPairHash(tokenA, tokenB);
    }

    /**
     * @notice Returns the current listing fee in CORE.
     * @return listingFeeCORE The amount of CORE needed to create an order
     */
    function getCurrentListingFee() external override view returns (uint256 listingFeeCORE) {
        return ((ListingFeeUSD * 10**18) / CORE_Price);
    }

    /**
     * @notice Returns the current cancel fee in CORE.
     * @return cancelFeeCORE The amount of CORE needed to create an order
     */
    function getCurrentCancelFee() external override view returns (uint256 cancelFeeCORE) {
        return ((CancelFeeUSD * 10**18) / CORE_Price);
    }

    // Internal Helper Functions

    function _orderStatus(uint256 _id) internal view returns (uint8) {
        if (orderId[_id].canceled) {
        return 3; // CANCELED - Lister canceled
        }
        if ((block.timestamp > orderId[_id].endTime) && !orderId[_id].settled) {
        return 3; // FAILED - not sold by end time
        }
        if (orderId[_id].settled) {
        return 2; // SUCCESS - Full order was filled
        }
        if ((block.timestamp <= orderId[_id].endTime) && !orderId[_id].settled) {
        return 1; // ACTIVE - Order is eligible for buys
        }
        return 0; // QUEUED - awaiting start time
    }

    function _addToPairArray(address sellToken, address buyToken, uint256 _id) internal {
        (address token0, address token1) = sellToken < buyToken ? (sellToken, buyToken) : (buyToken, sellToken);
        bytes32 pair = keccak256(abi.encodePacked(token0, token1));
        pairs[pair].push(_id);
        activePairOrders[pair]++;
    }

    function _addToPairArray2(address sellToken, address buyToken, uint256 _id) internal {
        (address token0, address token1) = sellToken < buyToken ? (sellToken, buyToken) : (buyToken, sellToken);
        pairs2[token0][token1].push(_id);
        activePairOrders2[token0][token1]++;
    }

    function _getPairHash(address tokenA, address tokenB) internal pure returns (bytes32 pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = keccak256(abi.encodePacked(token0, token1));
    }

    function _fulfillFullOrderERC20(address _taker, uint256 _id, IERC20 _token, uint256 _amount) internal {
        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 sellAmount = orderId[_id].sellAmount;
        uint256 taxAmount2 = sellAmount * _tax / 10000;
        uint256 finalAmount2 = sellAmount - taxAmount2;

        _token.safeTransferFrom(_taker, taxWallet, taxAmount1);
        _token.safeTransferFrom(_taker, orderId[_id].lister, finalAmount1);
        if(sellToken == IERC20(wCORE)) {
            _safeTransferETHWithFallback(taxWallet, taxAmount2);
            _safeTransferETHWithFallback(_taker, finalAmount2);
        } else {
            sellToken.safeTransfer(taxWallet, taxAmount2);
            sellToken.safeTransfer(_taker, finalAmount2);
        }

        orderId[_id].settled = true;
        IERC20[] memory buyTokens = orderId[_id].buyTokens;
        for(uint i = 0; i < buyTokens.length; i++){
            bytes32 pair = _getPairHash(address(sellToken), address(buyTokens[i]));
            activePairOrders[pair]--;
        }
        activeOrderCount--;

        emit OrderFulfilledFull(_id, _taker, orderId[_id].lister, _token, _amount, orderId[_id].sellAmount, taxAmount1, taxAmount2);
    }

    function _fulfillPartialOrderERC20(address _taker, uint256 _id, uint256 index, IERC20 _token, uint256 _amount) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 l = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < l; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 taxAmount2 = _partialSellAmount * _tax / 10000;
        uint256 finalAmount2 = _partialSellAmount - taxAmount2;

        _token.safeTransferFrom(_taker, taxWallet, taxAmount1);
        _token.safeTransferFrom(_taker, orderId[_id].lister, finalAmount1);
        if(sellToken == IERC20(wCORE)) {
            _safeTransferETHWithFallback(_taker, finalAmount2);
            _safeTransferETHWithFallback(_taker, finalAmount2);
        } else {
            sellToken.safeTransfer(taxWallet, taxAmount2);
            sellToken.safeTransfer(_taker, finalAmount2);
        }

        emit OrderFulfilledPartial(_id, _taker, orderId[_id].lister, _token, _amount, _partialSellAmount, taxAmount1, taxAmount2, orderId[_id].sellAmount);
    }

    function _fulfillFullOrderCore(address _taker, uint256 _id, IERC20 _token, uint256 _amount) internal {
        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 sellAmount = orderId[_id].sellAmount;
        uint256 taxAmount2 = sellAmount * _tax / 10000;
        uint256 finalAmount2 = sellAmount - taxAmount2;

        _safeTransferETHWithFallback(taxWallet, taxAmount1);
        _safeTransferETHWithFallback(orderId[_id].lister, finalAmount1);
        sellToken.safeTransfer(taxWallet, taxAmount2);
        sellToken.safeTransfer(_taker, finalAmount2);

        orderId[_id].settled = true;
        IERC20[] memory buyTokens = orderId[_id].buyTokens;
        for(uint i = 0; i < buyTokens.length; i++){
            bytes32 pair = _getPairHash(address(sellToken), address(buyTokens[i]));
            activePairOrders[pair]--;
        }
        activeOrderCount--;

        emit OrderFulfilledFull(_id, _taker, orderId[_id].lister, _token, _amount, orderId[_id].sellAmount, taxAmount1, taxAmount2);
    }

    function _fulfillPartialOrderCore(address _taker, uint256 _id, uint256 index, IERC20 _token, uint256 _amount) internal {
        uint256 _fullSellAmount = orderId[_id].sellAmount;
        uint256 _fullBuyAmount = orderId[_id].buyAmounts[index];
        uint256 adjuster = ((_amount * 10**18) / _fullBuyAmount);
        uint256 _partialSellAmount = ((_fullSellAmount * adjuster) / 10**18);
        orderId[_id].sellAmount -= _partialSellAmount;

        uint256 l = orderId[_id].buyTokens.length;
        uint256 b;
        uint256 n;
        for(uint i = 0; i < l; i++) {
            b = orderId[_id].buyAmounts[i];
            n = (b - ((b * adjuster) / 10**18));
            orderId[_id].buyAmounts[i] = n;
            emit OrderSinglePriceEdited(_id, orderId[_id].buyTokens[i], b, n);
        }

        uint16 _tax = orderId[_id].tax > tax ? tax : orderId[_id].tax;

        uint256 taxAmount1 = _amount * _tax / 10000;
        uint256 finalAmount1 = _amount - taxAmount1;

        IERC20 sellToken = orderId[_id].sellToken;
        uint256 taxAmount2 = _partialSellAmount * _tax / 10000;
        uint256 finalAmount2 = _partialSellAmount - taxAmount2;

        _safeTransferETHWithFallback(taxWallet, taxAmount1);
        _safeTransferETHWithFallback(orderId[_id].lister, finalAmount1);
        sellToken.safeTransfer(taxWallet, taxAmount2);
        sellToken.safeTransfer(_taker, finalAmount2);

        emit OrderFulfilledPartial(_id, _taker, orderId[_id].lister, _token, _amount, _partialSellAmount, taxAmount1, taxAmount2, orderId[_id].sellAmount);
    }
    
    /**
     * @notice Transfer ETH. If the ETH transfer fails, wrap the ETH and try send it as WETH.
     */
    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            IWETH(wCORE).deposit{ value: amount }();
            IERC20(wCORE).transfer(to, amount);
        }
    }

    /**
     * @notice Transfer ETH and return the success status.
     * @dev This function only forwards 30,000 gas to the callee.
     */
    function _safeTransferETH(address to, uint256 value) internal returns (bool) {
        (bool success, ) = to.call{ value: value, gas: 30_000 }(new bytes(0));
        return success;
    }

    // Admin Functions

    /**
     * @notice Set the isPaused status to restrict new orders.
     * @dev Only callable by owner
     * @param _flag Whether should be paused
     */
     function setPaused(bool _flag) external override onlyOwner {
        isPaused = _flag;
    }

    /**
     * @notice Set an address as an updated.
     * @dev Only callable by owner
     * @param _updater Address to grant/revoke privelege for
     * @param _flag Whether _updater should be allowed permission
     */
     function setUpdater(address _updater, bool _flag) external override onlyOwner {
        updaters[_updater] = _flag;
    }

    /**
     * @notice Set the restricted status of a token.
     * @dev Only callable by owner
     * @param token Address of the token to be updated
     * @param flag Whether token should be restricted
     */
     function setRestrictedToken(IERC20 token, bool flag) external override {
        restrictedTokens[token] = flag;
        emit TokenRestrictionUpdated(token, flag, block.timestamp);
    }

    /**
     * @notice Set the restricted status of a user.
     * @dev Only callable by owner
     * @param user Address of the user to be updated
     * @param flag Whether user should be restricted
     */
     function setRestrictedUser(address user, bool flag) external override {
        restrictedUsers[user] = flag;
        emit UserRestrictionUpdated(user, flag, block.timestamp);
    }

    /**
     * @notice Update the current price of CORE.
     * @dev Only callable by updaters
     * @param newPrice The current price of CORE adjusted to 10**9
     */
     function updateCOREPrice(uint256 newPrice) external override onlyUpdaters {
        uint256 oldPrice = CORE_Price;
        CORE_Price = newPrice;
        emit COREPriceUpdated(newPrice, oldPrice, block.timestamp);
    }

    /**
     * @notice Update the ListingFeeUSD.
     * @dev Only callable by updaters
     * @param newFee The updated fee in USD adjusted to 10**9
     */
     function updateListingFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee = ListingFeeUSD;
        ListingFeeUSD = newFee;
        emit ListingFeeUpdated(newFee, oldFee, block.timestamp);
    }

    /**
     * @notice Update the CancelFeeUSD.
     * @dev Only callable by updaters
     * @param newFee The updated fee in USD adjusted to 10**9
     */
     function updateCancelFee(uint256 newFee) external override onlyOwner {
        uint256 oldFee = CancelFeeUSD;
        CancelFeeUSD = newFee;
        emit CancelFeeUpdated(newFee, oldFee, block.timestamp);
    }

    /**
     * @notice Update the default tax percentage and taxWallet.
     * @dev Only callable by owner
     * @param _taxWallet The new wallet that tax and fees are sent to
     * @param _tax The new tax percent adjusted to 10**4
     */
     function updateTax(address payable _taxWallet, uint16 _tax) external override onlyOwner {
        taxWallet = _taxWallet;
        tax = _tax;
    }

    /**
     * @notice Emergency cancel an order by DEV, only to be used in emergencies.
     * @dev Only callable by owner
     * @param _id The orderId of the order to be cancelled
     */
     function emergencyCancelOrder(uint256 _id) external override nonReentrant onlyOwner {
        require(_orderStatus(_id) == 1, "Order is not active");
        orderId[_id].canceled = true;

        activeOrderCount--;

        IERC20 token = orderId[_id].sellToken;
        if(token == IERC20(wCORE)) {
            _safeTransferETHWithFallback(orderId[_id].lister, orderId[_id].sellAmount);
        } else {
            token.safeTransfer(orderId[_id].lister, orderId[_id].sellAmount);
        }

        emit OrderCanceled(_id, orderId[_id].lister, orderId[_id].sellToken, orderId[_id].sellAmount, msg.sender, block.timestamp);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { IERC20Upgradeable as IERC20 } from '@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol';

interface ICoreBook {

    event OrderCreated(uint256 indexed OrderId, uint256 startTime, uint256 endTime, IERC20 SellToken, uint256 SellAmount, IERC20[] BuyTokens, uint256[] BuyAmounts);
    
    event OrderSinglePriceEdited(uint256 indexed OrderId, IERC20 BuyToken, uint256 OldBuyAmount, uint256 NewBuyAmount);
    
    event OrderFulfilledFull(uint256 indexed OrderId, address Buyer, address Seller, IERC20 BuyToken, uint256 BuyAmount, uint256 SellAmount, uint256 TaxAmount1, uint256 TaxAmount2);
    
    event OrderFulfilledPartial(uint256 indexed OrderId, address Buyer, address Seller, IERC20 BuyToken, uint256 BuyAmount, uint256 SellAmount, uint256 TaxAmount1, uint256 TaxAmount2, uint256 SellAmountRemaining);
    
    event OrderRefunded(uint256 indexed OrderId, address Lister, IERC20 SellToken, uint256 SellAmountRefunded, address Caller);
    
    event OrderCanceled(uint256 indexed OrderId, address Lister, IERC20 SellToken, uint256 SellAmountRefunded, address Caller, uint256 TimeStamp);
    
    event COREPriceUpdated(uint256 NewPrice, uint256 OldPrice, uint256 UpdateTime);
    
    event ListingFeeUpdated(uint256 NewFee, uint256 OldFee, uint256 UpdateTime);
    
    event CancelFeeUpdated(uint256 NewFee, uint256 OldFee, uint256 UpdateTime);
    
    event TokenRestrictionUpdated(IERC20 indexed Token, bool Restricted, uint256 TimeStamp);
    
    event UserRestrictionUpdated(address indexed User, bool Restricted, uint256 TimeStamp);
    
    event Received(address indexed From, uint256 Amount);
    
    struct Order {
        address payable lister;
        uint32 startTime;
        uint32 endTime;
        bool allOrNone;
        uint16 tax;
        bool settled;
        bool canceled;
        bool failed;
        IERC20 sellToken;
        uint256 sellAmount;
        IERC20[] buyTokens;
        uint256[] buyAmounts;
    }

    receive() external payable;

    function createOrderERC20(IERC20 _sellToken, uint256 _sellAmount, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts, bool _allOrNone) external payable;

    function createOrderCore(uint256 _sellAmount, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts, bool _allOrNone) external payable;

    function getPairHash(address tokenA, address tokenB) external pure returns (bytes32 pair);

    function cancelOrder(uint256 _id) external payable;

    function editOrderPricesAll(uint256 _id, IERC20[] memory _buyTokens, uint256[] memory _buyAmounts) external;

    function editOrderPriceSingle(uint256 _id, uint256 _index, IERC20 _buyToken, uint256 _buyAmount) external;

    function executeOrderERC20(uint256 _id, uint256 index, IERC20 _token, uint256 _amount) external;

    function executeOrderCore(uint256 _id, uint256 index) external payable;

    function claimRefundOnExpire(uint256 _id) external;

    function emergencyCancelOrder(uint256 _id) external;

    function orderStatus(uint256 _id) external view returns (uint8);

    function getAllActiveOrders() external view returns (uint256[] memory _activeOrders);

    function getAllOrders() external view returns (uint256[] memory orders, uint8[] memory status);

    function getAllActiveOrdersForPair(address tokenA, address tokenB) external view returns (uint256[] memory _activeOrders);

    function getAllOrdersForPair(address tokenA, address tokenB) external view returns (uint256[] memory orders, uint8[] memory status);

    function getOrderBuyOptions(uint256 _id) external view returns (IERC20[] memory buyTokens, uint256[] memory buyAmounts);

    function getOrderInfo(
        uint256 _id
    ) external view returns (
        address lister,
        uint32 startTime,
        uint32 endTime,
        bool allOrNone,
        uint16 orderTax,
        bool settled,
        bool canceled,
        bool failed,
        IERC20 sellToken,
        uint256 sellAmount,
        IERC20[] memory buyTokens, 
        uint256[] memory buyAmounts
    );
    
    function getCurrentListingFee() external view returns (uint256 listingFeeCORE);
    
    function getCurrentCancelFee() external view returns (uint256 cancelFeeCORE);

    function setPaused(bool _flag) external;
    
    function setUpdater(address _updater, bool _flag) external;

    function setRestrictedToken(IERC20 token, bool flag) external;

    function setRestrictedUser(address user, bool flag) external;

    function updateCOREPrice(uint256 newPrice) external;

    function updateListingFee(uint256 newFee) external;

    function updateCancelFee(uint256 newFee) external;

    function updateTax(address payable _taxWallet, uint16 _tax) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}