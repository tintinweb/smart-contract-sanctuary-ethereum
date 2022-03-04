/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

// File: wns/wns_registrar.sol


pragma solidity 0.8.7;

interface WnsRegistryInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
    function setRecord(bytes32 _hash, uint256 _tokenId, string memory _name) external;
    function getRecord(bytes32 _hash) external view returns (uint256);
}

pragma solidity 0.8.7;

interface WnsErc721Interface {
    function mintErc721(address to) external;
    function getNextTokenId() external view returns (uint256);
}

pragma solidity 0.8.7;

interface WnsResolverInterface {
    function setPrimaryName(address _addresss, uint256 _tokenId) external;
}

pragma solidity 0.8.7;

interface WnsOldContractInterface {

    function totalSupply() external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function nameByTokenID(uint256 tokenId) external view returns (string memory);
    function getPrimaryName(address _address) external view returns (string memory);

}

pragma solidity 0.8.7;

interface WnsRegistrarInterface {
    function computeNamehash(string memory _name) external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsMigration {

    address private WnsRegistry;
    address public OldContract;
    WnsRegistryInterface wnsRegistry;
   

    constructor(address registry_, address oldContract_) {
        OldContract = oldContract_;
        WnsRegistry = registry_;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function setRegistry(address _registry) public {
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        WnsRegistry = _registry;
        wnsRegistry = WnsRegistryInterface(WnsRegistry);
    }

    function migrateTokens() public {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(wnsRegistry.getWnsAddress("_wnsErc721"));
        WnsResolverInterface wnsResolver = WnsResolverInterface(wnsRegistry.getWnsAddress("_wnsResolver"));
        WnsRegistrarInterface wnsRegistrar = WnsRegistrarInterface(wnsRegistry.getWnsAddress("_wnsRegistrar"));
        WnsOldContractInterface wnsOldContract = WnsOldContractInterface(OldContract);
        require(msg.sender == wnsRegistry.owner(), "Not authorized.");
        uint256 totalSupply = wnsOldContract.totalSupply();

        for(uint256 i=0; i<totalSupply; i++) {
            address tokenOwner = wnsOldContract.ownerOf(i);
            string memory fullname = wnsOldContract.nameByTokenID(i);
            string memory name = parseName(fullname);
            bytes32 _hash = wnsRegistrar.computeNamehash(name);
            require(wnsRegistry.getRecord(_hash) == 0, "Name already exists.");
            wnsErc721.mintErc721(tokenOwner);
            wnsRegistry.setRecord(_hash, wnsErc721.getNextTokenId(), fullname);

            try wnsOldContract.getPrimaryName(tokenOwner) {
                string memory _primary = wnsOldContract.getPrimaryName(tokenOwner);
                if(keccak256(bytes(_primary)) == keccak256(bytes(fullname))) {
                    wnsResolver.setPrimaryName(tokenOwner, wnsErc721.getNextTokenId() - 1);
                }
            } catch {}
        }
    }

    function parseName(string memory _fullName) public pure returns (string memory) {
        bytes memory _bytes = bytes(_fullName);
        uint256 index;
        for(uint256 i=0; i<_bytes.length; i++) {
            if(_bytes[i] == bytes(".")[0]) {
                index = i;
            }
        }
        return getSlice(1,index,_bytes);
    }

    function getSlice(uint256 begin, uint256 end, bytes memory text) public pure returns (string memory) {
        bytes memory a = new bytes(end-begin+1);
        for(uint i=0;i<=end-begin;i++){
            a[i] = text[i+begin-1];
        }
        return string(a);    
    }

}