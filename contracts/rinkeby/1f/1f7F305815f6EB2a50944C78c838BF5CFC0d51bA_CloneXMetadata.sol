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
                // bytes2(bytes.concat(b[0], b[1])),
                // bytes2(bytes.concat(b[2], b[3])),
                // bytes2(bytes.concat(b[4], b[5])),
                // bytes2(bytes.concat(b[6], b[7])),
                // bytes2(bytes.concat(b[8], b[9])),
                // bytes2(bytes.concat(b[10], b[11]))
                // bytes2(bytes.concat(b[12], b[13])),
                // bytes2(bytes.concat(b[14], b[15])),
                // bytes2(bytes.concat(b[16], b[17])),
                // bytes2(bytes.concat(b[18], b[19])),
                // bytes2(bytes.concat(b[20], b[21])),
                // bytes2(bytes.concat(b[22], b[23])),
                // bytes2(bytes.concat(b[24], b[25]))
                b[0],
                b[1],
                b[2],
                b[3],
                b[4],
                b[5],
                b[6],
                b[7],
                b[8],
                b[9],
                b[10],
                b[11],
                b[12]
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
        bytes1 dna;
        bytes1 cloneType;
        bytes1 accessories;
        bytes1 mouth;
        bytes1 eyewear;
        bytes1 eyeColor;
        bytes1 clothing;
        bytes1 facialFeature;
        bytes1 hair;
        bytes1 helmet;
        bytes1 jewlery;
        bytes1 level;
        bytes1 misc;
    }
}