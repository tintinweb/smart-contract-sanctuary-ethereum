// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";

contract NuppoDog is ERC721Enumerable, Ownable {
	using Strings for uint256;

	string public baseURI;
	string public baseExtension = ".json";
	uint256 public cost = 0.03 ether;
	uint256 public maxSupply = 3333;
	uint256 public maxMintAmount = 100;
	uint256 public nftPerAddressLimit = 100;
	bool public paused = false;
	mapping(address => uint256) public addressMintedBalance;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _initBaseURI
	) ERC721(_name, _symbol) {
		setBaseURI(_initBaseURI);
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	// public
	function mint(address _to, uint256 _mintAmount) public payable {
		require(!paused, "the contract is paused");
		uint256 supply = totalSupply();
		require(!paused);
		require(_mintAmount > 0, "need to mint at least 1 NFT");
		require(
			_mintAmount <= maxMintAmount,
			"max mint amount per session exceeded"
		);
		require(supply + _mintAmount <= maxSupply, "max NFT limit exceeded");

		if (msg.sender != owner()) {
			uint256 ownerMintedCount = addressMintedBalance[msg.sender];
			require(
				ownerMintedCount + _mintAmount <= nftPerAddressLimit,
				"max NFT per address exceeded"
			);
			require(msg.value >= cost * _mintAmount, "insufficient funds");
		}

		for (uint256 i = 1; i <= _mintAmount; i++) {
			addressMintedBalance[msg.sender]++;
			_safeMint(_to, supply + i);
		}
	}

	function walletOfOwner(address _owner)
		public
		view
		returns (uint256[] memory)
	{
		uint256 ownerTokenCount = balanceOf(_owner);
		uint256[] memory tokenIds = new uint256[](ownerTokenCount);
		for (uint256 i; i < ownerTokenCount; i++) {
			tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
		}
		return tokenIds;
	}

	function tokenURI(uint256 tokenId)
		public
		view
		virtual
		override
		returns (string memory)
	{
		require(
			_exists(tokenId),
			"ERC721Metadata: URI query for nonexistent token"
		);

		string memory currentBaseURI = _baseURI();
		return
			bytes(currentBaseURI).length > 0
				? string(
					abi.encodePacked(
						currentBaseURI,
						tokenId.toString(),
						baseExtension
					)
				)
				: "";
	}

	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
		maxMintAmount = _newmaxMintAmount;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension)
		public
		onlyOwner
	{
		baseExtension = _newBaseExtension;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function withdraw() public payable onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}