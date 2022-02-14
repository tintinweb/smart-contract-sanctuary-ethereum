//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IMetavatarGenerator.sol";

contract MetavatarGenerator is IMetavatarGenerator, Ownable {
    uint256 constant MAX_SHAPES = 3;
    uint256 constant MIN_SHAPE_SIZE = 800; // 0.5 * 1600
    uint256 constant MAX_SHAPE_SIZE = 1280; // 0.8 * 1600
    uint256 constant MIN_BACKGROUND_OPACITY = 10; // 0.1 (solidity doesnt have float)
    uint256 constant MAX_BACKGROUND_OPACITY = 50; // 0.5
    uint256 constant MIN_SHAPE_OPACITY = 50;
    uint256 constant MAX_SHAPE_OPACITY = 100;

    // Whether or not `tokenURI` should be returned as a data URI
    bool public isDataURIEnabled = true;
    // fallback option to support twitter pfp and MM wallet once all tokens have been minted!
    string public baseURI;

    function genMetavatarWithSeed(string memory seed)
        private
        pure
        returns (MetavatarStruct memory, string memory)
    {
        MetavatarStruct memory metav;
        string[7] memory colors = [
            "#FFC700",
            "#1BC47D",
            "#EF5533",
            "#18A0FB",
            "#907CFF",
            "#00B5CE",
            "#EE46D3"
        ];

        string[6] memory svgParts;
        metav.numShapes = getRandomInRange(seed, "SHAPES", 1, MAX_SHAPES + 1);
        metav.background = colors[
            getRandomInRange(seed, "BG", 0, colors.length)
        ];
        metav.lightMode = getRandomInRange(seed, "MODE", 0, 2) % 2 == 0
            ? true
            : false;
        uint256 opacityValue = getRandomInRange(
            seed,
            "BG_OPACITY",
            MIN_BACKGROUND_OPACITY,
            MAX_BACKGROUND_OPACITY
        );
        metav.bgOpacity = string(
            abi.encodePacked(".", Strings.toString(opacityValue))
        );
        metav.animated = getRandomInRange(seed, "ANIMATED", 0, 20) > 17
            ? true
            : false; // 15% probability

        svgParts[
            0
        ] = '<svg width="800" height="800" viewBox="0 0 1600 1600" fill="none" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" style="border-radius: 0px">';
        svgParts[1] = string(
            abi.encodePacked(
                '<rect width="1600" height="1600" fill="',
                !metav.lightMode ? "#000000" : "#FFFFFF",
                '"/>'
            )
        );
        svgParts[2] = string(
            abi.encodePacked(
                '<rect width="1600" height="1600" fill="',
                metav.background,
                '" fill-opacity="',
                metav.bgOpacity,
                '"/><g clip-path="url(#clip0_50_327)"><g filter="url(#filter0_f_50_327)">'
            )
        );

        string memory shapesSvg;
        for (uint256 i = 0; i < metav.numShapes; i++) {
            string memory shapeSvg;
            Shape memory sh;
            bool toAnimate = (metav.animated == true) &&
                (i == metav.numShapes - 1)
                ? true
                : false; // animate only the topmost shape
            sh.shapeType = getRandomInRange(
                seed,
                string(abi.encodePacked("SHAPE", i)),
                0,
                MAX_SHAPES
            );
            sh.width = getRandomInRange(
                seed,
                string(abi.encodePacked("SHAPE_WIDTH", i)),
                MIN_SHAPE_SIZE,
                MAX_SHAPE_SIZE
            );
            sh.height = getRandomInRange(
                seed,
                string(abi.encodePacked("SHAPE_HEIGHT", i)),
                MIN_SHAPE_SIZE,
                MAX_SHAPE_SIZE
            );
            sh.xpos = getRandomInRange(
                seed,
                string(abi.encodePacked("X", Strings.toString(i))),
                200,
                1000
            );
            sh.ypos = getRandomInRange(
                seed,
                string(abi.encodePacked("Y", Strings.toString(i))),
                200,
                1000
            );
            sh.fillType = getRandomInRange(
                seed,
                string(abi.encodePacked("FILL_TYPE", Strings.toString(i))),
                0,
                2
            );
            string memory lg_element = "";
            if (sh.fillType == 0) {
                // solid color
                sh.fillValue = colors[
                    getRandomInRange(
                        seed,
                        string(
                            abi.encodePacked(
                                "SHAPE_COLOR",
                                Strings.toString(i * 1111)
                            )
                        ),
                        0,
                        colors.length
                    )
                ];
            } else {
                // linear gradient element
                LG memory lge;
                lge.id = string(
                    abi.encodePacked(
                        "lg_",
                        Strings.toString(sh.shapeType),
                        "_",
                        Strings.toString(i)
                    )
                );
                sh.fillValue = string(abi.encodePacked("url(#", lge.id, ")"));
                lge.stopColor1 = pickColor(
                    colors,
                    seed,
                    string(
                        abi.encodePacked(
                            "STOP_COLOR_1",
                            Strings.toString(i * 1111)
                        )
                    )
                );
                lge.stopColor2 = pickColor(
                    colors,
                    seed,
                    string(
                        abi.encodePacked(
                            "STOP_COLOR_2",
                            Strings.toString(i * 3)
                        )
                    )
                );
                lge.stopOpacity1 = string(
                    abi.encodePacked(
                        ".",
                        toStr(
                            getRandomInRange(
                                seed,
                                "SHAPE_OPACITY_1",
                                MIN_SHAPE_OPACITY,
                                MAX_SHAPE_OPACITY
                            )
                        )
                    )
                );
                lge.stopOpacity2 = string(
                    abi.encodePacked(
                        ".",
                        toStr(
                            getRandomInRange(
                                seed,
                                "SHAPE_OPACITY_2",
                                MIN_SHAPE_OPACITY,
                                MAX_SHAPE_OPACITY
                            )
                        )
                    )
                );
                lg_element = createLinearGradient(sh, lge);
            }
            if (sh.shapeType == 0) {
                shapeSvg = createRectangle(sh, toAnimate);
            } else if (sh.shapeType == 1) {
                shapeSvg = createEllipse(sh, toAnimate);
            } else {
                shapeSvg = createTriangle(sh, toAnimate);
            }
            shapesSvg = string(
                abi.encodePacked(shapesSvg, shapeSvg, lg_element)
            );
        }
        svgParts[3] = shapesSvg;
        svgParts[4] = string(
            abi.encodePacked(
                '</g></g><g style="mix-blend-mode:overlay"><rect width="1600" height="1600" fill="url(#pattern0)" />',
                '<rect x="0" y="0" width="1600" height="1600" style="fill:gray; stroke:transparent; filter: url(#feTurb02)"/>'
            )
        );
        svgParts[
            5
        ] = '</g><defs><filter id="feTurb02" filterUnits="objectBoundingBox" x="0%" y="0%" width="100%" height="100%"><feTurbulence baseFrequency="0.3" numOctaves="2" seed="3" result="out1"/><feComposite in="out1" in2="SourceGraphic" operator="in" result="out2"/><feBlend in="SourceGraphic" in2="out2" mode="overlay" result="out3"/></filter><filter id="filter0_f_50_327" x="0" y="0" width="1600" height="1600" filterUnits="userSpaceOnUse" color-interpolation-filters="sRGB"><feFlood flood-opacity="0" result="BackgroundImageFix"/><feBlend mode="normal" in="SourceGraphic" in2="BackgroundImageFix" result="shape"/><feGaussianBlur stdDeviation="250" result="effect1_foregroundBlur_50_327"/></filter></defs></svg>';

        string memory svg = string(
            abi.encodePacked(
                svgParts[0],
                svgParts[1],
                svgParts[2],
                svgParts[3],
                svgParts[4],
                svgParts[5]
            )
        );
        return (metav, svg);
    }

    function animateTransform(Shape memory sh)
        private
        pure
        returns (string memory)
    {
        uint256 centroid_x;
        uint256 centroid_y;
        if (sh.shapeType == 0) {
            centroid_x = (sh.width / 2) + sh.xpos;
            centroid_y = (sh.height / 2) + sh.ypos;
        } else if (sh.shapeType == 1) {
            centroid_x = sh.xpos;
            centroid_y = sh.ypos;
        } else {
            bool isNegX = (sh.width / 2) > sh.xpos ? true : false;
            centroid_x = isNegX == true
                ? (sh.xpos +
                    (sh.xpos + (sh.width / 2)) -
                    (sh.width / 2 - sh.xpos)) / 3
                : (sh.xpos +
                    (sh.xpos + (sh.width / 2)) +
                    (sh.xpos - (sh.width / 2))) / 3;
            centroid_y = (sh.ypos + sh.height + sh.height) / 3;
        }
        return
            string(
                abi.encodePacked(
                    '<animateTransform attributeName="transform" type="rotate" from="0 ',
                    Strings.toString(centroid_x),
                    " ",
                    Strings.toString(centroid_y),
                    '" to="360 ',
                    Strings.toString(centroid_x),
                    " ",
                    Strings.toString(centroid_y),
                    '" dur="30s" repeatDur="indefinite"/>'
                )
            );
    }

    function createRectangle(Shape memory sh, bool animated)
        private
        pure
        returns (string memory)
    {
        string memory animTag = "";
        if (animated) {
            animTag = animateTransform(sh);
        }
        return
            string(
                abi.encodePacked(
                    '<rect x="',
                    Strings.toString(sh.xpos),
                    '" y="',
                    Strings.toString(sh.ypos),
                    '" width="',
                    Strings.toString(sh.width),
                    '" height="',
                    Strings.toString(sh.height),
                    '" fill="',
                    sh.fillValue,
                    '">',
                    animTag,
                    "</rect>"
                )
            );
    }

    function createEllipse(Shape memory sh, bool animated)
        private
        pure
        returns (string memory)
    {
        string memory animTag = "";
        if (animated) {
            animTag = animateTransform(sh);
        }
        return
            string(
                abi.encodePacked(
                    '<ellipse cx="',
                    Strings.toString(sh.xpos),
                    '" cy="',
                    Strings.toString(sh.ypos),
                    '" rx="',
                    Strings.toString(sh.width / 2),
                    '" ry="',
                    Strings.toString(sh.height / 2),
                    '" fill="',
                    sh.fillValue,
                    '">',
                    animTag,
                    "</ellipse>"
                )
            );
    }

    function createTriangle(Shape memory sh, bool animated)
        private
        pure
        returns (string memory)
    {
        string memory animTag = "";
        if (animated) {
            animTag = animateTransform(sh);
        }
        uint256 v1 = sh.xpos;
        uint256 v2 = sh.width / 2;
        string memory leftVertex = v2 > v1
            ? string(abi.encodePacked("-", Strings.toString(v2 - v1)))
            : Strings.toString(v1 - v2);
        return
            string(
                abi.encodePacked(
                    '<path d="M',
                    Strings.toString(sh.xpos),
                    " ",
                    Strings.toString(sh.ypos),
                    " L",
                    leftVertex,
                    " ",
                    Strings.toString(sh.height),
                    " L",
                    Strings.toString(sh.xpos + (sh.width / 2)),
                    " ",
                    Strings.toString(sh.height),
                    ' Z" fill="',
                    sh.fillValue,
                    '">',
                    animTag,
                    "</path>"
                )
            );
    }

    function createLinearGradient(Shape memory sh, LG memory lge)
        private
        pure
        returns (string memory)
    {
        /*
        Linear gradient from left to right of shape
        y + height / 2,
        x + width,
        y + height / 2,
      */
        return
            string(
                abi.encodePacked(
                    '<linearGradient id="',
                    lge.id,
                    '" x1="',
                    toStr(sh.xpos),
                    '" y1="',
                    toStr(sh.ypos + (sh.height / 2)),
                    '" x2="',
                    toStr(sh.xpos + sh.width),
                    '" y2="',
                    toStr(sh.ypos + (sh.height / 2)),
                    '" gradientUnits="userSpaceOnUse"><stop stop-color="',
                    lge.stopColor1,
                    '" stop-opacity="',
                    lge.stopOpacity1,
                    '"/><stop offset="1" stop-color="',
                    lge.stopColor2,
                    '" stop-opacity="',
                    lge.stopOpacity2,
                    '"/></linearGradient>'
                )
            );
    }

    function toStr(uint256 val) private pure returns (string memory) {
        return Strings.toString(val);
    }

    function pickColor(
        string[7] memory colors,
        string memory seed,
        string memory key
    ) private pure returns (string memory) {
        return colors[getRandomInRange(seed, key, 0, colors.length)];
    }

    function getRandomInRange(
        string memory seed,
        string memory key,
        uint256 min,
        uint256 max
    ) private pure returns (uint256) {
        if (max <= min) return min;
        return
            (uint256(keccak256(abi.encodePacked(key, seed))) % (max - min)) +
            min;
    }

    function tokenURI(uint256 tokenId, string memory seed)
        external
        view
        override
        returns (string memory)
    {
        if (isDataURIEnabled) {
            return dataURI(tokenId, seed);
        }
        return string(abi.encodePacked(baseURI, Strings.toString(tokenId)));
    }

    function dataURI(uint256 tokenId, string memory seed)
        public
        pure
        override
        returns (string memory)
    {
        MetavatarStruct memory metav;
        string memory svg;
        (metav, svg) = genMetavatarWithSeed(seed);
        string memory attributes = string(
            abi.encodePacked(
                '[{"trait_type":"Background","value":"',
                metav.background,
                '"},{"trait_type":"Number of Shapes","value":"',
                Strings.toString(metav.numShapes),
                '"},{"trait_type":"Mode","value":"',
                metav.lightMode ? "Light" : "Dark",
                '"},{"trait_type":"Animated","value":"',
                metav.animated ? "Yes" : "No",
                '"},{"trait_type":"Contains Blob","value":"No"}]'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name":"Metavatar #',
                        Strings.toString(tokenId),
                        '","description": "Unique pfps (on Chain) for the entire metaverse.", "attributes":',
                        attributes,
                        ',"image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(svg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    function setDataURIEnabled(bool status) external onlyOwner {
        isDataURIEnabled = status;
    }

    function setBaseURI(string calldata _baseURI) external onlyOwner {
        baseURI = _baseURI;
    }
}

library Base64 {
    bytes internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF)
                )
                out := shl(8, out)
                out := add(
                    out,
                    and(mload(add(tablePtr, and(input, 0x3F))), 0xFF)
                )
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

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
pragma solidity 0.8.9;

interface IMetavatarGenerator {
    struct MetavatarStruct {
        uint256 numShapes;
        string background;
        bool lightMode;
        string bgOpacity;
        bool animated;
    }

    struct Shape {
        uint256 shapeType; // 0: rectange, 1: ellipses, 2: triangle
        uint256 xpos;
        uint256 ypos;
        uint256 width;
        uint256 height;
        uint256 fillType; // 0: solid, 1: gradient
        string fillValue;
    }

    struct LG {
        string id;
        string stopColor1;
        string stopColor2;
        string stopOpacity1;
        string stopOpacity2;
    }

    function tokenURI(uint256 tokenId, string memory seed)
        external
        view
        returns (string memory);

    function dataURI(uint256 tokenId, string memory seed)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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