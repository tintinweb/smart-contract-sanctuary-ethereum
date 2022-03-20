// SPDX-License-Identifier: MIT

import "./ERC721_flat.sol";

pragma solidity ^0.8.0;
pragma abicoder v2;

contract CrazyCoconuts is ERC721, Ownable, nonReentrant {
    
    string public COCONUT_PROVENANCE = ""; // IPFS URL WILL BE ADDED WHEN COCONUTS ARE ALL SOLD OUT
    
    uint256 public CoconutPrice = 30000000000000000; // 0.03 ETH
	
	uint public constant maxCoconutPurchase = 25;

    uint256 public constant MAX_COCONUTS = 9999;
		
    // Reserve Coconuts for team - Giveaways/Prizes etc
	uint public constant MAX_COCONUTRESERVE = 100;	// total team reserves allowed
    uint public CoconutReserve = MAX_COCONUTRESERVE;	// counter for team reserves remaining 
	

    bool public saleIsActive = false;

    constructor() ERC721("CrazyCoconuts", "COCO") { }
    
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
	
	function setCoconutPrice(uint256 _CoconutPrice) public onlyOwner {
        CoconutPrice = _CoconutPrice;
    }
    
    function setProvenanceHash(string memory provenanceHash) public onlyOwner {
        COCONUT_PROVENANCE = provenanceHash;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function flipSaleState() public onlyOwner {
        saleIsActive = !saleIsActive;
    }
	
    function reserveCoconuts(address _to, uint256 _reserveAmount) public onlyOwner {
        uint reserveMint = MAX_COCONUTRESERVE - CoconutReserve;
        require(_reserveAmount > 0 && _reserveAmount < CoconutReserve + 1, "Not enough reserve left for team");
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, reserveMint + i);
        }
        CoconutReserve = CoconutReserve - _reserveAmount;
    }


    function mintCoconuts(uint numberOfTokens) public payable reentryLock {
        require(saleIsActive, "Sale must be active to mint token");
		require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(numberOfTokens > 0 && numberOfTokens < maxCoconutPurchase + 1, "Can only mint 10 Coconuts at a time");
        require(totalSupply() + numberOfTokens < MAX_COCONUTS - CoconutReserve + 1, "Purchase would exceed max supply of Coconuts");
        require(msg.value >= CoconutPrice * numberOfTokens, "Ether value sent is not correct");
        
        for(uint i = 0; i < numberOfTokens; i++) {
            uint mintIndex = totalSupply() + CoconutReserve; // start minting after reserved tokenIds
            if (totalSupply() < MAX_COCONUTS) {
                _safeMint(msg.sender, mintIndex);
            }
        }

    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
}