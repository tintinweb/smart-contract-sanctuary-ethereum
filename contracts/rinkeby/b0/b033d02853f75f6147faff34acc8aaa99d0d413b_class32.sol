/**
 *Submitted for verification at Etherscan.io on 2022-04-18
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender;
    }

    function querycontractbalance() public view returns(uint) {
        return address(this).balance;
    }    

    function queryownerbalance() public view returns(uint){
        return owner.balance;
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}