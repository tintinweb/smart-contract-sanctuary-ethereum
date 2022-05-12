/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// File: SimpleBank_v2.sol


pragma solidity ^0.5.5;

contract SimpleBank {
    mapping(address => uint) private balances;

    function withdraw(address payable to, uint amount) external {
        require(balances[msg.sender] >= amount, "Insufficient funds.");

        // (bool sent, ) = payable(msg.sender).call{value: amount}("");
        
        to.transfer(1 ether);

        // require(sent, "Could not withdraw!");
        balances[msg.sender] -= amount;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function getBalance() public view returns (uint) {
        uint res = balances[msg.sender];
        return res;
    }

}