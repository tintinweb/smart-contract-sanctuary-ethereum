// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/Pausable.sol";
import "./AccessControl.sol";
import "../interfaces/IERCHandler.sol";
import "../interfaces/IDepositExecute.sol";
import "../interfaces/IRollupSender.sol";
import "../interfaces/IRollupReceiver.sol";
import "../interfaces/IRollupHandler.sol";

/// @notice This contract facilitates the following:
/// - deposits
/// - creation and voting of deposit proposals
/// - deposit executions
/// - rollup executions and state settlements

library SafeCast {
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value < 2**200, "value does not fit in 200 bits");
        return uint200(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value < 2**128, "value does not fit in 128 bits");
        return uint128(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value < 2**40, "value does not fit in 40 bits");
        return uint40(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value < 2**8, "value does not fit in 8 bits");
        return uint8(value);
    }
}

contract Bridge is Pausable, AccessControl, IRollupSender {
    using SafeCast for *;

    /// @notice Limit relayers number because proposal can fit only so much votes
    uint256 public constant MAX_RELAYERS = 200;

    uint8 public immutable _domainID;
    uint8 public _relayerThreshold;
    uint128 public _fee;
    uint40 public _expiry;

    enum ProposalStatus {
        Inactive,
        Active,
        Passed,
        Executed,
        Cancelled
    }

    struct Proposal {
        ProposalStatus _status;
        uint200 _yesVotes; // bitmap, 200 maximum votes
        uint8 _yesVotesTotal;
        uint40 _proposedBlock; // 1099511627775 maximum block
    }

    // destinationDomainID => number of deposits
    mapping(uint8 => uint64) public _depositCounts;
    // resourceID => handler address
    mapping(bytes32 => address) public _resourceIDToHandlerAddress;
    // destinationDomainID + depositNonce => dataHash => Proposal
    mapping(uint72 => mapping(bytes32 => Proposal)) private _proposals;

    event RelayerThresholdChanged(uint256 newThreshold);
    event RelayerAdded(address relayer);
    event RelayerRemoved(address relayer);
    event Deposit(
        uint8 destinationDomainID,
        bytes32 resourceID,
        uint64 depositNonce,
        address indexed user,
        bytes data,
        bytes handlerResponse
    );
    event ProposalEvent(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event ProposalVote(
        uint8 originDomainID,
        uint64 depositNonce,
        ProposalStatus status,
        bytes32 dataHash
    );
    event FailedHandlerExecution(bytes lowLevelData);
    event ExecuteRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        bytes32 destResourceID,
        uint64 nonce,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    );
    event SettleStateChanges(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        uint64 batchIndex,
        uint64 totalBatches
    );

    bytes32 public constant RELAYER_ROLE = keccak256("RELAYER_ROLE");

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyAdminOrRelayer() {
        _onlyAdminOrRelayer();
        _;
    }

    modifier onlyRelayers() {
        _onlyRelayers();
        _;
    }

    /// @notice Initializes Bridge, creates and grants {msg.sender} the admin role,
    /// creates and grants {initialRelayers} the relayer role.
    ///
    /// @param domainID ID of chain the Bridge contract exists on.
    /// @param initialRelayers Addresses that should be initially granted the relayer role.
    /// @param initialRelayerThreshold Number of votes needed for a deposit proposal to be considered passed.
    constructor(
        uint8 domainID,
        address[] memory initialRelayers,
        uint256 initialRelayerThreshold,
        uint256 fee,
        uint256 expiry
    ) {
        _domainID = domainID;
        _relayerThreshold = initialRelayerThreshold.toUint8();
        _fee = fee.toUint128();
        _expiry = expiry.toUint40();

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);

        for (uint256 i = 0; i < initialRelayers.length; i++) {
            grantRole(RELAYER_ROLE, initialRelayers[i]);
        }
    }

    /// @notice Removes admin role from {msg.sender} and grants it to {newAdmin}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param newAdmin Address that admin role will be granted to.
    function renounceAdmin(address newAdmin) external onlyAdmin {
        require(msg.sender != newAdmin, "Cannot renounce oneself");
        grantRole(DEFAULT_ADMIN_ROLE, newAdmin);
        renounceRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Pauses deposits, proposal creation and voting, and deposit executions.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    function adminPauseTransfers() external onlyAdmin {
        _pause();
    }

    /// @notice Unpauses deposits, proposal creation and voting, and deposit executions.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    function adminUnpauseTransfers() external onlyAdmin {
        _unpause();
    }

    /// @notice Modifies the number of votes required for a proposal to be considered passed.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param newThreshold Value {_relayerThreshold} will be changed to.
    ///
    /// @notice Emits {RelayerThresholdChanged} event.
    function adminChangeRelayerThreshold(uint256 newThreshold)
        external
        onlyAdmin
    {
        _relayerThreshold = newThreshold.toUint8();
        emit RelayerThresholdChanged(newThreshold);
    }

    /// @notice Grants {relayerAddress} the relayer role.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {relayerAddress} must not already has relayer role.
    /// - The number of current relayer must be less than {MAX_RELAYERS}
    ///
    /// @param relayerAddress Address of relayer to be added.
    ///
    /// @notice Emits {RelayerAdded} event.
    ///
    /// @dev admin role is checked in grantRole()
    function adminAddRelayer(address relayerAddress) external {
        require(
            !hasRole(RELAYER_ROLE, relayerAddress),
            "addr already has relayer role!"
        );
        require(_totalRelayers() < MAX_RELAYERS, "relayers limit reached");
        grantRole(RELAYER_ROLE, relayerAddress);
        emit RelayerAdded(relayerAddress);
    }

    /// @notice Removes relayer role for {relayerAddress}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {relayerAddress} must has relayer role.
    ///
    /// @param relayerAddress Address of relayer to be removed.
    ///
    /// @notice Emits {RelayerRemoved} event.
    ///
    /// @dev admin role is checked in revokeRole()
    function adminRemoveRelayer(address relayerAddress) external {
        require(
            hasRole(RELAYER_ROLE, relayerAddress),
            "addr doesn't have relayer role!"
        );
        revokeRole(RELAYER_ROLE, relayerAddress);
        emit RelayerRemoved(relayerAddress);
    }

    /// @notice Sets a new resource for handler contracts that use the IERCHandler interface,
    /// and maps the {handlerAddress} to {resourceID} in {_resourceIDToHandlerAddress}.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler resource will be set for.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function adminSetResource(
        address handlerAddress,
        bytes32 resourceID,
        address tokenAddress
    ) external onlyAdmin {
        _resourceIDToHandlerAddress[resourceID] = handlerAddress;
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setResource(resourceID, tokenAddress);
    }

    /// @notice Sets a resource as burnable for handler contracts that use the IERCHandler interface.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler resource will be set for.
    /// @param tokenAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function adminSetBurnable(address handlerAddress, address tokenAddress)
        external
        onlyAdmin
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.setBurnable(tokenAddress);
    }

    /// @notice Sets the nonce for the specific domainID.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - {nonce} must be greater than the current nonce.
    ///
    /// @param domainID Domain ID for increasing nonce.
    /// @param nonce The nonce value to be set.
    function adminSetDepositNonce(uint8 domainID, uint64 nonce)
        external
        onlyAdmin
    {
        // solhint-disable-next-line reason-string
        require(
            nonce > _depositCounts[domainID],
            "Does not allow decrements of the nonce"
        );
        _depositCounts[domainID] = nonce;
    }

    /// @notice Changes deposit fee.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    /// - The current fee must not be equal to new fee.
    ///
    /// @param newFee Value {_fee} will be updated to.
    // slither-disable-next-line events-maths
    function adminChangeFee(uint256 newFee) external onlyAdmin {
        require(_fee != newFee, "Current fee is equal to new fee");
        _fee = newFee.toUint128();
    }

    /// @notice Used to manually withdraw funds from ERC safes.
    ///
    /// @notice Requirements:
    /// - It must be called by only admin.
    ///
    /// @param handlerAddress Address of handler to withdraw from.
    /// @param data ABI-encoded withdrawal params relevant to the specified handler.
    function adminWithdraw(address handlerAddress, bytes memory data)
        external
        onlyAdmin
    {
        IERCHandler handler = IERCHandler(handlerAddress);
        handler.withdraw(data);
    }

    /// @notice Initiates a transfer using a specified handler contract.
    ///
    /// @notice Requirements:
    /// - Bridge must be not be paused.
    /// - {msg.value} must be greater than or equal to {_fee}.
    /// - Handler must be registered with {resourceID}.
    ///
    /// @param destinationDomainID ID of chain deposit will be bridged to.
    /// @param resourceID ResourceID used to find address of handler to be used for deposit.
    /// @param data Additional data to be passed to specified handler.
    ///
    /// @notice Emits {Deposit} event with all necessary parameters and a handler response.
    /// - ERC20Handler: responds with an empty data.
    /// - ERC721Handler: responds with the deposited token metadata acquired by calling a tokenURI method in the token contract.
    /// - ERC1155Handler: responds with an empty data.
    /// - NativeTokenHandler: responds with an empty data.
    ///
    /// @dev RollupHandler doesn't support this function.
    function deposit(
        uint8 destinationDomainID,
        bytes32 resourceID,
        bytes calldata data
    ) external payable whenNotPaused {
        require(msg.value >= _fee, "Incorrect fee supplied");

        address handler = _resourceIDToHandlerAddress[resourceID];
        require(handler != address(0), "resourceID not mapped to handler");

        uint64 depositNonce = ++_depositCounts[destinationDomainID];

        IDepositExecute depositHandler = IDepositExecute(handler);
        bytes memory handlerResponse = depositHandler.deposit{
            value: msg.value - _fee
        }(resourceID, msg.sender, data);

        // slither-disable-next-line reentrancy-events
        emit Deposit(
            destinationDomainID,
            resourceID,
            depositNonce,
            msg.sender,
            data,
            handlerResponse
        );
    }

    /// @notice When called, {msg.sender} will be marked as voting in favor of proposal.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer.
    /// - Bridge must not be paused.
    /// - Handler must be registered with {resourceID}.
    /// - Proposal must not have already been passed or executed.
    /// - Relayer must vote only once.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param data Data originally provided when deposit was made.
    ///
    /// @notice Emits {ProposalEvent} event with status indicating the proposal status.
    /// @notice Emits {ProposalVote} event.
    function voteProposal(
        uint8 domainID,
        uint64 depositNonce,
        bytes32 resourceID,
        bytes calldata data
    ) external onlyRelayers whenNotPaused {
        address handler = _resourceIDToHandlerAddress[resourceID];
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
        bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
        Proposal memory proposal = _proposals[nonceAndID][dataHash];

        require(
            _resourceIDToHandlerAddress[resourceID] != address(0),
            "no handler for resourceID"
        );

        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(domainID, depositNonce, data, resourceID, true);
            return;
        }

        // Passed case is considered already
        // Now we can consider Inactive, Active cases
        // solhint-disable-next-line reason-string
        require(
            uint256(proposal._status) <= 1,
            "proposal already executed/cancelled"
        );
        require(!_hasVoted(proposal, msg.sender), "relayer already voted");

        if (proposal._status == ProposalStatus.Inactive) {
            proposal = Proposal({
                _status: ProposalStatus.Active,
                _yesVotes: 0,
                _yesVotesTotal: 0,
                _proposedBlock: uint40(block.number) // Overflow is desired.
            });

            emit ProposalEvent(
                domainID,
                resourceID,
                depositNonce,
                ProposalStatus.Active,
                dataHash
            );
        } else if (uint40(block.number - proposal._proposedBlock) > _expiry) {
            // if the number of blocks that has passed since this proposal was
            // submitted exceeds the expiry threshold set, cancel the proposal
            proposal._status = ProposalStatus.Cancelled;

            emit ProposalEvent(
                domainID,
                resourceID,
                depositNonce,
                ProposalStatus.Cancelled,
                dataHash
            );
        }

        if (proposal._status != ProposalStatus.Cancelled) {
            proposal._yesVotes = (proposal._yesVotes | _relayerBit(msg.sender))
                .toUint200();
            proposal._yesVotesTotal++; // TODO: check if bit counting is cheaper.

            emit ProposalVote(
                domainID,
                depositNonce,
                proposal._status,
                dataHash
            );

            // Finalize if _relayerThreshold has been reached
            if (proposal._yesVotesTotal >= _relayerThreshold) {
                proposal._status = ProposalStatus.Passed;
                emit ProposalEvent(
                    domainID,
                    resourceID,
                    depositNonce,
                    ProposalStatus.Passed,
                    dataHash
                );
            }
        }
        _proposals[nonceAndID][dataHash] = proposal;

        // slither-disable-next-line incorrect-equality
        if (proposal._status == ProposalStatus.Passed) {
            executeProposal(domainID, depositNonce, data, resourceID, false);
        }
    }

    /// @notice Cancels a deposit proposal that has not been executed yet.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer or admin.
    /// - Bridge must not be paused.
    /// - Proposal must be past expiry threshold.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param dataHash Hash of data originally provided when deposit was made.
    ///
    /// @notice Emits {ProposalEvent} event with status {Cancelled}.
    function cancelProposal(
        uint8 domainID,
        bytes32 resourceID,
        uint64 depositNonce,
        bytes32 dataHash
    ) external onlyAdminOrRelayer {
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
        Proposal memory proposal = _proposals[nonceAndID][dataHash];
        ProposalStatus currentStatus = proposal._status;

        require(
            currentStatus == ProposalStatus.Active ||
                currentStatus == ProposalStatus.Passed,
            "Proposal cannot be cancelled"
        );
        require(
            uint40(block.number - proposal._proposedBlock) > _expiry,
            "Proposal not at expiry threshold"
        );

        proposal._status = ProposalStatus.Cancelled;
        _proposals[nonceAndID][dataHash] = proposal;

        emit ProposalEvent(
            domainID,
            resourceID,
            depositNonce,
            ProposalStatus.Cancelled,
            dataHash
        );
    }

    /// @notice Transfers eth in the contract to the specified addresses. The parameters addrs and amounts are mapped 1-1.
    /// This means that the address at index 0 for addrs will receive the amount (in WEI) from amounts at index 0.
    ///
    /// @param addrs Array of addresses to transfer {amounts} to.
    /// @param amounts Array of amonuts to transfer to {addrs}.
    function transferFunds(
        address payable[] calldata addrs,
        uint256[] calldata amounts
    ) external onlyAdmin {
        require(
            addrs.length == amounts.length,
            "addrs[], amounts[]: diff length"
        );
        for (uint256 i = 0; i < addrs.length; i++) {
            // slither-disable-next-line calls-loop,low-level-calls
            (bool success, ) = addrs[i].call{value: amounts[i]}("");
            require(success, "ether transfer failed");
        }
    }

    /// @notice Executes rollup.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer.
    /// - Bridge must not be paused.
    /// - Handler must be registered with {resourceID}.
    /// - {msg.sender} must be registered in handler.
    ///
    /// @notice Emits {ExecuteRollup} event which is handled by relayer.
    function executeRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 stateChangeHash
    ) external override whenNotPaused {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        require(handlerAddress != address(0), "invalid resource ID");

        uint64 nonce = ++_depositCounts[destDomainID];

        // Note: The source resource ID is identical to the destination resource ID.
        bytes32 destResourceID = IRollupHandler(handlerAddress)
            .getResourceIDByAddress(msg.sender);

        require(destResourceID != bytes32(0), "invalid source resource");

        emit ExecuteRollup(
            destDomainID,
            resourceID,
            destResourceID,
            nonce,
            batchSize,
            startBlock,
            stateChangeHash
        );
    }

    /// @notice Settles state changes.
    ///
    /// @notice Requirements:
    /// - Handler must be registered with {resourceID}.
    ///
    /// @dev It can be called by anyone.
    function settleStateChanges(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce,
        bytes calldata data,
        bytes32[] calldata proof
    ) external whenNotPaused {
        address handlerAddress = _resourceIDToHandlerAddress[resourceID];
        require(handlerAddress != address(0), "no handler for resourceID");
        RollupInfo memory rollupInfo;
        address receiver;
        (rollupInfo, receiver) = IRollupHandler(handlerAddress).getRollupInfo(
            originDomainID,
            resourceID,
            nonce
        );

        IRollupReceiver(receiver).receiveStateChanges(rollupInfo, data, proof);
        uint64 batchIndex = abi.decode(data, (uint64));

        // slither-disable-next-line reentrancy-events
        emit SettleStateChanges(
            originDomainID,
            resourceID,
            nonce,
            batchIndex,
            rollupInfo.totalBatches
        );
    }

    /// @notice Returns a proposal.
    ///
    /// @param originDomainID Chain ID deposit originated from.
    /// @param depositNonce ID of proposal generated by proposal's origin Bridge contract.
    /// @param dataHash Hash of data to be provided when deposit proposal is executed.
    /// @return Proposal which consists of:
    /// - _dataHash Hash of data to be provided when deposit proposal is executed.
    /// - _yesVotes Number of votes in favor of proposal.
    /// - _noVotes Number of votes against proposal.
    /// - _status Current status of proposal.
    function getProposal(
        uint8 originDomainID,
        uint64 depositNonce,
        bytes32 dataHash
    ) external view returns (Proposal memory) {
        uint72 nonceAndID = (uint72(depositNonce) << 8) |
            uint72(originDomainID);
        return _proposals[nonceAndID][dataHash];
    }

    /// @notice Returns true if {relayer} has voted on {destNonce} {dataHash} proposal.
    ///
    /// @param destNonce destinationDomainID + depositNonce of the proposal.
    /// @param dataHash Hash of data to be provided when deposit proposal is executed.
    /// @param relayer Address to check.
    ///
    /// @dev Naming left unchanged for backward compatibility.
    function _hasVotedOnProposal(
        uint72 destNonce,
        bytes32 dataHash,
        address relayer
    ) external view returns (bool) {
        return _hasVoted(_proposals[destNonce][dataHash], relayer);
    }

    /// @notice Returns true if {relayer} has the relayer role.
    ///
    /// @param relayer Address to check.
    function isRelayer(address relayer) external view returns (bool) {
        return hasRole(RELAYER_ROLE, relayer);
    }

    /// @notice Executes a deposit proposal that is considered passed using a specified handler contract.
    ///
    /// @notice Requirements:
    /// - It must be called by only relayer.
    /// - Bridge must not be paused.
    /// - Proposal must have Passed status.
    /// - Hash of {data} must equal proposal's {dataHash}.
    ///
    /// @param domainID ID of chain deposit originated from.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param depositNonce ID of deposited generated by origin Bridge contract.
    /// @param data Data originally provided when deposit was made.
    /// @param revertOnFail Decision if the transaction should be reverted in case of handler's executeProposal is reverted or not.
    ///
    /// @notice Emits {ProposalEvent} event with status {Executed}.
    /// @notice Emits {FailedExecution} event with the failed reason.
    function executeProposal(
        uint8 domainID,
        uint64 depositNonce,
        bytes calldata data,
        bytes32 resourceID,
        bool revertOnFail
    ) public onlyRelayers whenNotPaused {
        address handler = _resourceIDToHandlerAddress[resourceID];
        uint72 nonceAndID = (uint72(depositNonce) << 8) | uint72(domainID);
        bytes32 dataHash = keccak256(abi.encodePacked(handler, data));
        Proposal storage proposal = _proposals[nonceAndID][dataHash];

        require(
            proposal._status == ProposalStatus.Passed,
            "Proposal must have Passed status"
        );

        proposal._status = ProposalStatus.Executed;
        IDepositExecute depositHandler = IDepositExecute(handler);

        if (revertOnFail) {
            depositHandler.executeProposal(resourceID, data);
        } else {
            try depositHandler.executeProposal(resourceID, data) {} catch (
                // slither-disable-next-line uninitialized-local,variable-scope
                bytes memory lowLevelData
            ) {
                // slither-disable-next-line reentrancy-no-eth
                proposal._status = ProposalStatus.Passed;
                // slither-disable-next-line reentrancy-events
                emit FailedHandlerExecution(lowLevelData);
                return;
            }
        }

        // slither-disable-next-line reentrancy-events
        emit ProposalEvent(
            domainID,
            resourceID,
            depositNonce,
            ProposalStatus.Executed,
            dataHash
        );
    }

    /// @notice Returns total relayers number.
    ///
    /// @dev Added for backwards compatibility.
    function _totalRelayers() public view returns (uint256) {
        return AccessControl.getRoleMemberCount(RELAYER_ROLE);
    }

    function _onlyAdminOrRelayer() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender) ||
                hasRole(RELAYER_ROLE, msg.sender),
            "sender is not relayer or admin"
        );
    }

    function _onlyAdmin() private view {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "sender doesn't have admin role"
        );
    }

    function _onlyRelayers() private view {
        require(
            hasRole(RELAYER_ROLE, msg.sender),
            "sender doesn't have relayer role"
        );
    }

    function _relayerBit(address relayer) private view returns (uint256) {
        return
            uint256(1) <<
            (AccessControl.getRoleMemberIndex(RELAYER_ROLE, relayer) - 1);
    }

    function _hasVoted(Proposal memory proposal, address relayer)
        private
        view
        returns (bool)
    {
        return (_relayerBit(relayer) & uint256(proposal._yesVotes)) > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev This module is supposed to be used in Bridge.
///
/// This is adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/access/AccessControl.sol
/// The only difference is added getRoleMemberIndex(bytes32 role, address account) function.

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessControl is Context {
    using EnumerableSet for EnumerableSet.AddressSet;
    using Address for address;

    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    ///  @notice Emitted when `account` is granted `role`.
    ///
    /// `sender` is the account that originated the contract call, an admin role
    /// bearer except when using {_setupRole}.
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when `account` is revoked `role`.
    ///
    /// `sender` is the account that originated the contract call:
    ///   - if using `revokeRole`, it is the admin role bearer
    ///   - if using `renounceRole`, it is the role bearer (i.e. `account`)
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members.contains(account);
    }

    /// @notice Returns the number of accounts that have `role`. Can be used
    /// together with {getRoleMember} to enumerate all bearers of a role.
    function getRoleMemberCount(bytes32 role) public view returns (uint256) {
        return _roles[role].members.length();
    }

    /// @notice Returns one of the accounts that have `role`. `index` must be a
    /// value between 0 and {getRoleMemberCount}, non-inclusive.
    ///
    /// Role bearers are not sorted in any particular way, and their ordering may
    /// change at any point.
    ///
    /// WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
    /// you perform all queries on the same block. See the following
    /// https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
    /// for more information.
    // slither-disable-next-line external-function
    function getRoleMember(bytes32 role, uint256 index)
        public
        view
        returns (address)
    {
        return _roles[role].members.at(index);
    }

    /// @notice Returns the index of the account that have `role`.
    function getRoleMemberIndex(bytes32 role, address account)
        public
        view
        returns (uint256)
    {
        return
            _roles[role].members._inner._indexes[
                bytes32(uint256(uint160(account)))
            ];
    }

    /// @notice Returns the admin role that controls `role`. See {grantRole} and
    /// {revokeRole}.
    ///
    /// To change a role's admin, use {_setRoleAdmin}.
    // slither-disable-next-line external-function
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function grantRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to grant"
        );

        _grantRole(role, account);
    }

    /// @notice Revokes `role` from `account`.
    ///
    /// If `account` had been granted `role`, emits a {RoleRevoked} event.
    ///
    /// @notice Requirements:
    /// - the caller must have ``role``'s admin role.
    function revokeRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            hasRole(_roles[role].adminRole, _msgSender()),
            "AccessControl: sender must be an admin to revoke"
        );

        _revokeRole(role, account);
    }

    /// @notice Revokes `role` from the calling account.
    ///
    /// Roles are often managed via {grantRole} and {revokeRole}: this function's
    /// purpose is to provide a mechanism for accounts to lose their privileges
    /// if they are compromised (such as when a trusted device is misplaced).
    ///
    /// If the calling account had been granted `role`, emits a {RoleRevoked}
    /// event.
    ///
    /// @notice Requirements:
    /// - the caller must be `account`.
    function renounceRole(bytes32 role, address account) public virtual {
        // solhint-disable-next-line reason-string
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /// @notice Grants `role` to `account`.
    ///
    /// If `account` had not been already granted `role`, emits a {RoleGranted}
    /// event. Note that unlike {grantRole}, this function doesn't perform any
    /// checks on the calling account.
    ///
    /// WARNING: This function should only be called from the constructor when setting
    /// up the initial roles for the system.
    ///
    /// Using this function in any other way is effectively circumventing the admin
    /// system imposed by {AccessControl}.
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /// @notice Sets `adminRole` as ``role``'s admin role.
    // slither-disable-next-line dead-code
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (_roles[role].members.add(account)) {
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (_roles[role].members.remove(account)) {
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IERCHandler {
    /// @notice Correlates {resourceID} with {contractAddress}.
    /// @param resourceID ResourceID to be used when making deposits.
    /// @param contractAddress Address of contract to be called when a deposit is made and a deposited is executed.
    function setResource(bytes32 resourceID, address contractAddress) external;

    /// @notice Marks {contractAddress} as mintable/burnable.
    /// @param contractAddress Address of contract to be used when making or executing deposits.
    function setBurnable(address contractAddress) external;

    /// @notice Withdraw funds from ERC safes.
    /// @param data ABI-encoded withdrawal params relevant to the handler.
    function withdraw(bytes memory data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

interface IDepositExecute {
    /// @notice It is intended that deposit are made using the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param depositer Address of account making the deposit in the Bridge contract.
    /// @param data Consists of additional data needed for a specific deposit.
    function deposit(
        bytes32 resourceID,
        address depositer,
        bytes calldata data
    ) external payable returns (bytes memory);

    /// @notice It is intended that proposals are executed by the Bridge contract.
    /// @param resourceID ResourceID to be used.
    /// @param data Consists of additional data needed for a specific deposit execution.
    function executeProposal(bytes32 resourceID, bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/rollup/RollupTypes.sol";

interface IRollupSender {
    function executeRollup(
        uint8 destDomainID,
        bytes32 resourceID,
        uint64 batchSize,
        uint256 startBlock,
        bytes32 state
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/rollup/RollupTypes.sol";

interface IRollupReceiver {
    function receiveStateChanges(
        RollupInfo memory rollupInfo,
        bytes memory data,
        bytes32[] calldata proof
    ) external;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

import "../utils/rollup/RollupTypes.sol";

interface IRollupHandler {
    function getRollupInfo(
        uint8 originDomainID,
        bytes32 resourceID,
        uint64 nonce
    ) external returns (RollupInfo memory rollupInfo, address receiver);

    function getResourceIDByAddress(address tokenAddress)
        external
        view
        returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.0;

struct StateContext {
    bool _writable;
    bytes32 _hash; // writable
    uint256 _startBlock; // writable
    // readable
    uint8 _epoch;
}

struct KeyValuePair {
    bytes key;
    bytes value;
}

struct BatchedStateChanges {
    uint64 batchIndex;
    bytes data;
}

struct RollupInfo {
    uint8 originDomainID;
    uint64 nonce;
    bytes32 stateChangeHash;
    bytes32 rootHash;
    uint64 totalBatches;
    address destAddress;
}