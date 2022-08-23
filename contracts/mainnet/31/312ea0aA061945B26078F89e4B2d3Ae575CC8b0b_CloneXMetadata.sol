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
    bytes2[20001] public clonex;
    bool[20001] public lockingState;

    constructor() {
        authorizedOwners[msg.sender] = true;
        clonex[0] = 0x0000;
        lockingState[0] = true;
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
        for(uint256 i = 0; i < tokenIds.length; ++i) {
            require(!lockingState[tokenIds[i]], "This CloneX is locked by its owner and can't be modified");

            clonex[tokenIds[i]] = metadatas[i];

            lockingState[tokenIds[i]] = true;
        }
    }

    /**
        GETTER
    **/

    function getDNA(uint256 tokenId) public view returns (bytes1) {
        return clonex[tokenId][0];
    }

    function isMurakami(uint256 tokenId) public view returns (bool) {
        return clonex[tokenId][1] == 0x31;
    }

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

}