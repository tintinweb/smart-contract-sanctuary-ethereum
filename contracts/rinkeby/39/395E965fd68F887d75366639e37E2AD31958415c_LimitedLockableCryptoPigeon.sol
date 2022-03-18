/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// File: EpigeonInterfaces8.sol


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


// File: LimitedLockablePigeonFactory.sol


pragma solidity ^0.8.12;


//----------------------------------------------------------------------------------------------------
contract LimitedLockablePigeonFactory is IPigeonFactory{

    address public lockableCoin;

    address public _owner;
    uint256 private _factoryId = 200;
    uint256 private _mintingPrice = 100000000000000;
    uint256 private _maxSupply;
    uint256 private _totalSupply;
    address public epigeon;
    string private _metadata = "https://www.epigeon.org/Meta/LimitedLockablePigeonMetadata.json";
    mapping (address => uint256) internal ApprovedTokenPrice;
    
    event PigeonCreated(ICryptoPigeon pigeon);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    function factoryId() external view returns (uint256 id){return _factoryId;}
    function mintingPrice() external view returns (uint256 price){return _mintingPrice;}
    function totalSupply() external view returns (uint256 supply){return _totalSupply;}
    function maxSupply() external view returns (uint256 supply){return _maxSupply;}

    constructor (address epigeonAddress, address coinAddress, uint256 price){
        _owner = msg.sender;
        epigeon = epigeonAddress;
        lockableCoin = coinAddress;
        _mintingPrice = price;
        _maxSupply = 100;
    }
    
    function amIEpigeon() public view returns (bool ami){
        return epigeon == msg.sender;
    }
    
    function createCryptoPigeon(address to) public returns (ICryptoPigeon pigeonaddress) {
        require(epigeon == msg.sender);
        require(_totalSupply < _maxSupply);
        
        ICryptoPigeon pigeon = new LimitedLockableCryptoPigeon(to, msg.sender, lockableCoin, _factoryId);
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

contract LimitedLockableCryptoPigeon is ICryptoPigeon{

    uint256 private _factoryId;  
    address private _owner;
    address private _manager;
    string public message;
    bytes32 internal message_hash;
    string public answer;
    uint256 public messageTimestamp;
    uint256 public answerTimestamp;
    address private _toAddress;
    bool private _hasFlown;
    bool public isRead;
    ILockable public lockable;
    address public epigeonContractAddress;
    bool public clearAtTransfer;
    bool public sentByManager;

    event AnswerSent(address sender, string message, uint256 messageTimestamp);  
    event MessageSent(address sender, string rmessage, address toAddress, uint256 messageTimestamp);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ValueClaimed(address receiver);
    
    function hasFlown() external view returns (bool HasFlown){return _hasFlown;}
    function toAddress() external view returns (address addressee){return _toAddress;} 
    function owner() external view returns (address owned){return _owner;}
    function manager() external view returns (address managed){return _manager;}
    function factoryId() external view returns (uint256 id){return _factoryId;}
    
    constructor (address _mintedto, address epigeonAddress, address coinAddress, uint256 fid){
        _owner = _mintedto;
        _manager = _mintedto;
        lockable = ILockable(coinAddress);
        epigeonContractAddress = epigeonAddress;
        _factoryId = fid;
        _hasFlown = false;
        clearAtTransfer = true;
    }
    
    function burnPigeon() public {
        require(msg.sender == epigeonContractAddress);
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        }
        address wallet = _owner;
        selfdestruct(payable(wallet));
    }  

    function getValueForMessage(string memory textMessage) public {
        require(msg.sender == _toAddress);
        require(keccak256(bytes(textMessage)) == keccak256(bytes(message)));
        lockable.operatorUnlock(_toAddress, message, "", "");
        delete message_hash;
        emit ValueClaimed(_toAddress);
    }
    
    function iAmPigeon() public pure returns (bool isIndeed) {
        return true;
    }
    
    function recallValue() public {
        require(msg.sender == _owner || msg.sender == _manager);
        require(message_hash != 0);
        lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        delete message_hash;
    }
    
    function sendAnswer(string memory textMessage) public {
        require(msg.sender == _toAddress);
        answer = textMessage;
        answerTimestamp = block.timestamp;
        emit AnswerSent(msg.sender, answer, answerTimestamp);
    }
    
    function sendMessage(string memory textMessage, address addressee) public {
        require(msg.sender == _owner || msg.sender == _manager);
        if (msg.sender == _manager){
            if (sentByManager == false) {sentByManager = true;}
        }
        else{
            if (sentByManager == true) {sentByManager = false;}
        }
        
        //clear balances
        if (message_hash != 0){
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
            delete message_hash;
        }
        
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
        isRead = false;
        
        emit MessageSent(msg.sender, message, _toAddress, messageTimestamp);
    }
    
    function sendMessagewithLockable(string memory textMessage, address addressee, uint256 amount) public {
        require(msg.sender == _owner || msg.sender == _manager);
        require(amount > 0);
        require(IERC777(address(lockable)).balanceOf(msg.sender) > amount);
        
        if (msg.sender == _manager){
            if (sentByManager == false) {sentByManager = true;}
        }
        else{
            if (sentByManager == true) {sentByManager = false;}
        }
        
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
        
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
        }
        
        //lock value
        bytes32 hash = keccak256(bytes(textMessage));
        lockable.operatorLock(msg.sender, addressee, amount, hash, "", "");
        
        message = textMessage;
        message_hash = hash;
        messageTimestamp = block.timestamp;
        isRead = false;
        
        emit MessageSent(msg.sender, message, _toAddress, messageTimestamp);
    }
    
    function setMessageRead() public returns (string memory rmessage){
        require(_toAddress == msg.sender);       
        isRead = true;
        rmessage = message;
    }
    
    function setClearAtTransfer(bool clear) public {
        require(msg.sender == _owner);
        clearAtTransfer = clear;
    }
    
    function setManager(address managerAddress) public {
        require(msg.sender == _owner || msg.sender == _manager);
        _manager = managerAddress;
    }  
    
    function transferOwnership(address to) public{
        require(msg.sender == _owner);
        IEpigeon(epigeonContractAddress).transferPigeon(msg.sender, to, address(this));
    }
    
    function transferPigeon(address newOwner) public {
        require(msg.sender == epigeonContractAddress);
        if (message_hash != 0){
            //clear balances
            lockable.operatorReclaim(_owner, _toAddress, message, "", "");
            delete message_hash;
        }
        if (clearAtTransfer){
            //delete MessageArchive;
            //delete AnswerArchive;
            delete message;
            delete answer;
            delete messageTimestamp;
            delete answerTimestamp;
            payable(_owner).transfer(address(this).balance);
        }
        _owner = newOwner;
		_manager = newOwner;
        _hasFlown = false;
        isRead = false;
        delete _toAddress;
        emit OwnershipTransferred(_owner, newOwner);
    }
    
    function viewValue() public view returns (uint256 value){
        return lockable.lockedAmount(_owner, message_hash);
    }
}
//----------------------------------------------------------------------------------------------------