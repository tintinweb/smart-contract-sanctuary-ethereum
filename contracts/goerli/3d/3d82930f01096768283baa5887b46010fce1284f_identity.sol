/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: MIT

pragma solidity >= 0.5.0 < 0.9.0;

contract identity
{

    string name;
    uint age;

    constructor() public
    {

        name="Ravi";
        age=17;

    }

    function getName() view public returns(string memory)
    {
        return name;
    }
 
 
 function getAge() view public returns(uint)
    {
        return age;
    }
}