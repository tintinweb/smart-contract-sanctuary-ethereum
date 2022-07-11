// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    uint256 constant DOW_MON = 1;
    uint256 constant DOW_TUE = 2;
    uint256 constant DOW_WED = 3;
    uint256 constant DOW_THU = 4;
    uint256 constant DOW_FRI = 5;
    uint256 constant DOW_SAT = 6;
    uint256 constant DOW_SUN = 7;

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
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days = _day -
            32075 +
            (1461 * (_year + 4800 + (_month - 14) / 12)) /
            4 +
            (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
            12 -
            (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
            4 -
            OFFSET19700101;

        _days = uint256(__days);
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
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    function timestampFromDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (uint256 timestamp) {
        timestamp =
            _daysFromDate(year, month, day) *
            SECONDS_PER_DAY +
            hour *
            SECONDS_PER_HOUR +
            minute *
            SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint256 daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }

    function isValidDateTime(
        uint256 year,
        uint256 month,
        uint256 day,
        uint256 hour,
        uint256 minute,
        uint256 second
    ) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }

    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
        uint256 _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import {Strings} from '@openzeppelin/contracts/utils/Strings.sol';
import {IUnipeeps} from './interfaces/IUnipeeps.sol';
import {IUnipeepsSVG} from './interfaces/IUnipeepsSVG.sol';
import {BokkyPooBahsDateTimeLibrary} from './BokkyPooBahsDateTimeLibrary.sol';

contract UnipeepsSVG {
    using Strings for *;

    struct Attributes {
        string color1;
        string color2;
        string color3;
        string coord1;
        string coord2;
        string coord3;
        string coord4;
    }

    mapping(uint8 => uint24[3][2]) colorMappings;

    constructor(uint24[3][2][7] memory _colorMappings) {
        for (uint8 i = 0; i < 7; i++) {
            colorMappings[i] = _colorMappings[i];
        }
    }

    function generateSVG(
        uint256 number,
        IUnipeeps.Peep memory peep,
        uint256 totalPeeps
    ) external view returns (bytes memory SVG) {
        uint256 numberHash1 = uint256(keccak256(abi.encode(peep.first)));
        uint256 numberHash2 = uint256(keccak256(abi.encode(peep.last)));
        string memory color1 = toColorHex(colorMappings[uint8(peep.group)][1][numberHash1 % uint8(3)]);
        string memory color2 = toColorHex(colorMappings[uint8(peep.group)][0][numberHash2 % uint8(3)]);
        string memory color3 = uint256(uint256(keccak256(abi.encodePacked(peep.first, peep.last))) % 360).toString();

        string memory coord1;
        string memory coord2;
        string memory coord3;
        string memory coord4;
        unchecked {
            coord1 = intToString(int256((numberHash1**numberHash2) % 190) - 50);
            coord2 = intToString(int256((numberHash2 + numberHash2) % 230) - 170);
            coord3 = intToString(int256((numberHash2 * numberHash2) % 190) - 10);
            coord4 = intToString(int256((numberHash1 % numberHash2) % 230));
        }

        return svgString(number, peep, Attributes(color1, color2, color3, coord1, coord2, coord3, coord4), totalPeeps);
    }

    function epochDayToString(uint256 epochDate) private pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary._daysToDate(epochDate);
        return
            string(
                abi.encodePacked(
                    year.toString(),
                    '/',
                    month < 10 ? '0' : '',
                    month.toString(),
                    '/',
                    day < 10 ? '0' : '',
                    day.toString()
                )
            );
    }

    function svgString(
        uint256 number,
        IUnipeeps.Peep memory peep,
        Attributes memory attributes,
        uint256 totalPeeps
    ) internal pure returns (bytes memory SVG) {
        string memory startDate = epochDayToString(peep.epochStartDate);
        return
            abi.encodePacked(
                '<svg version="1.1" width="375" height="636" preserveAspectRatio="xMidYMid meet" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 250 424" font-family="\'Inter\', sans-serif"><style>@import url(\'https://fonts.googleapis.com/css2?family=Inter:[email protected];300;500\');</style><defs><mask id="card"><rect width="100%" height="100%" fill="white" rx="4"/></mask><mask id="firstName"><text fill="white" x="16" y="330" font-size="36" font-weight="100" text-anchor="start">',
                peep.first,
                '</text></mask><mask id="lastName"><text fill="white" x="16" y="368" font-size="36" font-weight="100" text-anchor="start">',
                peep.last,
                '</text></mask><mask id="role"><text x="16" y="400" font-size="10" font-weight="300" text-anchor="start" fill="white">',
                peep.role,
                '</text></mask><mask id="joinDate"><text x="234" y="400" font-size="10" font-weight="300" text-anchor="end" fill="white">',
                startDate,
                '</text></mask><mask id="title"><text x="16" y="32" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="start" fill="none" stroke="white" stroke-width="0.5">UNISWAP LABS</text></mask><mask id="year"><text x="234" y="32" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="end" fill="none" stroke="white" stroke-width="0.5">2022</text></mask><mask id="number"><text x="16" y="32" dy="4%" font-size="12" font-family="sans-serif" font-weight="500" text-anchor="start" fill="none" stroke="white" stroke-width="0.5">',
                number.toString(),
                svgCenter(attributes, totalPeeps),
                number.toString(),
                '/',
                totalPeeps.toString(),
                '</text></g><g font-size="36" font-weight="lighter" text-anchor="start" fill="rgba(0,0,0,0.25)"><text mask="url(#firstName)" x="16" y="330" filter="url(#sh)">',
                peep.first,
                '</text><text mask="url(#lastName)" x="16" y="368" filter="url(#sh)">',
                peep.last,
                '</text></g><line x1="16" y1="382" x2="234" y2="382" stroke="rgba(0,0,0,0.25)" stroke-width="0.5" /><g font-size="10" fill="rgba(0,0,0,0.25)" font-weight="300"><text mask="url(#role)" x="16" y="400" text-anchor="start" filter="url(#sh)">',
                peep.role,
                '</text><text mask="url(#joinDate)" x="234" y="400" text-anchor="end" filter="url(#sh)">',
                startDate,
                '</text></g></g></svg>'
            );
    }

    function svgCenter(Attributes memory attributes, uint256 totalPeeps) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '/',
                totalPeeps.toString(),
                '</text></mask><mask id="border1"><rect width="234" height="408" x="8" y="8" stroke="white" /></mask><mask id="border2"><rect width="234" height="408" x="8" y="8" rx="24" stroke="white" /></mask><mask id="glimmer"><path d="M125.578 168V167.75H125.328H125.017H124.767V168L124.767 196.769C124.767 205.052 118.052 211.767 109.769 211.767L81 211.767H80.75V212.017V212.328V212.578H81L123.24 212.578V256.5V256.75H123.49H123.802H124.052V256.5V227.731C124.052 219.448 130.766 212.733 139.049 212.733H167.818H168.068V212.483V212.172V211.922H167.818H125.578L125.578 168Z" stroke="white" stroke-opacity="0.5" stroke-width="0.5"/></mask><mask id="circle"><circle cx="100" cy="220" r="40" fill="none" stroke="white" stroke-width="0.5" stroke-opacity="0.5"/></mask><mask id="star" maskUnits="objectBoundingBox"><path d="M37.25 0.99814L36.75 1C36.75 8.15363 36.3084 13.7289 35.3544 17.7352C34.3969 21.7566 32.9413 24.1209 30.9801 24.9763C29.0267 25.8284 26.4522 25.233 23.1202 23.0162C22.1515 22.3717 21.1245 21.5939 20.0373 20.6824C17.8024 18.0218 14.7895 15.0198 11.0032 11.6503L10.6503 12.0032C14.0198 15.7895 17.0218 18.8024 19.6824 21.0373C20.5939 22.1245 21.3717 23.1515 22.0162 24.1202C24.233 27.4522 24.8284 30.0267 23.9763 31.9801C23.1209 33.9413 20.7566 35.3969 16.7352 36.3544C12.7289 37.3084 7.15363 37.75 0 37.75V38V38.25C7.15363 38.25 12.7289 38.6916 16.7352 39.6456C20.7566 40.6031 23.1209 42.0587 23.9763 44.0199C24.8285 45.9733 24.233 48.5478 22.0162 51.8798C21.3717 52.8485 20.5939 53.8755 19.6824 54.9627C17.0218 57.1975 14.0198 60.2105 10.6503 63.9967L11.0032 64.3497C14.7895 60.9802 17.8025 57.9782 20.0373 55.3176C21.1245 54.4061 22.1515 53.6283 23.1202 52.9838C26.4522 50.767 29.0267 50.1715 30.9801 51.0237C32.9413 51.8791 34.3969 54.2434 35.3544 58.2648C36.3084 62.2711 36.75 67.8464 36.75 75L37.25 75.0019C37.3033 67.8367 37.7617 62.2626 38.7135 58.2626C39.6692 54.2467 41.1038 51.8959 43.041 51.0507C44.9704 50.209 47.5193 50.8108 50.8433 53.0264C51.8835 53.7196 52.9926 54.5664 54.1737 55.5671C56.3859 58.1655 59.3283 61.0851 62.9967 64.3497L63.3486 63.9955C60.0579 60.3478 57.1275 57.4178 54.5281 55.2121C53.5253 54.0322 52.6773 52.9223 51.9838 51.8798C49.767 48.5478 49.1715 45.9733 50.0237 44.0199C50.8791 42.0587 53.2434 40.6031 57.2648 39.6456C61.2711 38.6916 66.8464 38.25 74 38.25L74.0019 37.75C66.8367 37.6967 61.2626 37.2383 57.2626 36.2865C53.2467 35.3308 50.8959 33.8962 50.0507 31.959C49.209 30.0296 49.8108 27.4807 52.0264 24.1567C52.7711 23.0394 53.693 21.8424 54.7924 20.5622C57.3257 18.3837 60.1689 15.5292 63.3486 12.0045L62.9955 11.6514C59.4708 14.8311 56.6163 17.6743 54.4378 20.2076C53.1576 21.307 51.9606 22.2289 50.8433 22.9736C47.5193 25.1892 44.9704 25.791 43.041 24.9493C41.1038 24.1041 39.6692 21.7532 38.7135 17.7374C37.7617 13.7374 37.3033 8.16332 37.25 0.99814Z" stroke="white" stroke-width="0.5" stroke-opacity="0.5" /></mask><filter id="sh" x="0%" y="0%" width="100%" height="100%" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feColorMatrix in="SourceAlpha" type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 127 0" result="hardAlpha"/><feOffset dy="1"/><feGaussianBlur stdDeviation="0.5"/><feComposite in2="hardAlpha" operator="arithmetic" k2="-1" k3="1"/><feColorMatrix type="matrix" values="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.54 0"/><feBlend mode="normal" in2="shape" result="effect1_sh_1_537"/></filter><filter id="blur" x="-50%" y="-50%" width="200%" height="200%" color-interpolation-filters="sRGB"><feGaussianBlur stdDeviation="20" result="out"/><feGaussianBlur stdDeviation="20" result="out"/></filter><linearGradient id="backgroundGradient" x1="124" y1="245.012" x2="124" y2="424" gradientUnits="userSpaceOnUse"><stop stop-color="#',
                attributes.color1,
                '"/><stop offset="1" stop-color="#',
                attributes.color2,
                '"/></linearGradient></defs><g overflow="hidden" mask="url(#card)"><rect width="100%" height="100%" fill="url(#backgroundGradient)" rx="4"/><g filter="url(#blur)"><circle cx="120" r="160" fill="hsl(',
                attributes.color3,
                ',100%,90%)" /></g><g><path mask="url(#glimmer)" filter="url(#sh)" d="M125.578 168V167.75H125.328H125.017H124.767V168L124.767 196.769C124.767 205.052 118.052 211.767 109.769 211.767L81 211.767H80.75V212.017V212.328V212.578H81L123.24 212.578V256.5V256.75H123.49H123.802H124.052V256.5V227.731C124.052 219.448 130.766 212.733 139.049 212.733H167.818H168.068V212.483V212.172V211.922H167.818H125.578L125.578 168Z" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g transform="translate(',
                attributes.coord1,
                ' ',
                attributes.coord2,
                ')"><circle mask="url(#circle)" filter="url(#sh)" fill="none" cx="100" cy="220" r="40" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g transform="translate(',
                attributes.coord3,
                ' ',
                attributes.coord4,
                ')"><path mask="url(#star)" filter="url(#sh)" d="M37.25 0.99814L36.75 1C36.75 8.15363 36.3084 13.7289 35.3544 17.7352C34.3969 21.7566 32.9413 24.1209 30.9801 24.9763C29.0267 25.8284 26.4522 25.233 23.1202 23.0162C22.1515 22.3717 21.1245 21.5939 20.0373 20.6824C17.8024 18.0218 14.7895 15.0198 11.0032 11.6503L10.6503 12.0032C14.0198 15.7895 17.0218 18.8024 19.6824 21.0373C20.5939 22.1245 21.3717 23.1515 22.0162 24.1202C24.233 27.4522 24.8284 30.0267 23.9763 31.9801C23.1209 33.9413 20.7566 35.3969 16.7352 36.3544C12.7289 37.3084 7.15363 37.75 0 37.75V38V38.25C7.15363 38.25 12.7289 38.6916 16.7352 39.6456C20.7566 40.6031 23.1209 42.0587 23.9763 44.0199C24.8285 45.9733 24.233 48.5478 22.0162 51.8798C21.3717 52.8485 20.5939 53.8755 19.6824 54.9627C17.0218 57.1975 14.0198 60.2105 10.6503 63.9967L11.0032 64.3497C14.7895 60.9802 17.8025 57.9782 20.0373 55.3176C21.1245 54.4061 22.1515 53.6283 23.1202 52.9838C26.4522 50.767 29.0267 50.1715 30.9801 51.0237C32.9413 51.8791 34.3969 54.2434 35.3544 58.2648C36.3084 62.2711 36.75 67.8464 36.75 75L37.25 75.0019C37.3033 67.8367 37.7617 62.2626 38.7135 58.2626C39.6692 54.2467 41.1038 51.8959 43.041 51.0507C44.9704 50.209 47.5193 50.8108 50.8433 53.0264C51.8835 53.7196 52.9926 54.5664 54.1737 55.5671C56.3859 58.1655 59.3283 61.0851 62.9967 64.3497L63.3486 63.9955C60.0579 60.3478 57.1275 57.4178 54.5281 55.2121C53.5253 54.0322 52.6773 52.9223 51.9838 51.8798C49.767 48.5478 49.1715 45.9733 50.0237 44.0199C50.8791 42.0587 53.2434 40.6031 57.2648 39.6456C61.2711 38.6916 66.8464 38.25 74 38.25L74.0019 37.75C66.8367 37.6967 61.2626 37.2383 57.2626 36.2865C53.2467 35.3308 50.8959 33.8962 50.0507 31.959C49.209 30.0296 49.8108 27.4807 52.0264 24.1567C52.7711 23.0394 53.693 21.8424 54.7924 20.5622C57.3257 18.3837 60.1689 15.5292 63.3486 12.0045L62.9955 11.6514C59.4708 14.8311 56.6163 17.6743 54.4378 20.2076C53.1576 21.307 51.9606 22.2289 50.8433 22.9736C47.5193 25.1892 44.9704 25.791 43.041 24.9493C41.1038 24.1041 39.6692 21.7532 38.7135 17.7374C37.7617 13.7374 37.3033 8.16332 37.25 0.99814Z" stroke="black" stroke-opacity="0.24" stroke-width="0.5" style="mix-blend-mode:multiply"/></g><g stroke="rgba(0,0,0,0.24)" stroke-width="0.5" fill="none"><rect width="234" height="408" x="8" y="8" mask="url(#border1)"/><rect width="234" height="408" x="8" y="8" rx="24" mask="url(#border2)"/></g><g fill="none" stroke="rgba(0,0,0,0.24)" stroke-width="0.5" font-family="sans-serif" font-weight="500" font-size="12"><text mask="url(#title)" x="16" y="32" text-anchor="start" filter="url(#sh)">UNISWAP LABS</text><text mask="url(#year)" x="234" y="32" text-anchor="end" filter="url(#sh)">2022</text><text mask="url(#number)" x="16" y="32" dy="4%" filter="url(#sh)">'
            );
    }

    function toColorHex(uint256 value) private pure returns (string memory) {
        bytes16 ALPHABET = '0123456789abcdef';
        bytes memory buffer = new bytes(6);

        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    function intToString(int256 value) private pure returns (string memory) {
        if (value >= 0) {
            return uint256(value).toString();
        } else {
            return string(abi.encodePacked('-', uint256(value * -1).toString()));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import {IUnipeepsSVG} from './IUnipeepsSVG.sol';

interface IUnipeeps is IERC721 {
    /// @notice Emitted when a new SVG contract is added for the next future mints
    /// @param unipeepsSVG The address of the new contract
    /// @param totalSupply The total supply at the time of add. tokenIds after this will be minted with the new SVG.
    event NewSVGContractAdded(IUnipeepsSVG unipeepsSVG, uint96 totalSupply);

    /// @notice The queried token does not exist
    error NonexistentPeep(uint256 invalidId);
    /// @notice The number of peeps, employeeNumbers, and recipients must match
    error NewPeepsParamLengthMismatch();
    /// @notice The number of tokenIds, groups, and roles must match
    error ModifyPeepsParamLengthMismatch();
    /// @notice The employee number has already been minted.
    error NewPeepOutOfOrder(uint256 employeeNumber, uint256 totalSupply);

    enum Group {
        Design,
        Engineering,
        Executive,
        Legal,
        Operations,
        Product,
        Strategy
    }

    struct Peep {
        string first;
        string last;
        string role;
        uint248 epochStartDate;
        Group group;
    }

    /// @notice Mints a new NFT with the given metadata for the given recipient.
    /// @param peeps A list of the metadata for each NFT to mint.
    /// @param recipients A list of the recipient addresses that should receive the newly minted NFT. Indices should correspond
    ///        to the _peeps array.
    function newPeeps(Peep[] memory peeps, address[] memory recipients) external;

    /// @notice Modifies the role and group of an existing peep.
    /// @param tokenIds The tokenIds of the peeps to modify.
    /// @param _peeps The updated details for each peep.
    function modifyPeeps(
      uint256[] calldata tokenIds,
      Peep[] calldata _peeps
    ) external;

    /// @notice Adds new contract for svg art for the next future mints.
    /// @param svgContract The address of the new UnipeepsSVG contract
    function addNewSVGContract(IUnipeepsSVG svgContract) external;

    /// @notice Get the SVG contract associated with a tokenId
    /// @param tokenId The tokenId
    function getSVGContract(uint256 tokenId) external view returns (IUnipeepsSVG);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import {IUnipeeps} from './IUnipeeps.sol';

interface IUnipeepsSVG {
    function generateSVG(
        uint256 number,
        IUnipeeps.Peep memory peep,
        uint256 totalPeeps
    ) external view returns (bytes memory SVG);
}