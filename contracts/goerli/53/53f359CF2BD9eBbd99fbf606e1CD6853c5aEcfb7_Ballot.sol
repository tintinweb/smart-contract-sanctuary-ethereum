// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;
//we will give permission to vote single
//Function to vote on a proposal
//fun

    error YOUHAVEDELEGATED(address delegate);
    error AllreadyVoted(address voter);
    error NOPERSMISSION(address voter);
    error ALLREADYVoted();
    error ONLYCHAIRPERSON();
    error ProposeSomething();


contract Ballot{
    struct Vote{
     uint vote;
     address delegate;
     uint weight;
     bool IsVoted;   
    }
    struct Proposal {
        string name;   // short name (up to 32 bytes)
        uint TotalVote; // number of accumulated votes
    }
    Proposal[] public s_proposal;
    address[] private whoCanVote;
    mapping(address => mapping(address => Vote)) public s_voters;
    address public immutable s_chairPerson;

    event GavePermissioned(address indexed voter);
    event Voted(address indexed voter,uint indexed toWhom);
    event Propose(string indexed data);
    event _delegate(address indexed from,address indexed to);
    event _winner(string indexed data , uint indexed index);

    modifier OnlyChairPeron{
        if(msg.sender != s_chairPerson){
            revert ONLYCHAIRPERSON();
        }
        _;
    }
    constructor (){
        s_chairPerson = msg.sender;
    }
    function GivePermission(address _voter) external OnlyChairPeron {
        if(s_voters[s_chairPerson][_voter].IsVoted == true 
                         ||
         s_voters[s_chairPerson][_voter].weight > 0){
            revert AllreadyVoted(_voter);
        }
         s_voters[s_chairPerson][_voter].weight = 1;
         whoCanVote.push(_voter);
         emit GavePermissioned(_voter);
    }
    function ProposalSomething(string memory _name) external{
        for(uint i = 0;i<1;i++){
            s_proposal.push(Proposal({
                    name : _name,
                    TotalVote : 0
                }
            ));
        }
        emit Propose(_name);
    }
    function VOTE(uint index) external {
        Vote storage sender = s_voters[s_chairPerson][msg.sender];
        if(sender.weight == 0){
            revert NOPERSMISSION(msg.sender);
        }
        if(sender.delegate != address(0)){
            revert YOUHAVEDELEGATED(sender.delegate);
        }
        if(sender.IsVoted == true)
        {
           revert ALLREADYVoted();
        }
        sender.IsVoted = true;
        sender.weight = 0;
        s_proposal[index].TotalVote += 1;
        emit Voted(msg.sender,index);
    }
    function delegate(address to) public{
        Vote storage sender = s_voters[s_chairPerson][msg.sender];
        if(sender.IsVoted == true) revert ALLREADYVoted();
        if(sender.delegate != address(0)) revert YOUHAVEDELEGATED(sender.delegate);
        sender.delegate = to;
        sender.weight = 0;
        Vote storage _to = s_voters[s_chairPerson][to];
        _to.weight = 1;
        emit _delegate(msg.sender,to);
    }
    function Winner() public view returns(uint winner){
        uint number = 0;
        for(uint i = 0;i<s_proposal.length;i++){           
            if( s_proposal[i].TotalVote>=number){
               number =  s_proposal[i].TotalVote;
               winner = i;
            }
        }
    }
    function getWinner() public  returns(string memory Name){
        uint winner = Winner();
        Name =  s_proposal[winner].name;
        emit _winner(Name,winner);
    }
    function getWeight(address _sender) public view returns(uint){
        return  s_voters[s_chairPerson][_sender].weight;
    }
    function getDelegate(address _sender) public view returns(address){
        return s_voters[s_chairPerson][_sender].delegate;
    }
    function getIsVoted() public view returns(bool){
        return s_voters[s_chairPerson][msg.sender].IsVoted;
    }
    function whoCanVOTE(uint index) public view returns(address){
        return whoCanVote[index];
    }
    function proposal(uint index) public view returns(string memory){
        return s_proposal[index].name;
    }
    function getTotalVote(uint index) public view returns(uint){
        return s_proposal[index].TotalVote;
    }
}