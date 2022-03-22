/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// File: election.sol


pragma solidity ^0.8.0;

contract Election{
       uint public totalTopics;
       address owner;

       struct Option{
          uint optionId;
          string optionName; 
          uint votes;
       }   

       struct VoterLog{
           uint optionId;
           address voter; 
       }

       struct Topic {
           uint topicId;
           string topicName;
           uint optionCount;
           uint status;
           uint totalVotes;
           bool isDeleted;
           mapping (uint=>Option) optionMapping; 
           mapping (uint=>VoterLog[]) voterLogs;
       }  
        Topic[] public topics;    
        modifier onlyOwner{
            require(owner== msg.sender ,"Only owner can create topic.");
              _;
        } 

        modifier validateTopic(uint _topicId){
            require(_topicId >0 && _topicId<= totalTopics,"Provide valid input.");
             _;               
        }

       event TopicCreation (uint topicId);
       event StartVoting(uint topicId,bool status);
       event StopVoting(uint topicId,bool status);     
       event Vote(uint topicId,uint optionId ,bool status); 
       event TopicDeleted(uint topicId); 

       constructor() public {
           owner= msg.sender;
       }       
        function createTopic(string memory _topicName, string[] memory _optioNames) public onlyOwner{
            require(bytes(_topicName).length> 0,"Require Valid topicname.");
            require(_optioNames.length >= 2,"Require Valid number of optioNames.");
            ++totalTopics;
            Topic storage topic = topics.push();
            topic.topicId= totalTopics; 
            topic.topicName= _topicName;
            topic.optionCount= _optioNames.length;
            topic.status= 0;
            topic.totalVotes= 0;
            topic.isDeleted = false; 

            for(uint i=0; i<_optioNames.length; i++){
                topic.optionMapping[i] = Option(i,_optioNames[i],0);
            }
            emit TopicCreation(topic.topicId);
        }

        function getOptions(uint _topicId) public validateTopic(_topicId) returns(uint[] memory, string[] memory, uint[] memory){
            uint count = topics[_topicId-1].optionCount;
            uint[]  memory ids = new uint[](count);
            string[] memory optionsNames = new string[](count);    
            uint[] memory votes = new uint[](count);
            for(uint i=0; i< count;i++){
                ids[i]=topics[_topicId-1].optionMapping[i].optionId;
                optionsNames[i]= topics[_topicId-1].optionMapping[i].optionName;
                votes[i]= topics[_topicId-1].optionMapping[i].votes;
            }
            return (ids, optionsNames, votes);
        }

        function removeTopic(uint _topicId) public validateTopic(_topicId) returns(bool){
             require(topics[_topicId-1].isDeleted == false,"Topic is already deleted.");
             topics[_topicId-1].isDeleted = true;
             emit TopicDeleted(_topicId);
             return true;                              
        }
        
        function startVoting(uint _topicId) public validateTopic(_topicId) returns(bool){
            require(topics[_topicId-1].isDeleted == false,"Topic is already deleted.");
            if(topics[_topicId-1].status == 0 ){
                topics[_topicId-1].status =1;
                emit StartVoting(_topicId, true);
                return true;
            }
            else{
                return false;   
            }
        }

        function stopVoting(uint _topicId) public validateTopic(_topicId) returns(bool){
            require(topics[_topicId-1].isDeleted == false,"Topic is already deleted.");
            if(topics[_topicId-1].status == 1 ){
                topics[_topicId-1].status =2;
                emit StopVoting(_topicId, true);
                return true;
            }
            else{
                return false;   
            }
        }

        function vote(uint _topicId, uint _optionId) public validateTopic(_topicId) returns(bool){
            require(topics[_topicId-1].isDeleted == false,"Topic is already deleted.");
            require(_optionId < topics[_topicId-1].optionCount,"Enter valid option.");
            if(topics[_topicId-1].status == 1 ){
                topics[_topicId-1].optionMapping[_optionId].votes++;
                topics[_topicId-1].totalVotes++;
                topics[_topicId-1].voterLogs[_topicId].push(VoterLog(_optionId,msg.sender));
                emit Vote(_topicId, _optionId,true);
                return true;
            }
            else{
                return false;   
            }
        }

        function getVoterRecords(uint _topicId)public view returns(VoterLog[] memory){
            VoterLog[] memory logs=topics[_topicId-1].voterLogs[_topicId];
            return logs;
        }
}