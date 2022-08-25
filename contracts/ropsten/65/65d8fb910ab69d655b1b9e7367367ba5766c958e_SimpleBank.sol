/**
 *Submitted for verification at Etherscan.io on 2022-08-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract SimpleBank {

    // state variables
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public transcitions;

    address public owner;


    // functions
    constructor() payable{
        owner = msg.sender;
        balanceOf[owner] += msg.value;  //if the deployer deposite at the time of deployment, his balance eill be changed
    }

    // function to deposite ether to this contract address
    function deposite() public payable{
        payable(address(this)).transfer(msg.value);  //here using transfer function

        balanceOf[msg.sender] += msg.value;
    }

    // function to send ether to another address
    function sendTo(address _to) public payable returns(bytes memory){
        
        require(balanceOf[msg.sender] >= msg.value, "you do not have enough balance !");

        (bool sent, bytes memory data) = payable(_to).call{value:msg.value}("sent");   // here using call function
        require(sent, "there is some problem in this transcition !");
        
        balanceOf[msg.sender] -= msg.value;            //updating balance of sender
        balanceOf[_to] += msg.value;                   //updating balance of receiver
        transcitions[msg.sender][_to] += msg.value;    //transcitions between sender and receiver
        
        return data;
    }

    function checkContractBalance() public view returns(uint){
        require(msg.sender == owner, "you are not the owner !");

        return address(this).balance;
    }


    fallback() external payable{
        balanceOf[msg.sender] += msg.value;   // will update balance of address who send ether using fallback function
    }  

}