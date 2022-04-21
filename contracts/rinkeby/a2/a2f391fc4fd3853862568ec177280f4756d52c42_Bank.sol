/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

pragma solidity 0.4.25;

contract Bank {
    int bal;

    constructor() public {
        bal = 1;
    }

    function detail() view public returns(int){
        return bal;
    }

    function inc(int amt) public {
        bal = bal + amt;
    }

    function dec(int amt) public {
        bal = bal - amt;
    }
}