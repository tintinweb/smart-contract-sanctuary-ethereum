// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./ERC721Pausable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

// MetaBolts
// https://rinkeby.etherscan.io/address/0x8DfBca683b15924116c8eAcc25A212e2eeDA6ef3

contract MetaBolts is ERC721Enumerable, ERC721Burnable, ERC721Pausable, Ownable
{
	using Strings for uint256;

	string _baseTokenURI;

	address _ownerAddress = 0xe2F4A9360d52272dDc200e36A5E2db3f1190392E;
	address _devAddress = 0xbebc747a864f1F2db9955Aab390223b26c42d57C;

	uint256 public _price = 0.0001 ether;

	constructor(string memory baseURI) ERC721("MetaBolts", "MB")
	{
		setBaseURI(baseURI);

		// pre-minted
		uint256 premint = 3;
		for(uint256 i; i<premint; i++)
		{
			_safeMint(_ownerAddress, i);
		}
	}	

	// MetaBolts
	function purchase(uint256 quantity) public payable
	{
		uint256 supply = totalSupply();
		require(!paused(), "Sale paused");
		require(quantity < 21, "You can purchase a maximum of 20 NFTs");
		require(msg.value >= _price * quantity, "Ether sent is not correct");

		for(uint256 i; i<quantity; i++)
		{
			_safeMint(msg.sender, supply + i);
		}
	}

	function walletOfOwner(address owner) public view returns(uint256[] memory)
	{
		uint256 tokenCount = balanceOf(owner);

		uint256[] memory tokensId = new uint256[](tokenCount);
		for(uint256 i; i<tokenCount; i++)
		{
			tokensId[i] = tokenOfOwnerByIndex(owner, i);
		}
		
		return tokensId;
	}

	function setBaseURI(string memory baseURI) public onlyOwner
	{
		_baseTokenURI = baseURI;
	}

	function setPrice(uint256 newPrice) public onlyOwner()
	{
		_price = newPrice;
	} 

	function giveAway(address to, uint256 quantity) external onlyOwner()
	{
		uint256 supply = totalSupply();
		for(uint256 i; i<quantity; i++)
		{
			_safeMint(to, supply + i);
		}
	}

	function withdrawAll() public payable onlyOwner
	{
		uint256 all = address(this).balance;
		uint256 commissionPercent = 10;
		uint256 commission = SafeMath.div(SafeMath.mul(all, commissionPercent), 100);
		uint256 remainder = SafeMath.sub(all, commission);
		require(payable(_ownerAddress).send(remainder));
		require(payable(_devAddress).send(commission));
	}

	// ERC721
	function _baseURI() internal view virtual override returns (string memory)
	{
		return _baseTokenURI;
	}	

	function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable)
	{
		super._beforeTokenTransfer(from, to, tokenId);
	}

	function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) 
	{
		return super.supportsInterface(interfaceId);
	}		
}