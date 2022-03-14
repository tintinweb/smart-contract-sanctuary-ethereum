/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;

contract SimpleStorage {
    bool isAdmin = false;

    function getr() public view returns (bool) {
        return isAdmin;
    }

    function setr() public {
        /*‮ } ⁦ if(isAdmin)⁩⁦ 
        do this only if user is an admin*/
        isAdmin = true;
        /*else do nothing‮{⁦*/
    }
}