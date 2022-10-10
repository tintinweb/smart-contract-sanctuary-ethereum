/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// File: contracts/LEADERBOARD.sol

contract  Ranking {

  // person who deploys contract is the owner
  address owner;
  address public token;
  // lists top 10 users
  uint leaderboardLength = 100;

  // create an array of Users
  mapping (uint => User) public leaderboard;
    
  // each user has a username and score
  struct User {
    string user;
    uint score;
    address _address;
  }
    
  constructor() {
    owner = msg.sender;

  }
  
  event Transfer_ownership(address indexed old_owner, address indexed owner);
  event Change_token(address indexed old_token, address indexed token);

  // allows owner only
  modifier onlyOwner(){
    require(owner == msg.sender, "Sender not authorized");
    _;
  }

  function transferownership(address payable new_receiver) public returns (bool){
        require(msg.sender == owner);
        emit Transfer_ownership(msg.sender , new_receiver);
        owner = new_receiver;
        return true;
    }


  // owner calls to update leaderboard
  function addScore(string memory user, uint score, address _temp_address) onlyOwner() public returns (bool transaction) {
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
        transaction = true;
        return transaction;
      }
    }
  }


  function see_rank_address(uint256 position)public view returns(address rank){
    rank = leaderboard[position]._address;
    return rank;

  }

  function see_rank_score(uint256 position)public view returns(uint256 score_){
    score_ = leaderboard[position].score;
    return score_;

  }

  function see_rank_name(uint256 position) public view returns (string memory _alias){
    _alias = leaderboard[position].user;
    return _alias;
  }

}