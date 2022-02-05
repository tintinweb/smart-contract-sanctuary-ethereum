/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

// SPDX-License-Identifier: MIT


pragma solidity >= 0.8.3;

//Use 0.8.3

contract Token {
    function changeArtistAddress(address newAddress) external {}
    function balanceOf(address account) external view returns (uint256){}
    function transfer(address recipient, uint256 amount) external returns (bool){}
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool){}
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract ApolloDAO is Context {

    Token public immutable apolloToken;

    event newDaoNomination(address indexed newDAO, address indexed nominator);
    event cycleWinner(address indexed winner, uint256 reward);
    event creatorNomination(address indexed nominee, uint256 currentCycle);

    struct newDAONomination {
    uint256 timeOfNomination;
    address nominator;
    uint256 votesFor;
    uint256 votesAgainst;
    bool votingClosed;
    }

    struct DAOVotes {
        uint256 voteCount;
        bool votedFor;
    }

    mapping (address => newDAONomination) private _newDAONominations;
    mapping (address => mapping (address => DAOVotes)) private _lockedVotes;

    uint256 public constant daoVotingDuration = 259200;
    uint256 public constant minimumDAOBalance = 14000000000 * 10**9;
    uint256 public totalLockedVotes;
    uint256 public activeDaoNominations;

    address public approvedNewDAO = address(0);
    uint256 public constant daoUpdateDelay = 1209600;
    uint256 public daoApprovedTime;

    uint256 public constant votingCyleLength = 604800;
    uint256 public currentVotingCycleEnd;

    struct Vote {
        uint256 voteBalance;
        uint256 voteCycle;
        bool withdrawn;
    }

    struct LeadCandidate {
        address candidate;
        uint256 voteCount;
        uint256 voteCycle;
    }


    mapping (address => Vote[]) private _votesCast;
    mapping (address => mapping (uint256 => uint256)) private _votesReceived;
    mapping(address => uint256) private _nominations;
    mapping (address => uint256) private _winnings;

    LeadCandidate public leadVoteRecipient;
    uint256 public constant minBalancePercentage = 1;
    uint256 public constant voteAwardMultiplier = 15000000 * 10**9;

    address public immutable daoAdministrator;
    uint256 public constant daoAdminTax = 15;
    uint256 public constant rebatePercentage = 5;
    uint256 public constant maxRebate = 7100000 * 10**9;

    mapping (address => mapping (address => uint256)) private _voteAllowances;
    event voteServiceUsed(uint256 votesAttempted, uint256 successfulVotes);
    event failedVote(address indexed voter, address candidate);


    constructor (address tokenAddress, address administrator) {
        apolloToken = Token(tokenAddress);
        daoAdministrator = administrator;
    }

    function nominate() external {
        require(block.timestamp < currentVotingCycleEnd, "A new cycle has not started yet");
        require(apolloToken.balanceOf(_msgSender()) > 0, "Candidate does not hold any Apollo");
        require(_nominations[_msgSender()] != currentVotingCycleEnd, "Candidate has already been nominated this cycle");
        _nominations[_msgSender()] = currentVotingCycleEnd;
    }

    function vote(address candidate) external {
        require(block.timestamp < currentVotingCycleEnd, "A new cycle has not started yet");
        require(candidate != _msgSender() , "You cannot vote for yourself");
        require(_nominations[candidate] == currentVotingCycleEnd, "Candidate has not nominated themselves");
        if (_votesCast[_msgSender()].length > 0) {
            require(_votesCast[_msgSender()][_votesCast[_msgSender()].length - 1].voteCycle != currentVotingCycleEnd, "User has already voted");

        }
        uint256 voterBalance = apolloToken.balanceOf(_msgSender());
        require(voterBalance > 0, "Voter does not hold any apollo");

        _votesCast[_msgSender()].push(Vote(voterBalance,currentVotingCycleEnd, false));

        _votesReceived[candidate][currentVotingCycleEnd] += 1;

        if((_votesReceived[candidate][currentVotingCycleEnd] > leadVoteRecipient.voteCount) || (leadVoteRecipient.voteCycle != currentVotingCycleEnd)){
            leadVoteRecipient.candidate = candidate;
            leadVoteRecipient.voteCount = _votesReceived[candidate][currentVotingCycleEnd];
            leadVoteRecipient.voteCycle = currentVotingCycleEnd;
        }
    }

    function approveVotes(address voteCaster, uint256 amount) public returns (bool) {
        require(_msgSender() != address(0), "approve from the zero address");
        require(voteCaster != address(0), "approve to the zero address");
        _voteAllowances[_msgSender()][voteCaster] = amount;
        return true;
    }

    function voteService(address[] calldata voters, address[] calldata candidates) public returns (uint256) {
        require(block.timestamp < currentVotingCycleEnd, "A new cycle has not started yet");
        require(voters.length == candidates.length, "There must be as many voters as candidates");
        uint256 successfulVotes;
        for(uint i = 0; i < voters.length; i++) {
            if(_voterIsServiceElgibile(voters[i]) && _candidateIsEligible(voters[i], candidates[i])){
                _voteAllowances[voters[i]][_msgSender()] -= 1;

                _votesCast[voters[i]].push(Vote(0,currentVotingCycleEnd, false));

                _votesReceived[candidates[i]][currentVotingCycleEnd] += 1;

                if((_votesReceived[candidates[i]][currentVotingCycleEnd] > leadVoteRecipient.voteCount) || (leadVoteRecipient.voteCycle != currentVotingCycleEnd)){
                    leadVoteRecipient.candidate = candidates[i];
                    leadVoteRecipient.voteCount = _votesReceived[candidates[i]][currentVotingCycleEnd];
                    leadVoteRecipient.voteCycle = currentVotingCycleEnd;
                }

                successfulVotes += 1;
            } else {
                emit failedVote(voters[i], candidates[i]);
            }
        }
        emit voteServiceUsed(voters.length, successfulVotes);
        return successfulVotes;
    }

    function completeCycle() public {
        require(block.timestamp > currentVotingCycleEnd, "Voting Cycle has not ended");
        if(leadVoteRecipient.voteCycle == currentVotingCycleEnd) {
            uint256 minContractBalance = apolloToken.balanceOf(address(this)) * minBalancePercentage / 100;
            uint256 votesToAward = leadVoteRecipient.voteCount * voteAwardMultiplier;
            uint256 daoAdminTake;

            if(minContractBalance < votesToAward){
                daoAdminTake = minContractBalance * daoAdminTax / 100;
                _winnings[leadVoteRecipient.candidate] += (minContractBalance - daoAdminTake);
                emit cycleWinner(leadVoteRecipient.candidate, minContractBalance - daoAdminTake);

            } else {
                daoAdminTake = votesToAward * daoAdminTax / 100;
                _winnings[leadVoteRecipient.candidate] += (votesToAward - daoAdminTake);
                emit cycleWinner(leadVoteRecipient.candidate, votesToAward - daoAdminTake);
            }

            _winnings[daoAdministrator] += daoAdminTake;
        }

        if(approvedNewDAO == address(0)){
            currentVotingCycleEnd = block.timestamp + votingCyleLength;
        } else {
            leadVoteRecipient.voteCycle = 1;
            currentVotingCycleEnd = 1;
        }
    }

    function withdrawWinnings() public {
        uint256 winningsToWithdraw = _winnings[_msgSender()];
        require(winningsToWithdraw > 0, "User has no winnings");
        apolloToken.transfer(_msgSender(), winningsToWithdraw);
        _winnings[_msgSender()] -= winningsToWithdraw;
    }




    function voteForDAONomination (uint256 voteAmount, address newDAO, bool voteFor) external {
        require(_newDAONominations[newDAO].timeOfNomination > 0 , "There is no DAO Nomination for this address");
        require(_lockedVotes[_msgSender()][newDAO].voteCount == 0, "User already voted on this nomination");
        require(approvedNewDAO == address(0), "There is already an approved new DAO");
        apolloToken.transferFrom(_msgSender(), address(this), voteAmount);
        totalLockedVotes += voteAmount;
        _lockedVotes[_msgSender()][newDAO].voteCount += voteAmount;
        _lockedVotes[_msgSender()][newDAO].votedFor = voteFor;
        if(voteFor){
            _newDAONominations[newDAO].votesFor += voteAmount;
        } else {
            _newDAONominations[newDAO].votesAgainst += voteAmount;
        }
    }

    function withdrawNewDAOVotes (address newDAO) external {
        uint256 currentVoteCount = _lockedVotes[_msgSender()][newDAO].voteCount;
        require(currentVoteCount > 0 , "You have not cast votes for this nomination");
        require((totalLockedVotes - currentVoteCount) >= 0, "Withdrawing would take DAO balance below expected rewards amount");
        apolloToken.transfer(_msgSender(), currentVoteCount);

        totalLockedVotes -= currentVoteCount;
        _lockedVotes[_msgSender()][newDAO].voteCount -= currentVoteCount;

        if(_lockedVotes[_msgSender()][newDAO].votedFor){
            _newDAONominations[newDAO].votesFor -= currentVoteCount;
        } else {
            _newDAONominations[newDAO].votesAgainst -= currentVoteCount;
        }

    }

    function nominateNewDAO (address newDAO) external {
        require(apolloToken.balanceOf(_msgSender()) >= minimumDAOBalance , "Nominator does not own enough APOOLLO");
        _newDAONominations[newDAO] = newDAONomination(
            {
                timeOfNomination: block.timestamp,
                nominator: _msgSender(),
                votesFor: 0,
                votesAgainst: 0,
                votingClosed: false
            }
        );
        activeDaoNominations += 1;
        emit newDaoNomination(newDAO, _msgSender());
    }

    function closeNewDAOVoting (address newDAO) external {
        require(block.timestamp > (_newDAONominations[newDAO].timeOfNomination + daoVotingDuration), "We have not passed the minimum voting duration");
        require(!_newDAONominations[newDAO].votingClosed, "Voting has already closed for this nomination");
        require(approvedNewDAO == address(0), "There is already an approved new DAO");

        if(_newDAONominations[newDAO].votesFor > _newDAONominations[newDAO].votesAgainst){
            approvedNewDAO = newDAO;
            daoApprovedTime = block.timestamp;
        }
        activeDaoNominations -= 1;
        _newDAONominations[newDAO].votingClosed = true;
    }

    function updateDAOAddress() external {
        require(approvedNewDAO != address(0),"There is not an approved new DAO");
        require(block.timestamp > (daoApprovedTime + daoUpdateDelay), "We have not finished the delay for an approved DAO");
        apolloToken.changeArtistAddress(approvedNewDAO);
    }

    function daoNominationTime(address dao) external view returns (uint256){
        return _newDAONominations[dao].timeOfNomination;
    }

    function daoNominationNominator(address dao) external view returns (address){
        return _newDAONominations[dao].nominator;
    }

    function daoNominationVotesFor(address dao) external view returns (uint256){
        return _newDAONominations[dao].votesFor;
    }

    function daoNominationVotesAgainst(address dao) external view returns (uint256){
        return _newDAONominations[dao].votesAgainst;
    }

    function daoNominationVotingClosed(address dao) external view returns (bool){
        return _newDAONominations[dao].votingClosed;
    }

    function checkAddressVoteAmount(address voter, address dao) external view returns (uint256){
        return _lockedVotes[voter][dao].voteCount;
    }

    function checkDAOAddressVote(address voter, address dao) external view returns (bool){
        return _lockedVotes[voter][dao].votedFor;
    }

    function hasVotedForCreator(address voter) external view returns (bool) {
        return (_votesCast[voter][_votesCast[voter].length - 1].voteCycle == currentVotingCycleEnd);
    }

    function isNominated(address nominee) external view returns (bool) {
        if(_nominations[nominee] == currentVotingCycleEnd){
            return true;
        } else {
            return false;
        }
    }

    function checkCreatorVotesReceived(address candidate, uint256 cycle) external view returns (uint256) {
        return _votesReceived[candidate][cycle];
    }

    function checkWinningsToWithdraw(address candidate) external view returns (uint256) {
        return _winnings[candidate];
    }

    function addressVoteBalance(address voter, uint256 cycle) external view returns (uint256) {
        uint256 numberOfVotes = _votesCast[voter].length;
        for(uint256 i = 0; i < numberOfVotes; i++){
            if(_votesCast[voter][i].voteCycle == cycle){
                return _votesCast[voter][i].voteBalance;
            }
        }
        return 0;
    }

    function currentRebateAmount(address voter) external view returns (uint256) {
        uint256 numberOfVotes = _votesCast[voter].length;
        uint256 rebateAmount;
        for(uint256 i = 0; i < numberOfVotes; i++){
            if( (!_votesCast[voter][i].withdrawn) && (_votesCast[voter][i].voteCycle != currentVotingCycleEnd)){
                uint256 voteRebate = (_votesCast[voter][i].voteBalance * rebatePercentage / 100);
                if(voteRebate < maxRebate) {
                    rebateAmount += voteRebate;
                } else {
                    rebateAmount += maxRebate;
                }
            }
        }
        return rebateAmount;
    }

    function wthdrawRebate() external returns (uint256) {
        uint256 numberOfVotes = _votesCast[_msgSender()].length;
        uint256 rebateAmount;
        for(uint256 i = 0; i < numberOfVotes; i++){
            if( (!_votesCast[_msgSender()][i].withdrawn) && (_votesCast[_msgSender()][i].voteCycle != currentVotingCycleEnd)){
                uint256 voteRebate = (_votesCast[_msgSender()][i].voteBalance * rebatePercentage / 100);
                if(voteRebate < maxRebate) {
                    rebateAmount += voteRebate;
                } else {
                    rebateAmount += maxRebate;
                }
                _votesCast[_msgSender()][i].withdrawn = true;
            }
        }
        require(rebateAmount > 0 , "User has nothing to refund");
        apolloToken.transfer(_msgSender(), rebateAmount);

        return rebateAmount;
    }

    function allowance(address owner, address voteCaster) public view returns (uint256) {
        return _voteAllowances[owner][voteCaster];
    }

    function _voterIsServiceElgibile(address voter) private view returns (bool) {
        if (_votesCast[_msgSender()].length > 0) {
            if(_votesCast[_msgSender()][_votesCast[_msgSender()].length - 1].voteCycle == currentVotingCycleEnd) {
                return false;
            }
        }
        if(apolloToken.balanceOf(voter) == 0) {
            return false;
        }
        if(_voteAllowances[voter][_msgSender()] < 1) {
            return false;
        }

        return true;
    }

    function _candidateIsEligible(address voter, address candidate) private view returns (bool) {
        if(voter == candidate) {
            return false;
        }
        if(_nominations[candidate] != currentVotingCycleEnd) {
            return false;
        }
        
        return true;
    }


}