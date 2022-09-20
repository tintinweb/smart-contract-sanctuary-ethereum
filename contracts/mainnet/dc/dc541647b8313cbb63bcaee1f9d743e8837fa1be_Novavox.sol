// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "Ownable.sol";
import "ReentrancyGuard.sol";
import "ERC721A.sol";
import "Strings.sol";
import "Payment.sol";                                                                                        

contract Novavox is Ownable, ERC721A, ReentrancyGuard, Payment {
    using Strings for uint256;
    string public baseURI;

  	//Settings
  	uint256 public maxSupply = 10000;

	//Max Mint
	uint256 public maxMint = 10000; 

	//Shares
	address[] private addressList = [0x8B9789ce9745721Dfd2aD9D06Ae7c1662eB7B105];
	uint[] private shareList = [100];
    
	//Token
	constructor(
	string memory _name,
	string memory _symbol,
	string memory _initBaseURI
	) 
    ERC721A(_name, _symbol, maxMint, maxSupply)
	    Payment(addressList, shareList){
	    setURI(_initBaseURI);
	}

    // Owner Mint
    function ownerMint(uint256 mintAmount) public payable onlyOwner {
		uint256 s = totalSupply();
		require( s + mintAmount <= maxSupply, "Mint less");
		_safeMint(msg.sender, mintAmount, "");    

		delete s;
    }

	// Read Metadata
	function _baseURI() internal view virtual override returns (string memory) {
	   return baseURI;
	}

	function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
	   require(tokenId <= maxSupply);
	   string memory currentBaseURI = _baseURI();
	   return bytes(currentBaseURI).length > 0	? string(abi.encodePacked(currentBaseURI, tokenId.toString())) : "";
	}

	//Max Switches
	function setMaxMint(uint256 _newMaxMintAmount) public onlyOwner {
	   maxMint = _newMaxMintAmount;
	}
	function setMaxSupply(uint256 _newMaxSupplyAmount) public onlyOwner {
	   maxSupply = _newMaxSupplyAmount;
	}
	
	//Write Metadata
	function setURI(string memory _newBaseURI) public onlyOwner {
	   baseURI = _newBaseURI;
	}
	
	function withdraw() public payable onlyOwner {
	   (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
	   require(success);
	}
}