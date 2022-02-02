/**
 *Submitted for verification at Etherscan.io on 2022-02-01
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
    event cycleWinner(address winner, uint256 reward);
    event creatorNomination(address nominee, uint256 currentCycle);

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

    uint256 public constant daoVotingDuration = 14400;
    uint256 public constant minimumDAOBalance = 14000000000 * 10**9;
    uint256 public totalLockedVotes;
    uint256 public activeDaoNominations;

    address public approvedNewDAO = address(0);
    uint256 public constant daoUpdateDelay = 172800;
    uint256 public daoApprovedTime;

    uint256 public constant votingCyleLength = 600;
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
    mapping (uint256 => uint256) private _voteBalanceOfACycle;

    LeadCandidate public leadVoteRecipient;
    uint256 public constant minBalancePercentage = 1;
    uint256 public constant voteAwardMultiplier = 15000000;
    uint256 public constant minimumNominationBalance = 14000000 * 10**9;

    address public immutable daoAdministrator;
    uint256 public constant daoOwnerTax = 15;
    uint256 public constant refundPercentage = 5;
    uint256 public constant maxRefund = 7100000 * 10**9;

    constructor (address tokenAddress, address administrator) {
        apolloToken = Token(tokenAddress);
        daoAdministrator = administrator;
    }

    function nominate() external {
        require(apolloToken.balanceOf(_msgSender()) > minimumNominationBalance, "Candidate does not hold enough Apollo");
        require(_nominations[_msgSender()] != currentVotingCycleEnd, "Candidate has already been nominated this cycle");
        emit creatorNomination(_msgSender(),currentVotingCycleEnd);
        _nominations[_msgSender()] = currentVotingCycleEnd;
    }

    function vote(address candidate) external {
        require(block.timestamp < currentVotingCycleEnd, "A new cycle has not started yet");
        //require(candidate != _msgSender() , "You cannot vote for yourself");
        require(_nominations[candidate] == currentVotingCycleEnd, "Candidate has not nominated themselves");
        if (_votesCast[_msgSender()].length > 0) {
            require(_votesCast[_msgSender()][_votesCast[_msgSender()].length - 1].voteCycle != currentVotingCycleEnd, "User has already voted");

        }
        uint256 voterBalance = apolloToken.balanceOf(_msgSender());
        require(voterBalance > 0, "Voter does not hold any apollo");

        _votesCast[_msgSender()].push(Vote(voterBalance,currentVotingCycleEnd, false));

        _voteBalanceOfACycle[currentVotingCycleEnd] += voterBalance;

        _votesReceived[candidate][currentVotingCycleEnd] += 1;

        if((_votesReceived[candidate][currentVotingCycleEnd] > leadVoteRecipient.voteCount) || (leadVoteRecipient.voteCycle != currentVotingCycleEnd)){
            leadVoteRecipient.candidate = candidate;
            leadVoteRecipient.voteCount = _votesReceived[candidate][currentVotingCycleEnd];
            leadVoteRecipient.voteCycle = currentVotingCycleEnd;
        }
    }

    function completeCycle() public {
        require(block.timestamp > currentVotingCycleEnd, "Voting Cycle has not ended");
        if(leadVoteRecipient.voteCycle == currentVotingCycleEnd) {
            uint256 minContractBalance = apolloToken.balanceOf(address(this)) * minBalancePercentage / 100;
            uint256 votesToAward = leadVoteRecipient.voteCount * voteAwardMultiplier;
            uint256 daoOwnerTake;

            if(minContractBalance < votesToAward){
                daoOwnerTake = minContractBalance * daoOwnerTax / 100;
                _winnings[leadVoteRecipient.candidate] += (minContractBalance - daoOwnerTake);
                emit cycleWinner(leadVoteRecipient.candidate, minContractBalance - daoOwnerTake);

            } else {
                daoOwnerTake = votesToAward * daoOwnerTax / 100;
                _winnings[leadVoteRecipient.candidate] += (votesToAward - daoOwnerTake);
                emit cycleWinner(leadVoteRecipient.candidate, votesToAward - daoOwnerTake);
            }

            _winnings[daoAdministrator] += daoOwnerTake;
        }

        if(approvedNewDAO == address(0)){
            currentVotingCycleEnd = block.timestamp + votingCyleLength;
        } else {
            leadVoteRecipient.voteCycle = 1;
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

    function voteBalanceOfACycle(uint256 cycle) external view returns (uint256) {
         return _voteBalanceOfACycle[cycle];
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

    function currentRefundAmount(address voter) external view returns (uint256) {
        uint256 numberOfVotes = _votesCast[voter].length;
        uint256 refundAmount;
        for(uint256 i = 0; i < numberOfVotes; i++){
            if( (!_votesCast[voter][i].withdrawn) && (_votesCast[voter][i].voteCycle != currentVotingCycleEnd)){
                uint256 voteRefund = (_votesCast[voter][i].voteBalance * refundPercentage / 100);
                if(voteRefund < maxRefund) {
                    refundAmount += voteRefund;
                } else {
                    refundAmount += maxRefund;
                }
            }
        }
        return refundAmount;
    }

    function refundVotes() external returns (uint256) {
        uint256 numberOfVotes = _votesCast[_msgSender()].length;
        uint256 refundAmount;
        for(uint256 i = 0; i < numberOfVotes; i++){
            if( (!_votesCast[_msgSender()][i].withdrawn) && (_votesCast[_msgSender()][i].voteCycle != currentVotingCycleEnd)){
                uint256 voteRefund = (_votesCast[_msgSender()][i].voteBalance * refundPercentage / 100);
                if(voteRefund < maxRefund) {
                    refundAmount += voteRefund;
                } else {
                    refundAmount += maxRefund;
                }
                _votesCast[_msgSender()][i].withdrawn = true;
            }
        }
        require(refundAmount > 0 , "User has nothing to refund");
        apolloToken.transfer(_msgSender(), refundAmount);

        return refundAmount;
    }


}