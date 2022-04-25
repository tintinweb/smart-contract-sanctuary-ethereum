/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract hisVows {

    string public theVows = "These are his vows and he luvs her and stuff.";

    function getTheVows() public view returns (string memory) {
        return theVows;
    }

}