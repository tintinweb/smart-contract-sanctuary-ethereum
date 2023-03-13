/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

pragma solidity ^0.8.15;


// 
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)
/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
        - 32075
        + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
        + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
        - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
        - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }


    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    //
    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        uint year;
        uint month;
        uint day;
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }


    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        uint fromYear;
        uint fromMonth;
        uint fromDay;
        uint toYear;
        uint toMonth;
        uint toDay;
        (fromYear, fromMonth, fromDay) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (toYear, toMonth, toDay) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

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

contract SubscriptionApp {
    bool initialized;
    address public owner;
    uint256 public defaultTotalIntervals;
    uint256 public defaultPlatformFee;
    uint256 public nextOrder;

    // Events
    event OrderCreated(
        uint256 orderId,
        address merchant,
        uint256 chargePerInterval,
        uint256 startTime,
        uint256 intervalDuration,
        address erc20,
        uint256 merchantDefaultNumberOfOrderIntervals
    );

    event OrderAccepted(
        uint256 orderId,
        address customer,
        uint256 startTime,
        uint256 approvedPeriodsRemaining
    );

    event OrderPaidOut(
        uint256 orderId,
        address customer,
        uint256 amount,
        uint256 feeAmount,
        uint256 timestamp,
        address executor // Merchant or owner address that paid out
    );

    event OrderPaidOutGasSavingMode(
        uint256 orderId,
        address customer,
        uint256 amount,
        uint256 feeAmount,
        uint256 timestamp,
        address executor // Merchant or owner address that paid out
    );

    event OrderRenewed(
        uint256 orderId,
        address customer,
        uint256 startTime,
        uint256 approvedPeriodsRemaining,
        bool orderRenewedNotExtended
    );

    event OrderCancelled(
        uint256 orderId,
        address customer
    );

    event OrderPaused(
        uint256 orderId,
        bool isPaused,
        address whoPausedIt
    );

    event OrderSetMerchantDefaultNumberOfOrderIntervals(
        uint256 orderId,
        uint256 defaultNumberOfOrderIntervals,
        address whoSetIt
    );

    event SuccessfulPay(uint256 orderId, address customer);
    event PaymentFailureBytes(bytes someData, uint256 orderId, address customer);
    event PaymentFailure(string revertString, uint256 orderId, address customer);

    event SetMerchantSpecificPlatformFee(address merchant, uint256 customPlatformFee, bool activated);

    event MerchantWithdrawERC20(address erc20, address merchant, uint256 value);
    event OwnerWithdrawERC20(address erc20, uint256 value);

    // Structs

    struct CustomerOrder {
        address customer;
        uint256 approvedPeriodsRemaining; // This number is based on the registration, it is default 36 months of reg
        uint256 firstPaymentMadeTimestamp;
        uint256 numberOfIntervalsPaid;
        bool terminated;
        uint256 amountPaidToDate;
    }

    struct Order {
        uint256 orderId;
        address merchant;
        uint256 chargePerInterval;
        uint256 startTime;
        uint256 intervalDuration;
        address erc20;
        bool paused;
        uint256 merchantDefaultNumberOfOrderIntervals;
        mapping(address => CustomerOrder) customerOrders;
    }

    /// @notice order id to order
    mapping(uint256 => Order) public orders;

    mapping(uint256 => mapping(address=> uint256[])) public customerHistoryTimestamps;
    mapping(uint256 => mapping(address=> uint256[])) public customerHistoryAmounts;
    mapping(uint256 => mapping(address=> uint256[])) public customerHistoryFeePercentages;

    mapping(address => bool) public customPlatformFeeAssigned;
    mapping(address => uint256) public customPlatformFee;

    mapping(address => uint256) public pendingOwnerWithdrawalAmountByToken;
    mapping(address => mapping (address => uint256)) public pendingMerchantWithdrawalAmountByMerchantAndToken;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(){
    }

    function initialize(uint256 _defaultPlatformFee) public{
        if(!initialized){
            defaultTotalIntervals = 36; // This is the default # of months just to show the merchants at order creation, real default comes directly from merchant now
            defaultPlatformFee = _defaultPlatformFee;
            owner = msg.sender;
            nextOrder = 0;
            initialized = true;
        }
    }

    function changeOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function changeDefaultTotalIntervals(uint _defaultTotalIntervals) public onlyOwner {
        defaultTotalIntervals = _defaultTotalIntervals;
    }

    function changeDefaultPlatformFee(uint _defaultPlatformFee) public onlyOwner {
        defaultPlatformFee = _defaultPlatformFee;
    }

    function setMerchantSpecificPlatformFee(address _merchant, uint256 _platformFee, bool _activated) public onlyOwner {
        if(_activated){
            customPlatformFeeAssigned[_merchant] = true;
            customPlatformFee[_merchant] = _platformFee;
        } else{
            // Basically, turn off specific platform fee
            // Note this means that the _platformFee argument is irrelevant, the default will be used
            customPlatformFeeAssigned[_merchant] = false;
            customPlatformFee[_merchant] = 0;
        }
        emit SetMerchantSpecificPlatformFee(_merchant, _platformFee, _activated);
    }

    function platformFee(address _merchant) public view returns (uint256) {
        if(customPlatformFeeAssigned[_merchant]){
            return customPlatformFee[_merchant];
        } else {
            return defaultPlatformFee;
        }
    }

    /// @dev CreateNewOrder
    /// @param _chargePerInterval Cost of the order every interval
    /// @param _intervalDuration The duration of the interval - seconds 9, minutes 8, hourly 7, daily 6, weekly 5, bi-weekly 4, monthly 3, quarter-year 2, bi-yearly 1, yearly 0
    /// @param _erc20 Address of the payment token
    function createNewOrder(uint256 _chargePerInterval, uint256 _intervalDuration, IERC20 _erc20, uint256 _merchantDefaultNumberOfOrderIntervals) public {
        require(_intervalDuration < 10, "Interval duration between 0 and 9");
        // Supports interface
        bool worked = false;
        if (address(_erc20).code.length > 0) {
            try _erc20.totalSupply() returns (uint v){
                if(v > 0) {
                    Order storage order = orders[nextOrder];
                    order.orderId = nextOrder;
                    order.merchant = msg.sender;
                    order.chargePerInterval = _chargePerInterval;
                    order.startTime = _getNow();
                    order.intervalDuration = _intervalDuration;
                    order.erc20 = address(_erc20);
                    order.paused = false;
                    require(_merchantDefaultNumberOfOrderIntervals > 0, "Default number of intervals must be above 0");
                    order.merchantDefaultNumberOfOrderIntervals = _merchantDefaultNumberOfOrderIntervals;

                    emit OrderCreated(
                        nextOrder,
                        msg.sender,
                        _chargePerInterval,
                        order.startTime,
                        _intervalDuration,
                        address(_erc20),
                        _merchantDefaultNumberOfOrderIntervals);

                    nextOrder = nextOrder + 1;
                    worked = true;
                } else {
                    worked = false;
                }
            } catch Error(string memory revertReason) {
                worked = false;
            } catch (bytes memory returnData) {
                worked = false;
            }
        }
        require(worked, "ERC20 token not compatible");
    }

    function getOrder(uint256 _orderId) external view returns
    (uint256 orderId, address merchant, uint256 chargePerInterval, uint256 startTime, uint256 intervalDuration, address erc20, bool paused, uint256 merchantDefaultNumberOfOrderIntervals){
        Order storage order = orders[_orderId];
        return (
        order.orderId,
        order.merchant,
        order.chargePerInterval,
        order.startTime,
        order.intervalDuration,
        order.erc20,
        order.paused,
        order.merchantDefaultNumberOfOrderIntervals
        );
    }

    function getCustomerOrder(uint256 _orderId, address _customer) external view returns
    (address customer,
        uint256 approvedPeriodsRemaining, // This number is based on the registration, it is default 36 months of reg
        uint256 firstPaymentMadeTimestamp,
        uint256 numberOfIntervalsPaid,
        bool terminated,
        uint256 amountPaidToDate){
        CustomerOrder storage order = orders[_orderId].customerOrders[_customer];
        return (
        order.customer,
        order.approvedPeriodsRemaining,
        order.firstPaymentMadeTimestamp,
        order.numberOfIntervalsPaid,
        order.terminated,
        order.amountPaidToDate
        );
    }

    function getPaymentHistoryEntry(uint256 _orderId, address _customer, uint256 _index) external view returns
    (uint256 timestamp, uint256 amount, uint256 feePercentage){
        return (
        customerHistoryTimestamps[_orderId][_customer][_index],
        customerHistoryAmounts[_orderId][_customer][_index],
        customerHistoryFeePercentages[_orderId][_customer][_index]
        );
    }

    function setMerchantDefaultNumberOfOrderIntervals(uint256 orderId, uint256 _defaultNumberOfOrderIntervals) external{
        Order storage order = orders[orderId];
        require(order.merchant == msg.sender || owner == msg.sender, "Only the merchant or owner can call");
        order.merchantDefaultNumberOfOrderIntervals = _defaultNumberOfOrderIntervals;
        emit OrderSetMerchantDefaultNumberOfOrderIntervals(orderId, _defaultNumberOfOrderIntervals, msg.sender);
    }

    function setOrderPauseState(uint256 orderId, bool isPaused) external{
        Order storage order = orders[orderId];
        require(order.merchant == msg.sender || owner == msg.sender, "Only the merchant or owner can pause");
        order.paused = isPaused;
        emit OrderPaused(orderId, isPaused, msg.sender);
    }

    /// @dev CustomerAcceptOrder and pay
    /// @param _orderId Order id
    /// @param _approvedPeriods Number of periods or months accepted
    function customerAcceptOrder(uint256 _orderId, uint256 _approvedPeriods) public {
        Order storage order = orders[_orderId];
        require(!order.paused, "Cannot process, this order is paused");
        require(order.customerOrders[msg.sender].firstPaymentMadeTimestamp == 0, "This account is already registered on this order");

        // If it is 0 use the default
        if( _approvedPeriods == 0 ){
            _approvedPeriods = order.merchantDefaultNumberOfOrderIntervals;
        }

        uint256 calculateFee = (order.chargePerInterval * platformFee(order.merchant)) / (1000);
        require(IERC20(order.erc20).allowance(msg.sender, address(this)) >= order.chargePerInterval, "Insufficient erc20 allowance");
        require(IERC20(order.erc20).balanceOf(msg.sender) >= order.chargePerInterval, "Insufficient balance first month");

        IERC20(order.erc20).transferFrom(msg.sender, owner, calculateFee);
        IERC20(order.erc20).transferFrom(msg.sender, order.merchant, (order.chargePerInterval - calculateFee));

        // Update customer histories
        customerHistoryTimestamps[_orderId][msg.sender].push(_getNow());
        customerHistoryAmounts[_orderId][msg.sender].push( order.chargePerInterval);
        customerHistoryFeePercentages[_orderId][msg.sender].push(platformFee(order.merchant));

        order.customerOrders[msg.sender] = CustomerOrder({
        customer: msg.sender,
        approvedPeriodsRemaining: _approvedPeriods,
        terminated: false,
        amountPaidToDate: order.chargePerInterval,
        firstPaymentMadeTimestamp: _getNow(),
        numberOfIntervalsPaid: 1
        });


        emit OrderAccepted(
            _orderId,
            msg.sender,
            _getNow(),
            _approvedPeriods);
    }

    // @dev BatchProcessPayment
    // @param _orderIds Order ids
    // @param _customers The customers array it must be the same length as the order id array
    function batchProcessPayment(uint256[] memory _orderIds, address[] memory _customers, bool _gasSavingMode) external {
        require(_orderIds.length == _customers.length, "The orders and customers must be equal length");

        for(uint256 i=0; i< _orderIds.length; i++){
            bool success;
            string memory revertReason;
            bytes memory revertData;
            (success, revertReason, revertData) = _processPayment(_orderIds[i], _customers[i], _gasSavingMode);
            if(success)
            {
                emit SuccessfulPay(_orderIds[i], _customers[i]);
            } else {
                if(bytes(revertReason).length > 0){
                    emit PaymentFailure(revertReason, _orderIds[i], _customers[i]);
                } else {
                    emit PaymentFailureBytes(revertData, _orderIds[i], _customers[i]);
                }
            }
        }
    }

    function _processPayment(uint256 _orderId, address _customer, bool _gasSavingMode) internal returns (bool success, string memory revert, bytes memory revertData) {
        Order storage order = orders[_orderId];
        uint256 howManyIntervalsToPay = _howManyIntervalsToPay(order, _customer);
        if(howManyIntervalsToPay > order.customerOrders[_customer].approvedPeriodsRemaining){
            howManyIntervalsToPay = order.customerOrders[_customer].approvedPeriodsRemaining;
        }
        uint256 howMuchERC20ToSend = howManyIntervalsToPay * order.chargePerInterval;
        uint256 calculateFee = (howMuchERC20ToSend * platformFee(order.merchant)) / (1000);
        bool terminated = order.customerOrders[_customer].terminated;


        if(!_gasSavingMode){
            try SubscriptionApp(this).payOutMerchantAndFeesInternalMethod(_customer, howMuchERC20ToSend, calculateFee, order.paused, terminated, order.merchant, order.erc20
            ) {
                order.customerOrders[_customer].numberOfIntervalsPaid = order.customerOrders[_customer].numberOfIntervalsPaid + howManyIntervalsToPay;
                order.customerOrders[_customer].approvedPeriodsRemaining = order.customerOrders[_customer].approvedPeriodsRemaining - howManyIntervalsToPay;
                order.customerOrders[_customer].amountPaidToDate = order.customerOrders[_customer].amountPaidToDate + howMuchERC20ToSend;

                // Update customer histories
                customerHistoryTimestamps[_orderId][_customer].push(_getNow());
                customerHistoryAmounts[_orderId][_customer].push( order.chargePerInterval);
                customerHistoryFeePercentages[_orderId][_customer].push(platformFee(order.merchant));

                emit OrderPaidOut(
                    _orderId,
                    _customer,
                    howMuchERC20ToSend,
                    calculateFee,
                    _getNow(),
                    tx.origin
                );
                return (true, "", "");
            } catch Error(string memory revertReason) {
                return (false, revertReason, "");
            } catch (bytes memory returnData) {
                return (false, "", returnData);
            }
        } else{
            // Gas saving mode holds on to balances accounting for the merchants and owner
            try SubscriptionApp(this).payOutGasSavingInternalMethod(_customer, howMuchERC20ToSend, order.paused, terminated, order.erc20
            ) {
                order.customerOrders[_customer].numberOfIntervalsPaid = order.customerOrders[_customer].numberOfIntervalsPaid + howManyIntervalsToPay;
                order.customerOrders[_customer].approvedPeriodsRemaining = order.customerOrders[_customer].approvedPeriodsRemaining - howManyIntervalsToPay;
                order.customerOrders[_customer].amountPaidToDate = order.customerOrders[_customer].amountPaidToDate + howMuchERC20ToSend;

                // Update customer histories
                customerHistoryTimestamps[_orderId][_customer].push(_getNow());
                customerHistoryAmounts[_orderId][_customer].push( order.chargePerInterval);
                customerHistoryFeePercentages[_orderId][_customer].push(platformFee(order.merchant));

                // Update balance -- this is the different part of code
                pendingOwnerWithdrawalAmountByToken[order.erc20] = calculateFee;
                pendingMerchantWithdrawalAmountByMerchantAndToken[order.merchant][order.erc20] =  howMuchERC20ToSend - calculateFee;
                // --

                emit OrderPaidOutGasSavingMode(
                    _orderId,
                    _customer,
                    howMuchERC20ToSend,
                    calculateFee,
                    _getNow(),
                    tx.origin
                );
                return (true, "", "");
            } catch Error(string memory revertReason) {
                return (false, revertReason, "");
            } catch (bytes memory returnData) {
                return (false, "", returnData);
            }
        }
    }

    function payOutMerchantAndFeesInternalMethod(
        address _customer,
        uint256 howMuchERC20ToSend,
        uint256 calculateFee,
        bool orderPaused,
        bool terminated,
        address orderMerchant,
        address orderErc20) external {
        require(msg.sender == address(this), "Internal calls only");
        require(!orderPaused, "Cannot process, this order is paused");
        require(!terminated, "This payment has been cancelled");
        require(IERC20(orderErc20).allowance(_customer, address(this)) >= howMuchERC20ToSend, "Insufficient erc20 allowance");
        require(IERC20(orderErc20).balanceOf(_customer) >= howMuchERC20ToSend, "Insufficient balance");
        IERC20(orderErc20).transferFrom(_customer, owner, calculateFee);
        IERC20(orderErc20).transferFrom(_customer, orderMerchant, (howMuchERC20ToSend - calculateFee));
    }

    function payOutGasSavingInternalMethod(
        address _customer,
        uint256 howMuchERC20ToSend,
        bool orderPaused,
        bool terminated,
        address orderErc20) external {
        require(msg.sender == address(this), "Internal calls only");
        require(!orderPaused, "Cannot process, this order is paused");
        require(!terminated, "This payment has been cancelled");
        require(IERC20(orderErc20).allowance(_customer, address(this)) >= howMuchERC20ToSend, "Insufficient erc20 allowance");
        require(IERC20(orderErc20).balanceOf(_customer) >= howMuchERC20ToSend, "Insufficient balance");
        IERC20(orderErc20).transferFrom(_customer, address(this), howMuchERC20ToSend);
    }

    // Check how much erc20 amount is ready for payment
    function _howManyIntervalsToPay(Order storage order, address _customer) internal returns (uint256){
        // Pick the mode of the invoicing
        uint256 cycleStartTime = order.startTime; // startTime to find the interval start date
        uint256 customerCycleStartTime = order.customerOrders[_customer].firstPaymentMadeTimestamp;
        uint256 numberOfIntervalsPaid = order.customerOrders[_customer].numberOfIntervalsPaid;

        require(order.intervalDuration < 10, "The cycle mode is not correctly configured");

        uint256 elapsedCycles = 0;

        // Use cycle mode in switch statement
        // We find number of cycles that have elapsed since the first payment was made, and deduce from there with how many have been numberOfIntervalsPaid
        if(order.intervalDuration == 0){
            // Yearly Payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffYears(customerCycleStartTime, _getNow()));
        } else if(order.intervalDuration == 1){
            // 6 Month Payment
            elapsedCycles = (elapsedCycles + (BokkyPooBahsDateTimeLibrary.diffMonths(customerCycleStartTime, _getNow()))/ 6);
        } else if(order.intervalDuration == 2){
            // 3 Month payment
            elapsedCycles = (elapsedCycles + (BokkyPooBahsDateTimeLibrary.diffMonths(customerCycleStartTime, _getNow()))/ 3);
        } else if(order.intervalDuration == 3){
            // Monthly payment
            // Logic for these is that we add the number of passed months
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffMonths(customerCycleStartTime, _getNow()));
        } else if (order.intervalDuration == 4){
            // Bi-weekly payment
            elapsedCycles = (elapsedCycles + (BokkyPooBahsDateTimeLibrary.diffDays(customerCycleStartTime, _getNow()) / 14));
        } else if (order.intervalDuration == 5){
            // Weekly payment
            elapsedCycles = (elapsedCycles + (BokkyPooBahsDateTimeLibrary.diffDays(customerCycleStartTime, _getNow()) / 7));
        }  else if (order.intervalDuration == 6){
            // Daily payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffDays(customerCycleStartTime, _getNow()));
        } else if (order.intervalDuration == 7){
            // Hourly payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffHours(customerCycleStartTime, _getNow()));
        }  else if (order.intervalDuration == 8){
            // Minute payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffMinutes(customerCycleStartTime, _getNow()));
        } else {
            // Second payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffSeconds(customerCycleStartTime, _getNow()));
        }

        // Return the number of chargeable cycles
        return elapsedCycles - (numberOfIntervalsPaid - 1);
    }

    // @dev customerRenewOrder
    // @param _orderIds Order ids
    // @param _approvedPeriods If renewing , it sets this amount, if extending it adds this amount
    function customerRenewOrder(uint256 _orderId, uint256 _approvedPeriods) external {
        Order storage order = orders[_orderId];

        CustomerOrder storage customerOrder = orders[_orderId].customerOrders[msg.sender];
        require(customerOrder.firstPaymentMadeTimestamp > 0, "Not valid customer to renew");
        if( _approvedPeriods == 0 ){
            _approvedPeriods = order.merchantDefaultNumberOfOrderIntervals;
        }

        if(customerOrder.terminated){
            // The order was previously cancelled
            // Pays for first month
            require(IERC20(order.erc20).allowance(msg.sender, address(this)) >= order.chargePerInterval, "Insufficient erc20 allowance");
            require(IERC20(order.erc20).balanceOf(msg.sender) >= order.chargePerInterval, "Insufficient balance first month");

            uint256 calculateFee = (order.chargePerInterval * platformFee(order.merchant)) / (1000);
            IERC20(order.erc20).transferFrom(msg.sender, owner, calculateFee);
            IERC20(order.erc20).transferFrom(msg.sender, order.merchant, (order.chargePerInterval - calculateFee));

            // Update customer histories
            customerHistoryTimestamps[_orderId][msg.sender].push(_getNow());
            customerHistoryAmounts[_orderId][msg.sender].push( order.chargePerInterval);
            customerHistoryFeePercentages[_orderId][msg.sender].push(platformFee(order.merchant));

            customerOrder.approvedPeriodsRemaining = _approvedPeriods;
            customerOrder.numberOfIntervalsPaid = 1;
            customerOrder.firstPaymentMadeTimestamp = _getNow();
            customerOrder.terminated = false;
            customerOrder.amountPaidToDate = customerOrder.amountPaidToDate + order.chargePerInterval;

            emit OrderRenewed(
                _orderId,
                msg.sender,
                _getNow(),
                _approvedPeriods,
                true);
        } else {
            customerOrder.approvedPeriodsRemaining = customerOrder.approvedPeriodsRemaining + _approvedPeriods;

            emit OrderRenewed(
                _orderId,
                msg.sender,
                customerOrder.firstPaymentMadeTimestamp,
                _approvedPeriods,
                false);
        }
    }

    // @dev CustomerCancelPayment
    // @param _orderId Order id
    // @param _customer Customer address
    function customerCancelOrder(uint256 _orderId, address _customer) external {
        Order storage order = orders[_orderId];
        require((_customer == msg.sender) || (owner == msg.sender)
            || (order.merchant == msg.sender), "Only the customer, merchant, or owner can cancel an order");
        order.customerOrders[_customer].terminated = true;
        order.customerOrders[_customer].approvedPeriodsRemaining = 0;

        emit OrderCancelled(
            _orderId,
            _customer);
    }


    function withdraw(address _erc20Token) public {
        uint256 value = 0;
        if(msg.sender == owner){
            value = pendingOwnerWithdrawalAmountByToken[_erc20Token];
            IERC20(_erc20Token).transfer(
                owner,
                value);
            pendingOwnerWithdrawalAmountByToken[_erc20Token] = 0;
            emit OwnerWithdrawERC20(_erc20Token, value);
        } else {
            value = pendingMerchantWithdrawalAmountByMerchantAndToken[msg.sender][_erc20Token];
            IERC20(_erc20Token).transfer(
                msg.sender,
                value);
            pendingMerchantWithdrawalAmountByMerchantAndToken[msg.sender][_erc20Token] = 0;
            emit MerchantWithdrawERC20(_erc20Token, msg.sender, value);
        }
    }

    function withdrawBatch(address[] memory _erc20Tokens) external {
        for(uint256 i=0; i< _erc20Tokens.length; i++){
            withdraw(_erc20Tokens[i]);
        }
    }

    function addYearsToTimestamp(uint _timestamp, uint _years) external view returns (uint newTimestamp){
        return BokkyPooBahsDateTimeLibrary.addYears(_timestamp, _years);
    }

    function addMonthsToTimestamp(uint _timestamp, uint _months) external view returns (uint newTimestamp){
        return BokkyPooBahsDateTimeLibrary.addMonths(_timestamp, _months);
    }

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}