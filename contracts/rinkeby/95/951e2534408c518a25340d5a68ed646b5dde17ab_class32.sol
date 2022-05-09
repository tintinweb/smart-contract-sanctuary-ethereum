/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance1() public view returns(uint){
        return owner.balance;
        // return address(this).balance;
    }
       function querybalance2() public view returns(uint){
        // return owner.balance;
        return address(this).balance;
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}