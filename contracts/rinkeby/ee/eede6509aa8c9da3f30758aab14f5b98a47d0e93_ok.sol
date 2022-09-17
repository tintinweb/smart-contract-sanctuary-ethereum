/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity >=0.4.16 <0.7.0;

contract ok
{
    int bal;

    constructor() public
    {
        bal = 1;
    }

    function getBalance() view public returns(int)
    {
        return bal;
    }
        function withdraw(int amt) public
    {    
        bal = bal -amt;
    }

    function deposit(int amt) public
    {
        bal = bal + amt;

    }
}