// SPDX-License-Identifier: MIT

pragma solidity >=0.8.9 <0.9.0;

contract BuildURI{

    struct tokenData {
        string name;
        string GIF;
        string trait;
        bool updated;
    }

    mapping (uint256 => tokenData) public tokens;

    function setTokenInfo(uint _tokenId, string memory _name, string memory _GIF, string memory _trait) public {         
        tokens[_tokenId].name = _name;
        tokens[_tokenId].trait = _trait;
        tokens[_tokenId].GIF = _GIF;
        tokens[_tokenId].updated = true;
    }
}