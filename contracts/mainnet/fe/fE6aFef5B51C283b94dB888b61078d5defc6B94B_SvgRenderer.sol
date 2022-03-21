//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// Base libraries
import "./SVG.sol";
import "./Utils.sol";
import "./WatchData.sol";
import "./DateTime.sol";
import "./Base64.sol";
import "./Metadata.sol";

// Component libraries
import "./Bezel.sol";
import "./Face.sol";
import "./Hands.sol";
import "./Glasses.sol";
import "./Mood.sol";
import "./GlowInTheDark.sol";

interface IDefaultResolver {
    function name(bytes32 node) external view returns (string memory);
}

interface IReverseRegistrar {
    function node(address addr) external view returns (bytes32);

    function defaultResolver() external view returns (IDefaultResolver);
}

// Core Renderer called from the main contract. It takes in a Watchface configuration
// and pulls together every component's individual library to render the final Watchface.
contract SvgRenderer {
    struct WatchConfiguration {
        uint8 bezelId;
        uint8 faceId;
        uint8 moodId;
        uint8 glassesId;
    }

    uint256 constant BEZEL_PART_BASE = 1000000;
    uint256 constant FACE_PART_BASE = 10000;
    uint256 constant MOOD_PART_BASE = 100;
    uint256 constant GLASSES_PART_BASE = 1;

    function render(
        uint256 _tokenId,
        address _owner,
        uint256 _timestamp,
        uint256 _holdingProgress,
        string calldata _engraving
    ) public view returns (string memory) {
        string memory ensName = lookupENSName(_owner);
        WatchConfiguration memory configuration = parseTokenId(_tokenId);
        string memory raw = renderSVG(
            configuration,
            _owner,
            ensName,
            _timestamp,
            _holdingProgress,
            _engraving
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        Metadata.getWatchfaceJSON(
                            configuration.bezelId,
                            configuration.faceId,
                            configuration.moodId,
                            configuration.glassesId,
                            _holdingProgress,
                            _engraving,
                            // image data
                            Base64.encode(bytes(raw))
                        )
                    )
                )
            );
    }

    function parseTokenId(uint256 _tokenId)
        internal
        pure
        returns (WatchConfiguration memory configuration)
    {
        require(_tokenId / 100000000 == 0, "Token id too large");

        configuration.bezelId = uint8((_tokenId / BEZEL_PART_BASE) % 100);
        configuration.faceId = uint8((_tokenId / FACE_PART_BASE) % 100);
        configuration.moodId = uint8((_tokenId / MOOD_PART_BASE) % 100);
        configuration.glassesId = uint8((_tokenId / GLASSES_PART_BASE) % 100);
    }

    function renderSVG(
        WatchConfiguration memory _config,
        address _owner,
        string memory _ensName,
        uint256 _timestamp,
        uint256 _holdingProgress,
        string memory _engraving
    ) public pure returns (string memory) {
        require(
            utils.utfStringLength(_engraving) <= 20,
            "Engraving must be less than or equal to 20 chars"
        );
        Date memory ts = DateTime.timestampToDateTime(_timestamp);

        bool isLight = WatchData.MaterialId(_config.bezelId) ==
            WatchData.MaterialId.Pearl;
        bool isGlowInTheDark = _config.moodId ==
            WatchData.GLOW_IN_THE_DARK_ID &&
            _config.glassesId == WatchData.GLOW_IN_THE_DARK_ID;

        return
            string.concat(
                // primary container
                '<svg xmlns="http://www.w3.org/2000/svg" width="384" height="384" style="background:#000">',
                // embed the primary SVG inside to simulate padding
                '<svg width="360" height="360" x="12" y="12">',
                /*
                 render each component stacked on top of each other.
                 1. Bezel
                 2. Face (includes engraving and date)
                 3. Mood
                 4. Glasses
                 5. Hands
                 6. Overlays for color
                */
                string.concat(
                    Bezel.render(_owner, _ensName, _holdingProgress, isLight),
                    Face.render(ts.day, ts.month, ts.year, _engraving, isLight),
                    // render custom mood for GITD.
                    isGlowInTheDark
                        ? GlowInTheDark.renderMood()
                        : Mood.render(_config.moodId),
                    // render custom glasses for GITD.
                    isGlowInTheDark
                        ? GlowInTheDark.renderGlasses()
                        : Glasses.render(_config.glassesId),
                    Hands.render(ts.second, ts.minute, ts.hour),
                    // GITD has no diamond overlay
                    // TODO: check if you need to see GITD status before this
                    renderDiamondOverlay(_config)
                ),
                "</svg>",
                // global styles and defs
                generateDefs(),
                generateCssVars(
                    _config.bezelId,
                    _config.faceId,
                    // pass in whether it's glow in the dark to
                    // generate appropriate light / dark mode tokens.
                    isGlowInTheDark
                ),
                "</svg>"
            );
    }

    function renderDiamondOverlay(WatchConfiguration memory _config)
        internal
        pure
        returns (string memory)
    {
        bool hasDiamondBezel = WatchData.MaterialId(_config.bezelId) ==
            WatchData.MaterialId.Diamond;
        bool hasDiamondFace = WatchData.MaterialId(_config.faceId) ==
            WatchData.MaterialId.Diamond;
        bool hasPearl = WatchData.MaterialId(_config.bezelId) ==
            WatchData.MaterialId.Pearl ||
            WatchData.MaterialId(_config.faceId) == WatchData.MaterialId.Pearl;

        if (hasDiamondBezel && hasDiamondFace) {
            return DiamondOverlay(WatchData.OUTER_BEZEL_RADIUS, "1.0");
        } else if (hasDiamondBezel || hasDiamondFace) {
            return DiamondOverlay(WatchData.OUTER_BEZEL_RADIUS, "0.75");
        } else if (hasPearl) {
            return DiamondOverlay(WatchData.OUTER_BEZEL_RADIUS, "0.5");
        }

        return utils.NULL;
    }

    function DiamondOverlay(uint256 _radius, string memory _opacity)
        internal
        pure
        returns (string memory)
    {
        return
            svg.circle(
                string.concat(
                    svg.prop("r", utils.uint2str(_radius)),
                    svg.prop("cx", utils.uint2str(WatchData.CENTER)),
                    svg.prop("cy", utils.uint2str(WatchData.CENTER)),
                    svg.prop("fill", utils.getDefURL("diamondOverlay")),
                    svg.prop("filter", utils.getDefURL("blur")),
                    svg.prop(
                        "style",
                        string.concat(
                            "mix-blend-mode:overlay;opacity:",
                            _opacity,
                            ";"
                        )
                    )
                ),
                utils.NULL
            );
    }

    function generateDefs() internal pure returns (string memory) {
        return (
            string.concat(
                "<defs>",
                generateGradients(),
                generateFilters(),
                "</defs>"
            )
        );
    }

    function generateGradients() internal pure returns (string memory) {
        string memory gradientUnits = svg.prop(
            "gradientUnits",
            "userSpaceOnUse"
        );
        return
            string.concat(
                // Outer bezel gradient
                svg.radialGradient(
                    string.concat(
                        svg.prop("id", "obg"),
                        svg.prop("cx", "0"),
                        svg.prop("cy", "0"),
                        svg.prop("r", utils.uint2str(WatchData.WATCH_SIZE)),
                        svg.prop("gradientUnits", "userSpaceOnUse"),
                        svg.prop("gradientTransform", "scale(1)")
                    ),
                    string.concat(
                        svg.gradientStop(0, utils.getCssVar("bp"), utils.NULL),
                        svg.gradientStop(100, utils.getCssVar("bs"), utils.NULL)
                    )
                ),
                // Inner bezel gradient
                svg.radialGradient(
                    string.concat(
                        svg.prop("id", "ibg"),
                        svg.prop("cx", "0"),
                        svg.prop("cy", "0"),
                        svg.prop("r", utils.uint2str(WatchData.WATCH_SIZE)),
                        gradientUnits,
                        svg.prop(
                            "gradientTransform",
                            "scale(1.5) rotate(30 180 180)"
                        )
                    ),
                    string.concat(
                        svg.gradientStop(0, utils.getCssVar("bp"), utils.NULL),
                        svg.gradientStop(100, utils.getCssVar("bs"), utils.NULL)
                    )
                ),
                // Face gradient
                svg.radialGradient(
                    string.concat(
                        svg.prop("id", "fg"),
                        svg.prop("cx", "0"),
                        svg.prop("cy", "0"),
                        svg.prop("r", utils.uint2str(WatchData.WATCH_SIZE)),
                        gradientUnits
                    ),
                    string.concat(
                        svg.gradientStop(0, utils.getCssVar("fp"), utils.NULL),
                        svg.gradientStop(100, utils.getCssVar("fs"), utils.NULL)
                    )
                ),
                // Reflection gradient
                svg.linearGradient(
                    string.concat(
                        svg.prop("id", "rg"),
                        svg.prop("cx", "0"),
                        svg.prop("cy", "0"),
                        svg.prop("r", utils.uint2str(WatchData.WATCH_SIZE)),
                        gradientUnits
                    ),
                    string.concat(
                        svg.gradientStop(
                            0,
                            utils.getCssVar("bs"),
                            svg.prop("stop-opacity", "0%")
                        ),
                        svg.gradientStop(
                            50,
                            utils.getCssVar("ba"),
                            svg.prop("stop-opacity", "60%")
                        ),
                        svg.gradientStop(
                            100,
                            utils.getCssVar("bs"),
                            svg.prop("stop-opacity", "0%")
                        )
                    )
                ),
                // Gradient for monolens gradient
                svg.linearGradient(
                    string.concat(
                        svg.prop("id", "ml"),
                        svg.prop("x1", "87"),
                        svg.prop("y1", "137"),
                        svg.prop("x2", "273"),
                        svg.prop("y2", "137"),
                        gradientUnits
                    ),
                    string.concat(
                        svg.gradientStop(0, "#6DF7A5", utils.NULL),
                        svg.gradientStop(50, "#5400BF", utils.NULL),
                        svg.gradientStop(100, "#6DEFF7", utils.NULL)
                    )
                ),
                // // Shadow gradient
                svg.radialGradient(
                    string.concat(
                        svg.prop("id", "sg"),
                        // center/2
                        svg.prop("cx", "90"),
                        // center/2
                        svg.prop("cy", "90"),
                        svg.prop("r", utils.uint2str(WatchData.WATCH_SIZE)),
                        gradientUnits
                    ),
                    string.concat(
                        svg.gradientStop(
                            0,
                            utils.getCssVar("black"),
                            svg.prop("stop-opacity", "0%")
                        ),
                        svg.gradientStop(
                            50,
                            utils.getCssVar("black"),
                            svg.prop("stop-opacity", "5%")
                        ),
                        svg.gradientStop(
                            100,
                            utils.getCssVar("black"),
                            svg.prop("stop-opacity", "50%")
                        )
                    )
                ),
                // Diamond overlay
                svg.linearGradient(
                    string.concat(
                        svg.prop("id", "diamondOverlay"),
                        svg.prop("cx", "180"),
                        svg.prop("cy", "180"),
                        svg.prop("r", "180"),
                        gradientUnits
                    ),
                    string.concat(
                        svg.gradientStop(0, "#fffd92", utils.NULL),
                        svg.gradientStop(14, "#ffcca7", utils.NULL),
                        svg.gradientStop(28, "#f893ff", utils.NULL),
                        svg.gradientStop(42, "#b393ff", utils.NULL),
                        svg.gradientStop(57, "#99a7ff", utils.NULL),
                        svg.gradientStop(71, "#76d4ff", utils.NULL),
                        svg.gradientStop(85, "#7cffda", utils.NULL)
                    )
                )
            );
    }

    function generateFilters() internal pure returns (string memory) {
        string memory filterUnits = svg.prop("filterUnits", "userSpaceOnUse");
        return
            string.concat(
                // FILTERS
                // Inset shadow
                svg.filter(
                    string.concat(svg.prop("id", "insetShadow"), filterUnits),
                    string.concat(
                        svg.el(
                            "feColorMatrix",
                            string.concat(
                                svg.prop("in", "SourceGraphic"),
                                svg.prop("type", "matrix"),
                                // that second to last value is the opacity of the matrix.
                                svg.prop(
                                    "values",
                                    "0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0.7 0"
                                ),
                                svg.prop("result", "opaque-source")
                            ),
                            utils.NULL
                        ),
                        svg.el(
                            "feOffset",
                            string.concat(
                                svg.prop("in", "SourceGraphic"),
                                svg.prop("dx", "2"),
                                svg.prop("dy", "0")
                            ),
                            utils.NULL
                        ),
                        svg.el(
                            "feGaussianBlur",
                            svg.prop("stdDeviation", "6"),
                            utils.NULL
                        ),
                        svg.el(
                            "feComposite",
                            string.concat(
                                svg.prop("operator", "xor"),
                                svg.prop("in2", "opaque-source")
                            ),
                            utils.NULL
                        ),
                        svg.el(
                            "feComposite",
                            string.concat(
                                svg.prop("operator", "in"),
                                svg.prop("in2", "opaque-source")
                            ),
                            utils.NULL
                        ),
                        svg.el(
                            "feComposite",
                            string.concat(
                                svg.prop("operator", "over"),
                                svg.prop("in2", "SourceGraphic")
                            ),
                            utils.NULL
                        )
                    )
                ),
                // Drop shadow
                svg.filter(
                    string.concat(svg.prop("id", "dropShadow"), filterUnits),
                    svg.el(
                        "feDropShadow",
                        string.concat(
                            svg.prop("dx", "0"),
                            svg.prop("dy", "0"),
                            svg.prop("stdDeviation", "8"),
                            svg.prop("floodOpacity", "0.5")
                        ),
                        utils.NULL
                    )
                ),
                // Blur
                svg.filter(
                    svg.prop("id", "blur"),
                    svg.el(
                        "feGaussianBlur",
                        string.concat(
                            svg.prop("in", "SourceGraphic"),
                            svg.prop("stdDeviation", "8")
                        ),
                        utils.NULL
                    )
                )
            );
    }

    function generateCssVars(
        uint256 _bezelId,
        uint256 _faceId,
        bool _isGlowInTheDark
    ) internal pure returns (string memory) {
        // given an ID, generate the proper variables
        // query the mapping
        WatchData.Material memory bezelMaterial = WatchData.getMaterial(
            _bezelId
        );
        WatchData.Material memory faceMaterial = WatchData.getMaterial(_faceId);

        return
            string.concat(
                "<style>",
                _isGlowInTheDark
                    ? (GlowInTheDark.generateMaterialTokens())
                    : (
                        string.concat(
                            "*{",
                            generateMaterialTokens(bezelMaterial, faceMaterial),
                            "}"
                        )
                    ),
                // constant for both glow in the dark and regular colors.
                "*{",
                generateTypographyTokens(),
                generateConstantTokens(),
                "}",
                // Used for full progress watches.
                "@keyframes fadeOpacity{0%{opacity:1;} 50%{opacity:0;} 100%{opacity:1;}}",
                "</style>"
            );
    }

    function generateMaterialTokens(
        WatchData.Material memory _bezelMaterial,
        WatchData.Material memory _faceMaterial
    ) internal pure returns (string memory) {
        return
            string.concat(
                // BEZEL COLORS
                // bezel primary (bp)
                utils.setCssVar("bp", _bezelMaterial.vals[0]),
                // bezel secondary (bs)
                utils.setCssVar("bs", _bezelMaterial.vals[1]),
                // bezel accent (ba)
                utils.setCssVar(
                    "ba",
                    WatchData.getMaterialAccentColor(_bezelMaterial.id)
                ),
                // FACE COLORS
                // face primary (fp)
                utils.setCssVar("fp", _faceMaterial.vals[0]),
                // face secondary (fs)
                utils.setCssVar("fs", _faceMaterial.vals[1]),
                // face accent (fa)
                utils.setCssVar(
                    "fa",
                    WatchData.getMaterialAccentColor(_faceMaterial.id)
                )
            );
    }

    function generateTypographyTokens() internal pure returns (string memory) {
        return
            string.concat(
                // // typography
                // // bezel type size
                // the type size is 11.65px so that on average the space between characters around the bezel is an integer (7 px).
                // this helps with the rendering code inside of Bezel.sol because we need to calcualte the exact spacing dynamically
                // and can't use decimals easily.
                utils.setCssVar("bts", "11.65px"),
                // // face type size
                utils.setCssVar("fts", "12px"),
                // // text shadow
                utils.setCssVar("textShadow", "1px 0 6px rgba(0,0,0,0.8)")
            );
    }

    function generateConstantTokens() internal pure returns (string memory) {
        return
            string.concat(
                // constant colors
                utils.setCssVar("white", "#fff"),
                utils.setCssVar("black", "#000"),
                utils.setCssVar("clear", "transparent"),
                // More constants
                "font-family: monospace;",
                "font-weight: 500;",
                // Allows the glow to escape from the container
                "overflow: visible;"
            );
    }

    function lookupENSName(address _address)
        internal
        view
        returns (string memory)
    {
        address reverseRegistrarAddress = block.chainid == 1
            ? 0x084b1c3C81545d370f3634392De611CaaBFf8148
            : 0x6F628b68b30Dc3c17f345c9dbBb1E483c2b7aE5c;

        uint32 size;
        assembly {
            size := extcodesize(reverseRegistrarAddress)
        }
        if (size == 0) {
            return "";
        }
        IReverseRegistrar ensReverseRegistrar = IReverseRegistrar(
            reverseRegistrarAddress
        );
        bytes32 node = ensReverseRegistrar.node(_address);
        return ensReverseRegistrar.defaultResolver().name(node);
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

// SPDX-License-Identifier: MIT
// Copyright (c) 2018 The Officious BokkyPooBah / Bok Consulting Pty Ltd

pragma solidity ^0.8.0;

struct Date {
    uint256 year;
    uint256 month;
    uint256 day;
    uint256 hour;
    uint256 minute;
    uint256 second;
}

library DateTime {
    // for datetime conversion.
    uint256 private constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint256 private constant SECONDS_PER_HOUR = 60 * 60;
    uint256 private constant SECONDS_PER_MINUTE = 60;
    int256 constant OFFSET19700101 = 2440588;

    function timestampToDateTime(uint256 timestamp)
        internal
        pure
        returns (Date memory)
    {
        (uint256 year, uint256 month, uint256 day) = _daysToDate(
            timestamp / SECONDS_PER_DAY
        );
        uint256 secs = timestamp % SECONDS_PER_DAY;
        uint256 hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        uint256 minute = secs / SECONDS_PER_MINUTE;
        uint256 second = secs % SECONDS_PER_MINUTE;

        return Date(year, month, day, hour, minute, second);
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
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
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

    function isLeapYear(uint256 timestamp)
        internal
        pure
        returns (bool leapYear)
    {
        (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }

    function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
}

// SPDX-License-Identifier: MIT
// Author: Brecht Devos

pragma solidity ^0.8.0;

library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

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
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(248, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./WatchData.sol";

// Convenience functions for formatting all the metadata related to a particular NFT
library Metadata {
    function getWatchfaceJSON(
        uint8 _bezelId,
        uint8 _faceId,
        uint8 _moodId,
        uint8 _glassesId,
        uint256 _holdingProgress,
        string calldata _engraving,
        string memory _imageData
    ) public pure returns (string memory) {
        string memory attributes = renderAttributes(
            _bezelId,
            _faceId,
            _moodId,
            _glassesId,
            _holdingProgress,
            _engraving
        );
        return
            string.concat(
                '{"name": "',
                renderName(_bezelId, _faceId, _moodId, _glassesId, _engraving),
                '", "background_color": "000000", "image": "data:image/svg+xml;base64,',
                _imageData,
                '","attributes":[',
                attributes,
                "]}"
            );
    }

    function renderName(
        uint8 _bezelId,
        uint8 _faceId,
        uint8 _moodId,
        uint8 _glassesId,
        string calldata engraving
    ) public pure returns (string memory) {
        if (_moodId == WatchData.GLOW_IN_THE_DARK_ID) {
            return '\\"Glow In The Dark\\" Watchface 1/1';
        }

        string memory prefix = "";
        if (bytes(engraving).length > 0) {
            prefix = string.concat('\\"', engraving, '\\" ');
        }
        return
            string.concat(
                prefix,
                "Watchface ",
                utils.uint2str(_bezelId),
                "-",
                utils.uint2str(_faceId),
                "-",
                utils.uint2str(_moodId),
                "-",
                utils.uint2str(_glassesId)
            );
    }

    function renderAttributes(
        uint8 _bezelId,
        uint8 _faceId,
        uint8 _moodId,
        uint8 _glassesId,
        uint256 _holdingProgress,
        string calldata engraving
    ) public pure returns (string memory) {
        if (_moodId == WatchData.GLOW_IN_THE_DARK_ID) {
            return
                string.concat(
                    attributeBool("Glow In The Dark", true),
                    ",",
                    attributeBool("Cared-for", _holdingProgress >= 1000)
                );
        }

        string memory engravingAttribute = "";
        if (bytes(engraving).length > 0) {
            engravingAttribute = string.concat(
                attributeString("Engraving", engraving),
                ","
            );
        }
        return
            string.concat(
                engravingAttribute,
                attributeString("Bezel", WatchData.getMaterial(_bezelId).name),
                ",",
                attributeString("Face", WatchData.getMaterial(_faceId).name),
                ",",
                attributeString("Mood", WatchData.getMood(_moodId).name),
                ",",
                attributeString(
                    "Glasses",
                    WatchData.getGlasses(_glassesId).name
                ),
                ",",
                attributeBool("Cared-for", _holdingProgress >= 1000)
            );
    }

    function attributeString(string memory _name, string memory _value)
        public
        pure
        returns (string memory)
    {
        return
            string.concat(
                "{",
                kv("trait_type", string.concat('"', _name, '"')),
                ",",
                kv("value", string.concat('"', _value, '"')),
                "}"
            );
    }

    function attributeBool(string memory _name, bool _value)
        public
        pure
        returns (string memory)
    {
        return attributeString(_name, _value ? "Yes" : "No");
    }

    function kv(string memory _key, string memory _value)
        public
        pure
        returns (string memory)
    {
        return string.concat('"', _key, '"', ":", _value);
    }
}

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
        uint256 _holdingProgress,
        bool _isLight
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
        uint256 spaceLeft = 1005 - /* circumference = Math.floor(2*Pi*r(160)) */
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
                        renderMouth(MouthType.WholeFill),
                        renderEye(EyeType.Open, EyePosition.Left),
                        renderEye(EyeType.Open, EyePosition.Right)
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
                            svg.prop("stroke-opacity", "0.5")
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
                        svg.prop("opacity", "0.5")
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
                        svg.prop("opacity", "0.5")
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
                        svg.prop("opacity", "0.5")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.TopHalf) {
            return
                svg.path(
                    string.concat(
                        svg.prop("fill", utils.getCssVar("fa")),
                        svg.prop("d", "M9 0A9 9 0 0 0-9 0Z"),
                        svg.prop("opacity", "0.5")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeType.Wink) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("d", "M-8.1-2H8.1"),
                        svg.prop("opacity", "0.5")
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
                        svg.prop("opacity", "0.5")
                    ),
                    utils.NULL
                );
        } else if (_type == EyeTickLineType.InsideTop) {
            return
                svg.path(
                    string.concat(
                        svg.prop("stroke", utils.getCssVar("fa")),
                        svg.prop("opacity", "0.5"),
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
                        svg.prop("opacity", "0.5"),
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
                        svg.prop("opacity", "0.5"),
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
                        svg.prop("opacity", "0.5"),
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
                        svg.prop("stroke-opacity", "0.5"),
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
                        svg.prop("stroke-opacity", "0.5"),
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
                        svg.prop("stroke-opacity", "0.25")
                    ),
                    utils.NULL
                );
        }
        return utils.NULL;
    }
}

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