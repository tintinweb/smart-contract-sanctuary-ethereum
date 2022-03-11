// SPDX-License-Identifier: UNLICENSED

//version of solidity compiler
pragma solidity >=0.4.22 <0.9.0; 

contract Admin{

    // Storage
    struct Candidate {
        uint id;
        string name;
        uint voteCount;
    }
    address public admin; 

    string[] public candidateNameArray;
    string[] public newCandiAddArray;

    uint [] public candidateVotesArray;

    address [] public adsofVotersArray;


    bool public goingon;// status of election
    bool public isCandiAdded=false;


    mapping(address => bool) public voters;

    mapping(uint => Candidate) public candidates;
    uint public candidatesCount;
   
    // events 
    event votedEvent(
        uint indexed _candidateId
    );

    event electionEvent(
        bool started
    );

    event voterLogin(
        bool allow
    );

    // constructor to initialize admin address
    constructor(){
       
         admin=msg.sender;
    } 

    // Modifier for only admin access
    modifier onlyAdmin() {
    
        require(msg.sender == admin);
        _;
    }

    // ***Read Only Functions***

    // candidateList() function returns the
    // list of active candidates names
    function candidateList() public view returns(string [] memory ){
        return candidateNameArray;
    }   

    // candidateVoteList() function returns the
    // list of vote count of active candidates
    function candidateVoteList() public onlyAdmin view returns(uint [] memory ){
        uint[] memory temp = candidateVotesArray;
        return temp;
    }  
    
    // hasVoted() function check wheather 
    // the current msg.sender has voted or not
    function hasVoted() public view returns(bool){
        address ad=msg.sender;
        return voters[ad];
    }
     
    // isAdmin() function check wheather connected
    //  msg.sender address is admin address or not 
     function isAdmin() public view returns(bool){

         if(admin==msg.sender){
             return true;
         }else{
             return false;
         }

     }
    // ***Transaction functions***
    
    // addNewCandidate() function is used to add new candidates with validation
    function addNewCandidate(string memory candidateName) public onlyAdmin{
        bool flag=true;
        isCandiAdded=true;
        for(uint candCount=1;candCount<=candidatesCount;candCount++){
        
             if(keccak256(abi.encodePacked(candidates[candCount].name)) == keccak256(abi.encodePacked(candidateName))){
                 flag=false;  
             }
        }

        if(flag){
                addCandidate(candidateName);
        }
        else{
            revert('Candidate already exist');
        }
    }
     function addCandidate (string memory _name) public {
        
        candidatesCount ++;
        candidates[candidatesCount] = Candidate(candidatesCount, _name, 0);
        candidateNameArray.push(candidates[candidatesCount].name);
        candidateVotesArray.push(candidates[candidatesCount].voteCount);
    }

    // startElection() is used to start the election
    function startElection(bool status) public onlyAdmin{
        goingon = status;
        emit electionEvent(status);
    }

    // endElection() is used to start the election
     function endElection(bool status) public onlyAdmin{
        goingon = status;
        emit electionEvent(status);
    }
   
    // vote() function is used to vote the candidate
    function vote(uint _candidateId) public returns(bool){
        require(!voters[msg.sender],"Already voted....");

        require(_candidateId >= 0 && _candidateId <= candidatesCount,"Invalid candidate");

        require(goingon,"Election ended");

        voters[msg.sender] = true;
        address a=msg.sender;
        adsofVotersArray.push(a);
       

        candidates[_candidateId].voteCount ++;
        candidateVotesArray[_candidateId]++;
        emit votedEvent(_candidateId);
        if(hasVoted()){
            return true;
        }else{
            return false;
        }
    }

    
     function addAllCandi(string[] memory namestr) public onlyAdmin{
        newCandiAddArray=namestr;
        uint len=newCandiAddArray.length;
        for(uint i=0;i<len;i++){
            addNewCandidate(newCandiAddArray[i]);
        }

     }

    function resetall() public{
        for(uint i=0;i<adsofVotersArray.length;i++){
            voters[adsofVotersArray[i]]=false;
        }
        isCandiAdded=false;
        delete adsofVotersArray;
        delete candidateNameArray;
        delete newCandiAddArray;
        delete candidateVotesArray;
        goingon=false;
        delete candidatesCount;
    }

   
    
    
}