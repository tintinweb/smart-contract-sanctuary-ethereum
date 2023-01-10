/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Faucet {
    

    function withdraw(uint _amount) public {
        require(_amount <= 100000000000000000);
        payable(msg.sender).transfer(_amount);
    }

    //fallback function
    receive() external payable{}
}