/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

pragma solidity ^0.4.24;
contract class32{
    address owner;
    constructor() public payable{
        owner = msg.sender; //發送者address
    }    
    function querybalance1() public view returns(uint){
        return owner.balance; //表這個合約，this就是這個合約，所以就是用這個合約的地址
    }

    function querybalance2() public view returns(uint){
        return address(this).balance; //表這個合約，this就是這個合約，所以就是用這個合約的地址
    }
    
    function send(uint money) public returns(bool){
        bool reuslt = owner.send(money);
        return reuslt;
    }
    
    function transfer(uint money) public {
        owner.transfer(money);
    }
}