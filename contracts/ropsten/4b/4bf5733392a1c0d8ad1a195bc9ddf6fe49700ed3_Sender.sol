/**
 *Submitted for verification at Etherscan.io on 2022-06-27
*/

pragma solidity ^0.4.18;

contract Sender {
    address public receiver;

    uint256 balance = 0;
    
    function Sender(address addr) {
        receiver = addr;
    }

    function transferAll() payable {
        receiver.transfer(balance);
        balance = 0;
    } 

    function() payable external {
        balance += msg.value;
    }
}