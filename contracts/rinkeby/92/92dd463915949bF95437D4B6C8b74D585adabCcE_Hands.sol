//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";

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