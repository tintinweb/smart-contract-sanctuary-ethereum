/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

// File: contracts/Daughter.sol



pragma solidity ^0.8.0;

contract DaughterContract {
    string public name;
    uint public age;
    constructor(
        string memory _daughtersName,
        uint _daughtersAge
    )
    {
        name = _daughtersName;
        age = _daughtersAge;
    }
}
// File: contracts/Parent.sol



pragma solidity ^0.8.0;


contract ParentContract {

    constructor(){}

    function createNewDaughter(string memory _name_, uint256 _age_) public returns(address)
    {
        address test = address(new DaughterContract(_name_, _age_));
        
        return(test);
    }
}