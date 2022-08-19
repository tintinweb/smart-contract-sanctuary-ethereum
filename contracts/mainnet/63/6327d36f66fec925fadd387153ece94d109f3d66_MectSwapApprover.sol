/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: GNU AGPLv3
pragma solidity 0.8.16;

/// @title MectSwapApprover
/// @notice Contract allowing accounts to set their approval response for the swap of MECT tokens to MORPHO tokens.
contract MectSwapApprover {
    /// EVENTS ///

    /// @notice Emitted when the `approver` sets an `approval` response.
    /// @param approver The address of the approver.
    /// @param approval The approval response.
    event ApprovalSet(address indexed approver, bool approval);

    /// STORAGE ///

    mapping(address => bool) public approvals; // Approvals. approver -> approval

    /// EXTERNAL ///

    /// @notice Sets approval to swap MECT to MORPHO.
    /// @param _approval Whether of not the swap is approved.
    function setApproval(bool _approval) external {
        approvals[msg.sender] = _approval;

        emit ApprovalSet({ approver: msg.sender, approval: _approval });
    }
}