// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib.sol";

contract Italia is ERC721Enumerable, ReentrancyGuard, Ownable {

    string[] private _stickersIndex;

    function tokenURI(uint256 tokenId) override public pure returns (string memory) {
        string[1] memory parts;
        parts[0] = '<svg width="124" height="36" viewBox="0 0 124 36" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M29.1765 0V7.2V14.4V21.6V28.8H21.8823V21.6V14.4V7.2H14.5882V14.4V21.6V28.8H7.29411V21.6V14.4V7.2V0H0V7.2V14.4V21.6V28.8V36H7.29411H14.5882H21.8823H29.1765H36.4706V28.8V21.6V14.4V7.2V0H29.1765Z" fill="black"/><path d="M80.2352 28.8H72.9411H65.647H58.3529H51.0588V21.6H58.3529H65.647H72.9411V14.4H65.647H58.3529H51.0588V7.2H58.3529H65.647H72.9411H80.2352V0H72.9411H65.647H58.3529H51.0588H43.7646V7.2V14.4V21.6V28.8V36H51.0588H58.3529H65.647H72.9411H80.2352V28.8Z" fill="black"/><path d="M87.5293 7.2H94.8234H102.118H109.412H116.706V14.4H109.412H102.118H94.8234V21.6H102.118H109.412H116.706V28.8H109.412H102.118H94.8234H87.5293V36H94.8234H102.118H109.412H116.706H124V28.8V21.6V14.4V7.2V0H116.706H109.412H102.118H94.8234H87.5293V7.2Z" fill="black"/></svg>';

        string memory output = string(abi.encodePacked(parts[0]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "WE3+DREAM+Avara Italia', toString(tokenId), '", "description": "this is a description", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        _safeMint(owner(), tokenId);
    }

    function addSticker(string calldata svgCode) public nonReentrant {
        _stickersIndex.push(svgCode);
    }

    function getSticker(uint256 stickerId) public view returns (string memory) {
        return _stickersIndex[stickerId];
    }
    
    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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
    
    constructor() ERC721("Italia", "ITAL") Ownable() {}
}