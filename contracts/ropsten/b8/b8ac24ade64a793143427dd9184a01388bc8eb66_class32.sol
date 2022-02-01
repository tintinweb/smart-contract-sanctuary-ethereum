/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    
    function querybalance() public view returns(uint){
        return owner.balance;  //owner的餘額
    }

    function thisbalance() public view returns(uint){
        return address(this).balance;  //轉入合約的餘額
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}