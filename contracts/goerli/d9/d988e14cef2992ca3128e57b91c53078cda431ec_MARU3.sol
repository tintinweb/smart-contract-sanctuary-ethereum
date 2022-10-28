//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./ERC721A.sol";

contract MARU3 is ERC721A {

    string baseURI = "https://api.starsailorsiblings.com/sss/";
    uint256 limit = 10101;

    constructor() ERC721A("MaruNFT", "MFT") {}

    function setBaseURI(string memory BaseURI) public {
        baseURI = BaseURI;
    }

    function _baseURI() internal view override returns (string memory){
        return baseURI;
    }

    function changeLimit(uint256 newLimit) public {
        limit = newLimit;
    }
    function mint(uint256 amount) public {
        require(totalSupply() + amount <= limit, "Minted too many");
        _safeMint(msg.sender, amount);
    }
}