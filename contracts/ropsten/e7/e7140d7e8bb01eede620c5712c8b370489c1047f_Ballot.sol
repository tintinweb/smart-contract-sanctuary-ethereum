/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Ballot{
    // variable
    struct vote{
        address voterAddress;
        bool choice;
    }

    struct voter {
        string voterName;
        bool voted;
    }

    uint private countResult = 0;
    uint public finalResult = 0;
    uint public totalVoter = 0;
    uint public totalVote = 0;

address public ballotOfficialAddress;
string public ballotOfficialName;
string public proposal;


mapping(uint=>vote) private votes;
mapping (address=> voter) public voterRegister;

enum State{ Created, Voting, Ended }
State public state;

// modifier
modifier condition(bool _condition){
    require(_condition);
    _;
}

modifier onlyOfficial(){
    require(msg.sender==ballotOfficialAddress);
    _;
}

modifier inState(State _state){
    require(state == _state);
    _;
}
// events

// functions

constructor(string memory _ballotOfficialName,string memory _proposal){
    ballotOfficialAddress= msg.sender;
    ballotOfficialName=_ballotOfficialName;
    proposal=_proposal;


}

function addVoter(address _voteraddress, string memory _voterName) 
public
inState(State.Created)
onlyOfficial
{
 voter memory v;
    v.voterName= _voterName;
    v.voted=false;
    voterRegister[_voteraddress]=v;
    totalVoter++;

}

function startVote()
public
inState(State.Created)
onlyOfficial
{
state=State.Voting;
}


function doVote(bool _choice)
public
inState(State.Voting)
returns(bool voted)
{
bool found = false;

if(bytes(voterRegister[msg.sender].voterName).length !=0 
&& !voterRegister[msg.sender].voted){

voterRegister[msg.sender].voted= true;
vote memory v;
v.voterAddress = msg.sender;
v.choice = _choice;

if(_choice){
    countResult++;
}
votes[totalVote]=v;
totalVote++;
found= true;

}
return found;
}


function endVote() 
public 
inState(State.Voting)
onlyOfficial
{
state=State.Ended;
finalResult=countResult;
}
}