/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract AnswerHistory {
mapping(uint=>uint) expirydates; 
uint nextSurveyId =1; 

struct Participant {
        uint pdid;
        address [] addressbook;
         }
    
mapping(uint => Participant) public registeredParticipants;
mapping(address => bool) public bcusers;

   

         struct Survey {
           uint surveyid;
         uint expirydate;
        address creator;
        bytes32 surveyQuestionsHash;
        }
        // Mapping of sid to surveyStruct
 mapping(uint => Survey) surveys;
 

     
     // Mapping of  pdid to surveyid to boolean
     mapping(uint=> mapping(uint => bool)) public hasSubmitted;
    // mapping(address=>bool) public surveyAdded;
    mapping(uint => bool) public pdidexists;
   
 // Mapping of sid  to address to concatenated_answer_string  
 mapping(uint => mapping(address =>bytes32)) surveyanswers;

//  modifier registeredUsers (address ID) {
//       require(bcusers[ID] == true);
//       _;
//    }
    
    
      event votingDone(uint256 _sid, uint256 pdid, bytes32 _answerstring);
      event surveyCreated(uint256 _sid, bytes32 _surveyhash);

      event participantRegistered(uint256 ID ,address wallet);


    function registerParticipant(uint ID, address wallet) public payable    {
        require(wallet == msg.sender, "Invalid Identity");

      
        registeredParticipants[ID].pdid = ID;
        pdidexists[ID] =true;
       
        registeredParticipants[ID].addressbook.push(wallet);
        bcusers[wallet]=true;
        emit participantRegistered(ID, wallet);

         }
         
         function getParticipant(uint _key) public view returns (uint pdid, address[] memory addressbook) {
        return (registeredParticipants[_key].pdid,registeredParticipants[_key].addressbook);
    }

    function createSurvey( uint _expirydate,bytes32 _surveyhash) public  {
      require(bcusers[msg.sender] ==true, "User not registered");
        surveys[nextSurveyId].creator =msg.sender;
        surveys[nextSurveyId].surveyQuestionsHash = _surveyhash;
        surveys[nextSurveyId].expirydate = _expirydate;
        expirydates[nextSurveyId]=_expirydate;
        surveys[nextSurveyId].surveyid=nextSurveyId;
       
        
        emit surveyCreated(nextSurveyId,_surveyhash);
         nextSurveyId ++;

    }

    function getSurveyId() public view returns (uint) {
        return nextSurveyId;
    } 

  function vote(string memory  _surveyhash,uint _nextSurveyId, uint pdid, bytes32 _answerstring) public  {
    require(bcusers[msg.sender] ==true,"User not registered");
     require(keccak256(abi.encodePacked((surveys[_nextSurveyId].surveyQuestionsHash))) == keccak256(abi.encodePacked((_surveyhash))),"Select a valid survey"  );
     require(expirydates[_nextSurveyId]>=block.timestamp,"Time has passed");
      require(hasSubmitted[pdid][_nextSurveyId] ==false, "You have already voted"); 
     
           
      
    surveyanswers[_nextSurveyId][msg.sender]=_answerstring;
    
    hasSubmitted[pdid][_nextSurveyId] = true;
    
    emit votingDone(_nextSurveyId, pdid,_answerstring);
    
     }
  
function getAnswer(uint _nextSurveyId, address _voter) public view returns(bytes32){
      return surveyanswers[_nextSurveyId][_voter];
        }

function getSurvey(uint _nextSurveyId) public view returns ( bytes32 ){
          
          return surveys[_nextSurveyId].surveyQuestionsHash;

        }
    
}