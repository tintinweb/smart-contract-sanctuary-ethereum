/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: SimpleBank.sol


pragma solidity ^0.8.10;

contract SimpleBank {
    mapping( address => uint ) private money;

    function withdraw(uint amount) external payable {
        require(amount <= money[msg.sender], "not enough money");
        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent, "fail");
    }

    function deposit() external payable {
        money[msg.sender] += msg.value;
    }

    function gatBalance() public view returns (uint) {
        return money[msg.sender];
    }
}