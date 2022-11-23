// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {AlienArtBase} from "../../interfaces/alienArt/AlienArtBase.sol";
import {MoonImageConfig} from "../../moon/MoonStructs.sol";

import {IERC165} from "../../interfaces/ext/IERC165.sol";
import {Utils} from "../../utils/Utils.sol";
import {LibPRNG} from "../../utils/LibPRNG.sol";
import {svg} from "./SVG.sol";

/// @title AlienArtSpaceIsWeird
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
contract AlienArtSpaceIsWeird is AlienArtBase {
    using LibPRNG for LibPRNG.PRNG;

    function getArtName() external pure override returns (string memory) {
        return "Space is Weird";
    }

    function getTurbulenceTypeForToken(uint256 token)
        internal
        pure
        returns (string memory)
    {
        LibPRNG.PRNG memory prng;
        prng.seed(keccak256(abi.encodePacked(token)));
        return prng.uniform(4) == 0 ? "fractalNoise" : "turbulence";
    }

    function getTurbulence(uint256 tokenId, uint256 rotationInDegrees)
        internal
        pure
        returns (string memory)
    {
        string memory props1 = string.concat(
            svg.prop("type", getTurbulenceTypeForToken(tokenId)),
            svg.prop(
                "baseFrequency",
                string.concat(
                    "0.0",
                    // Trivially append rotation to 0.0 to vary the base frequency value based on rotation.
                    // NOTE: a rotationInDegrees value of 1 and of 100 will both result in value of 0.01 being used,
                    // and this logic represents what will occur for many values (ex. 2 and 200), which is intentional.
                    Utils.uint2str(rotationInDegrees)
                )
            ),
            svg.prop("numOctaves", "4"),
            svg.prop("seed", "15")
        );
        string memory props2 = string.concat(
            svg.prop("stitchTiles", "stitch"),
            svg.prop("x", "0%"),
            svg.prop("y", "0%"),
            svg.prop("width", "100%"),
            svg.prop("height", "100%"),
            svg.prop("result", "turbulence")
        );
        return svg.feTurbulence(string.concat(props1, props2));
    }

    function getNoiseDefinitions(
        string memory filterName,
        uint256 tokenId,
        MoonImageConfig memory moonImageConfig,
        uint256 rotationInDegrees
    ) internal pure returns (string memory) {
        string memory turbulence = getTurbulence(tokenId, rotationInDegrees);
        string memory specularLightingProps1 = string.concat(
            svg.prop("surfaceScale", "18"),
            svg.prop("specularConstant", "1.4"),
            svg.prop("specularExponent", "10"),
            svg.prop("lighting-color", moonImageConfig.colors.moon)
        );
        string memory specularLightingProps2 = string.concat(
            svg.prop("x", "0%"),
            svg.prop("y", "0%"),
            svg.prop("width", "100%"),
            svg.prop("height", "100%"),
            svg.prop("in", "turbulence"),
            svg.prop("result", "specularLighting")
        );

        string memory specularLighting = svg.feSpecularLighting(
            string.concat(specularLightingProps1, specularLightingProps2),
            svg.feDistantLight(
                string.concat(
                    svg.prop("azimuth", "3"),
                    svg.prop("elevation", "110")
                )
            )
        );

        string memory definitionProps = string.concat(
            svg.prop("id", filterName),
            svg.prop("width", "140%"),
            svg.prop("height", "140%"),
            svg.prop("filterUnits", "objectBoundingBox"),
            svg.prop("primitiveUnits", "userSpaceOnUse"),
            svg.prop("color-interpolation-filters", "linearRGB")
        );
        return
            svg.defs(
                svg.NULL,
                svg.filter(
                    definitionProps,
                    string.concat(turbulence, specularLighting)
                )
            );
    }

    function getArt(
        // Moon token id
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view override returns (string memory) {
        string memory definitions = getNoiseDefinitions(
            "noise",
            tokenId,
            moonImageConfig,
            rotationInDegrees
        );
        return
            svg.svgTag(
                svg.NULL,
                string.concat(
                    definitions,
                    svg.rect(
                        string.concat(
                            svg.prop("width", moonImageConfig.viewWidth),
                            svg.prop("height", moonImageConfig.viewHeight),
                            svg.prop("fill", "hsl(23, 100%, 0%)")
                        )
                    ),
                    svg.rect(
                        string.concat(
                            svg.prop("width", moonImageConfig.viewWidth),
                            svg.prop("height", moonImageConfig.viewHeight),
                            svg.prop("fill", moonImageConfig.colors.moon),
                            svg.prop("filter", "url(#noise)")
                        )
                    )
                )
            );
    }

    function getMoonFilter(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig memory moonImageConfig,
        uint256 rotationInDegrees
    ) external view override returns (string memory) {
        return
            getNoiseDefinitions(
                "mF",
                tokenId,
                moonImageConfig,
                rotationInDegrees
            );
    }

    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata,
        uint256
    ) external view override returns (string memory) {
        return "";
        // TODO try without any trait and make sure it shows correctly
        return
            string.concat(
                '{"trait_type": "Noise type", "value": "',
                getTurbulenceTypeForToken(tokenId),
                '"}'
            );
    }

    // IERC165 functions

    function supportsInterface(bytes4 interfaceID)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            // AlienArtBase interface id
            interfaceID == type(AlienArtBase).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {IERC165} from "../ext/IERC165.sol";
import {MoonImageConfig} from "../../moon/MoonStructs.sol";

/// @title AlienArtBase
/// @author Aspyn Palatnick (aspyn.eth, stuckinaboot.eth)
/// @notice Alien Art is an on-chain NFT composability standard for on-chain art and traits.
abstract contract AlienArtBase is IERC165 {
    // Define functions that alien art contracts can override. These intentionally
    // use function state mutability as view to allow for reading on-chain data.

    /// @notice get art name.
    /// @return art name.
    function getArtName() external view virtual returns (string memory);

    /// @notice get alien art image for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art image.
    function getArt(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory);

    /// @notice get moon filter for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return moon filter.
    function getMoonFilter(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }

    /// @notice get alien art traits for a particular token.
    /// @param tokenId token id.
    /// @param moonSeed moon seed.
    /// @param moonImageConfig moon image config.
    /// @param rotationInDegrees rotation in degrees.
    /// @return alien art traits.
    function getTraits(
        uint256 tokenId,
        bytes32 moonSeed,
        MoonImageConfig calldata moonImageConfig,
        uint256 rotationInDegrees
    ) external view virtual returns (string memory) {
        return "";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Colors describing the moon image.
struct MoonImageColors {
    string moon;
    uint16 moonHue;
    string border;
    uint8 borderSaturation;
    string background;
    uint8 backgroundLightness;
    string backgroundGradientColor;
}

// Config describing the complete moon image, with colors, positioning, and sizing.
struct MoonImageConfig {
    MoonImageColors colors;
    uint16 moonRadius;
    uint16 xOffset;
    uint16 yOffset;
    uint16 viewWidth;
    uint16 viewHeight;
    uint16 borderRadius;
    uint16 borderWidth;
    string borderType;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity 0.8.17;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Core utils used extensively to format CSS and numbers.
library Utils {
    string internal constant BASE64_TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    // converts an unsigned integer to a string
    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            ++len;
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

    function htmlToURI(string memory _source)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:text/html;base64,",
                encodeBase64(bytes(_source))
            );
    }

    function svgToImageURI(string memory _source)
        internal
        pure
        returns (string memory)
    {
        return
            string.concat(
                "data:image/svg+xml;base64,",
                encodeBase64(bytes(_source))
            );
    }

    function formatTokenURI(
        string memory _imageURI,
        string memory _animationURI,
        string memory _name,
        string memory _description,
        string memory _properties
    ) internal pure returns (string memory) {
        return
            string.concat(
                "data:application/json;base64,",
                encodeBase64(
                    bytes(
                        string.concat(
                            '{"name":"',
                            _name,
                            '","description":"',
                            _description,
                            '","attributes":',
                            _properties,
                            ',"image":"',
                            _imageURI,
                            '","animation_url":"',
                            _animationURI,
                            '"}'
                        )
                    )
                )
            );
    }

    // Encode some bytes in base64
    // https://gist.github.com/mbvissers/8ba9ac1eca9ed0ef6973bd49b3c999ba
    function encodeBase64(bytes memory data)
        internal
        pure
        returns (string memory)
    {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = BASE64_TABLE;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Library for generating psuedorandom numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/LibPRNG.sol)
library LibPRNG {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                          STRUCTS                           */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev A psuedorandom number state in memory.
    struct PRNG {
        uint256 state;
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         OPERATIONS                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Seeds the `prng` with `state`.
    function seed(PRNG memory prng, bytes32 state) internal pure {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(prng, state)
        }
    }

    /// @dev Returns a psuedorandom uint256, uniformly distributed
    /// between 0 (inclusive) and `upper` (exclusive).
    /// If your modulus is big, this method is recommended
    /// for uniform sampling to avoid modulo bias.
    /// For uniform sampling across all uint256 values,
    /// or for small enough moduli such that the bias is neligible,
    /// use {next} instead.
    function uniform(PRNG memory prng, uint256 upper)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // prettier-ignore
            for {} 1 {} {
                result := keccak256(prng, 0x20)
                mstore(prng, result)
                // prettier-ignore
                if iszero(lt(result, mod(sub(0, upper), upper))) { break }
            }
            result := mod(result, upper)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {Utils} from "../../utils/Utils.sol";

// Core SVG utility library which helps us construct
// onchain SVG's with a simple, web-like API.
// Props to w1nt3r.eth for creating the core of this SVG utility library.
library svg {
    string internal constant NULL = "";

    /* MAIN ELEMENTS */
    function svgTag(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("svg", _props, _children);
    }

    function defs(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("defs", _props, _children);
    }

    function rect(string memory _props) internal pure returns (string memory) {
        return el("rect", _props, NULL);
    }

    function filter(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("filter", _props, _children);
    }

    function feTurbulence(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feTurbulence", _props, NULL);
    }

    function feSpecularLighting(string memory _props, string memory _children)
        internal
        pure
        returns (string memory)
    {
        return el("feSpecularLighting", _props, _children);
    }

    function feDistantLight(string memory _props)
        internal
        pure
        returns (string memory)
    {
        return el("feDistantLight", _props, NULL);
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
        return string.concat(_key, '="', _val, '" ');
    }

    function prop(string memory _key, uint256 _val)
        internal
        pure
        returns (string memory)
    {
        return prop(_key, Utils.uint2str(_val));
    }
}