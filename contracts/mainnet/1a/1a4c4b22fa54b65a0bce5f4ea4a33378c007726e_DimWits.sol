// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./PaymentSplitter.sol";
import "./Delegated.sol";
import "./ERC721EnumerableB.sol";
import "./Strings.sol";

/****************************************
 * @author: Squeebo                     *
 * @team:   X-11                        *
 ****************************************
 *   Blimpie-ERC721 provides low-gas    *
 *           mints + transfers          *
 ****************************************/

contract DimWits is Delegated, ERC721EnumerableB, PaymentSplitter {
	using Strings for uint;

	uint public MAX_SUPPLY = 7777;

	bool public isActive   = false;
	bool public isActiveWL = false;
	uint public maxOrder   = 7;
	uint public wlPrice    = 0.04 ether;
	uint public price	   = 0.05 ether;

	string private _baseTokenURI = '';
	string private _tokenURISuffix = '';

	mapping(address => uint[]) private _balances;
	mapping(address => bool) public _whitelist;

	address[] private addressList = [
		0x7aa4720178a05654D48182aCF853b4eC1fe5f7E5,
		0xaC1F6F85c6e5Fc2C451e4f06fADAe1FF90077677,
		0xFa0f99C04a5E2fc967eb218E4e9678a0378bBD99,
		0xA6B0765819Fc970865660A31B1eB8F0e3a07F6a9,
		0x9B4146F5C28AAa1F6D66C93dcd042cF72bc8Ee85,
		0xC9312853bcD4662c316419aCd4A5552e8DEdEfe7
	];
	uint[] private shareList = [
		75,
		25,
		20,
		10,
		50,
		820
	];

	constructor()
		Delegated()
		ERC721B("DimWits", "DWS")
		PaymentSplitter(addressList, shareList)  {
	}

	//external
	fallback() external payable {}

	function mint( uint quantity ) external payable {
		require( isActive,        				"Sale is not active"		);
		require( quantity <= maxOrder,          "Order too big"             );
		require( msg.value >= price * quantity, "Ether sent is not correct" );

		uint256 supply = totalSupply();
		require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
		for(uint i = 0; i < quantity; ++i){
			_safeMint( msg.sender, supply++, "" );
		}
	}

	function whitelistMint( uint quantity ) external payable {
		require( isActiveWL,        			"Whitelist sale is not active");
		require( _whitelist[msg.sender], 		"Not whitelisted"			  );
		require( quantity <= maxOrder,          "Order too big"               );
		require( msg.value >= wlPrice * quantity, "Ether sent is not correct" );

		uint256 supply = totalSupply();
		require( supply + quantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
		for(uint i = 0; i < quantity; ++i){
			_safeMint( msg.sender, supply++, "" );
		}  
	}

	//external delegated
	function gift(uint[] calldata quantity, address[] calldata recipient) external onlyDelegates{
		require(quantity.length == recipient.length, "Must provide equal quantities and recipients" );

		uint totalQuantity = 0;
		uint256 supply = totalSupply();
		for(uint i = 0; i < quantity.length; ++i){
			totalQuantity += quantity[i];
		}
		require( supply + totalQuantity <= MAX_SUPPLY, "Mint/order exceeds supply" );
		delete totalQuantity;

		for(uint i = 0; i < recipient.length; ++i){
			for(uint j = 0; j < quantity[i]; ++j){
				_safeMint( recipient[i], supply++, "Sent with love" );
			}
		}
	}

	function setWhitelist(address[] memory _addresses) external onlyDelegates {
		for(uint i = 0; i < _addresses.length; ++i) {
			_whitelist[_addresses[i]] = true;
		}
	}

	function removeFromWhitelist(address[] memory _addresses) external onlyDelegates {
		for(uint i = 0; i < _addresses.length; ++i) {
			delete _whitelist[_addresses[i]];
		}
	}

	function setWhitelistActive(bool isActiveWL_) external onlyDelegates {
		if( isActiveWL != isActiveWL_ ) 
			isActiveWL = isActiveWL_;
	}

	function setActive(bool isActive_) external onlyDelegates{
		if( isActive != isActive_ )
			isActive = isActive_;
	}

	function setMaxOrder(uint maxOrder_) external onlyDelegates{
		if( maxOrder != maxOrder_ )
			maxOrder = maxOrder_;
	}

	function setPrice(uint price_, uint wlprice_) external onlyDelegates{
		if( price != price_ )
			price = price_;

		if( wlPrice != wlprice_)
			wlPrice = wlprice_;
	}

	function setBaseURI(string calldata _newBaseURI, string calldata _newSuffix) external onlyDelegates{
		_baseTokenURI = _newBaseURI;
		_tokenURISuffix = _newSuffix;
	}

	//external owner
	function setMaxSupply(uint maxSupply) external onlyOwner{
		if( MAX_SUPPLY != maxSupply ){
			require(maxSupply >= totalSupply(), "Specified supply is lower than current balance" );
			MAX_SUPPLY = maxSupply;
		}
	}

	//public
	function balanceOf(address owner) public view virtual override returns (uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return _balances[owner].length;
	}

	function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256 tokenId) {
		require(index < ERC721B.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
		return _balances[owner][index];
	}

	function tokenURI(uint tokenId) external view virtual override returns (string memory) {
		require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
		return string(abi.encodePacked(_baseTokenURI, tokenId.toString(), _tokenURISuffix));
	}

	//internal
	function _beforeTokenTransfer(
		address from,
		address to,
		uint256 tokenId
	) internal override virtual {
		address zero = address(0);
		if( from != zero || to == zero ){
			//find this token and remove it
			uint length = _balances[from].length;
			for( uint i; i < length; ++i ){
				if( _balances[from][i] == tokenId ){
					_balances[from][i] = _balances[from][length - 1];
					_balances[from].pop();
					break;
				}
			}

			delete length;
		}

		if( from == zero || to != zero ){
			_balances[to].push( tokenId );
		}
	}
}