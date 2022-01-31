// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";

interface IContract {
	function balanceOf(address owner) external view returns (uint256);

	function ownerOf(uint256 index) external view returns (address);
}

contract BoredLabs is ERC721Enumerable, Ownable {
	using SafeMath for uint256;

	uint256 public MAX_TOKENS;
	uint256 public MAX_PUBLIC_MINT = 5;
	uint256 public PRICE = 0.2 ether;

	address public treasury;
	string private baseTokenURI;

	IContract[3] public contracts;

	mapping(address => uint256) private publicMintMap;

	bool public openPublicMint = false;
	bool public openMint = false;

	constructor(
		address _treasury,
		uint256 _max_tokens,
		address _bayc,
		address _bakc,
		address _mayc
	) ERC721("The Bored Labs", "TBL") {
		treasury = _treasury;
		MAX_TOKENS = _max_tokens;
		contracts[0] = IContract(_bayc);
		contracts[1] = IContract(_bakc);
		contracts[2] = IContract(_mayc);
	}

	function publicMint(uint256 num) public payable {
		require(openPublicMint, "Public sales not active");
		uint256 supply = totalSupply();
		require(publicMintMap[_msgSender()].add(num) <= MAX_PUBLIC_MINT, "Reached max per transaction");
		require(supply.add(num) <= MAX_TOKENS, "Fully minted");
		require(msg.value >= num * PRICE, "Invalid price");

		for (uint256 i; i < num; i++) {
			publicMintMap[_msgSender()]++;
			_safeMint(_msgSender(), supply + i);
		}
	}

	function mint(uint16 index, uint256 num) external payable {
		require(openMint, "Public sales not active");
		uint256 supply = totalSupply();
		require(publicMintMap[_msgSender()].add(num) <= MAX_PUBLIC_MINT, "Reached max per transaction");
		require(supply.add(num) <= MAX_TOKENS, "Fully minted");
		require(msg.value >= num * PRICE, "Invalid price");

		require(contracts[index].balanceOf(_msgSender()) > 0, "no pass");

		for (uint256 i; i < num; i++) {
			publicMintMap[_msgSender()]++;
			_safeMint(_msgSender(), supply + i);
		}
	}

	function _baseURI() internal view virtual override returns (string memory) {
		return baseTokenURI;
	}

	function setBaseURI(string memory baseURI) public onlyOwner {
		baseTokenURI = baseURI;
	}

	function withdraw() public onlyOwner {
		payable(treasury).transfer(address(this).balance);
	}

	function setMint(bool _publicMint, bool _mint) external onlyOwner {
		openPublicMint = _publicMint;
		openMint = _mint;
	}

	function setTreasury(address _treasury) external onlyOwner {
		treasury = _treasury;
	}

	function setParams(
		uint256 _max_token,
		uint256 _max_public_mint,
		uint256 _price
	) external onlyOwner {
		MAX_TOKENS = _max_token;
		MAX_PUBLIC_MINT = _max_public_mint;
		PRICE = _price;
	}
}