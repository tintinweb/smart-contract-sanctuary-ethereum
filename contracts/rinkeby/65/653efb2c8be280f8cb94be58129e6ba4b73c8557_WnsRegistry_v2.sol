/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function getRecord(bytes32 _hash) external view returns (uint256);
    function getRecord(uint256 _tokenId) external view returns (string memory);
}

pragma solidity 0.8.7;

interface WnsAddressesInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract WnsRegistry_v2 {
    
    address private WnsRegistry_v1;
    address private WnsAddresses;
    WnsRegistryInterface wnsRegistry_v1;
    WnsAddressesInterface wnsAddresses;

    constructor(address registry_, address addresses_) {
        WnsRegistry_v1 = registry_;
        wnsRegistry_v1 = WnsRegistryInterface(WnsRegistry_v1);
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(WnsAddresses);
    }

    function owner() public view returns (address) {
        return wnsAddresses.owner();
    }

    function getWnsAddress(string memory _label) public view returns (address) {
        return wnsAddresses.getWnsAddress(_label);
    }

    function setRegistry_v1(address _registry) public {
        require(msg.sender == owner(), "Not authorized.");
        WnsRegistry_v1 = _registry;
        wnsRegistry_v1 = WnsRegistryInterface(WnsRegistry_v1);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(WnsAddresses);
    }

    mapping(bytes32 => uint256) private _hashToTokenId;
    mapping(uint256 => string) private _tokenIdToName;

    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name) public {
        require(msg.sender == getWnsAddress("_wnsRegistrar") || msg.sender == getWnsAddress("_wnsMigration"), "Caller is not authorized.");
        _hashToTokenId[_hash] = _tokenId;
        _tokenIdToName[_tokenId - 1] = _name;
    }

    function setRecord(uint256 _tokenId, string memory _name) public {
        require(msg.sender == getWnsAddress("_wnsRegistrar"), "Caller is not Registrar");
        _tokenIdToName[_tokenId - 1] = _name;
    }

    function getRecord(bytes32 _hash) public view returns (uint256) {
        if(_hashToTokenId[_hash] != 0) {
            return _hashToTokenId[_hash];
        } else {
            return wnsRegistry_v1.getRecord(_hash);
        }
    }

    function getRecord(uint256 _tokenId) public view returns (string memory) {
        if(keccak256(abi.encodePacked(_tokenIdToName[_tokenId])) != keccak256(abi.encodePacked(""))) {
            return _tokenIdToName[_tokenId];
        } else {
            return wnsRegistry_v1.getRecord(_tokenId);
        }
    }
}