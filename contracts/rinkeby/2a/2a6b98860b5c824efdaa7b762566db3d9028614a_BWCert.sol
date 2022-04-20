// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC721A.sol";
import "./Ownable.sol";

contract BWCert is ERC721A, Ownable {
    string private baseExtension = ".json";
    uint256 MAX_MINTS = 100;
    uint256 MAX_SUPPLY = 1000000;
    uint256 public mintRate = 0.00 ether;

    string public baseURI = "ipfs://QmeGZo3zCpZHe5zxtzSYPE3iitLcZ9QZC6ceP6CmqEYes4";

    constructor() ERC721A("BW Cert", "BWC") {}

    function mint(uint256 quantity) external payable {
        // _safeMint's second argument now takes in a quantity, not a tokenId.
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Exceeded the limit of mints per user");
        require(totalSupply() + quantity <= MAX_SUPPLY, "Not enough NFTs left");
        require(msg.value >= (mintRate * quantity), "Not enough ether sent");
        _safeMint(msg.sender, quantity);
    }

    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
}