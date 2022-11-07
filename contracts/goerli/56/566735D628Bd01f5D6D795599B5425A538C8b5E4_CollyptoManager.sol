// SPDX-License-Identifier: copyleft-next-0.3.1
// CollyptoManager Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;
import "./Collypto.sol";

/**
 * @title Collypto Manager
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract provides stratified access control to all utility and
 * management functions in the Collypto contract.
 * @dev This contract is the implementation of the Collypto Manager on the
 * Ethereum blockchain.
 *
 * OVERVIEW
 * This contract operates as an application specific multiplexed multisignature
 * access control system with social recovery. Operations are stratified into a
 * defined set of operator classes, where each class may conduct a defined set
 * of operations. Management and utility operations are enacted via a proposal
 * system where the proposal ID is generated using the enumerated {Operations}
 * value and data parameters of the operation itself. We have not designed this
 * contract to be upgradable. When we need to update it, we will simply
 * discontinue use of the current contract instance in favor of the newest
 * version of the contract.
 * 
 * PROPOSAL SYSTEM
 * When a utility or management operation function is called by an authorized
 * operator, a proposal is created with an ID that is generated using a
 * uniquely deterministic hash of its input parameters. When a given proposal
 * receives a majority of approvals from its authorized operators, this
 * contract will attempt to execute it on the Collypto contract and will return
 * the most recent proposal object available (after its final approval), in
 * addition to the Boolean result of its execution.
 *
 * Proposals are stored in the format defined in the {Proposal} struct, and
 * {Proposal} records are stored in the {_proposalMap} for O(1) retrieval, and
 * all active proposal IDs are maintained in the {_proposalList} for aggregated
 * reference and deletion. Consequently, this contract does not support
 * redundant proposals, and a {Proposal} record with a given {id} value and
 * parameters may be recreated and executed multiple times, but the {index}
 * value of each subsequent {Proposal} record will be unique for a given
 * instance of this contract, because it represents the value of
 * {_currentProposalIndex} when that proposal was created, and the value of
 * {_currentProposalIndex} cannot be reset.
 *
 * When an operator calls a utility or management function using an Ethereum
 * account belonging to the required operator class, this contract will
 * determine whether or not they represent a majority of operators of that
 * class. If the required operator class has less than two operators, the
 * operation will execute immediately, and the {id} value of the generated
 * {Proposal} record will be returned with the execution result, otherwise,
 * that {Proposal} record will be stored in the {_proposalMap}, its {id} value
 * will be added to the {_proposalList}, and the {id} value of the generated
 * {Proposal} record will be returned with a "false" value indicating that the
 * proposal was not immediately executed. Subsequent calls to the same utility
 * operation with identical input parameters will add the approval of the
 * calling operator's address (if authorized) to the {approvers} list of the
 * target {Proposal} record and the {_hasApproved} mapping for O(1) access.
 * 
 * When an approval breaks the majority threshold of greater than half of the
 * authorized operators of a given class, the proposal will be executed, the
 * corresponding {Proposal} record will be deleted, and the {id} value of that
 * {Proposal} record will be returned to the calling operator with a
 * Boolean value representing the execution result of that proposal.
 *
 * OPERATOR CLASSES
 * There are nine distinct operator classes in this contract that may be used
 * to conduct various operations within the Collypto contract and this contract
 * itself. A "management operation" can be defined as any operation that may
 * only be conducted by an operator with a Prime key, and a "utility
 * operation" can be defined as any operation to be executed in the Collypto
 * contract that requires a key belonging to any of the other eight classes in
 * the {OperatorClasses} enumeration. Operator authorizations are maintained in
 * the {_authorizedOperatorMap} for O(1) retrieval, and the list of authorized
 * operators for each operator class is maintained in the
 * {_authorizedOperatorList} for aggregated reference and removal.
 *
 * STANDARD OPERATIONS ({getCollyptoAddress}, {getProposalRecord},
 * {getActiveProposals}, {totalActiveProposals}, {getCurrentProposalIndex},
 * {getCurrentOperators}, {revokeApproval})
 * This contract contains seven standard operations that may be conducted by an
 * operator using any Ethereum account to retrieve proposal information, view
 * authorized operators by class, or revoke an approval on a proposal that was
 * previously approved by that account.
 *
 * UTILITY OPERATIONS ({updateUserStatus}, {forceTransfer}, {freeze},
 * {unfreeze}, {lock}, {unlock}, {mint}, {burn})
 * This contract contains eight utility operations that correspond to the
 * utility operations of the Collypto contract. Each utility operation may only
 * be conducted by an operator using an Ethereum account that is authorized as
 * the operator class required for the specified operation.
 *
 * MANAGEMENT OPERATIONS ({pause}, {unpause}, {addManager}, {removeManager},
 * {updateCollyptoAddress}, {removeProposal}, {purgeProposals}, {addOperator},
 * {removeOperator}, {purgeOperators})
 * This contract contains ten management operations that are used to maintain
 * the address and running state of the Collypto contract and regulate
 * operators and proposals within this contract. Management operations may only
 * be conducted by an operator using an Ethereum account with Prime
 * authorization.
 *
 * COLLYPTO CONTRACT MANAGEMENT ({pause}, {unpause}, {addManager},
 * {removeManager}, {updateCollyptoAddress})
 * All Collypto contract operations are multiplexed through the proposal system
 * and directed upon execution to the address maintained in {_collyptoAddress}.
 * In the event that we need to update the Collypto contract in a way that
 * doesn't require a corresponding code change in this contract, we may update
 * the Collypto reference address using the {updateCollyptoAddress} function.
 *
 * The {addManager} function allows Prime operators to add a new management
 * contract address to the Collypto contract (for updating this contract), and
 * the {removeManager} function allows Prime operators to remove the current
 * management address of this contract from the Collypto manager list after the
 * new contract address has been successfully added. The {pause} and {unpause}
 * functions allow Prime operators to pause the running state of the Collypto
 * contract and unpause it to respectively suspend and resume users' ability to
 * conduct standard Collypto operations.
 *
 * PROPOSAL REMOVAL ({removeProposal}, {purgeProposals})
 * There are two management functions that may be utilized by Prime operators
 * to permenantly delete proposals, removing their corresponding {Proposal}
 * records from the {_proposalMap} and {_proposalList} (all proposals in those
 * mappings are considered "active proposals"). The {removeProposal} function
 * removes a single {Proposal} record with the {id} value provided, and the
 * {purgeProposals} function removes all active proposals.
 *
 * OPERATOR MANAGEMENT ({addOperator}, {removeOperator}, {purgeOperators})
 * In the event that we need to add one or more authorized operators to a given
 * operator class, we can utilize the {addOperator} function to add individual
 * address authorizations for that class. To revoke operator authorizations, we
 * can utilize the {removeOperator} function with a provided operator class and
 * address to remove the provided address from the authorization mappings, or
 * we can utilize {purgeOperators} with a provided operator class to clear all
 * authorizations for that class (in the event that a majority of authorized
 * accounts are compromised). Prime operators cannot be purged, and a majority
 * compromise of Prime operators means that we would need to purge managers
 * from the Collypto contract itself and redeploy this contract.
 */
