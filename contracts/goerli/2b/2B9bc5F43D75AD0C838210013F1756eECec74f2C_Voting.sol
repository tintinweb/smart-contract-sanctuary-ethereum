/**
 *Submitted for verification at Etherscan.io on 2022-12-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

//voting contracts starts from here
contract Voting{

    //to store the address of contract owner(who deployed contract)
    address public owner;

    //modifiers-->
    //modifiers for giving rights to only owner
    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "only owner has rights to do this"
        );
        _;
    }

    //modifier for stop  voting
    bool isStop = true;
    modifier Stop(){
        require(isStop==false, "voting needs to stop to see winner");
        _;
    }

    //modifier for start voting
    bool isStart = false;
    modifier Start(){
        require(isStart==true, "voting needs to start to vote for");
        _;
    }

    //function to start voting
    function startVoting() public onlyOwner{
        isStart = true;
    }
    
    //function to stop voting
    function stopVoting() public onlyOwner{
        isStop = false;
    }

    //assign the address of contract owner to owner variable
    constructor(){
        owner = msg.sender;
    }

    struct Voter{
        bool voted; //if true then it is Already voted
        uint vote; //index of to who voted
    }

    //mapping over voters
    mapping(address => Voter) voters;

    string askQuestion;
    //questionn setter only owner can acces this
    function setQuestion(string memory _value) public onlyOwner{
        askQuestion = _value;
    }

    //see what questionn is
    function getQuestion() public view returns (string memory)  {
        return askQuestion;
    }

    //add options
    struct Options {
        string opt;   
        uint voteCount; 
    }

    //option array to store mulitiple options
    Options[] public  option;

    //input array of options in setOptions function
    //and only owner of contract can access this
    function setOptions(string[] memory _opt) public onlyOwner{
        for(uint8 i = 0; i<_opt.length; i++){
            option.push(Options({
                opt:_opt[i],
                voteCount:0
            }));
        }
    
    }

    //vote for particular option
    //voting needs to start in order vote for
    function voteFor(uint8 index) public Start{
        Voter storage sender = voters[msg.sender];      //current voter info
        require(!sender.voted, "Already voted.");       //if already voted then can't vote
        sender.voted = true;
        sender.vote = index;
        option[index].voteCount++;
    }

    //see the winner
    //voting has to stoped from owner to see the winner
    function winner() public view Stop returns (string memory winnerName){
        uint largest = 0;
        for(uint8 i=0; i<option.length; i++){
            if(option[i].voteCount > largest){
                largest = option[i].voteCount;
                winnerName = option[i].opt;
            }
        }
        
    }
}