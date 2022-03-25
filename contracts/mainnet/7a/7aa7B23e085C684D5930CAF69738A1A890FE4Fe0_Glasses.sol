//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./SVG.sol";
import "./WatchData.sol";
import "./Utils.sol";

// Renders the Glasses
library Glasses {
    function render(uint256 _id) public pure returns (string memory) {
        // convert into enum value
        WatchData.GlassesId glassesId = WatchData.GlassesId(_id);
        // first step: based on Id, render basic SVG.
        // first case! get the left monocle to work.'
        if (glassesId == WatchData.GlassesId.None) {
            return utils.NULL;
        } else if (glassesId == WatchData.GlassesId.LeftMonocle) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("fill", utils.getDefURL("obg")),
                        svg.prop("fill-opacity", "0.4"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    renderBaseMonocle()
                );
        } else if (glassesId == WatchData.GlassesId.RightMonocle) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("fill", utils.getDefURL("obg")),
                        svg.prop("fill-opacity", "0.4"),
                        svg.prop("transform", "translate(112 0)")
                    ),
                    renderBaseMonocle()
                );
        } else if (glassesId == WatchData.GlassesId.Flip) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke-width", "1"),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    string.concat(
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(236)),
                                svg.prop("cy", utils.uint2str(140)),
                                svg.prop("r", utils.uint2str(28)),
                                svg.prop("fill", utils.getDefURL("rg")),
                                svg.prop("fill-opacity", "0.5")
                            ),
                            utils.NULL
                        ),
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(124)),
                                svg.prop("cy", utils.uint2str(140)),
                                svg.prop("r", utils.uint2str(28)),
                                svg.prop("fill", utils.getDefURL("rg")),
                                svg.prop("fill-opacity", "0.5")
                            ),
                            utils.NULL
                        ),
                        svg.path(svg.prop("d", "M124 112h115"), utils.NULL),
                        svg.path(svg.prop("d", "M152 140h56"), utils.NULL),
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(236)),
                                svg.prop("cy", utils.uint2str(84)),
                                svg.prop("r", utils.uint2str(28)),
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.5")
                            ),
                            utils.NULL
                        ),
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(124)),
                                svg.prop("cy", utils.uint2str(84)),
                                svg.prop("r", utils.uint2str(28)),
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.5")
                            ),
                            utils.NULL
                        )
                    )
                );
        } else if (glassesId == WatchData.GlassesId.Valentine) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    string.concat(
                        svg.path(
                            string.concat(
                                svg.prop("fill", "none"),
                                svg.prop(
                                    "d",
                                    "M161 140.5C161 140.5 172.845 137.5 180.5 137.5C188.155 137.5 199 140.5 199 140.5"
                                )
                            ),
                            utils.NULL
                        ),
                        svg.path(
                            string.concat(
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.5"),
                                svg.prop(
                                    "d",
                                    "M123.67 118.671L124 118.959L124.33 118.671C124.726 118.323 125.143 117.992 125.581 117.68C125.956 117.412 126.325 117.146 126.687 116.885L126.689 116.884C130.189 114.36 133.136 112.245 137.26 111.728C143.709 110.919 150.018 112.253 154.705 115.888C159.378 119.513 162.5 125.473 162.5 134.054C162.5 138.275 160.859 142.7 158.168 147.04C155.479 151.376 151.761 155.594 147.66 159.388C139.49 166.948 129.879 172.755 124 174.47C118.121 172.755 108.51 166.948 100.34 159.388C96.2388 155.594 92.5215 151.376 89.8325 147.04C87.1412 142.7 85.5 138.275 85.5 134.054C85.5 125.473 88.6215 119.513 93.295 115.888C97.9815 112.253 104.291 110.919 110.74 111.728C114.864 112.245 117.811 114.36 121.311 116.884L121.313 116.885C121.675 117.146 122.044 117.412 122.419 117.68L122.71 117.273L122.419 117.68C122.857 117.992 123.274 118.323 123.67 118.671Z"
                                )
                            ),
                            utils.NULL
                        ),
                        svg.path(
                            string.concat(
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.5"),
                                svg.prop(
                                    "d",
                                    "M235.67 118.671L236 118.959L236.33 118.671C236.726 118.323 237.143 117.992 237.581 117.68C237.956 117.412 238.324 117.147 238.687 116.885L238.689 116.884C242.189 114.36 245.136 112.245 249.26 111.728C255.709 110.919 262.018 112.253 266.705 115.888C271.378 119.513 274.5 125.473 274.5 134.054C274.5 138.275 272.859 142.7 270.168 147.04C267.479 151.376 263.761 155.594 259.66 159.388C251.49 166.948 241.879 172.755 236 174.47C230.121 172.755 220.51 166.948 212.34 159.388C208.239 155.594 204.521 151.376 201.832 147.04C199.141 142.7 197.5 138.275 197.5 134.054C197.5 125.473 200.622 119.513 205.295 115.888C209.982 112.253 216.291 110.919 222.74 111.728C226.864 112.245 229.811 114.36 233.311 116.884L233.314 116.886C233.676 117.147 234.044 117.413 234.419 117.68C234.857 117.992 235.274 118.323 235.67 118.671Z"
                                )
                            ),
                            utils.NULL
                        )
                    )
                );
        } else if (glassesId == WatchData.GlassesId.Shutters) {
            return
                svg.g(
                    string.concat(
                        svg.prop("fill", utils.getDefURL("obg")),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.25"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    svg.path(
                        svg.prop(
                            "d",
                            "m85.3956 115.641.1044-.135v-.006h.0039l.1501-.187c4.3076-5.374 10.925-8.813 18.346-8.813h152c7.421 0 14.038 3.439 18.346 8.813l.15.187h.004v.006l.104.135c3.07 3.971 4.896 8.951 4.896 14.359v22c0 6.475-2.618 12.337-6.854 16.588l-.146.146v.766h-.814l-.142.125c-4.143 3.657-9.584 5.875-15.544 5.875h-28.853c-6.8 0-13.161-2.171-18.364-5.906l-.131-.094h-.152v-.11l-.201-.15c-4.846-3.621-8.637-8.62-10.763-14.486l-.006-.015-.006-.015c-1.12-2.554-1.953-5.224-2.764-7.827l-.018-.057c-1.234-3.958-2.43-7.797-4.542-10.635-2.158-2.901-5.256-4.742-10.2-4.742-4.944 0-8.042 1.841-10.2 4.742-2.112 2.838-3.308 6.677-4.542 10.635l-.018.057c-.811 2.603-1.644 5.273-2.764 7.827l-.006.015-.006.015c-2.126 5.866-5.917 10.865-10.763 14.486l-.201.15v.11h-.152l-.131.094c-5.203 3.735-11.564 5.906-18.364 5.906H104c-5.9602 0-11.4011-2.218-15.5441-5.875l-.1418-.125H87.5v-.766l-.1458-.146C83.1179 164.337 80.5 158.475 80.5 152v-22c0-5.408 1.8261-10.388 4.8956-14.359Zm3.1623 4.859h-.2709l-.148.227c-.8342 1.279-1.5418 2.649-2.105 4.091l-.2663.682h75.0693l-.327-.709c-.661-1.438-1.459-2.805-2.378-4.083l-.15-.208H88.5579Zm62.9541-5h1.652l-1.375-.916c-3.857-2.57-8.505-4.084-13.558-4.084H107c-4.816 0-9.28 1.514-12.9402 4.091l-1.2906.909h58.7428Zm10.889 15.417-.07-.417H84.6327l-.041.455c-.0607.674-.0917 1.356-.0917 2.045v2.5h78.237l.001-.499c.003-1.386-.112-2.751-.337-4.084Zm-.376 10.173.108-.59H84.5v5h76.722l.074-.41.729-4Zm-2.227 10.076.235-.666H84.5426l.0491.545c.0942 1.045.2598 2.069.4919 3.068l.0899.387h73.2215l.136-.283c.474-.987.898-2.005 1.267-3.051Zm-5.153 9.151.669-.817H87.0763l.4341.75c.8551 1.479 1.8734 2.85 3.0303 4.091l.1483.159h59.793l.14-.117c1.462-1.224 2.81-2.585 4.023-4.066Zm-15.781 10.166-.129-.983h-38.312l-.149.977c2.124.665 4.384 1.023 6.726 1.023h24.039c2.694 0 5.319-.352 7.825-1.017Zm132.997-49.756-.148-.227h-69.695l-.15.208c-.919 1.278-1.717 2.645-2.378 4.083l-.327.709h75.069l-.266-.682c-.563-1.442-1.271-2.812-2.105-4.091Zm-63.65-6.143-1.375.916h60.395l-1.291-.909c-3.66-2.577-8.124-4.091-12.94-4.091h-31.231c-5.053 0-9.701 1.514-13.558 4.084ZM198.092 130.5h-.423l-.07.417c-.225 1.333-.34 2.698-.337 4.084l.001.499H275.5V133c0-.689-.031-1.371-.092-2.045l-.041-.455h-77.275Zm.375 10h-.6l.108.59.729 4 .074.41H275.5v-5h-77.033Zm2.207 10h-.707l.235.666c.369 1.046.793 2.064 1.267 3.051l.136.283h73.221l.09-.387c.233-.999.398-2.023.492-3.068l.049-.545h-74.783Zm5.068 9h-1.056l.669.817c1.213 1.481 2.561 2.842 4.023 4.066l.14.117h59.793l.148-.159c1.157-1.241 2.176-2.612 3.031-4.091l.434-.75h-67.182Zm15.523 10-.129.983c2.506.665 5.131 1.017 7.825 1.017H253c2.342 0 4.602-.358 6.726-1.023l-.149-.977h-38.312Z"
                        ),
                        utils.NULL
                    )
                );
        } else if (glassesId == WatchData.GlassesId.ThreeD) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("fill-opacity", "0.5"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    string.concat(
                        svg.path(
                            string.concat(
                                svg.prop("fill", "red"),
                                svg.prop(
                                    "d",
                                    "M158.107 120.5H91a8.5 8.5 0 0 0-8.5 8.5v22a8.5 8.5 0 0 0 8.5 8.5h67.155a8.5 8.5 0 0 0 6.637-3.19l5.845-7.306a8.501 8.501 0 0 0 1.863-5.31v-7.181a8.5 8.5 0 0 0-1.812-5.246l-5.892-7.513a8.503 8.503 0 0 0-6.689-3.254Z"
                                )
                            ),
                            utils.NULL
                        ),
                        svg.path(
                            string.concat(
                                svg.prop("fill", "blue"),
                                svg.prop(
                                    "d",
                                    "M201.893 120.5H269a8.5 8.5 0 0 1 8.5 8.5v22a8.5 8.5 0 0 1-8.5 8.5h-67.155a8.5 8.5 0 0 1-6.637-3.19l-5.845-7.306a8.501 8.501 0 0 1-1.863-5.31v-7.181a8.5 8.5 0 0 1 1.812-5.246l5.892-7.513a8.503 8.503 0 0 1 6.689-3.254Z"
                                )
                            ),
                            utils.NULL
                        ),
                        svg.path(
                            string.concat(
                                svg.prop("fill", utils.getCssVar("bp")),
                                svg.prop("d", "M172.5 133.5h15v13h-15z")
                            ),
                            utils.NULL
                        )
                    )
                );
        } else if (glassesId == WatchData.GlassesId.Ski) {
            return
                svg.g(
                    string.concat(
                        svg.prop("fill-rule", "evenodd"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    string.concat(
                        svg.path(
                            string.concat(
                                svg.prop("fill-rule", "evenodd"),
                                svg.prop("clip-rule", "evenodd"),
                                svg.prop(
                                    "d",
                                    "M123.533 96V96.0018C99.4533 96.2181 80 115.834 80 140C80 164.301 99.6703 184 123.935 184C145.189 184 162.918 168.885 166.99 148.803C171.519 147.727 175.956 147.071 180.043 147.071C184.131 147.071 188.567 147.727 193.097 148.803C197.169 168.885 214.898 184 236.152 184C260.417 184 280.087 164.301 280.087 140C280.087 115.834 260.634 96.2181 236.554 96.0018V96H123.533ZM236.152 180.333C258.28 180.333 276.217 162.275 276.217 140C276.217 117.724 258.28 99.6666 236.152 99.6666C214.025 99.6666 196.087 117.724 196.087 140C196.087 162.275 214.025 180.333 236.152 180.333ZM123.935 180.333C146.062 180.333 164 162.275 164 140C164 117.725 146.062 99.6667 123.935 99.6667C101.807 99.6667 83.8696 117.725 83.8696 140C83.8696 162.275 101.807 180.333 123.935 180.333Z"
                                ),
                                svg.prop("fill", utils.getDefURL("fg")),
                                svg.prop("fill-opacity", "1"),
                                svg.prop("stroke", utils.getCssVar("fa")),
                                svg.prop("stroke-opacity", "0.35")
                            ),
                            utils.NULL
                        ),
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(124)),
                                svg.prop("cy", utils.uint2str(140)),
                                svg.prop("r", utils.uint2str(40)),
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.35")
                            ),
                            utils.NULL
                        ),
                        svg.circle(
                            string.concat(
                                svg.prop("cx", utils.uint2str(236)),
                                svg.prop("cy", utils.uint2str(140)),
                                svg.prop("r", utils.uint2str(40)),
                                svg.prop("fill", utils.getDefURL("obg")),
                                svg.prop("fill-opacity", "0.35")
                            ),
                            utils.NULL
                        )
                    )
                );
        } else if (glassesId == WatchData.GlassesId.Monolens) {
            return
                svg.g(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-opacity", "0.35"),
                        svg.prop("filter", utils.getDefURL("dropShadow"))
                    ),
                    string.concat(
                        svg.path(
                            string.concat(
                                svg.prop(
                                    "d",
                                    "M180 121C150.221 121 106.752 126.903 92.0635 129.029C89.1349 129.453 87 131.964 87 134.923V145.08C87 148.038 89.134 150.548 92.0614 150.973C106.726 153.1 150.096 159 180 159C209.904 159 253.274 153.1 267.939 150.973C270.866 150.548 273 148.038 273 145.08V134.923C273 131.964 270.865 129.453 267.937 129.029C253.248 126.903 209.779 121 180 121Z"
                                ),
                                svg.prop("fill", utils.getDefURL("ml")),
                                svg.prop("fill-opacity", "0.5")
                            ),
                            utils.NULL
                        ),
                        svg.path(
                            string.concat(
                                svg.prop("fill-rule", "evenodd"),
                                svg.prop("clip-rule", "evenodd"),
                                svg.prop(
                                    "d",
                                    "M74 134.14C74 131.182 76.1226 128.673 79.0501 128.247C95.0201 125.92 145.413 119 180 119C214.587 119 264.98 125.92 280.95 128.247C283.877 128.673 286 131.182 286 134.14V144.86C286 147.818 283.877 150.327 280.95 150.753C264.98 153.08 214.587 160 180 160C145.413 160 95.0201 153.08 79.0501 150.753C76.1226 150.327 74 147.818 74 144.86V134.14ZM87 134.923C87 131.964 89.1349 129.453 92.0635 129.029C106.752 126.903 150.221 121 180 121C209.779 121 253.248 126.903 267.937 129.029C270.865 129.453 273 131.964 273 134.923V144.08C273 147.038 270.866 149.548 267.939 149.973C253.274 152.1 209.904 158 180 158C150.096 158 106.726 152.1 92.0614 149.973C89.134 149.548 87 147.038 87 144.08V134.923Z"
                                ),
                                svg.prop("fill", utils.getDefURL("obg"))
                            ),
                            utils.NULL
                        )
                    )
                );
        }

        // Default case.
        return utils.NULL;
    }

    function renderBaseMonocle() internal pure returns (string memory) {
        return
            string.concat(
                svg.circle(
                    string.concat(
                        svg.prop("r", utils.uint2str(48)),
                        svg.prop("cx", utils.uint2str(124)),
                        svg.prop("cy", utils.uint2str(140))
                    ),
                    utils.NULL
                ),
                svg.line(
                    string.concat(
                        svg.prop("x1", utils.uint2str(123)),
                        svg.prop("x2", utils.uint2str(123)),
                        svg.prop("y1", utils.uint2str(188)),
                        svg.prop("y2", utils.uint2str(304)),
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("stroke-linecap", "round")
                    ),
                    utils.NULL
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