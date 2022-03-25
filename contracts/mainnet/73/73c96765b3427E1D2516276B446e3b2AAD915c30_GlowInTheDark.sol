//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";
import "./Mood.sol";

// Includes all relevant special data and rendering for
// the 1/1 Glow in the Dark Watchface.
library GlowInTheDark {
    function generateMaterialTokens() public pure returns (string memory) {
        WatchData.GlowInTheDarkData memory _data = WatchData
            .getGlowInTheDarkData();

        return
            string.concat(
                generateDarkModeCss(_data),
                generateLightModeCss(_data)
            );
    }

    function generateDarkModeCss(WatchData.GlowInTheDarkData memory _data)
        internal
        pure
        returns (string memory)
    {
        // not in a query, so it's dark mode by default.
        return
            string.concat(
                "*{",
                // bezel colors
                // bezel primary
                utils.setCssVar("bp", _data.dark[0]),
                // // bezel secondary
                utils.setCssVar("bs", _data.dark[1]),
                // // bezel accent
                utils.setCssVar("ba", _data.dark[1]),
                // // face colors
                // // face primary
                utils.setCssVar("fp", _data.dark[0]),
                // // face secondary
                utils.setCssVar("fs", _data.dark[1]),
                // // face accent
                utils.setCssVar("fa", utils.getCssVar("black")),
                "}",
                ".mood-light{display:none;}",
                ".mood-dark{display:block;}",
                ".glasses-flip{",
                "transform:translateY(-56px);",
                "transition: transform 0.2s;",
                "}"
            );
    }

    function generateLightModeCss(WatchData.GlowInTheDarkData memory _data)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "@media(prefers-color-scheme:light){",
                "*{",
                // bezel colors
                // bezel primary
                utils.setCssVar("bp", _data.light[0]),
                // // bezel secondary
                utils.setCssVar("bs", _data.light[1]),
                // // bezel accent
                utils.setCssVar("ba", utils.getCssVar("black")),
                // // face colors
                // // face primary
                utils.setCssVar("fp", _data.light[0]),
                // // face secondary
                utils.setCssVar("fs", _data.light[1]),
                // // face accent
                utils.setCssVar("fa", utils.getCssVar("black")),
                "}",
                ".mood-dark{display:none;}",
                ".mood-light{display:block;}",
                ".glasses-flip{",
                "transform:translateY(0px);",
                "transition: transform 0.2s;",
                "}",
                "}"
            );
    }

    function renderGlasses() public pure returns (string memory) {
        return
            svg.g(
                string.concat(
                    svg.prop("stroke-width", "1"),
                    svg.prop("stroke", utils.getCssVar("fa")),
                    svg.prop("stroke-opacity", "0.35")
                ),
                string.concat(
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(236)),
                            svg.prop("cy", utils.uint2str(140)),
                            svg.prop("r", utils.uint2str(28)),
                            svg.prop("fill", utils.getCssVar("rg")),
                            svg.prop("fill-opacity", "0.5")
                        ),
                        utils.NULL
                    ),
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(124)),
                            svg.prop("cy", utils.uint2str(140)),
                            svg.prop("r", utils.uint2str(28)),
                            svg.prop("fill", utils.getCssVar("rg")),
                            svg.prop("fill-opacity", "0.5")
                        ),
                        utils.NULL
                    ),
                    svg.path(svg.prop("d", "M124 112h115"), utils.NULL),
                    svg.path(svg.prop("d", "M152 140h56"), utils.NULL),
                    svg.g(
                        svg.prop("class", "glasses-flip"),
                        string.concat(
                            svg.circle(
                                string.concat(
                                    svg.prop("cx", utils.uint2str(236)),
                                    svg.prop("cy", utils.uint2str(140)),
                                    svg.prop("r", utils.uint2str(28)),
                                    svg.prop("fill", utils.getCssVar("bs")),
                                    svg.prop("fill-opacity", "0.5")
                                ),
                                utils.NULL
                            ),
                            svg.circle(
                                string.concat(
                                    svg.prop("cx", utils.uint2str(124)),
                                    svg.prop("cy", utils.uint2str(140)),
                                    svg.prop("r", utils.uint2str(28)),
                                    svg.prop("fill", utils.getCssVar("bs")),
                                    svg.prop("fill-opacity", "0.5")
                                ),
                                utils.NULL
                            )
                        )
                    )
                )
            );
    }

    function renderMood() public pure returns (string memory) {
        return
            svg.g(
                svg.prop("filter", utils.getDefURL("insetShadow")),
                string.concat(
                    svg.g(
                        svg.prop("class", "mood-light"),
                        string.concat(
                            Mood.renderMouth(MouthType.BottomFill),
                            Mood.renderEye(EyeType.TopHalf, EyePosition.Left),
                            Mood.renderEye(EyeType.TopHalf, EyePosition.Right)
                        )
                    ),
                    svg.g(
                        svg.prop("class", "mood-dark"),
                        string.concat(
                            Mood.renderMouth(MouthType.WholeFill),
                            Mood.renderEye(EyeType.Closed, EyePosition.Left),
                            Mood.renderEye(EyeType.Closed, EyePosition.Right)
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./Utils.sol";
import "./SVG.sol";
import "./WatchData.sol";

enum EyeType {
    Open,
    Closed,
    TopHalf,
    BottomHalf,
    Wink
}

enum EyeTickLineType {
    Outside,
    InsideTop,
    InsideBottom
}

enum EyePosition {
    Left,
    Right
}

enum MouthType {
    Line,
    BottomStroke,
    BottomFill,
    TopFill,
    WholeFill
}

// Convenience functions for formatting all the metadata related to a particular NFT
library Mood {
    function render(uint256 _id) public pure returns (string memory) {
        WatchData.MoodId moodId = WatchData.MoodId(_id);

        if (moodId == WatchData.MoodId.Surprised) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.WholeFill),
                        renderEye(EyeType.Open, EyePosition.Left),
                        renderEye(EyeType.Open, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Happy) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomStroke),
                        renderEye(EyeType.TopHalf, EyePosition.Left),
                        renderEye(EyeType.TopHalf, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Relaxed) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomStroke),
                        renderEye(EyeType.Closed, EyePosition.Left),
                        renderEye(EyeType.Closed, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Excited) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomFill),
                        renderEye(EyeType.TopHalf, EyePosition.Left),
                        renderEye(EyeType.TopHalf, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Speechless) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderEye(EyeType.Open, EyePosition.Left),
                        renderEye(EyeType.Open, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Chilling) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomFill),
                        renderEye(EyeType.BottomHalf, EyePosition.Left),
                        renderEye(EyeType.BottomHalf, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Annoyed) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.TopFill),
                        renderEye(EyeType.BottomHalf, EyePosition.Left),
                        renderEye(EyeType.BottomHalf, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Sleepy) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.WholeFill),
                        renderEye(EyeType.Closed, EyePosition.Left),
                        renderEye(EyeType.Closed, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Unimpressed) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.Line),
                        renderEye(EyeType.BottomHalf, EyePosition.Left),
                        renderEye(EyeType.BottomHalf, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Meditating) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.Line),
                        renderEye(EyeType.Closed, EyePosition.Left),
                        renderEye(EyeType.Closed, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Relieved) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomFill),
                        renderEye(EyeType.Closed, EyePosition.Left),
                        renderEye(EyeType.Closed, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Cheeky) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.BottomFill),
                        renderEye(EyeType.TopHalf, EyePosition.Left),
                        renderEye(EyeType.Wink, EyePosition.Right)
                    )
                );
        } else if (moodId == WatchData.MoodId.Sus) {
            return
                svg.g(
                    utils.NULL,
                    string.concat(
                        renderMouth(MouthType.Line),
                        renderEye(EyeType.Wink, EyePosition.Left),
                        renderEye(EyeType.Wink, EyePosition.Right)
                    )
                );
        }

        return utils.NULL;
    }

    function renderEye(EyeType _type, EyePosition _position)
        public
        pure
        returns (string memory)
    {
        if (_type == EyeType.Open) {
            return
                eyeContainer(
                    _position,
                    string.concat(
                        renderEyePupil(_type),
                        renderEyeTicklines(EyeTickLineType.InsideTop)
                    )
                );
        } else if (_type == EyeType.Closed) {
            return
                eyeContainer(
                    _position,
                    string.concat(
                        renderEyePupil(_type),
                        renderEyeTicklines(EyeTickLineType.Outside)
                    )
                );
        } else if (_type == EyeType.BottomHalf) {
            return
                eyeContainer(
                    _position,
                    string.concat(
                        renderEyePupil(_type),
                        renderEyeTicklines(EyeTickLineType.InsideTop)
                    )
                );
        } else if (_type == EyeType.TopHalf) {
            return
                eyeContainer(
                    _position,
                    string.concat(
                        renderEyePupil(_type),
                        renderEyeTicklines(EyeTickLineType.InsideTop)
                    )
                );
        } else if (_type == EyeType.Wink) {
            return
                eyeContainer(
                    _position,
                    string.concat(
                        renderEyePupil(_type),
                        renderEyeTicklines(EyeTickLineType.InsideBottom)
                    )
                );
        }
        return "";
    }

    // Eye and Eye helpers
    // Contains all contents and purely deals with setting the x/y position.
    function eyeContainer(EyePosition _position, string memory _children)
        private
        pure
        returns (string memory)
    {
        uint256 xPos = _position == EyePosition.Left
            ? 124 /* left */
            : 236; /* right */
        uint256 yPos = 140;

        return
            svg.g(
                svg.prop(
                    "transform",
                    string.concat(
                        "translate(",
                        utils.uint2str(xPos),
                        " ",
                        utils.uint2str(yPos),
                        ")"
                    )
                ),
                string.concat(
                    // always use this background circle behind every eye combo / contents.
                    svg.circle(
                        string.concat(
                            svg.prop("cx", utils.uint2str(0)),
                            svg.prop("cy", utils.uint2str(0)),
                            svg.prop("r", utils.uint2str(36)),
                            svg.prop("fill", utils.getCssVar("fs")),
                            svg.prop("filter", utils.getDefURL("insetShadow")),
                            svg.prop("stroke", utils.getCssVar("fa")),
                            svg.prop("stroke-opacity", "0.35")
                        ),
                        utils.NULL
                    ),
                    _children
                )
            );
    }

    function renderEyePupil(EyeType _type)
        private
        pure
        returns (string memory)
    {
        if (_type == EyeType.Open) {
            return
                svg.circle(
                    string.concat(
                        svg.prop("r", utils.uint2str(8)),
                        svg.prop("fill", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.4")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.Closed) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", "none"),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("d", "M-32.4 0a32.4 32.4 0 0 0 64.8 0"),
                        svg.prop("opacity", "0.4")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.BottomHalf) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", utils.getCssVar("fa")),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("d", "M-9 0A9 9 0 0 0 9 0Z"),
                        svg.prop("opacity", "0.4")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.TopHalf) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", utils.getCssVar("fa")),
                        svg.prop("d", "M9 0A9 9 0 0 0-9 0Z"),
                        svg.prop("opacity", "0.4")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.Wink) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("d", "M-8.1-2H8.1"),
                        svg.prop("opacity", "0.4")
                    ),
                    utils.NULL
                );
        }
        return utils.NULL;
    }

    function renderEyeTicklines(EyeTickLineType _type)
        private
        pure
        returns (string memory)
    {
        if (_type == EyeTickLineType.Outside) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop(
                            "d",
                            "M43.2 0h-4m3.1 9-3.91259-.83165M39.5 17.6l-3.65418-1.62695M34.9 25.4l-3.23607-2.35114M28.9 32.1l-2.67652-2.97258M21.6 37.4l-2-3.4641M13.3 41.1l-1.23607-3.80423M4.5 43l-.41811-3.97809M-4.5 43l.41811-3.97809M-13.3 41.1l1.23607-3.80423M-21.6 37.4l2-3.4641M-28.9 32.1l2.67652-2.97258M-34.9 25.4l3.23607-2.35114M-39.5 17.6l3.65418-1.62695M-42.3 9l3.91259-.83165M-43.2 0h4"
                        ),
                        svg.prop("opacity", "0.35")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeTickLineType.InsideTop) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.35"),
                        svg.prop(
                            "d",
                            "m-31.7-6.7 3.91259.83165M-29.6-13.2l3.65418 1.62695M-26.2-19l3.23607 2.35114M-21.7-24.1l2.67652 2.97258M-16.2-28.1l2 3.4641M-10-30.8l1.23607 3.80423M-3.4-32.2l.41811 3.97809M3.4-32.2l-.41811 3.97809M10-30.8l-1.23607 3.80423M16.2-28.1l-2 3.4641m7.5.5359-2.67652 2.97258M26.2-19l-3.23607 2.35114M29.6-13.2l-3.65418 1.62695M31.7-6.7l-3.91259.83165"
                        )
                    ),
                    utils.NULL
                );
        } else if (_type == EyeTickLineType.InsideBottom) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.35"),
                        svg.prop(
                            "d",
                            "M32.4 0h-4m3.3 6.7-3.91259-.83165M29.6 13.2l-3.65418-1.62695M26.2 19l-3.23607-2.35114M21.7 24.1l-2.67652-2.97258M16.2 28.1l-2-3.4641M10 30.8l-1.23607-3.80423M3.4 32.2l-.41811-3.97809M-3.4 32.2l.41811-3.97809M-10 30.8l1.23607-3.80423M-16.2 28.1l2-3.4641m-7.5-.5359 2.67652-2.97258M-26.2 19l3.23607-2.35114M-29.6 13.2l3.65418-1.62695M-31.7 6.7l3.91259-.83165M-32.4 0h4"
                        )
                    ),
                    utils.NULL
                );
        }

        return utils.NULL;
    }

    // Mouth and Mouth helpers
    function renderMouth(MouthType _type) public pure returns (string memory) {
        if (_type == MouthType.Line) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.35"),
                        svg.prop("d", "M157.5 223h45")
                    ),
                    utils.NULL
                );
        } else if (_type == MouthType.BottomStroke) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", "none"),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.35"),
                        svg.prop("d", "M164.41154 217a18 18 0 0 0 31.17692 0")
                    ),
                    utils.NULL
                );
        } else if (_type == MouthType.BottomFill) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", utils.getCssVar("fs")),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("filter", utils.getDefURL("insetShadow")),
                        svg.prop("d", "M157.5 216a22.5 22.5 0 0 0 45 0Z")
                    ),
                    utils.NULL
                );
        } else if (_type == MouthType.TopFill) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", utils.getCssVar("fs")),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("filter", utils.getDefURL("insetShadow")),
                        svg.prop("d", "M202.5 240a22.5 22.5 0 0 0-45 0Z")
                    ),
                    utils.NULL
                );
        } else if (_type == MouthType.WholeFill) {
            return
                svg.circle(
                    string.concat(
                        svg.prop("r", utils.uint2str(11)),
                        svg.prop("cx", utils.uint2str(180)),
                        svg.prop("cy", utils.uint2str(225)),
                        svg.prop("fill", utils.getCssVar("fs")),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("filter", utils.getDefURL("insetShadow")),
                        svg.prop("stroke-opacity", "0.35")
                    ),
                    utils.NULL
                );
        }
        return utils.NULL;
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