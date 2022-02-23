/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract PigBank {
    uint public goal;
    
    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns (uint){
        return address(this).balance;
    }

    function withdraw() public {
        if (getMyBalance() > goal)
            selfdestruct(payable(msg.sender));
    }

}