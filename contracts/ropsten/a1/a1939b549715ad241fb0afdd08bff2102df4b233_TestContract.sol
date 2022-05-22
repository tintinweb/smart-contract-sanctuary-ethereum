/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

pragma solidity ^0.4.21;

contract TestContract {
    function test() public payable {
        require(msg.value == 0.001 ether);
        msg.sender.transfer(msg.value);
    }
}