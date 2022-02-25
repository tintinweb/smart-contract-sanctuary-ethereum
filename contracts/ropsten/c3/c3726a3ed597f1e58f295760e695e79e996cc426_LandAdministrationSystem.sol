/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

interface LandAdministrationSystemInterface {
    function ownersOf(uint256 _tokenId) external view returns  (address[] memory);
    function shareOf(uint256 _tokenId, address _owner) external view returns (uint16);
    function transferFrom(address _from, address _to, uint256 _tokenId, uint16 _share, 
                          bytes memory _documentHash) external payable;
    function isTransferable(uint256 _tokenId) external view returns (bool);
    function setTransferable(uint256 _tokenId, bool _transferable, 
                             bytes memory _documentHash) external payable;
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId, uint16 _share, bytes _documentHash);
    event Transferable(uint256 indexed _tokenId, bool transferable, bytes _documentHash);
}

contract LandAdministrationSystem is LandAdministrationSystemInterface {
    address master;
    mapping(uint256 => address[]) realEstateOwners;
    mapping(uint256 => mapping(address => uint16)) realEstateOwnersShare;
    mapping(uint256 => bool) transferable;

    constructor() {
        master = msg.sender;
    }

    function mint(address _to, uint256 _tokenId, uint16 _share, 
                  bytes memory _documentHash) public {
        require(msg.sender == master);
        transferable[_tokenId] = true;
        realEstateOwners[_tokenId].push(_to);
        realEstateOwnersShare[_tokenId][_to] = _share;
        emit Transfer(master, _to, _tokenId, _share, _documentHash);
    }
   
    function ownersOf(uint256 _tokenId) override external view 
                      returns (address[] memory) {
        return realEstateOwners[_tokenId];
    }

    function shareOf(uint256 _tokenId, address _owner) override public view 
                     returns (uint16) {
        return realEstateOwnersShare[_tokenId][_owner];
    }

    function transferFrom(address _from, address _to, uint256 _tokenId, uint16 _share, 
                          bytes memory _documentHash) override external payable {
        if(!transferable[_tokenId]) {
            revert nonTransferable({
                _tokenId: _tokenId
            });
        }
        if (!(msg.sender == master || isOwner(_tokenId, _from))) {
            revert notOwnerOrMaster({
                _tokenId: _tokenId,
                _from: _from
            });
        }
        if (shareOf(_tokenId, _from) < _share) {
            revert notOwningBigEnoughShare({
                _tokenId: _tokenId,  
                _from: _from,
                  _owningShare: shareOf(_tokenId, _from),  
                  _transferingShare: _share
                });
        }
        realEstateOwnersShare[_tokenId][_from] -= _share;
        realEstateOwnersShare[_tokenId][_to] += _share;
        addToRealEstateOwnersIfNewOwner(_tokenId, _to);
        removeFromRealEstateOwnersIfNoShare(_tokenId, _from);
        emit Transfer(_from, _to, _tokenId, _share, _documentHash);
    }

    function isOwner(uint256 _tokenId, address _address) private view returns (bool) {
        address[] memory allOwners = realEstateOwners[_tokenId];
        for (uint i=0; i < allOwners.length; i++) {
            if (allOwners[i] == _address ) {
                return true;
            }
        }
        return false;
    }

    function getIndexOfOwner(uint256 _tokenId, address _owner) private view 
                             returns (int){
        for(uint i = 0; i< realEstateOwners[_tokenId].length; i++){
            if(_owner == realEstateOwners[_tokenId][i]) 
                return int(i);
        }
        return -1;
    }

    function removeFromRealEstateOwnersIfNoShare(uint256 _tokenId, address _from) 
                                                 private {
        if (shareOf(_tokenId, _from) == 0) {
            int i = getIndexOfOwner(_tokenId, _from);
            if (i != -1) {
                delete realEstateOwners[_tokenId][uint(i)];
            }
        }
    }

    function addToRealEstateOwnersIfNewOwner(uint256 _tokenId, address _owner) 
                                              private {
        if (!isOwner(_tokenId, _owner)) {
            realEstateOwners[_tokenId].push(_owner);
        }
    }

    function isTransferable(uint256 _tokenId) override external view returns (bool) {
        return transferable[_tokenId];
    }

    function setTransferable(uint256 _tokenId, bool _transferable, 
                             bytes memory _documentHash) override external payable {
        require(msg.sender == master);
        transferable[_tokenId] = _transferable;
        emit Transferable(_tokenId, transferable[_tokenId], _documentHash);
    }

    error nonTransferable(uint256 _tokenId);
    error notOwnerOrMaster(uint256 _tokenId, address _from);
    error notOwningBigEnoughShare(uint256 _tokenId, address _from, uint16 _owningShare, 
                                  uint16 _transferingShare);
    
}