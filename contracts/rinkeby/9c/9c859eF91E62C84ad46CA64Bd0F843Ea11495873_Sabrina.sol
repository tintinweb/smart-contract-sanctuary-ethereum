/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

//SPDX-License-Identifier: MIT

// File: contracts/Lucifer.sol
pragma solidity ^0.8.0;

interface InterSabrinaAge{
    function SetAgeOfSabrina(uint256 _sabrinaAge) external returns(uint256);   
}

contract Lucifer{

    address public lucifer;

    constructor()
    {
        lucifer = msg.sender;
    }

    uint256 public SabrinaAge;



    function SetAgeOfSabrina(uint256 _sabrinaAge) external returns(uint256)
    {
        require(msg.sender == lucifer , "only lucifer can set the age");

        SabrinaAge = _sabrinaAge;

        return SabrinaAge;
    }
    
}

pragma solidity ^0.8.0;



contract Sabrina is Lucifer{

    uint256 public ageOfSabrina = 14;
    address public lucifers;

    constructor(address _lucifer)
    {
        lucifers = _lucifer;
    }

    function updateAge()public  returns(uint256)
    {
        ageOfSabrina = SabrinaAge;

        return SabrinaAge;

    }

    // function SetAgeSabrina;

}