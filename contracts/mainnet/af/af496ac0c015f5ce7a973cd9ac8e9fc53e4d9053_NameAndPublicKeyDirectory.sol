/**
 *Submitted for verification at Etherscan.io on 2022-03-19
*/

// File: EpigeonInterfaces.sol


pragma solidity ^0.4.11;

//----------------------------------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
//----------------------------------------------------------------------------------------------------
interface IERC777 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function granularity() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function send(address recipient, uint256 amount, bytes data) external;
    function burn(uint256 amount, bytes data) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function defaultOperators() external view returns (address[] memory);
    function operatorSend(address sender, address recipient, uint256 amount, bytes data, bytes operatorData) external;
    function operatorBurn(address account, uint256 amount, bytes data, bytes operatorData) external;
    event Sent( address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}
//----------------------------------------------------------------------------------------------------
interface ILockable {
    function lock(address to, uint256 amount, bytes32 hash) external;
    function operatorLock(address from, address to, uint256 amount, bytes32 hash, bytes data, bytes operatorData) external;
    function unlock(string unlockerPhrase) external;
    function operatorUnlock(address to, string unlockerPhrase, bytes data, bytes operatorData) external;
    function reclaim(address to, string unlockerPhrase) external;
    function operatorReclaim(address from, address to, string unlockerPhrase, bytes data, bytes operatorData) external;
    function unlockByLockedCoinContract(address to, bytes32 hash) external;
    function reclaimByLockedCoinContract(address from, address to, bytes32 hash) external;
    function lockedSupply() external view returns (uint256 locked_supply);
    function lockedAmount(address from, bytes32 hash) external view returns (uint256 amount);
    function lockedBalanceOf(address account) external view returns (uint256);
}
//----------------------------------------------------------------------------------------------------
interface IPigeonFactory {
    function createCryptoPigeon(address to) external returns (ICryptoPigeon pigeonAddress);    
    function iAmFactory() external pure returns (bool);
    function amIEpigeon() external returns (bool);
    function factoryId() external view returns (uint256 id);
    function getMetaDataForPigeon(address pigeon) external view returns (string metadata);
    function mintingPrice() external view returns (uint256 price);
    function totalSupply() external view returns (uint256 supply);
    function maxSupply() external view returns (uint256 supply);
    function getFactoryTokenPrice(address ERC20Token) external view returns (uint256 price);
}
//----------------------------------------------------------------------------------------------------
interface ICryptoPigeon {
    function burnPigeon() external;    
    function iAmPigeon() external pure returns (bool); 
    function transferPigeon(address newOwner) external; 
    function hasFlown() external view returns (bool);
    function toAddress() external view returns (address addressee);   
    function owner() external view returns (address ownerAddress);
    function manager() external view returns (address managerAddress);
    function factoryId() external view returns (uint256 id);
}
//----------------------------------------------------------------------------------------------------
interface IEpigeon {
    function pigeonDestinations() external view returns (IPigeonDestinationDirectory destinations);
    function nameAndKeyDirectory() external view returns (INameAndPublicKeyDirectory directory);
    function getLastFactoryId() external view returns (uint256 id);
    function getFactoryAddresstoId(uint256 id) external view returns (address factoryAddress);
    function getPigeonPriceForFactory(uint256 factoryId) external view returns (uint256 price);
    function getPigeonTokenPriceForFactory(address ERC20Token, uint256 factoryId) external view returns (uint256 price);
    function createCryptoPigeonNFT(address to, uint256 factoryId) external returns (address pigeonaddress);
    function transferPigeon(address from, address to, address pigeon) external;
    function burnPigeon(address pigeon) external;
    function nftContractAddress() external view returns (address nftContract);
    function validPigeon(address pigeon, address pigeonOwner) external view returns (bool);
}
//----------------------------------------------------------------------------------------------------
interface IEpigeonNFT {
    function isTokenizedPigeon(address pigeon) external view returns (bool);
}
//----------------------------------------------------------------------------------------------------
interface INameAndPublicKeyDirectory {
    function getPublicKeyForAddress (address owner) external view returns (string key); 
    function getUserNameForAddress (address owner) external view returns (string name);
}
//----------------------------------------------------------------------------------------------------
interface IPigeonDestinationDirectory{
    function changeToAddress(address newToAddress, address oldToAddress) external;
    function setToAddress(address newToAddress) external;
    function deleteToAddress(address oldToAddress) external;
    function deleteToAddressByEpigeon(address pigeon) external;
    function pigeonsSentToAddressLenght(address toAddress) external view returns (uint256 length);
    function pigeonSentToAddressByIndex(address toAddress, uint index) external view returns (address pigeonAddress);   
}
//----------------------------------------------------------------------------------------------------
interface IPigeonManagerDirectory{
    function changeManager(address newManager, address oldManager) external;
    function deleteManager(address oldManager) external;
    function setManager(address newManager) external;
    function pigeonsOfManagerLenght(address toAddress) external view returns (uint256 length);
    function pigeonOfManagerByIndex(address toAddress, uint index) external view returns (address pigeonAddress);   
}
//----------------------------------------------------------------------------------------------------


