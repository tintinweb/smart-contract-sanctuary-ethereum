//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Bezel {
    function render(
        address _address,
        string memory _ensName,
        uint256 _holdingProgress,
        bool _isLight
    ) public pure returns (string memory) {
        // // if progress is > 1000, you have reached the minimum.
        uint256 circumference = 1118; /* 2 * Pi * BezelRadius - 12 (??? idk, it looks right tho) */
        bool isComplete = _holdingProgress >= 1000;
        uint256 holdingProgressOffset = isComplete
            ? circumference
            : ((circumference * _holdingProgress) / 1000);

        return
            svg.g(
                utils.NULL,
                string.concat(
                    // Outer bezel.
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                            svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                            svg.prop(
                                "r",
                                utils.uint2str(WatchData.BEZEL_RADIUS)
                            ),
                            svg.prop("fill", utils.getDefURL("obg"))
                        ),
                        utils.NULL
                    ),
                    // Dark bezel overlay
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                            svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                            svg.prop(
                                "r",
                                utils.uint2str(
                                    (WatchData.BEZEL_RADIUS * 98) / 100
                                )
                            ),
                            svg.prop("fill", utils.getCssVar("black")),
                            svg.prop(
                                "fill-opacity",
                                isComplete ? (_isLight ? "0.2" : "0.4") : "0"
                            ),
                            svg.prop(
                                "style",
                                string.concat(
                                    "mix-blend-mode:hard-light;",
                                    isComplete
                                        ? "animation: fadeOpacity 4s ease-in-out infinite;"
                                        : utils.NULL
                                )
                            )
                        ),
                        utils.NULL
                    ),
                    renderProgressBar(
                        circumference,
                        holdingProgressOffset,
                        isComplete
                    ),
                    // ADDRESS (includes inner bezel)
                    renderAddressAndInnerBezel(_address, _ensName)
                )
            );
    }

    function renderProgressBar(
        uint256 _circumference,
        uint256 _progressOffset,
        bool _isComplete
    ) internal pure returns (string memory) {
        string memory strokeProps = string.concat(
            svg.prop("stroke", utils.getCssVar("ba")),
            svg.prop("stroke-width", "2"),
            svg.prop("stroke-dasharray", utils.uint2str(_circumference)),
            svg.prop("stroke-linecap", "round"),
            svg.prop(
                "stroke-dashoffset",
                // need to offset by 12 for it to look right?
                utils.uint2str(_circumference - _progressOffset)
            )
        );

        return
            svg.circle(
                string.concat(
                    svg.prop("opacity", _isComplete ? "0.75" : "0.4"),
                    svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                    svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                    svg.prop(
                        "r",
                        utils.uint2str((WatchData.BEZEL_RADIUS * 99) / 100)
                    ),
                    svg.prop("fill", "transparent"),
                    svg.prop("transform", "rotate(270 180 180)"),
                    strokeProps
                ),
                utils.NULL
            );
    }

    function renderAddressAndInnerBezel(
        address _address,
        string memory _ensName
    ) internal pure returns (string memory) {
        string memory ownerAddress = Strings.toHexString(
            uint256(uint160(_address))
        );
        bool hasEns = !utils.stringsEqual(_ensName, "");
        string memory SEPARATOR = " ";
        string memory fullAddress = hasEns
            ? (string.concat(SEPARATOR, _ensName, SEPARATOR, ownerAddress))
            : (string.concat(SEPARATOR, ownerAddress));
        uint256 fullAddressLen = utils.utfStringLength(fullAddress);

        /* circumference - charWidth * address length.
        = how much space is left to distribute between the characters.*/
        uint256 spaceLeft = 1005 - /*circumference = Math.floor(2*Pi*r160)*/
            7 * /*char width*/
            fullAddressLen;

        // scale everything by 1000
        uint256 letterSpacingRaw = (spaceLeft * 1000) / fullAddressLen;
        uint256 letterSpacingDecimal = (letterSpacingRaw % 1000) / 100;
        uint256 letterSpacingWhole = (letterSpacingRaw - letterSpacingDecimal) /
            1000;

        return
            svg.g(
                string.concat(
                    svg.prop("fill", utils.getCssVar("ba")),
                    svg.prop("font-size", utils.getCssVar("bts"))
                ),
                string.concat(
                    svg.animateTransform(
                        string.concat(
                            svg.prop("attributeName", "transform"),
                            svg.prop("attributeType", "XML"),
                            svg.prop("type", "rotate"),
                            svg.prop("from", "0 180 180"),
                            svg.prop("to", "360 180 180"),
                            svg.prop("dur", "120s"),
                            svg.prop("repeatCount", "indefinite")
                        )
                    ),
                    // Inner bezel
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                            svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                            svg.prop(
                                "r",
                                utils.uint2str(WatchData.INNER_BEZEL_RADIUS)
                            ),
                            svg.prop("fill", utils.getDefURL("ibg")),
                            svg.prop("stroke-width", "1.5"),
                            svg.prop("stroke", utils.getDefURL("rg"))
                        ),
                        utils.NULL
                    ),
                    // Address text
                    svg.text(
                        string.concat(
                            svg.prop(
                                "letter-spacing",
                                string.concat(
                                    utils.uint2str(letterSpacingWhole),
                                    ".",
                                    utils.uint2str(letterSpacingDecimal)
                                )
                            ),
                            svg.prop("opacity", "0.5"),
                            svg.prop(
                                "style",
                                "text-transform:uppercase;text-shadow:var(--textShadow);"
                            )
                        ),
                        svg.el(
                            "textPath",
                            svg.prop("href", "#addressPath"),
                            // fullAddress
                            string.concat("<![CDATA[", fullAddress, "]]>")
                        )
                    ),
                    svg.el(
                        "defs",
                        utils.NULL,
                        svg.path(
                            string.concat(
                                svg.prop(
                                    "d",
                                    "M20,180a160,160 0 1,1 320,0a160,160 0 1,1 -320,0"
                                ),
                                svg.prop("id", "addressPath")
                            ),
                            utils.NULL
                        )
                    )
                )
            );
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./Utils.sol";

