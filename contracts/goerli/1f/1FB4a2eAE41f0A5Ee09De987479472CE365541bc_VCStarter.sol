// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCPool.sol";
import "./VCProject.sol";

import {Errors} from "./Errors.sol";

contract VCStarter {
    event SttrWhitelistedLab(address indexed lab);
    event SttrBlacklistedLab(address indexed lab);
    event SttrWhitelistedResearcher(address indexed researcher);
    event SttrBlacklistedResearcher(address indexed researcher);
    event SttrCurrencyListed(IERC20 indexed currency);
    event SttrCurrencyUnlisted(IERC20 indexed currency);
    event SttrSetMinCampaignDuration(uint256 minCampaignDuration);
    event SttrSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event SttrSetMinCampaignTarget(uint256 minCampaignTarget);
    event SttrSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event SttrSetSoftTargetBps(uint256 softTargetBps);
    event SttrPoCNftSet(IPoCNft indexed poCNft);
    event SttrCampaignStarted(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 startTime,
        uint256 endTime,
        uint256 backersDeadline,
        uint256 target,
        uint256 softTarget
    );
    event SttrCampaignFunding(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        IERC20 currency,
        address user,
        uint256 amount
    );
    event SttrCampaignFunded(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrCampaignSucceded(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrCampaignDefeated(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrLabCampaignWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        IERC20 currency,
        uint256 amount
    );
    event SttrLabWithdrawal(address indexed lab, address indexed project, IERC20 currency, uint256 amount);
    event SttrwithdrawToPool(address indexed project, IERC20 indexed currency, uint256 amount);
    event SttrBackerMintPoCNft(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrBackerWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrUnclaimedFundsTransferredToPool(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrProjectFunded(
        address indexed lab,
        address indexed project,
        address indexed backer,
        IERC20 currency,
        uint256 amount
    );
    event SttrProjectActivated(address indexed project);
    event SttrProjectClosed(address indexed lab, address indexed project);
    event SttrProjectRequest(address indexed lab);
    event SttrProjectCreated(address indexed lab, address indexed project);
    event SttrProjectCreationRejected(address indexed lab);
    event SttrCampaingClosed(address indexed lab, address indexed project, uint256 campaignId);

    /// @notice A project contract template cloned for each project
    address _projectTemplate;
    address _admin;
    address _coreTeam; // multisig of the VC CORE team
    address _pool;
    address _txValidator;
    uint256 _starterFeeBps;
    IPoCNft _poCNft;

    /// @notice The list of laboratories
    mapping(address => bool) _isWhitelistedLab;

    mapping(address => bool) _pendingProjectRequest;
    mapping(address => address) _projectToLab;
    mapping(address => bool) _activeProjects;

    mapping(IERC20 => bool) _allowedCurrencies;

    uint256 _minCampaignDuration;
    uint256 _maxCampaignDuration;
    uint256 _minCampaignTarget;
    uint256 _maxCampaignTarget;
    uint256 _softTargetBps;

    uint256 constant _FEE_DENOMINATOR = 10_000;

    /// @notice amount of seconds to wait for lab operation
    uint256 _backersTimeout = 15 days;

    constructor(
        address pool,
        address admin,
        address coreTeam,
        address txValidator,
        address projectTemplate,
        uint256 minCampaignDuration,
        uint256 maxCampaignDuration,
        uint256 minCampaignTarget,
        uint256 maxCampaignTarget,
        uint256 softTargetBps,
        uint256 starterFeeBps
    ) {
        _admin = admin;
        _pool = pool;
        _coreTeam = coreTeam;
        _projectTemplate = projectTemplate;
        _txValidator = txValidator;

        _minCampaignDuration = minCampaignDuration;
        _maxCampaignDuration = maxCampaignDuration;
        _minCampaignTarget = minCampaignTarget;
        _maxCampaignTarget = maxCampaignTarget;
        _softTargetBps = softTargetBps;
        _starterFeeBps = starterFeeBps;
    }

    /*********** ONLY-ADMIN / ONLY-CORE_TEAM FUNCTIONS ***********/

    function changeAdmin(address admin) external {
        _onlyAdmin();
        _admin = admin;
    }

    function whitelistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == true) {
            revert Errors.SttrLabAlreadyWhitelisted();
        }
        _isWhitelistedLab[lab] = true;
        emit SttrWhitelistedLab(lab);
    }

    function blacklistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == false) {
            revert Errors.SttrLabAlreadyBlacklisted();
        }
        _isWhitelistedLab[lab] = false;
        emit SttrBlacklistedLab(lab);
    }

    // add struct to store decimals of each currency
    function listCurrency(IERC20 currency) external {
        _onlyAdmin();
        if (_allowedCurrencies[currency] == true) {
            revert Errors.SttrCurrencyAlreadyListed();
        }
        _allowedCurrencies[currency] = true;
        emit SttrCurrencyListed(currency);
    }

    function unlistCurrency(IERC20 currency) external {
        _onlyAdmin();
        if (_allowedCurrencies[currency] == false) {
            revert Errors.SttrCurrencyAlreadyUnlisted();
        }
        _allowedCurrencies[currency] = false;
        emit SttrCurrencyUnlisted(currency);
    }

    function setMinCampaignDuration(uint256 minCampaignDuration) external {
        _onlyAdmin();
        if (_minCampaignDuration == minCampaignDuration || minCampaignDuration >= _maxCampaignDuration) {
            revert Errors.SttrMinCampaignDurationError();
        }
        _minCampaignDuration = minCampaignDuration;
        emit SttrSetMinCampaignDuration(_minCampaignDuration);
    }

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external {
        _onlyAdmin();
        if (_maxCampaignDuration == maxCampaignDuration || maxCampaignDuration <= _minCampaignDuration) {
            revert Errors.SttrMaxCampaignDurationError();
        }
        _maxCampaignDuration = maxCampaignDuration;
        emit SttrSetMaxCampaignDuration(_maxCampaignDuration);
    }

    function setMinCampaignTarget(uint256 minCampaignTarget) external {
        _onlyAdmin();
        if (_minCampaignTarget == minCampaignTarget || minCampaignTarget >= _maxCampaignTarget) {
            revert Errors.SttrMinCampaignTargetError();
        }
        _minCampaignTarget = minCampaignTarget;
        emit SttrSetMinCampaignTarget(minCampaignTarget);
    }

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external {
        _onlyAdmin();
        if (_maxCampaignTarget == maxCampaignTarget || maxCampaignTarget <= _minCampaignTarget) {
            revert Errors.SttrMaxCampaignTargetError();
        }
        _maxCampaignTarget = maxCampaignTarget;
        emit SttrSetMaxCampaignTarget(_maxCampaignTarget);
    }

    function setSoftTargetBps(uint256 softTargetBps) external {
        _onlyAdmin();
        if (_softTargetBps == softTargetBps || softTargetBps > _FEE_DENOMINATOR) {
            revert Errors.SttrSoftTargetBpsError();
        }
        _softTargetBps = softTargetBps;
        emit /*Events.*/
        SttrSetSoftTargetBps(_softTargetBps);
    }

    function setPoCNft(address _pocNft) external {
        _onlyAdmin();
        _poCNft = IPoCNft(_pocNft);
        emit SttrPoCNftSet(_poCNft);
    }

    function createProject(address _lab, bool _accepted) external returns (address newProject) {
        _onlyCoreTeam();

        if (!_pendingProjectRequest[_lab]) {
            revert Errors.SttrNonExistingProjectRequest();
        }
        _pendingProjectRequest[_lab] = false;

        if (_accepted) {
            newProject = Clones.clone(_projectTemplate);
            _activeProjects[newProject] = true;
            VCProject(newProject).init(address(this), _lab);
            _projectToLab[newProject] = _lab;
            emit SttrProjectCreated(_lab, newProject);
        } else {
            emit SttrProjectCreationRejected(_lab);
        }
    }

    /*********** EXTERNAL AND PUBLIC METHODS ***********/

    function createProjectRequest() external {
        _onlyWhitelistedLab();

        if (_pendingProjectRequest[msg.sender]) {
            revert Errors.SttrExistingProjectRequest();
        }
        _pendingProjectRequest[msg.sender] = true;
        emit SttrProjectRequest(msg.sender);
    }

    function fundProject(
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external {
        address lab = _fundProject(_project, _currency, _amount);
        _poCNft.mint(msg.sender, _amount);
        emit SttrProjectFunded(lab, _project, msg.sender, _currency, _amount);
    }

    function fundProjectOnBehalf(
        address _user,
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external {
        address lab = _fundProject(_project, _currency, _amount);
        _poCNft.mint(_user, _amount);
        emit SttrProjectFunded(lab, _project, _user, _currency, _amount);
    }

    function closeProject(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        _verifyCloseProject(_project, _sig);
        VCProject(_project).closeProject();
        _activeProjects[_project] = false;
        emit SttrProjectClosed(msg.sender, _project);
    }

    function startCampaign(
        address _project,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) external returns (uint256) {
        _onlyWhitelistedLab();
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = VCProject(_project).getNumberOfCampaigns();
        _verifyStartCampaign(_project, numberOfCampaigns, _target, _duration, _sig);

        if (_target < _minCampaignTarget || _target > _maxCampaignTarget) {
            revert Errors.SttrCampaignTargetError();
        }
        if (_duration < _minCampaignDuration || _duration > _maxCampaignDuration) {
            revert Errors.SttrCampaignDurationError();
        }
        uint256 softTarget = (_target * _softTargetBps) / _FEE_DENOMINATOR;
        uint256 campaignId = VCProject(_project).startCampaign(
            _target,
            softTarget,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout
        );
        emit SttrCampaignStarted(
            msg.sender,
            _project,
            campaignId,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout,
            _target,
            softTarget
        );
        return campaignId;
    }

    function publishCampaignResults(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = VCProject(_project).getNumberOfCampaigns();
        if (numberOfCampaigns == 0) {
            revert Errors.SttrResultsCannotBePublished();
        }

        uint256 currentCampaignId = numberOfCampaigns - 1;
        _verifyPublishCampaignResults(_project, currentCampaignId, _sig);
        VCProject(_project).publishCampaignResults();
        emit SttrCampaingClosed(msg.sender, _project, currentCampaignId);
    }

    function fundCampaign(
        address _project,
        uint256 _amount,
        IERC20 _currency
    ) external {
        address lab = _checkBeforeFund(_project, _amount, _currency);

        (uint256 campaignId, uint256 amountToCampaign, uint256 amountToPool, bool isFunded) = VCProject(_project)
            .getFundingAmounts(_amount);
        if (!_currency.transferFrom(msg.sender, _project, amountToCampaign)) {
            revert Errors.SttrERC20TransferError();
        }
        VCProject(_project).fundCampaign(_currency, msg.sender, amountToCampaign);
        emit SttrCampaignFunding(lab, _project, campaignId, _currency, msg.sender, amountToCampaign);

        if (amountToPool > 0) {
            if (!_currency.transferFrom(msg.sender, _pool, amountToPool)) {
                revert Errors.SttrERC20TransferError();
            }
            IVCPool(_pool).supportPoolFromStarter(msg.sender, amountToPool);
        }
        if (isFunded) {
            emit SttrCampaignFunded(lab, _project, campaignId);
        }
    }

    function backerMintPoCNft(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        uint256 amount = VCProject(_project).validateMint(_campaignId, _currency, msg.sender);
        _poCNft.mint(msg.sender, amount);
        emit SttrBackerMintPoCNft(_projectToLab[_project], _project, _campaignId, _currency, amount);
    }

    function backerWithdrawDefeated(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        (uint256 backerAmount, bool campaignDefeated) = VCProject(_project).backerWithdrawDefeated(
            _campaignId,
            msg.sender,
            _currency
        );
        emit SttrBackerWithdrawal(_projectToLab[_project], _project, _campaignId, _currency, backerAmount);
        if (campaignDefeated) {
            emit SttrCampaignDefeated(_projectToLab[_project], _project, _campaignId);
        }
    }

    function labCampaignWithdraw(address _project, IERC20 _currency) external {
        _onlyLabOwner(_project);

        (uint256 campaignId, uint256 withdrawAmount, bool campaignSucceeded) = VCProject(_project).labCampaignWithdraw(
            _currency
        );
        emit SttrLabCampaignWithdrawal(msg.sender, _project, campaignId, _currency, withdrawAmount);
        if (campaignSucceeded) {
            emit SttrCampaignSucceded(_projectToLab[_project], _project, campaignId);
        }
    }

    function labWithraw(address _project, IERC20 _currency) external {
        _onlyLabOwner(_project);

        uint256 amount = VCProject(_project).labWithdraw(_currency);
        emit SttrLabWithdrawal(msg.sender, _project, _currency, amount);
    }

    function transferUnclaimedFunds(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        address lab = _projectToLab[_project];
        (uint256 amountToPool, bool statusDefeated) = VCProject(_project).transferUnclaimedFunds(
            _campaignId,
            _currency,
            _pool
        );
        emit SttrUnclaimedFundsTransferredToPool(lab, _project, _campaignId, _currency, amountToPool);
        if (statusDefeated) {
            emit SttrCampaignDefeated(lab, _project, _campaignId);
        }
    }

    function withdrawToPool(address _project, IERC20 _currency) external {
        uint256 transferedAmount = VCProject(_project).withdrawToPool(_currency, _pool);
        emit SttrwithdrawToPool(_project, _currency, transferedAmount);
    }

    /*********** VIEW FUNCTIONS ***********/

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getCampaignStatus(address _project, uint256 _campaignId)
        public
        view
        returns (CampaignStatus currentStatus)
    {
        return VCProject(_project).getCampaignStatus(_campaignId);
    }

    function isValidProject(address _lab, address _project) external view returns (bool) {
        return _projectToLab[_project] == _lab;
    }

    function isWhitelistedLab(address _lab) external view returns (bool) {
        return _isWhitelistedLab[_lab];
    }

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory) {
        bool[] memory areActive = new bool[](_projects.length);
        for (uint256 i = 0; i < _projects.length; i++) {
            areActive[i] = _activeProjects[_projects[i]];
        }
        return areActive;
    }

    /*********** INTERNAL AND PRIVATE FUNCTIONS ***********/

    function _onlyAdmin() internal view {
        if (msg.sender != _admin) {
            revert Errors.SttrNotAdmin();
        }
    }

    function _onlyLabOwner(address _project) private view {
        if (msg.sender != _projectToLab[_project]) {
            revert Errors.SttrNotLabOwner();
        }
    }

    function _onlyWhitelistedLab() private view {
        if (_isWhitelistedLab[msg.sender] == false) {
            revert Errors.SttrNotWhitelistedLab();
        }
    }

    function _onlyCoreTeam() private view {
        if (msg.sender != _coreTeam) {
            revert Errors.SttrNotCoreTeam();
        }
    }

    function _checkBeforeFund(
        address _project,
        uint256 _amount,
        IERC20 _currency
    ) internal view returns (address lab) {
        lab = _projectToLab[_project];

        if (_amount == 0) {
            revert Errors.SttrFundingAmountIsZero();
        }
        if (_activeProjects[_project] == false) {
            revert Errors.SttrProjectIsNotActive();
        }
        if (lab == msg.sender) {
            revert Errors.SttrLabCannotFundOwnProject();
        }
        if (!_allowedCurrencies[_currency]) {
            revert Errors.SttrCurrencyNotWhitelisted();
        }
        if (!_isWhitelistedLab[lab]) {
            revert Errors.SttrBlacklistedLab();
        }
    }

    function _fundProject(
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) private returns (address lab) {
        lab = _checkBeforeFund(_project, _amount, _currency);

        if (!_currency.transferFrom(msg.sender, _project, _amount)) {
            revert Errors.SttrERC20TransferError();
        }
        VCProject(_project).fundProject(_amount, _currency);
    }

    function _verifyPublishCampaignResults(
        address _project,
        uint256 _campaignId,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _campaignId));
        _verify(messageHash, _sig);
    }

    function _verifyStartCampaign(
        address _project,
        uint256 _numberOfCampaigns,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _numberOfCampaigns, _target, _duration));
        _verify(messageHash, _sig);
    }

    function _verifyCloseProject(address _project, bytes memory _sig) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project));
        _verify(messageHash, _sig);
    }

    function _verify(bytes32 _messageHash, bytes memory _sig) private view {
        // this can change later - "\x19Ethereum Signed Message:\n32"
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

        if (_recover(ethSignedMessageHash, _sig) != _txValidator) {
            revert Errors.SttrInvalidSignature();
        }
    }

    function _recover(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        signer = ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_sig.length != 65) {
            revert Errors.SttrInvalidSignature();
        }

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;

    function setStarter(address _starter) external;

    function supportPoolFromStarter(address _supporter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
    // Starter Errors
    error SttrNotAdmin();
    error SttrNotWhitelistedLab();
    error SttrNotLabOwner();
    error SttrNotCoreTeam();
    error SttrLabAlreadyWhitelisted();
    error SttrLabAlreadyBlacklisted();
    error SttrFundingAmountIsZero();
    error SttrCurrencyAlreadyListed();
    error SttrCurrencyAlreadyUnlisted();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProject();
    error SttrCurrencyNotWhitelisted();
    error SttrBlacklistedLab();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequest();
    error SttrNonExistingProjectRequest();
    error SttrInvalidSignature();
    error SttrProjectIsNotActive();
    error SttrResultsCannotBePublished();

    // Project Errors
    error ProjOnlyStarter();
    error ProjBalanceIsZero();
    error ProjCampaignNotActive();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdraw();
    error ProjCampaignNotDefeated();
    error ProjCampaignNotNotFunded();
    error ProjCampaignNotFunded();
    error ProjCampaignNotSucceededNorFundedNorDefeated();
    error ProjResultsCannotBePublished();
    error ProjCampaignCannotStart();
    error ProjCannotBeClosed();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Errors} from "./Errors.sol";