// File: Epigeon.sol


pragma solidity ^0.4.11;


//----------------------------------------------------------------------------------------------------

contract NameAndPublicKeyDirectory is INameAndPublicKeyDirectory{
    
    mapping (address => string) internal addressToPublicKey;
    mapping (address => string) internal addressToUserName;
    mapping (string => address) internal userNameToAddress;
	
	Epigeon epigeonAddress;
	uint256 public uniqueNamePrice;
	
	constructor (){
        epigeonAddress = Epigeon(msg.sender);
    }
    
    function getPublicKeyForAddress (address owner) public view returns (string key){
        return addressToPublicKey[owner];
    }
    
    function getUserNameForAddress (address owner) public view returns (string name){
        return addressToUserName[owner];
    }
    
    function setPublicKeyToAddress (string key) public {
        addressToPublicKey[msg.sender] = key;
    }
	
	function setUniqueNamePrice (uint256 price) public {
		require(msg.sender == epigeonAddress.owner(), "Only Epigeon owner");
        uniqueNamePrice = price;
    }
    
    function setUserNameToAddress (string name) public payable {
        require(userNameToAddress[name] == msg.sender || userNameToAddress[name] == 0, "Name is already in use");
        require(msg.value >= uniqueNamePrice, "Not enough value");
        delete userNameToAddress[addressToUserName[msg.sender]];
        addressToUserName[msg.sender] = name;
        userNameToAddress[name] = msg.sender;
		epigeonAddress.owner().transfer(address(this).balance);
    }
	
	function transferUniqueName (address toAddress) public {
		addressToUserName[toAddress]= addressToUserName[msg.sender];
		userNameToAddress[addressToUserName[toAddress]] = toAddress;
		delete addressToUserName[msg.sender];
    }
}
//----------------------------------------------------------------------------------------------------

