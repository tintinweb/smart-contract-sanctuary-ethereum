/**
 *Submitted for verification at Etherscan.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract AnswerHistory {
mapping(uint=>uint) expirydates; 
uint nextSurveyId =1; 

    struct Survey {
           uint pdid;
           uint surveyid;
         uint expirydate;
        address creator;
        bytes32 surveyQuestionsHash;
        }
        // Mapping of sid to surveyStruct
 mapping(uint => Survey) surveys;
 

     
     // Mapping of  pdid to surveyid to boolean
     mapping(uint=> mapping(uint => bool)) public hasSubmitted;
   
 // Mapping of sid  to address to concatenated_answer_string  
 mapping(uint => mapping(address =>bytes32)) surveyanswers;
    
    
      event votingDone(uint256 _sid, uint256 pdid, bytes32 _answerstring);
      event surveyCreated(uint256 _sid, bytes32 _surveyhash);


   
         function createSurvey( uint _pdid, uint _expirydate,bytes32 _surveyhash) public  {
      surveys[nextSurveyId].pdid = _pdid;
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

  function vote(bytes32  _surveyhash,uint _nextSurveyId, uint pdid, bytes32 _answerstring) public  {
     require(surveys[_nextSurveyId].surveyQuestionsHash == _surveyhash,"Select a valid survey"  );
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