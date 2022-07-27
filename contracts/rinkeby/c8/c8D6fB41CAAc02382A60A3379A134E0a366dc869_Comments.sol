// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract Comments {

    event CommentCreated (bytes32 indexed commentId, address indexed commentOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event Voted (bytes32 indexed commentId, address indexed commentOwner, address indexed voter, uint80 reputationCommentOwner, uint80 reputationVoter, int40 commentVotes, bool up, uint8 reputationAmount);

    // Data structure for each comment
    struct comment {
        address commentOwner;
        bytes32 parentComment;
        bytes32 contentId;
        int40 votes;
        bytes32 categoryId;
    }

    mapping (address => mapping (bytes32 => uint80)) reputationRegistry; // mapping user address to a mapping of categoryId to category name (categoryRegistry)
    mapping (bytes32 => string) categoryRegistry; // mapping categoryId to the category name
    mapping (bytes32 => string) contentRegistry; // mapping the contentId to the url in IPFS
    mapping (bytes32 => comment) commentRegistry; // mapping the commentId to the comment data structure
    mapping (address => mapping (bytes32 => bool)) voteRegistry; // mapping user address to a mapping of voteId to a boolean (like/dislike => true/false)

    // Function to create a comment based on the comment data structure defined above
    function createComment(bytes32 _parentId, string calldata _contentUri, bytes32 _categoryId) external /* returns (bytes32) */ { // content URI is where the comment data is stored in IPFS
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri)); // create contentId by hashing the _contentUri
        bytes32 _commentId = keccak256(abi.encodePacked(_owner, _parentId, _contentId)); // commentId comprised of the hash of owner, parentId, contentId
        contentRegistry[_contentId] = _contentUri; // save the contentUri to the contentRegistry mapping
        commentRegistry[_commentId].commentOwner = _owner;
        commentRegistry[_commentId].parentComment = _parentId;
        commentRegistry[_commentId].contentId = _contentId;
        commentRegistry[_commentId].categoryId = _categoryId;
        // commentRegistry[_commentId].votes = 0; (Not needed bc Solidity auto initialized ints to 0)
        emit ContentAdded(_contentId, _contentUri); // event to notify that the content was IPFS, used to fetch data on front end
        emit CommentCreated (_commentId, _owner,_parentId,_contentId,_categoryId); // fire event that the comment was created
        /* return _commentId; */
    }

    // Function to add a "like" or "upvote" to another user's comment
    function voteUp(bytes32 _commentId, uint8 _reputationAdded) external { // _reputationAdded adds to the reputation of the _voter in specific category
        address _voter = msg.sender;
        bytes32 _category = commentRegistry[_commentId].categoryId;
        address _contributor = commentRegistry[_commentId].commentOwner;
        require (commentRegistry[_commentId].commentOwner != _voter, "User cannot vote their own comments");
        require (voteRegistry[_voter][_commentId] == false, "User already voted on this comment");
        require (validateReputationChange(_voter,_category,_reputationAdded) == true, "This address cannot add this amount of reputation points");
        commentRegistry[_commentId].votes += 1; // increments the vote count of the specific comment voted on
        reputationRegistry[_contributor][_category] += _reputationAdded; // increments to reputation of the user
        voteRegistry[_voter][_commentId] = true; // saves voteRegistry as state and changes to true so the user can't vote twice
        emit Voted(_commentId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], commentRegistry[_commentId].votes, true, _reputationAdded); // collects all voting data to be used to update UI
    }

    // Function to add a "dislike" or "downvote" to another user's comment
    function voteDown(bytes32 _commentId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = commentRegistry[_commentId].categoryId;
        address _contributor = commentRegistry[_commentId].commentOwner;
        require (voteRegistry[_voter][_commentId] == false, "User already voted in this comment");
        require (validateReputationChange(_voter,_category,_reputationTaken)==true, "This address cannot take this amount of reputation points");
        commentRegistry[_commentId].votes >= 1 ? commentRegistry[_commentId].votes -= 1 : commentRegistry[_commentId].votes = 0; // only decrement if user's votes are > 1; i.e. a comment cannot have negative votes!
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken: reputationRegistry[_contributor][_category] =0;
        voteRegistry[_voter][_commentId] = true;
        emit Voted(_commentId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], commentRegistry[_commentId].votes, false, _reputationTaken);
    }

    // Function to validate the change in user reputation
    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result) {
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2 ) { // if the reputation of the user voting is less than 2
            _reputationAdded == 1 ? _result = true : _result = false; // the reputation added will only be one
        }
        else { // if reputation is greater than 2
            2**_reputationAdded <= _reputation ? _result = true: _result = false; // we logarithmically determine the reputation added
        }
    }

    /* GET FUNCTIONS */

    function getContent(bytes32 _contentId) public view returns (string memory) {
        return contentRegistry[_contentId];
    }
    
    function getCategory(bytes32 _categoryId) public view returns(string memory) {   
        return categoryRegistry[_categoryId];
    }

    function getReputation(address _address, bytes32 _categoryID) public view returns(uint80) {   
        return reputationRegistry[_address][_categoryID];
    }

    function getComment(bytes32 _commentId) public view returns(address, bytes32, bytes32, int72, bytes32) {   
        return (
            commentRegistry[_commentId].commentOwner,
            commentRegistry[_commentId].parentComment,
            commentRegistry[_commentId].contentId,
            commentRegistry[_commentId].votes,
            commentRegistry[_commentId].categoryId);
    }
}