// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IDisputes} from "./interfaces/IDisputes.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ContextUpgradeable, ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {SignatureDecoder} from "./libraries/SignatureDecoder.sol";

contract Disputes is
    IDisputes,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable /// INTERFACES ///
{
    IHomeFi public override homeFi;
    uint256 public override disputeCount; //starts from 0
    mapping(uint256 => Dispute) public override disputes;

    /// MODIFIERS ///

    modifier nonZero(address _address) {
        // ensure an address is not the zero address (0x00)
        require(_address != address(0), "Dispute::0 address");
        _;
    }

    modifier onlyAdmin() {
        // ensure that only HomeFi admins can arbitrate disputes
        require(homeFi.admin() == _msgSender(), "Dispute::!Admin");
        _;
    }

    modifier onlyProject() {
        // ensure the call originates from a valid project contract
        require(homeFi.isProjectExist(_msgSender()), "Dispute::!Project");
        _;
    }

    /**
     * Affirm that a given dispute is currently resolvable
     * @param _disputeID uint256 - the serial/id of the dispute
     */
    modifier resolvable(uint256 _disputeID) {
        require(
            _disputeID < disputeCount &&
                disputes[_disputeID].status == Status.Active,
            "Disputes::!Resolvable"
        );
        _;
    }

    /// CONSTRUCTOR ///

    function initialize(address _homeFi)
        external
        override
        initializer
        nonZero(_homeFi)
    {
        homeFi = IHomeFi(_homeFi);
    }

    /// MUTABLE FUNCTIONS ///

    function assertMember(
        address _project,
        uint256 _taskID,
        address _address
    ) public view override {
        IProject p = IProject(_project);
        (, address sc, ) = p.getTask(_taskID);
        bool result = p.builder() == _address ||
            p.contractor() == _address ||
            sc == _address;
        require(result, "Disputes::!Member");
    }

    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        override
        onlyProject
        returns (uint256)
    {
        address signer = SignatureDecoder.recoverKey(
            keccak256(_data),
            _signature,
            0
        );
        (
            address _project,
            uint256 _taskID,
            uint8 _actionType,
            bytes memory _actionData,
            bytes memory _reason
        ) = abi.decode(_data, (address, uint256, uint8, bytes, bytes));
        require(
            _actionType > 0 && _actionType <= uint8(ActionType.TaskPay),
            "Disputes::!ActionType"
        );
        Dispute storage dispute = disputes[disputeCount];
        dispute.status = Status.Active;
        dispute.project = _project;
        dispute.taskID = _taskID;
        dispute.raisedBy = signer;
        dispute.actionType = ActionType(_actionType);
        dispute.actionData = _actionData;
        emit DisputeRaised(disputeCount, _reason);
        disputeCount++;
        return disputeCount - 1;
    }

    function attachDocument(uint256 _disputeID, bytes calldata _attachment)
        external
        override
        resolvable(_disputeID)
    {
        Dispute storage dispute = disputes[_disputeID];
        address _project = dispute.project;
        uint256 _taskID = dispute.taskID;
        assertMember(_project, _taskID, _msgSender());
        emit DisputeAttachmentAdded(_disputeID, _msgSender(), _attachment);
    }

    function resolveDispute(
        uint256 _disputeID,
        bytes calldata _judgement,
        bool _ratify
    ) external override onlyAdmin nonReentrant resolvable(_disputeID) {
        if (_ratify) {
            resolveHandler(_disputeID);
            disputes[_disputeID].status = Status.Accepted;
        } else {
            disputes[_disputeID].status = Status.Rejected;
        }
        emit DisputeResolved(_disputeID, _ratify, _judgement);
    }

    function isTrustedForwarder(address _forwarder)
        public
        view
        override(ERC2771ContextUpgradeable, IDisputes)
        returns (bool)
    {
        return homeFi.isTrustedForwarder(_forwarder);
    }

    /// INTERNAL FUNCTIONS ///

    /**
     * Given an id, attempt to execute the action to enforce the arbitration
     * @dev modifier actionUsed
     * @dev needs reentrant check
     * @notice logic for decoding and enforcing outcome of arbitration judgement
     *
     * @param _disputeID uint256 - the dispute to attempt to
     */
    function resolveHandler(uint256 _disputeID) internal {
        Dispute storage dispute = disputes[_disputeID];
        if (dispute.actionType == ActionType.TaskAdd) {
            executeTaskAdd(dispute.project, dispute.actionData);
        } else if (dispute.actionType == ActionType.TaskChange) {
            executeTaskChange(dispute.project, dispute.actionData);
        } else {
            executeTaskPay(dispute.project, dispute.actionData);
        }
    }

    /**
     * Arbitration enforcement of task change orders
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task add transaction data stored when dispute was raised
     * - bytes[] _hash an array whose length is equal to number of task that you want to add,
     *   and each element is bytes converted IPFS hash of task
     * - uint256[] _cost an array of cost for each task index
     * - address[] _sc an array subcontractor address for each task index
     * - uint256 _taskSerial current task count/serial before adding these tasks. Can be fetched by taskSerial.
     * - address _projectAddress the address of this contract. For signature security.
     */
    function executeTaskAdd(address _project, bytes memory _actionData)
        internal
    {
        IProject(_project).addTasks(_actionData, bytes(""));
    }

    /**
     * Arbitration enforcement of task change orders
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task change order transaction data stored when dispute was raised
     * - 0: index of task; 1: task subcontractor; 2: task cost; 3: project address
     * - ["uint256", "uint256", "address", "uint256", "address"]
     */
    function executeTaskChange(address _project, bytes memory _actionData)
        internal
    {
        IProject(_project).changeOrder(_actionData, bytes(""));
    }

    /**
     * Arbitration enforcement of task payout
     * @notice should only ever be used by resolveHandler
     *
     * @param _project address - the project address of the dispute
     * @param _actionData bytes - the task payout transaction data stored when dispute was raised
     * - 0: index of task; 2: project address
     * - ["uint256", "address"]
     */
    function executeTaskPay(address _project, bytes memory _actionData)
        internal
    {
        IProject(_project).setComplete(_actionData, bytes(""));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import {IToken20} from "./IToken20.sol";
import {IProjectFactory} from "./IProjectFactory.sol";

/**
 * @title HomeFi v0.1.0 ERC721 Contract Interface
 * @notice Interface for main on-chain client for HomeFi protocol
 * Interface for administrative controls and project deployment
 */
interface IHomeFi {
    event AddressSet();
    event AdminReplaced(address _newAdmin);
    event TreasuryReplaced(address _newTreasury);
    event NetworkFeeReplaced(uint256 _newBuilderFee, uint256 _newLenderFee);
    event ProjectAdded(
        uint256 _projectID,
        address indexed _project,
        address indexed _builder,
        address indexed _currency,
        bytes _hash
    );
    event NftCreated(uint256 _id, address _owner);

    /**
     * @notice checks if a project exists
     * @param _project address of project contract
     */
    function isProjectExist(address _project) external view returns (bool);

    /**
     * @notice initialize this contract with required parameters.
     * @dev modifier initializer
     * @param _treasury rigor address which will receive builderFee and lenderFee of rigor system
     * @param _builderFee percentage of fee builder have to pay to rigor system
     * @param _lenderFee percentage of fee lender have to pay to rigor system
     * @param _tokenCurrency1 address - DAI token address
     * @param _tokenCurrency2 address - USDC token address
     * @param _tokenCurrency3 address - WETH token address
     */
    function initialize(
        address _treasury,
        uint256 _builderFee,
        uint256 _lenderFee,
        address _tokenCurrency1,
        address _tokenCurrency2,
        address _tokenCurrency3,
        address _forwarder
    ) external;

    /**
     * Pass addresses of other deployed modules into the HomeFi contract
     * @dev can only be called once
     * @param _projectFactory contract address of ProjectFactory.sol
     * @param _communityContract contract address of Community.sol
     * @param _disputeContract contract address of Dispute.sol
     * @param _hTokenCurrency1 Token 1 debt token address
     * @param _hTokenCurrency2 Token 2 debt token address
     * @param _hTokenCurrency3 Token 3 debt token address
     */
    function setAddr(
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _hTokenCurrency1,
        address _hTokenCurrency2,
        address _hTokenCurrency3
    ) external;

    /// @notice address of token currency 1
    function tokenCurrency1() external view returns (address);

    /// @notice address of token currency 2
    function tokenCurrency2() external view returns (address);

    /// @notice address of token currency 3
    function tokenCurrency3() external view returns (address);

    /// @notice address of project factory contract instance
    function projectFactoryInstance() external view returns (IProjectFactory);

    /// @notice address of dispute contract
    function disputeContract() external view returns (address);

    /// @notice address of community contract
    function communityContract() external view returns (address);

    /// @notice bool if addr is set
    function addrSet() external view returns (bool);

    /// @notice address of HomeFi Admin
    function admin() external view returns (address);

    /// @notice address of treasury
    function treasury() external view returns (address);

    /// @notice builder fee of platform
    function builderFee() external view returns (uint256);

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

    /**
     * @dev to validate the currency is supported by HomeFi or not
     * @param _currency currency address
     */
    function validCurrency(address _currency) external view;

    /// ADMIN MANAGEMENT ///
    /**
     * @notice only called by admin
     * @dev replace admin
     * @param _newAdmin new admin address
     */
    function replaceAdmin(address _newAdmin) external;

    /**
     * @notice only called by admin
     * @dev address which will receive HomeFi builder and lender fee
     * @param _treasury new treasury address
     */
    function replaceTreasury(address _treasury) external;

    /**
     * @notice this is only called by admin
     * @dev to reset the builder and lender fee for HomeFi deployment
     * @param _builderFee percentage of fee builder have to pay to HomeFi treasury
     * @param _lenderFee percentage of fee lender have to pay to HomeFi treasury
     */
    function replaceNetworkFee(uint256 _builderFee, uint256 _lenderFee)
        external;

    /// PROJECT ///
    /**
     * @dev to create a project
     * @param _hash IPFS hash of project details
     * @param _currency address of currency which this project going to use
     */
    function createProject(bytes memory _hash, address _currency) external;

    /**
     * @notice only called by admin
     * @dev replace trustedForwarder
     * @param _newForwarder new forwarder address
     */
    function setTrustedForwarder(address _newForwarder) external;

    /**
     * @notice checks trustedForwarder on HomeFi contract
     * @param _forwarder address of contract forwarding meta tx
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import {IToken20} from "./IToken20.sol";
import {IHomeFi} from "./IHomeFi.sol";
import "../libraries/Tasks.sol";

/**
 * @title Interface for Project Contract for HomeFi v0.1.0
 */
interface IProject {
    event ApproveHash(bytes32 _hash, address _signer);
    event HashUpdated(bytes _hash);
    event ContractorInvited(address indexed _newContractor);
    event ContractorDelegated(bool _bool);
    event LendToProject(uint256 _cost);
    event IncompleteFund();
    event TasksAdded(uint256[] _taskCosts, bytes[] _taskHashes);
    event TaskHashUpdated(uint256 _taskID, bytes _taskHash);
    event MultipleSCInvited(uint256[] _taskList, address[] _scList);
    event SingleSCInvited(uint256 _taskID, address _sc);
    event SCConfirmed(uint256[] _taskList);
    event TaskFunded(uint256[] _taskIDs);
    event TaskComplete(uint256 _taskID);
    event ChangeOrderFee(uint256 _taskID, uint256 _newCost);
    event ChangeOrderSC(uint256 _taskID, address _sc);
    event AutoWithdrawn(uint256 _amount);

    /**
     * @notice initialize this contract with required parameters. This is initialized by HomeFi contract
     * @dev modifier initializer
     * @param _currency currency address for this project
     * @param _sender address of the creator / builder for this project
     * @param _homeFiAddress address of the HomeFi contract
     */
    function initialize(
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external;

    /**
     * Approve a hash on-chain.
     * @param _hash bytes32 - hash that is to be approved
     */
    function approveHash(bytes32 _hash) external;

    /**
     * @notice Contractor can be added to project
     * @dev nonReentrant
     * @param _data bytes encoded from-
     * - address _contractor: address of project contractor
     * - address _projectAddress this project address, for signature security
     */
    function inviteContractor(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice Builder can delegate his authorisation to the contractor.
     * @param _bool bool - bool to delegate builder authorisation to contractor.
     */
    function delegateContractor(bool _bool) external;

    /**
     * @notice update project ipfs hash with adequate signatures.
     * @dev If contractor is approved then both builder and contractor signature needed. Else only builder's.
     * @param _data bytes encoded from-
     * - bytes _hash bytes encoded ipfs hash.
     * - uint256 _nonce current hashChangeNonce
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice allows lending in the project, also funds 50 tasks. If the project currency is ERC20 token,
     * then before calling this function the sender must approve the tokens to this contract.
     * @dev can only be called by builder or community contract(via lender).
     * @param _cost the cost that is needed to be lent
     */
    function lendToProject(uint256 _cost) external;

    // Task-Specific //

    /**
     * @notice adds tasks. Needs both builder and contractor signature.
     * @dev contractor must be approved.
     * @param _data bytes encoded from-
     * - bytes[] _hash bytes ipfs hash of task details
     * - uint256[] _cost an array of cost for each task index
     * - address[] _sc an array subcontractor address for each task index
     * - uint256 _taskCount current task count before adding these tasks. Can be fetched by taskCount.
     *   For signature security.
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addTasks(bytes calldata _data, bytes calldata _signature) external;

    /**
     * @dev If subcontractor is approved then builder, contractor and subcontractor signature needed.
     * Else only builder and contractor.
     * @notice update ipfs hash for a particular task
     * @param _data bytes encoded from-
     * - bytes[] _hash bytes ipfs hash of task details
     * - uint256 _nonce current hashChangeNonce
     * - uint256 _taskID task index
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice invite subcontractors for existing tasks. This can be called by builder or contractor.
     * @dev this function internally calls _inviteSC.
     * _taskList must not have a task which already has approved subcontractor.
     * @param _taskList array the task index for which subcontractors needs to be assigned.
     * @param _scList array of addresses of subcontractor for the respective task index.
     */
    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external;

    /**
     * @notice accept invite as subcontractor for a particular task.
     * Only subcontractor invited can call this.
     * @dev subcontractor must be unapproved.
     * @param _taskList the task list of indexes for which sender wants to accept invite.
     */
    function acceptInviteSC(uint256[] calldata _taskList) external;

    /**
     * @notice mark a task a complete and release subcontractor payment.
     * Needs builder,contractor and subcontractor signature.
     * @dev task must be in active state.
     * @param _data bytes encoded from-
     * - uint256 _taskID the index of task
     * - address _projectAddress the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice allocates funds for unallocated tasks and mark them as funded.
     * @dev this is by default called by lendToProject.
     * But when unallocated task count are beyond 50 then this is needed to be called externally.
     */
    function fundProject() external;

    /**
     * @notice recover any amount sent mistakenly to this contract. Funds are transferred to builder account.
     * @dev If _tokenAddress is equal to this project currency, then we will first check is
     * all the tasks are complete
     * @param _tokenAddress - address address for the token user wants to recover.
     */
    function recoverTokens(address _tokenAddress) external;

    /**
     * @notice change order to change a task's subcontractor, cost or both.
     * Needs builder,contractor and subcontractor signature.
     * @param _data bytes encoded from-
     * - uint256 _taskID index of the task
     * - address _newSC address of new subcontractor.
     *   If do not want to replace subcontractor, then pass address of existing subcontractor.
     * - uint256 _newCost new cost for the task.
     *   If do not want to change cost, then pass existing cost.
     * - address _project address of project
     * @param _signature bytes representing signature on _data by builder,contractor and subcontractor.
     */
    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * Raise a dispute to arbitrate & potentially enforce requested state changes
     *
     * @param _data bytes
     *   - 0: project address, 1: task id (0 if none), 2: action type, 3: action data, 5: ipfs cid of pdf
     *   - const types = ["address", "uint256", "uint8", "bytes", "bytes"]
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        returns (uint256);

    /// VIEWABLE FUNCTIONS ///

    /// @notice HomeFi NFT contract instance
    function homeFi() external view returns (IHomeFi);

    /// @notice Address of project currency
    function currency() external view returns (IToken20);

    /// @notice builder fee inherited from HomeFi
    function builderFee() external view returns (uint256);

    /// @notice lender fee inherited from HomeFi
    function lenderFee() external view returns (uint256);

    /// @notice address of builder
    function builder() external view returns (address);

    /// @notice address of invited contractor
    function contractor() external view returns (address);

    /// @notice bool that indicated if contractor has accepted invite
    function contractorConfirmed() external view returns (bool);

    /// @notice nonce that is used for signature security related to hash change
    function hashChangeNonce() external view returns (uint256);

    /// @notice total amount lent in project
    function totalLent() external view returns (uint256);

    /// @notice total amount allocated in project
    function totalAllocated() external view returns (uint256);

    /// @notice task count/serial. Starts from 1.
    function taskCount() external view returns (uint256);

    /// @notice task details cost, subcontractor and task status (Inactive, Active, Complete)
    function getTask(uint256 _taskId)
        external
        view
        returns (
            uint256,
            address,
            TaskStatus
        );

    /// @notice version of project contract
    function version() external view returns (uint256);

    /// @notice bool indication if contractor is delegated
    function contractorDelegated() external view returns (bool);

    /// @notice index of last funded task
    function lastFundedTask() external view returns (uint256);

    /// @notice array of indexes of change ordered tasks
    function changeOrderedTask() external view returns (uint256[] memory);

    /// @notice index indicating last funded task in array of changeOrderedTask
    function lastFundedChangeOrderTask() external view returns (uint256);

    /// @notice Mapping to keep track of all hashes (message or transaction) that have been approved by ANYONE
    function approvedHashes(address _signer, bytes32 _hash)
        external
        view
        returns (bool);

    /**
     * @notice returns Lifecycle statuses of a task
     * @param _taskID task index
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached.
     * Lifecycle alerts- [None, TaskFunded, SCConfirmed]
     */
    function getAlerts(uint256 _taskID)
        external
        view
        returns (bool[3] memory _alerts);

    /**
     * @notice returns cost of project. Project cost is sum of all task cost with builder fee
     * @return _cost uint256 cost of project.
     */
    function projectCost() external view returns (uint256 _cost);

    /**
     * @notice checks trustedForwarder on HomeFi contract
     * @param _forwarder address of contract forwarding meta tx
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import "./IHomeFi.sol";
import "./IProject.sol";

/**
 * Module for raising disputes for arbitration within HomeFi projects
 */
interface IDisputes {
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

    /// ENUMERATIONS ///

    enum Status {
        None,
        Active,
        Accepted,
        Rejected
    }

    //determines how dispute action params are parsed and executed
    enum ActionType {
        None,
        TaskAdd,
        TaskChange,
        TaskPay
    }

    /// STRUCTS ///

    struct Dispute {
        // Object storing metadata around disputes
        Status status; //the ruling on the dispute (see Status enum for all possible cases)
        address project; //project the dispute occurred in
        uint256 taskID; // task the dispute occurred in
        address raisedBy; // user who raised the dispute
        ActionType actionType;
        bytes actionData;
    }

    /**
     * Initialize a new communities contract
     * @notice THIS IS THE CONSTRUCTOR thanks upgradable proxies
     * @dev modifier initializer
     *
     * @param _homeFi address - address of main homeFi contract
     */
    function initialize(address _homeFi) external;

    /// MUTABLE FUNCTIONS ///

    /**
     * Asserts whether a given address is a member of a project,
     * Reverts if address not a member
     *
     * @param _project address - the project being queried for membership
     * @param _task uint256 - the index/serial of the task
     *  - if not querying for subcontractor, set as 0
     * @param _address address - the address being checked for membership
     */
    function assertMember(
        address _project,
        uint256 _task,
        address _address
    ) external;

    /**
     * Raise a new dispute
     * @dev modifier
     * @dev modifier onlyMember (must be decoded first)
     *
     * @param _data bytes
     *   - 0: project address, 1: task id (0 if none), 2: action disputeType, 3: action data, 5: ipfs cid of pdf
     *   - const types = ["address", "uint256", "uint8", "bytes", "bytes"]
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        returns (uint256);

    /**
     * Attach cid of arbitrary documents used to arbitrate disputes
     *
     * @param _disputeID uint256 - the uuid/serial of the dispute within this contract
     * @param _attachment bytes - the URI of the document being added
     */
    function attachDocument(uint256 _disputeID, bytes calldata _attachment)
        external;

    /**
     * Arbitrate a dispute & execute accompanying enforcement logic to achieve desired project state
     * @dev modifier onlyAdmin
     *
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
     * @notice checks trustedForwarder on HomeFi contract
     * @param _forwarder address of contract forwarding meta tx
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771ContextUpgradeable is Initializable, ContextUpgradeable {
    address private _trustedForwarder;

    function __ERC2771Context_init(address trustedForwarder) internal onlyInitializing {
        __Context_init_unchained();
        __ERC2771Context_init_unchained(trustedForwarder);
    }

    function __ERC2771Context_init_unchained(address trustedForwarder) internal onlyInitializing {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes

library SignatureDecoder {
    /// @dev Recovers address who signed the message
    /// @param messageHash keccak256 hash of message
    /// @param messageSignatures concatenated message signatures
    /// @param pos which signature to read
    function recoverKey(
        bytes32 messageHash,
        bytes memory messageSignatures,
        uint256 pos
    ) internal pure returns (address) {
        if (messageSignatures.length % 65 != 0) {
            return (address(0));
        }

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(messageSignatures, pos);

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            // solium-disable-next-line arg-overflow
            return ecrecover(toEthSignedMessageHash(messageHash), v, r, s);
        }
    }

    function toEthSignedMessageHash(bytes32 hash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
            );
    }

    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(signatures, add(signaturePos, 0x60))))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @dev Interface of the ERC20 standard with mint & burn methods
 */
interface IToken20 is IERC20Upgradeable {
    /**
     * Create new tokens and sent to an address
     *
     * @param _to address - the address receiving the minted tokens
     * @param _total uint256 - the amount of tokens to mint to _to
     */
    function mint(address _to, uint256 _total) external;

    /**
     * Destroy tokens at an address
     *
     * @param _to address - the address where tokens are burned from
     * @param _total uint256 - the amount of tokens to burn from _to
     */
    function burn(address _to, uint256 _total) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

interface IProjectFactory {
    /**
     * @dev initialize this contract with rigor and master project address
     * @param _underlying the implementation address of project smart contract
     * @param _homeFi the latest address of rigor contract
     */
    function initialize(address _underlying, address _homeFi) external;

    /**
     * @dev update project implementation
     * @notice this function can only be called by HomeFi's admin
     * @param _underlying address of the implementation
     */
    function changeProjectImplementation(address _underlying) external;

    /**
     * @dev create a clone for project contract
     * @notice this function can only be called by Rigor contract
     * @param _currency address of the currency used by project
     * @param _sender address of the sender, builder
     * @return _clone address of the clone project contract
     */
    function createProject(address _currency, address _sender)
        external
        returns (address _clone);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

library Tasks {
    /// MODIFIERS ///

    /// @dev only allow inactive tasks. Task are inactive if SC is unconfirmed.
    modifier onlyInactive(Task storage _self) {
        require(_self.state == TaskStatus.Inactive, "Task::active");
        _;
    }

    /// @dev only allow active tasks. Task are inactive if SC is confirmed.
    modifier onlyActive(Task storage _self) {
        require(_self.state == TaskStatus.Active, "Task::!Active");
        _;
    }

    /// @dev only allow funded tasks.
    modifier onlyFunded(Task storage _self) {
        require(_self.alerts[uint256(Lifecycle.TaskFunded)], "Task::!funded");
        _;
    }

    /// MUTABLE FUNCTIONS ///

    // Task Status Changing Functions //

    /**
     * Create a new Task object
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
     * Attempt to transition task state from Payment Pending to Complete
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
     * Invite a subcontractor to the task
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
     * As a subcontractor, accept an invitation to participate in a task.
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
     * Set a task as funded
     * @param _self Task the task being set as funded
     */
    function fundTask(Task storage _self) internal {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = true;
    }

    /**
     * Set a task as un-funded
     * @param _self Task the task being set as funded
     */
    function unFundTask(Task storage _self) internal {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.TaskFunded)] = false;
    }

    /**
     * Set a task as un accepted/approved for SC
     * @dev modifier onlyActive
     * @param _self Task the task being set as funded
     */
    function unApprove(Task storage _self) internal {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.SCConfirmed)] = false;
        _self.state = TaskStatus.Inactive;
    }

    /// VIEWABLE FUNCTIONS ///

    /**
     * Determine the current state of all alerts in the project
     * @param _self Task the task being queried for alert status
     * @return _alerts bool[3] array of bool representing whether Lifecycle alert has been reached
     */
    function getAlerts(Task storage _self)
        internal
        view
        returns (bool[3] memory _alerts)
    {
        uint256 _length = _alerts.length;
        for (uint256 i = 0; i < _length; i++) _alerts[i] = _self.alerts[i];
    }

    /**
     * Return the numerical encoding of the TaskStatus enumeration stored as state in a task
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

// Task metadata
struct Task {
    // Metadata //
    uint256 cost;
    address subcontractor;
    // Lifecycle //
    TaskStatus state;
    mapping(uint256 => bool) alerts;
}

enum TaskStatus {
    None,
    Inactive,
    Active,
    Complete
}

enum Lifecycle {
    None,
    TaskFunded,
    SCConfirmed
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}