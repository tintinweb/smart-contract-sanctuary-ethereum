/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface ICollection {
    function isCollectionFromFactory(address _collection) external view returns (bool);
    function items(uint256 _itemId) external view returns (string memory, uint256, uint256, uint256, address, string memory, string memory);
    function creator() external view returns (address);
    function globalManagers(address _user) external view returns (bool);
    function itemManagers(uint256 _itemId, address _user) external view returns (bool);
}

interface ITPRegistry {
    function isThirdPartyManager(string memory _thirdPartyId, address _manager) external view returns (bool);
    function thirdParties(string memory _tpID) external view returns (
        bool,
        bytes32,
        uint256,
        uint256,
        uint256,
        string memory,
        string memory
    );
}  

interface INFT {
    function isApprovedForAll(address _user, address _operator) external view returns (bool);
    function getApproved(uint256 _nft) external view returns (address);
    function updateOperator(uint256 _nft) external view returns (address);
    function updateManager(address _user, address _operator) external view returns (bool);

    function ownerOf(uint256 _nft) external view returns (address);

    function encodeTokenId(int x, int y) external view returns (uint256);
    function getLandEstateId(uint256 nft) external view returns (uint256);

}  

interface IDCLRegistrar {
     /**
     * @dev Get the owner of a subdomain
     * @param _subdomain - string of the subdomain
     * @return owner of the subdomain
     */
    function getOwnerOf(string memory _subdomain) external view returns (address);
}


contract Checker {
    function validateWearables(
        address _sender,
        ICollection _factory,
        ICollection _collection,
        uint256 _itemId,
        string memory _contentHash
    ) external view returns (bool) {
        if(!_factory.isCollectionFromFactory(address(_collection))) {
            return false;
        }

        bool hasAccess = false;

        address creator = _collection.creator();
        if (creator == _sender) {
            hasAccess = true;
        }

        if ( _collection.globalManagers(_sender)) {
            hasAccess = true;
        }

        if (_collection.itemManagers(_itemId, _sender)) {
           hasAccess = true;
        }

        if(!hasAccess) {
            return false;
        }

        (,,,,,,string memory contentHash) = _collection.items(_itemId);

       return keccak256(bytes(_contentHash)) == keccak256(bytes(contentHash));
    }

    function validateThirdParty(
        address _sender,
        ITPRegistry _tpRegistry, 
        string memory _tpId,
        bytes32 _root
    ) external view returns (bool) {
        if (!_tpRegistry.isThirdPartyManager(_tpId, _sender)) {
            return false;
        }

        (bool isApproved, bytes32 root,,,,,) = _tpRegistry.thirdParties(_tpId);

        return isApproved && root == _root;
    }

    function checkName(address _sender, IDCLRegistrar _registrar, string calldata _name) external view returns (bool) {
        return _sender == _registrar.getOwnerOf(_name);
    }

    function checkLAND(address _sender, INFT _land, INFT _estate, int256 _x, int256 _y) external view returns (bool) {
        uint256 landId = _land.encodeTokenId(_x, _y);
        address owner = _land.ownerOf(landId);

        if(owner == _sender) {
            return true;
        }

        if(owner == address(_estate)) {
            uint256 estateId = _estate.getLandEstateId(landId);

            if(_estate.ownerOf(estateId) == _sender) {
                return true;
            }

            if(_estate.getApproved(estateId) == _sender) {
                return true;
            }

            if(_estate.isApprovedForAll(owner, _sender)){
                return true;
            }

            if(_estate.updateManager(owner, _sender)){
                return true;
            }

            if(_estate.updateOperator(landId) == _sender){
                return true;
            }
        } else {
            if(_land.getApproved(landId) == _sender) {
                return true;
            }

            if(_land.isApprovedForAll(owner, _sender)){
                return true;
            }

            if(_land.updateManager(owner, _sender)){
                return true;
            }

            if(_land.updateOperator(landId) == _sender){
                return true;
            }
        }

        return false;
    }
}