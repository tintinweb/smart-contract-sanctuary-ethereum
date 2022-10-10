/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

// SPDX-License-Identifier: CC-BY-SA 4.0
pragma solidity >=0.8.0 <0.9.0;
contract SocialMediaThread {
    address admin;
    enum ThreadState { OPEN, CLOSED }
    struct Comment {
        uint threadId;
        uint threadCommentId;
        uint likes;
        string comment;
        address author;
        mapping(address => bool) hasLiked;
    }
    struct Thread {
        uint id;
        uint likes;
        uint commentNonce;
        string title;
        string desc;
        string imageUrl;
        string prizeAmount;
        uint32 deadline;
        string winner;
        ThreadState state;
        mapping(uint => Comment) comments;
        mapping(address => bool) hasLiked;
        mapping(uint => bool) doesCommentExists;
    }
    uint public ThreadNonce;
    mapping(uint => Thread) public Threads;
    mapping(uint => bool) doesThreadExists;
    mapping(address => bool) hasAdminRights;
    ERC721 NFT;
    constructor(){
        admin = msg.sender;
        // NFT = ERC721(0x000...);
    }
    modifier isValidThread(uint _threadID) {
        require(doesThreadExists[_threadID] == true, "Invalid Thread Id");
        _;
    }
    modifier isAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }
    modifier checkAdminRights() {
        require(admin == msg.sender || hasAdminRights[msg.sender] == true, "not admin");
        _;
    }
    modifier isValidComment(uint _threadID, uint _commentId) {
        require(    doesThreadExists[_threadID] == true
                    && Threads[_threadID].doesCommentExists[_commentId] == true,
                     "Invalid thread or comment id");
        _;
    }
    modifier checkDeadline(uint _threadID){
        require(Threads[_threadID].deadline <= block.timestamp, "past deadline");
        _;
    }
    function editAdminRights(address _who, bool _val) public isAdmin {
        hasAdminRights[_who] = _val;
    }
    function editNFT(ERC721 _NFTAddress) public checkAdminRights {
        require(isContract(address(_NFTAddress)) == true, "input address is not a contract.");
        NFT = _NFTAddress;
    }
    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
    function createThread(string memory _title, string memory _desc, string memory _imageUrl, string memory _prize, uint32 _deadline) public checkAdminRights {
        Threads[ThreadNonce].id = ThreadNonce;
        Threads[ThreadNonce].title = _title;
        Threads[ThreadNonce].desc = _desc;
        Threads[ThreadNonce].imageUrl = _imageUrl;
        Threads[ThreadNonce].prizeAmount = _prize;
        Threads[ThreadNonce].deadline = _deadline;
        doesThreadExists[ThreadNonce] = true;
        ThreadNonce ++;
    }
    function editThread(string memory _title, string memory _desc, string memory _imageUrl, string memory _prize,
                             uint32 _deadline, string memory _winner, uint _threadID, ThreadState _state) public checkAdminRights isValidThread(_threadID) {
        Threads[_threadID].title = _title;
        Threads[_threadID].desc = _desc;
        Threads[_threadID].imageUrl = _imageUrl;
        Threads[_threadID].prizeAmount = _prize;
        Threads[_threadID].deadline = _deadline;
        Threads[_threadID].winner = _winner;
        Threads[_threadID].state = _state;
    }
    function postComment(uint _threadID, string memory _content) public isValidThread(_threadID) {
        require(NFT.balanceOf(msg.sender) != 0, "You do not have permission to post a comment.");
        require(Threads[_threadID].state == ThreadState.OPEN, "Thread is closed");
        uint commentNonce = Threads[_threadID].commentNonce;
        Threads[_threadID].comments[commentNonce].threadId = _threadID;
        Threads[_threadID].comments[commentNonce].threadCommentId = commentNonce;
        Threads[_threadID].comments[commentNonce].comment = _content;
        Threads[_threadID].comments[commentNonce].author = msg.sender;
        Threads[_threadID].doesCommentExists[commentNonce] = true;
        Threads[_threadID].commentNonce ++;
    }
    function likeComment(uint _threadID, uint _commentId, bool _val) public isValidComment(_threadID, _commentId){
        if (Threads[_threadID].comments[_commentId].hasLiked[msg.sender] == true && _val == false) {
            Threads[_threadID].comments[_commentId].likes --;
            Threads[_threadID].comments[_commentId].hasLiked[msg.sender] = false;
        } else if (Threads[_threadID].comments[_commentId].hasLiked[msg.sender] == false && _val == true) {
            Threads[_threadID].comments[_commentId].likes ++;
            Threads[_threadID].comments[_commentId].hasLiked[msg.sender] = true;
        } else {
            revert("Invalid operation");
        }
    }
    function likeThread(uint _threadID, bool _val) public isValidThread(_threadID) {
        if (Threads[_threadID].hasLiked[msg.sender] == true && _val == false) {
            Threads[_threadID].likes --;
            Threads[_threadID].hasLiked[msg.sender] = false;
        } else if (Threads[_threadID].hasLiked[msg.sender] == false && _val == true) {
            Threads[_threadID].likes ++;
            Threads[_threadID].hasLiked[msg.sender] = true;
        } else {
            revert("Invalid operation");
        }
    }
    function viewComment(uint _threadID, uint _commentId) public isValidComment(_threadID, _commentId) view returns (uint commentId, uint likes, address author, string memory comment) {
        Comment storage cmt = Threads[_threadID].comments[_commentId];
        return (cmt.threadCommentId, cmt.likes, cmt.author, cmt.comment);
    }
    function hasLiked(uint _threadID, uint _commentId, bool _isThread) public isValidThread(_threadID) view returns (bool liked) {
        if(_isThread == true) {
            return Threads[_threadID].hasLiked[msg.sender];
        } else {
            require( Threads[_threadID].doesCommentExists[_commentId] == true, "Invalid comment ID");
            return Threads[_threadID].comments[_commentId].hasLiked[msg.sender];
        }
    }
    function checkIsAdmin() public view returns (bool) {
        return (admin == msg.sender || hasAdminRights[msg.sender] == true);
    }
}
interface ERC721{
    function balanceOf(address) external returns (uint);
}