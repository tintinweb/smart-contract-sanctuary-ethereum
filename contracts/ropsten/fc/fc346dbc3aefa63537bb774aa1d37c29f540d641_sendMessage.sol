/**
 *Submitted for verification at Etherscan.io on 2022-09-06
*/

// SPDX-License-Identifier: MIT
// Further information: https://eips.ethereum.org/EIPS/eip-2770
pragma solidity ^0.8.5;


contract sendMessage {

    string[3] private txt = ["Hope that you have fun in your new job!", "Missing you here !", "Hope to see you soon..."];

 
    function readMsg1() public view returns(string memory) {
        return txt[0];
    }
    function readMsg2() public view returns(string memory) {
        return txt[1];
    }
    function readMsg3() public view returns(string memory) {
        return txt[2];
    }
}