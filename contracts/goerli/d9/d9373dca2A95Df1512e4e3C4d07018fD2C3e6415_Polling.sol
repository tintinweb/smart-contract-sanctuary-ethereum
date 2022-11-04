//SPDX-License-Identifier:MIT

pragma solidity ^0.8.9;

contract Polling{
  
    address immutable owner;
    uint32 public ID = 1;
 

    struct voteDetails{
        string Topic;
        string Details;
        string bannerURL;
        uint120 _noOfVOte;
        rating rate;
        bool voteCreated;
        uint32 votingPeriod;
        address voteOwnerAddress;
        uint32 No;
        uint32 Undecided;
        uint32 Yes; 
    }

    enum rating{
        No,
        Undecided,
        Yes   
    }

    mapping (uint => voteDetails) _votedetails;
    mapping(address => mapping(uint => bool)) hasVoted;

    modifier voted(uint _id){
        require(hasVoted[msg.sender][_id] == false, "youve voted");
        _;
    }

    modifier timeElapsed(uint _id){
        voteDetails storage VD =  _votedetails[_id];
        require(block.timestamp <= VD.votingPeriod, "Voting has ended");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function createVote(string memory _topic, uint duration, string memory bannerLink, string memory _details) external returns(uint, string memory){
        voteDetails storage VD =  _votedetails[ID];
        VD.voteOwnerAddress = msg.sender;
        VD.Topic = _topic;
        VD.Details = _details;
        VD.bannerURL = bannerLink;
        VD.voteCreated = true;
        VD.votingPeriod = uint32(block.timestamp + (duration * (1 days)));
        uint currentId = ID;
        ID++;
        return(currentId, "Created Succesfully");
    }

    function Vote(uint32 _id, rating _rate) external voted(_id) timeElapsed(_id){
        require(uint8(_rate) <= 2);
        voteDetails storage VD =  _votedetails[_id];
        require(VD.voteCreated == true, "invalid vote");
        hasVoted[msg.sender][_id] = true;
        VD.rate = _rate;
        VD._noOfVOte +=1; 

        if (rating.Yes == _rate) VD.Yes +=1 ;
        if (rating.Undecided == _rate) VD.Undecided +=1;
        if (rating.No == _rate) VD.No +=1;       
    }

    function getVoteDetails(uint _id) external view returns(address, string memory, string memory, uint, uint32, string memory, uint32, uint32, uint32){
        voteDetails storage VD =  _votedetails[_id];
        require(VD.voteCreated == true, "invalid vote id");
        return(VD.voteOwnerAddress, VD.Topic, VD.Details, VD._noOfVOte, VD.votingPeriod, VD.bannerURL, VD.No, VD.Undecided, VD.Yes);
    }

    function timeLeft(uint _id) external view returns(uint32){
        voteDetails storage VD =  _votedetails[_id];
        return uint32(VD.votingPeriod - block.timestamp);

    }


}