/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

contract OPISIds {
    string[] ids;
    function pushToIds(string memory _data) public{
        ids.push(_data);
    }
        function GetAllIds() view public returns(string[] memory){
        return ids;
    }
}