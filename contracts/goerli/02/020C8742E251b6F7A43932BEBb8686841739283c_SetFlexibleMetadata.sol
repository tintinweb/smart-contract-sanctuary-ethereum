// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

struct FlexibleMetadataData { 
    string defaultTokenMetadata;
    string prerevealTokenMetadata;
    string flaggedTokenMetadata;
    mapping(string => string) supplementalTokenMetadata;
    string contractMetadata;
    mapping(uint256 => bool) tokenFlag;
    mapping(uint256 => Supplement) supplemental;
    bool tokenReveal; 
}    
struct Supplement {
    string key;
    bool exists;
}
bytes16 constant _SYMBOLS = "0123456789abcdef";
uint256 constant DEFAULT = 1;
uint256 constant FLAG = 2;
uint256 constant PRE = 3;
library SetFlexibleMetadata {
    function setDefaultTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.defaultTokenMetadata = uri;
    }  
    function setPrerevealTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.prerevealTokenMetadata = uri;
    }  
    function setFlaggedTokenMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.flaggedTokenMetadata = uri;
    }  
    function setSupplementalTokenMetadataURI(FlexibleMetadataData storage self, string memory key, string memory uri) public {
        self.supplementalTokenMetadata[key] = uri;
    }      
    function setContractMetadataURI(FlexibleMetadataData storage self, string memory uri) public {
        self.contractMetadata = uri;
    }  
    function reveal(FlexibleMetadataData storage self, bool revealed) public {
        self.tokenReveal = revealed;
    }

    function flagToken(FlexibleMetadataData storage self, uint256 tokenId, bool flagged) public {
        self.tokenFlag[tokenId] = flagged;
    }

    function getTokenMetadata(FlexibleMetadataData storage self, uint256 tokenId) public view returns (string memory) {
        if (self.tokenFlag[tokenId]) {
            return encodeURI(self.flaggedTokenMetadata,tokenId);
        } 
        if (!self.tokenReveal) {
            return encodeURI(self.prerevealTokenMetadata,tokenId);
        }
        if (self.supplemental[tokenId].exists) {
            return encodeURI(self.supplementalTokenMetadata[self.supplemental[tokenId].key],tokenId);
        }
        return encodeURI(self.defaultTokenMetadata,tokenId);
    }

    function getContractMetadata(FlexibleMetadataData storage self) public view returns (string memory) { 
        return self.contractMetadata;
    }    

    function encodeURI(string storage uri, uint256 tokenId) public pure returns (string memory) {
        return string(abi.encodePacked(uri, "/", toString(tokenId)));
    }

    function toString(uint256 value) public pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function log10(uint256 value) public pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }        
}