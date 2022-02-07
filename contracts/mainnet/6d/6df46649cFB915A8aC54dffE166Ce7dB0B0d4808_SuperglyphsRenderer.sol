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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '../utils/Randomize.sol';

/// @title ISuperglyphsRenderer
/// @author Simon Fremaux (@dievardump)
interface ISuperglyphsRenderer {
    struct Configuration {
        uint256 seed;
        uint256 mod;
        int256 z1;
        int256 z2;
        bool randStroke;
        bool fullSymmetry;
        bool darkTheme;
        bytes9[2] colors;
        bytes16 symbols;
    }

    function start(
        uint256 seed,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    )
        external
        pure
        returns (Randomize.Random memory random, Configuration memory config);

    /// @dev Rendering function
    /// @param name the token name
    /// @param tokenId the tokenId
    /// @param colorSeed the seed used for coloring, if no color selected
    /// @param selectedColors the user selected colors
    /// @param selectedSymbols the symbols selected by the user
    /// @param frozen if the token customization is frozen
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/utils/Strings.sol';

import '../utils/Randomize.sol';
import '../utils/DynamicBuffer.sol';
import '../utils/Base64.sol';

import './ISuperglyphsRenderer.sol';

interface ISuperglyphs {
    function getSymbol(uint256 symbolId, Randomize.Random memory random)
        external
        view
        returns (bytes memory);
}

/// @title SuperglyphsRenderer
/// @author Simon Fremaux (@dievardump)
contract SuperglyphsRenderer is ISuperglyphsRenderer {
    using Strings for uint256;
    using Randomize for Randomize.Random;

    int256 public constant HALF = 24;
    uint256 public constant CELL_SIZE = 44;
    uint256 public constant SEED_BOUND = 0xfffffff;

    constructor() {}

    function start(
        uint256 seed,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    )
        public
        pure
        returns (Randomize.Random memory random, Configuration memory config)
    {
        random = Randomize.Random({seed: seed});

        config = _getConfiguration(
            random,
            seed,
            colorSeed,
            selectedColors,
            selectedSymbols
        );
    }

    /// @dev Rendering function
    /// @param name the token name
    /// @param tokenId the tokenId
    /// @param colorSeed the seed used for coloring, if no color selected
    /// @param selectedColors the user selected colors
    /// @param selectedSymbols the symbols selected by the user
    /// @param frozen if the token customization is frozen
    /// @return the json
    function render(
        string memory name,
        uint256 tokenId,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols,
        bool frozen
    ) external view returns (string memory) {
        (Randomize.Random memory random, Configuration memory config) = start(
            tokenId,
            colorSeed,
            selectedColors,
            selectedSymbols
        );

        (, bytes memory buffer) = DynamicBuffer.allocate(100000);

        DynamicBuffer.appendBytes(
            buffer,
            "%3Csvg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' viewBox='0 0 2464 2464' width='2464' height='2464'%3E%3Cdefs%3E"
        );

        _addGradient(buffer, config, random);
        _addSymbols(buffer, config);
        _fill(buffer, config, random);

        {
            bool yMirror = random.next(0, 10) < 8;
            DynamicBuffer.appendBytes(
                buffer,
                abi.encodePacked(
                    "%3Cmask id='mask' stroke-width='",
                    (config.randStroke ? random.next(4, 8).toString() : '4'),
                    "'%3E",
                    "%3Cuse href='%23left'/%3E%3Cuse href='%23left' transform='translate(-352, ",
                    yMirror ? '-352' : '0',
                    ') scale(-1, ',
                    yMirror ? '-1' : '1',
                    ")' transform-origin='50%25 50%25'/%3E",
                    '%3C/mask%3E',
                    '%3C/defs%3E'
                )
            );
        }

        DynamicBuffer.appendBytes(
            buffer,
            abi.encodePacked(
                "%3Crect width='100%25' height='100%25' fill='",
                (config.darkTheme ? '%23000' : '%23fff'),
                "'/%3E",
                "%3Cg transform='translate(176, 176)'%3E%3Crect width='2112' height='2112' fill='url(%23gr)' mask='url(%23mask)'/%3E%3C/g%3E",
                '%3C/svg%3E'
            )
        );

        // stack too deep "quick fix"
        string[6] memory data = [
            tokenId.toString(),
            config.mod.toString(),
            (tokenId % SEED_BOUND).toString(),
            string(
                abi.encodePacked(
                    '[{"trait_type":"Customizable","value":"',
                    ((frozen == false) ? 'Yes' : 'No'),
                    '"},{"trait_type":"Colors","value":"',
                    ((selectedColors == 0) ? 'Auto' : 'Custom'),
                    '"},{"trait_type":"Symbols","value":"',
                    ((selectedSymbols == 0) ? 'Auto' : 'Custom'),
                    '"},{"trait_type":"Last refresh","value":"',
                    _getDateTime(),
                    '"}]'
                )
            ),
            string(_getDescription(frozen, tokenId)),
            name
        ];

        return
            string(
                abi.encodePacked(
                    'data:application/json;base64,',
                    Base64.encode(
                        abi.encodePacked(
                            '{"image":"data:image/svg+xml;utf8,',
                            buffer,
                            '","seed":"',
                            data[0],
                            '","mod":"',
                            data[1],
                            '","base":"',
                            data[2],
                            '","attributes":',
                            data[3],
                            ',"license":"Full ownership with unlimited commercial rights.","creator":"dievardump"'
                            ',"description":',
                            data[4],
                            ',"name":"',
                            data[5],
                            '"}'
                        )
                    )
                )
            );
    }

    function _getDescription(bool frozen, uint256 tokenId)
        internal
        pure
        returns (bytes memory)
    {
        return
            abi.encodePacked(
                '"Superglyphs.sol\\n\\n',
                (
                    frozen
                        ? 'This Superglyph has been frozen and can not be customized anymore.'
                        : string(
                            abi.encodePacked(
                                'Name, Symbols and Colors customizable at [https://solSeedlings.art](https://solSeedlings.art/superglyphs/',
                                tokenId.toString(),
                                '). Non-customized tokens will change colors when they change owner.'
                            )
                        )
                ),
                '\\n\\nSuperglyphs.sol is the third of the [sol]Seedlings, an experiment of art and collectible NFTs 100% generated with Solidity.\\n\\nLicense: Full ownership with unlimited commercial rights.\\n\\nMore info at [https://solSeedlings.art](https://solSeedlings.art)\\n\\nby @dievardump with <3"'
            );
    }

    function _getConfiguration(
        Randomize.Random memory random,
        uint256 seed,
        uint256 colorSeed,
        bytes16 selectedColors,
        bytes16 selectedSymbols
    ) internal pure returns (Configuration memory config) {
        config.seed = seed;
        config.mod = random.next(5, 16);

        // z1 and z2 are kind of Z offsets
        config.z1 = int256(random.next(2, 500));

        // z1 == z2 means full symmetry
        config.z2 = random.next(0, 10) < 3
            ? int256(random.next(501, 1000))
            : config.z1;

        // 1 out of 10 have random stroke size
        config.randStroke = random.next(0, 10) < 1;

        // 50 / 50 chance dark / light
        config.darkTheme = random.next(0, 10) < 5;

        // colors and symbols can be modified by the owner of a token
        // therefore they do not use the main PRNG, as to not modify the other values
        // when they change

        // get colors
        if (selectedColors != 0) {
            config.colors = [
                bytes9(
                    abi.encodePacked(
                        '%23',
                        selectedColors[1],
                        selectedColors[2],
                        selectedColors[3],
                        selectedColors[4],
                        selectedColors[5],
                        selectedColors[6]
                    )
                ),
                bytes9(
                    abi.encodePacked(
                        '%23',
                        selectedColors[8],
                        selectedColors[9],
                        selectedColors[10],
                        selectedColors[11],
                        selectedColors[12],
                        selectedColors[13]
                    )
                )
            ];
        } else {
            config.colors = _getColors(colorSeed, config.darkTheme);
        }

        // those are simple preset symbols automatically selected when user doesn't custom
        if (selectedSymbols == 0) {
            // select symbols
            selectedSymbols = [
                bytes16(0x01020000000000000000000000000000), // vertical, horizontal
                bytes16(0x01020304050000000000000000000000), // vert, hor, diag1, diag2, cross
                bytes16(0x01020600000000000000000000000000), // vert, hor, circle
                bytes16(0x0C0D0700000000000000000000000000), // rounded 512Print 1, rounded 2, circle with dot
                bytes16(0x03040000000000000000000000000000), // diag 1, diag 2
                bytes16(0x1A0A0900000000000000000000000000), // circle with dot, square with square, square with cross
                bytes16(0x03040500000000000000000000000000), // diagonal 1, diagonal 2, cross
                bytes16(0x06050800000000000000000000000000), // cross, circle, square
                bytes16(0x01020B00000000000000000000000000), // plus, horizontal, vertical
                bytes16(0x01020B0C0D0000000000000000000000), // vert, hor, plus, rounded 512Print 1, rounded 2
                bytes16(0x0E0F1011000000000000000000000000), // sides
                bytes16(0x12131415000000000000000000000000), // triangles
                bytes16(0x1C1D1E00000000000000000000000000), // vert hor plus animated
                bytes16(0x1F1F1F00000000000000000000000000), // random squares
                bytes16(0x1B1B1B00000000000000000000000000), // animated squares
                bytes16(0x20030421000000000000000000000000), // longer (diagonals, verticals, horizontals)
                bytes16(0x22002200220000000000000000000000), // growing lines
                bytes16(0x23241A0A090000000000000000000000), // stroked square, stroked circle, circle with dot, square with square, square with cross
                bytes16(0x25002600270000000000000000000000), // 3 circles, barred circle, double triangle
                bytes16(0x28002800280000000000000000000000) // hashtags
            ][seed % 20];

            // what follows is a simple way to "shuffle" the selected symbols
            // 1) create an array of indexes.
            // 2) pick an index randomly
            // 3) replace this index by last index available
            // 4) decrement size of the array

            // create a PRNG specifically for symbols distribution
            // this way the random in symbol distribution does not affect the global random
            // else it will change the rendering when symbols are updated
            Randomize.Random memory random2 = Randomize.Random({
                seed: uint256(keccak256(abi.encode(seed)))
            });

            // create an array containing indexes 0 - config.mod
            uint256 temp = config.mod;
            uint256[] memory available = new uint256[](config.mod);
            for (uint256 i; i < temp; i++) {
                available[i] = i;
            }

            // shuffle the symbols using the array of indexes
            bytes memory selected = new bytes(config.mod);
            for (uint256 i; i < selected.length; i++) {
                // whenever there is a something to draw
                if (selectedSymbols[i] != 0) {
                    //select one of the remaining index
                    uint256 index = random2.next(0, temp);
                    // and set the element to draw for this index
                    selected[available[index]] = selectedSymbols[i];

                    // remove the index from the list of remaining index
                    // by replacing it with the last index
                    available[index] = available[temp - 1];

                    // decrement length of available index
                    temp--;
                }
            }

            // we end up with bytes of config.mod length
            // where some bytes are non-zero and correspond to a symbol
            config.symbols = bytes16(selected);
        } else {
            // selectedSymbols should only have non-zero values
            // at indexes lesser than config.mod
            config.symbols = selectedSymbols;
        }
    }

    function _fill(
        bytes memory buffer,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure {
        uint256 v;
        int256 y;
        int256 y2;
        int256 x;
        int256 base = int256(config.seed % SEED_BOUND);

        // rotating elements in bottom to have some mirroring happening, à la ModuloArt
        bool rot = random.next(0, 3) < 2;
        // invert top / bottom for a different effect
        bool invert = random.next(0, 2) == 0;
        // using [-HALF;HALF] grid instead of [1->HALF;HALF->1]
        bool translate = random.next(0, 2) == 0;

        DynamicBuffer.appendBytes(buffer, "%3Cg id='left'%3E");

        for (int256 i; i < HALF; i++) {
            if (translate) {
                y = (config.z1 * (i - HALF) + 1) * base;
                y2 = (config.z2 * (i + 1) - 1) * base;
            } else {
                y = (config.z1 * (i + 1)) * base;
                y2 = (config.z2 * (HALF - i)) * base;
            }

            if (invert) {
                (y, y2) = (y2, y);
            }

            for (int256 j; j < HALF; j++) {
                x = ((config.z1 * config.z2) * (j + 1)) * base;

                v = ((uint256(x * y)) / SEED_BOUND) % config.mod;

                bytes memory stroke = (
                    config.randStroke
                        ? abi.encodePacked(
                            "stroke-width='",
                            random.next(4, 8).toString(),
                            "'"
                        )
                        : bytes('')
                );

                if (config.symbols[v] != 0) {
                    DynamicBuffer.appendBytes(
                        buffer,
                        abi.encodePacked(
                            "%3Cuse x='",
                            _getPosition(j, 0),
                            "' y='",
                            _getPosition(i, 0),
                            "' href='%23s-",
                            v.toString(),
                            "' ",
                            stroke,
                            '/%3E'
                        )
                    );
                }

                v = ((uint256(x * y2)) / SEED_BOUND) % config.mod;

                if (config.symbols[v] != 0) {
                    DynamicBuffer.appendBytes(
                        buffer,
                        abi.encodePacked(
                            "%3Cuse x='",
                            _getPosition(j, 0),
                            "' y='",
                            _getPosition(i + HALF, 0),
                            "' href='%23s-",
                            v.toString(),
                            "' ",
                            (
                                !rot
                                    ? bytes('')
                                    : abi.encodePacked(
                                        "transform='rotate(180 ",
                                        _getPosition(j, 22),
                                        ' ',
                                        _getPosition(i + HALF, 22),
                                        ")'"
                                    )
                            ),
                            ' ',
                            stroke,
                            '/%3E'
                        )
                    );
                }
            }
        }

        DynamicBuffer.appendBytes(buffer, '%3C/g%3E');
    }

    /// @dev get the position in pixels
    /// @param index the index to get the coord for
    /// @return the position
    function _getPosition(int256 index, uint256 offset)
        internal
        pure
        returns (string memory)
    {
        return (uint256(index) * CELL_SIZE + offset).toString();
    }

    /// @dev create the symbols that will be referenced by the cells
    /// @param buffer the buffer to add to
    /// @param config the full configuration object
    function _addSymbols(bytes memory buffer, Configuration memory config)
        internal
        view
    {
        // symbols can change depending on the user choice, so their rendering
        // has its own PRNG, to not modify the cells distribution
        Randomize.Random memory random = Randomize.Random({
            seed: uint256(keccak256(abi.encode(config.seed)))
        });

        uint256 b;
        for (uint256 i; i < config.symbols.length; i++) {
            b = uint256(uint8(config.symbols[i]));
            if (b == 0) {
                // nothing.
                continue;
            } else if (b == 1) {
                // vertical line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,22L44,22' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 2) {
                // hor line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M22,0L22,44' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 3) {
                // diagonal line top left to bottom right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,0L44,44' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 4) {
                // diagonal line bottom left to top right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M44,0L0,44' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 5) {
                // cross
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,0L44,44M0,44L44,0' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 6) {
                // full circle
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Ccircle id='s-",
                        i.toString(),
                        "' cx='22' cy='22' r='22' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 7) {
                // circle with dot
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Ccircle cx='22' cy='22' r='18' fill='none' stroke='%23fff'/%3E%3Ccircle cx='22' cy='22' r='4' fill='%23fff'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 8) {
                // filled square
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Crect id='s-",
                        i.toString(),
                        "' x='7' y='7' width='30' height='30' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 9) {
                // square with cross
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Crect x='2' y='2' width='40' height='40' fill='%23fff'%3E%3C/rect%3E%3Cpath d='M18,18L26,26M18,26L26,18' stroke='%23000' stroke-width='4' stroke-linecap='round'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 10) {
                // square with square
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Crect x='2' y='2' width='40' height='40' fill='%23fff'/%3E%3Crect fill='%23000' x='18' y='18' width='8' height='8'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 11) {
                // plus
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Cpath d='M0,22L44,22M22,0L22,44' stroke='%23fff'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 12) {
                // rounded 512Print 1
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M22 0a22 22 0 0 1 -22 22m44 0a22 22 0 0 0 -22 22' stroke='%23fff' stroke-linecap='round'/%3E"
                    )
                );
            } else if (b == 13) {
                // rounded 512Print 2
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M22 0a22 22 0 0 0 22 22m-44 0a22 22 0 0 1 22 22' stroke='%23fff' stroke-linecap='round'/%3E"
                    )
                );
            } else if (b == 14) {
                // sides:top-right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0 0L44 0L44 44' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 15) {
                // sides:right-bottom
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M44 0L44 44L0 44' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 16) {
                // sides:bottom-left
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M44 44L0 44L0 0' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 17) {
                // sides:left-top
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0 44L0 0L44 0' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 18) {
                // triangles:top-right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0 0L44 0L44 44Z' ",
                        (
                            random.next(0, 100) < 50
                                ? "fill='none' stroke='%23fff'"
                                : "fill='%23fff'"
                        ),
                        '/%3E'
                    )
                );
            } else if (b == 19) {
                // triangles:right-bottom
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M44 0L44 44L0 44Z' ",
                        (
                            random.next(0, 100) < 50
                                ? "fill='none' stroke='%23fff'"
                                : "fill='%23fff'"
                        ),
                        '/%3E'
                    )
                );
            } else if (b == 20) {
                // triangles:bottom-left
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M44 44L0 44L0 0Z' ",
                        (
                            random.next(0, 100) < 50
                                ? "fill='none' stroke='%23fff'"
                                : "fill='%23fff'"
                        ),
                        '/%3E'
                    )
                );
            } else if (b == 21) {
                // triangles:left-top
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0 44L0 0L44 0Z' ",
                        (
                            random.next(0, 100) < 50
                                ? "fill='none' stroke='%23fff'"
                                : "fill='%23fff'"
                        ),
                        '/%3E'
                    )
                );
            } else if (b == 22) {
                // circle top-left
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath d='M0 0 h44 a44,44 0 0 1 -44,44z' id='s-",
                        i.toString(),
                        "' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 23) {
                // circle top-right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath d='M44 0 v44 a44,44 0 0 1 -44,-44z' id='s-",
                        i.toString(),
                        "' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 24) {
                // circle bottom right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath d='M44 44 h-44 a44,44 0 0 1 44,-44z' id='s-",
                        i.toString(),
                        "' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 25) {
                // circle bottom right
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath d='M0 44 v-44 a44,44 0 0 1 44,44z' id='s-",
                        i.toString(),
                        "' fill='%23fff'/%3E"
                    )
                );
            } else if (b == 26) {
                // full circle with empty dot
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Ccircle cx='22' cy='22' r='20' fill='%23fff'/%3E%3Ccircle cx='22' cy='22' r='4' fill='%23000'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 27) {
                // animated square
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Crect id='s-",
                        i.toString(),
                        "' x='7' y='7' width='30' height='30' fill='%23fff' transform='scale(1)' transform-origin='22 22' ",
                        "%3E%3CanimateTransform attributeName='transform' type='scale' values='1;0;1' dur='8s' fill='freeze' repeatCount='indefinite' begin='",
                        random.next(0, 5000).toString(),
                        "ms'/%3E%3C/rect%3E"
                    )
                );
            } else if (b == 28) {
                // animated vertical line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,22L44,22' stroke='%23fff' transform='scale(1)' transform-origin='22 22' ",
                        "%3E%3CanimateTransform attributeName='transform' type='scale' values='1;0;1' dur='8s' fill='freeze' repeatCount='indefinite' begin='",
                        random.next(0, 5000).toString(),
                        "ms'/%3E%3C/path%3E"
                    )
                );
            } else if (b == 29) {
                // animated hor line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M22,0L22,44' stroke='%23fff' transform='scale(1)' transform-origin='22 22' ",
                        "%3E%3CanimateTransform attributeName='transform' type='scale' values='1;0;1' dur='8s' fill='freeze' repeatCount='indefinite' begin='",
                        random.next(0, 5000).toString(),
                        "ms'/%3E%3C/path%3E"
                    )
                );
            } else if (b == 30) {
                // animated plus
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,22L44,22M22,0L22,44' stroke='%23fff' transform='scale(1)' transform-origin='22 22' ",
                        "%3E%3CanimateTransform attributeName='transform' type='scale' values='1;0;1' dur='8s' fill='freeze' repeatCount='indefinite' begin='",
                        random.next(0, 5000).toString(),
                        "ms'/%3E%3C/path%3E"
                    )
                );
            } else if (b == 31) {
                // random size square
                uint256 size = random.next(30, 44);
                if (size % 2 != 0) {
                    size++;
                }

                uint256 offset = (44 - size) / 2;
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Crect id='s-",
                        i.toString(),
                        "' x='",
                        offset.toString(),
                        "' y='",
                        offset.toString(),
                        "' width='",
                        size.toString(),
                        "' height='",
                        size.toString(),
                        "' fill='%23fff' transform='scale(1)' transform-origin='22 22' ",
                        '%3E%3C/rect%3E'
                    )
                );
            } else if (b == 32) {
                // "long" horizontal line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,0L44,44' stroke='%23fff' transform='rotate(45 22 22)'/%3E"
                    )
                );
            } else if (b == 33) {
                // "long" verticale line
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M0,0L44,44' stroke='%23fff' transform='rotate(-45 22 22)'/%3E"
                    )
                );
            } else if (b == 34) {
                // growing line random direction
                uint256 length = 44 * random.next(1, 10);
                string memory delay = random.next(500, 4000).toString();

                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cline id='s-",
                        i.toString(),
                        "' x1='0' y1='0' x2='",
                        (length.toString()),
                        "' y2='0' stroke='%23fff' stroke-dasharray='",
                        length.toString(),
                        "' stroke-dashoffset='",
                        (length - 1).toString(),
                        "' stroke-linecap='round' transform='rotate(",
                        (random.next(0, 4) * 90).toString(),
                        " 22 22)' stroke-width='22'%3E%3Canimate attributeName='stroke-dashoffset' "
                    )
                );
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        " values='",
                        (length - 1).toString(),
                        ';0;',
                        (length - 1).toString(),
                        "' dur='",
                        random.next(4000, 15000).toString(),
                        "ms' repeatCount='indefinite' begin='",
                        delay,
                        'ms;op.end+',
                        delay,
                        "ms'/%3E%3C/line%3E"
                    )
                );
            } else if (b == 35) {
                // stroked square
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Crect id='s-",
                        i.toString(),
                        "' x='7' y='7' width='30' height='30' fill='none' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 36) {
                // stroked circle
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Ccircle id='s-",
                        i.toString(),
                        "' cx='22' cy='22' r='22' fill='none' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 37) {
                // 3 circles
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg id='s-",
                        i.toString(),
                        "'%3E%3Ccircle cx='22' cy='22' r='20' fill='none' stroke='%23fff'/%3E%3Ccircle cx='22' cy='22' r='11' fill='none' stroke='%23fff'/%3E%3Ccircle cx='22' cy='22' r='4' fill='%23fff'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 38) {
                // barred circle
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cg transform='rotate(-45 22 22)' id='s-",
                        i.toString(),
                        "'%3E%3Ccircle cx='22' cy='22' r='20' fill='none' stroke='%23fff'/%3E%3Cpath d='M22 0L22 44' stroke='%23fff'/%3E%3Ccircle cx='22' cy='22' r='6' fill='%23fff'/%3E%3C/g%3E"
                    )
                );
            } else if (b == 39) {
                // double triangle
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M4 4L40 4L22 40Z M22 4L40 40L4 40Z' stroke='%23fff'/%3E"
                    )
                );
            } else if (b == 40) {
                // hashtag
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3Cpath id='s-",
                        i.toString(),
                        "' d='M14 6L14 38M30 6L30 38M6 14L38 14M6 30L38 30' stroke='%23fff'/%3E"
                    )
                );
            } else {
                // this allows to someday, extend the list of available symbols
                DynamicBuffer.appendBytes(
                    buffer,
                    ISuperglyphs(msg.sender).getSymbol(b, random)
                );
            }
        }
    }

    function _addGradient(
        bytes memory buffer,
        Configuration memory config,
        Randomize.Random memory random
    ) internal pure {
        // 50% chance linear gradient
        if (random.next(0, 10) < 5) {
            uint256 x1;
            uint256 y1;
            uint256 x2;
            uint256 y2;
            if (random.next(0, 10) < 5) {
                x1 = 0;
                x2 = 100;
                y1 = random.next(0, 100);
                y2 = 100 - y1;
            } else {
                y1 = 0;
                y2 = 100;
                x1 = random.next(0, 100);
                x2 = 100 - x1;
            }
            // 50% chance non-animated linear gradient
            if (random.next(0, 10) < 5) {
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3ClinearGradient id='gr' x1='",
                        x1.toString(),
                        "%25' y1='",
                        y1.toString(),
                        "%25' x2='",
                        x2.toString(),
                        "%25' y2='"
                    )
                );
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        y2.toString(),
                        "%25'%3E",
                        "%3Cstop offset='0%25' stop-color='",
                        config.colors[0],
                        "'/%3E",
                        "%3Cstop offset='100%25' stop-color='",
                        config.colors[1],
                        "'/%3E",
                        '%3C/linearGradient%3E'
                    )
                );
            } else {
                // else animated linear
                string memory animation = random.next(10000, 20000).toString();
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3ClinearGradient id='gr' x1='",
                        x1.toString(),
                        "%25' y1='",
                        y1.toString(),
                        "%25' x2='",
                        x2.toString(),
                        "%25' y2='"
                    )
                );
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        y2.toString(),
                        "%25'%3E%3Cstop offset='0%25' stop-color='",
                        config.colors[0],
                        "'%3E",
                        "%3Canimate attributeName='stop-color' dur='",
                        animation,
                        "ms' values='",
                        config.colors[0],
                        ';',
                        config.colors[1],
                        ';',
                        config.colors[0]
                    )
                );

                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "' repeatCount='indefinite'/%3E%3C/stop%3E%3Cstop offset='100%25' stop-color='",
                        config.colors[1],
                        "'%3E%3Canimate attributeName='stop-color' dur='",
                        animation,
                        "ms' values='",
                        config.colors[1],
                        ';',
                        config.colors[0],
                        ';',
                        config.colors[1],
                        "' repeatCount='indefinite'/%3E%3C/stop%3E%3C/linearGradient%3E"
                    )
                );
            }
        } else {
            // 50 % non-animated radial
            if (random.next(0, 10) < 5) {
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3CradialGradient id='gr' cx='",
                        (random.next(1, 4) * 25).toString(),
                        "%25' cy='",
                        (random.next(1, 4) * 25).toString(),
                        "%25'%3E%3Cstop offset='0%25' stop-color='",
                        config.colors[0],
                        "'/%3E%3Cstop offset='100%25' stop-color='",
                        config.colors[1],
                        "'/%3E%3C/radialGradient%3E"
                    )
                );
            } else {
                // animated radial gradient
                string memory animation = random.next(10000, 20000).toString();
                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "%3CradialGradient id='gr' cx='",
                        (random.next(1, 4) * 25).toString(),
                        "%25' cy='",
                        (random.next(1, 4) * 25).toString(),
                        "%25'%3E%3Cstop offset='0%25' stop-color='",
                        config.colors[0],
                        "' %3E%3Canimate attributeName='stop-color' dur='",
                        animation,
                        "ms' values='",
                        config.colors[0],
                        ';',
                        config.colors[1],
                        ';',
                        config.colors[0]
                    )
                );

                DynamicBuffer.appendBytes(
                    buffer,
                    abi.encodePacked(
                        "' repeatCount='indefinite'/%3E%3C/stop%3E%3Cstop offset='100%25' stop-color='",
                        config.colors[1],
                        "'%3E%3Canimate attributeName='stop-color' dur='",
                        animation,
                        "ms' values='",
                        config.colors[1],
                        ';',
                        config.colors[0],
                        ';',
                        config.colors[1],
                        "' repeatCount='indefinite'/%3E%3C/stop%3E%3C/radialGradient%3E"
                    )
                );
            }
        }
    }

    function _getColors(uint256 colorSeed, bool darkTheme)
        public
        pure
        returns (bytes9[2] memory)
    {
        string[14] memory colors;
        if (!darkTheme) {
            colors = [
                '%236a2c70',
                '%233f72af',
                '%23b83b5e',
                '%23112d4e',
                '%23a82ffc',
                '%23212121',
                '%23004a7c',
                '%233a0088',
                '%23364f6b',
                '%2353354a',
                '%23903749',
                '%232b2e4a',
                '%236639a6',
                '%23000000'
            ];
        } else {
            colors = [
                '%233fc1c9',
                '%23ffd3b5',
                '%23f9f7f7',
                '%23d6c8ff',
                '%2300bbf0',
                '%23ffde7d',
                '%23f6416c',
                '%23ff99fe',
                '%231891ac',
                '%23f8f3d4',
                '%2300b8a9',
                '%23f9ffea',
                '%23ff2e63',
                '%23ffffff'
            ];
        }

        // make sure to have different colors
        uint256 length = colors.length;
        uint256 index1 = colorSeed % length;
        uint256 index2 = (index1 +
            1 +
            (uint256(keccak256(abi.encode(colorSeed))) % (length - 1))) %
            length;

        return [bytes9(bytes(colors[index1])), bytes9(bytes(colors[index2]))];
    }

    function _getDateTime() internal view returns (string memory) {
        uint256 chainId = block.chainid;

        address bokky;
        if (chainId == 1) {
            bokky = address(0x23d23d8F243e57d0b924bff3A3191078Af325101);
        } else if (chainId == 4) {
            bokky = address(0x047C6386C30E785F7a8fd536945410802a605395);
        }

        if (address(0) != bokky) {
            (
                uint256 year,
                uint256 month,
                uint256 day,
                uint256 hour,
                uint256 minute,
                uint256 second
            ) = IBokkyPooBahsDateTimeContract(bokky).timestampToDateTime(
                    block.timestamp
                );

            return
                string(
                    abi.encodePacked(
                        year.toString(),
                        '/',
                        month.toString(),
                        '/',
                        day.toString(),
                        ' ',
                        hour.toString(),
                        ':',
                        minute.toString(),
                        ':',
                        second.toString(),
                        ' UTC'
                    )
                );
        }

        return '';
    }
}

