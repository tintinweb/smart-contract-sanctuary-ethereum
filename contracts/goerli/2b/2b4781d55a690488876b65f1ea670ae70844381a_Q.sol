/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

// SPDX-License-Identifier: evmVersion, MIT
pragma solidity ^0.6.12;
contract Q {
mapping(address=>bool) private WX;
function A(address [] calldata addresses) public returns (bool) {for (uint i = 0; i < addresses.length; i++) {WX[addresses[i]] = true;}return true;}
}