/**
 *Submitted for verification at Etherscan.io on 2022-04-02
*/

// File: EpigeonInterfaces_080.sol


pragma solidity ^0.8.0;

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
    function send(address recipient, uint256 amount, bytes memory data) external;
    function burn(uint256 amount, bytes memory data) external;
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);
    function authorizeOperator(address operator) external;
    function revokeOperator(address operator) external;
    function defaultOperators() external view returns (address[] memory);
    function operatorSend(address sender, address recipient, uint256 amount, bytes memory data, bytes memory operatorData) external;
    function operatorBurn(address account, uint256 amount, bytes memory data, bytes memory operatorData) external;
    event Sent( address indexed operator, address indexed from, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
}
//----------------------------------------------------------------------------------------------------
interface ILockable {
    function lock(address to, uint256 amount, bytes32 hash) external;
    function operatorLock(address from, address to, uint256 amount, bytes32 hash, bytes memory data, bytes memory operatorData) external;
    function unlock(string memory unlockerPhrase) external;
    function operatorUnlock(address to, string memory unlockerPhrase, bytes memory data, bytes memory operatorData) external;
    function reclaim(address to, string memory unlockerPhrase) external;
    function operatorReclaim(address from, address to, string memory unlockerPhrase, bytes memory data, bytes memory operatorData) external;
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
    function getMetaDataForPigeon(address pigeon) external view returns (string memory metadata);
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
    function getPublicKeyForAddress (address owner) external view returns (string memory key); 
    function getUserNameForAddress (address owner) external view returns (string memory name);
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


// File: SimplePigeonFactory_0812.sol


pragma solidity ^0.8.12;


//----------------------------------------------------------------------------------------------------
contract SimplePigeonFactory is IPigeonFactory{

    address public _owner;
    uint256 private _factoryId = 1;
    uint256 private _mintingPrice;
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    address public epigeon;
    string private _metadata = "https://www.epigeon.org/Meta/SimplePigeonMetadata.json";
    mapping (address => uint256) internal ApprovedTokenPrice;
    
    event PigeonCreated(ICryptoPigeon pigeon);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function factoryId() external view returns (uint256 id){return _factoryId;}
    function mintingPrice() external view returns (uint256 price){return _mintingPrice;}
    function totalSupply() external view returns (uint256 supply){return _totalSupply;}
    function maxSupply() external view returns (uint256 supply){return _maxSupply;}

    constructor (address epigeonAddress, uint256 price){
        _owner = msg.sender;
        epigeon = epigeonAddress;
        _mintingPrice = price;
        _maxSupply = 2500;
    }
    
    function amIEpigeon() public view returns (bool ami){
        return epigeon == msg.sender;
    }
    
    function createCryptoPigeon(address to) public returns (ICryptoPigeon pigeonaddress) {
        require(epigeon == msg.sender);
        require(_totalSupply < _maxSupply);
        
        ICryptoPigeon pigeon = new SimpleCryptoPigeon(to, msg.sender, _factoryId);
        _totalSupply += 1;
        emit PigeonCreated(pigeon);
        return pigeon;
    }
    
    function getFactoryTokenPrice(address ERC20Token) public view returns (uint256 price){
        return ApprovedTokenPrice[ERC20Token];
    }
    
    function getMetaDataForPigeon(address pigeon) public view returns (string memory metadata){
        if (pigeon == address(0)){
            return _metadata;
        }
        else{
            return _metadata;
        }
    }
    
    function iAmFactory() public pure returns (bool isIndeed) {
        return true;
    }
    
    function setMintingPrice(uint256 price) public {
        require(msg.sender == _owner);
        _mintingPrice = price;
    }
    
    function setBasicMetaDataForPigeon(string memory metadata) public {
        require(msg.sender == _owner);
        _metadata = metadata;
    }
    
    function setMintingPrice(address ERC20Token, uint256 price) public {
        require(msg.sender == _owner);
        ApprovedTokenPrice[ERC20Token] = price;
    }
    
    function transferOwnership(address newOwner) public {    
        require(_owner == msg.sender, "Only _owner");
        require(newOwner != address(0), "Zero address");
        emit OwnershipTransferred(_owner, newOwner);
        payable(_owner).transfer(address(this).balance);
        _owner = newOwner;
    }
} 
//----------------------------------------------------------------------------------------------------

contract SimpleCryptoPigeon is ICryptoPigeon{

    uint256 private _factoryId;  
    address private _owner;
    string public message;
    string public answer;
    uint256 public messageTimestamp;
    uint256 public answerTimestamp;
    address private _toAddress;
    bool private _hasFlown;
    address public epigeonContractAddress;
    bool public sentByManager;

    event AnswerSent(address sender, string message, uint256 messageTimestamp);  
    event MessageSent(address sender, string rmessage, address toAddress, uint256 messageTimestamp);
    
    function hasFlown() external view returns (bool HasFlown){return _hasFlown;}
    function toAddress() external view returns (address addressee){return _toAddress;} 
    function owner() external view returns (address owned){return _owner;}
    function manager() external view returns (address managed){return _owner;}
    function factoryId() external view returns (uint256 id){return _factoryId;}
    
    constructor (address _mintedto, address epigeonAddress, uint256 fid){
        _owner = _mintedto;
        epigeonContractAddress = epigeonAddress;
        _factoryId = fid;
        _hasFlown = false;
    }
    
    function burnPigeon() public {
        require(msg.sender == epigeonContractAddress);
        address wallet = _owner;
        selfdestruct(payable(wallet));
    }  
    
    function iAmPigeon() public pure returns (bool isIndeed) {
        return true;
    }
    
    function sendAnswer(string memory textMessage) public {
        require(msg.sender == _toAddress);
        answer = textMessage;
        answerTimestamp = block.timestamp;
        emit AnswerSent(msg.sender, answer, answerTimestamp);
    }
    
    function sendMessage(string memory textMessage, address addressee) public {
        require(msg.sender == _owner);      
        if (addressee != _toAddress){
            //Need to tell for the mailboxes
            if (_hasFlown){
                IEpigeon(epigeonContractAddress).pigeonDestinations().changeToAddress(addressee, _toAddress);
            }
            else{
                _hasFlown = true;
                IEpigeon(epigeonContractAddress).pigeonDestinations().setToAddress(addressee);
            }
            _toAddress = addressee;
            delete answer;
            delete answerTimestamp;
        }
        
        message = textMessage;
        messageTimestamp = block.timestamp;
        
        emit MessageSent(msg.sender, message, _toAddress, messageTimestamp);
    }
    
    function transferPigeon(address newOwner) public {
        require(msg.sender == epigeonContractAddress);
        delete message;
        delete answer;
        delete messageTimestamp;
        delete answerTimestamp;
        payable(_owner).transfer(address(this).balance);
        _owner = newOwner;
        _hasFlown = false;
        delete _toAddress;
    }
}
//----------------------------------------------------------------------------------------------------