/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }    
    function querybalance() public view returns(uint){
        return owner.balance; //這個owner的餘額
    }
    function querybalance1() public view returns(uint){
        return address(this). balance; //智能合約餘額
    }
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}