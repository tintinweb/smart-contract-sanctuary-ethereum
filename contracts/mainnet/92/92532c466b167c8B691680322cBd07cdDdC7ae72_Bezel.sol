//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Renders the Bezel, which includes the address and progress bar.
library Bezel {
    function render(
        address _address,
        string memory _ensName,
        uint256 _holdingProgress
    ) public pure returns (string memory) {
        uint256 circumference = 1118; /* 2 * Pi * BezelRadius - 12 (??? idk what the -12 is, but it makes it look right.) */

        // if progress is > 1000, you have reached the minimum.
        bool isComplete = _holdingProgress >= 1000;

        // Need to convert progress into an offset value around the circle so
        // the ring can render correctly
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
                                utils.uint2str(WatchData.OUTER_BEZEL_RADIUS)
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
                                    (WatchData.OUTER_BEZEL_RADIUS * 98) / 100
                                )
                            ),
                            svg.prop("fill", utils.getCssVar("black")),
                            svg.prop("fill-opacity", isComplete ? "0.3" : "0"),
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
                        utils.uint2str(
                            (WatchData.OUTER_BEZEL_RADIUS * 99) / 100
                        )
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
        uint256 spaceLeft = 1016 - /* circumference = Math.ceil(2*Pi*r(161)) + 4 */
            7 * /* ~approximate char width in pixels across browsers. */
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
                            svg.prop("stroke-width", "1"),
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
                                    "M19,180a161,161 0 1,1 323,0a161,161 0 1,1 -323,0"
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

