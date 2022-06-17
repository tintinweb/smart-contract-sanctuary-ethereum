/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^ 0.8.12;
contract Test{

    uint amount;
    address payable owner;
    

    constructor() public {
        owner = payable(msg.sender);
    }

    function Send(address payable account) public payable{
        amount = msg.value;
        account.transfer(amount);
    }
}