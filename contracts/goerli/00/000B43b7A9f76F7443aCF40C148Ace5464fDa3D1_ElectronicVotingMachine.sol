//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

import "./_Utils.sol";
import "./_Logging.sol";

contract ElectronicVotingMachine is Logging {
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

	function _calculeTotalPercentage(uint dividend, uint divisor) private pure returns (uint) {
		uint decimal = 4;

		return uint(((dividend * (10**decimal)) / divisor));
	}

	function getCandidatesRegistered() public view returns (Candidate[6] memory) {
		return _candidateList;
	}

	function getConfirmedVotes() public view returns (Confirmed[6] memory, Vote memory) {
		return (_confirmed, _confirmedVote);
	}

	function getAbstentionVotes() public view returns (Abstention memory) {
		return _abstention;
	}

	function getTotalElectorVotes() public view returns (uint) {
		return _confirmedVote.total + _abstention.votes.total;
	}

	function confirmVote(uint candidateId)
		public
		onlyCandidatesRegistered(candidateId)
		onlyElectorWithoutVote(tx.origin, _abstention, _confirmed)
	{
		_confirmedVote.total++;
		_confirmed[candidateId].electorList.push(Elector({wallet: tx.origin}));
		_confirmedVote.totalPercentage = _calculeTotalPercentage(_confirmedVote.total, getTotalElectorVotes());
		_abstention.votes.totalPercentage = _calculeTotalPercentage(_abstention.votes.total, getTotalElectorVotes());

		this.emitRealTimeVoting(_confirmed, _confirmedVote, _abstention);
	}

	function confirmAbstentionVote() public onlyElectorWithoutVote(tx.origin, _abstention, _confirmed) {
		_abstention.votes.total++;
		_abstention.electorList.push(Elector({wallet: tx.origin}));
		_abstention.votes.totalPercentage = _calculeTotalPercentage(_abstention.votes.total, getTotalElectorVotes());
		_confirmedVote.totalPercentage = _calculeTotalPercentage(_confirmedVote.total, getTotalElectorVotes());

		this.emitRealTimeVoting(_confirmed, _confirmedVote, _abstention);
	}
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

interface Utils {
	struct Candidate {
		uint id;
		string avatar;
	}

	struct Elector {
		address wallet;
	}

	struct Vote {
		uint total;
		uint totalPercentage;
	}

	struct Abstention {
		Elector[] electorList;
		Vote votes;
	}

	struct Confirmed {
		Candidate candidate;
		Elector[] electorList;
	}
}

//SPDX-License-Identifier: UNLICENSED

// Solidity files have to start with this pragma.
// It will be used by the Solidity compiler to validate its version.
pragma solidity ^0.8.17;

import "./_Utils.sol";

contract Logging is Utils {
	event LogRealTimeVoting(
		string message,
		Confirmed[6] indexed candidatesConfirmedVotes,
		Vote indexed confirmedVotes,
		Abstention indexed abstentionVotes
	);

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
		string memory messageError = "The voter already has a computed vote!";
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

		require(!hasAlreadyVoted, messageError);
		_;
	}

	function emitRealTimeVoting(
		Confirmed[6] memory candidatesConfirmedVotes,
		Vote memory confirmedVotes,
		Abstention memory abstentionVotes
	) external {
		emit LogRealTimeVoting(
			"There was a vote in the Electronic Voting Machine box!",
			candidatesConfirmedVotes,
			confirmedVotes,
			abstentionVotes
		);
	}
}