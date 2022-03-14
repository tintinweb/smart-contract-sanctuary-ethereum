/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.10;

contract Voting {
    //Declare vote parameter
    mapping (string => uint256) public votes;

    //Declare title list
    string [] public title;

    //Declare title list
    address public owner;
    constructor() {
        owner = msg.sender;
    }
    //create title function
    function createTitle(string memory _title) public { 
        require(owner == msg.sender, "only owner can create title.");
        title.push(_title);
        votes[_title] = 0;
    }

    //Vote
    function vote(string memory _title) public {
        votes[_title] += 1;
    }

    function checkLength() public view returns(uint) {
       return title.length;
    }
}