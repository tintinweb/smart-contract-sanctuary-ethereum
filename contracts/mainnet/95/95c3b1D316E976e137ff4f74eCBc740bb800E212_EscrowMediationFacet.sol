// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

interface IEscrow {
    function resolveDispute(bytes calldata _signature, uint8 _buyerPercent) external;
}

contract EscrowMediationFacet {

    function resolveDispute(
        address escrowAddr,
        bytes calldata _signature,
        uint8 _buyerPercent
    )
        external
    {
        IEscrow escrow = IEscrow(escrowAddr);
        escrow.resolveDispute(_signature, _buyerPercent);
    }
}