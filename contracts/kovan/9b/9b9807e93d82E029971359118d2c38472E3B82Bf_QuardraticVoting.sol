//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

////////////////////////////////////////////////////////////////////////////////////////////
///
/// @title QuardraticVoting
/// @author conlot-crypto
///
////////////////////////////////////////////////////////////////////////////////////////////
contract QuardraticVoting {
  struct Post {
    uint256 id;
    string caption; // maximum 280 characters
    uint256 timestamp;
    address author;
  }
  Post[] public posts;
  mapping(uint256 => uint256) postIDToIndex;

  struct Vote {
    uint256 id;
    uint256 postId;
    uint256 timestamp;
    uint256 rating;
    address voter;
  }
  Vote[] public votes;
  mapping(uint256 => uint256) voteIDToIndex;

  struct Credit {
    address owner;
    uint256 lastReset;
    uint256 creditsUsed;
  }
  mapping(address => Credit) public userCredits;

  /// @dev credits given to user every day
  uint256 public constant MAX_CREDITS_PER_DAY = 40;

  /// @dev period to rechard credits
  uint64 internal constant CREDITS_RECHARD_PERID = 24 hours;

  ////////////////////////////////////////////////////////////////////
  /// Events of QuardraticVoting
  ////////////////////////////////////////////////////////////////////
  event CreatePost(address _author, uint256 _postId, uint256 _timestamp);
  event CreateVote(
    address _voter,
    uint256 _voteId,
    uint256 _rating,
    uint256 _timestamp
  );
  event EditVote(uint256 _voteId, uint256 _rating, uint256 _timestamp);
  event RemoveVote(uint256 _voteId, uint256 _timestamp);

  ////////////////////////////////////////////////////////////////////
  /// Logics of Vote and Posts
  ////////////////////////////////////////////////////////////////////

  function creditsForRate(uint256 _rating) public pure returns (uint256) {
    require(_rating > 0 && _rating < 6, 'Invalid Rating');

    if (_rating == 1 || _rating == 4) {
      return 4;
    } else if (_rating == 2 || _rating == 3) {
      return 1;
    }

    return 9;
  }

  function _voteWithRatings(address _user, uint256 _rating) internal {
    Credit storage userCredit = userCredits[_user];
    uint256 creditsToRate = creditsForRate(_rating);

    if (userCredit.owner == address(0)) {
      // first vote
      userCredit.lastReset = block.timestamp;
      userCredit.owner = _user;
      userCredit.creditsUsed = creditsToRate;
    } else {
      // check if 1 day is passed from lastRest
      if (block.timestamp >= userCredit.lastReset + CREDITS_RECHARD_PERID) {
        userCredit.creditsUsed = 0;
        userCredit.lastReset = block.timestamp;
      }

      // check if have enought credits to rate
      require(
        userCredit.creditsUsed + creditsToRate <= MAX_CREDITS_PER_DAY,
        'Not enough credits today'
      );

      // update credit info
      userCredit.creditsUsed += creditsToRate;
      userCredit.owner = _user;
    }
  }

  /// @dev createPost
  /// @param _author who creates a Post
  /// @param _caption string content of Post
  /// @return newPostId index of new Post added to array
  function createPost(address _author, string memory _caption)
    public
    returns (uint256 newPostId)
  {
    require(_author != address(0), 'Invalid Author');
    require(_author == msg.sender, 'Caller is not an Author');

    bytes memory string_caption = bytes(_caption);
    require(
      string_caption.length > 0 && string_caption.length <= 280,
      'Invalid Caption'
    );

    // calculate new Post Id
    if (posts.length > 0) {
      newPostId = posts[posts.length - 1].id;
    }

    // add new Post to array
    Post memory newPost = Post(newPostId, _caption, block.timestamp, _author);
    posts.push(newPost);

    // store new Post Index with postId
    postIDToIndex[newPostId] = posts.length;

    // trigger event of creating a new post
    emit CreatePost(_author, newPostId, block.timestamp);
  }

  /// @dev createVote
  /// @param _voter who creates a Vote
  /// @param _postId id of Post
  /// @param _rating new rating
  /// @return newVoteId Id of new voting added to array
  function createVote(
    address _voter,
    uint256 _postId,
    uint256 _rating
  ) public returns (uint256 newVoteId) {
    require(_voter != address(0), 'Invalid Voter');
    require(_voter == msg.sender, 'Voter is not caller');
    require(_rating > 0 && _rating < 6, 'Invalid Rating');
    require(posts.length > 0, 'No Post yet');

    // validation of postID
    require(postIDToIndex[_postId] > 0, 'Invalid PostId');

    _voteWithRatings(_voter, _rating);

    // calculate new Vote Id
    if (votes.length > 0) {
      newVoteId = votes[votes.length - 1].id;
    }

    // add new vote to array
    Vote memory newVote = Vote(
      newVoteId,
      _postId,
      block.timestamp,
      _rating,
      _voter
    );
    votes.push(newVote);

    // store new Vote Index with voteId
    voteIDToIndex[newVoteId] = votes.length;

    // trigger event of creating a new Vote
    emit CreateVote(_voter, newVoteId, _rating, block.timestamp);
  }

  /// @dev editVote
  /// @param _voteId id of Vote to edit
  /// @param _rating new rating
  function editVote(uint256 _voteId, uint256 _rating) public {
    // validation check of _rating
    require(_rating > 0 && _rating < 6, 'Invalid Rating');

    // validaton check if not vote yet
    require(votes.length > 0, 'No Vote yet');

    // validation check if voteId is right
    require(voteIDToIndex[_voteId] > 0, 'Invalid VoteId');

    Vote storage vote = votes[voteIDToIndex[_voteId] - 1];

    // validation check if vote exists
    require(vote.voter != address(0), 'Invalid VoteId');

    // validation check of new voting
    require(vote.voter == msg.sender, 'Caller is not Voter');
    require(vote.rating != _rating, 'Same Rate');

    // update rating
    vote.rating = _rating;

    // trigger event of editing vote
    emit EditVote(_voteId, _rating, block.timestamp);
  }

  /// @dev removeVote
  /// @param _voteId id of Vote to remove
  function removeVote(uint256 _voteId) public {
    // validaton check if not vote yet
    require(votes.length > 0, 'No Vote yet');

    // validation check if voteId is right
    require(voteIDToIndex[_voteId] > 0, 'Invalid VoteId');

    // calculating voteIndex
    uint256 voteIndex = voteIDToIndex[_voteId] - 1;

    // validation check if vote exists
    require(votes[voteIndex].voter != address(0), 'Invalid VoteId');

    // validation check if voter is trying to remove
    require(votes[voteIndex].voter == msg.sender, 'Caller is not Voter');

    // remove vote
    delete votes[voteIndex];
    voteIDToIndex[_voteId] = 0;

    // trigger event of deleting vote
    emit RemoveVote(_voteId, block.timestamp);
  }
}