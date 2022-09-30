/**
 *Submitted for verification at Etherscan.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library DoubleSVGV2 {
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
                    '</text><text font-weight="bold" xml:space="preserve" font-family="Helvetica, Arial, sans-serif" font-size="20" y="461" x="163">@Double Protocol</text><g stroke="null" transform="matrix(0.3,0,0,0.3,60,180)"><g id="logo" transform="translate(0.621178, 0.006479)" fill="#292C33" fill-rule="nonzero"><path d="M142.12,29.243 C142.31,29.20 142.50,29.16 142.69,29.12 L143.25,29.017 C148.77,27.93 154.14,27.33 157.64,33.303 C160.56,38.283 157.54,41.643 153.20,45.443 L157.00,45.44 C161.38,45.44 165.60,45.44 169.74,45.43 L178.51,45.43 C180.83,45.44 183.13,45.44 185.43,45.443 C217.48,45.463 241.05,69.023 241.10,101.10 C241.12,117.71 241.28,134.32 240.99,150.92 C240.91,155.36 242.08,156.53 246.45,156.33 C254.29,155.97 257.30,158.86 257.19,165.20 C257.14,168.46 255.65,170.92 252.85,171.78 C249.45,172.82 249.15,174.87 249.39,177.73 C249.84,183.16 248.75,187.71 242.49,189.17 C240.85,189.55 240.93,190.74 241.07,191.87 L241.10,192.14 C241.13,192.40 241.16,192.66 241.15,192.90 C241.07,202.37 241.29,211.84 241.03,221.30 C240.77,230.83 233.48,237.86 224.51,237.73 C215.31,237.59 208.46,230.25 208.39,220.41 C208.35,214.93 208.38,209.45 208.38,203.97 C208.38,200.65 208.56,197.31 208.33,194.01 C208.12,191.04 208.68,189.41 211.98,188.32 C216.37,186.86 217.20,182.70 216.92,178.44 C216.71,175.35 216.80,172.95 220.59,171.49 C224.02,170.16 225.56,166.72 224.60,162.80 C223.61,158.77 220.91,156.65 216.82,156.26 C208.58,155.49 208.39,155.48 208.38,147.63 L208.38,147.05 C208.38,131.60 208.40,116.16 208.39,100.71 C208.38,87.243 199.45,78.023 186.05,78.003 C142.37,77.933 98.698,77.933 55.018,78.013 C41.568,78.033 32.728,87.163 32.718,100.70 C32.698,144.21 32.698,187.73 32.708,231.24 C32.718,244.59 41.878,253.76 55.228,253.77 C95.258,253.79 135.27,253.76 175.30,253.78 C183.53,253.79 189.53,258.22 191.70,265.67 C193.71,272.57 190.88,279.91 184.72,283.84 C181.67,285.78 178.28,286.51 174.75,286.51 C134.39,286.53 94.038,286.83 53.688,286.41 C23.398,286.10 0.088034,261.93 0.048034,231.69 C-0.0111780966,187.68 -0.0211780966,143.67 0.048034,99.653 C0.098034,69.283 24.238,45.373 54.568,45.443 C63.918,45.463 73.288,45.443 83.308,45.443 C75.488,38.623 73.518,33.203 76.768,28.703 C80.548,23.463 86.618,23.933 97.468,30.503 C95.748,22.913 97.298,16.213 102.02,10.373 C106.74,4.5535 112.99,1.5735 120.32,0.29349 C134.13,-2.12647925 151.07,10.673 142.12,29.243 Z M125.66,187.34 C127.36,190.99 125.45,193.32 122.22,194.87 C118.53,196.64 114.82,198.39 110.42,200.47 C114.85,202.65 118.55,204.47 122.24,206.31 C125.44,207.89 127.38,210.22 125.67,213.86 C123.89,217.64 120.79,217.98 117.32,216.26 C110.34,212.81 103.39,209.30 96.438,205.82 C94.358,204.78 92.948,203.18 92.848,200.83 C92.738,198.24 94.218,196.49 96.458,195.36 C103.41,191.87 110.36,188.36 117.33,184.90 C120.82,183.17 123.90,183.57 125.66,187.34 Z M81.548,131.02 C87.498,130.96 92.418,135.33 92.738,141.43 C93.008,146.56 92.978,151.73 92.688,156.86 C92.328,163.08 87.548,167.37 81.578,167.31 C75.398,167.25 70.898,162.67 70.678,156.15 C70.588,153.82 70.658,151.49 70.658,149.17 L70.6519701,147.928521 L70.623,145.438521 C70.613,144.19 70.618,142.948521 70.678,141.70 C70.978,135.55 75.588,131.08 81.548,131.02 Z M160.72,131.03 C166.67,131.15 171.22,135.65 171.50,141.82 C171.61,144.30 171.52,146.80 171.52,149.29 C171.50,149.28 171.50,149.28 171.49,149.28 C171.49,151.77 171.60,154.27 171.47,156.75 C171.14,162.69 166.71,167.08 160.98,167.30 C154.98,167.54 149.95,163.36 149.53,157.25 C149.17,151.96 149.16,146.62 149.44,141.33 C149.77,135.24 154.76,130.91 160.72,131.03 Z"></path></g></g></svg>'
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
        uint64 end_time,
        address oNFT
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
                                '"},{"trait_type":"original","value":"',
                                toAsciiString(oNFT),
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

    function toAsciiString(address x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(uint160(x)) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(abi.encodePacked("0x",s));
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }
}