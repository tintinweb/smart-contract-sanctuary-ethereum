/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance() public view returns(uint){
        // return owner.balance; // 查詢 owner 的餘額 
        // 等於下面這件事
        return address(this).balance;
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money); 
        return reuslt; // 
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}