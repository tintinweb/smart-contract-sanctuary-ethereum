/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.10;

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

interface ILUSDToken is IERC20 { 
    
    // --- Events ---

    event TroveManagerAddressChanged(address _troveManagerAddress);
    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event LUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

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

interface IBLUSDToken is IERC20 {
    function mint(address _to, uint256 _bLUSDAmount) external;

    function burn(address _from, uint256 _bLUSDAmount) external;
}

interface ICurvePool is IERC20 { 
    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount) external returns (uint256 mint_amount);

    function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver) external returns (uint256 mint_amount);

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts) external;

    function remove_liquidity(uint256 burn_amount, uint256[2] memory _min_amounts, address _receiver) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external;

    function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received, address _receiver) external;

    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address _receiver) external returns (uint256);

    function calc_withdraw_one_coin(uint256 _burn_amount, int128 i) external view returns (uint256);

    function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);

    function balances(uint256 arg0) external view returns (uint256);

    function token() external view returns (address);

    function totalSupply() external view returns (uint256);

    function get_dy(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_dy_underlying(int128 i,int128 j, uint256 dx) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function fee() external view returns (uint256);

    function D() external returns (uint256);

    function future_A_gamma_time() external returns (uint256);
}

interface IYearnVault is IERC20 { 
    function deposit(uint256 _tokenAmount) external returns (uint256);

    function withdraw(uint256 _tokenAmount) external returns (uint256);

    function lastReport() external view returns (uint256);

    function totalDebt() external view returns (uint256);

    function calcTokenToYToken(uint256 _tokenAmount) external pure returns (uint256); 

    function token() external view returns (address);

    function availableDepositLimit() external view returns (uint256);

    function pricePerShare() external view returns (uint256);

    function name() external view returns (string memory);

    function setDepositLimit(uint256 limit) external;

    function withdrawalQueue(uint256) external returns (address);
}

interface IBAMM {
    function deposit(uint256 lusdAmount) external;

    function withdraw(uint256 lusdAmount, address to) external;

    function swap(uint lusdAmount, uint minEthReturn, address payable dest) external returns(uint);

    function getSwapEthAmount(uint lusdQty) external view returns(uint ethAmount, uint feeLusdAmount);

    function getLUSDValue() external view returns (uint256, uint256, uint256);

    function setChicken(address _chicken) external;
}

interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    function lusdToken() external view returns (ILUSDToken);
    function bLUSDToken() external view returns (IBLUSDToken);
    function curvePool() external view returns (ICurvePool);
    function bammSPVault() external view returns (IBAMM);
    function yearnCurveVault() external view returns (IYearnVault);
    // constants
    function INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL() external pure returns (int128);

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external  returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minLUSD) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) external view returns (uint256);
    function getBondData(uint256 _bondID) external view returns (uint256 lusdAmount, uint64 claimedBLUSD, uint64 startTime, uint64 endTime, uint8 status);
    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256);
    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256);
    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256);
    function getLUSDInBAMMSPVault() external view returns (uint256);
    function calcTotalYearnCurveVaultShareValue() external view returns (uint256);
    function calcTotalLUSDValue() external view returns (uint256);
    function getPendingLUSD() external view returns (uint256);
    function getAcquiredLUSDInSP() external view returns (uint256);
    function getAcquiredLUSDInCurve() external view returns (uint256);
    function getTotalAcquiredLUSD() external view returns (uint256);
    function getPermanentLUSD() external view returns (uint256);
    function getOwnedLUSDInSP() external view returns (uint256);
    function getOwnedLUSDInCurve() external view returns (uint256);
    function calcSystemBackingRatio() external view returns (uint256);
    function calcUpdatedAccrualParameter() external view returns (uint256);
    function getBAMMLUSDDebt() external view returns (uint256);
}

interface IBondNFT is IERC721Enumerable {
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function mint(address _bonder, uint256 _permanentSeed) external returns (uint256, uint80);
    function setFinalExtraData(address _bonder, uint256 _tokenID, uint256 _permanentSeed) external returns (uint80);
    function chickenBondManager() external view returns (IChickenBondManager);
    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (uint80 initialHalfDna, uint80 finalHalfDna, uint32 troveSize, uint32 lqtyAmount, uint32 curveGaugeSlopes);
}

interface IBondNFTArtwork {
    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory);
}

interface IChickenBondManagerGetter {
    function chickenBondManager() external view returns (IChickenBondManager);
}

