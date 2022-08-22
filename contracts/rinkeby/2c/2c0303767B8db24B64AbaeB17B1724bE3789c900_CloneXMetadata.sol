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

abstract contract ERC721 {
    function ownerOf(uint256 tokenId) public view virtual returns (address);
}

contract CloneXMetadata {
    address cloneXcontract; 
    mapping (address => bool) authorizedOwners;
    // mapping (uint256 => Metadata) public clonex;
    bytes2[] public clonex;
    bool[20000] public lockingState;

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

    function setMetadata(uint256[] calldata tokenIds, bytes2[] memory metadatas) public isAuthorizedOwner {
        clonex = metadatas;
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 cloneIndex = getCloneIndex(tokenIds[i]);
            require(!lockingState[cloneIndex], "This CloneX is locked by its owner and can't be modified");

            lockingState[cloneIndex] = true;
        }
    }

    /**
        GETTER
    **/

    function getCloneIndex(uint256 tokenId) public pure returns (uint256) {
        return tokenId - 1;
    }

    function getDNA(uint256 tokenId) public view returns (bytes1) {
        return clonex[getCloneIndex(tokenId)][0];
    }

    function isMurakami(uint256 tokenId) public view returns (bool) {
        return clonex[getCloneIndex(tokenId)][1] == 0x31;
    }

    /**
        SETTER
    **/

    function toggleLockingState(uint256[] calldata tokenIds) public {
        ERC721 CloneXCollection = ERC721(cloneXcontract);

        for(uint256 i = 0; i < tokenIds.length; ++i) {
            uint256 cloneIndex = getCloneIndex(tokenIds[i]);
            require(CloneXCollection.ownerOf(tokenIds[i]) == msg.sender, "Don't own that CloneX");
            lockingState[cloneIndex] = !lockingState[cloneIndex];
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
}