contract PigeonDestinationDirectory is IPigeonDestinationDirectory{
    
    address public epigeonAddress;
    
    mapping (address => address[]) internal toAddressToPigeon;
    mapping (address => uint256) internal pigeonToToAddressIndex;
    mapping (address => bool) internal pigeonToAddressExists;
    
    event PigeonSent(address toAddress);
    
    constructor (){
        epigeonAddress = msg.sender;
    }
    
    function changeToAddress(address newToAddress, address oldToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        require(pigeonToAddressExists[msg.sender] == true, "Pigeon has no recipient entry to change");
        
        //Push new to address
        toAddressToPigeon[newToAddress].push(pigeon);
        pigeonToToAddressIndex[pigeon] = toAddressToPigeon[newToAddress].length-1;
        
        //Delete old to address
        address pigeonToRemove = pigeon;
        uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
        uint256 lastIdIndex = toAddressToPigeon[oldToAddress].length - 1;
        if (toAddressToPigeon[oldToAddress][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = toAddressToPigeon[oldToAddress][lastIdIndex];
          toAddressToPigeon[oldToAddress][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
          pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
        }
        delete toAddressToPigeon[oldToAddress][lastIdIndex];
        toAddressToPigeon[oldToAddress].length--;
        emit PigeonSent(newToAddress);
    }
    
    function deleteToAddress(address oldToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        
        //Delete old to address 
        address pigeonToRemove = pigeon;
        uint256 pigeonToRemoveIndex = pigeonToToAddressIndex[pigeon];
        uint256 lastIdIndex = toAddressToPigeon[oldToAddress].length - 1;
        if (toAddressToPigeon[oldToAddress][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = toAddressToPigeon[oldToAddress][lastIdIndex];
          toAddressToPigeon[oldToAddress][pigeonToToAddressIndex[pigeonToRemove]] = lastPigeon;
          pigeonToToAddressIndex[lastPigeon] = pigeonToRemoveIndex;
        }
        delete toAddressToPigeon[oldToAddress][lastIdIndex];
        toAddressToPigeon[oldToAddress].length--;
        
        pigeonToAddressExists[pigeon] = false;
    }
    
    function deleteToAddressByEpigeon(address pigeon) public {
        require(epigeonAddress == msg.sender, "Available only for Epigeon Smart Contract");
        address pToAddress = ICryptoPigeon(pigeon).toAddress();
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
    
    function pigeonSentToAddressByIndex(address toAddress, uint index) public view returns (address rpaddress){
        rpaddress = toAddressToPigeon[toAddress][index];
    }
    
    function pigeonsSentToAddressLenght(address toAddress) public view returns (uint256 length){
        length = toAddressToPigeon[toAddress].length;
    }
    
    function setToAddress(address newToAddress) public {
        //Check if the call is from a CryptoPigeon
        require(_isPigeon(msg.sender), "Available only for Epigeon's pigeon contracts");
        ICryptoPigeon pigeon = ICryptoPigeon(msg.sender);
        
        //Push new to address
        require(pigeonToAddressExists[msg.sender] != true, "Pigeon already has recipient entry");
        toAddressToPigeon[newToAddress].push(pigeon);
        pigeonToToAddressIndex[pigeon] = toAddressToPigeon[newToAddress].length-1;
        
        pigeonToAddressExists[pigeon] = true;
        emit PigeonSent(newToAddress);
    }
    
    function _isPigeon (address sender) internal view returns (bool indeed){
        ICryptoPigeon pigeon = ICryptoPigeon(sender);
        return IEpigeon(epigeonAddress).validPigeon(sender, pigeon.owner());
    }
}
//----------------------------------------------------------------------------------------------------

contract Epigeon is IEpigeon{

    address public owner;
    string public egigeonURI;
    address private _nftContractAddress;

    INameAndPublicKeyDirectory private _nameAndKeyDirectory;
    IPigeonDestinationDirectory private _pigeonDestinations;

    uint256[] factoryIds;
    mapping (address => bool) disabledFactories;
    mapping (uint256 => address) factoryIdtoAddress;

    mapping (address => address[]) internal ownerToPigeon;
    mapping (address => uint256) internal pigeonToOwnerIndex;

    event PigeonCreated(ICryptoPigeon pigeon);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor (){ 
        owner = msg.sender;
        _nameAndKeyDirectory = new NameAndPublicKeyDirectory();
        _pigeonDestinations = new PigeonDestinationDirectory();
    }   

    function addFactory(address factoryAddress) public {
        require(msg.sender == owner, "Only owner");
        IPigeonFactory factory = IPigeonFactory(factoryAddress);
        require(factory.iAmFactory(), "Not a factory");
        require(factory.amIEpigeon(), "Not the factory's Epigeon");
        require(factoryIdtoAddress[factory.factoryId()] == address(0), "Existing Factory ID");
        factoryIds.push(factory.factoryId());
        factoryIdtoAddress[factory.factoryId()] = factory;
        disabledFactories[factory] = false;
    }

    function burnPigeon(address pigeon) public {
        require((_nftContractAddress == msg.sender) || ((IEpigeonNFT(_nftContractAddress).isTokenizedPigeon(pigeon) == false) && (ICryptoPigeon(pigeon).owner() == msg.sender)), "Not authorized");
        address pOwner = ICryptoPigeon(pigeon).owner();
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
        _pigeonDestinations.deleteToAddressByEpigeon(pigeon);
        
        //Burn contract too
        ICryptoPigeon(pigeon).burnPigeon();        
    }
    
    function createCryptoPigeon(uint256 factoryId) public payable returns (address pigeonAddress) {
        require(msg.value >= getPigeonPriceForFactory(factoryId), "Not enough value"); 
        return _createPigeon(msg.sender, factoryId);
    }
    
    function createCryptoPigeonByLatestFactory() public payable returns (address pigeonAddress) {
        require(msg.value >= getPigeonPriceForFactory(getLastFactoryId()), "Not enough value");
        return _createPigeon(msg.sender, getLastFactoryId());
    }
    
    function createCryptoPigeonForToken(address ERC20Token, uint256 factoryId) public returns (address pigeonAddress) {
        require(getPigeonTokenPriceForFactory(ERC20Token, factoryId) > 0, "Price for token not available");
        require(IERC20(ERC20Token).balanceOf(msg.sender) >= getPigeonTokenPriceForFactory(ERC20Token, factoryId), "Not enough balance");
        require(IERC20(ERC20Token).allowance(msg.sender, address(this)) >= getPigeonTokenPriceForFactory(ERC20Token, factoryId), "Not enough allowance");
        IERC20(ERC20Token).transferFrom(msg.sender, owner, getPigeonTokenPriceForFactory(ERC20Token, factoryId));
        return _createPigeon(msg.sender, factoryId);
    }
    
    function createCryptoPigeonNFT(address to, uint256 factoryId) public returns (address pigeonAddress) {
        require(_nftContractAddress == msg.sender, "Available only for the NFT contract");   
        return _createPigeon(to, factoryId);
    }
    
    function disableFactory(uint256 factoryId) public {
        require(msg.sender == owner, "Only owner");
        disabledFactories[factoryIdtoAddress[factoryId]] = true;
    }
    
    function enableFactory(uint256 factoryId) public {
        require(msg.sender == owner, "Only owner");
        require(factoryIdtoAddress[factoryId] != address(0));
        disabledFactories[factoryIdtoAddress[factoryId]] = false;
    }
    
    function getFactoryAddresstoId(uint256 id) public view returns (address factory){
        return factoryIdtoAddress[id];
    }
    
    function getFactoryCount() public view returns (uint256 count){
        return factoryIds.length;
    }
    
    function getIdforFactory(uint256 index) public view returns (uint256 id){
        return factoryIds[index];
    }
    
    function getLastFactoryId() public view returns (uint256 id){
        return factoryIds[factoryIds.length-1];
    }
    
    function getPigeonPriceForFactory(uint256 factoryId) public view returns (uint256 price){
        return IPigeonFactory(factoryIdtoAddress[factoryId]).mintingPrice();
    }
    
    function getPigeonTokenPriceForFactory(address ERC20Token, uint256 factoryId) public view returns (uint256 price){
        return IPigeonFactory(factoryIdtoAddress[factoryId]).getFactoryTokenPrice(ERC20Token);
    }
    
    function isFactoryDisabled(address factoryAddress) public view returns (bool disabled){
        return disabledFactories[factoryAddress];
    }
    
    function nameAndKeyDirectory() external view returns (INameAndPublicKeyDirectory directory){
        return _nameAndKeyDirectory;
    }
    
    function nftContractAddress() external view returns (address _nftcontract){
        return _nftContractAddress;
    }

    function payout() public {
        require(msg.sender == owner, "Only owner");
        owner.transfer(address(this).balance);
    }
    
    function pigeonDestinations() external view returns (IPigeonDestinationDirectory destinations){
        return _pigeonDestinations;
    }
    
    function pigeonsCountOfOwner(address pigeonOwner) public view returns (uint256 length){
        length = ownerToPigeon[pigeonOwner].length;
        return length;
    }
    
    function pigeonOfOwnerByIndex(address pigeonOwner, uint index) public view returns (address rpaddress){
        rpaddress = ownerToPigeon[pigeonOwner][index];
        return rpaddress;
    }
    
    function setNFTContractAddress(address nftContract) public { 
        require(owner == msg.sender, "Only owner");
        require(_nftContractAddress == address(0), "NFT contract already set");
        _nftContractAddress = nftContract;
    }
    
    function setUri(string uri) public {  
        require(owner == msg.sender, "Only owner");
        egigeonURI = uri;
    }
    
    function transferOwnership(address newOwner) public {    
        require(owner == msg.sender, "Only owner");
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner.transfer(address(this).balance);
        owner = newOwner;
    }
    
    function transferPigeon(address from, address to, address pigeon) public {
    
        if (IEpigeonNFT(_nftContractAddress).isTokenizedPigeon(pigeon)) {
            require(_nftContractAddress == msg.sender, "Tokenized Pigeon can only be transferred by NFT contract");
        }
        else{
            require(ICryptoPigeon(pigeon).owner() == msg.sender || pigeon == msg.sender, "Only pigeon owner");
        }
        
        //Push new owner address
        ownerToPigeon[to].push(pigeon);
        pigeonToOwnerIndex[pigeon] = ownerToPigeon[to].length-1;
        
        //Delete old owner address
        address pigeonToRemove = pigeon;
        uint256 pigeonToRemoveIndex = pigeonToOwnerIndex[pigeon];
        uint256 lastIdIndex = ownerToPigeon[from].length - 1;
        if (ownerToPigeon[from][lastIdIndex] != pigeonToRemove)
        {
          address lastPigeon = ownerToPigeon[from][lastIdIndex];
          ownerToPigeon[from][pigeonToOwnerIndex[pigeonToRemove]] = lastPigeon;
          pigeonToOwnerIndex[lastPigeon] = pigeonToRemoveIndex;
          
        }
        delete ownerToPigeon[from][lastIdIndex];
        ownerToPigeon[from].length--;
        
        //Delete old to address
        _pigeonDestinations.deleteToAddressByEpigeon(pigeon);
         
        //Transfer contract too
        ICryptoPigeon(pigeon).transferPigeon(to);
    }
    
    function validPigeon(address pigeon, address pigeonOwner) public view returns (bool valid){
        require(pigeon != address(0), "Null address");
        return ownerToPigeon[pigeonOwner][pigeonToOwnerIndex[pigeon]] == pigeon;
    }
    
    function _createPigeon(address to, uint256 factoryId) internal returns (address pigeonAddress) {
        require(isFactoryDisabled(factoryIdtoAddress[factoryId]) == false, "Factory is disabled");
        ICryptoPigeon pigeon = IPigeonFactory(factoryIdtoAddress[factoryId]).createCryptoPigeon( to);
        ownerToPigeon[to].push(pigeon);
        pigeonToOwnerIndex[pigeon] = ownerToPigeon[to].length-1;
        emit PigeonCreated(pigeon);
        return pigeon;
    }
}