contract CollyptoManager {
    /**
     * @dev Enumeration containing all valid class values that may be assigned
     * to an operator using the {_authorizedOperatorMap} mapping and the
     * {_authorizedOperatorList} array
     */    
    enum OperatorClasses { 
        Prime,        
        Arbiter,
        Dispatch,
        Freeze,
        Unfreeze,
        Lock,
        Unlock,
        Mint,
        Burn
    }

    /**
     * @dev Enumeration containing values that correspond to all valid
     * operations that may be conducted by an operator using a management or
     * utility key
     */         
    enum Operations {
        Pause,        
        Unpause,
        AddManager,
        RemoveManager,
        UpdateCollyptoAddress,
        RemoveProposal,
        PurgeProposals,                
        AddOperator,
        RemoveOperator,
        PurgeOperators,
        SetUserStatus,
        ForceTransfer,
        Freeze,
        Unfreeze,
        Lock,
        Unlock,
        Mint,       
        Burn
    }

    /**
     * @dev Struct encapsulating all required proposal properties utilized in
     * consensus logic
     */
    struct Proposal {
        uint256 id;
        uint256 index;
        Operations operation;
        address[] addressList;
        uint256 data;
        address[] approvers;
    }
    
    /**
     * @dev Mapping of Prime and Utility operators (indexed by operator class
     * and Ethereum account address)
     */
    mapping(OperatorClasses => mapping(address => bool))
        private _authorizedOperatorMap;

    /**
     * @dev Mapping of lists of all operators in each operator class (indexed
     * by operator class)
     */
    mapping(OperatorClasses => address[])
        private _authorizedOperatorList;

    /// @dev Mapping of active {Proposal} records (indexed by proposal ID)
    mapping(uint256 => Proposal) private _proposalMap;

    /// @dev Complete list of IDs of all active proposals ({Proposal} records)
    uint256[] private _proposalList;

    /**
     * @dev Mapping that indicates whether an operator has approved any given
     * proposal (indexed by proposal ID and the operator's Ethereum account
     * address)
     */        
    mapping(uint256 => mapping(address => bool)) private _hasApproved;

    /// @dev Current address of the Collypto contract
    address private _collyptoAddress;

    /// @dev Most recent proposal index
    uint256 private _currentProposalIndex;

    /**
     * @dev Event emitted when a {Proposal} record is created with an {id}
     * value of `proposalId` and {index} value of `proposalIndex` by an
     * operator using the Ethereum account at `creatorAddress`
     */ 
    event ProposalCreated(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex,
        address indexed creatorAddress
    );

    /**
     * @dev Event emitted when a {Proposal} record is removed with an {id}
     * value of `proposalId` and {index} value of `proposalIndex`
     */ 
    event ProposalRemoved(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex
    );

    /**
     * @dev Event emitted when a {Proposal} record is executed with an {id}
     * value of `proposalId` and {index} value of `proposalIndex`
     */ 
    event ProposalExecuted(
        uint256 indexed proposalId,
        uint256 indexed proposalIndex
    );

    /**
     * @dev Event emitted when all active proposals are purged from this
     * contract
     */
    event ProposalsPurged();

    /**
     * @dev Event emitted when an approval is added to the {Proposal} record
     * with an {id} value of `proposalId` by an operator using the Ethereum
     * account at `operatorAddress`
     */
    event ApprovalAdded(
        uint256 indexed proposalId,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when an approval is revoked from the {Proposal}
     * record with an {id} value of `proposalId` by an operator using the
     * Ethereum account at `operatorAddress`
     */
    event ApprovalRevoked(
        uint256 indexed proposalId,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when authorization for the Ethereum account at
     * `operatorAddress` is added to operator class `operatorClass`
     */
    event OperatorAdded(
        uint256 indexed operatorClass,
        address indexed operatorAddress
    );

    /**
     * @dev Event emitted when authorization for the Ethereum account at
     * `operatorAddress` is removed from operator class `operatorClass`
     */
    event OperatorRemoved(
        uint256 indexed operatorClass,
        address indexed operatorAddress
    );
    
    /**
     * @dev Event emitted when all authorizations are purged from operator
     * class `operatorClass`
     */
    event OperatorsPurged(uint256 indexed operatorClass);

    /**
     * @dev Event emitted when the reference address of the Collypto contract
     * is updated to `targetAddress`
     */
    event CollyptoAddressUpdated(address indexed targetAddress);

    /**
     * @dev Modifier that determines if an operator is authorized to perform
     * the transaction and reverts on "false"
     */
    modifier isAuthorized(OperatorClasses operatorClass) {    
        // Operator must belong to the specified class to continue
        require(_authorizedOperatorMap[operatorClass][msg.sender]);
        _;
    }

    /**
     * @notice Initializes this contract with a Collypto contract address value
     * of `collyptoAddress` and assigns the Ethereum address of the deployment
     * operator as the initial Prime address
     * @param collyptoAddress The reference address of the Collypto contract
     */
    constructor(address collyptoAddress) {
        address operator = msg.sender;
        _authorizedOperatorMap[OperatorClasses.Prime][operator] = true;
        
        // Default prime address is the deployment operator address
        _authorizedOperatorList[OperatorClasses.Prime].push(operator);

        _collyptoAddress = collyptoAddress;
        _currentProposalIndex = 0;
    }

    /**
     * @notice Returns the current address of the Collypto contract
     * @return collyptoAddress The current address of the Collypto contract
     */
    function getCollyptoAddress()
        public
        view
        returns (address collyptoAddress)
    {
        return _collyptoAddress;
    }    

    /**
     * @notice Returns all properties of the {Proposal} record with an {id}
     * value of `proposalId`
     * @param proposalId The {id} of the {Proposal} record to be returned
     * @return id The {id} value of the retrieved {Proposal} record
     * @return index The {index} value of the retrieved {Proposal} record
     * @return operation The {operation} value corresponding to the operation
     * to be executed in the retrieved {Proposal} record
     * @return addressList The {addressList} array corresponding to the list of
     * addresses in the retrieved {Proposal} record
     * @return data The {data} value representing the hashed data in the
     * retrieved {Proposal} record     
     * @return approvers The {approvers} array corresponding to the list of
     * approvers in the retrieved {Proposal} record
     */
    function getProposalRecord(uint256 proposalId)
        public
        view
        returns (
            uint256 id,
            uint256 index,
            Operations operation,
            address[] memory addressList,
            uint256 data,
            address[] memory approvers
        )
    {
        Proposal storage proposal = _proposalMap[proposalId];

        return (
            proposal.id,
            proposal.index,
            proposal.operation,
            proposal.addressList,
            proposal.data,            
            proposal.approvers
        );
    }

    /**
     * @notice Returns the list of proposal IDs of all active proposals
     * @return proposalIds The list of proposal IDs of all active proposals
     */
    function getActiveProposals()
        public
        view
        returns (uint256[] memory proposalIds)
    {
        return _proposalList;
    }

    /**
    * @notice Returns the total number of active {Proposal} records in
    * {_proposalList}
    * @return total The total number of active {Proposal} records in
    * {_proposalList}
    */
    function totalActiveProposals()
        public
        view
        returns (uint256 total)
    {
        return _proposalList.length;
    }
    
    /**
    * @notice Returns the index of the most recently created {Proposal} record
    * @return proposalIndex The index of the most recently created {Proposal}
    * record
    */
    function getCurrentProposalIndex()
        public
        view
        returns (uint256 proposalIndex)
    {
        return _currentProposalIndex;
    } 

    /**
     * @notice Returns the current list of operator addresses that are
     * authorized for operator class `operatorClass` operations
     * @param operatorClass The {OperatorClasses} value of operator requested
     * @return operators The list of operators that are authorized to conduct
     * operations of the provided {operatorClass}
     */
    function getCurrentOperators(OperatorClasses operatorClass)
        public
        view
        returns (address[] memory operators)
    {
        return _authorizedOperatorList[operatorClass];
    }

    /**
     * @notice Revokes the current operator's approval of the {Proposal} record
     * with an {id} value of `proposalId` and emits an {ApprovalRevoked} event
     * @dev This operation will revert upon execution if the operator or any
     * provided arguments violates any of the rules in the {_revokeApproval}
     * function.
     * @param proposalId The {id} value of the {Proposal} record where the
     * current operator's approval will be revoked
     * @return success A Boolean value indicating whether the operator's
     * approval has been revoked for the proposal with an {id} value of
     * {proposalId}
     */
    function revokeApproval(uint256 proposalId) public returns (bool success) {
        address operator = msg.sender;

        return _revokeApproval(proposalId, operator);
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {updateUserStatus} operation in the Collypto
     * contract, updating the {UserStatus} record of the Ethereum account at
     * `targetAddress` to contain a {status} value of `status` and an {info}
     * value of `info` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} event upon execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violate any of the rules in the
     * {updateUserStatus} function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account to be updated
     * @param status The {status} value to be assigned to the {UserStatus}
     * record of the target Ethereum account
     * @param info The {info} value to be assigned to the {UserStatus} record
     * of the target Ethereum account
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */    
    function updateUserStatus(
        address targetAddress,
        Collypto.Statuses status,
        string memory info
    )
        public
        isAuthorized(OperatorClasses.Arbiter)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;         
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.SetUserStatus,
                addressList,
                uint256(keccak256(abi.encodePacked(status, info)))
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).updateUserStatus(
                    targetAddress,
                    status,
                    info
                )
            );
        } else {
            return (updatedProposal.id, false);
        }
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {forceTransfer} operation in the Collypto
     * contract, moving `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (regardless of user or account status) and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the
     * {forceTransfer} function of the Collypto contract.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function forceTransfer(address from, address to, uint256 amount)
        public
        isAuthorized(OperatorClasses.Dispatch)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;          
        address[] memory addressList = new address[](2);
        addressList[0] = from;
        addressList[1] = to;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.ForceTransfer,
                addressList,
                amount
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).forceTransfer(from, to, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {freeze} operation in the Collypto contract,
     * freezing `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function.
     * @param targetAddress The address of the Ethereum account where credits
     * will be frozen
     * @param amount The total number of credits (in slivers) to be frozen
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function freeze(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Freeze)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;      
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Freeze, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).freeze(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unfreeze} operation in the Collypto
     * contract, unfreezing `amount` slivers in the Ethereum account at
     * `targetAddress` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} event upon execution
     * @dev This is a restricted utility function.
     * @param targetAddress The address of the Ethereum account where credits
     * will be unfrozen
     * @param amount The total number of credits (in slivers) to be unfrozen
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */
    function unfreeze(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Unfreeze)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.Unfreeze,
                addressList,
                amount
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).unfreeze(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {lock} operation in the Collypto contract, 
     * locking the Ethereum account at `targetAddress` and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if it violates any of the rules in the {lock} function of the Collypto
     * contract.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */        
    function lock(address targetAddress)
        public
        isAuthorized(OperatorClasses.Lock)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;     
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.Lock,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).lock(targetAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unlock} operation in the Collypto contract, 
     * unlocking the Ethereum account at `targetAddress` and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if it violates any of the rules in the {unlock} function of the Collypto
     * contract.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */   
    function unlock(address targetAddress)
        public
        isAuthorized(OperatorClasses.Unlock)
        returns (uint256 proposalId, bool executed)
    {        
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Unlock, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).unlock(targetAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {mint} operation in the Collypto contract, 
     * minting `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the {mint}
     * function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account where credits
     * will be minted
     * @param amount The total number of credits (in slivers) to be minted
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */       
    function mint(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Mint)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;               
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Mint, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).mint(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }     

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {burn} operation in the Collypto contract, 
     * burning `amount` slivers in the Ethereum account at `targetAddress` and
     * emits a {ProposalCreated} event upon proposal creation, {ApprovalAdded}
     * events for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted utility function. This operation will revert
     * if any of the provided arguments violates any of the rules in the {burn}
     * function of the Collypto contract.
     * @param targetAddress The address of the Ethereum account where credits
     * will be burned
     * @param amount The total number of credits (in slivers) to be burned
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function burn(address targetAddress, uint256 amount)
        public
        isAuthorized(OperatorClasses.Burn)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;        
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Burn, addressList, amount);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).burn(targetAddress, amount)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct a {pause} operation in the Collypto contract,
     * blocking all standard (non-view) user operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if its timing would violate any of the rules in
     * the {pause} function of the Collypto contract.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */   
    function pause()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;       
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Pause, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, Collypto(_collyptoAddress).pause());
        } else {
            return (updatedProposal.id, false);
        }        
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to conduct an {unpause} operation in the Collypto
     * contract, unblocking all standard (non-view) user operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if its timing would violate any of the rules in
     * the {unpause} function of the Collypto contract.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */      
    function unpause()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;       
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(operator, Operations.Unpause, addressList, 0);

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, Collypto(_collyptoAddress).unpause());
        } else {
            return (updatedProposal.id, false);
        } 
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to add the manager account at address `managerAddress` to
     * the manager list of the Collypto contract and emits a {ProposalCreated}
     * event upon proposal creation, {ApprovalAdded} events for each additional
     * approval, and a {ProposalExecuted} event upon execution
     * @dev This is a restricted management function. This operation will
     * revert if {managerAddress} is the zero address or violates any of the
     * rules in the {addManager} function of the Collypto contract.
     * @param managerAddress The address of the Ethereum account to be added to
     * the manager list of the Collypto contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function addManager(
        address managerAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {        
        // Cannot add the zero address to the manager list
        require(managerAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = managerAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.AddManager,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).addManager(managerAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove the manager account at address `managerAddress`
     * from the manager list of the Collypto contract and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert if {managerAddress} is the zero address or violates any of the
     * rules in the {removeManager} function of the Collypto contract.
     * @param managerAddress The address of the Ethereum account to be removed
     * from the manager list of the Collypto contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function removeManager(
        address managerAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {        
        // Cannot remove the zero address from the manager list
        require(managerAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = managerAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveManager,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                Collypto(_collyptoAddress).removeManager(managerAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to update the reference address of the Collypto contract
     * to `targetAddress` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} and a {CollyptoAddressUpdated} event upon execution
     * @dev This is a restricted management function.
     * @param targetAddress The updated reference address of the Collypto
     * contract
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function updateCollyptoAddress(address targetAddress)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        address operator = msg.sender;  
        address[] memory addressList = new address[](1);
        addressList[0] = targetAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.UpdateCollyptoAddress,
                addressList,
                0
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _updateCollyptoAddress(targetAddress));
        } else {
            return (updatedProposal.id, false);
        } 
    }    

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove the active {Proposal} record with an {id} value
     * of `proposalId` and emits a {ProposalCreated} event upon proposal
     * creation, {ApprovalAdded} events for each additional approval, and a
     * {ProposalExecuted} and a {ProposalRemoved} event upon execution
     * @dev This is a restricted management function. This function
     * automatically removes the removal {Proposal} record itself from the
     * active proposals list and mapping once its underlying removal operation
     * is executed. This operation will revert upon execution if any of the
     * provided arguments violates any of the rules in the {_removeOperator}
     * function.
     * @param proposalId The {id} value of the {Proposal} record to be removed
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function removeProposal(uint256 id)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveProposal,
                addressList,
                id
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _removeProposal(id, false));
        } else {
            return (updatedProposal.id, false);
        } 
    }

    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to purge all active {Proposal} records and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} and a
     * {ProposalsPurged} event upon execution
     * @dev This is a restricted management function.
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */ 
    function purgeProposals()
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {       
        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.PurgeProposals,
                addressList,
                0
            );

        if (hasMajority) {
            emit ProposalExecuted(updatedProposal.id, updatedProposal.index);
            return (updatedProposal.id, _purgeProposals());
        } else {
            return (updatedProposal.id, false);
        } 
    }
    
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to authorize the operator at address `operatorAddress` to
     * conduct `operatorClass` operations and emits a {ProposalCreated} event
     * upon proposal creation, {ApprovalAdded} events for each additional
     * approval, and a {ProposalExecuted} and an {OperatorAdded} event upon
     * execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value, `operatorAddress` is the zero address, or if
     * any of the provided arguments violates any rules in the {_addOperator}
     * function.
     * @param operatorClass The operator class authorization to be assigned to
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to be
     * authorized to conduct operations of class {operatorClass}
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */     
    function addOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Specified operator class must be a valid operator class 
        require(_isValidOperatorClass(operatorClass));
        
        // New operator address cannot be the zero address
        require(operatorAddress != address(0));

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = operatorAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.AddOperator,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (
                updatedProposal.id,
                _addOperator(operatorClass, operatorAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }
       
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to remove authorization for the operator at
     * `operatorAddress` to conduct `operatorClass` operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event, a variable
     * number of {ProposalRemoved} and {ApprovalRevoked} events (depending on
     * the number of active proposals approved by the operator at
     * `operatorAddress`), and an {OperatorRemoved} event upon execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value, `operatorAddress` is the zero address, or if
     * any of the provided arguments violates any of the rules in the
     * {_removeOperator} function.
     * @param operatorClass The operator class authorization to be removed from
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to remove
     * authorization to conduct operations of class {operatorClass}
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */        
    function removeOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Specified operator class must be a valid operator class
        require(_isValidOperatorClass(operatorClass));
        
        // Operator address cannot be the zero address
        require(operatorAddress != address(0));

        address operator = msg.sender;         
        address[] memory addressList = new address[](1);
        addressList[0] = operatorAddress;

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.RemoveOperator,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);        
            return (
                updatedProposal.id,
                _removeOperator(operatorClass, operatorAddress)
            );
        } else {
            return (updatedProposal.id, false);
        }  
    }
    
    /**
     * @notice Submits, approves, or executes a proposal (depending on majority
     * requirements) to purge authorization for all currently authorized
     * operators to conduct `operatorClass` operations and emits a
     * {ProposalCreated} event upon proposal creation, {ApprovalAdded} events
     * for each additional approval, and a {ProposalExecuted} event, a variable
     * number of {ProposalRemoved} events (depending on the number of active
     * proposals corresponding to `operatorClass`) and an {OperatorsPurged}
     * event upon execution
     * @dev This is a restricted management function. This operation will
     * revert upon execution if `operatorClass` does not correspond to a valid
     * {OperatorClasses} value or `operatorClass` is "Prime".
     * @param operatorClass The operator class authorization to be purged
     * @return proposalId The {id} value of the {Proposal} record generated or
     * approved by the current operator
     * @return executed A Boolean value indicating whether the proposal was
     * executed
     */           
    function purgeOperators(OperatorClasses operatorClass)
        public
        isAuthorized(OperatorClasses.Prime)
        returns (uint256 proposalId, bool executed)
    {
        // Cannot purge operators from an invalid operator class
        require(_isValidOperatorClass(operatorClass));
        
        // Cannot purge Prime operators
        require(operatorClass != OperatorClasses.Prime);

        address operator = msg.sender;
        address[] memory addressList = new address[](1);
        addressList[0] = address(this);

        bool hasMajority;
        Proposal memory updatedProposal;
        (updatedProposal, hasMajority) =
            _submitProposal(
                operator,
                Operations.PurgeOperators,
                addressList,
                uint256(operatorClass)
            );

        if (hasMajority) {
            _removeProposal(updatedProposal.id, true);
            return (updatedProposal.id, _purgeOperators(operatorClass));
        } else {
            return (updatedProposal.id, false);
        }  
    }

    /**
     * @dev This function revokes approval of the operator at `operator` for
     * the proposal with an {id} value of `proposalId` and emits an
     * {ApprovalRevoked} event. This operation will revert if there is no
     * active proposal with an {id} value of `proposalId` or the current
     * operator has not authorized the target proposal.
     * @param proposalId The {id} value of the {Proposal} record where approval
     * will be revoked for {operator}
     * @param operator The address of the Etheruem account of the operator
     * whose approval will be revoked
     * @return success A Boolean value indicating whether the approval was
     * revoked successfully
     */
    function _revokeApproval(uint256 proposalId, address operator)
        internal
        returns (bool success)
    {
        // Proposal must exist with the {id} value specified
        require(_proposalExists(proposalId));
        
        Proposal storage targetProposal = _proposalMap[proposalId];
       
        // Operator must have already approved the specified proposal
        require(_hasApproved[proposalId][operator]);

        _hasApproved[proposalId][operator] = false;

        uint256 totalApprovers = targetProposal.approvers.length;

        for (uint256 i = 0; i < totalApprovers; i++) {
            if (targetProposal.approvers[i] == operator) {                                    
                uint256 lastApproverIndex = totalApprovers - 1;

                if ((totalApprovers > 1) && (i != lastApproverIndex)) {
                    targetProposal.approvers[i] =
                        targetProposal.approvers[lastApproverIndex];
                }
                
                targetProposal.approvers.pop();
                
                emit ApprovalRevoked(proposalId, operator); 

                return true;
            }              
        }

        return false;
    }

    /**
    * @dev This function updates the reference address of the Collypto contract
    * in {_collyptoAddress} to `contractAddress` and emits a
    * {CollyptoAddressUpdated} event.
    * @param contractAddress The updated reference address of the Collypto
    * contract
    * @return success A Boolean value indicating that the reference address of
    * the Collypto contract has been updated successfully 
    */
    function _updateCollyptoAddress(address contractAddress)
        internal
        returns (bool success)
    {
        _collyptoAddress = contractAddress;

        emit CollyptoAddressUpdated(contractAddress);

        return true;
    }

    /**
     * @dev This function returns a Boolean value indicating whether an active
     * {Proposal} record exists with an {id} value of `proposalId`.
     * @param proposalId The {id} value of the target {Proposal} record
     * @return exists A Boolean value indicating whether there is an active
     * {Proposal} record with the {id} value of {proposalId}
     */
    function _proposalExists(uint256 proposalId)
        internal
        view
        returns (bool exists)
    {
        return _proposalMap[proposalId].id > 0;
    }

    /**
     * @dev This function evaluates and returns an integer representing the
     * a unique proposal {id} created using a deterministic hash of the input
     * values.
     * @param operation The {Operations} value of the proposal operation
     * @param addresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return id An integer value representing the {id} value of a unique
     * {Proposal} record
     */
    function _getProposalId(
        Operations operation,
        address[] memory addresses,
        uint256 data
    )
        internal
        pure
        returns (uint256 id)
    {
        return uint256(
            keccak256(abi.encodePacked(operation, addresses, data))
        );
    }

    /**
     * @dev This function composes a proposal for the `operation` using the
     * input arguments provided, creates a unique {Proposal} record
     * encapsulating that data, emits a {ProposalCreated} event. This operation
     * will revert if there is already an active {Proposal} record with an {id}
     * value that would be identical to the {id} value of the proposal to be
     * created.
     * @param creatorAddress The address of the Ethereum account used to create
     * the proposal
     * @param operation The {Operations} value of the proposal operation
     * @param addresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return id An integer value representing the {id} value of the unique
     * {Proposal} record created by this operation
     */
    function _createProposal(
        address creatorAddress,
        Operations operation,
        address[] memory addresses,
        uint256 data
    )
        internal
        returns (uint256 id)
    {
        uint256 proposalId = _getProposalId(operation, addresses, data);

        // Cannot create redundant proposals
        require(!_proposalExists(proposalId));

        address[] memory approvers = new address[](1);
        approvers[0] = creatorAddress;

        _hasApproved[proposalId][creatorAddress] = true;

        // Create proposal object and add to proposal mapping table
        _proposalMap[proposalId] = Proposal({
            id : proposalId,
            index: ++_currentProposalIndex,
            operation: operation,
            addressList: addresses,
            data: data,
            approvers: approvers
        });

        // Add proposal {id} to proposal array
        _proposalList.push(proposalId);

        emit ProposalCreated(
            proposalId,
            _currentProposalIndex,
            creatorAddress
        );

        return proposalId;
    }    
    
    /**
     * @dev This function submits a proposal with the input arguments provided,
     * and emits either an {ApprovalAdded} or a {ProposalCreated} event
     * (depending on whether the resulting {Proposal} record already existed).
     * This operation will revert if the operator at `operatorAddress` has
     * already approved the proposal being submitted or if any input arguments
     * violate rules in the {_createProposal} function.
     * @param operatorAddress The Ethereum address of the operator submitting
     * the current proposal
     * @param operation The {Operations} value of the operation to be executed
     * by the current proposal
     * @param targetAddresses The ordered list of addresses acted upon in the
     * proposal
     * @param data An integer value representing the deterministic hash of
     * ordered proposal data
     * @return proposal The {Proposal} record generated or approved by the
     * current operator
     * @return hasMajority A Boolean value indicating whether the current
     * proposal has a majority of approvers
     */
    function _submitProposal(
        address operatorAddress,
        Operations operation,
        address[] memory targetAddresses,
        uint256 data
    )
        internal
        returns (Proposal memory proposal, bool hasMajority)
    {
        uint256 proposalId = _getProposalId(operation, targetAddresses, data);

        if (!_proposalExists(proposalId)) {
            // Create proposal and add operator address to the approvals list
            _createProposal(operatorAddress, operation, targetAddresses, data);
        } else { // Add operator address to approvals if it isn't on the list           
            Proposal storage storedProposal = _proposalMap[proposalId];
            
            // Current operator cannot approve the same proposal twice
            require(!_hasApproved[proposalId][operatorAddress]);
        
            // Approve proposal for current operator
            _hasApproved[proposalId][operatorAddress] = true;

            // Add operator to list of approvers
            storedProposal.approvers.push(operatorAddress);

            emit ApprovalAdded(proposalId, operatorAddress);
        }

        uint256 requiredMajority =
            (_authorizedOperatorList
                [_getRequiredOperatorClass(operation)].length / 2) + 1;
        uint256 currentApprovers = _proposalMap[proposalId].approvers.length;
        Proposal memory currentProposal = _proposalMap[proposalId];

        return (currentProposal, (currentApprovers >= requiredMajority));
    }

    /**
     * @dev This function removes the {Proposal} record with an {id} value of
     * `proposalId` and emits either a {ProposalExecuted} or {ProposalRemoved}
     * event, depending on the value of {executed}. This operation will revert
     * if there is no active proposal with an {id} value of {proposalId}.
     * @param proposalId The {id} value of the {Proposal} record to be removed
     * @param executed A Boolean value indicating whether the proposal
     * operation was executed
     * @return success A Boolean value indicating whether the proposal was
     * successfully removed from the proposal list and mapping
     */
    function _removeProposal(uint256 proposalId, bool executed)
        internal
        returns (bool success)
    {
        // Proposal must exist with the {id} value specified
        require(_proposalExists(proposalId));

        for (uint256 i = 0; i < _proposalList.length; i++) {
            if (_proposalList[i] == proposalId) {
                // Save location of last proposal in proposal list
                uint256 lastProposalIndex = _proposalList.length - 1;

                // Reset approver mappings for the proposal
                for (
                    uint256 j = 0;
                    j < _proposalMap[proposalId].approvers.length;
                    j++
                ) {                  
                    _hasApproved
                        [proposalId]
                        [_proposalMap[proposalId].approvers[j]] = false;
                }

                // Save proposal index before removal
                uint256 proposalIndex = _proposalMap[proposalId].index;
                
                // Remove proposal from the proposal mapping
                delete _proposalMap[proposalId];

                // Overwrite the proposal with the last proposal in the
                // proposal list
                if ((_proposalList.length > 1) && (i != lastProposalIndex)) {
                    _proposalList[i] = _proposalList[lastProposalIndex];
                }
                
                // Remove the redundant last proposal from the proposal list
                _proposalList.pop();

                if (executed) {
                    emit ProposalExecuted(proposalId, proposalIndex);
                } else {
                    emit ProposalRemoved(proposalId, proposalIndex);
                }

                return true;
            }
        }

        return false;
    }

    /**
     * @dev This function purges all active {Proposal} records and emits a
     * {ProposalsPurged} event.
     * @return success A Boolean value indicating that all proposals have been
     * purged successfully from {_proposalList} and {_proposalMap}
     */ 
    function _purgeProposals() internal returns (bool success) {
        for (uint256 i = 0; i < _proposalList.length; i++) {
            uint256 proposalId = _proposalList[i];

            for (
                uint256 j = 0;
                j < _proposalMap[proposalId].approvers.length;
                j++
            ) {
                _hasApproved
                    [proposalId]
                    [_proposalMap[proposalId].approvers[j]] = false;
            }

            delete _proposalMap[proposalId];                
        }

        delete _proposalList;

        emit ProposalsPurged();

        return true;
    }

    /**
     * @dev This function authorizes the operator at address `operatorAddress`
     * to conduct `operatorClass` operations and emits an {OperatorAdded}
     * event. This operation will revert if `operatorAddress` is already listed
     * as an authorized `operatorClass` operator.
     * @param operatorClass The operator class authorization to be assigned to
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account of the
     * operator to be authorized to conduct operations of class {operatorClass}
     * @return success A Boolean value indicating that the operator at
     * {operatorAddress} was successfully authorized to conduct {operatorClass}
     * operations
     */   
    function _addOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        internal
        returns (bool success)
    {
        address[] storage currentOperatorAddresses =
            _authorizedOperatorList[operatorClass];
        
        // Operator address cannot already be authorized for {operatorClass}
        require(!_authorizedOperatorMap[operatorClass][operatorAddress]);

        _authorizedOperatorMap[operatorClass][operatorAddress] = true;
        
        currentOperatorAddresses.push(operatorAddress);

        emit OperatorAdded(uint256(operatorClass), operatorAddress);

        return true;
    }

    /**
     * @dev This function removes authorization for the operator at address
     * `operatorAddress` to conduct `operatorClass` operations and emits a
     * variable number of {ProposalRemoved} and {ApprovalRevoked} events
     * (depending on the number of active proposals approved by the operator at
     * `operatorAddress`) and an {OperatorRemoved} event. This operation will
     * revert if the operator at `operatorAddress` is not currently authorized
     * to conduct operations of class `operatorClass`.
     * @param operatorClass The operator class authorization to be removed from
     * the operator at {operatorAddress}
     * @param operatorAddress The address of the Ethereum account to remove
     * authorization to conduct operations of class {operatorClass}
     * @return success A Boolean value indicating that {operatorClass}
     * authorization was successfully removed from the operator at
     * {operatorAddress}
     */
    function _removeOperator(
        OperatorClasses operatorClass,
        address operatorAddress
    )
        internal
        returns (bool success)
    {     
        // Operator must be on the authorization list for the class specified
        require(_authorizedOperatorMap[operatorClass][operatorAddress]);

        address[] storage operatorAddresses =
            _authorizedOperatorList[operatorClass];
        
        for (uint256 i = 0; i < operatorAddresses.length; i++) {
            if (operatorAddresses[i] == operatorAddress) {
                _authorizedOperatorMap[operatorClass][operatorAddresses[i]] =
                    false;
                
                uint256 lastOperatorIndex = operatorAddresses.length - 1;

                if (
                    (operatorAddresses.length > 1) &&
                    (i != lastOperatorIndex)
                ) {
                    operatorAddresses[i] =
                        operatorAddresses[lastOperatorIndex];
                }
                             
                operatorAddresses.pop();

                for (uint256 j = 1; j <= _proposalList.length; j++) {                
                    uint256 proposalId = _proposalList[j - 1];

                    if (_hasApproved[proposalId][operatorAddress]) {                        
                        if (_proposalMap[proposalId].approvers.length == 1) {
                            // This proposal has no other approvers, so remove
                            // it and continue searching
                            _removeProposal(proposalId, false);

                            // Decrement j to account for swap during removal
                            // if any proposals remain
                            if (_proposalList.length > 0) {
                                j--;
                            }
                        } else {
                            // Other operators have approved this proposal, so
                            // only remove the current operator from approvers
                            _revokeApproval(proposalId, operatorAddress);
                        }                  
                    }                
                }

                emit OperatorRemoved(uint256(operatorClass), operatorAddress);

                return true;
            }
        }

        return false;
    }

    /**
     * @dev This function purges authorization for all currently authorized
     * operators to conduct `operatorClass` operations and emits a variable
     * number of {ProposalRemoved} events (depending on the number of active
     * proposals corresponding to `operatorClass`) and an {OperatorsPurged}
     * event.
     * @param operatorClass The operator class to be purged
     * @return success A Boolean value indicating that {operatorClass}
     * authorization has been removed from all operators
     */   
    function _purgeOperators(OperatorClasses operatorClass)
        internal
        returns (bool success)
    {
        for (
            uint256 i = 0;
            i < _authorizedOperatorList[operatorClass].length;
            i++
        ) {
            _authorizedOperatorMap
                [operatorClass]
                [_authorizedOperatorList[operatorClass][i]] = false;
        }

        delete _authorizedOperatorList[operatorClass];

        for (uint256 j = 1; j <= _proposalList.length; j++) {
            uint256 proposalId = _proposalList[j - 1];
            if (
                _getRequiredOperatorClass(
                    _proposalMap[proposalId].operation
                ) == operatorClass
            ) {
                // Remove proposal and keep searching
                _removeProposal(proposalId, false);

                // Decrement j to account for swap during removal
                // if any proposals remain
                if (_proposalList.length > 0) {
                    j--;
                }
            }
        }

        emit OperatorsPurged(uint256(operatorClass));

        return true;
    }

    /**
     * @dev This function returns the required {OperatorClasses} authorization
     * that an operator must have to conduct `operation`. This operation will
     * revert if `operation` does not correspond to a valid {Operations} value.
     * @param operation The {Operations} value corresponding to the operation 
     * that will be checked for operator class requirement
     * @return operatorClass The required {OperatorClasses} authorization that
     * an operator must have to conduct the provided {operation}
     */
    function _getRequiredOperatorClass(Operations operation)
        internal
        pure
        returns (OperatorClasses operatorClass)
    {
        if (
            (operation == Operations.Pause) ||
            (operation == Operations.Unpause) ||
            (operation == Operations.AddManager) ||
            (operation == Operations.RemoveManager) ||
            (operation == Operations.RemoveProposal) ||
            (operation == Operations.PurgeProposals) ||
            (operation == Operations.AddOperator) ||
            (operation == Operations.RemoveOperator) ||
            (operation == Operations.PurgeOperators) ||
            (operation == Operations.UpdateCollyptoAddress)
        ) {
            return OperatorClasses.Prime;
        } else if (operation == Operations.ForceTransfer) {
            return OperatorClasses.Dispatch;
        } else if (operation == Operations.SetUserStatus) {
            return OperatorClasses.Arbiter;
        } else if (operation == Operations.Freeze) {
            return OperatorClasses.Freeze;
        } else if (operation == Operations.Unfreeze) {
            return OperatorClasses.Unfreeze;
        } else if (operation == Operations.Lock) {
            return OperatorClasses.Lock;
        } else if (operation == Operations.Unlock) {
            return OperatorClasses.Unlock;
        } else if (operation == Operations.Mint) {
            return OperatorClasses.Mint;
        } else if (operation == Operations.Burn) {
            return OperatorClasses.Burn;
        }

        // Specified operation is invalid
        revert();
    }

    /**
     * @dev This function determines whether `operatorClass` is a valid value
     * of the {OperatorClasses} enumeration and returns a Boolean value
     * indicating its validity.
     * @param operatorClass The operator class to be validated
     * @return valid A Boolean value indicating whether the {operatorClass} is
     * a valid operator class and member of the {OperatorClasses} enumeration
     */
    function _isValidOperatorClass(OperatorClasses operatorClass)
        internal
        pure
        returns (bool valid)
    {
        uint256 operatorClassIndex = uint256(operatorClass);
        
        if ((operatorClassIndex < 0) || (operatorClassIndex > 8)) {
            return false;
        }

        return true;
    }
}

// SPDX-License-Identifier: copyleft-next-0.3.1
// Collypto Contract v1.0.0
pragma solidity ^0.8.17 < 0.9.0;

/**
 * @dev Interface of the complete ERC-20 standard with all events, required
 * functions, and optional functions, as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Standard transfer event emitted when `amount` tokens are moved from
     * one account at `from` to another account at `to`
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @dev Standard approval event emitted when an allowance has been modified
     * to `amount` for the account at `spender` to spend on behalf of the
     * account at `owner`
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );

    /**
     * @dev Returns the name of the token
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token
     */
    function symbol() external view returns (string memory);
    
    /**
     * @dev Returns the number of decimals the token uses
     */
    function decimals() external view returns (uint8);
    
    /**
     * @dev Returns the total token supply
     */   
    function totalSupply() external view returns (uint256);
    
    /**
     * @dev Returns the balance of the account at `owner`
     */ 
    function balanceOf(address owner) external view returns (uint256);
    
    /**
     * @dev Transfers `amount` tokens from the operator's account to the
     * account at `to`
     */    
    function transfer(address to, uint256 amount) external returns (bool);
    
    /**
     * @dev Transfers `amount` tokens from the account at `from` to the account
     * at `to`
     */        
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool); 

    /**
     * @dev Allows the account at `spender` to withdraw from the operator's
     * account multiple times, up to a total of `amount` tokens
     */      
    function approve(address spender, uint256 amount) external returns (bool);
    
    /**
     * @dev Returns the amount which the account at `spender` is still allowed
     * to withdraw from the account at `owner`
     */     
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);   
}

/**
 * @title Collypto
 * @author Matthew McKnight - Collypto Technologies, Inc.
 * @notice This contract contains all core Collypto features that are available
 * on the Ethereum blockchain. 
 * @dev This contract is the implementation of Collypto's ERC-20 contract and
 * extended functions.
 * 
 * OVERVIEW
 * We have followed general best practices of OpenZeppelin and Solidity,
 * including operation reversion on failure, allowance support functions and
 * events, and an upgradable contract structure that utilizes an initializer
 * function instead of a constructor. In addition to the required and verified
 * versions of standard ERC-20 operations and extended operations, we have also
 * included functionality for minting and burning tokens, freezing and
 * unfreezing tokens, locking and unlocking Ethereum accounts, pausing and
 * unpausing this contract, and forcibly transferring tokens, in addition to
 * our other enhanced management and ownership operations. We have also
 * included a complete user status model that represents the off-chain status
 * of an address owner in our internal systems, as well as operations to allow
 * us to update the user status of Ethereum accounts and provide public
 * visibility of Ethereum account status.
 *
 * VERIFIED OPERATIONS ({verifiedTransfer}, {verifiedTransferFrom},
 * {verifiedApprove}, {verifiedIncreaseAllowance}, {verifiedDecreaseAllowance})
 * In addition to implementing all required ERC-20 functions and extended
 * functions, Collypto also provides users with "verified" versions of all
 * public token operations. Any call to one of these functions requires the
 * recipient (or target address) to be in the "Verified" status (corresponding
 * to a medallion account), otherwise the operation will revert.
 *
 * UTILITY OPERATIONS ({updateUserStatus}, {forceTransfer}, {freeze},
 * {unfreeze}, {lock}, {unlock}, {mint}, {burn})
 * The Collypto contract contains eight utility operations that correspond to
 * stratified sets of operator classes used to conduct transactions through the
 * multiplexed access controls of our management contract account. These
 * functions will only by utilized by authorized systems and representatives of
 * Collypto Technologies and will never be available to the public.
 *
 * USER STATUS ({updateUserStatus})
 * Collypto maintains a {UserStatus} record for every possible Ethereum account
 * in the {_userStatuses} mapping, and each corresponding {UserStatus} record
 * contains exactly two properties: {status} and {info}. The {status} value of
 * a {UserStatus} record defaults to "Unknown", and the {info} value defaults
 * to an empty string. 
 * 
 * We refer to a user's primary verified Ethereum account as their "medallion",
 * and upon receiving a request for verification from a user, we will update
 * the {status} value of their Medallion address to "Pending" as we conduct the
 * address validation and customer verification process. When the user has
 * completed our KYC verification process and they have verified ownership of
 * their Medallion address, we will change the {status} value of its
 * corresponding {UserStatus} record to "Verified", and we will change the
 * {info} value of its {UserStatus} record to a string in the format
 * {'creationDate':'yyyy-MM-dd','expirationDate':'yyyy-MM-dd','message':''},
 * where {creationDate} and {expirationDate} are dates represented as strings
 * in ISO 8601 standard date format.
 * 
 * The value of {creationDate} represents the original issue date of the
 * account owner's medallion certification, the value of {expirationDate}
 * represents the last day the medallion will be valid before its owner will
 * need to reverify their identity, and {message} is an optional property that
 * we can use to send an on-chain message to the owner of any Ethereum account.
 * Users may register other non-medallion Ethereum accounts in our off-chain
 * internal systems, but those accounts will remain in the "Unknown" {status},
 * and the value of their {info} property will remain an empty string.
 * {creationDate} and {expirationDate} properties will never be included in the
 * {info} value of non-medallion accounts.
 *
 * In addition to the verification model, we have also included functionality
 * to mark accounts as "Suspect" or "Blacklisted" if they are implicated in
 * criminal activity, government sanctions, or other violations of our Terms of
 * Service. Our internal blacklist will contain both Ethereum addresses and
 * known malicious actors, and Ethereum accounts with a {status} of
 * "Blacklisted" will automatically be locked and unable to send tokens,
 * receive tokens, or perform allowance operations.
 *
 * FORCE TRANSFER ({forceTransfer})
 * The {forceTransfer} function allows us to forcibly transfer credits (that
 * were stolen or fraudulently obtained) from a malicious actor's Ethereum
 * account back to the Ethereum account of a victim without corrupting the
 * collateralization state of our system.
 * 
 * FREEZE/UNFREEZE ({freeze}, {unfreeze})
 * In addition to the standard {_balances} mapping for Ethereum account token
 * balances, we also include the {_frozenBalances} property which is used to
 * represent the total frozen tokens in a user's Ethereum account. The total
 * frozen tokens will never exceed the Ethereum account balance. This
 * functionality allows us to freeze a specified amount of credits during an
 * investigation or government sanction, and it facilitates the "Limited
 * Freeze" feature of our Virtual Cold Storage (VCS) service for verified
 * users. Frozen tokens can only be unfrozen by our management account, which
 * provides an additional layer of security to traditional cold storage.
 * 
 * LOCK/UNLOCK ({lock}, {unlock})
 * As an additional security feature, we maintain the {_lockedAddresses}
 * mapping for both blacklisted accounts and the "Complete Lock" feature of our
 * VCS service for verified users. Locking an Ethereum account prevents it from
 * sending tokens, receiving tokens, or performing allowance operations. The
 * lock feature allows us to provide the "Complete Lock" feature of our VCS
 * service for verified users (in addition to its application for blacklisted
 * Ethereum accounts). As with frozen tokens, locked accounts can only be
 * unlocked by our management account, which provides an additional layer of
 * security to traditional cold storage.
 *
 * MINT/BURN ({mint}, {burn})
 * We have implemented standard mint and burn functions with {Transfer} events
 * to and from the zero address in addition to their respective {Mint} and
 * {Burn} events. Tokens will only be minted and burned by our management
 * account, and uncollateralized tokens will never enter circulation. Both mint
 * and burn operations may be conducted on any target account, rather than a
 * hard-coded vault account, which allows us the flexibility to change our
 * vault location without requiring an update to this contract. Minted tokens
 * are always unfrozen by default, and frozen tokens cannot be burned without
 * first being unfrozen.
 *
 * CONTRACT MANAGEMENT
 * Instead of utilizing a traditional ownership model, Collypto utilizes a
 * stratified management structure for contract management operations and the
 * transfer of management power in the event of an update or compromise of our
 * management contract.
 * 
 * MANAGEMENT OPERATIONS ({pause}, {unpause}, {addManager}, {removeManager})
 * In addition to the utility operations listed previously, this contract
 * contains four management operations that facilitate disaster recovery and
 * allow us to securely update our management contract. These functions will
 * only be utilized by authorized systems and representatives of Collypto
 * Technologies and will never be available to the public.
 * 
 * PAUSE/UNPAUSE ({pause}, {unpause})
 * This contract includes functionality to pause and unpause all non-view user
 * transactions. This is essential in the event of a security breach and allows
 * us to mitigate the damage that could otherwise be caused by a malicious
 * actor or institution. Any majority key compromise of our management contract
 * that is Category 3 or above would require us to pause the contract to
 * rectify the situation and reverse all malicious transactions. The running
 * state of this contract is maintained in the {_isRunning} Boolean property,
 * which defaults to "false" until the contract is initialized.
 * 
 * SECURE MANAGEMENT TRANSFER ({addManager}, {removeManager})
 * In order to allow our management contract to be upgradable, this contract
 * includes functions to add and remove a single manager address from the
 * {_managerAddresses} array (the manager list). These functions can only be
 * called by a management account, which includes the Master address
 * (maintained in the {_ownerAddress} property of this contract). The Master
 * address cannot be updated or removed by a standard management account.
 * 
 * Management transfers utilize the {addManager} and {removeManager} functions
 * to ensure that the new management account address is added to the manager
 * list before the old one is removed, and a manager account cannot remove
 * itself from the manager list. This means that, unlike the traditional
 * ownership model, it is impossible for our team or systems to accidentally
 * lose control of this contract by accidentally typing in the wrong address
 * value for the new management contract account. With the exception of
 * contract updates, the manager list will only ever contain a single address
 * value stored at {_managerAddresses[0]} (the management contract address) for
 * support operations.
 * 
 * CONTRACT OWNERSHIP
 * Collypto maintains an additional layer of security beyond the level of our
 * management account, and that is the Master address maintained in the
 * {_ownerAddress} property of this contract. In addition to being able to
 * conduct management operations, the Master address can also conduct three
 * additional operations to initialize this contract and provide recourse for
 * disaster recovery (up to and including a Category 1 breach). These functions
 * will only by utilized by authorized systems and representatives of Collypto
 * Technologies and will never be available to the public.
 * 
 * PURGE MANAGERS ({purgeManagers})
 * In the event that the majority of Prime keys that control the management
 * contract are compromised, the Master account can be used to purge all
 * management addresses from the manager list using the {purgeManagers}
 * function. At this point, we would need to deploy a new instance of the
 * management contract, and we would then use the Master account to add the
 * management contract address to the manager list. 
 * 
 * CONTRACT "TERMINATION" ({terminateContract})
 * In the event that the Master key itself is compromised, it can still be used
 * to call the {terminateContract} function, which clears the manager list,
 * resets the value of {_ownerAddress} (the Master address) to the zero
 * address, resets the value of {_isInitialized} to "false", and pauses the
 * contract. At this point, we would need to use the Admin account to update
 * this contract with a new value for the {_ownerAddress} (the address of the
 * new Master account), and we would need to use the new Master account to
 * reinitialize this contract with a new address for the updated management
 * contract.
 * 
 * CONTRACT INITIALIZATION ({initialize})
 * As previously stated, this contract is upgradable, and its storage model is
 * compliant with OpenZeppelin upgradable contract requirements. The storage
 * model of this contract has been optimized for our solution requirements, and
 * this contract utilizes an initializer function, rather than a constructor,
 * to define its name, symbol, owner, and management address. The
 * initialization state of this contract is maintained in the {_isInitialized}
 * Boolean property, which defaults to "false" until this contract is
 * initialized. The initialization counter of this contract is maintained in
 * the {_initializationIndex} property, which allows us to track how many times
 * it has been updated and defaults to zero until this contract is first
 * initialized.
 */
contract Collypto is IERC20 {
    /**
     * @dev Enumeration containing all valid values of the {status} property
     * that can be assigned in the {UserStatus} record of an Ethereum account
     */
    enum Statuses { Unknown, Pending, Verified, Suspect, Blacklisted }

    /**
     * @dev Struct that allows us to maintain on-chain user status records for
     * verification, internal investigations, and blacklisting
     */
    struct UserStatus {
        Statuses status; // Defaults to "Unknown" (zero value)
        string info; // Defaults to empty string value
    }

    /**
     * @dev Mapping of all Ethereum account balances (in slivers) (indexed by
     * account address)
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Mapping of all frozen balances (in slivers) (indexed by Ethereum
     * account address)
     */    
    mapping(address => uint256) private _frozenBalances;

    /**
     * @dev Mapping of all allowances (in slivers) (indexed by owner and
     * spender Ethereum account address)
     */
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev Mapping of the lock state of all Ethereum accounts (indexed by
     * account address)
     */
    mapping(address => bool) private _lockedAddresses;

    /**
     * @dev Mapping of {UserStatus} records of all Ethereum accounts (indexed
     * by account address)
     */    
    mapping(address => UserStatus) private _userStatuses;
    
    /// @dev Current address of the Master account
    address private _ownerAddress;

    /// @dev Current list of management account addresses (the manager list)
    address[2] private _managerAddresses;

    /**
     * @dev Total supply of credits (in slivers) that currently exists on the
     * Ethereum blockchain
     */
    uint256 private _totalSupply;

    /// @dev Name of the token defined in this contract
    string private _name;

    /// @dev Ticker symbol for the token defined in this contract
    string private _symbol;

    /// @dev Running state of this contract (defaults to "false")
    bool private _isRunning;

    /// @dev Initialization state of this contract (defaults to "false")
    bool private _isInitialized;

    /// @dev Initialization index of this contract (defaults to zero)
    uint256 private _initializationIndex;

    /**
     * @dev Utility event emitted when the {UserStatus} record of the Ethereum
     * account at `owner` is updated to contain a {status} value of `status`
     * and an {info} value of `info`
     */      
    event UpdateUserStatus(
        address indexed owner,
        Statuses status,
        string info
    );

    /**
     * @dev Utility event emitted when `amount` slivers are forcibly moved from
     * the Ethereum account at `from` to the account at `to`
     */      
    event ForceTransfer(
        address indexed from,
        address indexed to,
        uint256 amount
    );

    /**
     * @dev Utility event emitted when `amount` slivers are frozen in the
     * Ethereum account at `owner`
     */   
    event Freeze(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when `amount` slivers are unfrozen in the
     * Ethereum account at `owner`
     */   
    event Unfreeze(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when the Ethereum account at `owner` is
     * locked
     */   
    event Lock(address indexed owner);

    /**
     * @dev Utility event emitted when the Ethereum account at `owner` is
     * unlocked
     */  
    event Unlock(address indexed owner);
    
    /**
     * @dev Utility event emitted when `amount` slivers are minted in the
     * Ethereum account at `owner`
     */      
    event Mint(address indexed owner, uint256 amount);

    /**
     * @dev Utility event emitted when `amount` slivers are burned in the
     * Ethereum account at `owner`
     */
    event Burn(address indexed owner, uint256 amount);
    
    /// @dev Management event emitted when this contract is paused
    event Pause();

    /// @dev Management event emitted when this contract is unpaused
    event Unpause();

    /**
     * @dev Management event emitted when the manager account at `newManager`
     * is added to the manager list
     */      
    event AddManager(address indexed newManager);

    /**
     * @dev Management event emitted when the manager account at
     * `removedManager` is removed from the manager list
     */    
    event RemoveManager(address indexed removedManager);
    
    /**
     * @dev Ownership event emitted when all management addresses are purged
     * from the manager list
     */      
    event PurgeManagers();

    /**
     * @dev Ownership event emitted when this contract is initialized where
     * `index` is the total number of times the logic contract has been
     * initialized
     */
    event Initialize(uint256 index);

    /**
     * @dev Modifier that determines if this contract is currently running and
     * reverts on "false"
     */       
    modifier isRunning {
        // This contract must be running
        require(
            _isRunning,
            "Collypto is not accepting transactions at this time"
        );
        _;
    }

    /**
     * @dev Modifier that determines if an address belongs to a management
     * account or the Master account and reverts on "false"
     */
    modifier onlyManager {
        // Operator address must match one of the management addresses or the
        // address of the Master account
        require(
            (msg.sender == _managerAddresses[0]) || 
            (msg.sender == _managerAddresses[1]) || 
            (msg.sender == _ownerAddress)
        );
        _;
    }

    /**
     * @dev Modifier that determines if an address belongs to the Master
     * account and reverts on "false"
     */    
    modifier onlyOwner {
        // Operator address must match the address of the Master account
        require((msg.sender == _ownerAddress));
        _;
    }

    /**
     * @notice Initializes this contract with the input values provided 
     * @dev This is a restricted ownership function and can only be called by
     * an operator using the Master account, otherwise, it will revert. Once
     * initialization is complete, an instance of this contract cannot be
     * reinitialized.
     * @param name_ The name of the token defined in this contract
     * @param symbol_ The ticker symbol of the token defined in this contract
     * @param managerAddress The initial management address value that will be
     * assigned to {_managerAddresses[0]}
     * @return success A Boolean value indicating that initialization was
     * successful
     */
    function initialize(
        string memory name_, 
        string memory symbol_, 
        address managerAddress
    )
        public
        returns (bool success)
    {
        // An instance of this contract can be initialized only once
        require(_initializationIndex == 1);

        // Assign current Master address
        _ownerAddress = 0x9BeDD66b05712A1AdD7D1fEC899B8641B3ECc863;
        
        // Initialization must be conducted by an operator using the Master
        // account
        require(msg.sender == _ownerAddress);

        _name = name_;
        _symbol = symbol_;

        // First manager list slot is initialized to the address provided
        _managerAddresses[0] = managerAddress;
        
        // Second manager list slot is initialized to the zero address ("empty"
        // value)
        _managerAddresses[1] = address(0);
        
        // Increment initialization index for future contract upgrades
        _initializationIndex++;

        _isInitialized = true;
        _isRunning = true;

        emit Initialize(_initializationIndex);

        return true;
    }

    /**
     * @notice Returns the current initialization index of the contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return index The total number of times this contract has been
     * initialized
     */
    function initializationIndex() public view returns (uint256 index) {
        return _initializationIndex;
    }

    /**
     * @notice Returns a Boolean value indicating whether this contract has
     * been initialized
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return initialized A Boolean value indicating whether this contract has
     * been initialized
     */
    function isInitialized() public view returns (bool initialized) {
        return _isInitialized;
    }

    /**
     * @notice Returns a Boolean value indicating whether this contract is
     * currently paused
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return paused A Boolean value indicating whether this contract is
     * currently paused
     */
    function isPaused() public view returns (bool paused) {
        return !_isRunning;
    }    

    /**
     * @notice Returns the name of the token defined by this contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return tokenName The name of the token defined by this contract
     */
    function name() public view returns (string memory tokenName) {
        return _name;
    }

    /**
     * @notice Returns the ticker symbol of the token defined by this contract
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return tokenSymbol The ticker symbol of the token defined by this
     * contract
     */
    function symbol() public view returns (string memory tokenSymbol) {
        return _symbol;
    }

    /**
     * @notice Returns the number of decimals used by this token
     * @dev As a pure function, this operation can be conducted regardless of
     * the current running state of this contract. The smallest unit of
     * Collypto is the "sliver", which is one quintillionth of a credit.
     * @return totalDecimals The number of decimals used by this token 
     */   
    function decimals() public pure returns (uint8 totalDecimals) {
        return 18;
    }

    /**
     * @notice Returns the total supply of credits (in slivers) that currently
     * exists on the Ethereum blockchain
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @return supply The total supply of credits (in slivers) that currently
     * exists on the Ethereum blockchain
     */
    function totalSupply() public view returns (uint256 supply) {
        return _totalSupply;
    }    
  
    /**
     * @notice Returns the total credit balance (in slivers) of the Ethereum
     * account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose balance is being
     * requested
     * @return balance The total credit balance (in slivers) of the {owner}
     * account
     */
    function balanceOf(address owner) public view returns (uint256 balance) {
        return _balances[owner];
    }

    /**
     * @notice Returns the frozen credit balance (in slivers) of the Ethereum
     * account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.          
     * @param owner The address of the Ethereum account whose frozen balance is
     * being requested
     * @return frozenBalance The frozen credit balance (in slivers) of the
     * {owner} account
     */ 
    function frozenBalanceOf(address owner)
        public
        view
        returns (uint256 frozenBalance)
    {

        return _frozenBalances[owner];
    } 

    /** 
     * @notice Returns the available credit balance (in slivers) of the
     * Ethereum account at `owner` 
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose available balance
     * is being requested
     * @return availableBalance The available credit balance (in slivers) of
     * the {owner} account
     */
    function availableBalanceOf(address owner)
        public
        view
        returns (uint256 availableBalance)
    {
        return _balances[owner] - _frozenBalances[owner];
    }

    /**
     * @notice Returns the current allowance of credits (in slivers) that
     * the Ethereum account at `spender` is authorized to transfer on behalf of
     * the Ethereum account at `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @return remaining The total allowance of credits (in slivers) that the
     * {spender} account may spend on behalf of the {owner} account
     */
    function allowance(address owner, address spender)
        public
        view
        returns (uint256 remaining)
    {
        return _allowances[owner][spender];
    }

    /**
     * @notice Returns the {UserStatus} record of the Ethereum account at
     * `owner`
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. 
     * @param owner The address of the Ethereum account whose {UserStatus}
     * record is being requested
     * @return status The {status} value of the {UserStatus} record of the
     * {owner} account
     * @return info The {info} value of the {UserStatus} record of the
     * {owner} account
     */
    function userStatusOf(address owner)
        public
        view
        returns (Statuses status, string memory info)
    {
        return (_userStatuses[owner].status, _userStatuses[owner].info);
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is currently locked.
     * @dev Locked accounts cannot send tokens, receive tokens, or conduct
     * allowance operations. As with other view functions, this operation can
     * be conducted regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return locked A Boolean value indicating whether the target Ethereum
     * account is locked
     */
    function isLocked(address targetAddress)
        public
        view
        returns (bool locked)
    {
        return _lockedAddresses[targetAddress];
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Unknown"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. "Unknown" is
     * the default {status} value of all Ethereum accounts.
     * @param targetAddress The address of the target Ethereum account
     * @return unknown A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Unknown"
     */    
    function isUnknown(address targetAddress)
        public
        view
        returns (bool unknown)
    {
        return _userStatuses[targetAddress].status == Statuses.Unknown;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Verified"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. "Verified" is
     * the {status} of all medallion accounts. Only medallion accounts can
     * conduct verified user operations.
     * @param targetAddress The address of the target Ethereum account
     * @return verified A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Verified"
     */    
    function isVerified(address targetAddress)
        public
        view
        returns (bool verified)
    {
        return _userStatuses[targetAddress].status == Statuses.Verified;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Blacklisted"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Blacklisted
     * accounts can only conduct view operations.
     * @param targetAddress The address of the target Ethereum account
     * @return blacklisted A Boolean value indicating whether the target
     * Ethereum account has a {status} value of "Blacklisted"
     */   
    function isBlacklisted(address targetAddress)
        public
        view
        returns (bool blacklisted)
    {
        return _userStatuses[targetAddress].status == Statuses.Blacklisted;
    }
    
    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Suspect"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Suspected
     * accounts can still conduct all non-verified (standard) user operations.
     * @param targetAddress The address of the target Ethereum account
     * @return suspect A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Suspect"
     */       
    function isSuspect(address targetAddress)
        public
        view
        returns (bool suspect)
    {
        return _userStatuses[targetAddress].status == Statuses.Suspect;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` has a {status} value of "Pending"
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract. Accounts will
     * only be moved to "Pending" {status} prior to completion of the medallion
     * verification process.
     * @param targetAddress The address of the target Ethereum account
     * @return pending A Boolean value indicating whether the target Ethereum
     * account has a {status} value of "Pending"
     */      
    function isPending(address targetAddress)
        public
        view
        returns (bool pending)
    {
        return _userStatuses[targetAddress].status == Statuses.Pending;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is a manager account (includes the Master account)
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return manager A Boolean value indicating whether the target Ethereum
     * account is a manager account
     */      
    function isManager(address targetAddress)
        public
        view
        returns (bool manager)
    {
        if (targetAddress == address(0)) {
            return false;
        } else if (
            (targetAddress == _managerAddresses[0]) ||
            (targetAddress == _managerAddresses[1]) ||
            (targetAddress == _ownerAddress)
        ) {
            return true;
        }

        return false;
    }

    /**
     * @notice Returns a Boolean value indicating whether the Ethereum account
     * at `targetAddress` is the Master account
     * @dev As with other view functions, this operation can be conducted
     * regardless of the current running state of this contract.
     * @param targetAddress The address of the target Ethereum account
     * @return owner A Boolean value indicating whether the target Ethereum
     * account is the Master account
     */      
    function isOwner(address targetAddress)
        public
        view
        returns (bool owner)
    {
        if (targetAddress == address(0)) {
            return false;
        } else if (targetAddress == _ownerAddress) {
            return true;
        }

        return false;
    }

    /**
     * @notice Moves `amount` slivers from the operator's Ethereum account to
     * the Ethereum account at `to` and emits a {Transfer} event
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account or the {to} account is
     * blacklisted or locked or if any input arguments violate rules in the
     * {_transfer} function. Standard transfers cannot be conducted when this
     * contract is paused.
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function transfer(address to, uint256 amount) 
        public
        isRunning
        returns (bool success)
    {
        address from = msg.sender;        
        
        // Cannot transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Unauthorized");
        
        // Cannot transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _transfer(from, to, amount);

        return true;
    }

    /**
     * @notice Moves `amount` slivers from the operator's Ethereum account to
     * the Ethereum account at `to` (if the recipient is verified) and emits a
     * {Transfer} event
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account or the {to} account is
     * blacklisted or locked, the {to} account is unverified, or if any input
     * arguments violate rules in the {_transfer} function. Verified transfers
     * cannot be conducted when this contract is paused.
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function verifiedTransfer(address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address from = msg.sender;
        
        // Cannot transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Unauthorized");
        
        // Cannot transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot conduct a verified transfer to an unverified address
        require(isVerified(to), "ERROR: Unverified recipient");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _transfer(from, to, amount);

        return true;
    }

   /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to`, emits a {Transfer} event, and emits an
     * {Approval} event to track the updated allowance of the operator
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account, the {from} account, or the
     * {to} account is blacklisted or locked or if any input arguments violate
     * rules in the {_spendAllowance} or {_transfer} functions. Standard
     * transfers cannot be conducted when this contract is paused.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function transferFrom(address from, address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address spender = msg.sender;
        
        // Cannot initiate a verified transfer using a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Unauthorized");
        
        // Cannot conduct a verified transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Blacklisted sender");
        
        // Cannot conduct a verified transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot initiate transfer from a locked address
        require(!isLocked(spender), "ERROR: Spender is locked");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");
        
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }

   /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (if the recipient is verified), emits a
     * {Transfer} event, and emits an {Approval} event to track the updated
     * allowance value of the operator
     * @dev Per ERC-20 requirements, transfers of 0 credits are treated as
     * normal transfers and emit the {Transfer} event. This operation will
     * revert if the operator's Ethereum account, the {from} account, or the
     * {to} account is blacklisted or locked, the {to} account is unverified,
     * or if any input arguments violate rules in the {_spendAllowance} or
     * {_transfer} functions. Verified transfers cannot be conducted when this
     * contract is paused.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The total amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function verifiedTransferFrom(address from, address to, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address spender = msg.sender;
       
        // Cannot initiate a verified transfer using a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Unauthorized");
        
        // Cannot conduct a verified transfer from a blacklisted address
        require(!isBlacklisted(from), "ERROR: Blacklisted sender");
        
        // Cannot conduct a verified transfer to a blacklisted address
        require(!isBlacklisted(to), "ERROR: Blacklisted recipient");
        
        // Cannot conduct a verified transfer to an unverified address
        require(isVerified(to), "ERROR: Unverified recipient");
        
        // Cannot initiate transfer from a locked address
        require(!isLocked(spender), "ERROR: Spender is locked");
        
        // Cannot transfer from a locked address
        require(!isLocked(from), "ERROR: Sender is locked");
        
        // Cannot transfer to a locked address
        require(!isLocked(to), "ERROR: Recipient is locked");

        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);

        return true;
    }    

    /**
     * @notice Authorizes the Ethereum account at `spender` to transfer up to
     * `amount` slivers from the operator's Ethereum account to any other
     * Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted. Approvals cannot be conducted when
     * this contract is paused. Approvals for the MAX uint256 value of slivers
     * are considered infinite and will not be decremented automatically during
     * subsequent authorized transfers.
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function approve(address spender, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;
        
        // Cannot approve transactions from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot approve transactions for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");

        _approve(owner, spender, amount);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` (if verified) to
     * transfer up to `amount` slivers from the operator's Ethereum account to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the {spender} account is
     * unverified. Verified approvals cannot be conducted when this contract is
     * paused. Approvals for the MAX uint256 value of slivers are considered
     * infinite and will not be decremented automatically during subsequent
     * authorized transfers.
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedApprove(address spender, uint256 amount)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;   
        
        // Cannot approve transactions from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot approve transactions for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified.
        require(isVerified(spender), "ERROR: Unverified spender");

        _approve(owner, spender, amount);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` to transfer up to
     * `addedValue` additional slivers from the operator's Ethereum account to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * updated allowance limit) and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the resulting allowance value
     * would be larger than the MAX uint256 value. Allowance increases cannot
     * be conducted when this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param addedValue The amount of credits (in slivers) to be added to the
     * allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;
        
        // Cannot increase allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot increase allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        
        return true;
    }

    /**
     * @notice Authorizes the Ethereum account at `spender` (if verified) to
     * transfer up to `addedValue` additional slivers from the operator's
     * Ethereum account to any Ethereum account or accounts of the spender's
     * choosing (up to the updated allowance limit) and emits an {Approval}
     * event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted, if the resulting allowance value
     * would be larger than the MAX uint256 value, or if the {spender} account
     * is unverified. Verified allowance increases cannot be conducted when
     * this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param addedValue The amount of credits (in slivers) to be added to the
     * allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedIncreaseAllowance(address spender, uint256 addedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;     
        
        // Cannot increase allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot increase allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified
        require(isVerified(spender), "ERROR: Unverified spender");
        
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        
        return true;
    }

    /**
     * @notice Removes `subtractedValue` slivers from the allowance of
     * the Ethereum account at `spender` for the operator's Ethereum account
     * and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted or if the resulting allowance value
     * would be negative. Allowance decreases cannot be conducted when this
     * contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param subtractedValue The amount of credits (in slivers) to be removed
     * from the allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;        
        
        // Cannot decrease allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot decrease allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        uint256 currentAllowance = allowance(owner, spender);
        
        // Cannot decrease allowance below zero
        require(currentAllowance >= subtractedValue);
        
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @notice Removes `subtractedValue` slivers from the allowance of
     * the Ethereum account at `spender` (if verified) for the operator's
     * Ethereum account and emits an {Approval} event
     * @dev This operation will revert if the operator's Ethereum account or
     * the {spender} account is blacklisted, if the resulting allowance value
     * would be negative, or if the {spender} account is unverified. Verified
     * allowance decreases cannot be conducted when this contract is paused.
     * @param spender The address of the authorized Ethereum account
     * @param subtractedValue The amount of credits (in slivers) to be removed
     * from the allowance of the {spender} account
     * @return success A Boolean value indicating that the allowance has been
     * updated successfully
     */
    function verifiedDecreaseAllowance(
        address spender, 
        uint256 subtractedValue
    )
        public
        isRunning
        returns (bool success)
    {
        address owner = msg.sender;

        // Cannot decrease allowance from a blacklisted address
        require(!isBlacklisted(owner), "ERROR: Unauthorized");
        
        // Cannot decrease allowance for a blacklisted address
        require(!isBlacklisted(spender), "ERROR: Blacklisted spender");
        
        // Spender address must be verified
        require(isVerified(spender), "ERROR: Unverified spender");
        
        uint256 currentAllowance = allowance(owner, spender);
        
        // Cannot decrease allowance below zero
        require(currentAllowance >= subtractedValue);
        
        _approve(owner, spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @notice Updates the {UserStatus} record of the Ethereum account at
     * `targetAddress` to contain a {status} value of `status` and an {info}
     * value of `info` and emits an {UpdateUserStatus} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. {status} may
     * be any value in the {Statuses} enumeration, and {info} should be
     * provided in the format {creationDate: "yyyy-MM-dd", expirationDate:
     * "yyyy-MM-dd", message: ""}, where all properties are optional, and
     * {creationDate} and {expirationDate} are dates represented as strings in
     * ISO 8601 standard date format. {creationDate} and {expirationDate} will
     * only be included in Ethereum medallion accounts in the "Verified"
     * status, and {message} may be included in the {info} property of any
     * Ethereum account that we need to send an on-chain message.
     *
     * This operation will revert if the provided value of {status} does not
     * correspond to a valid {Statuses} value. Updating the {status} of an
     * address to "Blacklisted" will automatically lock the corresponding
     * Ethereum account, and it will need to be unlocked (in addition to
     * unblacklisted) in order to restore its ability to conduct transactions
     * and allowance operations.
     * @param targetAddress The address of the Ethereum account to be updated
     * @param status The {status} value to be assigned to the {UserStatus}
     * record of the target Ethereum account
     * @param info The {info} value to be assigned to the {UserStatus} record
     * of the target Ethereum account
     * @return success A Boolean value indicating that the provided {status}
     * and {info} were successfully assigned to the {UserStatus} record of the
     * target Ethereum account
     */
    function updateUserStatus(
        address targetAddress,
        Statuses status,
        string memory info
    )
        public
        onlyManager 
        returns (bool success)
    {
        if (
            (status == Statuses.Blacklisted) &&
            !isLocked(targetAddress)
        ) {
            _lock(targetAddress);
        }

        _userStatuses[targetAddress] = UserStatus({
            status: status,
            info: info            
        });

        emit UpdateUserStatus(targetAddress, status, info);

        return true;
    }

    /**
     * @notice Moves `amount` slivers from the Ethereum account at `from` to
     * the Ethereum account at `to` (regardless of user or account status) and
     * emits a {ForceTransfer} event. In the event that `amount` is greater
     * than the available balance of the account at `to`, the entire available
     * balance will be transferred.
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if the {from} account has an available balance of less than
     * the provided {amount}. Force transfers can be conducted regardless of
     * the current running state of this contract.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     * @return success A Boolean value indicating that the transfer was
     * successful
     */
    function forceTransfer(address from, address to, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {       
        uint256 availableBalance = availableBalanceOf(from);

        // Transfer all slivers in the account if {amount} is greater than the
        // available account balance
        if(amount > availableBalance) {
            amount = availableBalance;
        }

        _balances[from] -= amount;
        _balances[to] += amount;

        emit ForceTransfer(from, to, amount);

        return true;
    }

    /**
     * @notice Freezes `amount` slivers in the Ethereum account at
     * `targetAddress` and emits a {Freeze} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. In the event
     * that the {amount} value is greater than the available balance of the
     * Ethereum account at {targetAddress}, the entire balance of that account
     * will be frozen.
     * @param targetAddress The address of the Ethereum account where credits
     * will be frozen
     * @param amount The total number of credits (in slivers) to be frozen
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was succesfully frozen
     */
    function freeze(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {       
        uint256 availableBalance = availableBalanceOf(targetAddress);
        
        // Freeze all tokens if available balance is less than or equal to
        // target amount, otherwise, just increase the frozen balance by the
        // amount
        if (availableBalance <= amount) {
            _frozenBalances[targetAddress] = _balances[targetAddress];
        } else {
            _frozenBalances[targetAddress] += amount;
        }

        emit Freeze(
            targetAddress, 
            availableBalance - availableBalanceOf(targetAddress)
        );

        return true;
    }

    /**
     * @notice Unfreezes `amount` slivers in the Ethereum account at
     * `targetAddress` and emits an {Unfreeze} event
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. In the event
     * that the {amount} value is greater than the frozen balance of the
     * Ethereum account at {targetAddress}, the entire balance of that account
     * will be unfrozen.
     * @param targetAddress The address of the Ethereum account where credits
     * will be unfrozen
     * @param amount The total number of credits (in slivers) to be unfrozen
     * @return success A Boolean value indicating that the provided {amount}
     * of credits (in slivers) was succesfully unfrozen
     */    
    function unfreeze(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {
        uint256 frozenBalance = _frozenBalances[targetAddress];

        // Unfreeze all tokens if frozen balance is less than or equal to
        // target amount, otherwise, reduce the frozen balance by the amount
        if (frozenBalance <= amount) {
            _frozenBalances[targetAddress] = 0;
        } else {
            _frozenBalances[targetAddress] -= amount;
        }

        emit Unfreeze(
            targetAddress,
            frozenBalance - _frozenBalances[targetAddress]
        );

        return true;
    }

    /**
     * @notice Locks the Ethereum account at `targetAddress`
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {targetAddress} violates any of the rules in the {_lock}
     * function.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully locked
     */
    function lock(address targetAddress)
        public
        onlyManager
        returns (bool success)
    {
        return _lock(targetAddress);
    }

    /**
     * @notice Unlocks the Ethereum account at `targetAddress`
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {targetAddress} violates any of the rules in the
     * {_unlock} function.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully unlocked
     */
    function unlock(address targetAddress)
        public
        onlyManager
        returns (bool success)
    {
        return _unlock(targetAddress);
    }

    /**
     * @notice Mints `amount` slivers in the Ethereum account at
     * `targetAddress` and emits both {Mint} and {Transfer} events (per ERC-20
     * specifications)
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if {amount} would cause the value of {_totalSupply} to
     * exceed the MAX uint256 value.
     * @param targetAddress The address of the Ethereum account where credits
     * will be minted
     * @param amount The total number of credits (in slivers) to be minted
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was successfully minted
     */
    function mint(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {   
        _totalSupply += amount;
        
        unchecked {
            _balances[targetAddress] += amount;   
        }

        emit Mint(targetAddress, amount);
        emit Transfer(address(0), targetAddress, amount);

        return true;
    }

    /**
     * @notice Burns `amount` slivers in the Ethereum account at
     * `targetAddress` and emits both {Burn} and {Transfer} events (per ERC-20
     * specifications)
     * @dev This is a restricted utility function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if the {amount} value is greater than the available balance
     * of the Ethereum account at {targetAddress}.
     * @param targetAddress The address of the Ethereum account where credits
     * will be burned
     * @param amount The total number of credits (in slivers) to be burned
     * @return success A Boolean value indicating that the provided {amount} of
     * credits (in slivers) was successfully burned
     */
    function burn(address targetAddress, uint256 amount)
        public
        onlyManager
        returns (bool success)
    {        
        // Amount of credits (in slivers) specified cannot be greater than the
        // available balance of the target address
        require((amount <= availableBalanceOf(targetAddress)));
        
        unchecked {
            _totalSupply -= amount;
            _balances[targetAddress] -= amount;   
        }

        emit Burn(targetAddress, amount);
        emit Transfer(targetAddress, address(0), amount);

        return true;
    }

    /**
     * @notice Pauses this contract, blocking all standard user operations
     * until this contract is resumed
     * @dev This is a restricted management function and can be conducted
     * only when this contract is running.
     * @return success A Boolean value indicating that this contract has been
     * successfully paused
     */
    function pause() public onlyManager returns (bool success) {
        // This contract must be running to continue
        require(_isRunning);

        _isRunning = false;

        emit Pause();

        return true;
    }

    /**
     * @notice Unpauses this contract, unblocking all standard user operations
     * @dev This is a restricted management function and can be conducted
     * only when this contract is not running.   
     * @return success A Boolean value indicating that this contract has been
     * successfully unpaused
     */
    function unpause() public onlyManager returns (bool success) {
        // This contract must be paused to continue
        require(!_isRunning);        
        
        _isRunning = true;
        
        emit Unpause();

        return true;
    }

    /**
     * @notice Adds `managerAddress` to the manager list and emits an
     * {AddManager} event
     * @dev This is a restricted management function and can be conducted
     * regardless of the current running state of this contract. This operation
     * will revert if an operator attempts to add the Master address or a
     * redundant address to the manager list, and it will also revert if the
     * manager list already contains two manager addresses.
     * @return success A Boolean value indicating that the new manager address
     * has been successfully added to the manager list
     */
    function addManager(address managerAddress)
        public
        onlyManager
        returns (bool success)
    {
        // Cannot add the Master address to the manager list
        require((_ownerAddress != managerAddress));

        // Cannot add redundant addresses to the manager list
        require(_managerAddresses[0] != managerAddress);
        require(_managerAddresses[1] != managerAddress);
        
        if (_managerAddresses[0] == address(0)) {
            _managerAddresses[0] = managerAddress;
        } else if(_managerAddresses[1] == address(0)) {
            _managerAddresses[1] = managerAddress;
        } else {
            // Manager list is full
            revert();
        }
        
        emit AddManager(managerAddress);

        return true;
    }

    /**
     * @notice Removes `managerAddress` from the manager list and emits a
     * {RemoveManager} event
     * @dev This is a restricted management function and can be conducted
     * regardless of the current running state of this contract. Upon removal
     * of a secondary manager address, the remaining manager address will be
     * moved to {_managerAddresses[0]}, allowing all {onlyManager} checks to be
     * conducted in O(1) time on a standard manager address (not the Master
     * address). This operation will revert if an operator attempts to remove
     * the Master address, if the manager list is empty, or if the provided
     * manager address is not found in the manager list.
     * @return success A Boolean value indicating that the provided manager
     * address has been successfully removed from the manager list
     */
    function removeManager(address managerAddress)
        public
        onlyManager
        returns (bool success)
    {
        // An operator cannot remove their own address from the manager list
        require((msg.sender != managerAddress));
        
        // Cannot remove manager status from the Master address
        require((_ownerAddress != managerAddress));
        
        if (_managerAddresses[0] == managerAddress) {
            // Keep a single manager address at the front of the manager list
            _managerAddresses[0] = _managerAddresses[1];
            _managerAddresses[1] = address(0);
        } else if (_managerAddresses[1] == managerAddress) {
            _managerAddresses[1] = address(0);
        }       
        else {
            // There is no manager with the address provided
            revert();
        }
        
        emit RemoveManager(managerAddress);

        return true;
    }

    /** 
     * @notice Removes all managers from the manager list and emits a
     * {PurgeManagers} event
     * @dev This is a restricted ownership function and can be conducted
     * regardless of the current running state of this contract.
     * @return success A Boolean value indicating that all manager addresses
     * were successfully purged (set to the zero address) from the manager list
     */
    function purgeManagers() public onlyOwner returns (bool success) {
        _managerAddresses[0] = _managerAddresses[1] = address(0);

        emit PurgeManagers();

        return true;
    }

    /**
     * @notice Removes all manager addresses from the manager list, resets the
     * Master address to the zero address, pauses this contract, resets 
     * {_isInitialized} to false, and emits a {Pause} event
     * @dev This is a restricted ownership function and can be conducted
     * regardless of the current running state of this contract.     
     * @return success A Boolean value indicating that the manager list has
     * been purged, the Master address has been cleared (set to the zero
     * address), {_isInitialized} has been set to "false", and this contract
     * has been paused
     */
    function terminateContract() public onlyOwner returns (bool success) {
        _ownerAddress =
        _managerAddresses[0] =
        _managerAddresses[1] =
        address(0);

        _isRunning = false;
        _isInitialized = false;
        
        emit Pause();

        return true;
    }    

    /**
     * @dev This function moves `amount` slivers from the operator's Ethereum
     * account at `from` to the recipient's Ethereum account at `to` and emits
     * a {Transfer} event. This operation will revert if the account at `from`
     * has an available balance of less than `amount` slivers.
     * @param from The address of the sender's Ethereum account
     * @param to The address of the recipient's Ethereum account
     * @param amount The amount of credits (in slivers) to be transferred
     */
    function _transfer(address from, address to, uint256 amount) internal {        
        // Transfer amount cannot exceed available balance
        require((availableBalanceOf(from) >= amount));

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev This function authorizes the Ethereum account at `spender` to
     * transfer up to `amount` slivers from the Ethereum account at `owner` to
     * any Ethereum account or accounts of the spender's choosing (up to the
     * allowance limit) and emits an {Approval} event. Approvals for the MAX
     * uint256 value of slivers are considered infinite and will not be
     * decremented automatically during subsequent authorized transfers.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @param amount The allowance of credits (in slivers) to be authorized for
     * transfer by the {spender} account
     */
    function _approve(address owner, address spender, uint256 amount)
        internal 
    {
        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev This function removes `amount` slivers from the allowance of the
     * Ethereum account at `spender` that it would be authorized to transfer on
     * behalf of the Ethereum account at `owner` and emits an {Approval} event.
     * This operation will revert if `amount` is greater than the current
     * allowance of the account at `spender` and will exit without effect if
     * the current allowance of the account at `spender` is the MAX uint256
     * value.
     * @param owner The address of the authorizing Ethereum account
     * @param spender The address of the authorized Ethereum account
     * @param amount The amount of credits (in slivers) to be removed from the
     * allowance of the {spender} account
     */
    function _spendAllowance(address owner, address spender, uint256 amount)
        internal
    {
        uint256 currentAllowance = allowance(owner, spender);
        
        if (currentAllowance != type(uint256).max) {
            // Current allowance must be greater than or equal to the
            // transaction amount
            require(currentAllowance >= amount);

            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
    
    /**
     * @dev This function locks the Ethereum account at `targetAddress` and
     * emits a {Lock} event. This operation will revert if `targetAddress` is
     * already locked.
     * @param targetAddress The address of the Ethereum account to be locked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully locked
     */
    function _lock(address targetAddress) internal returns (bool success) {  
        // Cannot lock an address that is already locked
        require(!_lockedAddresses[targetAddress]);

        _lockedAddresses[targetAddress] = true;
        
        emit Lock(targetAddress);

        return true;
    }

    /**
     * @dev This function unlocks the Ethereum account at `targetAddress` and
     * emits an {Unlock} event. This operation will revert if `targetAddress`
     * is already unlocked.
     * @param targetAddress The address of the Ethereum account to be unlocked
     * @return success A Boolean value indicating that the Ethereum account was
     * successfully unlocked
     */
    function _unlock(address targetAddress) internal returns (bool success) {    
        // Cannot unlock an address that is already unlocked
        require(_lockedAddresses[targetAddress]);
 
        _lockedAddresses[targetAddress] = false;

        emit Unlock(targetAddress);

        return true;
    }
}