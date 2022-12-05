/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract CryptopsTeam {

    address[] public CryptopsDeveloperTeam;

    function JoinCryptopsDevTeam(address _newMember, bool _request) external {
        require( _request == true, "You have to be ambitious for hackhathons");

        CryptopsDeveloperTeam.push(_newMember);
        

    }
}