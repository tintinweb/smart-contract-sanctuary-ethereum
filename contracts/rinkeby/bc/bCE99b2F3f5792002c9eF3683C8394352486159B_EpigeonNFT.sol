// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./nf-token-enumerable.sol";
import "./EpigeonInterfaces.sol";
import "./ownable.sol";

//----------------------------------------------------------------------------------

contract EpigeonNFT is NFTokenEnumerable, Ownable
  {
    IEpigeon public epigeon;
      
    string internal nftName;
	string internal nftSymbol;
	mapping (uint256 => address) internal IdtoCryptoPigeon;
	mapping (address => uint256) internal CryptoPigeonToId;
	uint256 MintingPrice;
	uint256 HighestTokenId;
	bool freeMintEnabled;
	mapping (address => uint256) internal ApprovedTokenPrice;
	
	constructor (string memory _name, string memory _symbol, address _epigeon){
	    epigeon = IEpigeon(_epigeon);
		nftName = _name;
		nftSymbol = _symbol;
		HighestTokenId = 0;
	}
	
	function name() public view returns (string memory _name){
		_name = nftName;
	}
	
	function symbol() public view returns (string memory _symbol){
		_symbol = nftSymbol;
	}
	
	function tokenURI(uint256 _tokenId) public view returns (string metadata){
		metadata = IPigeonFactory(epigeon.getFactoryAddresstoId(ICryptoPigeon(IdtoCryptoPigeon[_tokenId]).getFactoryId())).getMetaDataForPigeon(IdtoCryptoPigeon[_tokenId]);
		return metadata;
	}
	
	function mintingPrice() public view returns (uint256 _mintingprice){
		_mintingprice = MintingPrice;
	}
	
	function mintingPrice(address ERC20Token) public view returns (uint256 _mintingprice){
		_mintingprice = ApprovedTokenPrice[ERC20Token];
	}
	
	function setMintingPrice(uint256 _mintingprice) public {
	    require(msg.sender == owner);
		MintingPrice = _mintingprice;
	}
	
	function setMintingPrice(address ERC20Token, uint256 _mintingprice) public {
	    require(msg.sender == owner);
		ApprovedTokenPrice[ERC20Token] = _mintingprice;
	}
	
	function setFreeMintEnabled(bool enabled) public {
	    require(msg.sender == owner);
	    freeMintEnabled = enabled;
	}
	
	function tokenContractAddress(uint256  _tokenId) public view validNFToken(_tokenId) returns (address rpigeon){
		return IdtoCryptoPigeon[_tokenId];
	}
	
	function PigeonAddressToToken(address  _pigeon) public view returns (uint256  tokenId){
		return CryptoPigeonToId[_pigeon];
	}
	
	function setTokenContractAddress(uint256  _tokenId, address  pigeon) internal validNFToken(_tokenId) {
		IdtoCryptoPigeon[_tokenId] = pigeon;
		CryptoPigeonToId[pigeon] = _tokenId;
	}
	
	function mintForEther(uint256 factory_id) public payable {
	    require(msg.value >= MintingPrice + epigeon.getPigeonPriceForFactory(factory_id));		
		_mintForAddress(msg.sender, factory_id);
	}
	
	function mintForToken(address ERC20Token, uint256 factory_id) public returns (bool){
		require (ApprovedTokenPrice[ERC20Token] > 0);
		require (epigeon.getPigeonTokenPriceForFactory(ERC20Token, factory_id) > 0);
		uint256 price = ApprovedTokenPrice[ERC20Token] + epigeon.getPigeonTokenPriceForFactory(ERC20Token, factory_id);
		if (IERC20(ERC20Token).transferFrom(msg.sender, owner, price) == true)
		{
			_mintForAddress(msg.sender, factory_id);
			return true;
		}
		else{
			return false;
		}
	}
	
	function mintForFree() public {
	    require(freeMintEnabled || msg.sender == owner);				
		_mintForAddress(msg.sender, epigeon.getLastFactoryId());
	}
	
	function _mintForAddress(address _to, uint256 _factory_id) internal {
		require(epigeon.getNFTContractAddress() == address(this));
		HighestTokenId++;
	    uint256 _tokenId = HighestTokenId;
	    address pigeon = epigeon.createCryptoPigeonNFT(_to, _factory_id);
		super._mint(_to, _tokenId);
		setTokenContractAddress(_tokenId, pigeon);
	}
	
	function tokenizePigeon(address pigeon) public payable{
	    require(msg.value >= MintingPrice);
		require(CryptoPigeonToId[pigeon] == 0);
		require(ICryptoPigeon(pigeon).getOwner() == msg.sender);
		require(ICryptoPigeon(pigeon).iAmPigeon());
		require(epigeon.validPigeon(pigeon, msg.sender));
		require(epigeon.getNFTContractAddress() == address(this));
	    HighestTokenId++;
	    uint256 _tokenId = HighestTokenId;
	    super._mint(msg.sender, _tokenId);
		setTokenContractAddress(_tokenId, pigeon);
	}
	
	function isTokenizedPigeon(address pigeon) public view returns (bool tokenized){
		if (IdtoCryptoPigeon[CryptoPigeonToId[pigeon]] == pigeon){
			return true;
		}
		else{
			return false;
		}
	}
	
	function burnPigeonToken(uint256 _tokenId) public {
		require(msg.sender == ICryptoPigeon(IdtoCryptoPigeon[_tokenId]).getOwner());
		require(epigeon.getNFTContractAddress() == address(this));
		delete CryptoPigeonToId[IdtoCryptoPigeon[_tokenId]];
		delete IdtoCryptoPigeon[_tokenId];
		super._burn(_tokenId);
	}
	
	function _transfer(address _to, uint256 _tokenId) internal {
		require(epigeon.getNFTContractAddress() == address(this));
	    epigeon.transferPigeon(ICryptoPigeon(IdtoCryptoPigeon[_tokenId]).getOwner(), _to, IdtoCryptoPigeon[_tokenId]);
	    super._transfer(_to, _tokenId);
	}
	
	function burn(uint256 _tokenId) public {
		require(msg.sender == ICryptoPigeon(IdtoCryptoPigeon[_tokenId]).getOwner());
		require(epigeon.getNFTContractAddress() == address(this));
		epigeon.BurnPigeon(IdtoCryptoPigeon[_tokenId]);
		delete CryptoPigeonToId[IdtoCryptoPigeon[_tokenId]];
		delete IdtoCryptoPigeon[_tokenId];
		super._burn(_tokenId);
	}
	
	function payout() public {
		require(msg.sender == owner);
		owner.transfer(address(this).balance);
	}
}