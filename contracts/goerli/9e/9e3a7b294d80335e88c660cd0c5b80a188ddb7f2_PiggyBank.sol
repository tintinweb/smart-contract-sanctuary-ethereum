/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PiggyBank {
    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getContractBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() public {
        if(getContractBalance() > goal) {
            address payable addr = payable(address(msg.sender));
            selfdestruct(addr);
        }
    }
}