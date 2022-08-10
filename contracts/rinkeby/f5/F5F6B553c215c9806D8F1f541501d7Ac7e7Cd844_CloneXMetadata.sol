// SPDX-License-Identifier: MIT
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         CloneX Metadata (made by @CardilloSamuel)

pragma solidity ^0.8.15;

import "./libraries/CloneXMetadataUtils.sol";

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract CloneXMetadata {
    address cloneXcontract; 
    mapping (address => bool) authorizedOwners;
    mapping (uint256 => CloneXMetadataUtils.Metadata) public clonex;
    mapping (uint256 => bool) public lockingState;

    // attribute name => index
    mapping (string => uint256) public attributes;

    constructor() {
        authorizedOwners[msg.sender] = true;
    }

    /** 
        MODIFIER 
    **/

    modifier isAuthorizedOwner() {
        require(authorizedOwners[msg.sender], "You are not authorized to perform this action");
        _;
    }

    /**
        MAIN FUNCTION
    **/

    function setMetadata(uint256[] calldata tokenIds, string[] calldata metadatas) public isAuthorizedOwner {
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            require(!lockingState[tokenIds[i]], "This CloneX is locked by its owner and can't be modified");
            bytes memory b = bytes(metadatas[i]);

            clonex[tokenIds[i]] = CloneXMetadataUtils.Metadata(
                _slice(b, 0, 2),
                _slice(b, 2, 4),
                _slice(b, 4, 6),
                _slice(b, 6, 8),
                _slice(b, 8, 10),
                _slice(b, 10, 12),
                _slice(b, 12, 14),
                _slice(b, 14, 16),
                _slice(b, 16, 18),
                _slice(b, 18, 20),
                _slice(b, 20, 22),
                _slice(b, 22, 24),
                _slice(b, 22, 24)
            );

            lockingState[tokenIds[i]] = true;
        }
    }

    /**
        GETTER
    **/

    /**
        SETTER
    **/

    function toggleLockingState(uint256[] calldata tokenIds) public {
        ERC721 CloneXCollection = ERC721(cloneXcontract);

        for(uint256 i = 0; i < tokenIds.length; ++i) {
            require(CloneXCollection.ownerOf(tokenIds[i]) == msg.sender, "Don't own that CloneX");
            lockingState[tokenIds[i]] = !lockingState[tokenIds[i]];
        }
    }

    /** 
        CONTRACT MANAGEMENT FUNCTIONS 
    **/ 

    function changeCloneXAddress(address newAddress) public isAuthorizedOwner {
        cloneXcontract = newAddress;
    }

    function toggleAuthorizedOwner(address newAddress) public isAuthorizedOwner {
        require(msg.sender != newAddress, "You can't revoke your own access");

        authorizedOwners[newAddress] = !authorizedOwners[newAddress];
    }

    function withdrawFunds(address withdrawalAddress) public isAuthorizedOwner {
        payable(withdrawalAddress).transfer(address(this).balance);
    }

    function _slice(bytes memory b, uint256 start, uint256 end) internal pure returns (bytes2) {
        bytes memory result = new bytes(end - start);
        for(uint i = start; i < end; i++) {
            result[i-start] = b[i];
        }
        return bytes2(result);
    }
}

// SPDX-License-Identifier: MIT
//          [email protected]@@                                                                  
//               ,@@@@@@@&,                  #@@%                                  
//                    @@@@@@@@@@@@@@.          @@@@@@@@@                           
//                        @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                      
//                            @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                   
//                                @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@.                 
//                                    @@@@@@@    &@@@@@@@@@@@@@@@@@                
//                                        @@@/        &@@@@@@@@@@@@@,              
//                                            @            @@@@@@@@@@@             
//                                                             /@@@@@@@#           
//                                                                  @@@@@          
//                                                                      *@&   
//         RTFKT Studios (https://twitter.com/RTFKT)
//         CloneX Metadata (made by @CardilloSamuel)

pragma solidity ^0.8.15;

library CloneXMetadataUtils {
    struct Metadata {
        bytes2 dna;
        bytes2 cloneType;
        bytes2 accessories;
        bytes2 mouth;
        bytes2 eyewear;
        bytes2 eyeColor;
        bytes2 clothing;
        bytes2 facialFeature;
        bytes2 hair;
        bytes2 helmet;
        bytes2 jewlery;
        bytes2 level;
        bytes2 misc;
    }
}