// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./Interfaces/ILosslessERC20.sol";
import "./Interfaces/ILosslessController.sol";
import "./Interfaces/ILosslessStaking.sol";
import "./Interfaces/ILosslessReporting.sol";
import "./Interfaces/ILosslessGovernance.sol";

/// @title Lossless Governance Contract
/// @notice The governance contract is in charge of handling the voting process over the reports and their resolution
contract LosslessGovernance is ILssGovernance, Initializable, AccessControlUpgradeable, PausableUpgradeable {

    uint256 override public constant LSS_TEAM_INDEX = 0;
    uint256 override public constant TOKEN_OWNER_INDEX = 1;
    uint256 override public constant COMMITEE_INDEX = 2;

    bytes32 public constant COMMITTEE_ROLE = keccak256("COMMITTEE_ROLE");

    uint256 override public committeeMembersCount;

    uint256 override public walletDisputePeriod;

    uint256 public compensationPercentage;

    uint256 public constant HUNDRED = 1e2;

    ILssReporting override public losslessReporting;
    ILssController override public losslessController;
    ILssStaking override public losslessStaking;

    struct Vote {
        mapping(address => bool) committeeMemberVoted;
        mapping(address => bool) committeeMemberClaimed;
        bool[] committeeVotes;
        bool[3] votes;
        bool[3] voted;
        bool resolved;
        bool resolution;
        bool losslessPayed;
        uint256 amountReported;
    }
    mapping(uint256 => Vote) public reportVotes;

    struct ProposedWallet {
        uint16 proposal;
        uint16 committeeDisagree;
        uint256 retrievalAmount;
        uint256 timestamp;
        address wallet;
        bool status;
        bool losslessVote;
        bool losslessVoted;
        bool tokenOwnersVote;
        bool tokenOwnersVoted;
        bool walletAccepted;
        mapping (uint16 => MemberVotesOnProposal) memberVotesOnProposal;
    }

    mapping(uint256 => ProposedWallet) public proposedWalletOnReport;

    struct Compensation {
        uint256 amount;
        bool payed;
    }

    struct MemberVotesOnProposal {
        mapping (address => bool) memberVoted;
    }

    mapping(address => Compensation) private compensation;

    address[] private reportedAddresses;

    function initialize(ILssReporting _losslessReporting, ILssController _losslessController, ILssStaking _losslessStaking, uint256 _walletDisputePeriod) public initializer {
        losslessReporting = _losslessReporting;
        losslessController = _losslessController;
        losslessStaking = _losslessStaking;
        walletDisputePeriod = _walletDisputePeriod;
        committeeMembersCount = 0;
    }

    modifier onlyLosslessAdmin() {
        require(msg.sender == losslessController.admin(), "LSS: Must be admin");
        _;
    }

    modifier onlyLosslessPauseAdmin() {
        require(msg.sender == losslessController.pauseAdmin(), "LSS: Must be pauseAdmin");
        _;
    }

    // --- ADMINISTRATION ---

    function pause() public onlyLosslessPauseAdmin  {
        _pause();
    }    
    
    function unpause() public onlyLosslessPauseAdmin {
        _unpause();
    }

    
    /// @notice This function gets the contract version
    /// @return Version of the contract
    function getVersion() external pure returns (uint256) {
        return 1;
    }
    
    /// @notice This function determines if an address belongs to the Committee
    /// @param _account Address to be verified
    /// @return True if the address is a committee member
    function isCommitteeMember(address _account) override public view returns(bool) {
        return hasRole(COMMITTEE_ROLE, _account);
    }

    /// @notice This function returns if a report has been voted by one of the three fundamental parts
    /// @param _reportId Report number to be checked
    /// @param _voterIndex Voter Index to be checked
    /// @return True if it has been voted
    function getIsVoted(uint256 _reportId, uint256 _voterIndex) override public view returns(bool) {
        return reportVotes[_reportId].voted[_voterIndex];
    }

    /// @notice This function returns the resolution on a report by a team 
    /// @param _reportId Report number to be checked
    /// @param _voterIndex Voter Index to be checked
    /// @return True if it has voted
    function getVote(uint256 _reportId, uint256 _voterIndex) override public view returns(bool) {
        return reportVotes[_reportId].votes[_voterIndex];
    }

    /// @notice This function returns if report has been resolved    
    /// @param _reportId Report number to be checked
    /// @return True if it has been solved
    function isReportSolved(uint256 _reportId) override public view returns(bool){
        return reportVotes[_reportId].resolved;
    }

    /// @notice This function returns report resolution     
    /// @param _reportId Report number to be checked
    /// @return True if it has been resolved positively
    function reportResolution(uint256 _reportId) override public view returns(bool){
        return reportVotes[_reportId].resolution;
    }

    /// @notice This function sets the wallet dispute period
    /// @param _timeFrame Time in seconds for the dispute period
    function setDisputePeriod(uint256 _timeFrame) override public onlyLosslessAdmin whenNotPaused {
        require(_timeFrame != walletDisputePeriod, "LSS: Already set to that amount");
        walletDisputePeriod = _timeFrame;
        emit NewDisputePeriod(walletDisputePeriod);
    }

    /// @notice This function sets the amount of tokens given to the erroneously reported address
    /// @param _amount Percentage to return
    function setCompensationAmount(uint256 _amount) override public onlyLosslessAdmin {
        require(_amount <= 100, "LSS: Invalid amount");
        require(_amount != compensationPercentage, "LSS: Already set to that amount");
        compensationPercentage = _amount;
        emit NewCompensationPercentage(compensationPercentage);
    }
    
    /// @notice This function returns if the majority of the commitee voted and the resolution of the votes
    /// @param _reportId Report number to be checked
    /// @return isMajorityReached result Returns True if the majority has voted and the true if the result is positive
    function _getCommitteeMajorityReachedResult(uint256 _reportId) private view returns(bool isMajorityReached, bool result) {        
        Vote storage reportVote = reportVotes[_reportId];
        uint256 committeeLength = reportVote.committeeVotes.length;
        uint256 committeeQuorum = (committeeMembersCount >> 2) + 1; 

        uint256 agreeCount;
        for(uint256 i = 0; i < committeeLength;) {
            if (reportVote.committeeVotes[i]) {
                agreeCount += 1;
            }
            unchecked{i++;}
        }

        if (agreeCount >= committeeQuorum) {
            return (true, true);
        } else if ((committeeLength - agreeCount) >= committeeQuorum) {
            return (true, false);
        } else {
            return (false, false);
        }
    }

    /// @notice This function returns the amount reported on a report    
    /// @param _reportId Report id to check
    function getAmountReported(uint256 _reportId) override external view returns(uint256) {
        return reportVotes[_reportId].amountReported;
    }

    /// @notice This function adds committee members    
    /// @param _members Array of members to be added
    function addCommitteeMembers(address[] memory _members) override public onlyLosslessAdmin whenNotPaused {
        committeeMembersCount += _members.length;

        for(uint256 i = 0; i < _members.length;) {
            address newMember = _members[i];
            require(!isCommitteeMember(newMember), "LSS: duplicate members");
            _grantRole(COMMITTEE_ROLE, newMember);

            unchecked{i++;}
        }

        emit NewCommitteeMembers(_members);
    } 

    /// @notice This function removes Committee members    
    /// @param _members Array of members to be added
    function removeCommitteeMembers(address[] memory _members) override public onlyLosslessAdmin whenNotPaused {  
        require(committeeMembersCount >= _members.length, "LSS: Not enough members to remove");

        committeeMembersCount -= _members.length;

        for(uint256 i = 0; i < _members.length;) {
            address newMember = _members[i];
            require(isCommitteeMember(newMember), "LSS: An address is not member");
            _revokeRole(COMMITTEE_ROLE, newMember);
            unchecked{i++;}
        }

        emit CommitteeMembersRemoval(_members);
    }

    /// @notice This function emits a vote on a report by the Lossless Team
    /// @dev Only can be run by the Lossless Admin
    /// @param _reportId Report to cast the vote
    /// @param _vote Resolution
    function losslessVote(uint256 _reportId, bool _vote) override public onlyLosslessAdmin whenNotPaused {
        require(!isReportSolved(_reportId), "LSS: Report already solved");
        require(isReportActive(_reportId), "LSS: report is not valid");
        
        Vote storage reportVote = reportVotes[_reportId];
        
        require(!reportVote.voted[LSS_TEAM_INDEX], "LSS: LSS already voted");

        reportVote.voted[LSS_TEAM_INDEX] = true;
        reportVote.votes[LSS_TEAM_INDEX] = _vote;

        if (_vote) {
            emit LosslessTeamPositiveVote(_reportId);
        } else {
            emit LosslessTeamNegativeVote(_reportId);
        }
    }

    /// @notice This function emits a vote on a report by the Token Owners
    /// @dev Only can be run by the Token admin
    /// @param _reportId Report to cast the vote
    /// @param _vote Resolution
    function tokenOwnersVote(uint256 _reportId, bool _vote) override public whenNotPaused {
        require(!isReportSolved(_reportId), "LSS: Report already solved");
        require(isReportActive(_reportId), "LSS: report is not valid");

        (,,,,ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        require(msg.sender == reportTokens.admin(), "LSS: Must be token owner");

        Vote storage reportVote = reportVotes[_reportId];

        require(!reportVote.voted[TOKEN_OWNER_INDEX], "LSS: owners already voted");
        
        reportVote.voted[TOKEN_OWNER_INDEX] = true;
        reportVote.votes[TOKEN_OWNER_INDEX] = _vote;

        if (_vote) {
            emit TokenOwnersPositiveVote(_reportId);
        } else {
            emit TokenOwnersNegativeVote(_reportId);
        }
    }

    /// @notice This function emits a vote on a report by a Committee member
    /// @dev Only can be run by a committee member
    /// @param _reportId Report to cast the vote
    /// @param _vote Resolution
    function committeeMemberVote(uint256 _reportId, bool _vote) override public whenNotPaused {
        require(!isReportSolved(_reportId), "LSS: Report already solved");
        require(isCommitteeMember(msg.sender), "LSS: Must be a committee member");
        require(isReportActive(_reportId), "LSS: report is not valid");

        Vote storage reportVote = reportVotes[_reportId];

        require(!reportVote.committeeMemberVoted[msg.sender], "LSS: Member already voted");
        
        reportVote.committeeMemberVoted[msg.sender] = true;
        reportVote.committeeVotes.push(_vote);

        (bool isMajorityReached, bool result) = _getCommitteeMajorityReachedResult(_reportId);

        if (isMajorityReached) {
            reportVote.votes[COMMITEE_INDEX] = result;
            reportVote.voted[COMMITEE_INDEX] = true;
            emit CommitteeMajorityReach(_reportId, result);
        }

        if (_vote) {
            emit CommitteeMemberPositiveVote(_reportId, msg.sender);
        } else {
            emit CommitteeMemberNegativeVote(_reportId, msg.sender);
        }
    }

    /// @notice This function solves a report based on the voting resolution of the three pilars
    /// @dev Only can be run by the three pilars.
    /// When the report gets resolved, if it's resolved negatively, the reported address gets removed from the blacklist
    /// If the report is solved positively, the funds of the reported account get retrieved in order to be distributed among stakers and the reporter.
    /// @param _reportId Report to be resolved
    function resolveReport(uint256 _reportId) override public whenNotPaused {

        require(!isReportSolved(_reportId), "LSS: Report already solved");


        (,,,uint256 reportTimestamps,,,) = losslessReporting.getReportInfo(_reportId);
        
        if (reportTimestamps + losslessReporting.reportLifetime() > block.timestamp) {
            _resolveActive(_reportId);
        } else {
            _resolveExpired(_reportId);
        }
        
        reportVotes[_reportId].resolved = true;
        delete reportedAddresses;

        emit ReportResolve(_reportId, reportVotes[_reportId].resolution);
    }

    /// @notice This function has the logic to solve a report that it's still active
    /// @param _reportId Report to be resolved
    function _resolveActive(uint256 _reportId) private {
                
        (,address reportedAddress, address secondReportedAddress,, ILERC20 token, bool secondReports,) = losslessReporting.getReportInfo(_reportId);

        Vote storage reportVote = reportVotes[_reportId];

        uint256 agreeCount = 0;
        uint256 voteCount = 0;

        if (getIsVoted(_reportId, LSS_TEAM_INDEX)){voteCount += 1;
        if (getVote(_reportId, LSS_TEAM_INDEX)){ agreeCount += 1;}}
        if (getIsVoted(_reportId, TOKEN_OWNER_INDEX)){voteCount += 1;
        if (getVote(_reportId, TOKEN_OWNER_INDEX)){ agreeCount += 1;}}

        (bool committeeResoluted, bool committeeResolution) = _getCommitteeMajorityReachedResult(_reportId);
        if (committeeResoluted) {voteCount += 1;
        if (committeeResolution) {agreeCount += 1;}}

        require(voteCount >= 2, "LSS: Not enough votes");
        require(!(voteCount == 2 && agreeCount == 1), "LSS: Need another vote to untie");

        reportedAddresses.push(reportedAddress);

        if (secondReports) {
            reportedAddresses.push(secondReportedAddress);
        }

        if (agreeCount > (voteCount - agreeCount)){
            reportVote.resolution = true;
            for(uint256 i; i < reportedAddresses.length;) {
                reportVote.amountReported += token.balanceOf(reportedAddresses[i]);
                unchecked{i++;}
            }
            proposedWalletOnReport[_reportId].retrievalAmount = losslessController.retrieveBlacklistedFunds(reportedAddresses, token, _reportId);
            losslessController.deactivateEmergency(token);
        }else{
            reportVote.resolution = false;
            _compensateAddresses(reportedAddresses);
        }
    } 

    /// @notice This function has the logic to solve a report that it's expired
    /// @param _reportId Report to be resolved
    function _resolveExpired(uint256 _reportId) private {

        (,address reportedAddress, address secondReportedAddress,,,bool secondReports,) = losslessReporting.getReportInfo(_reportId);

        reportedAddresses.push(reportedAddress);

        if (secondReports) {
            reportedAddresses.push(secondReportedAddress);
        }

        reportVotes[_reportId].resolution = false;
        _compensateAddresses(reportedAddresses);
    }

    /// @notice This compensates the addresses wrongly reported
    /// @dev The array of addresses will contain the main reported address and the second reported address
    /// @param _addresses Array of addresses to be compensated
    function _compensateAddresses(address[] memory _addresses) private {
        uint256 reportingAmount = losslessReporting.reportingAmount();
        uint256 compensationAmount = (reportingAmount * compensationPercentage) / HUNDRED;

        
        for(uint256 i = 0; i < _addresses.length;) {
            address singleAddress = _addresses[i];
            Compensation storage addressCompensation = compensation[singleAddress]; 
            losslessController.resolvedNegatively(singleAddress);      
            addressCompensation.amount += compensationAmount;
            addressCompensation.payed = false;
            unchecked{i++;}
        }
    }

    /// @notice This method retuns if a report is still active
    /// @param _reportId report Id to verify
    function isReportActive(uint256 _reportId) public view returns(bool) {
        (,,,uint256 reportTimestamps,,,) = losslessReporting.getReportInfo(_reportId);
        return reportTimestamps != 0 && reportTimestamps + losslessReporting.reportLifetime() > block.timestamp;
    }

    // REFUND PROCESS

    /// @notice This function proposes a wallet where the recovered funds will be returned
    /// @dev Only can be run by lossless team or token owners.
    /// @param _reportId Report to propose the wallet
    /// @param _wallet proposed address
    function proposeWallet(uint256 _reportId, address _wallet) override public whenNotPaused {
        (,,,uint256 reportTimestamps, ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        require(msg.sender == losslessController.admin() || 
                msg.sender == reportTokens.admin(),
                "LSS: Role cannot propose");
        require(reportTimestamps != 0, "LSS: Report does not exist");
        require(reportResolution(_reportId), "LSS: Report solved negatively");
        require(_wallet != address(0), "LSS: Wallet cannot ber zero adr");

        ProposedWallet storage proposedWallet = proposedWalletOnReport[_reportId];

        require(proposedWallet.wallet == address(0), "LSS: Wallet already proposed");

        proposedWallet.wallet = _wallet;
        proposedWallet.timestamp = block.timestamp;
        proposedWallet.losslessVote = true;
        proposedWallet.tokenOwnersVote = true;
        proposedWallet.walletAccepted = true;

        emit WalletProposal(_reportId, _wallet);
    }

    /// @notice This function is used to reject the wallet proposal
    /// @dev Only can be run by the three pilars.
    /// @param _reportId Report to propose the wallet
    function rejectWallet(uint256 _reportId) override public whenNotPaused {
        (,,,uint256 reportTimestamps,ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        ProposedWallet storage proposedWallet = proposedWalletOnReport[_reportId];

        require(block.timestamp <= (proposedWallet.timestamp + walletDisputePeriod), "LSS: Dispute period closed");
        require(reportTimestamps != 0, "LSS: Report does not exist");

        if (hasRole(COMMITTEE_ROLE, msg.sender)) {
            require(!proposedWallet.memberVotesOnProposal[proposedWallet.proposal].memberVoted[msg.sender], "LSS: Already Voted");
            proposedWallet.committeeDisagree += 1;
            proposedWallet.memberVotesOnProposal[proposedWallet.proposal].memberVoted[msg.sender] = true;
        } else if (msg.sender == losslessController.admin()) {
            require(!proposedWallet.losslessVoted, "LSS: Already Voted");
            proposedWallet.losslessVote = false;
            proposedWallet.losslessVoted = true;
        } else if (msg.sender == reportTokens.admin()) {
            require(!proposedWallet.tokenOwnersVoted, "LSS: Already Voted");
            proposedWallet.tokenOwnersVote = false;
            proposedWallet.tokenOwnersVoted = true;
        } else revert ("LSS: Role cannot reject.");

        if (!_determineProposedWallet(_reportId)) {
            emit WalletRejection(_reportId);
        }
    }

    /// @notice This function retrieves the fund to the accepted proposed wallet
    /// @param _reportId Report to propose the wallet
    function retrieveFunds(uint256 _reportId) override public whenNotPaused {
        (,,,uint256 reportTimestamps, ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        ProposedWallet storage proposedWallet = proposedWalletOnReport[_reportId];

        require(block.timestamp >= (proposedWallet.timestamp + walletDisputePeriod), "LSS: Dispute period not closed");
        require(reportTimestamps != 0, "LSS: Report does not exist");
        require(!proposedWallet.status, "LSS: Funds already claimed");
        require(proposedWallet.walletAccepted, "LSS: Wallet rejected");
        require(proposedWallet.wallet == msg.sender, "LSS: Only proposed adr can claim");

        proposedWallet.status = true;

        require(reportTokens.transfer(msg.sender, proposedWallet.retrievalAmount), 
        "LSS: Funds retrieve failed");

        emit FundsRetrieval(_reportId, proposedWallet.retrievalAmount);
    }

    /// @notice This function determins if the refund wallet was accepted
    /// @param _reportId Report to propose the wallet
    function _determineProposedWallet(uint256 _reportId) private returns(bool){
        
        ProposedWallet storage proposedWallet = proposedWalletOnReport[_reportId];
        uint256 agreementCount;
        
        if (proposedWallet.committeeDisagree < (committeeMembersCount >> 2)+1 ){
            agreementCount += 1;
        }

        if (proposedWallet.losslessVote) {
            agreementCount += 1;
        }

        if (proposedWallet.tokenOwnersVote) {
            agreementCount += 1;
        }
        
        if (agreementCount >= 2) {
            return true;
        }

        proposedWallet.wallet = address(0);
        proposedWallet.timestamp = block.timestamp;
        proposedWallet.status = false;
        proposedWallet.losslessVote = true;
        proposedWallet.losslessVoted = false;
        proposedWallet.tokenOwnersVote = true;
        proposedWallet.tokenOwnersVoted = false;
        proposedWallet.walletAccepted = false;
        proposedWallet.committeeDisagree = 0;
        proposedWallet.proposal += 1;

        return false;
    }

    /// @notice This lets an erroneously reported account to retrieve compensation
    function retrieveCompensation() override public whenNotPaused {
        require(!compensation[msg.sender].payed, "LSS: Already retrieved");
        require(compensation[msg.sender].amount != 0, "LSS: No retribution assigned");
        
        compensation[msg.sender].payed = true;

        losslessReporting.retrieveCompensation(msg.sender, compensation[msg.sender].amount);

        emit CompensationRetrieval(msg.sender, compensation[msg.sender].amount);

        compensation[msg.sender].amount = 0;

    }

    ///@notice This function verifies is an address belongs to a contract
    ///@param _addr address to verify
    function isContract(address _addr) private view returns (bool){
         uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size != 0);
    }

    ///@notice This function is for committee members to claim their rewards
    ///@param _reportId report ID to claim reward from
    function claimCommitteeReward(uint256 _reportId) override public whenNotPaused {
        require(reportResolution(_reportId), "LSS: Report solved negatively");

        Vote storage reportVote = reportVotes[_reportId];

        require(reportVote.committeeMemberVoted[msg.sender], "LSS: Did not vote on report");
        require(!reportVote.committeeMemberClaimed[msg.sender], "LSS: Already claimed");

        (,,,,ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        uint256 numberOfMembersVote = reportVote.committeeVotes.length;
        uint256 committeeReward = losslessReporting.committeeReward();

        uint256 compensationPerMember = (reportVote.amountReported * committeeReward /  HUNDRED) / numberOfMembersVote;

        reportVote.committeeMemberClaimed[msg.sender] = true;

        require(reportTokens.transfer(msg.sender, compensationPerMember), "LSS: Reward transfer failed");

        emit CommitteeMemberClaim(_reportId, msg.sender, compensationPerMember);
    }

    
    /// @notice This function is for the Lossless to claim the rewards
    /// @param _reportId report worked on
    function losslessClaim(uint256 _reportId) override public whenNotPaused onlyLosslessAdmin {
        require(reportResolution(_reportId), "LSS: Report solved negatively");   

        Vote storage reportVote = reportVotes[_reportId];

        require(!reportVote.losslessPayed, "LSS: Already claimed");

        (,,,,ILERC20 reportTokens,,) = losslessReporting.getReportInfo(_reportId);

        uint256 amountToClaim = reportVote.amountReported * losslessReporting.losslessReward() / HUNDRED;
        reportVote.losslessPayed = true;
        require(reportTokens.transfer(losslessController.admin(), amountToClaim), 
        "LSS: Reward transfer failed");

        emit LosslessClaim(reportTokens, _reportId, amountToClaim);
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
    uint256[49] private __gap;
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
    event NewCompensationPercentage(uint256 indexed compensationPercentage);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

pragma solidity ^0.8.0;

interface ProtectionStrategy {
    function isTransferAllowed(address token, address sender, address recipient, uint256 amount) external;
}