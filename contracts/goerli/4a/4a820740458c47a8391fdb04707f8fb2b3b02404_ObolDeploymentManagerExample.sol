/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ObolDeploymentManagerExample {

    // Represents the kind of info users will want to query
    // about their deployment
    struct DeploymentInfo {
        bool exists;
        address withdrawRecipient;
        address feeRecipient;
        address depositManager;
        uint rewardSplit;
    }

    mapping(address => mapping(string => DeploymentInfo)) deployments;

    // Deploy the contracts required to support a new cluster
    function deploy(string memory _clusterName, uint _rewardSplit) public returns (DeploymentInfo memory) {
        DeploymentInfo storage info = deployments[msg.sender][_clusterName];
        require(info.exists == false);
        
        info.exists = true;
        info.withdrawRecipient = deployWithdrawRecipient(_rewardSplit);
        info.feeRecipient = deployFeeRecipient(_rewardSplit);
        info.depositManager = deployDepositManager(_rewardSplit);
        info.rewardSplit = _rewardSplit;

        return info;
    }

    function getDeploymentInfo(address _creator, string memory _clusterName) public view returns (DeploymentInfo memory) {
        return deployments[_creator][_clusterName];
    }

    function deployWithdrawRecipient(uint) internal pure returns (address) {
        // Deploy withdraw contract with _rewardSplit
        return address(0xDEADBEEF);
    }

    function deployFeeRecipient(uint) internal pure returns (address) {
        // Deploy fee recipient contract with _rewardSplit
        return address(0xBADDAD);
    }

    function deployDepositManager(uint) internal pure returns (address) {
        // Deploy deposit manager contract with _rewardSplit
        return address(0xFEEDFAD);
    }
}