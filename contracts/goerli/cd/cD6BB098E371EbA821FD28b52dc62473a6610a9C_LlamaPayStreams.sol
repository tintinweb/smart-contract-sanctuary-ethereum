// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

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
    //   https://aa.usno.navy.mil/faq/JD_formula.html
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

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
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
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
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
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
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

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {BoringBatchable} from "./fork/BoringBatchable.sol";

interface Factory {
    function parameter() external view returns (address);
}

interface IERC20WithDecimals {
    function decimals() external view returns (uint8);
}

// All amountPerSec and all internal numbers use 20 decimals, these are converted to the right decimal on withdrawal/deposit
// The reason for that is to minimize precision errors caused by integer math on tokens with low decimals (eg: USDC)

// Invariant through the whole contract: lastPayerUpdate[anyone] <= block.timestamp
// Reason: timestamps can't go back in time (https://github.com/ethereum/go-ethereum/blob/master/consensus/ethash/consensus.go#L274 and block timestamp definition on ethereum's yellow paper)
// and we always set lastPayerUpdate[anyone] either to the current block.timestamp or a value lower than it
// We could use this to optimize subtractions and avoid an unneded safemath check there for some gas savings
// However this is obscure enough that we are not sure if a future ethereum network upgrade might remove this assertion
// or if an ethereum fork might remove that code and invalidate the condition, causing our deployment on that chain to be vulnerable
// This is dangerous because if someone can make a timestamp go back into the past they could steal all the money
// So we forgo these optimizations and instead enforce this condition.

// Another assumption is that all timestamps can fit in uint40, this will be true until year 231,800, so it's a safe assumption

contract LlamaPay is BoringBatchable {
    using SafeERC20 for IERC20;

    struct Payer {
        uint40 lastPayerUpdate;
        uint216 totalPaidPerSec; // uint216 is enough to hold 1M streams of 3e51 tokens/yr, which is enough
    }

    mapping (bytes32 => uint) public streamToStart;
    mapping (address => Payer) public payers;
    mapping (address => uint) public balances; // could be packed together with lastPayerUpdate but gains are not high
    IERC20 public token;
    uint public DECIMALS_DIVISOR;

    event StreamCreated(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);
    event StreamCreatedWithReason(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId, string reason);
    event StreamCancelled(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);
    event StreamPaused(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId);
    event StreamModified(address indexed from, address indexed oldTo, uint216 oldAmountPerSec, bytes32 oldStreamId, address indexed to, uint216 amountPerSec, bytes32 newStreamId);
    event Withdraw(address indexed from, address indexed to, uint216 amountPerSec, bytes32 streamId, uint amount);
    event PayerDeposit(address indexed from, uint amount);
    event PayerWithdraw(address indexed from, uint amount);

    constructor(){
        token = IERC20(Factory(msg.sender).parameter());
        uint8 tokenDecimals = IERC20WithDecimals(address(token)).decimals();
        DECIMALS_DIVISOR = 10**(20 - tokenDecimals);
    }

    function getStreamId(address from, address to, uint216 amountPerSec) public pure returns (bytes32){
        return keccak256(abi.encodePacked(from, to, amountPerSec));
    }

    function _createStream(address to, uint216 amountPerSec) internal returns (bytes32 streamId){
        streamId = getStreamId(msg.sender, to, amountPerSec);
        require(amountPerSec > 0, "amountPerSec can't be 0");
        require(streamToStart[streamId] == 0, "stream already exists");
        streamToStart[streamId] = block.timestamp;

        Payer storage payer = payers[msg.sender];
        uint totalPaid;
        uint delta = block.timestamp - payer.lastPayerUpdate;
        unchecked {
            totalPaid = delta * uint(payer.totalPaidPerSec);
        }
        balances[msg.sender] -= totalPaid; // implicit check that balance >= totalPaid, can't create a new stream unless there's no debt

        payer.lastPayerUpdate = uint40(block.timestamp);
        payer.totalPaidPerSec += amountPerSec;

        // checking that no overflow will ever happen on totalPaidPerSec is important because if there's an overflow later:
        //   - if we don't have overflow checks -> it would be possible to steal money from other people
        //   - if there are overflow checks -> money will be stuck forever as all txs (from payees of the same payer) will revert
        //     which can be used to rug employees and make them unable to withdraw their earnings
        // Thus it's extremely important that no user is allowed to enter any value that later on could trigger an overflow.
        // We implicitly prevent this here because amountPerSec/totalPaidPerSec is uint216 and is only ever multiplied by timestamps
        // which will always fit in a uint40. Thus the result of the multiplication will always fit inside a uint256 and never overflow
        // This however introduces a new invariant: the only operations that can be done with amountPerSec/totalPaidPerSec are muls against timestamps
        // and we need to make sure they happen in uint256 contexts, not any other
    }

    function createStream(address to, uint216 amountPerSec) public {
        bytes32 streamId = _createStream(to, amountPerSec);
        emit StreamCreated(msg.sender, to, amountPerSec, streamId);
    }

    function createStreamWithReason(address to, uint216 amountPerSec, string calldata reason) public {
        bytes32 streamId = _createStream(to, amountPerSec);
        emit StreamCreatedWithReason(msg.sender, to, amountPerSec, streamId, reason);
    }

    /*
        proof that lastUpdate < block.timestamp:

        let's start by assuming the opposite, that lastUpdate > block.timestamp, and then we'll prove that this is impossible
        lastUpdate > block.timestamp
            -> timePaid = lastUpdate - lastPayerUpdate[from] > block.timestamp - lastPayerUpdate[from] = payerDelta
            -> timePaid > payerDelta
            -> payerBalance = timePaid * totalPaidPerSec[from] > payerDelta * totalPaidPerSec[from] = totalPayerPayment
            -> payerBalance > totalPayerPayment
        but this last statement is impossible because if it were true we'd have gone into the first if branch!
    */
    /*
        proof that totalPaidPerSec[from] != 0:

        totalPaidPerSec[from] is a sum of uint that are different from zero (since we test that on createStream())
        and we test that there's at least one stream active with `streamToStart[streamId] != 0`,
        so it's a sum of one or more elements that are higher than zero, thus it can never be zero
    */

    // Make it possible to withdraw on behalf of others, important for people that don't have a metamask wallet (eg: cex address, trustwallet...)
    function _withdraw(address from, address to, uint216 amountPerSec) private returns (uint40 lastUpdate, bytes32 streamId, uint amountToTransfer) {
        streamId = getStreamId(from, to, amountPerSec);
        require(streamToStart[streamId] != 0, "stream doesn't exist");

        Payer storage payer = payers[from];
        uint totalPayerPayment;
        uint payerDelta = block.timestamp - payer.lastPayerUpdate;
        unchecked{
            totalPayerPayment = payerDelta * uint(payer.totalPaidPerSec);
        }
        uint payerBalance = balances[from];
        if(payerBalance >= totalPayerPayment){
            unchecked {
                balances[from] = payerBalance - totalPayerPayment;   
            }
            lastUpdate = uint40(block.timestamp);
        } else {
            // invariant: totalPaidPerSec[from] != 0
            unchecked {
                uint timePaid = payerBalance/uint(payer.totalPaidPerSec);
                lastUpdate = uint40(payer.lastPayerUpdate + timePaid);
                // invariant: lastUpdate < block.timestamp (we need to maintain it)
                balances[from] = payerBalance % uint(payer.totalPaidPerSec);
            }
        }
        uint delta = lastUpdate - streamToStart[streamId]; // Could use unchecked here too I think
        unchecked {
            // We push transfers to be done outside this function and at the end of public functions to avoid reentrancy exploits
            amountToTransfer = (delta*uint(amountPerSec))/DECIMALS_DIVISOR;
        }
        emit Withdraw(from, to, amountPerSec, streamId, amountToTransfer);
    }

    // Copy of _withdraw that is view-only and returns how much can be withdrawn from a stream, purely for convenience on frontend
    // No need to review since this does nothing
    function withdrawable(address from, address to, uint216 amountPerSec) external view returns (uint withdrawableAmount, uint lastUpdate, uint owed) {
        bytes32 streamId = getStreamId(from, to, amountPerSec);
        require(streamToStart[streamId] != 0, "stream doesn't exist");

        Payer storage payer = payers[from];
        uint totalPayerPayment;
        uint payerDelta = block.timestamp - payer.lastPayerUpdate;
        unchecked{
            totalPayerPayment = payerDelta * uint(payer.totalPaidPerSec);
        }
        uint payerBalance = balances[from];
        if(payerBalance >= totalPayerPayment){
            lastUpdate = block.timestamp;
        } else {
            unchecked {
                uint timePaid = payerBalance/uint(payer.totalPaidPerSec);
                lastUpdate = payer.lastPayerUpdate + timePaid;
            }
        }
        uint delta = lastUpdate - streamToStart[streamId];
        withdrawableAmount = (delta*uint(amountPerSec))/DECIMALS_DIVISOR;
        owed = ((block.timestamp - lastUpdate)*uint(amountPerSec))/DECIMALS_DIVISOR;
    }

    function withdraw(address from, address to, uint216 amountPerSec) external {
        (uint40 lastUpdate, bytes32 streamId, uint amountToTransfer) = _withdraw(from, to, amountPerSec);
        streamToStart[streamId] = lastUpdate;
        payers[from].lastPayerUpdate = lastUpdate;
        token.safeTransfer(to, amountToTransfer);
    }

    function _cancelStream(address to, uint216 amountPerSec) internal returns (bytes32 streamId) {
        uint40 lastUpdate; uint amountToTransfer;
        (lastUpdate, streamId, amountToTransfer) = _withdraw(msg.sender, to, amountPerSec);
        streamToStart[streamId] = 0;
        Payer storage payer = payers[msg.sender];
        unchecked{
            // totalPaidPerSec is a sum of items which include amountPerSec, so totalPaidPerSec >= amountPerSec
            payer.totalPaidPerSec -= amountPerSec;
        }
        payer.lastPayerUpdate = lastUpdate;
        token.safeTransfer(to, amountToTransfer);
    }

    function cancelStream(address to, uint216 amountPerSec) public {
        bytes32 streamId = _cancelStream(to, amountPerSec);
        emit StreamCancelled(msg.sender, to, amountPerSec, streamId);
    }

    function pauseStream(address to, uint216 amountPerSec) public {
        bytes32 streamId = _cancelStream(to, amountPerSec);
        emit StreamPaused(msg.sender, to, amountPerSec, streamId);
    }

    function modifyStream(address oldTo, uint216 oldAmountPerSec, address to, uint216 amountPerSec) external {
        // Can be optimized but I don't think extra complexity is worth it
        bytes32 oldStreamId = _cancelStream(oldTo, oldAmountPerSec);
        bytes32 newStreamId = _createStream(to, amountPerSec);
        emit StreamModified(msg.sender, oldTo, oldAmountPerSec, oldStreamId, to, amountPerSec, newStreamId);
    }

    function deposit(uint amount) public {
        balances[msg.sender] += amount * DECIMALS_DIVISOR;
        token.safeTransferFrom(msg.sender, address(this), amount);
        emit PayerDeposit(msg.sender, amount);
    }

    function depositAndCreate(uint amountToDeposit, address to, uint216 amountPerSec) external {
        deposit(amountToDeposit);
        createStream(to, amountPerSec);
    }

    function depositAndCreateWithReason(uint amountToDeposit, address to, uint216 amountPerSec, string calldata reason) external {
        deposit(amountToDeposit);
        createStreamWithReason(to, amountPerSec, reason);
    }

    function withdrawPayer(uint amount) public {
        Payer storage payer = payers[msg.sender];
        balances[msg.sender] -= amount; // implicit check that balance > amount
        uint delta = block.timestamp - payer.lastPayerUpdate;
        unchecked {
            require(balances[msg.sender] >= delta*uint(payer.totalPaidPerSec), "pls no rug");
            uint tokenAmount = amount/DECIMALS_DIVISOR;
            token.safeTransfer(msg.sender, tokenAmount);
            emit PayerWithdraw(msg.sender, tokenAmount);
        }
    }

    function withdrawPayerAll() external {
        Payer storage payer = payers[msg.sender];
        unchecked {
            uint delta = block.timestamp - payer.lastPayerUpdate;
            // Just helper function, nothing happens if number is wrong
            // If there's an overflow it's just equivalent to calling withdrawPayer() directly with a big number
            withdrawPayer(balances[msg.sender]-delta*uint(payer.totalPaidPerSec));
        }
    }

    function getPayerBalance(address payerAddress) external view returns (int) {
        Payer storage payer = payers[payerAddress];
        int balance = int(balances[payerAddress]);
        uint delta = block.timestamp - payer.lastPayerUpdate;
        return (balance - int(delta*uint(payer.totalPaidPerSec)))/int(DECIMALS_DIVISOR);
    }
}

