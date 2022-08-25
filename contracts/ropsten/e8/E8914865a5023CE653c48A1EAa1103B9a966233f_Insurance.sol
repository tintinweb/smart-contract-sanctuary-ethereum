/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
contract Insurance{
    address public company;
    uint public value;
    constructor(){
        company=msg.sender;
        value=10000;
    }
    mapping(address => uint) public traveler;
    function buyInsurance(address _travelerAddr,uint _amt) public{
        require(_amt==500,"You have to pay Rs. 500");
        traveler[_travelerAddr]=_amt;
    }
    function isLate(address _travelerAddr,bool _ans) public{
        if(traveler[_travelerAddr]==500&&_ans==false){
            revert("Not Eligible for claim");
        }
        else if((traveler[_travelerAddr]!=500&&_ans==true)||(traveler[_travelerAddr]!=500&&_ans==false)){
            revert("You do not have Insurance to claim");
        }
        else{
            traveler[_travelerAddr]+=value;
            delete value;
        }
    }
}