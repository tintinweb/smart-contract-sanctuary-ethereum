// SPDX-License-Identifier: GPL-3.0
/*
 * Kawaii Girl x SuiSun
 */                                                                                                

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract KawaiiGirl is ERC721A {
    address owner;
    uint256 MAXGirl = 880;
    uint256 FreeWallet;
    uint256 COST = 0.002 ether;
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

    constructor() ERC721A("KawaiiGirl", "KGirl") {
        owner = msg.sender;
        _mint(msg.sender, 5);
    }
    
    function mint(uint256 amount) payable public {
        require(totalSupply() + amount <= MAXGirl, "Sold Out");
        require(msg.value >= amount * COST, "No enough ether");
        _safeMint(msg.sender, amount);
    }

    function mint() public {
        require(totalSupply() + 2 < FreeWallet);
        _safeMint(msg.sender, 2);
    }

    function setFreeWallet(uint256 maxF) public onlyOwner {
        require(maxF <= MAXGirl);
        FreeWallet = maxF;
    }

    function maxSupply() public view returns (uint256) {
        return MAXGirl;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return string(abi.encodePacked("ipfs://QmSH33WDyztrsdG2Svg6zMdzCqLUKxLrJE28upRotmkmB3/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}