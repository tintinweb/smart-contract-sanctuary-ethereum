// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./MintInfo.sol";
import "./DateTime.sol";
import "./FormattedStrings.sol";
import "./SVG.sol";

/**
    @dev Library contains methods to generate on-chain NFT metadata
*/
library Metadata {
    using DateTime for uint256;
    using MintInfo for uint256;
    using Strings for uint256;

    uint256 public constant POWER_GROUP_SIZE = 7_500;
    uint256 public constant MAX_POWER = 52_500;

    uint256 public constant COLORS_FULL_SCALE = 300;
    uint256 public constant SPECIAL_LUMINOSITY = 45;
    uint256 public constant BASE_SATURATION = 75;
    uint256 public constant BASE_LUMINOSITY = 38;
    uint256 public constant GROUP_SATURATION = 100;
    uint256 public constant GROUP_LUMINOSITY = 50;
    uint256 public constant DEFAULT_OPACITY = 1;
    uint256 public constant NO_COLOR = 360;

    // PRIVATE HELPERS

    // The following pure methods returning arrays are workaround to use array constants,
    // not yet available in Solidity

    function _powerGroupColors() private pure returns (uint256[8] memory) {
        return [uint256(360), 1, 30, 60, 120, 180, 240, 300];
    }

    function _huesApex() private pure returns (uint256[3] memory) {
        return [uint256(169), 210, 305];
    }

    function _huesLimited() private pure returns (uint256[3] memory) {
        return [uint256(263), 0, 42];
    }

    function _stopOffsets() private pure returns (uint256[3] memory) {
        return [uint256(10), 50, 90];
    }

    function _gradColorsRegular() private pure returns (uint256[4] memory) {
        return [uint256(150), 150, 20, 20];
    }

    function _gradColorsBlack() private pure returns (uint256[4] memory) {
        return [uint256(100), 100, 20, 20];
    }

    function _gradColorsSpecial() private pure returns (uint256[4] memory) {
        return [uint256(100), 100, 0, 0];
    }

    /**
        @dev private helper to determine XENFT group index by its power
             (power = count of VMUs * mint term in days)
     */
    function _powerGroup(uint256 vmus, uint256 term) private pure returns (uint256) {
        return (vmus * term) / POWER_GROUP_SIZE;
    }

    /**
        @dev private helper to generate SVG gradients for special XENFT categories
     */
    function _specialClassGradients(bool rare) private pure returns (SVG.Gradient[] memory gradients) {
        uint256[3] memory specialColors = rare ? _huesApex() : _huesLimited();
        SVG.Color[] memory colors = new SVG.Color[](3);
        for (uint256 i = 0; i < colors.length; i++) {
            colors[i] = SVG.Color({
                h: specialColors[i],
                s: BASE_SATURATION,
                l: SPECIAL_LUMINOSITY,
                a: DEFAULT_OPACITY,
                off: _stopOffsets()[i]
            });
        }
        gradients = new SVG.Gradient[](1);
        gradients[0] = SVG.Gradient({colors: colors, id: 0, coords: _gradColorsSpecial()});
    }

    /**
        @dev private helper to generate SVG gradients for common XENFT category
     */
    function _commonCategoryGradients(uint256 vmus, uint256 term)
        private
        pure
        returns (SVG.Gradient[] memory gradients)
    {
        SVG.Color[] memory colors = new SVG.Color[](2);
        uint256 powerHue = term * vmus > MAX_POWER ? NO_COLOR : 1 + (term * vmus * COLORS_FULL_SCALE) / MAX_POWER;
        // group
        uint256 groupHue = _powerGroupColors()[_powerGroup(vmus, term) > 7 ? 7 : _powerGroup(vmus, term)];
        colors[0] = SVG.Color({
            h: groupHue,
            s: groupHue == NO_COLOR ? 0 : GROUP_SATURATION,
            l: groupHue == NO_COLOR ? 0 : GROUP_LUMINOSITY,
            a: DEFAULT_OPACITY,
            off: _stopOffsets()[0]
        });
        // power
        colors[1] = SVG.Color({
            h: powerHue,
            s: powerHue == NO_COLOR ? 0 : BASE_SATURATION,
            l: powerHue == NO_COLOR ? 0 : BASE_LUMINOSITY,
            a: DEFAULT_OPACITY,
            off: _stopOffsets()[2]
        });
        gradients = new SVG.Gradient[](1);
        gradients[0] = SVG.Gradient({
            colors: colors,
            id: 0,
            coords: groupHue == NO_COLOR ? _gradColorsBlack() : _gradColorsRegular()
        });
    }

    // PUBLIC INTERFACE

    /**
        @dev public interface to generate SVG image based on XENFT params
     */
    function svgData(
        uint256 tokenId,
        uint256 count,
        uint256 info,
        address token,
        uint256 burned
    ) external view returns (bytes memory) {
        string memory symbol = IERC20Metadata(token).symbol();
        (uint256 classIds, bool rare, bool limited) = info.getClass();
        SVG.SvgParams memory params = SVG.SvgParams({
            symbol: symbol,
            xenAddress: token,
            tokenId: tokenId,
            term: info.getTerm(),
            rank: info.getRank(),
            count: count,
            maturityTs: info.getMaturityTs(),
            amp: info.getAMP(),
            eaa: info.getEAA(),
            xenBurned: burned,
            series: StringData.getClassName(StringData.CLASSES, classIds),
            redeemed: info.getRedeemed()
        });
        uint256 quoteIdx = uint256(keccak256(abi.encode(info))) % StringData.QUOTES_COUNT;
        if (rare || limited) {
            return SVG.image(params, _specialClassGradients(rare), quoteIdx, rare, limited);
        }
        return SVG.image(params, _commonCategoryGradients(count, info.getTerm()), quoteIdx, rare, limited);
    }

    function _attr1(
        uint256 count,
        uint256 rank,
        uint256 class_
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"Class","value":"',
                StringData.getClassName(StringData.CLASSES, class_),
                '"},'
                '{"trait_type":"VMUs","value":"',
                count.toString(),
                '"},'
                '{"trait_type":"cRank","value":"',
                rank.toString(),
                '"},'
            );
    }

    function _attr2(
        uint256 amp,
        uint256 eaa,
        uint256 maturityTs
    ) private pure returns (bytes memory) {
        (uint256 year, string memory month) = DateTime.yearAndMonth(maturityTs);
        return
            abi.encodePacked(
                '{"trait_type":"AMP","value":"',
                amp.toString(),
                '"},'
                '{"trait_type":"EAA (%)","value":"',
                (eaa / 10).toString(),
                '"},'
                '{"trait_type":"Maturity Year","value":"',
                year.toString(),
                '"},'
                '{"trait_type":"Maturity Month","value":"',
                month,
                '"},'
            );
    }

    function _attr3(
        uint256 maturityTs,
        uint256 term,
        uint256 burned
    ) private pure returns (bytes memory) {
        return
            abi.encodePacked(
                '{"trait_type":"Maturity DateTime","value":"',
                maturityTs.asString(),
                '"},'
                '{"trait_type":"Term","value":"',
                term.toString(),
                '"},'
                '{"trait_type":"XEN Burned","value":"',
                (burned / 10**18).toString(),
                '"},'
            );
    }

    function _attr4(bool apex, bool limited) private pure returns (bytes memory) {
        string memory category = "Collector";
        if (limited) category = "Limited";
        if (apex) category = "Apex";
        return abi.encodePacked('{"trait_type":"Category","value":"', category, '"}');
    }

    /**
        @dev private helper to construct attributes portion of NFT metadata
     */
    function attributes(
        uint256 count,
        uint256 burned,
        uint256 mintInfo
    ) external pure returns (bytes memory) {
        (
            uint256 term,
            uint256 maturityTs,
            uint256 rank,
            uint256 amp,
            uint256 eaa,
            uint256 series,
            bool apex,
            bool limited,

        ) = MintInfo.decodeMintInfo(mintInfo);
        return
            abi.encodePacked(
                "[",
                _attr1(count, rank, series),
                _attr2(amp, eaa, maturityTs),
                _attr3(maturityTs, term, burned),
                _attr4(apex, limited),
                "]"
            );
    }

    function formattedString(uint256 n) public pure returns (string memory) {
        return FormattedStrings.toFormattedString(n);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/*
    Extra XEN quotes:

    "When you realize nothing is lacking, the whole world belongs to you." - Lao Tzu
    "Each morning, we are born again. What we do today is what matters most." - Buddha
    "If you are depressed, you are living in the past." - Lao Tzu
    "In true dialogue, both sides are willing to change." - Thich Nhat Hanh
    "The spirit of the individual is determined by his domination thought habits." - Bruce Lee
    "Be the path. Do not seek it." - Yara Tschallener
    "Bow to no one but your own divinity." - Satya
    "With insight there is hope for awareness, and with awareness there can be change." - Tom Kenyon
    "The opposite of depression isn't happiness, it is purpose." - Derek Sivers
    "If you can't, you must." - Tony Robbins
    “When you are grateful, fear disappears and abundance appears.” - Lao Tzu
    “It is in your moments of decision that your destiny is shaped.” - Tony Robbins
    "Surmounting difficulty is the crucible that forms character." - Tony Robbins
    "Three things cannot be long hidden: the sun, the moon, and the truth." - Buddha
    "What you are is what you have been. What you’ll be is what you do now." - Buddha
    "The best way to take care of our future is to take care of the present moment." - Thich Nhat Hanh
*/

/**
   @dev  a library to supply a XEN string data based on params
*/
library StringData {
    uint256 public constant QUOTES_COUNT = 12;
    uint256 public constant QUOTE_LENGTH = 66;
    bytes public constant QUOTES =
        bytes(
            '"If you realize you have enough, you are truly rich." - Lao Tzu   '
            '"The real meditation is how you live your life." - Jon Kabat-Zinn '
            '"To know that you do not know is the best." - Lao Tzu             '
            '"An over-sharpened sword cannot last long." - Lao Tzu             '
            '"When you accept yourself, the whole world accepts you." - Lao Tzu'
            '"Music in the soul can be heard by the universe." - Lao Tzu       '
            '"As soon as you have made a thought, laugh at it." - Lao Tzu      '
            '"The further one goes, the less one knows." - Lao Tzu             '
            '"Stop thinking, and end your problems." - Lao Tzu                 '
            '"Reliability is the foundation of commitment." - Unknown          '
            '"Your past does not equal your future." - Tony Robbins            '
            '"Be the path. Do not seek it." - Yara Tschallener                 '
        );
    uint256 public constant CLASSES_COUNT = 14;
    uint256 public constant CLASSES_NAME_LENGTH = 10;
    bytes public constant CLASSES =
        bytes(
            "Ruby      "
            "Opal      "
            "Topaz     "
            "Emerald   "
            "Aquamarine"
            "Sapphire  "
            "Amethyst  "
            "Xenturion "
            "Limited   "
            "Rare      "
            "Epic      "
            "Legendary "
            "Exotic    "
            "Xunicorn  "
        );

    /**
        @dev    Solidity doesn't yet support slicing of byte arrays anywhere outside of calldata,
                therefore we make a hack by supplying our local constant packed string array as calldata
    */
    function getQuote(bytes calldata quotes, uint256 index) external pure returns (string memory) {
        if (index > QUOTES_COUNT - 1) return string(quotes[0:QUOTE_LENGTH]);
        return string(quotes[index * QUOTE_LENGTH:(index + 1) * QUOTE_LENGTH]);
    }

    function getClassName(bytes calldata names, uint256 index) external pure returns (string memory) {
        if (index < CLASSES_COUNT) return string(names[index * CLASSES_NAME_LENGTH:(index + 1) * CLASSES_NAME_LENGTH]);
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./DateTime.sol";
import "./StringData.sol";
import "./FormattedStrings.sol";

/*
    @dev        Library to create SVG image for XENFT metadata
    @dependency depends on DataTime.sol and StringData.sol libraries
 */
library SVG {
    // Type to encode all data params for SVG image generation
    struct SvgParams {
        string symbol;
        address xenAddress;
        uint256 tokenId;
        uint256 term;
        uint256 rank;
        uint256 count;
        uint256 maturityTs;
        uint256 amp;
        uint256 eaa;
        uint256 xenBurned;
        bool redeemed;
        string series;
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

    string private constant _COLLECTOR =
        "<g>"
        "<path "
        'stroke="#ededed" '
        'fill="none" '
        'transform="translate(265,418)" '
        'd="m 0 0 L -20 -30 L -12.5 -38.5 l 6.5 7 L 0 -38.5 L 6.56 -31.32 L 12.5 -38.5 L 20 -30 L 0 0 L -7.345 -29.955 L 0 -38.5 L 7.67 -30.04 L 0 0 Z M 0 0 L -20.055 -29.955 l 7.555 -8.545 l 24.965 -0.015 L 20 -30 L -20.055 -29.955"/>'
        "</g>";

    string private constant _LIMITED =
        "<g> "
        '<path fill="#ededed" '
        'transform="scale(0.4) translate(600, 940)" '
        'd="M66,38.09q.06.9.18,1.71v.05c1,7.08,4.63,11.39,9.59,13.81,5.18,2.53,11.83,3.09,18.48,2.61,1.49-.11,3-.27,4.39-.47l1.59-.2c4.78-.61,11.47-1.48,13.35-5.06,1.16-2.2,1-5,0-8a38.85,38.85,0,0,0-6.89-11.73A32.24,32.24,0,0,0,95,21.46,21.2,21.2,0,0,0,82.3,20a23.53,23.53,0,0,0-12.75,7,15.66,15.66,0,0,0-2.35,3.46h0a20.83,20.83,0,0,0-1,2.83l-.06.2,0,.12A12,12,0,0,0,66,37.9l0,.19Zm26.9-3.63a5.51,5.51,0,0,1,2.53-4.39,14.19,14.19,0,0,0-5.77-.59h-.16l.06.51a5.57,5.57,0,0,0,2.89,4.22,4.92,4.92,0,0,0,.45.24ZM88.62,28l.94-.09a13.8,13.8,0,0,1,8,1.43,7.88,7.88,0,0,1,3.92,6.19l0,.43a.78.78,0,0,1-.66.84A19.23,19.23,0,0,1,98,37a12.92,12.92,0,0,1-6.31-1.44A7.08,7.08,0,0,1,88,30.23a10.85,10.85,0,0,1-.1-1.44.8.8,0,0,1,.69-.78ZM14.15,10c-.06-5.86,3.44-8.49,8-9.49C26.26-.44,31.24.16,34.73.7A111.14,111.14,0,0,1,56.55,6.4a130.26,130.26,0,0,1,22,10.8,26.25,26.25,0,0,1,3-.78,24.72,24.72,0,0,1,14.83,1.69,36,36,0,0,1,13.09,10.42,42.42,42.42,0,0,1,7.54,12.92c1.25,3.81,1.45,7.6-.23,10.79-2.77,5.25-10.56,6.27-16.12,7l-1.23.16a54.53,54.53,0,0,1-2.81,12.06A108.62,108.62,0,0,1,91.3,84v25.29a9.67,9.67,0,0,1,9.25,10.49c0,.41,0,.81,0,1.18a1.84,1.84,0,0,1-1.84,1.81H86.12a8.8,8.8,0,0,1-5.1-1.56,10.82,10.82,0,0,1-3.35-4,2.13,2.13,0,0,1-.2-.46L73.53,103q-2.73,2.13-5.76,4.16c-1.2.8-2.43,1.59-3.69,2.35l.6.16a8.28,8.28,0,0,1,5.07,4,15.38,15.38,0,0,1,1.71,7.11V121a1.83,1.83,0,0,1-1.83,1.83h-53c-2.58.09-4.47-.52-5.75-1.73A6.49,6.49,0,0,1,9.11,116v-11.2a42.61,42.61,0,0,1-6.34-11A38.79,38.79,0,0,1,1.11,70.29,37,37,0,0,1,13.6,50.54l.1-.09a41.08,41.08,0,0,1,11-6.38c7.39-2.9,17.93-2.77,26-2.68,5.21.06,9.34.11,10.19-.49a4.8,4.8,0,0,0,1-.91,5.11,5.11,0,0,0,.56-.84c0-.26,0-.52-.07-.78a16,16,0,0,1-.06-4.2,98.51,98.51,0,0,0-18.76-3.68c-7.48-.83-15.44-1.19-23.47-1.41l-1.35,0c-2.59,0-4.86,0-7.46-1.67A9,9,0,0,1,8,23.68a9.67,9.67,0,0,1-.91-5A10.91,10.91,0,0,1,8.49,14a8.74,8.74,0,0,1,3.37-3.29A8.2,8.2,0,0,1,14.15,10ZM69.14,22a54.75,54.75,0,0,1,4.94-3.24,124.88,124.88,0,0,0-18.8-9A106.89,106.89,0,0,0,34.17,4.31C31,3.81,26.44,3.25,22.89,4c-2.55.56-4.59,1.92-5,4.79a134.49,134.49,0,0,1,26.3,3.8,115.69,115.69,0,0,1,25,9.4ZM64,28.65c.21-.44.42-.86.66-1.28a15.26,15.26,0,0,1,1.73-2.47,146.24,146.24,0,0,0-14.92-6.2,97.69,97.69,0,0,0-15.34-4A123.57,123.57,0,0,0,21.07,13.2c-3.39-.08-6.3.08-7.47.72a5.21,5.21,0,0,0-2,1.94,7.3,7.3,0,0,0-1,3.12,6.1,6.1,0,0,0,.55,3.11,5.43,5.43,0,0,0,2,2.21c1.73,1.09,3.5,1.1,5.51,1.12h1.43c8.16.23,16.23.59,23.78,1.42a103.41,103.41,0,0,1,19.22,3.76,17.84,17.84,0,0,1,.85-2Zm-.76,15.06-.21.16c-1.82,1.3-6.48,1.24-12.35,1.17C42.91,45,32.79,44.83,26,47.47a37.41,37.41,0,0,0-10,5.81l-.1.08A33.44,33.44,0,0,0,4.66,71.17a35.14,35.14,0,0,0,1.5,21.32A39.47,39.47,0,0,0,12.35,103a1.82,1.82,0,0,1,.42,1.16v12a3.05,3.05,0,0,0,.68,2.37,4.28,4.28,0,0,0,3.16.73H67.68a10,10,0,0,0-1.11-3.69,4.7,4.7,0,0,0-2.87-2.32,15.08,15.08,0,0,0-4.4-.38h-26a1.83,1.83,0,0,1-.15-3.65c5.73-.72,10.35-2.74,13.57-6.25,3.06-3.34,4.91-8.1,5.33-14.45v-.13A18.88,18.88,0,0,0,46.35,75a20.22,20.22,0,0,0-7.41-4.42,23.54,23.54,0,0,0-8.52-1.25c-4.7.19-9.11,1.83-12,4.83a1.83,1.83,0,0,1-2.65-2.52c3.53-3.71,8.86-5.73,14.47-6a27.05,27.05,0,0,1,9.85,1.44,24,24,0,0,1,8.74,5.23,22.48,22.48,0,0,1,6.85,15.82v.08a2.17,2.17,0,0,1,0,.36c-.47,7.25-2.66,12.77-6.3,16.75a21.24,21.24,0,0,1-4.62,3.77H57.35q4.44-2.39,8.39-5c2.68-1.79,5.22-3.69,7.63-5.67a1.82,1.82,0,0,1,2.57.24,1.69,1.69,0,0,1,.35.66L81,115.62a7,7,0,0,0,2.16,2.62,5.06,5.06,0,0,0,3,.9H96.88a6.56,6.56,0,0,0-1.68-4.38,7.19,7.19,0,0,0-4.74-1.83c-.36,0-.69,0-1,0a1.83,1.83,0,0,1-1.83-1.83V83.6a1.75,1.75,0,0,1,.23-.88,105.11,105.11,0,0,0,5.34-12.46,52,52,0,0,0,2.55-10.44l-1.23.1c-7.23.52-14.52-.12-20.34-3A20,20,0,0,1,63.26,43.71Z"/>'
        "</g>";

    string private constant _APEX =
        '<g transform="scale(0.5) translate(533, 790)">'
        '<circle r="39" stroke="#ededed" fill="transparent"/>'
        '<path fill="#ededed" '
        'd="M0,38 a38,38 0 0 1 0,-76 a19,19 0 0 1 0,38 a19,19 0 0 0 0,38 z m -5 -57 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0 z" '
        'fill-rule="evenodd"/>'
        '<path fill="#ededed" '
        'd="m -5, 19 a 5,5 0 1,0 10,0 a 5,5 0 1,0 -10,0"/>'
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
        @dev internal helper to create cRank range string
     */
    function rankAndCount(uint256 rank, uint256 count) internal pure returns (bytes memory) {
        if (count == 1) return abi.encodePacked(rank.toString());
        return abi.encodePacked(rank.toString(), "..", (rank + count - 1).toString());
    }

    /**
        @dev internal helper to create 1st part of metadata section of SVG
     */
    function meta1(
        uint256 tokenId,
        uint256 count,
        uint256 eaa,
        string memory series,
        uint256 xenBurned
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
            xenBurned > 0 ? string.concat((xenBurned / 10**18).toFormattedString(), " X") : "",
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
            'text-anchor="end" >',
            series,
            "</text>"
        );
        bytes memory part2 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="68%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "VMU: ",
            count.toString(),
            "</text>"
            "<text "
            'x="18%" '
            'y="72%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "EAA: ",
            (eaa / 10).toString(),
            "%"
            "</text>"
        );
        return abi.encodePacked(part1, part2);
    }

    /**
        @dev internal helper to create 2nd part of metadata section of SVG
     */
    function meta2(
        uint256 maturityTs,
        uint256 amp,
        uint256 term,
        uint256 rank,
        uint256 count
    ) internal pure returns (bytes memory) {
        bytes memory part3 = abi.encodePacked(
            "<text "
            'x="18%" '
            'y="76%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "AMP: ",
            amp.toString(),
            "</text>"
            "<text "
            'x="18%" '
            'y="80%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Term: ",
            term.toString()
        );
        bytes memory part4 = abi.encodePacked(
            " days"
            "</text>"
            "<text "
            'x="18%" '
            'y="84%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "cRank: ",
            rankAndCount(rank, count),
            "</text>"
            "<text "
            'x="18%" '
            'y="88%" '
            'class="base meta" '
            'dominant-baseline="middle" >'
            "Maturity: ",
            maturityTs.asString(),
            "</text>"
        );
        return abi.encodePacked(part3, part4);
    }

    /**
        @dev internal helper to create `Text` SVG tag for XEN quote
     */
    function quote(uint256 idx) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                "<text "
                'x="50%" '
                'y="95%" '
                'class="base small" '
                'dominant-baseline="middle" '
                'text-anchor="middle" >',
                StringData.getQuote(StringData.QUOTES, idx),
                "</text>"
            );
    }

    /**
        @dev internal helper to generate `Redeemed` stamp
     */
    function stamp(bool redeemed) internal pure returns (bytes memory) {
        if (!redeemed) return "";
        return
            abi.encodePacked(
                "<rect "
                'x="50%" '
                'y="77.5%" '
                'width="100" '
                'height="40" '
                'stroke="black" '
                'stroke-width="1" '
                'fill="none" '
                'rx="5px" '
                'ry="5px" '
                'transform="translate(-50,-20) '
                'rotate(-20,0,400)" />',
                "<text "
                'x="50%" '
                'y="77.5%" '
                'stroke="black" '
                'class="base meta" '
                'dominant-baseline="middle" '
                'text-anchor="middle" '
                'transform="translate(0,0) rotate(-20,-45,380)" >'
                "Redeemed"
                "</text>"
            );
    }

    /**
        @dev main internal helper to create SVG file representing XENFT
     */
    function image(
        SvgParams memory params,
        Gradient[] memory gradients,
        uint256 idx,
        bool apex,
        bool limited
    ) internal pure returns (bytes memory) {
        string memory mark = limited ? _LIMITED : apex ? _APEX : _COLLECTOR;
        bytes memory graphics = abi.encodePacked(defs(gradients[0]), _STYLE, g(gradients.length), _LOGO, mark);
        bytes memory metadata = abi.encodePacked(
            contractData(params.symbol, params.xenAddress),
            meta1(params.tokenId, params.count, params.eaa, params.series, params.xenBurned),
            meta2(params.maturityTs, params.amp, params.term, params.rank, params.count),
            quote(idx),
            stamp(params.redeemed)
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

// mapping: NFT tokenId => MintInfo (used in tokenURI generation)
// MintInfo encoded as:
//      term (uint16)
//      | maturityTs (uint64)
//      | rank (uint128)
//      | amp (uint16)
//      | eaa (uint16)
//      | class (uint8):
//          [7] isApex
//          [6] isLimited
//          [0-5] powerGroupIdx
//      | redeemed (uint8)
library MintInfo {
    /**
        @dev helper to convert Bool to U256 type and make compiler happy
     */
    function toU256(bool x) internal pure returns (uint256 r) {
        assembly {
            r := x
        }
    }

    /**
        @dev encodes MintInfo record from its props
     */
    function encodeMintInfo(
        uint256 term,
        uint256 maturityTs,
        uint256 rank,
        uint256 amp,
        uint256 eaa,
        uint256 class_,
        bool redeemed
    ) public pure returns (uint256 info) {
        info = info | (toU256(redeemed) & 0xFF);
        info = info | ((class_ & 0xFF) << 8);
        info = info | ((eaa & 0xFFFF) << 16);
        info = info | ((amp & 0xFFFF) << 32);
        info = info | ((rank & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) << 48);
        info = info | ((maturityTs & 0xFFFFFFFFFFFFFFFF) << 176);
        info = info | ((term & 0xFFFF) << 240);
    }

    /**
        @dev decodes MintInfo record and extracts all of its props
     */
    function decodeMintInfo(uint256 info)
        public
        pure
        returns (
            uint256 term,
            uint256 maturityTs,
            uint256 rank,
            uint256 amp,
            uint256 eaa,
            uint256 class,
            bool apex,
            bool limited,
            bool redeemed
        )
    {
        term = uint16(info >> 240);
        maturityTs = uint64(info >> 176);
        rank = uint128(info >> 48);
        amp = uint16(info >> 32);
        eaa = uint16(info >> 16);
        class = uint8(info >> 8) & 0x3F;
        apex = (uint8(info >> 8) & 0x80) > 0;
        limited = (uint8(info >> 8) & 0x40) > 0;
        redeemed = uint8(info) == 1;
    }

    /**
        @dev extracts `term` prop from encoded MintInfo
     */
    function getTerm(uint256 info) public pure returns (uint256 term) {
        (term, , , , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `maturityTs` prop from encoded MintInfo
     */
    function getMaturityTs(uint256 info) public pure returns (uint256 maturityTs) {
        (, maturityTs, , , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `rank` prop from encoded MintInfo
     */
    function getRank(uint256 info) public pure returns (uint256 rank) {
        (, , rank, , , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `AMP` prop from encoded MintInfo
     */
    function getAMP(uint256 info) public pure returns (uint256 amp) {
        (, , , amp, , , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `EAA` prop from encoded MintInfo
     */
    function getEAA(uint256 info) public pure returns (uint256 eaa) {
        (, , , , eaa, , , , ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `redeemed` prop from encoded MintInfo
     */
    function getClass(uint256 info)
        public
        pure
        returns (
            uint256 class_,
            bool apex,
            bool limited
        )
    {
        (, , , , , class_, apex, limited, ) = decodeMintInfo(info);
    }

    /**
        @dev extracts `redeemed` prop from encoded MintInfo
     */
    function getRedeemed(uint256 info) public pure returns (bool redeemed) {
        (, , , , , , , , redeemed) = decodeMintInfo(info);
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
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) private pure returns (uint256 _days) {
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
    function _daysToDate(uint256 _days)
        private
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
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

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
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

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
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
        (year, month, day) = _daysToDate(timestamp / _SECONDS_PER_DAY);
        uint256 secs = timestamp % _SECONDS_PER_DAY;
        hour = secs / _SECONDS_PER_HOUR;
        secs = secs % _SECONDS_PER_HOUR;
        minute = secs / _SECONDS_PER_MINUTE;
        second = secs % _SECONDS_PER_MINUTE;
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