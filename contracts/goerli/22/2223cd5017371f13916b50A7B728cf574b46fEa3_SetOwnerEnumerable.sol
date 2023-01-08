// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OwnerEnumerableData { 
    mapping(uint256 => TokenOwnership) tokens;
    mapping(address => uint256[]) ownedTokens;

    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    uint256 totalSupply;    
}    

struct TokenOwnership {
    address ownedBy;
    bool exists;
}

error TokenNonOwner(address requester, uint256 tokenId); 
error InvalidOwner();

library SetOwnerEnumerable {
    function addTokenToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {        
        self.ownedTokens[to].push(tokenId);        
        uint256 length = self.ownedTokens[to].length;
        self.ownedTokensIndex[to][tokenId] = length-1;
        self.tokens[tokenId] = TokenOwnership(to,true);
    }    

    function removeTokenFromEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {

        uint256 length = self.ownedTokens[to].length;
        if (self.ownedTokensIndex[to][tokenId] > 0) {
            if (self.ownedTokensIndex[to][tokenId] != length - 1) {
                uint256 lastTokenId = self.ownedTokens[to][length - 1];
                self.ownedTokens[to][self.ownedTokensIndex[to][tokenId]] = lastTokenId; 
                self.ownedTokensIndex[to][lastTokenId] = self.ownedTokensIndex[to][tokenId];
            }
        }

        delete self.ownedTokensIndex[to][tokenId];
        if (self.ownedTokens[to].length > 0) {
            self.ownedTokens[to].pop();
        }
    }    

    function findTokensOwned(OwnerEnumerableData storage self, address wallet) public view returns (uint256[] storage) {
        return self.ownedTokens[wallet];
    }  

    function tokenIndex(OwnerEnumerableData storage self, address wallet, uint256 index) public view returns (uint256) {
        return self.ownedTokens[wallet][index];
    }    

    function ownerOf(OwnerEnumerableData storage self, uint256 tokenId) public view returns (address) {
        address owner = self.tokens[tokenId].ownedBy;
        if (owner == address(0)) {
            revert TokenNonOwner(owner,tokenId);
        }
        return owner;
    }      
}