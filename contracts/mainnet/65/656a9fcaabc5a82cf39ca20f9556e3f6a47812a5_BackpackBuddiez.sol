// SPDX-License-Identifier: MIT
//
// Backpack Buddiez
/*
 *   
 *     __n__ 
 *    /   ' \,
 *   | gm    |
 *   | __,__,|
 *   \___|___/
 * 
 * 
 * @Danny_One
 * 
 */

import "./ERC721_efficient.sol";

pragma solidity ^0.8.0;


contract BackpackBuddiez is ERC721Enumerable, Ownable, nonReentrant {

	uint256 public PRICE = 33000000000000000;		// 0.033 ETH
	uint256 public b_PRICE = 30000000000000000;		// 0.030 ETH
	
    uint256 public MAX_SUPPLY = 3333;		// 3333 supply
    uint256 public MAX_TEAMRESERVE = 50;	// total team reserves allowed
	
	bool public saleActive = false;
	
	uint256 public maxSaleMint = 20;
	uint256 public maxBLMint = 3;
	uint256 public teamMints = 0;
	
	bytes32 public MerkleRoot;
	
    address public proxyRegistryAddress;
	
	struct AddressInfo {
		bool projectProxy;
		uint256 BLmint;
	}
	
	mapping(address => AddressInfo) public addressInfo;
		
	constructor() ERC721("Backpack Buddiez", "BUDDIEZ") {}

	
	// PUBLIC FUNCTIONS
	
	function mint(uint256 _mintAmount) public payable reentryLock {
		require(saleActive, "public sale not active");
		require(msg.sender == tx.origin, "no proxy transactions");
		
		uint256 supply = totalSupply();
		require(_mintAmount < maxSaleMint + 1, "max mint per session exceeded");
		require(supply + _mintAmount < MAX_SUPPLY + 1, "max NFT limit exceeded");
	
		require(msg.value >= _mintAmount * PRICE, "not enough ETH sent");

		for (uint256 i=0; i < _mintAmount; i++) {
		  _safeMint(msg.sender, supply + i);
		}
	}
  
  
	function mintBuddiezSale(bytes32[] memory _proof, uint256 _mintAmount) public payable reentryLock {
		require(saleActive, "public sale not active");
		require(MerkleRoot > 0x00, "root not set");
		
		uint256 supply = totalSupply();
		require(supply + _mintAmount < MAX_SUPPLY + 1, "max collection limit exceeded");
		require(addressInfo[msg.sender].BLmint + _mintAmount < maxBLMint + 1, "max BL mints exceeded");
		
		require(MerkleProof.verify(_proof, MerkleRoot, keccak256(abi.encodePacked(msg.sender))), "invalid sender proof");

		require(msg.value >= _mintAmount * b_PRICE, "not enough ETH sent");
		
		addressInfo[msg.sender].BLmint += _mintAmount;
		
		for (uint256 i=0; i < _mintAmount; i++) {
		  _safeMint(msg.sender, supply + i);
		}
	}
	
	
	function checkProof(bytes32[] memory proof) public view returns(bool) {
        return MerkleProof.verify(proof, MerkleRoot, keccak256(abi.encodePacked(msg.sender)));
    }
	
    function isApprovedForAll(address _owner, address operator) public view override returns (bool) {
        MarketplaceProxyRegistry proxyRegistry = MarketplaceProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(_owner)) == operator || addressInfo[operator].projectProxy) return true;
        return super.isApprovedForAll(_owner, operator);
    }


	// ONLY OWNER FUNCTIONS

	function setBaseURI(string memory baseURI_) public onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setMerkleRoot(bytes32 _MerkleRoot) public onlyOwner {
        MerkleRoot = _MerkleRoot;
    }
	
    function flipSaleState() public onlyOwner {
        saleActive = !saleActive;
    }

	function setProxyRegistry(address _proxyRegistryAddress) public onlyOwner {
		proxyRegistryAddress = _proxyRegistryAddress;
    }

    function withdraw() public onlyOwner {
        uint256 balance = address(this).balance;
		(bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Transfer failed.");
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        PRICE = _newPrice;
    }
	
	// reserve function for team mints (giveaways & payments)
    function teamMint(address _to, uint256 _reserveAmount) public onlyOwner {
        require(_reserveAmount > 0 && _reserveAmount + teamMints < MAX_TEAMRESERVE + 1, "Not enough reserve left for team");
		uint256 supply = totalSupply();
		require(supply + _reserveAmount < MAX_SUPPLY + 1, "max collection limit exceeded");
		
		teamMints = teamMints + _reserveAmount;
		
        for (uint i = 0; i < _reserveAmount; i++) {
            _safeMint(_to, supply + i );
        }
    }

}

contract OwnableDelegateProxy { }
contract MarketplaceProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}