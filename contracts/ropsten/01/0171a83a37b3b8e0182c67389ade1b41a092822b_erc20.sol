/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.6.0;


contract erc20 {

    uint256 totalSupply_;

    constructor( uint256 total ) public {

        totalSupply_ = total;

        // balance[msg.sender] = totalSupply_;
    }

    function totalSupply() public view returns (uint256){
        return totalSupply_;
    }

}