contract BondNFTArtworkSwitcher is IBondNFTArtwork, IChickenBondManagerGetter {
    IChickenBondManager public immutable chickenBondManager;
    IBondNFTArtwork public immutable eggArtwork;
    IBondNFTArtwork public immutable chickenOutArtwork;
    IBondNFTArtwork public immutable chickenInArtwork;

    constructor(
        address _chickenBondManagerAddress,
        address _eggArtworkAddress,
        address _chickenOutArtworkAddress,
        address _chickenInArtworkAddress
    ) {
        chickenBondManager = IChickenBondManager(_chickenBondManagerAddress);
        eggArtwork = IBondNFTArtwork(_eggArtworkAddress);
        chickenOutArtwork = IBondNFTArtwork(_chickenOutArtworkAddress);
        chickenInArtwork = IBondNFTArtwork(_chickenInArtworkAddress);
    }

    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData)
        external
        view
        returns (string memory)
    {
        (
            /* uint256 lusdAmount */,
            /* uint64 claimedBLUSD */,
            /* uint64 startTime */,
            /* uint64 endTime */,
            uint8 status
        ) = chickenBondManager.getBondData(_tokenID);

        IBondNFTArtwork artwork = (
            status == uint8(IChickenBondManager.BondStatus.chickenedOut) ? chickenOutArtwork :
            status == uint8(IChickenBondManager.BondStatus.chickenedIn)  ? chickenInArtwork  :
            /* default, including active & nonExistent status */           eggArtwork
        );

        // eggArtwork will handle revert for nonExistent tokens, as per ERC-721
        return artwork.tokenURI(_tokenID, _bondExtraData);
    }
}

