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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Voting {

    struct Candidate {
        uint candidateId;
        bytes32 candidate;
        uint votes;
    }

    struct Detail {
        bytes32 title;
        uint duration;
        Candidate[] candidates;
        uint startTime;
        uint roomId;
        address proposer;
    }

    struct History {
        address voter;
        uint candidateId;
        uint timeStamp;
    }


    uint public votingCount = 1;
    mapping(uint => Detail) public votingDetails;
    mapping(uint => History[]) public votingHistory;
    mapping(uint => address[]) public voterVerified;


    function startSession(uint _votingId, uint _duration) public{
        Detail storage details = votingDetails[_votingId];
        details.duration = _duration;
        details.startTime = block.timestamp;
    }

    function createVoting(bytes32 _title, uint _duration, uint _startTime, uint _roomId, bytes32[] calldata _candidates) external{
        Detail storage details = votingDetails[votingCount];
        details.title = _title;
        details.duration = _duration;
        uint length = _candidates.length;
        for(uint i; i < length; ++i) {
            bytes32 candidate = _candidates[i];
            details.candidates.push(Candidate(i + 1, candidate, 0));
        }
        details.startTime = (_startTime * 1 hours) + block.timestamp;
        details.roomId = _roomId;
        details.proposer = msg.sender;
        votingCount ++;
    }

    function vote(uint _votingId, address _voter, uint _candidate) external {
        Detail memory details = votingDetails[_votingId];
        bool verified = checkVerifiedVoter(_votingId, _voter);
        bool voted = checkVoterVote(_votingId, _voter);
        uint startTime = details.startTime;
        uint duration = details.duration;
        uint totalDuration = startTime + (duration * 1 hours);

        require(verified == true, "You are not verified");
        require(voted == false, "You already voted to one of the candidates");
        require(startTime < block.timestamp, "Voting session has not started");
        require(totalDuration > block.timestamp, "Duration of the voting session is over");
        uint index = getCandidateIndex(_votingId, _candidate);
       
        Candidate[] storage  candidates= votingDetails[_votingId].candidates;
        candidates[index].votes = candidates[index].votes + 1;
        votingHistory[_votingId].push(History(_voter, _candidate, block.timestamp));

    }


    function getCandidateIndex(uint _votingId, uint _candidate) internal view returns(uint index) {
        Candidate[] memory  candidates= votingDetails[_votingId].candidates;
        uint length = candidates.length;
        for(uint i; i < length; ++i) {
            uint candidate = candidates[i].candidateId;
            if(candidate == _candidate) {
                index = i;
            }
        }  
    }

    function getCandidates(uint _votingId) external view returns(Candidate[] memory candidates) {
        candidates = votingDetails[_votingId].candidates;
    }

    function getHistory(uint _votingId) external view returns(History[] memory history) {
        history = votingHistory[_votingId];
    }

    function checkVerifiedVoter(uint _votingId, address _voter) internal view returns(bool result) {
        address[] memory verified = voterVerified[_votingId];
        uint length = verified.length;
        for(uint i; i < length; ++i) {
            address _verified = verified[i];
            if(_verified ==_voter) {
                result = true;
            } else {
                result = false;
            }
        }
    }
    
    function checkVoterVote(uint _votingId, address _voter) internal view returns(bool result) {
        History[] memory votes = votingHistory[_votingId];
        uint length = votes.length;
        for(uint i; i < length; i++){
            address voter = votes[i].voter;
            if(voter == _voter){
                result = true;
            } else {
                result = false;
            }
        }
    }

    function verifyVoter(uint _votingId, bool _isVerified) external{
        bool verified = checkVerifiedVoter(_votingId, msg.sender);
        require(_isVerified, "You are not a verified voter");
        require(!verified, "You are already verified");
        voterVerified[_votingId].push(msg.sender);
    }

}