/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity ^0.4.26;

contract invest{
    uint public investors = 0;
    int256 public Amount = 0;

    // "payable" modifier : this function can transfer/receive money
    function pay(int256 _Money) public payable{
        investors++;
        Amount = Amount + _Money;
    }
}