// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./nf-token-enumerable.sol";
import "./EpigeonInterfaces.sol";
import "./ownable.sol";

//----------------------------------------------------------------------------------

contract EpigeonNFT is NFTokenEnumerable, Ownable
  {
    IEpigeon public epigeon;
      
    string public name;
	string public symbol;
	mapping (uint256 => address) internal idtoCryptoPigeon;
	mapping (address => uint256) internal cryptoPigeonToId;
	uint256 mintingPrice = 1000000000000000;
	uint256 highestTokenId;
	bool freeMintEnabled;
	mapping (address => uint256) internal approvedTokenPrice;
	
	constructor (string memory _name, string memory _symbol, address _epigeon){
	    epigeon = IEpigeon(_epigeon);
		name = _name;
		symbol = _symbol;
		highestTokenId = 0;
	}
	
	function burn(uint256 _tokenId) public {
		require(msg.sender == ICryptoPigeon(idtoCryptoPigeon[_tokenId]).getOwner());
		require(epigeon.getNFTContractAddress() == address(this));
		epigeon.burnPigeon(idtoCryptoPigeon[_tokenId]);
		delete cryptoPigeonToId[idtoCryptoPigeon[_tokenId]];
		delete idtoCryptoPigeon[_tokenId];
		super._burn(_tokenId);
	}
	
	function burnPigeonToken(uint256 _tokenId) public {
		require(msg.sender == ICryptoPigeon(idtoCryptoPigeon[_tokenId]).getOwner());
		require(epigeon.getNFTContractAddress() == address(this));
		delete cryptoPigeonToId[idtoCryptoPigeon[_tokenId]];
		delete idtoCryptoPigeon[_tokenId];
		super._burn(_tokenId);
	}
	
	function isTokenizedPigeon(address pigeon) public view returns (bool tokenized){
		return idtoCryptoPigeon[cryptoPigeonToId[pigeon]] == pigeon;
	}
	
	function mintingTokenPrice(address ERC20Token) public view returns (uint256 _mintingprice){
		_mintingprice = approvedTokenPrice[ERC20Token];
	}
	
	function mintForEther(uint256 factory_id) public payable {
	    require(msg.value >= mintingPrice + epigeon.getPigeonPriceForFactory(factory_id), "Not enough value");		
		_mintForAddress(msg.sender, factory_id);
	}
	
	function mintForFree() public {
	    require(freeMintEnabled || msg.sender == owner);				
		_mintForAddress(msg.sender, epigeon.getLastFactoryId());
	}
	
	function mintForToken(address ERC20Token, uint256 factory_id) public returns (bool){
		require (approvedTokenPrice[ERC20Token] > 0);
		require (epigeon.getPigeonTokenPriceForFactory(ERC20Token, factory_id) > 0);
		uint256 price = approvedTokenPrice[ERC20Token] + epigeon.getPigeonTokenPriceForFactory(ERC20Token, factory_id);
		if (IERC20(ERC20Token).transferFrom(msg.sender, owner, price) == true)
		{
			_mintForAddress(msg.sender, factory_id);
			return true;
		}
		else{
			return false;
		}
	}
	
	function name() public view returns (string memory _name){
		_name = name;
	}
	
	function payout() public {
		require(msg.sender == owner);
		owner.transfer(address(this).balance);
	}
	
	function pigeonAddressToToken(address  _pigeon) public view returns (uint256  tokenId){
		return cryptoPigeonToId[_pigeon];
	}
	
	function setFreeMintEnabled(bool enabled) public {
	    require(msg.sender == owner);
	    freeMintEnabled = enabled;
	}
	
	function setMintingPrice(uint256 _mintingprice) public {
	    require(msg.sender == owner);
		mintingPrice = _mintingprice;
	}
	
	function setMintingPrice(address ERC20Token, uint256 _mintingprice) public {
	    require(msg.sender == owner);
		approvedTokenPrice[ERC20Token] = _mintingprice;
	}
	
	function symbol() public view returns (string memory _symbol){
		_symbol = symbol;
	}
	
	function tokenContractAddress(uint256  _tokenId) public view validNFToken(_tokenId) returns (address rpigeon){
		return idtoCryptoPigeon[_tokenId];
	}
	
	function tokenizePigeon(address pigeon) public payable{
	    require(msg.value >= mintingPrice, "Not enough value");
		require(cryptoPigeonToId[pigeon] == 0);
		require(ICryptoPigeon(pigeon).getOwner() == msg.sender);
		require(ICryptoPigeon(pigeon).iAmPigeon());
		require(epigeon.validPigeon(pigeon, msg.sender));
		require(epigeon.getNFTContractAddress() == address(this));
	    highestTokenId++;
	    uint256 _tokenId = highestTokenId;
	    super._mint(msg.sender, _tokenId);
		_setTokenContractAddress(_tokenId, pigeon);
	}
	
	function tokenURI(uint256 _tokenId) public view returns (string metadata){
		metadata = IPigeonFactory(epigeon.getFactoryAddresstoId(ICryptoPigeon(idtoCryptoPigeon[_tokenId]).getFactoryId())).getMetaDataForPigeon(idtoCryptoPigeon[_tokenId]);
		return metadata;
	}
	
	function _mintForAddress(address _to, uint256 _factory_id) internal {
		require(epigeon.getNFTContractAddress() == address(this));
		highestTokenId++;
	    uint256 _tokenId = highestTokenId;
	    address pigeon = epigeon.createCryptoPigeonNFT(_to, _factory_id);
		super._mint(_to, _tokenId);
		_setTokenContractAddress(_tokenId, pigeon);
	}
	
	function _setTokenContractAddress(uint256  _tokenId, address  pigeon) internal validNFToken(_tokenId) {
		idtoCryptoPigeon[_tokenId] = pigeon;
		cryptoPigeonToId[pigeon] = _tokenId;
	}
	
	function _transfer(address _to, uint256 _tokenId) internal {
		require(epigeon.getNFTContractAddress() == address(this));
	    epigeon.transferPigeon(ICryptoPigeon(idtoCryptoPigeon[_tokenId]).getOwner(), _to, idtoCryptoPigeon[_tokenId]);
	    super._transfer(_to, _tokenId);
	}
}