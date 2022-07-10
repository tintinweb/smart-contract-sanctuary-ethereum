/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.6.0;


contract erc20 {

    uint256 totalSupply_;

    address private owner;

    constructor( uint256 total ) public {

        totalSupply_ = total;
        owner = msg.sender;

        // balance[msg.sender] = totalSupply_;
    }

    function getOwner () public view returns (address) {
        return owner;
    }

    function getbalanceOf() public view returns ( uint256 ) {
        return owner.balance;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }



}