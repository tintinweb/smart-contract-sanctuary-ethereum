// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract FroggyFarm {
    string public constant SVG_HEADER =
        'data:image/svg+xml;utf8,<svg xmlns="http://www.w3.org/2000/svg" version="1.2" viewBox="0 0 24 24">';
    string public constant SVG_FOOTER = "</svg>";

    bytes public palette;
    mapping(uint8 => bytes) private assets;
    mapping(uint8 => string) private assetNames;
    
    mapping(uint64 => uint32) public composites;

    address internal deployer;
    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer.");
        _;
    }

    constructor() {
        deployer = msg.sender;
    }

    function setPalette(bytes memory _palette) external onlyDeployer {
        palette = _palette;
    }


    function composite(
        bytes1 index,
        bytes1 yr,
        bytes1 yg,
        bytes1 yb,
        bytes1 ya
    ) public view returns (bytes4 rgba) {
        uint256 x = uint256(uint8(index)) * 4;
        uint8 xAlpha = uint8(palette[x + 3]);
        /* if (xAlpha == 0xFF) {
            rgba = bytes4(
                uint32(
                    (uint256(uint8(palette[x])) << 24) |
                        (uint256(uint8(palette[x + 1])) << 16) |
                        (uint256(uint8(palette[x + 2])) << 8) |
                        xAlpha
                )
            );
        } else { */
            uint64 key = (uint64(uint8(palette[x])) << 56) |
                (uint64(uint8(palette[x + 1])) << 48) |
                (uint64(uint8(palette[x + 2])) << 40) |
                (uint64(xAlpha) << 32) |
                (uint64(uint8(yr)) << 24) |
                (uint64(uint8(yg)) << 16) |
                (uint64(uint8(yb)) << 8) |
                (uint64(uint8(ya)));
            rgba = bytes4(composites[key]);
        }
    


    function render(bytes memory assetIndex) external view returns (bytes memory) {
                bytes memory pixels = new bytes(2304);
                bytes memory a = assetIndex;
                uint256 n = a.length / 3;
                for (uint256 i = 0; i < n; i++) {
                    uint256[4] memory v = [
                        uint256(uint8(a[i * 3]) & 0xF0) >> 4, 
                        uint256(uint8(a[i * 3]) & 0xF),
                        uint256(uint8(a[i * 3 + 2]) & 0xF0) >> 4,
                        uint256(uint8(a[i * 3 + 2]) & 0xF)
                    ];
                    for (uint256 dx = 0; dx < 2; dx++) {
                        for (uint256 dy = 0; dy < 2; dy++) {
                            uint256 p = ((2 * v[1] + dy) *  24 + (2 * v[0] + dx)) * 4;

                            //if last byte isn't 0, indicating more pixels
                            if (v[2] & (1 << (dx * 2 + dy)) != 0) {
                                bytes4 c = composite(
                                    a[i * 3 + 1],
                                    pixels[p],
                                    pixels[p + 1],
                                    pixels[p + 2],
                                    pixels[p + 3]
                                );
                                pixels[p] = c[0];
                                pixels[p + 1] = c[1];
                                pixels[p + 2] = c[2];
                                pixels[p + 3] = c[3];
                            } else if (v[3] & (1 << (dx * 2 + dy)) != 0) {
                                pixels[p] = 0;
                                pixels[p + 1] = 0;
                                pixels[p + 2] = 0;
                                pixels[p + 3] = 0xFF;
                            }
                        }
                    }
                }
            
        
        return pixels;
    }



    //// String stuff from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) public pure returns (string memory) {
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