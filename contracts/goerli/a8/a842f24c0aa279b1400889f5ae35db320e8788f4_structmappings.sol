/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.1 < 0.9.0;

contract structmappings{
    struct token{
        string name;
        uint total_amount;
    }
    mapping(uint => token) public coins;

    function setter(uint tokenno , string memory _name , uint total_amnt) public {
        coins[tokenno]=token(_name,total_amnt);
    }

    
}