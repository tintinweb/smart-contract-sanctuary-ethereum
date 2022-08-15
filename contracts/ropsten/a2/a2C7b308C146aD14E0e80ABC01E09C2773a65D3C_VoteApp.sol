//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract VoteApp {
 
    address public owner;
    string[] public voteArray;

    constructor(){

        owner = msg.sender;

    }

    // commitedVote stores whether or not the voter has already commited his vote and whether or not he voted UP or DOWN
    struct commitedVote{

        string updownVote;
        bool commitedupdown;

    }
    // post struct stores the number of Up votes and Down votes on each post plus the voters who have commited their votes on this post and their commitedVotes
    struct post{

        uint256 downvotes;
        uint256 upvotes;

        mapping(address => commitedVote) Voters;

    }

    // an event that grants us an insight on every voteupdate
    event voteUpdate ( uint256 votes, address voter, string voted );
    // posts mapping stores all the posts
    mapping(string => post) private posts;

    function addpost(string memory _post) public{

        voteArray.push(_post);

            }

    function vote(string memory _post,string memory _updown) public{

        require(keccak256(abi.encodePacked(_updown)) == keccak256(abi.encodePacked("up")) || keccak256(abi.encodePacked(_updown)) == keccak256(abi.encodePacked("down")), "unvalid voting");
        require(!posts[_post].Voters[msg.sender].commitedupdown,"you have already voted");

        post storage p = posts[_post];
        p.Voters[msg.sender].commitedupdown= true;

        if (keccak256(abi.encodePacked(_updown)) == keccak256(abi.encodePacked("up"))) {p.upvotes++;}
        else if (keccak256(abi.encodePacked(_updown)) == keccak256(abi.encodePacked("down"))) {p.downvotes++;}

        emit voteUpdate(p.upvotes + p.downvotes,msg.sender,_post);

    }



    function getVotes(string memory _post) public view returns( uint256 upvotes, uint256 downvotes){

        post storage p = posts[_post];

        return(p.upvotes, p.downvotes);

    }

}