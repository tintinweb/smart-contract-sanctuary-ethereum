// SPDX-License-Identifier: GPL-3.0
/*
 * ENS 1K Club
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract ENS1KClub is ERC721A {
    address owner;
    uint256 public maxSupply = 1000;
    uint256 FreeWallet;
    uint256 COST = 0.001 ether;
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;
    uint256 private constant BITPOS_NUMBER_MINTED = 64;
    uint256 private constant BITPOS_NUMBER_BURNED = 128;
    uint256 private constant BITPOS_AUX = 192;
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;
    uint256 private constant BITPOS_START_TIMESTAMP = 160;
    uint256 private constant BITMASK_BURNED = 1 << 224;
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;
    
    modifier onlyOwner {
        require(owner == msg.sender, "No Permission");
        _;
    }

    constructor() ERC721A("ENS 1K Club", "E1C") {
        owner = msg.sender;
        _mint(msg.sender, 5);
    }
    
    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= maxSupply, "Sold Out");
        require(msg.value >= amount * COST, "No enough ether");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(totalSupply() < FreeWallet);
        _safeMint(msg.sender, 1);
    }

    function setFreeWallet(uint256 maxF) public onlyOwner {
        require(maxF <= maxSupply);
        FreeWallet = maxF;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://bafybeihjzcul5ke6p2dagdebk4xarzvlwz56wzcp74so4jgueltzwpaodq/", _toString(tokenId)));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}