//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./ReentrancyGuard.sol";

contract Pulsechains is ERC721URIStorage, ReentrancyGuard {

	uint256 public						tokenCounter;
	address payable private				owner;
	uint256 private						_tokenId;
	uint256 public						inSaleAmount;
	uint256 private constant			MAX_INT = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

	event CreatedNFT(uint256 indexed tokenId, string tokenURI);

	struct nft_data {
		string 	json;
		uint256 price;
		bool 	mintable;
	}

	mapping(uint256 => nft_data) public nft_info;
	mapping(string => bool) private serialnoStatus;

	constructor() ERC721("PULSECHAINS", "PLSCH") ReentrancyGuard()
	{
		tokenCounter = 1;
		_tokenId = 1;
		inSaleAmount = 0;
		owner = payable(msg.sender);
	}

	// This is the primary function for uploading the nft to the smart contract before minting.
	function setTokenData(string memory _imageCID, string memory _nftName, string memory _file_name, string memory _serialNo, uint256 _price) public
	{
		require(msg.sender == owner, "You're not allowed to set prices");
		nft_info[_tokenId].price = _price;
		nft_info[_tokenId].json = formatTokenURI(_imageCID, _nftName, _file_name, _serialNo);
		require(!nft_info[_tokenId].mintable, "This token is has already been set mintable.");
		nft_info[_tokenId].mintable = true;
		require(!serialnoStatus[_serialNo], "This serial nb is already in use.");
		serialnoStatus[_serialNo] = true;
		require(_tokenId < MAX_INT, "The token amount is too big.");
		_tokenId++;
		require(inSaleAmount < MAX_INT, "The in sale amount is too big.");
		inSaleAmount++;
	}

	/*
		These set functions have been created so that preminted data
		can still be altered in case something has gone wrong during upload.
	*/
	function setPrice(uint256 tokenId, uint256 _price) public
	{
		require(msg.sender == owner, "You're not allowed to set prices");
		nft_info[tokenId].price = _price;
	}
	
	function setMintable(uint256 tokenId, uint _boolean) public
	{
		require(msg.sender == owner, "You're not allowed to set mintable");
		if (_boolean == 1)
			nft_info[tokenId].mintable = true;
		else if (_boolean == 0)
			nft_info[tokenId].mintable = false;
	}
	
	function setJSON(uint256 tokenId, string memory _imageCID, string memory _nftName, string memory _file_name, string memory _serialNo) public
	{
		require(msg.sender == owner, "You're not allowed to reset JSON");
		require(nft_info[tokenId].mintable, "In order to change data it has to be mintable");
		nft_info[tokenId].json = formatTokenURI(_imageCID, _nftName, _file_name, _serialNo);
		require(bytes(nft_info[tokenId].json).length != 0, "There's not enough data to make change.");
	}

	function getPrices(uint256 _idNum) view public returns(uint256)
	{
		return nft_info[_idNum].price;
	}

	function getIfMintable(uint256 _idNum) view public returns(bool)
	{
		return nft_info[_idNum].mintable;
	}

	function getURI(uint256 _idNum) view public returns(string memory)
	{
		return nft_info[_idNum].json;
	}

	function create(uint256 _id) payable external check_accordance(_id) nonReentrant()
	{
		require(msg.value >= (nft_info[_id].price * 1e11), "Not enough Ether provided.");
		nft_info[_id].mintable = false;
		inSaleAmount--;
		tokenCounter++;
		emit CreatedNFT(tokenCounter - 1, nft_info[_id].json);
		_safeMint(msg.sender, tokenCounter - 1);
		_setTokenURI(tokenCounter - 1, nft_info[_id].json); 
		require((inSaleAmount + 1) > 0, "Cannot sell this.");
		(bool success,) = owner.call{value: msg.value}("");
		require(success, "failed to send the funds");
	}

	modifier check_accordance(uint256 _id)
	{
		require(nft_info[_id].mintable == true, "You cannot mint this!");
		require(nft_info[_id].price > 0, "No price has been set yet for this.");
		require(bytes(nft_info[_id].json).length != 0, "There's not enough data to mint an nft out this.");
		require(inSaleAmount > 0, "There's nothing to mint.");
		_;
	}

	function formatTokenURI(string memory _imgCID, string memory _nftname, string memory _file_name, string memory _serialNo) view private returns (string memory) 
	{
		return string(abi.encodePacked('{"name": "',_nftname,' #',_serialNo,'", "description": "", "image":"https://',_imgCID,'.ipfs.nftstorage.link/',_file_name,'", "attributes": [{"token_id": "',Strings.toString(_tokenId),'"}]}'));
	}
}