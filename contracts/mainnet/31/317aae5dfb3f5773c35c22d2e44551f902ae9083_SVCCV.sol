// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./ERC721A.sol";
import "./Strings.sol";

contract SVCCV is Ownable, ERC721A, ReentrancyGuard {

	uint256 public MAX_NFT = 800;
	uint256 public MINTED_NFT;
	
	string public _baseTokenURI;
  
	constructor() ERC721A("SVCC Voxels", "SVCCV") {}
  
	function mintNFT(address[] calldata _to, uint256[] calldata _count) public onlyOwner{
		require(_to.length == _count.length, "SVCCV: Length MisMatch");
		
		for (uint256 i = 0; i < _to.length; i++) {
		   require(MINTED_NFT + _count[i] <= MAX_NFT, "SVCCV: All NFT Minted");
		   
		   _safeMint(_to[i], _count[i]);
		   MINTED_NFT += _count[i];
		}
	}
	
	function mintNFT(address[] calldata _to, uint256 _count) public onlyOwner{
		for (uint256 i = 0; i < _to.length; i++) {
		   require(MINTED_NFT + _count <= MAX_NFT, "SVCCV: All NFT Minted");
		   _safeMint(_to[i], _count);
		   MINTED_NFT += _count;
		}
	}
	
   function _baseURI() internal view virtual override returns (string memory) {
	   return _baseTokenURI;
    }

    function setBaseURI(string calldata baseURI) external onlyOwner {
	    _baseTokenURI = baseURI;
    }

    function withdraw() public onlyOwner {
       uint256 balance = address(this).balance;
       payable(msg.sender).transfer(balance);
    }
	
    function numberMinted(address owner) public view returns (uint256) {
	   return _numberMinted(owner);
    }
	
	function getOwnershipData(uint256 tokenId) external view returns (TokenOwnership memory) {
	   return ownershipOf(tokenId);
	}
	
	function updateSupply(uint256 newSupply) external onlyOwner {
	    require(newSupply >= MINTED_NFT, "Incorrect value");
        MAX_NFT = newSupply;
    }
}