//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import {LlamaPay} from "./LlamaPay.sol";


contract LlamaPayFactory {
    bytes32 constant INIT_CODEHASH = keccak256(type(LlamaPay).creationCode);

    address public parameter;
    uint256 public getLlamaPayContractCount;
    address[1000000000] public getLlamaPayContractByIndex; // 1 billion indices

    event LlamaPayCreated(address token, address llamaPay);

    /**
        @notice Create a new Llama Pay Streaming instance for `_token`
        @dev Instances are created deterministically via CREATE2 and duplicate
            instances will cause a revert
        @param _token The ERC20 token address for which a Llama Pay contract should be deployed
        @return llamaPayContract The address of the newly created Llama Pay contract
      */
    function createLlamaPayContract(address _token) external returns (address llamaPayContract) {
        // set the parameter storage slot so the contract can query it
        parameter = _token;
        // use CREATE2 so we can get a deterministic address based on the token
        llamaPayContract = address(new LlamaPay{salt: bytes32(uint256(uint160(_token)))}());
        // CREATE2 can return address(0), add a check to verify this isn't the case
        // See: https://eips.ethereum.org/EIPS/eip-1014
        require(llamaPayContract != address(0));

        // Append the new contract address to the array of deployed contracts
        uint256 index = getLlamaPayContractCount;
        getLlamaPayContractByIndex[index] = llamaPayContract;
        unchecked{
            getLlamaPayContractCount = index + 1;
        }

        emit LlamaPayCreated(_token, llamaPayContract);
    }

    /**
      @notice Query the address of the Llama Pay contract for `_token` and whether it is deployed
      @param _token An ERC20 token address
      @return predictedAddress The deterministic address where the llama pay contract will be deployed for `_token`
      @return isDeployed Boolean denoting whether the contract is currently deployed
      */
    function getLlamaPayContractByToken(address _token) external view returns(address predictedAddress, bool isDeployed){
        predictedAddress = address(uint160(uint256(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            bytes32(uint256(uint160(_token))),
            INIT_CODEHASH
        )))));
        isDeployed = predictedAddress.code.length != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

