/**
 *Submitted for verification at Etherscan.io on 2022-07-23
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
//    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
//        require(year >= 1970);
//        int _year = int(year);
//        int _month = int(month);
//        int _day = int(day);
//
//        int __days = _day
//          - 32075
//          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
//          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
//          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
//          - OFFSET19700101;
//
//        _days = uint(__days);
//    }

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

//    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
//        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
//    }
//    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
//        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
//    }
//    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//    }
//    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        uint secs = timestamp % SECONDS_PER_DAY;
//        hour = secs / SECONDS_PER_HOUR;
//        secs = secs % SECONDS_PER_HOUR;
//        minute = secs / SECONDS_PER_MINUTE;
//        second = secs % SECONDS_PER_MINUTE;
//    }
//
//    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
//        if (year >= 1970 && month > 0 && month <= 12) {
//            uint daysInMonth = _getDaysInMonth(year, month);
//            if (day > 0 && day <= daysInMonth) {
//                valid = true;
//            }
//        }
//    }
//    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
//        if (isValidDate(year, month, day)) {
//            if (hour < 24 && minute < 60 && second < 60) {
//                valid = true;
//            }
//        }
//    }
//    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        leapYear = _isLeapYear(year);
//    }
//    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
//        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
//    }
//    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
//        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
//    }
//    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
//        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
//    }
//    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        daysInMonth = _getDaysInMonth(year, month);
//    }
//    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
//        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
//            daysInMonth = 31;
//        } else if (month != 2) {
//            daysInMonth = 30;
//        } else {
//            daysInMonth = _isLeapYear(year) ? 29 : 28;
//        }
//    }
//    // 1 = Monday, 7 = Sunday
//    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
//        uint _days = timestamp / SECONDS_PER_DAY;
//        dayOfWeek = (_days + 3) % 7 + 1;
//    }
//
//    function getYear(uint timestamp) internal pure returns (uint year) {
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//    }
//    function getMonth(uint timestamp) internal pure returns (uint month) {
//        uint year;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//    }
//    function getDay(uint timestamp) internal pure returns (uint day) {
//        uint year;
//        uint month;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//    }
//    function getHour(uint timestamp) internal pure returns (uint hour) {
//        uint secs = timestamp % SECONDS_PER_DAY;
//        hour = secs / SECONDS_PER_HOUR;
//    }
//    function getMinute(uint timestamp) internal pure returns (uint minute) {
//        uint secs = timestamp % SECONDS_PER_HOUR;
//        minute = secs / SECONDS_PER_MINUTE;
//    }
//    function getSecond(uint timestamp) internal pure returns (uint second) {
//        second = timestamp % SECONDS_PER_MINUTE;
//    }
//
//    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        year += _years;
//        uint daysInMonth = _getDaysInMonth(year, month);
//        if (day > daysInMonth) {
//            day = daysInMonth;
//        }
//        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//        require(newTimestamp >= timestamp);
//    }
//    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        month += _months;
//        year += (month - 1) / 12;
//        month = (month - 1) % 12 + 1;
//        uint daysInMonth = _getDaysInMonth(year, month);
//        if (day > daysInMonth) {
//            day = daysInMonth;
//        }
//        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//        require(newTimestamp >= timestamp);
//    }
//    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
//        require(newTimestamp >= timestamp);
//    }
//    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
//        require(newTimestamp >= timestamp);
//    }
//    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
//        require(newTimestamp >= timestamp);
//    }
//    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp + _seconds;
//        require(newTimestamp >= timestamp);
//    }
//
//    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        year -= _years;
//        uint daysInMonth = _getDaysInMonth(year, month);
//        if (day > daysInMonth) {
//            day = daysInMonth;
//        }
//        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//        require(newTimestamp <= timestamp);
//    }
//    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
//        uint year;
//        uint month;
//        uint day;
//        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
//        uint yearMonth = year * 12 + (month - 1) - _months;
//        year = yearMonth / 12;
//        month = yearMonth % 12 + 1;
//        uint daysInMonth = _getDaysInMonth(year, month);
//        if (day > daysInMonth) {
//            day = daysInMonth;
//        }
//        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
//        require(newTimestamp <= timestamp);
//    }
//    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
//        require(newTimestamp <= timestamp);
//    }
//    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
//        require(newTimestamp <= timestamp);
//    }
//    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
//        require(newTimestamp <= timestamp);
//    }
//    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
//        newTimestamp = timestamp - _seconds;
//        require(newTimestamp <= timestamp);
//    }

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
//    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
//        require(fromTimestamp <= toTimestamp);
//        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
//    }
//    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
//        require(fromTimestamp <= toTimestamp);
//        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
//    }
//    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
//        require(fromTimestamp <= toTimestamp);
//        _seconds = toTimestamp - fromTimestamp;
//    }
}

contract SubscriptionApp {
    bool initialized;
    address public owner;
    uint256 public defaultTotalIntervals;
    uint256 public platformFee;
    uint256 public nextOrder;

    // Events
    event OrderCreated(
        uint256 orderId,
        address merchant,
        uint256 chargePerInterval,
        uint256 startTime,
        uint256 intervalDuration,
        address erc20
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

    // Structs

    struct PaymentHistoryEntry {
        uint256 timestamp;
        uint256 amount;
        uint256 feePercentage;
    }

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
        mapping(address => CustomerOrder) customerOrders;
    }

    /// @notice order id to order
    mapping(uint256 => Order) public orders;

    mapping(uint256 => mapping(address=> PaymentHistoryEntry[])) public customerHistories;

    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }

    constructor(){
    }

    function initialize(uint256 _platformFee) public{
        if(!initialized){
            defaultTotalIntervals = 36;
            platformFee = _platformFee;
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

    function changePlatformFee(uint _platformFee) public onlyOwner {
        platformFee = _platformFee;
    }

    /// @dev CreateNewOrder
    /// @param _chargePerInterval Cost of the order every interval
    /// @param _intervalDuration The duration of the interval - daily 6, weekly 5, bi-weekly 4, monthly 3, quarter-year 2, bi-yearly 1, yearly 0
    /// @param _erc20 Address of the payment token
    function createNewOrder(uint256 _chargePerInterval, uint256 _intervalDuration, IERC20 _erc20) public {
         require(_intervalDuration < 7, "Interval duration between 0 and 6");
         Order storage order = orders[nextOrder];
         order.orderId = nextOrder;
         order.merchant = msg.sender;
         order.chargePerInterval = _chargePerInterval;
         order.startTime = _getNow();
         order.intervalDuration = _intervalDuration;
         order.erc20 = address(_erc20);
         order.paused = false;

        emit OrderCreated(
            nextOrder,
            msg.sender,
            _chargePerInterval,
            order.startTime,
            _intervalDuration,
            address(_erc20));

        nextOrder = nextOrder + 1;
    }

    function getOrder(uint256 _orderId) external view returns
        (uint256 orderId, address merchant, uint256 chargePerInterval, uint256 startTime, uint256 intervalDuration, address erc20, bool paused){
            Order storage order = orders[_orderId];
            return (
                order.orderId,
                order.merchant,
                order.chargePerInterval,
                order.startTime,
                order.intervalDuration,
                order.erc20,
                order.paused
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
            PaymentHistoryEntry storage history = customerHistories[_orderId][_customer][_index];
            return (
                history.timestamp,
                history.amount,
                history.feePercentage
            );
    }

    function setOrderPauseState(uint256 orderId, bool isPaused) external{
        Order storage order = orders[orderId];
        require(order.merchant == msg.sender, "Only the merchant can pause");
        order.paused = isPaused;
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
            _approvedPeriods = defaultTotalIntervals;
        }

        uint256 calculateFee = (order.chargePerInterval * platformFee) / (1000);

        IERC20(order.erc20).transferFrom(msg.sender, owner, calculateFee);
        IERC20(order.erc20).transferFrom(msg.sender, order.merchant, (order.chargePerInterval - calculateFee));

        // Update customer histories
        PaymentHistoryEntry memory historical = PaymentHistoryEntry(
            {timestamp: _getNow(), amount: order.chargePerInterval, feePercentage: platformFee});

        customerHistories[_orderId][msg.sender].push(historical);

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
    function batchProcessPayment(uint256[] memory _orderIds, address[] memory _customers) public {
        require(_orderIds.length == _customers.length, "The orders and customers must be equal length");

        for(uint256 i=0; i< _orderIds.length; i++){
            _processPayment(_orderIds[i], _customers[i]);
        }
    }

    function _processPayment(uint256 _orderId, address _customer) internal {
        Order storage order = orders[_orderId];
        // Need to figure out how much erc20 is on the order to be billed
        require(!order.customerOrders[_customer].terminated, "This payment has been cancelled");
        uint256 howManyIntervalsToPay = _howManyIntervalsToPay(order, _customer);
        if(howManyIntervalsToPay > order.customerOrders[_customer].approvedPeriodsRemaining){
            howManyIntervalsToPay = order.customerOrders[_customer].approvedPeriodsRemaining;
        }

        order.customerOrders[_customer].numberOfIntervalsPaid = order.customerOrders[_customer].numberOfIntervalsPaid + howManyIntervalsToPay;
        order.customerOrders[_customer].approvedPeriodsRemaining = order.customerOrders[_customer].approvedPeriodsRemaining - howManyIntervalsToPay;

        uint256 howMuchERC20ToSend = howManyIntervalsToPay * order.chargePerInterval;

        order.customerOrders[_customer].amountPaidToDate = order.customerOrders[_customer].amountPaidToDate + howMuchERC20ToSend;

        uint256 calculateFee = (howMuchERC20ToSend * platformFee) / (1000);

        IERC20(order.erc20).transferFrom(_customer, owner, calculateFee);
        IERC20(order.erc20).transferFrom(_customer, order.merchant, (howMuchERC20ToSend - calculateFee));

        PaymentHistoryEntry memory historical = PaymentHistoryEntry(
            {timestamp: _getNow(), amount: order.chargePerInterval, feePercentage: platformFee});

        customerHistories[_orderId][_customer].push(historical);

        emit OrderPaidOut(
            _orderId,
            _customer,
            howMuchERC20ToSend,
            calculateFee,
            _getNow(),
            msg.sender
         );

    }

    // Check how much erc20 amount is ready for payment
    function _howManyIntervalsToPay(Order storage order, address _customer) internal returns (uint256){
        // Pick the mode of the invoicing
        uint256 cycleStartTime = order.startTime; // startTime to find the interval start date
        uint256 customerCycleStartTime = order.customerOrders[_customer].firstPaymentMadeTimestamp;
        uint256 numberOfIntervalsPaid = order.customerOrders[_customer].numberOfIntervalsPaid;

        require(order.intervalDuration < 7, "The cycle mode is not correctly configured");

        uint256 elapsedCycles = 0;

        // Use cycle mode in switch statement
        // We find number of cycles that have elapsed since the first payment was made, and deduce from there with how many have been numberOfIntervalsPaid
        if(order.intervalDuration == 0){
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffYears(customerCycleStartTime, _getNow()));
        } else if(order.intervalDuration == 1){
            elapsedCycles = (elapsedCycles + (BokkyPooBahsDateTimeLibrary.diffMonths(customerCycleStartTime, _getNow()))/ 6);
        } else if(order.intervalDuration == 2){
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
        } else {
            // Daily payment
            elapsedCycles = (elapsedCycles + BokkyPooBahsDateTimeLibrary.diffDays(customerCycleStartTime, _getNow()));
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
            _approvedPeriods = defaultTotalIntervals;
        }

        if(customerOrder.terminated){
            // The order was previously cancelled
            // Pays for first month
            uint256 calculateFee = (order.chargePerInterval * platformFee) / (1000);
            IERC20(order.erc20).transferFrom(msg.sender, owner, calculateFee);
            IERC20(order.erc20).transferFrom(msg.sender, order.merchant, (order.chargePerInterval - calculateFee));

            // Update customer histories
            PaymentHistoryEntry memory historical = PaymentHistoryEntry(
                {timestamp: _getNow(), amount: order.chargePerInterval, feePercentage: platformFee});

            customerHistories[_orderId][msg.sender].push(historical);

            customerOrder.approvedPeriodsRemaining = _approvedPeriods;
            customerOrder.numberOfIntervalsPaid = 1;
            customerOrder.firstPaymentMadeTimestamp = _getNow();
            customerOrder.terminated = false;

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

    function _getNow() internal virtual view returns (uint256) {
        return block.timestamp;
    }
}