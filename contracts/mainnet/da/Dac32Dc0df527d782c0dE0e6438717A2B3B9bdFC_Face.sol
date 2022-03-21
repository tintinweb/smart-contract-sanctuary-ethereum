//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";

// Renders the Face, which includes the date and engraving.
library Face {
    function render(
        uint256 _day,
        uint256 _month,
        uint256 _year,
        string memory _engraving,
        bool _isLight
    ) public pure returns (string memory) {
        return
            svg.g(
                utils.NULL,
                string.concat(
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                            svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                            svg.prop(
                                "r",
                                utils.uint2str(WatchData.FACE_RADIUS)
                            ),
                            svg.prop("fill", utils.getDefURL("fg")),
                            svg.prop("filter", utils.getDefURL("insetShadow"))
                        ),
                        utils.NULL
                    ),
                    // inner tick lines
                    svg.path(
                        string.concat(
                            svg.prop(
                                "d",
                                "M316.8 180H180m136.6 7.2-136.61252-7.15956M316.1 194.3l-136.0506-14.2995M315.1 201.4l-135.11576-21.40023M313.8 208.4l-133.8106-28.44232M312.1 215.4l-132.13865-35.40645M310.1 222.3l-130.10453-42.27352M307.7 229l-127.7138-49.02474M305 235.6l-124.97302-55.64157M301.9 242.1l-121.8897-62.1059M298.5 248.4 180.02772 180M294.7 254.5l-114.73013-74.50662M290.7 260.4l-110.67352-80.40902M286.3 266.1l-106.31357-86.09103M281.7 271.5l-101.66221-91.53707M276.7 276.7l-96.7322-96.7322M271.5 281.7l-91.53707-101.66221M266.1 286.3l-86.09103-106.31357M260.4 290.7l-80.40902-110.67352M254.5 294.7l-74.50662-114.73013M248.4 298.5 180 180.02772M242.1 301.9l-62.1059-121.8897M235.6 305l-55.64157-124.97302M229 307.7l-49.02474-127.7138M222.3 310.1l-42.27352-130.10453M215.4 312.1l-35.40645-132.13865M208.4 313.8l-28.44232-133.8106M201.4 315.1l-21.40023-135.11576M194.3 316.1l-14.2995-136.0506M187.2 316.6l-7.15956-136.61252M180 316.8V180m-7.2 136.6 7.15956-136.61252M165.7 316.1l14.2995-136.0506M158.6 315.1l21.40023-135.11576M151.6 313.8l28.44232-133.8106M144.6 312.1l35.40645-132.13865M137.7 310.1l42.27352-130.10453M131 307.7l49.02474-127.7138M124.4 305l55.64157-124.97302M117.9 301.9l62.1059-121.8897M111.6 298.5 180 180.02772M105.5 294.7l74.50662-114.73013M99.6 290.7l80.40902-110.67352M93.9 286.3l86.09103-106.31357M88.5 281.7l91.53707-101.66221M83.3 276.7l96.7322-96.7322M78.3 271.5l101.66221-91.53707M73.7 266.1l106.31357-86.09103M69.3 260.4l110.67352-80.40902M65.3 254.5l114.73013-74.50662M61.5 248.4 179.97228 180M58.1 242.1l121.8897-62.1059M55 235.6l124.97302-55.64157M52.3 229l127.7138-49.02474M49.9 222.3l130.10453-42.27352M47.9 215.4l132.13865-35.40645M46.2 208.4l133.8106-28.44232M44.9 201.4l135.11576-21.40023M43.9 194.3l136.0506-14.2995M43.4 187.2l136.61252-7.15956M43.2 180H180m-136.6-7.2 136.61252 7.15956M43.9 165.7l136.0506 14.2995M44.9 158.6l135.11576 21.40023M46.2 151.6l133.8106 28.44232M47.9 144.6l132.13865 35.40645M49.9 137.7l130.10453 42.27352M52.3 131l127.7138 49.02474M55 124.4l124.97302 55.64157M58.1 117.9l121.8897 62.1059M61.5 111.6 179.97228 180M65.3 105.5l114.73013 74.50662M69.3 99.6l110.67352 80.40902M73.7 93.9l106.31357 86.09103M78.3 88.5l101.66221 91.53707M83.3 83.3l96.7322 96.7322M88.5 78.3l91.53707 101.66221M93.9 73.7l86.09103 106.31357M99.6 69.3l80.40902 110.67352M105.5 65.3l74.50662 114.73013M111.6 61.5 180 179.97228M117.9 58.1l62.1059 121.8897M124.4 55l55.64157 124.97302M131 52.3l49.02474 127.7138M137.7 49.9l42.27352 130.10453M144.6 47.9l35.40645 132.13865M151.6 46.2l28.44232 133.8106M158.6 44.9l21.40023 135.11576M165.7 43.9l14.2995 136.0506M172.8 43.4l7.15956 136.61252M180 43.2V180m7.2-136.6-7.15956 136.61252M194.3 43.9l-14.2995 136.0506M201.4 44.9l-21.40023 135.11576M208.4 46.2l-28.44232 133.8106M215.4 47.9l-35.40645 132.13865M222.3 49.9l-42.27352 130.10453M229 52.3l-49.02474 127.7138M235.6 55l-55.64157 124.97302M242.1 58.1l-62.1059 121.8897M248.4 61.5 180 179.97228M254.5 65.3l-74.50662 114.73013M260.4 69.3l-80.40902 110.67352M266.1 73.7l-86.09103 106.31357M271.5 78.3l-91.53707 101.66221M276.7 83.3l-96.7322 96.7322M281.7 88.5l-101.66221 91.53707M286.3 93.9l-106.31357 86.09103M290.7 99.6l-110.67352 80.40902M294.7 105.5l-114.73013 74.50662M298.5 111.6 180.02772 180M301.9 117.9l-121.8897 62.1059M305 124.4l-124.97302 55.64157M307.7 131l-127.7138 49.02474M310.1 137.7l-130.10453 42.27352M312.1 144.6l-132.13865 35.40645M313.8 151.6l-133.8106 28.44232M315.1 158.6l-135.11576 21.40023M316.1 165.7l-136.0506 14.2995M316.6 172.8l-136.61252 7.15956"
                            ),
                            svg.prop("stroke", utils.getCssVar("fa")),
                            svg.prop("opacity", _isLight ? "0.1" : "0.35"),
                            svg.prop(
                                "style",
                                string.concat(
                                    "mix-blend-mode:",
                                    _isLight ? "normal" : "overlay"
                                )
                            )
                        ),
                        utils.NULL
                    ),
                    // outer tick lines
                    svg.path(
                        string.concat(
                            svg.prop(
                                "d",
                                "M316.8 180h-12m11.3 14.3-5.96713-.62717M313.8 208.4l-5.86889-1.24747M310.1 222.3l-5.70634-1.8541M305 235.6l-5.48127-2.44042M298.5 248.4l-10.3923-6m2.5923 18-4.8541-3.52671M281.7 271.5l-4.45887-4.01478M271.5 281.7l-4.01478-4.45887M260.4 290.7l-3.52671-4.8541M248.4 298.5l-6-10.3923M235.6 305l-2.44042-5.48127M222.3 310.1l-1.8541-5.70634M208.4 313.8l-1.24747-5.86889M194.3 316.1l-.62717-5.96713M180 316.8v-12m-14.3 11.3.62717-5.96713M151.6 313.8l1.24747-5.86889M137.7 310.1l1.8541-5.70634M124.4 305l2.44042-5.48127M111.6 298.5l6-10.3923m-18 2.5923 3.52671-4.8541M88.5 281.7l4.01478-4.45887M78.3 271.5l4.45887-4.01478M69.3 260.4l4.8541-3.52671M61.5 248.4l10.3923-6M55 235.6l5.48127-2.44042M49.9 222.3l5.70634-1.8541M46.2 208.4l5.86889-1.24747M43.9 194.3l5.96713-.62717M43.2 180h12m-11.3-14.3 5.96713.62717M46.2 151.6l5.86889 1.24747M49.9 137.7l5.70634 1.8541M55 124.4l5.48127 2.44042M61.5 111.6l10.3923 6M69.3 99.6l4.8541 3.52671M78.3 88.5l4.45887 4.01478M88.5 78.3l4.01478 4.45887M99.6 69.3l3.52671 4.8541M111.6 61.5l6 10.3923M124.4 55l2.44042 5.48127M137.7 49.9l1.8541 5.70634M151.6 46.2l1.24747 5.86889M165.7 43.9l.62717 5.96713M180 43.2v12m14.3-11.3-.62717 5.96713M208.4 46.2l-1.24747 5.86889M222.3 49.9l-1.8541 5.70634M235.6 55l-2.44042 5.48127M248.4 61.5l-6 10.3923m18-2.5923-3.52671 4.8541M271.5 78.3l-4.01478 4.45887M281.7 88.5l-4.45887 4.01478M290.7 99.6l-4.8541 3.52671M298.5 111.6l-10.3923 6M305 124.4l-5.48127 2.44042M310.1 137.7l-5.70634 1.8541M313.8 151.6l-5.86889 1.24747M316.1 165.7l-5.96713.62717"
                            ),
                            svg.prop("stroke", utils.getCssVar("fa")),
                            svg.prop("stroke-width", "2"),
                            svg.prop("opacity", "0.35")
                        ),
                        utils.NULL
                    ),
                    renderDate(_day, _month, _year),
                    renderEngraving(_engraving)
                )
            );
    }

    function renderEngraving(string memory _engraving)
        private
        pure
        returns (string memory)
    {
        uint256 engravingLength = utils.utfStringLength(_engraving);

        if (engravingLength == 0 || engravingLength > 20) {
            return utils.NULL;
        }

        uint256 charWidth = 7;
        uint256 padding = 14;
        uint256 fullWidth = charWidth *
            engravingLength +
            padding *
            2 +
            padding /
            4;

        return
            svg.g(
                string.concat(
                    svg.prop(
                        "transform",
                        string.concat(
                            "translate(",
                            utils.uint2str(180 - fullWidth / 2),
                            " ",
                            utils.uint2str(268),
                            ")"
                        )
                    )
                ),
                string.concat(
                    svg.rect(
                        string.concat(
                            svg.prop("fill", utils.getCssVar("fs")),
                            svg.prop("filter", utils.getDefURL("insetShadow")),
                            svg.prop("x", "0"),
                            svg.prop("y", "-13"),
                            svg.prop("width", utils.uint2str(fullWidth)),
                            svg.prop(
                                "height",
                                utils.uint2str(charWidth + padding)
                            ),
                            svg.prop("rx", utils.uint2str(10)),
                            svg.prop("stroke", utils.getCssVar("fa")),
                            svg.prop("stroke-opacity", "0.2")
                        ),
                        utils.NULL
                    ),
                    svg.text(
                        string.concat(
                            svg.prop("text-anchor", "middle"),
                            svg.prop("x", utils.uint2str(fullWidth / 2)),
                            svg.prop("y", "1"),
                            svg.prop("font-size", utils.getCssVar("fts")),
                            svg.prop("fill", utils.getCssVar("fa")),
                            svg.prop("fill-opacity", "0.5")
                        ),
                        // _engraving
                        string.concat("<![CDATA[", _engraving, "]]>")
                    )
                )
            );
    }

    function renderDate(
        uint256 _day,
        uint256 _month,
        uint256 _year
    ) private pure returns (string memory) {
        // All x positions and transforms are calculated in js and just used as constants here.
        return
            svg.g(
                string.concat(svg.prop("transform", "translate(136, 88)")),
                string.concat(
                    // BACKGROUND CONTAINER
                    svg.g(
                        string.concat(
                            svg.prop("fill", utils.getCssVar("fs")),
                            svg.prop("filter", utils.getDefURL("insetShadow")),
                            svg.prop("stroke", utils.getCssVar("fa")),
                            svg.prop("stroke-opacity", "0.2")
                        ),
                        string.concat(
                            svg.rect(
                                string.concat(
                                    svg.prop("x", "0"),
                                    svg.prop("y", "-14"),
                                    svg.prop("width", "22"),
                                    svg.prop("height", "20"),
                                    svg.prop("rx", "4")
                                ),
                                utils.NULL
                            ),
                            svg.rect(
                                string.concat(
                                    svg.prop("x", "26"),
                                    svg.prop("y", "-14"),
                                    svg.prop("width", "22"),
                                    svg.prop("height", "20"),
                                    svg.prop("rx", "4")
                                ),
                                utils.NULL
                            ),
                            svg.rect(
                                string.concat(
                                    svg.prop("x", "52"),
                                    svg.prop("y", "-14"),
                                    svg.prop("width", "36"),
                                    svg.prop("height", "20"),
                                    svg.prop("rx", "4")
                                ),
                                utils.NULL
                            )
                        )
                    ),
                    // TEXT CONTAINER
                    svg.g(
                        string.concat(
                            svg.prop("font-size", utils.getCssVar("fts")),
                            svg.prop("fill", utils.getCssVar("fa")),
                            svg.prop("opacity", "0.5")
                        ),
                        string.concat(
                            svg.text(
                                string.concat(
                                    svg.prop("text-anchor", "middle"),
                                    svg.prop("x", "11")
                                ),
                                utils.uint2str(_month)
                            ),
                            svg.text(
                                string.concat(
                                    svg.prop("text-anchor", "middle"),
                                    svg.prop("x", "37")
                                ),
                                utils.uint2str(_day)
                            ),
                            svg.text(
                                string.concat(
                                    svg.prop("text-anchor", "middle"),
                                    svg.prop("x", "70")
                                ),
                                utils.uint2str(_year)
                            )
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
        uint256 supply;
    }

    struct Glasses {
        GlassesId id;
        string name;
        uint256 supply;
    }

    struct Mood {
        MoodId id;
        string name;
        uint256 supply;
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
                840
            ),
            Material(
                MaterialId.Copper,
                "Resistor Copper",
                ["#f7d1bf", "#5a2c1d"],
                840
            ),
            Material(
                MaterialId.Onyx,
                "Ocean Pearl",
                ["#615c5c", "#0f0f0f"],
                840
            ),
            Material(
                MaterialId.Quartz,
                "Block Quartz",
                ["#ffb4be", "#81004e"],
                840
            ),
            Material(
                MaterialId.Emerald,
                "Matrix Emerald",
                ["#97ff47", "#011601"],
                840
            ),
            Material(MaterialId.Ruby, "404 Ruby", ["#fe3d4a", "#460008"], 840),
            Material(
                MaterialId.Sapphire,
                "Hyperlink Sapphire",
                ["#4668ff", "#000281"],
                840
            ),
            Material(
                MaterialId.Amber,
                "Sunset Amber",
                ["#ffa641", "#30031f"],
                840
            ),
            Material(
                MaterialId.Amethyst,
                "Candy Amethyst",
                ["#f7dfff", "#3671ca"],
                840
            ),
            Material(
                MaterialId.Obsidian,
                "Nether Obsidian",
                ["#6f00ff", "#2b003b"],
                840
            ),
            Material(
                MaterialId.Gold,
                "Electric Gold",
                ["#fcba7d", "#864800"],
                840
            ),
            Material(
                MaterialId.Diamond,
                "Ethereal Diamond",
                ["#b5f9ff", "#30c2c2"],
                840
            )
        ];

        return materials[_materialId];
    }

    function getMood(uint256 _moodId) internal pure returns (Mood memory) {
        Mood[13] memory moods = [
            Mood(MoodId.Surprised, "Surprised", 840),
            Mood(MoodId.Happy, "Happy", 840),
            Mood(MoodId.Relaxed, "Relaxed", 840),
            Mood(MoodId.Excited, "Excited", 840),
            Mood(MoodId.Speechless, "Speechless", 25),
            Mood(MoodId.Chilling, "Chilling", 840),
            Mood(MoodId.Annoyed, "Annoyed", 840),
            Mood(MoodId.Sleepy, "Sleepy", 840),
            Mood(MoodId.Unimpressed, "Unimpressed", 840),
            Mood(MoodId.Meditating, "Meditating", 840),
            Mood(MoodId.Relieved, "Relieved", 840),
            Mood(MoodId.Cheeky, "Cheeky", 840),
            Mood(MoodId.Sus, "Sus", 840)
        ];

        return moods[_moodId];
    }

    function getGlasses(uint256 _glassesId)
        internal
        pure
        returns (Glasses memory)
    {
        Glasses[9] memory glasses = [
            Glasses(GlassesId.None, "None", 840),
            Glasses(GlassesId.LeftMonocle, "Left Monocle", 840),
            Glasses(GlassesId.RightMonocle, "Right Monocle", 840),
            Glasses(GlassesId.Flip, "Flip", 840),
            Glasses(GlassesId.Valentine, "Valentine", 840),
            Glasses(GlassesId.Shutters, "Shutters", 840),
            Glasses(GlassesId.ThreeD, "3D", 840),
            Glasses(GlassesId.Ski, "Ski", 840),
            Glasses(GlassesId.Monolens, "Monolens", 840)
        ];

        return glasses[_glassesId];
    }

    /* UTILS */
    // used to determine proper accent colors.
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