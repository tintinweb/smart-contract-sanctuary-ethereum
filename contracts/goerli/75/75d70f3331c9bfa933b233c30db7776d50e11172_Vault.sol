// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Vault {

    address immutable  owner; 

    bytes32 public last;


    constructor(){

        owner = msg.sender;

    }


    event Withdraw(address to);

    function withdraw(address to) external{


        if(msg.sender == owner){
            last = "Withdraw by owner";
        }else{
            last = "Withdraw by stranger";
        }
        
        payable(to).transfer(address(this).balance);

        emit Withdraw(to);
    }

    receive() external payable{}
}