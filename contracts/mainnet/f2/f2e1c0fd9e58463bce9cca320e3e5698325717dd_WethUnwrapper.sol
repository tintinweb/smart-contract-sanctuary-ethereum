/**
 *Submitted for verification at Etherscan.io on 2022-10-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
pragma abicoder v1;

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface InteractiveNotificationReceiver {
   /**
     * @notice Callback method that gets called after all funds transfers
     * @param orderHash Hash of the order being processed
     * @param maker Maker address
     * @param taker Taker address
     * @param makingAmount Actual making amount
     * @param takingAmount Actual taking amount
     * @param remainingAmount Limit order remaining maker amount after the swap
     * @param interactionData Interaction calldata
     */
    function fillOrderPostInteraction(
        bytes32 orderHash,
        address maker,
        address taker,
        uint256 makingAmount,
        uint256 takingAmount,
        uint256 remainingAmount,
        bytes memory interactionData
    ) external;
}

interface IWithdrawable {
    function withdraw(uint wad) external;
}

contract WethUnwrapper is InteractiveNotificationReceiver {

    IWithdrawable public immutable wrapper;
    constructor(IWithdrawable _wrapper) {
        wrapper = _wrapper;
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function fillOrderPostInteraction(
        bytes32, /* orderHash */
        address, /* maker */
        address, /* taker */
        uint256, /* makingAmount */
        uint256 takingAmount,
        uint256, /* remainingAmount */
        bytes calldata interactiveData
    ) external override {
        address payable makerAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            makerAddress := shr(96, calldataload(interactiveData.offset))
        }
        IWithdrawable(wrapper).withdraw(takingAmount);
        makerAddress.transfer(takingAmount);
    }
}