contract EggTraitWeights {
    enum BorderColor {
        White,
        Black,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum CardColor {
        Red,
        Green,
        Blue,
        Purple,
        Pink,
        YellowPink,
        BlueGreen,
        PinkBlue,
        RedPurple,
        Bronze,
        Silver,
        Gold,
        Rainbow
    }

    enum ShellColor {
        OffWhite,
        LightBlue,
        DarkerBlue,
        LighterOrange,
        LightOrange,
        DarkerOrange,
        LightGreen,
        DarkerGreen,
        Bronze,
        Silver,
        Gold,
        Rainbow,
        Luminous
    }

    uint256[6] public borderWeights = [30e16, 30e16, 15e16, 12e16, 8e16, 5e16];
    uint256[13] public cardWeights = [12e16, 12e16, 12e16, 11e16, 11e16, 7e16, 7e16, 7e16, 7e16, 5e16, 4e16, 3e16, 2e16];
    uint256[13] public shellWeights = [11e16, 9e16, 9e16, 10e16, 10e16, 10e16, 10e16, 10e16, 75e15, 6e16, 4e16, 25e15, 1e16];

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a border color.
    function _getBorderColor(uint256 rand) internal view returns (BorderColor) {
        uint256 needle = borderWeights[uint256(BorderColor.White)];
        if (rand < needle) { return BorderColor.White; }
        needle += borderWeights[uint256(BorderColor.Black)];
        if (rand < needle) { return BorderColor.Black; }
        needle += borderWeights[uint256(BorderColor.Bronze)];
        if (rand < needle) { return BorderColor.Bronze; }
        needle += borderWeights[uint256(BorderColor.Silver)];
        if (rand < needle) { return BorderColor.Silver; }
        needle += borderWeights[uint256(BorderColor.Gold)];
        if (rand < needle) { return BorderColor.Gold; }
        return BorderColor.Rainbow;
    }

    function _getCardAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory cardWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedCardColor =
                borderColor == BorderColor.Bronze ? uint256(CardColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(CardColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(CardColor.Gold) :
                uint256(CardColor.Rainbow);
            uint256 originalWeight = cardWeights[selectedCardColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            cardWeightsCached[selectedCardColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < cardWeightsCached.length; i++) {
                cardWeightsCached[i] = cardWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a card color.
    function _getCardColor(uint256 rand, BorderColor borderColor) internal view returns (CardColor) {
        // first adjust weights for affinity
        uint256[13] memory cardWeightsCached = _getCardAffinityWeights(borderColor);

        // then compute color
        uint256 needle = cardWeightsCached[uint256(CardColor.Red)];
        if (rand < needle) { return CardColor.Red; }
        needle += cardWeightsCached[uint256(CardColor.Green)];
        if (rand < needle) { return CardColor.Green; }
        needle += cardWeightsCached[uint256(CardColor.Blue)];
        if (rand < needle) { return CardColor.Blue; }
        needle += cardWeightsCached[uint256(CardColor.Purple)];
        if (rand < needle) { return CardColor.Purple; }
        needle += cardWeightsCached[uint256(CardColor.Pink)];
        if (rand < needle) { return CardColor.Pink; }
        needle += cardWeightsCached[uint256(CardColor.YellowPink)];
        if (rand < needle) { return CardColor.YellowPink; }
        needle += cardWeightsCached[uint256(CardColor.BlueGreen)];
        if (rand < needle) { return CardColor.BlueGreen; }
        needle += cardWeightsCached[uint256(CardColor.PinkBlue)];
        if (rand < needle) { return CardColor.PinkBlue; }
        needle += cardWeightsCached[uint256(CardColor.RedPurple)];
        if (rand < needle) { return CardColor.RedPurple; }
        needle += cardWeightsCached[uint256(CardColor.Bronze)];
        if (rand < needle) { return CardColor.Bronze; }
        needle += cardWeightsCached[uint256(CardColor.Silver)];
        if (rand < needle) { return CardColor.Silver; }
        needle += cardWeightsCached[uint256(CardColor.Gold)];
        if (rand < needle) { return CardColor.Gold; }
        return CardColor.Rainbow;
    }

    function _getShellAffinityWeights(BorderColor borderColor) internal view returns (uint256[13] memory shellWeightsCached) {
        if (borderColor == BorderColor.Bronze ||
            borderColor == BorderColor.Silver ||
            borderColor == BorderColor.Gold   ||
            borderColor == BorderColor.Rainbow
        ) {
            uint256 selectedShellColor =
                borderColor == BorderColor.Bronze ? uint256(ShellColor.Bronze) :
                borderColor == BorderColor.Silver ? uint256(ShellColor.Silver) :
                borderColor == BorderColor.Gold ? uint256(ShellColor.Gold) :
                uint256(ShellColor.Rainbow);
            uint256 originalWeight = shellWeights[selectedShellColor];
            uint256 finalWeight = originalWeight * 2;
            // As we are going to duplicate the original weight of the selected color,
            // we reduce that extra amount from all other weights, proportionally,
            // so we keep the total of 100%
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i] * (1e18 - finalWeight) / (1e18 - originalWeight);
            }
            shellWeightsCached[selectedShellColor] = finalWeight;
        } else {
            for (uint256 i = 0; i < shellWeightsCached.length; i++) {
                shellWeightsCached[i] = shellWeights[i];
            }
        }
    }

    // Turn the pseudo-random number `rand` -- 18 digit FP in range [0,1) -- into a shell color.
    function _getShellColor(uint256 rand, BorderColor borderColor) internal view returns (ShellColor) {
        // first adjust weights for affinity
        uint256[13] memory shellWeightsCached = _getShellAffinityWeights(borderColor);

        // then compute color
        uint256 needle = shellWeightsCached[uint256(ShellColor.OffWhite)];
        if (rand < needle) { return ShellColor.OffWhite; }
        needle += shellWeightsCached[uint256(ShellColor.LightBlue)];
        if (rand < needle) { return ShellColor.LightBlue; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerBlue)];
        if (rand < needle) { return ShellColor.DarkerBlue; }
        needle += shellWeightsCached[uint256(ShellColor.LighterOrange)];
        if (rand < needle) { return ShellColor.LighterOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightOrange)];
        if (rand < needle) { return ShellColor.LightOrange; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerOrange)];
        if (rand < needle) { return ShellColor.DarkerOrange; }
        needle += shellWeightsCached[uint256(ShellColor.LightGreen)];
        if (rand < needle) { return ShellColor.LightGreen; }
        needle += shellWeightsCached[uint256(ShellColor.DarkerGreen)];
        if (rand < needle) { return ShellColor.DarkerGreen; }
        needle += shellWeightsCached[uint256(ShellColor.Bronze)];
        if (rand < needle) { return ShellColor.Bronze; }
        needle += shellWeightsCached[uint256(ShellColor.Silver)];
        if (rand < needle) { return ShellColor.Silver; }
        needle += shellWeightsCached[uint256(ShellColor.Gold)];
        if (rand < needle) { return ShellColor.Gold; }
        needle += shellWeightsCached[uint256(ShellColor.Rainbow)];
        if (rand < needle) { return ShellColor.Rainbow; }
        return ShellColor.Luminous;
    }
}

enum Size {
    Tiny,
    Small,
    Normal,
    Big
}

struct CommonData {
    uint256 tokenID;

