/**
 *Submitted for verification at Etherscan.io on 2023-01-13
*/

/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.8.17;

contract CryptopunksData {
    string private constant SVG_HEADER = 'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 32 32" shape-rendering="crispEdges">';
    string private constant SVG_FOOTER = '</svg>';
    bytes16 private constant HEX_SYMBOLS = "0123456789abcdef";
    bytes private bgDefaultColor = "0x6AC3E6";
    bytes private bgAdditionalColor = "0xD4D4D4";
    bytes private stickDefaultColor = "0xFFFFFF";
    bytes private stickAdditionalColor = "0xEBEBEB";

    mapping(uint256 => bytes) private flags;
    uint256 formDefaultStartKey;
    uint256 formDefaultKeysCount;
    mapping(uint256 => formRange) private formDefault;
    uint256 formSquareStartKey;
    uint256 formSquareKeysCount;
    mapping(uint256 => formRange) private formSquare;
    struct formRange {
        uint256 start;
        uint256 end;
    }

    struct decompressionParameters{
        uint8 paletteLength;
        bool isDefaultForm;
        bool isHorizontalCompression;
        bytes bgColor;
        bytes stickColor;
        uint256 formStartKey;
        uint256 formKeysCount;
    }

    constructor() public {
        formDefaultStartKey = 10;
        formDefaultKeysCount = 13;
        formDefault[10] = formRange(10, 18);
        formDefault[11] = formRange(11, 19);
        formDefault[12] = formRange(12, 20);
        formDefault[13] = formRange(12, 20);
        formDefault[14] = formRange(12, 20);
        formDefault[15] = formRange(12, 20);
        formDefault[16] = formRange(11, 19);
        formDefault[17] = formRange(10, 18);
        formDefault[18] = formRange(10, 18);
        formDefault[19] = formRange(10, 18);
        formDefault[20] = formRange(10, 18);
        formDefault[21] = formRange(10, 18);
        formDefault[22] = formRange(11, 19);

        formSquareStartKey = 11;
        formSquareKeysCount = 10;
        formSquare[11] = formRange(9, 18);
        formSquare[12] = formRange(10, 19);
        formSquare[13] = formRange(11, 20);
        formSquare[14] = formRange(11, 20);
        formSquare[15] = formRange(11, 20);
        formSquare[16] = formRange(10, 19);
        formSquare[17] = formRange(9, 18);
        formSquare[18] = formRange(9, 18);
        formSquare[19] = formRange(9, 18);
        formSquare[20] = formRange(10, 19);
    }

    function addFlag(uint256 index, bytes memory flag) public {
        flags[index] = flag;
    }

    function getFlagSvg(uint256 index) public view returns (string memory svg){
        svg = decompressImg(flags[index]);
    }

    function decompressImg(bytes storage data) private view returns (string memory svg) {
        decompressionParameters memory params = getConfigurations(data[0]);
        mapping(uint256 => formRange) storage form = params.isDefaultForm ? formDefault : formSquare;

        svg = SVG_HEADER;
        svg = string(abi.encodePacked(svg, getSvgBlock(0, 0, 32, 32, params.bgColor)));
        svg = string(abi.encodePacked(svg, getSvgBlock(params.formStartKey, form[params.formStartKey].end + 1, 1, 32 - (form[params.formStartKey].end + 1), params.stickColor)));

        uint256 interator = 0;
        for (uint8 colorDataIndex = 1 + params.paletteLength * 3; colorDataIndex < data.length; colorDataIndex++)
        {
            (bytes1 colorIndex, bytes1 repeats) = decompressToByte(data[colorDataIndex]);
            
            bytes memory color;
            color[0] = data[1 + uint8(colorIndex) * 3];
            color[1] = data[1 + uint8(colorIndex) * 3 + 1];
            color[2] = data[1 + uint8(colorIndex) * 3 + 2];

            for (uint8 repeat = 0; repeat < uint8(repeats); repeat++)
            {
                (uint256 column, uint256 row) = getFormPixelByIterator(params.isHorizontalCompression, params.formStartKey, params.formKeysCount, form, interator);
                interator++;
                svg = string(abi.encodePacked(svg, getSvgBlock(column, row, 1, 1, color)));
            }
        }
        
        svg = string(abi.encodePacked(svg, SVG_FOOTER));
    }

    function getConfigurations(bytes1 configByte) private view returns (decompressionParameters memory params){
        (bytes1 configs, bytes1 paletteLength) = decompressToByte(configByte);
        (bool isDefaultForm, bool isHorizontalCompression, bool isDefaultBg, bool isDefaultStick) = decompressToBools(configs);
        params = decompressionParameters(
            uint8(paletteLength),
            isDefaultForm,
            isHorizontalCompression,
            isDefaultBg ? bgDefaultColor : bgAdditionalColor,
            isDefaultStick ? stickDefaultColor : stickAdditionalColor,
            isDefaultForm ? formDefaultStartKey : formSquareStartKey,
            isDefaultForm ? formDefaultKeysCount : formSquareKeysCount
        );
    }

    function decompressToBools(bytes1 i) private pure returns (bool b1, bool b2, bool b3, bool b4) {
        b1 = ((uint8(i) & 0xF) >> 3) & 0x1 == 1;
        b2 = ((uint8(i) & 0xF) >> 2) & 0x1 == 1;
        b3 = ((uint8(i) & 0xF) >> 1) & 0x1 == 1;
        b4 = ((uint8(i) & 0xF) >> 0) & 0x1 == 1;
    }

    function decompressToByte(bytes1 i) private pure returns (bytes1 i1, bytes1 i2) {
        i1 = i >> 4;
        i2 = bytes1(uint8(i) & 0xF);
    }

    function getFormPixelByIterator(
        bool isHorizontal, 
        uint256 formStartIndex,
        uint256 columnsCount,
        mapping(uint256 => formRange) storage form, 
        uint256 iterator
        ) private view returns (uint256 column, uint256 row) {
        uint256 columnIndex = 0;
        uint256 rowIndex = 0;
        uint256 rowsCount = form[formStartIndex].end - form[formStartIndex].start + 1;

        if (isHorizontal) {
            columnIndex = iterator % columnsCount;
            rowIndex = iterator / columnsCount;
        } else {
            columnIndex = iterator / rowsCount;
            rowIndex = iterator % rowsCount;
        }

        column = formStartIndex + columnIndex;
        row = form[column].start + rowIndex;
    }

    function getSvgBlock(uint256 x, uint256 y, uint256 xSize, uint256 ySize, bytes memory color) private pure returns (string memory) {
        bytes memory buffer = new bytes(6);
        for (uint256 i = 0; i < 3; i++) {
            uint8 value = uint8(color[i]);
            buffer[i * 2 + 1] = HEX_SYMBOLS[value & 0xf];
            value >>= 4;
            buffer[i * 2] = HEX_SYMBOLS[value & 0xf];
        }

        return string(abi.encodePacked(
                        '<rect x="', toString(x), '" y="', toString(y),'" width="', toString(xSize), '" height="', toString(ySize) ,'" fill="#', string(buffer),'"/>'));
    }

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
}