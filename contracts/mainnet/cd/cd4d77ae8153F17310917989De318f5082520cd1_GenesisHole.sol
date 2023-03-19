// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "ERC721A.sol";
import "Ownable.sol";

contract GenesisHole is ERC721A, Ownable {
    uint256 MAX_MINTS = 10;
    uint256 MAX_SUPPLY = 10000;
    uint256 public payLimit = 500;
    uint256 public mintRate = 0.006 ether;
    bool public mintWindow = true;
    event Log(int);
    event Log(string);
    string public baseURI = "http://ipfs.blackholenft.xyz/QmRo75kh1QLPcnE7g2AR2ZuZGixdi7z6gKxb1oEtJ8im3A/";

    constructor() ERC721A("GenesisHole NFT", "GH") {}

    function mint(uint256 quantity) external payable {
        require(mintWindow, "Mint is not open yet.");
        uint256 tokenNum = _numberMinted(msg.sender);
        require(quantity + tokenNum <= MAX_MINTS, "Each wallet can only mint 10 NFTs.");
        require(totalSupply() + quantity <= MAX_SUPPLY, "NFT is sold out.");
        uint256 payQuantity = 0;
        if(totalSupply() + quantity > payLimit) {
            if(totalSupply() >= payLimit){
                payQuantity = quantity;
            } else {
                payQuantity = totalSupply() + quantity - payLimit;
            }
        } else {
            payQuantity = 0;
        }
        if (tokenNum == 0 && payQuantity > 0){
            payQuantity = payQuantity - 1;
        }
        require(msg.value >= (mintRate * payQuantity), "The mint price of each Genesis-Hole is 0.006 ether.");

        _safeMint(msg.sender, quantity);
    }

    function withdraw(address addr) external onlyOwner {
        payable(addr).transfer(address(this).balance);
    }

    function setMintWindow(bool _mintOpen) public onlyOwner {
        mintWindow = _mintOpen;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setMintRate(uint256 _mintRate) public onlyOwner {
        mintRate = _mintRate;
    }

    function setPayLimit(uint256 _payLimit) public onlyOwner {
        payLimit = _payLimit;
    }
}