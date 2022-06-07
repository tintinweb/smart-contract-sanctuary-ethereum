/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract Chen {


    uint public P1 = 0;
    uint public P2 = 0;

    function votep1() public {

        P1 = P1 + 1;

    }

    function votep2() public {

        P2 = P2 + 1;

    }

    function getP1() public view returns (uint){
        return P1;
    }

    function getP2() public view returns (uint){
        return P2;
    }


}