// SPDX-License-Identifier: GPL-3.0

/*
 _______ __           ______ __         _______                          
|_     _|  |--.-----.|   __ \__|.-----.|   |   |.-----.--.--.-----.-----.
  |   | |     |  -__||   __ <  ||  _  ||       ||  _  |  |  |__ --|  -__|
  |___| |__|__|_____||______/__||___  ||__|_|__||_____|_____|_____|_____|
                                |_____|                                  
*/

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract TheBigMouse is ERC721A {
    
    // Limited FreeMint Each block
    uint256 _maxFreePerBlock = 10;
    mapping(uint256 => uint256) _freeForBlock;
    uint256 _price = 0.001 ether;
    uint256 _maxSupply = 999; 
    uint256 _maxPerTx = 20;
    address _owner;

    /**
     * PAY Mint 0.001 FOR EACH ONE
     */
    function mint(uint256 amount) payable public {
        require(totalSupply() + 1 <= _maxSupply, "Sold Out");
        require(amount <= _maxPerTx);
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Pay For");
        _safeMint(msg.sender, amount);
    }
    
    // FreeMint ONLY LIMITED FREEMINTS FOR EACH BLOCK. GOOD LUCK. 
    function earlyMint() public {
        require(_freeForBlock[block.number] < _maxFreePerBlock, "Late For This Block");
        require(msg.sender == tx.origin, "No EOA");
        require(totalSupply() + 1 <= _maxSupply, "Sold Out");
        _freeForBlock[block.number]++;
        _safeMint(msg.sender, 1);
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("TheBigMouse", "TBM") {
        _owner = msg.sender;
    }

    function setMaxFreePerBlock(uint8 maxFreePerBlock) public onlyOwner {
        _maxFreePerBlock = maxFreePerBlock;
    }

    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmS6Lt6665GYw6v6nVtB9fjfM1C3jhjueCXx7EsQbZHQoA/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}