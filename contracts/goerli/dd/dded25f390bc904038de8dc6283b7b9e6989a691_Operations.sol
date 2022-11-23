/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

pragma solidity ^0.8.9;

contract Operations{
    uint256 public count;

    function add()public {
        count++;
    }
    
    function sub()public {
        count--;
    }

    
}