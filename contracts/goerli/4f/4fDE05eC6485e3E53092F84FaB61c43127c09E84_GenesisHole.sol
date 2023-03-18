// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract GenesisHole is ERC721A, Ownable {
    uint256 MAX_MINTS = 10;
    uint256 MAX_SUPPLY = 10000;
    uint256 public mintRate = 0.006 ether;

    string public baseURI = "https://ipfs.filebase.io/ipfs/QmRKMfwcvXBQst8biDYPsAUCdvS3bJtLkKe11NStc2vr2g";

    constructor() ERC721A("GenesisHole NFT", "GH") {}

    function mint(uint256 quantity) external payable {
        require(quantity + _numberMinted(msg.sender) <= MAX_MINTS, "Each wallet can only mint 10 NFTs.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "NFT is sold out.");
        if (totalSupply() > 500){
            uint256 payQuantity;
            if (500 - (totalSupply() + quantity) < 0) {
                payQuantity = totalSupply() + quantity - 500;
            } else {
                payQuantity = quantity;
            }
            require(msg.value >= (mintRate * payQuantity), "The mint price of Genesis-Hole is 0.006 ether per.");
        }
        _safeMint(msg.sender, quantity);
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }
}