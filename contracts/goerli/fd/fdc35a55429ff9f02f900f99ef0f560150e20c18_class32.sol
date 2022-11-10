/**
 *Submitted for verification at Etherscan.io on 2022-11-10
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance1() public view returns(uint){
        return owner.balance;
    }

    function querytbalance2() public view returns(uint){
        return address(this).balance;  //this代表這份智能合約，address(this).balance代表這個智能喝月的餘額
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}