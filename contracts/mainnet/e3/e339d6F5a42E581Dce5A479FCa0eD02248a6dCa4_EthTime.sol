/**
 *Submitted for verification at Etherscan.io on 2022-02-22
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/EthTime.sol
// SPDX-License-Identifier: MIT AND AGPL-3.0-only
pragma solidity =0.8.10 >=0.6.0 >=0.8.0 >=0.6.0 <0.9.0 >=0.8.0 <0.9.0;

////// lib/BokkyPooBahsDateTimeLibrary/contracts/BokkyPooBahsDateTimeLibrary.sol
/* pragma solidity >=0.6.0 <0.9.0; */

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

////// lib/base64-sol/base64.sol

/* pragma solidity >=0.6.0; */

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/utils/Strings.sol
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/solmate/src/tokens/ERC721.sol
/* pragma solidity >=0.8.0; */

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}

////// lib/solmate/src/utils/ReentrancyGuard.sol
/* pragma solidity >=0.8.0; */

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
    }
}

////// src/CharitySplitter.sol
/* pragma solidity 0.8.10; */


/// @dev Emitted when trying to set the address to something invalid.
error CharitySplitter__InvalidCharityAddress();

/// @dev Emitted when trying to set the fee to something invalid.
error CharitySplitter__InvalidCharityFee();

