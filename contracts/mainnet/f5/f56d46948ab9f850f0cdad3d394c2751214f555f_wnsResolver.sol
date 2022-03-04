/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
    function getRecord(uint256 _tokenId) external view returns (string memory);
    function getRecord(bytes32 _hash) external view returns (uint256);

}

pragma solidity 0.8.7;

interface WnsERC721Interface {
    function ownerOf(uint256 tokenId) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsRegistrarInterface {
    function computeNamehash(string memory _name) external view returns (bytes32);
    function recoverSigner(bytes32 message, bytes memory sig) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsResolver {
 
    address private WnsRegistry;
    WnsRegistryInterface wnsRegistry;

    constructor(address registry_) {
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    //Primary names mapping
    mapping(address => uint256) private _primaryNames;
    mapping(uint256 => mapping(string => string)) private _txtRecords;
    

    function setPrimaryName(address _address, uint256 _tokenID) public {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        require((wnsErc721.ownerOf(_tokenID) == msg.sender && _address == msg.sender) || msg.sender == wnsRegistry.getWnsAddress("_wnsMigration"), "Not owned by caller.");
        _primaryNames[_address] = _tokenID + 1;
    }

    function resolveAddress(address _address) public view returns (string memory) {
        uint256 _tokenId = _primaryNames[_address];
        require(_tokenId != 0, "Primary Name not set for the address.");
        return wnsRegistry.getRecord(_tokenId - 1);
    }

    function resolveName(string memory _name, string memory _extension) public view returns (address) {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        bytes32 _hash = wnsRegistrar.computeNamehash(_name);
        uint256 _preTokenId = wnsRegistry.getRecord(_hash);
        require(_preTokenId != 0, "Name doesn't exist.");
        return wnsErc721.ownerOf(_preTokenId - 1);
    }

    function resolveTokenId(uint256 _tokenId) public view returns (string memory) {
        return wnsRegistry.getRecord(_tokenId);
    }

    function resolveNameToTokenId(string memory _name, string memory _extension) public view returns (uint256) {
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        bytes32 _hash = wnsRegistrar.computeNamehash(_name);
        uint256 _preTokenId = wnsRegistry.getRecord(_hash);
        require(_preTokenId != 0, "Name doesn't exist.");
        return _preTokenId - 1;
    }

    function setTxtRecords(string[] memory labels, string[] memory records, uint256 tokenId, bytes memory sig) public {
        WnsERC721Interface wnsErc721 = WnsERC721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        require(msg.sender == wnsErc721.ownerOf(tokenId), "Caller is not the Owner.");
        require(labels.length == records.length, "Invalid parameters.");
        bytes32 message = keccak256(abi.encode(labels, records, tokenId));
        require(wnsRegistrar.recoverSigner(message, sig) == wnsRegistry.getWnsAddress("_wnsSigner"), "Not authorized.");
        for(uint256 i; i<labels.length; i++) {
            string memory currentRecord = _txtRecords[tokenId][labels[i]];
            if (keccak256(bytes(currentRecord)) != keccak256(bytes(records[i]))) {
                _txtRecords[tokenId][labels[i]] = records[i];
            }
        }
    }

    function getTxtRecords(uint256 tokenId, string memory label) public view returns (string memory) {
        return _txtRecords[tokenId][label];
    }
}