interface IBokkyPooBahsDateTimeContract {
    function timestampToDateTime(uint256 timestamp)
        external
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        );
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump)
///         this library is just putting together code created by David Huber
///         that you can find in https://etherscan.io/address/0x1ca15ccdd91b55cd617a48dc9eefb98cae224757#code
///         he gave me the authorization to put it together into a single library
/// @notice This library is used to allocate a big amount of memory and then always update the buffer content
///         without needing to reallocate memory. This allows to save a lot of gas when manipulating bytes/strings
/// @dev First, allocate memory. Then use DynamicBuffer.appendBytes(buffer, theBytes);
library DynamicBuffer {
    function allocate(uint256 capacity)
        internal
        pure
        returns (bytes memory container, bytes memory buffer)
    {
        assembly {
            // Get next-free memory address
            container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                let size := add(capacity, 0x40)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return (container, buffer);
    }

    /// @notice Appends data_ to buffer_, and update buffer_ length
    /// @param buffer_ the buffer to append the data to
    /// @param data_ the data to append
    function appendBytes(bytes memory buffer_, bytes memory data_)
        internal
        pure
    {
        assembly {
            let length := mload(data_)
            for {
                let data := add(data_, 32)
                let dataEnd := add(data, length)
                let buf := add(buffer_, add(mload(buffer_), 32))
            } lt(data, dataEnd) {
                data := add(data, 32)
                buf := add(buf, 32)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length.
                mstore(buf, mload(data))
            }

            // Update buffer length
            mstore(buffer_, add(mload(buffer_), length))
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// small library to randomize using (min, max, seed)
// all number returned are considered with 3 decimals
library Randomize {
    struct Random {
        uint256 seed;
    }

    /// @notice This function uses seed to return a pseudo random interger between [min and max[
    /// @param random the random seed
    /// @return the pseudo random number
    function next(Random memory random, uint256 min, uint256 max) internal pure returns (uint256) {
        random.seed ^= random.seed << 13;
        random.seed ^= random.seed >> 17;
        random.seed ^= random.seed << 5;
        return min + random.seed % (max - min);
    }
}