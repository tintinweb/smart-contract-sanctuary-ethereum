pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


import {CommunityPoll, PollVote, PollStatus, ProposeChanges} from "./Community/Poll.sol";

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }
    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }
    function increment(Counter storage counter) internal {
        unchecked {
        counter._value += 1;
        }
    }
    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
    unchecked {
    counter._value = value - 1;
    }
    }
    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

/**
 * @title voting
 */
contract Voting {
	
	using Counters for Counters.Counter;
	Counters.Counter private _PollIds;

	event EvtCommunityPollCreate( uint256 pollId);
	event EvtCommunityPollDelete( uint256 pollId);
	
	mapping(uint256 => CommunityPoll[]) private _polls; //communityIds -> polls 
	mapping(uint256 => PollVote[]) private _pollVotes; // _PollIds -> PollVotes 

	/**
	* @notice Cast vote for the community poll
	*/
	function communityVoteCast(uint256 pollId, bool vote) external {
		address voter = msg.sender;
		PollVote memory pollvote = PollVote(
			voter,
			vote
		);
		_pollVotes[pollId].push(pollvote);
	}

	/**
	* @notice get the details for the community poll
	*/
	function pollFetch(uint256 commId, uint256 id) internal view returns ( CommunityPoll memory ){
		CommunityPoll[] memory pollArr = _polls[commId];
		require(id > 0, "No poll found with provided pollId");
		return (pollArr[id]);
	}
	
	/**
	* @notice create poll for the community (DAO)
	*/
	// uint256 startTime, uint256 endTime
	function communityPollCreate(uint256 daoId, uint256 pollType, ProposeChanges memory proposedChanges
	) external returns(bool){
		_PollIds.increment();
		uint256 pollId = _PollIds.current();
		CommunityPoll memory poll = CommunityPoll(
			pollId,
			msg.sender, 
			PollStatus.ACTIVE,
			pollType,
			proposedChanges
			// startTime,
			// endTime
		);
		_polls[daoId].push(poll);
		emit EvtCommunityPollCreate(pollId);
		return true;
	}

	/**
	* @notice delete the community poll
	*/
	function communityPollDelete(uint256 pollId) external { 
		delete _polls[pollId];
		emit EvtCommunityPollDelete(pollId);
	}

	/**	
	* @notice compute poll result
	*/
	function _computePollResult(uint256 communityId, uint256 pollId) external view returns(uint256 agreeVotes, uint256 rejectedVotes){
		CommunityPoll memory commPoll = pollFetch(communityId, pollId);
		require(commPoll.status != PollStatus.ENDED, "Poll is already ended.");
		PollVote[] memory pollVotes = _pollVotes[pollId];
		uint256 agreedVotesCount;
		uint256 rejectedVoteCount;
		for (uint256 index = 0; index < pollVotes.length; index++) {
			if(pollVotes[index].vote){
				agreedVotesCount = agreedVotesCount + 1;
			}else {
				rejectedVoteCount = rejectedVoteCount + 1;
			}
		}
		return ( agreedVotesCount, rejectedVoteCount );
	}
}

pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


/**
 * @notice Data structure for Community-based polls and proposals.
 */
struct CommunityPoll {
	uint256 id;
	address creator;
	PollStatus status;
	uint256 _type;
	ProposeChanges proposedChanges;
	// uint256 startTimeStamps;
	// uint256 endTimeStamps;
}

// name, description, amount, targetAcc, bountyAmount, availableClaims, daystoComplete, proposedDaoName, proposedPurpose, links,proposedCover, proposedLogo, proposedLegalStatus, proposedLegalDocs, bondsToCreateProposal, timeBeforeProposalExpires, bondsToClaimBounty, timeToUnclaimBounty, newGroupName, intialMemberAccount, targetGroupName, memberToAdd, memberToRemove, contractAddrFnCall, fnCallName, fnCallAbi
struct ProposeChanges {
	string amount;
	string targetAcc;
	string bountyAmount;
	string availableClaims;
	string daystoComplete;
	string proposedDaoName;
	string proposedPurpose;
	string links;
	string proposedCover;
	string proposedLogo;
	string proposedLegalStatus;
	string proposedLegalDocs;
	string bondsToCreateProposal;
	string timeBeforeProposalExpires;
	string bondsToClaimBounty;
	string timeToUnclaimBounty;
	string newGroupName;
	string intialMemberAccount;
	string targetGroupName;
	string memberToAdd;
	string memberToRemove;
	string contractAddrFnCall;
	string fnCallName;
	string fnCallAbi;
}

/**
 * @title Poll Status.
 * @notice
 */
enum PollStatus {
	ACTIVE,
	INACTIVE,
	ENDED
}

/**
 * @title Poll Vote.
 * @notice Poll vote struct for the community poll voting
 */
struct PollVote {
	address voter;
	bool vote;  //true-like, false-dislike
}