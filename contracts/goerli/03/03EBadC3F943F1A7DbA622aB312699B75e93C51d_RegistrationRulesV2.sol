// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IManager {

function IdToLabelMap( uint256 _tokenId) external view returns (string memory label);
function IdToOwnerId( uint256 _tokenId) external view returns (uint256 ownerId);
function IdToDomain( uint256 _tokenId) external view returns (string memory domain);
function TokenLocked( uint256 _tokenId) external view returns (bool locked);
function IdImageMap( uint256 _tokenId) external view returns (string memory image);
function IdToHashMap(uint256 _tokenId) external view returns (bytes32 _hash);
function text(bytes32 node, string calldata key) external view returns (string memory _value);
function DefaultMintPrice(uint256 _tokenId) external view returns (uint256 _priceInWei);
function transferDomainOwnership(uint256 _id, address _newOwner) external;
function TokenOwnerMap(uint256 _id) external view returns(address); 
}

interface IRegister {
    function canRegister(uint256 _tokenId, string memory _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool);
    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256);
    
}

//these rules don't enforce the minimum 0.01 eth fee..
contract RegistrationRulesV2 is IRegister {

    IManager immutable public DomainManager;

    mapping(uint256 => uint256) public prices;

    constructor(){
        DomainManager = IManager(0x33FA508781ec1BdC178A885ecDA46837841f7D02);
    }

    //we still use default price == 0 to work out if the token is for sale.
    function canRegister(uint256 _tokenId, string calldata _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        require(price == _priceInWei, "incorrect ether");
        require(price != 0, "not for primary sale");
        return true;
    }

    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256){
        uint256 price = prices[_tokenId];
        address owner = DomainManager.TokenOwnerMap(_tokenId);
        return owner == _addr ? 0 : price;
    }

    function setPrice(uint256 _tokenId, uint256 _priceInWei) authorised(_tokenId) external {
        prices[_tokenId] = _priceInWei;
    }
 

    modifier authorised(uint256 _tokenId) {
        address owner = DomainManager.TokenOwnerMap(_tokenId);
        require(owner == msg.sender, "not authorised");
        _;
    }
}