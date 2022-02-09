/**
 *Submitted for verification at Etherscan.io on 2022-02-08
*/

pragma solidity ^0.4.21;

contract flashbots {
    function withdraw() public {
        msg.sender.transfer(address(this).balance);
    }

    function deposit(uint256 amount) payable public {
        require(msg.value == amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }
}