/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Faucet {
    constructor() {
        
    }

    function withdraw(uint _amount) public {
        require(_amount<100000000000000000);
        payable(msg.sender).transfer(_amount);
    }

    receive() external payable{}
}