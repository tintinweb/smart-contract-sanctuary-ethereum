/**
 *Submitted for verification at Etherscan.io on 2022-02-21
*/

pragma solidity ^0.8.10;

contract Jar {
    mapping(address => uint) public balances;

    function deposit() public payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "No balance to withdraw");
        (bool success, ) = payable(msg.sender).call{value: balances[msg.sender]}("");
        require(success, "Failed to send ether");
        balances[msg.sender] = 0;

    }

    // Helper function to check the balance of this contract
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}