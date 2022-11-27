/**
 *Submitted for verification at Etherscan.io on 2022-11-27
*/

pragma solidity >=0.7.0 <0.9.0;

contract EthereumCourse {
    mapping(address => bool) public voted;
    string public poll = "Is this course hard or easy for you?";
    string[] public votes;
    
    event Vote(address voter, string answer);
    
    function vote(string memory _answer) public returns (bool) {
        if (voted[msg.sender]) {
            return false;
        }
        voted[msg.sender] = true;
        votes.push(_answer);
        emit Vote(msg.sender, _answer);
        return true;
    }
}