library svg {
    /** MAIN ELEMENTS */
    function g(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("g", _props, _children);
    }

    function path(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("path", _props, _children);
    }

    function text(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("text", _props, _children);
    }

    function line(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("line", _props, _children);
    }

    function circle(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("circle", _props, _children);
    }

    function rect(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("rect", _props, _children);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    /** GRADIENTS */
    function radialGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("radialGradient", _props, _children);
    }

    function linearGradient(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("linearGradient", _props, _children);
    }

    function gradientStop(
        uint256 offset,
        string memory stopColor,
        string memory _props
    ) internal pure returns (string memory) {
        return
            el(
                "stop",
                string.concat(
                    prop("stop-color", stopColor),
                    " ",
                    prop("offset", string.concat(utils.uint2str(offset), "%")),
                    " ",
                    _props
                ),
                utils.NULL
            );
    }

    function animateTransform(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("animateTransform", _props, utils.NULL);
    }

    /** COMMON */
    function el(
        string memory _tag,
        string memory _props,
        string memory _children
    ) internal pure returns (string memory) {
        return
            string.concat(
                "<",
                _tag,
                " ",
                _props,
                ">",
                _children,
                "</",
                _tag,
                ">"
            );
    }

    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;
import "./Utils.sol";

library WatchData {
    uint256 public constant WATCH_SIZE = 360;
    uint256 public constant CENTER = 180;
    // change to outer bezel radius
    uint256 public constant BEZEL_RADIUS = 180;
    uint256 public constant INNER_BEZEL_RADIUS = 152;
    uint256 public constant FACE_RADIUS = 144; // BEZEL_RADIUS * 0.8
    // used to detect
    uint8 public constant GLOW_IN_THE_DARK_ID = 99;

    enum MaterialId {
        Pearl,
        Copper,
        Onyx,
        Quartz,
        Emerald,
        Ruby,
        Sapphire,
        Amber,
        Amethyst,
        Obsidian,
        Gold,
        Diamond
    }

    enum MoodId {
        Surprised,
        Happy,
        Relaxed,
        Excited,
        Speechless,
        Chilling,
        Annoyed,
        Sleepy,
        Unimpressed,
        Meditating,
        Relieved,
        Cheeky,
        Sus
    }

    enum GlassesId {
        None,
        LeftMonocle,
        RightMonocle,
        Flip,
        Valentine,
        Shutters,
        ThreeD,
        Ski,
        Monolens
    }

    struct Material {
        MaterialId id;
        string name;
        string[2] vals;
        uint256 supply;
        // divide by 1000
        uint256 price;
    }

    struct Glasses {
        GlassesId id;
        string name;
        uint256 supply;
        // divide by 1000
        uint256 price;
    }

    struct Mood {
        MoodId id;
        string name;
        uint256 supply;
        // divide by 1000
        uint256 price;
    }

    struct GlowInTheDarkData {
        string[2] light;
        string[2] dark;
        string name;
    }

    function getGlowInTheDarkData()
        internal
        pure
        returns (GlowInTheDarkData memory)
    {
        return
            GlowInTheDarkData(
                ["#fbfffc", "#d7ffd7"],
                ["#052925", "#a4ffa1"],
                "Glow In The Dark"
            );
    }

    /* Primary data retrieval functions */
    function getMaterial(uint256 _materialId)
        internal
        pure
        returns (Material memory)
    {
        Material[12] memory materials = [
            Material(
                MaterialId.Pearl,
                "Ocean Pearl",
                ["#ffffff", "#f6e6ff"],
                840,
                25
            ),
            Material(
                MaterialId.Copper,
                "Resistor Copper",
                ["#f7d1bf", "#5a2c1d"],
                840,
                25
            ),
            Material(
                MaterialId.Onyx,
                "Ocean Pearl",
                ["#615c5c", "#0f0f0f"],
                840,
                25
            ),
            Material(
                MaterialId.Quartz,
                "Block Quartz",
                ["#ffb4be", "#81004e"],
                840,
                50
            ),
            Material(
                MaterialId.Emerald,
                "Matrix Emerald",
                ["#97ff47", "#011601"],
                840,
                50
            ),
            Material(
                MaterialId.Ruby,
                "404 Ruby",
                ["#d21925", "#3b0007"],
                840,
                50
            ),
            Material(
                MaterialId.Sapphire,
                "Hyperlink Sapphire",
                ["#4668ff", "#000281"],
                840,
                50
            ),
            Material(
                MaterialId.Amber,
                "Sunset Amber",
                ["#ffa641", "#30031f"],
                840,
                150
            ),
            Material(
                MaterialId.Amethyst,
                "Candy Amethyst",
                ["#f7dfff", "#3671ca"],
                840,
                150
            ),
            Material(
                MaterialId.Obsidian,
                "Nether Obsidian",
                ["#6f00ff", "#2b003b"],
                840,
                150
            ),
            Material(
                MaterialId.Gold,
                "Electric Gold",
                ["#fcba7d", "#864800"],
                840,
                150
            ),
            Material(
                MaterialId.Diamond,
                "Ethereal Diamond",
                ["#b5f9ff", "#30c2c2"],
                840,
                600
            )
        ];

        return materials[_materialId];
    }

    function getMood(uint256 _moodId) internal pure returns (Mood memory) {
        Mood[13] memory moods = [
            Mood(MoodId.Surprised, "Surprised", 840, 25),
            Mood(MoodId.Happy, "Happy", 840, 25),
            Mood(MoodId.Relaxed, "Relaxed", 840, 25),
            Mood(MoodId.Excited, "Excited", 840, 25),
            Mood(MoodId.Speechless, "Speechless", 840, 25),
            Mood(MoodId.Chilling, "Chilling", 840, 25),
            Mood(MoodId.Annoyed, "Annoyed", 840, 25),
            Mood(MoodId.Sleepy, "Sleepy", 840, 25),
            Mood(MoodId.Unimpressed, "Unimpressed", 840, 25),
            Mood(MoodId.Meditating, "Meditating", 840, 25),
            Mood(MoodId.Relieved, "Relieved", 840, 25),
            Mood(MoodId.Cheeky, "Cheeky", 840, 25),
            Mood(MoodId.Sus, "Sus", 840, 25)
        ];

        return moods[_moodId];
    }

    function getGlasses(uint256 _glassesId)
        internal
        pure
        returns (Glasses memory)
    {
        Glasses[9] memory glasses = [
            Glasses(GlassesId.None, "None", 840, 25),
            Glasses(GlassesId.LeftMonocle, "Left Monocle", 840, 25),
            Glasses(GlassesId.RightMonocle, "Right Monocle", 840, 25),
            Glasses(GlassesId.Flip, "Flip", 840, 25),
            Glasses(GlassesId.Valentine, "Valentine", 840, 25),
            Glasses(GlassesId.Shutters, "Shutters", 840, 25),
            Glasses(GlassesId.ThreeD, "3D", 840, 25),
            Glasses(GlassesId.Ski, "Ski", 840, 25),
            Glasses(GlassesId.Monolens, "Monolens", 840, 25)
        ];

        return glasses[_glassesId];
    }

    /* Other utils */

    function isLightMaterial(MaterialId _id) internal pure returns (bool) {
        return _id == MaterialId.Pearl || _id == MaterialId.Diamond;
    }

    function getMaterialAccentColor(MaterialId _id)
        internal
        pure
        returns (string memory)
    {
        if (isLightMaterial(_id)) {
            return utils.getCssVar("black");
        }

        return utils.getCssVar("white");
    }

    function getMaterialShadow(MaterialId _id)
        internal
        pure
        returns (string memory)
    {
        if (isLightMaterial(_id)) {
            return utils.black_a(85);
        }

        return utils.white_a(85);
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library utils {
    string internal constant NULL = "";

    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    function rgba(
        uint256 _r,
        uint256 _g,
        uint256 _b,
        uint256 _a
    ) internal pure returns (string memory) {
        string memory formattedA = _a < 100
            ? string.concat("0.", utils.uint2str(_a))
            : "1";
        return
            string.concat(
                "rgba(",
                utils.uint2str(_r),
                ",",
                utils.uint2str(_g),
                ",",
                utils.uint2str(_b),
                ",",
                formattedA,
                ")"
            );
    }

    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    function utfStringLength(string memory _str)
        internal
        pure
        returns (uint256 length)
    {
        uint256 i = 0;
        bytes memory string_rep = bytes(_str);

        while (i < string_rep.length) {
            if (string_rep[i] >> 7 == 0) i += 1;
            else if (string_rep[i] >> 5 == bytes1(uint8(0x6))) i += 2;
            else if (string_rep[i] >> 4 == bytes1(uint8(0xE))) i += 3;
            else if (string_rep[i] >> 3 == bytes1(uint8(0x1E)))
                i += 4;
                //For safety
            else i += 1;

            length++;
        }
    }

    function toString(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        return uint2str(uint256(_i));
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}