    // ChickenBondManager.BondData
    uint256 lusdAmount;
    uint256 claimedBLUSD;
    uint256 startTime;
    uint256 endTime;
    uint8 status;

    // IBondNFT.BondExtraData
    uint80 initialHalfDna;
    uint80 finalHalfDna;
    uint32 troveSize;
    uint32 lqtyAmount;
    uint32 curveGaugeSlopes;

    // Attributes derived from the DNA
    EggTraitWeights.BorderColor borderColor;
    EggTraitWeights.CardColor cardColor;
    EggTraitWeights.ShellColor shellColor;
    Size size;

    // Further data derived from the attributes
    bytes borderStyle;
    bytes cardStyle;
    bool hasCardGradient;
    string[2] cardGradient;
    string tokenIDString;
}

function _cutDNA(uint256 dna, uint8 startBit, uint8 numBits) pure returns (uint256) {
    uint256 ceil = 1 << numBits;
    uint256 bits = (dna >> startBit) & (ceil - 1);

    return bits * 1e18 / ceil; // scaled to [0,1) range
}

contract BondNFTArtworkCommon is EggTraitWeights {
    using Strings for uint256;

    ////////////////////////
    // External functions //
    ////////////////////////

    function calcData(CommonData memory _data) external view returns (CommonData memory) {
        _calcAttributes(_data);
        _calcDerivedData(_data);

        return _data;
    }

    function getMetadataJSON(
        CommonData calldata _data,
        bytes calldata _svg,
        bytes calldata _extraAttributes
    )
        external
        pure
        returns (string memory)
    {
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    abi.encodePacked(
                        '{',
                            '"name":"LUSD Chicken #', _data.tokenIDString, '",',
                            '"description":"LUSD Chicken Bonds",',
                            '"image":"data:image/svg+xml;base64,', Base64.encode(_svg), '",',
                            '"background_color":"0b112f",',
                            _getMetadataAttributes(_data, _extraAttributes),
                        '}'
                    )
                )
            )
        );
    }

    function getSVGBaseDefs(CommonData calldata _data, bool _darkMode)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _getSVGDefCardDiagonalGradient(_data),
            _getSVGDefCardRainbowGradient(_data),
            _darkMode ? _getSVGDefCardRadialGradient(_data) : bytes('')
        );
    }

    function getSVGBase(CommonData calldata _data, string memory _subtitle, bool _darkMode)
        external
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            _getSVGBorder(_data, _darkMode),
            _getSVGCard(_data),
            _darkMode ? _getSVGCardRadialGradient(_data) : bytes(''),
            _getSVGText(_data, _subtitle)
        );
    }

    ///////////////////////
    // Private functions //
    ///////////////////////

    function _getSize(uint256 lusdAmount) private pure returns (Size) {
        return (
            lusdAmount <    1_000e18 ?  Size.Tiny   :
            lusdAmount <   10_000e18 ?  Size.Small  :
            lusdAmount <  100_000e18 ?  Size.Normal :
         /* lusdAmount >= 100_000e18 */ Size.Big
        );
    }

    function _calcAttributes(CommonData memory _data) private view {
        uint80 dna = _data.initialHalfDna;

        _data.borderColor = _getBorderColor(_cutDNA(dna,  0, 26));
        _data.cardColor   = _getCardColor  (_cutDNA(dna, 26, 27), _data.borderColor);
        _data.shellColor  = _getShellColor (_cutDNA(dna, 53, 27), _data.borderColor);

        _data.size = _getSize(_data.lusdAmount);
    }

    function _getSolidBorderColor(EggTraitWeights.BorderColor _color)
        private
        pure
        returns (string memory)
    {
        return (
            _color == EggTraitWeights.BorderColor.White  ?    "#fff" :
            _color == EggTraitWeights.BorderColor.Black  ?    "#000" :
            _color == EggTraitWeights.BorderColor.Bronze ? "#cd7f32" :
            _color == EggTraitWeights.BorderColor.Silver ? "#c0c0c0" :
            _color == EggTraitWeights.BorderColor.Gold   ? "#ffd700" : ""
        );
    }

    function _getSolidCardColor(EggTraitWeights.CardColor _color)
        private
        pure
        returns (string memory)
    {
        return (
            _color == EggTraitWeights.CardColor.Red    ? "#ea394e" :
            _color == EggTraitWeights.CardColor.Green  ? "#5caa4b" :
            _color == EggTraitWeights.CardColor.Blue   ? "#008bf7" :
            _color == EggTraitWeights.CardColor.Purple ? "#9d34e8" :
            _color == EggTraitWeights.CardColor.Pink   ? "#e54cae" : ""
        );
    }

    function _getCardGradient(EggTraitWeights.CardColor _color)
        private
        pure
        returns (bool, string[2] memory)
    {
        return (
            _color == EggTraitWeights.CardColor.YellowPink ? (true, ["#ffd200", "#ff0087"]) :
            _color == EggTraitWeights.CardColor.BlueGreen  ? (true, ["#008bf7", "#58b448"]) :
            _color == EggTraitWeights.CardColor.PinkBlue   ? (true, ["#f900bd", "#00a7f6"]) :
            _color == EggTraitWeights.CardColor.RedPurple  ? (true, ["#ea394e", "#9d34e8"]) :
            _color == EggTraitWeights.CardColor.Bronze     ? (true, ["#804a00", "#cd7b26"]) :
            _color == EggTraitWeights.CardColor.Silver     ? (true, ["#71706e", "#b6b6b6"]) :
            _color == EggTraitWeights.CardColor.Gold       ? (true, ["#aa6c39", "#ffae00"]) :
                                                             (false, ["", ""])
        );
    }

    function _calcDerivedData(CommonData memory _data) private pure {
        _data.tokenIDString = _data.tokenID.toString();
        (_data.hasCardGradient, _data.cardGradient) = _getCardGradient(_data.cardColor);

        _data.borderStyle = abi.encodePacked(
            'fill:',
            _data.borderColor == EggTraitWeights.BorderColor.Rainbow
                ? abi.encodePacked('url(#cb-egg-', _data.tokenIDString, '-card-rainbow-gradient)')
                : bytes(_getSolidBorderColor(_data.borderColor))
        );

        _data.cardStyle = abi.encodePacked(
            'fill:',
            _data.cardColor == EggTraitWeights.CardColor.Rainbow
                ? abi.encodePacked('url(#cb-egg-', _data.tokenIDString, '-card-rainbow-gradient)')
                : _data.hasCardGradient
                ? abi.encodePacked('url(#cb-egg-', _data.tokenIDString, '-card-diagonal-gradient)')
                : bytes(_getSolidCardColor(_data.cardColor))
        );
    }

    function _getMetadataCommonDerivedAttributes(CommonData memory _data)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            '{"trait_type":"Size","value":"', _getSizeName(_data.size), '"},'
            '{"trait_type":"Border","value":"', _getBorderName(_data.borderColor), '"},',
            '{"trait_type":"Card","value":"', _getCardName(_data.cardColor), '"},'
        );
    }

    function _getMetadataAttributes(CommonData memory _data, bytes memory _extraAttributes)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            '"attributes":[',
                '{"display_type":"date","trait_type":"Created","value":', _data.startTime.toString(), '},',
                '{"display_type":"number","trait_type":"Bond Amount","value":', _formatDecimal(_data.lusdAmount), '},',
                '{"trait_type":"Bond Status","value":"', _getBondStatusName(IChickenBondManager.BondStatus(_data.status)), '"},',
                _getMetadataCommonDerivedAttributes(_data),
                _extraAttributes,
            ']'
        );
    }

    function _getBondStatusName(IChickenBondManager.BondStatus _status)
        private
        pure
        returns (string memory)
    {
        return (
            _status == IChickenBondManager.BondStatus.chickenedIn  ? "Chickened In"  :
            _status == IChickenBondManager.BondStatus.chickenedOut ? "Chickened Out" :
            _status == IChickenBondManager.BondStatus.active       ? "Active"        : ""
        );
    }

    function _getBorderName(EggTraitWeights.BorderColor _border)
        private
        pure
        returns (string memory)
    {
        return (
            _border == EggTraitWeights.BorderColor.White    ? "White"   :
            _border == EggTraitWeights.BorderColor.Black    ? "Black"   :
            _border == EggTraitWeights.BorderColor.Bronze   ? "Bronze"  :
            _border == EggTraitWeights.BorderColor.Silver   ? "Silver"  :
            _border == EggTraitWeights.BorderColor.Gold     ? "Gold"    :
            _border == EggTraitWeights.BorderColor.Rainbow  ? "Rainbow" : ""
        );
    }

    function _getCardName(EggTraitWeights.CardColor _card) private pure returns (string memory) {
        return (
            _card == EggTraitWeights.CardColor.Red        ? "Red"         :
            _card == EggTraitWeights.CardColor.Green      ? "Green"       :
            _card == EggTraitWeights.CardColor.Blue       ? "Blue"        :
            _card == EggTraitWeights.CardColor.Purple     ? "Purple"      :
            _card == EggTraitWeights.CardColor.Pink       ? "Pink"        :
            _card == EggTraitWeights.CardColor.YellowPink ? "Yellow-Pink" :
            _card == EggTraitWeights.CardColor.BlueGreen  ? "Blue-Green"  :
            _card == EggTraitWeights.CardColor.PinkBlue   ? "Pink-Blue"   :
            _card == EggTraitWeights.CardColor.RedPurple  ? "Red-Purple"  :
            _card == EggTraitWeights.CardColor.Bronze     ? "Bronze"      :
            _card == EggTraitWeights.CardColor.Silver     ? "Silver"      :
            _card == EggTraitWeights.CardColor.Gold       ? "Gold"        :
            _card == EggTraitWeights.CardColor.Rainbow    ? "Rainbow"     : ""
        );
    }

    function _getSizeName(Size _size) private pure returns (string memory) {
        return (
            _size == Size.Tiny   ? "Tiny"   :
            _size == Size.Small  ? "Small"  :
            _size == Size.Normal ? "Normal" :
            _size == Size.Big    ? "Big"    : ""
        );
    }

    function _getMonthName(uint256 _month) private pure returns (string memory) {
        return (
            _month ==  1 ? "JANUARY"   :
            _month ==  2 ? "FEBRUARY"  :
            _month ==  3 ? "MARCH"     :
            _month ==  4 ? "APRIL"     :
            _month ==  5 ? "MAY"       :
            _month ==  6 ? "JUNE"      :
            _month ==  7 ? "JULY"      :
            _month ==  8 ? "AUGUST"    :
            _month ==  9 ? "SEPTEMBER" :
            _month == 10 ? "OCTOBER"   :
            _month == 11 ? "NOVEMBER"  :
            _month == 12 ? "DECEMBER"  : ""
        );
    }

    function _formatDate(uint256 timestamp) private pure returns (string memory) {
        return string(
            abi.encodePacked(
                _getMonthName(BokkyPooBahsDateTimeLibrary.getMonth(timestamp)),
                ' ',
                BokkyPooBahsDateTimeLibrary.getDay(timestamp).toString(),
                ', ',
                BokkyPooBahsDateTimeLibrary.getYear(timestamp).toString()
            )
        );
    }

    function _formatDecimal(uint256 decimal) private pure returns (string memory) {
        return ((decimal + 0.5e18) / 1e18).toString();
    }

    function _getSVGDefCardDiagonalGradient(CommonData memory _data)
        private
        pure
        returns (bytes memory)
    {
        if (!_data.hasCardGradient) {
            return bytes('');
        }

        return abi.encodePacked(
            '<linearGradient id="cb-egg-', _data.tokenIDString, '-card-diagonal-gradient" y1="100%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-color="', _data.cardGradient[0], '"/>',
                '<stop offset="1" stop-color="', _data.cardGradient[1], '"/>',
            '</linearGradient>'
        );
    }

    function _getSVGDefCardRainbowGradient(CommonData memory _data)
        private
        pure
        returns (bytes memory)
    {
        if (
            _data.cardColor != EggTraitWeights.CardColor.Rainbow &&
            _data.borderColor != EggTraitWeights.BorderColor.Rainbow
        ) {
            return bytes('');
        }

        return abi.encodePacked(
            '<linearGradient id="cb-egg-', _data.tokenIDString, '-card-rainbow-gradient" y1="100%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-color="#93278f"/>',
                '<stop offset="0.2" stop-color="#662d91"/>',
                '<stop offset="0.4" stop-color="#3395d4"/>',
                '<stop offset="0.5" stop-color="#39b54a"/>',
                '<stop offset="0.6" stop-color="#fcee21"/>',
                '<stop offset="0.8" stop-color="#fbb03b"/>',
                '<stop offset="1" stop-color="#ed1c24"/>',
            '</linearGradient>'
        );
    }

    function _getSVGDefCardRadialGradient(CommonData memory _data)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            '<radialGradient id="cb-egg-', _data.tokenIDString, '-card-radial-gradient" cx="50%" cy="45%" r="38%" gradientUnits="userSpaceOnUse">',
                '<stop offset="0" stop-opacity="0"/>',
                '<stop offset="0.25" stop-opacity="0"/>',
                '<stop offset="1" stop-color="#000" stop-opacity="1"/>',
            '</radialGradient>'
        );
    }

    function _getSVGBorder(CommonData memory _data, bool _darkMode)
        private
        pure
        returns (bytes memory)
    {
        if (_darkMode && _data.borderColor == EggTraitWeights.BorderColor.Black) {
            // We will use the black radial gradient as border (covering the entire card)
            return bytes('');
        }

        return abi.encodePacked(
            '<rect style="', _data.borderStyle, '" width="100%" height="100%" rx="37.5"/>'
        );
    }

    function _getSVGCard(CommonData memory _data) private pure returns (bytes memory) {
        return abi.encodePacked(
            _data.cardColor == EggTraitWeights.CardColor.Rainbow && _data.borderColor == EggTraitWeights.BorderColor.Rainbow
                ? bytes('') // Rainbow gradient already placed by border
                : abi.encodePacked(
                    '<rect style="', _data.cardStyle, '" x="30" y="30" width="690" height="990" rx="37.5"/>'
                ),

            _data.cardColor == EggTraitWeights.CardColor.Rainbow
                ? '<rect fill="#000" opacity="0.05" x="30" y="30" width="690" height="990" rx="37.5"/>'
                : ''
        );
    }

    function _getSVGCardRadialGradient(CommonData memory _data)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            '<rect style="fill:url(#cb-egg-', _data.tokenIDString, '-card-radial-gradient);mix-blend-mode:hard-light" ',
                _data.borderColor == EggTraitWeights.BorderColor.Black
                    ? 'width="100%" height="100%"'
                    : 'x="30" y="30" width="690" height="990"',
                ' rx="37.5"/>'
        );
    }

    function _getSVGTextTag(string memory _child, string memory _attr)
        private
        pure
        returns (bytes memory)
    {
        return abi.encodePacked(
            '<text ', _attr, ' fill="#fff" font-family="''Arial Black'', Arial" font-weight="800" text-anchor="middle" x="50%">',
                _child,
            '</text>'
        );
    }

    function _getSVGText(CommonData memory _data, string memory _subtitle)
        private
        pure
        returns (bytes memory)
    {
        string memory tokenID = string(abi.encodePacked('ID: ', _data.tokenIDString));
        string memory lusdAmount = _formatDecimal(_data.lusdAmount);
        string memory startTime = _formatDate(_data.startTime);

        return abi.encodePacked(
            _getSVGTextTag('LUSD',     'y="14%" font-size="72px"'),
            _getSVGTextTag(tokenID,    'y="19%" font-size="30px"'),
            _getSVGTextTag(_subtitle,  'y="72%" font-size="40px"'),
            _getSVGTextTag(lusdAmount, 'y="81%" font-size="64px"'),
            _getSVGTextTag(startTime,  'y="91%" font-size="30px" opacity="0.6"')
        );
    }
}

