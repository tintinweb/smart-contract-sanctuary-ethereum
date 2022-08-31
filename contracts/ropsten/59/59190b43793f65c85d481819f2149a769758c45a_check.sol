/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

pragma solidity ^0.8.4;
contract check{
    address public owner;
    uint public balance;
    constructor(){
        owner = msg.sender;
        balance = 0;
    }
    modifier onlyowner (){
        require(owner == msg.sender,"only owner can call" );
        _;
    }
    function deposit(uint _amount)public onlyowner{
        balance = _amount ;
        assert(balance > 0);
    }
    function withdraw(uint _a)public pure{
        if(_a<0){
            revert("must be more than 0");
        }
    }
}