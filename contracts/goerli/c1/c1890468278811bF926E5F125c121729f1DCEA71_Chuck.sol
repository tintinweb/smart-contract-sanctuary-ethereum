/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

pragma solidity 0.8.20;

contract Chuck {

uint public l;

constructor () {
    l == 5e15;
}

function Bruh (uint c) public payable {
        require ((msg.value) >= l, "sorry you didnt pay the right amount");
        
}
}