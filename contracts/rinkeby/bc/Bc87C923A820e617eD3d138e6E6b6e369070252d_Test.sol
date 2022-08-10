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

pragma solidity ^0.8.15;

import "./libraries/CloneXMetadataUtils.sol";

abstract contract CloneMetadata {
    function clonex(uint256 tokenId) public view virtual returns (CloneXMetadataUtils.Metadata memory);
}

contract Test {
    constructor(address cloneXMetadata_) {
        cloneXMetadata = CloneMetadata(cloneXMetadata_);
    }

    CloneMetadata cloneXMetadata;

    function isDrip(uint256 tokenId) public view returns (bool) {
        return cloneXMetadata.clonex(tokenId).cloneType == 0x3031;
    }
}