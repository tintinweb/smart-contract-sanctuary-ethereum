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
    
    mapping (address => string) internal addressToPublicKey;
    mapping (address => string) internal addressToUserName;
    mapping (string => address) internal userNameToAddress;

    
    function SetPublicKeyToAddress (string _key) public {
        addressToPublicKey[msg.sender] = _key;
    }
    
    function GetPublicKeyForAddress (address _address) public view returns (string _key){
        _key = addressToPublicKey[_address];
    }
    
    function SetUserNameToAddress (string _name) public {
        require(userNameToAddress[_name] == msg.sender || userNameToAddress[_name] == 0, "Name is already in use");
        userNameToAddress[addressToUserName[msg.sender]] = 0;
        addressToUserName[msg.sender] = _name;
        userNameToAddress[_name] = msg.sender;
    }
    
    function GetUserNameForAddress (address _address) public view returns (string _name){
        _name = addressToUserName[_address];
    }
}
//----------------------------------------------------------------------------------------------------

contract PigeonDestinationDirectory is IPigeonDestinationDirectory{
    
    address public epigeonAddress;
    
    mapping (address => address[]) internal toAddressToPigeon;
	mapping (address => uint256) internal pigeonToToAddressIndex;
	mapping (address => bool) internal pigeonToAddressExists;
	
	constructor (){
	    epigeonAddress = msg.sender;
	}
	
	function changeToAddress(address new_to_address, address old_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
		require(pigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
		
		//Push new to address
		toAddressToPigeon[new_to_address].push(pigeon);
		pigeonToToAddressIndex[pigeon] = toAddressToPigeon[new_to_address].length-1;
		
		//Delete old to address
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
		uint256 lastIdIndex = toAddressToPigeon[old_to_address].length - 1;
		if (toAddressToPigeon[old_to_address][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = toAddressToPigeon[old_to_address][lastIdIndex];
		  toAddressToPigeon[old_to_address][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
		  pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
		}
		delete toAddressToPigeon[old_to_address][lastIdIndex];
		toAddressToPigeon[old_to_address].length--;
	}
	
	function setToAddress(address new_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);	
		//Push new to address
		require(pigeonToAddressExists[msg.sender] != true, "Pigeon already has recipient entry");
		toAddressToPigeon[new_to_address].push(pigeon);
		pigeonToToAddressIndex[pigeon] = toAddressToPigeon[new_to_address].length-1;
		
		pigeonToAddressExists[pigeon] = true;		
	}
	
	function deleteToAddress(address old_to_address) public {
		//Check if the call is from a CryptoPigeon
		require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
	    ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        //require(pigeon.iAmPigeon());	
		//Delete old to address
		require(pigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
		
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
		uint256 lastIdIndex = toAddressToPigeon[old_to_address].length - 1;
		if (toAddressToPigeon[old_to_address][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = toAddressToPigeon[old_to_address][lastIdIndex];
		  toAddressToPigeon[old_to_address][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
		  pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
		}
		delete toAddressToPigeon[old_to_address][lastIdIndex];
		toAddressToPigeon[old_to_address].length--;
		
		pigeonToAddressExists[pigeon] = false;
	}
	
	function deleteToAddressByEpigeon(address pigeon) public {
	    require(epigeonAddress == msg.sender, "Available only for Epigeon Smart Contract");
		require(pigeonToAddressExists[pigeon] == true, "Pigeon has no recipient entry to change");
	    address pToAddress = ICryptoPigeon(pigeon).getToAddress();
		address pigeonToRemove = pigeon;		
	    //Delete to address
        if (ICryptoPigeon(pigeon).hasFlown()){
    		uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
    		uint256 lastIdIndex = toAddressToPigeon[pToAddress].length - 1;
    		if (toAddressToPigeon[pToAddress][lastIdIndex] != pigeonToRemove)
    		{
    		  address alastPigeon = toAddressToPigeon[pToAddress][lastIdIndex];
    		  toAddressToPigeon[pToAddress][pigeonToToAddressIndex[pigeonToRemove]] = alastPigeon;
    		  pigeonToToAddressIndex[alastPigeon] = pigeonToRemoveIndex;
    		}
    		delete toAddressToPigeon[pToAddress][lastIdIndex];
		    toAddressToPigeon[pToAddress].length--;
         }
		 pigeonToAddressExists[pigeon] = false;
	}
	
	function PigeonsSentToAddressLenght(address toaddress) public view returns (uint256 length){
		length = toAddressToPigeon[toaddress].length;
	}
	
	function PigeonSentToAddressByIndex(address toaddress, uint index) public view returns (address rpaddress){
		rpaddress = toAddressToPigeon[toaddress][index];
	}
	
	function _isPigeon (address addr) internal view returns (bool indeed){
		ICryptoPigeon pigeon = ICryptoPigeon(addr);
        return IEpigeon(epigeonAddress).validPigeon(addr, pigeon.getOwner());
	}
}
//----------------------------------------------------------------------------------------------------

contract Epigeon is IEpigeon, Ownable
  {
	string egigeonURI;
	address nftContractAddress;
	
	INameAndPublicKeyDirectory public keyDirectory;
	IPigeonDestinationDirectory public pigeonDestinations;
	
	
	uint256[] factoryIds;
	mapping (address => bool) disabledFactories;
	mapping (uint256 => address) factoryIdtoAddress;

	mapping (address => address[]) internal ownerToPigeon;
	mapping (address => uint256) internal pigeonToOwnerIndex;

	
	constructor (){ 
		owner = msg.sender;
		keyDirectory = new NameAndPublicKeyDirectory();
		pigeonDestinations = new PigeonDestinationDirectory();
	}
	
	function setUri(string uri) onlyOwner public {	
		require(owner == msg.sender, "Only owner");
		egigeonURI = uri;
	}
	
	function setNFTContractAddress(address _nftcontract) onlyOwner public {	
		require(owner == msg.sender, "Only owner");
		require(nftContractAddress == address(0), "NFT contract already set");
		nftContractAddress = _nftcontract;
	}
	
	function getNFTContractAddress() public view returns (address _nftcontract) {	
		return nftContractAddress;
	}
	
	function getFactoryCount() public view returns (uint256 count){
		return factoryIds.length;
	}
	
	function getIdforFactory(uint256 _i) public view returns (uint256 id){
		return factoryIds[_i];
	}
	
	function getFactoryAddresstoId(uint256 _id) public view returns (address _factory){
		return factoryIdtoAddress[_id];
	}
	
/*	function getFactoryPrice(uint256 id) public view returns (uint256 price){
		return IPigeonFactory(factoryIdtoAddress[id]).getFactoryPrice();
	}
*/	
	function addFactory(address _factory) public {
		require(msg.sender == owner, "Only owner");
		IPigeonFactory factory = IPigeonFactory(_factory);
        require(factory.iAmFactory(), "Not a factory");
		require(factory.AmIEpigeon(), "Not the factory's Epigeon");
        require(factoryIdtoAddress[factory.getFactoryId()] == address(0), "Existing Factory ID");
		factoryIds.push(factory.getFactoryId());
		factoryIdtoAddress[factory.getFactoryId()] = _factory;
		disabledFactories[_factory] = false;
	}
	
	function disableFactory(uint256 factory_id) public {
		require(msg.sender == owner, "Only owner");
		disabledFactories[factoryIdtoAddress[factory_id]] = true;
	}
	
	function enableFactory(uint256 factory_id) public {
		require(msg.sender == owner, "Only owner");
		require(factoryIdtoAddress[factory_id] != address(0));
		disabledFactories[factoryIdtoAddress[factory_id]] = false;
	}
	
	function isFactoryDisabled(address _address) public view returns (bool disabled){
		return disabledFactories[_address];
	}
	
	function getDestinations() public view returns (IPigeonDestinationDirectory dests){
		return pigeonDestinations;
	}
	
	function getKeyDirectory() public view returns (INameAndPublicKeyDirectory keyd){
		return keyDirectory;
	}
	
	function getPigeonPriceForFactory(uint256 factory_id) public view returns (uint256 price){
		return IPigeonFactory(factoryIdtoAddress[factory_id]).getFactoryPrice();
	}
	
	function getPigeonTokenPriceForFactory(address ERC20Token, uint256 factory_id) public view returns (uint256 price){
		return IPigeonFactory(factoryIdtoAddress[factory_id]).getFactoryTokenPrice(ERC20Token);
	}
	
	function getLastFactoryId() public view returns (uint256 id){
		return factoryIds[factoryIds.length-1];
	}
		
	event e_PigeonCreated(ICryptoPigeon pigeon);	
	function createCryptoPigeonNFT(address _to, uint256 factory_id) public returns (address pigeonaddress) {
		require(nftContractAddress == msg.sender, "Available only for the NFT contract");	
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
	
	function PigeonsCountOfOwner(address pigeonowner) public view returns (uint256 length){
		length = ownerToPigeon[pigeonowner].length;
		return length;
	}
	
	function PigeonOfOwnerByIndex(address pigeonowner, uint index) public view returns (address rpaddress){
		rpaddress = ownerToPigeon[pigeonowner][index];
		return rpaddress;
	}
	
	function validPigeon(address pigeon, address owner) public view returns (bool valid){
		require(pigeon != address(0), "Null address");
		return ownerToPigeon[owner][pigeonToOwnerIndex[pigeon]] == pigeon;
	}
	
	function transferPigeon(address _from, address _to, address pigeon) public {
	
		if (IEpigeonNFT(nftContractAddress).isTokenizedPigeon(pigeon)) {
			require(nftContractAddress == msg.sender, "Tokenized Pigeon can only be transferred by NFT contract");
		}
		else{
			require(ICryptoPigeon(pigeon).getOwner() == msg.sender || pigeon == msg.sender, "Only pigeon owner");
		}
		
        //Push new owner address
		ownerToPigeon[_to].push(pigeon);
		pigeonToOwnerIndex[pigeon] = ownerToPigeon[_to].length-1;
		
		//Delete old owner address
		address pigeonToRemove = pigeon;
		uint256 pigeonToRemoveIndex = pigeonToOwnerIndex[pigeon];
		uint256 lastIdIndex = ownerToPigeon[_from].length - 1;
		if (ownerToPigeon[_from][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = ownerToPigeon[_from][lastIdIndex];
		  ownerToPigeon[_from][pigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
		  pigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;
		  
		}
		delete ownerToPigeon[_from][lastIdIndex];
		ownerToPigeon[_from].length--;
		
		//Delete old to address
		pigeonDestinations.deleteToAddressByEpigeon(pigeon);
         
        //Transfer contract too
        ICryptoPigeon(pigeon).transferPigeon(_to);
	}
	
	function burnPigeon(address pigeon) public {
        require((nftContractAddress == msg.sender) || ((IEpigeonNFT(nftContractAddress).isTokenizedPigeon(pigeon) == false) && (ICryptoPigeon(pigeon).getOwner() == msg.sender)), "Not authorized");
        address pOwner = ICryptoPigeon(pigeon).getOwner();
		address pigeonToRemove = pigeon;
		
		//Delete old owner address
		uint256 pigeonToRemoveIndex = pigeonToOwnerIndex[pigeon];
		uint256 lastIdIndex = ownerToPigeon[pOwner].length - 1;
		if (ownerToPigeon[pOwner][lastIdIndex] != pigeonToRemove)
		{
		  address lastPigeon = ownerToPigeon[pOwner][lastIdIndex];
		  ownerToPigeon[pOwner][pigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
		  pigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;		  
		}
		delete ownerToPigeon[pOwner][lastIdIndex];
		ownerToPigeon[pOwner].length--;
         
        //Delete to address
        pigeonDestinations.deleteToAddressByEpigeon(pigeon);
        
        //Burn contract too
        ICryptoPigeon(pigeon).burnPigeon();        
	}
	
	function payout() public {
		require(msg.sender == owner, "Only owner");
		owner.transfer(address(this).balance);
	}
	
	function _createPigeon(address _to, uint256 factory_id) internal returns (address pigeonaddress) {
		require(isFactoryDisabled(factoryIdtoAddress[factory_id]) == false, "Factory is disabled");
		ICryptoPigeon pigeon = IPigeonFactory(factoryIdtoAddress[factory_id]).createCryptoPigeon( _to);
        ownerToPigeon[_to].push(pigeon);
        pigeonToOwnerIndex[pigeon] = ownerToPigeon[_to].length-1;
		emit e_PigeonCreated(pigeon);
		return pigeon;
	}
}