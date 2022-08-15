// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10 <0.9.0;

import './ERC721A.sol';
import './Ownable.sol';


    // its free Mint  and ERC721A contract (low GAS Fee)
    // 3000 Supply and Max 2 NFT per wallet & per tx
    // REVEAL: After Sold Out 


contract BaoBaoNFTS1 is ERC721A, Ownable {
    constructor() ERC721A("BaoBao NFT S1", "BBNS1") {
        mint(2);
    }

    string _baseTokenURI;
    mapping(address => uint256) _minted;
    uint public constant RESERVED = 60;
    uint public RESERVED_Minted = 0;
    uint public maxPerTx = 2;
    uint public maxPerWallet = 2;

    function mint(uint256 quantity) public {
        require(totalSupply() + quantity <= 3000 - RESERVED, "All BaoBao NFT S1 minted");
        require(quantity <= maxPerTx, "Cant mint more than 2 BaoBao NFT S1 in one tx");
        require(quantity > 0, "Must mint at least one BaoBao NFT S1");
        require(_minted[msg.sender] < maxPerWallet, "Cant mint more than 2 BaoBao NFT S1 per wallet");
        _minted[msg.sender] += quantity;
        _mint(msg.sender, quantity);
    }

    function mintReserved(address toaddress, uint256 quantity) external onlyOwner 
    {
        require(RESERVED_Minted + quantity <= RESERVED, "Cant mint more than RESERVED");
        RESERVED_Minted = RESERVED_Minted + quantity;
        _mint(toaddress, quantity);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
	
	function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    } 
}