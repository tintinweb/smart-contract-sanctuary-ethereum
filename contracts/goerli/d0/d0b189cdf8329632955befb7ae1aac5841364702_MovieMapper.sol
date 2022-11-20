/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

contract MovieMapper {
    mapping (string => uint) movie_count_mapper;
    
    function increment(string memory movie_name) public  {
        movie_count_mapper[movie_name] += 1;
     }

    function getCount(string memory movie_name) public view returns (uint256) {
        return movie_count_mapper[movie_name];
    }
}