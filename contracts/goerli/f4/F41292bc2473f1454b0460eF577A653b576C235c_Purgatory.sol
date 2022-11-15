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

Purgatory is designed to be an ERC721/ERC1155 security service to help protect NFT holders against
common threats in the ecosystem. The most common attack vectors utilize techniques such as "setApprovalForAll"
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
3. Use another wallet as a "second factor" to approve the approval request at any time within the purgatory period to bypass the purgatory wait period 
AKA approve it and bypass the purgatory wait period. Multiple additional wallets can be added as approval request approvers and must each individually 
wait the purgatory wait period before their addition as approvers goes into effect.
4. Use another wallet as a "second factor" to deny the approval request in the case of the original requestor wallet is not readily 
availalbe.

--Manual transfers--
When a token holder wishes to transfer a token manually, they must first set an approved transfer recipient.
This request goes through the same purgatory time period as above and transfers to this recipient are blocked until
that is the case. Similar to above, the requestor can choose to:
1. Wait the required purgatory time period. Once done, the transfer request is validated and transfers to that recipient can begin.
2. Realize that the transfer was malicious and not intended, and revoke the transfer request while still in the purgatory period.
3. Use another wallet as a "second factor" to approve the transfer request at any time within the purgatory period bypass the purgatory wait period.
4. Use another wallet as a "second factor" to deny the transfer request in the case of the original requestor wallet is not readily 
availalbe.

