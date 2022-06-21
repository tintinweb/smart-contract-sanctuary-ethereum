/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

pragma solidity 0.8.12;

contract Twitter {

struct Commentaires{
    address commenter;
    string content;
    uint timestamp;
}

    struct Post{
        mapping(uint => Commentaires) listmsg;
        uint nbcomment;

        address commenter;
        string content;
        uint timestamp;
    }


    mapping (uint => Post) private Feed;
    uint private Feed_size;

    function SendPost(string memory _content) public {
        uint contentLenght = bytes(_content).length;
        require(contentLenght > 0, "Please provide a message");

        Feed[Feed_size].content = _content;
        Feed[Feed_size].timestamp = block.timestamp;
        Feed[Feed_size].commenter = msg.sender;

        Feed_size++;
    }

    function getPost() view public returns (string[] memory) {
        string[] memory list_post = new string[](Feed_size);
        for(uint i = 0; i < Feed_size; i++){
            list_post[i] = string.concat("#", uint2str(i), " -", Feed[i].content, "\n");
        }
        return list_post;
    }

    function uint2str(uint _i) internal pure returns (string memory str) {
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

            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function CommentPost(uint _id_post, string memory _comment) public {
        Feed[_id_post].listmsg[Feed[_id_post].nbcomment] = Commentaires(msg.sender, _comment, block.timestamp);
        Feed[_id_post].nbcomment++;
    }

    function getComments(uint _id_post) view public returns (string[] memory){
        uint nbcomment = Feed[_id_post].nbcomment;
        string[] memory list_comment = new string[](nbcomment);
        for(uint i = 0; i < nbcomment; i++){
            list_comment[i] = string.concat("#", uint2str(i), " -", Feed[_id_post].listmsg[i].content, "\n");
        }
        return list_comment;
    }

    function reward(uint _id_post) public payable{
        address payable post_owner = payable(Feed[_id_post].commenter);
        post_owner.transfer(msg.value);
    }


}