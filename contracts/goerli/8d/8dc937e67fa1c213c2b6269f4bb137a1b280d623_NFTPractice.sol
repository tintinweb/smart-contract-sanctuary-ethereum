// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

// Uncomment this line to use console.log
// import "./console.sol";

contract NFTPractice is ERC721Enumerable, Ownable {
	string private currentBaseURI;
	uint256 public constant mintPrice = 0.001 ether;
	uint256 public constant maxSupply = 5;

	constructor() ERC721("NFTPractice", "NFT") {}

	function mint(uint256 quantity) public payable {
		require(totalSupply() + quantity < maxSupply, "Collection Sold Out");
		require(msg.value >= mintPrice * quantity, "Insufficient Balance");

		for (uint256 i = 0; i < quantity; i++) {
			uint256 tokenId = totalSupply();
			_safeMint(msg.sender, tokenId);
		}
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return currentBaseURI;
	}

	function setBaseURI(string memory baseURI_) public onlyOwner {
		currentBaseURI = baseURI_;
	}

	function withdraw() public onlyOwner {
		uint256 balance = address(this).balance;
		(bool success, ) = payable(msg.sender).call{ value: balance }("");
		require(success, "Withdraw Failed");
	}
}