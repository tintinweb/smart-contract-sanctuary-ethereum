// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { IReBakedDAO } from "./interfaces/IReBakedDAO.sol";
import { ITokenFactory } from "./interfaces/ITokenFactory.sol";
import { IIOUToken } from "./interfaces/IIOUToken.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Project, ProjectLibrary } from "./libraries/ProjectLibrary.sol";
import { Package, PackageLibrary } from "./libraries/PackageLibrary.sol";
import { Collaborator, CollaboratorLibrary } from "./libraries/CollaboratorLibrary.sol";
import { Observer, ObserverLibrary } from "./libraries/ObserverLibrary.sol";

contract ReBakedDAO is IReBakedDAO, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ProjectLibrary for Project;
    using PackageLibrary for Package;
    using CollaboratorLibrary for Collaborator;
    using ObserverLibrary for Observer;

    // Percent Precision PPM (parts per million)
    uint256 public constant PCT_PRECISION = 1e6;
    // Rebaked DAO wallet
    address public treasury;
    // Token Factory contract address
    address public tokenFactory;

    mapping(bytes32 => Project) private projectData;

    mapping(bytes32 => mapping(bytes32 => Package)) private packageData;

    // projectId => packageId => address collaborator
    mapping(bytes32 => mapping(bytes32 => mapping(address => bool))) private approvedUser;

    // projectId => packageId => address collaborator
    mapping(bytes32 => mapping(bytes32 => mapping(address => Collaborator))) private collaboratorData;

    // projectId => packageId => address observer
    mapping(bytes32 => mapping(bytes32 => mapping(address => Observer))) private observerData;

    constructor(address treasury_, address tokenFactory_) {
        require(treasury_ != address(0), "invalid treasury address");
        require(tokenFactory_ != address(0), "invalid tokenFactory address");
        treasury = treasury_;
        tokenFactory = tokenFactory_;
    }

    /**
     * @dev Throws if amount provided is zero
     */
    modifier nonZero(uint256 amount_) {
        require(amount_ > 0, "Zero amount");
        _;
    }

    /**
     * @dev Throws if amount provided bytes32 array length is zero
     */
    modifier nonEmptyBytesArray(bytes32[] memory array_) {
        require(array_.length > 0, "Empty array");
        _;
    }

    /**
     * @dev Throws if amount provided uint256 array length is zero
     */
    modifier nonEmptyUintArray(uint256[] memory array_) {
        require(array_.length > 0, "Empty array");
        _;
    }

    /**
     * @dev Throws if called by any account other than the project initiator
     */
    modifier onlyInitiator(bytes32 projectId_) {
        require(projectData[projectId_].initiator == _msgSender(), "caller is not project initiator");
        _;
    }

    /***************************************
					PRIVATE
	****************************************/
    /**
     * @dev Generates unique id hash based on _msgSender() address and previous block hash.
     * @param nonce_ nonce
     * @return Id
     */
    function _generateId(uint256 nonce_) private view returns (bytes32) {
        return keccak256(abi.encodePacked(_msgSender(), blockhash(block.number - 1), nonce_));
    }

    /**
     * @dev Returns a new unique project id.
     * @return projectId_ Id of the project.
     */
    function _generateProjectId() private view returns (bytes32 projectId_) {
        projectId_ = _generateId(0);
        require(projectData[projectId_].timeCreated == 0, "duplicate project id");
    }

    /**
     * @dev Returns a new unique package id.
     * @param projectId_ Id of the project
     * @param nonce_ nonce
     * @return packageId_ Id of the package
     */
    function _generatePackageId(bytes32 projectId_, uint256 nonce_) private view returns (bytes32 packageId_) {
        packageId_ = _generateId(nonce_);
        require(packageData[projectId_][packageId_].timeCreated == 0, "duplicate package id");
    }

    /**
     * @dev Starts project
     * @param projectId_ Id of the project
     */
    function _startProject(bytes32 projectId_) private {
        uint256 _paidAmount = projectData[projectId_].budget;
        projectData[projectId_]._startProject(tokenFactory);
        emit StartedProject(projectId_, _paidAmount);
    }

    /***************************************
					ADMIN
	****************************************/

    function updateTreasury(address treasury_) external onlyOwner {
        require(treasury_ != address(0), "invalid treasury address");
        treasury = treasury_;
    }

    function _approveProject(bytes32 projectId_) private {
        projectData[projectId_]._approveProject();
        emit ApprovedProject(projectId_);
    }

    /**
     * @dev Approves project
     * @param projectId_ Id of the project
     */
    function approveProject(bytes32 projectId_) external onlyOwner {
        _approveProject(projectId_);
    }

    /**
     * @dev Sets scores for collaborator bonuses
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborators_ array of collaborators' addresses
     * @param scores_ array of collaboratos' scores in PPM
     */
    function setBonusScores(
        bytes32 projectId_,
        bytes32 packageId_,
        address[] memory collaborators_,
        uint256[] memory scores_
    ) external nonEmptyUintArray(scores_) onlyOwner {
        Package storage package = packageData[projectId_][packageId_];
        require(collaborators_.length == scores_.length, "arrays length mismatch");
        require(collaborators_.length <= package.totalCollaborators, "invalid collaborators list");
        uint256 _totalBonusScores;
        for (uint256 i = 0; i < collaborators_.length; i++) {
            collaboratorData[projectId_][packageId_][collaborators_[i]]._setBonusScore(scores_[i]);
            _totalBonusScores += scores_[i];
        }
        require(_totalBonusScores == PCT_PRECISION, "incorrect total bonus scores");
        package._setBonusScores(scores_.length);
        emit SetBonusScores(projectId_, packageId_, collaborators_, scores_);
    }

    // /**
    //  * @dev Raise dispute on collaborator, Set isInDispute flag, Check that user is authorized
    //  * @param _projectId Id of the project
    //  * @param _packageId Id of the package
    //  * @param _collaborator collaborator's address
    //  */

    // function raiseDispute(
    //     bytes32 _projectId,
    //     bytes32 _packageId,
    //     address _collaborator
    // ) external {
    //     require(
    //         _msgSender() == projectData[_projectId].initiator ||
    //         approvedUser[_projectId][_packageId][_msgSender()],
    //         "Caller not authorized"
    //     );
    //     Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_collaborator];
    //     collaborator._raiseDispute();
    // }

    function resolveDispute(
        bytes32 _projectId,
        bytes32 _packageId,
        address _collaborator,
        bool _approved
    ) external {
        Observer storage observer = observerData[_projectId][_packageId][_msgSender()];
        require(_msgSender() == owner() || (observer.timeCreated > 0 && !observer.isRemoved), "Caller is not authorized");
        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_collaborator];
        require(block.timestamp <= collaborator.appealedAt + 5 days, "resolve period already expired");
        collaborator._resolveDispute(_approved);
        packageData[_projectId][_packageId].disputesCount--;
        if (_approved) {
            _payMgp(_projectId, _packageId, _collaborator);
        }
    }

    /***************************************
			PROJECT INITIATOR ACTIONS
	****************************************/

    /**
     * @dev Creates project proposal
     * @param token_ project token address, zero addres if project has not token yet
     * (IOUToken will be deployed on project approval)
     * @param budget_ total budget (has to be approved on token contract if project has its own token)
     */
    function createProject(address token_, uint256 budget_) external nonZero(budget_) {
        bytes32 projectId_ = _generateProjectId();
        projectData[projectId_]._createProject(token_, budget_);
        emit CreatedProject(projectId_, _msgSender(), token_, budget_);
        if (token_ != address(0)) {
            _approveProject(projectId_);
            _startProject(projectId_);
        }
    }

    /**
     * @dev Starts project
     * @param projectId_ Id of the project
     */
    function startProject(bytes32 projectId_) external onlyInitiator(projectId_) {
        _startProject(projectId_);
    }

    /**
     * @dev Creates package in project
     * @param projectId_ Id of the project
     * @param budget_ MGP budget
     * @param bonus_ Bonus budget
     * @param observerBudget_ Observer budget
     * @param maxCollaborators_ maximum collaborators
     */
    function createPackage(
        bytes32 projectId_,
        uint256 budget_,
        uint256 bonus_,
        uint256 observerBudget_,
        uint256 maxCollaborators_
    ) external onlyInitiator(projectId_) nonZero(budget_) {
        Project storage project = projectData[projectId_];
        address _token = project.token;
        uint256 total = budget_ + bonus_ + observerBudget_;
        project._reservePackagesBudget(total, 1);
        bytes32 packageId_ = _generatePackageId(projectId_, 0);
        Package storage package = packageData[projectId_][packageId_];
        package._createPackage(budget_, observerBudget_, bonus_, maxCollaborators_);
        if (project.isOwnToken) {
            IERC20(_token).safeTransferFrom(_msgSender(), treasury, (total * 5) / 100);
        }
        emit CreatedPackage(projectId_, packageId_, budget_, bonus_);
    }

    function cancelPackage(
        bytes32 projectId_,
        bytes32 packageId_,
        address[] memory collaborators_,
        address[] memory observers_
    ) external onlyInitiator(projectId_) {
        Package storage package = packageData[projectId_][packageId_];
        package._cancelPackage();
        require(collaborators_.length == package.totalCollaborators, "invalid collaborators length");
        require(observers_.length == package.totalObservers, "invalid observers length");
        for (uint256 i = 0; i < collaborators_.length; i++) {
            payMgp(projectId_, packageId_, collaborators_[i]);
        }
        for (uint256 i = 0; i < observers_.length; i++) {
            payObserverFee(projectId_, packageId_, observers_[i]);
        }
        uint256 budgetToBeReverted_;
        budgetToBeReverted_ = package.budget - package.budgetPaid;
        projectData[projectId_]._revertPackageBudget(budgetToBeReverted_);
    }

    /**
     * @dev Adds collaborator to package
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborator_ collaborators' addresses
     * @param mgp_ MGP amount
     */
    function addCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        uint256 mgp_
    ) external onlyInitiator(projectId_) nonZero(mgp_) {
        require(collaborator_ != address(0), "collaborator's address is zero");
        collaboratorData[projectId_][packageId_][collaborator_]._addCollaborator(mgp_);
        packageData[projectId_][packageId_]._reserveCollaboratorsBudget(mgp_);
        emit AddedCollaborator(projectId_, packageId_, collaborator_, mgp_);
    }

    /**
     * @dev Approves collaborator's MGP or deletes collaborator (should be called by admin)
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborator_ collaborator's address
     * @param approve_ - bool whether to approve or not collaborator payment
     */
    function approveCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        bool approve_
    ) external onlyInitiator(projectId_) {
        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        uint256 mgp_ = collaborator.mgp;
        collaborator._approveCollaborator(approve_);

        approvedUser[projectId_][packageId_][collaborator_] = approve_;
        packageData[projectId_][packageId_]._approveCollaborator(approve_, mgp_);

        emit ApprovedCollaborator(projectId_, packageId_, collaborator_, approve_);
    }

    function removeCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        bool willPayMgp_
    ) external onlyInitiator(projectId_) {
        require(!approvedUser[projectId_][packageId_][collaborator_], "collaborator approved already!");

        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        if (willPayMgp_) {
            collaborator._removeAndPayMgp();
            _payMgp(projectId_, packageId_, collaborator_);
        } else {
            collaboratorData[projectId_][packageId_][collaborator_]._requestRemoval();
            packageData[projectId_][packageId_].disputesCount++;
        }
    }

    function settleExpiredDispute(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        bool approved_
    ) external onlyInitiator(projectId_) {
        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        require(collaborator.timeCreated > 0 && !collaborator.isRemoved, "no such collaborator");

        bool expiredWithoutAppeal = 0 < collaborator.disputeExpiresAt
                && collaborator.disputeExpiresAt < block.timestamp
                && collaborator.appealedAt == 0;
        bool expiredWithoutJudgment = 0 < collaborator.appealedAt
                && collaborator.appealedAt + 5 days < block.timestamp;
        require(expiredWithoutAppeal || expiredWithoutJudgment, "not elligible to remove yet");

        collaborator._resolveDispute(approved_);
        packageData[projectId_][packageId_].disputesCount--;
    }

    function selfRemove(bytes32 projectId_, bytes32 packageId_) external {
        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][_msgSender()];
        uint256 mgp_ = collaborator.mgp;
        collaborator._approveCollaborator(false);
        packageData[projectId_][packageId_]._removeCollaborator(mgp_, approvedUser[projectId_][packageId_][_msgSender()]);
        approvedUser[projectId_][packageId_][_msgSender()] = false;
    }

    /**
     * @dev Adds observer to packages
     * @param projectId_ Id of the project
     * @param packageIds_ Id of the package
     * @param observer_ observer address
     */
    function addObserver(
        bytes32 projectId_,
        bytes32[] memory packageIds_,
        address observer_
    ) external onlyInitiator(projectId_) {
        for (uint256 i = 0; i < packageIds_.length; i++) {
            require(observer_ != address(0), "observer's address is zero");
            observerData[projectId_][packageIds_[i]][observer_]._addObserver();
            packageData[projectId_][packageIds_[i]]._addObserver();
        }
        emit AddedObserver(projectId_, packageIds_, observer_);
    }

    /**
     * @dev Removes observer from packages
     * @param projectId_ Id of the project
     * @param packageIds_ packages' ids
     * @param observer_ observer address
     */
    function removeObserver(
        bytes32 projectId_,
        bytes32[] memory packageIds_,
        address observer_
    ) external onlyInitiator(projectId_) {
        for (uint256 i = 0; i < packageIds_.length; i++) {
            Observer storage observer = observerData[projectId_][packageIds_[i]][observer_];
            observer._removeObserver();
            Package storage package = packageData[projectId_][packageIds_[i]];
            package._removeObserver();
        }
    }

    function payMgp(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_
    ) public onlyInitiator(projectId_) {
        _payMgp(projectId_, packageId_, collaborator_);
    }

    function _payMgp(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_
    ) private {
        uint256 amount_ = collaboratorData[projectId_][packageId_][collaborator_]._payMgp();
        packageData[projectId_][packageId_]._payMgp(amount_);
        projectData[projectId_]._pay(collaborator_, amount_);
        emit PaidMgp(projectId_, packageId_, collaborator_, amount_);
    }

    function payObserverFee(
        bytes32 projectId_,
        bytes32 packageId_,
        address observer_
    ) public onlyInitiator(projectId_) {
        observerData[projectId_][packageId_][observer_]._claimObserverFee();

        uint256 amount_ = packageData[projectId_][packageId_]._getObserverFee();
        packageData[projectId_][packageId_]._claimObserverFee(amount_);
        projectData[projectId_]._pay(observer_, amount_);

        emit PaidObserverFee(projectId_, packageId_, observer_, amount_);
    }

    /**
     * @dev Finishes package in project
     * @param projectId_ Id of the project
     */
    function finishPackage(bytes32 projectId_, bytes32 packageId_) external onlyInitiator(projectId_) {
        uint256 budgetLeft_ = packageData[projectId_][packageId_]._finishPackage();
        projectData[projectId_]._finishPackage(budgetLeft_);
        emit FinishedPackage(projectId_, packageId_, budgetLeft_);
    }

    /**
     * @dev Finishes project
     * @param projectId_ Id of the project
     */
    function finishProject(bytes32 projectId_) external onlyInitiator(projectId_) {
        projectData[projectId_]._finishProject(treasury);
        emit FinishedProject(projectId_);
    }

    /***************************************
			COLLABORATOR ACTIONS
	****************************************/
    /**
     * @dev Sends approved MGP to collaborator, should be called from collaborator's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimMgp(bytes32 projectId_, bytes32 packageId_) public nonReentrant {
        address collaborator_ = _msgSender();
        require(approvedUser[projectId_][packageId_][collaborator_], "only collaborator can call");
        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        uint256 amount_ = collaborator._claimMgp();
        packageData[projectId_][packageId_]._claimMgp(amount_);
        projectData[projectId_]._pay(collaborator_, amount_);
        emit PaidMgp(projectId_, packageId_, _msgSender(), amount_);
    }

    /**
     * @dev Sends approved Bonus to collaborator, should be called from collaborator's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimBonus(bytes32 projectId_, bytes32 packageId_) external nonReentrant {
        address collaborator_ = _msgSender();
        require(approvedUser[projectId_][packageId_][collaborator_], "only collaborator can call");
        Collaborator storage collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        collaborator._claimBonus();
        Package storage package = packageData[projectId_][packageId_];
        (, uint256 amount_) = getCollaboratorRewards(projectId_, packageId_, collaborator_);
        package._claimBonus(amount_);
        projectData[projectId_]._pay(collaborator_, amount_);
        emit PaidBonus(projectId_, packageId_, collaborator_, amount_);
    }

    function defendRemoval(bytes32 _projectId, bytes32 _packageId) external {
        Collaborator storage collaborator = collaboratorData[_projectId][_packageId][_msgSender()];
        collaborator._defendRemoval();
    }

    /***************************************
			OBSERVER ACTIONS
	****************************************/

    /**
     * @dev Sends observer fee, should be called from observer's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimObserverFee(bytes32 projectId_, bytes32 packageId_) external nonReentrant {
        address observer_ = _msgSender();
        Observer storage observer = observerData[projectId_][packageId_][observer_];
        observer._claimObserverFee();

        uint256 amount_ = packageData[projectId_][packageId_]._getObserverFee();
        packageData[projectId_][packageId_]._claimObserverFee(amount_);
        projectData[projectId_]._pay(observer_, amount_);

        emit PaidObserverFee(projectId_, packageId_, observer_, amount_);
    }

    /***************************************
			GETTERS
	****************************************/

    function getProjectData(bytes32 projectId_) external view returns (Project memory) {
        return projectData[projectId_];
    }

    function getPackageData(bytes32 projectId_, bytes32 packageId_) external view returns (Package memory) {
        return (packageData[projectId_][packageId_]);
    }

    function getCollaboratorData(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_
    ) external view returns (Collaborator memory) {
        return collaboratorData[projectId_][packageId_][collaborator_];
    }

    function getCollaboratorRewards(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_
    ) public view returns (uint256, uint256) {
        Package memory package = packageData[projectId_][packageId_];
        if (package.timeCreated == 0) return (0, 0);
        Collaborator memory collaborator = collaboratorData[projectId_][packageId_][collaborator_];
        uint256 bonus = (package.collaboratorsPaidBonus + 1 == package.collaboratorsGetBonus)
            ? package.bonus - package.bonusPaid
            : (collaborator.bonusScore * package.bonus) / PCT_PRECISION;
        return (collaborator.mgp, bonus);
    }

    function getObserverData(
        bytes32 projectId_,
        bytes32 packageId_,
        address observer_
    ) external view returns (Observer memory) {
        return observerData[projectId_][packageId_][observer_];
    }

    function getObserverFee(
        bytes32 projectId_,
        bytes32 packageId_,
        address observer_
    ) public view returns (uint256) {
        Observer memory observer = observerData[projectId_][packageId_][observer_];
        if (observer.timePaid > 0 || observer.timeCreated == 0 || observer.isRemoved) {
            return 0;
        }
        return packageData[projectId_][packageId_]._getObserverFee();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IReBakedDAO {
    event CreatedProject(
        bytes32 indexed projectId,
        address initiator,
        address token,
        uint256 budget
    );
    event ApprovedProject(bytes32 indexed projectId);
    event StartedProject(bytes32 indexed projectId, uint256 indexed paidAmount);
    event FinishedProject(bytes32 indexed projectId);
    event CreatedPackage(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        uint256 budget,
        uint256 bonus
    );
    event AddedObserver(
        bytes32 indexed projectId,
        bytes32[] indexed packageId,
        address observer
    );
    event AddedCollaborator(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address collaborator,
        uint256 mgp
    );
    event ApprovedCollaborator(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address collaborator,
        bool approve
    );
    event FinishedPackage(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        uint256 indexed budgetLeft_
    );
    event SetBonusScores(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address[] collaborators,
        uint256[] scores
    );
    event PaidMgp(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address collaborator,
        uint256 amount
    );
    event PaidBonus(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address collaborator,
        uint256 amount
    );
    event PaidObserverFee(
        bytes32 indexed projectId,
        bytes32 indexed packageId,
        address observer,
        uint256 amount
    );

    /***************************************
					ADMIN
	****************************************/

    /**
     * @dev Approves project
     * @param projectId_ Id of the project
     */
    function approveProject(bytes32 projectId_) external;

    /**
     * @dev Sets scores for collaborator bonuses
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborators_ array of collaborators' addresses
     * @param scores_ array of collaboratos' scores in PPM
     */
    function setBonusScores(
        bytes32 projectId_,
        bytes32 packageId_,
        address[] memory collaborators_,
        uint256[] memory scores_
    ) external;

    /***************************************
			PROJECT INITIATOR ACTIONS
	****************************************/

    /**
     * @dev Creates project proposal
     * @param token_ project token address, zero addres if project has not token yet
     * (IOUT will be deployed on project approval)
     * @param budget_ total budget (has to be approved on token contract if project has its own token)
     */
    function createProject(address token_, uint256 budget_) external;

    /**
     * @dev Starts project
     * @param projectId_ Id of the project
     */
    function startProject(bytes32 projectId_) external;

    /**
     * @dev Creates package in project
     * @param projectId_ Id of the project
     * @param budget_ MGP budget
     * @param bonus_ Bonus budget
     */
    function createPackage(
        bytes32 projectId_,
        uint256 budget_,
        uint256 bonus_,
        uint256 observerBudget_,
        uint256 maxCollaborators_
    ) external;

    /**
     * @dev Approves collaborator's MGP or deletes collaborator
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborator_ collaborator's address
     * @param approve_ - bool whether to approve or not collaborator payment
     */
    function approveCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        bool approve_
    ) external;

    function cancelPackage(
        bytes32 projectId_,
        bytes32 packageId_,
        address[] calldata collaborator_,
        address[] calldata observer_
    ) external;

    /**
     * @dev Adds observer to package
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param observer_ observer addresses
     */
    function addObserver(
        bytes32 projectId_,
        bytes32[] calldata packageId_,
        address observer_
    ) external;

    /**
     * @dev Adds collaborator to package
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     * @param collaborator_ collaborators' addresses
     * @param mgp_ MGP amount
     */
    function addCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        uint256 mgp_
    ) external;

    function removeCollaborator(
        bytes32 projectId_,
        bytes32 packageId_,
        address collaborator_,
        bool willPayMgp_
    ) external;

    function selfRemove(
        bytes32 projectId_,
        bytes32 packageId_
    ) external;

    function removeObserver(
        bytes32 projectId_,
        bytes32[] calldata packageId_,
        address observer_
    ) external;

    /**
     * @dev Finishes package in project
     * @param projectId_ Id of the project
     */
    function finishPackage(bytes32 projectId_, bytes32 packageId_) external;

    /**
     * @dev Finishes project
     * @param projectId_ Id of the project
     */
    function finishProject(bytes32 projectId_) external;

    /***************************************
			COLLABORATOR ACTIONS
	****************************************/
    /**
     * @dev Sends approved MGP to collaborator, should be called from collaborator's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimMgp(
        bytes32 projectId_,
        bytes32 packageId_
    ) external;

    /**
     * @dev Sends approved Bonus to collaborator, should be called from collaborator's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimBonus(
        bytes32 projectId_,
        bytes32 packageId_
    ) external;

    /***************************************
			OBSERVER ACTIONS
	****************************************/

    /**
     * @dev Sends observer fee, should be called from observer's address
     * @param projectId_ Id of the project
     * @param packageId_ Id of the package
     */
    function claimObserverFee(bytes32 projectId_, bytes32 packageId_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ITokenFactory {
	function deployToken(uint256 totalSupply_) external returns(address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { IERC20, SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ITokenFactory } from "../interfaces/ITokenFactory.sol";
import { IIOUToken } from "../interfaces/IIOUToken.sol";
import { Project } from "./Structs.sol";

library ProjectLibrary {
    using SafeERC20 for IERC20;

    /**
	@dev Throws if there is no such project
	 */
    modifier onlyExistingProject(Project storage project_) {
        require(project_.timeCreated > 0, "no such project");
        _;
    }

    /**
     * @dev Creates project proposal
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
        project_.isOwnToken = token_ != address(0);
    }

    /**
     * @dev Approves project
     * @param project_ reference to Project struct
     */
    function _approveProject(Project storage project_) internal onlyExistingProject(project_) {
        require(project_.timeApproved == 0, "already approved project");
        project_.timeApproved = block.timestamp;
    }

    /**
     * @dev Starts project, if project own token auto approve, otherwise deploys IOUToken, transfers fee to DAO wallet
     * @param project_ reference to Project struct
     * @param tokenFactory_ address of token factory contract
     */
    function _startProject(Project storage project_, address tokenFactory_) internal {
        require(project_.timeApproved > 0, "project is not approved");
        require(project_.timeStarted == 0, "project already started");
        if (project_.isOwnToken) {
            IERC20(project_.token).safeTransferFrom(msg.sender, address(this), project_.budget);
        } else {
            project_.token = ITokenFactory(tokenFactory_).deployToken(project_.budget);
        }
        project_.timeStarted = block.timestamp;
    }

    /**
     * @dev Finishes project, checks if already finished or unfinished packages left
     * unallocated budget returned to initiator or burned (in case of IOUToken)
     * @param project_ reference to Project struct
     */
    function _finishProject(Project storage project_, address treasury_) internal {
        require(project_.timeStarted > 0, "project not started yet");
        require(project_.timeFinished == 0, "already finished project");
        require(project_.totalPackages == project_.totalFinishedPackages, "unfinished packages left");
        project_.timeFinished = block.timestamp;
        uint256 budgetLeft_ = project_.budget - project_.budgetAllocated;
        if (budgetLeft_ > 0) {
            if (project_.isOwnToken) {
                uint256 refundAmount_ = (budgetLeft_ * 5) / 100;
                budgetLeft_ -= refundAmount_;
                IERC20(project_.token).safeTransfer(project_.initiator, refundAmount_);
                IERC20(project_.token).safeTransfer(treasury_, budgetLeft_);
            } else IIOUToken(project_.token).burn(budgetLeft_);
        }
    }

    /**
     * @dev Creates package in project, check if there is budget available
     * allocates budget and increase total number of packages
     * @param project_ reference to Project struct
     * @param totalBudget_ total budget MGP + Bonus
     * @param count_ total count of packages
     */
    function _reservePackagesBudget(
        Project storage project_,
        uint256 totalBudget_,
        uint256 count_
    ) internal {
        require(project_.timeStarted > 0, "project is not started");
        require(project_.timeFinished == 0, "project is finished");
        uint256 _projectBudgetAvailable = project_.budget - project_.budgetAllocated;
        require(_projectBudgetAvailable >= totalBudget_, "not enough project budget left");
        project_.budgetAllocated += totalBudget_;
        project_.totalPackages += count_;
    }

    function _revertPackageBudget(Project storage project_, uint256 budgetToBeReverted_) internal {
        require(project_.timeStarted > 0, "project is not started");
        require(project_.timeFinished == 0, "project is finished");
        project_.budgetAllocated -= budgetToBeReverted_;
        project_.totalPackages -= 1;
    }

    /**
     * @dev Finishes package in project, budget left addded refunded back to project budget
     * increases total number of finished packages
     * @param project_ reference to Project struct
     * @param budgetLeft_ amount of budget left
     */
    function _finishPackage(Project storage project_, uint256 budgetLeft_) internal {
        if (budgetLeft_ > 0) project_.budgetAllocated -= budgetLeft_;
        project_.totalFinishedPackages++;
    }

    /**
     * @dev Pays from project's budget, increases budget paid
     * @param project_ reference to Project struct
     * @param amount_ amount to pay
     */
    function _pay(Project storage project_, address receiver_, uint256 amount_) internal onlyExistingProject(project_) {
        project_.budgetPaid += amount_;
        IERC20(project_.token).safeTransfer(receiver_, amount_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IIOUToken {
	function burn(uint256 amount_) 	external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Observer } from "./Structs.sol";

library ObserverLibrary {

    /**
	@dev Throws if there is no such observer
	 */
    modifier onlyExistingObserver(Observer storage observer_) {
        require(observer_.timeCreated > 0 && !observer_.isRemoved, "no such observer");
        _;
    }

    function _addObserver(Observer storage _observer) internal {
        require(_observer.timeCreated == 0, "observer already added");
        _observer.timeCreated = block.timestamp;
        _observer.isRemoved = false;
    }

    function _removeObserver(Observer storage _observer) internal onlyExistingObserver(_observer) {
        _observer.isRemoved = true;
    }

    function _claimObserverFee(Observer storage _observer) internal onlyExistingObserver(_observer) {
        require(_observer.timePaid == 0, "observer already paid");
        _observer.timePaid = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Collaborator } from "./Structs.sol";

library CollaboratorLibrary {
    /**
	@dev Throws if there is no such collaborator
	*/
    modifier onlyExistingCollaborator(Collaborator storage collaborator_) {
        require(collaborator_.timeCreated > 0 && !collaborator_.isRemoved, "no such collaborator");
        _;
    }

    /**
     * @dev Adds collaborator, checks for zero address and if already added, records mgp
     * @param collaborator_ reference to Collaborator struct
     * @param collaborator_ collaborator's address
     * @param mgp_ minimum guaranteed payment
     */
    function _addCollaborator(Collaborator storage collaborator_, uint256 mgp_) internal {
        require(collaborator_.timeCreated == 0, "collaborator already added");
        collaborator_.mgp = mgp_;
        collaborator_.timeCreated = block.timestamp;
        collaborator_.isRemoved = false;
    }

    function _removeAndPayMgp(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) {
        collaborator_.isRemoved = true;
    }

    /**
     * @dev Approves collaborator's MGP or deletes collaborator
     * @param collaborator_ reference to Collaborator struct
     */
    function _approveCollaborator(Collaborator storage collaborator_, bool approved_) internal onlyExistingCollaborator(collaborator_) {
        if (approved_) {
            require(collaborator_.timeMgpApproved == 0, "collaborator already approved");
            collaborator_.timeMgpApproved = block.timestamp;
        } else {
            collaborator_.isRemoved = true;
            collaborator_.mgp = 0;
            collaborator_.bonusScore = 0;
            collaborator_.timeMgpApproved = 0;
        }
    }

    /**
     * @dev Sets scores for collaborator bonuses
     * @param collaborator_ reference to Collaborator struct
     * @param bonusScore_ collaborator's bonus score
     */
    function _setBonusScore(Collaborator storage collaborator_, uint256 bonusScore_) internal onlyExistingCollaborator(collaborator_) {
        require(collaborator_.bonusScore == 0, "collaborator bonus already set");
        collaborator_.bonusScore = bonusScore_;
    }

    /**
     * @dev Raise Dispute
     * @param collaborator_ paid amount
     */
    function _requestRemoval(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) {
        require(!collaborator_.isInDispute, "Collaborator already in dispute");
        require(collaborator_.timeMgpPaid == 0, "Already Claimed MGP");
        require(collaborator_.timeBonusPaid == 0, "Already Claimed Bonus");
        collaborator_.isInDispute = true;
        collaborator_.disputeExpiresAt = block.timestamp + 3 days;
    }

    function _defendRemoval(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) {
        require(
            block.timestamp <= collaborator_.disputeExpiresAt,
            "dispute period already expired"
        );
        collaborator_.appealedAt = block.timestamp;
    }

    /**
     * @dev Resolve Dispute
     * @param collaborator_ collaborator in dispute
     */
    function _resolveDispute(Collaborator storage collaborator_, bool approved) internal onlyExistingCollaborator(collaborator_) {
        require(collaborator_.isInDispute, "Dispute Required");
        collaborator_.isInDispute = false;
        collaborator_.disputeExpiresAt = 0;
        collaborator_.appealedAt = 0;
        if (!approved) {
            collaborator_.isRemoved = true;
            collaborator_.mgp = 0;
        }
    }

    /**
     * @dev Sets MGP time paid flag, checks if approved and already paid
     * @param collaborator_ reference to Collaborator struct
     */
    function _claimMgp(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) returns (uint256) {
        require(!collaborator_.isInDispute, "Collaborator still in dispute");
        require(collaborator_.timeMgpApproved > 0, "mgp is not approved");
        require(collaborator_.timeMgpPaid == 0, "mgp already paid");
        collaborator_.timeMgpPaid = block.timestamp;
        return collaborator_.mgp;
    }

    function _payMgp(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) returns (uint256) {
        require(collaborator_.timeMgpPaid == 0, "mgp already paid");
        collaborator_.timeMgpPaid = block.timestamp;
        return collaborator_.mgp;
    }

    /**
     * @dev Sets Bonus time paid flag, checks is approved and already paid
     * @param collaborator_ reference to Collaborator struct
     */
    function _claimBonus(Collaborator storage collaborator_) internal onlyExistingCollaborator(collaborator_) {
        require(!collaborator_.isInDispute, "Collaborator still in dispute");
        require(collaborator_.bonusScore > 0, "bonus score is zero");
        require(collaborator_.timeBonusPaid == 0, "bonus already paid");
        collaborator_.timeBonusPaid = block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
import { Package } from "./Structs.sol";

library PackageLibrary {
    uint256 public constant MIN_COLLABORATORS = 3;
    uint256 public constant MAX_COLLABORATORS = 10;
    uint256 public constant MAX_OBSERVERS = 10;

    /**
	@dev Throws if there is no package
	 */
    modifier onlyExistingPackage(Package storage package_) {
        require(package_.timeCreated > 0, "no such package");
        _;
    }

    modifier activePackage(Package storage package_) {
        require(package_.isActive, "already canceled!");
        _;
    }

    /**
     * @dev Creates package in project
     * @param package_ reference to Package struct
     * @param budget_ MGP budget
     * @param feeObserversBudget_ Observers fee budget
     * @param bonus_ Bonus budget
     */
    function _createPackage(
        Package storage package_,
        uint256 budget_,
        uint256 feeObserversBudget_,
        uint256 bonus_,
        uint256 maxCollaborators_
    ) internal {
        require(MIN_COLLABORATORS <= maxCollaborators_ && maxCollaborators_ <= MAX_COLLABORATORS, "incorrect max colalborators");
        package_.budget = budget_;
        package_.budgetObservers = feeObserversBudget_;
        package_.bonus = bonus_;
        package_.budgetAllocated = 0;
        package_.maxCollaborators = maxCollaborators_;
        package_.timeCreated = block.timestamp;
        package_.isActive = true;
    }

    function _cancelPackage(Package storage package_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        package_.timeCanceled = block.timestamp;
        package_.isActive = false;
    }

    /**
     * @dev Adds observers to package
     * @param package_ reference to Package struct
     */
    function _addObserver(Package storage package_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        require(package_.totalObservers < MAX_OBSERVERS, "Max observers reached");
        package_.totalObservers++;
    }

    /**
     * @dev Removes observers from package
     * @param package_ reference to Package struct
     */
    function _removeObserver(Package storage package_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        require(package_.totalObservers > 0, "no observers in package");
        package_.totalObservers--;
    }

    /**
     * @dev Reserves collaborators MGP from package budget and increase total number of collaborators,
     * checks if there is budget available and allocates it
     * @param amount_ amount to reserve
     */
    function _reserveCollaboratorsBudget(Package storage package_, uint256 amount_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        require(package_.budget >= package_.budgetAllocated + amount_, "not enough package budget left");
        require(package_.totalCollaborators < package_.maxCollaborators, "Max collaborators reached");
        package_.budgetAllocated += amount_;
        package_.totalCollaborators++;
    }

    /**
     * @dev Refund package budget and decreace total collaborators if not approved
     * @param package_ reference to Package struct
     * @param approve_ whether to approve or not collaborator payment
     * @param mgp_ MGP amount
     */
    function _approveCollaborator(
        Package storage package_,
        bool approve_,
        uint256 mgp_
    ) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        if (!approve_) {
            package_.budgetAllocated -= mgp_;
            package_.totalCollaborators--;
        } else {
            package_.approvedCollaborators++;
        }
    }

    function _removeCollaborator(
        Package storage package_,
        uint256 mgp_,
        bool approved_
    ) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished == 0, "already finished package");
        package_.budgetAllocated -= mgp_;
        package_.totalCollaborators--;
        if (approved_) package_.approvedCollaborators--;
    }

    /**
     * @dev Finishes package in project, checks if already finished, records time
     * if budget left and there is no collaborators, bonus is refunded to package budget
     * @param package_ reference to Package struct
     */
    function _finishPackage(Package storage package_) internal onlyExistingPackage(package_) activePackage(package_) returns (uint256 budgetLeft_) {
        require(package_.timeFinished == 0, "already finished package");
        require(package_.disputesCount == 0, "package has unresolved disputes");
        require(package_.totalCollaborators == package_.approvedCollaborators, "unapproved collaborators left");
        budgetLeft_ = package_.budget - package_.budgetAllocated;
        if (package_.totalObservers == 0) budgetLeft_ += package_.budgetObservers;
        if (package_.totalCollaborators == 0) budgetLeft_ += package_.bonus;
        package_.timeFinished = block.timestamp;
        return budgetLeft_;
    }

    /**
     * @dev Sets scores for collaborator bonuses
     * @param package_ reference to Package struct
     * @param collaboratorsGetBonus_ max bonus scores (PPM)
     */
    function _setBonusScores(Package storage package_, uint256 collaboratorsGetBonus_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.bonus > 0, "zero bonus budget");
        require(package_.timeFinished > 0, "package is not finished");
        package_.collaboratorsGetBonus = collaboratorsGetBonus_;
    }

    /**
     * @dev Get observer's claimable portion in package
     * @param package_ reference to Package struct
     */
    function _getObserverFee(Package storage package_) internal view onlyExistingPackage(package_) returns (uint256) {
        if (package_.totalObservers == 0) return 0;
        if (package_.budgetObservers == package_.budgetObserversPaid) return 0;
        uint256 remains = package_.budgetObservers - package_.budgetObserversPaid;
        uint256 portion = package_.budgetObservers / package_.totalObservers;
        return (remains < 2 * portion) ? remains : portion;
    }

    /**
     * @dev Increases package's observers budget paid
     * @param package_ reference to Package struct
     */
    function _claimObserverFee(Package storage package_, uint256 amount_) internal {
        require(package_.timeFinished > 0 || package_.timeCanceled > 0, "package is not finished/canceled");
        package_.budgetObserversPaid += amount_;
    }

    /**
     * @dev Increases package budget paid
     * @param package_ reference to Package struct
     * @param amount_ MGP amount
     */
    function _claimMgp(Package storage package_, uint256 amount_) internal onlyExistingPackage(package_) {
        require(package_.timeFinished > 0, "package not finished/canceled");
        package_.budgetPaid += amount_;
    }

    function _payMgp(Package storage package_, uint256 amount_) internal onlyExistingPackage(package_) {
        package_.budgetPaid += amount_;
    }

    /**
     * @dev Increases package bonus paid
     * @param package_ reference to Package struct
     * @param amount_ Bonus amount
     */
    function _claimBonus(Package storage package_, uint256 amount_) internal onlyExistingPackage(package_) activePackage(package_) {
        require(package_.timeFinished > 0, "package not finished");
        require(package_.bonus > 0, "package has no bonus");
        package_.bonusPaid += amount_;
        package_.collaboratorsPaidBonus++;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
        IERC20Permit token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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
pragma solidity ^0.8.10;

struct Project {
    address initiator;
    address token;
    bool isOwnToken;
    uint256 budget;
    uint256 budgetAllocated;
    uint256 budgetPaid;
    uint256 timeCreated;
    uint256 timeApproved;
    uint256 timeStarted;
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
    uint256 collaboratorsGetBonus;
    uint256 timeCreated;
    uint256 timeFinished;
    uint256 totalObservers;
    uint256 totalCollaborators;
    uint256 maxCollaborators;
    uint256 approvedCollaborators;
    uint256 disputesCount;
    uint256 timeCanceled;
    bool isActive;
}

struct Collaborator {
    uint256 mgp;
    uint256 timeCreated;
    uint256 timeMgpApproved;
    uint256 timeMgpPaid;
    uint256 timeBonusPaid;
    uint256 bonusScore;
    uint256 disputeExpiresAt;
    uint256 appealedAt;
    bool isInDispute;
    bool isRemoved;
}

struct Observer {
    uint256 timeCreated;
    uint256 timePaid;
    bool isRemoved;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
interface IERC20Permit {
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