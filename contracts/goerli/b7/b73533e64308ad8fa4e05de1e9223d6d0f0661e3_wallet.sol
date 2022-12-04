/**
 *Submitted for verification at Etherscan.io on 2022-12-04
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;
contract wallet{
    //read
    string public name="wallet";
    uint num;
     
    //write
    function setValue(uint _num) public {
        num=_num;
    }
    //read
     function getValue() public view returns(uint){
        return num;
    }
    //write
    function sendEthContract() public payable{
        
    }
    //read
    function contractBalance() public view returns(uint){
        return address(this).balance;
    }
    //write
    function sendEthUser(address _user) public payable{
       payable(_user).transfer(msg.value);
    }
    //read
    function accountBalance(address _address) public view returns(uint){
        return (_address).balance;
    }
}