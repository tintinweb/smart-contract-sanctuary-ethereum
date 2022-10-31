// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import './Ownable.sol';
import './ChallengeAccount.sol';

contract ChallengeManager is Ownable {
  uint256 _counter = 0;
  uint8 internal _gymnasiaFee = 10; //percentage so always divide by 100 before
  address payable internal _gymnasiaAddress;
  address internal _apiAddress;
  ChallengeAccount internal _challengeAccount;

  enum Gender {
    UNISEX,
    FEMALE,
    MALE
  }

  struct Challenge {
    uint256 id;
    address creator;
    uint256 start;
    uint256 end;
    uint256 workouttype;
    uint256 condition;
    uint256 currentParticipantsCount;
    uint256 maxParticipantsCount;
    uint256 submissionFee;
    uint256 prizePool;
    address first;
    bool redeemed;
    Gender gender;
    bool multiSubmitAllowed;
  }

  struct Results {
    uint256 challengeId;
    address athleteAddress;
    uint32 value;
  }

  mapping(uint256 => Challenge) public challenges;
  mapping(uint256 => address[]) public athleteAddresses;
  mapping(uint256 => mapping(address => bool)) public challengeKeys;
  mapping(uint256 => mapping(address => uint32)) public leaderboards;
  mapping(uint256 => address) public prefunder;

  constructor(
    address gymnasiaAddress,
    address apiAddress,
    address challengeAccount
  ) {
    _gymnasiaAddress = payable(gymnasiaAddress);
    _apiAddress = apiAddress;
    _challengeAccount = ChallengeAccount(challengeAccount);
  }

  modifier onlyApi() {
    require(
      msg.sender == _apiAddress || msg.sender == owner(),
      'ChallengeManager: you are not allowed to submit'
    );
    _;
  }

  function getGymnasiaAddress() external view onlyOwner returns (address) {
    return _gymnasiaAddress;
  }

  function setGymnasiaAddress(address adr) public onlyOwner {
    _gymnasiaAddress = payable(adr);
  }

  function setGymnasiaFee(uint8 percentage) external onlyOwner {
    require(
      percentage >= 0 && percentage <= 100,
      'ChallengeManager: argument out of range -> not between 0 and 100'
    );
    _gymnasiaFee = percentage;
  }

  function getSubmissionFee(uint256 challengeId)
    external
    view
    returns (uint256)
  {
    return challenges[challengeId].submissionFee;
  }

  function getKeyPrice(uint256 challengeId) internal view returns (uint256) {
    uint256 submissionFee = challenges[challengeId].submissionFee;
    submissionFee = submissionFee - (submissionFee / 100) * _gymnasiaFee;
    return submissionFee;
  }

  //just for reuse purpose
  function _createChallenge(Challenge memory challenge)
    internal
    returns (Challenge memory)
  {
    require(
      challenge.start > block.timestamp,
      'ChallangeManager: start in the past'
    );
    require(
      challenge.end > challenge.start,
      'ChallengeManager: end time before start time'
    );

    challenges[_counter].id = _counter;
    challenges[_counter].creator = msg.sender;
    challenges[_counter].start = challenge.start;
    challenges[_counter].end = challenge.end;
    challenges[_counter].condition = challenge.condition;
    challenges[_counter].maxParticipantsCount = challenge.maxParticipantsCount;
    challenges[_counter].submissionFee = challenge.submissionFee;

    challenges[_counter].gender = challenge.gender;
    if (
      challenges[_counter].gender != Gender.FEMALE &&
      challenges[_counter].gender != Gender.MALE
    ) challenges[_counter].gender = Gender.UNISEX;

    challenges[_counter].redeemed = false;
    challenges[_counter].multiSubmitAllowed = true;

    return challenges[_counter];
  }

  function createChallenge(Challenge memory challenge)
    external
    payable
    returns (Challenge memory)
  {
    _createChallenge(challenge);
    prefundChallenge(_counter);
    return challenges[_counter++];
  }

  function prefundChallenge(uint256 challengeId) public payable {
    require(
      challenges[challengeId].end > block.timestamp,
      'ChallangeManager: challenge already ended'
    );
    require(
      challenges[challengeId].start > block.timestamp,
      'ChallangeManager: challenge already started'
    );

    challenges[challengeId].prizePool += msg.value;
    prefunder[challengeId] = msg.sender;
  }

  //todo remove payable after challenge account was added
  function submitData(Results[] memory results) public payable onlyApi {
    require(
      challenges[results[0].challengeId].start < block.timestamp,
      'ChallengeManager: Challenge did not start yet'
    );
    require(
      challenges[results[0].challengeId].end > block.timestamp,
      'ChallengeManager: Challenge already over'
    );
    //todo add condition check and type check

    if (
      !hasUnlockedChallenge(results[0].challengeId, results[0].athleteAddress)
    ) {
      //todo add substract from ChallengeAccount here
      require(
        msg.value >= challenges[results[0].challengeId].submissionFee,
        'ChallengeManager: msg.value too small'
      );
      uint256 remaining = msg.value -
        challenges[results[0].challengeId].submissionFee;
      // bool sent = _to.send(msg.value-);
      //   require(sent, "Failed to send Ether");
      (bool sent, ) = _gymnasiaAddress.call{
        value: challenges[results[0].challengeId].submissionFee -
          getKeyPrice(results[0].challengeId)
      }('');
      require(sent, 'ChallengeManager: Failed to send ether');

      challenges[results[0].challengeId].prizePool += getKeyPrice(
        results[0].challengeId
      );

      challengeKeys[results[0].challengeId][results[0].athleteAddress] = true;
    }

    leaderboards[results[0].challengeId][results[0].athleteAddress] += results[
      0
    ].value;
    athleteAddresses[results[0].challengeId].push(results[0].athleteAddress);
  }

  function hasEnoughFundsForChallenge(
    uint256 challengeId,
    address athleteAddresse
  ) public view returns (bool) {
    if (
      challenges[challengeId].submissionFee <=
      _challengeAccount.getBalance(athleteAddresse)
    ) return true;

    return false;
  }

  function hasUnlockedChallenge(uint256 challengeId, address athleteAddress)
    public
    view
    returns (bool)
  {
    return challengeKeys[challengeId][athleteAddress];
  }

  function withdraw(uint256 challengeId) public {
    require(
      block.timestamp >= challenges[challengeId].end,
      'ChallengeManager: challenge did not end yet'
    );
    require(
      !challenges[challengeId].redeemed,
      'Challengemanager: Challenge already redeemed'
    );
    address winner = getWinner(challengeId);
    challenges[challengeId].redeemed = true; //it is important that the set Redeemed command is before the sent operation

    (bool sent, ) = payable(winner).call{
      value: challenges[challengeId].prizePool
    }('');
    require(sent, 'ChallengeManager: Failed to send ether');
  }

  function getWinner(uint256 challengeId) internal returns (address) {
    require(
      block.timestamp >= challenges[challengeId].end,
      'ChallengeManager: challenge did not end yet'
    );
    challenges[challengeId].first = athleteAddresses[challengeId][0];
    uint32 newFirstValue = 0;
    for (uint256 i = 0; i < athleteAddresses[challengeId].length; i++) {
      if (
        newFirstValue <
        leaderboards[challengeId][athleteAddresses[challengeId][i]]
      ) {
        challenges[challengeId].first = athleteAddresses[challengeId][i];
        newFirstValue = leaderboards[challengeId][
          athleteAddresses[challengeId][i]
        ];
      }
    }
    return challenges[challengeId].first;
  }

  function getAllChallenges() public view returns (Challenge[] memory) {
    Challenge[] memory array = new Challenge[](_counter);
    for (uint256 i = 0; i < array.length; i++) {
      array[i].id = challenges[i].id;
      array[i].creator = challenges[i].creator;
      array[i].start = challenges[i].start;
      array[i].end = challenges[i].end;
      array[i].condition = challenges[i].condition;
      array[i].currentParticipantsCount = challenges[i]
        .currentParticipantsCount;
      array[i].maxParticipantsCount = challenges[i].maxParticipantsCount;
      array[i].submissionFee = challenges[i].submissionFee;
      array[i].prizePool = challenges[i].prizePool;
      array[i].first = challenges[i].first;
      array[i].redeemed = challenges[i].redeemed;
      array[i].gender = challenges[i].gender;
      array[i].multiSubmitAllowed = challenges[i].multiSubmitAllowed;
    }
    return array;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.17 <0.9.0;

abstract contract Ownable {
  //todo add abstract after compiler upgrade
  address private _owner;
  bool private isFirstCall = true;
  bool private isFirstCallToken = true;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor() {
    _transferOwnership(msg.sender);
  }

  function owner() public view returns (address) {
    //todo add virtual
    return _owner;
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, 'Ownable: caller is not the owner');
    _;
  }

  modifier onlyOwnerOrFirst() {
    require(
      owner() == msg.sender || isFirstCall,
      'Ownable: caller is not the owner'
    );
    isFirstCall = false;
    _;
  }

  modifier onlyOwnerOrFirstToken() {
    //todo find a better alternative
    require(
      owner() == msg.sender || isFirstCallToken,
      'Ownable: caller is not the owner'
    );
    isFirstCallToken = false;
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    //todo add virtual
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    //todo add virtual
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17 <0.9.0;

import './Ownable.sol';

contract ChallengeAccount is Ownable {
  mapping(address => uint256) public athleteFunds;

  constructor() {}

  function getBalance(address athlete) public view returns (uint256 balance) {
    return athleteFunds[athlete];
  }

  function deposit() external payable {
    athleteFunds[msg.sender] += msg.value;
  }

  function withdraw(uint256 amount) external {
    require(
      amount <= athleteFunds[msg.sender],
      'ChallengeAccount: cannot withdraw more than you have'
    );
    athleteFunds[msg.sender] -= amount;

    (bool sent, ) = payable(msg.sender).call{value: amount}('');
    require(sent, 'ChallengeAccount: Failed to send Ether');
  }
}