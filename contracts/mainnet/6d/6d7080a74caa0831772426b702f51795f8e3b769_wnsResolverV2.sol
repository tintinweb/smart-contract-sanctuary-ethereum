/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-03
*/

pragma solidity 0.8.7;

interface WnsAddressesInterface {
    function owner() external view returns (address);
    function getWnsAddress(string memory _label) external view returns (address);
}

pragma solidity 0.8.7;

interface WnsResolverInterface {
    function resolveAddress(address _address) external view returns (string memory);
    function resolveName(string memory _name, string memory _extension) external view returns (address);
    function resolveTokenId(uint256 _tokenId) external view returns (string memory);
    function resolveNameToTokenId(string memory _name, string memory _extension) external view returns (uint256);
}

pragma solidity 0.8.7;

interface WnsErc721Interface {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract wnsResolverV2 {
 
    address private WnsAddresses;
    WnsAddressesInterface wnsAddresses;

    constructor(address addresses_) {
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == wnsAddresses.owner(), "Not authorized.");
        WnsAddresses = addresses_;
        wnsAddresses = WnsAddressesInterface(addresses_);
    }

    function resolveAddress(address[] memory _addresses) public view returns (string[] memory) {
        WnsResolverInterface wnsResolver = WnsResolverInterface(wnsAddresses.getWnsAddress("_wnsResolver"));

        string[] memory names = new string[](_addresses.length);
        for(uint256 i=0; i<_addresses.length; i++) {
            names[i] = wnsResolver.resolveAddress(_addresses[i]);
        }
        return names;
    }

    function resolveName(string[] memory _names) public view returns (address[] memory) {
        WnsResolverInterface wnsResolver = WnsResolverInterface(wnsAddresses.getWnsAddress("_wnsResolver"));
        address[] memory addresses = new address[](_names.length);
        for(uint256 i=0; i<_names.length; i++) {
            addresses[i] = wnsResolver.resolveName(_names[i],"");
        }
        return addresses;
    }

    function resolveTokenId(uint256[] memory _tokenIds) public view returns (string[] memory) {
        WnsResolverInterface wnsResolver = WnsResolverInterface(wnsAddresses.getWnsAddress("_wnsResolver"));
        string[] memory names = new string[](_tokenIds.length);
        for(uint256 i=0; i<_tokenIds.length; i++) {
            names[i] = wnsResolver.resolveTokenId(_tokenIds[i]);
        }
        return names;
    }

    function resolveNameToTokenId(string[] memory _names) public view returns (uint256[] memory) {
        WnsResolverInterface wnsResolver = WnsResolverInterface(wnsAddresses.getWnsAddress("_wnsResolver"));
        uint256[] memory tokenIds = new uint256[](_names.length);
        for(uint256 i=0; i<_names.length; i++) {
            tokenIds[i] = wnsResolver.resolveNameToTokenId(_names[i],"");
        }
        return tokenIds;
    }

    function allTokenIdsOfOwner(address _owner) public view returns (uint256[] memory) {
        WnsErc721Interface wnsErc721 = WnsErc721Interface(wnsAddresses.getWnsAddress("_wnsErc721"));
        uint256 balance = wnsErc721.balanceOf(_owner);
        uint256[] memory tokenIds = new uint256[](balance);
        for(uint256 i=0; i<balance; i++) {
            tokenIds[i] = wnsErc721.tokenOfOwnerByIndex(_owner,i);
        }
        return tokenIds;
    }
}