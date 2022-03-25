//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";

// Renders the hands, which are layered on top of every other core element
library Hands {
    function render(
        uint256 _second,
        uint256 _minute,
        uint256 _hour
    ) public pure returns (string memory) {
        return
            svg.g(
                string.concat(
                    svg.prop("stroke", utils.getCssVar("fa")),
                    svg.prop("stroke-opacity", "0.1"),
                    svg.prop("filter", utils.getDefURL("dropShadow"))
                ),
                string.concat(
                    // Seconds
                    renderHand(
                        3,
                        WatchData.FACE_RADIUS,
                        _second * 6,
                        utils.getCssVar("fp"),
                        utils.getDefURL("ibg")
                    ),
                    // Minutes
                    renderHand(
                        4,
                        // 0.75 length
                        110,
                        _minute * 6,
                        utils.getDefURL("ibg"),
                        utils.getCssVar("bs")
                    ),
                    // // Hours
                    renderHand(
                        4,
                        // 0.35 length,
                        50,
                        ((_hour % 12) * 30 + ((_minute / 60) * 30)),
                        utils.getDefURL("ibg"),
                        utils.getCssVar("bs")
                    ),
                    renderCenter()
                )
            );
    }

    function renderCenter() internal pure returns (string memory) {
        return
            svg.circle(
                string.concat(
                    svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                    svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                    svg.prop("r", "6"),
                    svg.prop("fill", utils.getCssVar("fp"))
                ),
                utils.NULL
            );
    }

    function renderHand(
        uint256 _width,
        uint256 _length,
        uint256 _degree,
        string memory _mainColor,
        string memory _secondaryColor
    ) internal pure returns (string memory) {
        return
            svg.g(
                svg.prop(
                    "transform",
                    string(
                        string.concat(
                            "rotate(",
                            utils.uint2str(_degree),
                            " 180 180)"
                        )
                    )
                ),
                string.concat(
                    renderMainHandPart(_width, _length, _mainColor),
                    renderInnerHandPart(_width, _length, _secondaryColor)
                )
            );
    }

    function renderMainHandPart(
        uint256 _width,
        uint256 _length,
        string memory _color
    ) internal pure returns (string memory) {
        return
            svg.rect(
                string.concat(
                    commonHandProps(
                        (WatchData.CENTER - _width / 2),
                        (WatchData.CENTER - _length + 16),
                        _width,
                        _length,
                        _color,
                        "2"
                    )
                ),
                utils.NULL
            );
    }

    function renderInnerHandPart(
        uint256 _width,
        uint256 _length,
        string memory _color
    ) internal pure returns (string memory) {
        return
            svg.rect(
                string.concat(
                    commonHandProps(
                        (WatchData.CENTER - _width / 4),
                        (WatchData.CENTER - _length + 17),
                        _width / 2,
                        _length / 4,
                        _color,
                        "1"
                    )
                ),
                utils.NULL
            );
    }

    function commonHandProps(
        uint256 _x,
        uint256 _y,
        uint256 _width,
        uint256 _height,
        string memory _fill,
        string memory _rx
    ) internal pure returns (string memory) {
        return
            string.concat(
                svg.prop("x", utils.uint2str(_x)),
                svg.prop("y", utils.uint2str(_y)),
                svg.prop("width", utils.uint2str(_width)),
                svg.prop("height", utils.uint2str(_height)),
                svg.prop("fill", _fill),
                svg.prop("rx", _rx)
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