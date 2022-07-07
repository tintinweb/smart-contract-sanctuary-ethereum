// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.6;

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {Project} from "./Project.sol";
import {IProjectFactory} from "./interfaces/IProjectFactory.sol";
import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {Initializable, ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";

/**
 * @title ProjectFactory
 * @dev This contract is used by rigor to create cheap clones of Project contract underlying
 */
contract ProjectFactory is
    IProjectFactory,
    Initializable,
    ERC2771ContextUpgradeable
{
    //master implementation of project contract
    address public underlying;

    // address of the latest rigor contract
    address public homeFi;

    modifier nonZero(address _address) {
        // ensure an address is not the zero address (0x00)
        require(_address != address(0), "PF::0 address");
        _;
    }

    function initialize(address _underlying, address _homeFi)
        external
        override
        initializer
        nonZero(_underlying)
        nonZero(_homeFi)
    {
        underlying = _underlying;
        homeFi = _homeFi;
    }

    /**
     * @notice checks trustedForwarder on HomeFi contract
     * @param _forwarder address of contract forwarding meta tx
     */
    function isTrustedForwarder(address _forwarder)
        public
        view
        override
        returns (bool)
    {
        return IHomeFi(homeFi).isTrustedForwarder(_forwarder);
    }

    function changeProjectImplementation(address _underlying)
        external
        override
        nonZero(_underlying)
    {
        require(
            IHomeFi(homeFi).admin() == _msgSender(),
            "ProjectFactory::!Owner"
        );
        underlying = _underlying;
    }

    function createProject(address _currency, address _sender)
        external
        override
        returns (address _clone)
    {
        require(_msgSender() == homeFi, "PF::!HomeFiContract");
        _clone = ClonesUpgradeable.clone(underlying);
        Project(_clone).initialize(_currency, _sender, homeFi);
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

import {IHomeFi} from "./interfaces/IHomeFi.sol";
import {IProject} from "./interfaces/IProject.sol";
import {IToken20} from "./interfaces/IToken20.sol";
import {IDisputes} from "./interfaces/IDisputes.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import {ERC2771ContextUpgradeable} from "@openzeppelin/contracts-upgradeable/metatx/ERC2771ContextUpgradeable.sol";
import {SafeERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import {Tasks, Task, TaskStatus} from "./libraries/Tasks.sol";
import {SignatureDecoder} from "./libraries/SignatureDecoder.sol";

/**
 * @title Deployable Project Contract for HomeFi v0.1.0
 * @notice This contract is for project management of HomeFi.
 * Project contract responsible for aggregating payments and data by/ for users on-chain
 * @dev This contract is created as a clone copy for the end user
 */
contract Project is
    IProject,
    ReentrancyGuardUpgradeable,
    ERC2771ContextUpgradeable
{
    using Tasks for Task; // using Tasks library for Task struct
    using SafeERC20Upgradeable for IToken20;

    /// Fixed ///

    /// Dispute contract instance
    address internal disputes;
    IHomeFi public override homeFi;
    IToken20 public override currency;
    uint256 public override builderFee;
    uint256 public override lenderFee;
    address public override builder;

    /// Variable ///
    address public override contractor;
    bool public override contractorConfirmed;
    uint256 public override hashChangeNonce;
    uint256 public override totalLent;
    uint256 public override totalAllocated;
    uint256 public override taskCount;
    // TODO override if possible
    /// @notice mapping of tasks index to Task struct.
    mapping(uint256 => Task) public tasks;
    uint256 public override version;
    bool public override contractorDelegated;
    uint256 public override lastFundedTask;
    // TODO override if possible
    /// @notice array of indexes of change ordered tasks
    uint256[] internal _changeOrderedTask;
    uint256 public override lastFundedChangeOrderTask;
    mapping(address => mapping(bytes32 => bool)) public override approvedHashes;

    /// @dev to make sure master implementation cannot be initialized
    // solhint-disable-next-line no-empty-blocks
    constructor() initializer {}

    function initialize(
        address _currency,
        address _sender,
        address _homeFiAddress
    ) external override initializer {
        homeFi = IHomeFi(_homeFiAddress);
        disputes = homeFi.disputeContract();
        builderFee = homeFi.builderFee();
        lenderFee = homeFi.lenderFee();
        builder = _sender;
        currency = IToken20(_currency);
        version = 20000;
    }

    function changeOrderedTask()
        external
        view
        override
        returns (uint256[] memory)
    {
        return _changeOrderedTask;
    }

    function getTask(uint256 id)
        external
        view
        override
        returns (
            uint256,
            address,
            TaskStatus
        )
    {
        return (tasks[id].cost, tasks[id].subcontractor, tasks[id].state);
    }

    function approveHash(bytes32 _hash) external override {
        // allowing anyone to sign, as its hard to add restrictions here
        approvedHashes[_msgSender()][_hash] = true;
        emit ApproveHash(_hash, _msgSender());
    }

    // Project-Specific //

    function inviteContractor(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        require(!contractorConfirmed, "Project::GC accepted");
        (address _contractor, address _projectAddress) = abi.decode(
            _data,
            (address, address)
        );
        require(_projectAddress == address(this), "Project::!projectAddress");
        require(_contractor != address(0), "Project::0 address");
        contractor = _contractor;
        contractorConfirmed = true;
        checkSignature(_data, _signature);
        emit ContractorInvited(contractor);
    }

    // New function to delegate rights to contractor
    function delegateContractor(bool _bool) external override {
        require(_msgSender() == builder, "Project::!B");
        require(contractor != address(0), "Project::0 address");
        contractorDelegated = _bool;
        emit ContractorDelegated(_bool);
    }

    function updateProjectHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        checkSignature(_data, _signature);
        (bytes memory _hash, uint256 _nonce) = abi.decode(
            _data,
            (bytes, uint256)
        );
        require(_nonce == hashChangeNonce, "Project::!Nonce");
        hashChangeNonce += 1;
        emit HashUpdated(_hash);
    }

    function lendToProject(uint256 _cost) external override nonReentrant {
        require(
            _msgSender() == builder ||
                _msgSender() == homeFi.communityContract(),
            "Project::!Builder&&!Community"
        );
        require(_cost > 0, "Project::!value>0");
        uint256 _newTotalLent = totalLent + _cost;
        require(
            projectCost() >= uint256(_newTotalLent),
            "Project::value>required"
        );

        if (_msgSender() == builder) {
            currency.safeTransferFrom(_msgSender(), address(this), _cost);
        }

        totalLent = _newTotalLent;
        emit LendToProject(_cost);
        fundProject();
    }

    // Task Specific //

    function addTasks(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        if (_msgSender() != disputes) {
            checkSignature(_data, _signature);
        }
        (
            bytes[] memory _hash,
            uint256[] memory _taskCosts,
            uint256 _taskCount,
            address _projectAddress
        ) = abi.decode(_data, (bytes[], uint256[], uint256, address));
        require(_taskCount == taskCount, "Project::!taskCount");
        require(_projectAddress == address(this), "Project::!projectAddress");
        uint256 _length = _hash.length;
        require(_length == _taskCosts.length, "Project::Lengths !match");

        for (uint256 i = 0; i < _length; i++) {
            _taskCount += 1;
            checkPrecision(_taskCosts[i]);

            tasks[_taskCount].initialize(_taskCosts[i]);
        }
        taskCount = _taskCount;
        emit TasksAdded(_taskCosts, _hash);
    }

    function updateTaskHash(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        (bytes memory _taskHash, uint256 _nonce, uint256 _taskID) = abi.decode(
            _data,
            (bytes, uint256, uint256)
        );
        if (getAlerts(_taskID)[2]) {
            checkSignatureTask(_data, _signature, _taskID);
        } else {
            checkSignature(_data, _signature);
        }
        require(_nonce == hashChangeNonce, "Project::!Nonce");
        hashChangeNonce += 1;
        emit TaskHashUpdated(_taskID, _taskHash);
    }

    function inviteSC(uint256[] calldata _taskList, address[] calldata _scList)
        external
        override
    {
        require(
            _msgSender() == builder || _msgSender() == contractor,
            "Project::!Builder||!GC"
        );
        uint256 _length = _taskList.length;
        require(_length == _scList.length, "Project::Lengths !match");
        for (uint256 i = 0; i < _length; i++) {
            _inviteSC(_taskList[i], _scList[i], false);
        }
        emit MultipleSCInvited(_taskList, _scList);
    }

    function acceptInviteSC(uint256[] calldata _taskList) external override {
        uint256 _length = _taskList.length;
        for (uint256 i = 0; i < _length; i++) {
            tasks[_taskList[i]].acceptInvitation(_msgSender());
        }
        emit SCConfirmed(_taskList);
    }

    function setComplete(bytes calldata _data, bytes calldata _signature)
        external
        override
    {
        (uint256 _taskID, address _projectAddress) = abi.decode(
            _data,
            (uint256, address)
        );
        require(_projectAddress == address(this), "Project::!Project");
        if (_msgSender() != disputes) {
            checkSignatureTask(_data, _signature, _taskID);
        }
        payFee(tasks[_taskID].subcontractor, tasks[_taskID].cost);

        tasks[_taskID].setComplete();
        emit TaskComplete(_taskID);
    }

    function fundProject() public override {
        uint256 _maxLoop = 50;
        uint256 _costToAllocate = totalLent - totalAllocated;
        bool _exceedLimit;
        uint256 i = lastFundedChangeOrderTask;
        uint256 j = lastFundedTask;
        uint256[] memory _taskFunded = new uint256[](
            taskCount - j + _changeOrderedTask.length - i
        );
        uint256 _loopCount;

        /// Change ordered task funding
        if (_changeOrderedTask.length > 0) {
            for (i; i < _changeOrderedTask.length; i++) {
                uint256 _taskCost = tasks[_changeOrderedTask[i]].cost;
                _taskCost = _costWithBuilderFee(_taskCost);
                if (!(_loopCount < _maxLoop)) {
                    _exceedLimit = true;
                    break;
                }
                if (_costToAllocate >= _taskCost) {
                    _costToAllocate -= _taskCost;

                    tasks[_changeOrderedTask[i]].fundTask();
                    _taskFunded[_loopCount] = _changeOrderedTask[i];
                    _loopCount++;
                } else {
                    break;
                }
            }
            // if all the change ordered tasks are funded delete
            // the changeOrderedTask array and reset lastFundedChangeOrderTask
            if (i == _changeOrderedTask.length) {
                lastFundedChangeOrderTask = 0;
                delete _changeOrderedTask;
            } else {
                lastFundedChangeOrderTask = i;
            }
        }

        /// Task funding
        if (j < taskCount) {
            for (++j; j <= taskCount; j++) {
                uint256 _taskCost = tasks[j].cost;
                _taskCost = _costWithBuilderFee(_taskCost);
                if (!(_loopCount < _maxLoop)) {
                    _exceedLimit = true;
                    break;
                }

                if (_costToAllocate >= _taskCost) {
                    _costToAllocate -= _taskCost;

                    tasks[j].fundTask();
                    _taskFunded[_loopCount] = j;
                    _loopCount++;
                } else {
                    break;
                }
            }
            if (j > taskCount) {
                lastFundedTask = taskCount;
            } else lastFundedTask = --j;
        }

        if (_loopCount > 0) emit TaskFunded(_taskFunded);
        if (_exceedLimit) emit IncompleteFund();
        totalAllocated = totalLent - _costToAllocate;
    }

    function recoverTokens(address _tokenAddress) external override {
        if (_tokenAddress == address(currency)) {
            /* If the token address is same as currency of this project,
            then first check if all tasks are complete */
            uint256 _length = taskCount;
            for (uint256 _taskID = 1; _taskID <= _length; _taskID++) {
                require(tasks[_taskID].getState() == 3, "Project::!Complete");
            }
        }
        IToken20 _token = IToken20(_tokenAddress);
        uint256 _leftOutTokens = _token.balanceOf(address(this));
        if (_leftOutTokens > 0) {
            _token.safeTransfer(builder, _leftOutTokens);
        }
    }

    function changeOrder(bytes calldata _data, bytes calldata _signature)
        external
        override
        nonReentrant
    {
        (
            uint256 _taskID,
            address _newSC,
            uint256 _newCost,
            address _project
        ) = abi.decode(_data, (uint256, address, uint256, address));
        if (_msgSender() != disputes) {
            checkSignatureTask(_data, _signature, _taskID);
        }
        require(_project == address(this), "Project::!projectAddress");
        uint256 _taskCost = tasks[_taskID].cost;
        uint256 _oldCostWithFee = _costWithBuilderFee(_taskCost);
        uint256 _newCostWithFee = _costWithBuilderFee(_newCost);
        bool _unapproved = false;
        if (_newCost != _taskCost) {
            checkPrecision(_newCost);
            uint256 _totalAllocated = totalAllocated;
            //only for funded tasks
            if (tasks[_taskID].alerts[1] == true) {
                if (_newCost < _taskCost) {
                    //when _newCost is less than task cost
                    uint256 _withdrawDifference = _oldCostWithFee -
                        _newCostWithFee;
                    totalAllocated -= _withdrawDifference;
                    autoWithdraw(_withdrawDifference);
                } else if (
                    //when _newCost is more than task cost and totalLent is enough
                    totalLent - _totalAllocated >=
                    _newCostWithFee - _oldCostWithFee
                ) {
                    totalAllocated += (_newCostWithFee - _oldCostWithFee);
                } else {
                    //when _newCost is more than task cost and totalLent is not enough.
                    // un confirm SC, mark task as inactive, mark funded as false, mark lifecycle as None
                    _unapproved = true;

                    tasks[_taskID].unApprove();

                    tasks[_taskID].unFundTask();
                    totalAllocated -= _oldCostWithFee; // reduce from total allocated
                    _changeOrderedTask.push(_taskID);
                }
            }

            tasks[_taskID].cost = _newCost;
            emit ChangeOrderFee(_taskID, _newCost);
        }
        if (_newSC != tasks[_taskID].subcontractor) {
            if (!_unapproved) {
                tasks[_taskID].unApprove();
            }
            if (_newSC != address(0)) {
                _inviteSC(_taskID, _newSC, true); // inviteSubcontractor
            } else {
                tasks[_taskID].subcontractor = address(0);
            }
            emit ChangeOrderSC(_taskID, _newSC);
        }
    }

    function raiseDispute(bytes calldata _data, bytes calldata _signature)
        external
        override
        returns (uint256)
    {
        address signer = SignatureDecoder.recoverKey(
            keccak256(_data),
            _signature,
            0
        );
        (address _project, uint256 _task, , , ) = abi.decode(
            _data,
            (address, uint256, uint8, bytes, bytes)
        );
        require(_project == address(this), "Project::!Contract");
        if (_task == 0) {
            require(
                signer == builder || signer == contractor,
                "Project::!(GC||Builder)"
            );
        } else {
            require(
                signer == builder ||
                    signer == contractor ||
                    signer == tasks[_task].subcontractor,
                "Project::!(GC||Builder||SC)"
            );
            if (signer == tasks[_task].subcontractor) {
                require(getAlerts(_task)[2], "Project::!SCConfirmed");
            }
        }
        return IDisputes(disputes).raiseDispute(_data, _signature);
    }

    /// VIEWABLE FUNCTIONS ///

    function isTrustedForwarder(address _forwarder)
        public
        view
        override(ERC2771ContextUpgradeable, IProject)
        returns (bool)
    {
        return homeFi.isTrustedForwarder(_forwarder);
    }

    function getAlerts(uint256 _taskID)
        public
        view
        override
        returns (bool[3] memory _alerts)
    {
        return tasks[_taskID].getAlerts();
    }

    function projectCost() public view override returns (uint256 _cost) {
        uint256 _length = taskCount;
        for (uint256 _taskID = 1; _taskID <= _length; _taskID++) {
            _cost += tasks[_taskID].cost;
        }
        _cost = _costWithBuilderFee(_cost);
    }

    /// INTERNAL FUNCTIONS ///

    /**
     * @notice invite subcontractors for a single task. This can be called by builder or contractor.
     * @dev invite subcontractors for a single task. This can be called by builder or contractor.
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
        require(_sc != address(0), "Project::0 address");

        tasks[_taskID].inviteSubcontractor(_sc);
        if (_emitEvent) {
            emit SingleSCInvited(_taskID, _sc);
        }
    }

    /**
     * @dev transfer funds to contractor or subcontract, on completion of task respectively.
     */
    function payFee(address _recipient, uint256 _amount) internal {
        uint256 _builderFee = (_amount * builderFee) / 1000;
        address _treasury = homeFi.treasury();
        currency.safeTransfer(_treasury, _builderFee);
        currency.safeTransfer(_recipient, _amount);
    }

    /**
     * @dev transfer excess funds back to builder wallet.
     * Called internally when task changeOrder when new task cost is lower than older cost
     * @param _amount uint256 - amount of excess fund
     */
    function autoWithdraw(uint256 _amount) internal {
        totalLent -= _amount;
        currency.safeTransfer(builder, _amount);
        emit AutoWithdrawn(_amount);
    }

    /**
     * @dev check if recovered signatures match with builder and contractor address.
     * signatures must be in sequential order. First builder and then contractor.
     * reverts if signature do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     */
    function checkSignature(bytes calldata _data, bytes calldata _signature)
        internal
    {
        bytes32 _hash = keccak256(_data);
        if (contractor == address(0)) {
            // when there is no contractor, just check for builder's signature
            checkSignatureValidity(builder, _hash, _signature, 0);
        } else {
            // when there is a contractor
            if (contractorDelegated) {
                // when builder has delegated his rights to contractor, just check contractor's signature
                checkSignatureValidity(contractor, _hash, _signature, 0);
            } else {
                // when builder has not delegated rights to contractor, check for both B and GC signatures
                checkSignatureValidity(builder, _hash, _signature, 0);
                checkSignatureValidity(contractor, _hash, _signature, 1);
            }
        }
    }

    /**
     * @dev check if recovered signatures match with builder, contractor and subcontractor address for a task.
     * signatures must be in sequential order. First builder, then contractor, and then subcontractor.
     * reverts if signatures do not match.
     * @param _data bytes encoded parameters
     * @param _signature bytes appended signatures
     * @param _taskID index of the task.
     */
    function checkSignatureTask(
        bytes calldata _data,
        bytes calldata _signature,
        uint256 _taskID
    ) internal {
        bytes32 _hash = keccak256(_data);
        address _sc = tasks[_taskID].subcontractor;
        if (contractor == address(0)) {
            // when there is no contractor, just check for B and SC sign
            checkSignatureValidity(builder, _hash, _signature, 0);
            checkSignatureValidity(_sc, _hash, _signature, 1);
        } else {
            // when there is a contractor
            if (contractorDelegated) {
                // when builder has delegated his rights to contractor, just check for GC and SC sign
                checkSignatureValidity(contractor, _hash, _signature, 0);
                checkSignatureValidity(_sc, _hash, _signature, 1);
            } else {
                // when builder has not delegated rights to contractor, check for B, SC and GC signatures
                checkSignatureValidity(builder, _hash, _signature, 0);
                checkSignatureValidity(contractor, _hash, _signature, 1);
                checkSignatureValidity(_sc, _hash, _signature, 2);
            }
        }
    }

    /**
     * Internal function for checking signature validity
     * @dev checks if the signature is approved or recovered
     *
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

    /**
     * @dev check if precision is greater than 1000, if so it reverts
     * @param _amount amount needed to be checked for precision.
     */
    function checkPrecision(uint256 _amount) internal pure {
        require(
            ((_amount / 1000) * 1000) == _amount,
            "Project::Precision>=1000"
        );
    }

    /**
     * @dev returns the amount after adding builder fee
     * @param _amount amount to upon which builder fee is taken
     */
    function _costWithBuilderFee(uint256 _amount)
        internal
        view
        returns (uint256 _amountWithFee)
    {
        _amountWithFee = _amount + (_amount * builderFee) / 1000;
    }
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
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
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