abstract contract BondNFTArtworkBase is IBondNFTArtwork {
    BondNFTArtworkCommon public immutable common;

    constructor(BondNFTArtworkCommon _common) {
        common = _common;
    }

    ////////////////////////
    // External functions //
    ////////////////////////

    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData)
        external
        view
        returns (string memory)
    {
        IChickenBondManager chickenBondManager =
            IChickenBondManagerGetter(msg.sender).chickenBondManager();

        CommonData memory data;
        data.tokenID = _tokenID;
        data.initialHalfDna = _bondExtraData.initialHalfDna;
        data.finalHalfDna = _bondExtraData.finalHalfDna;
        data.troveSize = _bondExtraData.troveSize;
        data.lqtyAmount = _bondExtraData.lqtyAmount;
        data.curveGaugeSlopes = _bondExtraData.curveGaugeSlopes;

        (
            data.lusdAmount,
            data.claimedBLUSD,
            data.startTime,
            data.endTime,
            data.status
        ) = chickenBondManager.getBondData(_tokenID);

        return _tokenURIImplementation(common.calcData(data));
    }

    //////////////////////////////////////////////////////////
    // Abstract functions (to be implemented by subclasses) //
    //////////////////////////////////////////////////////////

    function _tokenURIImplementation(CommonData memory _commonData)
        internal
        view
        virtual
        returns (string memory);

    /////////////////////////////////////////////
    // Internal functions (used by subclasses) //
    /////////////////////////////////////////////

    function _getMetadataJSON(
        CommonData memory _commonData,
        bytes memory _svg,
        bytes memory _extraAttributes
    )
        internal
        view
        returns (string memory)
    {
        return common.getMetadataJSON(_commonData, _svg, _extraAttributes);
    }

    function _getSVGBaseDefs(CommonData memory _commonData, bool _darkMode)
        internal
        view
        returns (bytes memory)
    {
        return common.getSVGBaseDefs(_commonData, _darkMode);
    }

    function _getSVGBase(CommonData memory _commonData, string memory _subtitle, bool _darkMode)
        internal
        view
        returns (bytes memory)
    {
        return common.getSVGBase(_commonData, _subtitle, _darkMode);
    }

    // Shell & chicken share the same color range, but it's no use renaming the enum at this point
    function _getObjectColorName(EggTraitWeights.ShellColor _color)
        internal
        pure
        returns (string memory)
    {
        return (
            _color == EggTraitWeights.ShellColor.OffWhite      ? "Off-White"      :
            _color == EggTraitWeights.ShellColor.LightBlue     ? "Light Blue"     :
            _color == EggTraitWeights.ShellColor.DarkerBlue    ? "Darker Blue"    :
            _color == EggTraitWeights.ShellColor.LighterOrange ? "Lighter Orange" :
            _color == EggTraitWeights.ShellColor.LightOrange   ? "Light Orange"   :
            _color == EggTraitWeights.ShellColor.DarkerOrange  ? "Darker Orange"  :
            _color == EggTraitWeights.ShellColor.LightGreen    ? "Light Green"    :
            _color == EggTraitWeights.ShellColor.DarkerGreen   ? "Darker Green"   :
            _color == EggTraitWeights.ShellColor.Bronze        ? "Bronze"         :
            _color == EggTraitWeights.ShellColor.Silver        ? "Silver"         :
            _color == EggTraitWeights.ShellColor.Gold          ? "Gold"           :
            _color == EggTraitWeights.ShellColor.Rainbow       ? "Rainbow"        :
            _color == EggTraitWeights.ShellColor.Luminous      ? "Luminous"       : ""
        );
    }

    function _getSolidObjectColor(EggTraitWeights.ShellColor _color)
        internal
        pure
        returns (string memory)
    {
        return (
            _color == EggTraitWeights.ShellColor.OffWhite      ? "#fff1cb" :
            _color == EggTraitWeights.ShellColor.LightBlue     ? "#e5eff9" :
            _color == EggTraitWeights.ShellColor.DarkerBlue    ? "#aedfe2" :
            _color == EggTraitWeights.ShellColor.LighterOrange ? "#f6dac9" :
            _color == EggTraitWeights.ShellColor.LightOrange   ? "#f8d1b2" :
            _color == EggTraitWeights.ShellColor.DarkerOrange  ? "#fcba92" :
            _color == EggTraitWeights.ShellColor.LightGreen    ? "#c5e8d6" :
            _color == EggTraitWeights.ShellColor.DarkerGreen   ? "#e5daaa" :
            _color == EggTraitWeights.ShellColor.Bronze        ? "#cd7f32" :
            _color == EggTraitWeights.ShellColor.Silver        ? "#c0c0c0" :
            _color == EggTraitWeights.ShellColor.Gold          ? "#ffd700" : ""
        );
    }

    function _isMetallicCardColor(EggTraitWeights.CardColor _color) internal pure returns (bool) {
        return (
            _color == EggTraitWeights.CardColor.Bronze ||
            _color == EggTraitWeights.CardColor.Silver ||
            _color == EggTraitWeights.CardColor.Gold
        );
    }

    function _translateMetallicCardColorToObjectColor(EggTraitWeights.CardColor _color)
        internal
        pure
        returns (EggTraitWeights.ShellColor)
    {
        return (
            _color == EggTraitWeights.CardColor.Bronze ? EggTraitWeights.ShellColor.Bronze :
            _color == EggTraitWeights.CardColor.Silver ? EggTraitWeights.ShellColor.Silver :
                                                         EggTraitWeights.ShellColor.Gold
        );
    }

    function _isMetallicObjectColor(EggTraitWeights.ShellColor _color)
        internal
        pure
        returns (bool)
    {
        return (
            _color == EggTraitWeights.ShellColor.Bronze ||
            _color == EggTraitWeights.ShellColor.Silver ||
            _color == EggTraitWeights.ShellColor.Gold
        );
    }

    function _isLowContrastObjectColor(EggTraitWeights.ShellColor _color)
        internal
        pure
        returns (bool)
    {
        return (
            _color == EggTraitWeights.ShellColor.Bronze ||
            _color == EggTraitWeights.ShellColor.Silver
        );
    }
}