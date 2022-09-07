/**
 *Submitted for verification at Etherscan.io on 2022-09-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

    address public StorageToken = 0x3Accb592E1e64d08BA0875aa9A89774201Eb4BEc;
    address public MonsterToken = 0xd263D26e235D98ddA42741A58eB195d7a141f79b;

    bool public _isActiveStorage = true;
    bool public _isActiveMonster = false;

    address public ReleaseAddress = 0xc61cbf596D384f4162dB5d9f50b6401DBBc593D2;

    uint256 withdrawTimes = 3600;

    mapping(address => uint256) private Signature;

    uint256 currentId;

    event StorageLog(string indexed Signature,address indexed to,uint256 indexed _tokenId, uint256  _amount);
    event MonsterLog(string indexed Signature,address indexed to,uint256 indexed _tokenId);

    constructor(address _check) {
        Storage = IStorage(StorageToken);
        Monster = IMonster(MonsterToken);
        Check = ICheck(_check);
    }

   
    function receiveStorage(uint256[] memory _tokenIds,uint256[] memory _amounts,string memory _signature) public{
        require(_isActiveStorage, "Receive storage must be active");

        require(
            Signature[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Check.checkGetProp(msg.sender, _tokenIds, _amounts, _signature) == true,
            "Audit error"
        );   

        Storage.safeBatchTransferFrom(ReleaseAddress, msg.sender, _tokenIds, _amounts, "0x00");

        Signature[msg.sender] = block.timestamp;

        uint256  tokenIdLength  = _tokenIds.length;

        for(uint i = 0;i < tokenIdLength;i++){
            emit StorageLog(_signature, msg.sender, _tokenIds[i], _amounts[i]);
        }
    }

    function receiveMonster(uint256 _amount, string memory _signature) public{

        require(_isActiveMonster,  "Receive scary monster must be active");

        require(
            Check.checkGetRelease(msg.sender, _amount, _signature) == true,
            "Audit error"
        ); 

        for(uint i = 0;i < _amount;i++){

            Monster.safeTransferFrom(ReleaseAddress, msg.sender, currentId);

            emit MonsterLog(_signature, msg.sender, currentId);

            currentId++;
        }

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

    function setActiveReceive() external onlyOwner {
        _isActiveStorage = !_isActiveStorage;
    }

    function setActiveMonster() external onlyOwner {
        _isActiveMonster = !_isActiveMonster;
    }


    function withdrawETH(uint256 _amount) public {
        

         require(
            _amount > 0,
            "Withdraw torch must be greater than 0"
        );


        require(
            address(this).balance >= _amount,
            "ETH credit is running low"
        );

       

        payable(msg.sender).transfer(_amount);

       
    }
    
    
    function rechageEth() public payable {
        require(
            0 <= msg.value,
            "Not enough ether sent"
        );
    }


      function withdrawSHIB(uint256 _amount) public {

         require(
            _amount > 0,
            "Withdraw SHIB must be greater than 0"
        );

        

       payable(msg.sender).transfer(_amount);

    }
    

}