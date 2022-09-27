/**
 *Submitted for verification at Etherscan.io on 2022-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract FlyOnTheWall {
    enum Status {
        OPEN,
        CLOSED
    }
    uint8 private constant status_length = 2;
    uint256 internal postID;

    uint8 private constant max_number_rules = 10;

    struct Post {
        uint256 postID;
        string title;
        string url;
        address admin;
        Application[] applications;
        address[] winners;
        string[] rules;
        uint8[] rules_weight;
        uint8 highestScore;
        Status status;
    }

   struct PostUserInfo {
        uint256 postID;
        mapping(address => uint8[]) scores;
        mapping(address => bool) applied;
   }

    struct Application {
        address applicant;
        string url;
    }

    mapping(uint256 => Post) public posts;
    mapping(uint256 => PostUserInfo) public post_user_info_list;
    Post[] post_list;
    
    error TooManyRules();
    error InvalidState();
    error CannotSetSameState();
    error OnlyAdminAllowed();
    error InvalidPost();
    error PostClosed();
    error ApplicationScoresShouldMatchRules();
    error ApplicantDoesNotExistForThisPost();

    modifier validRules(string[] memory _rules) {
        if (_rules.length > max_number_rules) revert TooManyRules();
        _;
    }

    modifier onlyAdmin(uint256 _postID) {
        Post storage post = posts[_postID];
        if (msg.sender != post.admin) revert OnlyAdminAllowed();
        _;
    }

    modifier validPost(uint256 _postID) {
        Post storage post = posts[_postID];
        if (post.admin == address(0)) revert InvalidPost();
        _;
    }

    // 1. anyone can create a post
        // post admin, title, rules, url, status
    function createPost(string memory _title, string memory _url, string[] memory _rules, uint8[] memory _rules_weight) public validRules(_rules) returns (uint256) {
        Post storage post = posts[postID];
        post.admin = msg.sender;
        post.title = _title;
        post.url = _url;
        post.rules = _rules;
        post.rules_weight = _rules_weight;
        post.status = Status.OPEN;
        
        post_list.push(post);
        emit PostCreated(
          postID,
          _title,
          msg.sender,
          block.timestamp  
        );
        postID++;
        return post.postID;
    }

    // 1a list all posts
    function listPosts() public view returns (Post[] memory) {
        return post_list;
    }

    function validateState(Status _status) internal pure returns (bool) {
        return (uint8(_status) <= status_length);
    }

    // 1b admin can close or reopen post
    function changePostState(uint256 _postID, Status _status) public onlyAdmin(_postID) {
        if (!validateState(_status)) revert InvalidState();
    
        Post storage post = posts[_postID];

        if (post.status == _status) revert CannotSetSameState();
        post.status = _status;

        emit PostStateChanged(
            _postID,
            msg.sender,
            _status,
            block.timestamp  
        );
    }


    // 2. anyone can apply to post
        // address, url, email?
    function applyToPost(uint256 _postID, string memory _url) public validPost(_postID) returns (bool) {
        Post storage post = posts[_postID];
        if (post.status == Status.CLOSED) revert PostClosed();

        Application memory application;
        application.applicant = msg.sender;
        application.url = _url;
        
        // kept here to enable easily listing to user;
        post.applications.push(application);

        PostUserInfo storage pui = post_user_info_list[_postID];
        // kept here to enable easy access the application of a specific user
        pui.applied[msg.sender] = true;

        emit PostApplication(
            _postID,
            msg.sender
        );

        return true;
    }


    // 3. admin can score applications
    // assumes each score is a one to one mapping to the rules, in the same array order
    function scoreApplicationForPost(uint256 _postID, address _applicant, uint8[] memory _scores) public onlyAdmin(_postID) validPost(_postID) {
        Post storage post = posts[_postID];
        if (_scores.length != post.rules.length) revert ApplicationScoresShouldMatchRules();
        
        PostUserInfo storage pui = post_user_info_list[_postID];
        if (pui.applied[_applicant] == false) revert ApplicantDoesNotExistForThisPost();
        // saving scores here for auditing purposes
        pui.scores[_applicant] = _scores;
                                                                        
        uint8 totalScore;
        for (uint8 i = 0; i < _scores.length; i++) {
            totalScore += _scores[i] * post.rules_weight[i];
        }

        if (totalScore > post.highestScore) {
            address[] memory new_winner = new address[](1);
            new_winner[0] = _applicant;
            
            post.winners = new_winner;
            post.highestScore = totalScore;
        } else if (totalScore == post.highestScore) {
            // TODO: avoid having the same addresses as a tie (in case of updating scores)

            uint currentWinnersTotal = post.winners.length;
            address[] memory tie_winners = new address[](currentWinnersTotal + 1);
            for (uint i = 0; i < currentWinnersTotal; i++) {
                tie_winners[i] = post.winners[i];
            }
            tie_winners[currentWinnersTotal] = _applicant;
            post.winners = tie_winners; 
        }

        emit ApplicationScored(
            _postID,
            _applicant,
            block.timestamp
        );
    }

    // 4. users can check winner
    function getWinner(uint256 _postID) public view validPost(_postID) returns (address[] memory) {
        Post memory post = posts[_postID];

        return post.winners;
    }

    // 4b. list application score for post

    // 5. users can view applications
    function listApplicationsForPost(uint256 _postID) public view validPost(_postID) returns (Application[] memory) {
        Post memory post = posts[_postID];

        return post.applications;
    }

    // 6. implement payable, in case tokens are sent to contract?

    event PostCreated(
        uint256 postID,
        string title,
        address admin,
        uint256 timestamp
    );

    event PostApplication(
        uint256 postID,
        address applicant
    );

    event PostStateChanged(
        uint256 postID,
        address admin,
        Status state,
        uint256 timestamp
    );

    event ApplicationScored(
        uint256 postID,
        address applicant,
        uint256 timestamp
    );
}