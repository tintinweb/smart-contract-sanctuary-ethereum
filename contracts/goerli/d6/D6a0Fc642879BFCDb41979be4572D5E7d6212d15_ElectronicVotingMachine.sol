//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

import "./_IUtils.sol";
import "./_IWebSockets.sol";
import "./_Guard.sol";

contract ElectronicVotingMachine is Guard, IWebSockets {
	Candidate[6] private _candidateList;
	Confirmed[6] private _confirmed;
	Vote private _confirmedVote;
	Abstention private _abstention;

	constructor() {
		_abstention.votes = Vote({total: 0, totalPercentage: 0});
		_confirmedVote = Vote({total: 0, totalPercentage: 0});

		_registerCandidates();
	}

	function _registerCandidates() private {
		string[6] memory avatar = [
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-1.png",
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-2.png",
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-3.png",
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-4.png",
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-5.png",
			"https://raw.githubusercontent.com/thiagosaud/dApp-superior-electoral-court/main/temp/imgs/candidate-6.png"
		];

		for (uint i = 0; i < _candidateList.length; i++) {
			_candidateList[i] = Candidate({id: i == 0 ? 1 : i + 1, avatar: avatar[i]});
			_confirmed[i].candidate = _candidateList[i];
		}
	}

	function _calculeTotalPercentage(uint totalVotes) private view returns (uint) {
		uint decimal = 4;

		return uint(((totalVotes * (10**decimal)) / _getTotalElectorVotes()));
	}

	function _getTotalElectorVotes() private view returns (uint) {
		return _confirmedVote.total + _abstention.votes.total;
	}

	function getCandidatesRegistered() public view returns (Candidate[6] memory) {
		return _candidateList;
	}

	function getPolling() public view returns (Polling memory) {
		return
			Polling({
				abstentionVotes: _abstention,
				confirmedVotes: ConfirmedWithVotes({candidateList: _confirmed, votes: _confirmedVote}),
				totalElectorVotes: _getTotalElectorVotes()
			});
	}

	function confirmVote(uint candidateId)
		public
		onlyCandidatesRegistered(candidateId)
		onlyElectorWithoutVote(tx.origin, _abstention, _confirmed)
	{
		_confirmedVote.total++;
		_confirmed[candidateId].electorList.push(Elector({wallet: tx.origin}));
		_confirmedVote.totalPercentage = _calculeTotalPercentage(_confirmedVote.total);
		_abstention.votes.totalPercentage = _calculeTotalPercentage(_abstention.votes.total);

		emit LogRealTimeVoting("There was a vote in the Electronic Voting Machine box!", getPolling());
	}

	function confirmAbstentionVote() public onlyElectorWithoutVote(tx.origin, _abstention, _confirmed) {
		_abstention.votes.total++;
		_abstention.electorList.push(Elector({wallet: tx.origin}));
		_abstention.votes.totalPercentage = _calculeTotalPercentage(_abstention.votes.total);
		_confirmedVote.totalPercentage = _calculeTotalPercentage(_confirmedVote.total);

		emit LogRealTimeVoting("There was a vote in the Electronic Voting Machine box!", getPolling());
	}
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

interface IUtils {
	struct Abstention {
		Elector[] electorList;
		Vote votes;
	}

	struct Candidate {
		uint id;
		string avatar;
	}

	struct Confirmed {
		Candidate candidate;
		Elector[] electorList;
	}

	struct ConfirmedWithVotes {
		Confirmed[6] candidateList;
		Vote votes;
	}

	struct Elector {
		address wallet;
	}

	struct Polling {
		ConfirmedWithVotes confirmedVotes;
		Abstention abstentionVotes;
		uint totalElectorVotes;
	}

	struct Vote {
		uint total;
		uint totalPercentage;
	}
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

import "./_IUtils.sol";

interface IWebSockets is IUtils {
	event LogRealTimeVoting(string message, Polling indexed polling);
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

import "./_IUtils.sol";

abstract contract Guard is IUtils {
	modifier onlyCandidatesRegistered(uint candidateId) {
		string memory messageError = "This candidate don't exist!";

		require(candidateId >= 1 || candidateId <= 6, messageError);
		_;
	}

	modifier onlyElectorWithoutVote(
		address electorWallet,
		Abstention memory abstentionVotes,
		Confirmed[6] memory confirmedVotes
	) {
		bool hasAlreadyVoted = false;

		if (abstentionVotes.electorList.length > 0) {
			for (uint256 i = 0; i < abstentionVotes.electorList.length; i++) {
				if (abstentionVotes.electorList[i].wallet == electorWallet) {
					hasAlreadyVoted = true;
				}
			}
		}

		for (uint256 indexA = 0; indexA < confirmedVotes.length; indexA++) {
			if (confirmedVotes[indexA].electorList.length > 0) {
				for (uint indexB = 0; indexB < confirmedVotes[indexA].electorList.length; indexB++) {
					if (confirmedVotes[indexA].electorList[indexB].wallet == electorWallet) {
						hasAlreadyVoted = true;
					}
				}
			}
		}

		require(!hasAlreadyVoted, "The voter already has a computed vote!");
		_;
	}
}