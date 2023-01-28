// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StakeInfo.sol";
import "./DateTime.sol";
import "./FormattedStrings.sol";
import "./StakeSVG.sol";

/**
    @dev Library contains methods to generate on-chain NFT metadata
*/
library StakeMetadata {
    using DateTime for uint256;
    using StakeInfo for uint256;
    using Strings for uint256;

    // PRIVATE HELPERS

    // The following pure methods returning arrays are workaround to use array constants,
    // not yet available in Solidity

    /**
        @dev private helper to generate SVG gradients
     */
    function _commonCategoryGradients() private pure returns (StakeSVG.Gradient[] memory gradients) {
        StakeSVG.Color[] memory colors = new StakeSVG.Color[](3);
        colors[0] = StakeSVG.Color({h: 50, s: 10, l: 36, a: 1, off: 0});
        colors[1] = StakeSVG.Color({h: 50, s: 10, l: 12, a: 1, off: 50});
        colors[2] = StakeSVG.Color({h: 50, s: 10, l: 5, a: 1, off: 100});
        gradients = new StakeSVG.Gradient[](1);
        gradients[0] = StakeSVG.Gradient({colors: colors, id: 0, coords: [uint256(50), 0, 50, 100]});
    }

    // PUBLIC INTERFACE

    /**
        @dev public interface to generate SVG image based on XENFT params
     */
    function svgData(uint256 tokenId, uint256 info, address token) external view returns (bytes memory) {
        string memory symbol = IERC20Metadata(token).symbol();
        StakeSVG.SvgParams memory params = StakeSVG.SvgParams({
            symbol: symbol,
            xenAddress: token,
            tokenId: tokenId,
            term: info.getTerm(),
            maturityTs: info.getMaturityTs(),
            amount: info.getAmount(),
            apy: info.getAPY(),
            rarityScore: info.getRarityScore(),
            rarityBits: info.getRarityBits()
        });
        return StakeSVG.image(params, _commonCategoryGradients());
    }

    function _attr1(uint256 amount, uint256 apy) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"Amount","value":"',
                amount.toString(),
                '"},'
                '{"trait_type":"APY","value":"',
                apy.toString(),
                '%"},'
            );
    }

    function _attr2(uint256 term, uint256 maturityTs) private pure returns (bytes memory) {
        (uint256 year, string memory month) = DateTime.yearAndMonth(maturityTs);
        return
            abi.encodePacked(
                '{"trait_type":"Maturity DateTime","value":"',
                maturityTs.asString(),
                '"},'
                '{"trait_type":"Term","value":"',
                term.toString(),
                '"},'
                '{"trait_type":"Maturity Year","value":"',
                year.toString(),
                '"},'
                '{"trait_type":"Maturity Month","value":"',
                month,
                '"},'
            );
    }

    function _attr3(uint256 rarityScore, uint256) private pure returns (bytes memory) {
        return abi.encodePacked('{"trait_type":"Rarity","value":"', rarityScore.toString(), '"}');
    }

    /**
        @dev private helper to construct attributes portion of NFT metadata
     */
    function attributes(uint256 stakeInfo) external pure returns (bytes memory) {
        (
            uint256 term,
            uint256 maturityTs,
            uint256 amount,
            uint256 apy,
            uint256 rarityScore,
            uint256 rarityBits
        ) = StakeInfo.decodeStakeInfo(stakeInfo);
        return
            abi.encodePacked("[", _attr1(amount, apy), _attr2(term, maturityTs), _attr3(rarityScore, rarityBits), "]");
    }

    function formattedString(uint256 n) public pure returns (string memory) {
        return FormattedStrings.toFormattedString(n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTime.sol";
import "./FormattedStrings.sol";

/*
    @dev        Library to create SVG image for XENFT metadata
    @dependency depends on DataTime.sol and StringData.sol libraries
 */
library StakeSVG {
    // Type to encode all data params for SVG image generation
    struct SvgParams {
        string symbol;
        address xenAddress;
        uint256 tokenId;
        uint256 term;
        uint256 maturityTs;
        uint256 amount;
        uint256 apy;
        uint256 rarityScore;
        uint256 rarityBits;
    }

    // Type to encode SVG gradient stop color on HSL color scale
    struct Color {
        uint256 h;
        uint256 s;
        uint256 l;
        uint256 a;
        uint256 off;
    }

    // Type to encode SVG gradient
    struct Gradient {
        Color[] colors;
        uint256 id;
        uint256[4] coords;
    }

    using DateTime for uint256;
    using Strings for uint256;
    using FormattedStrings for uint256;
    using Strings for address;

    string private constant _STYLE =
        "<style> "
        ".base {fill: #ededed;font-family:Montserrat,arial,sans-serif;font-size:30px;font-weight:400;} "
        ".series {text-transform: uppercase} "
        ".logo {font-size:200px;font-weight:100;} "
        ".meta {font-size:12px;} "
        ".small {font-size:8px;} "
        ".burn {font-weight:500;font-size:16px;} }"
        "</style>";

    string private constant _STAKE =
        "<g>"
        "<path "
        'stroke="#ededed" '
        'fill="none" '
        'transform="translate(250,379), scale(0.7)" '
        'd="m 0 5 a 5 5 0 0 1 5 -5 l 40 0 a 5 5 0 0 1 5 5 l 0 40 a 5 5 0 0 1 -5 5 l -40 0 a 5 5 0 0 1 -5 -5 l 0 -40z m 25 0 l 20 10 l -20 10 l -20 -10 l 20 -10 m 10 15 l 10 5 l -20 10 l -20 -10 l 10 -5 m 20 10 l 10 5 l -20 10 l -20 -10 l 10 -5"/>'
        "</g>";

    string private constant _LOGO =
        '<path fill="#ededed" '
        'd="M122.7,227.1 l-4.8,0l55.8,-74l0,3.2l-51.8,-69.2l5,0l48.8,65.4l-1.2,0l48.8,-65.4l4.8,0l-51.2,68.4l0,-1.6l55.2,73.2l-5,0l-52.8,-70.2l1.2,0l-52.8,70.2z" '
        'vector-effect="non-scaling-stroke" />';

    /**
        @dev internal helper to create HSL-encoded color prop for SVG tags
     */
    function colorHSL(Color memory c) internal pure returns (bytes memory) {
        return abi.encodePacked("hsl(", c.h.toString(), ", ", c.s.toString(), "%, ", c.l.toString(), "%)");
    }

    /**
        @dev internal helper to create `stop` SVG tag
     */
    function colorStop(Color memory c) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                '<stop stop-color="',
                colorHSL(c),
                '" stop-opacity="',
                c.a.toString(),
                '" offset="',
                c.off.toString(),
                '%"/>'
            );
    }

    /**
        @dev internal helper to encode position for `Gradient` SVG tag
     */
    function pos(uint256[4] memory coords) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                'x1="',
                coords[0].toString(),
                '%" '
                'y1="',
                coords[1].toString(),
                '%" '
                'x2="',
                coords[2].toString(),
                '%" '
                'y2="',
                coords[3].toString(),
                '%" '
            );
    }

    /**
        @dev internal helper to create `Gradient` SVG tag
     */
    function linearGradient(
        Color[] memory colors,
        uint256 id,
        uint256[4] memory coords
    ) internal pure returns (bytes memory) {
        string memory stops = "";
        for (uint256 i = 0; i < colors.length; i++) {
            if (colors[i].h != 0) {
                stops = string.concat(stops, string(colorStop(colors[i])));
            }
        }
        return
            abi.encodePacked(
                "<linearGradient  ",
                pos(coords),
                'id="g',
                id.toString(),
                '">',
                stops,
                "</linearGradient>"
            );
    }

    /**
        @dev internal helper to create `Defs` SVG tag
     */
    function defs(Gradient memory grad) internal pure returns (bytes memory) {
        return abi.encodePacked("<defs>", linearGradient(grad.colors, 0, grad.coords), "</defs>");
    }

    /**
        @dev internal helper to create `Rect` SVG tag
     */
    function rect(uint256 id) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<rect "
                'width="100%" '
                'height="100%" '
                'fill="url(#g',
                id.toString(),
                ')" '
                'rx="10px" '
                'ry="10px" '
                'stroke-linejoin="round" '
                "/>"
            );
    }

    /**
        @dev internal helper to create border `Rect` SVG tag
     */
    function border() internal pure returns (string memory) {
        return
            "<rect "
            'width="94%" '
            'height="96%" '
            'fill="transparent" '
            'rx="10px" '
            'ry="10px" '
            'stroke-linejoin="round" '
            'x="3%" '
            'y="2%" '
            'stroke-dasharray="1,6" '
            'stroke="white" '
            "/>";
    }

    /**
        @dev internal helper to create group `G` SVG tag
     */
    function g(uint256 gradientsCount) internal pure returns (bytes memory) {
        string memory background = "";
        for (uint256 i = 0; i < gradientsCount; i++) {
            background = string.concat(background, string(rect(i)));
        }
        return abi.encodePacked("<g>", background, border(), "</g>");
    }

    /**
        @dev internal helper to create XEN logo line pattern with 2 SVG `lines`
     */
    function logo() internal pure returns (bytes memory) {
        return abi.encodePacked();
    }

    /**
        @dev internal helper to create `Text` SVG tag with XEN Crypto contract data
     */
    function contractData(string memory symbol, address xenAddress) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<text "
                'x="50%" '
                'y="5%" '
                'class="base small" '
                'dominant-baseline="middle" '
                'text-anchor="middle">',
                symbol,
                unicode"・",
                xenAddress.toHexString(),
                "</text>"
            );
    }

    /**
        @dev internal helper to create 1st part of metadata section of SVG
     */
    function meta1(
        uint256 tokenId,
        uint256 amount,
        uint256 apy,
        uint256 rarityScore
    ) internal pure returns (bytes memory) {
        bytes memory part1 = abi.encodePacked(
            "<text "
            'x="50%" '
            'y="50%" '
            'class="base " '
            'dominant-baseline="middle" '
            'text-anchor="middle">'
            "XEN CRYPTO"
            "</text>"
            "<text "
            'x="50%" '
            'y="56%" '
            'class="base burn" '
            'text-anchor="middle" '
            'dominant-baseline="middle"> ',
            amount > 0 ? string.concat(amount.toFormattedString(), " X") : "",
            "</text>"
            "<text "
            'x="18%" '
            'y="62%" '
            'class="base meta" '
            'dominant-baseline="middle"> '
            "#",
            tokenId.toString(),
            "</text>"
            "<text "
            'x="82%" '
            'y="62%" '
            'class="base meta series" '
            'dominant-baseline="middle" '
            'text-anchor="end" >STAKE</text>'
        );
        bytes memory part2 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="68%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "APY: ",
            apy.toString(),
            "%"
            "</text>"
            "<text "
            'x="18%" '
            'y="72%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Rarity: ",
            rarityScore.toString(),
            "</text>"
        );
        return abi.encodePacked(part1, part2);
    }

    /**
        @dev internal helper to create 2nd part of metadata section of SVG
     */
    function meta2(uint256 term, uint256 maturityTs) internal pure returns (bytes memory) {
        bytes memory part3 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="76%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Term: ",
            term.toString(),
            " days"
            "</text>"
            "<text "
            'x="18%" '
            'y="80%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Maturity: ",
            maturityTs.asString(),
            "</text>"
        );
        return abi.encodePacked(part3);
    }

    /**
        @dev main internal helper to create SVG file representing XENFT
     */
    function image(SvgParams memory params, Gradient[] memory gradients) internal pure returns (bytes memory) {
        string memory mark = _STAKE;
        bytes memory graphics = abi.encodePacked(defs(gradients[0]), _STYLE, g(gradients.length), _LOGO, mark);
        bytes memory metadata = abi.encodePacked(
            contractData(params.symbol, params.xenAddress),
            meta1(params.tokenId, params.amount, params.apy, params.rarityScore),
            meta2(params.term, params.maturityTs)
        );
        return
            abi.encodePacked(
                "<svg "
                'xmlns="http://www.w3.org/2000/svg" '
                'preserveAspectRatio="xMinYMin meet" '
                'viewBox="0 0 350 566">',
                graphics,
                metadata,
                "</svg>"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

// mapping: NFT tokenId => StakeInfo (used in tokenURI generation + other contracts)
// StakeInfo encoded as:
//      term (uint16)
//      | maturityTs (uint64)
//      | amount (uint128) TODO: storing here vs. separately as full uint256 ???
//      | apy (uint16)
//      | rarityScore (uint16)
//      | rarityBits (uint16):
//          [15] tokenIdIsPrime
//          [14] tokenIdIsFib
//          [14] blockIdIsPrime
//          [13] blockIdIsFib
//          [0-13] ...
library StakeInfo {
    /**
        @dev helper to convert Bool to U256 type and make compiler happy
     */
    // TODO: remove if not needed ???
    function toU256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    /**
        @dev encodes StakeInfo record from its props
     */
    function encodeStakeInfo(
        uint256 term,
        uint256 maturityTs,
        uint256 amount,
        uint256 apy,
        uint256 rarityScore,
        uint256 rarityBits
    ) public pure returns (uint256 info) {
        info = info | (rarityBits & 0xFFFF);
        info = info | ((rarityScore & 0xFFFF) << 16);
        info = info | ((apy & 0xFFFF) << 32);
        info = info | ((amount & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 48);
        info = info | ((maturityTs & 0xFFFFFFFFFFFFFFFF) << 176);
        info = info | ((term & 0xFFFF) << 240);
    }

    /**
        @dev decodes StakeInfo record and extracts all of its props
     */
    function decodeStakeInfo(
        uint256 info
    )
        public
        pure
        returns (uint256 term, uint256 maturityTs, uint256 amount, uint256 apy, uint256 rarityScore, uint256 rarityBits)
    {
        term = uint16(info >> 240);
        maturityTs = uint64(info >> 176);
        amount = uint128(info >> 48);
        apy = uint16(info >> 32);
        rarityScore = uint16(info >> 16);
        rarityBits = uint16(info);
    }

    /**
        @dev extracts `term` prop from encoded StakeInfo
     */
    function getTerm(uint256 info) public pure returns (uint256 term) {
        (term, , , , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `maturityTs` prop from encoded StakeInfo
     */
    function getMaturityTs(uint256 info) public pure returns (uint256 maturityTs) {
        (, maturityTs, , , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `amount` prop from encoded StakeInfo
     */
    function getAmount(uint256 info) public pure returns (uint256 amount) {
        (, , amount, , , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `APY` prop from encoded StakeInfo
     */
    function getAPY(uint256 info) public pure returns (uint256 apy) {
        (, , , apy, , ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `rarityScore` prop from encoded StakeInfo
     */
    function getRarityScore(uint256 info) public pure returns (uint256 rarityScore) {
        (, , , , rarityScore, ) = decodeStakeInfo(info);
    }

    /**
        @dev extracts `rarityBits` prop from encoded StakeInfo
     */
    function getRarityBits(uint256 info) public pure returns (uint256 rarityBits) {
        (, , , , , rarityBits) = decodeStakeInfo(info);
    }

    /**
        @dev decodes boolean flags from `rarityBits` prop
     */
    function decodeRarityBits(
        uint256 rarityBits
    ) public pure returns (bool isPrime, bool isFib, bool blockIsPrime, bool blockIsFib) {
        isPrime = rarityBits & 0x0008 > 0;
        isFib = rarityBits & 0x0004 > 0;
        blockIsPrime = rarityBits & 0x0002 > 0;
        blockIsFib = rarityBits & 0x0001 > 0;
    }

    /**
        @dev encodes boolean flags to `rarityBits` prop
     */
    function encodeRarityBits(
        bool isPrime,
        bool isFib,
        bool blockIsPrime,
        bool blockIsFib
    ) public pure returns (uint256 rarityBits) {
        rarityBits = rarityBits | ((toU256(isPrime) << 3) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(isFib) << 2) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(blockIsPrime) << 1) & 0xFFFF);
        rarityBits = rarityBits | ((toU256(blockIsFib)) & 0xFFFF);
    }

    /**
        @dev extracts `rarityBits` prop from encoded StakeInfo
     */
    function getRarityBitsDecoded(
        uint256 info
    ) public pure returns (bool isPrime, bool isFib, bool blockIsPrime, bool blockIsFib) {
        (, , , , , uint256 rarityBits) = decodeStakeInfo(info);
        (isPrime, isFib, blockIsPrime, blockIsFib) = decodeRarityBits(rarityBits);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library FormattedStrings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
            Base on OpenZeppelin `toString` method from `String` library
     */
    function toFormattedString(uint256 value) internal pure returns (string memory) {
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
        uint256 pos;
        uint256 comas = digits / 3;
        digits = digits + (digits % 3 == 0 ? comas - 1 : comas);
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            if (pos == 3) {
                buffer[digits] = ",";
                pos = 0;
            } else {
                buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
                value /= 10;
                pos++;
            }
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./BokkyPooBahsDateTimeLibrary.sol";

/*
    @dev        Library to convert epoch timestamp to a human-readable Date-Time string
    @dependency uses BokkyPooBahsDateTimeLibrary.sol library internally
 */
library DateTime {
    using Strings for uint256;

    bytes public constant MONTHS = bytes("JanFebMarAprMayJunJulAugSepOctNovDec");

    /**
     *   @dev returns month as short (3-letter) string
     */
    function monthAsString(uint256 idx) internal pure returns (string memory) {
        require(idx > 0, "bad idx");
        bytes memory str = new bytes(3);
        uint256 offset = (idx - 1) * 3;
        str[0] = bytes1(MONTHS[offset]);
        str[1] = bytes1(MONTHS[offset + 1]);
        str[2] = bytes1(MONTHS[offset + 2]);
        return string(str);
    }

    /**
     *   @dev returns string representation of number left-padded for 2 symbols
     */
    function asPaddedString(uint256 n) internal pure returns (string memory) {
        if (n == 0) return "00";
        if (n < 10) return string.concat("0", n.toString());
        return n.toString();
    }

    /**
     *   @dev returns string of format 'Jan 01, 2022 18:00 UTC' for a given timestamp
     */
    function asString(uint256 ts) external pure returns (string memory) {
        (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, ) = BokkyPooBahsDateTimeLibrary
            .timestampToDateTime(ts);
        return
            string(
                abi.encodePacked(
                    monthAsString(month),
                    " ",
                    day.toString(),
                    ", ",
                    year.toString(),
                    " ",
                    asPaddedString(hour),
                    ":",
                    asPaddedString(minute),
                    " UTC"
                )
            );
    }

    /**
     *   @dev returns (year, month as string) components of a date by timestamp
     */
    function yearAndMonth(uint256 ts) external pure returns (uint256, string memory) {
        (uint256 year, uint256 month, , , , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(ts);
        return (year, monthAsString(month));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

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
    uint256 constant _SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 constant _SECONDS_PER_HOUR = 60 * 60;
    uint256 constant _SECONDS_PER_MINUTE = 60;
    int256 constant _OFFSET19700101 = 2440588;

    uint256 constant _DOW_FRI = 5;
    uint256 constant _DOW_SAT = 6;

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
    function _daysFromDate(uint256 year, uint256 month, uint256 day) private pure returns (uint256 _days) {
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
            _OFFSET19700101;

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
    function _daysToDate(uint256 _days) private pure returns (uint256 year, uint256 month, uint256 day) {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + _OFFSET19700101;
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

    function timestampFromDate(uint256 year, uint256 month, uint256 day) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * _SECONDS_PER_DAY;
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
            _SECONDS_PER_DAY +
            hour *
            _SECONDS_PER_HOUR +
            minute *
            _SECONDS_PER_MINUTE +
            second;
    }

    function timestampToDate(uint256 timestamp) internal pure returns (uint256 year, uint256 month, uint256 day) {
        (year, month, day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
    }

    function timestampToDateTime(
        uint256 timestamp
    ) internal pure returns (uint256 year, uint256 month, uint256 day, uint256 hour, uint256 minute, uint256 second) {
        (year, month, day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        uint256 secs = timestamp % _SECONDS_PER_DAY;
        hour = secs / _SECONDS_PER_HOUR;
        secs = secs % _SECONDS_PER_HOUR;
        minute = secs / _SECONDS_PER_MINUTE;
        second = secs % _SECONDS_PER_MINUTE;
    }

    function isValidDate(uint256 year, uint256 month, uint256 day) internal pure returns (bool valid) {
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
        (uint256 year, , ) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) private pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }

    function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= _DOW_FRI;
    }

    function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= _DOW_SAT;
    }

    function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
        (uint256 year, uint256 month, ) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }

    function _getDaysInMonth(uint256 year, uint256 month) private pure returns (uint256 daysInMonth) {
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
        uint256 _days = timestamp / _SECONDS_PER_DAY;
        dayOfWeek = ((_days + 3) % 7) + 1;
    }

    function getYear(uint256 timestamp) internal pure returns (uint256 year) {
        (year, , ) = _daysToDate(timestamp / _SECONDS_PER_DAY);
    }

    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / _SECONDS_PER_DAY);
    }

    function getDay(uint256 timestamp) internal pure returns (uint256 day) {
        (, , day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
    }

    function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
        uint256 secs = timestamp % _SECONDS_PER_DAY;
        hour = secs / _SECONDS_PER_HOUR;
    }

    function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
        uint256 secs = timestamp % _SECONDS_PER_HOUR;
        minute = secs / _SECONDS_PER_MINUTE;
    }

    function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
        second = timestamp % _SECONDS_PER_MINUTE;
    }

    function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        year += _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * _SECONDS_PER_DAY + (timestamp % _SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = ((month - 1) % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * _SECONDS_PER_DAY + (timestamp % _SECONDS_PER_DAY);
        require(newTimestamp >= timestamp);
    }

    function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _days * _SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }

    function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _hours * _SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }

    function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _minutes * _SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }

    function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        year -= _years;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * _SECONDS_PER_DAY + (timestamp % _SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        uint256 yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = (yearMonth % 12) + 1;
        uint256 daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * _SECONDS_PER_DAY + (timestamp % _SECONDS_PER_DAY);
        require(newTimestamp <= timestamp);
    }

    function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _days * _SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }

    function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _hours * _SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }

    function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _minutes * _SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }

    function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, , ) = _daysToDate(fromTimestamp / _SECONDS_PER_DAY);
        (uint256 toYear, , ) = _daysToDate(toTimestamp / _SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }

    function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
        require(fromTimestamp <= toTimestamp);
        (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / _SECONDS_PER_DAY);
        (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / _SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }

    function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / _SECONDS_PER_DAY;
    }

    function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / _SECONDS_PER_HOUR;
    }

    function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / _SECONDS_PER_MINUTE;
    }

    function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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