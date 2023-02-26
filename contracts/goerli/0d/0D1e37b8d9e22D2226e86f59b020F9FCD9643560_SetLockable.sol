// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import { InvalidOwner } from "./SetOwnerEnumerable.sol";
struct LockableData { 

    mapping(address => uint256) lockableStatusIndex; 

    mapping(address => LockableStatus) lockableStatus;  
} 


struct LockableStatus {
    bool isLocked;
    uint256 lockedAt;
    address custodian;
    uint256 balance;
    address[] approvedAll;
    bool exists;
}

uint64 constant MAX_INT = 2**64 - 1;

error OnlyCustodianCanLock();

error OnlyOwnerCanSetCustodian();

error WalletLockedByOwner();


library SetLockable {           

    function lockWallet(LockableData storage self, address holder) public {
        LockableStatus storage status = self.lockableStatus[holder];    
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }       
        status.isLocked = true;
        status.lockedAt = block.timestamp;
    }

    function unlockWallet(LockableData storage self, address holder) public {        
        LockableStatus storage status = self.lockableStatus[holder];
        if (msg.sender != status.custodian) {
            revert OnlyCustodianCanLock();
        }                   
        
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }

    function setCustodian(LockableData storage self, address custodianAddress,  address holder) public {
        if (msg.sender != holder) {
            revert OnlyOwnerCanSetCustodian();
        }    
        LockableStatus storage status = self.lockableStatus[holder];
        status.custodian = custodianAddress;
    }

    function findCustodian(LockableData storage self, address wallet) public view returns (address) {
        return self.lockableStatus[wallet].custodian;
    }

    function forceUnlock(LockableData storage self, address owner) public {        
        LockableStatus storage status = self.lockableStatus[owner];
        status.isLocked = false;
        status.lockedAt = MAX_INT;
    }
            
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct OwnerEnumerableData { 
    mapping(uint256 => TokenOwnership) tokens;
    mapping(address => uint256[]) ownedTokens;

    mapping(address => mapping(uint256 => uint256)) ownedTokensIndex; 

    mapping(address => uint256[]) burnedTokens;

    mapping(address => mapping(uint256 => uint256)) burnedTokensIndex; 
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

    function addBurnToEnumeration(OwnerEnumerableData storage self, address to, uint256 tokenId) public {       
        self.burnedTokens[to].push(tokenId);        
        uint256 length = self.burnedTokens[to].length;
        self.burnedTokensIndex[to][tokenId] = length-1;        
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