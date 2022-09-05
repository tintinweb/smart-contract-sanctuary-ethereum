/**
 *Submitted for verification at Etherscan.io on 2022-09-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.5.16;

contract MyContract {

    enum State {Waiting, Ready, Active }  State public state;

    constructor() public {
        state=State.Waiting;
    }

    function activate() public{
        state=State.Active;
    }

    function isActive() public view returns(bool) {
        return state == State.Active;
    }

}