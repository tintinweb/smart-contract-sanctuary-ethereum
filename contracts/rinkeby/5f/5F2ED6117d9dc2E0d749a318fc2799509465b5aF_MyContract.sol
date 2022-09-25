/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract MyContract {

    string public myMsg = "Hello World!";

    function setMsg( string calldata newMsg) external {
        myMsg = newMsg;
    }
}