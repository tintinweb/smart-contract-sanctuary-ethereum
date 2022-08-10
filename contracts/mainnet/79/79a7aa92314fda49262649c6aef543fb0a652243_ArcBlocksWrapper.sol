/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGenArt721Core {
    function tokenIdToHash(uint256) view external returns (bytes32);
    function projectScriptInfo(uint256 _projectId) view external returns (string memory scriptJSON, uint256 scriptCount, bool useHashString, string memory ipfsHash, bool locked, bool paused);
    function projectScriptByIndex(uint256 _projectId, uint256 _index) view external returns (string memory); 
}

contract ArcBlocksWrapper {
    
    uint256 constant ONE_MILLION = 1_000_000;
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    IGenArt721Core public artblock;

    constructor(address artblock_) {
        artblock = IGenArt721Core(artblock_);
    }
    
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

    function render(uint256 projectId, uint256 index) public view returns (bytes memory) {
        uint256 tokenId = projectId * ONE_MILLION + index;
        bytes32 tokenHash = artblock.tokenIdToHash(tokenId);
        (, uint256 count,,,,) = artblock.projectScriptInfo(projectId);
        string memory script = "<script>";
        for (uint i=0;i < count;i++) {
            string memory scriptPart = artblock.projectScriptByIndex(projectId, i);
            script = string.concat(script, scriptPart);
        }
        script = string.concat(script, "</script>");
        bytes memory html = abi.encodePacked(
            '<html><head><meta charset="utf-8"><script src="https://cdnjs.cloudflare.com/ajax/libs/p5.js/1.0.0/p5.min.js"></script>',
            '<script>let tokenData = {"hash":"',
            toHexString(uint256(tokenHash)),
            '"}</script>',
            script,
            '<style type="text/css">body{margin: 0;padding: 0;}canvas {padding: 0;margin: auto;display: block;position: absolute;top: 0;bottom: 0;left: 0;right: 0;}</style></head></html>'
        );
        return html;
    }    
}