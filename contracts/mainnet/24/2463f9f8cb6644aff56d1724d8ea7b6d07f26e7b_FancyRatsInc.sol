// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./ERC721A.sol";
import "./Ownable.sol";

contract FancyRatsInc is ERC721A, Ownable {
    string public baseURI_;

    constructor() ERC721A("FancyRatsInc", "FANCY") Ownable() {}

    function _baseURI() internal view override returns (string memory) {
        return baseURI_;
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _safeMint(_to, _amount);
    }

    function burn(uint256 tokenId) public onlyOwner {
        _burn(tokenId);    
    }

    function setBaseURI(string memory __baseURI) public onlyOwner {
        baseURI_ = __baseURI;
    }

    // Soulbind-ish
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public payable override {
        require(msg.sender == owner(), "Only transferrable by contract owner");
        super.transferFrom(from, to, tokenId);
    }

    function isApprovedForAll(address, address operator) public view override returns (bool) {
        return operator == this.owner();
    }
}