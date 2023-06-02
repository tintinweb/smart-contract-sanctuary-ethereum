/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
contract Day4 {
    bool public isMessage = true;

    int private I = -123;
    uint public U = 999999;
    int8 public I8 = -4;
    uint256 public U256 = 3;

    address public JayAddr = 0x532826557F5Eb54aD3de956ce4DA39d1FA6c4146;
    address payable public PayJayAddr = payable (JayAddr);

    function  getI() view public returns(int){
        return I;
    }

    enum Color { Blue, Green }
    Color public C = Color.Green;
}