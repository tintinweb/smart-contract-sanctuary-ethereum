// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./INounSoupRenderer.sol";
import "./INOUN.sol";
import "./Utils.sol";

//           _____                   _______                   _____                    _____
//          /\    \                 /::\    \                 /\    \                  /\    \
//         /::\____\               /::::\    \               /::\____\                /::\____\
//        /::::|   |              /::::::\    \             /:::/    /               /::::|   |
//       /:::::|   |             /::::::::\    \           /:::/    /               /:::::|   |
//      /::::::|   |            /:::/~~\:::\    \         /:::/    /               /::::::|   |
//     /:::/|::|   |           /:::/    \:::\    \       /:::/    /               /:::/|::|   |
//    /:::/ |::|   |          /:::/    / \:::\    \     /:::/    /               /:::/ |::|   |
//   /:::/  |::|   | _____   /:::/____/   \:::\____\   /:::/    /      _____    /:::/  |::|   | _____
//  /:::/   |::|   |/\    \ |:::|    |     |:::|    | /:::/____/      /\    \  /:::/   |::|   |/\    \
// /:: /    |::|   /::\____\|:::|____|     |:::|    ||:::|    /      /::\____\/:: /    |::|   /::\____\
// \::/    /|::|  /:::/    / \:::\    \   /:::/    / |:::|____\     /:::/    /\::/    /|::|  /:::/    /
//  \/____/ |::| /:::/    /   \:::\    \ /:::/    /   \:::\    \   /:::/    /  \/____/ |::| /:::/    /
//          |::|/:::/    /     \:::\    /:::/    /     \:::\    \ /:::/    /           |::|/:::/    /
//          |::::::/    /       \:::\__/:::/    /       \:::\    /:::/    /            |::::::/    /
//          |:::::/    /         \::::::::/    /         \:::\__/:::/    /             |:::::/    /
//          |::::/    /           \::::::/    /           \::::::::/    /              |::::/    /
//          /:::/    /             \::::/    /             \::::::/    /               /:::/    /
//         /:::/    /               \::/____/               \::::/    /               /:::/    /
//         \::/    /                 ~~                      \::/____/                \::/    /
//          \/____/                                           ~~                       \/____/
//           _____                   _______                   _____                    _____
//          /\    \                 /::\    \                 /\    \                  /\    \
//         /::\    \               /::::\    \               /::\____\                /::\    \
//        /::::\    \             /::::::\    \             /:::/    /               /::::\    \
//       /::::::\    \           /::::::::\    \           /:::/    /               /::::::\    \
//      /:::/\:::\    \         /:::/~~\:::\    \         /:::/    /               /:::/\:::\    \
//     /:::/__\:::\    \       /:::/    \:::\    \       /:::/    /               /:::/__\:::\    \
//     \:::\   \:::\    \     /:::/    / \:::\    \     /:::/    /               /::::\   \:::\    \
//   ___\:::\   \:::\    \   /:::/____/   \:::\____\   /:::/    /      _____    /::::::\   \:::\    \
//  /\   \:::\   \:::\    \ |:::|    |     |:::|    | /:::/____/      /\    \  /:::/\:::\   \:::\____\
// /::\   \:::\   \:::\____\|:::|____|     |:::|    ||:::|    /      /::\____\/:::/  \:::\   \:::|    |
// \:::\   \:::\   \::/    / \:::\    \   /:::/    / |:::|____\     /:::/    /\::/    \:::\  /:::|____|
//  \:::\   \:::\   \/____/   \:::\    \ /:::/    /   \:::\    \   /:::/    /  \/_____/\:::\/:::/    /
//   \:::\   \:::\    \        \:::\    /:::/    /     \:::\    \ /:::/    /            \::::::/    /
//    \:::\   \:::\____\        \:::\__/:::/    /       \:::\    /:::/    /              \::::/    /
//     \:::\  /:::/    /         \::::::::/    /         \:::\__/:::/    /                \::/____/
//      \:::\/:::/    /           \::::::/    /           \::::::::/    /                  ~~
//       \::::::/    /             \::::/    /             \::::::/    /
//        \::::/    /               \::/____/               \::::/    /
//         \::/    /                 ~~                      \::/____/
//          \/____/                                           ~~

