/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Demo.sol


pragma solidity ^0.8.0;


interface IStorage {
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

interface IMonster {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
}

interface ICheck {
    function checkGetProp(address _address,uint256[] memory _tokenId,uint256[] memory _amounts,string memory signedMessage) external view returns (bool);

    function checkGetRelease(address _address,uint256 _amount, string memory signedMessage) external view returns (bool);
}

contract Airdrop is Ownable{

    IStorage public Storage;
    ICheck public Check;
    IMonster public Monster;

    address public StorageToken = 0xa755c08a422434C480076c80692d9aEe67bCea2B;
    address public MonsterToken = 0xf9524525BC155583775DB28bFDa4B99517a2257E;

    bool public _isActiveStorage = true;
    bool public _isActiveMonster = false;

    address public ReleaseAddress = 0x8cc60b6C29F9fe367DDc43DfA644194ce6d49b8c;

    uint256 withdrawTimes = 3600;

    mapping(address => uint256) private SignatureStorage;
    mapping(address => uint256) private SignatureMonster;

    uint256 currentId;

    event StorageLog(address indexed  to,  uint256 indexed  _tokenId, uint256 indexed  _amount, string Signature);
    event MonsterLog(address indexed  to,  uint256 indexed  _tokenId, string Signature);

    constructor(address _check) {
        Storage = IStorage(StorageToken);
        Monster = IMonster(MonsterToken);
        Check = ICheck(_check);
    }

   
    function receiveStorage(uint256[] memory _tokenIds,uint256[] memory _amounts,string memory _signature) public{
        require(_isActiveStorage, "Receive storage must be active");

        require(
            SignatureStorage[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Check.checkGetProp(msg.sender, _tokenIds, _amounts, _signature) == true,
            "Audit error"
        );   

        Storage.safeBatchTransferFrom(ReleaseAddress, msg.sender, _tokenIds, _amounts, "0x00");

        SignatureStorage[msg.sender] = block.timestamp;

        uint256  tokenIdLength  = _tokenIds.length;
        for(uint i = 0;i < tokenIdLength;i++){
            emit StorageLog(msg.sender, _tokenIds[i], _amounts[i], _signature);
        }

    }

    function receiveMonster(uint256 _amount, string memory _signature) public{

        require(_isActiveMonster,  "Receive scary monster must be active");

         require(
            SignatureMonster[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );


        require(
            Check.checkGetRelease(msg.sender, _amount, _signature) == true,
            "Audit error"
        ); 

        for(uint i = 0;i < _amount;i++){

            Monster.safeTransferFrom(ReleaseAddress, msg.sender, currentId);
            
            emit MonsterLog(msg.sender, currentId, _signature);

            currentId++;
        }

        SignatureMonster[msg.sender] = block.timestamp;

    }

    function setActiveReceive() external onlyOwner {
        _isActiveStorage = !_isActiveStorage;
    }

    function setActiveMonster() external onlyOwner {
        _isActiveMonster = !_isActiveMonster;
    }
    
    function setCurrentId(uint256 _indexId) public onlyOwner{
        currentId = _indexId;
    }


    function setWithdrawTimes(uint256 _timestamp) public onlyOwner{
        withdrawTimes = _timestamp;
    }

    function setReleaseAddress(address _address) external onlyOwner {
        ReleaseAddress = _address;
    }

    function setCheckContract(address _address) external onlyOwner {
        Check = ICheck(_address);
    }

    function setStorageContract(address _address) external onlyOwner {
        Storage = IStorage(_address);
    }

    function setMonsterContract(address _address) external onlyOwner {
        Monster = IMonster(_address);
    }

    
    

}