// Core SVG utilitiy library which helps us construct
// onchain SVG's with a simple, web-like API.
library svg {
    /* MAIN ELEMENTS */
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

    /* GRADIENTS */
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

    /* COMMON */
    // A generic element, can be used to construct any SVG (or HTML) element
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

    // an SVG attribute
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

// Primary library for storing all core constants and rendering data.
library WatchData {
    /* CONSTANTS */
    uint256 public constant WATCH_SIZE = 360;
    uint256 public constant CENTER = 180;
    uint256 public constant OUTER_BEZEL_RADIUS = 180;
    uint256 public constant INNER_BEZEL_RADIUS = 152;
    uint256 public constant FACE_RADIUS = 144; // OUTER_BEZEL_RADIUS * 0.8
    uint8 public constant GLOW_IN_THE_DARK_ID = 99;

    /* IDs */
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

    /* TRAIT STRUCTS */
    struct Material {
        MaterialId id;
        string name;
        string[2] vals;
    }

    struct Glasses {
        GlassesId id;
        string name;
    }

    struct Mood {
        MoodId id;
        string name;
    }

    struct GlowInTheDarkData {
        // contains the light mode colors
        string[2] light;
        // contains the dark mode colors
        string[2] dark;
        string name;
    }

    /* DATA RETRIEVAL */
    function getGlowInTheDarkData()
        public
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

    function getDiamondOverlayGradient()
        public
        pure
        returns (string[7] memory)
    {
        return [
            "#fffd92",
            "#ffcca7",
            "#f893ff",
            "#b393ff",
            "#99a7ff",
            "#76d4ff",
            "#7cffda"
        ];
    }

    function getMaterial(uint256 _materialId)
        public
        pure
        returns (Material memory)
    {
        Material[12] memory materials = [
            Material(MaterialId.Pearl, "Ocean Pearl", ["#ffffff", "#f6e6ff"]),
            Material(
                MaterialId.Copper,
                "Resistor Copper",
                ["#f7d1bf", "#5a2c1d"]
            ),
            Material(MaterialId.Onyx, "Void Onyx", ["#615c5c", "#0f0f0f"]),
            Material(MaterialId.Quartz, "Block Quartz", ["#ffb4be", "#81004e"]),
            Material(
                MaterialId.Emerald,
                "Matrix Emerald",
                ["#97ff47", "#011601"]
            ),
            Material(MaterialId.Ruby, "404 Ruby", ["#fe3d4a", "#460008"]),
            Material(
                MaterialId.Sapphire,
                "Hyperlink Sapphire",
                ["#4668ff", "#000281"]
            ),
            Material(MaterialId.Amber, "Sunset Amber", ["#ffa641", "#30031f"]),
            Material(
                MaterialId.Amethyst,
                "Candy Amethyst",
                ["#f7dfff", "#3671ca"]
            ),
            Material(
                MaterialId.Obsidian,
                "Nether Obsidian",
                ["#6f00ff", "#2b003b"]
            ),
            Material(MaterialId.Gold, "Electric Gold", ["#fcba7d", "#864800"]),
            Material(
                MaterialId.Diamond,
                "Ethereal Diamond",
                ["#b5f9ff", "#30c2c2"]
            )
        ];

        return materials[_materialId];
    }

    function getMood(uint256 _moodId) public pure returns (Mood memory) {
        Mood[13] memory moods = [
            Mood(MoodId.Surprised, "Surprised"),
            Mood(MoodId.Happy, "Happy"),
            Mood(MoodId.Relaxed, "Relaxed"),
            Mood(MoodId.Excited, "Excited"),
            Mood(MoodId.Speechless, "Speechless"),
            Mood(MoodId.Chilling, "Chilling"),
            Mood(MoodId.Annoyed, "Annoyed"),
            Mood(MoodId.Sleepy, "Sleepy"),
            Mood(MoodId.Unimpressed, "Unimpressed"),
            Mood(MoodId.Meditating, "Meditating"),
            Mood(MoodId.Relieved, "Relieved"),
            Mood(MoodId.Cheeky, "Cheeky"),
            Mood(MoodId.Sus, "Sus")
        ];

        return moods[_moodId];
    }

    function getGlasses(uint256 _glassesId)
        public
        pure
        returns (Glasses memory)
    {
        Glasses[9] memory glasses = [
            Glasses(GlassesId.None, "None"),
            Glasses(GlassesId.LeftMonocle, "Left Monocle"),
            Glasses(GlassesId.RightMonocle, "Right Monocle"),
            Glasses(GlassesId.Flip, "Flip"),
            Glasses(GlassesId.Valentine, "Valentine"),
            Glasses(GlassesId.Shutters, "Shutters"),
            Glasses(GlassesId.ThreeD, "3D"),
            Glasses(GlassesId.Ski, "Ski"),
            Glasses(GlassesId.Monolens, "Monolens")
        ];

        return glasses[_glassesId];
    }

    /* UTILS */
    // used to determine proper accent colors.
    function isLightMaterial(MaterialId _id) public pure returns (bool) {
        return _id == MaterialId.Pearl || _id == MaterialId.Diamond;
    }

    function getMaterialAccentColor(MaterialId _id)
        public
        pure
        returns (string memory)
    {
        if (isLightMaterial(_id)) {
            return utils.getCssVar("black");
        }

        return utils.getCssVar("white");
    }

    function getMaterialShadow(MaterialId _id)
        public
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

// Core utils used extensively to format CSS and numbers.
library utils {
    // used to simulate empty strings
    string internal constant NULL = "";

    // formats a CSS variable line. includes a semicolon for formatting.
    function setCssVar(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat("--", _key, ":", _val, ";");
    }

    // formats getting a css variable
    function getCssVar(string memory _key)
        internal
        pure
        returns (string memory)
    {
        return string.concat("var(--", _key, ")");
    }

    // formats getting a def URL
    function getDefURL(string memory _id)
        internal
        pure
        returns (string memory)
    {
        return string.concat("url(#", _id, ")");
    }

    // formats rgba white with a specified opacity / alpha
    function white_a(uint256 _a) internal pure returns (string memory) {
        return rgba(255, 255, 255, _a);
    }

    // formats rgba black with a specified opacity / alpha
    function black_a(uint256 _a) internal pure returns (string memory) {
        return rgba(0, 0, 0, _a);
    }

    // formats generic rgba color in css
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

    // checks if two strings are equal
    function stringsEqual(string memory _a, string memory _b)
        internal
        pure
        returns (bool)
    {
        return
            keccak256(abi.encodePacked(_a)) == keccak256(abi.encodePacked(_b));
    }

    // returns the length of a string in characters
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

    // converts an unsigned integer to a string
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