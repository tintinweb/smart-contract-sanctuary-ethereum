/**
 *Submitted for verification at Etherscan.io on 2022-04-21
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

abstract contract Auth {
    address internal owner;
    constructor(address _owner) { owner = _owner; }
    modifier onlyOwner() { require(msg.sender == owner, "Only contract owner can call this function"); _; }
    function transferOwnership(address payable _newOwner) external onlyOwner { owner = _newOwner; emit OwnershipTransferred(_newOwner); }
    event OwnershipTransferred(address owner);
}

interface IERC20 {
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface ICKStaking {
    function getStakingInfo(address staker) external view returns (uint256 started, uint256 lastChanged, uint256 stakedTokens, uint256 rewardsAccrued, uint16 activeAPR, bool rewardsPausedByUnstake, uint256 lockedUntil );
}

contract CKD01 is Auth {
    uint256 private _settingsWindowDuration = 86400; //TODO: settings get unlocked only for 24 hours (86400), then will be locked again
    uint256 private _settingsUnlockTimer = 180; //TODO: settings unlock wait time - 30 sec in local, 3 minutes (180) in testnet, 7 days (604800) in mainnet

    uint256 private _migrationMinUnlockWait = 180; //TODO: 30s in local test, 3 mins (180) in testnet, 14 days (14 * 86400) in Mainnet
    uint256 private _migrationTimerStarted;
    uint256 private _migrationUnlocksOn;

    struct DaoSettings {
        uint256 settingsUnlockWindowStart;
        uint256 settingsUnlockWindowEnd;

        address caToken;
        address caStaking; // staking contract which determines if a wallet can vote
        
        uint256 minStakedTimeToVote;
        uint256 minStakedTokensToVote;

        uint16 minVotingDuration; //how many days will a proposal be open for vote submissions
        uint16 minTimeToProcess; //how many hours after vote is passed till proposal can be actioned
    }

    DaoSettings public daoSettings;

    mapping(address => bool) private _authorizedProposer;
    mapping(address => uint256) private _lastProposalAddedTime;
    uint256 private _proposalIndex; //counts how many proposals have been submitted

    uint256 private _countAcceptedNoPay;
    uint256 private _countAcceptedWithPay;
    uint256 private _countRejected;
    uint256 private _countPending;
    uint256 private _countCancelled;

    enum Vote { NONE, YES, NO }

    enum PropState {
        NONE, 
        CREATED,
        VOTING_ACTIVE, 
        REJECTED,  
        ACCEPTED, 
        ACCEPTED_AND_PAID,
        CANCELLED
    }

    enum TransferType { NONE, ETH, ERC20 }

    struct PropData {
        uint256 id; 
        address author;   
        uint256 votingStart; 
        uint256 votingDuration; 

        string description;
        
        TransferType transferType;  
        address transferTokenContractAddress; 
        address transferRecipient;
        uint256 transferAmount; 
        
        uint256 votesYES; 
        uint256 votesNO; 

        PropState state;
    }

    mapping(uint256 => mapping(address => Vote)) private _voteValue; // i.e. _voteValue[proposalId][wallet] == Vote.YES // how did a wallet vote on a specific proposal
    mapping(uint256 => mapping(address => uint256)) private _voteWeight; // i.e. _voteWeight[proposalId][wallet] == 123456 //amount of staked tokens at the time of submitting the vote
    PropData[] public proposal;

    event SettingsUnlockTimerStarted(uint256 requestedOn, uint256 unlocksOn);
    event SettingsLocked(uint256 lockedOn);
    event SettingsUpdated(address caToken, address caStaking, uint256 minStakingTimeToVote, uint256 minStakedTokensVote, uint16 minVotingDuration, uint16 minTimeToProcess);
    event AuthorizedProposerUpdated(address wallet, bool isAuthorized);
    event ProposalAdded(uint256 proposalId, uint16 voteDuration, TransferType transferType, address transferRecipient, address transferTokenCA, uint256 transferAmountNonDecimal);
    event ProposalVotingStarted(uint256 proposalId);
    event ProposalCancelled(uint256 proposalId);
    event ProposalFinalized(uint256 proposalId, PropState result);
    event VoteSubmitted(address voteBy, uint256 proposalId, Vote vote, uint256 _voteWeight, bool updatingPreviousVote);
    event MigrationLocked(uint256 lockedOn);
    event MigrationUnlockTimerStarted(uint256 startedOn, uint256 duration, uint256 unlocksOn);
    event MigrationTransferredBalanceETH(address recipient, uint256 amount);
    event MigrationTransferredTokenBalance(address ercTokenCA, address recipient, uint256 amount);

    modifier onlyAuthorizedProposer { 
        require( _authorizedProposer[msg.sender], "Not authorized to manage proposals"); _; 
    }

    modifier propIdCheck(uint256 proposalId) { 
         require(proposalId <= _proposalIndex, "Proposal ID does not exist");
         require(proposal[proposalId].id == proposalId, "Proposal ID mismatch"); 
         _;
    }

    //////////////////////////////////////////////////////////////// CONSTRUCTOR ////////////////////////////////////////////////////////////////
    constructor() Auth(msg.sender) {    
        daoSettings.settingsUnlockWindowEnd = block.timestamp + (7*86400); //after deploying the contract, initial settings are unlocked for 7 days to be configured and locked post launch
        daoSettings.minVotingDuration = 60; //should be probably at least an hour
        daoSettings.minTimeToProcess = 60; //should be at least 5 or 10 minutes

        _authorizedProposer[owner] = true; 

        //initialize DAO proposals with index 0 as DAO creation
        PropData memory initProp;
        _proposalIndex = 0;
        initProp.id = _proposalIndex;
        initProp.description = "Create DAO";
        initProp.votingStart = block.timestamp;
        initProp.votesYES = 1;
        initProp.state = PropState.ACCEPTED;
        proposal.push(initProp);
    }

    receive() external payable {} //allows this DAO contract to receive ETH in order to act as treasury
    function getOwner() external view returns (address) { return owner; }

    //////////////////////////////// SETTINGS MANAGEMENT ////////////////////////////////
    function settingsUnlockStartTimer() external onlyOwner {
        //settings can be changed after being unlocked, unlock is on a timer - 5 minutes in testnet, 7 days in mainnet
        if (daoSettings.settingsUnlockWindowStart > block.timestamp && daoSettings.settingsUnlockWindowEnd > daoSettings.settingsUnlockWindowStart) { revert("Unlock timer already running"); }
        else if (daoSettings.settingsUnlockWindowStart <= block.timestamp && daoSettings.settingsUnlockWindowEnd > block.timestamp) { revert("Settings already unlocked"); }
        else {
            daoSettings.settingsUnlockWindowStart = block.timestamp + _settingsUnlockTimer;
            daoSettings.settingsUnlockWindowEnd = block.timestamp + _settingsUnlockTimer + _settingsWindowDuration;
        }
        emit SettingsUnlockTimerStarted(block.timestamp, daoSettings.settingsUnlockWindowStart);
    }

    function settingsLockNow() external onlyOwner {
        //if settings are unlocked, they can be re-locked at any time
        require(daoSettings.settingsUnlockWindowEnd > block.timestamp, "Settings already locked");
        daoSettings.settingsUnlockWindowStart = block.timestamp - 2;
        daoSettings.settingsUnlockWindowEnd = block.timestamp - 1;
        emit SettingsLocked(block.timestamp);
    }

    function settingsChange(address caToken, address caStaking, uint256 minStakedTimeToVote, uint256 minStakedTokensVote, uint16 minVotingDuration, uint16 minTimeToProcess) external onlyOwner {
        require(daoSettings.settingsUnlockWindowStart <= block.timestamp && daoSettings.settingsUnlockWindowEnd > block.timestamp, "Settings locked");
        
        require(caToken != address(0) && caStaking != address(0), "Zero address not allowed");
        daoSettings.caToken = caToken;
        daoSettings.caStaking = caStaking;

        daoSettings.minStakedTimeToVote = minStakedTimeToVote;
        daoSettings.minStakedTokensToVote = minStakedTokensVote;

        require(minVotingDuration >= 300, "Voting can't be shorter than 5 minutes"); //TODO - check and change to maybe 1 day ?
        daoSettings.minVotingDuration = minVotingDuration; //how much time will a proposal be open for vote submissions
        require(minTimeToProcess >= 120, "Can't process vote less than 2 minutes after voting is over"); //TODO - check and change to maybe 1 hour ?
        daoSettings.minTimeToProcess = minTimeToProcess; //how much time after vote is passed till proposal can be actioned
        
        emit SettingsUpdated(caToken, caStaking, minStakedTimeToVote, minStakedTokensVote, minVotingDuration, minTimeToProcess);
    }


    function setAuthorizedProposer(address wallet, bool toggle) external onlyOwner {
        require(_authorizedProposer[wallet] != toggle, "required setting already in place");
        _authorizedProposer[wallet] = toggle;
        emit AuthorizedProposerUpdated(wallet, toggle);
    }

    //////////////////////////////// DAO section ////////////////////////////////
    function proposalAdd(uint16 voteDuration, string memory description, TransferType transferType, address transferRecipient, address transferTokenCA, uint256 transferAmountNonDecimal, bool startVoteImmediately) external onlyAuthorizedProposer returns (uint256 proposalId) {
        require(block.timestamp >= _lastProposalAddedTime[msg.sender] + 10, "New proposal limit - 1 per 10 seconds"); //TODO change to 5 minutes (300)
        _proposalIndex++; 
        
        PropData memory newProp;
        newProp.id = _proposalIndex;
        newProp.author = msg.sender;
        newProp.votingStart = 0;
        require(voteDuration >= daoSettings.minVotingDuration, "Voting duration too short");
        newProp.votingDuration = voteDuration;
        newProp.description = description;
        newProp.transferType = transferType;
        if (transferType != TransferType.NONE ) {
            require(transferAmountNonDecimal > 0, "cannot propose sending zero value");
            newProp.transferAmount = transferAmountNonDecimal;
            if ( transferType == TransferType.ETH ) {
                //transfering native ETH
                require(transferRecipient != address(0), "cannot send ETH to zero wallet");
                newProp.transferRecipient = transferRecipient;
            } else if ( transferType == TransferType.ERC20 ) {
                //transfering ERC20 tokens, zero wallet is allowed because proposal can be to burn tokens
                newProp.transferRecipient = transferRecipient;
                require(transferTokenCA != address(0), "Zero wallet is not an ERC token address");
                newProp.transferTokenContractAddress = transferTokenCA;
            }
        }
        
        newProp.votesYES = 0;
        newProp.votesNO = 0;
        newProp.state = PropState.CREATED;

        proposal.push(newProp);
        _countPending++;

        if (startVoteImmediately) { _proposalStartVoting(_proposalIndex); }

        _lastProposalAddedTime[msg.sender] = block.timestamp;

        emit ProposalAdded(_proposalIndex, voteDuration, transferType, transferRecipient, transferTokenCA, transferAmountNonDecimal);
        return _proposalIndex;
    }

    function _proposalStartVoting(uint256 proposalId) internal propIdCheck(proposalId) {
        require(proposal[proposalId].votingStart == 0 && proposal[proposalId].state == PropState.CREATED, "Proposal is past being started");
        proposal[proposalId].votingStart = block.timestamp;
        proposal[proposalId].state = PropState.VOTING_ACTIVE;
        emit ProposalVotingStarted(proposalId);
    }

    function proposalStartVoting(uint256 proposalId) external onlyAuthorizedProposer {
        _proposalStartVoting(proposalId);
    }

    function proposalCancel(uint256 proposalId) external onlyAuthorizedProposer {
        require(proposal[proposalId].author == msg.sender, "Only author can cancel");

        require( proposal[proposalId].state == PropState.CREATED || proposal[proposalId].state == PropState.VOTING_ACTIVE, "Cannot cancel in this state" );

        if (proposal[proposalId].state == PropState.VOTING_ACTIVE) {
            uint256 votingEnd = proposal[proposalId].votingStart + proposal[proposalId].votingDuration;
            require( votingEnd > block.timestamp, "Voting period over, cannot cancel");
        } 
        proposal[proposalId].state = PropState.CANCELLED;
        _countPending--;
        _countCancelled++;
        emit ProposalCancelled(proposalId);
    }

    function getVoteInfo(uint256 proposalId, address wallet) external view returns (Vote vote, uint256 weight) {
        return (_voteValue[proposalId][wallet], _voteWeight[proposalId][wallet]);
    }

    function submitVote(uint256 proposalId, Vote vote) external propIdCheck(proposalId) {
        require(vote != Vote.NONE, "Must vote YES or NO (1 or 2)");
        require(proposal[proposalId].state == PropState.VOTING_ACTIVE, "Voting not active");

        require(block.timestamp >= proposal[proposalId].votingStart, "Voting period has not started yet");
        require(block.timestamp <= (proposal[proposalId].votingStart + proposal[proposalId].votingDuration), "Voting period has already ended");

        (uint256 stakingStarted, , uint256 stakedTokens, , , bool rewardsPausedByUnstake, ) = ICKStaking(daoSettings.caStaking).getStakingInfo(msg.sender);
        require( stakedTokens >= daoSettings.minStakedTokensToVote, "Staked balance too low" );
        uint256 stakedTime;
        if (stakingStarted < block.timestamp) { stakedTime = block.timestamp - stakingStarted; }
        require ( stakedTime >= daoSettings.minStakedTimeToVote, "Staking period too short");
        require ( !rewardsPausedByUnstake, "Unstaking request active");

        bool updatingPreviousVote = false;

        if (_voteValue[proposalId][msg.sender] != Vote.NONE && _voteWeight[proposalId][msg.sender] > 0) {
            // this person already voted, first remove the weight of the previous vote
            updatingPreviousVote = true;
            if (_voteValue[proposalId][msg.sender] == Vote.YES) {
                proposal[proposalId].votesYES -= _voteWeight[proposalId][msg.sender];
            } else if (_voteValue[proposalId][msg.sender] == Vote.NO) {
                proposal[proposalId].votesNO -= _voteWeight[proposalId][msg.sender];
            }
        }
        //now set the values of the vote and its weight
        _voteValue[proposalId][msg.sender] = vote;
        _voteWeight[proposalId][msg.sender] = stakedTokens;
        if (vote == Vote.YES) {
            proposal[proposalId].votesYES += stakedTokens;
        } else if (vote == Vote.NO) {
            proposal[proposalId].votesNO += stakedTokens;
        }

        emit VoteSubmitted(msg.sender, proposalId, vote, stakedTokens, updatingPreviousVote);
    }

    function proposalFinalize(uint256 proposalId) external propIdCheck(proposalId) {
        require(proposal[proposalId].state == PropState.VOTING_ACTIVE, "Proposal state not for finalization");
        uint256 votingEnd = proposal[proposalId].votingStart + proposal[proposalId].votingDuration;
        require( block.timestamp > votingEnd, "Voting is still open");

        if (proposal[proposalId].votesYES <= proposal[proposalId].votesNO) {
            //proposal REJECTED
            proposal[proposalId].state = PropState.REJECTED;
            _countRejected++;
        } else if ( proposal[proposalId].transferType == TransferType.NONE ) {
            //proposal ACCEPTED but no value transfer to be done
            proposal[proposalId].state = PropState.ACCEPTED;
            _countAcceptedNoPay++;
        } else {
            if ( proposal[proposalId].transferType == TransferType.ETH ) {
                //proposal ACCEPTED and now should send ETH transaction
                address payable recipientWallet = payable(proposal[proposalId].transferRecipient);
                recipientWallet.transfer(proposal[proposalId].transferAmount);
            } else if ( proposal[proposalId].transferType == TransferType.ERC20 ) {
                //proposal ACCEPTED and now should send ERC20 token transaction
                IERC20 ercToken = IERC20(proposal[proposalId].transferTokenContractAddress);
                address recipientWallet = proposal[proposalId].transferRecipient;
                uint256 tokenAmount = proposal[proposalId].transferAmount;
                ercToken.transfer(recipientWallet, tokenAmount);
            }
            //transfer success, not reverted, set state
            proposal[proposalId].state = PropState.ACCEPTED_AND_PAID;
            _countAcceptedWithPay++;
        }
        _countPending--;
        emit ProposalFinalized(proposalId, proposal[proposalId].state);
    }

    function getProposalStats() external view returns (uint256 acceptedWithoutPayment, uint256 acceptedWithPayment, uint256 rejected, uint256 pending, uint256 cancelled, uint256 total) {
        return (_countAcceptedNoPay, _countAcceptedWithPay, _countRejected, _countPending, _countCancelled, _proposalIndex);
    }


    function getAuthorizedStatus(address wallet) external view returns(bool canAddProposals, uint256 lastProposalAddedOn) {
        return ( _authorizedProposer[wallet], _lastProposalAddedTime[wallet] );
    }
    //////////////////////////////// Migration section ////////////////////////////////   
    function _migrationLocked() internal view returns (bool) {
        bool lockResult = true;
        if (_migrationUnlocksOn != 0 && _migrationUnlocksOn <= block.timestamp) { lockResult = false; }
        return lockResult;
    }

    function migrationStatus() public view returns (bool locked, bool unlockTimerRunning, uint256 unlockTimerStartedOn, uint256 unlocksOn, uint256 unlockTimeRemaining ) {
        bool timerRunning = false;
        uint256 unlockTimeLeft = 0; 
        if (_migrationUnlocksOn > 0 && block.timestamp < _migrationUnlocksOn) {
            timerRunning = true;
            unlockTimeLeft = _migrationUnlocksOn - block.timestamp;
        }
        return (_migrationLocked(), timerRunning, _migrationTimerStarted, _migrationUnlocksOn, unlockTimeLeft );
    }

    function migrationLockNow() external onlyOwner {
        _migrationTimerStarted = 0;
        _migrationUnlocksOn = 0;
        emit MigrationLocked(block.timestamp);
    }

    function migrationUnlockStartTimer(uint256 waitTime) external onlyOwner {
        if ( _migrationUnlocksOn > block.timestamp ) { revert("Unlock timer already running"); }
        else if ( _migrationUnlocksOn != 0 ) { revert("Migration already unlocked"); }

        require(waitTime >= _migrationMinUnlockWait, "Wait time cannot be less than 14 days");

        _migrationTimerStarted = block.timestamp;
        _migrationUnlocksOn = block.timestamp + waitTime;
        emit MigrationUnlockTimerStarted(_migrationTimerStarted, waitTime, _migrationUnlocksOn);
    }

    function migrationTransferBalanceETH(address payable recipient) external onlyOwner {
        require( !_migrationLocked(), "Migration is locked!" );
        uint256 ethBalance = address(this).balance;
        recipient.transfer(ethBalance);

        emit MigrationTransferredBalanceETH(recipient, ethBalance);
    }

    function migrationTransferBalanceERCtokens(address tokenCA, address recipient) external onlyOwner {
        require( !_migrationLocked(), "Migration is locked!" );

        IERC20 ercToken = IERC20(tokenCA);
        uint256 tokenBalance = ercToken.balanceOf(address(this));
        ercToken.transfer(recipient, tokenBalance);

        emit MigrationTransferredTokenBalance(tokenCA, recipient, tokenBalance);
    }

}