/// @notice Tracks splitting profits with a charity.
/// @dev This module essentialy does two things:
///  * Tracks how much money goes to the charity and how much to someone else.
///  * Implements a simple time-lock to avoid the contract owner changing the
///    charity address to one they own.
///
/// Anyone can call the method to send the funds to the charity.
contract CharitySplitter {
    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                            Constructor                               //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev Charity address, can be changed with a time-lock.
    address payable public charity;

    /// @dev Charity fee, in basis points. 1% = 100 bp.
    uint256 public charityFeeBp;

    constructor(address payable _charity, uint256 _charityFeeBp) {
        // checks: address not zero. Don't want to burn eth.
        if (_charity == address(0)) {
            revert CharitySplitter__InvalidCharityAddress();
        }

        // checks: fee > 0%. Don't want to deal with no fee edge cases.
        if (_charityFeeBp == 0) {
            revert CharitySplitter__InvalidCharityFee();
        }

        charity = _charity;
        charityFeeBp = _charityFeeBp;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                     Charity Address Management                       //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev Emitted when the charity address is updated.
    event CharityUpdated(address charity);

    /// @dev Update the charity address.
    function _updateCharity(address payable _charity)
        internal
    {
        if (_charity == address(0)) {
            revert CharitySplitter__InvalidCharityAddress();
        }

        charity = _charity;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Profit Tracking                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev Balance owed to the charity.
    uint256 public charityBalance;

    /// @dev Balance owed to the owner.
    uint256 public ownerBalance;

    /// @dev Denominator used when computing fee. 100% in bp.
    uint256 private constant BP_DENOMINATOR = 10000;

    /// @dev Update charity and owner balance.
    function _updateBalance(uint256 value)
        internal
    {
        // checks: if value is zero nothing to update.
        if (value == 0) {
            return;
        }

        uint256 charityValue = (value * charityFeeBp) / BP_DENOMINATOR;
        uint256 ownerValue = value - charityValue;

        // effects: update balances.
        charityBalance += charityValue;
        ownerBalance += ownerValue;
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                       Withdrawing Funds                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Withdraw funds to charity address.
    function _withdrawCharityBalance()
        internal
    {
        uint256 value = charityBalance;

        // checks: no money to withdraw.
        if (value == 0) {
            return;
        }

        // effects: reset charity balance to zero.
        charityBalance = 0;

        // interactions: send money to charity address.
        (bool sent, ) = charity.call{value: value}("");
        require(sent);
    }

    /// @notice Withdraw funds to owner address.
    /// @param destination the address that receives the funds.
    function _withdrawOwnerBalance(address payable destination)
        internal
    {
        uint256 value = ownerBalance;

        // checks: no money to withdraw.
        if (value == 0) {
            return;
        }

        // effects: reset owner balance to zero.
        ownerBalance = 0;

        // interactions: send money to destination address.
        (bool sent, ) = destination.call{value: value}("");
        require(sent);
    }
}

////// src/EthTime.sol
/* pragma solidity 0.8.10; */

/* import {Base64} from "@base64-sol/base64.sol"; */
/* import {BokkyPooBahsDateTimeLibrary} from "@bpb-datetime/BokkyPooBahsDateTimeLibrary.sol"; */
/* import {ERC721, ERC721TokenReceiver} from "@solmate/tokens/ERC721.sol"; */
/* import {ReentrancyGuard} from "@solmate/utils/ReentrancyGuard.sol"; */
/* import {Strings} from "@openzeppelin/utils/Strings.sol"; */
/* import {Ownable} from "@openzeppelin/access/Ownable.sol"; */

/* import {CharitySplitter} from "./CharitySplitter.sol"; */


/// @notice The NFT with the given id does not exist.
error EthTime__DoesNotExist();

/// @notice The operation requires the sender to be the owner.
error EthTime__NotOwner();

/// @notice Time offset (in minutes) is invalid.
error EthTime__InvalidTimeOffset();

/// @notice The number is outside the supported range.
error EthTime__NumberOutOfRange();

/// @notice The provided value is too low to mint.
error EthTime__InvalidMintValue();

/// @notice Trying to mint more NFTs than the amount allowed.
error EthTime__InvalidMintAmount();

/// @notice The collection has been completely minted.
error EthTime__CollectionMintClosed();

/// @notice ETH-Time NFT contract.
contract EthTime is ERC721, CharitySplitter, Ownable, ReentrancyGuard {
    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                            Constructor                               //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    constructor(address payable charity, uint256 charityFeeBp)
        ERC721("ETH Time", "ETHT")
        CharitySplitter(charity, charityFeeBp)
    {
    }

    receive() external payable {}

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                     Transfer with History                            //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice The state of each NFT.
    mapping(uint256 => uint160) public historyAccumulator;

    function transferFrom(address from, address to, uint256 id)
        public
        nonReentrant
        override
    {
        _transferFrom(from, to, id);
    }

    function safeTransferFrom(address from, address to, uint256 id)
        public
        nonReentrant
        override
    {
        _transferFrom(from, to, id);

        // interactions: check destination can handle ERC721
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(address from, address to, uint256 id, bytes memory /* data */)
        public
        nonReentrant
        override
    {
        _transferFrom(from, to, id);

        // interactions: check destination can handle ERC721
        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                        Charity Splitter                              //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Withdraw charity balance to charity address.
    /// @dev Anyone can call this at any time.
    function withdrawCharityBalance()
        public
        nonReentrant
    {
        _withdrawCharityBalance();
    }

    /// @notice Withdraw owner balance to the specified address.
    /// @param destination the address that receives the owner balance.
    function withdrawOwnerBalance(address payable destination)
        public
        onlyOwner
        nonReentrant
    {
        _withdrawOwnerBalance(destination);
    }

    /// @notice Update the address that receives the charity fee.
    /// @param charity the new charity address.
    function updateCharity(address payable charity)
        public
        onlyOwner
        nonReentrant
    {
        _updateCharity(charity);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                      Timezone Management                             //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    mapping(uint256 => int128) public timeOffsetMinutes;

    event TimeOffsetUpdated(uint256 indexed id, int128 offsetMinutes);

    /// @notice Sets the time offset of the given token id.
    /// @dev Use minutes because some timezones (like IST) are offset by half an hour.
    /// @param id the NFT unique id.
    /// @param offsetMinutes the offset in minutes.
    function setTimeOffsetMinutes(uint256 id, int128 offsetMinutes)
        public
    {
        // checks: id exists
        if (ownerOf[id] == address(0)) {
            revert EthTime__DoesNotExist();
        }

        // checks: sender is owner.
        if (ownerOf[id] != msg.sender) {
            revert EthTime__NotOwner();
        }

        // checks: validate time offset
        _validateTimeOffset(offsetMinutes);

        // effects: update time offset
        timeOffsetMinutes[id] = offsetMinutes;

        emit TimeOffsetUpdated(id, offsetMinutes);
    }

    function _validateTimeOffset(int128 offsetMinutes)
        internal
    {
        int128 offsetSeconds = offsetMinutes * 60;

        // checks: offset is  [-12, +14] hours UTC
        if (offsetSeconds > 14 hours || offsetSeconds < -12 hours) {
            revert EthTime__InvalidTimeOffset();
        }
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                              Minting                                 //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev The number of tokens minted.
    uint256 public totalSupply;

    /// @dev The maximum number of mintable tokens.
    uint256 public constant maximumSupply = 100;

    uint256 private constant TARGET_PRICE = 1 ether;
    uint256 private constant PRICE_INCREMENT = TARGET_PRICE / maximumSupply * 2;

    /// @notice Mint a new NFT, transfering ownership to the given account.
    /// @dev If the token id already exists, this method fails.
    /// @param to the NFT ower.
    /// @param offsetMinutes the time offset in minutes.
    /// @param id the NFT unique id.
    function mint(address to, int128 offsetMinutes, uint256 id)
        public
        payable
        nonReentrant
        virtual
    {
        // interactions: mint.
        uint256 valueLeft = _mint(to, offsetMinutes, id, msg.value);
    
        // interactions: send back leftover value.
        if (valueLeft > 0) {
            (bool success, ) = msg.sender.call{value: valueLeft}("");
            require(success);
        }
    }

    /// @notice Mint new NFTs, transfering ownership to the given account.
    /// @dev If any of the token ids already exists, this method fails.
    /// @param to the NFT ower.
    /// @param offsetMinutes the time offset in minutes.
    /// @param ids the NFT unique ids.
    function batchMint(address to, int128 offsetMinutes, uint256[] calldata ids)
        public
        payable
        nonReentrant
        virtual
    {
        uint256 count = ids.length;

        // checks: can mint count nfts
        _validateBatchMintCount(count);

        uint256 valueLeft = msg.value;
        for (uint256 i = 0; i < count; i++) {
            // interactions: mint.
            valueLeft = _mint(to, offsetMinutes, ids[i], valueLeft);
        }

        // interactions: send back leftover value.
        if (valueLeft > 0) {
            (bool success, ) = msg.sender.call{value: valueLeft}("");
            require(success);
        }
    }

    /// @notice Get the price for minting the next `count` NFT.
    function getBatchMintPrice(uint256 count)
        public
        view
        returns (uint256)
    {
        // checks: can mint count nfts
        _validateBatchMintCount(count);

        uint256 supply = totalSupply;
        uint256 price = 0;
        for (uint256 i = 0; i < count; i++) {
            price += _priceAtSupplyLevel(supply + i);
        }
        
        return price;
    }

    /// @notice Get the price for minting the next NFT.
    function getMintPrice()
        public
        view
        returns (uint256)
    {
        return _priceAtSupplyLevel(totalSupply);
    }

    function _mint(address to, int128 offsetMinutes, uint256 id, uint256 value)
        internal
        returns (uint256 valueLeft)
    {
        uint256 price = _priceAtSupplyLevel(totalSupply);

        // checks: value is enough to mint the nft.
        if (value < price) {
            revert EthTime__InvalidMintValue();
        }

        // checks: minting causes going over maximum supply.
        if (totalSupply == maximumSupply) {
            revert EthTime__CollectionMintClosed();
        }

        // checks: validate offset
        _validateTimeOffset(offsetMinutes);

        // effects: seed history with unique starting value.
        historyAccumulator[id] = uint160(id >> 4);

        // effects: increment total supply.
        totalSupply += 1;

        // effects: update charity split.
        _updateBalance(value);

        // effects: set time offset
        timeOffsetMinutes[id] = offsetMinutes;

        // interactions: safe mint
        _safeMint(to, id);

        // return value left to be sent back to user.
        valueLeft = value - price;
    }

    function _priceAtSupplyLevel(uint256 supply)
        internal
        pure
        returns (uint256)
    {
        uint256 price = supply * PRICE_INCREMENT;

        if (supply > 50) {
            price = TARGET_PRICE;
        }

        return price;
    }

    function _validateBatchMintCount(uint256 count)
        internal
        view
    {
        // checks: no more than 10.
        if (count > 10) {
            revert EthTime__InvalidMintAmount();
        }

        // checks: minting does not push over the limit.
        // notice that it would fail anyway.
        if (totalSupply + count > maximumSupply) {
            revert EthTime__InvalidMintAmount();
        }
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                           Token URI                                  //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @notice Returns the URI with the NFT metadata.
    /// @dev Returns the base64 encoded metadata inline.
    /// @param id the NFT unique id
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf[id] == address(0)) {
            revert EthTime__DoesNotExist();
        }

        string memory tokenId = Strings.toString(id);

        (uint256 hour, uint256 minute) = _adjustedHourMinutes(id);

        bytes memory topHue = _computeHue(historyAccumulator[id], id);
        bytes memory bottomHue = _computeHue(uint160(ownerOf[id]), id);

        int128 offset = timeOffsetMinutes[id];
        bytes memory offsetSign = offset >= 0 ? bytes('+') : bytes('-');
        uint256 offsetUnsigned = offset >= 0 ? uint256(int256(offset)) : uint256(int256(-offset));

        return
            string(
                bytes.concat(
                    'data:application/json;base64,',
                    bytes(
                        Base64.encode(
                            bytes.concat(
                                '{"name": "ETH Time #',
                                bytes(tokenId),
                                '", "description": "ETH Time", "image": "data:image/svg+xml;base64,',
                                bytes(_tokenImage(topHue, bottomHue, hour, minute)),
                                '", "attributes": [{"trait_type": "top_color", "value": "hsl(', topHue, ',100%,89%)"},',
                                '{"trait_type": "bottom_color", "value": "hsl(', bottomHue, ',77%,36%)"},',
                                '{"trait_type": "time_offset", "value": "', offsetSign, bytes(Strings.toString(offsetUnsigned)),  '"},',
                                '{"trait_type": "time", "value": "', bytes(Strings.toString(hour)), ':', bytes(Strings.toString(minute)), '"}]}'
                            )
                        )
                    )
                )
            );
    }

    /// @dev Generate a preview of the token that will be minted.
    /// @param to the minter.
    /// @param id the NFT unique id.
    function tokenImagePreview(address to, uint256 id)
        public
        view
        returns (string memory)
    {
        (uint256 hour, uint256 minute) = _adjustedHourMinutes(id);

        bytes memory topHue = _computeHue(uint160(id >> 4), id);
        bytes memory bottomHue = _computeHue(uint160(to), id);

        return _tokenImage(topHue, bottomHue, hour, minute);
    }

    //////////////////////////////////////////////////////////////////////////
    //                                                                      //
    //                         Private Functions                            //
    //                                                                      //
    //////////////////////////////////////////////////////////////////////////

    /// @dev Update the NFT history based on the transfer to the given account.
    /// @param to the address that will receive the nft.
    /// @param id the NFT unique id.
    function _updateHistory(address to, uint256 id)
        internal
    {
        // effects: xor existing value with address bytes content.
        historyAccumulator[id] ^= uint160(to) << 2;
    }

    function _transferFrom(address from, address to, uint256 id)
        internal
    {
        // checks: sender and destination
        require(from == ownerOf[id], "WRONG_FROM");
        require(to != address(0), "INVALID_RECIPIENT");

        // checks: can transfer
        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // effects: update balance
        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }

        // effects: update owership
        ownerOf[id] = to;

        // effects: reclaim storage
        delete getApproved[id];

        // effects: update history
        _updateHistory(to, id);

        emit Transfer(from, to, id);
    }

    bytes constant onColor = "FFF";
    bytes constant offColor = "333";

    /// @dev Generate the SVG image for the given NFT.
    function _tokenImage(bytes memory topHue, bytes memory bottomHue, uint256 hour, uint256 minute)
        internal
        pure
        returns (string memory)
    {

        return
            Base64.encode(
                bytes.concat(
                    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1000 1000">',
                    '<linearGradient id="bg" gradientTransform="rotate(90)">',
                    '<stop offset="0%" stop-color="hsl(', topHue, ',100%,89%)"/>',
                    '<stop offset="100%" stop-color="hsl(', bottomHue, ',77%,36%)"/>',
                    '</linearGradient>',
                    '<rect x="0" y="0" width="1000" height="1000" fill="url(#bg)"/>',
                    _binaryHour(hour),
                    _binaryMinute(minute),
                    '</svg>'
                )
            );
    }

    function _binaryHour(uint256 hour)
        internal
        pure
        returns (bytes memory)
    {
        if (hour > 24) {
            revert EthTime__NumberOutOfRange();
        }

        bytes[7] memory colors = _binaryColor(hour);

        return
            bytes.concat(
                '<circle cx="665" cy="875" r="25" fill="#', colors[0], '"/>',
                '<circle cx="665" cy="805" r="25" fill="#', colors[1], '"/>',
                // skip colors[2]
                '<circle cx="735" cy="875" r="25" fill="#', colors[3], '"/>',
                '<circle cx="735" cy="805" r="25" fill="#', colors[4], '"/>',
                '<circle cx="735" cy="735" r="25" fill="#', colors[5], '"/>',
                '<circle cx="735" cy="665" r="25" fill="#', colors[6], '"/>'
            );
    }

    function _binaryMinute(uint256 minute)
        internal
        pure
        returns (bytes memory)
    {
        if (minute > 59) {
            revert EthTime__NumberOutOfRange();
        }

        bytes[7] memory colors = _binaryColor(minute);

        return
            bytes.concat(
                '<circle cx="805" cy="875" r="25" fill="#', colors[0], '"/>',
                '<circle cx="805" cy="805" r="25" fill="#', colors[1], '"/>',
                '<circle cx="805" cy="735" r="25" fill="#', colors[2], '"/>',

                '<circle cx="875" cy="875" r="25" fill="#', colors[3], '"/>',
                '<circle cx="875" cy="805" r="25" fill="#', colors[4], '"/>',
                '<circle cx="875" cy="735" r="25" fill="#', colors[5], '"/>',
                '<circle cx="875" cy="665" r="25" fill="#', colors[6], '"/>'
            );
    }

    /// @dev Returns the colors to be used to display the time.
    /// The first 3 bytes are used for the first digit, the remaining 4 bytes
    /// for the second digit.
    function _binaryColor(uint256 n)
        internal
        pure
        returns (bytes[7] memory)
    {
        unchecked {
            uint256 firstDigit = n / 10;
            uint256 secondDigit = n % 10;

            return [
                (firstDigit & 0x1 != 0) ? onColor : offColor,
                (firstDigit & 0x2 != 0) ? onColor : offColor,
                (firstDigit & 0x4 != 0) ? onColor : offColor,

                (secondDigit & 0x1 != 0) ? onColor : offColor,
                (secondDigit & 0x2 != 0) ? onColor : offColor,
                (secondDigit & 0x4 != 0) ? onColor : offColor,
                (secondDigit & 0x8 != 0) ? onColor : offColor
            ];
        }
    }

    function _computeHue(uint160 n, uint256 id)
        internal
        pure
        returns (bytes memory)
    {
        uint160 t = n ^ uint160(id);
        uint160 acc = t % 360;
        return bytes(Strings.toString(acc));
    }

    function _adjustedHourMinutes(uint256 id)
        internal
        view
        returns (uint256 hour, uint256 minute)
    {
        int256 signedUserTimestamp = int256(block.timestamp) - 60 * timeOffsetMinutes[id];

        uint256 userTimestamp;
        // this won't realistically ever happen
        if (signedUserTimestamp <= 0) {
            userTimestamp = 0;
        } else {
            userTimestamp = uint256(signedUserTimestamp);
        }
        hour = BokkyPooBahsDateTimeLibrary.getHour(userTimestamp);
        minute = BokkyPooBahsDateTimeLibrary.getMinute(userTimestamp);
    }
}