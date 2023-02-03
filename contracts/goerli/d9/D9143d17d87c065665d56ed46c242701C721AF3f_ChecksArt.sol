//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./EightyColors.sol";
import "./IChecks.sol";
import "./Utilities.sol";

/**

 /////////   VV CHECKS   /////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////   DONT TRUST, CHECK   /////

@title  ChecksArt
@author VisualizeValue
@notice Renders the Checks visuals.
*/
library ChecksArt {

    /// @dev The path for a 20x20 px check based on a 36x36 px frame.
    string public constant CHECKS_PATH = 'M21.36 9.886A3.933 3.933 0 0 0 18 8c-1.423 0-2.67.755-3.36 1.887a3.935 3.935 0 0 0-4.753 4.753A3.933 3.933 0 0 0 8 18c0 1.423.755 2.669 1.886 3.36a3.935 3.935 0 0 0 4.753 4.753 3.933 3.933 0 0 0 4.863 1.59 3.953 3.953 0 0 0 1.858-1.589 3.935 3.935 0 0 0 4.753-4.754A3.933 3.933 0 0 0 28 18a3.933 3.933 0 0 0-1.887-3.36 3.934 3.934 0 0 0-1.042-3.711 3.934 3.934 0 0 0-3.71-1.043Zm-3.958 11.713 4.562-6.844c.566-.846-.751-1.724-1.316-.878l-4.026 6.043-1.371-1.368c-.717-.722-1.836.396-1.116 1.116l2.17 2.15a.788.788 0 0 0 1.097-.22Z';

    /// @dev The semiperfect divisors of the 80 checks.
    function DIVISORS() public pure returns (uint8[8] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1, 0 ];
    }

    /// @dev The different color band sizes that we use for the art.
    function COLOR_BANDS() public pure returns (uint8[7] memory) {
        return [ 80, 40, 20, 10, 5, 4, 1 ];
    }

    /// @dev The gradient increment steps.
    function GRADIENTS() public pure returns (uint8[7] memory) {
        return [ 0, 1, 2, 5, 8, 9, 10 ];
    }

    /// @dev Load a check from storage and fill its current state settings.
    /// @param tokenId The id of the check to fetch.
    /// @param checks The DB containing all checks.
    function getCheck(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (IChecks.Check memory check) {
        IChecks.StoredCheck memory stored = checks.all[tokenId];
        uint8 divisorIndex = stored.divisorIndex;

        check.stored = stored;
        check.hasManyChecks = divisorIndex < 6;
        check.checksCount = DIVISORS()[divisorIndex];
        check.composite = divisorIndex > 0 && divisorIndex < 7 ? stored.composites[divisorIndex - 1] : 0;
        check.colorBand = check.hasManyChecks ? COLOR_BANDS()[stored.colorBands[divisorIndex]] : 1;
        check.gradient  = check.hasManyChecks ? GRADIENTS()[stored.gradients[divisorIndex]] : 0;
        check.direction = uint8(stored.animation % 2);
        check.speed = uint8(2**(stored.animation % 3));
    }

    /// @dev Generate indexes for the color slots of check parents (up to the EightyColors.COLORS themselves).
    /// @param divisorIndex The current divisorIndex to query.
    /// @param check The current check to investigate.
    /// @param checks The DB containing all checks.
    function colorIndexes(
        uint8 divisorIndex, IChecks.Check memory check, IChecks.Checks storage checks
    )
        public view returns (uint256[] memory)
    {
        uint8[8] memory divisors = DIVISORS();
        uint256 checksCount = divisors[divisorIndex];
        uint32 seed = check.stored.seed;
        uint8 gradient = check.gradient;
        uint8 colorBand = check.colorBand;

        // If we're a composited check, we choose colors only based on
        // the slots available in our parents. Otherwise,
        // we choose based on our available spectrum.
        uint256 possibleColorChoices = divisorIndex > 0
            ? divisors[divisorIndex - 1] * 2
            : 80;

        // We initialize our index and select the first color
        uint256[] memory indexes = new uint256[](checksCount);
        indexes[0] = Utils.random(seed, possibleColorChoices - 1);

        // If we have more than one check, continue selecting colors
        if (check.hasManyChecks) {
            if (gradient > 0) {
                // If we're a gradient check, we select based on the color band looping around
                // the 80 possible colors
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / checksCount) % colorBand) % 80;
                    unchecked { ++i; }
                }
            } else if (divisorIndex == 0) {
                // If we select initial non gradient colors, we just take random ones
                // available in our color band
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + Utils.random(seed + i, colorBand)) % 80;
                    unchecked { ++i; }
                }
            } else {
                // If we have parent checks, we select our colors from their set
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = Utils.random(seed + i, possibleColorChoices - 1);
                    unchecked { ++i; }
                }
            }
        }

        // We resolve our color indexes through our parent tree until we reach the root checks
        if (divisorIndex > 0) {
            uint8 previousDivisor = divisorIndex - 1;

            // We already have our current check, but need the our parent state color indices
            uint256[] memory parentIndexes = colorIndexes(previousDivisor, check, checks);

            // We also need to fetch the colors of the check that was composited into us
            IChecks.Check memory composited = getCheck(check.composite, checks);
            uint256[] memory compositedIndexes = colorIndexes(previousDivisor, composited, checks);

            // Replace random indices with parent / root color indices
            uint8 count = divisors[previousDivisor];

            // We always select the first color from our parent
            uint256 initialBranchIndex = indexes[0] % count;
            indexes[0] = indexes[0] < count
                ? parentIndexes[initialBranchIndex]
                : compositedIndexes[initialBranchIndex];

            // If we don't have a gradient, we continue resolving from our parent for the remaining checks
            if (gradient == 0) {
                for (uint256 i; i < checksCount;) {
                    uint256 branchIndex = indexes[i] % count;
                    indexes[i] = indexes[i] < count
                        ? parentIndexes[branchIndex]
                        : compositedIndexes[branchIndex];

                    unchecked { ++i; }
                }
            // If we have a gradient we base the remaining colors off our initial selection
            } else {
                for (uint256 i = 1; i < checksCount;) {
                    indexes[i] = (indexes[0] + (i * gradient * colorBand / checksCount) % colorBand) % 80;

                    unchecked { ++i; }
                }
            }
        }

        return indexes;
    }

    /// @dev Fetch all colors of a given Check.
    /// @param check The check to get colors for.
    /// @param checks The DB containing all checks.
    function colors(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (string[] memory, uint256[] memory) {
        // A fully composited check has no color.
        if (check.stored.divisorIndex == 7) {
            string[] memory zeroColors = new string[](1);
            uint256[] memory zeroIndexes = new uint256[](1);
            zeroColors[0] = '000';
            zeroIndexes[0] = 999;
            return (zeroColors, zeroIndexes);
        }

        // Fetch the indices on the original color mapping.
        uint256[] memory indexes = colorIndexes(check.stored.divisorIndex, check, checks);

        // Map over to get the colors.
        string[] memory checkColors = new string[](indexes.length);
        string[80] memory allColors = EightyColors.COLORS();

        // Always set the first color.
        checkColors[0] = allColors[indexes[0]];

        // Resolve each color via their index in EightyColors.COLORS.
        for (uint256 i = 1; i < indexes.length; i++) {
            checkColors[i] = allColors[indexes[i]];
        }

        return (checkColors, indexes);
    }

    /// @dev Get the number of checks we should display per row.
    /// @param checks The number of checks in the piece.
    function perRow(uint8 checks) public pure returns (uint8) {
        return checks == 80
            ? 8
            : checks >= 20
                ? 4
                : checks == 10 || checks == 4
                    ? 2
                    : 1;
    }

    /// @dev Get the X-offset for positioning checks horizontally.
    /// @param checks The number of checks in the piece.
    function rowX(uint8 checks) public pure returns (uint16) {
        return checks <= 1
            ? 286
            : checks == 5
                ? 304
                : checks == 10 || checks == 4
                    ? 268
                    : 196;
    }

    /// @dev Get the Y-offset for positioning checks vertically.
    /// @param checks The number of checks in the piece.
    function rowY(uint8 checks) public pure returns (uint16) {
        return checks > 4
            ? 160
            : checks == 4
                ? 268
                : checks > 1
                    ? 304
                    : 286;
    }

    /// @dev Get the animation SVG snipped for an individual check of a piece.
    /// @param data The data object containing rendering settings.
    /// @param offset The index position of the check in question.
    /// @param allColors All available colors.
    function fillAnimation(
        CheckRenderData memory data,
        uint256 offset,
        string[80] memory allColors
    ) public pure returns (bytes memory)
    {
        if (data.isBlack) {
            return '';
        }

        // We only pick 20 colors from our gradient to reduce execution time.
        uint8 count = 20;

        bytes memory values;

        // Reverse loop through our color gradient.
        if (data.check.direction == 0) {
            for (uint256 i = offset + 80; i > offset;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i-=4; }
            }
        // Forward loop through our color gradient.
        } else {
            for (uint256 i = offset; i < offset + 80;) {
                values = abi.encodePacked(values, '#', allColors[i % 80], ';');
                unchecked { i+=4; }
            }
        }

        // Add initial color as last one for smooth animations.
        values = abi.encodePacked(values, '#', allColors[offset]);

        // Render the SVG snipped for the animation
        return abi.encodePacked(
            '<animate ',
                'attributeName="fill" values="',values,'" ',
                'dur="',Utils.uint2str(count * 2 / data.check.speed),'s" begin="animation.begin" ',
                'repeatCount="indefinite" ',
            '/>'
        );
    }

    /// @dev Generate the SVG code for all checks in a given token.
    /// @param data The data object containing rendering settings.
    function generateChecks(CheckRenderData memory data) public pure returns (bytes memory) {
        bytes memory checksBytes;
        string[80] memory allColors = EightyColors.COLORS();

        uint8 checksCount = data.count;
        for (uint8 i; i < checksCount; i++) {
            // Compute row settings.
            data.indexInRow = i % data.perRow;
            data.isNewRow = data.indexInRow == 0 && i > 0;

            // Compute offsets.
            if (data.isNewRow) data.rowY += data.spaceY;
            if (data.isNewRow && data.indent) {
                if (i == 0) {
                    data.rowX += data.spaceX / 2;
                }

                if (i % (data.perRow * 2) == 0) {
                    data.rowX -= data.spaceX / 2;
                } else {
                    data.rowX += data.spaceX / 2;
                }
            }
            string memory translateX = Utils.uint2str(data.rowX + data.indexInRow * data.spaceX);
            string memory translateY = Utils.uint2str(data.rowY);

            // Render the current check.
            checksBytes = abi.encodePacked(checksBytes, abi.encodePacked(
                '<g transform="translate(', translateX, ', ', translateY, ') scale(', data.scale, ')">',
                    '<use href="#check" fill="#', data.colors[i], '">',
                        fillAnimation(data, data.colorIndexes[i], allColors),
                    '</use>'
                '</g>'
            ));
        }

        return checksBytes;
    }

    /// @dev Collect relevant rendering data for easy access across functions.
    /// @param check Our current check loaded from storage.
    /// @param checks The DB containing all checks.
    function collectRenderData(
        IChecks.Check memory check, IChecks.Checks storage checks
    ) public view returns (CheckRenderData memory data) {
        // Carry through base settings.
        data.check = check;
        data.isBlack = check.stored.divisorIndex == 7;
        data.count = data.isBlack ? 1 : DIVISORS()[check.stored.divisorIndex];

        // Compute colors and indexes.
        (string[] memory colors_, uint256[] memory colorIndexes_) = colors(check, checks);
        data.colorIndexes = colorIndexes_;
        data.colors = colors_;
        data.gridColor = data.isBlack ? '#F2F2F2' : '#191919';
        data.canvasColor = data.isBlack ? '#FFF' : '#111';

        // Compute positioning data.
        data.scale = data.count > 20 ? '1' : data.count > 1 ? '2' : '3';
        data.spaceX = data.count == 80 ? 36 : 72;
        data.spaceY = data.count > 20 ? 36 : 72;
        data.perRow = perRow(data.count);
        data.indent = data.count == 40;
        data.rowX = rowX(data.count);
        data.rowY = rowY(data.count);
    }

    /// @dev Generate the SVG code for rows in the 8x10 Checks grid.
    function generateGridRow() public pure returns (bytes memory) {
        bytes memory row;
        for (uint256 i; i < 8; i++) {
            row = abi.encodePacked(
                row,
                '<use href="#square" x="', Utils.uint2str(196 + i*36), '" y="160"/>'
            );
        }
        return row;
    }

    /// @dev Generate the SVG code for the entire 8x10 Checks grid.
    function generateGrid() public pure returns (bytes memory) {
        bytes memory grid;
        for (uint256 i; i < 10; i++) {
            grid = abi.encodePacked(
                grid,
                '<use href="#row" y="', Utils.uint2str(i*36), '"/>'
            );
        }

        return abi.encodePacked('<g id="grid" x="196" y="160">', grid, '</g>');
    }

    /// @dev Generate the complete SVG code for a given Check.
    /// @param tokenId The ID of the token to render.
    /// @param checks The DB containing all checks.
    function generateSVG(
        uint256 tokenId, IChecks.Checks storage checks
    ) public view returns (bytes memory) {
        CheckRenderData memory data = collectRenderData(getCheck(tokenId, checks), checks);

        return abi.encodePacked(
            '<svg ',
                'viewBox="0 0 680 680" ',
                'fill="none" xmlns="http://www.w3.org/2000/svg" ',
                'style="width:100%;background:black;overflow:hidden;"',
            '>',
                '<defs>',
                    '<path id="check" fill-rule="evenodd" d="', CHECKS_PATH, '"></path>',
                    '<rect id="square" width="36" height="36" stroke="', data.gridColor, '"></rect>',
                    '<g id="row">', generateGridRow(), '</g>'
                '</defs>',
                '<rect width="680" height="680" fill="black"/>',
                '<rect x="188" y="152" width="304" height="376" fill="', data.canvasColor, '"/>',
                generateGrid(),
                generateChecks(data),
                '<rect width="680" height="680" fill="transparent">',
                    '<animate ',
                        'attributeName="width" ',
                        'from="680" ',
                        'to="0" ',
                        'dur="0.2s" ',
                        'begin="click" ',
                        'fill="freeze" ',
                        'id="animation"',
                    '/>',
                '</rect>',
            '</svg>'
        );
    }
}

