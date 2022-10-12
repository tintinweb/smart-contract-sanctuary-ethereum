// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "./interfaces/ICollection.sol";

/*
██████╗ ██╗   ██╗██████╗  ██████╗  █████╗ ████████╗ ██████╗ ██████╗ ██╗   ██╗
██╔══██╗██║   ██║██╔══██╗██╔════╝ ██╔══██╗╚══██╔══╝██╔═══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║   ██║██████╔╝██║  ███╗███████║   ██║   ██║   ██║██████╔╝ ╚████╔╝ 
██╔═══╝ ██║   ██║██╔══██╗██║   ██║██╔══██║   ██║   ██║   ██║██╔══██╗  ╚██╔╝  
██║     ╚██████╔╝██║  ██║╚██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║   ██║   
╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   

Purgatory is designed to be an ERC721/ERC1155 security module to help protect NFT holders against
common threats in the ecosystem. The most common attack vectors utilize "setApprovalForAll"
to trick users into giving approval to their high valued assets which are then immediately
transferred out after approval. Additionally, a common threat vector is to trick a user into
transferring out an NFT via safeTransferFrom, or is done from a private key compromise.

Purgatory aims to solve this problem for the vast majority of use cases by introducing a
"purgatory" time period where approvals and manual transfers cannot be done without approval.
It is important to note that in order to reduce friction and maintain compatibility with common
NFT use cases, transfers utilizing approvals are not blocked vial the manual transfer flow as long
as the approval has been successfully approved.

--Token approvals--
When a token approval is done, the approval enters the purgatory state where token transfers
utilitizing that approval are blocked. The requestor can choose one of a few options:
1. Wait the required purgatory time period. Once done, the approval is validated and transfers using that approval can begin.
2. Realize that the approval was malicious and not intended, and revoke the approval while still in the purgatory period.
3. Use another wallet as a "second factor" to approve the approval request at any time within the purgatory period to "send the request to heaven" 
AKA approve it and bypass the purgatory wait period. Multiple additional wallets can be added as approval request approvers and must each individually 
wait the purgatory wait period before their addition as approvers goes into effect.
4. Use another wallet as a "second factor" to deny the approval request (send it to hell) in the case of the original requestor wallet is not readily 
availalbe. In this case, the approval time is set to the max uint256 number indicating that it will never pass the purgatory time. This is done as the 
additional wallet does not have permission to revoke approvals for the original requestor.

--Manual transfers--
When a token holder wishes to transfer a token manually, they must first set an approved transfer recipient.
This request goes through the same purgatory time period as above and transfers to this recipient are blocked until
that is the case. Similar to above, the requestor can choose to:
1. Wait the required purgatory time period. Once done, the transfer request is validated and transfers to that recipient can begin.
2. Realize that the transfer was malicious and not intended, and revoke the transfer request while still in the purgatory period.
3. Use another wallet as a "second factor" to approve the transfer request at any time within the purgatory period to "send the request to heaven" 
AKA approve it and bypass the purgatory wait period.
4. Use another wallet as a "second factor" to deny the transfer request (send it to hell) in the case of the original requestor wallet is not readily 
availalbe. In this case, the transfer time is set to the max uint256 number indicating that it will never pass the purgatory time. This is done as the 
additional wallet does not have permission to revoke approvals for the original requestor.

Users can also choose to opt out of the purgatory system and the system is opt-in by default. Similarly
to other features, opting out must also go through the purgatory period before it is validated in order
to prevent abuse cases/bypasses.
*/
contract Purgatory {
    constructor (uint256 purgatoryTimeInSeconds_) {
        require (purgatoryTimeInSeconds_ >= MINIMUM_PURGATORY_TIME, "Purgatory time is too short");
        purgatoryTimeInSeconds = purgatoryTimeInSeconds_;
    }

    event ApproverSet(address owner, address approver);
    event ApproverRevoked(address owner, address approver);
    event NewApprovalRequest(address collection, address holder, address operator);
    event NewTransferRequest(address collection, address holder, address recipient);
    event ApprovalSentToHeaven(address collection, address owner, address approver, address operator);
    event ApprovalSentToHell(address collection, address owner, address approver, address operator, uint256 timeInHell);
    event TransferSentToHeaven(address collection, address owner, address approver, address recipient);
    event TransferSentToHell(address collection, address owner, address approver, address recipient, uint256 timeInHell);
    event OptStatusUpdate(address owner, bool optedOut);
    event CollectionEnrollUpdate(address collection, bool enrolled);

    uint256 public purgatoryTimeInSeconds;
    uint256 constant MINIMUM_PURGATORY_TIME = 10 minutes;
    // Maximum uint256 value
    uint256 constant TIME_IN_HELL = 2**256 - 1;

    // collection address => (holder address => (operator address => block.timestamp))
    mapping (address => mapping (address => mapping (address => uint256))) public approvals;

    // collection address => (holder address => (recipient address => block.timestamp))
    mapping (address => mapping (address => mapping (address => uint256))) public transferApprovals;

    // holder address => (second wallet address => block.timestamp)
    mapping (address => mapping (address => uint256)) public otherWalletApprovals;

    // holder address => block.timestamp
    // tracks whether a user has chosen to opt out of the purgatory period protection
    mapping (address => bool) public optedOut;

    // holder address => block.timestamp
    // optedOutTime of 0 indicates the user is opted in
    mapping (address => uint256) public optedOutLedger;

    mapping (address => bool) public enrolledCollections;

    function setOtherWalletApprover(address approver) public {
        otherWalletApprovals[msg.sender][approver] = block.timestamp;
        emit ApproverSet(msg.sender, approver);
    }

    function revokeOtherWalletApprover(address approver) public {
        delete otherWalletApprovals[msg.sender][approver];
        emit ApproverRevoked(msg.sender, approver);
    }

    function sendApprovalToHeaven(address requestor, address operator, address collection) external {
        require(otherWalletApprovals[requestor][msg.sender] != 0, "Invalid approval time - unauthorized");
        require(_isPurgatoryTimeCompleted(otherWalletApprovals[requestor][msg.sender]), "Cannot approve during purgatory time");
        require(approvals[collection][requestor][operator] != 0, "No request found");
        approvals[collection][requestor][operator] = block.timestamp - (purgatoryTimeInSeconds + 1);

        emit ApprovalSentToHeaven(collection, requestor, msg.sender, operator);
    }

    function sendApprovalToHell(address requestor, address operator, address collection) external {
        require(otherWalletApprovals[requestor][msg.sender] != 0, "Invalid approval time - unauthorized");
        require(_isPurgatoryTimeCompleted(otherWalletApprovals[requestor][msg.sender]), "Cannot approve during purgatory time");
        require(approvals[collection][requestor][operator] != 0, "No request found");
        // Banish to hell for the max uint256 value. Can be reset by revoking the approval and re-approving
        approvals[collection][requestor][operator] = TIME_IN_HELL;

        emit ApprovalSentToHell(collection, requestor, msg.sender, operator, TIME_IN_HELL);
    }

    function sendTransferToHeaven(address requestor, address recipient, address collection) external {
        require(otherWalletApprovals[requestor][msg.sender] != 0, "Invalid approval time - unauthorized");
        require(_isPurgatoryTimeCompleted(otherWalletApprovals[requestor][msg.sender]), "Cannot approve during purgatory time");
        require(transferApprovals[collection][requestor][recipient] != 0, "No request found");
        transferApprovals[collection][requestor][recipient] = block.timestamp - (purgatoryTimeInSeconds + 1);

        emit TransferSentToHeaven(collection, requestor, msg.sender, recipient);
    }

    function sendTransferToHell(address requestor, address recipient, address collection) external {
        require(otherWalletApprovals[requestor][msg.sender] != 0, "Invalid approval time - unauthorized");
        require(_isPurgatoryTimeCompleted(otherWalletApprovals[requestor][msg.sender]), "Cannot approve during purgatory time");
        require(transferApprovals[collection][requestor][recipient] != 0, "No request found");
        // Banish to hell for the max uint256 value. Can be reset by revoking the approval and re-approving
        transferApprovals[collection][requestor][recipient] = TIME_IN_HELL;

        emit TransferSentToHell(collection, requestor, msg.sender, recipient, TIME_IN_HELL);
    }

    function toggleOptOutIn() public {
        optedOut[msg.sender] = !optedOut[msg.sender];
        optedOutLedger[msg.sender] = block.timestamp;

        emit OptStatusUpdate(msg.sender, optedOut[msg.sender]);
    }

    function verifyTransfer(address from, address operator, address recipient) public view {
        // msg.sender in this case is the collection
        require(enrolledCollections[msg.sender], "Collection not enrolled");

        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from)) {
            return;
        }

        // If the operator is also the from (indicating owner is transferring), require valid recipient
        // in transferApprovals. If not, the require valid operator approval in approvals
        require(
            (
                from == address(0) ||
                (operator == from && _isPurgatoryTimeCompleted(transferApprovals[msg.sender][from][recipient])) ||
                _isPurgatoryTimeCompleted(approvals[msg.sender][from][operator])
            ),
            "Cannot transfer during purgatory time"
        );
    }

    function processApproval(address holder, address operator, bool approved) public {
        // msg.sender in this case is the collection
        require(enrolledCollections[msg.sender], "Collection not enrolled");

        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(holder)) {
            return;
        }

        if (!approved) {
            delete approvals[msg.sender][holder][operator];
        } else {
            require(approvals[msg.sender][holder][operator] == 0, "Approval already set");
            approvals[msg.sender][holder][operator] = block.timestamp;
            emit NewApprovalRequest(msg.sender, holder, operator);
        }
    }

    function isApproved(address from, address operator) public view returns (bool) {
        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from)) {
            return true;
        }

        // msg.sender in this case is the collection
        return _isPurgatoryTimeCompleted(approvals[msg.sender][from][operator]);
    }

    // Alternative isApproved method to be called outside of a specific collection context
    // to view approval status
    function isApproved(address from, address operator, address collection) external view returns (bool) {
        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from)) {
            return true;
        }

        // msg.sender in this case is the collection
        return _isPurgatoryTimeCompleted(approvals[collection][from][operator]);
    }

    function setApprovedTransfer(address collection, address recipient) public {
        transferApprovals[collection][msg.sender][recipient] = block.timestamp;
        emit NewTransferRequest(collection, msg.sender, recipient);
    }

    function toggleCollectionEnroll(address collectionAddress) public {
        ICollection collection = ICollection(collectionAddress);
        require(msg.sender == collection.owner(), "Must be contract owner");

        enrolledCollections[collectionAddress] = !enrolledCollections[collectionAddress];
    }

    function _isOptedOut(address from) internal view returns (bool) {
        // If optedOutLedger returns 0, the user is opted in as default opt-in
        if (optedOutLedger[from] == 0) {
            return false;
        }

        return optedOut[from] && _isPurgatoryTimeCompleted(optedOutLedger[from]);
    }

    function _isPurgatoryTimeCompleted(uint256 approvedTime) internal view returns (bool) {
        // If there is no approvedTime, that means there is no record indicating no
        // purgatory time has been completed. If approvedTime is greater than block.timestamp,
        // that indicates the request has been denied and is not approved
        if (approvedTime == 0 || approvedTime > block.timestamp) {
            return false;
        }
        return block.timestamp - approvedTime >= purgatoryTimeInSeconds;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICollection {
    function owner() external view returns (address);
}