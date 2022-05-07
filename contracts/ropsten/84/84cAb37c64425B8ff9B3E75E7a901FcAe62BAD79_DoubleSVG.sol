/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DoubleSVG {
    string internal constant TABLE_ENCODE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-:# ";

    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant SECONDS_PER_HOUR = 60 * 60;
    uint256 constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        string memory table = TABLE_ENCODE;

        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        string memory result = new string(encodedLen + 32);

        assembly {
            mstore(result, encodedLen)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 32)
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(18, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(12, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(
                    resultPtr,
                    mload(add(tablePtr, and(shr(6, input), 0x3F)))
                )
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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

    function generateImage(
        uint64 start,
        uint64 end,
        string memory nftName
    ) internal view returns (string memory) {
        string memory nameColor = "#000000";
        string memory bgColor = "#f0bb00";

        if (block.timestamp > end) {
            bgColor = "#b2b2b2";
        } else {
            nameColor = "#b25600";
        }
        string memory endTimeStr = "Infinity";
        if (end < type(uint64).max) {
            endTimeStr = formatDate(end);
        }
        return
            string(
                abi.encodePacked(
                    '<svg width="500" height="500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"> <rect fill="',
                    bgColor,
                    '" height="500" width="500" y="0" x="0"/><text font-weight="bold" xml:space="preserve" font-family="Helvetica, Arial, sans-serif" font-size="24" y="310" x="60" fill="',
                    nameColor,
                    '" >',
                    nftName,
                    '</text><text font-weight="normal" xml:space="preserve" font-family="Helvetica, Arial, sans-serif" font-size="20" y="350" x="60">Start Time : ',
                    formatDate(start),
                    '</text><text font-weight="normal" xml:space="preserve" font-family="Helvetica, Arial, sans-serif" font-size="20" y="380" x="60">End Time  : ',
                    endTimeStr,
                    '</text><text font-weight="bold" xml:space="preserve" font-family="Helvetica, Arial, sans-serif" font-size="20" y="461" x="163">@Double Protocol</text><g stroke="null" transform="matrix(0.5,0,0,0.5,-55,80)"><image stroke="null" x="395" y="-296" id="svg_19" xlink:href="data:image/png;base64,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" transform="translate(-2.2737367544323206e-13,384.775146484375) scale(0.5799999833106995,0.5899999737739563) " height="294" width="258"/></g></svg>'
                )
            );
    }

    function formatDate(uint256 timestamp)
        internal
        pure
        returns (string memory)
    {
        (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        ) = timestampToDateTime(timestamp);
        string memory monthStr = toString(month);
        if (month < 10) {
            monthStr = string(abi.encodePacked("0", monthStr));
        }
        string memory dayStr = toString(day);
        if (day < 10) {
            dayStr = string(abi.encodePacked("0", dayStr));
        }
        string memory hourStr = toString(hour);
        if (hour < 10) {
            hourStr = string(abi.encodePacked("0", hourStr));
        }
        string memory minuteStr = toString(minute);
        if (minute < 10) {
            minuteStr = string(abi.encodePacked("0", minuteStr));
        }
        string memory secondStr = toString(second);
        if (second < 10) {
            secondStr = string(abi.encodePacked("0", secondStr));
        }
        return
            string(
                abi.encodePacked(
                    toString(year),
                    "-",
                    monthStr,
                    "-",
                    dayStr,
                    " ",
                    hourStr,
                    ":",
                    minuteStr,
                    ":",
                    secondStr
                )
            );
    }

    function genTokenURI(
        uint256 tokenId,
        string memory name,
        string memory type_value,
        uint64 start_time,
        uint64 end_time
    ) public view returns (string memory) {
        string memory image = encode(
            bytes(generateImage(start_time, end_time, name))
        );
        name = string(abi.encodePacked(name, " #", toString(tokenId)));

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                name,
                                '", "image": "',
                                "data:image/svg+xml;base64,",
                                image,
                                '", "attributes":[{"trait_type":"type","value":"',
                                type_value,
                                '"},{"display_type":"date","trait_type":"start_time","value":"',
                                toString(start_time),
                                configTime(end_time),
                                "}]}"
                            )
                        )
                    )
                )
            );
    }

    function configTime(uint64 time) internal pure returns (string memory) {
        if (time == type(uint64).max) {
            return
                string(
                    abi.encodePacked(
                        '"},{"trait_type":"end_time","value":"Infinity"'
                    )
                );
        } else {
            return
                string(
                    abi.encodePacked(
                        '"},{"display_type":"date","trait_type":"end_time","value":"',
                        toString(time),
                        '"'
                    )
                );
        }
    }
}