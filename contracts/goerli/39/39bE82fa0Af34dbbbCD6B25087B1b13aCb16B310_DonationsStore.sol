// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DonationsStore {
  enum ChallengeStatus {
    Proposed,
    Completed,
    Failed
  }

  struct Challenge {
    address to;
    uint256 timestamp;
    string terms;
    uint256 award;
    ChallengeStatus status;
  }

  mapping(address => Challenge[]) public proposedChallenges; // donater address => challenges

  event NewDonation(
    address indexed from,
    string nickname,
    address indexed to,
    uint256 amount,
    uint256 timestamp,
    string message
  );

  event ChallengeProposed(
    address indexed from,
    string nickname,
    address indexed to,
    uint256 proposalPrice,
    uint256 timestamp,
    string terms,
    uint256 award,
    uint256 index
  );

  event ChallengeCompleted(
    address indexed from,
    address indexed to,
    uint256 timestamp,
    uint256 index
  );

  event ChallengeFailed(
    address indexed from,
    address indexed to,
    uint256 timestamp,
    uint256 index
  );

  function donate(
    string calldata _nickname,
    address _to,
    string calldata _message
  ) external payable {
    payable(_to).transfer(msg.value);
    emit NewDonation(
      msg.sender,
      _nickname,
      _to,
      msg.value,
      block.timestamp, // solhint-disable-line not-rely-on-time
      _message
    );
  }

  function proposeChallenge(
    string calldata _nickname,
    address _to,
    string calldata _terms,
    uint256 _award
  ) external payable {
    uint256 proposalPrice = msg.value - _award;
    payable(_to).transfer(proposalPrice);
    proposedChallenges[msg.sender].push(
      Challenge(_to, block.timestamp, _terms, _award, ChallengeStatus.Proposed)
    );
    emit ChallengeProposed(
      msg.sender,
      _nickname,
      _to,
      proposalPrice,
      block.timestamp, // solhint-disable-line not-rely-on-time
      _terms,
      _award,
      proposedChallenges[msg.sender].length - 1
    );
  }

  function completeChallenge(uint256 _index) external {
    Challenge storage challenge = proposedChallenges[msg.sender][_index];
    require(
      challenge.status == ChallengeStatus.Proposed,
      "Challenge already finished"
    );
    challenge.status = ChallengeStatus.Completed;
    payable(challenge.to).transfer(challenge.award);
    emit ChallengeCompleted(msg.sender, challenge.to, block.timestamp, _index); // solhint-disable-line not-rely-on-time
  }

  function failChallenge(uint256 _index) external {
    Challenge storage challenge = proposedChallenges[msg.sender][_index];
    require(
      challenge.status == ChallengeStatus.Proposed,
      "Challenge already finished"
    );
    challenge.status = ChallengeStatus.Failed;
    payable(msg.sender).transfer(challenge.award);
    emit ChallengeFailed(msg.sender, challenge.to, block.timestamp, _index); // solhint-disable-line not-rely-on-time
  }

  function getProposedChallenges(
    address _donater
  ) external view returns (Challenge[] memory) {
    return proposedChallenges[_donater];
  }
}