// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

//sample contract is called payableSample
contract  payableSample {
    
    uint amount =0;
    

    //payable is added to this function so another contract can call it and send ether to this contract
    function payMeMoney() public payable{
        amount += msg.value;
    }
}