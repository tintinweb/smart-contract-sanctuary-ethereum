/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract demo_mocha {
   
    // uint256 number;

    // function store(uint256 num) public {
    //     number = num;
    // }

    // function retrieve() public view returns (uint256) {
    //     return number;
    // }

    uint public goal;

    constructor(uint _goal) {
        goal = _goal;
    }

    receive() external payable {}

    function getMyBalance() public view returns (uint) {
        return address(this).balance;
    }

    function withdraw() public {
        if(getMyBalance() > goal)
        {
            selfdestruct(msg.sender);
        }
    }

}