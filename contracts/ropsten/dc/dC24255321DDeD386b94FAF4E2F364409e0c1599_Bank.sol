/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;


contract Bank{
    
    
    // uint _balance;
    mapping(address => uint) _balance;
    uint _totalsupply ; 
 
    function deposit() public payable {
        _balance[msg.sender] += msg.value;
        _totalsupply += msg.value;
    }

    function withdraw(uint amount) public payable {
        require(amount <= _balance[msg.sender],"Not Enough");
        payable(msg.sender).transfer(amount);

        _balance[msg.sender] -= amount ;
        _totalsupply -= amount ;
    }


    function checkbalance() public view returns(uint totalbalance){
        return _balance[msg.sender];
    }

    function checktotalsupply() public view returns(uint totalsupply){
        return _totalsupply ;
    }


}