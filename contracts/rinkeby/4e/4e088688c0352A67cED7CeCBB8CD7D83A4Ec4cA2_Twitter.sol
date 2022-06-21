/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Twitter {

    struct Commentaires {

        address commenter;
        string content;
        uint timestamp;
    }

    struct Post {

        mapping(uint => Commentaires) listmsg;
        uint nb_comment;

        address commenter;
        string content;
        uint timestamp;
    }

    mapping(uint => Post) private Feed;
    uint private Feed_size;

    function SendPost(string memory _content) public {
        uint contentLength = bytes(_content).length;
        require(contentLength > 0, "Please, provide a message.");

        Feed[Feed_size].content = _content;
        Feed[Feed_size].timestamp = block.timestamp;
        Feed[Feed_size].commenter = msg.sender;

        Feed_size++;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function getPost() view public returns (string[] memory) {

        string[] memory list_post = new string[](Feed_size);

        for(uint i = 0; i < Feed_size; i++) {
            list_post[i] = string.concat("#", uint2str(i), "  - ", Feed[i].content, "\n");
        }

        return list_post;
    }

    function CommentPost(uint _id_post, string memory _comment) public {
        Feed[_id_post].listmsg[Feed[_id_post].nb_comment] = Commentaires(msg.sender, _comment, block.timestamp);
        Feed[_id_post].nb_comment++;
    }

    function getComments(uint _id_post) view public returns (string[] memory) {
        string[] memory list_comments = new string[](Feed[_id_post].nb_comment);

        for(uint i = 0; i < Feed[_id_post].nb_comment; i++) {
            list_comments[i] = string.concat("#", uint2str(i), " -", Feed[i].listmsg[i].content, "\n");
        }

        return list_comments;
    }

    function reward(uint _id_post) public payable {
        address payable post_owner = payable(Feed[_id_post].commenter);
        post_owner.transfer(msg.value);
    }
}