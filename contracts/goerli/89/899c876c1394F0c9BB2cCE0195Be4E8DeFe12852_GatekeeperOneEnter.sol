/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOneEnter {
    // IGatekeeperOne gatekeeperOne;

    modifier gateTwo() {
        require(gasleft() % 8191 == 0, 'wrong gas!');
        _;
    }

    // constructor(IGatekeeperOne gatekeeper) {
    //     gatekeeperOne = gatekeeper;
    // }

    function enter2(bytes8 _gateKey) public gateTwo returns(bool) {
        return true;
    }

    // function enter(bytes8 _gateKey) public {
    //     gatekeeperOne.enter(_gateKey);
    // }

    function gas1() public view returns(uint) {
        return gasleft();
    }

    function gas2() public view returns(uint) {
        return gasleft() % 8191;
    }

}