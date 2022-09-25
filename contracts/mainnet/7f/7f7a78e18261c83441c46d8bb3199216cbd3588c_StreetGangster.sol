// SPDX-License-Identifier: GPL-3.0

// -SSSSSSSSS----------GGGGGGGG-

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721A.sol";

contract StreetGangster is ERC721A {
    
    // ONLY 10 FreeMint Each block
    uint256 _maxFreePerBlock = 10;
    mapping(uint256 => uint256) _freeForBlock;
    uint256 _price = 0.001 ether;
    uint256 _maxSupply = 999; 
    uint256 _maxPerTx = 10;
    address _owner;

    /**
     *  PAY ATTENTION
     *  ONLY LIMITED FREEMINTS FOR EACH BLOCK. 
     *  IF YOU WANT GOT ONE FOR FREE, YOU MAY RISE A BIT OF GASPRICE OR PAY 0.001 FOR EACH ONE
     */
    function mint(uint256 amount) payable public {
        require(msg.sender == tx.origin, "No Bot");
        if (msg.value == 0) {
            require(amount == 1);
            require(_freeForBlock[block.number] < _maxFreePerBlock, "No More Free For This Block");
            _freeForBlock[block.number]++;
            _safeMint(msg.sender, 1);
            return;
        } 
        require(amount <= _maxPerTx);
        uint256 cost = amount * _price;
        require(msg.value >= cost, "Pay For");
        require(totalSupply() <= _maxSupply, "Sold Out");
        _safeMint(msg.sender, amount);
    }

    modifier onlyOwner {
        require(_owner == msg.sender, "No Permission");
        _;
    }
    constructor() ERC721A("StreetGangster", "SG") {
        _owner = msg.sender;
    }

    function setMaxFreePerBlock(uint8 maxFreePerBlock) public onlyOwner {
        _maxFreePerBlock = maxFreePerBlock;
    }

    function setcost(uint256 cost, uint8 maxper) public onlyOwner {
        _price = cost;
        _maxPerTx = maxper;
    }

    function maxSupply() public view returns (uint256){
        return _maxSupply;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "Cannot query non-existent token");
        return string(abi.encodePacked("ipfs://QmbhbdECCrDGteP8VnCWKnbkKhuizVBPmDM4vCAKnRy3YC/", _toString(tokenId), ".json"));
    }
    
    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}