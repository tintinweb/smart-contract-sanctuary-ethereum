/**
 *Submitted for verification at Etherscan.io on 2022-11-11
*/

pragma solidity ^0.8.0;

contract Record {
    string str = "696C6F76657A786A";

    function find() view public returns(string memory strs){
        strs = str;
    }
}