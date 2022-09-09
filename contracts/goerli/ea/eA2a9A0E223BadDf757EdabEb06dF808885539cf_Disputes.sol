// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IDisputes} from "./interfaces/IDisputes.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ContextUpgradeable, ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

/**
 * @title Disputes Contract for HomeFi v0.2.5

 * @dev Module for raising disputes for arbitration within HomeFi projects
 */
contract Disputes is
    IDisputes,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable
{
    /*******************************************************************************
     * -------------------------PUBLIC STORED PROPERTIES-------------------------- *
     *******************************************************************************/

    /// @inheritdoc IDisputes
    IHomeFi public homeFi;
    /// @inheritdoc IDisputes
    uint256 public disputeCount; //starts from 0
    /// @inheritdoc IDisputes
    mapping(uint256 => Dispute) public disputes;

    /*******************************************************************************
     * ---------------------------------MODIFIERS--------------------------------- *
     *******************************************************************************/

    modifier nonZero(address _address) {
        // Revert if _address zero address (0x00)
        require(_address != address(0), "Disputes::0 address");
        _;
    }

    modifier onlyAdmin() {
        // Revert if sender is not HomeFi admin
        // Only HomeFi admin can resolve dispute
        require(homeFi.admin() == msg.sender, "Disputes::!Admin");
        _;
    }

    modifier onlyProject() {
        // Revert if project not originated of HomeFi
        require(homeFi.isProjectExist(msg.sender), "Disputes::!Project");
        _;
    }

    /**
     * Affirm that a given dispute is currently resolvable
     * @param _disputeID uint256 - the serial/id of the dispute
     */
    modifier resolvable(uint256 _disputeID) {
        require(_disputeID < disputeCount, "Disputes::!Resolvable");
        require(
            disputes[_disputeID].status == Status.Active,
            "Disputes::!Resolvable"
        );
        _;
    }

    // solhint-disable-next-line no-empty-blocks
    constructor() ERC2771ContextUpgradeable(address(0)) {}

    /*******************************************************************************
     * ---------------------------EXTERNAL TRANSACTIONS--------------------------- *
     *******************************************************************************/

    /// @inheritdoc IDisputes
    function initialize(address _homeFi) external initializer nonZero(_homeFi) {
        homeFi = IHomeFi(_homeFi);
    }

    /// @inheritdoc IDisputes
    function raiseDispute(
        IProject.RaiseDisputeData calldata _data,
        address _signer
    ) external onlyProject {
        // _data is validated in project contract

        // Store dispute details
        Dispute storage _dispute = disputes[disputeCount];
        _dispute.status = Status.Active;
        _dispute.project = msg.sender;
        _dispute.taskID = _data.taskID;
        _dispute.raisedBy = _signer;
        _dispute.actionType = ActionType(_data.actionType);
        _dispute.actionData = _data.actionData;

        // Increment dispute counter and emit event
        emit DisputeRaised(disputeCount++, _data.reason);
    }

    /// @inheritdoc IDisputes
    function attachDocument(uint256 _disputeID, bytes calldata _attachment)
        external
        resolvable(_disputeID)
    {
        // Local instance of variable. For saving gas.
        Dispute storage _dispute = disputes[_disputeID];

        // Check if sender is related to dispute
        _assertMember(_dispute.project, _dispute.taskID, _msgSender());

        // Emit _attachment in event. To save it in logs.
        emit DisputeAttachmentAdded(_disputeID, _msgSender(), _attachment);
    }

    /// @inheritdoc IDisputes
    function resolveDispute(
        uint256 _disputeID,
        bytes calldata _judgement,
        bool _ratify
    ) external onlyAdmin nonReentrant resolvable(_disputeID) {
        // If dispute is accepted
        if (_ratify) {
            // Complete dispute actions
            _resolveHandler(_disputeID);

            // Mark dispute as accepted
            disputes[_disputeID].status = Status.Accepted;
        }
        // If dispute is rejected
        else {
            // Mark dispute as rejected
            disputes[_disputeID].status = Status.Rejected;
        }

        emit DisputeResolved(_disputeID, _ratify, _judgement);
    }

    /*******************************************************************************
     * -------------------------------PUBLIC VIEWS-------------------------------- *
     *******************************************************************************/

    /// @inheritdoc IDisputes
    function isTrustedForwarder(address _forwarder)
        public
        view
        override(ERC2771ContextUpgradeable, IDisputes)
        returns (bool)
    {
        return homeFi.isTrustedForwarder(_forwarder);
    }

    /*******************************************************************************
     * ---------------------------INTERNAL TRANSACTIONS--------------------------- *
     *******************************************************************************/

    /**
     * @notice Given an id, attempt to execute the action to enforce the arbitration

     * @notice logic for decoding and enforcing outcome of arbitration judgement

     * @param _disputeID uint256 - the dispute to attempt to
     */
    function _resolveHandler(uint256 _disputeID) internal {
        // Local instance of variable. For saving gas.
        Dispute storage dispute = disputes[_disputeID];

        // If action type is add task then execute add task
        if (dispute.actionType == ActionType.TaskAdd) {
            _executeTaskAdd(dispute);
        }
        // If action type is task change then execute task change
        else if (dispute.actionType == ActionType.TaskChange) {
            _executeTaskChange(dispute);
        }
        // Else execute task pay
        else {
            _executeTaskPay(dispute);
        }
    }

    /**
     * @dev Arbitration enforcement of adding tasks

     * @param _dispute Dispute dispute data
     */
    function _executeTaskAdd(Dispute storage _dispute) internal {
        (
            uint256 _taskCount,
            uint256[] memory _costList,
            bytes[] memory _hashList
        ) = abi.decode(_dispute.actionData, (uint256, uint256[], bytes[]));
        IProject.AddTasksData memory data = IProject.AddTasksData({
            taskCount: _taskCount,
            costList: _costList,
            hashList: _hashList
        });
        IProject(_dispute.project).addTasks(data, bytes(""));
    }

    /**
     * @dev Arbitration enforcement of task change orders

     * @param _dispute Dispute dispute data
     */
    function _executeTaskChange(Dispute storage _dispute) internal {
        (uint256 _newCost, address _newSC) = abi.decode(
            _dispute.actionData,
            (uint256, address)
        );
        IProject.ChangeOrderData memory data = IProject.ChangeOrderData({
            taskID: _dispute.taskID,
            newCost: _newCost,
            newSC: _newSC
        });
        IProject(_dispute.project).changeOrder(data, bytes(""));
    }

    /**
     * @dev Arbitration enforcement of task completion and payout

     * @param _dispute Dispute dispute data
     */
    function _executeTaskPay(Dispute storage _dispute) internal {
        uint256 _cost = abi.decode(_dispute.actionData, (uint256));
        IProject.SetCompleteData memory data = IProject.SetCompleteData({
            taskID: _dispute.taskID,
            cost: _cost
        });
        IProject(_dispute.project).setComplete(data, bytes(""));
    }

    /*******************************************************************************
     * ------------------------------INTERNAL VIEWS------------------------------- *
     *******************************************************************************/

    /**
     * @notice Asserts whether a given address is a related to dispute.
     * Else reverts.
     *
     * @param _project address - the project being queried for membership
     * @param _taskID uint256 - the index/serial of the task
     *  - if not querying for subcontractor, set as 0
     * @param _address address - the address being checked for membership
     */
    function _assertMember(
        address _project,
        uint256 _taskID,
        address _address
    ) internal view {
        // Local instance of variable. For saving gas.
        IProject _projectInstance = IProject(_project);

        // Get task subcontractor
        (, address _sc, ) = _projectInstance.getTask(_taskID);

        // Revert is signer is not builder, contractor or subcontractor.
        bool _result = _projectInstance.builder() == _address ||
            _projectInstance.contractor() == _address ||
            _sc == _address;
        require(_result, "Disputes::!Member");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IProjectFactory} from "./IProjectFactory.sol";

/**
 * @title HomeFi v0.2.5 HomeFi Contract Interface.

 * @notice Main on-chain client.
 * Administrative controls and project deployment.
 */
interface IHomeFi {
    event AddressSet();
    event AdminReplaceProposed(address _newAdmin);
    event AdminReplaced(address _newAdmin);
    event TreasuryReplaced(address _newTreasury);
    event LenderFeeReplaced(uint256 _newLenderFee);
    event TrustedForwarderReplaced(address _trustedForwarder);
    event ProjectAdded(
        uint256 _projectID,
        address indexed _project,
        address indexed _builder,
        address indexed _currency,
        bytes _hash
    );

    /**
     * @notice initialize this contract with required parameters.

     * @dev modifier initializer
     * @dev modifier nonZero: with _treasury, _tokenCurrency1, _tokenCurrency2, and _tokenCurrency3

     * @param _treasury address - treasury address of HomeFi. It receives builder and lender fee.
     * @param _lenderFee uint256 - percentage of fee lender have to pay to HomeFi system.
     * the percentage must be multiplied with 10. Lowest being 0.1%.
     * for example: for 1% lender fee, pass the amount 10.
     * @param _tokenCurrency1 address - HomeFi supported token currency 1
     * @param _tokenCurrency2 address - HomeFi supported token currency 2
     * @param _tokenCurrency3 address - HomeFi supported token currency 3
     * @param _forwarder address - trusted forwarder
     */
    function initialize(
        address _treasury,
        uint256 _lenderFee,
        address _tokenCurrency1,
        address _tokenCurrency2,
        address _tokenCurrency3,
        address _forwarder
    ) external;

    /**
     * @notice Pass addresses of other deployed modules into the HomeFi contract

     * @dev can only be called once
     * @dev modifier onlyAdmin
     * @dev modifier nonZero: with _projectFactory, _communityContract, _disputesContract, _hTokenCurrency1, _hTokenCurrency2, and _hTokenCurrency3.

     * @param _projectFactory address - contract instance of ProjectFactory.sol
     * @param _communityContract address - contract instance of Community.sol
     * @param _disputesContract address - contract instance of Disputes.sol
     * @param _hTokenCurrency1 address - Token 1 debt token address
     * @param _hTokenCurrency2 address - Token 2 debt token address
     * @param _hTokenCurrency3 address - Token 3 debt token address
     * @param _newAdmin address - Address of new admin (Rigor Dao)
     */
    function setAddr(
        address _projectFactory,
        address _communityContract,
        address _disputesContract,
        address _hTokenCurrency1,
        address _hTokenCurrency2,
        address _hTokenCurrency3,
        address _newAdmin
    ) external;

    /**
     * @notice Propose the replacement of the current admin

     * @dev modifier onlyAdmin
     * @dev modifier nonZero with _newAdmin
     * @dev modifier noChange with `admin` and `_newAdmin`

     * @param _newAdmin address - new admin address
     */
    function proposeAdminReplace(address _newAdmin) external;

    /**
     * @notice Execute the proposed replacement of the current admin
     */
    function executeAdminReplace() external;

    /**
     * @notice Replace the current treasury

     * @dev modifier onlyAdmin
     * @dev modifier nonZero with _treasury
     * @dev modifier noChange with `treasury` and `_treasury`

     * @param _treasury address - new treasury address
     */
    function replaceTreasury(address _treasury) external;

    /**
     * @notice Replace the current builder and lender fee.

     * @dev modifier onlyAdmin

     * @param _lenderFee uint256 - percentage of fee lender have to pay to HomeFi system.
     * the percentage must be multiplied with 10. Lowest being 0.1%.
     * for example: for 1% lender fee, pass the amount 10.
     */
    function replaceLenderFee(uint256 _lenderFee) external;

    /**
     * @notice Replaces the trusted forwarder

     * @dev modifier onlyAdmin
     * @dev modifier noChange with `forwarder` and `_newForwarder`

     * @param _newForwarder new forwarder address
     */
    function replaceTrustedForwarder(address _newForwarder) external;

    /**
     * @notice Creates a new project (Project contract clone) with sender as the builder

     * @dev modifier nonReentrant

     * @param _hash bytes - IPFS hash of project details
     * @param _currency address - currency which this project going to use
     */
    function createProject(bytes memory _hash, address _currency) external;

    /**
     * @notice Checks if a project exists in HomeFi

     * @param _project address of project contract

     * @return bool true if `_project` exits or vice versa.
     */
    function isProjectExist(address _project) external view returns (bool);

    /**
     * @notice Validates if a currency is supported by HomeFi.
     * Reverts if it is not.

     * @param _currency currency address
     */
    function validCurrency(address _currency) external view;

    /**
     * @notice checks trustedForwarder on HomeFi contract

     * @param _forwarder address of contract forwarding meta tx

     * @return bool true if `_forwarder` is trusted forwarder or vice versa.
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);

    /// @notice address of token currency 1
    function tokenCurrency1() external view returns (address);

    /// @notice address of token currency 2
    function tokenCurrency2() external view returns (address);

    /// @notice address of token currency 3
    function tokenCurrency3() external view returns (address);

    /// @notice address of project factory contract instance
    function projectFactoryInstance() external view returns (IProjectFactory);

    /// @notice address of dispute contract
    function disputesContract() external view returns (address);

    /// @notice address of community contract
    function communityContract() external view returns (address);

    /// @notice bool if addr is set
    function addrSet() external view returns (bool);

    /// @notice address of HomeFi Admin
    function admin() external view returns (address);

    /// @notice address of HomeFi Proposed Admin
    function proposedAdmin() external view returns (address);

    /// @notice timestamp of Last HomeFi Admin Replacement Proposal
    function adminProposalTimestamp() external view returns (uint256);

    /// @notice address of treasury
    function treasury() external view returns (address);

    /// @notice lender fee of platform
    function lenderFee() external view returns (uint256);

    /// @notice number of projects
    function projectCount() external view returns (uint256);

    /// @notice address of trusted forwarder
    function trustedForwarder() external view returns (address);

    /// @notice returns project address of projectId
    function projects(uint256 _projectId) external view returns (address);

    /// @notice returns projectId of project address
    function projectTokenId(address _projectAddress)
        external
        view
        returns (uint256);

    /// @notice returns wrapped token address of currency
    function wrappedToken(address _currencyAddress)
        external
        view
        returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IDebtToken} from "./IDebtToken.sol";
import {IHomeFi} from "./IHomeFi.sol";
import {Tasks, Task, TaskStatus} from "../libraries/Tasks.sol";

/**
 * @title Interface for Project Contract for HomeFi v0.2.5

 * @notice contains the primary logic around construction project management. 
 * Onboarding contractors, fund escrow, and completion tracking are all managed here. 
 * Significant multi-signature and meta-transaction functionality is included here.
 */
interface IProject {
    /*******************************************************************************
     * ----------------------------------STRUCTS---------------------------------- *
     *******************************************************************************/

    // struct for data for inviting a contractor to the project
    struct InviteContractorData {
        address contractor;
    }

    // struct for data for updating project hash
    struct UpdateProjectData {
        uint256 nonce;
        bytes hash;
    }

    // struct for data for adding tasks to the project
    struct AddTasksData {
        uint256 taskCount;
        uint256[] costList;
        bytes[] hashList;
    }

    // struct for data for updating task hash
    struct UpdateTaskData {
        uint256 taskID;
        uint256 nonce;
        bytes hash;
    }

    // struct for data for set complete
    struct SetCompleteData {
        uint256 taskID;
        uint256 cost;
    }

    // struct for data for change order
    struct ChangeOrderData {
        uint256 taskID;
        uint256 newCost;
        address newSC;
    }

    // struct for data for raising a dispute
    struct RaiseDisputeData {
        uint256 taskID;
        uint8 actionType;
        bytes actionData; // data for executing dispute action
        bytes reason;
    }

    /*******************************************************************************
     * ----------------------------------EVENTS----------------------------------- *
     *******************************************************************************/
    event ApproveHash(bytes32 _hash, address _signer);
    event HashUpdated(bytes _hash);
    event ContractorInvited(address indexed _newContractor);
    event ContractorDelegated(bool _bool);
    event LendToProject(uint256 _cost, address indexed _sender);
    event IncompleteAllocation();
    event TasksAdded(uint256[] _taskCosts, bytes[] _taskHashes);
    event TaskHashUpdated(uint256 _taskID, bytes _taskHash);
    event MultipleSCInvited(uint256[] _taskList, address[] _scList);
    event SingleSCInvited(uint256 _taskID, address _sc);
    event SCConfirmed(uint256[] _taskList);
    event TaskAllocated(uint256[] _taskIDs);
    event TaskComplete(uint256 _taskID);
    event ChangeOrderFee(uint256 _taskID, uint256 _newCost);
    event ChangeOrderSC(uint256 _taskID, address _sc);
    event AutoWithdrawn(uint256 _amount);

    /**
     * @notice initialize this contract with required parameters. This is initialized by HomeFi contract.

     * @dev modifier initializer

     * @param _currency address - currency for this project
     * @param _sender address - creator / builder for this project
     * @param _homeFiAddress address - HomeFi contract
     */
    function initialize(
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external;

    /**
     * @notice Approve a hash on-chain.

     * @param _hash bytes32 - hash that is to be approved
     */
    function approveHash(bytes32 _hash) external;

    /**
     * @notice Adds a Contractor to project

     * @dev `_signature` must include builder and contractor (invited) signatures

     * @param _data InviteContractorData - encoded data for inviting contractor
     * @param _signature bytes representing signature on _data by required members.
     */
    function inviteContractor(
        InviteContractorData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * @notice Builder can delegate his authorisation to the contractor.

     * @param _bool bool - bool to delegate builder authorisation to contractor.
     */
    function delegateContractor(bool _bool) external;

    /**
     * @notice Update project IPFS hash with adequate signatures.
     
     * @dev Check if signature is correct. If contractor is NOT added, check for only builder.
     * If contractor is added and NOT delegated, then check for builder and contractor.
     * If contractor is delegated, then check for contractor.
     
     * @param _data UpdateProjectData - data for updating project hash
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateProjectHash(
        UpdateProjectData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * @notice Allows lending in the project and allocates 50 tasks. 

     * @dev modifier nonReentrant
     * @dev if sender is builder then he fist must approve `_cost` amount of tokens to this contract.
     * @dev can only be called by builder or Community Contract (via lender).

     * @param _cost the cost that is needed to be lent
     */
    function lendToProject(uint256 _cost) external;

    /**
     * @notice Add tasks.

     * @dev Check if signature is correct. If contractor is NOT added, check for only builder.
     * If contractor is added and NOT delegated, then check for builder and contractor.
     * If contractor is delegated, then check for contractor.
     * @dev If the sender is disputes contract, then do not check for signatures

     * @param _data AddTasksData - data for adding tasks
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addTasks(AddTasksData calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice Update IPFS hash for a particular task.

     * @dev If subcontractor is approved then check for signature using `checkSignatureTask`.
     * Else check for signature using `checkSignature`
     
     * @param _data UpdateTaskData - data for updating task hash
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateTaskHash(
        UpdateTaskData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * @notice Invite subcontractors for existing tasks. This can be called by builder or contractor.

     * @dev This function internally calls _inviteSC.
     * _taskList must not have a task which already has approved subcontractor.

     * @param _taskList uint256[] - array the task index for which subcontractors needs to be assigned.
     * @param _scList uint256[] - array of addresses of subcontractor for the respective task index.
     */
    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external;

    /**
     * @notice Accept invite as subcontractor for a multiple tasks.

     * @dev Subcontractor must be unapproved.

     * @param _taskList uint256[] - the task list of indexes for which sender wants to accept invite.
     */
    function acceptInviteSC(uint256[] calldata _taskList) external;

    /**
     * @notice Mark a task a complete and release subcontractor payment.

     * @dev Check for signature using `checkSignatureTask`.
     * Else sender must be disputes contract.

     * @param _data SetCompleteData - data for setting a task complete
     * @param _signature bytes representing signature on _data by required members.
     */
    function setComplete(
        SetCompleteData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * @notice Recover any token sent mistakenly to this contract. Funds are transferred to builder account.

     * @dev If _tokenAddress is equal to this project currency, then we will first check is
     * all the tasks are complete

     * @param _tokenAddress address - the token user wants to recover.
     */
    function recoverTokens(address _tokenAddress) external;

    /**
     * @notice Change order to change a task's subcontractor, cost or both.

     * @dev modifier nonReentrant.
     * @dev Check for signature using `checkSignatureTask`.

     * @param _data ChangeOrderData - data for changing cost / sc of a task
     * @param _signature bytes representing signature on _data by required members.
     */
    function changeOrder(
        ChangeOrderData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * Raise a dispute to arbitrate & potentially enforce requested state changes
     *
     * @param _data RaiseDisputeData - data for raising a dispute
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(
        RaiseDisputeData calldata _data,
        bytes calldata _signature
    ) external;

    /**
     * @notice allocates funds for unallocated tasks and mark them as allocated.
     
     * @dev this is by default called by lendToProject.
     * But when unallocated task count are beyond 50 then this is needed to be called externally.

     * @param _customMaxLoop Max amount out times this loop will run
     */
    function allocateFunds(uint256 _customMaxLoop) external;

    /**
     * @notice Returns tasks details
     
     * @param _taskId uint256 - task index

     * @return taskCost uint256 - task cost
     * @return taskSubcontractor uint256 - task subcontractor
     * @return taskStatus uint256 - task status
     */
    function getTask(uint256 _taskId)
        external
        view
        returns (
            uint256 taskCost,
            address taskSubcontractor,
            TaskStatus taskStatus
        );

    /**
     * @notice Returns array of indexes of change ordered tasks
     
     * @return changeOrderTask uint256[] - of indexes of change ordered tasks
     */
    function changeOrderedTask()
        external
        view
        returns (uint256[] memory changeOrderTask);

    /**
     * @notice Returns cost of project. Project cost is sum of all task cost.

     * @return _cost uint256 - cost of project.
     */
    function projectCost() external view returns (uint256 _cost);

    /**
     * @notice returns Lifecycle statuses of a task

     * @param _taskID uint256 - task index

     * @return _alerts bool[3] - array of bool representing whether Lifecycle alert has been reached.
     * Lifecycle alerts- [None, TaskAllocated, SCConfirmed]
     */
    function getAlerts(uint256 _taskID)
        external
        view
        returns (bool[3] memory _alerts);

    /**
     * @notice checks trustedForwarder on HomeFi contract

     * @param _forwarder address of contract forwarding meta tx

     * @return bool true if `_forwarder` is trustedForwarder else false
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);

    /// @notice Returns homeFi NFT contract instance
    function homeFi() external view returns (IHomeFi);

    /// @notice Returns address of project currency
    function currency() external view returns (IDebtToken);

    /// @notice Returns lender fee inherited from HomeFi
    function lenderFee() external view returns (uint256);

    /// @notice Returns address of builder
    function builder() external view returns (address);

    /// @notice Returns version of project contract
    // solhint-disable-next-line func-name-mixedcase
    function VERSION() external view returns (uint256);

    /// @notice Returns address of invited contractor
    function contractor() external view returns (address);

    /// @notice Returns nonce that is used for signature security related to hash change
    function hashChangeNonce() external view returns (uint256);

    /// @notice Returns total amount lent in project
    function totalLent() external view returns (uint256);

    /// @notice Returns total amount allocated in project
    function totalAllocated() external view returns (uint256);

    /// @notice Returns task count/serial. Starts from 1.
    function taskCount() external view returns (uint256);

    /// @notice Returns bool indication if contractor is delegated
    function contractorDelegated() external view returns (bool);

    /// @notice Returns index of last allocated task
    function lastAllocatedTask() external view returns (uint256);

    /// @notice Returns index indicating last allocated task in array of changeOrderedTask
    function lastAllocatedChangeOrderTask() external view returns (uint256);

    /// @notice Returns mapping to keep track of all hashes (message or transaction) that have been approved by ANYONE
    function approvedHashes(address _signer, bytes32 _hash)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IHomeFi} from "./IHomeFi.sol";
import {IProject} from "./IProject.sol";

/**
 * @title Interface for Disputes contract for HomeFi v0.2.5

 * @dev Module for raising disputes for arbitration within HomeFi projects
 */
interface IDisputes {
    /*******************************************************************************
     * -------------------------------ENUMERATIONS-------------------------------- *
     *******************************************************************************/

    // Status of a dispute
    enum Status {
        None,
        Active,
        Accepted,
        Rejected
    }

    // Determines how dispute action params are parsed and executed
    enum ActionType {
        None,
        TaskAdd,
        TaskChange,
        TaskPay
    }

    /*******************************************************************************
     * ----------------------------------STRUCTS---------------------------------- *
     *******************************************************************************/

    // Object storing details of disputes
    struct Dispute {
        Status status; // the ruling on the dispute (see Status enum for all possible cases)
        address project; // project the dispute occurred in
        uint256 taskID; // task the dispute occurred in
        address raisedBy; // user who raised the dispute
        ActionType actionType; // action taken on if dispute is accepted
        bytes actionData; // data for executing action of dispute off-chain dispute discussion
    }

    /*******************************************************************************
     * ----------------------------------EVENTS----------------------------------- *
     *******************************************************************************/

    event DisputeRaised(uint256 indexed _disputeID, bytes _reason);
    event DisputeResolved(
        uint256 indexed _disputeID,
        bool _ratified,
        bytes _judgement
    );
    event DisputeAttachmentAdded(
        uint256 indexed _disputeID,
        address _user,
        bytes _attachment
    );

    /**
     * @notice Initialize a new communities contract

     * @dev modifier initializer
     * @dev modifier nonZero with _homeFi

     * @param _homeFi address - address of main homeFi contract
     */
    function initialize(address _homeFi) external;

    /**
     * @notice Raise a new dispute

     * @dev modifier onlyProject

     * @param _data IProject.RaiseDisputeData
     * @param _signer address - user raising the dispute
     */
    function raiseDispute(
        IProject.RaiseDisputeData calldata _data,
        address _signer
    ) external;

    /**
     * @notice Attach cid of arbitrary documents used to arbitrate disputes

     * @dev modifier resolvable with _disputeID

     * @param _disputeID uint256 - the uuid/serial of the dispute within this contract
     * @param _attachment bytes - the URI of the document being added
     */
    function attachDocument(uint256 _disputeID, bytes calldata _attachment)
        external;

    /**
     * @notice Arbitrate a dispute & execute accompanying enforcement logic to achieve desired project state

     * @dev modifier onlyAdmin
     * @dev modifier nonReentrant
     * @dev modifier resolvable with _disputeID

     * @param _disputeID uint256 - the uuid (serial) of the dispute in this contract
     * @param _judgement bytes - the URI hash of the document to be used to close the dispute
     * @param _ratify bool - true if status should be set to accepted, and false if rejected
     */
    function resolveDispute(
        uint256 _disputeID,
        bytes calldata _judgement,
        bool _ratify
    ) external;

    /**
     * @notice Checks trustedForwarder on HomeFi contract

     * @param _forwarder address - contract forwarding meta tx

     * @return bool - bool if _forwarder is trustedForwarder
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);

    /// @notice address of homeFi Contract
    function homeFi() external view returns (IHomeFi);

    /// @notice number of disputes
    function disputeCount() external view returns (uint256);

    /// @notice dispute by ID
    function disputes(uint256)
        external
        view
        returns (
            Status,
            address,
            uint256,
            address,
            ActionType,
            bytes memory
        );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * @title Interface for ProjectFactory for HomeFi v0.2.5

 * @dev This contract is used by HomeFi to create cheap clones of Project contract underlying
 */
interface IProjectFactory {
    /**
     * @dev Initialize this contract with HomeFi and master project address

     * @param _underlying the implementation address of project smart contract
     
     * @param _homeFi the latest address of HomeFi contract
     */
    function initialize(address _underlying, address _homeFi) external;

    /**
     * @notice Update project implementation

     * @dev Can only be called by HomeFi's admin

     * @param _underlying address of the implementation
     */
    function changeProjectImplementation(address _underlying) external;

    /**
     * @notice Create a clone for project contract.

     * @dev Can only be called via HomeFi

     * @param _currency address of the currency used by project
     * @param _sender address of the sender, builder

     * @return _clone address of the clone project contract
     */
    function createProject(address _currency, address _sender)
        external
        returns (address _clone);

    /// @notice Returns master implementation of project contract
    function underlying() external view returns (address);

    /// @notice Returns address of HomeFi contract
    function homeFi() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title DebtToken Contract Interface for HomeFi v0.2.5

 * @title Interface for ERC20 for wrapping collateral currencies loaned to projects in HomeFi
 */
interface IDebtToken is IERC20Upgradeable {
    /**
     * @notice Initialize a new communities contract

     * @dev modifier initializer

     * @param _communityContract address - address of deployed community contract
     * @param _name string - The name of the token
     * @param _symbol string - The symbol of the token
     * @param _decimals uint8 - decimal precision of the token
     */
    function initialize(
        address _communityContract,
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) external;

    /**
     * @notice Create new tokens and sent to an address

     * @dev modifier onlyCommunityContract

     * @param _to address - the address receiving the minted tokens
     * @param _total uint256 - the amount of tokens to mint to _to
     */
    function mint(address _to, uint256 _total) external;

    /**
     * @notice Destroy tokens at an address

     * @dev modifier onlyCommunityContract

     * @param _to address - the address where tokens are burned from
     * @param _total uint256 - the amount of tokens to burn from _to
     */
    function burn(address _to, uint256 _total) external;

    /// @notice Returns address of community contract
    function communityContract() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/*******************************************************************************
 * ----------------------------------STRUCTS---------------------------------- *
 *******************************************************************************/

// Task metadata
struct Task {
    // Metadata //
    uint256 cost; // Cost of task
    address subcontractor; // Subcontractor of task
    // Lifecycle //
    TaskStatus state; // Status of task
    mapping(uint256 => bool) alerts; // Alerts of task
}

/*******************************************************************************
 * -----------------------------------ENUMS----------------------------------- *
 *******************************************************************************/

enum TaskStatus {
    None,
    Inactive,
    Active,
    Complete
}

enum Lifecycle {
    None,
    TaskAllocated,
    SCConfirmed
}

/**
 * @title Tasks Library for HomeFi v0.2.5

 * @notice Internal library used in Project. Contains functions specific to a task actions and lifecycle.
 */
library Tasks {
    /// @dev only allow inactive tasks. Task is inactive if SC is unconfirmed.
    modifier onlyInactive(Task storage _self) {
        require(_self.state == TaskStatus.Inactive, "Task::active");
        _;
    }

    /// @dev only allow active tasks. Task is inactive if SC is confirmed.
    modifier onlyActive(Task storage _self) {
        require(_self.state == TaskStatus.Active, "Task::!Active");
        _;
    }

    /// @dev only allow funded tasks.
    modifier onlyFunded(Task storage _self) {
        require(
            _self.alerts[uint256(Lifecycle.TaskAllocated)],
            "Task::!funded"
        );
        _;
    }

    /// MUTABLE FUNCTIONS ///

    // Task Status Changing Functions //

    /**
     * @notice Create a new Task object

     * @dev cannot operate on initialized tasks

     * @param _self Task the task struct being mutated
     * @param _cost uint the number of tokens to be escrowed in this contract
     */
    function initialize(Task storage _self, uint256 _cost) public {
        _self.cost = _cost;
        _self.state = TaskStatus.Inactive;
        _self.alerts[uint256(Lifecycle.None)] = true;
    }

    /**
     * @notice Attempt to transition task state from Payment Pending to Complete

     * @dev modifier onlyActive

     * @param _self Task the task whose state is being mutated
     */
    function setComplete(Task storage _self)
        internal
        onlyActive(_self)
        onlyFunded(_self)
    {
        // State/ Lifecycle //
        _self.state = TaskStatus.Complete;
    }

    // Subcontractor Joining //

    /**
     * @dev Invite a subcontractor to the task
     * @dev modifier onlyInactive

     * @param _self Task the task being joined by subcontractor
     * @param _sc address the subcontractor being invited
     */
    function inviteSubcontractor(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        _self.subcontractor = _sc;
    }

    /**
     * @dev As a subcontractor, accept an invitation to participate in a task.
     * @dev modifier onlyInactive
     * @param _self Task the task being joined by subcontractor
     * @param _sc Address of sender
     */
    function acceptInvitation(Task storage _self, address _sc)
        internal
        onlyInactive(_self)
    {
        // Prerequisites //
        require(_self.subcontractor == _sc, "Task::!SC");

        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = true;
        _self.state = TaskStatus.Active;
    }

    // Task Funding //

    /**
     * @dev Set a task as funded

     * @param _self Task the task being set as funded / allocated
     */
    function fundTask(Task storage _self) internal {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskAllocated)] = true;
    }

    /**
     * @dev Set a task as un-funded

     * @param _self Task the task being set as not funded / unallocated
     */
    function unAllocateFunds(Task storage _self) internal {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.TaskAllocated)] = false;
    }

    /**
     * @dev Set a task as un accepted/approved for SC

     * @dev modifier onlyActive

     * @param _self Task the task being set as unapproved
     */
    function unApprove(Task storage _self) internal {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = false;
        _self.state = TaskStatus.Inactive;
    }

    /// VIEWABLE FUNCTIONS ///

    /**
     * @dev Determine the current state of all alerts in the project

     * @param _self Task the task being queried for alert status

     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached
     */
    function getAlerts(Task storage _self)
        internal
        view
        returns (bool[3] memory _alerts)
    {
        uint256 _length = _alerts.length;
        for (uint256 i; i < _length; ) {
            _alerts[i] = _self.alerts[i];

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev Return the numerical encoding of the TaskStatus enumeration stored as state in a task

     * @param _self Task the task being queried for state
     
     * @return _state uint 0: none, 1: inactive, 2: active, 3: complete
     */
    function getState(Task storage _self)
        internal
        view
        returns (uint256 _state)
    {
        return uint256(_self.state);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}