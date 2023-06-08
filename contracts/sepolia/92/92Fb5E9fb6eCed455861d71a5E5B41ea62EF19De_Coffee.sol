/**
 *Submitted for verification at Etherscan.io on 2023-06-07
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


contract Coffee{
    address payable owner;

    constructor() payable {
        owner = payable(msg.sender);
    }

    // check for owner
    modifier IsOwner(){
        require(
            msg.sender == owner,
            "Only owner can call this"
        );
        _;
    }

    /* 
    The author of this smart contract is a student who is very interested in blockchain technology.
    These 4% will be used to distribute this service to other blockchains, and of course, coffee to the author)
    */
    function buyCoffe(address payable  to) public payable {
        uint256 send_amount = msg.value / 25 * 24;
        to.transfer(send_amount);
    }

    function withdraw() public IsOwner {
        owner.transfer(address(this).balance);
    }

    function getOnew() public view returns (address){
        return owner;
    }

    function getAmount() public view returns(uint256){
        return address(this).balance;
    }
}