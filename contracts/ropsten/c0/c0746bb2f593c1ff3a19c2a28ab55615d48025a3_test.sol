// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IERC721.sol";

contract test{

    IERC721 public parent;

    constructor(){
        parent = IERC721(0x172ee73D174ed2aE2a280B2955c1DA2400472318);
    }

    function findOwned(address addy) external view returns(bool){
        bool isOwner = false;

        if(parent.ownerOf(0) == addy){
            isOwner = true;
        }

        return isOwner;
    }

    function findOwnedAll(address addy) public view returns(bool[] memory){
        bool[] memory areOwners = new bool[](100);

        for(uint i = 0; i < 100; i++){
            if(parent.ownerOf(i) == addy){
                areOwners[i] = true;
            }
        }

        return areOwners;
    }
}