// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

contract TeamProject {
    struct Comment {
        address author;
        string content;
        address[] likes;
    }

    mapping(bytes32 => Comment[]) private allComments;

    event CommentAddedEvent(
        bytes32 indexed txHash,
        address indexed author,
        string indexed content
    );

    event LikeAddedEvent(
        bytes32 indexed txHash,
        address indexed author,
        address indexed whoLike
    );

    function hasAlreadyCommanded(bytes32 _txHash, address _author)
        private
        view
        returns (bool)
    {
        Comment[] memory commentsInOneHash = allComments[_txHash];
        for (uint256 i = 0; i < commentsInOneHash.length; i++) {
            if (commentsInOneHash[i].author == _author) {
                return true;
            }
        }
        return false;
    }

    function addCommentByTxHash(bytes32 _txHash, string memory _content)
        public
    {
        require(
            !hasAlreadyCommanded(_txHash, msg.sender),
            "Only one comment is allowed per account"
        );

        allComments[_txHash].push(
            Comment({
                author: msg.sender,
                content: _content,
                likes: new address[](0)
            })
        );
        emit CommentAddedEvent(_txHash, msg.sender, _content);
    }

    function getCommentsByTxHash(bytes32 _txHash)
        public
        view
        returns (Comment[] memory)
    {
        return allComments[_txHash];
    }

    function testGetString() public pure returns (string memory) {
        return "Hello world";
    }

    function testGetStringArray() public pure returns (string[3] memory) {
        string[3] memory arr = ["s1", "s2", "s3"];
        return arr;
    }

    function checkAlreadyLiked(bytes32 _txHash, address _author)
        private
        view
        returns (uint256)
    {
        Comment[] memory commentsInOneHash = allComments[_txHash];
        // There are many comments in a tx hash, find out the comment you need by ID.
        for (uint256 i = 0; i < commentsInOneHash.length; i++) {
            if (commentsInOneHash[i].author == _author) {
                // There are many likes in a comment, check if the user has already liked.
                for (
                    uint256 j = 0;
                    j < commentsInOneHash[i].likes.length;
                    j++
                ) {
                    if (commentsInOneHash[i].likes[j] == msg.sender) {
                        revert();
                    }
                }
                // Check finished. Return comment index.
                return i;
            }
        }
        revert();
    }

    function addLikeByTxHashAuthor(bytes32 _txHash, address _author) public {
        uint256 commentIndex = checkAlreadyLiked(_txHash, _author);
        allComments[_txHash][commentIndex].likes.push(msg.sender);
        emit LikeAddedEvent(_txHash, _author, msg.sender);
    }
}