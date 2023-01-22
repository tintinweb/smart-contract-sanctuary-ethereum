/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

contract Incentivise {

    struct tokens {
        uint256 postId;
        uint256 totalTokens;
    }
    
    mapping(uint256 => tokens) posts;
    event post(uint256 postId, tokens token);

    function setToken(uint256 _postId, uint256 _totalTokens) public{
        tokens storage tok = posts[_postId];
        tok.postId = _postId;
        tok.totalTokens = _totalTokens;
    } 

    function getToken(uint256 postId) public view returns(tokens memory){
        return(posts[postId]);
    }   

    function sortWithToken() public{
        uint256 i = 0;
        while(posts[i].totalTokens != 0){
            emit post(i,posts[i]);
            i++;
        }
    }

}