// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract NFTSocial {

    event PostCreated (bytes32 indexed postId, address indexed postOwner, bytes32 indexed parentId, bytes32 contentId, bytes32 categoryId);
    event ContentAdded (bytes32 indexed contentId, string contentUri);
    event CategoryCreated (bytes32 indexed categoryId, string category);
    event Voted (bytes32 indexed postId, address indexed postOwner, address indexed voter, uint80 reputationPostOwner, uint80 reputationVoter, int40 postVotes, bool up, uint8 reputationAmount);

    // Data structure for each post
    struct post {
        address postOwner;
        bytes32 parentPost; // used to implement comments as a child of each post
        bytes32 contentId;
        int40 votes;
        bytes32 categoryId;
    }

    mapping (address => mapping (bytes32 => uint80)) reputationRegistry; // mapping user address to a mapping of categoryId to category name (categoryRegistry)
    mapping (bytes32 => string) categoryRegistry; // mapping categoryId to the category name
    mapping (bytes32 => string) contentRegistry; // mapping the contentId to the url in IPFS
    mapping (bytes32 => post) postRegistry; // mapping the postId to the post data structure
    mapping (address => mapping (bytes32 => bool)) voteRegistry; // mapping user address to a mapping of voteId to a boolean (like/dislike => true/false)

    // Function to create a post based on the post struct data structure defined above
    function createPost(bytes32 _parentId, string calldata _contentUri, bytes32 _categoryId) external { // content URI is where the post data is stored in IPFS
        address _owner = msg.sender;
        bytes32 _contentId = keccak256(abi.encode(_contentUri)); // create contentId by hashing the _contentUri
        bytes32 _postId = keccak256(abi.encodePacked(_owner, _parentId, _contentId)); // postId comprised of the hash of owner, parentId, contentId
        contentRegistry[_contentId] = _contentUri; // save the contentUri to the contentRegistry mapping
        postRegistry[_postId].postOwner = _owner;
        postRegistry[_postId].parentPost = _parentId;
        postRegistry[_postId].contentId = _contentId;
        postRegistry[_postId].categoryId = _categoryId;
        // postRegistry[_postId].votes = 0; (Not needed bc Solidity auto initialized ints to 0)
        emit ContentAdded(_contentId, _contentUri); // event to notify that the content was IPFS, used to fetch data on front end
        emit PostCreated (_postId, _owner,_parentId,_contentId,_categoryId); // fire event that post was created
    }

    // Function to add a "like" or "upvote" to another user's post
    function voteUp(bytes32 _postId, uint8 _reputationAdded) external { // _reputationAdded adds to the reputation of the _voter in specific category
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (postRegistry[_postId].postOwner != _voter, "User cannot vote their own posts");
        require (voteRegistry[_voter][_postId] == false, "User already voted on this post");
        require (validateReputationChange(_voter,_category,_reputationAdded) == true, "This address cannot add this amount of reputation points");
        postRegistry[_postId].votes += 1; // increments the vote count of the specific post voted on
        reputationRegistry[_contributor][_category] += _reputationAdded; // increments to reputation of the user
        voteRegistry[_voter][_postId] = true; // saves voteRegistry as state and changes to true so the user can't vote twice
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, true, _reputationAdded); // collects all voting data to be used to update UI
    }

    // Function to add a "dislike" or "downvote" to another user's post
    function voteDown(bytes32 _postId, uint8 _reputationTaken) external {
        address _voter = msg.sender;
        bytes32 _category = postRegistry[_postId].categoryId;
        address _contributor = postRegistry[_postId].postOwner;
        require (voteRegistry[_voter][_postId] == false, "Sender already voted in this post");
        require (validateReputationChange(_voter,_category,_reputationTaken)==true, "This address cannot take this amount of reputation points");
        postRegistry[_postId].votes >= 1 ? postRegistry[_postId].votes -= 1 : postRegistry[_postId].votes = 0; // only decrement if user's votes are > 1; i.e. a post cannot have negative votes!
        reputationRegistry[_contributor][_category] >= _reputationTaken ? reputationRegistry[_contributor][_category] -= _reputationTaken: reputationRegistry[_contributor][_category] =0;
        voteRegistry[_voter][_postId] = true;
        emit Voted(_postId, _contributor, _voter, reputationRegistry[_contributor][_category], reputationRegistry[_voter][_category], postRegistry[_postId].votes, false, _reputationTaken);
    }

    // Function to validate the change in user reputation
    function validateReputationChange(address _sender, bytes32 _categoryId, uint8 _reputationAdded) internal view returns (bool _result){
        uint80 _reputation = reputationRegistry[_sender][_categoryId];
        if (_reputation < 2 ) { // if the reputation of the user voting is less than 2
            _reputationAdded == 1 ? _result = true : _result = false; // the reputation added will only be one
        }
        else { // if reputation is greater than 2
            2**_reputationAdded <= _reputation ? _result = true: _result = false; // we logarithmically determine the reputation added
        }
    }

    // Function to add a new category for posts / discussion
    function addCategory(string calldata _category) external {
        bytes32 _categoryId = keccak256(abi.encode(_category));
        categoryRegistry[_categoryId] = _category;
        emit CategoryCreated(_categoryId, _category);
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

    function getPost(bytes32 _postId) public view returns(address, bytes32, bytes32, int72, bytes32) {   
        return (
            postRegistry[_postId].postOwner,
            postRegistry[_postId].parentPost,
            postRegistry[_postId].contentId,
            postRegistry[_postId].votes,
            postRegistry[_postId].categoryId);
    }
}