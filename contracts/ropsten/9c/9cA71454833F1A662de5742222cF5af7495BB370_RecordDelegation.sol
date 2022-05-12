/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

contract RecordDelegation {
    struct Delegation {
        address delegator;
        uint256 amount;
    }
    mapping(address => mapping(address => uint256)) public delegationInfo;
    mapping(address => address[]) public delegatorInfo;
    mapping(address => mapping(address => bool)) public delegatorExist;

    function recordDelegation(address validatorAddress, uint256 amount) public {
        delegationInfo[validatorAddress][msg.sender] += amount;
        if (!delegatorExist[validatorAddress][msg.sender]) {
            delegatorInfo[validatorAddress].push(msg.sender);
            delegatorExist[validatorAddress][msg.sender] = true;
        }
    }

    function unstakeDelegation(address validatorAddress, uint256 amount) public {
        require(delegationInfo[validatorAddress][msg.sender] >= amount, "Not enough amount");
        
        delegationInfo[validatorAddress][msg.sender] -= amount;
    }
    
    function getDelegations(address validatorAddress) public view returns (Delegation[] memory) {
        Delegation[] memory delegations = new Delegation[](delegatorInfo[validatorAddress].length);
        uint256 count = 0;
        for (uint256 i = 0; i < delegatorInfo[validatorAddress].length; i++) {
            delegations[count].delegator = validatorAddress;
            delegations[count].amount = delegationInfo[validatorAddress][delegatorInfo[validatorAddress][i]];
        }
        return delegations;
    }
}