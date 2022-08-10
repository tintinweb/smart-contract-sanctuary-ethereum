/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;


contract VaganContract {

    string message = "Vagan is PeaceDaBall";

    function whoIsVagan() public view returns (string memory) {
        return message;
    }


}