Users can also choose to opt out of the purgatory system and the system is opt-in by default. Similarly
to other features, opting out must also go through the purgatory period before it is validated in order
to prevent abuse cases/bypasses.
*/
contract Purgatory {
    constructor () {
        deployer = msg.sender;
    }

    error AlreadyApproved();
    error ApprovalAlreadySetToSameStatus();
    error IsNotAuthorized();
    error RequestNotFound();
    error LockDownModeEnabled();
    error AdminFunctionsPermanentlyDisabled();
    error CannotTransferDuringPurgatoryTime();

    event NewTransferRecipientSet(address collection, address holder, address recipient, bool approved);
    event NewGlobalTransferRecipientRequest(address holder, address recipient, bool approved);
    event NewOperatorApprovalRequest(address collection, address holder, address operator, bool approved);
    event OtherWalletApproverSet(address owner, address approver, bool approved);
    event OperatorApprovalSet(address collection, address owner, address approver, address operator, bool approved);
    event TransferRecipientApprovalSet(address collection, address owner, address approver, address recipient, bool approved);
    event GlobalTransferRecipientApprovalSet(address owner, address approver, address recipient, bool approved);
    event OptStatusSet(address owner, bool optedOut);
    event LockDownStatusSet(address owner, bool lockDownActive);
    event CollectionEnrollmentSet(address collection, bool enrolled);

    bool public emergencyShutdownActive;
    bool public adminFunctionPermanentlyDisabled;

    uint256 constant public PURGATORY_TIME = 5 minutes;
    address immutable deployer;

    struct Approval {
        bool approved;
        uint128 lastUpdated;
    }

    struct OptStatus {
        bool optedOut;
        bool lockDownActive;
        uint64 optStatusLastUpdated;
        uint64 lockDownLastUpdated;
    }

    // operator approval status for setApprovalForAll/approve
    // collection address => (holder address => (operator address => (approvedStatus, block.timestamp of last update)))
    mapping (address => mapping (address => mapping (address => Approval))) public approvals;

    // transfer recipient approval status for safeTransferFrom transfers
    // collection address => (holder address => (recipient address => (approvedStatus, block.timestamp of last update)))
    mapping (address => mapping (address => mapping (address => Approval))) public approvedRecipients;

    // global transfer recipient approvals for all collections for a given holder
    // holder address => (recipient address => block.timestamp of last update, block.timestamp of last update)
    mapping (address => mapping (address => Approval)) public globalApprovedRecipients;

    // other wallet approvals AKA second factor authentication
    // holder address => (other wallet address => (approvedStatus, block.timestamp of last update))
    mapping (address => mapping (address => Approval)) public otherWalletApprovals;

    // tracks whether a user has chosen to opt out of the purgatory period protection
    // holder address => (optedOutStatus, block.timestamp of last update)
    // optedOutTime of 0 indicates the user is opted in as opt-in is default
    mapping (address => OptStatus) public optedOut;

    // while enrolling is free, the collection must be enrolled by the contract owner
    // (owner() method must be implemented)
    mapping (address => bool) public enrolledCollections;

    /*
    Approval request setters
    **/

    // TODO Re-review this function for potential griefing issues with approve + unapprove requests to bypass
    // recently unapproved allowances support
    function setOtherWalletApprover(address approver, bool approved) public {
        Approval memory currentApproval = otherWalletApprovals[msg.sender][approver];
        if (currentApproval.approved == approved) {
            revert ApprovalAlreadySetToSameStatus();
        }

        // If the below condition is not met, that means time should be set to 0 in order to allow
        // and protect against a case where we want to allow recently unapproved recipients still
        // within purgatory time to pass
        uint128 time = 0;
        if ((_isPurgatoryTimeCompleted(currentApproval.lastUpdated) && currentApproval.approved) || currentApproval.lastUpdated == 0) {
            time = uint128(block.timestamp);
        }

        otherWalletApprovals[msg.sender][approver] = Approval(approved, time);
        emit OtherWalletApproverSet(msg.sender, approver, approved);
    }

    // TODO Re-review this function for potential griefing issues with approve + unapprove requests to bypass
    // recently unapproved allowances support
    function setApprovedRecipient(address collection, address recipient, bool approved) public {
        Approval memory currentApproval = approvedRecipients[collection][msg.sender][recipient];
        if (currentApproval.approved == approved) {
            revert ApprovalAlreadySetToSameStatus();
        }
        // If the below condition is not met, that means time should be set to 0 in order to allow
        // and protect against a case where we want to allow recently unapproved recipients still
        // within purgatory time to pass
        uint128 time = 0;
        if ((_isPurgatoryTimeCompleted(currentApproval.lastUpdated) && currentApproval.approved) || currentApproval.lastUpdated == 0) {
            time = uint128(block.timestamp);
        }

        approvedRecipients[collection][msg.sender][recipient] = Approval(approved, time);

        emit NewTransferRecipientSet(collection, msg.sender, recipient, approved);
    }

    // TODO Re-review this function for potential griefing issues with approve + unapprove requests to bypass
    // recently unapproved allowances support
    function setGlobalApprovedRecipient(address recipient, bool approved) public {
        Approval memory currentApproval = globalApprovedRecipients[msg.sender][recipient];
        if (currentApproval.approved == approved) {
            revert ApprovalAlreadySetToSameStatus();
        }
        // If the below condition is not met, that means time should be set to 0 in order to allow
        // and protect against a case where we want to allow recently unapproved recipients still
        // within purgatory time to pass
        uint128 time = 0;
        if ((_isPurgatoryTimeCompleted(currentApproval.lastUpdated) && currentApproval.approved) || currentApproval.lastUpdated == 0) {
            time = uint128(block.timestamp);
        }

        globalApprovedRecipients[msg.sender][recipient] = Approval(approved, time);

        emit NewGlobalTransferRecipientRequest(msg.sender, recipient, approved);
    }

    function toggleOptOutIn() public {
        OptStatus memory optStatus = optedOut[msg.sender];
        optedOut[msg.sender].optedOut = !optStatus.optedOut;
        optedOut[msg.sender].optStatusLastUpdated = uint64(block.timestamp);

        emit OptStatusSet(msg.sender, optedOut[msg.sender].optedOut);
    }

    function toggleLockDownMode() public {
        OptStatus memory optStatus = optedOut[msg.sender];
        optedOut[msg.sender].lockDownActive = !optStatus.lockDownActive;

        uint64 time = 0;
        if ((_isPurgatoryTimeCompleted(optStatus.lockDownLastUpdated) && optStatus.lockDownActive) || optStatus.lockDownLastUpdated == 0) {
            time = uint64(block.timestamp);
        }

        optedOut[msg.sender].lockDownLastUpdated = time;


        emit LockDownStatusSet(msg.sender, optedOut[msg.sender].lockDownActive);
    }

    function toggleCollectionEnroll(address collectionAddress) public {
        ICollection collection = ICollection(collectionAddress);
        if (msg.sender != collection.owner()) {
            revert IsNotAuthorized();
        }

        enrolledCollections[collectionAddress] = !enrolledCollections[collectionAddress];
        emit CollectionEnrollmentSet(collectionAddress, enrolledCollections[collectionAddress]);
    }

    /*
    Other Wallet Approval setters
    **/

    function setApprovalForOperatorApproval(address holder, address operator, address collection, bool approved) external {
        if (!_isOtherWalletApproved(holder, msg.sender)) {
            revert IsNotAuthorized();
        }

        Approval memory currentApproval = approvals[collection][holder][operator];
        if (currentApproval.lastUpdated == 0) {
            revert RequestNotFound();
        }

        // If the approval status is the same and purgatory time is complete, don't process as approval is complete
        if (currentApproval.approved == approved && _isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            revert ApprovalAlreadySetToSameStatus();
        }

        // TODO: Look into deleting the record if not approved
        uint128 time;
        if (approved) {
            time = uint128(block.timestamp - (PURGATORY_TIME + 1));
        } else {
            time = uint128(block.timestamp);
        }

        approvals[collection][holder][operator] = Approval(approved, time);

        emit OperatorApprovalSet(collection, holder, msg.sender, operator, approved);
    }

    function setApprovalForTransferRecipient(address holder, address recipient, address collection, bool approved) external {
        if (!_isOtherWalletApproved(holder, msg.sender)) {
            revert IsNotAuthorized();
        }

        Approval memory currentApproval = approvedRecipients[collection][holder][recipient];
        if (currentApproval.lastUpdated == 0) {
            revert RequestNotFound();
        }

        // If the approval status is the same and purgatory time is complete, don't process as approval is complete
        if (currentApproval.approved == approved && _isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            revert ApprovalAlreadySetToSameStatus();
        }

        // TODO: Look into deleting the record if not approved
        uint128 time;
        if (approved) {
            time = uint128(block.timestamp - (PURGATORY_TIME + 1));
        } else {
            time = uint128(block.timestamp);
        }

        approvedRecipients[collection][holder][recipient] = Approval(approved, time);

        emit TransferRecipientApprovalSet(collection, holder, msg.sender, recipient, approved);
    }

    function setApprovalForGlobalTransferRecipient(address holder, address recipient, bool approved) external {
        if (!_isOtherWalletApproved(holder, msg.sender)) {
            revert IsNotAuthorized();
        }

        Approval memory currentApproval = globalApprovedRecipients[holder][recipient];
        if (currentApproval.lastUpdated == 0) {
            revert RequestNotFound();
        }

        // If the approval status is the same and purgatory time is complete, don't process as approval is complete
        if (currentApproval.approved == approved && _isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            revert ApprovalAlreadySetToSameStatus();
        }

        // TODO: Look into deleting the record if not approved
        uint128 time;
        if (approved) {
            time = uint128(block.timestamp - (PURGATORY_TIME + 1));
        } else {
            time = uint128(block.timestamp);
        }

        globalApprovedRecipients[holder][recipient] = Approval(approved, time);

        emit GlobalTransferRecipientApprovalSet(holder, msg.sender, recipient, approved);
    }

    // TODO: Look into adding quick deactivation approval for lock down mode to bypass Purgatory time

    /*
    ERC721/1155 integrated functions
    **/

    function validateTransfer(address from, address operator, address recipient) public view {
        if (emergencyShutdownActive) return;

        // msg.sender in this case is the collection
        // If the collection is not enrolled, skip transfer validation
        if (!enrolledCollections[msg.sender]) return;

        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from)) {
            return;
        }

        // TODO: Combine _isOptedOut and _isLockedDown read mapping calls to save gas
        // Allow mints while lockdown is enabled
        if (_isLockedDown(from) && from != address(0)) {
            revert LockDownModeEnabled();
        }

        // If the operator is also the from (indicating owner is transferring), require valid recipient
        // in approvedRecipients or globalApprovedRecipients. If not, the require valid operator approval in approvals
        require(
            (
                from == address(0) ||
                (operator == from && _isTransferRecipientApproved(from, recipient)) ||
                _isOperatorApprovalApproved(msg.sender, from, operator)
            ),
            "Cannot transfer during purgatory time"
        );

        // if (
        //     (from != address(0)) &&
        //     (operator == from && !_isTransferRecipientApproved(from, recipient)) &&
        //     !_isOperatorApprovalApproved(msg.sender, from, operator)
        // ) {
        //     revert CannotTransferDuringPurgatoryTime();
        // }
    }

    function validateApproval(address from, address operator, bool approved) public {
        if (emergencyShutdownActive) return;

        // msg.sender in this case is the collection
        // If the collection is not enrolled, skip approval validation
        if (!enrolledCollections[msg.sender]) return;

        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from)) {
            return;
        }

        // TODO: Combine _isOptedOut and _isLockedDown read mapping calls to save gas
        if (_isLockedDown(from)) {
            revert LockDownModeEnabled();
        }

        if (!approved) {
            delete approvals[msg.sender][from][operator];
        } else {
            if (!approvals[msg.sender][from][operator].approved) {
                approvals[msg.sender][from][operator] = Approval(true, uint128(block.timestamp));
            } else {
                revert AlreadyApproved();
            }
        }

        emit NewOperatorApprovalRequest(msg.sender, from, operator, approved);
    }

    function isApproved(address from, address operator) public view returns (bool) {
        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from) || emergencyShutdownActive) {
            return true;
        }

        // If locked down, do not show the approval as valid to avoid griefing issues
        // on marketplace listings
        // TODO: Combine _isOptedOut and _isLockedDown read mapping calls to save gas
        if (_isLockedDown(from)) {
            return false;
        }

        // msg.sender in this case is the collection
        return _isOperatorApprovalApproved(msg.sender, from, operator);
    }

    // Alternative isApproved method to be called outside of a specific collection context
    // to view approval status
    function isApproved(address from, address operator, address collection) external view returns (bool) {
        // Skip processing if user is opted out and has passed the purgatory period for the opt out
        if (_isOptedOut(from) || emergencyShutdownActive) {
            return true;
        }

        // If locked down, do not show the approval as valid to avoid griefing issues
        // on marketplace listings
        if (_isLockedDown(from)) {
            return false;
        }

        return _isOperatorApprovalApproved(collection, from, operator);
    }

    /*
    Internal functions
    **/

    function _isOptedOut(address from) internal view returns (bool) {
        OptStatus memory optStatus = optedOut[from];
        // If optStatusLastUpdated returns 0, the user is opted in as default option is opt-in
        if (optStatus.optStatusLastUpdated == 0) {
            return false;
        }

        return optStatus.optedOut && _isPurgatoryTimeCompleted(optStatus.optStatusLastUpdated);
    }

    function _isLockedDown(address from) internal view returns (bool) {
        OptStatus memory optStatus = optedOut[from];
        // If lockDownLastUpdated returns 0, the user is opted out as default option is opt-out
        if (optStatus.lockDownLastUpdated == 0) {
            return false;
        }

        // if lockDown is not set and the purgatory is not complete (but last updated is NOT 0)
        // then the status was recently revoked but has not completed the purgatory time.
        // In order to prevent abuse of deactivating lock down mode via a compromised wallet
        // or phished transaction, we should ensure even deactivations go through purgatory time
        if (!optStatus.lockDownActive && !_isPurgatoryTimeCompleted(optStatus.lockDownLastUpdated)) {
            return true;
        }

        // Do not require activating lockdown mode to go through Purgatory time
        // TODO: Review if any issues can come from bypassing Purgatory time
        return optStatus.lockDownActive;
    }

    function _isPurgatoryTimeCompleted(uint256 approvedTime) internal view returns (bool) {
        // If there is no approvedTime, that means there is no record indicating no
        // purgatory time has been completed. If approvedTime is greater than block.timestamp,
        // that indicates the request has been denied and is not approved
        if (approvedTime == 0 || approvedTime > uint128(block.timestamp)) {
            return false;
        }

        return block.timestamp - approvedTime >= PURGATORY_TIME;
    }

    function _isTransferRecipientApproved(address holder, address recipient) internal view returns (bool) {
        Approval memory collectionApprovalStatus = approvedRecipients[msg.sender][holder][recipient];
        Approval memory globalApprovalStatus = globalApprovedRecipients[holder][recipient];

        if (collectionApprovalStatus.lastUpdated == 0 && globalApprovalStatus.lastUpdated == 0) {
            return false;
        }

        if (
            (collectionApprovalStatus.approved && _isPurgatoryTimeCompleted(collectionApprovalStatus.lastUpdated)) || 
            (globalApprovalStatus.approved && _isPurgatoryTimeCompleted(globalApprovalStatus.lastUpdated))
        ) {
            return true;
        }

        // if the approval is not set and the purgatory is not complete (but ledger is NOT 0)
        // then the approval was recently revoked but has not completed the purgatory time.
        // In order to prevent abuse of revoking secondary approvers via a compromised wallet
        // or phished transaction, we should ensure even revokals go through purgatory time
        if (
            (!collectionApprovalStatus.approved && !_isPurgatoryTimeCompleted(collectionApprovalStatus.lastUpdated)) && 
            (!globalApprovalStatus.approved && !_isPurgatoryTimeCompleted(globalApprovalStatus.lastUpdated))
        ) {
            return true;
        }

        return false;
    }

    function _isOperatorApprovalApproved(address collection, address holder, address operator) internal view returns (bool) {
        Approval memory currentApproval = approvals[collection][holder][operator];

        // TODO: Possible issue with double revokals. might not be an issue, needs double check
        if (currentApproval.lastUpdated == 0) {
            return false;
        }

        if (currentApproval.approved && _isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            return true;
        }

        return false;
    }

    function _isOtherWalletApproved(address holder, address approver) internal view returns (bool) {
        Approval memory currentApproval = otherWalletApprovals[holder][approver];

        if (currentApproval.lastUpdated == 0) {
            return false;
        }

        if (currentApproval.approved && _isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            return true;
        }

        // if the approval is not set and the purgatory is not complete (but lastUpdated is NOT 0)
        // then the approval was recently revoked but has not completed the purgatory time.
        // In order to prevent abuse of revoking secondary approvers via a compromised wallet
        // or phished transaction, we should ensure even revokals go through purgatory time
        if (!currentApproval.approved && !_isPurgatoryTimeCompleted(currentApproval.lastUpdated)) {
            return true;
        }

        return false;
    }

    /*
    Temporary Admin Function
    **/

    // A single admin function to pause/shutdown the Purgatory system has been added
    // in the case a breaking bug arises and the system needs to be shutdown in order
    // to prevent projects leveraging this system also having breaking issues. If after
    // a period of time using the system there are no issues identified, this admin
    // function will be permanently disabled via disableAdminFunctionPermanently
    function toggleEmergencyShutdown() public {
        if (deployer != msg.sender) {
            revert IsNotAuthorized();
        }

        if (adminFunctionPermanentlyDisabled) {
            revert AdminFunctionsPermanentlyDisabled();
        }

        emergencyShutdownActive = !emergencyShutdownActive;
    }

    function disableAdminFunctionPermanently() public {
        if (deployer != msg.sender) {
            revert IsNotAuthorized();
        }
        adminFunctionPermanentlyDisabled = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface ICollection {
    function owner() external view returns (address);
}