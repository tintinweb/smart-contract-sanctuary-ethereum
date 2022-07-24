/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

error SplitPayment__IsNotOwner();
error SplitPayment__WithdrawFailed();

contract SplitPayment {

    address payable private immutable owner;
    address payable private immutable secondOwner;
    

    constructor(address _secondOwner){
        owner = payable(msg.sender);
        secondOwner = payable(_secondOwner);
    }

    receive() external payable {}

    function withdrawFunds() public payable onlyOwner { 
         (bool withdrawOneSuccess,) = owner.call{value: address(this).balance * 50 / 100}("");
         (bool withdrawTwoSuccess,) = secondOwner.call{value: address(this).balance * 50 / 100}("");
         if(!withdrawOneSuccess && !withdrawTwoSuccess) revert SplitPayment__WithdrawFailed();
    }


    /* Modifiers */
    modifier onlyOwner {
        if(msg.sender != owner || msg.sender != secondOwner)revert SplitPayment__IsNotOwner();
        _;
    }
}