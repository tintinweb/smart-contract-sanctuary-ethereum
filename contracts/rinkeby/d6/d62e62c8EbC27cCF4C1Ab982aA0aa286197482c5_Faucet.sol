/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.4.22;

contract Faucet {
    function withdraw(uint _amount) public {
        require(_amount <= 1000000000000000000);
        msg.sender.transfer(_amount);
    }

    function () public payable {}
}