struct CampaignData {
    uint256 target;
    uint256 softTarget;
    uint256 raisedAmount;
    uint256 balance;
    uint256 startTime;
    uint256 endTime;
    uint256 backersDeadline;
    bool resultsPublished;
}

enum CampaignStatus {
    ACTIVE,
    NOTFUNDED,
    FUNDED,
    SUCCEEDED,
    DEFEATED
}

contract VCProject is Initializable {
    address _starter;
    address _lab;
    uint256 _numberOfCampaigns;
    bool _projectStatus;

    mapping(uint256 => CampaignData) _campaigns;
    mapping(uint256 => mapping(address => mapping(IERC20 => uint256))) _backers;
    mapping(uint256 => mapping(IERC20 => uint256)) _campaignBalance;

    // Project balances: increase after funding and decrease after deposit
    mapping(IERC20 => uint256) _totalCampaignsBalance;
    mapping(IERC20 => uint256) _totalOutsideCampaignsBalance;
    uint256 _projectBalance; // en USD

    // Raised amounts: only increase after funding, never decrease
    uint256 _raisedAmountOutsideCampaigns; // en USD

    constructor() {}

    function init(address starter, address lab) external initializer {
        _starter = starter;
        _lab = lab;
        _numberOfCampaigns = 0;
        _raisedAmountOutsideCampaigns = 0;
        _projectStatus = true;
    }

    ///////////////////////
    // PROJECT FUNCTIONS //
    ///////////////////////

    function fundProject(uint256 _amount, IERC20 _currency) external {
        _onlyStarter();

        _raisedAmountOutsideCampaigns += _amount;
        _totalOutsideCampaignsBalance[_currency] += _amount;
        _projectBalance += _amount;
    }

    function closeProject() external {
        _onlyStarter();

        bool canBeClosed = _projectStatus && _projectBalance == 0;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canBeClosed =
                canBeClosed &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canBeClosed) {
            revert Errors.ProjCannotBeClosed();
        }
        _projectStatus = false;
    }

    ////////////////////////
    // CAMPAIGN FUNCTIONS //
    ////////////////////////

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256) {
        _onlyStarter();

        bool canStartCampaign = _projectStatus;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canStartCampaign =
                canStartCampaign &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canStartCampaign) {
            revert Errors.ProjCampaignCannotStart();
        }

        uint256 currentId = _numberOfCampaigns;
        _numberOfCampaigns++;

        _campaigns[currentId] = CampaignData(_target, _softTarget, 0, 0, _startTime, _endTime, _backersDeadline, false);
        return currentId;
    }

    function publishCampaignResults() external {
        _onlyStarter();

        uint256 currentCampaignId = _numberOfCampaigns - 1;
        CampaignStatus campaignStatus = getCampaignStatus(currentCampaignId);
        bool resultsPublished = _campaigns[currentCampaignId].resultsPublished;

        if (campaignStatus != CampaignStatus.SUCCEEDED || resultsPublished == true) {
            revert Errors.ProjResultsCannotBePublished();
        }

        _campaigns[currentCampaignId].resultsPublished = true;
    }

    function fundCampaign(
        IERC20 _currency,
        address _user,
        uint256 _amount
    ) external {
        _onlyStarter();
        uint256 currentCampaignId = _numberOfCampaigns - 1;

        _backers[currentCampaignId][_user][_currency] += _amount;
        _updateBalances(currentCampaignId, _currency, _amount, true);
    }

    function validateMint(
        uint256 _campaignId,
        IERC20 _currency,
        address _user
    ) external returns (uint256 backerBalance) {
        _onlyStarter();
        CampaignStatus currentCampaignStatus = getCampaignStatus(_campaignId);

        if (currentCampaignStatus == CampaignStatus.ACTIVE || currentCampaignStatus == CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotSucceededNorFundedNorDefeated();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }
        _backers[_campaignId][_user][_currency] = 0;
    }

    function backerWithdrawDefeated(
        uint256 _campaignId,
        address _user,
        IERC20 _currency
    ) external returns (uint256 backerBalance, bool statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotNotFunded();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _backers[_campaignId][_user][_currency] = 0;
        _updateBalances(_campaignId, _currency, backerBalance, false);
        if (_campaigns[_campaignId].balance == 0) {
            statusDefeated = true;
        }

        if (!_currency.transfer(_user, backerBalance)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labCampaignWithdraw(IERC20 _currency)
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            bool statusSucceeded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.FUNDED) {
            revert Errors.ProjCampaignNotFunded();
        }

        withdrawAmount = _campaignBalance[currentCampaignId][_currency];

        if (withdrawAmount == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(currentCampaignId, _currency, withdrawAmount, false);
        if (_campaigns[currentCampaignId].balance == 0) {
            statusSucceeded = true;
        }

        if (!_currency.transfer(_lab, withdrawAmount)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labWithdraw(IERC20 _currency) external returns (uint256 _amount) {
        _onlyStarter();

        _amount = _totalOutsideCampaignsBalance[_currency];

        if (_totalOutsideCampaignsBalance[_currency] == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        if (!_currency.transfer(_lab, _amount)) {
            revert Errors.ProjERC20TransferError();
        }
        _totalOutsideCampaignsBalance[_currency] = 0;
        _projectBalance -= _amount;
    }

    function withdrawToPool(IERC20 _currency, address _receiver) external returns (uint256 amountAvailable) {
        _onlyStarter();
        amountAvailable =
            _currency.balanceOf(address(this)) -
            _totalCampaignsBalance[_currency] -
            _totalOutsideCampaignsBalance[_currency];
        if (amountAvailable == 0) {
            revert Errors.ProjZeroAmountToWithdraw();
        }
        if (!_currency.transfer(_receiver, amountAvailable)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function transferUnclaimedFunds(
        uint256 _campaignId,
        IERC20 _currency,
        address _pool
    ) external returns (uint256 _amountToPool, bool _statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.DEFEATED) {
            revert Errors.ProjCampaignNotDefeated();
        }
        _amountToPool = _campaignBalance[_campaignId][_currency];
        if (_amountToPool == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(_campaignId, _currency, _amountToPool, false);
        if (_campaigns[_campaignId].balance == 0) {
            _statusDefeated = true;
        }

        if (!_currency.transfer(_pool, _amountToPool)) {
            revert Errors.SttrERC20TransferError();
        }
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function getNumberOfCampaigns() external view returns (uint256) {
        return _numberOfCampaigns;
    }

    function getCampaignRaisedAmount(uint256 _campaignId) external view returns (uint256) {
        return _campaigns[_campaignId].raisedAmount;
    }

    function getRaisedAmountFromCampaigns() public view returns (uint256 raisedAmount) {
        for (uint256 i = 0; i <= _numberOfCampaigns; i++) {
            if (getCampaignStatus(i) == CampaignStatus.SUCCEEDED) {
                raisedAmount += _campaigns[i].raisedAmount;
            }
        }
    }

    function getRaisedAmountOutsideCampaigns() public view returns (uint256 raisedAmount) {
        return _raisedAmountOutsideCampaigns;
    }

    function getTotalRaisedAmount() external view returns (uint256) {
        return getRaisedAmountFromCampaigns() + _raisedAmountOutsideCampaigns;
    }

    function campaignBalance(uint256 _campaignId, IERC20 _currency) external view returns (uint256) {
        return _campaignBalance[_campaignId][_currency];
    }

    function totalCampaignBalance(IERC20 _currency) external view returns (uint256) {
        return _totalCampaignsBalance[_currency];
    }

    function totalOutsideCampaignsBalance(IERC20 _currency) external view returns (uint256) {
        return _totalOutsideCampaignsBalance[_currency];
    }

    function projectBalance() external view returns (uint256) {
        return _projectBalance;
    }

    function getCampaignStatus(uint256 _campaignId) public view returns (CampaignStatus currentStatus) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        uint256 target = campaignData.target;
        uint256 softTarget = campaignData.softTarget;
        uint256 raisedAmount = campaignData.raisedAmount;
        uint256 balance = campaignData.balance;
        uint256 endTime = campaignData.endTime;
        uint256 backersDeadline = campaignData.backersDeadline;

        uint256 currentTime = block.timestamp;

        if (raisedAmount == target || (raisedAmount >= softTarget && currentTime > endTime)) {
            if (balance > 0) {
                return CampaignStatus.FUNDED;
            } else {
                return CampaignStatus.SUCCEEDED;
            }
        } else if (currentTime <= endTime) {
            return CampaignStatus.ACTIVE;
        } else if (currentTime <= backersDeadline && balance > 0) {
            return CampaignStatus.NOTFUNDED;
        } else {
            return CampaignStatus.DEFEATED;
        }
    }

    function getProjectStatus() external view returns (bool) {
        return _projectStatus;
    }

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.ACTIVE) {
            revert Errors.ProjCampaignNotActive();
        }

        uint256 amountToTarget = _campaigns[currentCampaignId].target - _campaigns[currentCampaignId].balance;

        if (amountToTarget > _amount) {
            amountToCampaign = _amount;
            amountToPool = 0;
            isFunded = false;
        } else {
            amountToCampaign = amountToTarget;
            amountToPool = _amount - amountToCampaign;
            isFunded = true;
        }
    }

    function _onlyStarter() private view {
        if (msg.sender != _starter) {
            revert Errors.ProjOnlyStarter();
        }
    }

    ////////////////////////////////
    // PRIVATE/INTERNAL FUNCTIONS //
    ////////////////////////////////

    function _updateBalances(
        uint256 _campaignId,
        IERC20 _currency,
        uint256 _amount,
        bool _fund
    ) private {
        if (_fund) {
            _campaigns[_campaignId].balance += _amount;
            _campaigns[_campaignId].raisedAmount += _amount;
            _campaignBalance[_campaignId][_currency] += _amount;
            _totalCampaignsBalance[_currency] += _amount;
            _projectBalance += _amount;
        } else {
            _campaigns[_campaignId].balance -= _amount;
            _campaignBalance[_campaignId][_currency] -= _amount;
            _totalCampaignsBalance[_currency] -= _amount;
            _projectBalance -= _amount;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

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
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
        /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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