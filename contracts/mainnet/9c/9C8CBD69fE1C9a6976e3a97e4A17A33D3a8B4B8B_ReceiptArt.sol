// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IReceiptArt {
    struct TxContext {
        uint256 value;
        uint256 gas;
        uint256 timestamp;
        address from;
    }

    struct TransferContext {
        string datetime;
        address from;
    }

    function linesCount(uint256 _value) external pure returns (uint256);

    function timestampToString(uint256 _timestamp)
        external
        view
        returns (string memory, string memory);

    function tokenSVG(
        TxContext memory _txContext,
        TransferContext[] memory _transfers,
        uint256 _tokenId
    ) external view returns (string memory);

    function weiToEtherStr(uint256 _wei) external pure returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "./IReceiptArt.sol";

interface IFont {
    function font() external view returns (string memory);
}

interface IDateTime {
    function timestampToDateTime(uint256)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );
}

contract ReceiptArt is IReceiptArt {
    struct SVGContext {
        string[3] borders;
        string[6] body;
        string turbulence;
        string color;
        TxContext txContext;
    }

    uint256 private constant _maxTransferDisplay = 100;
    IFont private font;
    IFont private barcode;
    IDateTime private datetime;

    constructor(
        address _fontAddress,
        address _barcodeAddress,
        address _datetimeAddress
    ) {
        font = IFont(_fontAddress);
        barcode = IFont(_barcodeAddress);
        datetime = IDateTime(_datetimeAddress);
    }

    /* draw */

    function t(
        uint256 _x,
        uint256 _y,
        string memory _c,
        string memory _t
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<text x='",
                    Strings.toString(_x),
                    "' y='",
                    Strings.toString(_y),
                    "' class='",
                    _c,
                    "'>",
                    _t,
                    "</text>"
                )
            );
    }

    function feTurbulence(
        string memory _type,
        string memory _frequency,
        string memory _octaves,
        string memory _seed
    ) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<feTurbulence type='",
                    _type,
                    "' baseFrequency='",
                    _frequency,
                    "' result='noise' numOctaves='",
                    _octaves,
                    "' seed='",
                    _seed,
                    "'/>"
                )
            );
    }

    function feDisplacementMap(string memory _scale) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "<feDisplacementMap in2='noise' in='SourceGraphic' scale='",
                    _scale,
                    "' xChannelSelector='R' yChannelSelector='G'/>"
                )
            );
    }

    function barcodeStr(uint256 _int) private pure returns (string memory) {
        if (_int > 99_999_999_999) {
            return "99999999999";
        }
        string memory res = Strings.toString(_int);
        uint256 diff = 11 - bytes(res).length;
        for (uint256 i; i < diff; i++) {
            res = string(bytes.concat(bytes1("0"), bytes(res)));
        }
        return res;
    }

    function svgBody(TxContext memory _txContext, uint256 _tokenId)
        private
        view
        returns (string memory)
    {
        SVGContext memory ctx;
        ctx.borders[0] = "***************";
        ctx.borders[1] = "------------------------------------";
        ctx.borders[2] = "====================================";

        {
            ctx.body[0] = string(
                abi.encodePacked(
                    t(100, 30, "f m", ctx.borders[0]),
                    t(100, 41, "f m fb", "RECEIPT"),
                    t(100, 55, "f m", ctx.borders[0])
                )
            );
        }
        {
            ctx.body[1] = string(
                abi.encodePacked(
                    t(100, 62, "m", "MADE BY"),
                    t(100, 74, "m", Strings.toHexString(_txContext.from))
                )
            );
        }
        {
            (string memory day, string memory time) = timestampToString(_txContext.timestamp);
            ctx.body[2] = string(
                abi.encodePacked(
                    t(15, 100, "s", day),
                    t(185, 100, "e", time),
                    t(100, 110, "f2 m", ctx.borders[1])
                )
            );
        }
        {
            ctx.body[3] = string(
                abi.encodePacked(
                    t(15, 130, "s", "Value"),
                    t(
                        185,
                        130,
                        "e",
                        string(abi.encodePacked(unicode"Ξ", weiToEtherStr(_txContext.value)))
                    ),
                    t(15, 140, "s", "Transaction Fee"),
                    t(
                        185,
                        140,
                        "e",
                        string(abi.encodePacked(unicode"Ξ", weiToEtherStr(_txContext.gas)))
                    )
                )
            );
        }
        {
            ctx.body[4] = string(
                abi.encodePacked(
                    t(100, 150, "f2 m", ctx.borders[1]),
                    t(15, 160, "f2 s", "Total"),
                    t(
                        185,
                        160,
                        "f2 e",
                        string(
                            abi.encodePacked(
                                unicode"Ξ",
                                weiToEtherStr(_txContext.value + _txContext.gas)
                            )
                        )
                    )
                )
            );
        }
        {
            ctx.body[5] = string(
                abi.encodePacked(
                    t(100, 190, "f2 m", ctx.borders[2]),
                    t(100, 210, "f m", "THANK YOU"),
                    t(100, 230, "f2 m", ctx.borders[2])
                )
            );
        }
        return
            string(
                abi.encodePacked(
                    ctx.body[0],
                    ctx.body[1],
                    ctx.body[2],
                    ctx.body[3],
                    ctx.body[4],
                    ctx.body[5],
                    t(100, 255, "bcd m", string(abi.encodePacked("*", barcodeStr(_tokenId), "*"))),
                    t(100, 265, "m f2", barcodeStr(_tokenId))
                )
            );
    }

    function svgStyle(TxContext memory _txContext) private view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked("color", _txContext.value)));
        uint256 rtype = rand % 3;
        rand = uint256(keccak256(abi.encodePacked(rand)));
        string memory rfilter = string(
            abi.encodePacked(
                "hsl(",
                Strings.toString(rand % 361),
                ",100%,",
                Strings.toString(rtype == 1 ? 10 + (rand % 19) : 50 + (rand % 11)),
                "%)"
            )
        );
        rand = uint256(keccak256(abi.encodePacked(rand)));
        rfilter = rand % 3 == 0 ? "#ffffff00" : rfilter;

        return
            string(
                abi.encodePacked(
                    "<style>@font-face {font-family:'RCPT';font-display:block;src:url(",
                    font.font(),
                    ") format('woff2');}@font-face {font-family:'BARCODE';font-display:block;src:url(",
                    barcode.font(),
                    ") format('woff2');}",
                    "*{font-family:'RCPT',monospace}.bcd{font-family:'BARCODE';font-size:26px}*{font-size:6px;padding:0;margin:0}.f{font-size:12px}.f2{font-size:8px}.fb{stroke-width:1;stroke:#1a1a1a}.flb{stroke-width:0.3;stroke:#1a1a1a}",
                    ".w{x:0;y:0;width:100%;height:100%}.s{text-anchor:start}.e{text-anchor:end}.m{text-anchor:middle}",
                    ".n{filter:url(#f2);mix-blend-mode:luminosity;opacity:0.55}.n2{filter:url(#f4);mix-blend-mode:color-dodge;opacity:0.3}.g{fill:url(#g);mix-blend-mode:soft-light;opacity:0.5}",
                    ".c{mix-blend-mode:",
                    ["multiply", "difference", "color"][rtype],
                    ";fill:",
                    rfilter,
                    "}.b{fill:#c3c3c3}</style>"
                )
            );
    }

    function svgFilters(string memory _seed) private pure returns (string memory) {
        string memory turbulence = feTurbulence("turbulence", "0.004 0.02", "3", _seed);
        return
            string(
                abi.encodePacked(
                    "<filter id='f1'>",
                    turbulence,
                    feDisplacementMap("4"),
                    "</filter><filter id='f2'>",
                    turbulence,
                    "</filter><filter id='f3'><feGaussianBlur in='SourceGraphic' stdDeviation='1 2'/></filter><filter id='f4'>",
                    feTurbulence("turbulence", "0.4 0.6", "2", _seed),
                    "<feDiffuseLighting in='noise' lighting-color='#fff' surfaceScale='30'><feDistantLight azimuth='45' elevation='40'/></feDiffuseLighting></filter><filter id='f5'>",
                    feTurbulence("fractalNoise", "0.5 0.005", "3", _seed),
                    feDisplacementMap("500"),
                    "</filter>"
                )
            );
    }

    function transferBody(TransferContext[] memory _transfers)
        private
        pure
        returns (string memory)
    {
        string memory ext;
        uint256 diff;
        string memory txTop;
        string memory txBottom;
        for (
            uint256 i = _transfers.length > _maxTransferDisplay
                ? _transfers.length - _maxTransferDisplay
                : 0;
            i < _transfers.length;
            i++
        ) {
            {
                txTop = string(
                    abi.encodePacked(
                        t(
                            15,
                            290 + diff,
                            "s flb",
                            string(abi.encodePacked("Transfer [", Strings.toString(i + 1), "]"))
                        ),
                        t(185, 290 + diff, "e", _transfers[i].datetime)
                    )
                );
            }
            {
                txBottom = string(
                    abi.encodePacked(
                        t(15, 300 + diff, "s", "To"),
                        t(185, 300 + diff, "e", Strings.toHexString(_transfers[i].from))
                    )
                );
            }
            ext = string(abi.encodePacked(ext, txTop, txBottom));
            diff += 20;
        }
        return ext;
    }

    function linesCount(uint256 _value) public pure returns (uint256) {
        uint256[7] memory count = [uint256(0), 0, 0, 0, 0, 1, 2];
        return count[uint256(keccak256(abi.encodePacked("line", _value))) % count.length];
    }

    function endLine(TxContext memory _txContext, uint256 _index)
        private
        pure
        returns (string memory)
    {
        uint256 c = linesCount(_txContext.value);
        if (c == 0) return "";
        if (c == 1 && _index == 1) return "";
        string memory tr = string(
            abi.encodePacked(
                "translate(",
                _index == 1 ? "-" : "",
                Strings.toString(
                    uint256(keccak256(abi.encodePacked("lp", _txContext.value, _index))) % 31
                ),
                ",-30) rotate(",
                zeroCenteredString(
                    uint256(keccak256(abi.encodePacked("lr", _txContext.value, _index))) % 17,
                    8
                ),
                ")"
            )
        );
        return
            string(
                abi.encodePacked(
                    "<rect transform='",
                    tr,
                    "' opacity='0.4' fill='red' height='100%' width='20' x='",
                    _index == 0 ? "-7" : "185",
                    "' y='0' style='mix-blend-mode:color-burn'/>"
                )
            );
    }

    // e.g. (10, 5) => "5", (2, 5) => "-3"
    function zeroCenteredString(uint256 _value, uint256 _max) private pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _value < _max ? "-" : "",
                    Strings.toString(_value < _max ? _max - _value : _value - _max)
                )
            );
    }

    function tokenSVG(
        TxContext memory _txContext,
        TransferContext[] memory _transfers,
        uint256 _tokenId
    ) external view returns (string memory) {
        uint256 height = 300 +
            20 *
            (_transfers.length > _maxTransferDisplay ? _maxTransferDisplay : _transfers.length);
        if (_transfers.length > 0) {
            height += 20;
        }
        string memory heightStr = Strings.toString(height);
        string memory canvasHeightStr = Strings.toString(height + 100);

        return
            string(
                abi.encodePacked(
                    "<svg viewBox='0 0 300 ",
                    canvasHeightStr,
                    "' width='300' height='",
                    canvasHeightStr,
                    "' fill='#1a1a1a' preserveAspectRatio='xMidYMid meet' version='2' xmlns='http://www.w3.org/2000/svg'>",
                    svgStyle(_txContext),
                    svgFilters(
                        Strings.toString(
                            uint256(keccak256(abi.encodePacked("nseed", _txContext.value))) % 2000
                        )
                    ),
                    "<symbol id='p'><path d='M0,5 q1.5,2.5 3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t3,0 t2,0 l0,",
                    heightStr,
                    " q-1.5,-2.5 -3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 t-3,0 l0,-",
                    heightStr,
                    "' fill='#fdfdf9'/></symbol>",
                    "<radialGradient id='g' cx='20%' cy='20%' r='80%'><stop offset='0%' stop-color='#86b8db'/><stop offset='100%' stop-color='#000'/></radialGradient>",
                    "<mask id='m'><use href='#p'/></mask><clipPath id='o'><rect x='0' y='0' width='100%' height='100%'/></clipPath><rect class='w b'/><rect class='n2 w' clip-path='url(#o)'/>",
                    "<g transform='scale(1.01 1) translate(49,50)' filter='url(#f3)'><rect class='w' fill='black' style='opacity: 0.25' mask='url(#m)'/></g><g mask='url(#m)' transform='translate(50,50)'><use href='#p'/><g filter='url(#f1)'>",
                    svgBody(_txContext, _tokenId),
                    endLine(_txContext, 0),
                    endLine(_txContext, 1),
                    transferBody(_transfers),
                    "</g><rect filter='url(#f5)' fill='#fdfdf9' class='w' style='opacity:0.3;mix-blend-mode:screen'/><rect class='w c'/><rect class='n w'/></g><rect class='g w'/></svg>"
                )
            );
    }

    function weiToEtherStr(uint256 _wei) public pure returns (string memory) {
        uint256 afDecimal = 1000000000;
        uint256 afLength = 9;

        uint256 val = (_wei * afDecimal) / 1 ether;
        uint256 reg = val / afDecimal;
        uint256 dec = val % afDecimal;

        if (dec == 0) {
            return Strings.toString(reg);
        }

        string memory decStr = Strings.toString(dec);

        uint256 diff = afLength - bytes(decStr).length;
        for (uint256 i; i < diff; i++) {
            decStr = string(bytes.concat(bytes1("0"), bytes(decStr)));
        }

        bytes memory decBytes = bytes(decStr);

        uint256 head = afLength - 1;
        for (uint256 i; i < afLength; i++) {
            if (decBytes[afLength - 1 - i] != bytes1("0")) {
                break;
            }
            head--;
        }
        bytes memory c = new bytes(head + 1);
        for (uint256 i = 0; i < head + 1; i++) {
            c[i] = decBytes[i];
        }
        decStr = string(c);
        return string(abi.encodePacked(Strings.toString(reg), ".", decStr));
    }

    function timestampToString(uint256 _timestamp)
        public
        view
        returns (string memory, string memory)
    {
        (
            uint256 year,
            uint256 month,
            uint256 day,
            uint256 hour,
            uint256 minute,
            uint256 second
        ) = datetime.timestampToDateTime(_timestamp);

        return (
            string(
                abi.encodePacked(
                    day > 9 ? "" : "0",
                    Strings.toString(day),
                    "/",
                    month > 9 ? "" : "0",
                    Strings.toString(month),
                    "/",
                    Strings.toString(year)
                )
            ),
            string(
                abi.encodePacked(
                    hour > 9 ? "" : "0",
                    Strings.toString(hour),
                    ":",
                    minute > 9 ? "" : "0",
                    Strings.toString(minute),
                    ":",
                    second > 9 ? "" : "0",
                    Strings.toString(second)
                )
            )
        );
    }
}