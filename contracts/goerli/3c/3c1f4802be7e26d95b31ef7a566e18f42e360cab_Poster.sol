/**
 *Submitted for verification at Etherscan.io on 2022-03-07
*/

pragma solidity 0.8.0;

interface IPoster {
    event NewPost(address indexed user, string content);

    function post(string memory content) external;
}

contract Poster {
    event NewPost(address indexed user, string content, string indexed tag);

    function post(string calldata content, string calldata tag) public {
        emit NewPost(msg.sender, content, tag);
    }
}