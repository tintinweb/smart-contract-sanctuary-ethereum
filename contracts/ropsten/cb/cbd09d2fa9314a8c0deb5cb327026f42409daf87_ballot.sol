/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 < 0.9.0;

contract ballot{
    // this struct will handle our votes
    string voterName;
    
    struct vote{
        address voterAddress;
        bool choice;
    }
    // this struct will handle our voters
    struct voter{
        string voterName;
        bool voted;
    }

    uint private countResult    = 0; // keep track of our count results means track how many people are voted for the specific propsal
                                     // as it is private so when the voting goes end , it will pass the countResult variable to = FinalResult variable   
    uint public finalResult     = 0; // we show the result of this variable when the final result passes from countResult to Final Result 
    uint public totalVoter      = 0; // total amount of voters
    uint public totalVote       = 0; // total amount of votes

    address public ballotOfficalAddress ; // this is the address to keep the track of the offical address of this ballot - including some string name of the ballots and propsal.
    string public ballotOfficalName ;
    string public proposal;

    // now we have define two mappings

    mapping(uint => vote ) private votes ;          // this one to keep our votes 
    mapping(address => voter) public voterRegister ;  // this one is to keep our voters registers
    // here we define our state variable using enum
    enum State { Created , Voting , Ended}
    State public state;
//_____________________________________________________________________________________________________________________________
/*Modifires 
 now we define our modifires here
 here we call condition - and it will accept any kind of condition but is gonna be bool so we get true or false*/   
modifier condition(bool _condition){
     require(_condition);   // basically what is require is simply for condition to be true or
     _;
 }
// second modifier----------------------------------------------------------------
modifier onlyOfficial(){ 
    // it will take no arguments
    // it just make sure who is caling this  , so msg.sender or whatever address is calling  a function has to be equal
    // to the ballot offical address , that we will be defined in our constructor 
    require(msg.sender == ballotOfficalAddress);
    _;
}
// 3rd modifire ----------------------------------------------------------------
modifier inState(State _state) { 
    // this is going to allow us to do is simply pass a state that we're going to call
    // basically we just require that the current state of the contract will be equal to the state that is passed here
    require(state == _state);
    _;
}
//______________________________________________________________________________________________________________________________

// Events

// Functions - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

constructor(
// constructor will take two arguments
    string memory _ballotOfficalName,
    string memory _proposal
)
{
        ballotOfficalAddress =  msg.sender;    
        ballotOfficalName = _ballotOfficalName;
        proposal = _proposal;

        state = State.Created ;

        // wee just need to pass two arguments when we want to call the voting created function 
}


/*with the help of this addVoter function the creator of this contract can add the voters one by one
    and these people using there addresses will later be able to vote*/

function addVoter(address  _voterAddress , string memory _voterName)
    public
    inState(State.Created)
    onlyOfficial 
{
    /*this function will create new voter 
    local v for  this function 
    this variable v is going to be a voter 
    then we setup some attributes for it*/
    voter memory v ;
    v.voterName = _voterName;
    v.voted = false;
/*then we add this voter to our voterRegister mapping and assign value to the v*/
    voterRegister[_voterAddress] = v ;
    totalVoter++;
}

/* This function will allow user to cast their votes , we do not need any argument here
    this can only happen if the state is created otherwise not starting possible
*/

/* can only happen when our state is created otherwise doesn't make sense we cannot start the vote when it's already ongoing or when
the vote is ended and again it can only be called by the official address so we type on the official*/
function startVote()
    public
    inState(State.Created)
    onlyOfficial
{
    state = State.Voting ; // after setting this , you would not be able to add the voters and start the voting anymore
                           // now we can only do vote and end vote 

}
/*h--*/
function doVote(bool _choice)
    public
    inState(State.Voting)
    returns(bool voted)
{
    bool found = false;
    if(bytes(voterRegister[msg.sender].voterName).length != 0 && !voterRegister[msg.sender].voted)
    {
        voterRegister[msg.sender].voted = true;
        vote memory v ; 
        v.voterAddress = msg.sender;
        v.choice = _choice;
        if(_choice){
            countResult++;
        }

        votes[totalVote]  = v ; 
        totalVote++ ;
        found = true ;
    }

    return found ; 

}
function endVote()
    public
    inState(State.Voting)
    onlyOfficial
{
     state = State.Ended ; 
     finalResult = countResult ;
}

}