contract NounSoupRenderer is INounSoupRenderer, Ownable {
    /// @notice The seed for our randomness
    uint256 private renderSeed;

    /// @notice we cache these when the descriptor is set so they don't change if the number of items change
    uint256 private backgroundCount;
    uint256 private bodyCount;
    uint256 private glassesCount;
    uint256 private accessoryCount;
    uint256 private headCount;

    /// @notice the contract address to render Nouns
    address public nounGenerator;
    /// @notice the contract address to decorate Nouns
    address public nounDecorator;

    /// @notice set the contract to render the Nouns
    function setNounGeneratorAddress(address address_) external onlyOwner {
        nounGenerator = address_;
        // we record these just in case new heads are added to the generator.
        // we don't want our soup to change because of the mods that happen when building the svg
        if (Address.isContract(address_)) {
            backgroundCount = INounDescriptor(nounGenerator).backgroundCount();
            bodyCount = INounDescriptor(nounGenerator).bodyCount();
            accessoryCount = INounDescriptor(nounGenerator).accessoryCount();
            glassesCount = INounDescriptor(nounGenerator).glassesCount();
            headCount = INounDescriptor(nounGenerator).headCount();
        }
        // generate this once for some psuedorandomness
        if (renderSeed == 0) {
            renderSeed =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            block.timestamp,
                            block.difficulty,
                            msg.sender
                        )
                    )
                ) %
                16669;
        }
    }

    /// @notice set the contract to decorate the Nouns
    function setNounDecoratorAddress(address address_) external onlyOwner {
        nounDecorator = address_;
    }

    /// @notice removes the background from the noun (this is destructive as it overwrites memory but at least it doesn't need to allocate any)
    function cleanNoun(string memory str)
        internal
        pure
        returns (string memory)
    {
        // let's make things readable below
        uint8 percentSign = 37;
        uint8 doubleQuote = 34;
        uint8 slash = 47;
        uint8 space = 32;
        // some state as we cruise through the noun svg
        bool foundPercent = false;
        bool foundClosingQuote = false;
        bool finishedCleaning = false;

        // let's treat it like bytes
        bytes memory bStr = bytes(str);

        // the first rect in a noun is the background.
        // so we want to go from this:
        // <rect width="100%" height="100%" fill="#d5d7e1" />
        // to:
        // <rect width="100%"                              />
        // ----
        // this is the only rect that uses % so the first time we see a %
        // so let's find the percent, and the closing quote and then put
        // a space until we get to the closing / char.

        // let's go char by char
        for (uint256 i = 0; i < bStr.length; i++) {
            // if we made it this far, we haven't found the % yet OR we aren't done erasing things.
            if (!foundPercent && uint8(bStr[i]) == percentSign) {
                // cool we found the %
                foundPercent = true;
            } else if (
                foundPercent &&
                !foundClosingQuote &&
                uint8(bStr[i]) == doubleQuote
            ) {
                // and this is the closing quote after the "100%", we wanna keep it so the svg/xml stays valid
                foundClosingQuote = true;
            } else if (
                foundClosingQuote &&
                !finishedCleaning &&
                uint8(bStr[i]) == slash
            ) {
                // ok, we made it to the "/" .. let's start passing through the chars again, instead of erasing.
                finishedCleaning = true;
                break;
            } else if (foundClosingQuote) {
                // if we have found the " but haven't seen the "/" yet, then we should just erase the data and put a space " "
                bStr[i] = bytes1(space);
            }
        }

        // so fresh and so clean clean
        return string(bStr);
    }

    // a pretty naive way to determine which character you get in a panel
    // but... we don't want to store a seed per token on mint because that's expensive
    // so this is a minimal amount of obfuscation considering the renderSeed
    // is only generated after mint out. we don't want to store the seed on mint
    // because that costs gas and we keep this cheap.
    function _seedForTokenId(uint256 tokenId_) public view returns (uint256) {
        return tokenId_ + renderSeed;
    }

    // switch it up from time to time
    function _randomizeSeed(uint256 seed) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(seed, renderSeed))) % (16789);
    }

    function _nounSeedForTokenSeed(uint256 seed)
        private
        view
        returns (INounSeeder.Seed memory)
    {
        uint48 backgroundId = uint48(seed % backgroundCount);
        uint48 bodyId = uint48(seed % bodyCount);
        uint48 accessoryId = uint48(seed % accessoryCount);
        uint48 headId = uint48(seed % headCount);
        uint48 glassesId = uint48(seed % glassesCount);

        return
            INounSeeder.Seed({
                background: backgroundId,
                body: bodyId,
                accessory: accessoryId,
                head: headId,
                glasses: glassesId
            });
    }

    /// @notice svg snippet for can & noun
    function _svgForCanAndNoun(INounSeeder.Seed memory seed)
        private
        view
        returns (string memory)
    {
        if (!Address.isContract(nounGenerator)) {
            return "";
        }

        string memory _base64NounSVG = INounDescriptor(nounGenerator)
            .generateSVGImage(seed);

        return
            string(
                abi.encodePacked(
                    '<svg viewBox="0 0 180 180" x="40" y="40" width="420" height="420"><use xlink:href="#_can" /><svg viewBox="0 0 320 320" x="60" y="90" width="60" height="60">',
                    cleanNoun(string(Base64.decode(_base64NounSVG))),
                    "</svg></svg>"
                )
            );
    }

    function _paletteForSeed(uint256 seed)
        private
        view
        returns (SoupPalette memory)
    {
        // v rare "black label"
        if (seed % 666 == 0) {
            return
                SoupPalette(
                    false,
                    false,
                    true,
                    false,
                    _NEAR_BLACK_COLOR,
                    _NEAR_BLACK_COLOR,
                    _BLACK_COLOR,
                    _NEAR_BLACK_COLOR,
                    BackgroundStyle.solid
                );
        }

        // regular palettes
        seed = _randomizeSeed(seed);
        bool isStandardColors = (seed % 5) == 0;
        seed = _randomizeSeed(seed);
        uint256 altSeed = ((seed + 1) * 2);
        seed = _randomizeSeed(seed);
        bool hasWhiteBackground = (seed % 5) == 0;

        seed = _randomizeSeed(seed);
        string memory p1 = isStandardColors
            ? _DEFAULT_TOP_COLOR
            : _PALETTE[seed % _PALETTE.length];
        string memory s1 = isStandardColors
            ? _DEFAULT_BOTTOM_COLOR
            : _PALETTE[(seed * 3) % _PALETTE.length];
        seed = _randomizeSeed(seed);
        string memory p2 = isStandardColors
            ? _DEFAULT_BADGE_COLOR
            : _PALETTE[(altSeed * 7) % _PALETTE.length];
        string memory s2 = isStandardColors
            ? _DEFAULT_BOTTOM_COLOR
            : _PALETTE[(altSeed * 5) % _PALETTE.length];

        BackgroundStyle bgStyle = BackgroundStyle.solid;
        seed = _randomizeSeed(seed);
        bool hasNonRepeatingColors = bytes(p1)[1] != bytes(s1)[1] &&
            bytes(s1)[1] != bytes(p2)[1] &&
            bytes(p2)[1] != bytes(s2)[1] &&
            bytes(s2)[1] != bytes(p1)[1];
        if (seed % 37 == 0 && hasNonRepeatingColors) {
            bgStyle = BackgroundStyle.rainbow;
        } else if (seed % 29 == 0) {
            bgStyle = BackgroundStyle.circles;
        } else if (seed % 23 == 0 && hasNonRepeatingColors) {
            // vertical stripes
            bgStyle = BackgroundStyle.stripes;
        } else if (seed % 19 == 0) {
            // checker board
            bgStyle = BackgroundStyle.grid;
        } else if (seed % 13 == 0) {
            // 50/50 horizontal
            bgStyle = BackgroundStyle.hSplit;
        } else if (seed % 9 == 0) {
            // 50/50 vertical
            bgStyle = BackgroundStyle.vSplit;
        }

        return
            SoupPalette(
                false,
                isStandardColors,
                false,
                hasWhiteBackground,
                p1,
                s1,
                p2,
                s2,
                bgStyle
            );
    }

    function _svgCircle(
        uint256 cx,
        uint256 cy,
        uint256 radius,
        string memory color
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<circle cx="',
                    Strings.toString(cx),
                    '%" cy="',
                    Strings.toString(cy),
                    '%" r="',
                    Strings.toString(radius),
                    '%" fill="',
                    color,
                    '"/>'
                )
            );
    }

    function _svgRect(
        uint256 x,
        uint256 y,
        uint256 width,
        uint256 height,
        string memory color
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    Strings.toString(x),
                    '%" y="',
                    Strings.toString(y),
                    '%" width="',
                    Strings.toString(width),
                    '%" height="',
                    Strings.toString(height),
                    '%" fill="',
                    color,
                    '"/>'
                )
            );
    }

    function _backgroundForSeed(uint256 seed, SoupPalette memory palette)
        private
        pure
        returns (string memory)
    {
        // default is the primary color as the background
        string memory background = _svgRect(
            0,
            0,
            100,
            100,
            palette.hasWhiteBackground ? _DEFAULT_BOTTOM_COLOR : palette.p1
        );

        if (palette.bgStyle == BackgroundStyle.rainbow) {
            uint256 stripeCount = 6;
            string[4] memory colors = [
                palette.p1,
                palette.s1,
                palette.p2,
                palette.s2
            ];
            for (uint256 i = 0; i <= stripeCount; i++) {
                background = string(
                    abi.encodePacked(
                        background,
                        _svgCircle(
                            50,
                            100,
                            99 - (11 * i),
                            colors[i % colors.length]
                        )
                    )
                );
            }
        } else if (palette.bgStyle == BackgroundStyle.circles) {
            string[3] memory colors = [palette.s1, palette.p2, palette.s2];

            uint256 gridSize = 5 * ((seed % 2) + 1); //10;
            for (uint256 i = 0; i <= gridSize; i++) {
                for (uint256 j = 0; j <= gridSize; j++) {
                    background = string(
                        abi.encodePacked(
                            background,
                            _svgCircle(
                                (100 / gridSize) *
                                    i +
                                    ((j % 2) * (100 / gridSize)) /
                                    2,
                                (100 / gridSize) * j,
                                (100 / gridSize) / 3,
                                colors[(i + j) % colors.length]
                            )
                        )
                    );
                }
            }
        } else if (palette.bgStyle == BackgroundStyle.stripes) {
            background = "";
            uint256 stripeCount = 25;
            string[4] memory colors = [
                palette.p1,
                palette.s1,
                palette.p2,
                palette.s2
            ];
            for (uint256 i = 0; i <= stripeCount; i++) {
                background = string(
                    abi.encodePacked(
                        background,
                        _svgRect(
                            (100 / stripeCount) * i,
                            0,
                            (100 / stripeCount),
                            100,
                            colors[i % colors.length]
                        )
                    )
                );
            }
        } else if (palette.bgStyle == BackgroundStyle.grid) {
            background = string(
                abi.encodePacked(
                    background,
                    _svgRect(0, 50, 50, 50, palette.s1),
                    _svgRect(50, 50, 50, 50, palette.p1),
                    _svgRect(50, 0, 50, 50, palette.s1)
                )
            );
        } else if (palette.bgStyle == BackgroundStyle.hSplit) {
            // 50/50 horizontal
            background = string(
                abi.encodePacked(
                    background,
                    _svgRect(0, 0, 50, 100, palette.s1)
                )
            );
        } else if (palette.bgStyle == BackgroundStyle.vSplit) {
            // 50/50 vertical
            background = string(
                abi.encodePacked(
                    background,
                    _svgRect(0, 0, 100, 50, palette.s1)
                )
            );
        }

        return background;
    }

    /// @notice the svg for the nft with tokenId_
    function _fullSVGForToken(
        uint256 tokenSeed,
        INounSeeder.Seed memory nounSeed,
        SoupPalette memory palette
    ) private view returns (string memory) {
        string memory bg = palette.hasWhiteBackground ||
            palette.isBlackLabel ||
            palette.isClassic
            ? ""
            : _backgroundForSeed(tokenSeed, palette);

        string memory svg1 = string(
            abi.encodePacked(
                _CAN_1,
                palette.isBlackLabel
                    ? _NEAR_BLACK_COLOR
                    : _DEFAULT_BOTTOM_COLOR,
                _CAN_2,
                bg,
                _svgForCanAndNoun(nounSeed),
                _CAN_3,
                palette.s2
            )
        );

        string memory svg2 = string(
            abi.encodePacked(
                _CAN_4,
                palette.p1,
                _CAN_5,
                palette.p2,
                _CAN_6,
                palette.p1
            )
        );

        string memory svg3 = string(
            abi.encodePacked(
                _CAN_7,
                palette.s1,
                _CAN_8,
                palette.p2,
                _CAN_9,
                palette.isBlackLabel ? _NEAR_BLACK_COLOR : _BLACK_COLOR,
                _CAN_10
            )
        );

        return string(abi.encodePacked(svg1, svg2, svg3));
    }

    function _attributeJSONSnip(
        string memory attrName,
        string memory attrValue,
        bool hasMore
    ) private pure returns (string memory) {
        string memory traitStart = '{"trait_type": "';
        string memory traitMiddle = '", "value": "';
        string memory traitEnd = '"}';
        string memory traitHasMore = ", ";

        return
            string(
                abi.encodePacked(
                    traitStart,
                    attrName,
                    traitMiddle,
                    attrValue,
                    traitEnd,
                    hasMore ? traitHasMore : ""
                )
            );
    }

    function generateData(uint256 tokenId_)
        public
        view
        returns (string memory svg, string memory attributes)
    {
        uint256 seed = _seedForTokenId(tokenId_);
        INounSeeder.Seed memory nounSeed = _nounSeedForTokenSeed(seed);
        SoupPalette memory palette;

        // v rare "black label"
        if (tokenId_ == 1) {
            palette = SoupPalette(
                true,
                false,
                false,
                false,
                _UKRAINE_PALETTE[0],
                _UKRAINE_PALETTE[1],
                _UKRAINE_PALETTE[0],
                _UKRAINE_PALETTE[1],
                BackgroundStyle.vSplit
            );
        } else {
            palette = _paletteForSeed(seed);
        }

        seed = _randomizeSeed(seed);

        string memory canNounSvg = _fullSVGForToken(seed, nounSeed, palette);

        string memory bgString = palette.isUkraine
            ? "Flag"
            : (palette.isClassic || palette.hasWhiteBackground)
            ? "Classic"
            : "Solid";

        if (
            !palette.isUkraine &&
            !palette.isClassic &&
            !palette.hasWhiteBackground
        ) {
            if (palette.bgStyle == BackgroundStyle.circles) {
                bgString = "Polka";
            } else if (palette.bgStyle == BackgroundStyle.stripes) {
                bgString = "Stripes";
            } else if (palette.bgStyle == BackgroundStyle.grid) {
                bgString = "Grid";
            } else if (palette.bgStyle == BackgroundStyle.hSplit) {
                bgString = "Side Split";
            } else if (palette.bgStyle == BackgroundStyle.vSplit) {
                bgString = "Split";
            }
        }

        string memory attributesString = string(
            abi.encodePacked(
                ', "attributes": [',
                _attributeJSONSnip(
                    "Style",
                    palette.isUkraine ? "Ukraine" : palette.isClassic
                        ? "Classic"
                        : palette.isBlackLabel
                        ? "Black Label"
                        : "Screenprint",
                    true
                ),
                _attributeJSONSnip(
                    "Background",
                    bgString,
                    Address.isContract(nounDecorator)
                )
            )
        );

        // combine

        if (Address.isContract(nounDecorator)) {
            INounDecorator decorator = INounDecorator(nounDecorator);
            attributesString = string(
                abi.encodePacked(
                    attributesString,
                    _attributeJSONSnip(
                        "Head",
                        decorator.headMapping(nounSeed.head),
                        true
                    ),
                    _attributeJSONSnip(
                        "Body",
                        decorator.bodyMapping(nounSeed.body),
                        true
                    ),
                    _attributeJSONSnip(
                        "Accessory",
                        decorator.accessoryMapping(nounSeed.accessory),
                        true
                    ),
                    _attributeJSONSnip(
                        "Glasses",
                        decorator.glassesMapping(nounSeed.glasses),
                        false
                    )
                )
            );
        }

        attributesString = string(abi.encodePacked(attributesString, "]"));
        return (canNounSvg, attributesString);
    }

    ////////////// svg snippets for the image making

    enum BackgroundStyle {
        rainbow,
        circles,
        stripes,
        solid,
        vSplit,
        hSplit,
        grid
    }

    struct SoupPalette {
        bool isUkraine;
        bool isClassic;
        bool isBlackLabel;
        bool hasWhiteBackground;
        string p1;
        string s1;
        string p2;
        string s2;
        BackgroundStyle bgStyle;
    }

    string private constant _BLACK_COLOR = "#000";
    string private constant _NEAR_BLACK_COLOR = "#222";
    string private constant _DEFAULT_TOP_COLOR = "#d10f11";
    string private constant _DEFAULT_BADGE_COLOR = "#705b2c";
    string private constant _DEFAULT_BOTTOM_COLOR = "#fff";

    string[] private _UKRAINE_PALETTE = ["#fbd035", "#1650ae"];

    string[] private _PALETTE = [
        "#3b0f0e",
        "#cc2726",
        "#3e6c23",
        "#6d3b7c",
        "#951b4e",
        "#494337",
        "#7f405d",
        "#539f79",
        "#3e698b",
        "#03bfac",
        "#ed3192",
        "#9f9d48",
        "#e9bc25",
        "#fbce03",
        "#be7998",
        "#ef7d01",
        "#b7b230",
        "#adc8db",
        "#fa65ae",
        "#8dc6e3",
        "#d3c7d3",
        "#86f3ba",
        "#1dbacc",
        "#ed3192",
        "#75dfca",
        "#fa8c82"
    ];

    string private constant _CAN_1 =
        '<svg viewBox="0 0 500 500" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink"><svg width="500" height="500"><rect width="500" height="500" fill="';

    string private constant _CAN_2 = '" />';

    string private constant _CAN_3 =
        '</svg><defs><svg id="_can" viewBox="0 0 54 91" fill-rule="evenodd"><path d="M26.802 72.29c12.219 0 23.294.87 26.285 5.026.74 1.03.43 3.312.43 4.14 0 5.09-12.125 8.937-26.715 8.937S1.46 86.221.366 81.513c-.416-1.792.052-3.47.585-3.88 2.923-2.249 13.35-5.343 25.851-5.343z"/><path d="M26.852 72.787c12.038 0 22.961.968 25.907 4.847.73.961.468 2.798.468 3.57 0 4.751-11.946 8.662-26.321 8.662-14.374 0-24.967-4.215-26.045-8.608-.41-1.672.079-2.834.604-3.216 2.88-2.099 13.071-5.255 25.387-5.255z" fill="#7f7f7f"/><path d="M3.178 84.587c.241-.888-.816-2.071-1.372-2.853-.479-.674-.478-1.036-.214-.816.447.375 2.274 2.045 4.317 3.089 1.492.763 4.895 1.701 5.098 2.23.106.278-3.87-1.077-4.829-1.139-.4-.026-.925.767-.925.767s-2.3-.448-2.075-1.278zm47.176.769c.355-.274-1.516.167-1.325-.239.148-.314 1.282-1.08 2.144-1.903.67-.64 1.453-2.437 1.076-2.072-3.141 3.043-8.424 4.903-10.278 5.336-.471.109-.031.277.915.275 1.161-.003 2.685-.866 3.505-.687.366.08-.422 1.188-.053 1.122.66-.118 3.567-1.487 4.016-1.832z"/><path d="M52.744 5.258s-4.783 3.123-25.955 3.331C7.393 8.779 1.248 5.258 1.248 5.258v73.871s4.26 7.975 25.946 7.889c22.541-.09 25.55-7.889 25.55-7.889V5.258z" fill="';

    string private constant _CAN_4 =
        '" stroke="#000" stroke-width=".7"/><path d="M52.516 5.604S48.013 8.392 26.841 8.6C7.445 8.79 1.565 5.528 1.565 5.528v27.933s3.995 5.22 25.681 5.145c25.715-.09 25.27-5.068 25.27-5.068V5.604z" fill="';

    string private constant _CAN_5 =
        '"/><path d="M22.393 80.092c.107-.309.121-.576.042-.801a1.17 1.17 0 00-.4-.541c-.203-.158-.554-.25-.678-.274-.296-.057-.617-.039-.724-.008-.653.19-.871.642-.953.847a1.35 1.35 0 00-.089.656c.024.234.099.475.286.674.226.24.58.344.679.378.099.035.381.139.473.312.153.288.03.512-.057.58-.247.192-.523.004-.613-.079a.378.378 0 01-.116-.329 5.967 5.967 0 01-.483-.082 2.413 2.413 0 00-.492-.058l-.006.038c-.043.202-.029.387.027.561.143.44.562.697.738.787.175.089.355.151.542.182.297.049.64-.019.759-.056a.994.994 0 00.578-.492c.068-.103.227-.392.243-.686a2.245 2.245 0 00-.015-.357c-.045-.404-.356-.715-.531-.863a1.512 1.512 0 00-.594-.31c-.088-.026-.352-.065-.37-.423-.008-.165.125-.276.228-.301a.467.467 0 01.539.198c.061.087.07.186.027.297.142.064.299.106.469.125.171.019.332.027.485.024l.006.001zm3.948.271c.04-.752-.131-.921-.332-1.11a1.144 1.144 0 00-.406-.23c-.153-.055-.553-.172-.962-.091-.163.033-.464.066-.611.239-.146.173-.332.446-.395.959-.04.333-.052.666-.051.999v.994c0 .123.024.581.137.822.04.084.079.159.138.212.279.252.925.285 1.046.282a1.78 1.78 0 00.361-.049c.132-.028.593-.261.669-.36.081-.119.144-.253.188-.402.045-.148.116-.653.116-.653.027-.219.064-1.075.086-1.299.009-.105.011-.21.016-.313zm-.843 1.111l-.008.108c-.005.063-.025.524-.082.673-.086.225-.234.238-.329.266-.094.028-.459-.013-.537-.063a.463.463 0 01-.176-.205 2.426 2.426 0 01-.058-.444c-.008-.134.003-.81.014-.988.044-.672.259-.854.408-.967.149-.114.385-.069.468-.031.095.05.169.125.222.225.054.1.074.209.085.328.032.316-.007 1.098-.007 1.098zm4.934-2.49a1.008 1.008 0 00-.289-.048c-.082-.003-.594.082-.649.09.02.497.197 2.528.146 3.111a.415.415 0 01-.126.24c-.173.172-.398.093-.483.058-.408-.168-.422-2.324-.443-3.362l-.001-.007a2.489 2.489 0 00-.452-.015c-.081.003-.391.038-.455.042l-.006.001.006.006c.046.564.162 2.852.199 3.417.021.196.089.36.203.493.114.132.252.235.413.308.162.073.34.119.535.139.195.019.381.015.56-.014.306-.051.543-.18.71-.389.166-.208.258-.455.273-.74.024-.556.022-1.113-.006-1.672a26.403 26.403 0 00-.135-1.658zm4.366.766a1.212 1.212 0 00-.268-.776 1.413 1.413 0 00-.434-.376 1.677 1.677 0 00-.559-.187 3.072 3.072 0 00-.622-.03 3.786 3.786 0 00-1.185.271c.061.354.589 4.112.644 4.423a9.1 9.1 0 00.559-.052 4.641 4.641 0 00.52-.123c.002-.003.005-.004.01-.005l-.001-.006c-.051-.312-.232-1.551-.244-1.61.21.007.41-.03.6-.111a1.631 1.631 0 00.854-.825c.086-.186.131-.384.126-.593zm-1.573-.406c.349.009.484.168.531.207.123.101.151.415.065.527-.044.059-.219.161-.38.215-.148.05-.375.073-.443.086l-.019.003c-.03-.061-.174-.88-.188-.956.003-.005.289-.086.434-.082z" fill-rule="nonzero"/><path d="M52.479 8.164s-8.223 4.019-25.368 3.994C10.089 12.134 1.549 8.091 1.549 8.091l.033.571s7.478 4.2 25.528 4.3c17.703.098 25.39-4.123 25.39-4.123l-.021-.675z" fill="';
    // BADGE COLOR
    string private constant _CAN_6 =
        '"/><path d="M52.373 76.919s-5.772 7.502-25.188 7.586C7.487 84.589 1.55 76.919 1.55 76.919l.032.624s5.308 7.686 25.603 7.765c19.976.078 25.209-7.765 25.209-7.765l-.021-.624z" fill="';
    // TOP COLOR
    string private constant _CAN_7 =
        '"/><use xlink:href="#tt" x=".6" y=".6"/><use xlink:href="#tt" fill="';
    // BOTTOM COLOR
    string private constant _CAN_8 =
        '"/><defs><path id="tt" d="M39.393 26.115c-.632 1.234-1.48 2.348-2.094 2.383-.26.015-.414-.237-.438-.656-.042-.739.562-2.095 1.143-3.15.575-1.155.898-1.814.873-2.254-.043-.758-.622-1.426-1.201-1.393-.719.04-1.64.754-2.453 1.602a2.57 2.57 0 00-.003-.401 1.807 1.807 0 00-.313-.924c-.22-.348-.521-.351-.759.044-1.132 1.927-2.51 4.81-2.826 5.95a5.24 5.24 0 00-.093.485c-.588.691-1.209 1.182-1.631 1.176-.26-.004-.377-.206-.372-.566.005-.34.132-.758.338-1.175.497-1.153 1.476-2.458 1.868-3.273.248-.476.334-.895.339-1.275.007-.44-.128-.802-.324-1.045-.256-.303-.577-.248-.822.108-.755 1.049-1.193 2.243-2.441 4.144-1.045 1.645-2.084 2.89-2.643 2.882-.18-.003-.237-.204-.233-.484.004-.3.089-.659.235-1.036.414-.934.866-1.728 1.562-2.818.431-.733.68-1.33.687-1.81.004-.28-.11-.681-.346-.965-.275-.324-.535-.308-.781.049l-.756 1.068c-.633.891-1.566 1.757-2.468 1.904.098-1.219-.214-1.743-.608-2.169-.099-.102-.197-.183-.296-.305-.431-.586-.828-.792-1.508-.762-1.242.082-2.579 1.262-3.338 2.531-.534.892-.849 1.927-.861 2.767-.01.64.141 1.263.513 1.768.549.768 1.305 1.04 1.965 1.049 1.68.025 3.373-2.17 3.941-4.082.42.007.821-.068 1.223-.202-.247.457-.454.954-.6 1.352a4.446 4.446 0 00-.26 1.376c-.013.86.356 1.625 1.396 1.641.999.015 1.929-.632 2.6-1.342.107.842.678 1.47 1.818 1.487.66.01 1.376-.263 1.99-.694.078.125.174.236.287.338.338.301.591.166.712-.161.717-1.844 1.504-3.852 2.536-5.072 1.028-1.301 1.974-1.916 2.154-1.926.14-.008-.15.529-.532 1.212-.708 1.282-1.522 3.172-1.461 4.25.059 1.038.677 1.684 2.015 1.608.995-.057 2.127-.853 2.767-1.769l.042.056c.849 1.154 2.081 1.304 3.264 1.098 1.477-.267 2.759-1.214 3.317-2.706.271-.664.134-1.21.007-1.394-.183-.298-.5-.395-.614.086-.221 1.02-.684 1.752-1.418 2.42.157-.466.178-1.035.128-1.533-.11-1.075-.547-2.326-.744-3.733a11.033 11.033 0 01-.077-.837c.472-1.096.293-1.515-.242-1.44-.297.041-.634.23-.913.551-.402.441-.576.929-.556 1.654-.395.923-.945 2.05-1.468 3.073-.126-.467-.437-.525-.786-.133-.327.374-.46.867-.441 1.373zm-27.083.823c-.015 1.023.255 1.571.88 1.971.322.211.552.112.694-.116 1.466-2.574 4.354-7.025 5.64-8.752.711-.938.896-1.624.94-2.102a1.72 1.72 0 00-.106-.793c-.184-.399-.413-.521-.751-.131-1.507 1.928-3.764 5.232-5.385 7.953.354-2.277.727-4.331 1.157-5.918.093-.353.163-.668.189-.946.067-.717-.173-1.162-.729-1.656-.277-.266-.516-.289-.815.125-1.749 2.367-4.721 6.87-6.007 9.441-.198.404-.342.872-.37 1.171a1.87 1.87 0 00.274 1.15c.251.325.551.333.728-.052 1.105-2.367 2.776-4.983 4.418-7.28a45.5 45.5 0 00-.681 4.476c-.044.478-.062.878-.076 1.459zm6.066.732c.011-.74.327-1.835.861-2.767.39-.634.757-1.129 1.183-1.523.172.563.681 1.27 1.196 1.618a8.296 8.296 0 01-.682 1.47c-.78 1.349-1.65 2.056-2.15 2.049-.32-.005-.416-.287-.408-.847zm24.021.228c-.436.061-.949-.574-1.317-1.472.475-.935.91-1.864 1.28-2.683.115.529.223 1.16.312 1.794.18 1.287.14 2.302-.275 2.361zm-20.451-3.575c-.216-.263-.308-.785-.303-1.145.005-.32.187-.477.307-.475.14.002.298.124.294.424-.004.26-.091.739-.298 1.196zm20.031-7.195c.192-.425.316-.922.089-1.319-.2-.339-.536-.462-.859.059-.566.85-1.478 3.069-1.716 4.144-.05.267.05.437.313.447.223.014.497-.058.698-.403.441-.715 1.313-2.406 1.475-2.928z" fill-rule="nonzero"/></defs><g fill="';
    // BADGE COLOR
    string private constant _CAN_9 =
        '"><path d="M52.477 33.76s-4.122 4.812-25.762 4.801c-19.466-.01-25.084-4.979-25.084-4.979v.723s5.952 4.898 25.068 4.967c21.02.077 25.778-4.789 25.778-4.789v-.723z"  fill-rule="nonzero"/><circle cx="27.107" cy="38.532" r="5.924"/><path fill="';
    string private constant _CAN_10 =
        '" d="M26.939 40.666h-2.043v2.031h.931v-1.051h1.112v-.98zm2.098 2.022v-2.022h-1.045v1.012h-1.057v1.01h2.102zm-3.129-5.164h-2.099v2.027h2.099v-2.027zm2.087 1.036v-1.036h-.983v2.027h3.106v-2.027H29.1v1.036h-1.105zm-3.064-4.104h-.003v1.984h.931v-1.046h1.112v-.983h-2.04v.045zm4.151 1.984l-.004-2.062-1.054-.007v1.054h-1.057v1.015h2.115z"/></g><g><path d="M26.738 0c12.284 0 23.419.435 26.426 2.515.745.516.432 1.658.432 2.072 0 2.547-12.19 4.645-26.858 4.645-14.668 0-25.477-2.26-26.577-4.616-.419-.897.052-1.737.588-1.942C3.688 1.548 14.17 0 26.738 0z"/><path d="M26.788.237c12.103 0 23.084.48 26.047 2.404.733.477.47 1.389.47 1.772 0 2.357-12.01 4.297-26.462 4.297S1.742 6.619.658 4.44c-.412-.83.08-1.406.608-1.596C4.161 1.802 14.406.237 26.788.237z" fill="#7f7f7f"/><path d="M.954 2.866c.156-.23.472-.309.472-.309l-.472.309c-.124.184-.147.463.171.875.39.506 1.851 1.25 7.059 2.36 4.159.886 9.685 1.111 18.564 1.366 8.841.254 21.29-1.254 25.452-2.952 1.492-.608 1.053-1.574 1.053-1.574s.25.277.247.623c-.004.427-.096.846-1.089 1.22-1.304.492-4.092 1.247-5.174 1.445-4.426.811-14.366 1.834-21.169 1.742C11.648 7.776 2.472 5.831.414 3.8c-.402-.396-.145-.314-.062-.525.005-.013.316-.22.602-.409zm50.867.538c.017-.092-.053-.177-.261-.236-3.227-.921-12.657-2.079-16.36-2.11-10.303-.086-20.127.807-21.732.917-.336.024-.68-.137-.66-.347.011-.114 1.175-.211 1.797-.359.473-.113.446-.297.446-.297s-1.998.136-3.515.32c-1.908.231-3.679.439-4.997.641a35.89 35.89 0 00-2.915.572c-.718.176-1.847.458-2.119.66-.197.148.255.478.49.555 1.209.392 4.45 1.509 6.766 1.802 4.16.527 12.119 1.37 18.197 1.361 6.077-.01 13.934-.756 18.268-1.418 2.685-.41 6.594-1.188 7.737-2.553.375-.449-1.993-1.129-1.993-1.129s2.34.675 1.305 1.354c-.14.092-.292.181-.454.267zM40.73 5.705c-1.315-.393-6.393-1.725-14.091-1.484-3.417.108-7.92.541-10.254 1.099-.347.083-.9.349-1.191.495 3.712.355 7.981.668 11.501.683 4.417.018 9.793-.366 14.035-.793zm5.252-.636a8.749 8.749 0 00-2.973-1.159c-3.978-.736-12.123-1.258-15.984-1.159-11.95.306-13.675 1.403-16.744 1.816-.429.057-1.11.376-1.457.55 1.042.129 2.367.285 3.86.444.707-.182 2.142-.539 2.986-.66 6.725-.964 8.875-1.068 12.743-1.087 5.808-.028 13.676 1.264 15.367 1.555.388-.047.757-.094 1.102-.139.355-.047.724-.101 1.1-.161zm3.139-.665a17.767 17.767 0 001.573-.501C48.71 2.798 38.937 1.362 34.803 1.41c-13.246.152-26.114 1.247-26.51 1.317-.764.135-4.623.478-4.584.87.026.26 1.398.733 2.807 1.084.164-.13.45-.335.654-.36 3.386-.409 7.082-1.515 19.533-1.989 6.207-.236 15.516.896 19.259 1.251 1.021.097 2.88.547 3.159.821z"/></g></svg></defs></svg>';
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

// SPDX-License-Identifier: GPL-3.0

/// @title Interfaces for NounsDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

interface INounSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 tokenId, INounDescriptor descriptor) external view returns (Seed memory);
}

interface INounDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounSeeder.Seed memory seed) external view returns (string memory);
}

interface INounDecorator {
    function backgroundMapping(uint256) external view returns (string memory);
    function bodyMapping(uint256) external view returns (string memory);
    function accessoryMapping(uint256) external view returns (string memory);
    function headMapping(uint256) external view returns (string memory);
    function glassesMapping(uint256) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface INounSoupRenderer {
    function generateData(uint256 tokenId_)
        external
        view
        returns (string memory svg, string memory attributes);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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