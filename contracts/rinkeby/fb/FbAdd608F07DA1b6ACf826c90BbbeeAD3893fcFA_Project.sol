// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IDebtToken} from "./interfaces/IDebtToken.sol";
import {IDisputes} from "./interfaces/IDisputes.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Tasks, Task, TaskStatus} from "./libraries/Tasks.sol";
import {SignatureDecoder} from "./libraries/SignatureDecoder.sol";

/**
 * @title Deployable Project Contract for HomeFi v2.5.0

 * @notice contains the primary logic around construction project management. 
 * Onboarding contractors, fund escrow, and completion tracking are all managed here. 
 * Significant multi-signature and meta-transaction functionality is included here.

 * @dev This contract is created as a clone copy for the end user
 */
contract Project is
    IProject,
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

    /// @notice Dispute contract instance
    address internal disputes;

    /// @notice mapping of tasks index to Task struct.
    mapping(uint256 => Task) internal tasks;

    /// @notice array of indexes of change ordered tasks
    uint256[] internal _changeOrderedTask;

    /*******************************************************************************
     * ----------------------FIXED PUBLIC STORED PROPERTIES----------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    IHomeFi public override homeFi;
    /// @inheritdoc IProject
    IDebtToken public override currency;
    /// @inheritdoc IProject
    uint256 public override lenderFee;
    /// @inheritdoc IProject
    address public override builder;
    /// @inheritdoc IProject
    uint256 public constant override VERSION = 25000;

    /*******************************************************************************
     * ---------------------VARIABLE PUBLIC STORED PROPERTIES--------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    address public override contractor;
    /// @inheritdoc IProject
    bool public override contractorConfirmed;
    /// @inheritdoc IProject
    uint256 public override hashChangeNonce;
    /// @inheritdoc IProject
    uint256 public override totalLent;
    /// @inheritdoc IProject
    uint256 public override totalAllocated;
    /// @inheritdoc IProject
    uint256 public override taskCount;
    /// @inheritdoc IProject
    bool public override contractorDelegated;
    /// @inheritdoc IProject
    uint256 public override lastAllocatedTask;
    /// @inheritdoc IProject
    uint256 public override lastAllocatedChangeOrderTask;
    /// @inheritdoc IProject
    mapping(address => mapping(bytes32 => bool)) public override approvedHashes;

    /// @dev Added to make sure master implementation cannot be initialized
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    /*******************************************************************************
     * ---------------------------EXTERNAL TRANSACTION---------------------------- *
     *******************************************************************************/
    /// @inheritdoc IProject
    function initialize(
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external override initializer {
        // Initialize variables
        homeFi = IHomeFi(_homeFiAddress);
        disputes = homeFi.disputeContract();
        lenderFee = homeFi.lenderFee();
        builder = _sender;
        currency = IDebtToken(_currency);
    }

    /// @inheritdoc IProject
    function approveHash(bytes32 _hash) external override {
        address _sender = _msgSender();
        // Allowing anyone to sign, as its hard to add restrictions here.
        // Store _hash as signed for sender.
        approvedHashes[_sender][_hash] = true;

        emit ApproveHash(_hash, _sender);
    }

    /// @inheritdoc IProject
    function inviteContractor(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // Revert if contractor has already confirmed his invitation
        require(!contractorConfirmed, "Project::GC accepted");

        // Decode params from _data
        (address _contractor, address _projectAddress) = abi.decode(
            _data,
            (address, address)
        );

        // Revert if decoded project address does not match this contract. Indicating incorrect _data.
        require(_projectAddress == address(this), "Project::!projectAddress");

        // Revert if contractor address is invalid.
        require(_contractor != address(0), "Project::0 address");

        // Store new contractor
        contractor = _contractor;
        contractorConfirmed = true;

        // Check signature for builder and contractor
        checkSignature(_data, _signature);

        emit ContractorInvited(contractor);
    }

    /// @inheritdoc IProject
    function delegateContractor(bool _bool) external override {
        // Revert if sender is not builder
        require(_msgSender() == builder, "Project::!B");

        // Revert if contract not assigned
        require(contractor != address(0), "Project::0 address");

        // Store new bool for contractorDelegated
        contractorDelegated = _bool;

        emit ContractorDelegated(_bool);
    }

    /// @inheritdoc IProject
    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // Check for required signatures
        checkSignature(_data, _signature);

        // Decode params from _data
        (bytes memory _hash, uint256 _nonce) = abi.decode(
            _data,
            (bytes, uint256)
        );

        // Revert if decoded nonce is incorrect. This indicates wrong _data.
        require(_nonce == hashChangeNonce, "Project::!Nonce");

        // Increment to ensure a set of data and signature cannot be re-used.
        hashChangeNonce += 1;

        emit HashUpdated(_hash);
    }

    /// @inheritdoc IProject
    function lendToProject(uint256 _cost) external override nonReentrant {
        address _sender = _msgSender();

        // Revert if sender is not builder or Community Contract (lender)
        require(
            _sender == builder || _sender == homeFi.communityContract(),
            "Project::!Builder&&!Community"
        );

        // Revert if try to lend 0
        require(_cost > 0, "Project::!value>0");

        // Revert if try to lend more than project cost
        uint256 _newTotalLent = totalLent + _cost;
        require(
            projectCost() >= uint256(_newTotalLent),
            "Project::value>required"
        );

        if (_sender == builder) {
            // Transfer assets from builder to this contract
            currency.safeTransferFrom(_sender, address(this), _cost);
        }

        // Update total lent with added lend
        totalLent = _newTotalLent;

        emit LendToProject(_cost);

        // Allocate funds to tasks and mark then as allocated
        allocateFunds();
    }

    /// @inheritdoc IProject
    function addTasks(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            // Check for required signatures
            checkSignature(_data, _signature);
        }

        // Decode params from _data
        (
            bytes[] memory _hash,
            uint256[] memory _taskCosts,
            uint256 _taskCount,
            address _projectAddress
        ) = abi.decode(_data, (bytes[], uint256[], uint256, address));

        // Revert if decoded taskCount is incorrect. This indicates wrong data.
        require(_taskCount == taskCount, "Project::!taskCount");

        // Revert if decoded project address does not match this contract. Indicating incorrect _data.
        require(_projectAddress == address(this), "Project::!projectAddress");

        // Revert if IPFS hash array length is not equal to task cost array length.
        uint256 _length = _hash.length;
        require(_length == _taskCosts.length, "Project::Lengths !match");

        // Loop over all the new tasks.
        for (uint256 i = 0; i < _length; i++) {
            // Increment local task counter.
            _taskCount += 1;

            // Check task cost precision. Revert if too precise.
            checkPrecision(_taskCosts[i]);

            // Initialize task.
            tasks[_taskCount].initialize(_taskCosts[i]);
        }

        // Update task counter equal to local task counter.
        taskCount = _taskCount;

        emit TasksAdded(_taskCosts, _hash);
    }

    /// @inheritdoc IProject
    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // Decode params from _data
        (bytes memory _taskHash, uint256 _nonce, uint256 _taskID) = abi.decode(
            _data,
            (bytes, uint256, uint256)
        );

        // Revert if decoded nonce is incorrect. This indicates wrong data.
        require(_nonce == hashChangeNonce, "Project::!Nonce");

        // If subcontractor has confirmed then check signature using `checkSignatureTask`.
        // Else check signature using `checkSignature`.
        if (getAlerts(_taskID)[2]) {
            // If subcontractor has confirmed.
            checkSignatureTask(_data, _signature, _taskID);
        } else {
            // If subcontractor not has confirmed.
            checkSignature(_data, _signature);
        }

        // Increment to ensure a set of data and signature cannot be re-used.
        hashChangeNonce += 1;

        emit TaskHashUpdated(_taskID, _taskHash);
    }

    /// @inheritdoc IProject
    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external
        override
    {
        // Revert if sender is neither builder nor contractor.
        require(
            _msgSender() == builder || _msgSender() == contractor,
            "Project::!Builder||!GC"
        );

        // Revert if taskList array length not equal to scList array length.
        uint256 _length = _taskList.length;
        require(_length == _scList.length, "Project::Lengths !match");

        // Invite subcontractor for each task.
        for (uint256 i = 0; i < _length; i++) {
            _inviteSC(_taskList[i], _scList[i], false);
        }

        emit MultipleSCInvited(_taskList, _scList);
    }

    /// @inheritdoc IProject
    function acceptInviteSC(uint256[] calldata _taskList) external override {
        // Accept invitation for each task in taskList.
        uint256 _length = _taskList.length;
        for (uint256 i = 0; i < _length; i++) {
            tasks[_taskList[i]].acceptInvitation(_msgSender());
        }

        emit SCConfirmed(_taskList);
    }

    /// @inheritdoc IProject
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // Decode params from _data
        (uint256 _taskID, address _projectAddress) = abi.decode(
            _data,
            (uint256, address)
        );

        // Revert if decoded project address does not match this contract. Indicating incorrect _data.
        require(_projectAddress == address(this), "Project::!Project");

        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            // Check signatures.
            checkSignatureTask(_data, _signature, _taskID);
        }

        // Mark task as complete. Only works when task is active.
        tasks[_taskID].setComplete();

        // Transfer funds to subcontractor.
        currency.safeTransfer(
            tasks[_taskID].subcontractor,
            tasks[_taskID].cost
        );

        emit TaskComplete(_taskID);
    }

    /// @inheritdoc IProject
    function recoverTokens(address _tokenAddress) external override {
        /* If the token address is same as currency of this project,
            then first check if all tasks are complete */
        if (_tokenAddress == address(currency)) {
            // Iterate for each task and check if it is complete.
            uint256 _length = taskCount;
            for (uint256 _taskID = 1; _taskID <= _length; _taskID++) {
                require(tasks[_taskID].getState() == 3, "Project::!Complete");
            }
        }

        // Create token instance.
        IDebtToken _token = IDebtToken(_tokenAddress);

        // Check the balance of _token in this contract.
        uint256 _leftOutTokens = _token.balanceOf(address(this));

        // If balance is present then it to the builder.
        if (_leftOutTokens > 0) {
            _token.safeTransfer(builder, _leftOutTokens);
        }
    }

    /// @inheritdoc IProject
    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
        override
        nonReentrant
    {
        // Decode params from _data
        (
            uint256 _taskID,
            address _newSC,
            uint256 _newCost,
            address _project
        ) = abi.decode(_data, (uint256, address, uint256, address));

        // If the sender is disputes contract, then do not check for signatures.
        if (_msgSender() != disputes) {
            // Check for required signatures.
            checkSignatureTask(_data, _signature, _taskID);
        }

        // Revert if decoded project address does not match this contract. Indicating incorrect _data.
        require(_project == address(this), "Project::!projectAddress");

        // Local variable for task cost. For gas saving.
        uint256 _taskCost = tasks[_taskID].cost;

        // Local variable indicating if subcontractor is already unapproved.
        bool _unapproved = false;

        // If task cost is to be changed.
        if (_newCost != _taskCost) {
            // Check new task cost precision. Revert if too precise.
            checkPrecision(_newCost);

            // Local variable for total cost allocated. For gas saving.
            uint256 _totalAllocated = totalAllocated;

            // If tasks are already allocated with old cost.
            if (tasks[_taskID].alerts[1]) {
                // If new task cost is less than old task cost.
                if (_newCost < _taskCost) {
                    // Find the difference between old - new.
                    uint256 _withdrawDifference = _taskCost - _newCost;

                    // Reduce this difference from total cost allocated.
                    // As the same task is now allocated with lesser cost.
                    totalAllocated -= _withdrawDifference;

                    // Withdraw the difference back to builder's account.
                    // As this additional amount may not be required by the project.
                    autoWithdraw(_withdrawDifference);
                }
                // If new cost is more than task cost but total lent is enough to cover for it.
                else if (totalLent - _totalAllocated >= _newCost - _taskCost) {
                    // Increase the difference of new cost and old cost to total allocated.
                    totalAllocated += _newCost - _taskCost;
                }
                // If new cost is more than task cost and totalLent is not enough.
                else {
                    // Un-confirm SC, mark task as inactive, mark allocated as false, mark lifecycle as None

                    // Mark task as inactive by unapproving subcontractor.
                    // As subcontractor can only be approved if task is allocated
                    _unapproved = true;
                    tasks[_taskID].unApprove();

                    // Mark task as not allocated.
                    tasks[_taskID].unAllocateFunds();

                    // Reduce total allocation by old task cost.
                    // As as needs to go though funding process again.
                    totalAllocated -= _taskCost;

                    // Add this task to _changeOrderedTask array. These tasks will be allocated first.
                    _changeOrderedTask.push(_taskID);
                }
            }

            // Store new cost for the task
            tasks[_taskID].cost = _newCost;

            emit ChangeOrderFee(_taskID, _newCost);
        }

        // If task subcontractor is to be changed.
        if (_newSC != tasks[_taskID].subcontractor) {
            // If task is not already unapproved, then un-approve it.
            // Un-approving task means marking subcontractor as unconfirmed.
            if (!_unapproved) {
                tasks[_taskID].unApprove();
            }

            // If new subcontractor is not zero address.
            if (_newSC != address(0)) {
                // Invite the new subcontractor for the task.
                _inviteSC(_taskID, _newSC, true);
            }
            // Else store zero address for the task subcontractor.
            // This implies that a subcontractor is not invited from the task.
            else {
                tasks[_taskID].subcontractor = address(0);
            }

            emit ChangeOrderSC(_taskID, _newSC);
        }
    }

    /// @inheritdoc IProject
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        // Recover the signer from the signature
        address signer = SignatureDecoder.recoverKey(
            keccak256(_data),
            _signature,
            0
        );

        // Decode params from _data
        (address _project, uint256 _task, , , ) = abi.decode(
            _data,
            (address, uint256, uint8, bytes, bytes)
        );

        // Revert if decoded project address does not match this contract. Indicating incorrect _data.
        require(_project == address(this), "Project::!projectAddress");

        if (_task == 0) {
            // Revet if sender is not builder or contractor
            require(
                signer == builder || signer == contractor,
                "Project::!(GC||Builder)"
            );
        } else {
            // Revet if sender is not builder, contractor or task's subcontractor
            require(
                signer == builder ||
                    signer == contractor ||
                    signer == tasks[_task].subcontractor,
                "Project::!(GC||Builder||SC)"
            );

            if (signer == tasks[_task].subcontractor) {
                // If sender is task's subcontractor, revert if invitation is not accepted.
                require(getAlerts(_task)[2], "Project::!SCConfirmed");
            }
        }

        // Make a call to Dispute contract raiseDisputes.
        IDisputes(disputes).raiseDispute(_data, _signature);
    }

    /*******************************************************************************
     * ------------------------------EXTERNAL VIEWS------------------------------- *
     *******************************************************************************/

    /// @inheritdoc IProject
    function getTask(uint256 id)
        external
        view
        override
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
    function changeOrderedTask()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _changeOrderedTask;
    }

    /*******************************************************************************
     * ----------------------------PUBLIC TRANSACTIONS---------------------------- *
     *******************************************************************************/

    /// @inheritdoc IProject
    function allocateFunds() public override {
        // Max amount out times this loop will run
        // This is to ensure the transaction do not run out of gas (max gas limit)
        uint256 _maxLoop = 50;

        // Difference of totalLent and totalAllocated is what can be used to allocate new tasks
        uint256 _costToAllocate = totalLent - totalAllocated;

        // Bool if max loop limit is exceeded
        bool _exceedLimit;

        // Local instance of lastAllocatedChangeOrderTask. To save gas.
        uint256 i = lastAllocatedChangeOrderTask;

        // Local instance of lastAllocatedTask. To save gas.
        uint256 j = lastAllocatedTask;

        // Initialize empty array in which allocated tasks will be added.
        uint256[] memory _tasksAllocated = new uint256[](
            taskCount - j + _changeOrderedTask.length - i
        );

        // Number of times a loop has run.
        uint256 _loopCount;

        /// CHANGE ORDERED TASK FUNDING ///

        // Any tasks added to _changeOrderedTask will be allocated first
        if (_changeOrderedTask.length > 0) {
            // Loop from lastAllocatedChangeOrderTask to _changeOrderedTask length (until _maxLoop)
            for (; i < _changeOrderedTask.length; i++) {
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
                    _costToAllocate -= _taskCost;

                    // Mark the task as allocated
                    tasks[_changeOrderedTask[i]].fundTask();

                    // Add task to _tasksAllocated array
                    _tasksAllocated[_loopCount] = _changeOrderedTask[i];

                    // Increment loop counter
                    _loopCount++;
                }
                // If there are not enough funds to allocate this task then stop looping
                else {
                    break;
                }
            }

            // If all the change ordered tasks are allocated, then delete
            // the changeOrderedTask array and reset lastAllocatedChangeOrderTask.
            if (i == _changeOrderedTask.length) {
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
            for (++j; j <= taskCount; j++) {
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
                    _costToAllocate -= _taskCost;

                    // Mark the task as allocated
                    tasks[j].fundTask();

                    // Add task to _tasksAllocated array
                    _tasksAllocated[_loopCount] = j;

                    // Increment loop counter
                    _loopCount++;
                }
                // If there are not enough funds to allocate this task then stop looping
                else {
                    break;
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
    function projectCost() public view override returns (uint256 _cost) {
        // Local instance of taskCount. To save gas.
        uint256 _length = taskCount;

        // Iterate over all tasks to sum their cost
        for (uint256 _taskID = 1; _taskID <= _length; _taskID++) {
            _cost += tasks[_taskID].cost;
        }
    }

    /// @inheritdoc IProject
    function getAlerts(uint256 _taskID)
        public
        view
        override
        returns (bool[3] memory _alerts)
    {
        return tasks[_taskID].getAlerts();
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
     * @dev Transfer excess funds back to builder wallet.
     * Called internally in task changeOrder when new task cost is lower than older cost.

     * @param _amount uint256 - amount of excess funds
     */
    function autoWithdraw(uint256 _amount) internal {
        // Reduce amount from totalLent
        totalLent -= _amount;

        // Transfer amount to builder address
        currency.safeTransfer(builder, _amount);

        emit AutoWithdrawn(_amount);
    }

    /**
     * @dev Check if recovered signatures match with builder and contractor address.
     * Signatures must be in sequential order. First builder and then contractor.
     * Reverts if signature do not match.
     * If contractor is not assigned then only checks for builder signature.
     * If contractor is assigned but not delegated then only checks for builder and contractor signature.
     * If contractor is assigned and delegated then only checks for contractor signature.

     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     */
    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
    {
        // Calculate hash from bytes
        bytes32 _hash = keccak256(_data);

        // When there is no contractor
        if (contractor == address(0)) {
            // Check for builder's signature
            checkSignatureValidity(builder, _hash, _signature, 0);
        }
        // When there is a contractor
        else {
            // When builder has delegated his rights to contractor
            if (contractorDelegated) {
                //  Check contractor's signature
                checkSignatureValidity(contractor, _hash, _signature, 0);
            }
            // When builder has not delegated rights to contractor
            else {
                // Check for both B and GC signatures
                checkSignatureValidity(builder, _hash, _signature, 0);
                checkSignatureValidity(contractor, _hash, _signature, 1);
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

     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _taskID index of the task.
     */
    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _taskID
    ) internal {
        // Calculate hash from bytes
        bytes32 _hash = keccak256(_data);

        // Local instance of subcontractor. To save gas.
        address _sc = tasks[_taskID].subcontractor;

        // When there is no contractor
        if (contractor == address(0)) {
            // Just check for B and SC sign
            checkSignatureValidity(builder, _hash, _signature, 0);
            checkSignatureValidity(_sc, _hash, _signature, 1);
        }
        // When there is a contractor
        else {
            // When builder has delegated his rights to contractor
            if (contractorDelegated) {
                // Check for GC and SC sign
                checkSignatureValidity(contractor, _hash, _signature, 0);
                checkSignatureValidity(_sc, _hash, _signature, 1);
            }
            // When builder has not delegated rights to contractor
            else {
                // Check for B, SC and GC signatures
                checkSignatureValidity(builder, _hash, _signature, 0);
                checkSignatureValidity(contractor, _hash, _signature, 1);
                checkSignatureValidity(_sc, _hash, _signature, 2);
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
    function checkSignatureValidity(
        address _address,
        bytes32 _hash,
        bytes memory _signature,
        uint256 _signatureIndex
    ) internal {
        address _recoveredSignature = SignatureDecoder.recoverKey(
            _hash,
            _signature,
            _signatureIndex
        );
        require(
            _recoveredSignature == _address || approvedHashes[_address][_hash],
            "Project::invalid signature"
        );
        // delete from approvedHash
        delete approvedHashes[_address][_hash];
    }

    /*******************************************************************************
     * -------------------------------INTERNAL PURE------------------------------- *
     *******************************************************************************/

    /**
     * @dev Check if precision is greater than 1000, if so, it reverts

     * @param _amount amount needed to be checked for precision.
     */
    function checkPrecision(uint256 _amount) internal pure {
        // Divide and multiply amount with 1000 should be equal to amount.
        // This ensures the amount is not too precise.
        require(
            ((_amount / 1000) * 1000) == _amount,
            "Project::Precision>=1000"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.6;

import {IProjectFactory} from "./IProjectFactory.sol";

/**
 * @title HomeFi v2.5.0 HomeFi Contract Interface.

 * @notice Main on-chain client.
 * Administrative controls and project deployment.
 */
interface IHomeFi {
    event AddressSet();
    event AdminReplaced(address _newAdmin);
    event TreasuryReplaced(address _newTreasury);
    event LenderFeeReplaced(uint256 _newLenderFee);
    event ProjectAdded(
        uint256 _projectID,
        address indexed _project,
        address indexed _builder,
        address indexed _currency,
        bytes _hash
    );
    event NftCreated(uint256 _id, address _owner);

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
     * @dev modifier nonZero: with _projectFactory, _communityContract, _disputeContract, _hTokenCurrency1, _hTokenCurrency2, and _hTokenCurrency3.

     * @param _projectFactory address - contract instance of ProjectFactory.sol
     * @param _communityContract address - contract instance of Community.sol
     * @param _disputeContract address - contract instance of Dispute.sol
     * @param _hTokenCurrency1 address - Token 1 debt token address
     * @param _hTokenCurrency2 address - Token 2 debt token address
     * @param _hTokenCurrency3 address - Token 3 debt token address
     */
    function setAddr(
        address _projectFactory,
        address _communityContract,
        address _disputeContract,
        address _hTokenCurrency1,
        address _hTokenCurrency2,
        address _hTokenCurrency3
    ) external;

    /**
     * @notice Replace the current admin

     * @dev modifier onlyAdmin
     * @dev modifier nonZero with _newAdmin
     * @dev modifier noChange with `admin` and `_newAdmin`

     * @param _newAdmin address - new admin address
     */
    function replaceAdmin(address _newAdmin) external;

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
    function setTrustedForwarder(address _newForwarder) external;

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
    function disputeContract() external view returns (address);

    /// @notice address of community contract
    function communityContract() external view returns (address);

    /// @notice bool if addr is set
    function addrSet() external view returns (bool);

    /// @notice address of HomeFi Admin
    function admin() external view returns (address);

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

pragma solidity 0.8.6;

import {IDebtToken} from "./IDebtToken.sol";
import {IHomeFi} from "./IHomeFi.sol";
import {Tasks, Task, TaskStatus} from "../libraries/Tasks.sol";

/**
 * @title Interface for Project Contract for HomeFi v2.5.0

 * @notice contains the primary logic around construction project management. 
 * Onboarding contractors, fund escrow, and completion tracking are all managed here. 
 * Significant multi-signature and meta-transaction functionality is included here.
 */
interface IProject {
    /*******************************************************************************
     * ----------------------------------EVENTS----------------------------------- *
     *******************************************************************************/
    event ApproveHash(bytes32 _hash, address _signer);
    event HashUpdated(bytes _hash);
    event ContractorInvited(address indexed _newContractor);
    event ContractorDelegated(bool _bool);
    event LendToProject(uint256 _cost);
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

     * @param _data bytes - encoded from:
     * - _contractor address - contractor address
     * - _projectAddress address - this project address, for signature security
     * @param _signature bytes representing signature on _data by required members.
     */
    function inviteContractor(bytes calldata _data, bytes calldata _signature)
        external;

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
     
     * @param _data bytes - encoded from:
     * - _hash bytes - bytes encoded IPFS hash.
     * - _nonce uint256 - current hashChangeNonce
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external;

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

     * @param _data bytes - encoded from:
     * - _hash bytes[] - bytes IPFS hash of task details
     * - _taskCosts uint256[] - an array of cost for each task index
     * - _taskCount uint256 - current task count before adding these tasks. Can be fetched by taskCount.
     *   For signature security.
     * - _projectAddress address - the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by builder and contractor.
     */
    function addTasks(bytes calldata _data, bytes calldata _signature) external;

    /**
     * @notice Update IPFS hash for a particular task.

     * @dev If subcontractor is approved then check for signature using `checkSignatureTask`.
     * Else check for signature using `checkSignature`
     
     * @param _data bytes - encoded from:
     * - _taskHash bytes - IPFS hash of task details
     * - _nonce uint256 - current hashChangeNonce. For signature security.
     * - _taskID uint256 - task index
     * @param _signature bytes representing signature on _data by required members.
     */
    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external;

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

     * @param _data bytes - encoded from:
     * - _taskID uint256 - the index of task
     * - _projectAddress address - the address of this contract. For signature security.
     * @param _signature bytes representing signature on _data by required members.
     */
    function setComplete(bytes calldata _data, bytes calldata _signature)
        external;

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

     * @param _data bytes - encoded from:
     * - _taskID uint256 - index of the task
     * - _newSC address - address of new subcontractor.
     *   If do not want to replace subcontractor, then pass address of existing subcontractor.
     * - _newCost uint256 - new cost for the task.
     *   If do not want to change cost, then pass existing cost.
     * - _project address - address of project
     * @param _signature bytes representing signature on _data by required members.
     */
    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * Raise a dispute to arbitrate & potentially enforce requested state changes
     *
     * @param _data bytes - encoded from:
     *   - _project address - address of this project
     *   - _task uint256 - task id (0 if none)
     *   - _actionType uint8 - action type
     *   - _actionData bytes - action data
     *   - _reason bytes - IPFS hash of the reason for dispute
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external;

    /**
     * @notice allocates funds for unallocated tasks and mark them as allocated.
     
     * @dev this is by default called by lendToProject.
     * But when unallocated task count are beyond 50 then this is needed to be called externally.
     */
    function allocateFunds() external;

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

    /// @notice Returns bool that indicated if contractor has accepted invite
    function contractorConfirmed() external view returns (bool);

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

pragma solidity 0.8.6;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
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

pragma solidity 0.8.6;

import {IHomeFi} from "./IHomeFi.sol";
import {IProject} from "./IProject.sol";

/**
 * @title Interface for Dispute contract for HomeFi v2.5.0

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
        bytes actionData; // IPFS hash of off-chain dispute discussion
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

     * @param _data bytes
     *   - 0: project address, 1: task id (0 if none), 2: action disputeType, 3: action data, 5: ipfs cid of pdf
     *   - const types = ["address", "uint256", "uint8", "bytes", "bytes"]
     * @param _signature bytes - hash of _data signed by the address raising dispute
     */
    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external;

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
     * @notice Asserts whether a given address is a related to dispute.
     * Else reverts.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
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

pragma solidity 0.8.6;

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

     * @param _self Task the task being set as funded
     */
    function fundTask(Task storage _self) internal {
        // State/ Lifecycle //
        _self.alerts[uint256(Lifecycle.TaskAllocated)] = true;
    }

    /**
     * @dev Set a task as un-funded

     * @param _self Task the task being set as funded
     */
    function unAllocateFunds(Task storage _self) internal {
        // State/ lifecycle //
        _self.alerts[uint256(Lifecycle.TaskAllocated)] = false;
    }

    /**
     * @dev Set a task as un accepted/approved for SC

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
        for (uint256 i = 0; i < _length; i++) _alerts[i] = _self.alerts[i];
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

pragma solidity 0.8.6;

/**
 * @title SignatureDecoder for HomeFi v2.5.0
 
 * @notice Decodes signatures that a encoded as bytes
 */
library SignatureDecoder {
    /**
    * @dev Recovers address who signed the message

    * @param messageHash bytes32 - keccak256 hash of message
    * @param messageSignatures bytes - concatenated message signatures
    * @param pos uint256 - which signature to read

    * @return address - recovered address
    */
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

    /**
    * @dev Divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    * @dev Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures

    * @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    * @param signatures concatenated rsv signatures
    */
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

/**
 * @title Interface for ProjectFactory for HomeFi v2.5.0

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

    /**
     * @notice checks trustedForwarder on HomeFi contract
     
     * @param _forwarder address of contract forwarding meta tx
     */
    function isTrustedForwarder(address _forwarder)
        external
        view
        returns (bool);
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