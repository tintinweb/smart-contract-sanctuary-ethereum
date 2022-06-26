// SPDX-License-Identifier: MIT

import "./interfaces/IManager.sol";
import "./interfaces/IRegister.sol";


pragma solidity ^0.8.13;

contract RegistrationRulesV1 is IRegister {

    IManager public DomainManager;
    constructor(IManager _manager){
        DomainManager = _manager;
    }

    function canRegister(uint256 _tokenId, string calldata _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        require(price == _priceInWei, "incorrect ether");
        require(price != 0, "not for primary sale");
        return true;
    }

    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256){
        uint256 price = DomainManager.DefaultMintPrice(_tokenId);
        address owner = DomainManager.TokenOwnerMap(_tokenId);
        return owner == _addr ? 0 : price;
    }
 
}

//SPDX-License-Identifier: MIT


pragma solidity ^0.8.13;

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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IRegister {
    function canRegister(uint256 _tokenId, string memory _label, address _addr, uint256 _priceInWei, bytes32[] calldata _proofs) external view returns(bool);
    function mintPrice(uint256 _tokenId, string calldata _label, address _addr, bytes32[] calldata _proofs) external view returns(uint256);
    
}