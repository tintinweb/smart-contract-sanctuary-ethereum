contract StakingContract {
  struct Season {
    uint256 startSeason;
    uint256 applicationStart;
    uint256 applicationEnd;
    uint256 applicationVotingStart;
    uint256 applicationVotingEnd;
    uint256 startVoting;
    uint256 endVoting;
    uint256 endSeason;
    uint256 decayStart;
  }

  Season[] public seasons;

  constructor() {
    Season memory newSeason = Season({
      startSeason: 1643810511,
      applicationStart: 1643810511,
      applicationEnd: 1643810511,
      applicationVotingStart: 1643810511,
      applicationVotingEnd: 1643810511,
      startVoting: 1643810511,
      endVoting: 1643810511,
      endSeason: 1643810511,
      decayStart: 1643810511
    });

    seasons.push(newSeason);
    seasons.push(newSeason);
    seasons.push(newSeason);
    seasons.push(newSeason);
    seasons.push(newSeason);
  }
}