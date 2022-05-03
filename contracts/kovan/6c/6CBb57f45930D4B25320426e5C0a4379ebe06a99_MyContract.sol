pragma solidity >=0.7.0 <0.9.0;

contract MyContract{
    int bal;

    constructor() public
    {
        bal = 1;
    }

    function getBalance() public view returns(int){
        return bal;
    }

    function withdraw(int amt) public {
        bal = bal - amt;
    }     

    function deposit(int amt) public{
        bal = bal + amt;
    }
}