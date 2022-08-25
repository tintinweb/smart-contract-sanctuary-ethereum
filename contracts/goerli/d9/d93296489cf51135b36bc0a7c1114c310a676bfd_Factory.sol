pragma solidity 0.8.14;

import {IChallengeFactory} from "./Challenge/IChallengeFactory.sol";

contract Factory {
  event Deployed(address indexed player, address[] challengeContracts);

  mapping(uint256 => IChallengeFactory) challengeFactories;

  mapping(address => mapping(uint256 => address[])) public challenges;

  address immutable public owner;
  constructor() {
    owner = msg.sender;
  }

  function addChallenge(uint256 key, address challenge) external {
    require(owner == msg.sender, '!owner');
    challengeFactories[key] = IChallengeFactory(challenge);
  }

  function challenge2contract(uint256 nChallenge) internal view returns(IChallengeFactory) {
    if (nChallenge > 3) {
      revert('Unknown challenge');
    }
    return challengeFactories[nChallenge];
    
  }

  function deployChallenge(uint256 nChallenge) external {
    address[] memory _challengeContracts = challenge2contract(nChallenge).deploy(msg.sender);
    emit Deployed(msg.sender, _challengeContracts);

    challenges[msg.sender][nChallenge] = _challengeContracts;
  }

  function getChallengesNumber(address user) external view returns(bool[4] memory ret) {
    for (uint256 i = 0; i < 4; ++i) {
      ret[i] = checkChallenge(user, i);
    }
  }

  function getChallengesInstances(address user, uint256 instance) external view returns(address[] memory) {
    return challenges[user][instance];
  }

  function checkChallenge(address user, uint256 nChallenge) public view returns(bool) {
    if (challenges[user][nChallenge].length == 0) {
      return false;
    }

    return challenge2contract(nChallenge).isComplete(challenges[user][nChallenge]);
  }

}

pragma solidity ^0.8.0;

interface IChallengeFactory {
    function deploy(address player) external returns (address[] memory);
    function isComplete(address[] calldata) external view returns(bool);
}