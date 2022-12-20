// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./_IHelper.sol";
import "./_Guard.sol";
import "./_Logging.sol";

/**
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract Ballot is IHelper, Guard, Logging {
	Confirmed[6] private _confirmedVotes;
	Abstention private _abstentionVotes;
	uint[6] private _candidates;
	uint private _totalConfirmedVotes;
	mapping(address => bool) private _electorHasAlreadyVoted;

	constructor() {
		_registerCandidates();

		emit LogStartElection("Beginning of the election period, ballot box released!", getResult());
	}

	/** @dev Register Candidates **/
	function _registerCandidates() private {
		for (uint i = 0; i < _candidates.length; i++) {
			_candidates[i] = i;
			_confirmedVotes[i].candidate = i;
		}
	}

	/**
	 * @dev Return Elector Has Already Voted
	 * @return value of '_electorHasAlreadyVoted'
	 */
	function getElectorHasAlreadyVoted() public view returns (bool) {
		return _electorHasAlreadyVoted[msg.sender];
	}

	/**
	 * @dev Return Electoral Result
	 * @return value of 'ElectionResult'
	 */
	function getResult() public view returns (ElectionResult memory) {
		return
			ElectionResult({
				candidates: _candidates,
				totalConfirmedVotes: _totalConfirmedVotes,
				confirmedVotes: _confirmedVotes,
				abstentionVotes: _abstentionVotes
			});
	}

	/**
	 * @dev Elector Vote Confirmation
	 * @param candidateID value to store
	 */
	function confirmVote(
		uint candidateID
	) public onlyCandidateRegistered(candidateID, _candidates.length) onlyElectorWhoDidNotVote(_electorHasAlreadyVoted[msg.sender]) {
		_confirmedVotes[candidateID].totalVotes++;
		_confirmedVotes[candidateID].electors.push(msg.sender);
		_confirmedVotes[candidateID].candidate = candidateID;

		_electorHasAlreadyVoted[msg.sender] = true;

		_totalConfirmedVotes++;

		emit LogElectorVote("Vote Confirmed and Computed!", getResult());
	}

	/** @dev Elector Vote Abstention **/
	function abstainVote() public onlyElectorWhoDidNotVote(_electorHasAlreadyVoted[msg.sender]) {
		_abstentionVotes.totalVotes++;
		_abstentionVotes.electors.push(msg.sender);

		_electorHasAlreadyVoted[msg.sender] = true;

		emit LogElectorVote("Vote Abstained and Computed!", getResult());
	}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./_IHelper.sol";

/**
 * @title Logging
 * @dev It brings reliability to the results of the contract
 */
abstract contract Logging is IHelper {
	event LogStartElection(string msg, ElectionResult);
	event LogElectorVote(string msg, ElectionResult);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Guard
 * @dev To ensure the integrity of the contract.
 */
abstract contract Guard {
	/**
	 * @dev Ensures that voting will be for existing candidates.
	 * @param candidateID value to store
	 * @param candidateListLength value to store
	 */
	modifier onlyCandidateRegistered(uint candidateID, uint candidateListLength) {
		require(candidateID >= 0 && candidateID < candidateListLength, "This candidate don't exist!");
		_;
	}

	/**
	 * @dev Ensures that Electors who have already voted will not be able to vote again.
	 * @param hasAlreadyVoted value to store
	 */
	modifier onlyElectorWhoDidNotVote(bool hasAlreadyVoted) {
		require(!hasAlreadyVoted, "This elector already voted!");
		_;
	}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title IHelper
 * @dev Interfaces shared between contracts
 */
interface IHelper {
	/** @dev Confirming Votes **/
	struct Confirmed {
		uint candidate;
		address[] electors;
		uint totalVotes;
	}

	/** @dev Abstention Votes **/
	struct Abstention {
		address[] electors;
		uint totalVotes;
	}

	/** @dev Election Result **/
	struct ElectionResult {
		uint[6] candidates;
		uint totalConfirmedVotes;
		Confirmed[6] confirmedVotes;
		Abstention abstentionVotes;
	}
}