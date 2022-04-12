// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./Interfaces/ILosslessERC20.sol";
import "./Interfaces/ILosslessController.sol";
import "./Interfaces/ILosslessGovernance.sol";
import "./Interfaces/ILosslessReporting.sol";

/// @title Lossless Reporting Contract
/// @author Lossless.cash
/// @notice The Reporting smart contract is in charge of handling all the parts related to creating new reports
contract LosslessReporting is ILssReporting, Initializable, ContextUpgradeable, PausableUpgradeable {
    uint256 override public reporterReward;
    uint256 override public losslessReward;
    uint256 override public stakersReward;
    uint256 override public committeeReward;

    uint256 override public reportLifetime;
    uint256 override public reportingAmount;

    uint256 override public reportCount;

    uint256 public constant HUNDRED = 1e2;

    ILERC20 override public stakingToken;
    ILssController override public losslessController;
    ILssGovernance override public losslessGovernance;

    struct TokenReports {
        mapping(address => uint256) reports;
    }

    mapping(ILERC20 => TokenReports) private tokenReports;

    //mapping(uint256 => bool)  private reporterClaimStatus;

    struct Report {
        address reporter;
        address reportedAddress;
        address secondReportedAddress;
        uint256 reportTimestamps;
        ILERC20 reportTokens;
        bool secondReports;
        bool reporterClaimStatus;
    }

    mapping(uint256 => Report) reportInfo;

    // --- MODIFIERS ---

    /// @notice Avoids execution from other than the Lossless Admin
    modifier onlyLosslessAdmin() {
        require(msg.sender == losslessController.admin(), "LSS: Must be admin");
        _;
    }

    /// @notice Avoids execution from other than the Pause Admin
    modifier onlyPauseAdmin() {
        require(msg.sender == losslessController.pauseAdmin(), "LSS: Must be pauseAdmin");
        _;
    }

    /// @notice Avoids execution from blacklisted addresses
    modifier notBlacklisted() {
        require(!losslessController.blacklist(msg.sender), "LSS: You cannot operate");
        _;
    }

    /// @notice Avoids execution from other than the Lossless Governance
    modifier onlyLosslessGov {
        require(msg.sender == address(losslessGovernance),
                "LSS: Lss SC only");
        _;
    }

    /// @notice Avoids rewards to exceed a hundrer percent
    modifier cannotExceedHundred() {
        _;
        require(reporterReward + losslessReward + committeeReward + stakersReward <= 100, "LSS: Total exceed 100");
    }

    function initialize(ILssController _losslessController) public initializer {
        reportCount = 0;
        losslessController = _losslessController;
    }
    
    // --- SETTERS ---

    /// @notice This function pauses the contract
    function pause() override public onlyPauseAdmin{
        _pause();
    }    

    /// @notice This function unpauses the contract
    function unpause() override public onlyPauseAdmin{
        _unpause();
    }

    /// @notice This function sets the address of the Lossless Governance Token
    /// @dev Only can be called by the Lossless Admin
    /// @param _stakingToken Address corresponding to the Lossless Governance Token
    function setStakingToken(ILERC20 _stakingToken) override public onlyLosslessAdmin {
        require(address(_stakingToken) != address(0), "LSS: Cannot be zero address");
        require(_stakingToken != stakingToken, "LSS: Cannot be same address");
        stakingToken = _stakingToken;
        emit NewStakingToken(stakingToken);
    }

    /// @notice This function sets the address of the Lossless Governance smart contract
    /// @dev Only can be called by the Lossless Admin
    /// @param _losslessGovernance Address corresponding to the Lossless Governance smart contract
    function setLosslessGovernance(ILssGovernance _losslessGovernance) override public onlyLosslessAdmin {
        require(address(_losslessGovernance) != address(0), "LSS: Cannot be zero address");
        require(_losslessGovernance != losslessGovernance, "LSS: Cannot be same address");
        losslessGovernance = _losslessGovernance;
        emit NewGovernanceContract(losslessGovernance);
    }

    /// @notice This function sets the amount of tokens to be staked when reporting
    /// @param _reportingAmount Amount to generate a report
    function setReportingAmount(uint256 _reportingAmount) override public onlyLosslessAdmin {
        require(reportingAmount != _reportingAmount, "LSS: Already set to that amount");
        reportingAmount = _reportingAmount;
        emit NewReportingAmount(_reportingAmount);
    }

    /// @notice This function sets the default reporter reward
    /// @param _reward Percentage rewarded to the reporter when a report gets resolved positively
    function setReporterReward(uint256 _reward) override public onlyLosslessAdmin cannotExceedHundred {
        require(_reward != reporterReward, "LSS: Already set to that amount");
        reporterReward = _reward;
        emit NewReporterReward(_reward);
    }

    /// @notice This function sets the default Lossless Reward
    /// @param _reward Percentage attributed to Lossless when a report gets resolved positively
    function setLosslessReward(uint256 _reward) override public onlyLosslessAdmin cannotExceedHundred {
        require(_reward != losslessReward, "LSS: Already set to that amount");
        losslessReward = _reward;
        emit NewLosslessReward(_reward);
    }

    /// @notice This function sets the default Stakers Reward
    /// @param _reward Percentage attributed to Stakers when a report gets resolved positively
    function setStakersReward(uint256 _reward) override public onlyLosslessAdmin cannotExceedHundred {
        require(_reward != stakersReward, "LSS: Already set to that amount");
        stakersReward = _reward;
        emit NewStakersReward(_reward);
    }

    /// @notice This function sets the default Committee Reward
    /// @param _reward Percentage attributed to committee when a report gets resolved positively
    function setCommitteeReward(uint256 _reward) override public onlyLosslessAdmin cannotExceedHundred {
        require(_reward != committeeReward, "LSS: Already set to that amount");
        committeeReward = _reward;
        emit NewCommitteeReward(_reward);
    }

    /// @notice This function sets the default lifetime of the reports
    /// @param _lifetime Time frame of which a report is active
    function setReportLifetime(uint256 _lifetime) override public onlyLosslessAdmin {
        require(_lifetime != reportLifetime, "LSS: Already set to that amount");
        reportLifetime = _lifetime;
        emit NewReportLifetime(reportLifetime);
    }

    // --- GETTERS ---

    /// @notice This function gets the contract version
    /// @return Version of the contract
    function getVersion() override external pure returns (uint256) {
        return 1;
    }

    /// @notice This function will return the reward amount for all parties
    /// @return _reporter Returns the reporter reward
    /// @return _lossless Returns the Lossless Reward
    /// @return _committee Returns the committee Reward
    /// @return _stakers Returns the stakers Reward
    function getRewards() override external view returns (uint256 _reporter, uint256 _lossless, uint256 _committee, uint256 _stakers) {
        return (reporterReward, losslessReward, committeeReward, stakersReward);
    }
    
    /// @notice This function will return the admin of the repoted token
    /// @param _reportId Report Id to get admin
    /// @return reporter
    /// @return reportedAddress
    /// @return secondReportedAddress
    /// @return reportTimestamps
    /// @return reportTokens
    /// @return secondReports 
    /// @return reporterClaimStatus 
    function getReportInfo(uint256 _reportId) override external view returns(address reporter,
        address reportedAddress,
        address secondReportedAddress,
        uint256 reportTimestamps,
        ILERC20 reportTokens,
        bool secondReports,
        bool reporterClaimStatus) {

        Report storage queriedReport = reportInfo[_reportId];

        return (queriedReport.reporter, 
        queriedReport.reportedAddress, 
        queriedReport.secondReportedAddress, 
        queriedReport.reportTimestamps, 
        queriedReport.reportTokens, 
        queriedReport.secondReports, 
        queriedReport.reporterClaimStatus);
    }

    // --- REPORTS ---

    /// @notice This function will generate a report
    /// @dev This function must be called by a non blacklisted/reported address. 
    /// It will generate a report for an address linked to a token.
    /// Lossless Contracts, Admin addresses and Dexes cannot be reported.
    /// @param _token Token address of the stolen funds
    /// @param _account Potential malicious address
    function report(ILERC20 _token, address _account) override public notBlacklisted whenNotPaused returns (uint256){
        require(_account != address(0), "LSS: Cannot report zero address");
        require(!losslessController.whitelist(_account), "LSS: Cannot report LSS protocol");
        require(!losslessController.dexList(_account), "LSS: Cannot report Dex");

        uint256 reportId = tokenReports[_token].reports[_account];

        require(reportId == 0 || 
                reportInfo[reportId].reportTimestamps + reportLifetime < block.timestamp || 
                losslessGovernance.isReportSolved(reportId) && 
                !losslessGovernance.reportResolution(reportId), "LSS: Report already exists");

        reportCount += 1;
        reportId = reportCount;
        reportInfo[reportId].reporter = msg.sender;

        tokenReports[_token].reports[_account] = reportId;
        reportInfo[reportId].reportTimestamps = block.timestamp;
        reportInfo[reportId].reportTokens = _token;

        require(stakingToken.transferFrom(msg.sender, address(this), reportingAmount), "LSS: Reporting stake failed");

        losslessController.addToBlacklist(_account);
        reportInfo[reportId].reportedAddress = _account;
        
        losslessController.activateEmergency(_token);

        emit ReportSubmission(_token, _account, reportId, reportingAmount);

        return reportId;
    }


    /// @notice This function will add a second address to a given report.
    /// @dev This funtion must be called by a non blacklisted/reported address. 
    /// It will generate a second report linked to the first one created. 
    /// This can be used in the event that the malicious actor is able to frontrun the first report by swapping the tokens or transfering.
    /// @param _reportId Report that was previously generated.
    /// @param _account Potential malicious address
    function secondReport(uint256 _reportId, address _account) override public whenNotPaused {
        require(_account != address(0), "LSS: Cannot report zero address");
        require(!losslessGovernance.isReportSolved(_reportId) && !losslessGovernance.reportResolution(_reportId), "LSS: Report already solved");
        require(!losslessController.whitelist(_account), "LSS: Cannot report LSS protocol");
        require(!losslessController.dexList(_account), "LSS: Cannot report Dex");

        Report storage queriedReport = reportInfo[_reportId]; 

        uint256 reportTimestamp = queriedReport.reportTimestamps;
        ILERC20 token = queriedReport.reportTokens;

        require(_reportId != 0 && reportTimestamp + reportLifetime > block.timestamp, "LSS: report does not exists");
        require(queriedReport.secondReports == false, "LSS: Another already submitted");
        require(msg.sender == queriedReport.reporter, "LSS: invalid reporter");

        queriedReport.secondReports = true;
        tokenReports[token].reports[_account] = _reportId;

        losslessController.addToBlacklist(_account);
        queriedReport.secondReportedAddress = _account;

        emit SecondReportSubmission(token, _account, _reportId);
    }

    /// @notice This function is for the reporter to claim their rewards
    /// @param _reportId Staked report
    function reporterClaim(uint256 _reportId) override public whenNotPaused {
        require(reportInfo[_reportId].reporter == msg.sender, "LSS: Only reporter");
        require(losslessGovernance.reportResolution(_reportId), "LSS: Report solved negatively");

        Report storage queriedReport = reportInfo[_reportId];

        require(!queriedReport.reporterClaimStatus, "LSS: You already claimed");

        queriedReport.reporterClaimStatus = true;

        uint256 amountToClaim = reporterClaimableAmount(_reportId);

        require(queriedReport.reportTokens.transfer(msg.sender, amountToClaim), "LSS: Token transfer failed");
        require(stakingToken.transfer(msg.sender, reportingAmount), "LSS: Reporting stake failed");
        emit ReporterClaim(msg.sender, _reportId, amountToClaim);
    }

    // --- CLAIM ---

    /// @notice This function returns the claimable amount by the reporter
    /// @dev The reporter has a fixed percentage as reward.
    /// @param _reportId Staked report    
    function reporterClaimableAmount(uint256 _reportId) override public view returns (uint256) {
        uint256 reportedAmount = losslessGovernance.getAmountReported(_reportId);
        return reportedAmount * reporterReward / HUNDRED;
    }
    
    /// @notice This function allows the governance token to retribute an erroneous report
    /// @param _adr retribution address
    /// @param _amount amount to be retrieved
    function retrieveCompensation(address _adr, uint256 _amount) override public onlyLosslessGov {
        require(stakingToken.transfer(_adr, _amount), "LSS: Compensation retrieve fail");
        emit CompensationRetrieve(_adr, _amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
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
pragma solidity ^0.8.0;

interface ILERC20 {
    function name() external view returns (string memory);
    function admin() external view returns (address);
    function getAdmin() external view returns (address);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _account) external view returns (uint256);
    function transfer(address _recipient, uint256 _amount) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function transferFrom(address _sender, address _recipient, uint256 _amount) external returns (bool);
    function increaseAllowance(address _spender, uint256 _addedValue) external returns (bool);
    function decreaseAllowance(address _spender, uint256 _subtractedValue) external returns (bool);
    
    function transferOutBlacklistedFunds(address[] calldata _from) external;
    function setLosslessAdmin(address _newAdmin) external;
    function transferRecoveryAdminOwnership(address _candidate, bytes32 _keyHash) external;
    function acceptRecoveryAdminOwnership(bytes memory _key) external;
    function proposeLosslessTurnOff() external;
    function executeLosslessTurnOff() external;
    function executeLosslessTurnOn() external;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event NewAdmin(address indexed _newAdmin);
    event NewRecoveryAdminProposal(address indexed _candidate);
    event NewRecoveryAdmin(address indexed _newAdmin);
    event LosslessTurnOffProposal(uint256 _turnOffDate);
    event LosslessOff();
    event LosslessOn();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./IProtectionStrategy.sol";

interface ILssController {
    // function getLockedAmount(ILERC20 _token, address _account)  returns (uint256);
    // function getAvailableAmount(ILERC20 _token, address _account) external view returns (uint256 amount);
    function retrieveBlacklistedFunds(address[] calldata _addresses, ILERC20 _token, uint256 _reportId) external returns(uint256);
    function whitelist(address _adr) external view returns (bool);
    function dexList(address _dexAddress) external returns (bool);
    function blacklist(address _adr) external view returns (bool);
    function admin() external view returns (address);
    function pauseAdmin() external view returns (address);
    function recoveryAdmin() external view returns (address);
    function guardian() external view returns (address);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessGovernance() external view returns (ILssGovernance);
    function dexTranferThreshold() external view returns (uint256);
    function settlementTimeLock() external view returns (uint256);
    
    function pause() external;
    function unpause() external;
    function setAdmin(address _newAdmin) external;
    function setRecoveryAdmin(address _newRecoveryAdmin) external;
    function setPauseAdmin(address _newPauseAdmin) external;
    function setSettlementTimeLock(uint256 _newTimelock) external;
    function setDexTransferThreshold(uint256 _newThreshold) external;
    function setDexList(address[] calldata _dexList, bool _value) external;
    function setWhitelist(address[] calldata _addrList, bool _value) external;
    function addToBlacklist(address _adr) external;
    function resolvedNegatively(address _adr) external;
    function setStakingContractAddress(ILssStaking _adr) external;
    function setReportingContractAddress(ILssReporting _adr) external; 
    function setGovernanceContractAddress(ILssGovernance _adr) external;
    function proposeNewSettlementPeriod(ILERC20 _token, uint256 _seconds) external;
    function executeNewSettlementPeriod(ILERC20 _token) external;
    function activateEmergency(ILERC20 _token) external;
    function deactivateEmergency(ILERC20 _token) external;
    function setGuardian(address _newGuardian) external;
    function removeProtectedAddress(ILERC20 _token, address _protectedAddresss) external;
    function beforeTransfer(address _sender, address _recipient, uint256 _amount) external;
    function beforeTransferFrom(address _msgSender, address _sender, address _recipient, uint256 _amount) external;
    function beforeApprove(address _sender, address _spender, uint256 _amount) external;
    function beforeIncreaseAllowance(address _msgSender, address _spender, uint256 _addedValue) external;
    function beforeDecreaseAllowance(address _msgSender, address _spender, uint256 _subtractedValue) external;
    function beforeMint(address _to, uint256 _amount) external;
    function beforeBurn(address _account, uint256 _amount) external;
    function setProtectedAddress(ILERC20 _token, address _protectedAddress, ProtectionStrategy _strategy) external;

    event AdminChange(address indexed _newAdmin);
    event RecoveryAdminChange(address indexed _newAdmin);
    event PauseAdminChange(address indexed _newAdmin);
    event GuardianSet(address indexed _oldGuardian, address indexed _newGuardian);
    event NewProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress, address indexed _strategy);
    event RemovedProtectedAddress(ILERC20 indexed _token, address indexed _protectedAddress);
    event NewSettlementPeriodProposal(ILERC20 indexed _token, uint256 _seconds);
    event SettlementPeriodChange(ILERC20 indexed _token, uint256 _proposedTokenLockTimeframe);
    event NewSettlementTimelock(uint256 indexed _timelock);
    event NewDexThreshold(uint256 indexed _newThreshold);
    event NewDex(address indexed _dexAddress);
    event DexRemoval(address indexed _dexAddress);
    event NewWhitelistedAddress(address indexed _whitelistAdr);
    event WhitelistedAddressRemoval(address indexed _whitelistAdr);
    event NewBlacklistedAddress(address indexed _blacklistedAddres);
    event AccountBlacklistRemoval(address indexed _adr);
    event NewStakingContract(ILssStaking indexed _newAdr);
    event NewReportingContract(ILssReporting indexed _newAdr);
    event NewGovernanceContract(ILssGovernance indexed _newAdr);
    event EmergencyActive(ILERC20 indexed _token);
    event EmergencyDeactivation(ILERC20 indexed _token);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessStaking.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssGovernance {
    function LSS_TEAM_INDEX() external view returns(uint256);
    function TOKEN_OWNER_INDEX() external view returns(uint256);
    function COMMITEE_INDEX() external view returns(uint256);
    function committeeMembersCount() external view returns(uint256);
    function walletDisputePeriod() external view returns(uint256);
    function losslessStaking() external view returns (ILssStaking);
    function losslessReporting() external view returns (ILssReporting);
    function losslessController() external view returns (ILssController);
    function isCommitteeMember(address _account) external view returns(bool);
    function getIsVoted(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function getVote(uint256 _reportId, uint256 _voterIndex) external view returns(bool);
    function isReportSolved(uint256 _reportId) external view returns(bool);
    function reportResolution(uint256 _reportId) external view returns(bool);
    function getAmountReported(uint256 _reportId) external view returns(uint256);
    
    function setDisputePeriod(uint256 _timeFrame) external;
    function addCommitteeMembers(address[] memory _members) external;
    function removeCommitteeMembers(address[] memory _members) external;
    function losslessVote(uint256 _reportId, bool _vote) external;
    function tokenOwnersVote(uint256 _reportId, bool _vote) external;
    function committeeMemberVote(uint256 _reportId, bool _vote) external;
    function resolveReport(uint256 _reportId) external;
    function proposeWallet(uint256 _reportId, address wallet) external;
    function rejectWallet(uint256 _reportId) external;
    function retrieveFunds(uint256 _reportId) external;
    function retrieveCompensation() external;
    function claimCommitteeReward(uint256 _reportId) external;
    function setCompensationAmount(uint256 _amount) external;
    function losslessClaim(uint256 _reportId) external;
    function setRevshareAdmin(address _address) external;
    function setRevsharePercentage(uint256 _amount) external;
    function revshareClaim(uint256 _reportId) external;

    event NewCommitteeMembers(address[] _members);
    event CommitteeMembersRemoval(address[] _members);
    event LosslessTeamPositiveVote(uint256 indexed _reportId);
    event LosslessTeamNegativeVote(uint256 indexed _reportId);
    event TokenOwnersPositiveVote(uint256 indexed _reportId);
    event TokenOwnersNegativeVote(uint256 indexed _reportId);
    event CommitteeMemberPositiveVote(uint256 indexed _reportId, address indexed _member);
    event CommitteeMemberNegativeVote(uint256 indexed _reportId, address indexed _member);
    event ReportResolve(uint256 indexed _reportId, bool indexed _resolution);
    event WalletProposal(uint256 indexed _reportId, address indexed _wallet);
    event CommitteeMemberClaim(uint256 indexed _reportId, address indexed _member, uint256 indexed _amount);
    event CommitteeMajorityReach(uint256 indexed _reportId, bool indexed _result);
    event NewDisputePeriod(uint256 indexed _newPeriod);
    event WalletRejection(uint256 indexed _reportId);
    event FundsRetrieval(uint256 indexed _reportId, uint256 indexed _amount);
    event CompensationRetrieval(address indexed _wallet, uint256 indexed _amount);
    event LosslessClaim(ILERC20 indexed _token, uint256 indexed _reportID, uint256 indexed _amount);
    event NewCompensationPercentage(uint256 indexed _compensationPercentage);
    event NewRevshareAdmin(address indexed _revshareAdmin);
    event NewRevsharePercentage(uint256 indexed _revsharePercentage);
    event RevshareClaim(ILERC20 indexed _token, uint256 indexed _reportID, uint256 indexed _amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessStaking.sol";
import "./ILosslessController.sol";

interface ILssReporting {
  function reporterReward() external returns(uint256);
  function losslessReward() external returns(uint256);
  function stakersReward() external returns(uint256);
  function committeeReward() external returns(uint256);
  function reportLifetime() external view returns(uint256);
  function reportingAmount() external returns(uint256);
  function reportCount() external returns(uint256);
  function stakingToken() external returns(ILERC20);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function getVersion() external pure returns (uint256);
  function getRewards() external view returns (uint256 _reporter, uint256 _lossless, uint256 _committee, uint256 _stakers);
  function report(ILERC20 _token, address _account) external returns (uint256);
  function reporterClaimableAmount(uint256 _reportId) external view returns (uint256);
  function getReportInfo(uint256 _reportId) external view returns(address _reporter,
        address _reportedAddress,
        address _secondReportedAddress,
        uint256 _reportTimestamps,
        ILERC20 _reportTokens,
        bool _secondReports,
        bool _reporterClaimStatus);
  
  function pause() external;
  function unpause() external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setReportingAmount(uint256 _reportingAmount) external;
  function setReporterReward(uint256 _reward) external;
  function setLosslessReward(uint256 _reward) external;
  function setStakersReward(uint256 _reward) external;
  function setCommitteeReward(uint256 _reward) external;
  function setReportLifetime(uint256 _lifetime) external;
  function secondReport(uint256 _reportId, address _account) external;
  function reporterClaim(uint256 _reportId) external;
  function retrieveCompensation(address _adr, uint256 _amount) external;

  event ReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event SecondReportSubmission(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId);
  event NewReportingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _token);
  event NewGovernanceContract(ILssGovernance indexed _adr);
  event NewReporterReward(uint256 indexed _newValue);
  event NewLosslessReward(uint256 indexed _newValue);
  event NewStakersReward(uint256 indexed _newValue);
  event NewCommitteeReward(uint256 indexed _newValue);
  event NewReportLifetime(uint256 indexed _newValue);
  event ReporterClaim(address indexed _reporter, uint256 indexed _reportId, uint256 indexed _amount);
  event CompensationRetrieve(address indexed _adr, uint256 indexed _amount);
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
pragma solidity ^0.8.0;

import "./ILosslessERC20.sol";
import "./ILosslessGovernance.sol";
import "./ILosslessReporting.sol";
import "./ILosslessController.sol";

interface ILssStaking {
  function stakingToken() external returns(ILERC20);
  function losslessReporting() external returns(ILssReporting);
  function losslessController() external returns(ILssController);
  function losslessGovernance() external returns(ILssGovernance);
  function stakingAmount() external returns(uint256);
  function getVersion() external pure returns (uint256);
  function getIsAccountStaked(uint256 _reportId, address _account) external view returns(bool);
  function getStakerCoefficient(uint256 _reportId, address _address) external view returns (uint256);
  function stakerClaimableAmount(uint256 _reportId) external view returns (uint256);
  
  function pause() external;
  function unpause() external;
  function setLssReporting(ILssReporting _losslessReporting) external;
  function setStakingToken(ILERC20 _stakingToken) external;
  function setLosslessGovernance(ILssGovernance _losslessGovernance) external;
  function setStakingAmount(uint256 _stakingAmount) external;
  function stake(uint256 _reportId) external;
  function stakerClaim(uint256 _reportId) external;

  event NewStake(ILERC20 indexed _token, address indexed _account, uint256 indexed _reportId, uint256 _amount);
  event StakerClaim(address indexed _staker, ILERC20 indexed _token, uint256 indexed _reportID, uint256 _amount);
  event NewStakingAmount(uint256 indexed _newAmount);
  event NewStakingToken(ILERC20 indexed _newToken);
  event NewReportingContract(ILssReporting indexed _newContract);
  event NewGovernanceContract(ILssGovernance indexed _newContract);
}

pragma solidity ^0.8.0;

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}