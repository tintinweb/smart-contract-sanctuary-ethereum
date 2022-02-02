contract VotingContract {
  uint256 public decimals; //1e18 decimals
  address[] public users = [
    0x65FD7945953B2b96c51b182C43dD8386de1A5049,
    0xAAbaD597D47f374aF7689c885075F7e93EA058Ce,
    0x8a6CE5BE599e3d5870E2ff82B4E2CeE186d2314b,
    0xABCED79a22A409b687f50C525D7153f3110E7ca6,
    0xABC61229288098cc174b4aEe6FcE957cb5fCa0Fa,
    0xABCC512B3c398C7eeeebe86647e60D60B15dcDc6,
    0xABCAc7226bE52009fb06BB6Ad48f7A08518E6d28,
    0xABCbb7269A5A06d434B46F0e7AFe828c36881f8d,
    0xABCf790c451D37df5b7D726DA4F3032Ae3C89cF5,
    0xABCc6FBb9f9d9284FE805bBb114B82B4A7dfb56E
  ];
  uint256[] public votes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
  uint256[] public testArray = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  constructor() {
    decimals = 1 ether; // 1e18 decimals
  }

  function getCurrentSeasonId() public view returns (uint256) {
    return 2;
  }

  function getProjectsInSeason(uint256 _seasonId) external view returns (uint256[] memory) {
    return testArray;
  }

  // Returns the uncondional reward amount to be distributed to a project
  function getProjectUnconditionalRewards(uint256 _projectId)
    external
    view
    returns (
      uint256 totalUnconditionalReward,
      uint256 obtainedPercentageOfVotes,
      uint256 projectUnconditionalReward
    )
  {
    totalUnconditionalReward = 100 / decimals;
    obtainedPercentageOfVotes = (100 * decimals) / 10000;
    projectUnconditionalReward = 100 / decimals;
  }

  // Returns the obtained condional reward amount for a Kpi in a specific project
  function getProjectConditionalRewardForKpi(uint256 _projectId, uint256 _kpiNumber)
    external
    view
    returns (
      uint256 totalConditionalAmount,
      uint256 maximumObtainableConditional,
      uint256 obtainedConditionalRewardAmount,
      uint256 kpiDate,
      bool reachedGoal
    )
  {
    totalConditionalAmount = 100 / decimals**2;
    kpiDate = 1643810511;

    uint256 conditionalRewardsMax = 99999 / decimals**2;
    maximumObtainableConditional = 99999 / decimals;
    obtainedConditionalRewardAmount = 100 / decimals;
    reachedGoal = true;
  }

  // Returns the users who voted for a project and the amount of votes per user
  function getVotesPerProject(uint256 _projectId)
    external
    view
    returns (
      uint256 totalNumberOfVotes,
      address[] memory users,
      uint256[] memory votes
    )
  {
    //    address[] users;
    //    uint256[] votes;
    //    users.push('0x65FD7945953B2b96c51b182C43dD8386de1A5049', '0xAAbaD597D47f374aF7689c885075F7e93EA058Ce', '0x8a6CE5BE599e3d5870E2ff82B4E2CeE186d2314b', '0xABCED79a22A409b687f50C525D7153f3110E7ca6', '0xABC61229288098cc174b4aEe6FcE957cb5fCa0Fa', '0xABCC512B3c398C7eeeebe86647e60D60B15dcDc6', '0xABCAc7226bE52009fb06BB6Ad48f7A08518E6d28', '0xABCbb7269A5A06d434B46F0e7AFe828c36881f8d', '0xABCf790c451D37df5b7D726DA4F3032Ae3C89cF5', '0xABCc6FBb9f9d9284FE805bBb114B82B4A7dfb56E');
    totalNumberOfVotes = 100;
    //    users  = users;
    //    votes = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
    return (totalNumberOfVotes, users, votes);
  }
}