/// @dev Bag holding all data relevant for rendering.
struct CheckRenderData {
    IChecks.Check check;
    uint256[] colorIndexes;
    string[] colors;
    string canvasColor;
    string gridColor;
    string duration;
    string scale;
    uint32 seed;
    uint16 rowX;
    uint16 rowY;
    uint8 count;
    uint8 spaceX;
    uint8 spaceY;
    uint8 perRow;
    uint8 indexInRow;
    uint8 isIndented;
    bool indent;
    bool isNewRow;
    bool isBlack;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**

 /////////////////////////////////
 //                             //
 //                             //
 //                             //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //       ✓ ✓ ✓ ✓ ✓ ✓ ✓ ✓       //
 //                             //
 //                             //
 //                             //
 /////////////////////////////////

@title  EightyColors
@author VisualizeValue
@notice The eighty colors of Checks.
*/
library EightyColors {

    /// @dev Theese are sorted in a gradient.
    function COLORS() public pure returns (string[80] memory) {
        return [
            'E84AA9',
            'F2399D',
            'DB2F96',
            'E73E85',
            'FF7F8E',
            'FA5B67',
            'E8424E',
            'D5332F',
            'C23532',
            'F2281C',
            'D41515',
            '9D262F',
            'DE3237',
            'DA3321',
            'EA3A2D',
            'EB4429',
            'EC7368',
            'FF8079',
            'FF9193',
            'EA5B33',
            'D05C35',
            'ED7C30',
            'EF9933',
            'EF8C37',
            'F18930',
            'F09837',
            'F9A45C',
            'F2A43A',
            'F2A840',
            'F2A93C',
            'FFB340',
            'F2B341',
            'FAD064',
            'F7CA57',
            'F6CB45',
            'FFAB00',
            'F4C44A',
            'FCDE5B',
            'F9DA4D',
            'F9DA4A',
            'FAE272',
            'F9DB49',
            'FAE663',
            'FBEA5B',
            'A7CA45',
            'B5F13B',
            '94E337',
            '63C23C',
            '86E48E',
            '77E39F',
            '5FCD8C',
            '83F1AE',
            '9DEFBF',
            '2E9D9A',
            '3EB8A1',
            '5FC9BF',
            '77D3DE',
            '6AD1DE',
            '5ABAD3',
            '4291A8',
            '33758D',
            '45B2D3',
            '81D1EC',
            'A7DDF9',
            '9AD9FB',
            'A4C8EE',
            '60B1F4',
            '2480BD',
            '4576D0',
            '3263D0',
            '2E4985',
            '25438C',
            '525EAA',
            '3D43B3',
            '322F92',
            '4A2387',
            '371471',
            '3B088C',
            '6C31D7',
            '9741DA'
        ];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IChecks {

    struct StoredCheck {
        uint32 seed;            // The seed is based the mint and enables pseudo-randomisation
        uint16[6] composites;  // The tokenIds that were composited into this one
        uint8[6] colorBands;  // The length of the used color band in percent
        uint8[6] gradients;  // Gradient settings for each generation
        uint8 divisorIndex; // Easy access to next / previous divisor
        uint8 animation;   // Animation seed
    }

    struct Check {
        StoredCheck stored;
        uint16 composite;     // The parent tokenId that was composited into this one
        bool hasManyChecks;  // Quick access for whether the check has many checks
        uint8 checksCount;  // How many checks this token has
        uint8 colorBand;   // 100%, 50%, 25%, 12.5%, 6.25%, 5%, 1.25%
        uint8 gradient;   // Linearly through the colorBand [1, 2, 3]
        uint8 direction; // Animation direction
        uint8 speed;    // Animation speed
    }

    struct Checks {
        uint32 minted;
        uint32 burned;
        mapping(uint256 => StoredCheck) all;
    }

    event Sacrifice(
        uint256 indexed burnedId,
        uint256 indexed tokenId
    );

    event Composite(
        uint256 indexed tokenId,
        uint256 indexed burnedId,
        uint8 indexed checks
    );

    event Infinity(
        uint256 indexed tokenId,
        uint256[] indexed burnedIds
    );

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Utils {
    /// @dev Create a pseudo random number
    function seed(uint256 nonce) public view returns (uint256) {
        return uint256(
            keccak256(abi.encodePacked(msg.sender, block.coinbase, nonce))
        );
    }

    /// @dev Pseudorandom number based on input max bound
    function random(uint256 input, uint256 max) public pure returns (uint256) {
        return max - (uint256(keccak256(abi.encodePacked(input))) % max);
    }

    /// @dev Convert an integer to a string
    function uint2str(uint256 _i) public pure returns (string memory _uintAsString) {
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

    /// @dev Get the smallest non zero number
    function minGt0(uint8 one, uint8 two) public pure returns (uint8) {
        return one > two
            ? two > 0
                ? two
                : one
            : two;
    }

    /// @dev Get the smallest number
    function min(uint8 one, uint8 two) public pure returns (uint8) {
        return one < two ? one : two;
    }

    /// @dev Get the average between two numbers
    function avg(uint8 one, uint8 two) public pure returns (uint8) {
        return (one & two) + (one ^ two) / 2;
    }
}