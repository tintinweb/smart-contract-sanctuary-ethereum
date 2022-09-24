/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

pragma solidity ^0.8.7;

contract VotingDapp {



     struct Vote {
       bool Isvooted;
       bool authorize;
  }

  constructor()  {
       owner = msg.sender;
  }
   
     mapping (address => Vote) public Voter_detail ;

    mapping (string => uint256) public CandidateNoOfVoting ;
  

 modifier OnlyOwner{
        require(msg.sender == owner, "Only owner can run this function");
        _;
    }




    address owner ;
    uint public TimeStampStart ; 
     uint public TimeStampEnd; 
    uint256 public voter;
    address payable Donationowner;
    string []  public AllCandidate;
    address []  public AllVoter;
    address public Winner ;
    string []  public Remaing_Candidate;
  
   
    bool Voting_start = false; 




   
    function StartVoting() public OnlyOwner { 
    
        TimeStampStart = block.timestamp; 
        Voting_start = true;
        
    }


function addCandidate(string []  memory _candidate) public {

 AllCandidate = _candidate;

}

function addVoter(address [] memory _voters) public {

AllVoter = _voters;
for(uint i =0 ; i<_voters.length ; i++){
    Voter_detail[ AllVoter[i]].authorize = true; 
}

}

function place_Vote(uint _place) public{
        //    require(Voter_detail[msg.sender].authorize == true , " Only Authorize user can place vote" );
        require(Voter_detail[msg.sender].Isvooted == false , "Already paid" );
        // payable(msg.sender).transfer(msg.value);

 if(_place == 1){
                CandidateNoOfVoting[AllCandidate[0]] = CandidateNoOfVoting[AllCandidate[0]] + 1 ; 
                

            }
            else if(_place == 2){
                CandidateNoOfVoting[AllCandidate[1]] = CandidateNoOfVoting[AllCandidate[1]] + 1 ; 
            }
            else if(_place == 3){
                CandidateNoOfVoting[AllCandidate[2]] = CandidateNoOfVoting[AllCandidate[2]] + 1 ;  
            }
            else if(_place == 4){
                CandidateNoOfVoting[AllCandidate[3]] = CandidateNoOfVoting[AllCandidate[3]] + 1 ;  
            }
            else if(_place == 5){
                CandidateNoOfVoting[AllCandidate[4]] = CandidateNoOfVoting[AllCandidate[4]] + 1 ;  
            }
            else if(_place == 6){
                CandidateNoOfVoting[AllCandidate[5]] = CandidateNoOfVoting[AllCandidate[5]] + 1 ;  
            }
            else if(_place == 7){
                CandidateNoOfVoting[AllCandidate[6]] = CandidateNoOfVoting[AllCandidate[6]] + 1 ;  
            }
            else if(_place == 8){
                CandidateNoOfVoting[AllCandidate[7]] = CandidateNoOfVoting[AllCandidate[7]] + 1 ;  
            }
            else if(_place == 9){
                CandidateNoOfVoting[AllCandidate[8]] = CandidateNoOfVoting[AllCandidate[8]] + 1 ;  
            }
            else if(_place == 10){
                CandidateNoOfVoting[AllCandidate[9]] = CandidateNoOfVoting[AllCandidate[9]] + 1 ;  
            }

    //         uint winner = 0;
    // for(uint i = 0 ; i<AllCandidate.length ; i++){
    //     if(CandidateNoOfVoting[AllCandidate[i]] > winner){
    //         winner = CandidateNoOfVoting[AllCandidate[i]];
    //         Winner = AllCandidate[i];

    //     }
    // }
   Voter_detail[msg.sender].Isvooted = true;
    voter++;

    



           
}



      
   
function SetDonationowner( address payable _owner) public  {
 Donationowner = _owner;

}

function Donate() public payable {

Donationowner.transfer(msg.value);
}

}