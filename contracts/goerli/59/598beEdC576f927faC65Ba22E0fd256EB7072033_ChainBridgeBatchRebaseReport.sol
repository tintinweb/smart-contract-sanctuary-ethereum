// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.3;

interface IBridge {
    function deposit(
        uint8 destinationChainID,
        bytes32 resourceID,
        bytes calldata data,
        bytes calldata feeData
    ) external payable;

    function calculateFee(
        uint8 destinationDomainID,
        bytes32 resourceID,
        bytes calldata depositData,
        bytes calldata feeData
    ) external view returns (uint256);
}

interface IPolicy {
    function globalAmpleforthEpochAndAMPLSupply() external view returns (uint256, uint256);
}

/**
 * @title ChainBridgeBatchRebaseReport
 * @notice Utility that executes rebase report 'deposit' transactions in batch.
 */
contract ChainBridgeBatchRebaseReport {
    function execute(
        address policy,
        address bridge,
        uint8[] memory destinationChainIDs,
        bytes32 resourceID
    ) external payable {
        uint256 epoch;
        uint256 totalSupply;
        (epoch, totalSupply) = IPolicy(policy).globalAmpleforthEpochAndAMPLSupply();

        uint256 dataLen = 64;
        bytes memory txData = abi.encode(dataLen, epoch, totalSupply);
        bytes memory feeData = "";

        for (uint256 i = 0; i < destinationChainIDs.length; i++) {
            uint8 destinationChainID = destinationChainIDs[i];
            uint256 bridgeFee = IBridge(bridge).calculateFee(
                destinationChainID,
                resourceID,
                txData,
                feeData
            );
            IBridge(bridge).deposit{value: bridgeFee}(
                destinationChainID,
                resourceID,
                txData,
                feeData
            );
        }
    }
}