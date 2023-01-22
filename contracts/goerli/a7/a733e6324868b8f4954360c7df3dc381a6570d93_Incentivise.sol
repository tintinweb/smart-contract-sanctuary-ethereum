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
    event tokenAdded(uint256 postId, uint256 token);
    event getTokens(uint256 postId);

    function setToken(uint256 _postId, uint256 _totalTokens) public{
        tokens storage tok = posts[_postId];
        tok.postId = _postId;
        tok.totalTokens = _totalTokens;
        emit tokenAdded(_postId, _totalTokens);
    } 

    function getToken(uint256 _postId) public returns(tokens memory){
        emit getTokens(_postId);
        return(posts[_postId]);
    }   

    function sortWithToken() public{
        uint256 i = 0;
        while(posts[i].totalTokens != 0){
            emit post(i,posts[i]);
            i++;
        }
    }

}