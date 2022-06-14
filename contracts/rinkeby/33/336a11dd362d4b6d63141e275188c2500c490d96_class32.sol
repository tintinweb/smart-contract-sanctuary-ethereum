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
        return owner.balance; //查看自己的錢包地址餘額
    }
    
    function querybalance1() public view returns(uint){
        return address(this).balance; //查看這個智能合約的餘額
    }

    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money); //由智能合約轉幣到自己的地址
    }
}