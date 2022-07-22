// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "./Son.sol";

contract DadContract{

    //Other contracts
    PPtoken private pptoken;
    constructor(){
        pptoken = PPtoken(0x0144B7e66993C6BfaB85581e8601f96BFE50c9Df);
    }


    function getVote(uint256 tokenId, address delegatee) public{
        Son current = new Son();
        pptoken.transferFrom(msg.sender, address(current), tokenId);
        current.claDelTra(tokenId, delegatee);
    }


    function getMultipleVotes(uint256[] memory tokenIds, address delegatee) public{
        for(uint i = 0; i < tokenIds.length; i++){
            getVote(tokenIds[i], delegatee);
        }
    }

 
}