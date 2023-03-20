/**
 *Submitted for verification at Etherscan.io on 2023-03-20
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

contract SmartWill {
    address payable public owner;
    uint256 public lastAlive;
    mapping(address => bool) public beneficiaries;
    address[] public beneficiaryList;

    constructor() payable {
        owner = payable(msg.sender);
        lastAlive = block.timestamp;
    }

    function setBeneficiary(address _beneficiary) public {
        require(msg.sender == owner, "Only the owner can set beneficiaries.");
        beneficiaries[_beneficiary] = true;
        beneficiaryList.push(_beneficiary);
    }

    function removeBeneficiary(address _beneficiary) public {
        require(msg.sender == owner, "Only the owner can remove beneficiaries.");
        beneficiaries[_beneficiary] = false;
        for (uint i = 0; i < beneficiaryList.length; i++) {
            if (beneficiaryList[i] == _beneficiary) {
                beneficiaryList[i] = beneficiaryList[beneficiaryList.length - 1];
                beneficiaryList.pop();
                break;
            }
        }
    }

    function alive() public {
        require(msg.sender == owner, "Only the owner can update last alive.");
        lastAlive = block.timestamp;
    }

    function distributeFunds() private {
        uint numBeneficiaries = beneficiaryList.length;
        uint amountPerBeneficiary = address(this).balance / numBeneficiaries;
        for (uint i = 0; i < numBeneficiaries; i++) {
            payable(beneficiaryList[i]).transfer(amountPerBeneficiary);
        }
    }

    function automaticDistribution() public {
        require(msg.sender == owner, "Only the owner can trigger automatic distribution.");
        require(address(this).balance > 0, "No funds to distribute.");
        distributeFunds();
    }

    function getLastAlive() public {
        require(beneficiaries[msg.sender], "Only designated beneficiaries can get the last alive timestamp.");
        require(block.timestamp > lastAlive + 365 days, "Last alive timestamp has not elapsed.");
        automaticDistribution();
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // fallback function to receive ether sent to the contract
    receive() external payable {}

    // self-destruct function to destroy the contract and send remaining funds to the owner
    function destroy() public {
        require(msg.sender == owner, "Only the owner can self-destruct the contract.");
        selfdestruct(owner);
    }
}