// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.10;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {DateTime, Date} from "../../utils/DateTime.sol";

library Metadata {
    function getMetadataJson(
        uint256 tokenId,
        address owner,
        uint256 timestamp,
        string memory imageData
    ) public pure returns (string memory) {
        string memory attributes = renderAttributes(tokenId, owner, timestamp);
        return string(abi.encodePacked(
            '{"name": "',
            renderName(tokenId),
            '", "image": "data:image/svg+xml;base64,',
            imageData,
            '","attributes":[',
            attributes,
            "]}"
        ));
    }

    function renderName(
        uint256 id
    ) public pure returns (string memory) {
        return string(abi.encodePacked("Nation3 Genesis Passport #", Strings.toString(id)));
    }

    function renderAttributes(
        uint256 id,
        address owner,
        uint256 timestamp
    ) public pure returns (string memory) {
        Date memory ts = DateTime.timestampToDateTime(timestamp);

        return
            string(abi.encodePacked(
                attributeString("Passport Holder", Strings.toHexString(uint256(uint160(owner)))),
                ",",
                attributeString("Passport Number", Strings.toString(id)),
                ",",
                attributeString(
                    "Issue Date",
                    string(abi.encodePacked(Strings.toString(ts.day),'/',Strings.toString(ts.month),'/',Strings.toString(ts.year)))
                )
            ));
    }

    function attributeString(string memory _name, string memory _value)
        public
        pure
        returns (string memory)
    {
        return
            string(abi.encodePacked(
                "{",
                kv("trait_type", string(abi.encodePacked('"', _name, '"'))),
                ",",
                kv("value", string(abi.encodePacked('"', _value, '"'))),
                "}"
            ));
    }

    function kv(string memory _key, string memory _value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', _key, '"', ":", _value));
    }
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2018 The Officious BokkyPooBah / Bok Consulting Pty Ltd

pragma solidity ^0.8.0;

struct Date {
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
}

library DateTime {
    // for datetime conversion.
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant SECONDS_PER_HOUR = 60 * 60;
    uint256 private constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDateTime(uint256 timestamp) internal pure returns (Date memory) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint256 secs = timestamp % SECONDS_PER_DAY;
        uint256 hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        uint256 minute = secs / SECONDS_PER_MINUTE;
        uint256 second = secs % SECONDS_PER_MINUTE;

        return Date(year, month, day, hour, minute, second);
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

    function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
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