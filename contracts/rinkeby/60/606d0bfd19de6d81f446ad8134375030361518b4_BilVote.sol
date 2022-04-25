/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;


 contract BilVote{

    uint counter=0;
    address admin;

    enum Phase{
        Register,
        Voting,
        Results
    }

    Phase public _phase;

    struct Voter{
        address mp;
        string constituency;
    }

    struct Bill{
        uint id;
        string name;
        string year;
        Phase phase;
        uint votes;
        mapping(address=>bool) hasVoted;
    }

    mapping(uint =>Bill) public bills;
    mapping(address=>bool) public isVoter;
    Voter [] public voters;

    constructor(){
        counter ++;
        admin =msg.sender;
    }

    modifier onlyAdmin(){
        require(msg.sender ==admin, "Not and admin");
        _;
    }

    modifier validAddress(address _addr){
        require(msg.sender != address(0), "invalid address");
        _;
    }

    function changeAdmin (address newAdmin) onlyAdmin validAddress(newAdmin) public{
        admin =newAdmin;
    }

    function registerVoter(address _voter, string memory _constituency) onlyAdmin validAddress(_voter) public{
        require(isVoter[_voter] !=true);
        voters.push(Voter({
            mp:_voter,
            constituency:_constituency
        }));
        isVoter[_voter]=true;
    }

    function registerBill(string memory _name, string memory _year) onlyAdmin public{

        Bill storage newBill= bills[counter];
        newBill.id=counter;
        newBill.name=_name;
        newBill.year=_year;
        newBill.phase=_phase;
        newBill.votes=0;
        counter++; 
    }

    function changeBillPhase(uint _id) onlyAdmin public{
        require(_id !=0, "invlaid id");
        Bill storage _bill=bills[_id];
        _bill.phase =Phase.Voting;
        
    }

    function closeVoting(uint _id) onlyAdmin public{
        require(_id !=0, "invlaid id");
        Bill storage _bill=bills[_id];
        _bill.phase =Phase.Results;
        
    }

    function voteForBill(uint _id) public{
        require(isVoter[msg.sender]);
        Bill storage billToVote=bills[_id];
        require(!billToVote.hasVoted[msg.sender]);
        require(billToVote.phase ==Phase.Voting);
        billToVote.votes++;
        billToVote.hasVoted[msg.sender]=true;
    }

    function results(uint _id) public view returns(uint){
        Bill storage bill =bills[_id];
        return bill.votes;
    }
 }