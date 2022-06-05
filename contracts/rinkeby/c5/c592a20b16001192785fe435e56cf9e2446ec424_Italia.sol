// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib.sol";

contract Italia is ERC721Enumerable, ReentrancyGuard, Ownable {

    string[] private _stickers;

    // maps a tokenId to an array of stickerIds
    mapping(uint256 => uint256[]) private _tokenMapToStickerIds;

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory prefix = '<svg width="1000" height="1000" viewBox="0 0 1000 1000" fill="none" xmlns="http://www.w3.org/2000/svg">';
        string memory suffix = '</svg>';

        string memory stickerSVGs = prefix;

        uint256[] memory stickerIds = _tokenMapToStickerIds[tokenId];
        for (uint i=0; i < stickerIds.length; i++) {
            stickerSVGs = string.concat(stickerSVGs, _stickers[stickerIds[i]]);
        }

        stickerSVGs = string.concat(stickerSVGs, suffix);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "WE3+DREAM+Avara Italia', toString(tokenId), '", "description": "this is a description", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(stickerSVGs)), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function claim(uint256 tokenId) public nonReentrant {
        _safeMint(_msgSender(), tokenId);
    }
    
    function ownerClaim(uint256 tokenId) public nonReentrant onlyOwner {
        _safeMint(owner(), tokenId);
    }

    function addNewSticker(string calldata svgCode) public nonReentrant {
        _stickers.push(svgCode);
    }

    function addStickerToToken(uint256 stickerId, uint256 tokenId) public nonReentrant {
        _tokenMapToStickerIds[tokenId].push(stickerId);
    } 

    function getSticker(uint256 stickerId) public view returns (string memory) {
        return _stickers[stickerId];
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