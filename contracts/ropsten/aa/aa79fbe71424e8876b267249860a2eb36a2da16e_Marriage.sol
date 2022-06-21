/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
contract Marriage
{
    string private personne1;
    string private personne2;

    constructor(string memory _personne1, string memory _personne2)
    {
        personne1 = _personne1;
        personne2 = _personne2;
    }

    function GetPersonne1() public view returns(string memory)
    {
        return personne1;
    }

    function GetPersonne2() public view returns(string memory)
    {
        return personne2;
    }

    function GetAdresse() public view returns (address)
    {
        return address(this);
    }
}