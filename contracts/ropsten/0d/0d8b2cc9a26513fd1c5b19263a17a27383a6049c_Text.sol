/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Text {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    string public name;
    string public baseURI;

    function setURI(string memory _newuri) public {
        baseURI = _newuri;
    }

    function toHexString(uint256 value, uint256 length) public pure returns (string memory) {
        bytes memory buffer = new bytes(length+2);
        for (uint256 i = length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    function uri(uint256 _tokenID, uint256 length) public view returns (string memory) {
       return string(abi.encodePacked(baseURI,toHexString(_tokenID,length),".json"));
    }

}