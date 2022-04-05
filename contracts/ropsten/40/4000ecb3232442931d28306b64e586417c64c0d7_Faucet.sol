/**
 *Submitted for verification at Etherscan.io on 2022-04-05
*/

pragma solidity ^0.4.19;

contract Faucet{
    function withdraw(uint withdraw_amount) public{
        require(withdraw_amount <= 100000000000000000);
        msg.sender.transfer(withdraw_amount);
    }

    function() public payable{}

    event OwnerSet(address indexed owner);
    event AddRet(uint indexed ret);
    event Equal(bool indexed ret);

    address owner;

    constructor(){
        owner = msg.sender;
        emit OwnerSet(owner);
    }

    function add(uint a, uint b) public returns(uint){
        uint c = a + b;
        emit AddRet(c);
        return c;
    }

    function equal(uint a, uint b) public returns(bool){
        bool ret = a == b;

        emit Equal(ret);
        return ret;
    }
}