// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib.sol";

// TODO introduce soft delete to allow removal of sticker
struct StickerInstance {
    uint256 x;
    uint256 y;
    uint256 id;
    bool isDeleted;
}

contract Italia is ERC721Enumerable, ReentrancyGuard, Ownable {

    // Stickers are just an SVG
    string[] private _allStickers;

    // maps a tokenId to an array of stickerInstances
    mapping(uint256 => StickerInstance[]) public _tokenMapToStickerInstances;

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        string memory prefix = '<svg width="600" height="600" viewBox="0 0 600 600" fill="none" xmlns="http://www.w3.org/2000/svg"><rect width="600" height="600" fill="url(#paint0_radial_311_353)"/><rect x="53" y="232" width="493" height="308" rx="20" fill="#999999"/><defs><radialGradient id="paint0_radial_311_353" cx="0" cy="0" r="1" gradientUnits="userSpaceOnUse" gradientTransform="translate(300 -26.4999) rotate(91.5182) scale(490.672)"><stop stop-color="#2184DF"/><stop offset="1" stop-color="#EBB2DB"/></radialGradient></defs>';
        string memory suffix = '</svg>';

        string memory stickerSVGs = prefix;

        StickerInstance[] memory stickerInstances = _tokenMapToStickerInstances[tokenId];

        for (uint i=0; i < stickerInstances.length; i++) {
            StickerInstance memory sticker = stickerInstances[i];

            stickerSVGs = string.concat(stickerSVGs, '<!--', toString(i), '-->');
            
            if (!sticker.isDeleted) {
                stickerSVGs = string.concat(stickerSVGs, '<g transform="translate(', toString(sticker.x), ', ', toString(sticker.y), ')">');
                stickerSVGs = string.concat(stickerSVGs, _allStickers[sticker.id]);
                stickerSVGs = string.concat(stickerSVGs, '</g>');  
            }
        }

        stickerSVGs = string.concat(stickerSVGs, suffix);

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "Italia NFT", "description": "This is a description", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(stickerSVGs)), '"}'))));
        string memory output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    // TODO, just mint the next available
    function claim(uint256 tokenId) public nonReentrant {
        _safeMint(_msgSender(), tokenId);
    }

    function addNewSticker(string calldata svgCode) public nonReentrant {
        _allStickers.push(svgCode);
    }

    function addStickerToLaptop(
        uint256 stickerId, 
        uint256 x, 
        uint256 y, 
        uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "You're not the owner of this NFT");
        require(stickerId > 0, "Sticker 0 is special");

        _addStickerToToken(stickerId, x, y, tokenId);
    }

    function adminOnlyaddStickerToToken (
        uint256 stickerId, 
        uint256 x, 
        uint256 y, 
        uint256 tokenId) public onlyOwner {

        _addStickerToToken(stickerId, x, y, tokenId);
    }

    function _addStickerToToken(
        uint256 stickerId, 
        uint256 x, 
        uint256 y, 
        uint256 tokenId) internal nonReentrant {
        require(stickerId < _allStickers.length, "That sticker doesn't exist");
        _tokenMapToStickerInstances[tokenId].push(StickerInstance(x, y, stickerId, false));
    } 

    // StickerId is order of sticker for this particular token
    // Not index of allStickers
    function removeSticker(uint256 stickerId, uint256 tokenId) public nonReentrant {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "You're not the owner of this NFT");
        _tokenMapToStickerInstances[tokenId][stickerId].isDeleted = true;
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