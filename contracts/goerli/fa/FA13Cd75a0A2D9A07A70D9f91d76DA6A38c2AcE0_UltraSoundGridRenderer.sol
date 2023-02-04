// SPDX-License-Identifier: MIT

/// @title Ultra Sound Grid Renderer
/// @author -wizard

/// Inspired by @jackbutcher checks

pragma solidity ^0.8.6;

import {IUltraSoundGridRenderer} from "./interfaces/IUltraSoundGridRenderer.sol";
import {IUltraSoundParts} from "./interfaces/IUltraSoundParts.sol";
import {Array} from "./libs/Array.sol";

import "@openzeppelin/contracts/utils/Strings.sol";

contract UltraSoundGridRenderer is IUltraSoundGridRenderer {
    using Strings for *;
    using Array for bytes[];

    /// @notice The contract responsible for holding symbols and pallets
    IUltraSoundParts public parts;

    constructor(IUltraSoundParts _part) {
        parts = _part;
    }

    uint16[80] gx = [
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896,
        28,
        152,
        276,
        400,
        524,
        648,
        772,
        896
    ];

    uint16[80] gy = [
        30,
        30,
        30,
        30,
        30,
        30,
        30,
        30,
        154,
        154,
        154,
        154,
        154,
        154,
        154,
        154,
        278,
        278,
        278,
        278,
        278,
        278,
        278,
        278,
        402,
        402,
        402,
        402,
        402,
        402,
        402,
        402,
        526,
        526,
        526,
        526,
        526,
        526,
        526,
        526,
        650,
        650,
        650,
        650,
        650,
        650,
        650,
        650,
        774,
        774,
        774,
        774,
        774,
        774,
        774,
        774,
        898,
        898,
        898,
        898,
        898,
        898,
        898,
        898,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1022,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146,
        1146
    ];

    string[4] ss = ["124", "248", "372", "496"];

    string[2] mvbw = ["1050", "2342"];
    string[2] mvbh = ["1300", "2342"];
    string[2] ine = ["0", "646"];
    string[2] inf = ["0", "521"];

    function generateGrid(
        Symbol memory symbol,
        Override[] memory overrides,
        uint256 gradient,
        uint256 edition
    ) public view override returns (string memory) {
        bytes memory symbols;
        bytes[] memory symbolParts = new bytes[](80);
        bytes[] memory bp = abi.decode(
            parts.palettes(symbol.gridPalette),
            (bytes[])
        );
        bytes memory gradients = gradient > 0
            ? _generateGradient(gradient)
            : bytes("");

        if (symbol.id > 0) {
            symbols = abi.encodePacked(symbols, parts.symbols(symbol.id));
            symbolParts = _expandSymbols(symbol);
        }

        if (overrides.length > 0) {
            for (uint16 i = 0; i < overrides.length; i++) {
                Override memory o = overrides[i];
                symbols = abi.encodePacked(symbols, parts.symbols(o.symbols));
                symbolParts[o.positions] = (
                    abi.encodePacked(
                        _generateSymbolSVG(
                            o.symbols,
                            o.positions,
                            false,
                            o.colors,
                            o.size
                        )
                    )
                );
            }
        }

        return
            string.concat(
                "<svg xmlns='http://www.w3.org/2000/svg' fill='none' viewBox='0 0 ",
                string.concat(
                    mvbw[symbol.gridSize],
                    " ",
                    mvbh[symbol.gridSize],
                    "'>"
                ),
                string(abi.encodePacked(gradients, symbols)),
                "<defs>",
                "<rect id='square' width='124' height='124' ",
                "stroke='",
                string(bp[2]),
                "' />"
                "<filter id='b1' x='0' y='0' width='500' height='500' filterUnits='userSpaceOnUse'><feGaussianBlur stdDeviation='7' /></filter>"
                "<filter id='g1' x='-100%' y='-100%' width='400%' height='400%' filterUnits='objectBoundingBox' primitiveUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur stdDeviation='52 63' x='0%' y='0%' width='100%' height='100%' in='SourceGraphic' result='blur'/></filter><filter id='g2' x='-100%' y='-100%' width='400%' height='400%' filterUnits='objectBoundingBox' primitiveUnits='userSpaceOnUse' color-interpolation-filters='sRGB'><feGaussianBlur stdDeviation='24 31' x='0%' y='0%' width='100%' height='100%' in='SourceGraphic' result='blur'/></filter>",
                "</defs>",
                // Outer
                string.concat(
                    "<rect width='2342' height='2342' fill='",
                    string(bp[0]),
                    symbol.gridSize == 0 ? "' visibility='hidden' />" : "' />"
                ),
                // Main
                string.concat(
                    "<g transform='matrix(1,0,0,1,",
                    ine[symbol.gridSize],
                    ",",
                    inf[symbol.gridSize],
                    ")'>"
                ),
                // Inner
                string.concat(
                    "<rect width='1050' height='1300' fill='",
                    string(bp[1]),
                    "' />"
                ),
                string.concat("<g id='grid'>", string(_grid()), "</g>"),
                string(
                    abi.encodePacked(
                        "<g id='symbols'>",
                        symbolParts.join(),
                        edition > 0 ? _edition(edition) : bytes(""),
                        "</g>"
                    )
                ),
                "</g>",
                "</svg>"
            );
    }

    function _grid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint256 i = 0; i < 10; i++) {
            for (uint256 j = 0; j < 8; j++) {
                grid = abi.encodePacked(
                    grid,
                    "<use href='#square' x='",
                    uint16(30 + j * 124).toString(),
                    "' y='",
                    uint16(30 + i * 124).toString(),
                    "'/>"
                );
            }
        }
        return grid;
    }

    function _edition(uint256 edition)
        public
        pure
        returns (bytes memory editionBytes)
    {
        editionBytes = abi.encodePacked(
            "<rect x='675' y='1179' width='294' height='51' fill='#1C2234'/><text fill='#9497B3' font-family='Inter, Arial, Helvetica, sans-serif' font-size='38px' font-weight='300' text-anchor='end' x='973' y='1221'>EDITION #",
            edition.toString(),
            "</text>"
        );
    }

    function _expandSymbols(Symbol memory symbol)
        internal
        view
        returns (bytes[] memory)
    {
        uint16 q = parts.quantities(symbol.level);
        bytes[] memory symbolParts = new bytes[](80);
        bytes[] memory symbolColors = abi.decode(
            parts.palettes(symbol.palette),
            (bytes[])
        );

        if (q == 0) return symbolParts;
        if (q == 80) {
            {
                for (uint16 i = 0; i < 80; i++) {
                    symbolParts[i] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            i,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            0
                        )
                    );
                }
            }
        } else if (q == 40) {
            {
                uint16 k = 0;
                bool pad = false;
                for (uint16 i = 0; i < 10; i++) {
                    for (uint16 j = 0; j < 4; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                0
                            )
                        );
                        k = k + 2;
                    }
                    pad = !pad;
                    k = 8 * (i + 1);
                    if (pad == true) k++;
                }
            }
        } else if (q == 20) {
            {
                uint16 k = 0;
                for (uint16 i = 0; i < 5; i++) {
                    for (uint16 j = 0; j < 4; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                1
                            )
                        );
                        k = k + 2;
                    }
                    k = 16 * (i + 1);
                }
            }
        } else if (q == 10) {
            {
                uint16 k = 2;
                for (uint16 i = 1; i < 6; i++) {
                    for (uint256 j = 0; j < 2; j++) {
                        symbolParts[k] = abi.encodePacked(
                            _generateSymbolSVG(
                                symbol.id,
                                k,
                                symbol.opaque,
                                string(
                                    symbolColors[
                                        (symbol.seed + i) % symbolColors.length
                                    ]
                                ),
                                1
                            )
                        );
                        k = k + 2;
                    }
                    k = 16 * i + 2;
                }
            }
        } else if (q == 5) {
            {
                uint16 k = 3;
                for (uint16 i = 1; i < 6; i++) {
                    symbolParts[k] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            k,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            1
                        )
                    );
                    k = 16 * i + 3;
                }
            }
        } else if (q == 4) {
            {
                for (uint16 i = 32; i < 39; i = i + 2) {
                    symbolParts[i] = abi.encodePacked(
                        _generateSymbolSVG(
                            symbol.id,
                            i,
                            symbol.opaque,
                            string(
                                symbolColors[
                                    (symbol.seed + i) % symbolColors.length
                                ]
                            ),
                            1
                        )
                    );
                }
            }
        } else {
            {
                symbolParts[35] = abi.encodePacked(
                    _generateSymbolSVG(
                        symbol.id,
                        35,
                        false,
                        string(symbolColors[1 % symbolColors.length]),
                        1
                    )
                );
            }
        }
        return symbolParts;
    }

    function _generateSymbolSVG(
        uint16 symbol,
        uint16 position,
        bool opaque,
        string memory fill,
        uint256 size
    ) internal view returns (string memory) {
        return
            string.concat(
                "<use href='#",
                symbol.toString(),
                "' x='",
                gx[position].toString(),
                "' y='",
                gy[position].toString(),
                "' fill='",
                fill,
                "' opacity='",
                _opacity(opaque ? position : 0),
                "' ",
                string.concat("height='", ss[size], "' width='", ss[size], "'"),
                " />"
            );
    }

    function _generateGradient(uint256 gradient)
        internal
        view
        returns (bytes memory)
    {
        bytes[] memory g = abi.decode(parts.gradients(gradient), (bytes[]));
        return
            abi.encodePacked(
                "<linearGradient id='lg1' gradientUnits='objectBoundingBox' x1='0' y1='0' x2='1' y2='1'><stop offset='0'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[0]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='.5'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[1]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='1'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[2]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><animateTransform attributeName='gradientTransform' type='rotate' from='0 .5 .5' to='360 .5 .5' dur='20s' repeatCount='indefinite'/></linearGradient>",
                "<linearGradient id='lg2' gradientUnits='objectBoundingBox' x1='0' y1='1' x2='1' y2='1'><stop offset='0'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[0]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><stop offset='1'>",
                string.concat(
                    "<animate attributeName='stop-color' values='",
                    string(g[1]),
                    "' dur='20s' repeatCount='indefinite'/>"
                ),
                "</stop><animateTransform attributeName='gradientTransform' type='rotate' values='360 .5 .5;0 .5 .5' class='ignore' dur='10s' repeatCount='indefinite'/></linearGradient>"
            );
    }

    function _opacity(uint16 p) internal pure returns (string memory) {
        uint16 o = 0;
        if (p == 0) return "1";
        else if (p <= 60) o = uint16(65 - p);
        else if (p <= 71) o = 5;

        if (o > 9) return string.concat("0.", o.toString());
        if (o <= 9) return string.concat("0.0", o.toString());
        return "1";
    }
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Grid Renderer
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundGridRenderer {
    struct Symbol {
        uint32 seed;
        uint8 gridPalette;
        uint8 gridSize;
        uint8 id;
        uint8 level;
        uint8 palette;
        bool opaque;
    }

    struct Override {
        uint16 symbols;
        uint16 positions;
        string colors;
        uint16 size;
    }

    function generateGrid(
        Symbol memory symbol,
        Override[] memory overides,
        uint256 gradient,
        uint256 edition
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

/// @title Interface for Ultra Sound Parts
/// @author -wizard

pragma solidity ^0.8.6;

interface IUltraSoundParts {
    error SenderIsNotDescriptor();
    error PartNotFound();

    event SymbolAdded();
    event PaletteAdded();
    event GradientAdded();

    function addSymbol(bytes calldata data) external;

    function addSymbols(bytes[] calldata data) external;

    function addPalette(bytes calldata data) external;

    function addPalettes(bytes[] calldata data) external;

    function addGradient(bytes calldata data) external;

    function addGradients(bytes[] calldata data) external;

    function symbols(uint256 index) external view returns (bytes memory);

    function palettes(uint256 index) external view returns (bytes memory);

    function gradients(uint256 index) external view returns (bytes memory);

    function quantities(uint256 index) external view returns (uint16);

    function symbolsCount() external view returns (uint256);

    function palettesCount() external view returns (uint256);

    function gradientsCount() external view returns (uint256);

    function quantityCount() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

/*
 * @title Arrays Utils
 * @author Clement Walter <[email protected]gmail.com>
 * Source: https://github.com/ClementWalter/eth-projects-monorepo/blob/main/packages/eth-projects-contracts/contracts/lib/utils/Array.sol
 *
 * @notice An attempt at implementing some of the widely used javascript's Array functions in solidity.
 */
pragma solidity ^0.8.6;

error EmptyArray();
error GlueOutOfBounds(uint256 length);

library Array {
    function join(string[] memory a, string memory glue)
        public
        pure
        returns (string memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return string(_joinReferenceType(inputPointer, gluePointer));
    }

    function join(string[] memory a) public pure returns (string memory) {
        return join(a, "");
    }

    function join(bytes[] memory a, bytes memory glue)
        public
        pure
        returns (bytes memory)
    {
        uint256 inputPointer;
        uint256 gluePointer;

        assembly {
            inputPointer := a
            gluePointer := glue
        }
        return _joinReferenceType(inputPointer, gluePointer);
    }

    function join(bytes[] memory a) public pure returns (bytes memory) {
        return join(a, bytes(""));
    }

    function join(bytes2[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 0);
    }

    /// @dev Join the underlying array of bytes2 to a string.
    function join(uint16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 2, 256 - 16);
    }

    function join(bytes3[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 3, 0);
    }

    function join(bytes4[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 4, 0);
    }

    function join(bytes8[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 8, 0);
    }

    function join(bytes16[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 16, 0);
    }

    function join(bytes32[] memory a) public pure returns (bytes memory) {
        uint256 pointer;

        assembly {
            pointer := a
        }
        return _joinValueType(pointer, 32, 0);
    }

    function _joinValueType(
        uint256 a,
        uint256 typeLength,
        uint256 shiftLeft
    ) private pure returns (bytes memory) {
        bytes memory tempBytes;

        assembly {
            let inputLength := mload(a)
            let inputData := add(a, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Initialize the length of the final bytes: length is typeLength x inputLength (array of bytes4)
            mstore(tempBytes, mul(inputLength, typeLength))
            let memoryPointer := add(tempBytes, 0x20)

            // Iterate over all bytes4
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentSlot := shl(shiftLeft, mload(pointer))
                mstore(memoryPointer, currentSlot)
                memoryPointer := add(memoryPointer, typeLength)
            }

            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }

    function _joinReferenceType(uint256 inputPointer, uint256 gluePointer)
        public
        pure
        returns (bytes memory tempBytes)
    {
        assembly {
            // Get a location of some free memory and store it in tempBytes as
            // Solidity does for memory variables.
            tempBytes := mload(0x40)

            // Skip the first 32 bytes where we will store the length of the result
            let memoryPointer := add(tempBytes, 0x20)

            // Load glue
            let glueLength := mload(gluePointer)
            if gt(glueLength, 0x20) {
                revert(gluePointer, 0x20)
            }
            let glue := mload(add(gluePointer, 0x20))

            // Load the length (first 32 bytes)
            let inputLength := mload(inputPointer)
            let inputData := add(inputPointer, 0x20)
            let end := add(inputData, mul(inputLength, 0x20))

            // Initialize the length of the final string
            let stringLength := 0

            // Iterate over all strings (a string is itself an array).
            for {
                let pointer := inputData
            } lt(pointer, end) {
                pointer := add(pointer, 0x20)
            } {
                let currentStringArray := mload(pointer)
                let currentStringLength := mload(currentStringArray)
                stringLength := add(stringLength, currentStringLength)
                let currentStringBytesCount := add(
                    div(currentStringLength, 0x20),
                    gt(mod(currentStringLength, 0x20), 0)
                )

                let currentPointer := add(currentStringArray, 0x20)

                for {
                    let copiedBytesCount := 0
                } lt(copiedBytesCount, currentStringBytesCount) {
                    copiedBytesCount := add(copiedBytesCount, 1)
                } {
                    mstore(
                        add(memoryPointer, mul(copiedBytesCount, 0x20)),
                        mload(currentPointer)
                    )
                    currentPointer := add(currentPointer, 0x20)
                }
                memoryPointer := add(memoryPointer, currentStringLength)
                mstore(memoryPointer, glue)
                memoryPointer := add(memoryPointer, glueLength)
            }

            mstore(
                tempBytes,
                add(stringLength, mul(sub(inputLength, 1), glueLength))
            )
            mstore(0x40, and(add(memoryPointer, 31), not(31)))
        }
        return tempBytes;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}