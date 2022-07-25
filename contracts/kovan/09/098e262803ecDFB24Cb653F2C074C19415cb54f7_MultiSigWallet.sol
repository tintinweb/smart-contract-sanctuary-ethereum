// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @dev This is a multi signature wallet contract.
 * @author MikhilMC
 */
contract MultiSigWallet is ReentrancyGuard {
    event DepositAmount(address indexed sender, uint256 indexed amount);
    event SubmitTransaction(uint256 indexed txId);
    event ApproveTransaction(address indexed owner, uint256 indexed txId);
    event RevokeTransaction(address indexed owner, uint256 indexed txId);
    event ExecuteTransaction(uint256 indexed txId);

    event SubmitCandidate(uint256 indexed reqId);
    event SupportCandidate(address indexed owner, uint256 indexed reqId);
    event RevokeSupport(address indexed owner, uint256 indexed reqId);
    event OwnerSelected(uint256 indexed reqId, address indexed newOwner);

    event SubmitRemoval(uint256 indexed reqId);
    event ApproveRemoval(address indexed owner, uint256 indexed reqId);
    event RevokeApproval(address indexed owner, uint256 indexed reqId);
    event OwnerRemoved(uint256 indexed reqId, address indexed oldOwner);

    event SubmitNewRequiredVotes(uint256 indexed reqId);
    event ApproveNewRequiredVotes(
        address indexed owner,
        uint256 indexed reqId
    );
    event RevokeNewRequiredVotes(
        address indexed owner,
        uint256 indexed reqId
    );
    event RequiredVotesChanged(
        uint256 indexed reqId,
        uint256 indexed newRequiredVotes
    );

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        uint256 numberOfApprovals;
        uint256 startTime;
        uint256 endTime;
        bool executed;
    }

    struct Candidate {
        address candidateAddress;
        uint256 numberOfApprovals;
        uint256 startTime;
        uint256 endTime;
        bool selected;
    }

    struct OwnershipRemoval {
        address ownerAddress;
        uint256 numberOfApprovals;
        uint256 startTime;
        uint256 endTime;
        bool removed;
    }

    struct NewRequiredVote {
        uint256 newRequiredVotes;
        uint256 numberOfApprovals;
        uint256 startTime;
        uint256 endTime;
        bool changed;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    Candidate[] public candidates;
    mapping(uint256 => mapping(address => bool)) public supportCandidate;

    OwnershipRemoval[] public removalProposals;
    mapping(uint256 => mapping(address => bool)) public supportRemoval;

    NewRequiredVote[] public requiredVotesProposals;
    mapping(uint256 => mapping(address => bool)) public supportRequiredVotes;

    /**@dev Modifier used for restricting access 
     * only for the owners of the multi sig wallet
     */
    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the transaction data exists
     */
    modifier txExists(uint256 _txId) {
        require(_txId < transactions.length, "Tx does not exists");
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the transaction is not approved by an owner
     */
    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "Tx already approved");
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the transaction is not executed
     */
    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "Tx already executed");
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the candidate data exists
     */
    modifier candidateExists(uint256 _candidateId) {
        require(_candidateId < candidates.length, "Candidate does not exists");
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the candidate is not supported by that owner
     */
    modifier notSupported(uint256 _candidateId) {
        require(
            !supportCandidate[_candidateId][msg.sender],
            "Candidate already approved"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the candidate is not elected as a new owner
     */
    modifier notElected(uint256 _candidateId) {
        require(
            !candidates[_candidateId].selected,
            "Candidate already elected"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the removal proposal data for an owner exists
     */
    modifier removalProposalExists(uint256 _proposalId) {
        require(
            _proposalId < removalProposals.length,
            "Removal proposal does not exists"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the removal proposal data for an owner 
     * is not supported by that user
     */
    modifier notSupportedRemoval(uint256 _proposalId) {
        require(
            !supportRemoval[_proposalId][msg.sender],
            "Removal proposal already approved"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the removal proposal data for an owner 
     * is not completed and that owner is not removed.
     */
    modifier notRemoved(uint256 _proposalId) {
        require(
            !removalProposals[_proposalId].removed,
            "Owner already removed"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the data about the proposal for a 
     * new required votes exists.
     */
    modifier newRequiredVotesExists(uint256 _proposalId) {
        require(
            _proposalId < requiredVotesProposals.length,
            "New required votes proposal does not exists"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the data about the proposal for a 
     * new required votes is supported by that user.
     */
    modifier notApprovedRequiredVotes(uint256 _proposalId) {
        require(
            !supportRequiredVotes[_proposalId][msg.sender],
            "New required votes proposal already approved"
        );
        _;
    }

    /**@dev Modifier used for restricting access 
     * only if the data about the proposal for a 
     * new required votes is selected and 
     * the required votes is changed.
     */
    modifier notChanged(uint256 _proposalId) {
        require(
            !requiredVotesProposals[_proposalId].changed,
            "Required votes proposal already changed"
        );
        _;
    }

    /**@dev Creates a multi signature wallet.
     * @param _owners array of address of owners.
     * @param _required number required votes
     */
    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(
            _required >= ((_owners.length / 2) + 1) && 
            _required < _owners.length,
            "Invalid number of required votes"
        );

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid address");
            require(!isOwner[owner], "Owner is not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        required = _required;
    }

    /**@dev function to receive ether to the contract.*/
    receive() external payable {
        emit DepositAmount(msg.sender, msg.value);
    }

    // ---------------------START of Election for a transaction--------------

    /**@dev Submits the proposal for a new transaction to
     * the multi signature wallet contract.
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     *
     * @param _to address to which this transaction is going to execute
     * @param _value amount of ether wants to be sent with the transaction
     * @param _data bytes of the data which going to be executed
     * @param _timeDuration time duration given to the owners to make decision
     *        on the given transaction
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _timeDuration
    ) external onlyOwner nonReentrant {
        require(_timeDuration > 0, "Zero time duration");
        transactions.push(Transaction({
            to: _to,
            value: _value,
            data: _data,
            numberOfApprovals: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _timeDuration,
            executed: false
        }));

        emit SubmitTransaction(transactions.length - 1);
    }

    /**@dev Supports the proposal for a new transaction by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The transaction proposal data must exist in the smart contract.
     * - The owner shouldn't have approved this transaction before.
     * - The transaction shouldn't have executed
     *
     * @param _txId index in which the transaction data 
     *        lies in the transactions array
     */
    function confirmTransaction(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notApproved(_txId)
        notExecuted(_txId)
        nonReentrant
    {
        Transaction storage transaction = transactions[_txId];
        require(
            transaction.endTime >= block.timestamp,
            "Time up!"
        );
        approved[_txId][msg.sender] = true;
        transaction.numberOfApprovals += 1;
        emit ApproveTransaction(msg.sender, _txId);
        if (transaction.numberOfApprovals == required) {
            transaction.executed = true;

            (bool success, ) = transaction.to.call{value: transaction.value}(
                transaction.data
            );

            require(success, "Tx failed");

            emit ExecuteTransaction(_txId);
        }
    }

    /**@dev Revoke the support for the proposal for a new transaction, by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The transaction proposal data must exist in the smart contract.
     * - The owner should have approved this transaction before.
     * - The transaction shouldn't have executed
     *
     * @param _txId index in which the transaction data 
     *        lies in the transactions array
     */
    function revokeConfirmation(uint256 _txId)
        external
        onlyOwner
        txExists(_txId)
        notExecuted(_txId)
        nonReentrant
    {
        require(
            transactions[_txId].endTime >= block.timestamp,
            "Time up!"
        );
        require(approved[_txId][msg.sender], "Tx not approved");
        transactions[_txId].numberOfApprovals -= 1;
        approved[_txId][msg.sender] = false;
        emit RevokeTransaction(msg.sender, _txId);
    }

    // ---------------------END of Election for a transaction--------------

    // ---------------------START of Election for a new owner--------------

    /**@dev Submits the proposal for a new owner to
     * the multi signature wallet contract.
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The given candidate must not be a current owner.
     * - The time duration must not be 0.
     *
     * @param _candidate address of the new owner candidate
     * @param _timeDuration time duration given to the owners to make decision
     *        on the given owner candidate
     */
    function addOwnerCandidate(
        address _candidate,
        uint256 _timeDuration
    ) external onlyOwner nonReentrant {
        require(!isOwner[_candidate], "Already an owner");
        require(_timeDuration > 0, "Zero time duration");
        candidates.push(Candidate({
            candidateAddress: _candidate,
            numberOfApprovals: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _timeDuration,
            selected: false
        }));

        emit SubmitCandidate(candidates.length - 1);
    }

    /**@dev Supports the proposal for a new ownership candidate by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The candidateship proposal data must exist in the smart contract.
     * - The owner shouldn't have approved this candidateship proposal before.
     * - The candidate shouldn't have selected as an owner
     *
     * @param _candidateId index in which the candidateship proposal data 
     *        lies in the candidates array
     */
    function voteCandidate(uint256 _candidateId) 
        external
        onlyOwner
        candidateExists(_candidateId)
        notSupported(_candidateId)
        notElected(_candidateId)
        nonReentrant 
    {
        Candidate storage candidate = candidates[_candidateId];
        require(
            candidate.endTime >= block.timestamp,
            "Time up!"
        );
        supportCandidate[_candidateId][msg.sender] = true;
        candidate.numberOfApprovals += 1;
        emit SupportCandidate(msg.sender, _candidateId);
        if (candidate.numberOfApprovals == required) {
            candidate.selected = true;
            address newOwner = candidate.candidateAddress;
            owners.push(newOwner);
            isOwner[newOwner] = true;
            if (required == (owners.length / 2)) {
                required += 1;
            }
            emit OwnerSelected(_candidateId, newOwner);
        }
    }

    /**@dev Revoke support for the proposal for a new 
     *      ownership candidate by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The candidateship proposal data must exist in the smart contract.
     * - The owner should have approved this candidateship proposal before.
     * - The candidate shouldn't have selected as an owner
     *
     * @param _candidateId index in which the candidateship proposal data 
     *        lies in the candidates array
     */
    function revokeVote(uint256 _candidateId)
        external
        onlyOwner
        candidateExists(_candidateId)
        notElected(_candidateId)
        nonReentrant
    {
        require(
            candidates[_candidateId].endTime >= block.timestamp,
            "Time up!"
        );
        require(
            supportCandidate[_candidateId][msg.sender],
            "Candidate not approved"
        );
        candidates[_candidateId].numberOfApprovals -= 1;
        supportCandidate[_candidateId][msg.sender] = false;
        emit RevokeSupport(msg.sender, _candidateId);
    }

    // ---------------------END of Election for a new owner--------------

    // ---------------------START of Removal of a current owner--------------

    /**@dev Submits the proposal for removing a current owner from
     * the multi signature wallet contract.
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The given address must be a current owner.
     * - The time duration must not be 0.
     *
     * @param _owner address of the current owner whom need to be removed.
     * @param _timeDuration time duration given to the owners to make decision
     *        on the given removal proposal of an owner.
     */
    function removeOwner(
        address _owner,
        uint256 _timeDuration
    ) external onlyOwner nonReentrant {
        require(isOwner[_owner], "Not an owner");
        require(_timeDuration > 0, "Zero time duration");
        removalProposals.push(OwnershipRemoval({
            ownerAddress: _owner,
            numberOfApprovals: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _timeDuration,
            removed: false
        }));

        emit SubmitRemoval(removalProposals.length - 1);
    }

    /**@dev Supports the proposal for removing a current owner by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The removal proposal data must exist in the smart contract.
     * - The owner shouldn't have approved this removal proposal before.
     * - The owner in the removal proposal must not be removed 
     *   from the ownership position.
     *
     * @param _proposalId index in which the removal proposal data 
     *        lies in the removalProposals array
     */
    function voteRemovalProposal(uint256 _proposalId) 
        external
        onlyOwner
        removalProposalExists(_proposalId)
        notSupportedRemoval(_proposalId)
        notRemoved(_proposalId) 
        nonReentrant
    {
        OwnershipRemoval storage proposal = removalProposals[_proposalId];
        require(
            proposal.endTime >= block.timestamp,
            "Time up!"
        );
        supportRemoval[_proposalId][msg.sender] = true;
        proposal.numberOfApprovals += 1;
        emit ApproveRemoval(msg.sender, _proposalId);
        if (proposal.numberOfApprovals == required) {
            proposal.removed = true;
            address oldOwner = proposal.ownerAddress;
            _removeOwner(oldOwner);
            isOwner[oldOwner] = false;
            emit OwnerRemoved(_proposalId, oldOwner);
        }
    }

    /**@dev Removes the given owner from owners array
     *      and sets the ownership status of that address is set as false
     *
     * @param _owner address which need to be stripped
     *        from the ownership privilages.
    */
    function _removeOwner(address _owner) private {
        uint256 index;
        for (uint256 i; i < owners.length; i++) {
            if (_owner == owners[i]) {
                index = i;
                break;
            }
        }
        owners[index] = owners[owners.length - 1];
        owners.pop();
        if (required == owners.length) {
            required -= 1;
        }
    }

    /**@dev Revoke the support the proposal 
     * for removing a current owner by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The removal proposal data must exist in the smart contract.
     * - The owner should have approved this removal proposal before.
     * - The owner in the removal proposal must not be removed 
     *   from the ownership position.
     *
     * @param _proposalId index in which the removal proposal data 
     *        lies in the removalProposals array
     */
    function revokeRemovalSupport(uint256 _proposalId)
        external
        onlyOwner
        removalProposalExists(_proposalId)
        notRemoved(_proposalId)
        nonReentrant
    {
        require(
            removalProposals[_proposalId].endTime >= block.timestamp,
            "Time up!"
        );
        require(
            supportRemoval[_proposalId][msg.sender],
            "Ownership removal not approved"
        );
        removalProposals[_proposalId].numberOfApprovals -= 1;
        supportRemoval[_proposalId][msg.sender] = false;
        emit RevokeApproval(msg.sender, _proposalId);
    }

    // ---------------------END of Removal of a current owner--------------

    // ---------------START of Changing the required number of votes--------------

    /**@dev Submits the proposal for a new amount of required voted for
     * the multi signature wallet contract.
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The given required votes must not be the current required amount.
     * - The given required votes must be greater than half of the
     *   length of the owners array.
     * - The given required votes must be less than the length of the owners array.
     * - The time duration must not be 0.
     *
     * @param _reqVotes amount of new required votes.
     * @param _timeDuration time duration given to the owners to make decision on the
     *        given proposal for deciding to change the required amount of votes.
     */
    function addNewRequiredVotes(
        uint256 _reqVotes,
        uint256 _timeDuration
    ) external onlyOwner nonReentrant {
        require(_reqVotes != required, "Already the same required votes");
        require(
            _reqVotes >= ((owners.length / 2) + 1) && 
            _reqVotes < owners.length,
            "Invalid number of required votes"
        );
        require(_timeDuration > 0, "Zero time duration");
        requiredVotesProposals.push(NewRequiredVote({
            newRequiredVotes: _reqVotes,
            numberOfApprovals: 0,
            startTime: block.timestamp,
            endTime: block.timestamp + _timeDuration,
            changed: false
        }));

        emit SubmitNewRequiredVotes(requiredVotesProposals.length - 1);
    }

    /**@dev Supports the proposal for the new required amount of votes by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The proposal data for the new required amount of votes
     *   must exist in the smart contract.
     * - The owner shouldn't have approved this proposal
     *   for the new required amount of votes before.
     * - The amount in the proposal for the new required amount
     *   of votes must not be selected.
     *
     * @param _proposalId index in which the proposal data 
     *        for the new required amount of votes lies in 
     *        the requiredVotesProposals array
     */
    function approveNewRequiredVotes(uint256 _proposalId) 
        external
        onlyOwner
        newRequiredVotesExists(_proposalId)
        notApprovedRequiredVotes(_proposalId)
        notChanged(_proposalId) 
        nonReentrant
    {
        NewRequiredVote storage proposal = requiredVotesProposals[_proposalId];
        require(
            proposal.endTime >= block.timestamp,
            "Time up!"
        );
        supportRequiredVotes[_proposalId][msg.sender] = true;
        proposal.numberOfApprovals += 1;
        emit ApproveNewRequiredVotes(msg.sender, _proposalId);
        if (proposal.numberOfApprovals == required) {
            proposal.changed = true;
            uint256 reqVotes = proposal.newRequiredVotes;
            required = reqVotes;
            emit RequiredVotesChanged(_proposalId, reqVotes);
        }
    }

    /**@dev Revoke support for the proposal for the new required amount
     *      of votes by an owner
     * Requirements:
     *
     * - Only the owners of the contract can call this function.
     * - The proposal data for the new required amount of votes
     *   must exist in the smart contract.
     * - The owner should have approved this proposal
     *   for the new required amount of votes before.
     * - The amount in the proposal for the new required amount
     *   of votes must not be selected.
     *
     * @param _proposalId index in which the proposal data 
     *        for the new required amount of votes lies in 
     *        the requiredVotesProposals array
     */
    function revokeNewRequiredVotes(uint256 _proposalId)
        external
        onlyOwner
        newRequiredVotesExists(_proposalId)
        notChanged(_proposalId)
        nonReentrant
    {
        require(
            requiredVotesProposals[_proposalId].endTime >= block.timestamp,
            "Time up!"
        );
        require(
            supportRequiredVotes[_proposalId][msg.sender],
            "New required votes proposal not approved"
        );
        requiredVotesProposals[_proposalId].numberOfApprovals -= 1;
        supportRequiredVotes[_proposalId][msg.sender] = false;
        emit RevokeNewRequiredVotes(msg.sender, _proposalId);
    }

    // ---------------END of Changing the required number of votes--------------

    /**@dev Function to get the current time.*/
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}