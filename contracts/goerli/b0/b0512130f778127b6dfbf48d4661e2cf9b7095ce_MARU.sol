//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";

contract MARU is ERC721A {

    string baseURI = '';

    constructor() ERC721A("MaruNFT", "MFT") {}

    function setBaseURI(string memory BaseURI) public {
        baseURI = BaseURI;
    }

    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    function mint(uint256 amount) public {
        _safeMint(msg.sender, amount);
    }

}