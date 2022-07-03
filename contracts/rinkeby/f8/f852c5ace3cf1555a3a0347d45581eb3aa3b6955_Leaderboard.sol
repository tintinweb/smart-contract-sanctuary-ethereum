/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// File: Loaderboard_Tyago_03_07_2022.sol

pragma solidity >=0.6.6;

contract Leaderboard {

  // person who deploys contract is the owner
  address owner;

  // lists top 10 users
  uint leaderboardLength = 10;

  // create an array of Users
  mapping (uint => User) public leaderboard;
    
  // each user has a username and score
  struct User {
    string user;
    uint score;
    address _address;
  }
    
  constructor() public{
    owner = msg.sender;
  }

  // allows owner only
  modifier onlyOwner(){
    require(owner == msg.sender, "Sender not authorized");
    _;
  }

  // owner calls to update leaderboard
  function addScore(string memory user, uint score, address _temp_address) onlyOwner() public returns (bool) {
    // if the score is too low, don't update
    if (leaderboard[leaderboardLength-1].score >= score) return false;

    // loop through the leaderboard
    for (uint i=0; i<leaderboardLength; i++) {
      // find where to insert the new score
      if (leaderboard[i].score < score) {

        // shift leaderboard
        User memory currentUser = leaderboard[i];
        for (uint j=i+1; j<leaderboardLength+1; j++) {
          User memory nextUser = leaderboard[j];
          leaderboard[j] = currentUser;
          currentUser = nextUser;
        }

        // insert
        leaderboard[i] = User({
          user: user,
          score: score,
          _address: _temp_address
        });

        // delete last from list
        delete leaderboard[leaderboardLength];

        return true;
      }
    }
  }



}