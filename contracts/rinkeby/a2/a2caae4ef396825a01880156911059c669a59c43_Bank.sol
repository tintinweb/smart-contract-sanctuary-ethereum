/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.10;

contract Bank {
    mapping (address => uint256) public accounts;

    function deposit( ) public payable {
        require(msg.value > 0, "deposit over 0");
        accounts[msg.sender] += msg.value;
    }

    function withdraw( uint256 money) public payable {
        require(money > 0, "withdraw over 0");
        require(accounts[msg.sender] - money >= 0, "balance more or equal to 0");
        payable(msg.sender).transfer(money);
        accounts[msg.sender] -= money;

    }
    function checkBalance() public view returns(uint256) {
        return accounts[msg.sender];
    }
}