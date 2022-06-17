/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract BlockchainChat {

    struct Commentaires {
        address waver;
        string content;
        uint timestamp;
    }
    struct Post {
      mapping(uint => Commentaires) listmsg;
      uint nb_comment;
      address waver;
      string content;
      uint timestamp;
    }


    mapping(uint => Post) private Feed;
    uint private list_size;

  function uint2str(uint256 _i) internal pure returns (string memory str){
    if (_i == 0){
        return "0";
      }
      uint256 j = _i;
      uint256 length;
      while (j != 0)
      {
        length++;
        j /= 10;
      }
      bytes memory bstr = new bytes(length);
      uint256 k = length;
      j = _i;
      while (j != 0)
      {
        bstr[--k] = bytes1(uint8(48 + j % 10));
        j /= 10;
      }
      str = string(bstr);
    }

    function SendPost(string memory _content) public {
        uint contentLength = bytes(_content).length;
        require(contentLength > 0, "Please provide a message!");

        Feed[list_size].content = _content; 
        Feed[list_size].timestamp = block.timestamp;
        Feed[list_size].waver = msg.sender;

        list_size++;
    }

    function CommentPost(uint _id_post, string memory _comment) public {
      Feed[_id_post].listmsg[Feed[_id_post].nb_comment] = Commentaires(msg.sender, _comment, block.timestamp);
      Feed[_id_post].nb_comment++;
    }

    function GetComments(uint _id_post)view public returns (string[] memory){
      string[] memory list_comment = new string[](Feed[_id_post].nb_comment);

      for(uint i = 0; i < Feed[_id_post].nb_comment; i++){
        list_comment[i] = Feed[_id_post].listmsg[i].content;
      }

      return list_comment;
    }

    function getPost() view public returns (string[] memory) {

      string[] memory list_post = new string[](list_size);

      for(uint i = 0; i < list_size; i++){
        list_post[i] = string.concat("#", uint2str(list_size), "  - ",  Feed[i].content, "\n");
      }

      return list_post;
    }

    function reward(uint _id_post) public payable{
      address payable post_owner = payable(Feed[_id_post].waver);
      post_owner.transfer(msg.value);
    }
}