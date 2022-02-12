// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.4.11;

import "./ownable.sol";
import "./EpigeonInterfaces.sol";

/*/---------------------------------------------------------------------------------------------------

to do: 
- ERC20 with lockable and reversable transactions depending on unlock
- Send pigeon with token to unlock (conversion between 2 tokens for read message - unlocking with the message itself)
- pigeon NFT update option (with remaining token id, but newly minted contract by updated factory; factory check, factory info in pigeon)
- messagebox for all (safe)
- subscriptionnél legyen közös privát kulcs a subscribereknek, amit kikérhetnek (ezzel a későbbi üzenetek olcsóbbak)
- metadata frissíthető legyen a galambból (alap metadata a factory settingben)
- bővíthető universal registry tömb epigonban (interface definícióval)
- mass message pigeon (address list, address list ellenőrzés token unlock-hoz)

*///----------------------------------------------------------------------------------------------------
//----------------------------------------------------------------------------------------------------

contract NameAndPublicKeyDirectory is INameAndPublicKeyDirectory{
    
    mapping (address => string) internal AddressToPublicKey;
    mapping (address => string) internal AddressToUserName;
    mapping (string => address) internal UserNameToAddress;

    
    function SetPublicKeyToAddress (string _key) public {
        AddressToPublicKey[msg.sender] = _key;
    }
    
    function GetPublicKeyForAddress (address _address) public view returns (string _key){
        _key = AddressToPublicKey[_address];
    }
    
    function SetUserNameToAddress (string _name) public {
        require(UserNameToAddress[_name] == msg.sender || UserNameToAddress[_name] == 0, "Name is already in use");
        UserNameToAddress[AddressToUserName[msg.sender]] = 0;
        AddressToUserName[msg.sender] = _name;
        UserNameToAddress[_name] = msg.sender;
    }
    
    function GetUserNameForAddress (address _address) public view returns (string _name){
        _name = AddressToUserName[_address];
    }
}
//----------------------------------------------------------------------------------------------------

