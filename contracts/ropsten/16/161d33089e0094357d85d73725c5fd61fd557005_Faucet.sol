/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

pragma solidity ^0.4.17;

contract Faucet {
    function withdraw(uint amount) public {
        require(amount<=10000000000000000);
        msg.sender.transfer(amount);
    }
    function ()public payable{}
}