interface IERC20Permit{
     /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20Permit token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity ^0.8.0;

import {SafeAware, ISafe} from "./SafeAware.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

// When the base contract (implementation) that proxies use is created,
// we use this no-op address when an address is needed to make contracts initialized but unusable
address constant IMPL_INIT_NOOP_ADDR = address(1);
ISafe constant IMPL_INIT_NOOP_SAFE = ISafe(payable(IMPL_INIT_NOOP_ADDR));

/**
 * @title EIP1967Upgradeable
 * @dev Minimal implementation of EIP-1967 allowing upgrades of itself by a Safe transaction
 * @dev Note that this contract doesn't have have an initializer as the implementation
 * address must already be set in the correct slot (in our case, the proxy does on creation)
 */
abstract contract EIP1967Upgradeable is SafeAware {
    event Upgraded(IModuleMetadata indexed implementation, string moduleId, uint256 version);

    // EIP1967_IMPL_SLOT = keccak256('eip1967.proxy.implementation') - 1
    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant IMPL_CONTRACT_FLAG = address(0xffff);

    // As the base contract doesn't use the implementation slot,
    // set a flag in that slot so that it is possible to detect it
    constructor() {
        address implFlag = IMPL_CONTRACT_FLAG;
        assembly {
            sstore(EIP1967_IMPL_SLOT, implFlag)
        }
    }

    /**
     * @notice Upgrades the proxy to a new implementation address
     * @dev The new implementation should be a contract that implements a way to perform upgrades as well
     * otherwise the proxy will freeze on that implementation forever, since the proxy doesn't contain logic to change it.
     * It also must conform to the IModuleMetadata interface (this is somewhat of an implicit guard against bad upgrades)
     * @param _newImplementation The address of the new implementation address the proxy will use
     */
    function upgrade(IModuleMetadata _newImplementation) public onlySafe {
        assembly {
            sstore(EIP1967_IMPL_SLOT, _newImplementation)
        }

        emit Upgraded(_newImplementation, _newImplementation.moduleId(), _newImplementation.moduleVersion());
    }

    function _implementation() internal view returns (IModuleMetadata impl) {
        assembly {
            impl := sload(EIP1967_IMPL_SLOT)
        }
    }

    /**
     * @dev Checks whether the context is foreign to the implementation
     * or the proxy by checking the EIP-1967 implementation slot.
     * If we were running in proxy context, the impl address would be stored there
     * If we were running in impl conext, the IMPL_CONTRACT_FLAG would be stored there
     */
    function _isForeignContext() internal view returns (bool) {
        return address(_implementation()) == address(0);
    }

    function _isImplementationContext() internal view returns (bool) {
        return address(_implementation()) == IMPL_CONTRACT_FLAG;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Copied and modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/ERC2771Context.sol (MIT licensed)
 */
abstract contract ERC2771Context is SafeAware {
    // SAFE_SLOT = keccak256("firm.erc2271context.forwarders") - 1
    bytes32 internal constant ERC2271_TRUSTED_FORWARDERS_BASE_SLOT =
        0xde1482070091aef895249374204bcae0fa9723215fa9357228aa489f9d1bd669;

    event TrustedForwarderSet(address indexed forwarder, bool enabled);

    function setTrustedForwarder(address forwarder, bool enabled) external onlySafe {
        _setTrustedForwarder(forwarder, enabled);
    }

    function _setTrustedForwarder(address forwarder, bool enabled) internal {
        _trustedForwarders()[forwarder] = enabled;

        emit TrustedForwarderSet(forwarder, enabled);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders()[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _trustedForwarders() internal pure returns (mapping(address => bool) storage trustedForwarders) {
        assembly {
            trustedForwarders.slot := ERC2271_TRUSTED_FORWARDERS_BASE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";
import {ERC2771Context} from "./ERC2771Context.sol";
import {EIP1967Upgradeable, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "./EIP1967Upgradeable.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

abstract contract FirmBase is EIP1967Upgradeable, ERC2771Context, IModuleMetadata {
    event Initialized(ISafe indexed safe, IModuleMetadata indexed implementation);

    function __init_firmBase(ISafe safe_, address trustedForwarder_) internal {
        // checks-effects-interactions violated so that the init event always fires first
        emit Initialized(safe_, _implementation());

        __init_setSafe(safe_);
        if (trustedForwarder_ != address(0) || trustedForwarder_ != IMPL_INIT_NOOP_ADDR) {
            _setTrustedForwarder(trustedForwarder_, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AddressUint8FlagsLib} from "./utils/AddressUint8FlagsLib.sol";

import {IRoles} from "../roles/interfaces/IRoles.sol";

uint8 constant ROLES_FLAG_TYPE = 0x01;

abstract contract RolesAuth {
    using AddressUint8FlagsLib for address;

    // ROLES_SLOT = keccak256("firm.rolesauth.roles") - 1
    bytes32 internal constant ROLES_SLOT = 0x7aaf26e54f46558e57a4624b01631a5da30fe5fe9ba2f2500c3aee185f8fb90b;

    function roles() public view returns (IRoles rolesAddr) {
        assembly {
            rolesAddr := sload(ROLES_SLOT)
        }
    }

    function _setRoles(IRoles roles_) internal {
        assembly {
            sstore(ROLES_SLOT, roles_)
        }
    }

    error UnexistentRole(uint8 roleId);

    function _validateAuthorizedAddress(address authorizedAddr) internal view {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            uint8 roleId = authorizedAddr.flagValue();
            if (!roles().roleExists(roleId)) {
                revert UnexistentRole(roleId);
            }
        }
    }

    function _isAuthorized(address actor, address authorizedAddr) internal view returns (bool) {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            return roles().hasRole(actor, authorizedAddr.flagValue());
        } else {
            return actor == authorizedAddr;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeAware
 * @dev Base contract for Firm components that need to be aware of a Safe
 * as their admin
 */
abstract contract SafeAware {
    // SAFE_SLOT = keccak256("firm.safeaware.safe") - 1
    bytes32 internal constant SAFE_SLOT = 0xb2c095c1a3cccf4bf97d6c0d6a44ba97fddb514f560087d9bf71be2c324b6c44;

    /**
     * @notice Address of the Safe that this module is tied to
     */
    function safe() public view returns (ISafe safeAddr) {
        assembly {
            safeAddr := sload(SAFE_SLOT)
        }
    }

    error SafeAddressZero();
    error AlreadyInitialized();

    /**
     * @dev Contracts that inherit from SafeAware, including derived contracts as
     * EIP1967Upgradeable or Safe, should call this function on initialization
     * Will revert if called twice
     * @param _safe The address of the GnosisSafe to use, won't be modifiable unless
     * implicitly implemented by the derived contract, which is not recommended
     */
    function __init_setSafe(ISafe _safe) internal {
        if (address(_safe) == address(0)) {
            revert SafeAddressZero();
        }
        if (address(safe()) != address(0)) {
            revert AlreadyInitialized();
        }
        assembly {
            sstore(SAFE_SLOT, _safe)
        }
    }

    error UnauthorizedNotSafe();
    /**
     * @dev Modifier to be used by derived contracts to limit access control to priviledged
     * functions so they can only be called by the Safe
     */
    modifier onlySafe() {
        if (_msgSender() != address(safe())) {
            revert UnauthorizedNotSafe();
        }

        _;
    }

    function _msgSender() internal view virtual returns (address sender); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FirmBase} from "./FirmBase.sol";
import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeModule
 * @dev More minimal implementation of Safe's Module.sol without an owner
 * and using unstructured storage
 * @dev Note that this contract doesn't have an initializer and SafeState
 * must be set explicly if desired, but defaults to being unset
 */
abstract contract SafeModule is FirmBase {
    error BadExecutionContext();

    // Sometimes it makes sense to have some code from the module ran on the Safe context
    // via a DelegateCall operation.
    // Since the functions the Safe can enter through have to be external,
    // we need to ensure that we aren't in the context of the module (or it's implementation)
    // for extra security
    // NOTE: this would break if Safe were to start using the EIP-1967 implementation slot
    // as it is how foreign context detection works
    modifier onlyForeignContext() {
        if (!_isForeignContext()) {
            revert BadExecutionContext();
        }
        _;
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExec(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success)
    {
        return safe().execTransactionFromModule(to, value, data, operation);
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * and returns the call status and the return data of the call
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExecAndReturnData(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success, bytes memory returnData)
    {
        return safe().execTransactionFromModuleReturnData(to, value, data, operation);
    }

    function _moduleExecDelegateCallToSelf(bytes memory data) internal returns (bool success) {
        return _moduleExec(address(_implementation()), 0, data, ISafe.Operation.DelegateCall);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimum viable interface of a Safe that Firm's protocol needs
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    receive() external payable;

    /**
     * @dev Allows modules to execute transactions
     * @notice Can only be called by an enabled module.
     * @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
     * @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
     */
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Returns if a certain address is an owner of this Safe
     * @return Whether the address is an owner or not
     */
    function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressUint8FlagsLib {
    // Address uint8 flag format: 0x00..00[flag uint8 byte][type of flag byte]

    // - The last byte of the address is used to signal the type of flag
    // - The second to last to store the specific uint8 being flagged
    // - All other bytes in the address must be 0
    uint256 internal constant ADDR_UINT8_FLAG_MASK = ~uint160(0xFF00);

    function isFlag(address addr, uint8 flagType) internal pure returns (bool) {
        // An address 0x00...00[roleId byte]01 is interpreted as a flag for flagType=0x01
        // Eg. In the case of roles, 0x0000000000000000000000000000000000000201 flags roleId=2
        // Therefore if any other byte other than the roleId byte or the 0x01 byte
        // is set, it will be considered not to be a valid role flag
        return (uint256(uint160(addr)) & ADDR_UINT8_FLAG_MASK) == uint256(flagType);
    }

    function flagValue(address addr) internal pure returns (uint8) {
        return uint8(uint160(addr) >> 8);
    }

    function toFlag(uint8 value, uint8 flagType) internal pure returns (address) {
        return address(uint160(uint256(value) << 8) + flagType);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {FirmBase, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";
import {SafeModule, ISafe} from "../bases/SafeModule.sol";
import {IRoles, RolesAuth} from "../bases/RolesAuth.sol";

import {TimeShiftLib, EncodedTimeShift} from "./TimeShiftLib.sol";

address constant NATIVE_ASSET = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
uint256 constant NO_PARENT_ID = 0;
uint256 constant INHERITED_AMOUNT = 0;
uint40 constant INHERITED_RESET_TIME = 0;

/**
 * @title Budget
 * @author Firm ([email protected])
 * @notice Budgeting module for efficient spending from a Safe using allowance chains
 * to delegate spending authority
 */
contract Budget is FirmBase, SafeModule, RolesAuth {
    string public constant moduleId = "org.firm.budget";
    uint256 public constant moduleVersion = 1;

    using TimeShiftLib for uint40;
    using SafeERC20 for IERC20;

    struct Allowance {
        uint256 parentId;
        uint256 amount;
        uint256 spent;
        address token;
        uint40 nextResetTime;
        address spender;
        EncodedTimeShift recurrency;
        bool isDisabled;
    }

    mapping(uint256 => Allowance) public allowances;
    uint256 public allowancesCount;

    event AllowanceCreated(
        uint256 indexed allowanceId,
        uint256 indexed parentAllowanceId,
        address indexed spender,
        address token,
        uint256 amount,
        EncodedTimeShift recurrency,
        uint40 nextResetTime,
        string name
    );
    event AllowanceStateChanged(uint256 indexed allowanceId, bool isEnabled);
    event AllowanceAmountChanged(uint256 allowanceId, uint256 amount);
    event AllowanceSpenderChanged(uint256 allowanceId, address spender);
    event AllowanceNameChanged(uint256 allowanceId, string name);
    event PaymentExecuted(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        address indexed to,
        uint256 amount,
        uint40 nextResetTime,
        string description
    );
    event MultiPaymentExecuted(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        address[] tos,
        uint256[] amounts,
        uint40 nextResetTime,
        string description
    );
    event AllowanceDebited(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        uint256 amount,
        uint40 nextResetTime,
        bytes description
    );

    error UnexistentAllowance(uint256 allowanceId);
    error DisabledAllowance(uint256 allowanceId);
    error UnauthorizedNotAllowanceAdmin(uint256 allowanceId);
    error TokenMismatch(address patentToken, address childToken);
    error InheritedAmountNotAllowed();
    error ZeroAmountPayment();
    error BadInput();
    error UnauthorizedPaymentExecution(uint256 allowanceId, address actor);
    error Overbudget(uint256 allowanceId, uint256 amount, uint256 remainingBudget);
    error PaymentExecutionFailed(uint256 allowanceId, address token, address to, uint256 amount);
    error NativeValueMismatch();

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(IMPL_INIT_NOOP_SAFE, IRoles(IMPL_INIT_NOOP_ADDR), IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, IRoles roles_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);
        _setRoles(roles_);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ALLOWANCE MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new allowance giving permission to spend funds from the Safe to a given address or addresses with a certain role
     * @dev Note 1: that child allowances can be greater than the allowed amount of its parent budget and have different recurrency
     * Note 2: It is possible to create child allowances for allowances that are disabled (either its parent disabled or any of its ancestors up to the top-level)
     * @param parentAllowanceId ID for the parent allowance (value is 0 for top-level allowances without dependencies)
     * @param spender Address or role identifier of the entities authorized to execute payments from this allowance
     * @param token Address of the token (must be the same as the parent's token)
     * @param amount Amount of token that can be spent per period
     * @param recurrency Unit of time for the allowance spent amount to be reset (value is 0 for the allowance to inherit its parent's recurrency)
     * @param name Name of the allowance being created
     * @return allowanceId ID of the allowance created
     */
    function createAllowance(
        uint256 parentAllowanceId,
        address spender,
        address token,
        uint256 amount,
        EncodedTimeShift recurrency,
        string memory name
    ) public returns (uint256 allowanceId) {
        uint40 nextResetTime;

        if (spender == address(0) || token == address(0)) {
            revert BadInput();
        }

        if (parentAllowanceId == NO_PARENT_ID) {
            // Top-level allowances can only be created by the Safe
            if (_msgSender() != address(safe())) {
                revert UnauthorizedNotSafe();
            }

            // We don't allow setting inherited amounts on top-level allowances as
            // it could be prone to a client-side mistake to send 0 as the amount which will
            // will create an allowance that allows completely wiping the safe (for the token)
            if (amount == INHERITED_AMOUNT) {
                revert InheritedAmountNotAllowed();
            }

            // For top-level allowances, recurrency needs to be set and cannot be zero (inherited)
            // applyShift reverts with InvalidTimeShift if recurrency is unspecified
            // Therefore, nextResetTime is always greater than the current time
            nextResetTime = uint40(block.timestamp).applyShift(recurrency);
        } else {
            // Reverts if parentAllowanceId doesn't exist
            Allowance storage parentAllowance = _getAllowance(parentAllowanceId);

            // Not checking whether the parentAllowance is enabled is an explicit decision
            // Disabling any allowance in a given allowance chain will result in all its
            // children not being able to execute payments
            // This allows for disabling a certain allowance to reconfigure the whole tree
            // of sub-allowances below it, before enabling it again

            // Sub-allowances can be created by entities authorized to spend from a particular allowance
            if (!_isAuthorized(_msgSender(), parentAllowance.spender)) {
                revert UnauthorizedNotAllowanceAdmin(parentAllowanceId);
            }
            if (token != parentAllowance.token) {
                revert TokenMismatch(parentAllowance.token, token);
            }
            // Recurrency can be zero in sub-allowances and is inherited from the parent
            if (!recurrency.isInherited()) {
                // If recurrency is not inherited, amount cannot be inherited
                if (amount == INHERITED_AMOUNT) {
                    revert InheritedAmountNotAllowed();
                }

                // Will revert with InvalidTimeShift if recurrency is invalid
                nextResetTime = uint40(block.timestamp).applyShift(recurrency);
            }
        }

        // Checks that if it is a role flag, a roles instance has been set and the role exists
        _validateAuthorizedAddress(spender);

        unchecked {
            // The index of the first allowance is 1, so NO_PARENT_ID can be 0 (optimization)
            allowanceId = ++allowancesCount;
        }

        Allowance storage allowance = allowances[allowanceId];
        if (parentAllowanceId != NO_PARENT_ID) {
            allowance.parentId = parentAllowanceId;
        }
        if (nextResetTime != INHERITED_RESET_TIME) {
            allowance.recurrency = recurrency;
            allowance.nextResetTime = nextResetTime;
        }
        allowance.spender = spender;
        allowance.token = token;
        allowance.amount = amount;

        emit AllowanceCreated(allowanceId, parentAllowanceId, spender, token, amount, recurrency, nextResetTime, name);
    }

    /**
     * @notice Changes the enabled/disabled state of the allowance
     * @dev Note: Disabling an allowance will implicitly disable payments from all its descendant allowances
     * @param allowanceId ID of the allowance whose state is being changed
     * @param isEnabled Whether to enable or disable the allowance
     */
    function setAllowanceState(uint256 allowanceId, bool isEnabled) external {
        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);
        allowance.isDisabled = !isEnabled;
        emit AllowanceStateChanged(allowanceId, isEnabled);
    }

    /**
     * @notice Changes the amount that an allowance can spend
     * @dev Note: It is possible to decrease the amount in an allowance to a smaller amount of what's already been spent
     * which will cause the allowance not to be able to execute any more payments until it resets (and the new amount will be enforced)
     * @param allowanceId ID of the allowance whose amount is being changed
     * @param amount New allowance amount to be set
     */
    function setAllowanceAmount(uint256 allowanceId, uint256 amount) external {
        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);

        // Same checks for what allowances can have an inherited amount as in the creation
        if (amount == INHERITED_AMOUNT && (allowance.parentId == NO_PARENT_ID || !allowance.recurrency.isInherited())) {
            revert InheritedAmountNotAllowed();
        }

        allowance.amount = amount;
        emit AllowanceAmountChanged(allowanceId, amount);
    }

    /**
     * @notice Changes the spender of an allowance
     * @dev Note: Changing the spender also changes who the admin is for all the sub-allowances
     * @param allowanceId ID of the allowance whose spender is being changed
     * @param spender New spender account for the allowance
     */
    function setAllowanceSpender(uint256 allowanceId, address spender) external {
        if (spender == address(0)) {
            revert BadInput();
        }

        _validateAuthorizedAddress(spender);

        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);
        allowance.spender = spender;
        emit AllowanceSpenderChanged(allowanceId, spender);
    }

    /**
     * @notice Changes the name of an allowance
     * @dev Note: This has no on-chain side-effects and only emits an event for off-chain consumption
     * @param allowanceId ID of the allowance whose name is being changed
     * @param name New name for the allowance
     */
    function setAllowanceName(uint256 allowanceId, string memory name) external {
        _getAllowanceAndValidateAdmin(allowanceId);
        emit AllowanceNameChanged(allowanceId, name);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // PAYMENT EXECUTION
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Executes a payment from an allowance
     * @param allowanceId ID of the allowance from which the payment is made
     * @param to Address that will receive the payment
     * @param amount Amount of the allowance's token being sent
     * @param description Description of the payment
     */
    function executePayment(uint256 allowanceId, address to, uint256 amount, string memory description)
        external
        returns (uint40 nextResetTime)
    {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();

        if (!_isAuthorized(actor, allowance.spender)) {
            revert UnauthorizedPaymentExecution(allowanceId, actor);
        }

        if (amount == 0) {
            revert ZeroAmountPayment();
        }

        address token = allowance.token;

        // Make sure the payment is within budget all the way up to its top-level budget
        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, amount, add);

        if (!_performTransfer(token, to, amount)) {
            revert PaymentExecutionFailed(allowanceId, token, to, amount);
        }

        emit PaymentExecuted(allowanceId, actor, token, to, amount, nextResetTime, description);
    }

    /**
     * @notice Executes multiple payments from an allowance
     * @param allowanceId ID of the allowance from which payments are made
     * @param tos Addresses that will receive the payment
     * @param amounts Amounts of the allowance's token being sent
     * @param description Description of the payments
     */
    function executeMultiPayment(
        uint256 allowanceId,
        address[] calldata tos,
        uint256[] calldata amounts,
        string memory description
    ) external returns (uint40 nextResetTime) {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();

        if (!_isAuthorized(actor, allowance.spender)) {
            revert UnauthorizedPaymentExecution(allowanceId, actor);
        }

        uint256 count = tos.length;
        if (count == 0 || count != amounts.length) {
            revert BadInput();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < count;) {
            if (amounts[i] == 0) {
                revert ZeroAmountPayment();
            }

            totalAmount += amounts[i];

            unchecked {
                i++;
            }
        }

        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, totalAmount, add);

        address token = allowance.token;
        if (!_performMultiTransfer(token, tos, amounts)) {
            revert PaymentExecutionFailed(allowanceId, token, address(0), totalAmount);
        }

        emit MultiPaymentExecuted(allowanceId, actor, token, tos, amounts, nextResetTime, description);
    }

    /**
     * @notice Deposit funds into safe debiting funds into an allowance. Frequently used to return a payment
     * @dev Anyone is allowed to perform this action, independently of whether they could have spent funds in the first place
     * @param allowanceId ID of the allowance to be debited (along with its ancester tree)
     * @param amount Amount being debited
     * @param description Description of the debit
     */
    function debitAllowance(uint256 allowanceId, uint256 amount, bytes calldata description)
        external
        payable
        returns (uint40 nextResetTime)
    {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();
        address payable safeAddr = payable(address(safe()));
        uint256 balanceDelta = 0;

        // Since funds are going to the safe which is trusted we don't need to follow checks-effects-interactions
        // A malicious token could re-enter, but it would only have effects in allowances for that bad token
        // And we don't need to worry about 'callbacks' since the safe is always the receiver and shouldn't do it
        if (allowance.token != NATIVE_ASSET) {
            if (msg.value != 0) {
                revert NativeValueMismatch();
            }

            IERC20 token = IERC20(allowance.token);
            uint256 prevBalance = token.balanceOf(safeAddr);
            token.safeTransferFrom(actor, safeAddr, amount);
            balanceDelta = token.balanceOf(safeAddr) - prevBalance;
        } else {
            if (msg.value != amount) {
                revert NativeValueMismatch();
            }

            safeAddr.transfer(amount);
            balanceDelta = amount; // For native asset transfers, assume balance delta is the amount
        }

        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, balanceDelta, zeroCappedSub);

        emit AllowanceDebited(allowanceId, actor, allowance.token, amount, nextResetTime, description);
    }

    function _performTransfer(address token, address to, uint256 amount) internal returns (bool) {
        if (token == NATIVE_ASSET) {
            return _moduleExec(to, amount, hex"", ISafe.Operation.Call);
        } else {
            (bool callSuccess, bytes memory retData) =
                _moduleExecAndReturnData(token, 0, abi.encodeCall(IERC20.transfer, (to, amount)), ISafe.Operation.Call);

            return callSuccess && (((retData.length == 32 && abi.decode(retData, (bool))) || retData.length == 0));
        }
    }

    function _performMultiTransfer(address token, address[] calldata tos, uint256[] calldata amounts)
        internal
        returns (bool)
    {
        return _moduleExecDelegateCallToSelf(
            abi.encodeCall(this.__safeContext_performMultiTransfer, (token, tos, amounts))
        );
    }

    function __safeContext_performMultiTransfer(address token, address[] calldata tos, uint256[] calldata amounts)
        external
        onlyForeignContext
    {
        uint256 length = tos.length;

        if (token == NATIVE_ASSET) {
            for (uint256 i = 0; i < length;) {
                (bool callSuccess,) = tos[i].call{value: amounts[i]}(hex"");
                require(callSuccess);
                unchecked {
                    i++;
                }
            }
        } else {
            for (uint256 i = 0; i < length;) {
                (bool callSuccess, bytes memory retData) =
                    token.call(abi.encodeCall(IERC20.transfer, (tos[i], amounts[i])));
                require(callSuccess && (((retData.length == 32 && abi.decode(retData, (bool))) || retData.length == 0)));
                unchecked {
                    i++;
                }
            }
        }
    }

    function _getAllowanceAndValidateAdmin(uint256 allowanceId) internal view returns (Allowance storage allowance) {
        allowance = _getAllowance(allowanceId);
        if (!_isAdminOnAllowance(allowance, _msgSender())) {
            revert UnauthorizedNotAllowanceAdmin(allowance.parentId);
        }
    }

    function _getAllowance(uint256 allowanceId) internal view returns (Allowance storage allowance) {
        allowance = allowances[allowanceId];

        if (allowance.spender == address(0)) {
            revert UnexistentAllowance(allowanceId);
        }
    }

    function isAdminOnAllowance(uint256 allowanceId, address actor) public view returns (bool) {
        return _isAdminOnAllowance(_getAllowance(allowanceId), actor);
    }

    function _isAdminOnAllowance(Allowance storage allowance, address actor) internal view returns (bool) {
        // Changes to the allowance state can be done by the same entity that could
        // create that allowance in the first place (a spender of the parent allowance)
        // In the case of top-level allowances, only the safe can enable/disable them
        // For child allowances, spenders of the parent can change the state of the child
        uint256 parentId = allowance.parentId;
        return parentId == NO_PARENT_ID ? actor == address(safe()) : _isAuthorized(actor, allowances[parentId].spender);
    }

    function _checkAndUpdateAllowanceChain(
        uint256 allowanceId,
        uint256 amount,
        function(uint256, uint256) pure returns (uint256) op
    ) internal returns (uint40 nextResetTime, bool allowanceResets) {
        // Can do 'unsafely' as this function only used when allowanceId always points to an allowance which exists
        // (checked through _getAllowance or a parentId which always exists)
        Allowance storage allowance = allowances[allowanceId];

        if (allowance.isDisabled) {
            revert DisabledAllowance(allowanceId);
        }

        if (allowance.nextResetTime == INHERITED_RESET_TIME) {
            // Note that since top-level allowances are not allowed to have an inherited reset time,
            // this branch is only ever executed for sub-allowances (which always have a parentId)
            (nextResetTime, allowanceResets) = _checkAndUpdateAllowanceChain(allowance.parentId, amount, op);
        } else {
            nextResetTime = allowance.nextResetTime;

            // Reset time has past, so we need to reset the allowance
            if (uint40(block.timestamp) >= nextResetTime) {
                EncodedTimeShift recurrency = allowance.recurrency;
                // For a non-recurrent allowance, after the reset time has passed,
                // the allowance is disabled and cannot be used anymore
                if (recurrency.isNonRecurrent()) {
                    revert DisabledAllowance(allowanceId);
                } else {
                    allowanceResets = true;
                    nextResetTime = uint40(block.timestamp).applyShift(recurrency);
                    allowance.nextResetTime = nextResetTime;
                }
            }

            // Recursively update all parent allowances before checking the amounts (inheritance forces this)
            if (allowance.parentId != NO_PARENT_ID) {
                _checkAndUpdateAllowanceChain(allowance.parentId, amount, op);
            }
        }

        if (allowance.amount != INHERITED_AMOUNT) {
            uint256 spentAfter = op(allowanceResets ? 0 : allowance.spent, amount);
            if (spentAfter > allowance.amount) {
                revert Overbudget(allowanceId, amount, allowance.amount - allowance.spent);
            }

            allowance.spent = spentAfter;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function zeroCappedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Formal verification for library and formula: https://twitter.com/Zellic_io/status/1510341868021854209
import {BokkyPooBahsDateTimeLibrary as DateTimeLib} from "datetime/BokkyPooBahsDateTimeLibrary.sol";

type EncodedTimeShift is bytes6;

struct TimeShift {
    TimeShiftLib.TimeUnit unit;
    int40 offset;
}

function encode(TimeShift memory shift) pure returns (EncodedTimeShift) {
    return EncodedTimeShift.wrap(bytes6(abi.encodePacked(uint8(shift.unit), shift.offset)));
}

function decode(EncodedTimeShift encoded) pure returns (TimeShiftLib.TimeUnit unit, int40 offset) {
    uint48 encodedValue = uint48(EncodedTimeShift.unwrap(encoded));
    unit = TimeShiftLib.TimeUnit(uint8(encodedValue >> 40));
    offset = int40(uint40(uint48(encodedValue)));
}

// Note this is an efficient way to check for inherited time shifts
// Even if an offset is specified, it will be ignored, but it is still
// considered an inherited time shift
function isInherited(EncodedTimeShift encoded) pure returns (bool) {
    return EncodedTimeShift.unwrap(encoded) < 0x010000000000;
}

// Note this is an efficient way to check for non-recurrent time shifts
// Any value lower than 0x070000000000 is a recurrent time shift
function isNonRecurrent(EncodedTimeShift encoded) pure returns (bool) {
    return EncodedTimeShift.unwrap(encoded) > 0x06ffffffffff;
}

using {decode, isInherited, isNonRecurrent} for EncodedTimeShift global;
using {encode} for TimeShift global;

library TimeShiftLib {
    using TimeShiftLib for *;

    enum TimeUnit {
        Inherit,
        Daily, // 1
        Weekly, // 2
        Monthly, // 3
        Quarterly, // 4
        Semiyearly, // 5
        Yearly, // 6
        NonRecurrent
    }

    error InvalidTimeShift();

    function applyShift(uint40 time, EncodedTimeShift shift) internal pure returns (uint40) {
        (TimeUnit unit, int40 offset) = shift.decode();

        if (unit == TimeUnit.NonRecurrent) {
            // Ensure offset is positive and in the future
            // (We cast to int48 so we don't overflow for any possible uint40 value)
            if (int48(offset) > int48(uint48(time))) {
                return uint40(offset);
            } else {
                revert InvalidTimeShift();
            }
        }

        uint40 realTime = uint40(int40(time) + offset);
        (uint256 y, uint256 m, uint256 d) = realTime.toDate();

        // Gas opt: split branches for shorter paths and handle the most common cases first
        if (uint8(unit) > 3) {
            if (unit == TimeUnit.Yearly) {
                (y, m, d) = (y + 1, 1, 1);
            } else if (unit == TimeUnit.Quarterly) {
                (y, m, d) = m < 10 ? (y, (1 + (m - 1) / 3) * 3 + 1, 1) : (y + 1, 1, 1);
            } else if (unit == TimeUnit.Semiyearly) {
                (y, m, d) = m < 7 ? (y, 7, 1) : (y + 1, 1, 1);
            } else {
                revert InvalidTimeShift();
            }
        } else {
            if (unit == TimeUnit.Monthly) {
                (y, m, d) = m < 12 ? (y, m + 1, 1) : (y + 1, 1, 1);
            } else if (unit == TimeUnit.Weekly) {
                (y, m, d) = addDays(y, m, d, 8 - DateTimeLib.getDayOfWeek(realTime));
            } else if (unit == TimeUnit.Daily) {
                (y, m, d) = addDays(y, m, d, 1);
            } else {
                revert InvalidTimeShift();
            }
        }

        // All time shifts are relative to the beginning of the day UTC before removing the offset
        uint256 shiftedTs = DateTimeLib.timestampFromDateTime(y, m, d, 0, 0, 0);
        return uint40(int40(uint40(shiftedTs)) - offset);
    }

    /**
     * @dev IT WILL ONLY TRANSITION ONE MONTH IF NECESSARY
     */
    function addDays(uint256 y, uint256 m, uint256 d, uint256 daysToAdd)
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 daysInMonth = DateTimeLib._getDaysInMonth(y, m);
        uint256 d2 = d + daysToAdd;

        return d2 <= daysInMonth ? (y, m, d2) : m < 12 ? (y, m + 1, d2 - daysInMonth) : (y + 1, 1, d2 - daysInMonth);
    }

    function toDate(uint40 timestamp) internal pure returns (uint256 y, uint256 m, uint256 d) {
        return DateTimeLib._daysToDate(timestamp / 1 days);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FirmBase, ISafe, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../../bases/FirmBase.sol";

import {Budget} from "../Budget.sol";

abstract contract BudgetModule is FirmBase {
    // BUDGET_SLOT = keccak256("firm.budgetmodule.budget") - 1
    bytes32 internal constant BUDGET_SLOT = 0xc7637e5414363c2355f9e835e00d15501df0666fb3c6c5fe259b9a40aeedbc49;

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(Budget(IMPL_INIT_NOOP_ADDR), IMPL_INIT_NOOP_ADDR);
    }

    function initialize(Budget budget_, address trustedForwarder_) public {
        ISafe safe = address(budget_) != IMPL_INIT_NOOP_ADDR ? budget_.safe() : IMPL_INIT_NOOP_SAFE;

        // Will revert if already initialized
        __init_firmBase(safe, trustedForwarder_);
        assembly {
            sstore(BUDGET_SLOT, budget_)
        }
    }

    function budget() public view returns (Budget _budget) {
        assembly {
            _budget := sload(BUDGET_SLOT)
        }
    }

    error UnauthorizedNotAllowanceAdmin(uint256 allowanceId, address actor);

    modifier onlyAllowanceAdmin(uint256 allowanceId) {
        address actor = _msgSender();
        if (!budget().isAdminOnAllowance(allowanceId, actor)) {
            revert UnauthorizedNotAllowanceAdmin(allowanceId, actor);
        }

        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

library ForwarderLib {
    type Forwarder is address;

    using ForwarderLib for Forwarder;

    error ForwarderAlreadyDeployed();

    function getForwarder(bytes32 salt) internal view returns (Forwarder) {
        return getForwarder(salt, address(this));
    }

    function getForwarder(bytes32 salt, address deployer) internal pure returns (Forwarder) {
        return Forwarder.wrap(
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(bytes1(0xff), deployer, salt, keccak256(forwarderCreationCode(deployer)))
                        )
                    )
                )
            )
        );
    }

    function forwarderCreationCode(address owner) internal pure returns (bytes memory) {
        return abi.encodePacked(
            hex"60468060093d393df373",
            owner,
            hex"330360425760403d3d3d3d3d60148036106042573603803d3d373d34823560601c5af1913d913e3d9257fd5bf35b3d3dfd"
        );
    }

    function create(bytes32 salt) internal returns (Forwarder) {
        bytes memory initcode = forwarderCreationCode(address(this));
        address fwd_;

        assembly {
            fwd_ := create2(0, add(initcode, 0x20), mload(initcode), salt)
        }

        if (fwd_ == address(0)) {
            revert ForwarderAlreadyDeployed();
        }

        return Forwarder.wrap(fwd_);
    }

    function forward(Forwarder forwarder, address to, bytes memory data) internal returns (bool ok, bytes memory ret) {
        return forwarder.forward(to, 0, data);
    }

    function forward(Forwarder forwarder, address to, uint256 value, bytes memory data)
        internal
        returns (bool ok, bytes memory ret)
    {
        return forwarder.addr().call{value: value}(abi.encodePacked(data, to));
    }

    function forwardChecked(Forwarder forwarder, address to, bytes memory data) internal returns (bytes memory ret) {
        return forwarder.forwardChecked(to, 0, data);
    }

    function forwardChecked(Forwarder forwarder, address to, uint256 value, bytes memory data)
        internal
        returns (bytes memory ret)
    {
        bool ok;
        (ok, ret) = forwarder.forward(to, value, data);
        if (!ok) {
            assembly {
                revert(add(ret, 0x20), mload(ret))
            }
        }
    }

    function addr(Forwarder forwarder) internal pure returns (address) {
        return Forwarder.unwrap(forwarder);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {LlamaPay, LlamaPayFactory} from "llamapay/LlamaPayFactory.sol";
import {IERC20, IERC20Metadata} from "openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";

import {BudgetModule, Budget} from "../BudgetModule.sol";
import {ForwarderLib} from "./ForwarderLib.sol";

/**
 * @title LlamaPayStreams
 * @author Firm ([email protected])
 * @notice Budget module to manage LlamaPay v1 streams from Budget allowances
 */
contract LlamaPayStreams is BudgetModule {
    using ForwarderLib for ForwarderLib.Forwarder;

    string public constant moduleId = "org.firm.budget.llamapay-streams";
    uint256 public constant moduleVersion = 1;

    // See https://github.com/LlamaPay/llamapay/blob/90d18e11b94b02208100b3ac8756955b1b726d37/contracts/LlamaPay.sol#L16
    uint256 internal constant LLAMAPAY_DECIMALS = 20;
    LlamaPayFactory internal immutable llamaPayFactory;

    struct StreamConfig {
        bool enabled;
        IERC20 token;
        uint8 decimals;
        uint40 prepayBuffer;
    }

    mapping(uint256 => StreamConfig) public streamConfigs;

    event StreamsConfigured(uint256 indexed allowanceId, LlamaPay streamer, ForwarderLib.Forwarder forwarder);
    event PrepayBufferSet(uint256 indexed allowanceId, uint40 prepayBuffer);
    event DepositRebalanced(uint256 indexed allowanceId, bool isDeposit, uint256 amount, address sender);

    error StreamsAlreadyConfigured(uint256 allowanceId);
    error NoStreamsToRebalance(uint256 allowanceId);
    error InvalidPrepayBuffer(uint256 allowanceId);
    error StreamsNotConfigured(uint256 allowanceId);
    error UnsupportedTokenDecimals();
    error ApproveFailed(uint256 allowanceId);

    constructor(LlamaPayFactory llamaPayFactory_) {
        // NOTE: This immutable value is set in the constructor of the implementation contract
        // and all proxies will read from it as it gets saved in the bytecode
        llamaPayFactory = llamaPayFactory_;
    }

    // Note: Initialization is done in the BudgetModule.initialize since
    // LlamaPayStreams doesn't have any other state that needs to be initialized

    ////////////////////////
    // Config
    ////////////////////////

    /**
     * @notice Configure the streams for the allowance
     * @param allowanceId The allowance ID
     * @param prepayBuffer The prepay buffer in seconds
     */
    function configure(uint256 allowanceId, uint40 prepayBuffer) external onlyAllowanceAdmin(allowanceId) {
        StreamConfig storage streamConfig = streamConfigs[allowanceId];

        if (streamConfig.enabled) {
            revert StreamsAlreadyConfigured(allowanceId);
        }

        // Due to how LlamaPay v1 works, intermediate forwarder contracts are used to manage deposits
        // in LlamaPay separately for each allowance. These are the contracts that appear as payers on LlamaPay.
        (LlamaPay streamer, ForwarderLib.Forwarder forwarder) = _setupStreamsForAllowance(streamConfig, allowanceId);

        emit StreamsConfigured(allowanceId, streamer, forwarder);

        _setPrepayBuffer(allowanceId, streamConfig, prepayBuffer);
    }

    /**
     * @notice Set the prepay buffer for the allowance
     * @param allowanceId The allowance ID
     * @param prepayBuffer The prepay buffer in seconds
     */
    function setPrepayBuffer(uint256 allowanceId, uint40 prepayBuffer) external onlyAllowanceAdmin(allowanceId) {
        _setPrepayBuffer(allowanceId, _getStreamConfig(allowanceId), prepayBuffer);
        rebalance(allowanceId);
    }

    function _setPrepayBuffer(uint256 allowanceId, StreamConfig storage streamConfig, uint40 prepayBuffer) internal {
        if (prepayBuffer == 0) {
            revert InvalidPrepayBuffer(allowanceId);
        }

        streamConfig.prepayBuffer = prepayBuffer;

        emit PrepayBufferSet(allowanceId, prepayBuffer);
    }

    ////////////////////////
    // STREAM MANAGEMENT
    ////////////////////////

    /**
     * @notice Start a new stream from the allowance
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     * @param description The description of the stream
     */
    function startStream(uint256 allowanceId, address to, uint256 amountPerSec, string calldata description)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(
            allowanceId, abi.encodeCall(LlamaPay.createStreamWithReason, (to, uint216(amountPerSec), description))
        );
    }

    /**
     * @notice Modify an existing stream
     * @dev LlamaPay cancels and creates a new stream under the hood
     * @param allowanceId The allowance ID
     * @param oldTo The old recipient of the stream
     * @param oldAmountPerSec The old amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     * @param newTo The new recipient of the stream
     * @param newAmountPerSec The new amount of tokens per second to stream (Always 20 decimals for LlamaPay)
     */
    function modifyStream(
        uint256 allowanceId,
        address oldTo,
        uint256 oldAmountPerSec,
        address newTo,
        uint256 newAmountPerSec
    ) external onlyAllowanceAdmin(allowanceId) {
        _executeAndRebalance(
            allowanceId,
            abi.encodeCall(LlamaPay.modifyStream, (oldTo, uint216(oldAmountPerSec), newTo, uint216(newAmountPerSec)))
        );
    }

    /**
     * @notice Pause a stream
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second streamed (Always 20 decimals for LlamaPay)
     */
    function pauseStream(uint256 allowanceId, address to, uint256 amountPerSec)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(allowanceId, abi.encodeCall(LlamaPay.pauseStream, (to, uint216(amountPerSec))));
    }

    /**
     * @notice Cancel a stream
     * @param allowanceId The allowance ID
     * @param to The recipient of the stream
     * @param amountPerSec The amount of tokens per second streamed (Always 20 decimals for LlamaPay)
     */
    function cancelStream(uint256 allowanceId, address to, uint256 amountPerSec)
        external
        onlyAllowanceAdmin(allowanceId)
    {
        _executeAndRebalance(allowanceId, abi.encodeCall(LlamaPay.cancelStream, (to, uint216(amountPerSec))));
    }

    function _executeAndRebalance(uint256 allowanceId, bytes memory data) internal {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        IERC20 token = streamConfig.token;
        LlamaPay streamer = streamerForToken(token);
        ForwarderLib.Forwarder forwarder = ForwarderLib.getForwarder(_forwarderSalt(allowanceId, token));

        forwarder.forwardChecked(address(streamer), data);

        _rebalance(allowanceId, streamConfig, token, streamer, forwarder);
    }

    ////////////////////////
    // REBALANCING AND DEPOSIT MANAGEMENT
    ////////////////////////

    /**
     * @notice Rebalance LlamaPay deposit for streams from allowance
     * @dev This function is unprotected so it can be called by anyone who wishes to rebalance
     * @param allowanceId The allowance ID
     */
    function rebalance(uint256 allowanceId) public {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        IERC20 token = streamConfig.token;

        _rebalance(
            allowanceId,
            streamConfig,
            token,
            streamerForToken(token),
            ForwarderLib.getForwarder(_forwarderSalt(allowanceId, token))
        );
    }

    /**
     * @dev Rebalances the amount that should be deposited to LlamaPay based on the current state of the streams
     */
    function _rebalance(
        uint256 allowanceId,
        StreamConfig storage streamConfig,
        IERC20 token,
        LlamaPay streamer,
        ForwarderLib.Forwarder forwarder
    ) internal {
        uint256 existingBalance;
        uint256 targetAmount;
        {
            (uint40 lastUpdate, uint216 paidPerSec) = streamer.payers(forwarder.addr());

            if (lastUpdate == 0) {
                revert NoStreamsToRebalance(allowanceId);
            }

            existingBalance = streamer.balances(forwarder.addr());
            uint256 secondsToFund = uint40(block.timestamp) + streamConfig.prepayBuffer - lastUpdate;
            targetAmount = secondsToFund * paidPerSec;
        }

        if (targetAmount > existingBalance) {
            uint256 amount = targetAmount - existingBalance;
            uint256 tokenAmount = amount / (10 ** (LLAMAPAY_DECIMALS - streamConfig.decimals));

            if (tokenAmount == 0) {
                return;
            }

            // The first time we do a deposit, we leave one token in the forwarder
            // as a gas optimization
            bool leaveExtraToken = existingBalance == 0 && token.balanceOf(forwarder.addr()) == 0;

            budget().executePayment(
                allowanceId, forwarder.addr(), tokenAmount + (leaveExtraToken ? 1 : 0), "Streams deposit"
            );
            forwarder.forwardChecked(address(streamer), abi.encodeCall(streamer.deposit, (tokenAmount)));

            emit DepositRebalanced(allowanceId, true, tokenAmount, msg.sender);
        } else {
            uint256 amount = existingBalance - targetAmount;
            uint256 tokenAmount = amount / (10 ** (LLAMAPAY_DECIMALS - streamConfig.decimals));

            if (tokenAmount == 0) {
                return;
            }

            forwarder.forwardChecked(address(streamer), abi.encodeCall(streamer.withdrawPayer, (amount)));

            Budget budget = budget();
            if (token.allowance(forwarder.addr(), address(budget)) < tokenAmount) {
                forwarder.forwardChecked(
                    address(token), abi.encodeCall(IERC20.approve, (address(budget), type(uint256).max))
                );
            }

            forwarder.forwardChecked(
                address(budget), abi.encodeCall(budget.debitAllowance, (allowanceId, tokenAmount, "Streams withdraw"))
            );

            emit DepositRebalanced(allowanceId, false, tokenAmount, msg.sender);
        }
    }

    function _getStreamConfig(uint256 allowanceId) internal view returns (StreamConfig storage streamConfig) {
        streamConfig = streamConfigs[allowanceId];

        if (!streamConfig.enabled) {
            revert StreamsNotConfigured(allowanceId);
        }
    }

    function _setupStreamsForAllowance(StreamConfig storage streamConfig, uint256 allowanceId)
        internal
        returns (LlamaPay streamer, ForwarderLib.Forwarder forwarder)
    {
        // NOTE: Caller must have used `onlyAllowanceAdmin` modifier to ensure that the allowance exists
        (,,, address token,,,,) = budget().allowances(allowanceId);

        uint8 decimals = IERC20Metadata(token).decimals();
        if (decimals > 20) {
            revert UnsupportedTokenDecimals();
        }

        streamConfig.enabled = true;
        streamConfig.token = IERC20(token);
        streamConfig.decimals = decimals;

        (address streamer_, bool isDeployed) = llamaPayFactory.getLlamaPayContractByToken(token);
        streamer = LlamaPay(streamer_);
        if (!isDeployed) {
            llamaPayFactory.createLlamaPayContract(token);
        }

        forwarder = ForwarderLib.create(_forwarderSalt(allowanceId, IERC20(token)));
        bytes memory retData =
            forwarder.forwardChecked(address(token), abi.encodeCall(IERC20.approve, (streamer_, type(uint256).max)));
        if (retData.length > 0) {
            if (retData.length != 32 || abi.decode(retData, (bool)) == false) {
                revert ApproveFailed(allowanceId);
            }
        }
    }

    function streamerForToken(IERC20 token) public view returns (LlamaPay) {
        (address streamer,) = llamaPayFactory.getLlamaPayContractByToken(address(token));
        return LlamaPay(streamer);
    }

    function forwarderForAllowance(uint256 allowanceId) public view returns (ForwarderLib.Forwarder) {
        StreamConfig storage streamConfig = _getStreamConfig(allowanceId);
        return ForwarderLib.getForwarder(_forwarderSalt(allowanceId, streamConfig.token));
    }

    function _forwarderSalt(uint256 allowanceId, IERC20 token) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(allowanceId, token));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint8 constant ROOT_ROLE_ID = 0;
uint8 constant ROLE_MANAGER_ROLE_ID = 1;
// The last possible role is an unassingable role which is dynamic
// and having it or not depends on whether the user is an owner in the Safe
uint8 constant SAFE_OWNER_ROLE_ID = 255;

bytes32 constant ONLY_ROOT_ROLE_AS_ADMIN = bytes32(uint256(1));
bytes32 constant NO_ROLE_ADMINS = bytes32(0);

interface IRoles {
    function roleExists(uint8 roleId) external view returns (bool);
    function hasRole(address user, uint8 roleId) external view returns (bool);
}