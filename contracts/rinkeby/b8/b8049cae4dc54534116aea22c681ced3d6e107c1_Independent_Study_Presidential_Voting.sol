/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Independent_Study_Presidential_Voting {

    uint public TheodoreRoosevelt = 0;
    uint public AbrahamLincoln = 0;

    function vote_TheodoreRoosevelt() public {
        TheodoreRoosevelt = TheodoreRoosevelt + 1;
    }

    function vote_AbrahamLincoln() public {
        AbrahamLincoln = AbrahamLincoln + 1;
    }

    function get_TheodoreRoosevelt() public view returns (uint){
        return TheodoreRoosevelt;
    }

    function get_AbrahamLincoln() public view returns (uint){
        return AbrahamLincoln;
    }

}