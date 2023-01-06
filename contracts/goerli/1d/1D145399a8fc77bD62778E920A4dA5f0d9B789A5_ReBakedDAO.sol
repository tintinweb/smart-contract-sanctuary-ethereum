// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { IReBakedDAO } from "./interfaces/IReBakedDAO.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { Project, ProjectLibrary } from "./libraries/ProjectLibrary.sol";
import { Package, PackageLibrary } from "./libraries/PackageLibrary.sol";
import { Collaborator, CollaboratorLibrary } from "./libraries/CollaboratorLibrary.sol";
import { Observer, ObserverLibrary } from "./libraries/ObserverLibrary.sol";

/**
 *  @title  ReBakedDAO Contract
 *  @author ReBaked Team
 */
contract ReBakedDAO is IReBakedDAO, OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using ProjectLibrary for Project;
    using PackageLibrary for Package;
    using CollaboratorLibrary for Collaborator;
    using ObserverLibrary for Observer;

    // Percent Precision PPM (parts per million)
    uint256 public constant PCT_PRECISION = 1e6;

    // Rebaked DAO wallet
    address public treasury;

    // projectId => Project
    mapping(bytes32 => Project) private projectData;

    // projectId => packageId => Package
    mapping(bytes32 => mapping(bytes32 => Package)) private packageData;

    // projectId => packageId => address collaborator
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) private approvedUser;

    // projectId => packageId => address collaborator
    mapping(bytes32 => mapping(bytes32 => mapping(address => Collaborator))) private collaboratorData;

    // projectId => packageId => address observer
    mapping(bytes32 => mapping(bytes32 => mapping(address => Observer))) private observerData;

    /**
     * @notice Throws if amount provided is zero
     */
    modifier nonZero(uint256 amount_) {
        require(amount_ > 0, "Zero amount");
        _;
    }

    /**
     * @notice Throws if called by any account other than the project initiator
     */
    modifier onlyInitiator(bytes32 _projectId) {
        require(projectData[_projectId].initiator == _msgSender(), "caller is not project initiator");
        _;
    }

    /**
     * @notice Initialize of contract (replace for constructor)
     * @param treasury_ Treasury address
     */
    function initialize(address treasury_) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();

        require(treasury_ != address(0), "invalid treasury address");

        treasury = treasury_;
    }

    /* --------EXTERNAL FUNCTIONS-------- */

    /**
     * @notice Update treasury address
     * @param treasury_ Treasury address
     * Emit {UpdatedTreasury}
     */
    function updateTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "invalid treasury address");
        address oldTreasury = treasury;
        treasury = treasury_;

        emit UpdatedTreasury(oldTreasury, treasury);
    }

    /**
     * @dev Creates project proposal
     * @param token_ project token address
     * @param budget_ total budget (has to be approved on token contract if project has its own token)
     *
     * Emit {CreatedProject}
     */
    function createProject(address token_, uint256 budget_) external nonZero(budget_) nonReentrant {
        require(token_ != address(0), "Invalid token address");
        bytes32 _projectId = _generateProjectId();
        projectData[_projectId]._createProject(token_, budget_);
        emit CreatedProject(_projectId, _msgSender(), token_, budget_);
    }

    /**
     * @notice Finishes project
     * @param _projectId Id of the project
     * Emit {FinishedProject}
     */
    function finishProject(bytes32 _projectId) external onlyInitiator(_projectId) nonReentrant {
        uint256 budgetLeft_ = projectData[_projectId]._finishProject();
        emit FinishedProject(_projectId, budgetLeft_);
    }

    /**
     * @notice Creates package in project
     * @param _projectId Id of the project
     * @param _budget MGP budget
     * @param _bonus Bonus budget
     * @param _observerBudget Observer budget
     * @param _collaboratorsLimit limit on number of collaborators
     * @param _observers List of observers
     * Emit {CreatedPackage}
     */
    function createPackage(
        bytes32 _projectId,
        uint256 _budget,
        uint256 _bonus,
        uint256 _observerBudget,
        uint256 _collaboratorsLimit,
        address[] memory _observers
    ) external onlyInitiator(_projectId) nonZero(_budget) nonReentrant {
        Project storage project = projectData[_projectId];
        uint256 total = _budget + _bonus + _observerBudget;
        project._reservePackagesBudget(total);
        bytes32 _packageId = _generatePackageId(_projectId, 0);
        Package storage package = packageData[_projectId][_packageId];
        package._createPackage(_budget, _observerBudget, _bonus, _collaboratorsLimit);
        IERC20Upgradeable(project.token).safeTransferFrom(_msgSender(), treasury, (total * 5) / 100);

        if (_observers.length > 0) {
            require(_observerBudget > 0, "invalid observers budget");
            _addObservers(_projectId, _packageId, _observers);
        }

        emit CreatedPackage(_projectId, _packageId, _budget, _bonus, _observerBudget);
    }

    /**
     * @notice Finishes package in project
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborators List of collaborators
     * @param _observers List of observers
     * @param _scores List of bonus scores for collaborators
     *
     * Emit {FinishedPackage}
     */
    function finishPackage(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _collaborators,
        address[] memory _observers,
        uint256[] memory _scores
    ) external onlyInitiator(_projectId) {
        Package storage package = packageData[_projectId][_packageId];
        require(_collaborators.length == package.totalCollaborators, "invalid collaborators list");
        require(_collaborators.length == _scores.length, "arrays' length mismatch");
        require(_observers.length == package.totalObservers, "invalid observers list");

        uint256 budgetLeft_ = package._finishPackage();
        projectData[_projectId]._finishPackage(budgetLeft_);

        if (package.bonus > 0 && _collaborators.length > 0) {
            uint256 _totalBonusScores = 0;
            for (uint256 i = 0; i < _scores.length; i++) {
                require(_scores[i] > 0, "invalid bonus score");
                _totalBonusScores += _scores[i];
            }
            require(_totalBonusScores == PCT_PRECISION, "incorrect total bonus scores");
        }

        for (uint256 i = 0; i < _collaborators.length; i++) {
            _payCollaboratorRewards(_projectId, _packageId, _collaborators[i], _scores[i]);
        }

        for (uint256 i = 0; i < _observers.length; i++) {
            _payObserverFee(_projectId, _packageId, _observers[i]);
        }

        emit FinishedPackage(_projectId, _packageId, budgetLeft_);
    }

    /**
     * @notice Cancel package in project and release project budget
     * @param _projectId Id of the project
     * @param _packageId Id of the project
     * @param _collaborators address of the collaborators
     * @param _observers address of the observers
     * Emit {CanceledPackage}
     */
    function cancelPackage(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _collaborators,
        address[] memory _observers,
        bool _workStarted
    ) external onlyInitiator(_projectId) {
        Package storage package = packageData[_projectId][_packageId];
        require(_collaborators.length == package.totalCollaborators, "invalid collaborators length");
        require(_observers.length == package.totalObservers, "invalid observers length");

        package._cancelPackage();

        if (_workStarted) {
            for (uint256 i = 0; i < _collaborators.length; i++) _payCollaboratorRewards(_projectId, _packageId, _collaborators[i], 0);
            for (uint256 i = 0; i < _observers.length; i++) _payObserverFee(_projectId, _packageId, _observers[i]);
        }

        uint256 budgetToBeReverted_ = (package.budget - package.budgetPaid) + package.bonus;
        budgetToBeReverted_ += (package.budgetObservers - package.budgetObserversPaid);
        projectData[_projectId]._revertPackageBudget(budgetToBeReverted_);

        emit CanceledPackage(_projectId, _packageId, budgetToBeReverted_);
    }

    /**
     * @notice Adds collaborator to package
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborators' addresses
     * @param _mgp MGP amount
     * Emit {AddedCollaborator}
     */
    function addCollaborator(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator,
        uint256 _mgp
    ) external onlyInitiator(_projectId) nonZero(_mgp) {
        require(_collaborator != address(0), "collaborator's address is zero");

        collaboratorData[_projectId][_packageId][_collaborator]._addCollaborator(_mgp);
        packageData[_projectId][_packageId]._allocateBudget(_mgp);

        emit AddedCollaborator(_projectId, _packageId, _collaborator, _mgp);
    }

    /**
     * @notice Approves collaborator's MGP or deletes collaborator (should be called by admin)
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborator's address
     * Emit {ApprovedCollaborator}
     */
    function approveCollaborator(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator
    ) external onlyInitiator(_projectId) {
        approvedUser[_projectId][_packageId][_collaborator] = true;

        collaboratorData[_projectId][_packageId][_collaborator]._approveCollaborator();
        packageData[_projectId][_packageId]._approveCollaborator();

        emit ApprovedCollaborator(_projectId, _packageId, _collaborator);
    }

    /**
     * @notice Approves collaborator's MGP or deletes collaborator (should be called by admin)
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborator's address
     * @param _shouldPayMgp Should pay MGP for the collaborator
     * Emit {RemovedCollaborator}
     */
    function removeCollaborator(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator,
        bool _shouldPayMgp
    ) external onlyInitiator(_projectId) {
        require(!approvedUser[_projectId][_packageId][_collaborator], "collaborator approved already!");

        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_collaborator];
        if (_shouldPayMgp) {
            _payCollaboratorRewards(_projectId, _packageId, _collaborator, 0);
        }

        collaborator._removeCollaborator();
        packageData[_projectId][_packageId]._removeCollaborator(_shouldPayMgp, collaborator.mgp);

        emit RemovedCollaborator(_projectId, _packageId, _collaborator);
    }

    /**
     * @notice Self remove collaborator
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * Emit {RemovedCollaborator}
     */
    function selfRemove(bytes32 _projectId, bytes32 _packageId) external {
        require(!approvedUser[_projectId][_packageId][_msgSender()], "collaborator approved already!");

        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_msgSender()];
        collaborator._removeCollaborator();
        packageData[_projectId][_packageId]._removeCollaborator(false, collaborator.mgp);

        emit RemovedCollaborator(_projectId, _packageId, _msgSender());
    }

    function _addObservers(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _observers
    ) private {
        require(_observers.length > 0, "empty observers array!");

        for (uint256 i = 0; i < _observers.length; i++) {
            require(_observers[i] != address(0), "zero observer's address!");
            observerData[_projectId][_packageId][_observers[i]]._addObserver();
        }
        packageData[_projectId][_packageId]._addObservers(_observers.length);

        emit AddedObservers(_projectId, _packageId, _observers);
    }

    /**
     * @notice Adds observer to packages
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _observers observers' addresses
     * Emit {AddedObservers}
     */
    function addObservers(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _observers
    ) external onlyInitiator(_projectId) {
        _addObservers(_projectId, _packageId, _observers);
    }

    /**
     * @notice Removes observer from packages
     * @param _projectId Id of the project
     * @param _packageId package id
     * @param _observers observers' addresses
     * Emit {RemovedObservers}
     */
    function removeObservers(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _observers
    ) external onlyInitiator(_projectId) {
        require(_observers.length > 0, "empty observers array!");

        for (uint256 i = 0; i < _observers.length; i++) {
            observerData[_projectId][_packageId][_observers[i]]._removeObserver();
        }
        packageData[_projectId][_packageId]._removeObservers(_observers.length);

        emit RemovedObservers(_projectId, _packageId, _observers);
    }

    function updateObservers(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _observersIn,
        address[] memory _observersOut
    ) external onlyInitiator(_projectId) {
        require(_observersIn.length > 0 || _observersOut.length > 0, "empty observers arrays!");

        if (_observersIn.length > 0) {
            for (uint256 i = 0; i < _observersIn.length; i++) {
                observerData[_projectId][_packageId][_observersIn[i]]._addObserver();
            }
            packageData[_projectId][_packageId]._addObservers(_observersIn.length);

            emit AddedObservers(_projectId, _packageId, _observersIn);
        }

        if (_observersOut.length > 0) {
            for (uint256 i = 0; i < _observersOut.length; i++) {
                observerData[_projectId][_packageId][_observersOut[i]]._removeObserver();
            }

            packageData[_projectId][_packageId]._removeObservers(_observersOut.length);

            emit RemovedObservers(_projectId, _packageId, _observersOut);
        }
    }

    /* --------VIEW FUNCTIONS-------- */

    /**
     * @notice Get project details
     * @param _projectId Id of the project
     */
    function getProjectData(bytes32 _projectId) external view returns (Project memory) {
        return projectData[_projectId];
    }

    /**
     * @notice Get package details
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     */
    function getPackageData(bytes32 _projectId, bytes32 _packageId) external view returns (Package memory) {
        return (packageData[_projectId][_packageId]);
    }

    /**
     * @notice Get collaborator details
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator Collaborator address
     */
    function getCollaboratorData(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator
    ) external view returns (Collaborator memory) {
        return collaboratorData[_projectId][_packageId][_collaborator];
    }

    /**
     * @notice Get collaborator rewards
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator Collaborator address
     */
    function getCollaboratorRewards(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator
    ) public view returns (uint256, uint256) {
        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_collaborator];

        return (collaborator.mgp, collaborator.bonus);
    }

    /**
     * @notice Get observer details
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _observer Observer address
     */
    function getObserverData(
        bytes32 _projectId,
        bytes32 _packageId,
        address _observer
    ) external view returns (Observer memory) {
        return observerData[_projectId][_packageId][_observer];
    }

    /**
     * @notice Get observer fee
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _observer Observer address
     */
    function getObserverFee(
        bytes32 _projectId,
        bytes32 _packageId,
        address _observer
    ) public view returns (uint256) {
        Observer storage observer = observerData[_projectId][_packageId][_observer];
        if (observer.timePaid > 0 || observer.timeCreated == 0 || observer.isRemoved) {
            return 0;
        }
        return packageData[_projectId][_packageId]._getObserverFee();
    }

    /* --------PRIVATE FUNCTIONS-------- */

    /**
     * @notice Pay fee to observer
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator observer address
     * @param _score Bonus score of collaborator
     * Emit {PaidCollaboratorRewards}
     */
    function _payCollaboratorRewards(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator,
        uint256 _score
    ) private {
        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_collaborator];
        Package storage package = packageData[_projectId][_packageId];

        uint256 bonus_;
        if (package.bonus > 0 && _score > 0) {
            bonus_ = (package.collaboratorsPaidBonus + 1 == package.totalCollaborators)
                    ? (package.bonus - package.bonusPaid)
                    : (package.bonus * _score) / PCT_PRECISION;
        }

        collaboratorData[_projectId][_packageId][_collaborator]._payReward(bonus_);
        packageData[_projectId][_packageId]._payReward(collaborator.mgp, bonus_);
        projectData[_projectId]._pay(_collaborator, collaborator.mgp + bonus_);

        emit PaidCollaboratorRewards(_projectId, _packageId, _collaborator, collaborator.mgp, bonus_);
    }

    /**
     * @notice Pay fee to observer
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _observer observer address
     * Emit {PaidObserverFee}
     */
    function _payObserverFee(
        bytes32 _projectId,
        bytes32 _packageId,
        address _observer
    ) private {
        observerData[_projectId][_packageId][_observer]._payObserverFee();

        uint256 amount_ = packageData[_projectId][_packageId]._getObserverFee();
        packageData[_projectId][_packageId]._payObserverFee(amount_);
        projectData[_projectId]._pay(_observer, amount_);

        emit PaidObserverFee(_projectId, _packageId, _observer, amount_);
    }

    /**
     * @notice Generates unique id hash based on _msgSender() address and previous block hash.
     * @param _nonce nonce
     * @return Id
     */
    function _generateId(uint256 _nonce) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1), _nonce));
    }

    /**
     * @notice Returns a new unique project id.
     * @return _projectId Id of the project.
     */
    function _generateProjectId() private view returns (bytes32 _projectId) {
        _projectId = _generateId(0);
        require(projectData[_projectId].timeCreated == 0, "duplicate project id");
    }

    /**
     * @notice Returns a new unique package id.
     * @param _projectId Id of the project
     * @param _nonce nonce
     * @return _packageId Id of the package
     */
    function _generatePackageId(bytes32 _projectId, uint256 _nonce) private view returns (bytes32 _packageId) {
        _packageId = _generateId(_nonce);
        require(packageData[_projectId][_packageId].timeCreated == 0, "duplicate package id");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface IReBakedDAO {
    event UpdatedTreasury(address oldTreasury, address newTreasury);
    event CreatedProject(bytes32 indexed projectId, address initiator, address token, uint256 budget);
    event StartedProject(bytes32 indexed projectId);
    event ApprovedProject(bytes32 indexed projectId);
    event FinishedProject(bytes32 indexed projectId, uint256 budgetLeft);
    event CreatedPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 budget, uint256 bonus, uint256 observerBudget);
    event AddedObservers(bytes32 indexed projectId, bytes32 indexed packageId, address[] observers);
    event RemovedObservers(bytes32 indexed projectId, bytes32 indexed packageId, address[] observers);
    event AddedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 mgp);
    event ApprovedCollaborator(bytes32 indexed projectId, bytes32 indexed packageId, address collaborator);
    event RemovedCollaborator(bytes32 indexed projectId_, bytes32 indexed packageId_, address collaborator_);
    event FinishedPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 indexed budgetLeft);
    event CanceledPackage(bytes32 indexed projectId, bytes32 indexed packageId, uint256 indexed revertedBudget);
    event PaidObserverFee(bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 amount);
    event PaidCollaboratorRewards(bytes32 indexed projectId, bytes32 indexed packageId, address collaborator, uint256 mgp, uint256 bonus);

    /**
     * @notice Update treasury address
     * @param treasury_ Treasury address
     * Emit {UpdatedTreasury}
     */
    function updateTreasury(address treasury_) external;

    /**
     * @dev Creates project proposal
     * @param token_ project token address, zero addres if project has not token yet
     * (IOUToken will be deployed on project approval)
     * @param budget_ total budget (has to be approved on token contract if project has its own token)
     *
     * @dev (`token_` == ZERO_ADDRESS) ? project has no token yet : `IOUToken` will be deployed on project approval
     * Emit {CreatedProject}
     */
    function createProject(address token_, uint256 budget_) external;

    /**
     * @notice Finishes project
     * @param _projectId Id of the project
     * Emit {FinishedProject}
     */
    function finishProject(bytes32 _projectId) external;

    /**
     * @notice Creates package in project
     * @param _projectId Id of the project
     * @param _budget MGP budget
     * @param _bonus Bonus budget
     * @param _observerBudget Observer budget
     * @param _collaboratorsLimit maximum collaborators
     * @param _observers List of observers
     * Emit {CreatedPackage}
     */
    function createPackage(
        bytes32 _projectId,
        uint256 _budget,
        uint256 _bonus,
        uint256 _observerBudget,
        uint256 _collaboratorsLimit,
        address[] memory _observers
    ) external;

    /**
     * @notice Finishes package in project
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborators List of collaborators
     * @param _observers List of observers
     * @param _scores List of bonus scores for collaborators
     * 
     * Emit {FinishedPackage}
     */
    function finishPackage(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _collaborators,
        address[] memory _observers,
        uint256[] memory _scores
    ) external;

    /**
     * @notice Cancel package in project and release project budget
     * @param _projectId Id of the project
     * @param _packageId Id of the project
     * @param _collaborators address of the collaborators
     * @param _observers address of the observers
     * Emit {CanceledPackage}
     */
    function cancelPackage(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _collaborators,
        address[] memory _observers,
        bool _workStarted
    ) external;

    /**
     * @notice Adds collaborator to package
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborators' addresses
     * @param _mgp MGP amount
     * Emit {AddedCollaborator}
     */
    function addCollaborator(bytes32 _projectId, bytes32 _packageId, address _collaborator, uint256 _mgp) external;

    /**
     * @notice Approves collaborator's MGP or deletes collaborator (should be called by admin)
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborator's address
     * Emit {ApprovedCollaborator}
     */
    function approveCollaborator(bytes32 _projectId, bytes32 _packageId, address _collaborator) external;

    /**
     * @notice Approves collaborator's MGP or deletes collaborator (should be called by admin)
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _collaborator collaborator's address
     * @param _shouldPayMgp Should pay MGP for the collaborator
     * Emit {RemovedCollaborator}
     */
    function removeCollaborator(bytes32 _projectId, bytes32 _packageId, address _collaborator, bool _shouldPayMgp) external;

    /**
     * @notice Self remove collaborator
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * Emit {RemovedCollaborator}
     */
    function selfRemove(bytes32 _projectId, bytes32 _packageId) external;

    /**
     * @notice Adds observers to package
     * @param _projectId Id of the project
     * @param _packageId Id of the package
     * @param _observers observers' addresses
     * Emit {AddedObservers}
     */
    function addObservers(bytes32 _projectId, bytes32 _packageId, address[] memory _observers) external;

    /**
     * @notice Removes observers from package
     * @param _projectId Id of the project
     * @param _packageId package id
     * @param _observers observers' addresses
     * Emit {RemovedObservers}
     */
    function removeObservers(bytes32 _projectId, bytes32 _packageId, address[] memory _observers) external;

    /**
     * @notice Adds, removes observers from package
     * @param _projectId Id of the project
     * @param _packageId package id
     * @param _observersIn observers' addresses to be added
     * @param _observersOut observers' addresses to be removed
     * Emit {AddedObservers} {RemovedObservers}
     */
    function updateObservers(
        bytes32 _projectId,
        bytes32 _packageId,
        address[] memory _observersIn,
        address[] memory _observersOut
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { Package } from "./Structs.sol";

library PackageLibrary {
    uint256 public constant MAX_COLLABORATORS = 10;
    uint256 public constant MAX_OBSERVERS = 10;

    /**
	@notice Throws if there is no package
	 */
    modifier onlyActivePackage(Package storage package_) {
        require(package_.isActive, "no such package");
        _;
    }

    /**
     * @notice Creates package in project
     * @param package_ reference to Package struct
     * @param budget_ MGP budget
     * @param feeObserversBudget_ Observers fee budget
     * @param bonus_ Bonus budget
     * @param collaboratorsLimit_ Limit on number of collaborators
     */
    function _createPackage(
        Package storage package_,
        uint256 budget_,
        uint256 feeObserversBudget_,
        uint256 bonus_,
        uint256 collaboratorsLimit_
    ) internal {
        require(0 < collaboratorsLimit_ && collaboratorsLimit_ <= MAX_COLLABORATORS, "incorrect collaborators limit");
        package_.budget = budget_;
        package_.budgetObservers = feeObserversBudget_;
        package_.bonus = bonus_;
        package_.collaboratorsLimit = collaboratorsLimit_;
        package_.timeCreated = block.timestamp;
        package_.isActive = true;
    }

    /**
     * @notice Cancel package in project
     * @param package_ Package want to cancel
     */
    function _cancelPackage(Package storage package_) internal onlyActivePackage(package_) {
        package_.timeCanceled = block.timestamp;
        package_.isActive = false;
    }

    /**
     * @notice Adds observer to package
     * @param package_ reference to Package struct
     */
    function _addObserver(Package storage package_) internal onlyActivePackage(package_) {
        require(package_.totalObservers < MAX_OBSERVERS, "max observers reached");
        package_.totalObservers++;
    }

    /**
     * @notice Adds observers to package
     * @param package_ reference to Package struct
     * @param count_ number of observers
     */
    function _addObservers(Package storage package_, uint256 count_) internal onlyActivePackage(package_) {
        require(package_.totalObservers + count_ <= MAX_OBSERVERS, "max observers reached");
        package_.totalObservers += count_;
    }

    /**
     * @notice Removes observer from package
     * @param package_ reference to Package struct
     */
    function _removeObserver(Package storage package_) internal onlyActivePackage(package_) {
        package_.totalObservers--;
    }

    /**
     * @notice Removes observers from package
     * @param package_ reference to Package struct
     * @param count_ number of observers
     */
    function _removeObservers(Package storage package_, uint256 count_) internal onlyActivePackage(package_) {
        package_.totalObservers -= count_;
    }

    /**
     * @notice Allocate budget to collaborator and increase number of collaborators
     * @param amount_ amount to reserve
     */
    function _allocateBudget(Package storage package_, uint256 amount_) internal onlyActivePackage(package_) {
        require(package_.budget >= package_.budgetAllocated + amount_, "not enough package budget left");
        require(package_.totalCollaborators < package_.collaboratorsLimit, "collaborators limit reached");
        package_.budgetAllocated += amount_;
        package_.totalCollaborators++;
    }

    /**
     * @notice Increase number of approved Collaborator
     * @param package_ reference to Package struct
     */
    function _approveCollaborator(Package storage package_) internal onlyActivePackage(package_) {
        package_.approvedCollaborators++;
    }

    /**
     * @notice Remove collaborator from package
     * @param package_ Package want to cancel
     * @param mgp_ MGP amount
     */
    function _removeCollaborator(Package storage package_, bool paidMgp_, uint256 mgp_) internal onlyActivePackage(package_) {
        if (!paidMgp_) {
            package_.budgetAllocated -= mgp_;
        }
        package_.totalCollaborators--;
    }

    /**
     * @notice Finishes package in project, checks if already finished, records time
     * if budget left and there is no collaborators, bonus is refunded to package budget
     * @param package_ reference to Package struct
     */
    function _finishPackage(Package storage package_) internal onlyActivePackage(package_) returns (uint256 budgetLeft_) {
        require(package_.totalCollaborators == package_.approvedCollaborators, "unapproved collaborators left");
        budgetLeft_ = package_.budget - package_.budgetAllocated;
        if (package_.totalObservers == 0) budgetLeft_ += package_.budgetObservers;
        if (package_.totalCollaborators == 0) budgetLeft_ += package_.bonus;
        package_.timeFinished = block.timestamp;
        package_.isActive = false;
        return budgetLeft_;
    }

    /**
     * @notice Get observer's claimable portion in package
     * @param package_ reference to Package struct
     */
    function _getObserverFee(Package storage package_) internal view returns (uint256) {
        uint256 remains = package_.budgetObservers - package_.budgetObserversPaid;
        //slither-disable-next-line divide-before-multiply
        uint256 portion = package_.budgetObservers / package_.totalObservers;
        return (remains < 2 * portion) ? remains : portion;
    }

    /**
     * @notice Increases package's observers budget paid
     * @param package_ reference to Package struct
     */
    function _payObserverFee(Package storage package_, uint256 amount_) internal {
        package_.budgetObserversPaid += amount_;
    }


    /**
     * @notice Pay Reward to budget
     * @param package_ reference to Package struct
     * @param mgp_ MGP amount
     * @param bonus_ Bonus amount
     */
    function _payReward(
        Package storage package_,
        uint256 mgp_,
        uint256 bonus_
    ) internal {
        package_.budgetPaid += mgp_;
        if (bonus_ > 0) {
            package_.bonusPaid += bonus_;
            package_.collaboratorsPaidBonus++;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { Observer } from "./Structs.sol";

library ObserverLibrary {
    /**
	@notice Throws if there is no such observer
	 */
    modifier onlyActiveObserver(Observer storage observer_) {
        require(observer_.timeCreated > 0 && !observer_.isRemoved, "no such observer");
        _;
    }

    /**
     * @notice Add observer to package
     * @param _observer Observer address
     */
    function _addObserver(Observer storage _observer) internal {
        require(_observer.timeCreated == 0, "observer already added");
        _observer.timeCreated = block.timestamp;
    }

    /**
     * @notice Remove observer from package
     * @param _observer Observer address
     */
    function _removeObserver(Observer storage _observer) internal onlyActiveObserver(_observer) {
        _observer.isRemoved = true;
    }

    /**
     * @notice Observer claim fee
     * @param _observer Observer address
     */
    function _payObserverFee(Observer storage _observer) internal onlyActiveObserver(_observer) {
        require(_observer.timePaid == 0, "observer fee already paid");
        _observer.timePaid = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { IERC20Upgradeable, SafeERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import { ITokenFactory } from "../interfaces/ITokenFactory.sol";
import { Project } from "./Structs.sol";

library ProjectLibrary {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /**
     * @notice Creates project proposal
     * @param project_ reference to Project struct
     * @param token_ project token address
     * @param budget_ total budget
     */
    function _createProject(
        Project storage project_,
        address token_,
        uint256 budget_
    ) internal {
        project_.initiator = msg.sender;
        project_.token = token_;
        project_.budget = budget_;
        project_.timeCreated = block.timestamp;

        IERC20Upgradeable(project_.token).safeTransferFrom(msg.sender, address(this), project_.budget);
    }

    /**
     * @notice Finishes project, checks if already finished or unfinished packages left
     * unallocated budget returned to initiator or burned (in case of IOUToken)
     * @param project_ reference to Project struct
     */
    function _finishProject(Project storage project_) internal returns (uint256) {
        require(project_.timeFinished == 0, "already finished project");
        require(project_.totalPackages == project_.totalFinishedPackages, "unfinished packages left");
        project_.timeFinished = block.timestamp;
        uint256 budgetLeft_ = project_.budget - project_.budgetAllocated;
        if (budgetLeft_ > 0) {
            IERC20Upgradeable(project_.token).safeTransfer(project_.initiator, budgetLeft_);
        }
        return budgetLeft_;
    }

    /**
     * @notice Creates package in project, check if there is budget available
     * allocates budget and increase total number of packages
     * @param project_ reference to Project struct
     * @param totalBudget_ total budget MGP + Bonus
     */
    function _reservePackagesBudget(
        Project storage project_,
        uint256 totalBudget_
    ) internal {
        require(project_.timeFinished == 0, "project is finished");
        require(project_.budget >= project_.budgetAllocated + totalBudget_, "not enough project budget left");
        project_.budgetAllocated += totalBudget_;
        project_.totalPackages += 1;
    }

    /**
     * @notice Get back package budget package
     * @param project_ Project reference address
     * @param budgetToBeReverted_ Budget amount to be reverted
     */
    function _revertPackageBudget(Project storage project_, uint256 budgetToBeReverted_) internal {
        project_.budgetAllocated -= budgetToBeReverted_;
        project_.totalPackages--;
    }

    /**
     * @notice Finishes package in project, budget left addded refunded back to project budget
     * increases total number of finished packages
     * @param project_ reference to Project struct
     * @param budgetLeft_ amount of budget left
     */
    function _finishPackage(Project storage project_, uint256 budgetLeft_) internal {
        if (budgetLeft_ > 0) project_.budgetAllocated -= budgetLeft_;
        project_.totalFinishedPackages++;
    }

    /**
     * @notice Pays from project's budget, increases budget paid
     * @param project_ reference to Project struct
     * @param amount_ amount to pay
     */
    function _pay(
        Project storage project_,
        address receiver_,
        uint256 amount_
    ) internal {
        project_.budgetPaid += amount_;
        IERC20Upgradeable(project_.token).safeTransfer(receiver_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import { Collaborator } from "./Structs.sol";

library CollaboratorLibrary {
    /**
	@notice Throws if there is no such collaborator
	*/
    modifier onlyActiveCollaborator(Collaborator storage collaborator_) {
        require(collaborator_.timeCreated > 0 && !collaborator_.isRemoved, "no such collaborator");
        _;
    }

    /**
     * @notice Adds collaborator, checks for zero address and if already added, records mgp
     * @param collaborator_ reference to Collaborator struct
     * @param collaborator_ collaborator's address
     * @param mgp_ minimum guaranteed payment
     */
    function _addCollaborator(Collaborator storage collaborator_, uint256 mgp_) internal {
        require(collaborator_.isRemoved || collaborator_.timeCreated == 0, "collaborator already added");

        collaborator_.mgp = mgp_;
        collaborator_.isRemoved = false;
        collaborator_.timeCreated = block.timestamp;
    }

    /**
     * @notice Approves collaborator's MGP or deletes collaborator
     * @param collaborator_ reference to Collaborator struct
     */
    function _approveCollaborator(Collaborator storage collaborator_) internal onlyActiveCollaborator(collaborator_) {
        require(collaborator_.timeMgpApproved == 0, "collaborator already approved");
        collaborator_.timeMgpApproved = block.timestamp;
    }

    function _removeCollaborator(Collaborator storage collaborator_) internal onlyActiveCollaborator(collaborator_) {
        collaborator_.isRemoved = true;
    }

    /**
     * @notice Pay Reward to collaborator
     * @param collaborator_ collaborator
     * @param bonus_ bonus of collaborator
     */
    function _payReward(Collaborator storage collaborator_, uint256 bonus_) internal onlyActiveCollaborator(collaborator_) {
        require(collaborator_.timeMgpPaid == 0, "reward already paid");
        collaborator_.timeMgpPaid = block.timestamp;
        if (bonus_ > 0) {
            collaborator_.bonus = bonus_;
            collaborator_.timeBonusPaid = block.timestamp;
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

struct Project {
    address initiator;
    address token;
    uint256 budget;
    uint256 budgetAllocated;
    uint256 budgetPaid;
    uint256 timeCreated;
    uint256 timeFinished;
    uint256 totalPackages;
    uint256 totalFinishedPackages;
}

struct Package {
    uint256 budget;
    uint256 budgetAllocated;
    uint256 budgetPaid;
    uint256 budgetObservers;
    uint256 budgetObserversPaid;
    uint256 bonus;
    uint256 bonusPaid;
    uint256 collaboratorsPaidBonus;
    uint256 timeCreated;
    uint256 timeFinished;
    uint256 totalObservers;
    uint256 totalCollaborators;
    uint256 collaboratorsLimit;
    uint256 approvedCollaborators;
    uint256 timeCanceled;
    bool isActive;
}

struct Collaborator {
    uint256 mgp;
    uint256 bonus;
    uint256 timeCreated;
    uint256 timeMgpApproved;
    uint256 timeMgpPaid;
    uint256 timeBonusPaid;
    bool isRemoved;
}

struct Observer {
    uint256 timeCreated;
    uint256 timePaid;
    bool isRemoved;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

interface ITokenFactory {
    event DeployedToken(address indexed token, uint256 indexed totalSupply);
    event SetLearnToEarn(address indexed oldLearnToEarn, address indexed newLearnToEarn);
    event DeployedNFT(address indexed nft);

    /**
     * @notice Deploys IOUT with totalSupply equal to project budget
     * @param _totalSupply Token total supply
     * @param _name Name of token
     * @param _symbol Symbol of token
     * @return token_ IOU token address
     *
     * emit {DeployedToken} events
     */
    function deployToken(uint256 _totalSupply, string memory _name, string memory _symbol) external returns (address);

    /**
     * @notice Deploy new contract to mint NFT
     * @param _name Name of NFT
     * @param _symbol Symbol of NFT
     * @param _uri Ipfs of NFT
     * @return nft_ address
     *
     * emit {DeployedNFT} events
     */
    function deployNFT(string memory _name, string memory _symbol, string memory _uri) external returns (address);
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