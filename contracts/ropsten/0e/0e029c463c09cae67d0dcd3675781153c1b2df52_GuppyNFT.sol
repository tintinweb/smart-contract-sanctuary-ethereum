// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./ERC721A.sol";

contract GuppyNFT is ERC721A, Ownable {
    uint256 public TOTAL_SUPPLY;
    uint256 public MAX_PER_MINT;
    uint256 public PRICE;

    bool public mintActive = false;

    string private _baseTokenURI;

    string public GUPPY_PROVENANCE;

    constructor(string memory name, string memory symbol, uint256 totalSupply, uint256 maxPerMint, uint256 price) ERC721A(name,symbol) {
        TOTAL_SUPPLY = totalSupply;
        MAX_PER_MINT = maxPerMint;
        PRICE = price;
    }

    function mintGuppy(uint256 quantity) public payable {
        require(msg.sender != address(0), "Mint to null address");
        require(mintActive, "Mint not active");
        require(_totalMinted() + quantity <= TOTAL_SUPPLY, "Cannot mint more than max supply");
        require(msg.value >= quantity * PRICE, "Minimum payment not met");
        require(msg.sender == tx.origin, "Calls from contracts not allowed");
    
        _mint(msg.sender, quantity);
    }

    function setProvenance(string memory guppyHash) public onlyOwner {
        GUPPY_PROVENANCE = guppyHash;
    }

    function saleStatus(bool status) external onlyOwner {
        mintActive = status;
    }

    function setBaseURI(string memory uri) public onlyOwner {
        _baseTokenURI = uri;
    }

    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function _baseURI() internal view virtual override returns(string memory) {
        return _baseTokenURI;
    }    
}