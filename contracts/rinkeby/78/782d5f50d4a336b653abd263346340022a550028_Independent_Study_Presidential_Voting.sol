/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Independent_Study_Presidential_Voting {


    uint public Theodore_Roosevelt = 0;
    uint public Abraham_Lincoln = 0;

    function vote_TheodoreRoosevelt() public {

        Theodore_Roosevelt = Theodore_Roosevelt + 1;

    }

    function vote_Abraham_Lincoln() public {

        Abraham_Lincoln = Abraham_Lincoln + 1;

    }

    function get_TheodoreRoosevelt() public view returns (uint){
        return Theodore_Roosevelt;
    }

    function get_AbrahamLincoln() public view returns (uint){
        return Abraham_Lincoln;
    }


}