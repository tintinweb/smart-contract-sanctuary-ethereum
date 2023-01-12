/**
 *Submitted for verification at Etherscan.io on 2023-01-12
*/

// SPDX-License-Identifier: Michael A Poole 2022
pragma solidity ^0.8.8;


contract FundMike {

address public owner;

constructor() {
        owner = msg.sender;
    }

function fundMike() public payable  {

require (msg.value >= 0, "Did not send enough");

}

function withdrawToMike() public {

        require(msg.sender == owner, "You are not the owner of this account");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fundMike();
    }

    receive() external payable {
        fundMike();
    }



}