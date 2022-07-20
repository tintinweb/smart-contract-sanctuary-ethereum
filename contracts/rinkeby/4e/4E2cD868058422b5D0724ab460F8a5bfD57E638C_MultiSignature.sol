// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

contract MultiSignature {
    address[] public signers;
    uint256 public immutable i_quorum;

    constructor(address[] memory _signers, uint256 quorum) payable {
        signers = _signers;
        i_quorum = quorum;
    }

    uint256 id;
    struct Transfer {
        uint256 id;
        uint256 amount;
        address payable to;
        uint256 approvals;
        bool isSent;
    }

    Transfer[] public transfers;
    mapping(address => mapping(uint256 => bool)) approvedTransfer;

    function createTransfer(uint256 amount, address payable to)
        external
        onlySigner
    {
        transfers.push(Transfer(id, amount, to, 0, false));
        id++;
    }

    function sendTransfer(uint256 transferId) external onlySigner {
        Transfer memory transfer = transfers[transferId];

        require(transfer.isSent == false, "Already Sent");
        require(
            transfer.amount <= address(this).balance,
            "The contract doesnt have enough balance"
        );
        if (transfer.approvals >= i_quorum) {
            transfer.to.transfer(transfer.amount);
            transfers[transferId].isSent = true;
            return;
        }
        require(
            approvedTransfer[msg.sender][transferId] == false,
            "Already Approved"
        );
        transfers[transferId].approvals++;
        approvedTransfer[msg.sender][transferId] = true;
    }

    modifier onlySigner() {
        bool isSigner = false;
        for (uint256 i = 0; i < signers.length; i++) {
            if (signers[i] == msg.sender) {
                isSigner = true;
            }
        }

        require(isSigner, "Only Signer allowed");
        _;
    }
}