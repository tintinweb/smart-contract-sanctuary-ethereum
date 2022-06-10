pragma solidity ^0.8.0;

//SPDX-License-Identifier: MIT


import {CommunityPoll, PollVote, PollStatus, PollType, ProposeChanges} from "./Community/Poll.sol";

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
	
	mapping(uint256 => CommunityPoll) private _polls; //communityIds -> polls 
	mapping(uint256 => PollVote) private _pollVotes; // _PollIds -> PollVotes 

	/**
	* @notice Cast vote for the community poll
	*/
	function communityVoteCast(uint256 pollId, bool vote) external {
		address voter = msg.sender;
		PollVote memory pollvote = PollVote(
			voter,
			vote
		);
		_pollVotes[pollId] = pollvote;
	}

	/**
	* @notice get the details for the community poll
	*/
	function pollFetch(uint256 id) internal view returns ( CommunityPoll memory ){
		require(_polls[id].id > 0, "No poll found with provided pollId");
		return (_polls[id]);
	}
	
	/**
	* @notice create poll for the community (DAO)
	*/
	function communityPollCreate(uint256 daoId, PollType pollType, ProposeChanges memory proposedChanges
	) external returns(bool){
		_PollIds.increment();
		uint256 pollId = _PollIds.current();
		CommunityPoll memory poll = CommunityPoll(
			pollId,
			msg.sender, 
			PollStatus.ACTIVE,
			pollType,
			proposedChanges
		);

		_polls[daoId] = poll;
		emit EvtCommunityPollCreate(pollId);
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
	function _computePollResult(uint256 communityId, uint256 pollId) external {
		CommunityPoll memory commPoll = pollFetch(pollId);
		require(commPoll.status != PollStatus.ENDED, "Poll is already ended.");
		// require(commPoll.status);
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
	PollType _type;
	ProposeChanges proposedChanges;
}

struct ProposeChanges {
	string configName; 
	string configPurpose;
	string configLinks;
	string logoImage;
	string coverImage;
	string legalStatus;
	string legalDocuments;
	string consensus;
	address memberToadd;
	address memberToRemove;
	string gasFee;
	string bond;
	string fnCode;
	address bounty_receiver;
	string bounty;
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
 * @title Poll Type.
 * @notice Which type of poll (proposal) has been created
 */
enum PollType {
	CONFIG_NAME, 
	CONFIG_PURPOSE,
	CONFIG_LINKS,
	CONFIG_LOGO_IMAGE, 
	CONFIG_COVER_IMAGE, 
	CONFIG_LEGAL_STATUS,
	CONFIG_LEGAL_DOCUMENT,
	VOTING_CONSENSUS,
	MEMBER_TO_ADD,
	MEMER_TO_REMOVE,
	GAS_FEE,
	BOND,
	FUNCTION_CODE,
	BOUNTY_RECEIVER,
	BOUNTY
}

/**
 * @title Poll Vote.
 * @notice Poll vote struct for the community poll voting
 */
struct PollVote {
	address voter;
	bool vote;  //true-like, false-dislike
}