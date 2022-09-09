// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IDebtToken} from "./interfaces/IDebtToken.sol";
import {IDisputes} from "./interfaces/IDisputes.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Tasks, Task, TaskStatus, Lifecycle} from "./libraries/Tasks.sol";
import {SignatureDecoder} from "./libraries/SignatureDecoder.sol";
import {EIP712Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import {PPT_DIVISOR, INVITE_CONTRACTOR_HASH, UPDATE_PROJECT_HASH, ADD_TASKS_HASH, UPDATE_TASK_HASH, SET_COMPLETE_HASH, CHANGE_ORDER_HASH, RAISE_DISPUTE_HASH} from "./Constants.sol";

/**
 * @title Deployable Project Contract for HomeFi v0.2.5

 * @notice contains the primary logic around construction project management. 
 * Onboarding contractors, fund escrow, and completion tracking are all managed here. 
 * Significant multi-signature and meta-transaction functionality is included here.

 * @dev This contract is created as a clone copy for the end user
 */
contract Project is
    IProject,
    EIP712Upgradeable,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable
{
    // Using Tasks library for Task struct
    using Tasks for Task;

    // Using SafeERC20Upgradeable library for IDebtToken
    using SafeERC20Upgradeable for IDebtToken;

    /*******************************************************************************
     * ------------------------FIXED INTERNAL STORED PROPERTIES------------------------- *
     *******************************************************************************/

    /// @notice Disputes contract instance
    address internal disputes;

    /// @notice mapping of tasks index to Task struct.
    mapping(uint256 => Task) internal tasks;

    /// @notice array of indexes of change ordered tasks
    uint256[] internal _changeOrderedTask;

    /*******************************************************************************
     * ----------------------FIXED PUBLIC STORED PROPERTIES----------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    IHomeFi public homeFi;
    /// @inheritdoc IProject
    IDebtToken public currency;
    /// @inheritdoc IProject
    uint256 public lenderFee;
    /// @inheritdoc IProject
    address public builder;
    /// @inheritdoc IProject
    uint256 public constant VERSION = 25000;

    /*******************************************************************************
     * ---------------------VARIABLE PUBLIC STORED PROPERTIES--------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    address public contractor;
    /// @inheritdoc IProject
    uint256 public hashChangeNonce;
    /// @inheritdoc IProject
    uint256 public totalLent;
    /// @inheritdoc IProject
    uint256 public totalAllocated;
    /// @inheritdoc IProject
    uint256 public taskCount;
    /// @inheritdoc IProject
    bool public contractorDelegated;
    /// @inheritdoc IProject
    uint256 public lastAllocatedTask;
    /// @inheritdoc IProject
    uint256 public lastAllocatedChangeOrderTask;
    /// @inheritdoc IProject
    uint256 public projectCost;

    mapping(address => mapping(bytes32 => bool)) public approvedHashes;

    /// @dev Added to make sure master implementation cannot be initialized
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer ERC2771ContextUpgradeable(address(0)) {}

    /*******************************************************************************
     * ---------------------------EXTERNAL TRANSACTION---------------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    function initialize(
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external initializer {
        // Initialize EIP712
        __EIP712_init("HomeFi::Project", "0.2.5");

        // Initialize variables
        homeFi = IHomeFi(_homeFiAddress);
        disputes = homeFi.disputesContract();
        lenderFee = homeFi.lenderFee();
        builder = _sender;
        currency = IDebtToken(_currency);
    }

    /// @inheritdoc IProject
    function approveHash(bytes32 _hash) external {
        address _sender = _msgSender();
        // Allowing anyone to sign, as its hard to add restrictions here.
        // Store _hash as signed for sender.
        approvedHashes[_sender][_hash] = true;

        emit ApproveHash(_hash, _sender);
    }

    /// @inheritdoc IProject
    function inviteContractor(
        InviteContractorData calldata _data,
        bytes calldata _signature
    ) external {
        // Revert if contractor has already confirmed his invitation
        require(contractor == address(0), "Project::GC accepted");

        // Compute hash from data
        bytes32 _hash = _hashTypedDataV4(
            keccak256(abi.encode(INVITE_CONTRACTOR_HASH, _data.contractor))
        );

        // Revert if contractor address is invalid.
        require(_data.contractor != address(0), "Project::0 address");

        // Store contractor
        contractor = _data.contractor;

        // Check signature for builder and contractor
        _checkSignature(_hash, _signature);

        emit ContractorInvited(_data.contractor);
    }

    /// @inheritdoc IProject
    function delegateContractor(bool _bool) external {
        // Revert if sender is not builder
        require(_msgSender() == builder, "Project::!B");

        // Revert if contract not assigned
        require(contractor != address(0), "Project::0 address");

        // Store new bool for contractorDelegated
        contractorDelegated = _bool;

        emit ContractorDelegated(_bool);
    }

    /// @inheritdoc IProject
    function updateProjectHash(
        UpdateProjectData calldata _data,
        bytes calldata _signature
    ) external {
        // Compute hash from data
        bytes32 _hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UPDATE_PROJECT_HASH,
                    _data.nonce,
                    keccak256(_data.hash)
                )
            )
        );

        // Check for required signatures
        _checkSignature(_hash, _signature);

        // Revert if decoded nonce is incorrect. This indicates wrong _data.
        // And Increment to ensure a set of data and signature cannot be re-used.
        require(_data.nonce == hashChangeNonce++, "Project::!Nonce");

        emit HashUpdated(_data.hash);
    }

    /// @inheritdoc IProject
    function lendToProject(uint256 _cost) external nonReentrant {
        address _sender = _msgSender();

        // Revert if sender is not builder or Community Contract (lender)
        require(
            _sender == builder || _sender == homeFi.communityContract(),
            "Project::!Builder||!Community"
        );

        // Revert if try to lend 0
        require(_cost != 0, "Project::!value>0");

        // Revert if try to lend more than project cost
        uint256 _newTotalLent = totalLent + _cost;
        require(projectCost >= _newTotalLent, "Project::value>required");

        if (_sender == builder) {
            // Transfer assets from builder to this contract
            currency.safeTransferFrom(_sender, address(this), _cost);
        }

        // Update total lent with added lend
        totalLent = _newTotalLent;

        emit LendToProject(_cost, _sender);

        // Allocate funds to tasks and mark then as allocated
        allocateFunds(50);
    }

    /// @inheritdoc IProject
    function addTasks(AddTasksData calldata _data, bytes calldata _signature)
        external
    {
        // Revert if decoded taskCount is incorrect. This indicates wrong data.
        require(_data.taskCount == taskCount, "Project::!taskCount");

        // Revert if IPFS hash array length is not equal to task cost array length.
        uint256 _length = _data.hashList.length;
        require(_length == _data.costList.length, "Project::Lengths !match");

        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            bytes32[] memory _bytesHash = new bytes32[](_length);
            for (uint256 i; i < _length; ) {
                _bytesHash[i] = keccak256(_data.hashList[i]);
                unchecked {
                    ++i;
                }
            }
            // Compute hash from data
            bytes32 _hash = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        ADD_TASKS_HASH,
                        _data.taskCount,
                        keccak256(abi.encodePacked(_data.costList)),
                        keccak256(abi.encodePacked(_bytesHash))
                    )
                )
            );
            // Check for required signatures
            _checkSignature(_hash, _signature);
        }

        uint256 _totalCost;
        uint256 _taskCount = _data.taskCount;

        // Loop over all the new tasks.
        for (uint256 i; i < _length; ) {
            // Check task cost precision. Revert if too precise.
            _checkValidAmount(_data.costList[i]);
            _totalCost += _data.costList[i];

            // Increment local task counter and Initialize task.
            tasks[++_taskCount].initialize(_data.costList[i]);

            unchecked {
                ++i;
            }
        }

        // Update task counter equal to local task counter.
        taskCount = _taskCount;
        projectCost = projectCost + _totalCost;

        emit TasksAdded(_data.costList, _data.hashList);
    }

    /// @inheritdoc IProject
    function updateTaskHash(
        UpdateTaskData calldata _data,
        bytes calldata _signature
    ) external {
        // Compute hash from data
        bytes32 _hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    UPDATE_TASK_HASH,
                    _data.taskID,
                    _data.nonce,
                    keccak256(_data.hash)
                )
            )
        );

        // Revert if decoded nonce is incorrect. This indicates wrong data.
        // And Increment to ensure a set of data and signature cannot be re-used.
        require(_data.nonce == hashChangeNonce++, "Project::!Nonce");

        // If subcontractor has confirmed then check signature using `_checkSignatureTask`.
        // Else check signature using `_checkSignature`.
        if (getAlerts(_data.taskID)[uint256(Lifecycle.SCConfirmed)]) {
            // If subcontractor has confirmed.
            _checkSignatureTask(_hash, _signature, _data.taskID);
        } else {
            // If subcontractor not has confirmed.
            _checkSignature(_hash, _signature);
        }

        emit TaskHashUpdated(_data.taskID, _data.hash);
    }

    /// @inheritdoc IProject
    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external
    {
        // Local variable. For gas saving.
        address _sender = _msgSender();

        // Revert if sender is neither builder nor contractor.
        require(
            _sender == builder || _sender == contractor,
            "Project::!Builder||!GC"
        );

        // Revert if taskList array length not equal to scList array length.
        uint256 _length = _taskList.length;
        require(_length == _scList.length, "Project::Lengths !match");

        // Invite subcontractor for each task.
        for (uint256 i; i < _length; ) {
            _inviteSC(_taskList[i], _scList[i], false);

            unchecked {
                ++i;
            }
        }

        emit MultipleSCInvited(_taskList, _scList);
    }

    /// @inheritdoc IProject
    function acceptInviteSC(uint256[] calldata _taskList) external {
        // Local variable. For gas saving.
        address _sender = _msgSender();

        // Accept invitation for each task in taskList.
        uint256 _length = _taskList.length;
        for (uint256 i; i < _length; ) {
            tasks[_taskList[i]].acceptInvitation(_sender);

            unchecked {
                ++i;
            }
        }

        emit SCConfirmed(_taskList);
    }

    /// @inheritdoc IProject
    function setComplete(
        SetCompleteData calldata _data,
        bytes calldata _signature
    ) external {
        Task storage task = tasks[_data.taskID];
        // ensure change order makes changes
        require(task.cost == _data.cost, "Project::!cost");
        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            // Compute hash from data
            bytes32 _hash = _hashTypedDataV4(
                keccak256(
                    abi.encode(SET_COMPLETE_HASH, _data.taskID, _data.cost)
                )
            );
            // Check signatures.
            _checkSignatureTask(_hash, _signature, _data.taskID);
        }

        // Mark task as complete. Only works when task is active.
        task.setComplete();

        // Transfer funds to subcontractor.
        if (task.cost != 0) {
            currency.safeTransfer(task.subcontractor, task.cost);
        }

        emit TaskComplete(_data.taskID);
    }

    /// @inheritdoc IProject
    function recoverTokens(address _tokenAddress) external {
        // Revert if sender is not builder
        require(_msgSender() == builder, "Project::!B");
        /* If the token address is same as currency of this project,
            then first check if all tasks are complete */
        if (_tokenAddress == address(currency)) {
            // Iterate for each task and check if it is complete.
            uint256 _length = taskCount;
            for (uint256 _taskID = 1; _taskID <= _length; ) {
                require(tasks[_taskID].getState() == 3, "Project::!Complete");

                unchecked {
                    ++_taskID;
                }
            }
        }

        // Create token instance.
        IDebtToken _token = IDebtToken(_tokenAddress);

        // Check the balance of _token in this contract.
        uint256 _leftOutTokens = _token.balanceOf(address(this));

        // If any balance is present, transfer it to the builder.
        if (_leftOutTokens != 0) {
            _token.safeTransfer(builder, _leftOutTokens);
        }
    }

    /// @inheritdoc IProject
    function changeOrder(
        ChangeOrderData calldata _data,
        bytes calldata _signature
    ) external nonReentrant {
        Task storage task = tasks[_data.taskID];
        require(task.state != TaskStatus.Complete, "Project::!Active");

        // ensure change order makes changes
        require(
            task.cost != _data.newCost || task.subcontractor != _data.newSC,
            "Project::!Change"
        );

        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            // Compute hash from data
            bytes32 _hash = _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CHANGE_ORDER_HASH,
                        _data.taskID,
                        _data.newCost,
                        _data.newSC
                    )
                )
            );
            // If subcontractor has confirmed then check signature using `_checkSignatureTask`.
            // Else check signature using `_checkSignature`.
            if (getAlerts(_data.taskID)[uint256(Lifecycle.SCConfirmed)]) {
                // If subcontractor has confirmed.
                _checkSignatureTask(_hash, _signature, _data.taskID);
            } else {
                // If subcontractor not has confirmed.
                _checkSignature(_hash, _signature);
            }
        }

        // Local variable for task cost. For gas saving.
        uint256 _taskCost = task.cost;

        // If task cost is to be changed.
        if (_data.newCost != _taskCost) {
            // Check new task cost precision. Revert if too precise.
            _checkValidAmount(_data.newCost);

            // Local variable for total cost allocated. For gas saving.
            uint256 _totalAllocated = totalAllocated;

            // If tasks are already allocated with old cost.
            if (getAlerts(_data.taskID)[uint256(Lifecycle.TaskAllocated)]) {
                // If new task cost is less than old task cost.
                if (_data.newCost < _taskCost) {
                    // Find the difference between old - new.
                    uint256 _withdrawDifference;
                    unchecked {
                        _withdrawDifference = _taskCost - _data.newCost;
                    }

                    // Reduce this difference from total cost allocated.
                    // As the same task is now allocated with lesser cost.
                    totalAllocated -= _withdrawDifference;

                    // Withdraw the difference back to builder's account.
                    // As this additional amount may not be required by the project.
                    // Reduce amount from totalLent
                    totalLent -= _withdrawDifference;

                    // Transfer amount to builder address
                    currency.safeTransfer(builder, _withdrawDifference);

                    emit AutoWithdrawn(_withdrawDifference);
                }
                // If new cost is more than task cost but total lent is enough to cover for it.
                else if (
                    totalLent - _totalAllocated >= _data.newCost - _taskCost
                ) {
                    // Increase the difference of new cost and old cost to total allocated.
                    unchecked {
                        totalAllocated += _data.newCost - _taskCost;
                    }
                }
                // If new cost is more than task cost and totalLent is not enough.
                else {
                    // Mark allocated as false
                    task.unAllocateFunds();

                    // Reduce total allocation by old task cost.
                    // As it needs to go though funding process again.
                    totalAllocated -= _taskCost;

                    // Add this task to _changeOrderedTask array. These tasks will be allocated first.
                    _changeOrderedTask.push(_data.taskID);
                }
            }

            // Store new cost for the task
            task.cost = _data.newCost;

            projectCost = projectCost + _data.newCost - _taskCost;

            emit ChangeOrderFee(_data.taskID, _data.newCost);
        }

        // If task subcontractor is to be changed.
        if (_data.newSC != task.subcontractor) {
            // If task is not already unapproved, then un-approve it.
            // Un-approving task means marking subcontractor as unconfirmed.
            task.unApprove();

            // If new subcontractor is not zero address.
            if (_data.newSC != address(0)) {
                // Invite the new subcontractor for the task.
                _inviteSC(_data.taskID, _data.newSC, true);
            }
            // Else store zero address for the task subcontractor.
            // This implies that a subcontractor is not invited from the task.
            else {
                task.subcontractor = address(0);
            }

            emit ChangeOrderSC(_data.taskID, _data.newSC);
        }
    }

    /// @inheritdoc IProject
    function raiseDispute(
        RaiseDisputeData calldata _data,
        bytes calldata _signature
    ) external override {
        // validate actionType
        require(_data.actionType != 0, "Project::invalid dispute");
        require(_data.actionType < 4, "Project::invalid dispute");

        // Compute hash from data
        bytes32 _hash = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    RAISE_DISPUTE_HASH,
                    _data.taskID,
                    _data.actionType,
                    keccak256(_data.actionData),
                    keccak256(_data.reason)
                )
            )
        );

        // Ensure sender has signed the data
        address _signer = _msgSender();
        _checkSignatureValidity(_signer, _hash, _signature, 0);

        if (_data.taskID == 0) {
            // Dispute for TaskAdd
            // Revert if sender is not builder or contractor
            require(
                _signer == builder || _signer == contractor,
                "Project::!(GC||Builder)"
            );
        } else {
            // Revert if sender is not builder, contractor or task's subcontractor
            require(
                _signer == builder ||
                    _signer == contractor ||
                    _signer == tasks[_data.taskID].subcontractor,
                "Project::!(GC||Builder||SC)"
            );

            if (_signer == tasks[_data.taskID].subcontractor) {
                // If sender is task's subcontractor, revert if invitation is not accepted.
                require(
                    getAlerts(_data.taskID)[uint256(Lifecycle.SCConfirmed)],
                    "Project::!SCConfirmed"
                );
            }
        }

        // Make a call to Disputes contract raiseDisputes.
        IDisputes(disputes).raiseDispute(_data, _signer);
    }

    /*******************************************************************************
     * ------------------------------EXTERNAL VIEWS------------------------------- *
     *******************************************************************************/

    /// @inheritdoc IProject
    function getTask(uint256 id)
        external
        view
        returns (
            uint256 cost,
            address subcontractor,
            TaskStatus state
        )
    {
        cost = tasks[id].cost;
        subcontractor = tasks[id].subcontractor;
        state = tasks[id].state;
    }

    /// @inheritdoc IProject
    function changeOrderedTask() external view returns (uint256[] memory) {
        return _changeOrderedTask;
    }

    /*******************************************************************************
     * ----------------------------PUBLIC TRANSACTIONS---------------------------- *
     *******************************************************************************/

    /// @inheritdoc IProject
    function allocateFunds(uint256 _maxLoop) public {
        // Difference of totalLent and totalAllocated is what can be used to allocate new tasks
        uint256 _costToAllocate = totalLent - totalAllocated;

        // Bool if max loop limit is exceeded
        bool _exceedLimit;

        // Local instance of lastAllocatedChangeOrderTask. To save gas.
        uint256 i = lastAllocatedChangeOrderTask;

        // Local instance. To save gas.
        uint256 j = lastAllocatedTask;
        uint256 _changeOrderedTaskLength = _changeOrderedTask.length;

        // Initialize empty array in which allocated tasks will be added.
        uint256[] memory _tasksAllocated = new uint256[](
            taskCount - j + _changeOrderedTaskLength - i
        );

        // Number of times a loop has run.
        uint256 _loopCount;

        /// CHANGE ORDERED TASK FUNDING ///

        // Any tasks added to _changeOrderedTask will be allocated first
        if (_changeOrderedTaskLength > 0) {
            // Loop from lastAllocatedChangeOrderTask to _changeOrderedTask length (until _maxLoop)
            for (; i < _changeOrderedTaskLength; ) {
                // Local instance of task cost. To save gas.
                uint256 _taskCost = tasks[_changeOrderedTask[i]].cost;

                // If _maxLoop limit is reached then stop looping
                if (_loopCount >= _maxLoop) {
                    _exceedLimit = true;
                    break;
                }

                // If there is enough funds to allocate this task
                if (_costToAllocate >= _taskCost) {
                    // Reduce task cost from _costToAllocate
                    unchecked {
                        _costToAllocate -= _taskCost;
                    }

                    // Mark the task as allocated
                    tasks[_changeOrderedTask[i]].fundTask();

                    // Add task to _tasksAllocated array
                    _tasksAllocated[_loopCount] = _changeOrderedTask[i];

                    // Increment loop counter
                    unchecked {
                        ++_loopCount;
                    }
                }
                // If there are not enough funds to allocate this task then stop looping
                else {
                    break;
                }

                unchecked {
                    ++i;
                }
            }

            // If all the change ordered tasks are allocated, then delete
            // the changeOrderedTask array and reset lastAllocatedChangeOrderTask.
            if (i == _changeOrderedTaskLength) {
                lastAllocatedChangeOrderTask = 0;
                delete _changeOrderedTask;
            }
            // Else store the last allocated change order task index.
            else {
                lastAllocatedChangeOrderTask = i;
            }
        }

        /// TASK FUNDING ///

        // If lastAllocatedTask is lesser than taskCount, that means there are un-allocated tasks
        if (j < taskCount) {
            // Loop from lastAllocatedTask + 1 to taskCount (until _maxLoop)
            for (++j; j <= taskCount; ) {
                // Local instance of task cost. To save gas.
                uint256 _taskCost = tasks[j].cost;

                // If _maxLoop limit is reached then stop looping
                if (_loopCount >= _maxLoop) {
                    _exceedLimit = true;
                    break;
                }

                // If there is enough funds to allocate this task
                if (_costToAllocate >= _taskCost) {
                    // Reduce task cost from _costToAllocate
                    unchecked {
                        _costToAllocate -= _taskCost;
                    }

                    // Mark the task as allocated
                    tasks[j].fundTask();

                    // Add task to _tasksAllocated array
                    _tasksAllocated[_loopCount] = j;

                    // Increment loop counter
                    unchecked {
                        ++_loopCount;
                    }
                }
                // If there are not enough funds to allocate this task then stop looping
                else {
                    break;
                }

                unchecked {
                    ++j;
                }
            }

            // If all pending tasks are allocated store lastAllocatedTask equal to taskCount
            if (j > taskCount) {
                lastAllocatedTask = taskCount;
            }
            // If not all tasks are allocated store updated lastAllocatedTask
            else {
                lastAllocatedTask = --j;
            }
        }

        // If any tasks is allocated, then emit event
        if (_loopCount > 0) emit TaskAllocated(_tasksAllocated);

        // If allocation was incomplete, then emit event
        if (_exceedLimit) emit IncompleteAllocation();

        // Update totalAllocated with all allocations
        totalAllocated = totalLent - _costToAllocate;
    }

    /*******************************************************************************
     * -------------------------------PUBLIC VIEWS-------------------------------- *
     *******************************************************************************/

    /// @inheritdoc IProject
    function getAlerts(uint256 _taskID)
        public
        view
        returns (bool[3] memory _alerts)
    {
        _alerts = tasks[_taskID].getAlerts();
    }

    /// @inheritdoc IProject
    function isTrustedForwarder(address _forwarder)
        public
        view
        override(ERC2771ContextUpgradeable, IProject)
        returns (bool)
    {
        return homeFi.isTrustedForwarder(_forwarder);
    }

    /*******************************************************************************
     * ---------------------------INTERNAL TRANSACTIONS--------------------------- *
     *******************************************************************************/

    /**
     * @dev Invite subcontractors for a single task. This can be called by builder or contractor.
     * _taskList must not have a task which already has approved subcontractor.
     
     * @param _taskID uint256 task index
     * @param _sc address addresses of subcontractor for the respective task
     * @param _emitEvent whether to emit event for each sc added or not
     */
    function _inviteSC(
        uint256 _taskID,
        address _sc,
        bool _emitEvent
    ) internal {
        // Revert if sc to invite is address 0
        require(_sc != address(0), "Project::0 address");

        // Internal call to tasks invite contractor
        tasks[_taskID].inviteSubcontractor(_sc);

        // If `_emitEvent` is true (called via changeOrder) then emit event
        if (_emitEvent) {
            emit SingleSCInvited(_taskID, _sc);
        }
    }

    /**
     * @dev Check if recovered signatures match with builder and contractor address.
     * Signatures must be in sequential order. First builder and then contractor.
     * Reverts if signature do not match.
     * If contractor is not assigned then only checks for builder signature.
     * If contractor is assigned but not delegated then only checks for builder and contractor signature.
     * If contractor is assigned and delegated then only checks for contractor signature.

     * @param _hash bytes32 typed hash of data
     * @param _signature bytes appended signatures
     */
    function _checkSignature(bytes32 _hash, bytes calldata _signature)
        internal
    {
        // When there is no contractor
        if (contractor == address(0)) {
            // Check for builder's signature
            _checkSignatureValidity(builder, _hash, _signature, 0);
        }
        // When there is a contractor
        else {
            // When builder has delegated his rights to contractor
            if (contractorDelegated) {
                //  Check contractor's signature
                _checkSignatureValidity(contractor, _hash, _signature, 0);
            }
            // When builder has not delegated rights to contractor
            else {
                // Check for both B and GC signatures
                _checkSignatureValidity(builder, _hash, _signature, 0);
                // if hash is approved by the builder and builder is not contractor
                if (builder != contractor) {
                    _checkSignatureValidity(contractor, _hash, _signature, 1);
                }
            }
        }
    }

    /**
     * @dev Check if recovered signatures match with builder, contractor and subcontractor address for a task.
     * Signatures must be in sequential order. First builder, then contractor, and then subcontractor.
     * reverts if signatures do not match.
     * If contractor is not assigned then only checks for builder and subcontractor signature.
     * If contractor is assigned but not delegated then only checks for builder, contractor and subcontractor signature.
     * If contractor is assigned and delegated then only checks for contractor and subcontractor signature.

     * @param _hash bytes32 typed hash of data
     * @param _signature bytes appended signatures
     * @param _taskID index of the task.
     */
    function _checkSignatureTask(
        bytes32 _hash,
        bytes calldata _signature,
        uint256 _taskID
    ) internal {
        // Local instance of subcontractor. To save gas.
        address _sc = tasks[_taskID].subcontractor;

        // When there is no contractor
        if (contractor == address(0)) {
            // Just check for B and SC sign
            _checkSignatureValidity(builder, _hash, _signature, 0);
            // if hash is approved by the builder and builder is not SC
            if (builder != _sc) {
                _checkSignatureValidity(_sc, _hash, _signature, 1);
            }
        }
        // When there is a contractor
        else {
            // When builder has delegated his rights to contractor
            if (contractorDelegated) {
                // Check for GC and SC sign
                _checkSignatureValidity(contractor, _hash, _signature, 0);
                // if hash is approved by the contractor and contractor is not SC
                if (contractor != _sc) {
                    _checkSignatureValidity(_sc, _hash, _signature, 1);
                }
            }
            // When builder has not delegated rights to contractor
            else {
                // Check for B, SC and GC signatures
                _checkSignatureValidity(builder, _hash, _signature, 0);
                if (builder != contractor) {
                    // if hash is approved by the builder and builder is not GC
                    _checkSignatureValidity(contractor, _hash, _signature, 1);
                }
                if (builder != _sc && contractor != _sc) {
                    // if hash is approved by the builder and builder is not SC
                    _checkSignatureValidity(_sc, _hash, _signature, 2);
                }
            }
        }
    }

    /**
     * @dev Internal function for checking signature validity
     * @dev Checks if the signature is approved or recovered
     * @dev Reverts if not

     * @param _address address - address checked for validity
     * @param _hash bytes32 - hash for which the signature is recovered
     * @param _signature bytes - signatures
     * @param _signatureIndex uint256 - index at which the signature should be present
     */
    function _checkSignatureValidity(
        address _address,
        bytes32 _hash,
        bytes memory _signature,
        uint256 _signatureIndex
    ) internal {
        require(
            approvedHashes[_address][_hash] ||
                SignatureDecoder.recoverKey(
                    _hash,
                    _signature,
                    _signatureIndex
                ) ==
                _address,
            "HomeFi::invalid signature"
        );
        // delete from approvedHash
        delete approvedHashes[_address][_hash];
    }

    /*******************************************************************************
     * -------------------------------INTERNAL PURE------------------------------- *
     *******************************************************************************/

    /**
     * @dev Check if amount is zero or precision is greater than PPT_DIVISOR, if so, it reverts
     * @param _amount amount needed to be checked for precision.
     */
    function _checkValidAmount(uint256 _amount) internal pure {
        // Divide and multiply amount with PPT_DIVISOR should be equal to amount.
        // This ensures the amount is not too precise.
        require(
            ((_amount / PPT_DIVISOR) * PPT_DIVISOR) == _amount,
            "Project::Precision>=1000"
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
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

pragma solidity 0.8.16;

import {ECDSAUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";

/**
 * @title SignatureDecoder for HomeFi v0.2.5
 
 * @notice Decodes signatures that a encoded as bytes
 */
library SignatureDecoder {
    /**
    * @dev Recovers address who signed the message

    * @param _hash bytes32 - keccak256 hash of message
    * @param _signatures bytes - concatenated message signatures
    * @param _pos uint256 - which signature to read

    * @return address - recovered address
    */
    function recoverKey(
        bytes32 _hash,
        bytes memory _signatures,
        uint256 _pos
    ) internal pure returns (address) {
        // Check that the provided signature data is not too short
        require(_signatures.length >= _pos * 65, "HomeFi::invalid signature");

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = signatureSplit(_signatures, _pos);
        (address signer, ECDSAUpgradeable.RecoverError error) = ECDSAUpgradeable
            .tryRecover(_hash, v, r, s);
        require(
            error == ECDSAUpgradeable.RecoverError.NoError,
            "HomeFi::invalid signature"
        );
        return signer;
    }

    /**
    * @dev Divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures

    * @param _pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    * @param _signatures concatenated rsv signatures
    */
    function signatureSplit(bytes memory _signatures, uint256 _pos)
        private
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
            let signaturePos := mul(0x41, _pos)
            r := mload(add(_signatures, add(signaturePos, 0x20)))
            s := mload(add(_signatures, add(signaturePos, 0x40)))
            v := byte(0, mload(add(_signatures, add(signaturePos, 0x60))))
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
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

uint256 constant ONE_DAY = 86400; // 24 * 60 * 60
uint256 constant DAYS_IN_YEAR_TIMES_PPT_DIVISOR = 365000; // 365 (days in a year) * PPT_DIVISOR;
uint256 constant PPT_DIVISOR = 1000;

// Project.sol EIP712 TYPE HASHES
bytes32 constant INVITE_CONTRACTOR_HASH = keccak256(
    "InviteContractorData(address contractor)"
);

bytes32 constant UPDATE_PROJECT_HASH = keccak256(
    "UpdateProjectData(uint256 nonce,bytes hash)"
);

bytes32 constant ADD_TASKS_HASH = keccak256(
    "AddTasksData(uint256 taskCount,uint256[] costList,bytes[] hashList)"
);

bytes32 constant UPDATE_TASK_HASH = keccak256(
    "UpdateTaskData(uint256 taskID,uint256 nonce,bytes hash)"
);

bytes32 constant SET_COMPLETE_HASH = keccak256(
    "SetCompleteData(uint256 taskID,uint256 cost)"
);

bytes32 constant CHANGE_ORDER_HASH = keccak256(
    "ChangeOrderData(uint256 taskID,uint256 newCost,address newSC)"
);

bytes32 constant RAISE_DISPUTE_HASH = keccak256(
    "RaiseDisputeData(uint256 taskID,uint8 actionType,bytes actionData,bytes reason)"
);

// Community.sol EIP712 TYPE HASHES
bytes32 constant ADD_MEMBER_HASH = keccak256(
    "AddMemberData(uint256 communityID,address member,bytes message)"
);

bytes32 constant PUBLISH_PROJECT_HASH = keccak256(
    "PublishProjectData(uint256 communityID,address project,uint256 apr,uint256 publishFee,uint256 publishNonce,bytes message)"
);

bytes32 constant ESCROW_HASH = keccak256(
    "EscrowData(uint256 communityID,address builder,address lender,address agent,address project,uint256 repayAmount,uint256 escrowNonce,bytes message)"
);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}