contract PigeonDestinationDirectory is IPigeonDestinationDirectory{
    
    address public epigeonaddress;
    
    mapping (address => address[]) internal ToAddressToPigeon;
	mapping (address => uint256) internal PigeonToToAddressIndex;
	mapping (address => bool) internal PigeonToAddressExists;
	
	constructor (){
	    epigeonaddress = msg.sender;
	}
	
	function changeToAddress(address new_to_address, address old_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
		require(PigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
		
		//Push new to address
		ToAddressToPigeon[new_to_address].push(pigeon);
		PigeonToToAddressIndex[pigeon] = ToAddressToPigeon[new_to_address].length-1;
		
		//Delete old to address
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = PigeonToToAddressIndex[pigeon];
		uint256 lastIdIndex = ToAddressToPigeon[old_to_address].length - 1;
		if (ToAddressToPigeon[old_to_address][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = ToAddressToPigeon[old_to_address][lastIdIndex];
		  ToAddressToPigeon[old_to_address][PigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
		  PigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
		}
		delete ToAddressToPigeon[old_to_address][lastIdIndex];
		ToAddressToPigeon[old_to_address].length--;
	}
	
	function setToAddress(address new_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);	
		//Push new to address
		require(PigeonToAddressExists[msg.sender] != true, "Pigeon already has recipient entry");
		ToAddressToPigeon[new_to_address].push(pigeon);
		PigeonToToAddressIndex[pigeon] = ToAddressToPigeon[new_to_address].length-1;
		
		PigeonToAddressExists[pigeon] = true;		
	}
	
	function deleteToAddress(address old_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        //require(pigeon.iAmPigeon());	
		//Delete old to address
		require(PigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
		
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = PigeonToToAddressIndex[pigeon];
		uint256 lastIdIndex = ToAddressToPigeon[old_to_address].length - 1;
		if (ToAddressToPigeon[old_to_address][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = ToAddressToPigeon[old_to_address][lastIdIndex];
		  ToAddressToPigeon[old_to_address][PigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
		  PigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
		}
		delete ToAddressToPigeon[old_to_address][lastIdIndex];
		ToAddressToPigeon[old_to_address].length--;
		
		PigeonToAddressExists[pigeon] = false;
	}
	
	function deleteToAddressByEpigeon(address pigeon){
	    require(epigeonaddress == msg.sender, "Available only for Epigeon Smart Contract");
		require(PigeonToAddressExists[pigeon] == true, "Pigeon has no recipient entry to change");
	    address pToAddress = ICryptoPigeon(pigeon).getToAddress();
		address pigeonToRemove = pigeon;		
	    //Delete to address
        if (ICryptoPigeon(pigeon).hasFlown()){
    		uint256 pigeonToRemoveIndex = PigeonToToAddressIndex[pigeon];
    		uint256 lastIdIndex = ToAddressToPigeon[pToAddress].length - 1;
    		if (ToAddressToPigeon[pToAddress][lastIdIndex] != pigeonToRemove)
    		{
    		  address alastPigeon = ToAddressToPigeon[pToAddress][lastIdIndex];
    		  ToAddressToPigeon[pToAddress][PigeonToToAddressIndex[pigeonToRemove]] = alastPigeon;
    		  PigeonToToAddressIndex[alastPigeon] = pigeonToRemoveIndex;
    		}
    		delete ToAddressToPigeon[pToAddress][lastIdIndex];
		    ToAddressToPigeon[pToAddress].length--;
         }
		 PigeonToAddressExists[pigeon] = false;
	}
	
	function PigeonsSentToAddressLenght(address toaddress) public view returns (uint256 length){
		length = ToAddressToPigeon[toaddress].length;
	}
	
	function PigeonSentToAddressByIndex(address toaddress, uint index) public view returns (address rpaddress){
		rpaddress = ToAddressToPigeon[toaddress][index];
	}
	
	function isPigeon (address addr) internal returns (bool indeed){
		ICryptoPigeon pigeon = ICryptoPigeon(addr);
        if(IEpigeon(epigeonaddress).validPigeon(addr, pigeon.getOwner())) {
			return true;
		}
		else{
			return false;
		}
	}
}
//----------------------------------------------------------------------------------------------------

contract Epigeon is IEpigeon, Ownable
  {
	string Egigeon_URI;
	address NFTContractAddress;
	
	INameAndPublicKeyDirectory public KeyDirectory;
	IPigeonDestinationDirectory public Destinations;
	
	
	uint256[] FactoryIds;
	mapping (address => uint256) disabledFactorys;
	mapping (uint256 => address) FactoryIdtoAddress;

	mapping (address => address[]) internal OwnerToPigeon;
	mapping (address => uint256) internal PigeonToOwnerIndex;

	
	constructor (){ 
		owner = msg.sender;
		KeyDirectory = new NameAndPublicKeyDirectory();
		Destinations = new PigeonDestinationDirectory();
	}
	
	function setUri(string uri) onlyOwner public {	
		require(owner == msg.sender, "Only owner");
		Egigeon_URI = uri;
	}
	
	function setNFTContractAddress(address _nftcontract) onlyOwner public {	
		require(owner == msg.sender, "Only owner");
		require(NFTContractAddress == address(0), "NFT contract already set");
		NFTContractAddress = _nftcontract;
	}
	
	function getNFTContractAddress() public view returns (address _nftcontract) {	
		return NFTContractAddress;
	}
	
	function getFactoryCount() public view returns (uint256 count){
		return FactoryIds.length;
	}
	
	function getIdforFactory(uint256 _i) public view returns (uint256 id){
		return FactoryIds[_i];
	}
	
	function getFactoryAddresstoId(uint256 _id) public view returns (address _factory){
		return FactoryIdtoAddress[_id];
	}
	
/*	function getFactoryPrice(uint256 id) public view returns (uint256 price){
		return IPigeonFactory(FactoryIdtoAddress[id]).getFactoryPrice();
	}
*/	
	function addFactory(address _factory) public {
		require(msg.sender == owner, "Only owner");
		IPigeonFactory factory = IPigeonFactory(_factory);
        require(factory.iAmFactory(), "Not a factory");
		require(factory.AmIEpigeon(), "Not the factory's Epigeon");
        require(FactoryIdtoAddress[factory.getFactoryId()] == address(0), "Existing Factory ID");
		FactoryIds.push(factory.getFactoryId());
		FactoryIdtoAddress[factory.getFactoryId()] = _factory;
	}
	
	function disableFactory(uint256 factory_id) public {
		require(msg.sender == owner, "Only owner");
		disabledFactorys[FactoryIdtoAddress[factory_id]] = 1;
	}
	
	function enableFactory(uint256 factory_id) public {
		require(msg.sender == owner, "Only owner");
		require(FactoryIdtoAddress[factory_id] != address(0));
		disabledFactorys[FactoryIdtoAddress[factory_id]] = 0;
	}
	
	function isFactoryDisabled(address _address) public view returns (uint256 disabled){
		return disabledFactorys[_address];
	}
	
	function getDestinations() public view returns (IPigeonDestinationDirectory dests){
		return Destinations;
	}
	
	function getKeyDirectory() public view returns (INameAndPublicKeyDirectory keyd){
		return KeyDirectory;
	}
	
	function getPigeonPriceForFactory(uint256 factory_id) public view returns (uint256 price){
		return IPigeonFactory(FactoryIdtoAddress[factory_id]).getFactoryPrice();
	}
	
	function getPigeonTokenPriceForFactory(address ERC20Token, uint256 factory_id) public view returns (uint256 price){
		return IPigeonFactory(FactoryIdtoAddress[factory_id]).getFactoryTokenPrice(ERC20Token);
	}
	
	function getLastFactoryId() public view returns (uint256 id){
		return FactoryIds[FactoryIds.length-1];
	}
		
	event e_PigeonCreated(ICryptoPigeon pigeon);	
	function createCryptoPigeonNFT(address _to, uint256 factory_id) public returns (address pigeonaddress) {
		require(NFTContractAddress == msg.sender, "Available only for the NFT contract");	
		return _createPigeon(_to, factory_id);
    }
	
	function createCryptoPigeonByLatestFactory() public payable returns (address pigeonaddress) {
		require(msg.value >= getPigeonPriceForFactory(getLastFactoryId()), "Not enough value");
		return _createPigeon(msg.sender, getLastFactoryId());
    }
	
	function createCryptoPigeon(uint256 factory_id) public payable returns (address pigeonaddress) {
		require(msg.value >= getPigeonPriceForFactory(factory_id), "Not enough value");	
		return _createPigeon(msg.sender, factory_id);
    }
	
	function createCryptoPigeonForToken(address ERC20Token, uint256 factory_id) public returns (address pigeonaddress) {
		require(getPigeonTokenPriceForFactory(ERC20Token, factory_id) > 0, "Price for token not available");
		require(IERC20(ERC20Token).balanceOf(msg.sender) >= getPigeonTokenPriceForFactory(ERC20Token, factory_id), "Not enough balance");
		require(IERC20(ERC20Token).allowance(msg.sender, address(this)) >= getPigeonTokenPriceForFactory(ERC20Token, factory_id), "Not enough allowance");
		IERC20(ERC20Token).transferFrom(msg.sender, owner, getPigeonTokenPriceForFactory(ERC20Token, factory_id));
		return _createPigeon(msg.sender, factory_id);
    }
	
	function _createPigeon(address _to, uint256 factory_id) internal returns (address pigeonaddress) {
		require(isFactoryDisabled(FactoryIdtoAddress[factory_id]) == 0, "Factory is disabled");
		ICryptoPigeon pigeon = IPigeonFactory(FactoryIdtoAddress[factory_id]).createCryptoPigeon( _to);
        OwnerToPigeon[_to].push(pigeon);
        PigeonToOwnerIndex[pigeon] = OwnerToPigeon[_to].length-1;
		emit e_PigeonCreated(pigeon);
		return pigeon;
	}
	
	function PigeonsCountOfOwner(address pigeonowner) public view returns (uint256 length){
		length = OwnerToPigeon[pigeonowner].length;
		return length;
	}
	
	function PigeonOfOwnerByIndex(address pigeonowner, uint index) public view returns (address rpaddress){
		rpaddress = OwnerToPigeon[pigeonowner][index];
		return rpaddress;
	}
	
	function validPigeon(address pigeon, address owner) public view returns (bool valid){
		require(pigeon != address(0), "Null address");
		if (OwnerToPigeon[owner][PigeonToOwnerIndex[pigeon]] == pigeon)
		{
			return true;
		}
		else
		{
			return false;
		}
	}
	
	function transferPigeon(address _from, address _to, address pigeon) public {
	
		if (IEpigeonNFT(NFTContractAddress).isTokenizedPigeon(pigeon)) {
			require(NFTContractAddress == msg.sender, "Tokenized Pigeon can only be transferred by NFT contract");
		}
		else{
			require(ICryptoPigeon(pigeon).getOwner() == msg.sender || pigeon == msg.sender, "Only pigeon owner");
		}
		
        //Push new owner address
		OwnerToPigeon[_to].push(pigeon);
		PigeonToOwnerIndex[pigeon] = OwnerToPigeon[_to].length-1;
		
		//Delete old owner address
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = PigeonToOwnerIndex[pigeon];
		uint256 lastIdIndex = OwnerToPigeon[_from].length - 1;
		if (OwnerToPigeon[_from][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = OwnerToPigeon[_from][lastIdIndex];
		  OwnerToPigeon[_from][PigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
		  PigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;
		  
		}
		delete OwnerToPigeon[_from][lastIdIndex];
		OwnerToPigeon[_from].length--;
		
		//Delete old to address
		Destinations.deleteToAddressByEpigeon(pigeon);
         
        //Transfer contract too
        ICryptoPigeon(pigeon).transferPigeon(_to);
	}
	
	function BurnPigeon(address pigeon) public {
        require((NFTContractAddress == msg.sender) || ((IEpigeonNFT(NFTContractAddress).isTokenizedPigeon(pigeon) == false) && (ICryptoPigeon(pigeon).getOwner() == msg.sender)));
        address pOwner = ICryptoPigeon(pigeon).getOwner();
		address pigeonToRemove = pigeon;
		
		//Delete old owner address
		uint256 pigeonToRemoveIndex = PigeonToOwnerIndex[pigeon];
		uint256 lastIdIndex = OwnerToPigeon[pOwner].length - 1;
		if (OwnerToPigeon[pOwner][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = OwnerToPigeon[pOwner][lastIdIndex];
		  OwnerToPigeon[pOwner][PigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
		  PigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;		  
		}
		delete OwnerToPigeon[pOwner][lastIdIndex];
		OwnerToPigeon[pOwner].length--;
         
        //Delete to address
        Destinations.deleteToAddressByEpigeon(pigeon);
        
        //Burn contract too
        ICryptoPigeon(pigeon).burnPigeon();        
	}
	
	function payout() public {
		require(msg.sender == owner, "Only owner");
		owner.transfer(address(this).balance);
	}
}